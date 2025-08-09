import 'dart:async';

import 'package:combo_2048/grid-peoperties.dart';
import 'package:combo_2048/tile.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      title: '2048',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, visualDensity: VisualDensity.adaptivePlatformDensity),
      home: TwentyFortyEight(),
    ),
  );
}

enum SwipeDirection { up, down, left, right }

class GameState {
  // this is the grid before the swipe has taken place
  final List<List<Tile>> _previousGrid;
  final SwipeDirection swipe;

  GameState(List<List<Tile>> previousGrid, this.swipe) : _previousGrid = previousGrid;

  // always make a copy so mutations don't screw things up.
  List<List<Tile>> get previousGrid => _previousGrid.map((row) => row.map((tile) => tile.copy()).toList()).toList();
}

class TwentyFortyEight extends StatefulWidget {
  const TwentyFortyEight({super.key});

  @override
  TwentyFortyEightState createState() => TwentyFortyEightState();
}

class TwentyFortyEightState extends State<TwentyFortyEight> with SingleTickerProviderStateMixin {
  late AnimationController controller;

  List<List<Tile>> grid = List.generate(4, (y) => List.generate(4, (x) => Tile(x, y, 0)));
  List<GameState> gameStates = [];
  List<Tile> toAdd = [];

  Iterable<Tile> get gridTiles => grid.expand((e) => e);
  Iterable<Tile> get allTiles => [gridTiles, toAdd].expand((e) => e);
  List<List<Tile>> get gridCols => List.generate(4, (x) => List.generate(4, (y) => grid[y][x]));

  late Timer aiTimer;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          for (var e in toAdd) {
            grid[e.y][e.x].value = e.value;
          }
          for (var t in gridTiles) {
            t.resetAnimations();
          }
          toAdd.clear();
        });
      }
    });

    setupNewGame();
  }

  @override
  Widget build(BuildContext context) {
    final contentPadding = 16.0;
    final borderSize = 4.0;
    final gridSize = MediaQuery.of(context).size.width - contentPadding * 2;
    final tileSize = (gridSize - borderSize * 2) / 4;

    final List<Widget> stackItems = [
      // fundo do tabuleiro
      ...gridTiles.map(
        (t) => TileWidget(x: tileSize * t.x, y: tileSize * t.y, containerSize: tileSize, size: tileSize - borderSize * 2, color: lightBrown),
      ),
      // tiles animados
      ...allTiles.map(
        (tile) => AnimatedBuilder(
          animation: controller,
          builder:
              (context, child) =>
                  tile.animatedValue.value == 0
                      ? const SizedBox()
                      : TileWidget(
                        x: tileSize * tile.animatedX.value,
                        y: tileSize * tile.animatedY.value,
                        containerSize: tileSize,
                        size: (tileSize - borderSize * 2) * tile.size.value,
                        color: numTileColor[tile.animatedValue.value] ?? lightBrown,
                        child: Center(child: TileNumber(tile.animatedValue.value)),
                      ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: tan,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- BOTÕES EM CIMA ---
              Row(
                children: [
                  // Expanded(child: BigButton(label: "Undo", color: numColor, onPressed: gameStates.isEmpty ? null : undoMove)),
                  const SizedBox(width: 12),
                  Expanded(child: BigButton(label: "Restart", color: orange, onPressed: setupNewGame)),
                ],
              ),
              const SizedBox(height: 12),

              // --- JOGO EMBAIXO ---
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Swiper(
                    up: () => merge(SwipeDirection.up),
                    down: () => merge(SwipeDirection.down),
                    left: () => merge(SwipeDirection.left),
                    right: () => merge(SwipeDirection.right),
                    child: Container(
                      height: gridSize, // quadrado fixo com base na largura
                      width: gridSize,
                      padding: EdgeInsets.all(borderSize),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(cornerRadius), color: darkBrown),
                      child: Stack(children: stackItems),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void undoMove() {
    GameState previousState = gameStates.removeLast();
    bool Function() mergeFn;
    switch (previousState.swipe) {
      case SwipeDirection.up:
        mergeFn = mergeUp;
        break;
      case SwipeDirection.down:
        mergeFn = mergeDown;
        break;
      case SwipeDirection.left:
        mergeFn = mergeLeft;
        break;
      case SwipeDirection.right:
        mergeFn = mergeRight;
        break;
    }
    setState(() {
      grid = previousState.previousGrid;
      mergeFn();
      controller.reverse(from: .99).then((_) {
        setState(() {
          grid = previousState.previousGrid;
          for (var t in gridTiles) {
            t.resetAnimations();
          }
        });
      });
    });
  }

  void merge(SwipeDirection direction) {
    bool Function() mergeFn;
    switch (direction) {
      case SwipeDirection.up:
        mergeFn = mergeUp;
        break;
      case SwipeDirection.down:
        mergeFn = mergeDown;
        break;
      case SwipeDirection.left:
        mergeFn = mergeLeft;
        break;
      case SwipeDirection.right:
        mergeFn = mergeRight;
        break;
    }
    List<List<Tile>> gridBeforeSwipe = grid.map((row) => row.map((tile) => tile.copy()).toList()).toList();
    setState(() {
      if (mergeFn()) {
        gameStates.add(GameState(gridBeforeSwipe, direction));
        addNewTiles([2]);
        controller.forward(from: 0);
      }
    });
  }

  bool mergeLeft() => grid.map((e) => mergeTiles(e)).toList().any((e) => e);

  bool mergeRight() => grid.map((e) => mergeTiles(e.reversed.toList())).toList().any((e) => e);

  bool mergeUp() => gridCols.map((e) => mergeTiles(e)).toList().any((e) => e);

  bool mergeDown() => gridCols.map((e) => mergeTiles(e.reversed.toList())).toList().any((e) => e);

  bool mergeTiles(List<Tile> tiles) {
    bool didChange = false;

    for (int i = 0; i < tiles.length; i++) {
      for (int j = i; j < tiles.length; j++) {
        if (tiles[j].value != 0) {
          // procura o próximo tile não-zero após j
          final nextIndex = tiles.indexWhere((t) => t.value != 0, j + 1);
          Tile? mergeTile = nextIndex == -1 ? null : tiles[nextIndex];

          // só faz merge se o próximo tiver o mesmo valor
          if (mergeTile != null && mergeTile.value != tiles[j].value) {
            mergeTile = null;
          }

          if (i != j || mergeTile != null) {
            didChange = true;

            int resultValue = tiles[j].value;
            tiles[j].moveTo(controller, tiles[i].x, tiles[i].y);

            if (mergeTile != null) {
              resultValue += mergeTile.value;
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

  void addNewTiles(List<int> values) {
    List<Tile> empty = gridTiles.where((t) => t.value == 0).toList();
    empty.shuffle();
    for (int i = 0; i < values.length; i++) {
      toAdd.add(Tile(empty[i].x, empty[i].y, values[i])..appear(controller));
    }
  }

  void setupNewGame() {
    setState(() {
      gameStates.clear();
      for (var t in gridTiles) {
        t.value = 0;
        t.resetAnimations();
      }
      toAdd.clear();
      addNewTiles([2, 2]);
      controller.forward(from: 0);
    });
  }
}
