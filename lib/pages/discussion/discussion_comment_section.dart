import 'package:flutter/material.dart';
import 'package:inter_knot/components/comment.dart';
import 'package:inter_knot/models/discussion.dart';

class DiscussionCommentSection extends StatelessWidget {
  const DiscussionCommentSection({
    super.key,
    required this.discussion,
    required this.isInitialLoading,
    required this.onReply,
    this.onCommentDeleted,
    this.useListView = false,
    this.controller,
    this.physics,
    this.padding,
  });

  final DiscussionModel discussion;
  final bool isInitialLoading;
  final void Function(String id, String? userName, {bool addPrefix}) onReply;
  final VoidCallback? onCommentDeleted;

  final bool useListView;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Comment(
      discussion: discussion,
      loading: isInitialLoading,
      onReply: onReply,
      onCommentDeleted: onCommentDeleted,
      useListView: useListView,
      controller: controller,
      physics: physics,
      padding: padding,
    );
  }
}
