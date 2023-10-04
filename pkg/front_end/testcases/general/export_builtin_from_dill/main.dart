// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib1.dart' as exported;
import 'main_lib2.dart' as lib2;
import 'main_lib3.dart' as lib3;
import 'main_lib4.dart' as lib4;

test() {
  new exported.Never();
  exported.Never n1;
  <exported.Never>[];
  new exported.dynamic();
  exported.dynamic d1;
  <exported.dynamic>[];

  new lib2.Never();
  lib2.Never n2;
  <lib2.Never>[];
  new lib2.dynamic();
  lib2.dynamic d2;
  <lib2.dynamic>[];

  new lib3.Never();
  lib3.Never n3;
  <lib3.Never>[];
  new lib3.dynamic();
  lib3.dynamic d3;
  <lib3.dynamic>[];

  new lib4.Never();
  lib4.Never n4;
  <lib4.Never>[];
  new lib4.dynamic();
  lib4.dynamic d4;
  <lib4.dynamic>[];
}
