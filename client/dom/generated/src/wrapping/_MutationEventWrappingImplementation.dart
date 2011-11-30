// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MutationEventWrappingImplementation extends _EventWrappingImplementation implements MutationEvent {
  _MutationEventWrappingImplementation() : super() {}

  static create__MutationEventWrappingImplementation() native {
    return new _MutationEventWrappingImplementation();
  }

  int get attrChange() { return _get_attrChange(this); }
  static int _get_attrChange(var _this) native;

  String get attrName() { return _get_attrName(this); }
  static String _get_attrName(var _this) native;

  String get newValue() { return _get_newValue(this); }
  static String _get_newValue(var _this) native;

  String get prevValue() { return _get_prevValue(this); }
  static String _get_prevValue(var _this) native;

  Node get relatedNode() { return _get_relatedNode(this); }
  static Node _get_relatedNode(var _this) native;

  void initMutationEvent(String type, bool canBubble, bool cancelable, Node relatedNode, String prevValue, String newValue, String attrName, int attrChange) {
    _initMutationEvent(this, type, canBubble, cancelable, relatedNode, prevValue, newValue, attrName, attrChange);
    return;
  }
  static void _initMutationEvent(receiver, type, canBubble, cancelable, relatedNode, prevValue, newValue, attrName, attrChange) native;

  String get typeName() { return "MutationEvent"; }
}
