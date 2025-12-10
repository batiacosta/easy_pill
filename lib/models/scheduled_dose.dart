import 'package:flutter/material.dart';
import 'medication.dart';

class ScheduledDose {
  final Medication medication;
  final DateTime scheduledTime;

  ScheduledDose({
    required this.medication,
    required this.scheduledTime,
  });

  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduleDate = DateTime(
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
    );
    return scheduleDate.isAtSameMomentAs(today);
  }

  String formatTime() {
    final hour = scheduledTime.hour.toString().padLeft(2, '0');
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String formatTimeWithPeriod() {
    final hour = scheduledTime.hour;
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = (hour % 12 == 0) ? 12 : (hour % 12);
    return '$displayHour:$minute $period';
  }

  String formatDate() {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[scheduledTime.month - 1]} ${scheduledTime.day}';
  }

  String formatDateTime() {
    if (isToday) {
      return 'Today at ${formatTime()}';
    }
    return '${formatDate()} at ${formatTime()}';
  }
}
