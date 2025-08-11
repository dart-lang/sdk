// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

class SliverConstraints {}

abstract class RenderSliver extends RenderObject {
  SliverConstraints get constraints => super.constraints as SliverConstraints;
}

abstract class RenderSliverSingleBoxAdapter extends RenderSliver
    with RenderObjectWithChildMixin {}

main() {}
