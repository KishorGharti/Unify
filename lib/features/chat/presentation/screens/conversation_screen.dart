import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unify/core/constants/channel_config.dart';
import 'package:unify/core/theme/app_colors.dart';
import 'package:unify/core/theme/app_dimensions.dart';
import 'package:unify/core/theme/app_typography.dart';
import 'package:unify/core/widgets/channel_badge.dart';
import 'package:unify/core/widgets/status_badge.dart';
import 'package:unify/core/widgets/user_avatar.dart';
import 'package:unify/core/widgets/loading_state_view.dart';
import 'package:unify/features/auth/presentation/providers/auth_provider.dart';
import 'package:unify/features/customer/presentation/screens/customer_profile_screen.dart';
import 'package:unify/features/inbox/data/models/conversation_model.dart';
import 'package:unify/features/inbox/presentation/providers/inbox_provider.dart';
import 'package:unify/features/chat/data/models/message_model.dart';
import 'package:unify/features/chat/presentation/providers/chat_provider.dart';
import 'package:unify/features/chat/presentation/widgets/assignee_picker_modal.dart';
import 'package:unify/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:unify/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:unify/features/chat/presentation/widgets/quick_replies_modal.dart';
import 'package:unify/features/chat/presentation/widgets/tag_manager_modal.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final ConversationModel initialConversation;

  const ConversationScreen({Key? key, required this.initialConversation}) : super(key: key);

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  late ConversationModel _conversation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _conversation = widget.initialConversation;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inboxProvider.notifier).markAsRead(_conversation.id);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleResolveStatus() {
    final newStatus = _conversation.status == ConversationStatus.resolved
        ? ConversationStatus.open
        : ConversationStatus.resolved;

    setState(() {
      _conversation = _conversation.copyWith(status: newStatus);
    });
    ref.read(inboxProvider.notifier).updateStatus(_conversation.id, newStatus);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newStatus == ConversationStatus.resolved
            ? 'Conversation marked as Resolved'
            : 'Conversation reopened'),
        backgroundColor: newStatus == ConversationStatus.resolved
            ? AppColors.success
            : AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openAssigneePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AssigneePickerModal(
        currentAssigneeId: _conversation.assignedToMemberId,
        onSelectAssignee: (memberId, memberName) {
          setState(() {
            _conversation = _conversation.copyWith(
              assignedToMemberId: memberId,
              assignedToMemberName: memberName,
            );
          });
          ref.read(inboxProvider.notifier).updateAssignee(_conversation.id, memberId, memberName);
        },
      ),
    );
  }

  void _openTagManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TagManagerModal(
        currentTags: _conversation.tags,
        onSaveTags: (tags) {
          setState(() {
            _conversation = _conversation.copyWith(tags: tags);
          });
          ref.read(inboxProvider.notifier).updateTags(_conversation.id, tags);
        },
      ),
    );
  }

  void _openQuickReplies() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickRepliesModal(
        onSelectReply: (text) {
          final auth = ref.read(authStateProvider);
          final senderName = auth.user?.fullName ?? 'Support Agent';
          ref.read(chatProviderFamily(_conversation.id).notifier).sendMessage(
                text: text,
                channel: _conversation.channel,
                senderName: senderName,
              );
          Future.delayed(const Duration(milliseconds: 150), _scrollToBottom);
        },
      ),
    );
  }

  void _handleAttachment() {
    final sampleImages = [
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500',
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=500',
    ];
    final auth = ref.read(authStateProvider);
    final senderName = auth.user?.fullName ?? 'Support Agent';
    ref.read(chatProviderFamily(_conversation.id).notifier).sendImageAttachment(
          imageUrl: sampleImages.first,
          channel: _conversation.channel,
          senderName: senderName,
        );
    Future.delayed(const Duration(milliseconds: 150), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatState = ref.watch(chatProviderFamily(_conversation.id));
    final auth = ref.watch(authStateProvider);
    final isResolved = _conversation.status == ConversationStatus.resolved;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CustomerProfileScreen(customer: _conversation.customer),
              ),
            );
          },
          child: Row(
            children: [
              UserAvatar(
                name: _conversation.customer.fullName,
                channel: _conversation.channel,
                size: 38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _conversation.customer.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.subtitle1(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    Row(
                      children: [
                        ChannelBadge(channel: _conversation.channel, showLabel: false, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _conversation.customer.socialHandle,
                          style: AppTypography.caption(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [

          IconButton(
            icon: Icon(
              isResolved ? Icons.restart_alt_rounded : Icons.check_circle_outline_rounded,
              color: isResolved ? AppColors.primary : AppColors.success,
            ),
            tooltip: isResolved ? 'Reopen Conversation' : 'Resolve Conversation',
            onPressed: _toggleResolveStatus,
          ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'assign') {
                _openAssigneePicker();
              } else if (value == 'tags') {
                _openTagManager();
              } else if (value == 'profile') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CustomerProfileScreen(customer: _conversation.customer),
                  ),
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'assign',
                child: Row(
                  children: [
                    const Icon(Icons.person_add_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text('Assignee: ${_conversation.assignedToMemberName ?? "Unassigned"}'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'tags',
                child: Row(
                  children: [
                    Icon(Icons.label_outline_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Manage Tags'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_search_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('View Customer Profile'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder)),
            ),
            child: Row(
              children: [
                StatusBadge(status: _conversation.status),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _openAssigneePicker,
                  borderRadius: AppDimensions.roundedFull,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: AppDimensions.roundedFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          _conversation.assignedToMemberName ?? 'Unassigned',
                          style: AppTypography.badge(color: AppColors.primary).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _openTagManager,
                  child: Wrap(
                    spacing: 4,
                    children: [
                      ..._conversation.tags.take(2).map((t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.lightInputBg,
                              borderRadius: AppDimensions.roundedSm,
                            ),
                            child: Text(
                              '#$t',
                              style: AppTypography.caption(
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ).copyWith(fontSize: 10),
                            ),
                          )),
                      const Icon(Icons.edit_outlined, size: 14, color: AppColors.textMutedDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: chatState.isLoading
                ? const LoadingStateView(message: 'Loading conversation messages...')
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: chatState.messages.length + (chatState.isCustomerTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatState.messages.length && chatState.isCustomerTyping) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
                          child: Row(
                            children: [
                              Text(
                                '${_conversation.customer.fullName} is typing...',
                                style: AppTypography.caption(color: AppColors.primaryLight).copyWith(fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        );
                      }

                      final msg = chatState.messages[index];
                      final isPrevSame = index > 0 && chatState.messages[index - 1].senderType == msg.senderType;

                      return ChatBubble(
                        message: msg,
                        isPreviousSameSender: isPrevSame,
                      );
                    },
                  ),
          ),

          ChatInputBar(
            channel: _conversation.channel,
            inputMode: chatState.inputMode,
            onModeChanged: (mode) {
              ref.read(chatProviderFamily(_conversation.id).notifier).setInputMode(mode);
            },
            onSend: (text) async {
              final senderName = auth.user?.fullName ?? 'Support Agent';
              await ref.read(chatProviderFamily(_conversation.id).notifier).sendMessage(
                    text: text,
                    channel: _conversation.channel,
                    senderName: senderName,
                  );
              Future.delayed(const Duration(milliseconds: 150), _scrollToBottom);
            },
            onQuickRepliesTap: _openQuickReplies,
            onAttachmentTap: _handleAttachment,
          ),
        ],
      ),
    );
  }
}
