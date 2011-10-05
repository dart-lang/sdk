// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMMimeTypeWrappingImplementation extends DOMWrapperBase implements DOMMimeType {
  DOMMimeTypeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get description() { return _ptr.description; }

  DOMPlugin get enabledPlugin() { return LevelDom.wrapDOMPlugin(_ptr.enabledPlugin); }

  String get suffixes() { return _ptr.suffixes; }

  String get type() { return _ptr.type; }

  String get typeName() { return "DOMMimeType"; }
}
