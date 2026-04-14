import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/connect_dots/interactor/connect_dots_snapshot.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class ConnectDotsHeader extends StatelessWidget {
  const ConnectDotsHeader({
    required this.snapshot,
    required this.onRestart,
    required this.onClear,
    super.key,
  });

  final ConnectDotsSnapshot snapshot;
  final VoidCallback onRestart;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(LocaleKey.connectDotsTitle.tr, style: AppStyles.h3()),
          6.height,
          Text(
            LocaleKey.connectDotsSubtitle.tr,
            style: AppStyles.bodyMedium(color: AppColors.color667394),
          ),
          14.height,
          Row(
            children: <Widget>[
              Expanded(
                child: _InfoCard(
                  label: LocaleKey.connectDotsInk.tr,
                  value: '${snapshot.inkPercent}%',
                ),
              ),
              10.width,
              Expanded(
                child: _InfoCard(
                  label: LocaleKey.connectDotsLines.tr,
                  value: snapshot.linesUsed.toString(),
                ),
              ),
              10.width,
              Expanded(
                child: _InfoCard(
                  label: LocaleKey.connectDotsGoal.tr,
                  value: LocaleKey.connectDotsGoalValue.tr,
                ),
              ),
            ],
          ),
          10.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: onClear,
                child: Text(
                  LocaleKey.connectDotsClear.tr,
                  style: AppStyles.bodyMedium(
                    color: AppColors.color2D7DD2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              10.width,
              TextButton(
                onPressed: onRestart,
                child: Text(
                  LocaleKey.connectDotsRestart.tr,
                  style: AppStyles.bodyMedium(
                    color: AppColors.color2D7DD2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.colorF8FAFB,
        borderRadius: 12.borderRadiusAll,
        border: Border.all(color: AppColors.colorE8EDF5),
      ),
      child: Padding(
        padding: 10.paddingAll,
        child: Column(
          children: <Widget>[
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.bodySmall(color: AppColors.color667394),
            ),
            4.height,
            Text(
              value,
              textAlign: TextAlign.center,
              style: AppStyles.h5(
                color: AppColors.color1D2410,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
