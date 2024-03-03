import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'flow_painting_context_extension.dart';

/// Signature for [FlowStackEntry.paintCallback]
///
/// [pctx] is used for calling one of 'paintChild*' method on [i]th child:
///  - [FlowPaintingContext.paintChild]
///  - [FlowPaintingContextExtension.paintChildTranslated]
///  - [FlowPaintingContextExtension.paintChildComposedOf]
///  - [FlowPaintingContextExtension.paintChildInRect]
///
/// Two additional parameters are passed for convenience (both obtained from [pctx]):
///  - [size] - [i]th child size
///  - [rect] - parent's bounding rect
typedef PaintCallback = void Function(int i, FlowPaintingContext pctx, Size size, Rect rect);

class FlowStack extends StatelessWidget {
  const FlowStack({
    super.key,
    this.repaint,
    this.children = const [],
    this.clipBehavior = Clip.hardEdge,
    this.wrapped = true,
  });

  FlowStack.fromDelegates({
    Key? key,
    Listenable? repaint,
    required Iterable<({
      FlowStackLayoutDelegate delegate,
      Iterable<dynamic> ids,
      Iterable<Widget> children,
    })> delegates,
    Clip clipBehavior = Clip.hardEdge,
    bool wrapped = true,
  }) : this(
    key: key,
    repaint: repaint,
    children: [
      ...delegates.expand((record) =>
        FlowStackEntry.delegatedList(
          delegate: record.delegate,
          children: record.children,
          ids: record.ids,
        ),
      ),
    ],
    clipBehavior: clipBehavior,
    wrapped: wrapped,
  );

  FlowStack.fromDelegate({
    Key? key,
    Listenable? repaint,
    required FlowStackLayoutDelegate delegate,
    required Iterable<dynamic> ids,
    required Iterable<Widget> children,
    Clip clipBehavior = Clip.hardEdge,
    bool wrapped = true,
  }) : this(
    key: key,
    repaint: repaint,
    children: FlowStackEntry.delegatedList(
      delegate: delegate,
      children: children,
      ids: ids,
    ),
    clipBehavior: clipBehavior,
    wrapped: wrapped,
  );

  final Listenable? repaint;
  final Clip clipBehavior;
  final List<FlowStackEntry> children;
  final bool wrapped;

  @override
  Widget build(BuildContext context) {
    final children_ = children.map((e) => e.child).toList();
    final delegate = _FlowStackDelegate(
      entries: children,
      repaint: repaint,
    );
    return wrapped?
      Flow(
        delegate: delegate,
        clipBehavior: clipBehavior,
        children: children_,
      ) :
      Flow.unwrapped(
        delegate: delegate,
        clipBehavior: clipBehavior,
        children: children_,
      );
  }
}

/// helper paint callbacks that can be used with generic [FlowStackEntry.fromCallbacks] constructor.

PaintCallback alignedPaintCallback(Alignment alignment, {
  Offset? offset,
  Offset? fractionalOffset,
}) {
  return (i, pctx, size, rect) {
    Offset translate = alignment.inscribe(size, rect).topLeft;
    if (offset != null) translate += offset;
    if (fractionalOffset != null) translate += fractionalOffset.scale(size.width, size.height);
    pctx.paintChildTranslated(i, translate);
  };
}

PaintCallback translatedPaintCallback(Offset o, {Alignment anchor = Alignment.topLeft}) {
  return (i, pctx, size, rect) => pctx.paintChildTranslated(i, o - anchor.alongSize(size));
}

class FlowStackEntry {
  /// The generic constructor, [paintCallback] is responsible for calling one of:
  ///  - [FlowPaintingContext.paintChild]
  ///  - [FlowPaintingContextExtension.paintChildTranslated]
  ///  - [FlowPaintingContextExtension.paintChildComposedOf]
  /// Optional [constraintsCallback] provides [BoxConstraints] used for [child]
  /// sizing.
  ///
  /// For simple cases where all layout data is static you can use:
  ///  - [FlowStackEntry.at]
  ///  - [FlowStackEntry.tight]
  ///  - [FlowStackEntry.aligned]
  ///  - [FlowStackEntry.filled]
  ///  - [FlowStackEntry.follower]
  FlowStackEntry.fromCallbacks({
    required this.paintCallback,
    this.constraintsCallback,
    required this.child,
  });

  /// Sets [child] at given [offset], by default [child]'s top-left corner is
  /// aligned to [offset], this can changed with optional [anchor] parameter.
  ///
  /// Optional [constraints] can be set to specify [BoxConstraints] used for [child]
  /// sizing.
  FlowStackEntry.at({
    required Offset offset,
    BoxConstraints? constraints,
    Alignment anchor = Alignment.topLeft,
    required this.child,
  }) : paintCallback = translatedPaintCallback(offset, anchor: anchor),
       constraintsCallback = (constraints != null? (c) => constraints : null);

  /// Sets [child] at given [rect].
  FlowStackEntry.tight({
    required Rect rect,
    required Widget child,
  }) : this.at(
    offset: rect.topLeft,
    constraints: BoxConstraints.tight(rect.size),
    child: child,
  );

  /// Aligns [child] within parent's size by given [alignment], the final position
  /// can be adjusted with optional [offset] / [fractionalOffset] that moves [child]
  /// by additional (offset.dx, offset.dy) and
  /// (fractionalOffset.dx * childSize.width, fractionalOffset.dy * childSize.height)
  /// pixels respectively. Note that [fractionalOffset] is expressed as [Offset]
  /// scaled to the [child]'s size. For example, 'fractionalOffset: Offset(1, 0)' will move
  /// [child] by (childSize.width, 0) pixels.
  ///
  /// Optional [constraints] can be set to specify [BoxConstraints] used for [child]
  /// sizing.
  FlowStackEntry.aligned({
    required Alignment alignment,
    BoxConstraints? constraints,
    Offset? offset,
    Offset? fractionalOffset,
    required this.child,
  }) : paintCallback = alignedPaintCallback(alignment, offset: offset, fractionalOffset: fractionalOffset),
       constraintsCallback = (constraints != null? (c) => constraints : null);

  /// Fills [child] by deflating parent's size with given [padding].
  FlowStackEntry.filled({
    required EdgeInsets padding,
    required this.child,
  }) : paintCallback = ((i, pctx, size, rect) => pctx.paintChildTranslated(i, padding.topLeft)),
       constraintsCallback = ((c) => BoxConstraints.tight(padding.deflateSize(c.biggest)).enforce(c));

  /// Animates [child] based on [animation] and [transform] callback.
  /// Note that [animation] has to be passed to [FlowStack.repaint] - otherwise no
  /// animation will happen.
  ///
  /// If you want to change opacity during the animation use generic
  /// [FlowStackEntry.fromCallbacks] constructor.
  FlowStackEntry.animated({
    required Animation<double> animation,
    required Matrix4 Function(Animation<double>, Size, Rect) transform,
    required this.child,
  }) : paintCallback = ((i, pctx, size, rect) => pctx.paintChild(i,
         transform: transform(animation, size, rect)
       )),
       constraintsCallback = null;

  /// Follows [CompositedTransformTarget] with given [link].
  /// Optional parameters: [offset], [targetAnchor] and [followerAnchor] are
  /// directly passed to [CompositedTransformFollower].
  /// Note that followed [CompositedTransformTarget] must be specified in
  /// [FlowStackEntry] that is painted before this one.
  ///
  /// Optional [constraints] can be set to specify [BoxConstraints] used for [child]
  /// sizing.
  FlowStackEntry.follower({
    required LayerLink link,
    Offset offset = Offset.zero,
    Alignment targetAnchor = Alignment.topLeft,
    Alignment followerAnchor = Alignment.topLeft,
    BoxConstraints? constraints,
    required Widget child,
  }) : child = CompositedTransformFollower(
         link: link,
         offset: offset,
         targetAnchor: targetAnchor,
         followerAnchor: followerAnchor,
         child: child,
       ),
       paintCallback = translatedPaintCallback(Offset.zero),
       constraintsCallback = (constraints != null? (c) => constraints : null);

  /// Delegates sizing / painting the [child] to given [delegate].
  /// [delegate] should use [id] when calling [FlowStackLayoutDelegate.getChildSize],
  /// [FlowStackLayoutDelegate.paintChildTranslated] and [FlowStackLayoutDelegate.paintChildComposedOf].

  FlowStackEntry.delegated({
    required FlowStackLayoutDelegate delegate,
    required dynamic id,
    required this.child,
  }) : paintCallback = delegate._paintCallback,
       constraintsCallback = ((BoxConstraints c) => delegate.getConstraintsForChild(id, c)),
       delegateContext = (delegate: delegate, id: id);

  /// A helper method to group multiple [FlowStackEntry.delegated] entries into a [List].
  ///
  /// Can be used like this:
  ///
  /// ```dart
  /// FlowStack(
  ///   children: [
  ///     ...FlowStackEntry.delegatedList(
  ///       delegate: delegateOne,
  ///       children: [childA0, childA1, childA2],
  ///       ids: [0, 1, 2],
  ///     ),
  ///     ...FlowStackEntry.delegatedList(
  ///       delegate: delegateTwo,
  ///       children: [childB0, childB1],
  ///       ids: ['top', 'bottom'],
  ///     ),
  ///   ],
  /// )
  /// ```
  static List<FlowStackEntry> delegatedList({
    required FlowStackLayoutDelegate delegate,
    required Iterable<Widget> children,
    required Iterable<dynamic> ids,
  }) {
    assert(children.length == ids.length);
    return IterableZip([ids, children]).map((zip) => FlowStackEntry.delegated(
      delegate: delegate,
      id: zip[0],
      child: zip[1],
    )).toList();
  }

  /// Cosmetic version of [delegatedList].
  ///
  /// Iterables: "children" and "ids" are replaced with single [map] map.
  static List<FlowStackEntry> delegatedListFromMap({
    required FlowStackLayoutDelegate delegate,
    required Map<dynamic, Widget> map,
  }) {
    return [
      for (final MapEntry(key: id, value: child) in map.entries)
        FlowStackEntry.delegated(
          delegate: delegate,
          id: id,
          child: child,
        )
    ];
  }

  final PaintCallback paintCallback;
  final BoxConstraints Function(BoxConstraints)? constraintsCallback;
  ({FlowStackLayoutDelegate delegate, dynamic id})? delegateContext;
  final Widget child;
}

typedef _EntryRecord = ({int index, FlowStackEntry entry});

abstract class FlowStackLayoutDelegate with Diagnosticable {
  final _paintData = <dynamic, ({Matrix4 transform, double opacity})>{};
  final _idToIndex = <dynamic, int>{};
  final _indexToId = <int, dynamic>{};
  late FlowPaintingContext _context;

  /// Layout children of this delegate by calling [paintChildTranslated] or
  /// [paintChildComposedOf].
  /// You can also call [getChildSize] if the position of one child depends on the
  /// size of any child.
  layout(Size size);

  /// The size of the child with given [id].
  Size getChildSize(dynamic id) {
    assert(_idToIndex.containsKey(id), _notFoundMessage(id));
    return _context.getChildSize(_idToIndex[id]!)!;
  }

  /// Paint a child with a translation.
  paintChildTranslated(dynamic id, Offset translate, [double opacity = 1.0]) {
    assert(_idToIndex.containsKey(id), _notFoundMessage(id));
    final transform = FlowPaintingContextExtension.composeMatrix(translate: translate);
    _paintData[id] = (transform: transform, opacity: opacity);
  }

  /// Paint a child within a [Rect].
  /// See [FlowPaintingContextExtension.paintChildInRect] for more info.
  paintChildInRect(dynamic id, Rect rect, {
    EdgeInsets? padding,
    BoxFit fit = BoxFit.none,
    Alignment alignment = Alignment.topLeft,
    double opacity = 1.0,
  }) {
    assert(_idToIndex.containsKey(id), _notFoundMessage(id));
    if (padding != null) {
      rect = padding.deflateRect(rect);
    }
    final transform = FlowPaintingContextExtension.sizeToRect(getChildSize(id), rect, fit: fit, alignment: alignment);
    _paintData[id] = (transform: transform, opacity: opacity);
  }

  /// Paint a child with a full transformation.
  /// See [FlowPaintingContextExtension.paintChildComposedOf] for more info.
  paintChildComposedOf(dynamic id, {
    double scale = 1,
    double rotation = 0,
    Offset translate = Offset.zero,
    Offset anchor = Offset.zero,
    double opacity = 1.0,
  }) {
    assert(_idToIndex.containsKey(id), _notFoundMessage(id));
    final transform = FlowPaintingContextExtension.composeMatrix(
      scale: scale,
      rotation: rotation,
      translate: translate,
      anchor: anchor,
    );
    _paintData[id] = (transform: transform, opacity: opacity);
  }

  _notFoundMessage(dynamic id) => 'id |$id| not found\navailable ids: ${_idToIndex.keys}';

  _setup(List<_EntryRecord> records) {
    _idToIndex.clear();
    _indexToId.clear();
    for (final record in records) {
      final index = record.index;
      final id = record.entry.delegateContext!.id;
      _idToIndex[id] = index;
      _indexToId[index] = id;
    }
    // debugPrint(toDiagnosticsNode().toStringDeep(prefixLineOne: '|  '));
  }

  _layout(FlowPaintingContext context) {
    _context = context;
    _paintData.clear();
    layout(context.size);
  }

  _paintCallback(int i, FlowPaintingContext pctx, Size size, Rect rect) {
    final pd = _paintData[_indexToId[i]];
    if (pd == null) return; // no paintChild* method called on this child

    pctx.paintChild(i, transform: pd.transform, opacity: pd.opacity);
  }

  /// Override to control the layout constraints given to each child.
  /// See [FlowDelegate.getConstraintsForChild] for more info.
  BoxConstraints getConstraintsForChild(dynamic id, BoxConstraints constraints) => constraints.loosen();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(MessageProperty('_idToIndex', _idToIndex.toString()))
      ..add(MessageProperty('_indexToId', _indexToId.toString()));
  }
}

Map<FlowStackLayoutDelegate, List<_EntryRecord>> _groupEntriesByDelegate(List<FlowStackEntry> entries) {
  final groupedEntries = <FlowStackLayoutDelegate, List<_EntryRecord>>{};
  entries.forEachIndexed((index, entry) {
    if (entry.delegateContext != null) {
      final list = groupedEntries[entry.delegateContext!.delegate] ??= [];
      list.add((index: index, entry: entry));
    }
  });
  for (final delegate in groupedEntries.keys) {
    delegate._setup(groupedEntries[delegate]!);
  }
  return groupedEntries;
}

class _FlowStackDelegate extends FlowDelegate {
  _FlowStackDelegate({
    required this.entries,
    required Listenable? repaint,
  }) : _groupedEntries = _groupEntriesByDelegate(entries), super(repaint: repaint);

  final List<FlowStackEntry> entries;
  final Map<FlowStackLayoutDelegate, List<_EntryRecord>> _groupedEntries;

  @override
  void paintChildren(FlowPaintingContext context) {
    final r = Offset.zero & context.size;
    int i = 0;

    for (final delegate in _groupedEntries.keys) {
      delegate._layout(context);
    }
    for (final entry in entries) {
      entry.paintCallback(i, context, context.getChildSize(i)!, r);
      i++;
    }
  }

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    return entries[i].constraintsCallback?.call(constraints) ?? constraints.loosen();
  }

  @override
  bool shouldRepaint(covariant FlowDelegate oldDelegate) => true;

  @override
  bool shouldRelayout(covariant FlowDelegate oldDelegate) => true;
}
