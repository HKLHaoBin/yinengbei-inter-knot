import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:inter_knot/components/avatar.dart';
import 'package:inter_knot/api/api.dart';
import 'package:inter_knot/api/api_exception.dart';
import 'package:inter_knot/helpers/toast.dart';
import 'package:inter_knot/controllers/data.dart';
import 'package:inter_knot/helpers/profile_dialogs.dart';
import 'package:inter_knot/pages/history_page.dart';
import 'package:inter_knot/pages/liked_page.dart';
import 'package:inter_knot/pages/my_discussions_page.dart';

import 'package:inter_knot/pages/my_page_desktop.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  final scrollController = ScrollController();
  final api = Get.find<Api>();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Desktop/expanded layout uses new modern forum UI
    // Compact layout uses standard scrolling
    final isCompact = MediaQuery.of(context).size.width < 640;

    if (!isCompact) {
      return Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/pc-page-bg.png',
              fit: BoxFit.cover,
            ),
          ),
          const MyPageDesktop(),
        ],
      );
    }

    final child = Column(
      children: [
        const SizedBox(height: 16),
        Obx(() {
          final user = c.user.value;
          final isLogin = c.isLogin.value;
          return Card(
            color: const Color(0xff1E1E1E),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Avatar(
                        user?.avatar,
                        size: 64,
                        onTap: isLogin ? c.pickAndUploadAvatar : null,
                      ),
                      if (c.isUploadingAvatar.value)
                        const Positioned.fill(
                          child: ColoredBox(
                            color: Color(0x66000000),
                            child: Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user?.name ?? '未登录',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (isLogin) ...[
                          const SizedBox(height: 4),
                          Text(
                            'UID: ${user?.userId ?? "未知"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => showEditProfileDialog(context),
                            child: Text(
                              '编辑资料',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        Obx(() {
          final user = c.user.value;
          final isLogin = c.isLogin.value;

          return Card(
            color: const Color(0xff1E1E1E),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: !isLogin || user == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '绳网等级',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '登录后可查看你的绳网等级与每日签到奖励。',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xffA0A0A0),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: c.ensureLogin,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xffD7FF00),
                              ),
                            ),
                            child: const Text(
                              '登录以解锁签到',
                              style: TextStyle(color: Color(0xffD7FF00)),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildMobileLevelAndCheckInSection(context, user),
            ),
          );
        }),
        Card(
          color: const Color(0xff1E1E1E),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('我的帖子'),
            subtitle: Obx(
              () => Text(
                '共 ${c.myDiscussionsCount.value} 项',
                style: const TextStyle(color: Color(0xff808080)),
              ),
            ),
            onTap: () async {
              if (await c.ensureLogin()) {
                Get.to(
                  () => const MyDiscussionsPage(),
                  routeName: '/my-discussions',
                );
              }
            },
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ),
        Obx(
          () => Card(
            color: const Color(0xff1E1E1E),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('喜欢'),
              onTap: () => Get.to(
                () => const LikedPage(),
                routeName: '/liked',
              ),
              subtitle: Text(
                '共 ${c.bookmarks.length} 项',
                style: const TextStyle(color: Color(0xff808080)),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ),
        ),
        Obx(
          () => Card(
            color: const Color(0xff1E1E1E),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.history),
              title: const Text('历史记录'),
              onTap: () => Get.to(
                () => const HistoryPage(),
                routeName: '/history',
              ),
              subtitle: Text(
                '共 ${c.history.length} 项',
                style: const TextStyle(color: Color(0xff808080)),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ),
        ),
        Obx(() {
          if (c.isLogin()) {
            return Card(
              color: const Color(0xff1E1E1E),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                onTap: () => showLogoutDialog(context),
                title: const Text('退出登录'),
                leading: const Icon(Icons.logout),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            );
          } else {
            return Card(
              color: const Color(0xff1E1E1E),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                onTap: c.ensureLogin,
                title: const Text('登录'),
                leading: const Icon(Icons.login),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            );
          }
        }),
      ],
    );

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/pc-page-bg.png',
            fit: BoxFit.cover,
          ),
        ),
        SingleChildScrollView(
          controller: scrollController,
          child: child,
        ),
      ],
    );
  }

  Widget _buildMobileLevelAndCheckInSection(BuildContext context, dynamic user) {
    const levelTable = [
      (level: 6, exp: 3200, title: '不良布'),
      (level: 5, exp: 1600, title: '恶魔布'),
      (level: 4, exp: 800, title: '电击布'),
      (level: 3, exp: 400, title: '招财布'),
      (level: 2, exp: 200, title: '纸壳布'),
      (level: 1, exp: 0, title: '纸袋布'),
    ];

    final currentLevel = user.level ?? 1;
    final currentExp = user.exp ?? 0;

    final currentConfig = levelTable.firstWhere(
      (e) => e.level == currentLevel,
      orElse: () => levelTable.last,
    );

    final nextConfig = levelTable
        .cast<({int level, int exp, String title})?>()
        .firstWhere(
          (e) => e != null && e.level == currentLevel + 1,
          orElse: () => null,
        );

    double progress = 0.0;
    int nextExpTarget = currentExp;

    if (nextConfig != null) {
      final levelExp = currentConfig.exp;
      final nextExp = nextConfig.exp;
      nextExpTarget = nextExp;
      if (nextExp > levelExp) {
        progress = (currentExp - levelExp) / (nextExp - levelExp);
      }
      progress = progress.clamp(0.0, 1.0);
    } else {
      progress = 1.0;
      nextExpTarget = currentExp;
    }

    final hasCheckedInToday =
        user.lastCheckInDate == DateTime.now().toIso8601String().split('T')[0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '绳网等级',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message:
                  '每日签到 ：\n- 基础经验： 10 XP\n- 连签奖励：每天额外 +2 XP\n- 每日上限： 50 XP (基础 + 奖励)\n发布文章 ：\n- 每次发布： 12 XP\n发表评论 ：\n- 每次评论： 3 XP',
              child: Icon(
                Icons.help_outline,
                size: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lv.$currentLevel ${currentConfig.title}',
              style: const TextStyle(
                color: Color(0xffD7FF00),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              '$currentExp / $nextExpTarget XP',
              style: const TextStyle(
                color: Color(0xffA0A0A0),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[850],
            color: const Color(0xffD7FF00),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: hasCheckedInToday
              ? OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xff444444)),
                  ),
                  child: const Text(
                    '今日已签到',
                    style: TextStyle(color: Color(0xffA0A0A0)),
                  ),
                )
              : ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await api.checkIn();
                      await c.refreshSelfUserInfo();
                      if (context.mounted) {
                        showToast(
                          '签到成功 +${result.reward}EXP，已连续签到${result.consecutiveDays}天',
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        String msg = e.toString();
                        if (e is ApiException) {
                          msg = e.message;
                        }
                        showToast(
                          msg,
                          isError: true,
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffD7FF00),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: const Text('每日签到'),
                ),
        ),
      ],
    );
  }
}
