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

/// Screen for adding a new expense to a group.
class AddExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;
  const AddExpenseScreen({super.key, required this.groupId});

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) setState(() => _payerId = user.id);
    });
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

    // Create expense with splitMode on it (per Image 3)
    final expense = ExpenseModel.create(
      groupId: widget.groupId,
      description: desc,
      totalAmount: amount,
      currency: group.currency,
      payerId: _payerId!,
      createdBy: user.id,
      category: _category,
      splitMode: _splitMode,
      deviceId: user.deviceId,
    );

    // Create splits for all group members
    List<SplitModel> splits;
    if (_splitMode == SplitMode.equal) {
      splits = group.memberIds.map((memberId) {
        return SplitModel.create(transactionId: expense.id, debtorId: memberId, owedShare: 0);
      }).toList();
    } else {
      splits = group.memberIds.map((memberId) {
        final controller = _splitControllers[memberId];
        final rawInput = double.tryParse(controller?.text ?? '0') ?? 0;
        return SplitModel.create(transactionId: expense.id, debtorId: memberId, rawInput: rawInput, owedShare: 0);
      }).toList();
    }

    // Calculate splits using the service, passing splitMode from expense
    final calculator = ref.read(splitCalculatorProvider);
    splits = calculator.calculateSplits(amount, splits, _splitMode);

    ref.read(expensesProvider.notifier).addExpense(expense);
    ref.read(splitsProvider.notifier).addSplits(splits);
    context.pop();
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
      return Scaffold(appBar: AppBar(title: const Text('Add Expense')), body: const Center(child: Text('Group not found')));
    }

    for (final memberId in group.memberIds) {
      _splitControllers.putIfAbsent(memberId, () => TextEditingController());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded)),
        actions: [TextButton(onPressed: _saveExpense, child: const Text('Save'))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
