import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/medication.dart';
import '../models/scheduled_dose.dart';
import '../widgets/add_medication_modal.dart';
import '../extensions/localization_extension.dart';
import '../services/notification_service.dart';
import '../services/firestore_service.dart';
import '../providers/medication_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';
import 'account.dart';
import 'login.dart';
import 'sync_conflict_screen.dart';
import 'locations.dart';
import '../widgets/home_header.dart';
import '../widgets/medication_options_sheet.dart';
import '../widgets/scheduled_dose_options_sheet.dart';
import '../utilities/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String greeting;
  late String currentDate;
  bool _isScheduledExpanded = true; // Track if Scheduled section is expanded
  VoidCallback? _authListener;

  // Color map for schedule types
  static const Map<ScheduleType, Color> scheduleTypeColors = {
    ScheduleType.everyHours: AppColors.primary,  // Purple (primary)
    ScheduleType.fixedHours: AppColors.secondary,  // Blue (secondary)
    ScheduleType.everyDays: AppColors.danger,   // Red (tertiary)
  };

  Color getScheduleTypeColor(ScheduleType type) {
    return scheduleTypeColors[type] ?? AppColors.primary;
  }

  @override
  void initState() {
    super.initState();
    currentDate = DateFormat('MMMM d').format(DateTime.now());
    _initializeApp();
    // Listen to auth changes to refresh content and notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      _authListener = () => _handleAuthChange(authProvider);
      authProvider.addListener(_authListener!);
    });
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh when returning from auth screens
    setState(() {});
  }

  @override
  void dispose() {
    final authProvider = context.read<AuthProvider>();
    if (_authListener != null) {
      authProvider.removeListener(_authListener!);
    }
    super.dispose();
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
      
      // Check for sync if user is authenticated
      final authProvider = context.read<AuthProvider>();
      final syncProvider = context.read<SyncProvider>();
      
      if (authProvider.isAuthenticated && authProvider.isFirebaseEnabled) {
        await _performSync(syncProvider);
      }
    }
  }

  Future<void> _performSync(SyncProvider syncProvider) async {
    final hasInternet = await syncProvider.checkInternet();
    if (!hasInternet) {
      debugPrint('No internet connection, skipping sync');
      return;
    }

    final medicationProvider = context.read<MedicationProvider>();
    final success = await syncProvider.performSync(
      medicationProvider.medications,
      '',
    );

    if (!success && syncProvider.hasSyncConflicts && mounted) {
      // Show conflict resolution screen
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => SyncConflictScreen(
            conflicts: syncProvider.conflicts,
          ),
        ),
      );

      if (result == true && mounted) {
        // Sync was successful, refresh data
        await medicationProvider.refreshMedications();
        await medicationProvider.rescheduleAllNotifications();
      }
    } else if (success && mounted) {
      // Silent sync success
      await medicationProvider.refreshMedications();
      await medicationProvider.rescheduleAllNotifications();
      debugPrint('Sync completed successfully');
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

  Future<void> _handleAuthChange(AuthProvider authProvider) async {
    if (!mounted) return;
    final medicationProvider = context.read<MedicationProvider>();
    final syncProvider = context.read<SyncProvider>();
    final firestoreService = FirestoreService();

    // Always refresh local data after auth state changes
    await medicationProvider.loadMedications();

    // If authenticated and Firebase is enabled, sync and reschedule notifications
    if (authProvider.isAuthenticated && authProvider.isFirebaseEnabled) {
      // Pull remote meds
      try {
        final remoteMeds = await firestoreService.downloadMedications();
        if (remoteMeds.isNotEmpty) {
          // If local is empty or count differs, replace with remote
          if (medicationProvider.medications.isEmpty ||
              remoteMeds.length != medicationProvider.medications.length) {
            await medicationProvider.replaceWithRemote(remoteMeds);
          }
        }
      } catch (e) {
        debugPrint('Error fetching remote medications: $e');
      }

      await _performSync(syncProvider);
    }

    // Reschedule notifications based on latest data
    await medicationProvider.rescheduleAllNotifications();

    if (mounted) setState(() {});
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
          backgroundColor: AppColors.surface,
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
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
                  color: AppColors.primary,
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
                  color: AppColors.danger,
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
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error adding medication: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error adding medication'),
              backgroundColor: AppColors.danger,
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
            backgroundColor: AppColors.primary,
          ),
        );
      } catch (e) {
        debugPrint('Error updating medication: $e');
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Error updating medication'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showClearMissedDialog(
    BuildContext context,
    MedicationProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Clear Missed Doses',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'This will mark all missed doses as skipped. This action cannot be undone.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.trStatic('cancel'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              await provider.clearMissedDoses();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Missed doses cleared'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            child: Text(
              context.trStatic('clear'),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Consumer<MedicationProvider>(
              builder: (context, medicationProvider, _) {
                if (medicationProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
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
                      // Header (extracted)
                      HomeHeader(
                        greeting: greeting,
                        currentDate: currentDate,
                        onSync: () async {
                          final syncProvider = context.read<SyncProvider>();
                          await _performSync(syncProvider);
                          await context.read<MedicationProvider>().loadMedications();
                          if (mounted) setState(() {});
                        },
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
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        context.tr('no_medications'),
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        context.tr('tap_to_add_first'),
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
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
                                      context.tr('today_section'),
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
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
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.surfaceAlt,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        context.tr('all_caught_up'),
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
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
                                      context.tr('taken_today_section'),
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
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
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.surfaceAlt,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        context.tr('nothing_taken_yet'),
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
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
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isScheduledExpanded = !_isScheduledExpanded;
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          context.tr('scheduled_section'),
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Icon(
                                          _isScheduledExpanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          color: AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (_isScheduledExpanded) ...[
                                    if (scheduledDoses.isEmpty)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.surfaceAlt,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        context.tr('no_scheduled_doses'),
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
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

                                  const SizedBox(height: 24),
                                  // Missed section
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        context.tr('missed'),
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (medicationProvider.getMissedDoses().isNotEmpty)
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'clear') {
                                              _showClearMissedDialog(context, medicationProvider);
                                            }
                                          },
                                          itemBuilder: (BuildContext context) => [
                                            PopupMenuItem<String>(
                                              value: 'clear',
                                              child: Text(
                                                context.trStatic('clear'),
                                              ),
                                            ),
                                          ],
                                          icon: const Icon(
                                            Icons.more_vert,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (medicationProvider.getMissedDoses().isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.surfaceAlt,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        context.tr('no_missed_doses'),
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  else
                                    for (final dose in medicationProvider.getMissedDoses())
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
                backgroundColor: AppColors.primary,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.surfaceAlt,
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
                          color: AppColors.textPrimary,
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
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (medication.pillCount != null) ...[
                        const SizedBox(height: 4),
                        Consumer<MedicationProvider>(
                          builder: (context, provider, _) {
                            final takenToday = provider.todayDoseCounts[medication.id] ?? 0;
                            final remaining = medication.pillCount! - takenToday;
                            return Text(
                              context.tr('pills_remaining', {
                                'remaining': remaining.toString(),
                                'total': medication.pillCount.toString(),
                              }),
                              style: TextStyle(
                                color: remaining <= 0 
                                    ? AppColors.secondary
                                    : AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textSecondary, size: 24),
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
                  color: AppColors.textSecondary,
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
                color: AppColors.surfaceAlt2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getScheduleText(medication),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
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
                      ? AppColors.secondary
                      : getScheduleTypeColor(medication.scheduleType),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.surfaceAlt,
                  disabledForegroundColor: AppColors.textSecondary,
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
                      ? context.tr('taken_today_label')
                      : dueToday
                          ? context.tr('mark_as_taken')
                          : context.tr('not_due_today'),
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
        return context.tr('schedule_every_hours', {
          'hours': (medication.interval ?? 1).toString(),
        });
      case ScheduleType.fixedHours:
        final times = medication.fixedTimes
                ?.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
                .join(', ') ??
            '';
        return context.tr('schedule_daily_at', {'times': times});
      case ScheduleType.everyDays:
        final times = medication.fixedTimes
                ?.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
                .join(', ') ??
            '';
        return context.tr('schedule_every_days_at', {
          'days': (medication.interval ?? 1).toString(),
          'times': times,
        });
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
      backgroundColor: AppColors.surface,
      builder: (context) => MedicationOptionsSheet(
        medication: medication,
        onEdit: () => _showEditMedicationModal(context, medication, provider),
        onRemove: () {
          final scaffold = ScaffoldMessenger.of(context);
          final medName = medication.name;
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
                  backgroundColor: AppColors.danger,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showSkipDoseDialog(BuildContext context, Medication medication, {DateTime? scheduledTime}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            context.trStatic('skip_dose'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Skip this dose of ${medication.name}?',
            style: const TextStyle(
              color: AppColors.textSecondary,
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
                  color: AppColors.primary,
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
                    backgroundColor: AppColors.secondary,
                  ),
                );
              },
              child: Text(
                context.trStatic('skip_dose'),
                style: const TextStyle(
                  color: AppColors.secondary,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.surfaceAlt,
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
                      color: AppColors.textPrimary,
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
                        color: AppColors.textSecondary,
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
                  color: AppColors.textSecondary, size: 24),
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
      backgroundColor: AppColors.surface,
      builder: (context) => ScheduledDoseOptionsSheet(
        dose: dose,
        onEditMedication: () => _showEditMedicationModal(context, dose.medication, provider),
        onRemoveMedication: () {
          final scaffold = ScaffoldMessenger.of(context);
          final medName = dose.medication.name;
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
                  backgroundColor: AppColors.danger,
                ),
              );
            },
          );
        },
        onSkipDose: () => _showSkipDoseDialog(context, dose.medication, scheduledTime: dose.scheduledTime),
      ),
    );
  }
}

