import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ptapp/models/user_model.dart';
import 'package:ptapp/models/message_model.dart';
import 'package:ptapp/providers/auth_provider.dart';
import 'package:ptapp/services/database_service.dart';
import 'package:ptapp/utils/theme.dart';
import 'package:ptapp/screens/common/chat_screen.dart';
import 'package:intl/intl.dart';

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

  Stream<int> _getUnreadCountStream(String clientId, String coachId) {
    return _unreadCountStreams.putIfAbsent(
      clientId,
      () => _dbService.getUnreadCount(clientId, coachId),
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'MESSAGES',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            // fontSize: 16,
            // letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.campaign_outlined,
                color: AppTheme.primaryColor,
                size: 30,
              ),
            ),
            onPressed: () =>
                _showBroadcastDialog(context, coachId, _dbService),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // SliverAppBar(
          //   expandedHeight: 60,
          //   // floating: true,
          //   // pinned: true,
          //   backgroundColor: AppTheme.backgroundColor,
          //   elevation: 0,
          //   flexibleSpace: FlexibleSpaceBar(
          //     title: const Text(
          //       'MESSAGES',
          //       style: TextStyle(
          //         fontWeight: FontWeight.w900,
          //         fontSize: 16,
          //         letterSpacing: 1.5,
          //         color: Colors.white,
          //       ),
          //     ),
          //     centerTitle: true,
          //     titlePadding: const EdgeInsets.all(30),
          //   ),
          //   actions: [
          //     IconButton(
          //       icon: Container(
          //         padding: const EdgeInsets.all(8),
          //         decoration: BoxDecoration(
          //           color: AppTheme.primaryColor.withOpacity(0.1),
          //           shape: BoxShape.circle,
          //         ),
          //         child: const Icon(
          //           Icons.campaign_outlined,
          //           color: AppTheme.primaryColor,
          //           size: 30,
          //         ),
          //       ),
          //       onPressed: () =>
          //           _showBroadcastDialog(context, coachId, _dbService),
          //     ),
          //     const SizedBox(width: 8),
          //   ],
          // ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: _buildSearchBar(),
            ),
          ),
          StreamBuilder<List<AppUser>>(
            stream: _clientsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final clients = snapshot.data ?? [];
              final filteredClients = clients
                  .where(
                    (c) => c.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
                  )
                  .toList();

              if (filteredClients.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState());
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final client = filteredClients[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildClientChatItem(context, client, coachId),
                    );
                  }, childCount: filteredClients.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Find client...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.forum_outlined,
              size: 48,
              color: AppTheme.primaryColor.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty ? 'No messages yet' : 'No clients found',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Start a conversation with your clients'
                : 'Try a different search term',
            style: const TextStyle(color: AppTheme.mutedTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildClientChatItem(
    BuildContext context,
    AppUser client,
    String coachId,
  ) {
    return StreamBuilder<int>(
      stream: _getUnreadCountStream(client.uid, coachId),
      builder: (context, unreadSnapshot) {
        final unreadCount = unreadSnapshot.data ?? 0;
        final hasUnread = unreadCount > 0;

        return StreamBuilder<ChatMessage?>(
          stream: _dbService.getLastMessageModel(client.uid, coachId),
          builder: (context, msgSnapshot) {
            final lastMsg = msgSnapshot.data;
            final timeStr = lastMsg != null
                ? _formatChatTime(lastMsg.timestamp)
                : '';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  if (hasUnread)
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          _buildPremiumAvatar(client, hasUnread),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      client.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: hasUnread
                                            ? FontWeight.w900
                                            : FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: hasUnread
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    if (timeStr.isNotEmpty)
                                      Text(
                                        timeStr,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: hasUnread
                                              ? AppTheme.primaryColor
                                                    .withOpacity(0.8)
                                              : AppTheme.mutedTextColor
                                                    .withOpacity(0.5),
                                          fontWeight: hasUnread
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        lastMsg?.text ?? 'No messages yet',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: hasUnread
                                              ? Colors.white.withOpacity(0.8)
                                              : AppTheme.mutedTextColor
                                                    .withOpacity(0.6),
                                          fontWeight: hasUnread
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (hasUnread)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          unreadCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPremiumAvatar(AppUser client, bool hasUnread) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: hasUnread
                  ? AppTheme.primaryColor.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              width: 1.5,
            ),
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.surfaceColor,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  client.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasUnread)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surfaceColor, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _formatChatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return DateFormat.Hm().format(dt);
    }
    return DateFormat('MMM d').format(dt);
  }

  void _showBroadcastDialog(
    BuildContext context,
    String coachId,
    DatabaseService dbService,
  ) async {
    final clients = await _dbService.getClients(coachId).first;
    if (clients.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No clients to broadcast to.')),
        );
      }
      return;
    }

    final controller = TextEditingController();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 32,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.campaign,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Broadcast Message',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Sending to ${clients.length} clients individually.',
              style: const TextStyle(color: AppTheme.mutedTextColor),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your announcement...',
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;

                  Navigator.pop(context);
                  final clientIds = clients.map((c) => c.uid).toList();
                  await _dbService.sendBroadcastMessage(
                    coachId,
                    clientIds,
                    text,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Broadcast sent to ${clients.length} clients!',
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'SEND BROADCAST',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
