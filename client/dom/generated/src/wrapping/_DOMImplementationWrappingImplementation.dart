// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DOMImplementationWrappingImplementation extends DOMWrapperBase implements DOMImplementation {
  _DOMImplementationWrappingImplementation() : super() {}

  static create__DOMImplementationWrappingImplementation() native {
    return new _DOMImplementationWrappingImplementation();
  }

  CSSStyleSheet createCSSStyleSheet([String title = null, String media = null]) {
    if (title === null) {
      if (media === null) {
        return _createCSSStyleSheet(this);
      }
    } else {
      if (media === null) {
        return _createCSSStyleSheet_2(this, title);
      } else {
        return _createCSSStyleSheet_3(this, title, media);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static CSSStyleSheet _createCSSStyleSheet(receiver) native;
  static CSSStyleSheet _createCSSStyleSheet_2(receiver, title) native;
  static CSSStyleSheet _createCSSStyleSheet_3(receiver, title, media) native;

  Document createDocument([String namespaceURI = null, String qualifiedName = null, DocumentType doctype = null]) {
    if (namespaceURI === null) {
      if (qualifiedName === null) {
        if (doctype === null) {
          return _createDocument(this);
        }
      }
    } else {
      if (qualifiedName === null) {
        if (doctype === null) {
          return _createDocument_2(this, namespaceURI);
        }
      } else {
        if (doctype === null) {
          return _createDocument_3(this, namespaceURI, qualifiedName);
        } else {
          return _createDocument_4(this, namespaceURI, qualifiedName, doctype);
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static Document _createDocument(receiver) native;
  static Document _createDocument_2(receiver, namespaceURI) native;
  static Document _createDocument_3(receiver, namespaceURI, qualifiedName) native;
  static Document _createDocument_4(receiver, namespaceURI, qualifiedName, doctype) native;

  DocumentType createDocumentType([String qualifiedName = null, String publicId = null, String systemId = null]) {
    if (qualifiedName === null) {
      if (publicId === null) {
        if (systemId === null) {
          return _createDocumentType(this);
        }
      }
    } else {
      if (publicId === null) {
        if (systemId === null) {
          return _createDocumentType_2(this, qualifiedName);
        }
      } else {
        if (systemId === null) {
          return _createDocumentType_3(this, qualifiedName, publicId);
        } else {
          return _createDocumentType_4(this, qualifiedName, publicId, systemId);
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static DocumentType _createDocumentType(receiver) native;
  static DocumentType _createDocumentType_2(receiver, qualifiedName) native;
  static DocumentType _createDocumentType_3(receiver, qualifiedName, publicId) native;
  static DocumentType _createDocumentType_4(receiver, qualifiedName, publicId, systemId) native;

  HTMLDocument createHTMLDocument([String title = null]) {
    if (title === null) {
      return _createHTMLDocument(this);
    } else {
      return _createHTMLDocument_2(this, title);
    }
  }
  static HTMLDocument _createHTMLDocument(receiver) native;
  static HTMLDocument _createHTMLDocument_2(receiver, title) native;

  bool hasFeature([String feature = null, String version = null]) {
    if (feature === null) {
      if (version === null) {
        return _hasFeature(this);
      }
    } else {
      if (version === null) {
        return _hasFeature_2(this, feature);
      } else {
        return _hasFeature_3(this, feature, version);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static bool _hasFeature(receiver) native;
  static bool _hasFeature_2(receiver, feature) native;
  static bool _hasFeature_3(receiver, feature, version) native;

  String get typeName() { return "DOMImplementation"; }
}
