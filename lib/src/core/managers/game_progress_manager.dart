import 'package:flow_connection/src/utils/app_shared.dart';

class GameProgressManager {
  GameProgressManager(this._appShared);

  static const int _defaultCurrentLevel = 1;
  static const int _defaultCoins = 200;
  static const int _defaultStars = 0;

  final AppShared _appShared;

  int _currentLevel = _defaultCurrentLevel;
  int _coins = _defaultCoins;
  int _stars = _defaultStars;

  int get currentLevel => _currentLevel;
  int get coins => _coins;
  int get stars => _stars;

  Future<void> init() async {
    final savedLevel = _appShared.getLinkNumberCurrentLevel();
    final savedCoins = _appShared.getLinkNumberCoins();
    final savedStars = _appShared.getLinkNumberStars();

    _currentLevel = savedLevel != null && savedLevel > 0
        ? savedLevel
        : _defaultCurrentLevel;
    _coins = savedCoins != null && savedCoins >= 0 ? savedCoins : _defaultCoins;
    _stars = savedStars != null && savedStars >= 0 ? savedStars : _defaultStars;
  }

  Future<void> saveProgress({
    required int currentLevel,
    required int coins,
    required int stars,
  }) async {
    _currentLevel = currentLevel > 0 ? currentLevel : _defaultCurrentLevel;
    _coins = coins >= 0 ? coins : _defaultCoins;
    _stars = stars >= 0 ? stars : _defaultStars;

    await Future.wait<void>(<Future<void>>[
      _appShared.setLinkNumberCurrentLevel(_currentLevel),
      _appShared.setLinkNumberCoins(_coins),
      _appShared.setLinkNumberStars(_stars),
    ]);
  }
}
