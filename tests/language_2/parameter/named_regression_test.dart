// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A regression test for dart2js bug 6015.

class Fisk {
  foo({b, a: true}) {
    if (b == null) return;
    throw 'broken';
  }

  bar({a, b: true}) {
    if (a == null) return;
    throw 'broken';
  }
}

main() {
  new Fisk().foo(a: true);
  new Fisk().bar(b: true);
}
