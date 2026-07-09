// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

class SliverHitTestEntry {}

abstract class RenderSliver {
  void handleEvent(PointerEvent event, SliverHitTestEntry entry) {}
}

abstract class RenderSliverSingleBoxAdapter extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox>, RenderSliverHelpers {}

main() {}
