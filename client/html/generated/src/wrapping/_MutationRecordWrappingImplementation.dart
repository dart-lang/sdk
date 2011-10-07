// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MutationRecordWrappingImplementation extends DOMWrapperBase implements MutationRecord {
  MutationRecordWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  ElementList get addedNodes() { return LevelDom.wrapElementList(_ptr.addedNodes); }

  String get attributeName() { return _ptr.attributeName; }

  String get attributeNamespace() { return _ptr.attributeNamespace; }

  Node get nextSibling() { return LevelDom.wrapNode(_ptr.nextSibling); }

  String get oldValue() { return _ptr.oldValue; }

  Node get previousSibling() { return LevelDom.wrapNode(_ptr.previousSibling); }

  ElementList get removedNodes() { return LevelDom.wrapElementList(_ptr.removedNodes); }

  Node get target() { return LevelDom.wrapNode(_ptr.target); }

  String get type() { return _ptr.type; }
}
