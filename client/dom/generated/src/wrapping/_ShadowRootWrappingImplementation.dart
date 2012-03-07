// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ShadowRootWrappingImplementation extends _DocumentFragmentWrappingImplementation implements ShadowRoot {
  _ShadowRootWrappingImplementation() : super() {}

  static create__ShadowRootWrappingImplementation() native {
    return new _ShadowRootWrappingImplementation();
  }

  Element get host() { return _get_host(this); }
  static Element _get_host(var _this) native;

  String get innerHTML() { return _get_innerHTML(this); }
  static String _get_innerHTML(var _this) native;

  void set innerHTML(String value) { _set_innerHTML(this, value); }
  static void _set_innerHTML(var _this, String value) native;

  Element getElementById(String elementId) {
    return _getElementById(this, elementId);
  }
  static Element _getElementById(receiver, elementId) native;

  NodeList getElementsByClassName(String className) {
    return _getElementsByClassName(this, className);
  }
  static NodeList _getElementsByClassName(receiver, className) native;

  NodeList getElementsByTagName(String tagName) {
    return _getElementsByTagName(this, tagName);
  }
  static NodeList _getElementsByTagName(receiver, tagName) native;

  NodeList getElementsByTagNameNS(String namespaceURI, String localName) {
    return _getElementsByTagNameNS(this, namespaceURI, localName);
  }
  static NodeList _getElementsByTagNameNS(receiver, namespaceURI, localName) native;

  String get typeName() { return "ShadowRoot"; }
}
