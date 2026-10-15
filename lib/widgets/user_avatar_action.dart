import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class UserAvatarAction extends StatefulWidget {
  final VoidCallback? onTap;

  const UserAvatarAction({super.key, this.onTap});

  @override
  State<UserAvatarAction> createState() => _UserAvatarActionState();
}

class _UserAvatarActionState extends State<UserAvatarAction> {
  String? _cachedSource;
  Uint8List? _cachedBytes;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    if (user.profilePicture != _cachedSource) {
      _cachedSource = user.profilePicture;
      if (_cachedSource != null) {
        try {
          _cachedBytes = base64Decode(_cachedSource!);
        } catch (_) {
          _cachedBytes = null;
        }
      } else {
        _cachedBytes = null;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: widget.onTap,
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white24,
          backgroundImage: _cachedBytes != null ? MemoryImage(_cachedBytes!) : null,
          child: _cachedBytes == null
              ? Text(
                  user.avatarInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
