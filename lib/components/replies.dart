import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:inter_knot/api/api.dart';
import 'package:inter_knot/components/avatar.dart';
import 'package:inter_knot/components/my_chip.dart';
import 'package:inter_knot/constants/globals.dart';
import 'package:get/get.dart';
import 'package:inter_knot/controllers/data.dart';
import 'package:inter_knot/components/image_viewer.dart';
import 'package:inter_knot/helpers/dialog_helper.dart';
import 'package:inter_knot/helpers/toast.dart';
import 'package:inter_knot/models/comment.dart';
import 'package:inter_knot/models/discussion.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

enum _ReplyAction { delete }

class Replies extends StatefulWidget {
  const Replies({
    super.key,
    required this.comment,
    required this.discussion,
    required this.onReply,
    this.onCommentDeleted,
  });

  final CommentModel comment;
  final DiscussionModel discussion;
  final void Function(String id, String? userName, {bool addPrefix}) onReply;
  final VoidCallback? onCommentDeleted;

  @override
  State<Replies> createState() => _RepliesState();
}

class _RepliesState extends State<Replies> {
  bool _expanded = false;
  final c = Get.find<Controller>();
  late final api = Get.find<Api>();

  bool _isMyComment(CommentModel comment) {
    final user = c.user.value;
    final currentAuthorId = c.authorId.value ?? user?.authorId;
    return currentAuthorId != null &&
        currentAuthorId.isNotEmpty &&
        currentAuthorId == comment.author.authorId;
  }

  Future<void> _showReplyActions(CommentModel reply) async {
    if (!await c.ensureLogin()) return;

    final isMine = _isMyComment(reply);
    final selected = await showModalBottomSheet<_ReplyAction>(
      context: context,
      backgroundColor: const Color(0xff1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              enabled: isMine,
              leading: Icon(
                Icons.delete_outline,
                color: isMine ? Colors.redAccent : Colors.grey,
              ),
              title: Text(
                '删除评论',
                style: TextStyle(color: isMine ? Colors.redAccent : Colors.grey),
              ),
              subtitle: isMine ? null : const Text('只能删除自己的评论'),
              onTap: isMine
                  ? () => Navigator.of(ctx).pop(_ReplyAction.delete)
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('取消'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );

    if (selected == _ReplyAction.delete) {
      await _deleteComment(reply);
    }
  }

  Future<void> _deleteComment(CommentModel comment) async {
    if (!await c.ensureLogin()) return;
    if (!_isMyComment(comment)) {
      showToast('只能删除自己的评论', isError: true);
      return;
    }

    final confirmed = await showZZZDialog<bool>(
      context: context,
      pageBuilder: (dialogContext) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
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
                    '确认删除评论',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '删除后不可恢复，是否继续？',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
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
    if (confirmed != true) return;

    try {
      final res = await api.deleteComment(comment.id);
      if (res.hasError) {
        showToast('删除失败: ${res.statusText}', isError: true);
        return;
      }

      widget.discussion.comments.clear();
      if (widget.discussion.commentsCount > 0) {
        widget.discussion.commentsCount--;
      }
      await widget.discussion.fetchComments();

      if (mounted) {
        setState(() {});
      }
      widget.onCommentDeleted?.call();
      showToast('评论已删除');
    } catch (e) {
      showToast('删除失败: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.comment.replies.isEmpty) return const SizedBox.shrink();

    if (!_expanded) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => setState(() => _expanded = true),
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.hovered)) {
                  return const Color(0xffD7FF00).withValues(alpha: 0.1);
                }
                return null;
              },
            ),
          ),
          child: Text(
            '展开 ${widget.comment.replies.length} 条回复',
            style: const TextStyle(color: Color(0xffD7FF00)),
          ),
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 600;
    return Column(
      children: [
        const SizedBox(height: 10),
        for (final reply in widget.comment.replies)
          isMobile
              ? _buildMobileReplyItem(reply, c)
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: () => _showReplyActions(reply),
                  child: ListTile(
                    titleAlignment: ListTileTitleAlignment.top,
                    contentPadding: EdgeInsets.zero,
                    horizontalTitleGap: 16,
                    minVerticalPadding: 0,
                    leading: ClipOval(
                      child: InkWell(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        borderRadius: BorderRadius.circular(50),
                        onTap: () => launchUrlString(reply.url),
                        child: Avatar(reply.author.avatar),
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () => launchUrlString(reply.url),
                            child: Obx(() {
                              final user = c.user.value;
                              final currentAuthorId =
                                  c.authorId.value ?? user?.authorId;
                              final isMe = currentAuthorId != null &&
                                  currentAuthorId == reply.author.authorId;
                              final isOp = reply.author.login ==
                                  widget.discussion.author.login;
                              final isLayerOwner = reply.author.login ==
                                  widget.comment.author.login;

                              return Text(
                                '${isOp ? '【楼主】 ' : (isLayerOwner ? '【层主】 ' : '')}${isMe ? (user?.name ?? reply.author.name) : reply.author.name}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isMe ? const Color(0xFFFFBC2E) : null,
                                  fontWeight: isMe ? FontWeight.bold : null,
                                  fontSize: 13,
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lv.${reply.author.level ?? 1}',
                          style: const TextStyle(
                            color: Color(0xffD7FF00),
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (reply.author.login == owner)
                                const MyChip('绳网创始人'),
                              if (collaborators.contains(reply.author.login))
                                const MyChip('绳网协作者'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        SelectionArea(
                          child: HtmlWidget(
                            reply.bodyHTML,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              color:
                                  Color(0xffE0E0E0), // Light grey for replies
                            ),
                            onTapImage: (data) {
                              if (data.sources.isEmpty) return;
                              final url = data.sources.first.url;
                              ImageViewer.show(context,
                                  imageUrls: [url], heroTagPrefix: null);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              DateFormat('yyyy-MM-dd HH:mm')
                                  .format(reply.createdAt.toLocal()),
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => widget.onReply(
                                  widget.comment.id, reply.author.name,
                                  addPrefix: true),
                              style: ButtonStyle(
                                padding:
                                    WidgetStateProperty.all(EdgeInsets.zero),
                                minimumSize: WidgetStateProperty.all(Size.zero),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                overlayColor:
                                    WidgetStateProperty.resolveWith<Color?>(
                                  (Set<WidgetState> states) {
                                    if (states.contains(WidgetState.hovered)) {
                                      return const Color(0xffD7FF00)
                                          .withValues(alpha: 0.1);
                                    }
                                    return null;
                                  },
                                ),
                                foregroundColor:
                                    WidgetStateProperty.resolveWith<Color>(
                                  (Set<WidgetState> states) {
                                    if (states.contains(WidgetState.hovered)) {
                                      return const Color(0xffD7FF00);
                                    }
                                    return Colors.grey;
                                  },
                                ),
                              ),
                              child: const Text('回复',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
                ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _expanded = false),
            style: ButtonStyle(
              overlayColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.hovered)) {
                    return const Color(0xffD7FF00).withValues(alpha: 0.1);
                  }
                  return null;
                },
              ),
            ),
            child: const Text(
              '收起回复',
              style: TextStyle(color: Color(0xffD7FF00)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileReplyItem(dynamic reply, Controller c) {
    final baseTitleStyle =
        Theme.of(context).textTheme.titleMedium ?? const TextStyle();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showReplyActions(reply as CommentModel),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipOval(
                  child: InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                    onTap: () => launchUrlString(reply.url),
                    child: Avatar(reply.author.avatar, size: 32),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () => launchUrlString(reply.url),
                    child: Obx(() {
                      final user = c.user.value;
                      final currentAuthorId = c.authorId.value ?? user?.authorId;
                      final isMe = currentAuthorId != null &&
                          currentAuthorId == reply.author.authorId;
                      final isOp =
                          reply.author.login == widget.discussion.author.login;
                      final isLayerOwner =
                          reply.author.login == widget.comment.author.login;

                      return Text(
                        '${isOp ? '【楼主】 ' : (isLayerOwner ? '【层主】 ' : '')}${isMe ? (user?.name ?? reply.author.name) : reply.author.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: baseTitleStyle.copyWith(
                          color: isMe
                              ? const Color(0xFFFFBC2E)
                              : baseTitleStyle.color,
                          fontWeight: isMe
                              ? FontWeight.bold
                              : baseTitleStyle.fontWeight,
                          fontSize: 13,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Lv.${reply.author.level ?? 1}',
                  style: const TextStyle(
                    color: Color(0xffD7FF00),
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 0, top: 8),
              child: SelectionArea(
                child: HtmlWidget(
                  reply.bodyHTML,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    color: Color(0xffE0E0E0),
                  ),
                  onTapImage: (data) {
                    if (data.sources.isEmpty) return;
                    final url = data.sources.first.url;
                    ImageViewer.show(context,
                        imageUrls: [url], heroTagPrefix: null);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  DateFormat('yyyy-MM-dd HH:mm')
                      .format(reply.createdAt.toLocal()),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => widget.onReply(
                      widget.comment.id, reply.author.name,
                      addPrefix: true),
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all(EdgeInsets.zero),
                    minimumSize: WidgetStateProperty.all(Size.zero),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    foregroundColor: WidgetStateProperty.all(Colors.grey),
                    overlayColor: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.hovered)) {
                          return const Color(0xffD7FF00).withValues(alpha: 0.1);
                        }
                        return null;
                      },
                    ),
                  ),
                  child: const Text('回复', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
