import 'dart:ui' as ui show TextDirection;
// ─────────────────────────────────────────────────────────────────────────────
// delivery_card.dart — Delivery toggle cards for husband/wife copies
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:marriage_agency_app/features/marriages/data/models/marriage_model.dart';
import 'package:marriage_agency_app/core/theme/app_theme.dart';

class DeliveryCard extends StatefulWidget {
  const DeliveryCard({
    super.key,
    required this.title,
    required this.delivery,
    required this.onUpdate,
    this.icon = Icons.person_outlined,
  });

  final String title;
  final DeliveryInfo delivery;
  final ValueChanged<DeliveryInfo> onUpdate;
  final IconData icon;

  @override
  State<DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends State<DeliveryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  final _receiverController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    if (widget.delivery.isDelivered) _controller.value = 1.0;
    _receiverController.text = widget.delivery.receiverName ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    _receiverController.dispose();
    super.dispose();
  }

  void _toggle(bool value) {
    if (value) {
      _controller.forward();
      _showReceiverDialog();
    } else {
      _controller.reverse();
      widget.onUpdate(const DeliveryInfo(isDelivered: false));
    }
  }

  void _showReceiverDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Text('تسليم النسخة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('أدخل اسم المستلم (اختياري)', style: GoogleFonts.cairo()),
              const SizedBox(height: 12),
              TextField(
                controller: _receiverController,
                decoration: InputDecoration(
                  labelText: 'اسم المستلم',
                  hintText: 'اسم من استلم النسخة',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                style: GoogleFonts.cairo(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _controller.reverse();
              },
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onUpdate(DeliveryInfo(
                  isDelivered: true,
                  deliveredAt: DateTime.now(),
                  receiverName: _receiverController.text.trim().isEmpty
                      ? null
                      : _receiverController.text.trim(),
                ));
              },
              child: Text('تأكيد التسليم', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDelivered = widget.delivery.isDelivered;
    final color = isDelivered ? AppTheme.statusCompleted : Colors.black;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(
          color: isDelivered
              ? AppTheme.statusCompleted.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.2),
          width: isDelivered ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDelivered
                ? AppTheme.statusCompleted.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Animated check circle
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Icon(
                    isDelivered ? Icons.check_circle_rounded : widget.icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (isDelivered && widget.delivery.deliveredAt != null)
                        Text(
                          'تم التسليم: ${DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(widget.delivery.deliveredAt!)}',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppTheme.statusCompleted,
                          ),
                        ),
                      if (isDelivered && widget.delivery.receiverName != null)
                        Text(
                          'المستلم: ${widget.delivery.receiverName}',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: isDelivered,
                  onChanged: _toggle,
                  activeColor: AppTheme.statusCompleted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
