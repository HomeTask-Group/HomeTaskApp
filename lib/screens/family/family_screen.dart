import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/task_card.dart';
import '../../widgets/user_avatar_action.dart';

class FamilyScreen extends StatefulWidget {
  final VoidCallback? onAvatarTap;
  const FamilyScreen({super.key, this.onAvatarTap});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen>
    with WidgetsBindingObserver {
  UserModel? _selectedMember;

  final Map<String, Uint8List> _imageCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    await context.read<AuthProvider>().refreshFamilyMembers();
    await context.read<TaskProvider>().loadAllTasks();
  }

  Uint8List? _decodedImage(UserModel m) {
    if (m.profilePicture == null) return null;
    return _imageCache.putIfAbsent(m.id, () => base64Decode(m.profilePicture!));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _selectedMember == null
              ? 'Familia ${auth.currentUser?.familyName ?? ''}'.trim()
              : _selectedMember!.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: _selectedMember != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedMember = null),
              )
            : null,
        actions: [
          UserAvatarAction(onTap: widget.onAvatarTap),
        ],
      ),
      body: _selectedMember == null
          ? _buildGrid(auth.familyMembers, taskProvider.allTasks, context)
          : _buildMemberDetail(_selectedMember!, taskProvider.allTasks),
    );
  }

  int _pendingFor(String userId, List<TaskModel> tasks) => tasks
      .where(
        (t) => t.assignedToId == userId && t.status == TaskStatus.pendiente,
      )
      .length;

  Widget _buildGrid(
    List<UserModel> members,
    List<TaskModel> tasks,
    BuildContext context,
  ) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: members.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 100),
                Center(
                  child: Text(
                    'Aún no hay integrantes registrados',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Integrantes del hogar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.95,
                        ),
                    itemCount: members.length,
                    itemBuilder: (_, i) {
                      final m = members[i];
                      final pending = _pendingFor(m.id, tasks);
                      return GestureDetector(
                        key: ValueKey(m.id),
                        onTap: () => setState(() => _selectedMember = m),
                        child: _buildMemberCard(m, pending),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMemberCard(UserModel m, int pending) {
    final imageBytes = _decodedImage(m);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Theme.of(context).colorScheme.primary,
            backgroundImage: imageBytes != null
                ? MemoryImage(imageBytes)
                : null,
            child: imageBytes == null
                ? Text(
                    m.avatarInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            m.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            m.role.label,
            style: TextStyle(
              fontSize: 11.5,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$pending pendientes',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberDetail(UserModel member, List<TaskModel> allTasks) {
    final tasks = allTasks.where((t) => t.assignedToId == member.id).toList();
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: tasks.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                Center(child: Text('Sin tareas')),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              itemCount: tasks.length,
              itemBuilder: (_, i) {
                final t = tasks[i];
                return TaskCard(key: ValueKey(t.id), task: t);
              },
            ),
    );
  }
}
