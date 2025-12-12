import 'package:flutter/material.dart';
import '../models/medication_item.dart';
import '../utilities/app_colors.dart';
import 'medication_card.dart';

class CollapsibleMedicationSection extends StatefulWidget {
  final String title;
  final List<MedicationItem> medications;
  final Function(MedicationItem) onMarkAsTaken;
  final Function(BuildContext, String, String, String, VoidCallback) onShowDeleteDialog;
  final bool showMarkButton;
  final bool showMarkInMenu;

  const CollapsibleMedicationSection({
    super.key,
    required this.title,
    required this.medications,
    required this.onMarkAsTaken,
    required this.onShowDeleteDialog,
    this.showMarkButton = true,
    this.showMarkInMenu = false,
  });

  @override
  State<CollapsibleMedicationSection> createState() => _CollapsibleMedicationSectionState();
}

class _CollapsibleMedicationSectionState extends State<CollapsibleMedicationSection> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.primary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Column(
            children: widget.medications
                .map((med) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MedicationCard(
                        medication: med,
                        onMarkAsTaken: () => widget.onMarkAsTaken(med),
                        onShowDeleteDialog: widget.onShowDeleteDialog,
                        showMarkButton: widget.showMarkButton,
                        showMarkInMenu: widget.showMarkInMenu,
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }
}
