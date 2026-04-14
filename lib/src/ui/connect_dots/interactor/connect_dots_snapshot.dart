class ConnectDotsSnapshot {
  const ConnectDotsSnapshot({
    required this.inkLeft,
    required this.linesUsed,
    required this.hasWon,
  });

  static const double maxInk = 52;

  factory ConnectDotsSnapshot.initial() {
    return const ConnectDotsSnapshot(
      inkLeft: maxInk,
      linesUsed: 0,
      hasWon: false,
    );
  }

  final double inkLeft;
  final int linesUsed;
  final bool hasWon;

  int get inkPercent => ((inkLeft / maxInk) * 100).round();

  ConnectDotsSnapshot copyWith({
    double? inkLeft,
    int? linesUsed,
    bool? hasWon,
  }) {
    return ConnectDotsSnapshot(
      inkLeft: inkLeft ?? this.inkLeft,
      linesUsed: linesUsed ?? this.linesUsed,
      hasWon: hasWon ?? this.hasWon,
    );
  }
}
