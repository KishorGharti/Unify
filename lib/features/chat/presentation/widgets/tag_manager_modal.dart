import 'package:flutter/material.dart';
import 'package:algora/core/theme/app_colors.dart';
import 'package:algora/core/theme/app_dimensions.dart';
import 'package:algora/core/theme/app_typography.dart';
import 'package:algora/core/widgets/algora_button.dart';

class TagManagerModal extends StatefulWidget {
  final List<String> currentTags;
  final ValueChanged<List<String>> onSaveTags;

  const TagManagerModal({
    Key? key,
    required this.currentTags,
    required this.onSaveTags,
  }) : super(key: key);

  @override
  State<TagManagerModal> createState() => _TagManagerModalState();
}

class _TagManagerModalState extends State<TagManagerModal> {
  late List<String> _selectedTags;
  final TextEditingController _customTagController = TextEditingController();

  static const List<String> availableTags = [
    'VIP',
    'High Intent',
    'Urgent',
    'B2B',
    'Wholesale',
    'Support',
    'Feedback',
    'Influencer',
    'Lead',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.currentTags);
  }

  @override
  void dispose() {
    _customTagController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _addCustomTag() {
    final tag = _customTagController.text.trim();
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
        _customTagController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkCardBorder,
                  borderRadius: AppDimensions.roundedFull,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Manage Conversation Tags',
              style: AppTypography.heading3(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 14),

            // Tag chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (_) => _toggleTag(tag),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Add custom tag row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customTagController,
                    decoration: InputDecoration(
                      hintText: 'New custom tag...',
                      hintStyle: AppTypography.caption(color: AppColors.textMutedDark),
                      filled: true,
                      fillColor: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: AppDimensions.roundedMd,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                  onPressed: _addCustomTag,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Save button
            AlgoraButton(
              text: 'Save Tags',
              onPressed: () {
                widget.onSaveTags(_selectedTags);
                Navigator.of(context).pop();
              },
              variant: AlgoraButtonVariant.gradient,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
