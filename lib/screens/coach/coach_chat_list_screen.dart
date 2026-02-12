import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled3/models/user_model.dart';
import 'package:untitled3/providers/auth_provider.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/utils/theme.dart';
import 'package:untitled3/screens/common/chat_screen.dart';

class CoachChatListScreen extends StatefulWidget {
  const CoachChatListScreen({super.key});

  @override
  State<CoachChatListScreen> createState() => _CoachChatListScreenState();
}

class _CoachChatListScreenState extends State<CoachChatListScreen> {
  final _searchController = TextEditingController();
  final _dbService = DatabaseService();
  String _searchQuery = '';
  Stream<List<AppUser>>? _clientsStream;
  final Map<String, Stream<int>> _unreadCountStreams = {};
  final Map<String, Stream<String?>> _lastMessageStreams = {};

  Stream<int> _getUnreadCountStream(String clientId, String coachId) {
    return _unreadCountStreams.putIfAbsent(
      clientId,
      () => _dbService.getUnreadCount(clientId, coachId),
    );
  }

  Stream<String?> _getLastMessageStream(String clientId, String coachId) {
    return _lastMessageStreams.putIfAbsent(
      clientId,
      () => _dbService.getLastMessage(clientId, coachId),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final coachId = Provider.of<AuthProvider>(context).userProfile?.uid ?? '';
    _clientsStream ??= _dbService.getClients(coachId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coachId = Provider.of<AuthProvider>(context).userProfile?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('CLIENT MESSAGES'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign),
            tooltip: 'Broadcast Message',
            onPressed: () => _showBroadcastDialog(context, coachId, _dbService),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search clients...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.mutedTextColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.mutedTextColor),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: _clientsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var clients = snapshot.data ?? [];
                
                if (_searchQuery.isNotEmpty) {
                  clients = clients
                      .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                if (clients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No clients found.' : 'No matches found for "$_searchQuery"',
                          style: const TextStyle(color: AppTheme.mutedTextColor),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: clients.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    return _buildClientChatItem(context, client, coachId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context, String coachId, DatabaseService dbService) async {
    final clients = await _dbService.getClients(coachId).first;
    if (clients.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No clients to broadcast to.')));
      }
      return;
    }

    final controller = TextEditingController();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Row(
          children: [
            Icon(Icons.campaign, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Broadcast Message', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This message will be sent to all ${clients.length} of your clients individually.',
              style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your announcement here...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.black12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.mutedTextColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              
              Navigator.pop(context);
              
              final clientIds = clients.map((c) => c.uid).toList();
              await _dbService.sendBroadcastMessage(coachId, clientIds, text);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Broadcast sent to ${clients.length} clients!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
            ),
            child: const Text('SEND TO ALL', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildClientChatItem(BuildContext context, AppUser client, String coachId) {
    return StreamBuilder<int>(
      stream: _getUnreadCountStream(client.uid, coachId),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unreadCount > 0 ? AppTheme.primaryColor.withOpacity(0.3) : Colors.white.withOpacity(0.05),
              width: unreadCount > 0 ? 1.5 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    currentUserId: coachId,
                    otherUserId: client.uid,
                    otherUserName: client.name,
                  ),
                ),
              );
            },
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    client.name[0].toUpperCase(),
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              client.name.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: StreamBuilder<String?>(
              stream: _getLastMessageStream(client.uid, coachId),
              builder: (context, snapshot) {
                final lastMsg = snapshot.data ?? 'No messages yet';
                return Text(
                  lastMsg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unreadCount > 0 ? Colors.white : AppTheme.mutedTextColor,
                    fontSize: 13,
                    fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              },
            ),
            trailing: unreadCount > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                : const Icon(Icons.chevron_right, color: Colors.white24),
          ),
        );
      },
    );
  }
}
