import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medication_item.dart';
import '../widgets/medication_section.dart';
import '../widgets/collapsible_medication_section.dart';
import '../widgets/add_medication_modal.dart' show AddMedicationModal, ScheduleType;
import '../extensions/localization_extension.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String greeting;
  late String currentDate;

  @override
  void initState() {
    super.initState();
    currentDate = DateFormat('MMMM d').format(DateTime.now());
    _initializeNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateGreeting();
  }

  Future<void> _initializeNotifications() async {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();
  }

  Future<void> _showAddMedicationModal() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddMedicationModal(),
    );

    if (result != null) {
      // Schedule notifications based on the result
      final notificationService = NotificationService();
      final int medicationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      switch (result['scheduleType']) {
        case ScheduleType.everyHours:
          await notificationService.scheduleEveryHours(
            id: medicationId,
            medicationName: result['name'],
            hours: result['interval'],
            dosing: result['dosing'],
            totalDoses: result['pillCount'],
          );
          break;
        case ScheduleType.fixedHours:
          await notificationService.scheduleFixedHours(
            id: medicationId,
            medicationName: result['name'],
            times: result['fixedTimes'],
            dosing: result['dosing'],
            totalDoses: result['pillCount'],
          );
          break;
        case ScheduleType.everyDays:
          await notificationService.scheduleEveryDays(
            id: medicationId,
            medicationName: result['name'],
            days: result['interval'],
            times: result['fixedTimes'],
            dosing: result['dosing'],
            totalDoses: result['pillCount'],
          );
          break;
      }

      if (mounted) {
        // Show pending notifications count for debugging
        final pending = await NotificationService().getPendingNotifications();
        debugPrint('Pending notifications: ${pending.length}');
        for (var notif in pending) {
          debugPrint('  - ID: ${notif.id}, Title: ${notif.title}, Body: ${notif.body}');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result['name']} added successfully (${pending.length} reminders scheduled)',
            ),
            backgroundColor: const Color(0xFF9B51E0),
          ),
        );
      }
    }
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      greeting = context.tr('good_morning');
    } else if (hour < 18) {
      greeting = context.tr('good_afternoon');
    } else {
      greeting = context.tr('good_evening');
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    String medicationName,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Color(0xFF828282),
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                context.tr('cancel'),
                style: const TextStyle(
                  color: Color(0xFF9B51E0),
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text(
                context.tr('delete'),
                style: const TextStyle(
                  color: Color(0xFFEB5757),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Container(
                    color: const Color(0xFF121212),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting and Notification
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$greeting, Alex',
                              style: const TextStyle(
                                color: Color(0xFFE0E0E0),
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined,
                                  color: Color(0xFFE0E0E0), size: 28),
                              onPressed: () async {
                                // Test notification - will fire in 5 seconds
                                await NotificationService().scheduleTestNotification();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Test notification scheduled for 5 seconds from now'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      // Date
                      Text(
                        '${context.tr('today')}, $currentDate',
                        style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Today - Pending Section (medications that need to be taken)
                      MedicationSection(
                        title: context.tr('today_pending'),
                        medications: [
                          MedicationItem(
                            name: 'Ibuprofen 200mg',
                            time: 'Next dose: 8:00 AM',
                            icon: Icons.medication,
                            color: const Color(0xFFEB5757),
                            bgColor: const Color(0x1AEB5757),
                            isTaken: false,
                          ),
                          MedicationItem(
                            name: 'Vitamin D 1000IU',
                            time: 'Taken at 8:05 AM',
                            icon: Icons.medication,
                            color: const Color(0xFF828282),
                            bgColor: const Color(0x1A828282),
                            isTaken: true,
                          ),
                        ],
                        onMarkAsTaken: (medication) {
                          setState(() {
                            medication.isTaken = true;
                          });
                        },
                        onShowDeleteDialog: _showDeleteDialog,
                        showMarkButton: true,
                        showMarkInMenu: true,
                      ),
                      // Today - Scheduled Section (medications scheduled for later today)
                      MedicationSection(
                        title: context.tr('today_scheduled'),
                        medications: [
                          MedicationItem(
                            name: 'Allergy Relief',
                            time: 'Next dose: 1:00 PM',
                            icon: Icons.healing,
                            color: const Color(0xFF2D9CDB),
                            bgColor: const Color(0x1A2D9CDB),
                            isTaken: false,
                          ),
                          MedicationItem(
                            name: 'Magnesium 400mg',
                            time: 'Next dose: 9:00 PM',
                            icon: Icons.water_drop,
                            color: const Color(0xFF9B51E0),
                            bgColor: const Color(0x1A9B51E0),
                            isTaken: false,
                          ),
                        ],
                        onMarkAsTaken: (medication) {
                          setState(() {
                            medication.isTaken = true;
                          });
                        },
                        onShowDeleteDialog: _showDeleteDialog,
                        showMarkButton: false,
                        showMarkInMenu: true,
                      ),
                      // Tomorrow - Collapsible Section
                      CollapsibleMedicationSection(
                        title: context.tr('tomorrow'),
                        medications: [
                          MedicationItem(
                            name: 'Aspirin 500mg',
                            time: '8:00 AM',
                            icon: Icons.medication,
                            color: const Color(0xFFEB5757),
                            bgColor: const Color(0x1AEB5757),
                            isTaken: false,
                          ),
                          MedicationItem(
                            name: 'Vitamin C 1000mg',
                            time: '12:00 PM',
                            icon: Icons.healing,
                            color: const Color(0xFF2D9CDB),
                            bgColor: const Color(0x1A2D9CDB),
                            isTaken: false,
                          ),
                        ],
                        onMarkAsTaken: (medication) {
                          setState(() {
                            medication.isTaken = true;
                          });
                        },
                        onShowDeleteDialog: _showDeleteDialog,
                        showMarkButton: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
          // Floating Action Button
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton.extended(
              onPressed: _showAddMedicationModal,
              elevation: 8,
              backgroundColor: const Color(0xFF9B51E0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              icon: const Icon(Icons.add, size: 32),
              label: const SizedBox.shrink(),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

