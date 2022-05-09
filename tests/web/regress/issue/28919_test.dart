// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/28919.
//
// This would crash at runtime because the type of closure parameter 'x' was
// empty, leading to bad codegen. The empty type was due to a tracing bug that
// failed to escape the closure when stored into the list which was not traced
// as a container.

import 'package:expect/expect.dart';

int foo([List _methods = const []]) {
  final methods = new List.from(_methods);
  for (int i = 0; i < 3; i++) {
    methods.add((int x) => x + i);
  }
  return methods[0](499);
}

main() {
  Expect.equals(499, foo());
}
