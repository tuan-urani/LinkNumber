class AppAssets {
  AppAssets._();

  static const String tapTutorialSvg = 'assets/tap_tutorial.svg';
  static const String linkNumberSkillHammerSvg = 'assets/hammer.svg';
  static const String gameMenuCoinPng = 'assets/coin.png';
  static const String gameMenuCurrentLevelPng = 'assets/current_level.png';
  static const String gameMenuMainMenuPng = 'assets/main_menu.png';
  static const String splashMainSloganPng = 'assets/main_slogan.png';
  static const String linkNumberSelectedSfxMp3 = 'assets/music/selected.mp3';
  static const String linkNumberPopCellSfxMp3 = 'assets/music/pop_cell.mp3';
  static const String linkNumberSuccessSfxMp3 = 'assets/music/success.mp3';
  static const String linkNumberLossSfxMp3 = 'assets/music/loss.mp3';
  static const String linkNumberFeverSfxMp3 = 'assets/music/fever.mp3';
  static const String numberConnectMenuCleanBackgroundGrayPng =
      'assets/game/backgrounds/number_connect_menu_clean_background_gray.png';
  static const String boardGameTableBackgroundPng =
      'assets/game/board_pack/backgrounds/board_game_table_background.png';
  static const String boardGameClassicWoodBackgroundPng =
      'assets/game/board_pack/backgrounds/board_game_classic_wood_background.png';
  static const String boardGameCellBackground5x6Png =
      'assets/game/board_pack/backgrounds/board_game_cell_background_5x6.png';
  static const String boardGameCleanPlayfieldPng =
      'assets/game/board_pack/backgrounds/board_game_clean_playfield.png';
  static const String boardGamePanelBackgroundPng =
      'assets/game/board_pack/backgrounds/board_game_panel_background.png';
  static const String boardGameTilePlainPng =
      'assets/game/board_pack/tiles/board_game_tile_plain.png';
  static const String boardGameTileHoverPng =
      'assets/game/board_pack/tiles/board_game_tile_hover.png';
  static const String boardGameTileSelectedPng =
      'assets/game/board_pack/tiles/board_game_tile_selected.png';
  static const String boardGameTileBlockedPng =
      'assets/game/board_pack/tiles/board_game_tile_blocked.png';
  static const String boardGameTileMoveHintPng =
      'assets/game/board_pack/tiles/board_game_tile_move_hint.png';
  static const String boardGameTileMergeHintPng =
      'assets/game/board_pack/tiles/board_game_tile_merge_hint.png';
  static const String boardGamePawnBluePng =
      'assets/game/board_pack/pieces/board_game_pawn_blue.png';
  static const String boardGamePawnRedPng =
      'assets/game/board_pack/pieces/board_game_pawn_red.png';
  static const String boardGamePawnGreenPng =
      'assets/game/board_pack/pieces/board_game_pawn_green.png';
  static const String boardGamePawnYellowPng =
      'assets/game/board_pack/pieces/board_game_pawn_yellow.png';
  static const String boardGameDiceWhitePng =
      'assets/game/board_pack/pieces/board_game_dice_white.png';
  static const String boardGameCardBackPng =
      'assets/game/board_pack/pieces/board_game_card_back.png';
  static const String boardGamePathGlowSoftPng =
      'assets/game/board_pack/effects/board_game_path_glow_soft.png';
  static const String boardGameSelectionRingPng =
      'assets/game/board_pack/effects/board_game_selection_ring.png';

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
  static const String linkNumberSkillBreakIdleLoopGif =
      'assets/game/skills/link_number_skill_break_idle_loop.gif';
  static const String linkNumberSkillBreakSelectedLoopGif =
      'assets/game/skills/link_number_skill_break_selected_loop.gif';
  static const String linkNumberSkillBreakExecutingGif =
      'assets/game/skills/link_number_skill_break_executing.gif';
  static const String linkNumberSkillBreakTravelLoopGif =
      'assets/game/skills/link_number_skill_break_travel_loop.gif';
  static const String linkNumberSkillSwapIdleLoopGif =
      'assets/game/skills/link_number_skill_swap_idle_loop.gif';
  static const String linkNumberSkillSwapSelectedLoopGif =
      'assets/game/skills/link_number_skill_swap_selected_loop.gif';
  static const String linkNumberSkillSwapExecutingGif =
      'assets/game/skills/link_number_skill_swap_executing.gif';
  static const String linkNumberV2CoreBallIdleLoopGif =
      'gen-asset/assets/game/balls/gif/ball_core_idle_loop.gif';
  static const String linkNumberV2CoreBallSelectedPathLoopGif =
      'gen-asset/assets/game/balls/gif/ball_core_selected_path_loop.gif';
  static const String linkNumberV2CoreBallDestroyingOutGif =
      'gen-asset/assets/game/balls/gif/ball_core_destroying_out.gif';

  static const List<int> linkNumberAnimatedBallValues = <int>[
    2,
    4,
    8,
    16,
    32,
    64,
    128,
    256,
    512,
    1024,
    2048,
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
