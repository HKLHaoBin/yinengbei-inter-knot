import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import 'package:inter_knot/components/avatar.dart';
import 'package:inter_knot/components/image_viewer.dart';
import 'package:inter_knot/components/my_chip.dart';
import 'package:inter_knot/components/replies.dart';
import 'package:inter_knot/constants/globals.dart';
import 'package:inter_knot/controllers/data.dart';
import 'package:inter_knot/helpers/flatten.dart';
import 'package:inter_knot/models/comment.dart';
import 'package:inter_knot/models/discussion.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Comment extends StatefulWidget {
  const Comment({
    super.key,
    required this.discussion,
    this.loading = false,
    this.onReply,
  });

  final DiscussionModel discussion;
  final bool loading;
  final void Function(String parentId, String? userName, {bool addPrefix})?
      onReply;

  @override
  State<Comment> createState() => _CommentState();
}

class _CommentState extends State<Comment> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(Comment oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  Widget _buildFooter() {
    if (widget.discussion.comments.isNotEmpty &&
        widget.discussion.comments.last.hasNextPage) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Image.asset(
            'assets/images/Bangboo.gif',
            width: 80,
            height: 80,
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: Text('没有更多评论了')),
    );
  }

  Widget _buildCommentItem(CommentModel comment, int index, bool isMobile) {
    Widget content = ListTile(
      titleAlignment: ListTileTitleAlignment.top,
      contentPadding: EdgeInsets.zero,
      horizontalTitleGap: 8,
      minVerticalPadding: 0,
      leading: ClipOval(
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          onTap: () => launchUrlString(comment.url),
          child: Avatar(comment.author.avatar),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () => launchUrlString(comment.url),
              child: Obx(() {
                final user = c.user.value;
                final currentAuthorId = c.authorId.value ?? user?.authorId;
                final isMe = currentAuthorId != null &&
                    currentAuthorId == comment.author.authorId;

                return Text(
                  isMe
                      ? (user?.name ?? comment.author.name)
                      : comment.author.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (comment.author.login == widget.discussion.author.login)
                  const MyChip('楼主'),
                if (comment.author.login == owner) const MyChip('绳网创始人'),
                if (collaborators.contains(comment.author.login))
                  const MyChip('绳网协作者'),
              ],
            ),
          ),
        ],
      ),
      trailing: MyChip('F${index + 1}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('yyyy-MM-dd HH:mm').format(comment.createdAt.toLocal()),
          ),
          const SizedBox(height: 8),
          SelectionArea(
            child: HtmlWidget(
              comment.bodyHTML,
              textStyle: const TextStyle(
                fontSize: 16,
                color: Color(0xffE0E0E0), // Force light grey color
              ),
              onTapImage: (data) {
                if (data.sources.isEmpty) return;
                final url = data.sources.first.url;
                ImageViewer.show(context,
                    imageUrls: [url], heroTagPrefix: null);
              },
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => widget.onReply
                  ?.call(comment.id, comment.author.name, addPrefix: false),
              style: ButtonStyle(
                padding: WidgetStateProperty.all(EdgeInsets.zero),
                minimumSize: WidgetStateProperty.all(const Size(50, 30)),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                overlayColor: WidgetStateProperty.resolveWith<Color?>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.hovered)) {
                      return const Color(0xffD7FF00).withValues(alpha: 0.1);
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
              child: const Text('回复'),
            ),
          ),
          Replies(
              comment: comment,
              discussion: widget.discussion,
              onReply: (id, userName, {addPrefix = false}) =>
                  widget.onReply?.call(id, userName, addPrefix: addPrefix)),
        ],
      ),
    );

    content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        content,
        const Divider(thickness: 2, height: 32),
      ],
    );

    return content;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Image.asset(
            'assets/images/Bangboo.gif',
            width: 80,
            height: 80,
          ),
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    final list = Column(
      children: [
        ...widget.discussion.comments
            .map((e) => e.nodes)
            .flat
            .toList()
            .asMap()
            .entries
            .map(
                (entry) => _buildCommentItem(entry.value, entry.key, isMobile)),
        _buildFooter(),
      ],
    );

    return list;
  }
}
