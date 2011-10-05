// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StyleMediaWrappingImplementation extends DOMWrapperBase implements StyleMedia {
  StyleMediaWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get type() { return _ptr.type; }

  bool matchMedium(String mediaquery) {
    return _ptr.matchMedium(mediaquery);
  }

  String get typeName() { return "StyleMedia"; }
}
