// lib/features/game/pages/twenty_forty_eight.dart
import 'dart:async';
import 'package:combo_2048/core/helper/ads_helper.dart';
import 'package:flutter/material.dart';

import 'package:combo_2048/theme/app_theme.dart';
import 'package:combo_2048/theme/theme_controller.dart';
import 'package:combo_2048/tile.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class TwentyFortyEight extends StatefulWidget {
  final ThemeController themeController;
  const TwentyFortyEight({super.key, required this.themeController});

  @override
  TwentyFortyEightState createState() => TwentyFortyEightState();
}

class TwentyFortyEightState extends State<TwentyFortyEight> with SingleTickerProviderStateMixin {
  late AnimationController controller;

  List<List<Tile>> grid = List.generate(4, (y) => List.generate(4, (x) => Tile(x, y, 0)));
  final List<GameState> gameStates = [];
  final List<Tile> toAdd = [];

  Iterable<Tile> get gridTiles => grid.expand((e) => e);
  Iterable<Tile> get allTiles => [gridTiles, toAdd].expand((e) => e);
  List<List<Tile>> get gridCols => List.generate(4, (x) => List.generate(4, (y) => grid[y][x]));

  late Timer aiTimer; // (se quiser IA depois)

  // ---- ADS ----
  BannerAd? _mrec;
  bool _mrecLoaded = false;

  InterstitialAd? _interstitial;
  int _undosSinceAd = 0;

  void _loadMrec() {
    _mrec = BannerAd(
      adUnitId: AdIds.mrec,
      size: AdSize.mediumRectangle, // 300x250
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _mrecLoaded = true),
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          _mrecLoaded = false;
        },
      ),
    )..load();
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(onAdLoaded: (ad) => _interstitial = ad, onAdFailedToLoad: (err) => _interstitial = null),
    );
  }

  Future<void> _maybeShowUndoAd() async {
    _undosSinceAd++;
    if (_undosSinceAd % 3 != 0) return;

    if (_interstitial == null) _loadInterstitial();
    // dá um tempinho pro load (opcional). Se ainda for null, só ignora.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final ad = _interstitial;
    _interstitial = null; // consumir o ad atual

    if (ad != null) {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitial(); // pré-carrega o próximo
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _loadInterstitial();
        },
      );
      ad.show();
    } else {
      // tenta pré-carregar pro futuro
      _loadInterstitial();
    }
  }

  @override
  void initState() {
    super.initState();

    controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          for (final e in toAdd) {
            grid[e.y][e.x].value = e.value;
          }
          for (final t in gridTiles) {
            t.resetAnimations();
          }
          toAdd.clear();
        });
      }
    });

    _loadMrec();
    _loadInterstitial(); // pré-carrega o primeiro
    setupNewGame();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final game = Theme.of(context).extension<GameColors>()!;

    const contentPadding = 16.0;
    const borderSize = 4.0;
    final gridSize = MediaQuery.of(context).size.width - contentPadding * 2;
    final tileSize = (gridSize - borderSize * 2) / 4;

    final stackItems = <Widget>[
      // casas vazias do tabuleiro
      ...gridTiles.map(
        (t) => TileWidget(x: tileSize * t.x, y: tileSize * t.y, containerSize: tileSize, size: tileSize - borderSize * 2, color: game.tileEmpty),
      ),
      // tiles animados
      ...allTiles.map(
        (tile) => AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final v = tile.animatedValue.value;
            if (v == 0) return const SizedBox();
            return TileWidget(
              x: tileSize * tile.animatedX.value,
              y: tileSize * tile.animatedY.value,
              containerSize: tileSize,
              size: (tileSize - borderSize * 2) * tile.size.value,
              color: game.colorFor(v),
              child: Center(
                child: DefaultTextStyle(style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: game.textPrimary), child: TileNumber(v)),
              ),
            );
          },
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(onRestart: setupNewGame, onToggleTheme: widget.themeController.toggle, onUndo: undoMove, primary: scheme.primary),
              const SizedBox(height: 12),
              // Banner logo abaixo do botão Restart
              if (_mrecLoaded && _mrec != null)
                SizedBox(
                  height: _mrec!.size.height.toDouble(), // 250
                  width: _mrec!.size.width.toDouble(), // 300
                  child: AdWidget(ad: _mrec!),
                ),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.bottomCenter,
                child: Swiper(
                  up: () => merge(SwipeDirection.up),
                  down: () => merge(SwipeDirection.down),
                  left: () => merge(SwipeDirection.left),
                  right: () => merge(SwipeDirection.right),
                  child: Container(
                    height: gridSize,
                    width: gridSize,
                    padding: const EdgeInsets.all(borderSize),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: game.boardBg,
                      border: Border.all(color: game.boardBorder, width: 2),
                    ),
                    child: Stack(children: stackItems),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======== LÓGICA DO JOGO ========

  void setupNewGame() {
    setState(() {
      gameStates.clear();
      for (final t in gridTiles) {
        t.value = 0;
        t.resetAnimations();
      }
      toAdd.clear();
      addNewTiles([2, 2]); // duas peças iniciais
      controller.forward(from: 0);
    });
  }

  void addNewTiles(List<int> values) {
    final empty = gridTiles.where((t) => t.value == 0).toList()..shuffle();
    for (int i = 0; i < values.length && i < empty.length; i++) {
      toAdd.add(Tile(empty[i].x, empty[i].y, values[i])..appear(controller));
    }
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

    final gridBeforeSwipe = grid.map((row) => row.map((tile) => tile.copy()).toList()).toList();

    setState(() {
      if (mergeFn()) {
        gameStates.add(GameState(gridBeforeSwipe, direction));
        addNewTiles([2]); // nova peça após movimento válido
        controller.forward(from: 0);
      }
    });
  }

  bool mergeLeft() => grid.map((row) => mergeTiles(row)).toList().any((e) => e);

  bool mergeRight() => grid.map((row) => mergeTiles(row.reversed.toList())).toList().any((e) => e);

  bool mergeUp() => gridCols.map((col) => mergeTiles(col)).toList().any((e) => e);

  bool mergeDown() => gridCols.map((col) => mergeTiles(col.reversed.toList())).toList().any((e) => e);

  bool mergeTiles(List<Tile> tiles) {
    bool didChange = false;

    for (int i = 0; i < tiles.length; i++) {
      for (int j = i; j < tiles.length; j++) {
        if (tiles[j].value != 0) {
          final nextIndex = tiles.indexWhere((t) => t.value != 0, j + 1);
          Tile? mergeTile = nextIndex == -1 ? null : tiles[nextIndex];

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

  void undoMove() {
    if (gameStates.isEmpty) return;
    final previousState = gameStates.removeLast();
    _maybeShowUndoAd();

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
          for (final t in gridTiles) {
            t.resetAnimations();
          }
        });
      });
    });
  }
}

// ======== SUPORTES / MODELOS ========

enum SwipeDirection { up, down, left, right }

class GameState {
  final List<List<Tile>> _previousGrid;
  final SwipeDirection swipe;

  GameState(List<List<Tile>> previousGrid, this.swipe) : _previousGrid = previousGrid;

  List<List<Tile>> get previousGrid => _previousGrid.map((row) => row.map((tile) => tile.copy()).toList()).toList();
}

// ======== TOP BAR COMPONENTIZADA ========

class _TopBar extends StatelessWidget {
  final VoidCallback onRestart;
  final VoidCallback onToggleTheme;
  final VoidCallback onUndo;
  final Color primary;

  const _TopBar({required this.onRestart, required this.onToggleTheme, required this.onUndo, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 12),
        Expanded(child: BigButton(label: "Restart", color: primary, onPressed: onRestart)),
        const SizedBox(width: 8),
        IconButton.filledTonal(onPressed: onUndo, icon: const Icon(Icons.undo), tooltip: 'Voltar jogada'),
        const SizedBox(width: 8),
        IconButton.filledTonal(onPressed: onToggleTheme, icon: const Icon(Icons.palette), tooltip: 'Alternar tema'),
      ],
    );
  }
}
