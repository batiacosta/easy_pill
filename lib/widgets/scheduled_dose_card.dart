import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../models/scheduled_dose.dart';
import '../utilities/app_colors.dart';

class ScheduledDoseCard extends StatelessWidget {
  final ScheduledDose dose;
  final VoidCallback onMorePressed;
  final Color Function(ScheduleType) getScheduleTypeColor;

  const ScheduledDoseCard({
    super.key,
    required this.dose,
    required this.onMorePressed,
    required this.getScheduleTypeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.surfaceAlt,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Time badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: getScheduleTypeColor(dose.medication.scheduleType),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    dose.formatDate(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dose.formatTimeWithPeriod(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Medication info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dose.medication.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dose.medication.dosing != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      dose.medication.dosing!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Options menu
            IconButton(
              icon: const Icon(Icons.more_vert,
                  color: AppColors.textSecondary, size: 24),
              onPressed: onMorePressed,
            ),
          ],
        ),
      ),
    );
  }
}
