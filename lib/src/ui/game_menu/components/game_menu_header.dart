import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class GameMenuHeader extends StatelessWidget {
  const GameMenuHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          LocaleKey.gameMenuTitle.tr,
          style: AppStyles.h3(
            color: AppColors.color1D2410,
            fontWeight: FontWeight.w700,
          ),
        ),
        6.height,
        Text(
          LocaleKey.gameMenuSubtitle.tr,
          style: AppStyles.bodyMedium(color: AppColors.color667394),
        ),
      ],
    );
  }
}
