// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'deferred.dart';

import 'deferred_lib1.dart' deferred as d hide y1;

part 'deferred_part2.dart';

method1() {
  d.loadLibrary(); // Ok
  d.x1; // Ok
  d.y1; // Error
}
