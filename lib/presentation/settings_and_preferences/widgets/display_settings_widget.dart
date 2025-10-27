import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DisplaySettingsWidget extends StatefulWidget {
  final String currentTheme;
  final double textSize;
  final double defaultZoom;
  final Function(String) onThemeChanged;
  final Function(double) onTextSizeChanged;
  final Function(double) onZoomChanged;

  const DisplaySettingsWidget({
    Key? key,
    required this.currentTheme,
    required this.textSize,
    required this.defaultZoom,
    required this.onThemeChanged,
    required this.onTextSizeChanged,
    required this.onZoomChanged,
  }) : super(key: key);

  @override
  State<DisplaySettingsWidget> createState() => _DisplaySettingsWidgetState();
}

class _DisplaySettingsWidgetState extends State<DisplaySettingsWidget> {
  @override
  Widget build(BuildContext context) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: 'display_settings',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Display',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Divider(
          color: Theme.of(context).dividerColor,
          height: 1,
          indent: 4.w,
          endIndent: 4.w,
        ),
        _buildThemeSelector(),
        _buildTextSizeSlider(),
        _buildZoomLevelSelector(),
      ],
    ),
  );
}

Widget _buildThemeSelector() {
  return Padding(
    padding: EdgeInsets.all(4.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildThemeOption('Light', 'light_mode'),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildThemeOption('Dark', 'dark_mode'),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildThemeOption('System', 'brightness_auto'),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildThemeOption(String label, String iconName) {
  final bool isSelected =
      widget.currentTheme.toLowerCase() == label.toLowerCase();

  return GestureDetector(
    onTap: () => widget.onThemeChanged(label.toLowerCase()),
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 24,
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildTextSizeSlider() {
  return Padding(
    padding: EdgeInsets.all(4.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Text Size',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${widget.textSize.toInt()}sp',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            inactiveTrackColor: Theme.of(context).colorScheme.outline,
            trackHeight: 4,
          ),
          child: Slider(
            value: widget.textSize,
            min: 10,
            max: 20,
            divisions: 10,
            onChanged: widget.onTextSizeChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Small',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Large',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildZoomLevelSelector() {
  return Padding(
    padding: EdgeInsets.all(4.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Default Zoom Level',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(widget.defaultZoom * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            inactiveTrackColor: Theme.of(context).colorScheme.outline,
            trackHeight: 4,
          ),
          child: Slider(
            value: widget.defaultZoom,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            onChanged: widget.onZoomChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '50%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '200%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    ),
  );
}

}
