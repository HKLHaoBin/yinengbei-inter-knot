import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:inter_knot/components/avatar.dart';
import 'package:inter_knot/components/my_chip.dart';
import 'package:inter_knot/constants/globals.dart';
import 'package:get/get.dart';
import 'package:inter_knot/controllers/data.dart';
import 'package:inter_knot/components/image_viewer.dart';
import 'package:inter_knot/models/comment.dart';
import 'package:inter_knot/models/discussion.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Replies extends StatefulWidget {
  const Replies({
    super.key,
    required this.comment,
    required this.discussion,
    required this.onReply,
  });

  final CommentModel comment;
  final DiscussionModel discussion;
  final void Function(String id, String? userName, {bool addPrefix}) onReply;

  @override
  State<Replies> createState() => _RepliesState();
}

class _RepliesState extends State<Replies> {
  bool _expanded = false;

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

    final c = Get.find<Controller>();

    return Column(
      children: [
        const SizedBox(height: 10),
        for (final reply in widget.comment.replies)
          ListTile(
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
                      final isOp =
                          reply.author.login == widget.discussion.author.login;
                      final isLayerOwner =
                          reply.author.login == widget.comment.author.login;

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
                      if (reply.author.login == owner) const MyChip('绳网创始人'),
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
                      color: Color(0xffE0E0E0), // Light grey for replies
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
                        overlayColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.hovered)) {
                              return const Color(0xffD7FF00)
                                  .withValues(alpha: 0.1);
                            }
                            return null;
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.hovered)) {
                              return const Color(0xffD7FF00);
                            }
                            return Colors.grey;
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
}
