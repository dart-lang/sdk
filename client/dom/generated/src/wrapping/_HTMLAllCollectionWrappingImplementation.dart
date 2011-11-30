// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLAllCollectionWrappingImplementation extends DOMWrapperBase implements HTMLAllCollection {
  _HTMLAllCollectionWrappingImplementation() : super() {}

  static create__HTMLAllCollectionWrappingImplementation() native {
    return new _HTMLAllCollectionWrappingImplementation();
  }

  int get length() { return _get_length(this); }
  static int _get_length(var _this) native;

  Node item(int index) {
    return _item(this, index);
  }
  static Node _item(receiver, index) native;

  Node namedItem(String name) {
    return _namedItem(this, name);
  }
  static Node _namedItem(receiver, name) native;

  NodeList tags(String name) {
    return _tags(this, name);
  }
  static NodeList _tags(receiver, name) native;

  String get typeName() { return "HTMLAllCollection"; }
}
