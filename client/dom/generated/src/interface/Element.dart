// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Element extends Node, NodeSelector, ElementTraversal {

  int get childElementCount();

  int get clientHeight();

  int get clientLeft();

  int get clientTop();

  int get clientWidth();

  Element get firstElementChild();

  Element get lastElementChild();

  Element get nextElementSibling();

  int get offsetHeight();

  int get offsetLeft();

  Element get offsetParent();

  int get offsetTop();

  int get offsetWidth();

  EventListener get onabort();

  void set onabort(EventListener value);

  EventListener get onbeforecopy();

  void set onbeforecopy(EventListener value);

  EventListener get onbeforecut();

  void set onbeforecut(EventListener value);

  EventListener get onbeforepaste();

  void set onbeforepaste(EventListener value);

  EventListener get onblur();

  void set onblur(EventListener value);

  EventListener get onchange();

  void set onchange(EventListener value);

  EventListener get onclick();

  void set onclick(EventListener value);

  EventListener get oncontextmenu();

  void set oncontextmenu(EventListener value);

  EventListener get oncopy();

  void set oncopy(EventListener value);

  EventListener get oncut();

  void set oncut(EventListener value);

  EventListener get ondblclick();

  void set ondblclick(EventListener value);

  EventListener get ondrag();

  void set ondrag(EventListener value);

  EventListener get ondragend();

  void set ondragend(EventListener value);

  EventListener get ondragenter();

  void set ondragenter(EventListener value);

  EventListener get ondragleave();

  void set ondragleave(EventListener value);

  EventListener get ondragover();

  void set ondragover(EventListener value);

  EventListener get ondragstart();

  void set ondragstart(EventListener value);

  EventListener get ondrop();

  void set ondrop(EventListener value);

  EventListener get onerror();

  void set onerror(EventListener value);

  EventListener get onfocus();

  void set onfocus(EventListener value);

  EventListener get oninput();

  void set oninput(EventListener value);

  EventListener get oninvalid();

  void set oninvalid(EventListener value);

  EventListener get onkeydown();

  void set onkeydown(EventListener value);

  EventListener get onkeypress();

  void set onkeypress(EventListener value);

  EventListener get onkeyup();

  void set onkeyup(EventListener value);

  EventListener get onload();

  void set onload(EventListener value);

  EventListener get onmousedown();

  void set onmousedown(EventListener value);

  EventListener get onmousemove();

  void set onmousemove(EventListener value);

  EventListener get onmouseout();

  void set onmouseout(EventListener value);

  EventListener get onmouseover();

  void set onmouseover(EventListener value);

  EventListener get onmouseup();

  void set onmouseup(EventListener value);

  EventListener get onmousewheel();

  void set onmousewheel(EventListener value);

  EventListener get onpaste();

  void set onpaste(EventListener value);

  EventListener get onreset();

  void set onreset(EventListener value);

  EventListener get onscroll();

  void set onscroll(EventListener value);

  EventListener get onsearch();

  void set onsearch(EventListener value);

  EventListener get onselect();

  void set onselect(EventListener value);

  EventListener get onselectstart();

  void set onselectstart(EventListener value);

  EventListener get onsubmit();

  void set onsubmit(EventListener value);

  EventListener get ontouchcancel();

  void set ontouchcancel(EventListener value);

  EventListener get ontouchend();

  void set ontouchend(EventListener value);

  EventListener get ontouchmove();

  void set ontouchmove(EventListener value);

  EventListener get ontouchstart();

  void set ontouchstart(EventListener value);

  EventListener get onwebkitfullscreenchange();

  void set onwebkitfullscreenchange(EventListener value);

  Element get previousElementSibling();

  int get scrollHeight();

  int get scrollLeft();

  void set scrollLeft(int value);

  int get scrollTop();

  void set scrollTop(int value);

  int get scrollWidth();

  CSSStyleDeclaration get style();

  String get tagName();

  void blur();

  void focus();

  String getAttribute([String name]);

  String getAttributeNS([String namespaceURI, String localName]);

  Attr getAttributeNode([String name]);

  Attr getAttributeNodeNS([String namespaceURI, String localName]);

  ClientRect getBoundingClientRect();

  ClientRectList getClientRects();

  NodeList getElementsByClassName([String name]);

  NodeList getElementsByTagName([String name]);

  NodeList getElementsByTagNameNS([String namespaceURI, String localName]);

  bool hasAttribute(String name);

  bool hasAttributeNS([String namespaceURI, String localName]);

  Element querySelector(String selectors);

  NodeList querySelectorAll(String selectors);

  void removeAttribute([String name]);

  void removeAttributeNS(String namespaceURI, String localName);

  Attr removeAttributeNode([Attr oldAttr]);

  void scrollByLines([int lines]);

  void scrollByPages([int pages]);

  void scrollIntoView([bool alignWithTop]);

  void scrollIntoViewIfNeeded([bool centerIfNeeded]);

  void setAttribute([String name, String value]);

  void setAttributeNS([String namespaceURI, String qualifiedName, String value]);

  Attr setAttributeNode([Attr newAttr]);

  Attr setAttributeNodeNS([Attr newAttr]);

  bool webkitMatchesSelector([String selectors]);
}
