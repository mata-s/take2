import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/user_profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _userNameKey = 'user_name';

  final TextEditingController _nameController = TextEditingController();
  final UserProfileService _userProfileService = UserProfileService();

  String friendId = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final code = await _userProfileService.getOrCreateFriendCode();

    if (!mounted) return;

    setState(() {
      friendId = code;
      _nameController.text = prefs.getString(_userNameKey) ?? '';
    });
  }

  Future<void> _saveName() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _userNameKey,
      _nameController.text.trim(),
    );

    await _userProfileService.saveName(
      _nameController.text.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('名前を保存しました'),
      ),
    );
  }

  Future<void> _copyFriendId() async {
    await Clipboard.setData(
      ClipboardData(text: friendId),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('IDをコピーしました'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E4B3C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('プロフィール'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '名前',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: const OutlineInputBorder(),
              hintText: 'プレイヤー名を入力',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saveName,
            child: const Text('保存'),
          ),
          const SizedBox(height: 24),
          const Text(
            'フレンドID',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(friendId),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: friendId.isEmpty ? null : _copyFriendId,
            icon: const Icon(Icons.copy),
            label: const Text('IDをコピー'),
          ),
        ],
      ),
    );
  }
}
