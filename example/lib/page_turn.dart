part of 'main.dart';

class _FlowStackPageTurn extends StatefulWidget {
  @override
  State<_FlowStackPageTurn> createState() => _FlowStackPageTurnState();
}

class _FlowStackPageTurnState extends State<_FlowStackPageTurn> with TickerProviderStateMixin {
  static final months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December',
  ];
  final r = Random();
  late final cards = List.generate(months.length, (index) {
    final controller = AnimationController(vsync: this, duration: Durations.extralong4);
    return (
      color: HSVColor.fromAHSV(1, 360 * r.nextDouble(), lerpDouble(0.66, 1, r.nextDouble())!, 1).toColor(),
      label: months[months.length - 1 - index],
      controller: controller,
      curvedAnimation: CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
      offset: Offset.lerp(const Offset(-50, 0), const Offset(50, -50), r.nextDouble())!,
      angle: lerpDouble(-0.4, 0.4, r.nextDouble())!,
    );
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return FlowStack(
      repaint: Listenable.merge(cards.map((card) => card.controller).toList()),
      children: [
        FlowStackEntry.aligned(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('click furiously fast on the bottom part of the pages to see a stream of multiple pages turning to the top', style: theme.headlineSmall),
          ),
        ),
        for (final card in cards)
          FlowStackEntry.animated(
            animation: card.controller,
            transform: (animation, childSize, parentRect) {
              final m0 = FlowPaintingContextExtension.composeMatrix(
                translate: parentRect.center + card.offset * card.curvedAnimation.value,
                rotation: card.angle * card.curvedAnimation.value,
              );
              final proj = MatrixUtils.createCylindricalProjectionTransform(
                perspective: 0.0015,
                orientation: Axis.vertical,
                radius: (animation.status == AnimationStatus.forward? 100 : -75) * sin(2 * pi * card.curvedAnimation.value),
                angle: pi * card.curvedAnimation.value,
              );
              final m1 = FlowPaintingContextExtension.composeMatrix(
                translate: -childSize.topCenter(Offset.zero),
              );
              return m0 * proj * m1;
            },
            child: SizedBox.fromSize(
              key: ValueKey(card),
              size: const Size(150, 250),
              child: Card(
                color: card.color,
                child: InkWell(
                  splashColor: Colors.black26,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    final controller = card.controller;
                    if (controller.isAnimating) return;
                    cards
                      ..remove(card)
                      ..add(card);
                    controller.value < 0.5? controller.forward() : controller.reverse();
                    setState(() {});
                  },
                  child: Stack(
                    children: [
                      Center(child: Text(card.label, style: theme.headlineSmall)),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white60,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(8))
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          child: const Text('turn page')
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
      ],
    );
  }

  @override
  void dispose() {
    for (final card in cards) {
      card
        ..controller.dispose()
        ..curvedAnimation.dispose();
    }
    super.dispose();
  }
}
