// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WebKitNamedFlowWrappingImplementation extends DOMWrapperBase implements WebKitNamedFlow {
  _WebKitNamedFlowWrappingImplementation() : super() {}

  static create__WebKitNamedFlowWrappingImplementation() native {
    return new _WebKitNamedFlowWrappingImplementation();
  }

  bool get overflow() { return _get_overflow(this); }
  static bool _get_overflow(var _this) native;

  NodeList getRegionsByContentNode(Node contentNode) {
    return _getRegionsByContentNode(this, contentNode);
  }
  static NodeList _getRegionsByContentNode(receiver, contentNode) native;

  String get typeName() { return "WebKitNamedFlow"; }
}
