// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IFrameElementWrappingImplementation extends ElementWrappingImplementation implements IFrameElement {
  IFrameElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  Document get contentDocument() { return LevelDom.wrapDocument(_ptr.contentDocument); }

  Window get contentWindow() { return LevelDom.wrapWindow(_ptr.contentWindow); }

  String get frameBorder() { return _ptr.frameBorder; }

  void set frameBorder(String value) { _ptr.frameBorder = value; }

  String get height() { return _ptr.height; }

  void set height(String value) { _ptr.height = value; }

  String get longDesc() { return _ptr.longDesc; }

  void set longDesc(String value) { _ptr.longDesc = value; }

  String get marginHeight() { return _ptr.marginHeight; }

  void set marginHeight(String value) { _ptr.marginHeight = value; }

  String get marginWidth() { return _ptr.marginWidth; }

  void set marginWidth(String value) { _ptr.marginWidth = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get sandbox() { return _ptr.sandbox; }

  void set sandbox(String value) { _ptr.sandbox = value; }

  String get scrolling() { return _ptr.scrolling; }

  void set scrolling(String value) { _ptr.scrolling = value; }

  String get src() { return _ptr.src; }

  void set src(String value) { _ptr.src = value; }

  String get width() { return _ptr.width; }

  void set width(String value) { _ptr.width = value; }

  String get typeName() { return "IFrameElement"; }
}
