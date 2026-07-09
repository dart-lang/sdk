// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

class Offset {}

class PlatformViewRenderBox extends RenderBox with _PlatformViewGestureMixin {}

mixin _PlatformViewGestureMixin on RenderBox implements MouseTrackerAnnotation {
  bool hitTestSelf(Offset position) =>
      _hitTestBehavior != PlatformViewHitTestBehavior.transparent;
}

main() {}
