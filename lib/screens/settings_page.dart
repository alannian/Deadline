import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_strings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // ── 外观 ──
              _SectionHeader(title: s.appearance, isDark: isDark),
              SwitchListTile(
                title: Text(s.darkMode),
                subtitle: Text(
                  settings.themeMode == ThemeMode.dark ? s.enabled : s.disabled,
                  style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 13),
                ),
                secondary: Icon(
                  settings.themeMode == ThemeMode.dark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                ),
                value: settings.themeMode == ThemeMode.dark,
                onChanged: (v) {
                  settings.setThemeMode(
                      v ? ThemeMode.dark : ThemeMode.light);
                },
              ),

              const SizedBox(height: 16),

              // ── 语言 ──
              _SectionHeader(title: s.language, isDark: isDark),
              ListTile(
                leading: const Icon(Icons.language_rounded),
                title: Text(s.languageLabel),
                subtitle: Text(
                  s.currentLanguage,
                  style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 13),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  settings.setLanguage(
                      settings.language == 'zh' ? 'en' : 'zh');
                },
              ),

              const SizedBox(height: 16),

              // ── 目标日期 ──
              _SectionHeader(title: s.targetDate, isDark: isDark),
              ListTile(
                leading: const Icon(Icons.flag_rounded),
                title: Text(s.deadlineDateLabel),
                subtitle: Text(
                  settings.deadline != null
                      ? s.deadlineInfo(
                          settings.deadline!.year,
                          settings.deadline!.month,
                          settings.deadline!.day,
                          settings.remainingDays)
                      : s.notSet,
                  style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 13),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (settings.deadline != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => settings.clearDeadline(),
                        tooltip: s.clear,
                      ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    locale: const Locale('zh', 'CN'),
                    initialDate:
                        settings.deadline ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2099),
                  );
                  if (picked != null) {
                    if (!context.mounted) return;
                    final reward =
                        await _askReward(context, settings.deadlineReward);
                    if (reward == null || reward.trim().isEmpty) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.rewardRequired)),
                      );
                      return;
                    }
                    settings.setDeadlineWithReward(picked, reward);
                  }
                },
              ),

              const SizedBox(height: 16),

              // ── 页面顺序 ──
              _SectionHeader(title: s.pageOrder, isDark: isDark),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  s.dragToReorder,
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[600] : Colors.grey[500]),
                ),
              ),
              _PageOrderEditor(settings: settings, isDark: isDark),

              const SizedBox(height: 32),

              // ── 打赏 ──
              _SectionHeader(title: s.donation, isDark: isDark),
              ListTile(
                leading: const Icon(Icons.favorite_rounded, color: Colors.red),
                title: Text(s.donationDesc),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showDonationPage(context),
              ),
              ListTile(
                leading: const Icon(Icons.feedback_outlined, color: Colors.orange),
                title: Text(s.feedbackDesc),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showContactPage(context),
              ),

              const SizedBox(height: 16),

              // ── 关于 ──
              _SectionHeader(title: s.about, isDark: isDark),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('Deadline'),
                subtitle: Text(s.appSubtitle,
                    style: const TextStyle(fontSize: 13)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('made with ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Icon(Icons.favorite, color: Colors.red, size: 14),
                        Text(' for productivity', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '创建于 2026年2月\n作者：Tao\n\n© 2026 Tao. All rights reserved.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _showDonationPage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('打赏')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('感谢你的支持！',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 32),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/qrcode.png', width: 240, height: 240, fit: BoxFit.cover),
                ),
                const SizedBox(height: 24),
                Text('扫码打赏',
                    style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _askReward(BuildContext context, String? initialReward) {
    final s = S.read(context);
    final ctrl = TextEditingController(text: initialReward ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.setDeadlineReward),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: s.rewardHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(s.ok),
          ),
        ],
      ),
    );
  }

  void _showContactPage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.read(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(s.contactTitle)),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.mail_outline_rounded, size: 56, color: Color(0xFF42A5F5)),
                const SizedBox(height: 24),
                Text(s.contactTitle,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 32),
                _contactItem(Icons.email_rounded, '邮箱 / Email', '1027999125@qq.com', isDark),
                const Spacer(),
                Text(
                  '欢迎反馈问题、提出建议或进行合作交流',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactItem(IconData icon, String label, String value, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF42A5F5)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                )),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2),
        ),
      ),
    );
  }
}

class _PageOrderEditor extends StatelessWidget {
  final SettingsProvider settings;
  final bool isDark;

  const _PageOrderEditor({
    required this.settings,
    required this.isDark,
  });

  static const _pageIcons = [
    Icons.checklist_rounded,
    Icons.psychology_alt_outlined,
    Icons.note_alt_outlined,
    Icons.settings_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final order = settings.pageOrder;
    final s = S.of(context);
    final pageNames = s.navLabels;

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: order.length,
      onReorder: (oldIndex, newIndex) {
        final updated = List<int>.from(order);
        if (newIndex > oldIndex) newIndex--;
        final item = updated.removeAt(oldIndex);
        updated.insert(newIndex, item);
        settings.setPageOrder(updated);
      },
      itemBuilder: (ctx, index) {
        final pageIndex = order[index];
        return ListTile(
          key: ValueKey(pageIndex),
          leading: Icon(_pageIcons[pageIndex]),
          title: Text(pageNames[pageIndex]),
          trailing: const Icon(Icons.drag_handle_rounded),
        );
      },
    );
  }
}
