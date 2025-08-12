import 'package:combo_2048/theme/grid-peoperties.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Tile {
  final int x;
  final int y;

  int value;

  late Animation<double> animatedX;
  late Animation<double> animatedY;
  late Animation<double> size;

  late Animation<int> animatedValue;

  Tile(this.x, this.y, this.value) {
    resetAnimations();
  }

  void resetAnimations() {
    animatedX = AlwaysStoppedAnimation(x.toDouble());
    animatedY = AlwaysStoppedAnimation(y.toDouble());
    size = AlwaysStoppedAnimation(1.0);
    animatedValue = AlwaysStoppedAnimation(value);
  }

  void moveTo(Animation<double> parent, int x, int y) {
    Animation<double> curved = CurvedAnimation(parent: parent, curve: Interval(0.0, moveInterval));
    animatedX = Tween(begin: this.x.toDouble(), end: x.toDouble()).animate(curved);
    animatedY = Tween(begin: this.y.toDouble(), end: y.toDouble()).animate(curved);
  }

  void bounce(Animation<double> parent) {
    size = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1.0),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1.0),
    ]).animate(CurvedAnimation(parent: parent, curve: Interval(moveInterval, 1.0)));
  }

  void changeNumber(Animation<double> parent, int newValue) {
    animatedValue = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(value), weight: .01),
      TweenSequenceItem(tween: ConstantTween(newValue), weight: .99),
    ]).animate(CurvedAnimation(parent: parent, curve: Interval(moveInterval, 1.0)));
  }

  void appear(Animation<double> parent) {
    size = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: parent, curve: Interval(moveInterval, 1.0)));
  }

  Tile copy() {
    Tile t = Tile(x, y, value);
    t.resetAnimations();
    return t;
  }
}

class TileWidget extends StatelessWidget {
  final double x;
  final double y;
  final double containerSize;
  final double size;
  final Color color;
  final Widget? child; // aqui pode ser null

  const TileWidget({super.key, required this.x, required this.y, required this.containerSize, required this.size, required this.color, this.child});

  @override
  Widget build(BuildContext context) => Positioned(
    left: x,
    top: y,
    child: SizedBox(
      width: containerSize,
      height: containerSize,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(cornerRadius), color: color),
          child: child,
        ),
      ),
    ),
  );
}

class TileNumber extends StatelessWidget {
  final int val;

  const TileNumber(this.val, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text("$val", style: TextStyle(color: numTextColor[val], fontSize: val > 512 ? 28 : 35, fontWeight: FontWeight.w900));
}

class BigButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const BigButton({super.key, required this.label, required this.color, this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 80,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cornerRadius)),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700)),
    ),
  );
}

class Swiper extends StatelessWidget {
  final VoidCallback? up;
  final VoidCallback? down;
  final VoidCallback? left;
  final VoidCallback? right;
  final Widget child;

  const Swiper({super.key, this.up, this.down, this.left, this.right, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onVerticalDragEnd: (details) {
      final dy = details.velocity.pixelsPerSecond.dy;
      if (dy < -250) {
        up?.call();
      } else if (dy > 250) {
        down?.call();
      }
    },
    onHorizontalDragEnd: (details) {
      final dx = details.velocity.pixelsPerSecond.dx;
      if (dx < -1000) {
        left?.call();
      } else if (dx > 1000) {
        right?.call();
      }
    },
    child: child,
  );
}
