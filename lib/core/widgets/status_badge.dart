// ─────────────────────────────────────────────────────────────────────────────
// status_badge.dart — Color-coded status badges (Arabic labels)
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marriage_agency_app/core/sync/sync_status.dart';
import 'package:marriage_agency_app/core/theme/app_theme.dart';

class ProcessingStatusBadge extends StatelessWidget {
  const ProcessingStatusBadge(this.status, {super.key});
  final ProcessingStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      ProcessingStatus.missingFiles => (AppTheme.statusMissingFiles, Icons.warning_amber_rounded),
      ProcessingStatus.inProgress => (AppTheme.statusInProgress, Icons.hourglass_top_rounded),
      ProcessingStatus.ready => (AppTheme.statusReady, Icons.check_circle_outline_rounded),
      ProcessingStatus.completed => (AppTheme.statusCompleted, Icons.verified_rounded),
    };
    return _Badge(label: status.label, color: color, icon: icon);
  }
}

class AgencyStatusBadge extends StatelessWidget {
  const AgencyStatusBadge(this.status, {super.key});
  final AgencyStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      AgencyStatus.draft => (Colors.grey, Icons.edit_outlined),
      AgencyStatus.pendingSignatures => (AppTheme.statusInProgress, Icons.draw_outlined),
      AgencyStatus.inProgress => (AppTheme.statusInProgress, Icons.hourglass_top_rounded),
      AgencyStatus.ready => (AppTheme.statusReady, Icons.check_circle_outline_rounded),
      AgencyStatus.completed => (AppTheme.statusCompleted, Icons.verified_rounded),
    };
    return _Badge(label: status.label, color: color, icon: icon);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
