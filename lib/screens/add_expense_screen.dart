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

/// Add/Edit Expense — Splitwise-inspired clean form.
///
/// **Authorization:**
/// - CREATE: Any group member
/// - EDIT/DELETE: Only payer or creator
class AddExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;
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

  void _loadExpenseForEditing() {
    final expense = ref.read(expensesProvider.notifier).getExpenseById(widget.expenseId!);
    if (expense == null) return;

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
        content: Text('Delete "${_existingExpense!.description}"?'),
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
    final accent = Theme.of(context).colorScheme.primary;

    if (group == null) {
      return Scaffold(appBar: AppBar(title: Text(_isEditing ? 'Edit Expense' : 'Add Expense')),
        body: const Center(child: Text('Group not found')));
    }

    for (final memberId in group.memberIds) {
      _splitControllers.putIfAbsent(memberId, () => TextEditingController());
    }

    // Build "With You and X" text
    final otherMembers = group.memberIds
        .where((id) => id != user?.id)
        .map((id) {
          final member = allUsers.where((u) => u.id == id).firstOrNull;
          return member?.displayName ?? 'Member';
        })
        .toList();
    final withText = otherMembers.isEmpty
        ? 'With You'
        : 'With You and ${otherMembers.join(', ')}';

    // Find payer name
    final payerName = _payerId == user?.id
        ? 'YOU'
        : (allUsers.where((u) => u.id == _payerId).firstOrNull?.displayName.toUpperCase() ?? 'SELECT');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_rounded, color: accent),
        ),
        title: Text(
          _isEditing ? 'Edit Expense' : 'Add Expense',
          style: TextStyle(color: accent, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _deleteExpense,
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.error,
            ),
          TextButton(
            onPressed: _saveExpense,
            child: Text(
              'SAVE',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "With You and X"
                  Text(
                    withText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Category icon + Name + Date row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category selector
                      GestureDetector(
                        onTap: () => _showCategoryPicker(context),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: (AppColors.categoryColors[_category.name] ??
                                    AppColors.textTertiaryLight)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.dividerDark
                                  : AppColors.dividerLight,
                            ),
                          ),
                          child: Center(
                            child: Text(_category.emoji,
                                style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            // Name
                            TextField(
                              controller: _descController,
                              textCapitalization: TextCapitalization.sentences,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: 'Name of the expense',
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.dividerDark
                                        : AppColors.dividerLight,
                                  ),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.dividerDark
                                        : AppColors.dividerLight,
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: accent),
                                ),
                                filled: false,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Date
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.dividerDark
                                        : AppColors.dividerLight,
                                  ),
                                ),
                                child: Text(
                                  'Today',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Amount ──────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.dividerDark
                                    : AppColors.dividerLight,
                              ),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.dividerDark
                                    : AppColors.dividerLight,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: accent),
                            ),
                            filled: false,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Paid by + Split ─────────────────
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Paid by ',
                            style: Theme.of(context).textTheme.bodyMedium),
                        GestureDetector(
                          onTap: () => _showPayerPicker(context, group, user, allUsers),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark
                                    ? AppColors.dividerDark
                                    : AppColors.dividerLight,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              payerName,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                        Text(' and split ',
                            style: Theme.of(context).textTheme.bodyMedium),
                        GestureDetector(
                          onTap: () => _showSplitModePicker(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark
                                    ? AppColors.dividerDark
                                    : AppColors.dividerLight,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _splitMode.label.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Custom Split Inputs ─────────────
                  if (_splitMode != SplitMode.equal) ...[
                    const SizedBox(height: 24),
                    Text(
                      _splitMode == SplitMode.percent
                          ? 'Enter percentage for each member'
                          : 'Enter exact amount for each member',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    ...group.memberIds.map((memberId) {
                      final isCurrentUser = memberId == user?.id;
                      final member = allUsers
                          .where((u) => u.id == memberId)
                          .firstOrNull;
                      final displayName = isCurrentUser
                          ? 'You'
                          : (member?.displayName ?? 'Member');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          SizedBox(
                            width: 80,
                            child: Text(displayName,
                                style:
                                    Theme.of(context).textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _splitControllers[memberId],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                hintText: _splitMode == SplitMode.percent
                                    ? '%'
                                    : group.currency,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                        ]),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),

          // ── Bottom "Done" Button ──────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(_isEditing ? 'Update' : 'Done'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpenseCategory.values.map((cat) {
                final isSelected = _category == cat;
                return ChoiceChip(
                  label: Text('${cat.emoji}  ${cat.label}'),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _category = cat);
                    Navigator.pop(ctx);
                  },
                  selectedColor:
                      (AppColors.categoryColors[cat.name] ?? AppColors.primary)
                          .withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPayerPicker(BuildContext context, dynamic group, dynamic user,
      List allUsers) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paid by',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ...group.memberIds.map<Widget>((memberId) {
              final isCurrentUser = memberId == user?.id;
              final member = allUsers
                  .where((u) => u.id == memberId)
                  .firstOrNull;
              final displayName = isCurrentUser
                  ? 'You'
                  : (member?.displayName ?? 'Member');
              final isSelected = _payerId == memberId;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : AppColors.avatarColors[
                          group.memberIds.indexOf(memberId) %
                              AppColors.avatarColors.length],
                  child: Text(
                    displayName[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                title: Text(displayName),
                trailing: isSelected
                    ? Icon(Icons.check_rounded,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() => _payerId = memberId);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showSplitModePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Split method',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ...SplitMode.values.map((mode) {
              final isSelected = _splitMode == mode;
              return ListTile(
                title: Text(mode.label),
                trailing: isSelected
                    ? Icon(Icons.check_rounded,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() => _splitMode = mode);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
