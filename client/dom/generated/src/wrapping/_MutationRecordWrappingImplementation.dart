// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MutationRecordWrappingImplementation extends DOMWrapperBase implements MutationRecord {
  _MutationRecordWrappingImplementation() : super() {}

  static create__MutationRecordWrappingImplementation() native {
    return new _MutationRecordWrappingImplementation();
  }

  NodeList get addedNodes() { return _get__MutationRecord_addedNodes(this); }
  static NodeList _get__MutationRecord_addedNodes(var _this) native;

  String get attributeName() { return _get__MutationRecord_attributeName(this); }
  static String _get__MutationRecord_attributeName(var _this) native;

  String get attributeNamespace() { return _get__MutationRecord_attributeNamespace(this); }
  static String _get__MutationRecord_attributeNamespace(var _this) native;

  Node get nextSibling() { return _get__MutationRecord_nextSibling(this); }
  static Node _get__MutationRecord_nextSibling(var _this) native;

  String get oldValue() { return _get__MutationRecord_oldValue(this); }
  static String _get__MutationRecord_oldValue(var _this) native;

  Node get previousSibling() { return _get__MutationRecord_previousSibling(this); }
  static Node _get__MutationRecord_previousSibling(var _this) native;

  NodeList get removedNodes() { return _get__MutationRecord_removedNodes(this); }
  static NodeList _get__MutationRecord_removedNodes(var _this) native;

  Node get target() { return _get__MutationRecord_target(this); }
  static Node _get__MutationRecord_target(var _this) native;

  String get type() { return _get__MutationRecord_type(this); }
  static String _get__MutationRecord_type(var _this) native;

  String get typeName() { return "MutationRecord"; }
}
