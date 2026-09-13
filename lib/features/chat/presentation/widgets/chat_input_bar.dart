import 'package:flutter/material.dart';
import 'package:unify/core/constants/channel_config.dart';
import 'package:unify/core/theme/app_colors.dart';
import 'package:unify/core/theme/app_dimensions.dart';
import 'package:unify/core/theme/app_typography.dart';
import '../providers/chat_provider.dart';

class ChatInputBar extends StatefulWidget {
  final ChannelType channel;
  final ChatInputMode inputMode;
  final ValueChanged<ChatInputMode> onModeChanged;
  final Future<void> Function(String text) onSend;
  final VoidCallback onQuickRepliesTap;
  final VoidCallback onAttachmentTap;

  const ChatInputBar({
    Key? key,
    required this.channel,
    required this.inputMode,
    required this.onModeChanged,
    required this.onSend,
    required this.onQuickRepliesTap,
    required this.onAttachmentTap,
  }) : super(key: key);

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _controller.clear();
    await widget.onSend(text);
    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isInternalNote = widget.inputMode == ChatInputMode.internalNote;

    final barBg = isInternalNote
        ? (isDark ? AppColors.internalNoteBgDark : AppColors.internalNoteBg)
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final borderCol = isInternalNote
        ? (isDark ? AppColors.internalNoteBorderDark : AppColors.internalNoteBorder)
        : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder);

    return Container(
      decoration: BoxDecoration(
        color: barBg,
        border: Border(top: BorderSide(color: borderCol, width: 1.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Row(
              children: [
                InkWell(
                  onTap: () => widget.onModeChanged(ChatInputMode.customerReply),
                  borderRadius: AppDimensions.roundedFull,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: !isInternalNote
                          ? AppColors.primary.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: AppDimensions.roundedFull,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.channel.iconData,
                          size: 13,
                          color: !isInternalNote ? AppColors.primary : AppColors.textMutedDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reply on ${widget.channel.shortName}',
                          style: AppTypography.badge(
                            color: !isInternalNote ? AppColors.primary : AppColors.textMutedDark,
                          ).copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => widget.onModeChanged(ChatInputMode.internalNote),
                  borderRadius: AppDimensions.roundedFull,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isInternalNote
                          ? AppColors.warning.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: AppDimensions.roundedFull,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 13,
                          color: isInternalNote ? AppColors.warning : AppColors.textMutedDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Internal Note',
                          style: AppTypography.badge(
                            color: isInternalNote ? AppColors.warning : AppColors.textMutedDark,
                          ).copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.flash_on_rounded, size: 18, color: AppColors.primary),
                  tooltip: 'Quick Canned Responses',
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onQuickRepliesTap,
                ),
              ],
            ),
            const SizedBox(height: 6),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 22),
                  onPressed: widget.onAttachmentTap,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
                      borderRadius: AppDimensions.roundedLg,
                      border: Border.all(
                        color: isInternalNote
                            ? (isDark ? AppColors.internalNoteBorderDark : AppColors.internalNoteBorder)
                            : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _controller,
                      maxLines: 4,
                      minLines: 1,
                      style: AppTypography.body1(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      decoration: InputDecoration(
                        hintText: isInternalNote
                            ? 'Write private note for your team...'
                            : 'Type customer reply via ${widget.channel.shortName}...',
                        hintStyle: AppTypography.body2(
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isInternalNote ? AppColors.warning : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                    onPressed: _isSending ? null : _handleSend,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
