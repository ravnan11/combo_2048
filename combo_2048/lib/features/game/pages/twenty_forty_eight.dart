// lib/features/game/pages/twenty_forty_eight.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:combo_2048/core/helper/ads_helper.dart';
import 'package:combo_2048/features/game/widgets/top_bar.dart';
import 'package:combo_2048/features/logic/game_logic.dart';
import 'package:combo_2048/theme/app_theme.dart';
import 'package:combo_2048/theme/theme_controller.dart';
import 'package:combo_2048/tile.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class TwentyFortyEight extends StatefulWidget {
  final ThemeController themeController;
  const TwentyFortyEight({super.key, required this.themeController});

  @override
  TwentyFortyEightState createState() => TwentyFortyEightState();
}

class TwentyFortyEightState extends State<TwentyFortyEight> with SingleTickerProviderStateMixin, MergeLogic<TwentyFortyEight> {
  // ---------- engine (MergeLogic) requer estes membros ----------
  @override
  late AnimationController controller;

  @override
  List<List<Tile>> grid = List.generate(4, (y) => List.generate(4, (x) => Tile(x, y, 0)));

  final List<GameState> gameStates = [];
  final List<Tile> toAdd = [];

  @override
  Iterable<Tile> get gridTiles => grid.expand((e) => e);

  @override
  List<List<Tile>> get gridCols => List.generate(4, (x) => List.generate(4, (y) => grid[y][x]));

  @override
  void onMerged(int mergedValue) {
    _pendingScore += mergedValue;
  }

  // ---------- resto ----------
  late Timer aiTimer; // (se quiser IA depois)
  final math.Random _rng = math.Random();

  // Score
  int _score = 0;
  int _pendingScore = 0; // pontos do movimento corrente

  // ADS
  BannerAd? _mrec;
  bool _mrecLoaded = false;

  InterstitialAd? _interstitial;
  int _undosSinceAd = 0;

  // Spawns (clássico 2048): 90% sai 2, 10% sai 4
  int _spawnValue() => _rng.nextDouble() < 0.9 ? 2 : 4;

  // ---- Ads ----
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
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final ad = _interstitial;
    _interstitial = null;

    if (ad != null) {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitial();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _loadInterstitial();
        },
      );
      ad.show();
    } else {
      _loadInterstitial();
    }
  }

  // ---- ciclo de vida ----
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
    _loadInterstitial();
    setupNewGame();
  }

  @override
  void dispose() {
    controller.dispose();
    _mrec?.dispose();
    _interstitial?.dispose();
    super.dispose();
  }

  bool _canShowMrec(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // exige largura mínima para caber 300dp sem cortar e uma altura decente
    return size.width >= 320 && size.height >= 640 && _mrecLoaded && _mrec != null;
  }

  // ---- UI ----
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final game = Theme.of(context).extension<GameColors>()!;

    // padding levemente adaptativo: reduz em telas bem estreitas
    final screenW = MediaQuery.of(context).size.width;
    final contentPadding = screenW < 360 ? 12.0 : 16.0;
    const borderSize = 4.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TopBar(
                onRestart: setupNewGame,
                onToggleTheme: widget.themeController.toggle,
                onUndo: undoMove,
                onHelp: () => _showHowItWorks(context),
                primary: scheme.primary,
                score: _score,
              ),
              const SizedBox(height: 12),

              // MREC responsivo: só exibe se couber
              if (_canShowMrec(context))
                Center(
                  child: SizedBox(
                    height: _mrec!.size.height.toDouble(), // 250
                    width: _mrec!.size.width.toDouble(), // 300
                    child: AdWidget(ad: _mrec!),
                  ),
                ),
              if (_canShowMrec(context)) const SizedBox(height: 12),

              // --- Área do tabuleiro: sempre quadrado e ajustado ao espaço restante ---
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // calcula o lado do quadrado com base no espaço DISPONÍVEL
                    final side = math.min(constraints.maxWidth, constraints.maxHeight);

                    return Center(
                      child: SizedBox(
                        width: side,
                        height: side,
                        child: _Board(
                          side: side,
                          borderSize: borderSize,
                          game: game,
                          controller: controller,
                          gridTiles: gridTiles,
                          allTiles: [gridTiles, toAdd].expand((e) => e),
                          onSwipeUp: () => merge(SwipeDirection.up),
                          onSwipeDown: () => merge(SwipeDirection.down),
                          onSwipeLeft: () => merge(SwipeDirection.left),
                          onSwipeRight: () => merge(SwipeDirection.right),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======== LÓGICA do fluxo (spawns/undo/score) ========

  void setupNewGame() {
    setState(() {
      _score = 0;
      gameStates.clear();
      for (final t in gridTiles) {
        t.value = 0;
        t.resetAnimations();
      }
      toAdd.clear();
      addNewTiles([_spawnValue(), _spawnValue()]);
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
      _pendingScore = 0; // zera pontos do movimento
      if (mergeFn()) {
        _score += _pendingScore; // aplica pontos acumulados
        gameStates.add(GameState(gridBeforeSwipe, direction));
        addNewTiles([_spawnValue()]);
        controller.forward(from: 0);
      }
    });
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

  // ======== UI: Tutorial “Como funciona” (scrollável) ========

  void _showHowItWorks(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.85;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return ConstrainedBox(constraints: BoxConstraints(maxHeight: maxH), child: const _HowItWorksSheet());
      },
    );
  }
}

// ----------------- Board isolado (usa o 'side' calculado) -----------------

class _Board extends StatelessWidget {
  final double side;
  final double borderSize;
  final GameColors game;
  final AnimationController controller;
  final Iterable<Tile> gridTiles;
  final Iterable<Tile> allTiles;
  final VoidCallback onSwipeUp;
  final VoidCallback onSwipeDown;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const _Board({
    required this.side,
    required this.borderSize,
    required this.game,
    required this.controller,
    required this.gridTiles,
    required this.allTiles,
    required this.onSwipeUp,
    required this.onSwipeDown,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  Widget build(BuildContext context) {
    final tileSize = (side - borderSize * 2) / 4;

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

    return Swiper(
      up: onSwipeUp,
      down: onSwipeDown,
      left: onSwipeLeft,
      right: onSwipeRight,
      child: Container(
        height: side,
        width: side,
        padding: EdgeInsets.all(borderSize),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: game.boardBg,
          border: Border.all(color: game.boardBorder, width: 2),
        ),
        child: Stack(children: stackItems),
      ),
    );
  }
}

// ======== Sheet: Como funciona (Regra clássica) ========

class _HowItWorksSheet extends StatelessWidget {
  const _HowItWorksSheet();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Como funciona', style: text.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Deslize para mover os tiles. Quando dois tiles de MESMO número se encontram, '
            'eles se fundem e viram a soma.\nEx.: 2 + 2 = 4, 4 + 4 = 8, 8 + 8 = 16...',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text('Exemplos', style: text.titleMedium),
          const SizedBox(height: 8),
          const _ExampleRow(examples: ['2 + 2 = 4', '4 + 4 = 8', '8 + 8 = 16']),
          const SizedBox(height: 12),
          Text('Não funde', style: text.titleMedium),
          const SizedBox(height: 8),
          const _ExampleRow(examples: ['2 + 4 ✗', '4 + 8 ✗', '8 + 16 ✗']),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Text(
              'Após cada movimento válido nasce um novo tile (normalmente 2, às vezes 4).\n'
              'Pontuação: cada fusão soma o valor do tile resultante ao seu Score.',
              style: text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  final List<String> examples;
  const _ExampleRow({required this.examples});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          examples
              .map(
                (e) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Text(e),
                ),
              )
              .toList(),
    );
  }
}
