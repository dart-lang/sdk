// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';

class Align extends SingleChildRenderObjectWidget {
  /// How to align the child.
  ///
  /// The x and y values of the [Alignment] control the horizontal and vertical
  /// alignment, respectively. An x value of -1.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.0 means that the center of the child is aligned
  /// with the center of the parent.
  ///
  /// See also:
  ///
  ///  * [Alignment], which has more details and some convenience constants for
  ///    common positions.
  ///  * [AlignmentDirectional], which has a horizontal coordinate orientation
  ///    that depends on the [TextDirection].
  final AlignmentGeometry alignment;

  /// If non-null, sets its width to the child's width multiplied by this factor.
  ///
  /// Can be both greater and less than 1.0 but must be positive.
  final double widthFactor;

  /// If non-null, sets its height to the child's height multiplied by this factor.
  ///
  /// Can be both greater and less than 1.0 but must be positive.
  final double heightFactor;

  /// Creates an alignment widget.
  ///
  /// The alignment defaults to [Alignment.center].
  const Align({
    Key key,
    this.alignment = Alignment.center,
    this.widthFactor,
    this.heightFactor,
    Widget child,
  })  : assert(alignment != null),
        assert(widthFactor == null || widthFactor >= 0.0),
        assert(heightFactor == null || heightFactor >= 0.0),
        super(key: key, child: child);
}

class AspectRatio extends SingleChildRenderObjectWidget {
  const AspectRatio({
    Key key,
    @required double aspectRatio,
    Widget child,
  });
}

class Center extends StatelessWidget {
  const Center({Key key, double heightFactor, Widget child});
}

class ClipRect extends SingleChildRenderObjectWidget {
  const ClipRect({Key key, Widget child}) : super(key: key, child: child);

  /// Does not actually exist in Flutter.
  const ClipRect.rect({Key key, Widget child}) : super(key: key, child: child);
}

class Column extends Flex {
  Column({
    Key key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline textBaseline,
    List<Widget> children = const <Widget>[],
  });
}

class Expanded extends StatelessWidget {
  const Expanded({
    Key key,
    int flex = 1,
    @required Widget child,
  });
}

class Flex extends Widget {
  Flex({
    Key key,
    List<Widget> children = const <Widget>[],
  });
}

class Padding extends SingleChildRenderObjectWidget {
  final EdgeInsetsGeometry padding;

  const Padding({
    Key key,
    @required this.padding,
    Widget child,
  });
}

class Row extends Flex {
  Row({
    Key key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline textBaseline,
    List<Widget> children = const <Widget>[],
  });
}

class Transform extends SingleChildRenderObjectWidget {
  const Transform({
    Key key,
    @required transform,
    origin,
    alignment,
    transformHitTests = true,
    Widget child,
  });
}
