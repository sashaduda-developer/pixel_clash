class PlayerBuildState {
  PlayerBuildState({Map<String, int>? stacks}) : stacks = stacks ?? <String, int>{};

  /// id -> stacks
  final Map<String, int> stacks;

  int getStacks(String id) => stacks[id] ?? 0;

  int addStack(String id, {int delta = 1}) {
    final next = (stacks[id] ?? 0) + delta;
    stacks[id] = next;
    return next;
  }

  Map<String, Object?> toJson() => {
        'stacks': stacks,
      };

  static PlayerBuildState fromJson(Map<String, Object?> json) {
    final raw = json['stacks'];
    final map = <String, int>{};

    if (raw is Map) {
      for (final e in raw.entries) {
        final k = e.key;
        final v = e.value;
        if (k is String && v is num) {
          map[k] = v.toInt();
        }
      }
    }

    return PlayerBuildState(stacks: map);
  }
}
