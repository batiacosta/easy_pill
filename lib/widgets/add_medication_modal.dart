import 'package:flutter/material.dart';
import '../extensions/localization_extension.dart';
import '../models/medication.dart';
import '../utilities/app_colors.dart';
import '../utilities/input_formatters.dart';

class AddMedicationModal extends StatefulWidget {
  final Medication? medicationToEdit;

  const AddMedicationModal({super.key, this.medicationToEdit});

  @override
  State<AddMedicationModal> createState() => _AddMedicationModalState();
}

class _AddMedicationModalState extends State<AddMedicationModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosingController = TextEditingController();
  final _pillCountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _intervalController = TextEditingController(text: '8');
  
  ScheduleType _scheduleType = ScheduleType.everyHours;
  List<TimeOfDay> _fixedTimes = [TimeOfDay.now()];
  TimeOfDay? _startTime;
  bool _hasLimit = false;

  @override
  void initState() {
    super.initState();
    // If editing, populate fields with existing medication data
    if (widget.medicationToEdit != null) {
      final med = widget.medicationToEdit!;
      _nameController.text = med.name;
      _dosingController.text = med.dosing ?? '';
      _descriptionController.text = med.description ?? '';
      _scheduleType = med.scheduleType;
      
      if (med.interval != null) {
        _intervalController.text = med.interval!.toString();
      }
      
      if (med.pillCount != null) {
        _hasLimit = true;
        _pillCountController.text = med.pillCount!.toString();
      }
      
      if (med.fixedTimes != null && med.fixedTimes!.isNotEmpty) {
        _fixedTimes = List<TimeOfDay>.from(med.fixedTimes!);
      }
      
      if (med.startTime != null) {
        _startTime = med.startTime;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosingController.dispose();
    _pillCountController.dispose();
    _descriptionController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  void _addFixedTime() {
    setState(() {
      _fixedTimes.add(TimeOfDay.now());
    });
  }

  void _removeFixedTime(int index) {
    if (_fixedTimes.length > 1) {
      setState(() {
        _fixedTimes.removeAt(index);
      });
    }
  }

  Future<void> _selectTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _fixedTimes[index],
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fixedTimes[index] = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  void _saveMedication() {
    if (!_formKey.currentState!.validate()) return;

    // Parse interval only for the schedule types that require it
    final int? interval =
        _scheduleType == ScheduleType.fixedHours ? null : int.parse(_intervalController.text);

    // Choose fixed times only when applicable
    final List<TimeOfDay>? times =
        _scheduleType == ScheduleType.everyHours ? null : List<TimeOfDay>.from(_fixedTimes);

    Navigator.pop(context, {
      'id': widget.medicationToEdit?.id, // Include ID if editing
      'name': _nameController.text.trim(),
      'dosing': _dosingController.text.trim().isEmpty ? null : _dosingController.text.trim(),
      'pillCount': _hasLimit ? int.tryParse(_pillCountController.text) : null,
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'scheduleType': _scheduleType,
      'interval': interval,
      'fixedTimes': times,
      'startTime': _scheduleType == ScheduleType.everyHours ? _startTime : null,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.medicationToEdit != null
                              ? 'Edit Medication'
                              : context.tr('add_medication'),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Medication Name
                    Text(
                      context.tr('medication_name'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: context.tr('medication_name_hint'),
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.surfaceAlt2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                            return context.trStatic('required_field');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Dosing (Optional)
                    Text(
                      context.tr('dosing_optional'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dosingController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: context.tr('dosing_hint'),
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.surfaceAlt2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pill Count Limit
                    Row(
                      children: [
                        Checkbox(
                          value: _hasLimit,
                          onChanged: (value) {
                            setState(() {
                              _hasLimit = value ?? false;
                            });
                          },
                          fillColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColors.primary;
                            }
                            return AppColors.surfaceAlt2;
                          }),
                        ),
                        Text(
                          context.tr('limit_pill_count'),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (_hasLimit) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _pillCountController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        keyboardType: TextInputType.number,
                        inputFormatters: AppInputFormatters.digitsOnly,
                        decoration: InputDecoration(
                          hintText: context.tr('total_pills_hint'),
                          hintStyle: const TextStyle(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.surfaceAlt2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (_hasLimit && (value == null || value.isEmpty)) {
                            return context.trStatic('required_field');
                          }
                          if (_hasLimit && int.tryParse(value!) == null) {
                            return context.trStatic('invalid_number');
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Schedule Type
                    Text(
                      context.tr('schedule_type'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Every X Hours Option
                    RadioListTile<ScheduleType>(
                      title: Text(
                        context.tr('every_hours'),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      value: ScheduleType.everyHours,
                      groupValue: _scheduleType,
                      onChanged: (value) {
                        setState(() {
                          _scheduleType = value!;
                        });
                      },
                      activeColor: AppColors.primary,
                      tileColor: AppColors.surfaceAlt2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    if (_scheduleType == ScheduleType.everyHours) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              context.tr('every'),
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                controller: _intervalController,
                                style: const TextStyle(color: AppColors.textPrimary),
                                keyboardType: TextInputType.number,
                                inputFormatters: AppInputFormatters.digitsOnly,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surfaceAlt2,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                ),
                                validator: (value) {
                                  if (_scheduleType == ScheduleType.everyHours &&
                                      (value == null || value.isEmpty)) {
                                    return context.trStatic('required');
                                  }
                                  if (int.tryParse(value!) == null) {
                                    return context.trStatic('invalid');
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('hours'),
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('starting_time'),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _startTime != null ? () => _selectStartTime() : null,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt2,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _startTime != null
                                          ? _startTime!.format(context)
                                          : context.tr('select_time'),
                                      style: TextStyle(
                                        color: _startTime != null
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.access_time,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _selectStartTime(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.surfaceAlt2,
                                  foregroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.access_time),
                                label: Text(
                                  _startTime == null
                                      ? context.tr('set_start_time')
                                      : context.tr('change_start_time'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Fixed Hours Option
                    RadioListTile<ScheduleType>(
                      title: Text(
                        context.tr('fixed_hours'),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      value: ScheduleType.fixedHours,
                      groupValue: _scheduleType,
                      onChanged: (value) {
                        setState(() {
                          _scheduleType = value!;
                        });
                      },
                      activeColor: AppColors.primary,
                      tileColor: AppColors.surfaceAlt2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    if (_scheduleType == ScheduleType.fixedHours) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            for (int i = 0; i < _fixedTimes.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _selectTime(i),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceAlt2,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _fixedTimes[i].format(context),
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.access_time,
                                                color: AppColors.primary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_fixedTimes.length > 1) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle,
                                          color: AppColors.danger,
                                        ),
                                        onPressed: () => _removeFixedTime(i),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _addFixedTime,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surfaceAlt2,
                                foregroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.add),
                              label: Text(context.tr('add_time')),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Every X Days Option
                    RadioListTile<ScheduleType>(
                      title: Text(
                        context.tr('every_days'),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      value: ScheduleType.everyDays,
                      groupValue: _scheduleType,
                      onChanged: (value) {
                        setState(() {
                          _scheduleType = value!;
                        });
                      },
                      activeColor: AppColors.primary,
                      tileColor: AppColors.surfaceAlt2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    if (_scheduleType == ScheduleType.everyDays) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  context.tr('every'),
                                  style: const TextStyle(color: AppColors.textPrimary),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    controller: _intervalController,
                                    style: const TextStyle(color: AppColors.textPrimary),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: AppColors.surfaceAlt2,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 12,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (_scheduleType == ScheduleType.everyDays &&
                                          (value == null || value.isEmpty)) {
                                        return context.trStatic('required');
                                      }
                                      if (int.tryParse(value!) == null) {
                                        return context.trStatic('invalid');
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('days'),
                                  style: const TextStyle(color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.tr('at_these_times'),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (int i = 0; i < _fixedTimes.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _selectTime(i),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceAlt2,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _fixedTimes[i].format(context),
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.access_time,
                                                color: AppColors.primary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_fixedTimes.length > 1) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle,
                                          color: AppColors.danger,
                                        ),
                                        onPressed: () => _removeFixedTime(i),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ElevatedButton.icon(
                              onPressed: _addFixedTime,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surfaceAlt2,
                                foregroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.add),
                              label: Text(context.tr('add_time')),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Description (Optional)
                    Text(
                      context.tr('description_optional'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: context.tr('description_hint'),
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.surfaceAlt2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: AppColors.textSecondary),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              context.tr('cancel'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveMedication,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              context.tr('add_medication'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
