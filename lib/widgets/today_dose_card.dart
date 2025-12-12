import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medication.dart';
import '../models/scheduled_dose.dart';
import '../providers/medication_provider.dart';
import '../providers/localization_provider.dart';
import '../extensions/localization_extension.dart';
import '../utilities/app_colors.dart';

class TodayDoseCard extends StatelessWidget {
  final ScheduledDose dose;
  final MedicationProvider provider;
  final VoidCallback onMorePressed;
  final Color Function(ScheduleType) getScheduleTypeColor;

  const TodayDoseCard({
    super.key,
    required this.dose,
    required this.provider,
    required this.onMorePressed,
    required this.getScheduleTypeColor,
  });

  String _getScheduleDescription(Medication medication) {
    switch (medication.scheduleType) {
      case ScheduleType.everyHours:
        return 'Every ${medication.interval} hour${medication.interval! > 1 ? 's' : ''}';
      case ScheduleType.fixedHours:
        final times = medication.fixedTimes?.map((t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}').join(', ') ?? '';
        return 'Daily at $times';
      case ScheduleType.everyDays:
        final times = medication.fixedTimes?.map((t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}').join(', ') ?? '';
        return 'Every ${medication.interval} day${medication.interval! > 1 ? 's' : ''} at $times';
    }
  }

  @override
  Widget build(BuildContext context) {
    final medication = dose.medication;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: getScheduleTypeColor(medication.scheduleType).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (medication.dosing != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          medication.dosing!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  onPressed: onMorePressed,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Scheduled time
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: getScheduleTypeColor(medication.scheduleType),
                ),
                const SizedBox(width: 6),
                Text(
                  'Scheduled for ${dose.formatTimeWithPeriod()}',
                  style: TextStyle(
                    color: getScheduleTypeColor(medication.scheduleType),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Schedule description
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: getScheduleTypeColor(medication.scheduleType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getScheduleDescription(medication),
                style: TextStyle(
                  color: getScheduleTypeColor(medication.scheduleType),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Pills remaining
            if (medication.pillCount != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.medication, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('pills_remaining', {
                      'remaining': medication.pillCount.toString(),
                      'total': medication.pillCount.toString(),
                    }),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // Mark as Taken button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await provider.recordDoseTaken(medication.id!, scheduledTime: dose.scheduledTime);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.read<LocalizationProvider>().tr('taken')),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: Text(
                  context.tr('mark_as_taken'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
