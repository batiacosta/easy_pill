// Account screen: displays basic user info and provides logout.
// Reads AuthProvider for current user and performs sign-out.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../extensions/localization_extension.dart';
import '../utilities/app_colors.dart';
import '../widgets/action_button.dart';
import '../services/database_service.dart';
import '../providers/medication_provider.dart';
import '../providers/sync_provider.dart';
import 'home.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Layout: app bar, user info card (name/email), and logout button
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          context.tr('account'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final user = authProvider.user;
            
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Info Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.displayName ?? 'User',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Logout Button
                  ActionButton(
                    text: context.tr('logout'),
                    icon: Icons.logout,
                    onPressed: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: Text(
                              context.tr('logout'),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Text(
                              context.tr('confirm_logout'),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                                child: Text(
                                  context.tr('cancel'),
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                                child: Text(
                                  context.tr('logout'),
                                  style: const TextStyle(color: AppColors.danger),
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      if (shouldLogout == true && context.mounted) {
                        await authProvider.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                    backgroundColor: AppColors.danger,
                  ),

                  const SizedBox(height: 12),

                  // Delete Account Button
                  ActionButton(
                    text: context.tr('delete_account'),
                    icon: Icons.delete_forever,
                    onPressed: () async {
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: Text(
                              context.tr('delete_account'),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Text(
                              context.tr('confirm_delete_account'),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                                child: Text(
                                  context.tr('cancel'),
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                                child: Text(
                                  context.tr('delete'),
                                  style: const TextStyle(color: AppColors.danger),
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      if (shouldDelete == true && context.mounted) {
                        final success = await authProvider.deleteAccount();
                        if (!success) {
                          final error = authProvider.errorMessage ?? context.tr('invalid');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                          }
                          return;
                        }

                        // Clear local database after successful deletion
                        final db = DatabaseService();
                        await db.deleteAllData();

                        // Reset local providers and notifications
                        if (context.mounted) {
                          final medicationProvider = context.read<MedicationProvider>();
                          await medicationProvider.refreshMedications();
                          await medicationProvider.rescheduleAllNotifications();

                          final syncProvider = context.read<SyncProvider>();
                          syncProvider.clearSyncState();
                        }

                        if (context.mounted) {
                          // Replace the entire stack with a fresh HomeScreen
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                          );
                        }
                      }
                    },
                    backgroundColor: AppColors.danger,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
