class AppAssets {
  AppAssets._();

  static const String iconsInputRequiredSvg =
      'assets/images/icons/input_required.svg';
  static const String iconsChevronDownSvg =
      'assets/images/icons/chevron down.svg';
  static const String iconsRadioCheckSvg =
      'assets/images/icons/radio_check.svg';
  static const String iconsRadioUncheckSvg =
      'assets/images/icons/radio_uncheck.svg';
  static const String iconsHideEyeSvg = 'assets/images/icons/hide_eye.svg';
  static const String iconsShowEyeSvg = 'assets/images/icons/show_eye.svg';

  static const String linkNumberTileBallBasePng =
      'assets/game/balls/tile_ball_base.png';
  static const String linkNumberTileBallHighlightPng =
      'assets/game/balls/tile_ball_highlight.png';
  static const String linkNumberTileBallShadowSoftPng =
      'assets/game/balls/tile_ball_shadow_soft.png';
  static const String linkNumberMergeBurstSheetPng =
      'assets/game/effects/explosion/merge_burst_sheet_01.png';
  static const String linkNumberPathGlowPng =
      'assets/game/effects/path_glow.png';
  static const String linkNumberSkillBreakAxePng =
      'assets/game/skills/link_number_skill_break_axe.png';

  static const List<int> linkNumberAnimatedBallValues = <int>[
    2,
    4,
    8,
    16,
    32,
    64,
  ];

  static final Set<int> _linkNumberAnimatedBallValueSet =
      linkNumberAnimatedBallValues.toSet();

  static bool supportsLinkNumberAnimatedBall(int value) =>
      _linkNumberAnimatedBallValueSet.contains(value);

  static String linkNumberBallIdleLoopGif(int value) =>
      'assets/game/balls/gif/ball_${value}_idle_loop.gif';

  static String linkNumberBallSelectedPathLoopGif(int value) =>
      'assets/game/balls/gif/ball_${value}_selected_path_loop.gif';

  static String linkNumberBallDestroyingOutGif(int value) =>
      'assets/game/balls/gif/ball_${value}_destroying_out.gif';
}
