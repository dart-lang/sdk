// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DocumentTypeWrappingImplementation extends _NodeWrappingImplementation implements DocumentType {
  _DocumentTypeWrappingImplementation() : super() {}

  static create__DocumentTypeWrappingImplementation() native {
    return new _DocumentTypeWrappingImplementation();
  }

  NamedNodeMap get entities() { return _get__DocumentType_entities(this); }
  static NamedNodeMap _get__DocumentType_entities(var _this) native;

  String get internalSubset() { return _get__DocumentType_internalSubset(this); }
  static String _get__DocumentType_internalSubset(var _this) native;

  String get name() { return _get__DocumentType_name(this); }
  static String _get__DocumentType_name(var _this) native;

  NamedNodeMap get notations() { return _get__DocumentType_notations(this); }
  static NamedNodeMap _get__DocumentType_notations(var _this) native;

  String get publicId() { return _get__DocumentType_publicId(this); }
  static String _get__DocumentType_publicId(var _this) native;

  String get systemId() { return _get__DocumentType_systemId(this); }
  static String _get__DocumentType_systemId(var _this) native;

  String get typeName() { return "DocumentType"; }
}
