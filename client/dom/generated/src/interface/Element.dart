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

  String getAttribute(String name = null);

  String getAttributeNS(String namespaceURI = null, String localName = null);

  Attr getAttributeNode(String name = null);

  Attr getAttributeNodeNS(String namespaceURI = null, String localName = null);

  ClientRect getBoundingClientRect();

  ClientRectList getClientRects();

  NodeList getElementsByClassName(String name = null);

  NodeList getElementsByTagName(String name = null);

  NodeList getElementsByTagNameNS(String namespaceURI = null, String localName = null);

  bool hasAttribute(String name);

  bool hasAttributeNS(String namespaceURI = null, String localName = null);

  Element querySelector(String selectors);

  NodeList querySelectorAll(String selectors);

  void removeAttribute(String name = null);

  void removeAttributeNS(String namespaceURI, String localName);

  Attr removeAttributeNode(Attr oldAttr = null);

  void scrollByLines(int lines = null);

  void scrollByPages(int pages = null);

  void scrollIntoView(bool alignWithTop = null);

  void scrollIntoViewIfNeeded(bool centerIfNeeded = null);

  void setAttribute(String name = null, String value = null);

  void setAttributeNS(String namespaceURI = null, String qualifiedName = null, String value = null);

  Attr setAttributeNode(Attr newAttr = null);

  Attr setAttributeNodeNS(Attr newAttr = null);

  bool webkitMatchesSelector(String selectors = null);
}
