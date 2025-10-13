// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'show_hide_part1.dart';

import 'show_hide_lib5.dart' show x5;
import 'show_hide_lib5.dart' as lib show x5;
import 'show_hide_lib6.dart' hide y6;
import 'show_hide_lib6.dart' as lib hide y6;

method3() {
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

  x3; // Ok
  y3; // Error
  z3; // Error
  x4; // Ok
  y4; // Error
  z4; // Ok
  lib.x3; // Ok
  lib.y3; // Error
  lib.z3; // Error
  lib.x4; // Ok
  lib.y4; // Error
  lib.z4; // Ok

  x5; // Ok
  y5; // Error
  z5; // Error
  x6; // Ok
  y6; // Error
  z6; // Ok
  lib.x5; // Ok
  lib.y5; // Error
  lib.z5; // Error
  lib.x6; // Ok
  lib.y6; // Error
  lib.z6; // Ok
}
