// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMParserWrappingImplementation extends DOMWrapperBase implements DOMParser {
  DOMParserWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  Document parseFromString(String str, String contentType) {
    return LevelDom.wrapDocument(_ptr.parseFromString(str, contentType));
  }

  String get typeName() { return "DOMParser"; }
}
