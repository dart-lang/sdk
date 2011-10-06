// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DOMImplementationWrappingImplementation extends DOMWrapperBase implements DOMImplementation {
  _DOMImplementationWrappingImplementation() : super() {}

  static create__DOMImplementationWrappingImplementation() native {
    return new _DOMImplementationWrappingImplementation();
  }

  CSSStyleSheet createCSSStyleSheet(String title, String media) {
    return _createCSSStyleSheet(this, title, media);
  }
  static CSSStyleSheet _createCSSStyleSheet(receiver, title, media) native;

  Document createDocument(String namespaceURI, String qualifiedName, DocumentType doctype) {
    return _createDocument(this, namespaceURI, qualifiedName, doctype);
  }
  static Document _createDocument(receiver, namespaceURI, qualifiedName, doctype) native;

  DocumentType createDocumentType(String qualifiedName, String publicId, String systemId) {
    return _createDocumentType(this, qualifiedName, publicId, systemId);
  }
  static DocumentType _createDocumentType(receiver, qualifiedName, publicId, systemId) native;

  HTMLDocument createHTMLDocument(String title) {
    return _createHTMLDocument(this, title);
  }
  static HTMLDocument _createHTMLDocument(receiver, title) native;

  bool hasFeature(String feature, String version) {
    return _hasFeature(this, feature, version);
  }
  static bool _hasFeature(receiver, feature, version) native;

  String get typeName() { return "DOMImplementation"; }
}
