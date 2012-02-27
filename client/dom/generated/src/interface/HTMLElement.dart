// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface HTMLElement extends Element {

  String accessKey;

  final HTMLCollection children;

  final DOMTokenList classList;

  String className;

  String contentEditable;

  String dir;

  bool draggable;

  bool hidden;

  String id;

  String innerHTML;

  String innerText;

  final bool isContentEditable;

  String lang;

  String outerHTML;

  String outerText;

  bool spellcheck;

  int tabIndex;

  String title;

  bool translate;

  String webkitdropzone;

  void click();

  Element insertAdjacentElement(String where, Element element);

  void insertAdjacentHTML(String where, String html);

  void insertAdjacentText(String where, String text);
}
