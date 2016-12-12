// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2js used to fail this test, by inferring that `a.last()`
// returns the element type of the `a` list.

main() {
  var a = [() => 123];
  if (a.last() is! num) {
    throw 'Test failed';
  }
}
