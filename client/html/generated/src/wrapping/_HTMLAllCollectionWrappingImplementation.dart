// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class HTMLAllCollectionWrappingImplementation extends DOMWrapperBase implements HTMLAllCollection {
  HTMLAllCollectionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Node item(int index) {
    return LevelDom.wrapNode(_ptr.item(index));
  }

  Node namedItem(String name) {
    return LevelDom.wrapNode(_ptr.namedItem(name));
  }

  ElementList tags(String name) {
    return LevelDom.wrapElementList(_ptr.tags(name));
  }

  String get typeName() { return "HTMLAllCollection"; }
}
