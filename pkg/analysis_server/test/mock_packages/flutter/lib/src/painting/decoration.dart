// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'edge_insets.dart';

/// A description of a box decoration (a decoration applied to a [Rect]).
///
/// This class presents the abstract interface for all decorations.
/// See [BoxDecoration] for a concrete example.
///
/// To actually paint a [Decoration], use the [createBoxPainter]
/// method to obtain a [BoxPainter]. [Decoration] objects can be
/// shared between boxes; [BoxPainter] objects can cache resources to
/// make painting on a particular surface faster.
@immutable
abstract class Decoration {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Decoration();

  /// Whether this decoration is complex enough to benefit from caching its painting.
  bool get isComplex => false;

  /// Returns the insets to apply when using this decoration on a box
  /// that has contents, so that the contents do not overlap the edges
  /// of the decoration. For example, if the decoration draws a frame
  /// around its edge, the padding would return the distance by which
  /// to inset the children so as to not overlap the frame.
  ///
  /// This only works for decorations that have absolute sizes. If the padding
  /// needed would change based on the size at which the decoration is drawn,
  /// then this will return incorrect padding values.
  ///
  /// For example, when a [BoxDecoration] has [BoxShape.circle], the padding
  /// does not take into account that the circle is drawn in the center of the
  /// box regardless of the ratio of the box; it does not provide the extra
  /// padding that is implied by changing the ratio.
  ///
  /// The value returned by this getter must be resolved (using
  /// [EdgeInsetsGeometry.resolve] to obtain an absolute [EdgeInsets]. (For
  /// example, [BorderDirectional] will return an [EdgeInsetsDirectional] for
  /// its [padding].)
  EdgeInsetsGeometry get padding => EdgeInsets.zero;
}
