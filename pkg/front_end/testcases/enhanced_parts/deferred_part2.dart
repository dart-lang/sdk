// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'deferred_part1.dart';

import 'deferred_lib2.dart' deferred as d show x2;

part 'deferred_part3.dart';

method2() {
  d.loadLibrary(); // Ok
  d.x1; // Error
  d.y1; // Error
  d.x2; // Ok
  d.y2; // Error
}
