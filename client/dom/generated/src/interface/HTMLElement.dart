// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLElement extends Element {

  HTMLCollection get children();

  DOMTokenList get classList();

  String get className();

  void set className(String value);

  String get contentEditable();

  void set contentEditable(String value);

  String get dir();

  void set dir(String value);

  bool get draggable();

  void set draggable(bool value);

  bool get hidden();

  void set hidden(bool value);

  String get id();

  void set id(String value);

  String get innerHTML();

  void set innerHTML(String value);

  String get innerText();

  void set innerText(String value);

  bool get isContentEditable();

  String get lang();

  void set lang(String value);

  String get outerHTML();

  void set outerHTML(String value);

  String get outerText();

  void set outerText(String value);

  bool get spellcheck();

  void set spellcheck(bool value);

  int get tabIndex();

  void set tabIndex(int value);

  String get title();

  void set title(String value);

  String get webkitdropzone();

  void set webkitdropzone(String value);

  Element insertAdjacentElement(String where, Element element);

  void insertAdjacentHTML(String where, String html);

  void insertAdjacentText(String where, String text);
}
