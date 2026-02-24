import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:inter_knot/api/api.dart';
import 'package:markdown_widget/markdown_widget.dart' hide ImageViewer;
import 'package:inter_knot/components/avatar.dart';
import 'package:inter_knot/components/click_region.dart';
import 'package:inter_knot/components/comment.dart';
import 'package:inter_knot/components/discussion_card.dart'
    show NetworkImageBox;
import 'package:inter_knot/components/image_viewer.dart';
import 'package:inter_knot/components/my_chip.dart';
import 'package:inter_knot/constants/globals.dart';
import 'package:inter_knot/controllers/data.dart';
import 'package:inter_knot/gen/assets.gen.dart';
import 'package:inter_knot/helpers/dialog_helper.dart';
import 'package:inter_knot/helpers/logger.dart';
import 'package:inter_knot/helpers/smooth_scroll.dart';
import 'package:inter_knot/helpers/toast.dart';
import 'package:inter_knot/models/discussion.dart';
import 'package:inter_knot/models/h_data.dart';
import 'package:inter_knot/pages/create_discussion_page.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DiscussionPage extends StatefulWidget {
  const DiscussionPage({
    super.key,
    required this.discussion,
    required this.hData,
  });

  final DiscussionModel discussion;
  final HDataModel hData;

  @override
  State<DiscussionPage> createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<DiscussionPage> {
  final scrollController = ScrollController();
  final leftScrollController =
      ScrollController(); // New controller for left side
  final c = Get.find<Controller>();
  final actionButtonsKey = GlobalKey<DiscussionActionButtonsState>(); // Add key
  bool _isLoadingMore = false;
  bool _isInitialLoading = false;
  Timer? _newCommentCheckTimer;
  int _newCommentCount = 0;
  int _serverCommentCount = 0;

  Future<void> _fetchArticleDetails() async {
    try {
      final fullDiscussion =
          await Get.find<Api>().getArticleDetail(widget.discussion.id);
      if (mounted) {
        setState(() {
          widget.discussion.updateFrom(fullDiscussion);
        });
      }
    } catch (e) {
      logger.e('Failed to fetch article details', error: e);
    }
  }

  @override
  void initState() {
    super.initState();
    Future(() {
      c.history({widget.hData, ...c.history});
    });

    widget.discussion.comments.clear();
    _isInitialLoading = true;
    _startNewCommentCheck();
    _fetchArticleDetails();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wasRead = widget.discussion.isRead;
      c.markDiscussionReadAndViewed(widget.discussion);
      if (!wasRead) {
        Get.find<Api>().markAsRead(widget.discussion.id);
      }
      Get.find<Api>().viewArticle(widget.discussion.databaseId.toString());
    });

    scrollController.addListener(() {
      if (_isLoadingMore) return;
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;
      if (maxScroll - currentScroll < 200 && widget.discussion.hasNextPage()) {
        _isLoadingMore = true;
        widget.discussion.fetchComments().then((_) {
          if (mounted) {
            setState(() {});
          }
        }).catchError((e) {
          logger.e('Error loading more comments', error: e);
        }).whenComplete(() {
          _isLoadingMore = false;
        });
      }
    });

    // Delay initial loading until transition animation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route != null &&
          route.animation != null &&
          !route.animation!.isCompleted) {
        void listener(AnimationStatus status) {
          if (status == AnimationStatus.completed) {
            route.animation!.removeStatusListener(listener);
            _startInitialLoad();
          }
        }

        route.animation!.addStatusListener(listener);
      } else {
        _startInitialLoad();
      }
    });
  }

  void _startInitialLoad() {
    if (!mounted) return;
    widget.discussion.fetchComments().then((e) async {
      try {
        while (scrollController.hasClients &&
            scrollController.position.maxScrollExtent == 0 &&
            widget.discussion.hasNextPage()) {
          await widget.discussion.fetchComments();
        }
      } catch (e, s) {
        logger.e('Failed to get scroll position', error: e, stackTrace: s);
      }
    }).whenComplete(() {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    });
  }

  void _startNewCommentCheck() {
    _newCommentCheckTimer?.cancel();
    _newCommentCheckTimer =
        Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkNewComments();
    });
  }

  Future<void> _checkNewComments() async {
    try {
      final count = await Get.find<Api>().getCommentCount(widget.discussion.id);
      if (count > widget.discussion.commentsCount) {
        if (mounted) {
          setState(() {
            _serverCommentCount = count;
            _newCommentCount = count - widget.discussion.commentsCount;
          });
        }
      } else {
        // If server count is less or equal (e.g. deletion), sync it?
        // Or just ignore.
        if (_newCommentCount > 0 && mounted) {
          setState(() {
            _newCommentCount = 0;
          });
        }
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _newCommentCheckTimer?.cancel();
    scrollController.dispose();
    leftScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutQuart,
          );
        }
      });
    }
  }

  Widget _buildNewCommentNotification() {
    if (_newCommentCount <= 0) return const SizedBox.shrink();

    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          color: const Color(0xffD7FF00),
          borderRadius: BorderRadius.circular(20),
          elevation: 4,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              widget.discussion.commentsCount = _serverCommentCount;
              setState(() {
                _newCommentCount = 0;
              });

              // Always try to fetch if we have new comments
              if (widget.discussion.comments.isNotEmpty) {
                // Mark hasNextPage true to force fetch even if we thought we were at end
                widget.discussion.comments.last.hasNextPage = true;
              }

              await widget.discussion.fetchComments();
              if (mounted) setState(() {});
              _scrollToBottom();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_downward,
                    size: 16,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '有 $_newCommentCount 条新评论',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isDesktop = screenW >= 800;
    final double baseFactor = isDesktop ? 0.7 : 0.9;
    final double zoomScale = isDesktop ? 1.1 : 1.0;
    final double layoutFactor = baseFactor * zoomScale;

    return SafeArea(
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final safeW = constraints.maxWidth;
            final safeH = constraints.maxHeight;
            return SizedBox(
              width: safeW * layoutFactor,
              height: safeH * layoutFactor,
              child: FittedBox(
                child: SizedBox(
                  width: safeW * baseFactor,
                  height: safeH * baseFactor,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(59, 255, 255, 255),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: Scaffold(
                          backgroundColor: const Color(0xff121212),
                          body: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: Assets.images.discussionPageBgPoint
                                        .provider(),
                                    repeat: ImageRepeat.repeat,
                                  ),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xff161616),
                                      Color(0xff080808)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomLeft,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xff2D2D2D),
                                          width: 3,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(maxRadius),
                                      ),
                                      child: Avatar(
                                          widget.discussion.author.avatar),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.discussion.author.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      widget
                                                          .discussion.createdAt
                                                          .toLocal()
                                                          .toString()
                                                          .split('.')
                                                          .first,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Color(0xff808080),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (widget.discussion.author
                                                        .login ==
                                                    owner)
                                                  const MyChip('绳网创始人'),
                                                if (collaborators.contains(
                                                  widget
                                                      .discussion.author.login,
                                                ))
                                                  const MyChip(
                                                    '绳网协作者',
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ClickRegion(
                                      child: Assets.images.closeBtn.image(),
                                      onTap: () => Get.back(),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, con) {
                                    if (con.maxWidth < 600) {
                                      return Stack(
                                        children: [
                                          CustomScrollView(
                                            controller: scrollController,
                                            slivers: [
                                              SliverToBoxAdapter(
                                                child: AspectRatio(
                                                  aspectRatio: 16 / 9,
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    child: Cover(
                                                        discussion:
                                                            widget.discussion),
                                                  ),
                                                ),
                                              ),
                                              SliverToBoxAdapter(
                                                child: DiscussionDetailBox(
                                                  discussion: widget.discussion,
                                                ),
                                              ),
                                              SliverPersistentHeader(
                                                pinned: true,
                                                delegate: _StickyHeaderDelegate(
                                                  child:
                                                      DiscussionActionButtons(
                                                    key: actionButtonsKey,
                                                    discussion:
                                                        widget.discussion,
                                                    hData: widget.hData,
                                                    onCommentAdded:
                                                        _scrollToBottom,
                                                    onEditSuccess: () =>
                                                        setState(() {}),
                                                  ),
                                                ),
                                              ),
                                              SliverToBoxAdapter(
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16),
                                                  child: Column(
                                                    children: [
                                                      const SizedBox(
                                                          height: 16),
                                                      const Divider(),
                                                      Comment(
                                                          discussion:
                                                              widget.discussion,
                                                          loading:
                                                              _isInitialLoading,
                                                          onReply: (id,
                                                                  userName,
                                                                  {addPrefix =
                                                                      false}) =>
                                                              actionButtonsKey
                                                                  .currentState
                                                                  ?.replyTo(id,
                                                                      userName,
                                                                      addPrefix:
                                                                          addPrefix)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          _buildNewCommentNotification(),
                                        ],
                                      );
                                    }
                                    return Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              top: 16,
                                              left: 16,
                                              right: 8,
                                              bottom: 16,
                                            ),
                                            height: double.infinity,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              color: const Color(0xff070707),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: LayoutBuilder(
                                                builder:
                                                    (context, constraints) {
                                                  return AdaptiveSmoothScroll(
                                                    controller:
                                                        leftScrollController,
                                                    scrollSpeed: 0.5,
                                                    builder: (context,
                                                            physics) =>
                                                        SingleChildScrollView(
                                                      controller:
                                                          leftScrollController,
                                                      physics: physics,
                                                      child: Column(
                                                        children: [
                                                          SizedBox(
                                                            height: constraints
                                                                    .maxHeight -
                                                                120,
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .fromLTRB(
                                                                      16,
                                                                      16,
                                                                      24,
                                                                      16),
                                                              child: ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                                child:
                                                                    Container(
                                                                  width: double
                                                                      .infinity,
                                                                  foregroundDecoration:
                                                                      BoxDecoration(
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      color: const Color(
                                                                          0xff313132),
                                                                      width: 4,
                                                                    ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            12),
                                                                  ),
                                                                  child: Cover(
                                                                    discussion:
                                                                        widget
                                                                            .discussion,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          DiscussionDetailBox(
                                                            discussion: widget
                                                                .discussion,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              top: 16,
                                              left: 8,
                                              right: 16,
                                              bottom: 16,
                                            ),
                                            height: double.infinity,
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xff070707),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Column(
                                                children: [
                                                  Expanded(
                                                    child: Stack(
                                                      children: [
                                                        AdaptiveSmoothScroll(
                                                          controller:
                                                              scrollController,
                                                          scrollSpeed: 0.5,
                                                          builder: (context,
                                                                  physics) =>
                                                              SingleChildScrollView(
                                                            controller:
                                                                scrollController,
                                                            physics: physics,
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(
                                                                      16.0),
                                                              child: Column(
                                                                children: [
                                                                  Comment(
                                                                      discussion:
                                                                          widget
                                                                              .discussion,
                                                                      loading:
                                                                          _isInitialLoading,
                                                                      onReply: (id, userName, {addPrefix = false}) => actionButtonsKey.currentState?.replyTo(
                                                                          id,
                                                                          userName,
                                                                          addPrefix:
                                                                              addPrefix)),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        _buildNewCommentNotification(),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16.0),
                                                    decoration:
                                                        const BoxDecoration(
                                                      border: Border(
                                                        top: BorderSide(
                                                          color:
                                                              Color(0xff313132),
                                                        ),
                                                      ),
                                                    ),
                                                    child:
                                                        DiscussionActionButtons(
                                                      key: actionButtonsKey,
                                                      discussion:
                                                          widget.discussion,
                                                      hData: widget.hData,
                                                      onCommentAdded:
                                                          _scrollToBottom,
                                                      onEditSuccess: () =>
                                                          setState(() {}),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DiscussionDetailBox extends StatefulWidget {
  const DiscussionDetailBox({
    super.key,
    required this.discussion,
  });

  final DiscussionModel discussion;

  @override
  State<DiscussionDetailBox> createState() => _DiscussionDetailBoxState();
}

class _DiscussionDetailBoxState extends State<DiscussionDetailBox> {
  final c = Get.find<Controller>();

  @override
  Widget build(BuildContext context) {
    final discussion = widget.discussion;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                discussion.title,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              SelectionArea(
                child: MarkdownWidget(
                  data: discussion.rawBodyText,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  config: MarkdownConfig.darkConfig.copy(
                    configs: [
                      LinkConfig(
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        onTap: (url) {
                          if (url.isNotEmpty) {
                            launchUrlString(url);
                          }
                        },
                      ),
                      const PConfig(
                        textStyle: TextStyle(
                          fontSize: 16,
                          color: Color(0xffE0E0E0),
                        ),
                      ),
                      PreConfig.darkConfig.copy(
                        wrapper: (child, code, language) => Stack(
                          children: [
                            child,
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Text(
                                language,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DiscussionActionButtons extends StatefulWidget {
  const DiscussionActionButtons({
    super.key,
    required this.discussion,
    required this.hData,
    this.onCommentAdded,
    this.onEditSuccess,
  });

  final DiscussionModel discussion;
  final HDataModel hData;
  final VoidCallback? onCommentAdded;
  final VoidCallback? onEditSuccess;

  @override
  State<DiscussionActionButtons> createState() =>
      DiscussionActionButtonsState();
}

class DiscussionActionButtonsState extends State<DiscussionActionButtons>
    with SingleTickerProviderStateMixin {
  final c = Get.find<Controller>();
  late final api = Get.find<Api>();

  bool _isWriting = false;
  bool _isLoading = false;
  String? _parentId;
  String? _replyToUser;
  bool _addReplyPrefix = false;

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _controller;
  late final Animation<double> _sizeAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _sizeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    // Initially expanded (value 1.0)
    _controller.value = 1.0;
  }

  // Public method to trigger reply
  Future<void> replyTo(String parentId, String? userName,
      {bool addPrefix = false}) async {
    if (!await c.ensureLogin()) return;

    setState(() {
      _parentId = parentId;
      _replyToUser = userName;
      _isWriting = true;
      _addReplyPrefix = addPrefix;
    });
    _controller.reverse();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    var content = _textController.text.trim();
    if (content.isEmpty) {
      showToast('评论内容不能为空', isError: true);
      return;
    }

    if (_addReplyPrefix && _replyToUser != null) {
      content = '回复 @$_replyToUser :$content';
    }

    if (!await c.ensureLogin()) return;

    setState(() => _isLoading = true);

    try {
      final user = c.user.value;
      final authorId = c.authorId.value ?? await c.ensureAuthorForUser(user);
      if (authorId == null || authorId.isEmpty) {
        showToast('无法关联作者，请重新登录后再试', isError: true);
        return;
      }

      final res = await api.addDiscussionComment(
        widget.discussion.id,
        content,
        authorId: authorId,
        parentId: _parentId,
      );

      if (res.hasError) throw Exception(res.statusText ?? 'Unknown error');

      if (res.body?['errors'] != null) {
        final errors = res.body!['errors'] as List<dynamic>;
        if (errors.isNotEmpty) {
          final first = errors[0];
          final msg = first is Map ? first['message']?.toString() : null;
          throw Exception(msg ?? 'Failed to add comment');
        }
      }

      _textController.clear();
      _cancel();

      widget.discussion.comments.clear();
      widget.discussion.commentsCount++;
      await widget.discussion.fetchComments();
      widget.onCommentAdded?.call();
      showToast('评论发布成功');
    } catch (e) {
      showToast('评论发布失败: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleTap() async {
    if (!await c.ensureLogin()) return;

    if (_isWriting) {
      _submit();
    } else {
      setState(() => _isWriting = true);
      _controller.reverse();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  void _cancel() {
    setState(() {
      _isWriting = false;
      _parentId = null;
      _replyToUser = null;
      _addReplyPrefix = false;
    });
    _textController.clear();
    _controller.forward();
    _focusNode.unfocus();
  }

  Future<void> _handleDelete() async {
    final confirmed = await showZZZDialog<bool>(
      context: context,
      pageBuilder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xff1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xff313132),
                  width: 4,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '确认删除',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '确定要删除这个帖子吗？此操作不可恢复。',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          '删除',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      try {
        final res = await api.deleteDiscussion(widget.discussion.id);
        if (res.hasError) {
          showToast('删除失败: ${res.statusText}', isError: true);
        } else {
          if (!mounted) return;
          // Close detail page first
          Navigator.of(context).pop(true);
          showToast('帖子已删除');
          // Refresh lists
          c.searchResult.refresh();
          c.bookmarks.refresh();
          c.history.refresh();
        }
      } catch (e) {
        showToast('删除出错: $e', isError: true);
      }
    }
  }

  void _handleEdit() async {
    final result = await CreateDiscussionPage.show(
      context,
      discussion: widget.discussion,
    );
    if (result == true) {
      widget.onEditSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: (_) {
        if (_isWriting) _cancel();
      },
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xff222222),
                borderRadius: BorderRadius.circular(maxRadius),
                border: Border.all(color: const Color(0xff2D2D2D), width: 4),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fullWidth = constraints.maxWidth;
                  const iconWidth = 48.0;

                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      // _controller goes from 1.0 (closed) to 0.0 (open)
                      final progress = 1.0 - _controller.value;
                      final curve = Curves.easeInOut.transform(progress);

                      final inputWidth =
                          (fullWidth - iconWidth) * curve; // 0 -> max
                      final buttonWidth = fullWidth - inputWidth; // max -> icon

                      return Row(
                        children: [
                          // Input Section
                          SizedBox(
                            width: inputWidth,
                            child: ClipRect(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                widthFactor: 1.0,
                                child: UnconstrainedBox(
                                  alignment: Alignment.centerLeft,
                                  constrainedAxis: Axis.vertical,
                                  child: SizedBox(
                                    width: fullWidth - iconWidth,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: CallbackShortcuts(
                                        bindings: {
                                          const SingleActivator(
                                                  LogicalKeyboardKey.escape):
                                              _cancel,
                                        },
                                        child: TextField(
                                          controller: _textController,
                                          focusNode: _focusNode,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white),
                                          cursorColor: Colors.white,
                                          decoration: InputDecoration.collapsed(
                                            hintText: _replyToUser != null
                                                ? '回复 @$_replyToUser：'
                                                : '请输入文本...',
                                            hintStyle: const TextStyle(
                                                color: Colors.grey),
                                          ),
                                          onSubmitted: (_) => _submit(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Button Section
                          SizedBox(
                            width: buttonWidth,
                            child: ClickRegion(
                              onTap: _handleTap,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Send Icon (Visible when open)
                                  Opacity(
                                    opacity: curve,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white),
                                          )
                                        : const Icon(Icons.send,
                                            key: ValueKey('send')),
                                  ),
                                  // Write Comment Text (Visible when closed)
                                  Opacity(
                                    opacity: 1.0 - curve,
                                    child: Transform.translate(
                                      offset: Offset(-50 * curve,
                                          0), // Slide left slightly
                                      child: UnconstrainedBox(
                                        constrainedAxis: Axis.vertical,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_comment_outlined),
                                            SizedBox(width: 8),
                                            Text(
                                              '评论',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              widget.discussion.commentsCount
                                                  .toString(),
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _sizeAnimation,
            axis: Axis.horizontal,
            axisAlignment: -1.0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Obx(() {
                    final isLiked = c.bookmarks
                        .map((e) => e.id)
                        .contains(widget.discussion.id);
                    return Tooltip(
                      message: isLiked ? '不喜欢' : '喜欢',
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xff222222),
                          borderRadius: BorderRadius.circular(maxRadius),
                          border: Border.all(
                              color: const Color(0xff2D2D2D), width: 4),
                        ),
                        child: ClickRegion(
                          onTap: () => c.toggleFavorite(widget.hData),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_outline,
                            color: isLiked ? Colors.red : null,
                          ),
                        ),
                      ),
                    );
                  }),
                  if (c.user.value?.login ==
                      widget.discussion.author.login) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: '编辑',
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xff222222),
                          borderRadius: BorderRadius.circular(maxRadius),
                          border: Border.all(
                              color: const Color(0xff2D2D2D), width: 4),
                        ),
                        child: ClickRegion(
                          onTap: _handleEdit,
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: '删除',
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xff222222),
                          borderRadius: BorderRadius.circular(maxRadius),
                          border: Border.all(
                              color: const Color(0xff2D2D2D), width: 4),
                        ),
                        child: ClickRegion(
                          onTap: _handleDelete,
                          child: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Cover extends StatefulWidget {
  const Cover({super.key, required this.discussion});

  final DiscussionModel discussion;

  @override
  State<Cover> createState() => _CoverState();
}

class _CoverState extends State<Cover> {
  final _controller = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final covers = widget.discussion.covers;

    if (covers.isEmpty) {
      return Assets.images.defaultCover.image(fit: BoxFit.contain);
    }

    if (covers.length == 1) {
      final url = covers.first;
      final heroTag = 'cover-${widget.discussion.id}-0';

      return Hero(
        tag: heroTag,
        child: ClickRegion(
          onTap: () => ImageViewer.show(
            context,
            imageUrls: covers,
            heroTagPrefix: 'cover-${widget.discussion.id}',
          ),
          child: NetworkImageBox(
            url: url,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            loadingBuilder: (context, progress) {
              return Center(
                child: CircularProgressIndicator(value: progress),
              );
            },
            errorBuilder: (context) =>
                Assets.images.defaultCover.image(fit: BoxFit.contain),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ScrollConfiguration(
            behavior: const _CoverScrollBehavior(),
            child: PageView.builder(
              controller: _controller,
              itemCount: covers.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final url = covers[index];
                final heroTag = 'cover-${widget.discussion.id}-$index';

                return Hero(
                  tag: heroTag,
                  child: ClickRegion(
                    onTap: () => ImageViewer.show(
                      context,
                      imageUrls: covers,
                      initialIndex: index,
                      heroTagPrefix: 'cover-${widget.discussion.id}',
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: NetworkImageBox(
                        url: url,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        gaplessPlayback: true,
                        loadingBuilder: (context, progress) {
                          return Center(
                            child: CircularProgressIndicator(value: progress),
                          );
                        },
                        errorBuilder: (context) => Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.broken_image,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (covers.length > 1)
            Positioned.fill(
              left: 8,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _NavButton(
                  icon: Icons.chevron_left,
                  onTap: () => _goToPage(_currentIndex - 1, covers.length),
                ),
              ),
            ),
          if (covers.length > 1)
            Positioned.fill(
              right: 8,
              child: Align(
                alignment: Alignment.centerRight,
                child: _NavButton(
                  icon: Icons.chevron_right,
                  onTap: () => _goToPage(_currentIndex + 1, covers.length),
                ),
              ),
            ),
          Positioned(
            bottom: 8,
            child: IgnorePointer(
              child: SizedBox(
                height: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(covers.length, (i) {
                    final isActive = i == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xffFBC02D)
                            : const Color(0xff2E2E2E),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToPage(int index, int total) {
    if (total <= 1) return;
    final target = index.clamp(0, total - 1);
    if (target == _currentIndex) return;
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xB3000000),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _CoverScrollBehavior extends MaterialScrollBehavior {
  const _CoverScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.unknown,
      };
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({
    required this.child,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xff121212),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  double get maxExtent => 64.0;

  @override
  double get minExtent => 64.0;

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
