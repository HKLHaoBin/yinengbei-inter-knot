import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:inter_knot/api/api.dart';
import 'package:inter_knot/controllers/data.dart';
import 'package:inter_knot/constants/globals.dart';
import 'package:inter_knot/helpers/copy_text.dart';
import 'package:inter_knot/pages/history_page.dart';
import 'package:inter_knot/pages/liked_page.dart';
import 'package:inter_knot/pages/login_page.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Obx(
            () => ListTile(
              leading: const Icon(Icons.favorite),
              title: Text('Like'.tr),
              onTap: () => Get.to(() => const LikedPage()),
              subtitle: Text(
                'A total of @count items'
                    .trParams({'count': c.bookmarks.length.toString()}),
              ),
            ),
          ),
          Obx(
            () => ListTile(
              leading: const Icon(Icons.history),
              title: Text('History'.tr),
              onTap: () => Get.to(() => const HistoryPage()),
              subtitle: Text(
                'A total of @count items'
                    .trParams({'count': c.history.length.toString()}),
              ),
            ),
          ),
          FutureBuilder(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final fullVer =
                    'v${snapshot.data!.version}+${snapshot.data!.buildNumber}';
                return ListTile(
                  onTap: () => copyText(fullVer),
                  title: Text('Current version'.tr),
                  subtitle: Text(fullVer),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Obx(() {
            if (c.isLogin()) {
              return ListTile(
                onTap: () async {
                  await c.pref.remove('access_token');
                  c.isLogin(false);
                  Get.rawSnackbar(message: 'Logout successfully'.tr);
                },
                title: Text('Logout'.tr),
                leading: const Icon(Icons.logout),
              );
            } else {
              return ListTile(
                onTap: () => Get.to(() => const LoginPage()),
                title: Text('Login'.tr),
                leading: const Icon(Icons.login),
              );
            }
          }),
          // Documentation and Links
          ListTile(
            leading: Icon(MdiIcons.github),
            title: const Text('Github'),
            onTap: () => launchUrlString(githubLink),
            subtitle: const Text(githubLink),
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: Text('Documentation'.tr),
            onTap: () => launchUrlString(docLink),
            subtitle: const Text(docLink),
          ),
        ],
      ),
    );
  }
}
