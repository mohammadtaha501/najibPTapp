import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:untitled3/models/user_model.dart';
import 'package:untitled3/providers/auth_provider.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/models/program_model.dart';
import 'package:untitled3/utils/theme.dart';
import 'package:untitled3/screens/coach/program_editor.dart';
import 'package:untitled3/screens/coach/client_detail.dart';
import 'package:untitled3/screens/coach/client_creation_screen.dart';

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showPublicPrograms = false;
  String _clientFilter = 'all'; // 'all', 'active', 'blocked'
  final _dbService = DatabaseService();
  late Stream<List<AppUser>> _clientsStream;
  late Stream<List<Program>> _programsStream;
  late Stream<List<Program>> _publicProgramsStream;
  final Map<String, Stream<int>> _unreadCountStreams = {};
  bool _streamsInitialized = false;

  Stream<int> _getUnreadCountStream(String clientId, String coachId) {
    return _unreadCountStreams.putIfAbsent(
      clientId,
      () => _dbService.getUnreadCount(clientId, coachId),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_streamsInitialized) {
      final authProvider = Provider.of<AuthProvider>(context);
      final coachId = authProvider.userProfile?.uid;
      if (coachId != null) {
        _clientsStream = _dbService.getClients(coachId);
        _programsStream = _dbService.getCoachPrograms(coachId);
        _publicProgramsStream = _dbService.getPublicPrograms(coachId);
        _streamsInitialized = true;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSummaryStats(DatabaseService dbService, String coachId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: StreamBuilder<List<AppUser>>(
        stream: _clientsStream,
        builder: (context, snapshot) {
          final totalClients = snapshot.data?.length ?? 0;
          
          return StreamBuilder<List<Program>>(
            stream: _programsStream,
            builder: (context, progSnapshot) {
              final programs = progSnapshot.data ?? [];
              final activeClientsCount = programs
                .where((p) => p.status == ProgramStatus.active && p.assignedClientId != null)
                .map((p) => p.assignedClientId)
                .toSet()
                .length;
              
              return Row(
                children: [
                  _statsBox('CLIENTS', '$totalClients', Icons.people_outline, const Color(0xFF5856D6)),
                  const SizedBox(width: 12),
                  _statsBox('ACTIVE', '$activeClientsCount', Icons.bolt, const Color(0xFFFF2D55)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _statsBox(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.mutedTextColor, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Welcome ${authProvider.userProfile?.name ?? 'Coach'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutConfirmation(context, authProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryStats(_dbService, authProvider.userProfile!.uid),
          _buildSearchOverlay(context),
          _buildViewToggle(),
          if (!_showPublicPrograms) _buildClientFilter(),
          Expanded(
            child: _showPublicPrograms 
              ? _buildPublicProgramsList(_dbService, authProvider.userProfile!.uid)
              : _buildClientsList(_dbService, authProvider.userProfile!.uid),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => ProgramEditor(coachId: authProvider.userProfile!.uid))
        ),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildSearchOverlay(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showAddClientDialog(context),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_add, color: Colors.black, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: _showPublicPrograms ? 'Search programs...' : 'Search clients...',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.mutedTextColor),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20, color: AppTheme.mutedTextColor),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip('All', 'all', Icons.people_outline),
          const SizedBox(width: 8),
          _filterChip('Active', 'active', Icons.check_circle_outline),
          const SizedBox(width: 8),
          _filterChip('Blocked', 'blocked', Icons.block),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, IconData icon) {
    final isSelected = _clientFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _clientFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.black : AppTheme.mutedTextColor,
              ),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : AppTheme.mutedTextColor,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientListItem(BuildContext context, AppUser client) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientDetailScreen(client: client))),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white10,
              child: Text(client.name[0], style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${client.email} • 0 Notes', style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 12)),
                ],
              ),
            ),
            StreamBuilder<int>(
              stream: _getUnreadCountStream(client.uid, Provider.of<AuthProvider>(context, listen: false).userProfile!.uid),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (client.isBlocked) return const Icon(Icons.cancel, color: Colors.redAccent, size: 18);
                if (count == 0) return const Icon(Icons.check_circle, color: Color(0xFF4CD964), size: 18);
                return Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                  child: Text(
                    '$count',
                    style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }



  void _showLogoutConfirmation(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: AppTheme.mutedTextColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedTextColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              auth.signOut();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  void _showAddClientDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClientCreationScreen()),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _toggleButton('Clients', !_showPublicPrograms)),
          Expanded(child: _toggleButton('General Programs', _showPublicPrograms)),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _showPublicPrograms = (label == 'General Programs')),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : AppTheme.mutedTextColor,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildClientsList(DatabaseService dbService, String coachId) {
    return StreamBuilder<List<AppUser>>(
      stream: _clientsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading clients: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        var clients = snapshot.data ?? [];
        
        // Apply status filter
        if (_clientFilter == 'active') {
          clients = clients.where((c) => !c.isBlocked).toList();
        } else if (_clientFilter == 'blocked') {
          clients = clients.where((c) => c.isBlocked).toList();
        }
        
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          clients = clients.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        }
        
        if (clients.isEmpty) {
          return Center(child: Text(_searchQuery.isEmpty ? 'No clients found.' : 'No clients found.', style: const TextStyle(color: AppTheme.mutedTextColor)));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: clients.length,
          itemBuilder: (context, index) => _buildClientListItem(context, clients[index]),
        );
      },
    );
  }

  Widget _buildPublicProgramsList(DatabaseService dbService, String coachId) {
    return StreamBuilder<List<Program>>(
      stream: _publicProgramsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading programs: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        var programs = snapshot.data ?? [];
        if (_searchQuery.isNotEmpty) {
          programs = programs.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        }
        if (programs.isEmpty) {
          return Center(child: Text(_searchQuery.isEmpty ? 'No general programs yet.' : 'No programs found.', style: const TextStyle(color: AppTheme.mutedTextColor)));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: programs.length,
          itemBuilder: (context, index) {
            final p = programs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
              ),
              child: ListTile(
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Text('${p.totalWeeks} Weeks • Public', style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProgramEditor(coachId: coachId, programToEdit: p))),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => _confirmDeleteProgram(context, p),
                    ),
                  ],
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteProgram(BuildContext context, Program program) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete Program?', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${program.name}"?', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            const Text(
              'WARNING: If you delete this program, it will also get deleted for all the users who are currently performing it and all their progress logs for this program will be lost.',
              style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
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
              Navigator.pop(context);
              try {
                await _dbService.deleteProgramCompletely(program.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Program and all its instances deleted.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting program: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('DELETE EVERYWHERE'),
          ),
        ],
      ),
    );
  }
}
