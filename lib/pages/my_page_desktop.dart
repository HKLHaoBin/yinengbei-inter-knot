import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:inter_knot/api/api.dart';
import 'package:inter_knot/constants/api_config.dart';
import 'package:inter_knot/components/avatar.dart';
import 'package:inter_knot/components/discussions_grid.dart';
import 'package:inter_knot/controllers/data.dart';
import 'package:inter_knot/helpers/profile_dialogs.dart';
import 'package:inter_knot/helpers/throttle.dart';
import 'package:inter_knot/models/h_data.dart';
import 'package:intl/intl.dart';

class MyPageDesktop extends StatefulWidget {
  const MyPageDesktop({super.key});

  @override
  State<MyPageDesktop> createState() => _MyPageDesktopState();
}

class _MyPageDesktopState extends State<MyPageDesktop>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // 1. Header Box
              _buildHeaderCard(context),
              const SizedBox(height: 24),
              // 2. Main Content
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Box (Large) - Tabs & Content
                    Expanded(
                      flex: 3,
                      child: _buildLeftContentBox(context),
                    ),
                    const SizedBox(width: 24),
                    // Right Box (Small) - Placeholder
                    Expanded(
                      flex: 1,
                      child: _buildRightPlaceholderBox(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      color: const Color(0xff1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Obx(() {
          final user = c.user.value;
          final isLogin = c.isLogin.value;
          final dateFormat = DateFormat('yyyy-MM-dd');
          final regTime = user?.createdAt != null
              ? dateFormat.format(user!.createdAt!)
              : '未知';

          return Row(
            children: [
              // Avatar
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.5),
                        width: 4,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Avatar(
                        user?.avatar,
                        size: 100,
                      ),
                    ),
                  ),
                  if (c.isUploadingAvatar.value)
                    const Positioned.fill(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              const SizedBox(width: 24),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user?.name ?? '未登录',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (isLogin)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'UID: ${user?.userId ?? "未知"}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '注册时间: $regTime',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: c.ensureLogin,
                        icon: const Icon(Icons.login),
                        label: const Text('立即登录'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffD7FF00),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
              // Account Actions (Logout)
              if (isLogin)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () => showEditProfileDialog(context),
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      label: const Text('编辑资料',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => showLogoutDialog(context),
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('退出登录',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLeftContentBox(BuildContext context) {
    return Card(
      color: const Color(0xff1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _buildCustomTabBar(context),
          ),
          const Divider(height: 1, color: Color(0xff333333)),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MyDiscussionsTab(),
                _MyFavoritesTab(),
                Obx(() => DiscussionGrid(
                      list: c.history(),
                      hasNextPage: false,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPlaceholderBox(BuildContext context) {
    return Card(
      color: const Color(0xff1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: const Center(
        child: Text(
          '更多功能开发中...',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildCustomTabBar(BuildContext context) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final selectedIndex = _tabController.index;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabItem(context, '我的帖子', 0, selectedIndex == 0),
              _buildTabItem(context, '我的收藏', 1, selectedIndex == 1),
              _buildTabItem(context, '浏览历史', 2, selectedIndex == 2),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabItem(
      BuildContext context, String text, int index, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            _tabController.animateTo(index);
          },
          child: SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xffD7FF00),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyDiscussionsTab extends StatefulWidget {
  @override
  State<_MyDiscussionsTab> createState() => _MyDiscussionsTabState();
}

class _MyDiscussionsTabState extends State<_MyDiscussionsTab> {
  final api = Get.find<Api>();
  final discussions = <HDataModel>{}.obs;
  final hasNextPage = true.obs;
  String? endCursor;
  bool isLoading = false;
  late final Worker _loginWorker;

  late final fetchData = retryThrottle(
    _loadMore,
    const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    _loadMore();
    _loginWorker = ever(c.isLogin, (v) {
      if (v == true) {
        _refresh();
      } else {
        discussions.clear();
        endCursor = null;
        hasNextPage.value = true;
      }
    });
  }

  Future<void> _loadMore() async {
    if (isLoading || !hasNextPage.value) return;

    final authorId = c.authorId.value ?? c.user.value?.authorId;
    if (authorId == null || authorId.isEmpty) {
      await c.refreshSelfUserInfo();
      if (c.authorId.value == null && c.user.value?.authorId == null) {
        hasNextPage.value = false;
        return;
      }
    }

    isLoading = true;
    try {
      final res = await api.getUserDiscussions(
        c.authorId.value ?? c.user.value!.authorId!,
        endCursor ?? '',
      );

      if (res.nodes.isNotEmpty) {
        discussions.addAll(res.nodes);
        endCursor = res.endCursor;
        hasNextPage.value = res.hasNextPage;
      } else {
        hasNextPage.value = false;
      }
    } catch (e) {
      // Quiet fail or log
    } finally {
      isLoading = false;
    }
  }

  Future<void> _refresh() async {
    discussions.clear();
    endCursor = null;
    hasNextPage.value = true;
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return DiscussionGrid(
        list: discussions(),
        hasNextPage: hasNextPage(),
        fetchData: fetchData,
      );
    });
  }

  @override
  void dispose() {
    _loginWorker.dispose();
    super.dispose();
  }
}

class _MyFavoritesTab extends StatefulWidget {
  @override
  State<_MyFavoritesTab> createState() => _MyFavoritesTabState();
}

class _MyFavoritesTabState extends State<_MyFavoritesTab> {
  final api = Get.find<Api>();
  final discussions = <HDataModel>{}.obs;
  final hasNextPage = true.obs;
  String? endCursor;
  bool isLoading = false;
  late final Worker _loginWorker;

  late final fetchData = retryThrottle(
    _loadMore,
    const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    _loadMore();
    _loginWorker = ever(c.isLogin, (v) {
      if (v == true) {
        _refresh();
      } else {
        discussions.clear();
        endCursor = null;
        hasNextPage.value = true;
      }
    });
  }

  Future<void> _loadMore() async {
    if (isLoading || !hasNextPage.value) return;

    final authorId = c.authorId.value ?? c.user.value?.authorId;
    if (authorId == null || authorId.isEmpty) {
      await c.refreshSelfUserInfo();
      if (c.authorId.value == null && c.user.value?.authorId == null) {
        hasNextPage.value = false;
        return;
      }
    }

    isLoading = true;
    try {
      final res = await api.getFavorites(
        c.user.value!.login,
        endCursor ?? '',
      );

      if (res.items.isNotEmpty) {
        discussions.addAll(res.items);
        endCursor = (int.parse(endCursor ?? '0') + ApiConfig.defaultPageSize)
            .toString();
        hasNextPage.value = res.items.length >= ApiConfig.defaultPageSize;
      } else {
        hasNextPage.value = false;
      }
    } catch (e) {
      // Quiet fail or log
    } finally {
      isLoading = false;
    }
  }

  Future<void> _refresh() async {
    discussions.clear();
    endCursor = null;
    hasNextPage.value = true;
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return DiscussionGrid(
        list: discussions(),
        hasNextPage: hasNextPage(),
        fetchData: fetchData,
      );
    });
  }

  @override
  void dispose() {
    _loginWorker.dispose();
    super.dispose();
  }
}
