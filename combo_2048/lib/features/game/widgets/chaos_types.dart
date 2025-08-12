import 'dart:math' as math;
import 'package:combo_2048/features/logic/game_logic.dart';
import 'package:combo_2048/tile.dart';

/// Tipos de caos
enum ChaosType { doubleSpawn, mirrorControls, shuffleOnce }

/// Estado do caos (tipo + jogadas restantes)
class ChaosState {
  final ChaosType type;
  int movesLeft;
  ChaosState(this.type, this.movesLeft);
}

/// Rótulo amigável para UI
String? chaosLabel(ChaosState? s) {
  if (s == null) return null;
  switch (s.type) {
    case ChaosType.doubleSpawn:
      return 'Duplo Spawn';
    case ChaosType.mirrorControls:
      return 'Controles Invertidos';
    case ChaosType.shuffleOnce:
      return 'Embaralhar';
  }
}

/// Duração padrão por tipo
int defaultChaosDuration(ChaosType t) => (t == ChaosType.shuffleOnce) ? 1 : 10;

/// Sorteia um caos
ChaosState drawChaos(math.Random rng) {
  final values = ChaosType.values;
  final chosen = values[rng.nextInt(values.length)];
  return ChaosState(chosen, defaultChaosDuration(chosen));
}

/// Inverte direção se caos exigir
SwipeDirection maybeMirror(SwipeDirection d, ChaosState? s) {
  if (s?.type != ChaosType.mirrorControls) return d;
  switch (d) {
    case SwipeDirection.up:
      return SwipeDirection.down;
    case SwipeDirection.down:
      return SwipeDirection.up;
    case SwipeDirection.left:
      return SwipeDirection.right;
    case SwipeDirection.right:
      return SwipeDirection.left;
  }
}

/// Define os valores de spawn para esta jogada (1 ou 2 tiles)
List<int> spawnForThisMove(ChaosState? s, int Function() spawnValue) {
  if (s?.type == ChaosType.doubleSpawn) {
    return [spawnValue(), spawnValue()];
  }
  return [spawnValue()];
}

/// Aplica efeito instantâneo (embaralhar) e retorna se foi consumido
bool applyInstantChaosIfAny({
  required ChaosState state,
  required Iterable<Tile> tiles,
  required math.Random rng,
  required void Function() onAfterApply,
}) {
  if (state.type != ChaosType.shuffleOnce) return false;

  final values = tiles.map((t) => t.value).toList()..shuffle(rng);
  int k = 0;
  for (final t in tiles) {
    t.value = values[k++];
    t.resetAnimations();
  }
  onAfterApply();
  return true;
}
