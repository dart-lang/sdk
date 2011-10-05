// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _XMLSerializerWrappingImplementation extends DOMWrapperBase implements XMLSerializer {
  _XMLSerializerWrappingImplementation() : super() {}

  static create__XMLSerializerWrappingImplementation() native {
    return new _XMLSerializerWrappingImplementation();
  }

  String serializeToString(Node node = null) {
    if (node === null) {
      return _serializeToString(this);
    } else {
      return _serializeToString_2(this, node);
    }
  }
  static String _serializeToString(receiver) native;
  static String _serializeToString_2(receiver, node) native;

  String get typeName() { return "XMLSerializer"; }
}
