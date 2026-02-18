import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:inter_knot/components/avatar.dart';
import 'package:inter_knot/components/my_chip.dart';
import 'package:inter_knot/constants/globals.dart';
import 'package:inter_knot/models/comment.dart';
import 'package:inter_knot/models/discussion.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Replies extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final reply in comment.replies)
          ListTile(
            titleAlignment: ListTileTitleAlignment.top,
            contentPadding: EdgeInsets.zero,
            horizontalTitleGap: 8,
            minVerticalPadding: 0,
            leading: MediaQuery.of(context).size.width > 400
                ? ClipOval(
                    child: InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      borderRadius: BorderRadius.circular(50),
                      onTap: () => launchUrlString(reply.url),
                      child: Avatar(reply.author.avatar),
                    ),
                  )
                : null,
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
                      if (reply.author.login == discussion.author.login)
                        const MyChip('楼主'),
                      if (reply.author.login == comment.author.login)
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
                  child: TextButton.icon(
                    onPressed: () =>
                        onReply(comment.id, reply.author.name, addPrefix: true),
                    icon: const Icon(Icons.reply, size: 16, color: Colors.grey),
                    label:
                        const Text('回复', style: TextStyle(color: Colors.grey)),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const Divider(),
              ],
            ),
          ),
      ],
    );
  }
}
