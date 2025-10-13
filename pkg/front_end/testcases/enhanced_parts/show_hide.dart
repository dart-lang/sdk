// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'show_hide_lib1.dart' show x1;
import 'show_hide_lib1.dart' as lib show x1;
import 'show_hide_lib2.dart' hide y2;
import 'show_hide_lib2.dart' as lib hide y2;

part 'show_hide_part1.dart';

method1() {
  x1; // Ok
  y1; // Error
  z1; // Error
  x2; // Ok
  y2; // Error
  z2; // Ok
  lib.x1; // Ok
  lib.y1; // Error
  lib.z1; // Error
  lib.x2; // Ok
  lib.y2; // Error
  lib.z2; // Ok
}