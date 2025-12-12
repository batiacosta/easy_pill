import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../extensions/localization_extension.dart';
import '../models/scheduled_dose.dart';
import '../providers/medication_provider.dart';

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
      color: const Color(0xFF1E1E1E),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dose.medication.name,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dose.formatDateTime(),
            style: const TextStyle(
              color: Color(0xFF828282),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          // Mark as Taken
          ListTile(
            leading: const Icon(Icons.check_circle_outline, color: Color(0xFF9B51E0)),
            title: Text(
              context.trStatic('mark_as_taken'),
              style: const TextStyle(color: Color(0xFF9B51E0)),
            ),
            onTap: () {
              Navigator.pop(context);
              provider.recordDoseTaken(dose.medication.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${dose.medication.name} marked as taken'),
                  backgroundColor: const Color(0xFF9B51E0),
                ),
              );
            },
          ),
          const Divider(color: Color(0xFF2C2C2C), height: 8),
          // Edit Medication
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Color(0xFF2D9CDB)),
            title: const Text(
              'Edit Medication',
              style: TextStyle(color: Color(0xFF2D9CDB)),
            ),
            onTap: () {
              Navigator.pop(context);
              onEditMedication();
            },
          ),
          const Divider(color: Color(0xFF2C2C2C), height: 8),
          // Skip Dose
          ListTile(
            leading: const Icon(Icons.skip_next, color: Color(0xFF2D9CDB)),
            title: Text(
              context.trStatic('skip_dose'),
              style: const TextStyle(color: Color(0xFF2D9CDB)),
            ),
            onTap: () {
              Navigator.pop(context);
              onSkipDose();
            },
          ),
          const Divider(color: Color(0xFF2C2C2C), height: 8),
          // Remove Medication
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Color(0xFFEB5757)),
            title: Text(
              context.trStatic('remove_medication'),
              style: const TextStyle(color: Color(0xFFEB5757)),
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
