import 'package:combo_2048/tile.dart';
import 'package:flutter/animation.dart';

/// Direções do swipe
enum SwipeDirection { up, down, left, right }

/// Estado para desfazer jogada
class GameState {
  final List<List<Tile>> _previousGrid;
  final SwipeDirection swipe;

  GameState(List<List<Tile>> previousGrid, this.swipe) : _previousGrid = previousGrid;

  List<List<Tile>> get previousGrid => _previousGrid.map((row) => row.map((tile) => tile.copy()).toList()).toList();
}

/// Mixin com a LÓGICA de mergir movimentação (2,4,8,16...)
/// A UI hospedeira só precisa prover os getters/sets abaixo e
/// implementar [onMerged] para pontuação (ou outras reações).
mixin MergeLogic<T> {
  // --- contratos que a tela hospedeira deve prover ---
  AnimationController get controller;

  List<List<Tile>> get grid;
  set grid(List<List<Tile>> value);

  Iterable<Tile> get gridTiles;
  List<List<Tile>> get gridCols;

  /// Chamado a cada fusão com o valor resultante (ex.: 2+2=>4)
  void onMerged(int mergedValue);

  // --- funções de direção (não mexer mais nelas) ---

  bool mergeLeft() => grid.map((row) => mergeTiles(row)).toList().any((e) => e);

  bool mergeRight() => grid.map((row) => mergeTiles(row.reversed.toList())).toList().any((e) => e);

  bool mergeUp() => gridCols.map((col) => mergeTiles(col)).toList().any((e) => e);

  bool mergeDown() => gridCols.map((col) => mergeTiles(col.reversed.toList())).toList().any((e) => e);

  /// Regra clássica: tiles iguais fundem (2+2=4, 4+4=8, ...).
  /// Chama [onMerged] com o valor do tile resultante para pontuação.
  bool mergeTiles(List<Tile> tiles) {
    bool didChange = false;

    for (int i = 0; i < tiles.length; i++) {
      for (int j = i; j < tiles.length; j++) {
        if (tiles[j].value != 0) {
          final nextIndex = tiles.indexWhere((t) => t.value != 0, j + 1);
          Tile? mergeTile = nextIndex == -1 ? null : tiles[nextIndex];

          // Se existir um próximo não-vazio diferente, não funde
          if (mergeTile != null && mergeTile.value != tiles[j].value) {
            mergeTile = null;
          }

          if (i != j || mergeTile != null) {
            didChange = true;

            int resultValue = tiles[j].value;
            tiles[j].moveTo(controller, tiles[i].x, tiles[i].y);

            if (mergeTile != null) {
              resultValue += mergeTile.value; // soma (2+2, 4+4, ...)
              onMerged(resultValue); // >>> notifica pontuação

              mergeTile.moveTo(controller, tiles[i].x, tiles[i].y);
              mergeTile.bounce(controller);
              mergeTile.changeNumber(controller, resultValue);
              mergeTile.value = 0;
            }

            tiles[j].changeNumber(controller, 0);
            tiles[j].value = 0;
            tiles[i].value = resultValue;
          }
          break;
        }
      }
    }

    return didChange;
  }
}
