import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class GameMenuGameCard extends StatelessWidget {
  const GameMenuGameCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: 14.borderRadiusAll,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.colorF8FAFB,
            borderRadius: 14.borderRadiusAll,
            border: Border.all(color: AppColors.colorE8EDF5),
          ),
          child: Padding(
            padding: 14.paddingAll,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: 12.borderRadiusAll,
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                12.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppStyles.h5(
                          color: AppColors.color1D2410,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      6.height,
                      Text(
                        description,
                        style: AppStyles.bodySmall(
                          color: AppColors.color667394,
                        ),
                      ),
                      10.height,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            LocaleKey.gameMenuPlayNow.tr,
                            style: AppStyles.bodyMedium(
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          4.width,
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: accentColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
