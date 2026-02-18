import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:inter_knot/components/my_tab.dart';
import 'package:inter_knot/constants/globals.dart';
import 'package:inter_knot/controllers/data.dart';
import 'package:inter_knot/gen/assets.gen.dart';

class MyAppBar extends StatefulWidget {
  const MyAppBar({super.key});

  @override
  State<MyAppBar> createState() => _MyAppBarState();
}

class _MyAppBarState extends State<MyAppBar> {
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      c.searchQuery(query);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 640;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: isCompact ? width : max(width, 640),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.black,
          child: Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/images/zzzicon.png',
                    width: 48,
                    height: 48,
                    filterQuality: FilterQuality.medium,
                  ),
                  if (!isCompact) ...[
                    const SizedBox(width: 12),
                    const Text(
                      'INTER-KNOT',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 16),
              // 新增：搜索栏
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 700),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: SearchBar(
                        controller: c.searchController,
                        onChanged: _onSearchChanged,
                        onSubmitted: c.searchQuery.call,
                        backgroundColor:
                            const WidgetStatePropertyAll(Color(0xff1E1E1E)),
                        leading: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.search, color: Color(0xffB0B0B0)),
                        ),
                        hintText: '搜索',
                        hintStyle: const WidgetStatePropertyAll(
                          TextStyle(color: Color(0xff808080)),
                        ),
                        textStyle: const WidgetStatePropertyAll(
                          TextStyle(color: Color(0xffE0E0E0)),
                        ),
                        side: WidgetStatePropertyAll(
                          BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!isCompact)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xff313131),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(maxRadius),
                    image: DecorationImage(
                      image: Assets.images.tabBgPoint.provider(),
                      repeat: ImageRepeat.repeat,
                    ),
                  ),
                  child: Obx(() {
                    final page = c.curPage.value;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MyTab(
                          first: true,
                          text: '推送',
                          isSelected: page == 0,
                          onTap: () {
                            if (c.curPage() == 0) c.refreshSearchData();
                            c.animateToPage(0, animate: false);
                          },
                        ),
                        MyTab(
                          text: '我的',
                          last: true,
                          isSelected: page == 1,
                          onTap: () => c.animateToPage(1, animate: false),
                        ),
                      ],
                    );
                  }),
                )
              else
                const SizedBox(width: 72),
            ],
          ),
        ),
      ),
    );
  }
}
