import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_colors.dart';

/// Screen for creating a new expense group.
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _memberNameController = TextEditingController();
  String _currency = '₹';
  final List<String> _memberNames = [];

  final List<String> _currencies = ['₹', '\$', '€', '£', '¥'];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _memberNameController.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _memberNameController.text.trim();
    if (name.isEmpty) return;
    if (_memberNames.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member already added'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() { _memberNames.add(name); _memberNameController.clear(); });
  }

  void _removeMember(int index) {
    setState(() => _memberNames.removeAt(index));
  }

  void _createGroup() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final allUsers = ref.read(allUsersProvider.notifier);
    final memberIds = <String>[currentUser.id];

    for (final memberName in _memberNames) {
      final member = UserModel.create(
        username: memberName.toLowerCase().replaceAll(' ', '_'),
        displayName: memberName,
        avatarColorIndex: memberIds.length,
        deviceId: 'placeholder-${memberName.hashCode}',
      );
      allUsers.addUser(member);
      memberIds.add(member.id);
    }

    ref.read(groupsProvider.notifier).createGroup(
      name: name,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      currency: _currency,
      memberIds: memberIds,
      createdBy: currentUser.id,
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Group Name', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'e.g., Goa Trip 2026', prefixIcon: Icon(Icons.group_outlined)),
            ),
            const SizedBox(height: 20),
            Text('Description (optional)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(controller: _descController, maxLines: 2,
              decoration: const InputDecoration(hintText: 'What is this group for?', prefixIcon: Icon(Icons.description_outlined))),
            const SizedBox(height: 20),
            Text('Currency', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _currencies.map((c) {
                final isSelected = _currency == c;
                return ChoiceChip(
                  label: Text(c), selected: isSelected,
                  onSelected: (_) => setState(() => _currency = c),
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 16,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Members', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('You are added automatically', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(
                  controller: _memberNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Add member name', prefixIcon: Icon(Icons.person_add_outlined)),
                  onSubmitted: (_) => _addMember(),
                )),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addMember, icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.person, size: 18),
                  label: Text(ref.watch(currentUserProvider)?.displayName ?? 'You'),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  side: BorderSide.none,
                ),
                ...List.generate(_memberNames.length, (i) {
                  return Chip(
                    label: Text(_memberNames[i]),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeMember(i),
                    side: BorderSide.none,
                  );
                }),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(onPressed: _createGroup, child: const Text('Create Group')),
            ),
          ],
        ),
      ),
    );
  }
}
