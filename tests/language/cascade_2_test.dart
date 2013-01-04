// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test cascades, issue 7665.

main() {
  var a = new Element(null);
  Expect.equals(1, a.path0.length);
  Expect.equals(a, a.path0[0]);

  Expect.equals(1, a.path1.length);  // 2 instead of 1
  Expect.equals(a, a.path1[0]);

  Expect.equals(1, a.path2.length);  // NPE.

  var b = new Element(a);
  Expect.equals(2, b.path0.length);
  Expect.equals(a, b.path0[0]);
  Expect.equals(b, b.path0[1]);

  Expect.equals(2, b.path1.length);  // 3 instead of 2.
  Expect.equals(a, b.path1[0]);
  Expect.equals(b, b.path1[1]);

  Expect.equals(2, b.path2.length);  // NPE.
}


class Element {
  final Element parent;

  Element(this.parent);

  List<Element> get path0 {
    if (parent == null) {
      return <Element>[this];
    } else {
      return parent.path0..add(this);
    }
  }

  List<Element> get path1 {
    return (parent == null) ? <Element>[this] : parent.path1..add(this);
  }

  List<Element> get path2 {
    return (parent == null) ? <Element>[this] : (parent.path2..add(this));
  }
}
