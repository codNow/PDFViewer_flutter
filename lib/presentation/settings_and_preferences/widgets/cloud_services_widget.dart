import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CloudServicesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> connectedAccounts;
  final String syncFrequency;
  final Function(String) onManageAccount;
  final Function(String) onSyncFrequencyChanged;

  const CloudServicesWidget({
    Key? key,
    required this.connectedAccounts,
    required this.syncFrequency,
    required this.onManageAccount,
    required this.onSyncFrequencyChanged,
  }) : super(key: key);

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
                  iconName: 'cloud',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Text(
                  'Cloud Services',
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
          _buildConnectedAccounts(context),
          _buildSyncFrequency(context),
        ],
      ),
    );
  }

  Widget _buildConnectedAccounts(BuildContext context) {
    return Column(
      children: connectedAccounts.map((account) {
        return _buildAccountItem(context, account);
      }).toList(),
    );
  }

  Widget _buildAccountItem(BuildContext context, Map<String, dynamic> account) {
    final String serviceName = account['service'] as String;
    final String email = account['email'] as String;
    final bool isConnected = account['connected'] as bool;
    final String iconName = _getServiceIcon(serviceName);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: _getServiceColor(context, serviceName).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: iconName,
                color: _getServiceColor(context, serviceName),
                size: 24,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  isConnected ? email : 'Not connected',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isConnected
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => onManageAccount(serviceName),
            child: Text(
              isConnected ? 'Manage' : 'Connect',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncFrequency(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sync Frequency',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildFrequencyOption(context, 'Manual'),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildFrequencyOption(context, 'Hourly'),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildFrequencyOption(context, 'Daily'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyOption(BuildContext context, String frequency) {
    final bool isSelected = syncFrequency == frequency;

    return GestureDetector(
      onTap: () => onSyncFrequencyChanged(frequency),
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
        child: Center(
          child: Text(
            frequency,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  String _getServiceIcon(String serviceName) {
    switch (serviceName.toLowerCase()) {
      case 'google drive':
        return 'cloud_upload';
      case 'onedrive':
        return 'cloud_sync';
      case 'dropbox':
        return 'cloud_download';
      default:
        return 'cloud';
    }
  }

  Color _getServiceColor(BuildContext context, String serviceName) {
    switch (serviceName.toLowerCase()) {
      case 'google drive':
        return const Color(0xFF4285F4);
      case 'onedrive':
        return const Color(0xFF0078D4);
      case 'dropbox':
        return const Color(0xFF0061FF);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
