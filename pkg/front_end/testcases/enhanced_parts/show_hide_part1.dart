// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'show_hide.dart';

import 'show_hide_lib3.dart' show x3;
import 'show_hide_lib3.dart' as lib show x3;
import 'show_hide_lib4.dart' hide y4;
import 'show_hide_lib4.dart' as lib hide y4;

part 'show_hide_part2.dart';

method2() {
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
}
