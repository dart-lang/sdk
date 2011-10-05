// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StyleSheetWrappingImplementation extends DOMWrapperBase implements StyleSheet {
  StyleSheetWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  String get href() { return _ptr.href; }

  MediaList get media() { return LevelDom.wrapMediaList(_ptr.media); }

  Node get ownerNode() { return LevelDom.wrapNode(_ptr.ownerNode); }

  StyleSheet get parentStyleSheet() { return LevelDom.wrapStyleSheet(_ptr.parentStyleSheet); }

  String get title() { return _ptr.title; }

  String get type() { return _ptr.type; }

  String get typeName() { return "StyleSheet"; }
}
