// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DOMParserWrappingImplementation extends DOMWrapperBase implements DOMParser {
  _DOMParserWrappingImplementation() : super() {}

  static create__DOMParserWrappingImplementation() native {
    return new _DOMParserWrappingImplementation();
  }

  Document parseFromString(String str, String contentType) {
    return _parseFromString(this, str, contentType);
  }
  static Document _parseFromString(receiver, str, contentType) native;

  String get typeName() { return "DOMParser"; }
}
