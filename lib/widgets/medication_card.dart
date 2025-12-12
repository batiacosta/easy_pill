import 'package:flutter/material.dart';
import '../models/medication_item.dart';
import '../extensions/localization_extension.dart';
import '../utilities/app_colors.dart';

class MedicationCard extends StatefulWidget {
  final MedicationItem medication;
  final VoidCallback onMarkAsTaken;
  final Function(BuildContext, String, String, String, VoidCallback) onShowDeleteDialog;
  final bool showMarkButton;
  final bool showMarkInMenu;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.onMarkAsTaken,
    required this.onShowDeleteDialog,
    this.showMarkButton = true,
    this.showMarkInMenu = false,
  });

  @override
  State<MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<MedicationCard> {
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
      child: Opacity(
        opacity: widget.medication.isTaken ? 0.5 : 1.0,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon and Text
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: widget.medication.bgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            widget.medication.icon,
                            color: widget.medication.color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.medication.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.medication.time,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // More Options Button
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.textSecondary, size: 24),
                    color: AppColors.surfaceAlt2,
                    onSelected: (value) {
                      if (value == 'mark_taken') {
                        widget.onMarkAsTaken();
                      } else if (value == 'delete') {
                        widget.onShowDeleteDialog(
                          context,
                          widget.medication.name,
                          'Skip Dose',
                          'Are you sure you want to skip this scheduled dose?',
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Skipped ${widget.medication.name}',
                                ),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          },
                        );
                      } else if (value == 'delete_all') {
                        widget.onShowDeleteDialog(
                          context,
                          widget.medication.name,
                          'Remove Medication',
                          'Remove all scheduled doses of ${widget.medication.name}? This action cannot be undone.',
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Removed all scheduled doses of ${widget.medication.name}',
                                ),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          },
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      final items = <PopupMenuItem<String>>[];
                      
                      if (widget.showMarkInMenu && !widget.medication.isTaken) {
                        items.add(
                          PopupMenuItem<String>(
                            value: 'mark_taken',
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: AppColors.textPrimary, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  context.tr('mark_as_taken'),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      items.addAll([
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline,
                                  color: AppColors.danger, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                context.tr('skip_dose'),
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete_all',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_sweep,
                                  color: AppColors.danger, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                context.tr('remove_medication'),
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]);
                      return items;
                    },
                  ),
                ],
              ),
            ),
            // Action Button
            if (widget.showMarkButton)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: widget.medication.isTaken
                      ? ElevatedButton.icon(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceAlt2,
                            disabledForegroundColor: AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle,
                              size: 20, color: AppColors.textSecondary),
                          label: Text(
                            context.tr('taken'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: widget.onMarkAsTaken,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.medication.color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            context.tr('mark_as_taken'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
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
