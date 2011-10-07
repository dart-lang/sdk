// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMPluginWrappingImplementation extends DOMWrapperBase implements DOMPlugin {
  DOMPluginWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get description() { return _ptr.description; }

  String get filename() { return _ptr.filename; }

  int get length() { return _ptr.length; }

  String get name() { return _ptr.name; }

  DOMMimeType item(int index) {
    return LevelDom.wrapDOMMimeType(_ptr.item(index));
  }

  DOMMimeType namedItem(String name) {
    return LevelDom.wrapDOMMimeType(_ptr.namedItem(name));
  }
}
