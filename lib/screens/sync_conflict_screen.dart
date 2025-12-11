import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sync_conflict.dart';
import '../providers/medication_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/localization_provider.dart';

class SyncConflictScreen extends StatefulWidget {
  final List<SyncConflict> conflicts;

  const SyncConflictScreen({Key? key, required this.conflicts}) : super(key: key);

  @override
  State<SyncConflictScreen> createState() => _SyncConflictScreenState();
}

class _SyncConflictScreenState extends State<SyncConflictScreen> {
  late Map<String, ConflictResolutionStrategy> _resolutions;

  @override
  void initState() {
    super.initState();
    _resolutions = {};
    for (final conflict in widget.conflicts) {
      _resolutions[conflict.medicationId] = ConflictResolutionStrategy.merge;
    }
  }

  void _applyResolutions() async {
    final syncProvider = context.read<SyncProvider>();
    final medicationProvider = context.read<MedicationProvider>();
    final localizationProvider = context.read<LocalizationProvider>();

    try {
      // Set all resolutions
      for (final conflict in widget.conflicts) {
        final strategy = _resolutions[conflict.medicationId];
        if (strategy != null) {
          conflict.resolutionStrategy = strategy;
        }
      }

      // Apply to Firestore and get resolved list
      final success = await syncProvider.applyConflictResolutions(
        medicationProvider.medications,
      );

      if (success && mounted) {
        // Refresh local data
        await medicationProvider.refreshMedications();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizationProvider.tr('sync_complete')),
            backgroundColor: Colors.green,
          ),
        );

        // Return user to Home
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      // If not successful, keep user on screen (error handled below)
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationProvider = context.read<LocalizationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(localizationProvider.tr('sync_conflicts')),
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.conflicts.length,
                itemBuilder: (context, index) {
                  final conflict = widget.conflicts[index];
                  final strategy = _resolutions[conflict.medicationId] ?? ConflictResolutionStrategy.merge;

                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medication: ${conflict.localMedication.name}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Local and cloud versions differ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStrategyOption(
                            localizationProvider,
                            ConflictResolutionStrategy.merge,
                            'Merge Both Versions',
                            'Keep all data from both local and cloud',
                            Icons.merge,
                            strategy,
                            conflict.medicationId,
                          ),
                          const SizedBox(height: 12),
                          _buildStrategyOption(
                            localizationProvider,
                            ConflictResolutionStrategy.keepOnline,
                            'Keep Cloud Version',
                            'Replace local data with cloud data',
                            Icons.cloud_download,
                            strategy,
                            conflict.medicationId,
                          ),
                          const SizedBox(height: 12),
                          _buildStrategyOption(
                            localizationProvider,
                            ConflictResolutionStrategy.keepLocal,
                            'Keep Local Version',
                            'Replace cloud data with local data',
                            Icons.phone_android,
                            strategy,
                            conflict.medicationId,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _applyResolutions,
                icon: const Icon(Icons.check),
                label: Text(localizationProvider.tr('apply_resolutions')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B51E0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(localizationProvider.tr('cancel')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyOption(
    LocalizationProvider localizationProvider,
    ConflictResolutionStrategy value,
    String title,
    String subtitle,
    IconData icon,
    ConflictResolutionStrategy currentStrategy,
    String medicationId,
  ) {
    final isSelected = currentStrategy == value;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? const Color(0xFF9B51E0) : Colors.white12,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RadioListTile<ConflictResolutionStrategy>(
        value: value,
        groupValue: currentStrategy,
        onChanged: (selected) {
          if (selected != null) {
            setState(() {
              _resolutions[medicationId] = selected;
            });
          }
        },
        activeColor: const Color(0xFF9B51E0),
        tileColor: isSelected ? const Color(0xFF9B51E0).withOpacity(0.1) : null,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        secondary: Icon(icon, color: const Color(0xFF9B51E0)),
      ),
    );
  }
}
