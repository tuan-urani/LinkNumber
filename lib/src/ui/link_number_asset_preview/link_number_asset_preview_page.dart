import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/link_number_asset_preview/components/link_number_asset_preview_sections.dart';
import 'package:flow_connection/src/ui/link_number_asset_preview/interactor/link_number_asset_preview_controller.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class LinkNumberAssetPreviewPage
    extends GetView<LinkNumberAssetPreviewController> {
  const LinkNumberAssetPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.color131A29,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppColors.color131A29,
              AppColors.splashBackgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: 16.paddingAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _PreviewHeader(),
                16.height,
                Expanded(
                  child: Obx(() {
                    return switch (controller.status.value) {
                      LinkNumberAssetPreviewStatus.loading => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.splashProgressFill,
                        ),
                      ),
                      LinkNumberAssetPreviewStatus.empty => Center(
                        child: Text(
                          LocaleKey.linkNumberAssetPreviewNoAssets.tr,
                          style: AppStyles.bodyLarge(color: AppColors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      LinkNumberAssetPreviewStatus.success =>
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              LinkNumberAssetPreviewStaticSection(
                                assets: controller.staticAssets,
                              ),
                              20.height,
                              const LinkNumberAssetPreviewBoardSection(),
                              20.height,
                              LinkNumberAssetPreviewAnimatedSection(
                                assets: controller.animatedBallAssets,
                              ),
                              24.height,
                            ],
                          ),
                        ),
                    };
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: Get.back,
            borderRadius: 12.borderRadiusAll,
            child: Ink(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.12),
                borderRadius: 12.borderRadiusAll,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.28),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        12.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                LocaleKey.linkNumberAssetPreviewTitle.tr,
                style: AppStyles.h4(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              4.height,
              Text(
                LocaleKey.linkNumberAssetPreviewSubtitle.tr,
                style: AppStyles.bodySmall(
                  color: AppColors.white.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
