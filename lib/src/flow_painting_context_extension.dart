import 'dart:math';

import 'package:flutter/rendering.dart';

extension FlowPaintingContextExtension on FlowPaintingContext {
  /// Paints the [i]th child using [translate] to position the child at given [anchor].
  paintChildTranslated(int i, Offset translate, {
    Alignment anchor = Alignment.topLeft,
    double opacity = 1.0,
  }) => paintChild(i,
    transform: composeMatrix(
      translate: translate,
      anchor: anchor == Alignment.topLeft?
        Offset.zero : anchor.alongSize(getChildSize(i)!),
    ),
    opacity: opacity,
  );

  /// Paints the [i]th child with a transformation.
  /// The transformation is composed of [scale], [rotation], [translate] and [anchor].
  ///
  /// [anchor] is a central point within a child where all transformations are applied:
  /// 1. first the child is moved so that [anchor] point is located at [Offset.zero]
  /// 2. if [scale] is provided the child is scaled by [scale] factor ([anchor] still stays at [Offset.zero])
  /// 3. if [rotation] is provided the child is rotated by [rotation] radians ([anchor] still stays at [Offset.zero])
  /// 4. finally if [translate] is provided the child is moved by [translate]
  ///
  /// For example if child size is `Size(80, 60)` and for
  /// `anchor: Offset(20, 10), scale: 2, translate: Offset(100, 100)` then child's
  /// top-left and bottom-right corners are as follows:
  ///
  /// **step** | **top-left**     | **bottom-right**
  /// ----------------------------------------------
  /// 1.       | Offset(-20, -10) | Offset(60, 50)
  /// 2.       | Offset(-40, -20) | Offset(120, 100)
  /// 3.       | n/a              | n/a
  /// 4.       | Offset(60, 80)   | Offset(220, 200)
  ///
  /// The following image shows how it works in practice:
  ///
  /// ![](https://github.com/pskink/flow_stack/blob/main/images/transform_composing.png?raw=true)
  ///
  /// steps:
  /// 1. `anchor: Offset(61, 49)` - indicated by a green vector
  /// 2. `scale: 1.2` - the anchor point is untouched after scaling
  /// 3. `rotation: 0.1 * pi` - the anchor point is untouched after rotating
  /// 4. `translate: Offset(24, -71)` - indicated by a red vector

  paintChildComposedOf(int i, {
    double scale = 1,
    double rotation = 0,
    Offset translate = Offset.zero,
    Offset anchor = Offset.zero,
    double opacity = 1.0,
  }) => paintChild(i,
    transform: composeMatrix(
      scale: scale,
      rotation: rotation,
      translate: translate,
      anchor: anchor,
    ),
    opacity: opacity,
  );

  /// Paints the [i]th child using [fit] and [alignment] to position the child
  /// within a given [rect] (optionally deflated by [padding]).
  ///
  /// By default the following values are used:
  ///
  /// - [rect] = Offset.zero & size - the entire area of [Flow] widget
  /// - [padding] = null - when specified it is used to deflate [rect]
  /// - [fit] = BoxFit.none
  /// - [alignment] = Alignment.topLeft
  /// - [opacity] = 1.0
  ///
  paintChildInRect(int i, {
    Rect? rect,
    EdgeInsets? padding,
    BoxFit fit = BoxFit.none,
    Alignment alignment = Alignment.topLeft,
    double opacity = 1.0,
  }) {
    rect ??= Offset.zero & size;
    if (padding != null) {
      rect = padding.deflateRect(rect);
    }
    paintChild(i,
      transform: sizeToRect(getChildSize(i)!, rect, fit: fit, alignment: alignment),
      opacity: opacity,
    );
  }

  static Matrix4 sizeToRect(Size src, Rect dst, {BoxFit fit = BoxFit.contain, Alignment alignment = Alignment.center}) {
    FittedSizes fs = applyBoxFit(fit, src, dst.size);
    double scaleX = fs.destination.width / fs.source.width;
    double scaleY = fs.destination.height / fs.source.height;
    Size fittedSrc = Size(src.width * scaleX, src.height * scaleY);
    Rect out = alignment.inscribe(fittedSrc, dst);

    return Matrix4.identity()
      ..translate(out.left, out.top)
      ..scale(scaleX, scaleY);
  }

  static Matrix4 composeMatrix({
    double scale = 1,
    double rotation = 0,
    Offset translate = Offset.zero,
    Offset anchor = Offset.zero,
  }) {
    if (rotation == 0) {
      // a special case:
      //   c = cos(rotation) * scale => scale
      //   s = sin(rotation) * scale => 0
      // it reduces to:
      return Matrix4(
        scale, 0,     0, 0,
        0,     scale, 0, 0,
        0,     0,     1, 0,
        translate.dx - scale * anchor.dx, translate.dy - scale * anchor.dy, 0, 1
      );
    }
    final double c = cos(rotation) * scale;
    final double s = sin(rotation) * scale;
    final double dx = translate.dx - c * anchor.dx + s * anchor.dy;
    final double dy = translate.dy - s * anchor.dx - c * anchor.dy;
    return Matrix4(c, s, 0, 0, -s, c, 0, 0, 0, 0, 1, 0, dx, dy, 0, 1);
  }
}

extension AlignSizeToRectExtension on Rect {
  /// Returns a [Rect] (output [Rect]) with given [size] aligned to this [Rect]
  /// (input [Rect]) in such a way that [inputAnchor] applied to input [Rect]
  /// lines up with [outputAnchor] applied to output [Rect].
  ///
  /// For example if [inputAnchor] is [Alignment.bottomCenter] and [outputAnchor] is
  /// [Alignment.topCenter] the output [Rect] is as follows (two points that
  /// line up are shown as █):
  ///
  ///     ┌─────────────────────┐
  ///     │     input Rect      │
  ///     └───┲━━━━━━█━━━━━━┱───┘
  ///         ┃ output Rect ┃
  ///         ┃             ┃
  ///         ┗━━━━━━━━━━━━━┛
  ///
  /// another example: [inputAnchor] is [Alignment.bottomRight] and
  /// [outputAnchor] is [Alignment.topRight]:
  ///
  ///     ┌─────────────────────┐
  ///     │     input Rect      │
  ///     └───────┲━━━━━━━━━━━━━█
  ///             ┃ output Rect ┃
  ///             ┃             ┃
  ///             ┗━━━━━━━━━━━━━┛
  ///
  /// yet another example: [inputAnchor] is [Alignment.bottomRight] and
  /// [outputAnchor] is [Alignment.bottomLeft]:
  ///
  ///                           ┏━━━━━━━━━━━━━┓
  ///     ┌─────────────────────┨ output Rect ┃
  ///     │     input Rect      ┃             ┃
  ///     └─────────────────────█━━━━━━━━━━━━━┛
  ///
  Rect alignSize(Size size, Alignment inputAnchor, Alignment outputAnchor, [Offset extraOffset = Offset.zero]) {
    final inputOffset = inputAnchor.withinRect(this);
    final outputOffset = outputAnchor.alongSize(size);
    Offset offset = inputOffset - outputOffset;
    if (extraOffset != Offset.zero) offset += extraOffset;

    return offset & size;
  }
}
