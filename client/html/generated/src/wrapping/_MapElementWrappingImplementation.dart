// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MapElementWrappingImplementation extends ElementWrappingImplementation implements MapElement {
  MapElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  ElementList get areas() { return LevelDom.wrapElementList(_ptr.areas); }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get typeName() { return "MapElement"; }
}
