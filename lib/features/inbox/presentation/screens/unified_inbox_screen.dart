import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:algora/core/theme/app_colors.dart';
import 'package:algora/core/theme/app_typography.dart';
import 'package:algora/core/utils/date_formatter.dart';
import 'package:algora/core/widgets/empty_state_view.dart';
import 'package:algora/core/widgets/loading_state_view.dart';
import 'package:algora/core/widgets/user_avatar.dart';
import 'package:algora/features/chat/presentation/screens/conversation_screen.dart';
import 'package:algora/features/inbox/data/models/conversation_model.dart';
import 'package:algora/features/inbox/presentation/providers/inbox_provider.dart';

class UnifiedInboxScreen extends ConsumerStatefulWidget {
  const UnifiedInboxScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UnifiedInboxScreen> createState() => _UnifiedInboxScreenState();
}

class _UnifiedInboxScreenState extends ConsumerState<UnifiedInboxScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editNickname(ConversationModel conv) async {
    final controller = TextEditingController(text: conv.nickname ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nickname'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Marketing, Designer — optional'),
        ),
        actions: [
          if (conv.nickname != null)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(''),
              child: const Text('Remove', style: TextStyle(color: AppColors.error)),
            ),
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await ref.read(inboxProvider.notifier).updateNickname(conv.id, result.isEmpty ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inboxState = ref.watch(inboxProvider);
    final conversations = inboxState.filteredConversations;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'ALGORA',
                      style: AppTypography.wordmark(color: isDark ? AppColors.textPrimaryDark : AppColors.authHeading, fontSize: 26),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: isDark ? AppColors.textPrimaryDark : const Color(0xFF334155)),
                    onPressed: () => ref.read(inboxProvider.notifier).loadConversations(),
                    tooltip: 'Refresh messages',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (q) => ref.read(inboxProvider.notifier).setSearchQuery(q),
                style: TextStyle(color: isDark ? AppColors.textPrimaryDark : const Color(0xFF334155)),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: isDark ? AppColors.textMutedDark : Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search_rounded, color: isDark ? AppColors.textMutedDark : Colors.grey.shade400),
                  filled: true,
                  fillColor: isDark ? AppColors.darkInputBg : const Color(0xFFF3F5F9),
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: InboxFilterType.values.map((filter) {
                  final isSelected = inboxState.currentFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => ref.read(inboxProvider.notifier).setFilter(filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.success : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.success : (isDark ? AppColors.darkCardBorder : const Color(0xFFCBD5E1)),
                          ),
                        ),
                        child: Text(
                          filter.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? AppColors.textSecondaryDark : const Color(0xFF475569)),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: inboxState.isLoading
                  ? const LoadingStateView(message: 'Loading conversations...')
                  : conversations.isEmpty
                      ? EmptyStateView(
                          title: 'No Conversations Found',
                          description: inboxState.searchQuery.isNotEmpty
                              ? 'No customer messages match "${inboxState.searchQuery}".'
                              : 'No customer messages in this filter category.',
                          icon: Icons.inbox_rounded,
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref.read(inboxProvider.notifier).loadConversations(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                            itemCount: conversations.length,
                            separatorBuilder: (_, __) => Divider(height: 26, color: isDark ? AppColors.darkCardBorder : Colors.grey.shade200),
                            itemBuilder: (context, index) => _buildConversationItem(context, conversations[index], isDark),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationItem(BuildContext context, ConversationModel conv, bool isDark) {
    final hasUnread = !conv.isRead || conv.unreadCount > 0;

    // No inline "add nickname" prompt cluttering the row - swipe a contact
    // left to reveal the option instead. An already-set nickname still
    // shows as a plain pill (that's just displaying data, not an
    // affordance), and the same swipe action also edits/removes it.
    return Slidable(
      key: ValueKey(conv.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.28,
        children: [
          SlidableAction(
            onPressed: (_) => _editNickname(conv),
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            icon: Icons.label_outline_rounded,
            label: 'Nickname',
            borderRadius: BorderRadius.circular(14),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ConversationScreen(initialConversation: conv)),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(name: conv.customer.fullName, channel: conv.channel, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (conv.nickname != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        conv.nickname!,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  Text(
                    conv.customer.fullName,
                    style: TextStyle(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.authHeading,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conv.latestMessageText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormatter.formatMessageTime(conv.latestMessageTimestamp),
                  style: TextStyle(
                    color: hasUnread ? AppColors.success : (isDark ? AppColors.textMutedDark : Colors.grey.shade400),
                    fontSize: 12,
                    fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (conv.unreadCount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    child: Text(
                      conv.unreadCount > 9 ? '9+' : '${conv.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
