// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'deferred_part2.dart';

import 'deferred_lib3.dart' as d hide y3; // Not deferred.

part 'deferred_part4.dart';

method3() {
  d.loadLibrary(); // Error
  d.x1; // Error
  d.y1; // Error
  d.x2; // Error
  d.y2; // Error
  d.x3; // Ok
  d.y3; // Error
}
