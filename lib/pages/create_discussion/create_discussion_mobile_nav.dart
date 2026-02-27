import 'package:flutter/material.dart';

class CreateDiscussionMobileNav extends StatelessWidget {
  const CreateDiscussionMobileNav({
    super.key,
    required this.selectedIndex,
    required this.isLoading,
    required this.onSelectPage,
    required this.onSubmit,
  });

  final int selectedIndex;
  final bool isLoading;
  final ValueChanged<int> onSelectPage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: Color(0xff1A1A1A),
        border: Border(
          top: BorderSide(
            color: Colors.white12,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () => onSelectPage(0),
              child: AnimatedScale(
                scale: selectedIndex == 0 ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selectedIndex == 0
                          ? Icons.article
                          : Icons.article_outlined,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '正文',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Material(
              color: const Color(0xffFBC02D),
              shape: const CircleBorder(),
              child: InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                customBorder: const CircleBorder(),
                onTap: isLoading ? null : onSubmit,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: isLoading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        )
                      : const Icon(Icons.send, color: Colors.black),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () => onSelectPage(1),
              child: AnimatedScale(
                scale: selectedIndex == 1 ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selectedIndex == 1 ? Icons.image : Icons.image_outlined,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '封面',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
