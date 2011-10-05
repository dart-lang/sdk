// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DOMParserWrappingImplementation extends DOMWrapperBase implements DOMParser {
  _DOMParserWrappingImplementation() : super() {}

  static create__DOMParserWrappingImplementation() native {
    return new _DOMParserWrappingImplementation();
  }

  Document parseFromString(String str = null, String contentType = null) {
    if (str === null) {
      if (contentType === null) {
        return _parseFromString(this);
      }
    } else {
      if (contentType === null) {
        return _parseFromString_2(this, str);
      } else {
        return _parseFromString_3(this, str, contentType);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static Document _parseFromString(receiver) native;
  static Document _parseFromString_2(receiver, str) native;
  static Document _parseFromString_3(receiver, str, contentType) native;

  String get typeName() { return "DOMParser"; }
}
