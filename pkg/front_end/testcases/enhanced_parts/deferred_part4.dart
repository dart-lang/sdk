// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'deferred_part3.dart';

import 'deferred_lib4.dart' deferred as d show x4;

method4() {
  d.loadLibrary(); // Ok
  d.x1; // Error
  d.y1; // Error
  d.x2; // Error
  d.y2; // Error
  d.x3; // Error
  d.y3; // Error
  d.x4; // Ok
  d.y4; // Error
}
