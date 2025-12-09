import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medication_item.dart';
import '../widgets/medication_section.dart';

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
    _updateGreeting();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    final now = DateTime.now();

    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 18) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    currentDate = DateFormat('MMMM d').format(now);
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
              child: const Text(
                'Cancel',
                style: TextStyle(
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
              child: const Text(
                'Delete',
                style: TextStyle(
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
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                      // Date
                      Text(
                        'Today, $currentDate',
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
                      // Morning Section
                      MedicationSection(
                        title: 'Pending',
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
                      ),
                      // Afternoon Section
                      MedicationSection(
                        title: 'Afternoon',
                        medications: [
                          MedicationItem(
                            name: 'Allergy Relief',
                            time: 'Next dose: 1:00 PM',
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
                      ),
                      // Evening Section
                      MedicationSection(
                        title: 'Evening',
                        medications: [
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
              onPressed: () {},
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

