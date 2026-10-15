import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_accent.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/utils/ui_utils.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    await auth.refreshFamilyMembers();
    if (!mounted) return;
    if (auth.currentUser != null) {
      await context.read<TaskProvider>().loadMyTasks(auth.currentUser!.id);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFile != null) {
      setState(() => _isLoadingImage = true);

      try {
        final Uint8List imageBytes = await pickedFile.readAsBytes();
        final String base64String = base64Encode(imageBytes);

        if (!mounted) return;
        await context.read<AuthProvider>().updateProfilePicture(base64String);

        if (mounted) {
          UiUtils.showSuccessModal(context, '¡Éxito!', 'Foto de perfil actualizada con éxito.');
        }
      } catch (e) {
        if (mounted) {
          UiUtils.showErrorModal(context, 'Error', 'Error al actualizar la foto: $e');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingImage = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final user = auth.currentUser;

    if (user == null) return const SizedBox.shrink();
    final String inviteCode = user.familyInviteCode ?? 'Sin código';


    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final textSecondaryColor = textColor.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<ThemeProvider>(
            builder: (_, themeProv, __) => IconButton(
              icon: Icon(
                themeProv.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: Colors.white,
              ),
              tooltip: themeProv.isDark ? 'Modo claro' : 'Modo oscuro',
              onPressed: () => themeProv.toggle(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      backgroundImage: user.profilePicture != null
                          ? MemoryImage(base64Decode(user.profilePicture!))
                          : null,
                      child: user.profilePicture == null
                          ? Text(
                              user.avatarInitial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    if (_isLoadingImage)
                      const Positioned.fill(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    if (!_isLoadingImage)
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'En línea',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: textSecondaryColor,
                  tooltip: 'Editar perfil',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Código de Invitación Familiar',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      inviteCode,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.copy, color: Theme.of(context).colorScheme.primary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inviteCode));
                    UiUtils.showSuccessModal(context, '¡Copiado!', 'Código copiado al portapapeles');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.groups_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Familia',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.familyName ?? 'Sin nombre',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Rendimiento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricChip(
                'Total',
                '${taskProvider.totalCount}',
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              _metricChip(
                'Hechas',
                '${taskProvider.completedCount}',
                AppColors.completedCheck.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.2),
                AppColors.completedCheck,
              ),
              const SizedBox(width: 10),
              _metricChip(
                'Pendientes',
                '${taskProvider.pendingCount}',
                AppColors.priorityHigh.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.2),
                AppColors.priorityHigh,
              ),
            ],
          ),

          const SizedBox(height: 16),

          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              leading: Icon(Icons.color_lens_outlined, color: Theme.of(context).colorScheme.primary),
              title: Text(
                'Color de tema',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
              subtitle: Text(
                'Personaliza el color de la aplicación',
                style: TextStyle(color: textSecondaryColor, fontSize: 13),
              ),
              trailing: Icon(Icons.chevron_right, color: textSecondaryColor),
              onTap: () => _showAppearanceModal(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11.5, color: fg)),
          ],
        ),
      ),
    );
  }

  void _showAppearanceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Color de tema',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Consumer<ThemeProvider>(
                builder: (_, themeProv, __) => Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: AppAccent.values.map((accent) {
                    final isSelected = themeProv.accent == accent;
                    return GestureDetector(
                      onTap: () => themeProv.setAccent(accent),
                      child: AnimatedScale(
                        scale: isSelected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Tooltip(
                          message: accent.label,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [accent.gradientStart, accent.primary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2.5)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: accent.primary.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                                : null,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
