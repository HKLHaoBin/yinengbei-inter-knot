import 'package:flutter/material.dart';
import 'package:inter_knot/components/discussions_grid.dart';
import 'package:inter_knot/models/discussion.dart';
import 'package:inter_knot/models/h_data.dart';

class CreateDiscussionDraftsPage extends StatelessWidget {
  const CreateDiscussionDraftsPage({
    super.key,
    required this.isLoggedIn,
    required this.isLoading,
    required this.drafts,
    required this.hasNextPage,
    required this.onFetchMore,
    required this.onOpenDraft,
  });

  final bool isLoggedIn;
  final bool isLoading;
  final Set<HDataModel> drafts;
  final bool hasNextPage;
  final VoidCallback? onFetchMore;
  final Future<void> Function(
    BuildContext context,
    HDataModel item,
    DiscussionModel discussion,
  ) onOpenDraft;

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return const Center(
        child: DiscussionEmptyState(
          message: '登录后查看草稿箱',
          textStyle: TextStyle(
            color: Color(0xff808080),
            fontSize: 16,
          ),
        ),
      );
    }

    if (isLoading && drafts.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: Color(0xffD7FF00),
          ),
        ),
      );
    }

    if (drafts.isEmpty) {
      return const Center(
        child: DiscussionEmptyState(
          message: '还没有纯草稿',
          textStyle: TextStyle(
            color: Color(0xff808080),
            fontSize: 16,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xff121212),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xff2A2A2A),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.drafts_outlined,
                color: Color(0xffD7FF00),
                size: 18,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '草稿箱只显示从未发布过的草稿，点击卡片可继续编辑。',
                  style: TextStyle(
                    color: Color(0xffCFCFCF),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: DiscussionGrid(
            list: drafts,
            hasNextPage: hasNextPage,
            fetchData: onFetchMore,
            reorderHistoryOnOpen: false,
            onOpenItem: onOpenDraft,
          ),
        ),
      ],
    );
  }
}
