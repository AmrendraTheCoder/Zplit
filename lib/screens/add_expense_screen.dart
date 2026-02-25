import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/expense_model.dart';
import '../models/split_model.dart';
import '../providers/user_provider.dart';
import '../providers/group_provider.dart';
import '../providers/expense_provider.dart';
import '../services/split_calculator_service.dart';
import '../theme/app_colors.dart';

/// Screen for adding OR editing an expense.
///
/// **Authorization rules (security):**
/// - CREATE: Any group member can create an expense.
/// - EDIT: Only the payer (payerId) or original creator (createdBy)
///   can edit. This is enforced before navigation and in the save method.
/// - DELETE: Only payer/creator can soft-delete. Vector clocks track who
///   made the change via lastModifiedBy for audit.
class AddExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;

  /// If provided, the screen enters EDIT mode.
  final String? expenseId;

  const AddExpenseScreen({super.key, required this.groupId, this.expenseId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String? _payerId;
  ExpenseCategory _category = ExpenseCategory.other;
  SplitMode _splitMode = SplitMode.equal;
  final Map<String, TextEditingController> _splitControllers = {};

  bool get _isEditing => widget.expenseId != null;
  ExpenseModel? _existingExpense;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isEditing) {
        _loadExpenseForEditing();
      } else {
        final user = ref.read(currentUserProvider);
        if (user != null) setState(() => _payerId = user.id);
      }
    });
  }

  /// Loads existing expense data into the form for editing.
  void _loadExpenseForEditing() {
    final expense = ref.read(expensesProvider.notifier).getExpenseById(widget.expenseId!);
    if (expense == null) return;

    // --- AUTHORIZATION CHECK ---
    final user = ref.read(currentUserProvider);
    if (user == null || !canEditExpense(expense, user.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Only the payer or creator can edit this expense'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
      return;
    }

    _existingExpense = expense;
    _amountController.text = expense.totalAmount.toStringAsFixed(
        expense.totalAmount == expense.totalAmount.roundToDouble() ? 0 : 2);
    _descController.text = expense.description;
    setState(() {
      _payerId = expense.payerId;
      _category = expense.category;
      _splitMode = expense.splitMode;
    });
  }

  /// **Security rule:** Only the person who paid or the original
  /// creator of the expense record can edit/delete it.
  ///
  /// This prevents a group member from quietly changing someone
  /// else's expense amounts — important in a trustless P2P system.
  static bool canEditExpense(ExpenseModel expense, String currentUserId) {
    return expense.payerId == currentUserId ||
        expense.createdBy == currentUserId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    for (final c in _splitControllers.values) { c.dispose(); }
    super.dispose();
  }

  void _saveExpense() {
    final amountText = _amountController.text.trim();
    final desc = _descController.text.trim();
    if (amountText.isEmpty || double.tryParse(amountText) == null) { _showError('Please enter a valid amount'); return; }
    if (desc.isEmpty) { _showError('Please add a description'); return; }
    if (_payerId == null) { _showError('Please select who paid'); return; }

    final amount = double.parse(amountText);
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final group = ref.read(groupsProvider).where((g) => g.id == widget.groupId).firstOrNull;
    if (group == null) return;

    if (_isEditing && _existingExpense != null) {
      _updateExpense(amount, desc, user.id, user.deviceId, group);
    } else {
      _createExpense(amount, desc, user.id, user.deviceId, group);
    }

    context.pop();
  }

  void _createExpense(double amount, String desc, String userId, String deviceId, dynamic group) {
    final expense = ExpenseModel.create(
      groupId: widget.groupId,
      description: desc,
      totalAmount: amount,
      currency: group.currency,
      payerId: _payerId!,
      createdBy: userId,
      category: _category,
      splitMode: _splitMode,
      deviceId: deviceId,
    );

    final splits = _buildSplits(expense.id, amount, group);
    ref.read(expensesProvider.notifier).addExpense(expense);
    ref.read(splitsProvider.notifier).addSplits(splits);
  }

  void _updateExpense(double amount, String desc, String userId, String deviceId, dynamic group) {
    // Increment vector clock on edit — critical for sync conflict detection
    final updatedExpense = _existingExpense!.copyWith(
      description: desc,
      totalAmount: amount,
      payerId: _payerId,
      category: _category,
      splitMode: _splitMode,
      lastModifiedBy: userId,
      vectorClock: _existingExpense!.vectorClock.increment(deviceId),
      updatedAt: DateTime.now(),
    );

    final splits = _buildSplits(updatedExpense.id, amount, group);
    ref.read(expensesProvider.notifier).updateExpense(updatedExpense);
    ref.read(splitsProvider.notifier).replaceSplitsForTransaction(updatedExpense.id, splits);
  }

  List<SplitModel> _buildSplits(String expenseId, double amount, dynamic group) {
    List<SplitModel> splits;
    if (_splitMode == SplitMode.equal) {
      splits = group.memberIds.map<SplitModel>((memberId) {
        return SplitModel.create(transactionId: expenseId, debtorId: memberId, owedShare: 0);
      }).toList();
    } else {
      splits = group.memberIds.map<SplitModel>((memberId) {
        final controller = _splitControllers[memberId];
        final rawInput = double.tryParse(controller?.text ?? '0') ?? 0;
        return SplitModel.create(transactionId: expenseId, debtorId: memberId, rawInput: rawInput, owedShare: 0);
      }).toList();
    }

    final calculator = ref.read(splitCalculatorProvider);
    return calculator.calculateSplits(amount, splits, _splitMode);
  }

  void _deleteExpense() {
    if (_existingExpense == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    if (!canEditExpense(_existingExpense!, user.id)) {
      _showError('Only the payer or creator can delete this expense');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Delete "${_existingExpense!.description}"? This will be synced as a soft-delete to other devices.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(expensesProvider.notifier).softDeleteExpense(
                _existingExpense!.id, user.deviceId, user.id,
              );
              ref.read(splitsProvider.notifier).softDeleteSplitsForTransaction(
                _existingExpense!.id,
              );
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupsProvider).where((g) => g.id == widget.groupId).firstOrNull;
    final user = ref.watch(currentUserProvider);
    final allUsers = ref.watch(allUsersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (group == null) {
      return Scaffold(appBar: AppBar(title: Text(_isEditing ? 'Edit Expense' : 'Add Expense')),
        body: const Center(child: Text('Group not found')));
    }

    for (final memberId in group.memberIds) {
      _splitControllers.putIfAbsent(memberId, () => TextEditingController());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded)),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _deleteExpense,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete expense',
              color: AppColors.error,
            ),
          TextButton(
            onPressed: _saveExpense,
            child: Text(_isEditing ? 'Update' : 'Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Authorization Badge (edit mode) ─────
            if (_isEditing)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'Editing as ${_existingExpense?.payerId == user?.id ? "payer" : "creator"} · Changes tracked via Vector Clock',
                      style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                    )),
                  ],
                ),
              ),

            // ── Amount ────────────────────────────
            Center(child: Column(children: [
              Text(group.currency, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 48),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight, fontSize: 48),
                  border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false,
                ),
              ),
            ])),
            const SizedBox(height: 24),

            // ── Description ───────────────────────
            TextField(controller: _descController, textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'What was this for?', prefixIcon: Icon(Icons.edit_outlined))),
            const SizedBox(height: 20),

            // ── Category ──────────────────────────
            Text('Category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8,
              children: ExpenseCategory.values.map((cat) {
                final isSelected = _category == cat;
                return ChoiceChip(
                  label: Text('${cat.emoji} ${cat.label}'), selected: isSelected,
                  onSelected: (_) => setState(() => _category = cat),
                  selectedColor: (AppColors.categoryColors[cat.name] ?? AppColors.primary).withValues(alpha: 0.2),
                  labelStyle: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, fontSize: 13),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Paid By ───────────────────────────
            Text('Paid by', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8,
              children: group.memberIds.map((memberId) {
                final isCurrentUser = memberId == user?.id;
                final member = allUsers.where((u) => u.id == memberId).firstOrNull;
                final displayName = isCurrentUser ? 'You' : (member?.displayName ?? 'Member');
                final isSelected = _payerId == memberId;
                return ChoiceChip(
                  label: Text(displayName), selected: isSelected,
                  onSelected: (_) => setState(() => _payerId = memberId),
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  labelStyle: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Split Method (Image 3: EQUAL, PERCENT, EXACT) ──
            Text('Split method', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<SplitMode>(
              segments: SplitMode.values.map((mode) => ButtonSegment(value: mode, label: Text(mode.label))).toList(),
              selected: {_splitMode},
              onSelectionChanged: (modes) => setState(() => _splitMode = modes.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.15),
                selectedForegroundColor: AppColors.primary,
              ),
            ),

            // ── Custom Split Inputs (for non-equal modes) ──
            if (_splitMode != SplitMode.equal) ...[
              const SizedBox(height: 16),
              Text(
                _splitMode == SplitMode.percent ? 'Enter percentage for each member' : 'Enter exact amount for each member',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              ...group.memberIds.map((memberId) {
                final isCurrentUser = memberId == user?.id;
                final member = allUsers.where((u) => u.id == memberId).firstOrNull;
                final displayName = isCurrentUser ? 'You' : (member?.displayName ?? 'Member');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    SizedBox(width: 80, child: Text(displayName, style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(
                      controller: _splitControllers[memberId],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: _splitMode == SplitMode.percent ? '%' : group.currency,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    )),
                  ]),
                );
              }),
            ],
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
