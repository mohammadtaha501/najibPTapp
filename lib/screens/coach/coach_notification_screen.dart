import 'package:flutter/material.dart';
import 'package:ptapp/models/notification_model.dart';
import 'package:ptapp/services/database_service.dart';
import 'package:ptapp/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:ptapp/providers/auth_provider.dart';
import 'package:ptapp/screens/coach/client_detail.dart';
// import 'package:ptapp/models/user_model.dart';

class CoachNotificationScreen extends StatelessWidget {
  const CoachNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coachId = Provider.of<AuthProvider>(context).userProfile!.uid;
    final dbService = DatabaseService();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => dbService.markAllNotificationsAsRead(coachId),
            child: const Text(
              'Mark all as read',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: dbService.getNotifications(coachId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: AppTheme.mutedTextColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: AppTheme.mutedTextColor),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(context, notification, dbService);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    AppNotification notification,
    DatabaseService dbService,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.transparent
            : AppTheme.primaryColor.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notification.type == NotificationType.onboarding
              ? AppTheme.primaryColor
              : Colors.blue,
          child: Icon(
            notification.type == NotificationType.onboarding
                ? Icons.person_add
                : Icons.message,
            color: Colors.black,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              style: const TextStyle(color: AppTheme.mutedTextColor),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.createdAt),
              style: const TextStyle(
                color: AppTheme.mutedTextColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
        onTap: () async {
          await dbService.markNotificationAsRead(notification.id!);
          if (context.mounted &&
              notification.type == NotificationType.onboarding &&
              notification.senderId.isNotEmpty) {
            // Fetch the user object and navigate
            final user = await DatabaseService().getUserById(
              notification.senderId,
            );
            if (user != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClientDetailScreen(client: user),
                ),
              );
            }
          }
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${date.day}/${date.month}';
  }
}
