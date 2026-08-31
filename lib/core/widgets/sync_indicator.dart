// ─────────────────────────────────────────────────────────────────────────────
// sync_indicator.dart — Animated sync status badge
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marriage_agency_app/core/sync/sync_repository.dart';
import 'package:marriage_agency_app/core/sync/sync_status.dart';
import 'package:marriage_agency_app/core/theme/app_theme.dart';

class SyncIndicator extends ConsumerStatefulWidget {
  const SyncIndicator({super.key});

  @override
  ConsumerState<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends ConsumerState<SyncIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(syncStateProvider);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => _buildBadge(state),
    );
  }

  Widget _buildBadge(SyncState state) {
    final (color, icon, label) = switch (state) {
      SyncState.synced => (AppTheme.syncSynced, Icons.cloud_done_rounded, 'متزامن'),
      SyncState.syncing => (AppTheme.syncSyncing, Icons.sync_rounded, 'جاري المزامنة'),
      SyncState.offline => (AppTheme.syncOffline, Icons.cloud_off_rounded, 'غير متصل'),
      SyncState.error => (AppTheme.syncError, Icons.error_outline_rounded, 'خطأ في المزامنة'),
    };

    final opacity = state == SyncState.syncing ? _pulse.value : 1.0;

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
