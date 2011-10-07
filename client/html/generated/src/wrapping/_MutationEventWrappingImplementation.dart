// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MutationEventWrappingImplementation extends EventWrappingImplementation implements MutationEvent {
  MutationEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get attrChange() { return _ptr.attrChange; }

  String get attrName() { return _ptr.attrName; }

  String get newValue() { return _ptr.newValue; }

  String get prevValue() { return _ptr.prevValue; }

  Node get relatedNode() { return LevelDom.wrapNode(_ptr.relatedNode); }

  void initMutationEvent(String type, bool canBubble, bool cancelable, Node relatedNode, String prevValue, String newValue, String attrName, int attrChange) {
    _ptr.initMutationEvent(type, canBubble, cancelable, LevelDom.unwrap(relatedNode), prevValue, newValue, attrName, attrChange);
    return;
  }
}
