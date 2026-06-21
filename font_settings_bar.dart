import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

/// Accessibility toolbar shown beneath the AppBar: lets the user
/// scale font size up/down and switch font family across the whole feed.
class FontSettingsBar extends StatelessWidget {
  const FontSettingsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.pureBlack,
        border: Border(bottom: BorderSide(color: AppColors.borderGrey, width: 0.6)),
      ),
      child: Row(
        children: [
          _FontSizeButton(
            icon: Icons.text_decrease,
            label: 'A-',
            onTap: settings.decreaseFont,
          ),
          const SizedBox(width: 8),
          _FontSizeButton(
            icon: Icons.text_increase,
            label: 'A+',
            onTap: settings.increaseFont,
          ),
          const SizedBox(width: 8),
          Text(
            '${(settings.fontScale * 100).round()}%',
            style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
          ),
          const Spacer(),
          _FontFamilyDropdown(settings: settings),
        ],
      ),
    );
  }
}

class _FontSizeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FontSizeButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardGrey,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _FontFamilyDropdown extends StatelessWidget {
  final SettingsProvider settings;
  const _FontFamilyDropdown({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.cardGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AppFontFamily>(
          value: settings.fontFamily,
          dropdownColor: AppColors.cardGrey,
          icon: const Icon(Icons.expand_more, color: AppColors.secondaryText, size: 18),
          style: const TextStyle(color: AppColors.white, fontSize: 13),
          underline: const SizedBox(),
          items: AppFontFamily.values.map((font) {
            return DropdownMenuItem(
              value: font,
              child: Text(font.label, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) settings.setFontFamily(value);
          },
        ),
      ),
    );
  }
}
