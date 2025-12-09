import 'package:flutter/material.dart';
import '../models/medication_item.dart';
import 'medication_card.dart';

class MedicationSection extends StatelessWidget {
  final String title;
  final List<MedicationItem> medications;
  final Function(MedicationItem) onMarkAsTaken;
  final Function(BuildContext, String, String, String, VoidCallback) onShowDeleteDialog;
  final bool showMarkButton;
  final bool showMarkInMenu;

  const MedicationSection({
    super.key,
    required this.title,
    required this.medications,
    required this.onMarkAsTaken,
    required this.onShowDeleteDialog,
    this.showMarkButton = true,
    this.showMarkInMenu = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Column(
          children: medications
              .map((med) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MedicationCard(
                      medication: med,
                      onMarkAsTaken: () => onMarkAsTaken(med),
                      onShowDeleteDialog: onShowDeleteDialog,
                      showMarkButton: showMarkButton,
                      showMarkInMenu: showMarkInMenu,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
