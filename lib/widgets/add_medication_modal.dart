import 'package:flutter/material.dart';
import '../extensions/localization_extension.dart';

enum ScheduleType { everyHours, fixedHours, everyDays }

class AddMedicationModal extends StatefulWidget {
  const AddMedicationModal({super.key});

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
  bool _hasLimit = false;

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
              primary: Color(0xFF9B51E0),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Color(0xFFE0E0E0),
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

  void _saveMedication() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save medication and schedule notifications
      Navigator.pop(context, {
        'name': _nameController.text,
        'dosing': _dosingController.text,
        'pillCount': _hasLimit ? int.tryParse(_pillCountController.text) : null,
        'description': _descriptionController.text,
        'scheduleType': _scheduleType,
        'interval': _scheduleType != ScheduleType.fixedHours 
            ? int.parse(_intervalController.text) 
            : null,
        'fixedTimes': _scheduleType == ScheduleType.fixedHours 
            ? _fixedTimes 
            : null,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
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
                          context.tr('add_medication'),
                          style: const TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF828282)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Medication Name
                    Text(
                      context.tr('medication_name'),
                      style: const TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Color(0xFFE0E0E0)),
                      decoration: InputDecoration(
                        hintText: context.tr('medication_name_hint'),
                        hintStyle: const TextStyle(color: Color(0xFF828282)),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('required_field');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Dosing (Optional)
                    Text(
                      context.tr('dosing_optional'),
                      style: const TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dosingController,
                      style: const TextStyle(color: Color(0xFFE0E0E0)),
                      decoration: InputDecoration(
                        hintText: context.tr('dosing_hint'),
                        hintStyle: const TextStyle(color: Color(0xFF828282)),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2E),
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
                              return const Color(0xFF9B51E0);
                            }
                            return const Color(0xFF2C2C2E);
                          }),
                        ),
                        Text(
                          context.tr('limit_pill_count'),
                          style: const TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (_hasLimit) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _pillCountController,
                        style: const TextStyle(color: Color(0xFFE0E0E0)),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: context.tr('total_pills_hint'),
                          hintStyle: const TextStyle(color: Color(0xFF828282)),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (_hasLimit && (value == null || value.isEmpty)) {
                            return context.tr('required_field');
                          }
                          if (_hasLimit && int.tryParse(value!) == null) {
                            return context.tr('invalid_number');
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
                        color: Color(0xFFE0E0E0),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Every X Hours Option
                    RadioListTile<ScheduleType>(
                      title: Text(
                        context.tr('every_hours'),
                        style: const TextStyle(color: Color(0xFFE0E0E0)),
                      ),
                      value: ScheduleType.everyHours,
                      groupValue: _scheduleType,
                      onChanged: (value) {
                        setState(() {
                          _scheduleType = value!;
                        });
                      },
                      activeColor: const Color(0xFF9B51E0),
                      tileColor: const Color(0xFF2C2C2E),
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
                              style: const TextStyle(color: Color(0xFFE0E0E0)),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                controller: _intervalController,
                                style: const TextStyle(color: Color(0xFFE0E0E0)),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFF2C2C2E),
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
                                    return context.tr('required');
                                  }
                                  if (int.tryParse(value!) == null) {
                                    return context.tr('invalid');
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('hours'),
                              style: const TextStyle(color: Color(0xFFE0E0E0)),
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
                        style: const TextStyle(color: Color(0xFFE0E0E0)),
                      ),
                      value: ScheduleType.fixedHours,
                      groupValue: _scheduleType,
                      onChanged: (value) {
                        setState(() {
                          _scheduleType = value!;
                        });
                      },
                      activeColor: const Color(0xFF9B51E0),
                      tileColor: const Color(0xFF2C2C2E),
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
                                            color: const Color(0xFF2C2C2E),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _fixedTimes[i].format(context),
                                                style: const TextStyle(
                                                  color: Color(0xFFE0E0E0),
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.access_time,
                                                color: Color(0xFF9B51E0),
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
                                          color: Color(0xFFEB5757),
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
                                backgroundColor: const Color(0xFF2C2C2E),
                                foregroundColor: const Color(0xFF9B51E0),
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
                        style: const TextStyle(color: Color(0xFFE0E0E0)),
                      ),
                      value: ScheduleType.everyDays,
                      groupValue: _scheduleType,
                      onChanged: (value) {
                        setState(() {
                          _scheduleType = value!;
                        });
                      },
                      activeColor: const Color(0xFF9B51E0),
                      tileColor: const Color(0xFF2C2C2E),
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
                                  style: const TextStyle(color: Color(0xFFE0E0E0)),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    controller: _intervalController,
                                    style: const TextStyle(color: Color(0xFFE0E0E0)),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFF2C2C2E),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('days'),
                                  style: const TextStyle(color: Color(0xFFE0E0E0)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.tr('at_these_times'),
                              style: const TextStyle(
                                color: Color(0xFF828282),
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
                                            color: const Color(0xFF2C2C2E),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _fixedTimes[i].format(context),
                                                style: const TextStyle(
                                                  color: Color(0xFFE0E0E0),
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.access_time,
                                                color: Color(0xFF9B51E0),
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
                                          color: Color(0xFFEB5757),
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
                                backgroundColor: const Color(0xFF2C2C2E),
                                foregroundColor: const Color(0xFF9B51E0),
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
                        color: Color(0xFFE0E0E0),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Color(0xFFE0E0E0)),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: context.tr('description_hint'),
                        hintStyle: const TextStyle(color: Color(0xFF828282)),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2E),
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
                              foregroundColor: const Color(0xFF828282),
                              side: const BorderSide(color: Color(0xFF828282)),
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
                              backgroundColor: const Color(0xFF9B51E0),
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
