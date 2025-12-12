import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../extensions/localization_extension.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/medication_provider.dart';
import '../services/notification_service.dart';
import '../screens/login.dart';
import '../screens/account.dart';
import '../screens/locations.dart';

class HomeHeader extends StatelessWidget {
  final String greeting;
  final String currentDate;
  final Future<void> Function() onSync;

  const HomeHeader({
    super.key,
    required this.greeting,
    required this.currentDate,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      if (authProvider.isAuthenticated && authProvider.user != null) {
                        final userName = authProvider.user!.displayName ?? context.tr('user');
                        return Text(
                          '$greeting, $userName',
                          style: const TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        );
                      } else {
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF2D9CDB).withOpacity(0.15),
                                  const Color(0xFF2D9CDB).withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF2D9CDB).withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.cloud_sync_outlined,
                                  color: Color(0xFF2D9CDB),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('sync_your_data'),
                                  style: const TextStyle(
                                    color: Color(0xFF2D9CDB),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Color(0xFF2D9CDB),
                                  size: 12,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                Row(
                  children: [
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        if (authProvider.isAuthenticated && authProvider.isFirebaseEnabled) {
                          return IconButton(
                            icon: const Icon(
                              Icons.sync,
                              color: Color(0xFF2D9CDB),
                              size: 28,
                            ),
                            tooltip: context.tr('sync_with_cloud'),
                            onPressed: () async {
                              final scaffold = ScaffoldMessenger.of(context);
                              try {
                                scaffold.showSnackBar(
                                  SnackBar(
                                    content: Text(context.tr('syncing')),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                                await onSync();
                                scaffold.showSnackBar(
                                  SnackBar(
                                    content: Text(context.tr('sync_complete')),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              } catch (e) {
                                scaffold.showSnackBar(
                                  SnackBar(
                                    content: Text(context.tr('sync_failed', {'error': e.toString()})),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFFE0E0E0),
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LocationsScreen(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Color(0xFFE0E0E0),
                        size: 28,
                      ),
                      onPressed: () async {
                        await NotificationService().scheduleTestNotification();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.tr('test_notification_scheduled')),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return IconButton(
                          icon: Icon(
                            authProvider.isAuthenticated
                                ? Icons.account_circle
                                : Icons.account_circle_outlined,
                            color: authProvider.isAuthenticated
                                ? const Color(0xFF9B51E0)
                                : const Color(0xFFE0E0E0),
                            size: 28,
                          ),
                          onPressed: () {
                            if (authProvider.isAuthenticated) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const AccountScreen(),
                                ),
                              );
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
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
    );
  }
}
