// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to infinite loop on
// speculatively propagating types.

class Bar {
  noSuchMethod(e) => null;
}

main() {
  var d = new Bar();

  while (false) {
    // [input] will change from indexable to unknown: the use line 20
    // changes its decision because [a2] changes its type from unknown to
    // null.
    var input = ((x) {})(null);
    var p2 = input.keys.firstWhere(null);
    var a2 = input.keys.firstWhere(null);
    print(input[a2] == p2);
  }
}
