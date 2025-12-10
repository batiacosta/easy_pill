import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/medication.dart';
import '../models/scheduled_dose.dart';
import '../widgets/add_medication_modal.dart';
import '../extensions/localization_extension.dart';
import '../services/notification_service.dart';
import '../providers/medication_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String greeting;
  late String currentDate;

  // Color map for schedule types
  static const Map<ScheduleType, Color> scheduleTypeColors = {
    ScheduleType.everyHours: Color(0xFF9B51E0),  // Purple
    ScheduleType.fixedHours: Color(0xFF2D9CDB),  // Blue
    ScheduleType.everyDays: Color(0xFF27AE60),   // Green
  };

  Color getScheduleTypeColor(ScheduleType type) {
    return scheduleTypeColors[type] ?? const Color(0xFF9B51E0);
  }

  @override
  void initState() {
    super.initState();
    currentDate = DateFormat('MMMM d').format(DateTime.now());
    _initializeApp();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateGreeting();
  }

  Future<void> _initializeApp() async {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();
    
    // Load medications from database
    if (mounted) {
      await context.read<MedicationProvider>().loadMedications();
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

  Future<void> _showAddMedicationModal() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddMedicationModal(),
    );

    if (result != null && mounted) {
      try {
        // Create medication from result
        final medication = Medication(
          name: result['name'],
          dosing: result['dosing'],
          pillCount: result['pillCount'],
          description: result['description'],
          scheduleType: result['scheduleType'],
          interval: result['interval'],
          fixedTimes: result['fixedTimes'],
          startTime: result['startTime'],
          notificationId: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );

        // Add through provider
        await context.read<MedicationProvider>().addMedication(medication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result['name']} added successfully'),
              backgroundColor: const Color(0xFF9B51E0),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error adding medication: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error adding medication'),
              backgroundColor: Color(0xFFEB5757),
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditMedicationModal(
    BuildContext context,
    Medication medication,
    MedicationProvider provider,
  ) async {
    // Capture scaffold before showing modal
    final scaffold = ScaffoldMessenger.of(context);
    
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMedicationModal(medicationToEdit: medication),
    );

    if (result != null && mounted) {
      try {
        final medName = result['name'];
        
        // Update medication with result
        final updatedMedication = Medication(
          id: medication.id,
          name: result['name'],
          dosing: result['dosing'],
          pillCount: result['pillCount'],
          description: result['description'],
          scheduleType: result['scheduleType'],
          interval: result['interval'],
          fixedTimes: result['fixedTimes'],
          startTime: result['startTime'],
          notificationId: medication.notificationId,
          createdAt: medication.createdAt,
        );

        // Update through provider
        await provider.updateMedication(updatedMedication);

        scaffold.showSnackBar(
          SnackBar(
            content: Text('$medName updated successfully'),
            backgroundColor: const Color(0xFF9B51E0),
          ),
        );
      } catch (e) {
        debugPrint('Error updating medication: $e');
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Error updating medication'),
            backgroundColor: Color(0xFFEB5757),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          children: [
            Consumer<MedicationProvider>(
              builder: (context, medicationProvider, _) {
                if (medicationProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF9B51E0),
                    ),
                  );
                }

                final medications = medicationProvider.medications;
                final todayCounts = medicationProvider.todayDoseCounts;
                final scheduledDoses = medicationProvider.getScheduledDoses();

                final pendingToday = medications
                    .where((m) => _isDueToday(m) && (todayCounts[m.id] ?? 0) == 0)
                    .toList();
                final takenToday = medications
                    .where((m) => _isDueToday(m) && (todayCounts[m.id] ?? 0) > 0)
                    .toList();

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header
                      Container(
                        color: const Color(0xFF121212),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Greeting and Notification
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    icon: const Icon(
                                        Icons.notifications_outlined,
                                        color: Color(0xFFE0E0E0),
                                        size: 28),
                                    onPressed: () async {
                                      // Test notification
                                      await NotificationService()
                                          .scheduleTestNotification();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Test notification scheduled for 5 seconds from now'),
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
                            if (medications.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.medication,
                                        size: 64,
                                        color: Color(0xFF828282),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No medications yet',
                                        style: TextStyle(
                                          color: Color(0xFF828282),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Tap the + button to add your first medication',
                                        style: TextStyle(
                                          color: Color(0xFF828282),
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: [
                                  // Pending today
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Today',
                                      style: const TextStyle(
                                        color: Color(0xFFE0E0E0),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (pendingToday.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E1E1E),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF2C2C2C),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        'All caught up for today!',
                                        style: TextStyle(
                                          color: Color(0xFF828282),
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  else
                                    for (final med in pendingToday)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _buildMedicationCard(
                                          context,
                                          med,
                                          medicationProvider,
                                          takenToday: false,
                                          dueToday: true,
                                        ),
                                      ),

                                  const SizedBox(height: 16),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Taken Today',
                                      style: const TextStyle(
                                        color: Color(0xFFE0E0E0),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (takenToday.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E1E1E),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF2C2C2C),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        'Nothing marked as taken yet.',
                                        style: TextStyle(
                                          color: Color(0xFF828282),
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  else
                                    for (final med in takenToday)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _buildMedicationCard(
                                          context,
                                          med,
                                          medicationProvider,
                                          takenToday: true,
                                          dueToday: true,
                                        ),
                                      ),

                                  const SizedBox(height: 16),
                                  // Scheduled section
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Scheduled',
                                      style: const TextStyle(
                                        color: Color(0xFFE0E0E0),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (scheduledDoses.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E1E1E),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF2C2C2C),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        'No scheduled doses.',
                                        style: TextStyle(
                                          color: Color(0xFF828282),
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  else
                                    for (final dose in scheduledDoses)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _buildScheduledDoseCard(
                                          context,
                                          dose,
                                          medicationProvider,
                                        ),
                                      ),
                                ],
                              ),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
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

  Widget _buildMedicationCard(
    BuildContext context,
    Medication medication,
    MedicationProvider provider,
    {required bool takenToday, required bool dueToday}
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2C2C2C),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (medication.dosing != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          medication.dosing!,
                          style: const TextStyle(
                            color: Color(0xFF828282),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: Color(0xFF828282), size: 24),
                  onPressed: () => _showMedicationOptions(
                    context,
                    medication,
                    provider,
                  ),
                ),
              ],
            ),
            if (medication.description != null) ...[
              const SizedBox(height: 8),
              Text(
                medication.description!,
                style: const TextStyle(
                  color: Color(0xFF828282),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            // Schedule info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Color(0xFF9B51E0), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getScheduleText(medication),
                      style: const TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (!dueToday || takenToday)
                    ? null
                    : () => provider.recordDoseTaken(medication.id!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: takenToday
                      ? const Color(0xFF2D9CDB)
                      : getScheduleTypeColor(medication.scheduleType),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF2C2C2C),
                  disabledForegroundColor: const Color(0xFF828282),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(
                  takenToday
                      ? Icons.check_circle
                      : dueToday
                          ? Icons.check_circle_outline
                          : Icons.lock_clock,
                  size: 20,
                ),
                label: Text(
                  takenToday
                      ? 'Taken today'
                      : dueToday
                          ? context.tr('mark_as_taken')
                          : 'Not due today',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getScheduleText(Medication medication) {
    switch (medication.scheduleType) {
      case ScheduleType.everyHours:
        return 'Every ${medication.interval} hours';
      case ScheduleType.fixedHours:
        final times = medication.fixedTimes
                ?.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
                .join(', ') ??
            '';
        return 'Daily at $times';
      case ScheduleType.everyDays:
        final times = medication.fixedTimes
                ?.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
                .join(', ') ??
            '';
        return 'Every ${medication.interval} days at $times';
    }
  }

  bool _isDueToday(Medication medication) {
    switch (medication.scheduleType) {
      case ScheduleType.everyHours:
        return true;
      case ScheduleType.fixedHours:
        return true;
      case ScheduleType.everyDays:
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final start = DateTime(medication.createdAt.year, medication.createdAt.month, medication.createdAt.day);
        final diffDays = today.difference(start).inDays;
        final interval = medication.interval ?? 1;
        return diffDays >= 0 && diffDays % interval == 0;
    }
  }

  void _showMedicationOptions(
    BuildContext context,
    Medication medication,
    MedicationProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
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
                _showEditMedicationModal(context, medication, provider);
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
                _showSkipDoseDialog(context, medication, scheduledTime: null);
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
                final scaffold = ScaffoldMessenger.of(context);
                final medName = medication.name;
                Navigator.pop(context);
                _showDeleteDialog(
                  context,
                  medication.name,
                  context.trStatic('remove_medication'),
                  'Remove ${medication.name} and all its scheduled doses?',
                  () {
                    provider.deleteMedication(medication.id!);
                    scaffold.showSnackBar(
                      SnackBar(
                        content: Text('$medName removed'),
                        backgroundColor: const Color(0xFFEB5757),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSkipDoseDialog(BuildContext context, Medication medication, {DateTime? scheduledTime}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            context.trStatic('skip_dose'),
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Skip this dose of ${medication.name}?',
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
                context.trStatic('cancel'),
                style: const TextStyle(
                  color: Color(0xFF9B51E0),
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                final provider = context.read<MedicationProvider>();
                
                // If no specific time, skip next dose (now)
                final timeToSkip = scheduledTime ?? DateTime.now();
                provider.skipDose(medication.id!, timeToSkip);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${medication.name} dose skipped'),
                    backgroundColor: const Color(0xFF2D9CDB),
                  ),
                );
              },
              child: Text(
                context.trStatic('skip_dose'),
                style: const TextStyle(
                  color: Color(0xFF2D9CDB),
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

  Widget _buildScheduledDoseCard(
    BuildContext context,
    ScheduledDose dose,
    MedicationProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2C2C2C),
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
                      color: Color(0xFFE0E0E0),
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
                        color: Color(0xFF828282),
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
                  color: Color(0xFF828282), size: 24),
              onPressed: () => _showScheduledDoseOptions(
                context,
                dose,
                provider,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduledDoseOptions(
    BuildContext context,
    ScheduledDose dose,
    MedicationProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
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
                _showEditMedicationModal(context, dose.medication, provider);
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
                _showSkipDoseDialog(context, dose.medication, scheduledTime: dose.scheduledTime);
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
                final scaffold = ScaffoldMessenger.of(context);
                final medName = dose.medication.name;
                Navigator.pop(context);
                _showDeleteDialog(
                  context,
                  dose.medication.name,
                  context.trStatic('remove_medication'),
                  'Remove ${dose.medication.name} and all its scheduled doses?',
                  () {
                    provider.deleteMedication(dose.medication.id!);
                    scaffold.showSnackBar(
                      SnackBar(
                        content: Text('$medName removed'),
                        backgroundColor: const Color(0xFFEB5757),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

