import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/utils/app_assets.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';
import 'package:flow_connection/src/utils/app_ui_sfx.dart';

class LinkNumberWinRewardSpinOverlay extends StatefulWidget {
  const LinkNumberWinRewardSpinOverlay({
    required this.isClaimingRewardAd,
    required this.onConfirmReward,
    required this.onClaimRewardX2,
    super.key,
  });

  final bool isClaimingRewardAd;
  final ValueChanged<int> onConfirmReward;
  final Future<bool> Function(int rewardCoins) onClaimRewardX2;

  @override
  State<LinkNumberWinRewardSpinOverlay> createState() =>
      _LinkNumberWinRewardSpinOverlayState();
}

class _LinkNumberWinRewardSpinOverlayState
    extends State<LinkNumberWinRewardSpinOverlay>
    with TickerProviderStateMixin {
  static const List<int> _rewardSegments = <int>[10, 20, 40, 60, 80, 100];
  static const List<Color> _segmentColors = <Color>[
    AppColors.color18A9FF,
    AppColors.color88CF66,
    AppColors.colorFF8B2F,
    AppColors.color8A56D8,
    AppColors.color18A9FF,
    AppColors.colorFF8B2F,
  ];
  static const Duration _spinBaseDuration = Duration(milliseconds: 3800);
  static const Duration _wheelLightPulseDuration = Duration(milliseconds: 1800);
  static const Duration _introAutoSpinDuration = Duration(milliseconds: 1500);

  final math.Random _random = math.Random();

  late final AnimationController _spinController;
  late final AnimationController _wheelLightPulseController;
  Animation<double>? _spinTurnsAnimation;
  double _wheelTurns = 0;
  int? _selectedSegmentIndex;
  bool _isIntroSpinInProgress = true;
  bool _isSpinning = false;
  bool _isClaimRequestInFlight = false;

  bool get _isClaimingRewardAd =>
      widget.isClaimingRewardAd || _isClaimRequestInFlight;

  bool get _hasSpun => _selectedSegmentIndex != null && !_isSpinning;

  int get _selectedRewardCoins {
    final index = _selectedSegmentIndex;
    if (index == null || index < 0 || index >= _rewardSegments.length) {
      return _rewardSegments.first;
    }
    return _rewardSegments[index];
  }

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: _spinBaseDuration,
    )..addStatusListener(_onSpinStatusChanged);
    _wheelLightPulseController = AnimationController(
      vsync: this,
      duration: _wheelLightPulseDuration,
    )..repeat();
    _startIntroAutoSpin();
  }

  @override
  void dispose() {
    _wheelLightPulseController.dispose();
    _spinController
      ..removeStatusListener(_onSpinStatusChanged)
      ..dispose();
    super.dispose();
  }

  void _onSpinStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }
    final animation = _spinTurnsAnimation;
    if (animation != null) {
      _wheelTurns = animation.value;
    }

    final isCompletingIntroSpin = _isIntroSpinInProgress;
    final shouldAutoGoToWinModal =
        !isCompletingIntroSpin && _selectedSegmentIndex != null;
    final resolvedReward = _selectedRewardCoins;

    setState(() {
      _isSpinning = false;
      if (isCompletingIntroSpin) {
        _isIntroSpinInProgress = false;
      }
      _spinTurnsAnimation = null;
    });

    if (shouldAutoGoToWinModal) {
      widget.onConfirmReward(resolvedReward);
    }
  }

  double _resolveTargetTurns({
    required int selectedIndex,
    required int fullLoops,
  }) {
    final segmentSweep = (2 * math.pi) / _rewardSegments.length;
    final desiredModulo = (-selectedIndex * segmentSweep) % (2 * math.pi);
    final currentAngle = _wheelTurns * (2 * math.pi);
    final currentModulo = currentAngle % (2 * math.pi);
    final delta = (desiredModulo - currentModulo) % (2 * math.pi);
    final targetAngle = currentAngle + (fullLoops * 2 * math.pi) + delta;
    return targetAngle / (2 * math.pi);
  }

  void _startIntroAutoSpin() {
    final introIndex = _rewardSegments.indexOf(10);
    final targetIndex = introIndex >= 0 ? introIndex : 0;
    final targetTurns = _resolveTargetTurns(
      selectedIndex: targetIndex,
      fullLoops: 5,
    );
    _isIntroSpinInProgress = true;
    _isSpinning = true;
    unawaited(AppUiSfx.playSpinStart());
    _spinTurnsAnimation = Tween<double>(begin: _wheelTurns, end: targetTurns)
        .animate(
          CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
        );
    _spinController
      ..duration = _introAutoSpinDuration
      ..stop()
      ..reset()
      ..forward();
  }

  void _onSpinPressed() {
    if (_isSpinning || _hasSpun || _isIntroSpinInProgress) {
      return;
    }
    unawaited(AppUiSfx.playSpinEnd());
    final selectedIndex = _random.nextInt(_rewardSegments.length);
    final fullLoops = 6 + _random.nextInt(3);
    final targetTurns = _resolveTargetTurns(
      selectedIndex: selectedIndex,
      fullLoops: fullLoops,
    );

    setState(() {
      _selectedSegmentIndex = selectedIndex;
      _isSpinning = true;
      _spinTurnsAnimation = Tween<double>(begin: _wheelTurns, end: targetTurns)
          .animate(
            CurvedAnimation(
              parent: _spinController,
              curve: Curves.easeOutQuart,
            ),
          );
    });

    _spinController
      ..duration = _spinBaseDuration
      ..stop()
      ..reset()
      ..forward();
  }

  void _onOkPressed() {
    if (!_hasSpun || _isClaimingRewardAd) {
      return;
    }
    unawaited(AppUiSfx.playButtonTap());
    widget.onConfirmReward(_selectedRewardCoins);
  }

  Future<void> _onClaimX2Pressed() async {
    if (!_hasSpun || _isClaimingRewardAd) {
      return;
    }
    unawaited(AppUiSfx.playButtonTap());
    setState(() {
      _isClaimRequestInFlight = true;
    });
    try {
      await widget.onClaimRewardX2(_selectedRewardCoins);
    } finally {
      if (mounted) {
        setState(() {
          _isClaimRequestInFlight = false;
        });
      }
    }
  }

  double _lerp(double begin, double end, double t) {
    return begin + ((end - begin) * t);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.black.withValues(alpha: 0.84),
      child: Center(
        child: Padding(
          padding: 14.paddingAll,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 460),
              curve: Curves.linear,
              builder: (context, progress, child) {
                final t = progress.clamp(0.0, 1.0);
                final fadeProgress = (t / 0.55).clamp(0.0, 1.0);
                final opacity = Curves.easeOutCubic.transform(fadeProgress);

                final scale = t < 0.72
                    ? _lerp(
                        0.84,
                        1.05,
                        Curves.easeOutCubic.transform((t / 0.72)),
                      )
                    : _lerp(
                        1.05,
                        1.0,
                        Curves.easeOutBack.transform(((t - 0.72) / 0.28)),
                      );

                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(scale: scale, child: child),
                );
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: 30.borderRadiusAll,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      AppColors.color131A29.withValues(alpha: 0.98),
                      AppColors.color111827.withValues(alpha: 0.99),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.colorFFE53E.withValues(alpha: 0.86),
                    width: 2.8,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.colorFFE53E.withValues(alpha: 0.32),
                      blurRadius: 28,
                      spreadRadius: 1.2,
                    ),
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.56),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        LocaleKey.linkNumberWinSpinTitle.tr,
                        style:
                            AppStyles.h2(
                              color: AppColors.colorFFE53E,
                              fontWeight: FontWeight.w900,
                            ).copyWith(
                              shadows: <Shadow>[
                                Shadow(
                                  color: AppColors.colorFF8B2F.withValues(
                                    alpha: 0.84,
                                  ),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      14.height,
                      SizedBox(
                        width: 330,
                        height: 330,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: <Widget>[
                            const Positioned.fill(child: _SpinWheelBackdrop()),
                            Positioned.fill(
                              child: Padding(
                                padding: 8.paddingAll,
                                child: AnimatedBuilder(
                                  animation: Listenable.merge(<Listenable>[
                                    _spinController,
                                    _wheelLightPulseController,
                                  ]),
                                  builder: (context, child) {
                                    final turns =
                                        _spinTurnsAnimation?.value ??
                                        _wheelTurns;
                                    return Transform.rotate(
                                      angle: turns * 2 * math.pi,
                                      child: CustomPaint(
                                        painter: _SpinWheelPainter(
                                          rewards: _rewardSegments,
                                          segmentColors: _segmentColors,
                                          lightPulse:
                                              _wheelLightPulseController.value,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const _SpinCenterStarBadge(),
                            Positioned(
                              top: -2,
                              child: _SpinPointer(isSpinning: _isSpinning),
                            ),
                          ],
                        ),
                      ),
                      18.height,
                      if (!_hasSpun)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          opacity: _isIntroSpinInProgress ? 0 : 1,
                          child: IgnorePointer(
                            ignoring: _isIntroSpinInProgress,
                            child: _SpinActionButton(
                              label: LocaleKey.linkNumberWinSpinSpin.tr
                                  .toUpperCase(),
                              icon: Icons.casino_rounded,
                              iconAssetPath: AppAssets.linkNumberSpinWheelPng,
                              onPressed: _isSpinning ? null : _onSpinPressed,
                              topColor: AppColors.colorFFCA2A,
                              bottomColor: AppColors.colorFF8B2F,
                              isPrimaryCta: true,
                            ),
                          ),
                        )
                      else
                        Column(
                          children: <Widget>[
                            DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: 999.borderRadiusAll,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    AppColors.color111827,
                                    AppColors.color131A29,
                                  ],
                                ),
                                border: Border.all(
                                  color: AppColors.colorFFE53E.withValues(
                                    alpha: 0.68,
                                  ),
                                  width: 1.5,
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: AppColors.colorFFE53E.withValues(
                                      alpha: 0.16,
                                    ),
                                    blurRadius: 10,
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Image.asset(
                                        AppAssets.gameMenuCoinPng,
                                      ),
                                    ),
                                    6.width,
                                    Text(
                                      LocaleKey.linkNumberWinSpinResult
                                          .trParams(<String, String>{
                                            'count': '$_selectedRewardCoins',
                                          }),
                                      style: AppStyles.h4(
                                        color: AppColors.colorFFE53E,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            12.height,
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: _SpinActionButton(
                                    label: LocaleKey.ok.tr.toUpperCase(),
                                    icon: Icons.check_rounded,
                                    onPressed: _isClaimingRewardAd
                                        ? null
                                        : _onOkPressed,
                                    topColor: AppColors.color18A9FF,
                                    bottomColor: AppColors.color0095FF,
                                  ),
                                ),
                                10.width,
                                Expanded(
                                  child: _SpinActionButton(
                                    label: LocaleKey.linkNumberWinSpinClaimX2.tr
                                        .toUpperCase(),
                                    icon: Icons.ondemand_video_rounded,
                                    onPressed: _isClaimingRewardAd
                                        ? null
                                        : _onClaimX2Pressed,
                                    isLoading: _isClaimingRewardAd,
                                    topColor: AppColors.color88CF66,
                                    bottomColor: AppColors.color14B8A6,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpinWheelBackdrop extends StatelessWidget {
  const _SpinWheelBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              AppColors.colorFFE53E.withValues(alpha: 0.22),
              AppColors.colorFF8B2F.withValues(alpha: 0.12),
              AppColors.transparent,
            ],
            stops: const <double>[0.12, 0.52, 1],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.colorFFE53E.withValues(alpha: 0.2),
              blurRadius: 34,
              spreadRadius: 3,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpinPointer extends StatelessWidget {
  const _SpinPointer({required this.isSpinning});

  final bool isSpinning;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSpinning ? 1.06 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: SizedBox(
        width: 52,
        height: 58,
        child: CustomPaint(painter: _SpinPointerPainter()),
      ),
    );
  }
}

class _SpinCenterStarBadge extends StatelessWidget {
  const _SpinCenterStarBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  AppColors.colorFFE53E.withValues(alpha: 0.42),
                  AppColors.colorF39702.withValues(alpha: 0.24),
                  AppColors.transparent,
                ],
                stops: const <double>[0.0, 0.56, 1.0],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  AppColors.color131A29.withValues(alpha: 0.94),
                  AppColors.black.withValues(alpha: 0.96),
                ],
              ),
              border: Border.all(
                color: AppColors.colorFFE53E.withValues(alpha: 0.92),
                width: 2.4,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.colorFFE53E.withValues(alpha: 0.36),
                  blurRadius: 16,
                  spreadRadius: 1.4,
                ),
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.28),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Icon(
                  Icons.star_rounded,
                  size: 26,
                  color: AppColors.colorFFE53E,
                  shadows: <Shadow>[
                    Shadow(
                      color: AppColors.colorFFCA2A.withValues(alpha: 0.95),
                      blurRadius: 10,
                    ),
                    Shadow(
                      color: AppColors.white.withValues(alpha: 0.34),
                      blurRadius: 2,
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

class _SpinPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final bodyTop = size.height * 0.08;
    final bodyBottom = size.height * 0.96;
    final bodyWidth = size.width * 0.86;

    final path = Path()
      ..moveTo(centerX, bodyBottom)
      ..lineTo(centerX - (bodyWidth / 2), bodyTop + 8)
      ..quadraticBezierTo(
        centerX,
        bodyTop - 4,
        centerX + (bodyWidth / 2),
        bodyTop + 8,
      )
      ..close();

    final pointerRect = Rect.fromLTWH(0, bodyTop - 4, size.width, size.height);
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          AppColors.colorFFCA2A,
          AppColors.colorF39702,
          AppColors.colorFF8B2F,
        ],
      ).createShader(pointerRect);
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = AppColors.colorFFE53E.withValues(alpha: 0.9);
    canvas.drawPath(path, strokePaint);

    final capRect = Rect.fromCenter(
      center: Offset(centerX, bodyTop + 2),
      width: size.width * 0.46,
      height: size.height * 0.26,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, 9.borderRadiusAll.topLeft),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[AppColors.colorFFCA2A, AppColors.colorFF8B2F],
        ).createShader(capRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, 9.borderRadiusAll.topLeft),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = AppColors.colorFFE53E.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _SpinPointerPainter oldDelegate) => false;
}

class _SpinActionButton extends StatelessWidget {
  const _SpinActionButton({
    required this.label,
    required this.icon,
    this.iconAssetPath,
    required this.onPressed,
    required this.topColor,
    required this.bottomColor,
    this.isPrimaryCta = false,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final String? iconAssetPath;
  final VoidCallback? onPressed;
  final Color topColor;
  final Color bottomColor;
  final bool isPrimaryCta;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final buttonHeight = isPrimaryCta ? 62.0 : 56.0;
    final iconSize = isPrimaryCta ? 22.0 : 19.0;
    final borderWidth = isPrimaryCta ? 2.2 : 1.6;
    return SizedBox(
      height: buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: 999.borderRadiusAll,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDisabled
                ? <Color>[
                    AppColors.colorF6B7280.withValues(alpha: 0.66),
                    AppColors.colorF64748B.withValues(alpha: 0.7),
                  ]
                : <Color>[topColor, bottomColor],
          ),
          border: Border.all(
            color: AppColors.white.withValues(alpha: isDisabled ? 0.24 : 0.56),
            width: borderWidth,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.34),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
            if (!isDisabled)
              BoxShadow(
                color: topColor.withValues(alpha: 0.2),
                blurRadius: 12,
                spreadRadius: 0.6,
              ),
            if (!isDisabled && isPrimaryCta)
              BoxShadow(
                color: AppColors.colorFFE53E.withValues(alpha: 0.34),
                blurRadius: 18,
                spreadRadius: 1.8,
              ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: 999.borderRadiusAll,
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (iconAssetPath != null)
                            SizedBox(
                              width: iconSize + 2,
                              height: iconSize + 2,
                              child: Image.asset(iconAssetPath!),
                            )
                          else
                            Icon(
                              icon,
                              color: AppColors.white.withValues(alpha: 0.95),
                              size: iconSize,
                            ),
                          6.width,
                          Flexible(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: isPrimaryCta
                                  ? AppStyles.h4(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w900,
                                    )
                                  : AppStyles.bodyMedium(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpinWheelPainter extends CustomPainter {
  const _SpinWheelPainter({
    required this.rewards,
    required this.segmentColors,
    required this.lightPulse,
  });

  final List<int> rewards;
  final List<Color> segmentColors;
  final double lightPulse;

  @override
  void paint(Canvas canvas, Size size) {
    if (rewards.isEmpty) {
      return;
    }

    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final rimRadius = radius - 10;
    final segmentOuterRadius = rimRadius - 12;
    const segmentGap = 0.0;
    final segmentSweep = (2 * math.pi) / rewards.length;
    final baseStartAngle = (-math.pi / 2) - (segmentSweep / 2);

    final outerGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..color = AppColors.colorFFE53E.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, rimRadius - 2, outerGlowPaint);

    final rimRect = Rect.fromCircle(center: center, radius: rimRadius);
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: (3 * math.pi) / 2,
        colors: <Color>[
          AppColors.colorFFCA2A,
          AppColors.colorF39702,
          AppColors.colorFF8B2F,
          AppColors.colorFFCA2A,
        ],
      ).createShader(rimRect);
    canvas.drawCircle(center, rimRadius, rimPaint);

    final rimStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = AppColors.colorFFE53E.withValues(alpha: 0.84);
    canvas.drawCircle(center, rimRadius + 7.5, rimStrokePaint);
    canvas.drawCircle(center, rimRadius - 7.5, rimStrokePaint);

    const lightCount = 32;
    for (var index = 0; index < lightCount; index++) {
      final angle = (-math.pi / 2) + ((index / lightCount) * 2 * math.pi);
      final pulse =
          0.35 +
          0.65 *
              ((math.sin((lightPulse * 2 * math.pi * 1.8) + (index * 0.9)) +
                      1) /
                  2);
      final bulbCenter = Offset(
        center.dx + (math.cos(angle) * (rimRadius - 1.5)),
        center.dy + (math.sin(angle) * (rimRadius - 1.5)),
      );
      canvas.drawCircle(
        bulbCenter,
        7.2,
        Paint()..color = AppColors.colorFFE53E.withValues(alpha: 0.12 * pulse),
      );
      canvas.drawCircle(
        bulbCenter,
        3.2,
        Paint()..color = AppColors.colorFFE53E.withValues(alpha: 0.52 * pulse),
      );
    }

    final outerRect = Rect.fromCircle(
      center: center,
      radius: segmentOuterRadius,
    );
    for (var index = 0; index < rewards.length; index++) {
      final rawStartAngle = baseStartAngle + (index * segmentSweep);
      final startAngle = rawStartAngle + (segmentGap / 2);
      final drawSweep = segmentSweep - segmentGap;
      final color = segmentColors[index % segmentColors.length];
      final topTone = Color.lerp(color, AppColors.white, 0.22) ?? color;
      final bottomTone = Color.lerp(color, AppColors.black, 0.2) ?? color;

      final segmentPath = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(outerRect, startAngle, drawSweep, false)
        ..close();

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[topTone, bottomTone],
        ).createShader(outerRect);
      canvas.drawPath(segmentPath, fillPaint);

      canvas.save();
      canvas.clipPath(segmentPath);
      canvas.drawCircle(
        Offset(center.dx, center.dy - (segmentOuterRadius * 0.34)),
        segmentOuterRadius * 0.9,
        Paint()
          ..shader =
              RadialGradient(
                colors: <Color>[
                  AppColors.white.withValues(alpha: 0.2),
                  AppColors.transparent,
                ],
                stops: const <double>[0.1, 1],
              ).createShader(
                Rect.fromCircle(
                  center: Offset(
                    center.dx,
                    center.dy - (segmentOuterRadius * 0.34),
                  ),
                  radius: segmentOuterRadius * 0.9,
                ),
              ),
      );
      canvas.restore();

      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = AppColors.white.withValues(alpha: 0.34);
      canvas.drawPath(segmentPath, borderPaint);

      final labelAngle = rawStartAngle + (segmentSweep / 2);
      final labelRadius = segmentOuterRadius * 0.62;
      final labelCenter = Offset(
        center.dx + (math.cos(labelAngle) * labelRadius),
        center.dy + (math.sin(labelAngle) * labelRadius),
      );

      final rewardTextPainter = TextPainter(
        text: TextSpan(
          text: '${rewards[index]}',
          style:
              AppStyles.h2(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ).copyWith(
                fontSize: 24,
                height: 1,
                shadows: <Shadow>[
                  Shadow(
                    color: AppColors.black.withValues(alpha: 0.36),
                    offset: const Offset(0, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      rewardTextPainter.paint(
        canvas,
        Offset(
          labelCenter.dx - (rewardTextPainter.width / 2),
          labelCenter.dy - (rewardTextPainter.height / 2) - 8,
        ),
      );

      _paintCoin(
        canvas,
        center: Offset(labelCenter.dx, labelCenter.dy + 20),
        radius: 10.5,
      );
    }
  }

  void _paintCoin(
    Canvas canvas, {
    required Offset center,
    required double radius,
  }) {
    final outerRect = Rect.fromCircle(center: center, radius: radius);
    final innerRadius = radius * 0.66;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.colorFFE53E,
            AppColors.colorFFCA2A,
            AppColors.colorF39702,
          ],
        ).createShader(outerRect),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.colorFF8B2F.withValues(alpha: 0.92),
    );

    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[AppColors.colorFFE53E, AppColors.colorF39702],
        ).createShader(Rect.fromCircle(center: center, radius: innerRadius)),
    );

    final symbolPainter = TextPainter(
      text: TextSpan(
        text: 'S',
        style: AppStyles.bodyMedium(
          color: AppColors.colorFF8B2F,
          fontWeight: FontWeight.w900,
        ).copyWith(fontSize: radius * 1.08, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    symbolPainter.paint(
      canvas,
      Offset(
        center.dx - (symbolPainter.width / 2),
        center.dy - (symbolPainter.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _SpinWheelPainter oldDelegate) {
    return oldDelegate.rewards != rewards ||
        oldDelegate.segmentColors != segmentColors ||
        oldDelegate.lightPulse != lightPulse;
  }
}
