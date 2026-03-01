import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ptapp/providers/auth_provider.dart';
import 'package:ptapp/utils/theme.dart';
import 'package:ptapp/screens/common/change_password_screen.dart';
import 'package:ptapp/utils/navigation.dart';

class CoachProfileScreen extends StatefulWidget {
  const CoachProfileScreen({super.key});

  @override
  State<CoachProfileScreen> createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).userProfile;
    _nameController.text = user?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).updateName(_nameController.text.trim());
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  // Future<void> _seedDatabase() async {
  //   setState(() => _isLoading = true);
  //   try {
  //     final db = DatabaseService();
  //     final data = {
  //       "Quadriceps": [
  //         "Barbell Box Squat",
  //         "Barbell Bulgarian Split-Squat",
  //         "Barbell Front Squat",
  //         "Barbell Jump Squat",
  //         "Barbell Squat",
  //         "Barbell Standing Lunge",
  //         "Barbell Step Up",
  //         "Barbell Walking Lunge",
  //         "Body Weight Bulgarian Split-Squat",
  //         "Body Weight Pistol Squat",
  //         "Body Weight Squat",
  //         "Body Weight Standing Lunge",
  //         "Body Weight Step Up",
  //         "Body Weight Walking Lunge",
  //         "Dumbbell Body Weight Squat",
  //         "Dumbbell Bulgarian Split-Squat",
  //         "Dumbbell Goblet Squat",
  //         "Dumbbell Standing Lunge",
  //         "Dumbbell Step Up",
  //         "Dumbbell Walking Lunge",
  //         "Machine Hack Squat",
  //         "Machine Laying Leg Press",
  //         "Machine Leg Press",
  //         "Machine Seated Leg Press",
  //         "Machine Single-Leg Press",
  //         "Hip Ab/Adduction (Pulse)",
  //       ],
  //       "Glutes_Hamstrings": [
  //         "Barbell Deadlift",
  //         "Barbell Deadlifts from Blocks",
  //         "Barbell Deadlifts from Deficit",
  //         "Barbell Glute Bridge",
  //         "Barbell Hip Thrust",
  //         "Barbell Romanian Deadlift",
  //         "Barbell Stiff-Legged Deadlift",
  //         "Barbell Sumo Deadlift",
  //         "Body Weight Glute-Ham Raise",
  //         "Cable One-Legged Kickback",
  //         "Cable Pull Through",
  //         "Dumbbell Glute Bridge",
  //         "Dumbbell Hip Thrust",
  //         "Dumbbell Romanian Deadlift",
  //         "Dumbbell Stiff-Legged Deadlift",
  //         "Machine Glute-Ham Raise",
  //         "Machine Laying Leg Curl",
  //         "Machine Reverse Hyperextension",
  //         "Machine Seated Leg Curl",
  //         "Glute Bridge",
  //         "Machine Standing Leg Curl",
  //         "Banded Leg Extension",
  //         "Double Leg Hamstring Bridge",
  //       ],
  //       "Calves": [
  //         "Barbell Calf Raise",
  //         "Dumbbell Calf Raise",
  //         "Machine Calf Extension (Seated)",
  //         "Machine Calf Raise",
  //         "Machine Leg Press Calf Extension (Seated/Laying)",
  //         "Single Leg Seated Calf Raise",
  //       ],
  //       "Chest": [
  //         "Barbell Decline Bench Press",
  //         "Barbell Flat Bench Press",
  //         "Barbell Incline Bench Press",
  //         "Body Weight Decline Push-Up",
  //         "Body Weight Dip (Chest Variation)",
  //         "Body Weight Incline Push-Up",
  //         "Body Weight Push-Up",
  //         "Cable Chest Press (Seated)",
  //         "Cable Chest Press (Standing)",
  //         "Cable Crossover",
  //         "Cable Crossover (High Angle)",
  //         "Cable Crossover (Low Angle)",
  //         "Cable Flat Bench Fly",
  //         "Cable Incline Bench Fly",
  //         "Cable Incline Bench Press",
  //         "Dumbbell Decline Bench Fly",
  //         "Dumbbell Decline Bench Press",
  //         "Dumbbell Flat Bench Fly",
  //         "Dumbbell Flat Bench Press",
  //         "Dumbbell Incline Bench Fly",
  //         "Dumbbell Incline Bench Press",
  //         "Machine Assisted Dip (Chest Variation)",
  //         "Machine Butterfly",
  //         "Machine Chest Press",
  //         "Machine Decline Chest Press",
  //         "Machine Incline Chest Press",
  //         "Smith Machine Bench Press",
  //         "Smith Machine Decline Chest Press",
  //         "Smith Machine Incline Bench Press",
  //         "Weighted Decline Push-Up",
  //         "Weighted Dip (Chest Variation)",
  //         "Weighted Incline Push-Up",
  //         "Weighted Push-Up",
  //       ],
  //       "Back": [
  //         "Barbell Bent Over Row",
  //         "Barbell Chest-Supported T-Bar Row",
  //         "Barbell Incline Bench Row",
  //         "Barbell One-Arm Row",
  //         "Barbell Pendlay Row",
  //         "Barbell Reverse Grip Bent Over",
  //         "Barbell Shrug",
  //         "Barbell T-Bar Row",
  //         "Body Weight Back Extension",
  //         "Body Weight Inverted Row",
  //         "Body Weight Pull-Up",
  //         "Cable Narrow-Grip Lat Pull-Down",
  //         "Cable One-Arm Lat Pull-Down",
  //         "Cable One-Arm Row (Seated)",
  //         "Cable Reverse-Grip Lat Pull-Down",
  //         "Cable Row (Seated)",
  //         "Cable Straight-Arm Pull-Down",
  //         "Cable V-Bar Lat Pull-Down",
  //         "Cable Wide-Grip Lat Pull-Down",
  //         "Dumbbell Bent Over Row",
  //         "Dumbbell Incline Bench Row",
  //         "Dumbbell One-Arm Row",
  //         "Dumbbell Reverse Grip Bent Over",
  //         "Dumbbell Shrug",
  //         "Machine Assisted Pull-Up",
  //         "Machine Back Extension",
  //         "Machine Chest Supported Row",
  //         "Machine Iso Row",
  //         "Machine Shrug",
  //         "Smith Machine Bent Over Row",
  //         "Weighted Pull-Up",
  //       ],
  //       "Shoulders": [
  //         "Barbell Front Raise",
  //         "Barbell One-Arm Linear Jammer",
  //         "Barbell Push Press",
  //         "Barbell Seated Shoulder Press",
  //         "Barbell Standing Shoulder Press",
  //         "Barbell Upright Row",
  //         "Body Weight Handstand Push-Up",
  //         "Body Weight Pike Push-Up",
  //         "Cable Face Pull",
  //         "Cable Front Raise",
  //         "Cable Lateral Raise",
  //         "Cable Rear Delt Fly",
  //         "Cable Shoulder Press (Seated)",
  //         "Cable Standing Shoulder Press (Standing)",
  //         "Cable Upright Row",
  //         "Dumbbell Arnold Press",
  //         "Dumbbell Front Raise",
  //         "Dumbbell One-Arm Lateral Raise",
  //         "Dumbbell Rear Delt Raise",
  //         "Dumbbell Reverse Fly",
  //         "Dumbbell Seated Shoulder Press",
  //         "Dumbbell Side Lateral Raise",
  //         "Dumbbell Standing One-Arm Press",
  //         "Dumbbell Standing Shoulder Press",
  //         "Dumbbell Upright Row",
  //         "Machine Lateral Raise",
  //         "Machine Reverse Fly",
  //         "Machine Shoulder Press",
  //         "Machine Upright Row",
  //         "Smith Machine Shoulder Press",
  //       ],
  //       "Triceps": [
  //         "Barbell Close-Grip Bench Press",
  //         "Barbell Decline Bench Triceps Extension",
  //         "Barbell Flat Bench Triceps Extension",
  //         "Barbell Incline Bench Triceps Extension",
  //         "Barbell Overhead Triceps Extension",
  //         "Body Weight Bench Dip",
  //         "Body Weight Dips (Triceps Variation)",
  //         "Cable Decline Bench Triceps Extension",
  //         "Cable Flat Bench Triceps Extension",
  //         "Cable Incline Bench Triceps Extension",
  //         "Cable One-Arm Overhead Triceps Extension",
  //         "Cable Overhead Triceps Extension",
  //         "Cable Reverse-Grip Triceps Push-Down",
  //         "Cable Rope Triceps Push-Down",
  //         "Cable Straight-Bar Triceps Push-Down",
  //         "Cable Triceps Kickback",
  //         "Cable V-Bar Triceps Push-Down",
  //         "Dumbbell Bent Over Triceps Extension",
  //         "Dumbbell Close-Grip Bench Press",
  //         "Dumbbell Decline Bench Triceps Extension",
  //         "Dumbbell Flat Bench Triceps Extension",
  //         "Dumbbell Incline Bench Triceps Extension",
  //         "Dumbbell One-Arm Overhead Triceps Extension",
  //         "Dumbbell Overhead Triceps Extension",
  //         "Dumbbell Triceps Kickback",
  //         "Machine Assisted Dips (Triceps Variation)",
  //         "Machine Triceps Extension",
  //         "Smith Machine Close-Grip Bench Press",
  //         "Weighted Bench Dip",
  //         "Weighted Dips (Triceps Variation)",
  //       ],
  //       "Biceps": [
  //         "Barbell Close-Grip Biceps Curl",
  //         "Barbell Concentration Biceps Curl",
  //         "Barbell Preacher Biceps Curl",
  //         "Barbell Regular-Grip Biceps Curl",
  //         "Barbell Reverse-Grip Biceps Curl",
  //         "Barbell Wide-Grip Biceps Curl",
  //         "Body Weight Chin-Up",
  //         "Cable Bar Biceps Curl",
  //         "Cable Incline Bench Biceps Curl",
  //         "Cable One-Arm Biceps Curl",
  //         "Cable Overhead Curl",
  //         "Cable Rope Biceps Curl",
  //         "Dumbbell Alternate Biceps Curl",
  //         "Dumbbell Concentration Biceps Curl",
  //         "Dumbbell Hammer Biceps Curl",
  //         "Dumbbell Incline Bench Biceps Curl",
  //         "Dumbbell One-Arm Biceps Curl",
  //         "Dumbbell Preacher Biceps Curl",
  //         "Dumbbell Reverse-Grip Biceps Curl",
  //         "Dumbbell Reverse-Grip Biceps Curl",
  //         "Machine Assisted Chin-Up",
  //         "Machine Biceps Curl",
  //         "Machine Preacher Biceps Curl",
  //         "Weighted Chin-Up",
  //       ],
  //       "Abs": [
  //         "Barbell Plate Ab Twist",
  //         "Body Weight Ab Crunch",
  //         "Body Weight Hanging Leg Raise",
  //         "Body Weight Plank",
  //         "Dumbbell Ab Twist",
  //         "Machine Ab Crunch",
  //         "Weighted Hanging Leg Raise",
  //         "Weighted Plank",
  //       ],
  //       "Other": [
  //         "Barbell Wrist Curl",
  //         "Dumbbell Wrist Curl",
  //         "Neck Curl",
  //         "Neck Extension",
  //         "ITB release via Foam roller",
  //         "TFL release via Trigger ball",
  //       ],
  //     };
  //
  //     for (var group in data.entries) {
  //       for (var exName in group.value) {
  //         final exercise = Exercise(name: exName, muscleGroup: group.key);
  //         await db.addExercise(exercise);
  //       }
  //     }
  //
  //     setState(() => _isLoading = false);
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Database Seeded Successfully!')),
  //       );
  //     }
  //   } catch (e) {
  //     setState(() => _isLoading = false);
  //     if (mounted) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text('Error seeding: $e')));
  //     }
  //   }
  // }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Logout',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userProfile;

    return Scaffold(
      backgroundColor: AppTheme.getScaffoldColor(context),
      appBar: AppBar(
        title: const Text('PROFILE'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            // Premium Header with Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.4),
                          AppTheme.primaryColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: Icon(
                          Icons.person_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? 'Coach',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              'Professional Coach',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 32),

            // Profile Information Card
            _buildSectionHeader('Profile Information'),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.05),
                ),
              ),
              child: Column(
                children: [
                  _buildProfileTile(
                    label: 'Display Name',
                    value: user?.name ?? '',
                    icon: Icons.person_outline_rounded,
                    isEditable: true,
                    onEdit: () => setState(() => _isEditing = true),
                    showEditing: _isEditing,
                    controller: _nameController,
                    onSave: _updateName,
                    onCancel: () => setState(() {
                      _isEditing = false;
                      _nameController.text = user?.name ?? '';
                    }),
                    isLoading: _isLoading,
                  ),
                  _buildDivider(),
                  _buildProfileTile(
                    label: 'Email address',
                    value: user?.email ?? '',
                    icon: Icons.alternate_email_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account Security Card
            _buildSectionHeader('Account Settings'),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.05),
                ),
              ),
              child: Column(
                children: [
                  _buildActionTile(
                    label: 'Change Password',
                    icon: Icons.lock_outline_rounded,
                    onTap: () => NavigationService.navigateTo(
                      const ChangePasswordScreen(),
                      context: context,
                    ),
                  ),
                  // _buildDivider(),
                  // _buildActionTile(
                  //   label: 'Seed Database',
                  //   icon: Icons.upload_file_rounded,
                  //   onTap: _seedDatabase,
                  // ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Danger Zone / Session
            _buildActionTile(
              label: 'Logout Account',
              icon: Icons.logout_rounded,
              color: Colors.redAccent,
              onTap: _showLogoutConfirmation,
              showChevron: false,
              isCard: true,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required String label,
    required String value,
    required IconData icon,
    bool isEditable = false,
    VoidCallback? onEdit,
    bool showEditing = false,
    TextEditingController? controller,
    VoidCallback? onSave,
    VoidCallback? onCancel,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: showEditing
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          autofocus: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else ...[
                        IconButton(
                          icon: const Icon(
                            Icons.check_rounded,
                            color: Colors.greenAccent,
                            size: 20,
                          ),
                          onPressed: onSave,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: onCancel,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
          ),
          if (isEditable && !showEditing)
            IconButton(
              icon: Icon(
                Icons.edit_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color color = AppTheme.primaryColor,
    bool showChevron = true,
    bool isCard = false,
  }) {
    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color == Theme.of(context).colorScheme.primary
                  ? Theme.of(context).colorScheme.onSurface
                  : color,
            ),
          ),
          const Spacer(),
          if (showChevron)
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isCard ? 24 : 0),
        child: isCard
            ? Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: color.withOpacity(0.1)),
                ),
                child: tile,
              )
            : tile,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor.withOpacity(0.05),
      indent: 72,
      endIndent: 20,
    );
  }
}
