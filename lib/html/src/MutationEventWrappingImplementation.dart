// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MutationEventWrappingImplementation extends EventWrappingImplementation implements MutationEvent {
  MutationEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory MutationEventWrappingImplementation(String type, Node relatedNode,
      String prevValue, String newValue, String attrName, int attrChange,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("MutationEvent");
    e.initMutationEvent(type, canBubble, cancelable,
        LevelDom.unwrap(relatedNode), prevValue, newValue, attrName,
        attrChange);
    return LevelDom.wrapMutationEvent(e);
  }

  int get attrChange => _ptr.attrChange;

  String get attrName => _ptr.attrName;

  String get newValue => _ptr.newValue;

  String get prevValue => _ptr.prevValue;

  Node get relatedNode => LevelDom.wrapNode(_ptr.relatedNode);
}
