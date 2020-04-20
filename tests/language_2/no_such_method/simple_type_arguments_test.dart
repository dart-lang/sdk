// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// dart2jsOptions=--disable-rti-optimization

// Dart test program testing that type arguments are captured by the Invocation
// passed to noSuchMethod from a dynamic call.

import "package:expect/expect.dart";

class Mock {
  noSuchMethod(i) => i.typeArguments;
}

void main() {
  var g = new Mock();

  Expect.listEquals(
      [String, int], (g as dynamic).hurrah<String, int>(moose: 42, duck: 12));

  // map has interceptor calling convention in dart2js.
  Expect.listEquals([String, int], (g as dynamic).map<String, int>());
}
