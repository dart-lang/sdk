// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

library touch;

import 'dart:async';
import 'dart:collection'
    show
        Queue,
        DoubleLinkedQueue,
        DoubleLinkedQueueEntry,
        ListMixin,
        ImmutableListMixin;
import 'dart:html';
import 'dart:math' as Math;

import '../base/base.dart';

part 'BezierPhysics.dart';
part 'FxUtil.dart';
part 'InfiniteScroller.dart';
part 'Momentum.dart';
part 'Scroller.dart';
part 'TouchHandler.dart';
part 'ClickBuster.dart';
part 'EventUtil.dart';
part 'Geometry.dart';
part 'Math.dart';
part 'Scrollbar.dart';
part 'ScrollWatcher.dart';
part 'TimeUtil.dart';
part 'TouchUtil.dart';
