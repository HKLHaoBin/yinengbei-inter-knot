import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:inter_knot/components/avatar.dart';
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
}
