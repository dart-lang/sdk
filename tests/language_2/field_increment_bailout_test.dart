// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2js regression test for issue 8781.

import "dart:mirrors" show reflect;
import "package:expect/expect.dart";

class N {
  var outgoing;
  var incoming;
  N(this.outgoing, this.incoming);
}

class A {
  int offset = 0;
  var list;
  var node;

  A(node)
      : node = node,
        list = node.outgoing;

  next() {
    // dart2js used to update [offset] twice: once in the optimized
    // version, which would bailout to the non-optimized version
    // because [list] is not an Array, and once in the non-optimized
    // version.
    var edge = list[offset++];
    if (list == node.outgoing) {
      list = node.incoming;
      offset = 0;
    } else
      list = null;
    return edge;
  }
}

class L {
  final list;
  L(this.list);
  // Use noSuchMethod to defeat type inferencing.
  noSuchMethod(mirror) => reflect(list).delegate(mirror);
}

main() {
  var o = new A(new N(new L([1]), new L([2])));

  for (var i = 1; i <= 2; i++) Expect.equals(i, o.next());

  Expect.equals(null, o.list);
}
