// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Part of 34219_signature_test.dart

import '34219_signature_lib2.dart';

class SystemMessage extends GeneratedMessage {}

var g;

test1() {
  new GeneratedMessage();
  g = (SystemMessage a, SystemMessage b) => a == b;
}
