// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic_types.dart';
import 'border_radius.dart';
import 'box_border.dart';
import 'decoration.dart';

/// An immutable description of how to paint a box.
///
/// The [BoxDecoration] class provides a variety of ways to draw a box.
///
/// The box has a [border], a body, and may cast a [boxShadow].
///
/// The [shape] of the box can be a circle or a rectangle. If it is a rectangle,
/// then the [borderRadius] property controls the roundness of the corners.
///
/// The body of the box is painted in layers. The bottom-most layer is the
/// [color], which fills the box. Above that is the [gradient], which also fills
/// the box. Finally there is the [image], the precise alignment of which is
/// controlled by the [DecorationImage] class.
///
/// The [border] paints over the body; the [boxShadow], naturally, paints below it.
///
/// {@tool sample}
///
/// The following example uses the [Container] widget from the widgets layer to
/// draw an image with a border:
///
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     color: const Color(0xff7c94b6),
///     image: DecorationImage(
///       image: ExactAssetImage('images/flowers.jpeg'),
///       fit: BoxFit.cover,
///     ),
///     border: Border.all(
///       color: Colors.black,
///       width: 8.0,
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// {@template flutter.painting.boxDecoration.clip}
/// The [shape] or the [borderRadius] won't clip the children of the
/// decorated [Container]. If the clip is required, insert a clip widget
/// (e.g., [ClipRect], [ClipRRect], [ClipPath]) as the child of the [Container].
/// Be aware that clipping may be costly in terms of performance.
/// {@endtemplate}
///
/// See also:
///
///  * [DecoratedBox] and [Container], widgets that can be configured with
///    [BoxDecoration] objects.
///  * [CustomPaint], a widget that lets you draw arbitrary graphics.
///  * [Decoration], the base class which lets you define other decorations.
class BoxDecoration extends Decoration {
  /// The color to fill in the background of the box.
  ///
  /// The color is filled into the [shape] of the box (e.g., either a rectangle,
  /// potentially with a [borderRadius], or a circle).
  ///
  /// This is ignored if [gradient] is non-null.
  ///
  /// The [color] is drawn under the [image].
  final Color color;

  /// A border to draw above the background [color], [gradient], or [image].
  ///
  /// Follows the [shape] and [borderRadius].
  ///
  /// Use [Border] objects to describe borders that do not depend on the reading
  /// direction.
  ///
  /// Use [BoxBorder] objects to describe borders that should flip their left
  /// and right edges based on whether the text is being read left-to-right or
  /// right-to-left.
  final BoxBorder border;

  /// If non-null, the corners of this box are rounded by this [BorderRadius].
  ///
  /// Applies only to boxes with rectangular shapes; ignored if [shape] is not
  /// [BoxShape.rectangle].
  ///
  /// {@macro flutter.painting.boxDecoration.clip}
  final BorderRadiusGeometry borderRadius;

  /// The blend mode applied to the [color] or [gradient] background of the box.
  ///
  /// If no [backgroundBlendMode] is provided then the default painting blend
  /// mode is used.
  ///
  /// If no [color] or [gradient] is provided then the blend mode has no impact.
  final BlendMode backgroundBlendMode;

  /// The shape to fill the background [color], [gradient], and [image] into and
  /// to cast as the [boxShadow].
  ///
  /// If this is [BoxShape.circle] then [borderRadius] is ignored.
  ///
  /// The [shape] cannot be interpolated; animating between two [BoxDecoration]s
  /// with different [shape]s will result in a discontinuity in the rendering.
  /// To interpolate between two shapes, consider using [ShapeDecoration] and
  /// different [ShapeBorder]s; in particular, [CircleBorder] instead of
  /// [BoxShape.circle] and [RoundedRectangleBorder] instead of
  /// [BoxShape.rectangle].
  ///
  /// {@macro flutter.painting.boxDecoration.clip}
  final BoxShape shape;

  /// Creates a box decoration.
  ///
  /// * If [color] is null, this decoration does not paint a background color.
  /// * If [image] is null, this decoration does not paint a background image.
  /// * If [border] is null, this decoration does not paint a border.
  /// * If [borderRadius] is null, this decoration uses more efficient background
  ///   painting commands. The [borderRadius] argument must be null if [shape] is
  ///   [BoxShape.circle].
  /// * If [boxShadow] is null, this decoration does not paint a shadow.
  /// * If [gradient] is null, this decoration does not paint gradients.
  /// * If [backgroundBlendMode] is null, this decoration paints with [BlendMode.srcOver]
  ///
  /// The [shape] argument must not be null.
  const BoxDecoration({
    this.color,
    this.border,
    this.borderRadius,
    this.backgroundBlendMode,
    this.shape = BoxShape.rectangle,
  });
}
