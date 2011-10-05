// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EntryArrayWrappingImplementation extends DOMWrapperBase implements EntryArray {
  EntryArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Entry item(int index) {
    return LevelDom.wrapEntry(_ptr.item(index));
  }

  String get typeName() { return "EntryArray"; }
}
