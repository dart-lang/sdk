// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _XSLTProcessorWrappingImplementation extends DOMWrapperBase implements XSLTProcessor {
  _XSLTProcessorWrappingImplementation() : super() {}

  static create__XSLTProcessorWrappingImplementation() native {
    return new _XSLTProcessorWrappingImplementation();
  }

  void clearParameters() {
    _clearParameters(this);
    return;
  }
  static void _clearParameters(receiver) native;

  String getParameter(String namespaceURI, String localName) {
    return _getParameter(this, namespaceURI, localName);
  }
  static String _getParameter(receiver, namespaceURI, localName) native;

  void importStylesheet(Node stylesheet) {
    _importStylesheet(this, stylesheet);
    return;
  }
  static void _importStylesheet(receiver, stylesheet) native;

  void removeParameter(String namespaceURI, String localName) {
    _removeParameter(this, namespaceURI, localName);
    return;
  }
  static void _removeParameter(receiver, namespaceURI, localName) native;

  void reset() {
    _reset(this);
    return;
  }
  static void _reset(receiver) native;

  void setParameter(String namespaceURI, String localName, String value) {
    _setParameter(this, namespaceURI, localName, value);
    return;
  }
  static void _setParameter(receiver, namespaceURI, localName, value) native;

  Document transformToDocument(Node source) {
    return _transformToDocument(this, source);
  }
  static Document _transformToDocument(receiver, source) native;

  DocumentFragment transformToFragment(Node source, Document docVal) {
    return _transformToFragment(this, source, docVal);
  }
  static DocumentFragment _transformToFragment(receiver, source, docVal) native;

  String get typeName() { return "XSLTProcessor"; }
}
