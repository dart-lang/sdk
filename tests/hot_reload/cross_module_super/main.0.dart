// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for 'RenderBox' test failures in Flutter.

import 'lib.dart';

class Child extends ParentWithMixin {
  @override
  method() {
    return super.method;
  }
}

void main() {
  var child = Child();
  child.method();
}
