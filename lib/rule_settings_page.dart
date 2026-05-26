import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RuleSettingsPage extends StatefulWidget {
  const RuleSettingsPage({super.key});

  @override
  State<RuleSettingsPage> createState() => _RuleSettingsPageState();
}

class _RuleSettingsPageState extends State<RuleSettingsPage> {
  static const _useJokersKey = 'use_jokers';

  bool useJokers = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      useJokers = prefs.getBool(_useJokersKey) ?? false;
      isLoading = false;
    });
  }

  Future<void> _toggleUseJokers(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useJokersKey, value);

    if (!mounted) return;

    setState(() {
      useJokers = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E4B3C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          '禁止ルール',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ジョーカーを使う',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'OFFにするとジョーカーを抜きます。',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.72),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Switch(
                          value: useJokers,
                          activeColor: const Color(0xFFFFC857),
                          onChanged: _toggleUseJokers,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
