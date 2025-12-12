import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../extensions/localization_extension.dart';
import '../models/medication.dart';
import '../providers/medication_provider.dart';
import '../utilities/app_colors.dart';

class MedicationOptionsSheet extends StatelessWidget {
  final Medication medication;
  final void Function() onEdit;
  final void Function() onRemove;

  const MedicationOptionsSheet({
    super.key,
    required this.medication,
    required this.onEdit,
    required this.onRemove,
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
            medication.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
              provider.recordDoseTaken(medication.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${medication.name} marked as taken'),
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
              onEdit();
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
              onRemove();
            },
          ),
        ],
      ),
    );
  }
}
