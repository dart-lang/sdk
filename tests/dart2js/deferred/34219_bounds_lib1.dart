// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Part of 34219_bounds_test.dart

import '34219_bounds_lib2.dart';

class SystemMessage extends GeneratedMessage {}

var g;

test1() {
  new GeneratedMessage();
  g = (<T extends SystemMessage>(T a, T b) => a == b);
}
