import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:inter_knot/components/avatar.dart';
import 'package:inter_knot/components/my_chip.dart';
import 'package:inter_knot/constants/globals.dart';
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

    return Column(
      children: [
        for (final reply in widget.comment.replies)
          ListTile(
            titleAlignment: ListTileTitleAlignment.top,
            contentPadding: EdgeInsets.zero,
            horizontalTitleGap: 8,
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
                    child: Text(
                      reply.author.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (reply.author.login == widget.discussion.author.login)
                        const MyChip('楼主'),
                      if (reply.author.login == widget.comment.author.login)
                        const MyChip('层主'),
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
                Text(
                  DateFormat('yyyy-MM-dd HH:mm')
                      .format(reply.createdAt.toLocal()),
                ),
                const SizedBox(height: 8),
                SelectionArea(
                  child: HtmlWidget(
                    reply.bodyHTML,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      color: Color(0xffE0E0E0), // Light grey for replies
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
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
