// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMImplementation {

  CSSStyleSheet createCSSStyleSheet(String title, String media);

  Document createDocument(String namespaceURI, String qualifiedName, DocumentType doctype);

  DocumentType createDocumentType(String qualifiedName, String publicId, String systemId);

  HTMLDocument createHTMLDocument(String title);

  bool hasFeature(String feature, String version);
}
