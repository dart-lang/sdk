// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface ElementList extends List<Element> {
  // TODO(jacobr): add element batch manipulation methods.
  Element get first();
  // TODO(jacobr): add insertAt
}

class DeferredElementRect {
  // TODO(jacobr)
}

class ScrollOptions {
  final int lines;
  final int pages;
  final bool center;

  ScrollOptions([this.lines = 0, this.pages = 0, this.center = false]);
}

interface ElementEvents extends Events {
  EventListenerList get abort();
  EventListenerList get beforeCopy();
  EventListenerList get beforeCut();
  EventListenerList get beforePaste();
  EventListenerList get blur();
  EventListenerList get change();
  EventListenerList get click();
  EventListenerList get contextMenu();
  EventListenerList get copy();
  EventListenerList get cut();
  EventListenerList get dblClick();
  EventListenerList get drag();
  EventListenerList get dragEnd();
  EventListenerList get dragEnter();
  EventListenerList get dragLeave();
  EventListenerList get dragOver();
  EventListenerList get dragStart();
  EventListenerList get drop();
  EventListenerList get error();
  EventListenerList get focus();
  EventListenerList get input();
  EventListenerList get invalid();
  EventListenerList get keyDown();
  EventListenerList get keyPress();
  EventListenerList get keyUp();
  EventListenerList get load();
  EventListenerList get mouseDown();
  EventListenerList get mouseMove();
  EventListenerList get mouseOut();
  EventListenerList get mouseOver();
  EventListenerList get mouseUp();
  EventListenerList get mouseWheel();
  EventListenerList get paste();
  EventListenerList get reset();
  EventListenerList get scroll();
  EventListenerList get search();
  EventListenerList get select();
  EventListenerList get selectStart();
  EventListenerList get submit();
  EventListenerList get touchCancel();
  EventListenerList get touchEnd();
  EventListenerList get touchLeave();
  EventListenerList get touchMove();
  EventListenerList get touchStart();
  EventListenerList get transitionEnd();
  EventListenerList get fullscreenChange();
}

interface Element extends Node /*, common.NodeSelector, common.ElementTraversal */
    factory ElementWrappingImplementation {

  Element.html(String html);
  Element.tag(String tag);

  Map<String, String> get attributes();
  void set attributes(Map<String, String> value);

  ElementList get elements();

  // TODO: The type of value should be Collection<Element>. See http://b/5392897
  void set elements(value);

  _CssClassSet get classes();

  // TODO: The type of value should be Collection<String>. See http://b/5392897
  void set classes(value);

  Map<String, String> get dataAttributes();
  void set dataAttributes(Map<String, String> value);

  int get clientHeight();

  int get clientLeft();

  int get clientTop();

  int get clientWidth();

  String get contentEditable();

  void set contentEditable(String value);

  String get dir();

  void set dir(String value);

  bool get draggable();

  void set draggable(bool value);

  Element get firstElementChild();

  bool get hidden();

  void set hidden(bool value);

  String get id();

  void set id(String value);

  String get innerHTML();

  void set innerHTML(String value);

  bool get isContentEditable();

  String get lang();

  void set lang(String value);

  Element get lastElementChild();

  Element get nextElementSibling();

  int get offsetHeight();

  int get offsetLeft();

  Element get offsetParent();

  int get offsetTop();

  int get offsetWidth();

  String get outerHTML();

  Element get previousElementSibling();

  int get scrollHeight();

  int get scrollLeft();

  void set scrollLeft(int value);

  int get scrollTop();

  void set scrollTop(int value);

  int get scrollWidth();

  bool get spellcheck();

  void set spellcheck(bool value);

  CSSStyleDeclaration get style();

  int get tabIndex();

  void set tabIndex(int value);

  String get tagName();

  String get title();

  void set title(String value);

  String get webkitdropzone();

  void set webkitdropzone(String value);

  void blur();

  void focus();

  ClientRect getBoundingClientRect();

  ClientRectList getClientRects();

  Element insertAdjacentElement([String where, Element element]);

  void insertAdjacentHTML([String position_OR_where, String text]);

  void insertAdjacentText([String where, String text]);

  Element query(String selectors);

  ElementList queryAll(String selectors);

  Element get parent();

  void scrollByLines([int lines]);

  void scrollByPages([int pages]);

  void scrollIntoView([bool centerIfNeeded]);

  bool matchesSelector([String selectors]);

  ElementEvents get on();
}
