// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// foo() => 42;
import 'data:application/dart;charset=utf-8,foo%28%29%20%3D%3E%2042%3B';

import "package:expect/expect.dart";

main() {
  Expect.equals(42, foo());
}