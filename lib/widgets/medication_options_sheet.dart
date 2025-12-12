import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../extensions/localization_extension.dart';
import '../models/medication.dart';
import '../providers/medication_provider.dart';

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
      color: const Color(0xFF1E1E1E),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            medication.name,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
              provider.recordDoseTaken(medication.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${medication.name} marked as taken'),
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
              onEdit();
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
              onRemove();
            },
          ),
        ],
      ),
    );
  }
}
