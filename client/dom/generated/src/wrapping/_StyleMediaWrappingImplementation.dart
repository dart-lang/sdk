// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _StyleMediaWrappingImplementation extends DOMWrapperBase implements StyleMedia {
  _StyleMediaWrappingImplementation() : super() {}

  static create__StyleMediaWrappingImplementation() native {
    return new _StyleMediaWrappingImplementation();
  }

  String get type() { return _get__StyleMedia_type(this); }
  static String _get__StyleMedia_type(var _this) native;

  bool matchMedium(String mediaquery) {
    return _matchMedium(this, mediaquery);
  }
  static bool _matchMedium(receiver, mediaquery) native;

  String get typeName() { return "StyleMedia"; }
}
