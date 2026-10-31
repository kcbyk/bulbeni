import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class FilterChipItem {
  final String key;
  final String label;

  const FilterChipItem({required this.key, required this.label});
}

class FilterChipsBar extends StatelessWidget {
  final List<FilterChipItem> items;
  final String selectedKey;
  final ValueChanged<String> onSelected;

  const FilterChipsBar({
    super.key,
    required this.items,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: items.map((item) {
          final isSelected = item.key == selectedKey;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => onSelected(item.key),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? AppColors.darkChipBackground : AppColors.lightChipBackground),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? const Color(0xFF28282C) : const Color(0xFFE2E2E6)),
                    width: 1,
                  ),
                ),
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? AppColors.darkChipTextUnselected : AppColors.lightChipTextUnselected),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
