// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final materialInkWellLibrary = MockLibraryUnit(
  'lib/src/material/ink_well.dart',
  r'''
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class InkResponse extends StatelessWidget {
  const InkResponse({
    super.key,
    this.child,
    GestureTapCallback? onTap,
    GestureTapDownCallback? onTapDown,
    GestureTapUpCallback? onTapUp,
    GestureTapCallback? onTapCancel,
    GestureTapCallback? onDoubleTap,
    GestureLongPressCallback? onLongPress,
    GestureLongPressUpCallback? onLongPressUp,
    GestureTapCallback? onSecondaryTap,
    GestureTapUpCallback? onSecondaryTapUp,
    GestureTapDownCallback? onSecondaryTapDown,
    GestureTapCallback? onSecondaryTapCancel,
    ValueChanged<bool>? onHighlightChanged,
    this.onHover,
    MouseCursor? mouseCursor,
    bool containedInkWell = false,
    BoxShape highlightShape = BoxShape.circle,
    double? radius,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    Color? focusColor,
    Color? hoverColor,
    Color? highlightColor,
    WidgetStateProperty<Color?>? overlayColor,
    Color? splashColor,
    InteractiveInkFeatureFactory? splashFactory,
    bool enableFeedback = true,
    bool excludeFromSemantics = false,
    FocusNode? focusNode,
    bool canRequestFocus = true,
    ValueChanged<bool>? onFocusChange,
    bool autofocus = false,
    MaterialStatesController? statesController,
    Duration? hoverDuration,
  });

  final Widget? child;

  final ValueChanged<bool>? onHover;
}

class InkWell extends InkResponse {
  const InkWell({
    super.key,
    super.child,
    super.onTap,
    super.onDoubleTap,
    super.onLongPress,
    super.onTapDown,
    super.onTapUp,
    super.onTapCancel,
    super.onSecondaryTap,
    super.onSecondaryTapUp,
    super.onSecondaryTapDown,
    super.onSecondaryTapCancel,
    super.onHighlightChanged,
    super.onHover,
    super.mouseCursor,
    super.focusColor,
    super.hoverColor,
    super.highlightColor,
    super.overlayColor,
    super.splashColor,
    super.splashFactory,
    super.radius,
    super.borderRadius,
    super.customBorder,
    super.enableFeedback,
    super.excludeFromSemantics,
    super.focusNode,
    super.canRequestFocus,
    super.onFocusChange,
    super.autofocus,
    super.statesController,
    super.hoverDuration,
  }) : super(containedInkWell: true, highlightShape: BoxShape.rectangle);
}
''',
);
