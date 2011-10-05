// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DOMImplementation {

  CSSStyleSheet createCSSStyleSheet(String title = null, String media = null);

  Document createDocument(String namespaceURI = null, String qualifiedName = null, DocumentType doctype = null);

  DocumentType createDocumentType(String qualifiedName = null, String publicId = null, String systemId = null);

  HTMLDocument createHTMLDocument(String title = null);

  bool hasFeature(String feature = null, String version = null);
}
