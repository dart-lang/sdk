// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  var parent = new Element(null);
  var child = new Element(parent);
  var result = child.path0.length;
  if (result != 2) {
    throw "Expected 2, but child.path0.length was $result";
  }
}

class Element {
  final Element parent;

  Element(this.parent);

  List<Element> get path0 {
    if (parent == null) {
      return <Element>[this];
    } else {
      var list = parent.path0;
      list.add(this);
      return list;
    }
  }
}
