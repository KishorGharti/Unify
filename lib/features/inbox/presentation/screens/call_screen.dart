import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unify/core/theme/app_colors.dart';
import 'package:unify/core/theme/app_typography.dart';
import 'package:unify/core/widgets/user_avatar.dart';
import 'package:unify/features/inbox/data/models/conversation_model.dart';
import 'package:unify/features/inbox/presentation/providers/inbox_provider.dart';

enum _CallDirection { outgoing, incomingAnswered, incomingMissed }

enum _CallKind { voice, video }

class _CallLogEntry {
  final ConversationModel? conversation;
  final String? rawNumber;
  final _CallDirection direction;
  final _CallKind kind;
  final String whenLabel;

  const _CallLogEntry({
    this.conversation,
    this.rawNumber,
    required this.direction,
    required this.kind,
    required this.whenLabel,
  });
}

class CallScreen extends ConsumerWidget {
  const CallScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conversations = ref.watch(inboxProvider).allConversations;
    final recentContacts = conversations.take(6).toList();
    final entries = _buildSampleLog(conversations);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Call',
                    style: AppTypography.heading1(color: isDark ? AppColors.textPrimaryDark : AppColors.authHeading).copyWith(fontSize: 26),
                  ),
                ],
              ),
            ),
            if (recentContacts.isNotEmpty)
              SizedBox(
                height: 78,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: recentContacts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final conv = recentContacts[i];
                    return UserAvatar(name: conv.customer.fullName, channel: conv.channel, size: 58);
                  },
                ),
              ),
            Divider(height: 24, color: isDark ? AppColors.darkCardBorder : const Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Recent', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                itemCount: entries.length,
                separatorBuilder: (_, __) => Divider(height: 26, color: isDark ? AppColors.darkCardBorder : Colors.grey.shade200),
                itemBuilder: (context, i) => _buildCallRow(entries[i], isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallRow(_CallLogEntry entry, bool isDark) {
    final isMissed = entry.direction == _CallDirection.incomingMissed;
    final color = isMissed ? AppColors.error : (isDark ? AppColors.textPrimaryDark : AppColors.authHeading);
    final name = entry.conversation?.customer.fullName ?? entry.rawNumber ?? 'Unknown';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        entry.conversation != null
            ? UserAvatar(name: entry.conversation!.customer.fullName, channel: entry.conversation!.channel, size: 52)
            : CircleAvatar(
                radius: 26,
                backgroundColor: isDark ? AppColors.darkCardBorder : const Color(0xFFE2E8F0),
                child: const Icon(Icons.person_outline, color: Colors.white),
              ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.conversation?.nickname != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    entry.conversation!.nickname!,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              Text(name, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    entry.direction == _CallDirection.outgoing ? Icons.north_east_rounded : Icons.south_west_rounded,
                    size: 14,
                    color: isMissed ? AppColors.error : AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(entry.whenLabel, style: TextStyle(color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600, fontSize: 13.5)),
                ],
              ),
            ],
          ),
        ),
        Icon(
          entry.kind == _CallKind.video ? Icons.videocam_outlined : Icons.call_outlined,
          color: isDark ? AppColors.textMutedDark : Colors.grey.shade500,
        ),
      ],
    );
  }

  List<_CallLogEntry> _buildSampleLog(List<ConversationModel> conversations) {
    if (conversations.isEmpty) return const [];
    final c = conversations;
    final entries = <_CallLogEntry>[];

    entries.add(_CallLogEntry(conversation: c[0], direction: _CallDirection.outgoing, kind: _CallKind.video, whenLabel: '4 minute ago'));
    if (c.length > 1) {
      entries.add(_CallLogEntry(conversation: c[1], direction: _CallDirection.outgoing, kind: _CallKind.video, whenLabel: 'Today, 5:54 pm'));
    }
    entries.add(_CallLogEntry(conversation: c[0], direction: _CallDirection.incomingAnswered, kind: _CallKind.video, whenLabel: '4 minute ago'));

    entries.add(const _CallLogEntry(rawNumber: '+977-9866989166', direction: _CallDirection.incomingMissed, kind: _CallKind.voice, whenLabel: 'Today, 5:54 pm'));
    entries.add(_CallLogEntry(conversation: c[0], direction: _CallDirection.incomingMissed, kind: _CallKind.voice, whenLabel: '4 minute ago'));
    if (c.length > 1) {
      entries.add(_CallLogEntry(conversation: c[1], direction: _CallDirection.incomingAnswered, kind: _CallKind.video, whenLabel: 'Today, 5:54 pm'));
    }

    return entries;
  }
}
