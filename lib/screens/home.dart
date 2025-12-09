import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
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
                      _buildMedicationSection(
                        title: 'Pending',
                        medications: [
                          _MedicationItem(
                            name: 'Ibuprofen 200mg',
                            time: 'Next dose: 8:00 AM',
                            icon: Icons.medication,
                            color: const Color(0xFFEB5757),
                            bgColor: const Color(0x1AEB5757),
                            isTaken: false,
                          ),
                          _MedicationItem(
                            name: 'Vitamin D 1000IU',
                            time: 'Taken at 8:05 AM',
                            icon: Icons.medication,
                            color: const Color(0xFF828282),
                            bgColor: const Color(0x1A828282),
                            isTaken: true,
                          ),
                        ],
                      ),
                      // Afternoon Section
                      _buildMedicationSection(
                        title: 'Afternoon',
                        medications: [
                          _MedicationItem(
                            name: 'Allergy Relief',
                            time: 'Next dose: 1:00 PM',
                            icon: Icons.healing,
                            color: const Color(0xFF2D9CDB),
                            bgColor: const Color(0x1A2D9CDB),
                            isTaken: false,
                          ),
                        ],
                      ),
                      // Evening Section
                      _buildMedicationSection(
                        title: 'Evening',
                        medications: [
                          _MedicationItem(
                            name: 'Magnesium 400mg',
                            time: 'Next dose: 9:00 PM',
                            icon: Icons.water_drop,
                            color: const Color(0xFF9B51E0),
                            bgColor: const Color(0x1A9B51E0),
                            isTaken: false,
                          ),
                        ],
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
    );
  }

  Widget _buildMedicationSection({
    required String title,
    required List<_MedicationItem> medications,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Column(
          children: medications
              .map((med) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildMedicationCard(med),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMedicationCard(_MedicationItem medication) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2C2C2C),
          width: 1,
        ),
      ),
      child: Opacity(
        opacity: medication.isTaken ? 0.5 : 1.0,
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
                            color: medication.bgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            medication.icon,
                            color: medication.color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
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
                              const SizedBox(height: 4),
                              Text(
                                medication.time,
                                style: const TextStyle(
                                  color: Color(0xFF828282),
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
                  IconButton(
                    icon: const Icon(Icons.more_vert,
                        color: Color(0xFF828282), size: 24),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Action Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: medication.isTaken
                    ? ElevatedButton.icon(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C2C2E),
                          disabledForegroundColor: const Color(0xFF828282),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle,
                            size: 20, color: Color(0xFF828282)),
                        label: const Text(
                          'Taken',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          setState(() {
                            medication.isTaken = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: medication.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Mark as Taken',
                          style: TextStyle(
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

class _MedicationItem {
  final String name;
  final String time;
  final IconData icon;
  final Color color;
  final Color bgColor;
  bool isTaken;

  _MedicationItem({
    required this.name,
    required this.time,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.isTaken,
  });
}
