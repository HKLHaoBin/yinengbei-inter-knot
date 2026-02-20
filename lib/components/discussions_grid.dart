import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:inter_knot/components/discussion_card.dart';
import 'package:inter_knot/controllers/data.dart';
import 'package:inter_knot/helpers/dialog_helper.dart';
import 'package:inter_knot/helpers/smooth_scroll.dart';
import 'package:inter_knot/models/discussion.dart';
import 'package:inter_knot/models/h_data.dart';
import 'package:inter_knot/pages/discussion_page.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

class DiscussionEmptyState extends StatelessWidget {
  const DiscussionEmptyState({
    super.key,
    required this.message,
    this.imageAsset,
    this.imageSize = 120,
    this.textStyle,
  });

  final String message;
  final String? imageAsset;
  final double imageSize;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageAsset != null && imageAsset!.isNotEmpty;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        if (hasImage)
          Image.asset(
            imageAsset!,
            width: imageSize,
            height: imageSize,
          ),
        if (hasImage) const SizedBox(height: 16),
        Text(
          message,
          style: textStyle,
        ),
      ],
    );
  }
}

class DiscussionGrid extends StatefulWidget {
  const DiscussionGrid({
    super.key,
    required this.list,
    required this.hasNextPage,
    this.fetchData,
    this.controller,
  });

  final Set<HDataModel> list;
  final bool hasNextPage;
  final void Function()? fetchData;
  final ScrollController? controller;

  @override
  State<DiscussionGrid> createState() => _DiscussionGridState();
}

class _DiscussionGridState extends State<DiscussionGrid>
    with AutomaticKeepAliveClientMixin {
  late final ScrollController scrollController;
  bool _isLocalController = false;

  @override
  bool get wantKeepAlive => true;

  Widget _buildCard(
      BuildContext context, HDataModel item, DiscussionModel discussion) {
    return DiscussionCard(
      discussion: discussion,
      hData: item,
      onTap: () async {
        final result = await showZZZDialog(
          context: context,
          pageBuilder: (context) {
            return DiscussionPage(
              discussion: discussion,
              hData: item,
            );
          },
        );

        if (result == true) {
          if (widget.list is RxSet) {
            widget.list.remove(item);
          } else {
            setState(() {
              widget.list.remove(item);
            });
          }
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      scrollController = widget.controller!;
    } else {
      scrollController = ScrollController();
      _isLocalController = true;
    }
  }

  @override
  void didUpdateWidget(covariant DiscussionGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        // old was local, dispose it
        if (_isLocalController) {
          scrollController.dispose();
          _isLocalController = false;
        }
      }
      if (widget.controller != null) {
        scrollController = widget.controller!;
        _isLocalController = false;
      } else {
        scrollController = ScrollController();
        _isLocalController = true;
      }
    }
  }

  @override
  void dispose() {
    if (_isLocalController) {
      scrollController.dispose();
    }
    // DO NOT dispose external controller here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final list = widget.list;
    final items = list.toList(growable: false);
    final fetchData = widget.fetchData;
    final hasNextPage = widget.hasNextPage;

    // Performance: Use layout builder only if list is empty to avoid unnecessary rebuilds
    if (list.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Obx(() {
                final isSearching = Get.find<Controller>().isSearching.value;
                if (isSearching) {
                  return const DiscussionEmptyState(
                    message: '正在搜索...',
                    imageAsset: 'assets/images/Bangboo.gif',
                    imageSize: 120,
                    textStyle: TextStyle(
                      color: Color(0xff808080),
                      fontSize: 16,
                    ),
                  );
                }
                return const DiscussionEmptyState(
                  message: '暂无相关帖子',
                  textStyle: TextStyle(
                    color: Color.fromARGB(255, 233, 233, 233),
                    fontSize: 16,
                  ),
                );
              }),
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, con) {
        final width = MediaQuery.of(context).size.width;
        final isCompact = width < 640;
        final child = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1450),
            child: WaterfallFlow.builder(
              controller: scrollController,
              physics: !isCompact
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(4).copyWith(top: 16),
              gridDelegate: SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 275,
                mainAxisSpacing: 2,
                crossAxisSpacing: 1,
                lastChildLayoutTypeBuilder: (index) => index == items.length
                    ? LastChildLayoutType.foot
                    : LastChildLayoutType.none,
                viewportBuilder: (firstIndex, lastIndex) {
                  if (lastIndex == items.length) fetchData?.call();
                },
              ),
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == items.length) {
                  if (hasNextPage) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/images/Bangboo.gif',
                          width: 80,
                          height: 80,
                        ),
                      ),
                    );
                  }
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('已经到底啦…[ O_X ] /'),
                    ),
                  );
                }
                final item = items[index];

                // Performance Optimization: Check synchronous cache first
                // This avoids creating FutureBuilder for already loaded items, reducing build overhead and flickering
                final cachedDiscussion = item.cachedDiscussion;
                if (cachedDiscussion != null) {
                  return KeyedSubtree(
                    key: ValueKey(item.id),
                    child: _buildCard(context, item, cachedDiscussion),
                  );
                }

                return FutureBuilder(
                  key: ValueKey(item.id),
                  future: item.discussion,
                  builder: (context, snaphost) {
                    if (snaphost.hasData) {
                      return _buildCard(context, item, snaphost.data!);
                    }
                    if (snaphost.hasError) {
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        color: const Color(0xff222222),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                            bottomLeft: Radius.circular(24),
                          ),
                        ),
                        child: AspectRatio(
                          aspectRatio: 5 / 6,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                                child: SelectableText('${snaphost.error}')),
                          ),
                        ),
                      );
                    }
                    if (snaphost.connectionState == ConnectionState.done) {
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        color: const Color(0xff222222),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                            bottomLeft: Radius.circular(24),
                          ),
                        ),
                        child: InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () => launchUrlString(item.url),
                          child: const AspectRatio(
                            aspectRatio: 5 / 6,
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: Text('讨论已删除')),
                            ),
                          ),
                        ),
                      );
                    }
                    return const DiscussionCardSkeleton();
                  },
                );
              },
            ),
          ),
        );
        if (!isCompact) {
          return SmoothScroll(
            controller: scrollController,
            child: DraggableScrollbar(
              controller: scrollController,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                ),
                child: child,
              ),
            ),
          );
        }
        return child;
      },
    );
  }
}
