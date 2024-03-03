part of 'main.dart';

class _FlowStackOverview extends StatefulWidget {
  @override
  State<_FlowStackOverview> createState() => _FlowStackOverviewState();
}

class _FlowStackOverviewState extends State<_FlowStackOverview> with TickerProviderStateMixin {
  late final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  late final ca = CurvedAnimation(parent: ctrl, curve: Curves.easeOutBack, reverseCurve: Curves.easeInBack);
  final countNotifier = ValueNotifier(-1);

  @override
  Widget build(BuildContext context) {
    return FlowStack(
      repaint: ctrl,
      children: [
        // label 0
        FlowStackEntry.filled(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 50),
          child: Badge(
            label: const Text('0'),
            child: SizedBox.expand(
              child: ColoredBox(
                color: Colors.grey.shade400,
                child: const Text('filled\nhorizontal: 25, vertical: 50'),
              ),
            ),
          ),
        ),

        ..._grid(false),

        // this one should really be simplified with "FlowStackEntry.at"
        // see the next entry (label 3) centered at 100, 200
        // label 1
        FlowStackEntry.fromCallbacks(
          paintCallback: translatedPaintCallback(const Offset(100, 100)),
          child: _FooCard(
            color: Colors.orange.shade400,
            label: '1',
            alignment: Alignment.topLeft,
            child: const Text('topLeft\n@100,100'),
          ),
        ),
        // label 2
        FlowStackEntry.animated(
          animation: ctrl,
          transform: _MoveAndTurn(const Offset(200, 200), const Offset(100, 100), countNotifier).call,
          child: _FooCard(
            color: Colors.blue.shade400,
            label: '2',
            alignment: Alignment.center,
            child: const Text('animated\n\nbottomLeft\n@200,200\nor\nbottomRight\n@100,100'),
          ),
        ),
        // label 3
        FlowStackEntry.at(
          offset: const Offset(100, 200),
          anchor: Alignment.center,
          child: _FooCard(
            color: Colors.green.shade400,
            label: '3',
            alignment: Alignment.center,
            child: const Text('at\ncenter\n@100,200'),
          ),
        ),
        // label 4
        FlowStackEntry.at(
          offset: const Offset(300, 200),
          anchor: Alignment.centerRight,
          child: _FooCard(
            color: Colors.yellow.shade400,
            label: '4',
            alignment: Alignment.centerRight,
            child: const Text('at\ncenterRight\n@300,200'),
          ),
        ),

        FlowStackEntry.fromCallbacks(
          paintCallback: alignedPaintCallback(Alignment.center),
          constraintsCallback: (c) => BoxConstraints.tightFor(width: c.maxWidth * 0.65),
          child: Badge(
            label: const Text('A'),
            child: ElevatedButton(
              onPressed: () {
                ctrl.value < 0.5? ctrl.forward() : ctrl.reverse();
                countNotifier.value++;
              },
              child: const Text('center aligned button, click to animate', textScaler: TextScaler.linear(1.75)),
            ),
          ),
        ),

        // note that SizedBox can be removed and constraints: ... can be used instead
        // label 5
        FlowStackEntry.at(
          offset: const Offset(100, 400),
          anchor: Alignment.topCenter,
          child: SizedBox(
            width: 80,
            child: _FooCard(
              color: Colors.red.shade400,
              label: '5',
              alignment: Alignment.topCenter,
              child: const SizedBox(width: double.infinity, child: Text('at\ntopCenter\n@100,400')),
            ),
          ),
        ),
        // instead of additional SizedBox we use constraints: ...
        // label 6
        FlowStackEntry.at(
          offset: const Offset(200, 400),
          anchor: Alignment.centerLeft,
          constraints: const BoxConstraints.tightFor(width: 80),
          child: _FooCard(
            color: Colors.deepPurple.shade400,
            label: '6',
            alignment: Alignment.centerLeft,
            child: const SizedBox(width: double.infinity, child: Text('at\ncenterLeft\n@200,400')),
          ),
        ),
        // label 7
        FlowStackEntry.tight(
          rect: const Rect.fromLTWH(200, 450, 100, 100),
          child: _FooCard(
            color: Colors.blueGrey.shade400,
            label: '7',
            alignment: Alignment.center,
            child: const SizedBox.expand(child: Text('tight\n@200,450,100,100')),
          ),
        ),

        // label 8
        FlowStackEntry.aligned(
          alignment: Alignment.bottomCenter,
          child: _FooCard(
            color: Colors.brown.shade300,
            label: '8',
            alignment: Alignment.bottomCenter,
            child: const Text('aligned\nbottomCenter'),
          ),
        ),

        // label 9
        FlowStackEntry.animated(
          animation: ca,
          transform: _moveWifiIconTransform,
          child: AnimatedBuilder(
            animation: ctrl,
            builder: (context, child) {
              final color = Color.lerp(Colors.indigo, Colors.orange, ctrl.value)!;
              return Badge(
                label: const Text('9'),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black45),
                  ),
                  child: Icon(Icons.wifi, size: 100, color: color),
                ),
              );
            }
          ),
        ),

        ..._grid(true),

      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    ctrl.dispose();
  }

  Iterable<FlowStackEntry> _grid(bool showLabels) sync* {
    const offsets = [
      Offset(100, 0), Offset(200, 0), Offset(300, 0),
      Offset(0, 100), Offset(0, 200), Offset(0, 400), Offset(0, 450), Offset(0, 550),
    ];
    for (final o in offsets) {
      if (showLabels) {
        final borderRadius = o.dx == 0?
          const BorderRadius.horizontal(right: Radius.circular(12)) :
          const BorderRadius.vertical(bottom: Radius.circular(12));
        yield FlowStackEntry.fromCallbacks(
          paintCallback: translatedPaintCallback(o, anchor: o.dx == 0? Alignment.centerLeft : Alignment.topCenter),
          child: Container(
            padding: o.dx == 0?
              const EdgeInsets.only(right: 6, top: 3, bottom: 3) :
              const EdgeInsets.only(left: 6, right: 6, bottom: 3),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(color: Colors.black38),
              color: Colors.yellow.shade200,
              boxShadow: kElevationToShadow[4],
            ),
            child: Text(o.distance.toInt().toString()),
          ),
        );
      } else {
        yield FlowStackEntry.at(
          offset: o,
          child: o.dx == 0?
            const Divider(height: 0, color: Colors.black38) :
            const VerticalDivider(width: 0, color: Colors.black38),
        );
      }
    }
  }

  Matrix4 _moveWifiIconTransform(Animation<double> animation, Size childSize, Rect parentRect) {
    final a = Alignment.lerp(const Alignment(-1, 0.25), Alignment.bottomRight, animation.value)!;
    return FlowPaintingContextExtension.composeMatrix(
      anchor: childSize.center(Offset.zero),
      translate: a.inscribe(childSize, parentRect).center,
      rotation: lerpDouble(-pi / 6, pi / 2, ctrl.value)!,
    );
  }
}

class _MoveAndTurn {
  _MoveAndTurn(this.begin, this.end, this.countNotifier) : angle = (begin - end).direction;

  final Offset begin;
  final Offset end;
  final ValueNotifier<int> countNotifier;
  final double angle;

  Matrix4 call(Animation<double> animation, Size childSize, Rect parentRect) {
    final t = Curves.easeInOut.transform(animation.value);
    final o = Offset.lerp(begin, end, t)!;
    final a = Alignment.lerp(Alignment.bottomLeft, Alignment.bottomRight, t)!;

    if ((countNotifier.value ~/ 3).isEven) {
      return FlowPaintingContextExtension.composeMatrix(
        translate: o,
        anchor: a.alongSize(childSize),
        rotation: angle * sin(pi * t),
      );
    } else {
      // timeDilation = 10;
      final m = MatrixUtils.createCylindricalProjectionTransform(
        perspective: 0.015,
        orientation: Axis.horizontal,
        radius: 15,
        angle: 0.35 * sin(2 * pi * t),
      );
      final anchor = Alignment.lerp(Alignment.centerLeft, Alignment.centerRight, t)!.alongSize(childSize);
      return Matrix4.translationValues(anchor.dx, anchor.dy, 0) *
        FlowPaintingContextExtension.composeMatrix(
          translate: o,
          anchor: a.alongSize(childSize),
          scale: 1 + 0.5 * sin(pi * t),
        ) * m * Matrix4.translationValues(-anchor.dx, -anchor.dy, 0);
    }
  }
}

class _FooCard extends StatefulWidget {
  const _FooCard({
    required this.color,
    required this.label,
    required this.alignment,
    required this.child,
  });

  final Color color;
  final String label;
  final Alignment alignment;
  final Widget child;

  @override
  State<_FooCard> createState() => _FooCardState();
}

class _FooCardState extends State<_FooCard> with SingleTickerProviderStateMixin {
  late final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (d) => ctrl.animateTo(1, curve: Curves.easeOutBack),
      onTapUp: (d) => ctrl.animateTo(0, curve: Curves.easeOutBack),
      onTapCancel: () => ctrl.animateTo(0, curve: Curves.easeOutBack),
      child: ScaleTransition(
        scale: Animation.fromValueListenable(ctrl,
          transformer: (v) => lerpDouble(1, 2.5, v)!,
        ),
        alignment: widget.alignment,
        child: Badge(
          label: Text(widget.label),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: Colors.black38),
              color: widget.color,
              boxShadow: kElevationToShadow[3],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
