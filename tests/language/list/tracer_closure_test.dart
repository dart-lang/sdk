// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js' inferrer: if we closurize a method, we
// still need to collect the users of the parameters for the trace
// container pass to work.

main() {
  var a = new List.empty();
  a.add;
  var b = new List.empty(growable: true);
  var c = new List<dynamic>.filled(1, null);
  b.add(c);
  b[0][0] = 42;
  if (c[0] is! int) {
    throw 'Test failed';
  }
}
