import 'package:flow_connection/src/utils/app_shared.dart';
import 'package:get/get.dart';

class GameProgressManager {
  GameProgressManager(this._appShared);

  static const int _defaultCurrentLevel = 1;
  static const int _defaultCoins = 200;
  static const int _defaultStars = 0;

  final AppShared _appShared;
  final RxInt currentLevelRx = _defaultCurrentLevel.obs;
  final RxInt coinsRx = _defaultCoins.obs;
  final RxInt starsRx = _defaultStars.obs;

  int get currentLevel => currentLevelRx.value;
  int get coins => coinsRx.value;
  int get stars => starsRx.value;

  Future<void> init() async {
    final savedLevel = _appShared.getLinkNumberCurrentLevel();
    final savedCoins = _appShared.getLinkNumberCoins();
    final savedStars = _appShared.getLinkNumberStars();

    currentLevelRx.value = savedLevel != null && savedLevel > 0
        ? savedLevel
        : _defaultCurrentLevel;
    coinsRx.value = savedCoins != null && savedCoins >= 0
        ? savedCoins
        : _defaultCoins;
    starsRx.value = savedStars != null && savedStars >= 0
        ? savedStars
        : _defaultStars;
  }

  Future<void> saveProgress({
    required int currentLevel,
    required int coins,
    required int stars,
  }) async {
    currentLevelRx.value = currentLevel > 0
        ? currentLevel
        : _defaultCurrentLevel;
    coinsRx.value = coins >= 0 ? coins : _defaultCoins;
    starsRx.value = stars >= 0 ? stars : _defaultStars;

    await Future.wait<void>(<Future<void>>[
      _appShared.setLinkNumberCurrentLevel(currentLevelRx.value),
      _appShared.setLinkNumberCoins(coinsRx.value),
      _appShared.setLinkNumberStars(starsRx.value),
    ]);
  }
}
