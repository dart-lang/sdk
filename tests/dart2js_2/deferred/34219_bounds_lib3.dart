// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Part of 34219_bounds_test.dart
//
// This library places GeneratedMessage into a different partition to
// SystemMessage.

import '34219_bounds_lib2.dart';

test3() {
  new GeneratedMessage();
}
