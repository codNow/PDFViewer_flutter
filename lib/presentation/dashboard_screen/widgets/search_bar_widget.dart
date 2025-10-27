import 'package:flutter/material.dart';
import 'package:pdfviewer/presentation/dashboard_screen/widgets/asset_icon_widget.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearchChanged;
  final VoidCallback onFilterTap;

  const SearchBarWidget({
    Key? key,
    required this.onSearchChanged,
    required this.onFilterTap,
  }) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen to text changes and notify parent
    _searchController.addListener(() {
      widget.onSearchChanged(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onSearchChanged('');
    // Optional: unfocus keyboard
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      color: theme.colorScheme.surface,
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: SizedBox(
        height: 45,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            )
          ),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, child) {
              return TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: 'Search documents...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: AssetIconWidget(
                      iconName: 'search',
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  suffixIcon: value.text.isNotEmpty
                    ? IconButton(
                        onPressed: _clearSearch,
                        icon: CustomIconWidget(
                          iconName: 'clear',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 16,
                        ),
                        splashRadius: 20,
                      )
                    : IconButton(
                        onPressed: widget.onFilterTap,
                        icon: CustomIconWidget(
                          iconName: 'tune',
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                  filled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.h,
                  ),
                  isDense: true,
                ),
                style: theme.textTheme.bodyMedium,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) async {
                  // Add your search submission logic here
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
