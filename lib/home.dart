import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game.dart';
import 'rule_settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _useJokersKey = 'use_jokers';

  bool useJokers = false;

  @override
  void initState() {
    super.initState();
    _loadRuleSettings();
  }

  Future<void> _loadRuleSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      useJokers = prefs.getBool(_useJokersKey) ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 56),
              const Text(
                'Take2',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'リーチとドーンで逆転する\n4人用トランプゲーム',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _MenuButton(
                label: 'ゲーム開始',
                icon: Icons.play_arrow_rounded,
                onTap: () async {
                  final playerCount = await showModalBottomSheet<int>(
                    context: context,
                    backgroundColor: const Color(0xFF123F35),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (_) => const _PlayerCountSheet(),
                  );

                  if (playerCount == null) return;

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GamePage(
                        playerCount: playerCount,
                        useJokers: useJokers,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              _MenuButton(
                label: '禁止ルール設定',
                icon: Icons.block_rounded,
                isSecondary: true,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RuleSettingsPage(),
                    ),
                  );

                  _loadRuleSettings();
                },
              ),
              const SizedBox(height: 14),
              _MenuButton(
                label: 'ルール確認',
                icon: Icons.menu_book_rounded,
                isSecondary: true,
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: const Color(0xFF123F35),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => const _RuleSheet(),
                  );
                },
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isSecondary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 26),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: isSecondary ? Colors.white : const Color(0xFF0E4B3C),
          backgroundColor: isSecondary ? Colors.white.withOpacity(0.14) : Colors.white,
          elevation: isSecondary ? 0 : 8,
          shadowColor: Colors.black.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: isSecondary
                ? BorderSide(color: Colors.white.withOpacity(0.18))
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _PlayerCountSheet extends StatelessWidget {
  const _PlayerCountSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '人数を選択',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            for (final count in [2, 3, 4]) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(count);
                  },
                  child: Text(
                    '$count 人で遊ぶ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              if (count != 4) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _RuleSheet extends StatelessWidget {
  const _RuleSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '基本ルール',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            _RuleText('マークか数字が同じカードを出せます。'),
            _RuleText('出せない時は1枚引き、それでも無理ならパス。'),
            _RuleText('手札合計が13以下ならリーチ。'),
            _RuleText('誰かが自分の合計と同じ数字を出したらドーンできます。'),
            _RuleText('8とジョーカーでは上がれません。'),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleText extends StatelessWidget {
  const _RuleText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '・$text',
        style: TextStyle(
          color: Colors.white.withOpacity(0.86),
          fontSize: 15,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
