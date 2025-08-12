import 'dart:async';
import 'dart:math' as math;

import 'package:combo_2048/core/helper/ads_helper.dart';
import 'package:combo_2048/features/game/widgets/chaos_types.dart';
import 'package:combo_2048/features/game/widgets/how_it_works_sheet.dart';
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

  // Spawns (clássico): 90% sai 2, 10% sai 4
  int _spawnValue() => _rng.nextDouble() < 0.9 ? 2 : 4;

  // ---------------- MODO CAOS ----------------
  int _validSwipes = 0;
  ChaosState? _activeChaos;

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
    return size.width >= 320 && size.height >= 640 && _mrecLoaded && _mrec != null;
  }

  // ---- UI ----
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final game = Theme.of(context).extension<GameColors>()!;

    final screenW = MediaQuery.of(context).size.width;
    final contentPadding = screenW < 360 ? 12.0 : 16.0;

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
                chaosLabel: chaosLabel(_activeChaos),
                chaosMovesLeft: _activeChaos?.movesLeft,
              ),
              const SizedBox(height: 12),

              if (_canShowMrec(context))
                Center(
                  child: SizedBox(
                    height: _mrec!.size.height.toDouble(), // 250
                    width: _mrec!.size.width.toDouble(), // 300
                    child: AdWidget(ad: _mrec!),
                  ),
                ),
              if (_canShowMrec(context)) const SizedBox(height: 12),

              // Tabuleiro responsivo (lado = min(largura, altura disponível))
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const borderSize = 4.0;
                    final side = math.min(constraints.maxWidth, constraints.maxHeight);
                    final tileSize = (side - borderSize * 2) / 4;

                    final stackItems = <Widget>[
                      ...gridTiles.map(
                        (t) => TileWidget(
                          x: tileSize * t.x,
                          y: tileSize * t.y,
                          containerSize: tileSize,
                          size: tileSize - borderSize * 2,
                          color: game.tileEmpty,
                        ),
                      ),
                      ...[gridTiles, toAdd]
                          .expand((e) => e)
                          .map(
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
                                    child: DefaultTextStyle(
                                      style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: game.textPrimary),
                                      child: TileNumber(v),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                    ];

                    return Center(
                      child: SizedBox(
                        width: side,
                        height: side,
                        child: Swiper(
                          up: () => merge(SwipeDirection.up),
                          down: () => merge(SwipeDirection.down),
                          left: () => merge(SwipeDirection.left),
                          right: () => merge(SwipeDirection.right),
                          child: Container(
                            height: side,
                            width: side,
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

  // ======== Fluxo do jogo (spawns/undo/score + CAOS) ========

  void setupNewGame() {
    setState(() {
      _score = 0;
      _validSwipes = 0;
      _activeChaos = null;

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

  void _maybeActivateChaos() {
    if (_activeChaos != null) return;
    _validSwipes++;
    if (_validSwipes < 10) return;

    _validSwipes = 0;
    final next = drawChaos(_rng);
    // efeitos instantâneos: embaralha e consome
    if (applyInstantChaosIfAny(state: next, tiles: gridTiles, rng: _rng, onAfterApply: () => controller.forward(from: 0))) {
      setState(() {}); // atualiza UI (p.ex. score) se necessário
      return;
    }
    _activeChaos = next;
    setState(() {});
  }

  void _tickChaos() {
    final c = _activeChaos;
    if (c == null) return;
    if (c.type == ChaosType.shuffleOnce) return; // já consumido
    c.movesLeft--;
    if (c.movesLeft <= 0) _activeChaos = null;
  }

  void merge(SwipeDirection direction) {
    // aplica caos de controle invertido
    final dir = maybeMirror(direction, _activeChaos);

    bool Function() mergeFn;
    switch (dir) {
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
      _pendingScore = 0;

      if (mergeFn()) {
        _score += _pendingScore;
        gameStates.add(GameState(gridBeforeSwipe, direction));

        _maybeActivateChaos();
        _tickChaos();

        addNewTiles(spawnForThisMove(_activeChaos, _spawnValue));
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

  // ======== UI: Tutorial (usa widget separado) ========

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
        return ConstrainedBox(constraints: BoxConstraints(maxHeight: maxH), child: const HowItWorksSheet());
      },
    );
  }
}
