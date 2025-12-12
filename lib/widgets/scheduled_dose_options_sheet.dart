import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../extensions/localization_extension.dart';
import '../models/scheduled_dose.dart';
import '../providers/medication_provider.dart';
import '../utilities/app_colors.dart';

class ScheduledDoseOptionsSheet extends StatelessWidget {
  final ScheduledDose dose;
  final void Function() onEditMedication;
  final void Function() onRemoveMedication;
  final void Function() onSkipDose;

  const ScheduledDoseOptionsSheet({
    super.key,
    required this.dose,
    required this.onEditMedication,
    required this.onRemoveMedication,
    required this.onSkipDose,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MedicationProvider>();
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dose.medication.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dose.formatDateTime(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          // Mark as Taken
          ListTile(
            leading: const Icon(Icons.check_circle_outline, color: AppColors.primary),
            title: Text(
              context.trStatic('mark_as_taken'),
              style: const TextStyle(color: AppColors.primary),
            ),
            onTap: () {
              Navigator.pop(context);
              provider.recordDoseTaken(dose.medication.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${dose.medication.name} marked as taken'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          const Divider(color: AppColors.surfaceAlt, height: 8),
          // Edit Medication
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: AppColors.secondary),
            title: const Text(
              'Edit Medication',
              style: TextStyle(color: AppColors.secondary),
            ),
            onTap: () {
              Navigator.pop(context);
              onEditMedication();
            },
          ),
          const Divider(color: AppColors.surfaceAlt, height: 8),
          // Skip Dose
          ListTile(
            leading: const Icon(Icons.skip_next, color: AppColors.secondary),
            title: Text(
              context.trStatic('skip_dose'),
              style: const TextStyle(color: AppColors.secondary),
            ),
            onTap: () {
              Navigator.pop(context);
              onSkipDose();
            },
          ),
          const Divider(color: AppColors.surfaceAlt, height: 8),
          // Remove Medication
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.danger),
            title: Text(
              context.trStatic('remove_medication'),
              style: const TextStyle(color: AppColors.danger),
            ),
            onTap: () {
              Navigator.pop(context);
              onRemoveMedication();
            },
          ),
        ],
      ),
    );
  }
}
