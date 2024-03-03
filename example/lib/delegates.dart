part of 'main.dart';

class _FlowStackDelegates extends StatefulWidget {
  @override
  State<_FlowStackDelegates> createState() => _FlowStackDelegatesState();
}

class _FlowStackDelegatesState extends State<_FlowStackDelegates> with TickerProviderStateMixin {
  late final ctrl = AnimationController.unbounded(vsync: this, duration: const Duration(milliseconds: 750));
  final start = ValueNotifier(0);
  final pageController = PageController(initialPage: 1000000);
  double turns = 0;

  @override
  Widget build(BuildContext context) {
    final roundMenuDelegate = _RoundMenuDelegate(ctrl, start);
    final textDelegate = _TextDelegate(ctrl);
    final colors = [
      Colors.black, const Color(0xff00aa00), Colors.orange, const Color(0xffaa0000), const Color(0xff0000aa)
    ];
    final roundMenuData = [
      (id: 0, icon: Icons.apple, color: colors[0]),
      (id: 1, icon: Icons.android, color: colors[1]),
      (id: 2, icon: Icons.blur_on, color: colors[2]),
      (id: 3, icon: Icons.blur_circular, color: colors[3]),
      (id: 4, icon: Icons.blur_linear, color: colors[4]),
    ];
    return FlowStack(
      repaint: ctrl,
      children: [
        FlowStackEntry.filled(
          padding: EdgeInsets.zero,
          child: AnimatedBuilder(
            animation: ctrl,
            builder: (context, child) {
              final color0 = HSVColor.fromAHSV(1, 30 * ctrl.value % 360, 1, 0.7).toColor();
              final color1 = HSVColor.fromAHSV(1, 30 * ctrl.value % 360, 0.75, 0.2).toColor();
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color0, color1],
                    transform: GradientRotation(-pi * 0.25 * ctrl.value),
                  )
                ),
              );
            }
          ),
        ),
        ...FlowStackEntry.delegatedList(
          delegate: textDelegate,
          children: const [
            DecoratedBox(
              decoration: BoxDecoration(border: Border.symmetric(vertical: BorderSide(color: Colors.black45))),
              child: Text('press any icon to rotate them',
                textAlign: TextAlign.center,
                textScaler: TextScaler.linear(2),
                style: TextStyle(color: Colors.white38),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(border: Border.symmetric(vertical: BorderSide(color: Colors.black45))),
              child: Text('it will also rotate the background gradient',
                textAlign: TextAlign.center,
                textScaler: TextScaler.linear(0.9),
                style: TextStyle(color: Colors.white38),
              ),
            ),
            Material(
              shape: StarBorder(points: 4, innerRadiusRatio: 0.33),
              color: Colors.orange,
            ),
          ],
          ids: [_IDS.top, _IDS.bottom, _IDS.star],
        ),
        FlowStackEntry.delegated(
          delegate: textDelegate,
          id: _IDS.pageView,
          child: Container(
            decoration: const ShapeDecoration(
              shape: CircleBorder(),
              color: Colors.black26,
            ),
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.all(16),
            child: PageView.builder(
              controller: pageController,
              itemBuilder: (ctx, index) {
                final page = index % 5;
                final pageDelegate = _PageDelegate(index, pageController);
                final filter = ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.0);
                final icon = roundMenuData[page].icon;
                final pageChildren = [
                  ImageFiltered(imageFilter: filter, child: Icon(icon, color: Colors.white, size: 32)),
                  ImageFiltered(imageFilter: filter, child: Icon(icon, color: Colors.white54, size: 32)),
                  Icon(icon, color: colors[page], size: 32),
                ];
                return FittedBox(
                  // the "static" version:
                  // child: Stack(
                  //   children: pageChildren,
                  // ),
                  child: SizedBox.fromSize(
                    size: const Size.square(32),
                    child: FlowStack.fromDelegate(
                      repaint: pageController,
                      delegate: pageDelegate,
                      ids: const [0, 1, 2],
                      children: pageChildren,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        FlowStackEntry.aligned(
          alignment: Alignment.bottomCenter,
          offset: const Offset(0, 2),
          constraints: const BoxConstraints.tightFor(width: 200),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              color: Colors.black38,
              border: Border.all(width: 2, color: Colors.white24),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text('example of FlowStackEntry delegated entries', style: TextStyle(color: Colors.white70)),
            ),
          ),
        ),
        ...roundMenuData.map((e) => FlowStackEntry.delegated(
          delegate: roundMenuDelegate,
          id: e.id,
          child: DecoratedBox(
            decoration: const ShapeDecoration(
              gradient: RadialGradient(center: Alignment(-0.5, -0.5), colors: [Colors.white54, Colors.transparent]),
              shape: CircleBorder(
                side: BorderSide(width: 4, color: Colors.white12),
              ),
            ),
            child: IconButton(
              color: e.color,
              onPressed: () {
                start.value = e.id;
                final page = pageController.page!.round();
                int delta = (e.id - page) % 5;
                if (delta >= 3) delta -= 5;
                pageController.animateToPage(page + delta,
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.ease,
                );
                ctrl.animateTo(++turns);
              },
              icon: Icon(e.icon),
              iconSize: 48,
            ),
          )),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    ctrl.dispose();
    pageController.dispose();
  }
}

class _RoundMenuDelegate extends FlowStackLayoutDelegate {
  _RoundMenuDelegate(this.ctrl, this.start);

  final AnimationController ctrl;
  final ValueNotifier<int> start;

  static const N = 5;

  static const X = 8;
  final curves = List.generate(N, (i) => Interval(i / X, (X - N + 1 + i) / X, curve: Curves.easeOut));

  @override
  layout(Size size) {
    final maxWidth = Iterable.generate(N).fold(0.0, (acc, id) => max(acc, getChildSize(id).width));
    final rect = Alignment.center.inscribe(Size(size.height * 0.55, size.height), Offset.zero & size);
    final distance = (rect.shortestSide - maxWidth) / 2;
    for (int id = 0; id < N; id++) {
      final base = ctrl.value.floor();
      final fraction = ctrl.value - base;
      final a = 2 * pi * (base + curves[(id - start.value) % N].transform(fraction)) / N;
      final translate = rect.center +
        Offset.fromDirection(-pi / 2 + a + id * 2 * pi / N, distance) - getChildSize(id).center(Offset.zero);
      paintChildTranslated(id, translate);
    }
  }
}

enum _IDS {
  top, bottom, star, pageView,
}

class _TextDelegate extends FlowStackLayoutDelegate {
  _TextDelegate(this.ctrl);

  final AnimationController ctrl;

  @override
  layout(Size size) {
    final r = Offset.zero & size;

    final topSize = getChildSize(_IDS.top);
    final topRect = Alignment.center.inscribe(topSize, r);
    paintChildTranslated(_IDS.top, topRect.topLeft);

    final bottomSize = getChildSize(_IDS.bottom);
    final bottomRect = topRect.alignSize(bottomSize, Alignment.bottomCenter, Alignment.topCenter);
    paintChildTranslated(_IDS.bottom, bottomRect.topLeft);

    final pageViewSize = getChildSize(_IDS.pageView);
    final pageViewRect = bottomRect.alignSize(pageViewSize, Alignment.bottomCenter, Alignment.topCenter);
    final rotation = 0.2 * pi * sin(0.25 * pi * ctrl.value);
    paintChildComposedOf(_IDS.pageView,
      translate: pageViewRect.center,
      anchor: pageViewSize.center(Offset.zero),
      rotation: rotation,
    );

    final starSize = getChildSize(_IDS.star);
    final t = pow(sin(pi * ctrl.value * 0.25), 2).toDouble();
    final distance = pageViewSize.longestSide / 2;
    paintChildComposedOf(_IDS.star,
      translate: pageViewRect.center + Offset.fromDirection(-pi * ctrl.value + rotation, distance),
      anchor: starSize.center(Offset.zero),
      rotation: 2.123 * 2 * pi * ctrl.value,
      scale: lerpDouble(2.5, 1, t)!,
      opacity: lerpDouble(0.05, 0.5, t)!,
    );
  }

  @override
  BoxConstraints getConstraintsForChild(id, BoxConstraints constraints) => switch (id as _IDS) {
    _IDS.top => const BoxConstraints.tightFor(width: 200),
    _IDS.bottom => const BoxConstraints.tightFor(width: 125),
    _IDS.star => BoxConstraints.tight(const Size.square(16)),
    _IDS.pageView => BoxConstraints.tight(const Size.square(200)),
  };
}

class _PageDelegate extends FlowStackLayoutDelegate {
  _PageDelegate(this.index, this.pageController);

  final int index;
  final PageController pageController;

  @override
  layout(Size size) {
    final offset = Offset((index - pageController.page!) * size.width * 0.75, 0);
    paintChildTranslated(0, offset);      // bg shadow
    paintChildTranslated(1, offset);      // bg shadow
    paintChildTranslated(2, Offset.zero); // fg icon
  }
}
