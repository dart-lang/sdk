// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js, that used to emit wrong code on is
// checks of native classes that are not instantiated.

import 'dart:html';

import 'package:expect/expect.dart';

var a = [new Object()];

main() {
  Expect.isFalse(a[0] is Node);
}
