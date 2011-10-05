// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jacobr): use Lists.dart to remove some of the duplicated functionality.
class _ChildrenElementList implements ElementList {
  // Raw Element.
  final _element;
  final _childElements;

  _ChildrenElementList._wrap(var element)
    : _childElements = element.children,
      _element = element;

  List<Element> _toList() {
    final output = new List(_childElements.length);
    for (int i = 0, len = _childElements.length; i < len; i++) {
      output[i] = LevelDom.wrapElement(_childElements[i]);
    }
    return output;
  }

  Element get first() {
    return LevelDom.wrapElement(_element.firstElementChild);
  }

  void forEach(void f(Element element)) {
    for (var element in _childElements) {
      f(LevelDom.wrapElement(element));
    }
  }

  Collection<Element> filter(bool f(Element element)) {
    List<Element> output = new List<Element>();
    forEach((Element element) {
      if (f(element)) {
        output.add(element);
      }
    });
    return output;
  }

  bool every(bool f(Element element)) {
    for(Element element in this) {
      if (!f(element)) {
        return false;
      }
    };
    return true;
  }

  bool some(bool f(Element element)) {
    for(Element element in this) {
      if (f(element)) {
        return true;
      }
    };
    return false;
  }

  bool isEmpty() {
    return _element.firstElementChild !== null;
  }

  int get length() {
    return _childElements.length;
  }

  Element operator [](int index) {
    return LevelDom.wrapElement(_childElements[index]);
  }

  void operator []=(int index, Element value) {
    _element.replaceChild(LevelDom.unwrap(value), _childElements.item(index));
  }

   void set length(int newLength) {
     // TODO(jacobr): remove children when length is reduced.
     throw const UnsupportedOperationException('');
   }

  Element add(Element value) {
    _element.appendChild(LevelDom.unwrap(value));
    return value;
  }

  Element addLast(Element value) {
    _element.appendChild(LevelDom.unwrap(value));
    return value;
  }

  Iterator<Element> iterator() {
    return _toList().iterator();
  }

  void addAll(Collection<Element> collection) {
    for (Element element in collection) {
      _element.appendChild(LevelDom.unwrap(element));
    }
  }

  void sort(int compare(Element a, Element b)) {
    throw const UnsupportedOperationException('TODO(jacobr): should we impl?');
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw 'Not impl yet. todo(jacobr)';
  }

  int indexOf(Element element, int startIndex) {
    throw 'Not impl yet. todo(jacobr)';
  }

  int lastIndexOf(Element element, int startIndex) {
    throw 'Not impl yet. todo(jacobr)';
  }

  void clear() {
    throw 'Not impl yet. todo(jacobr)';
  }

  Element removeLast() {
    throw 'Not impl yet. todo(jacobr)';
  }

  Element last() {
    return LevelDom.wrapElement(_element.lastElementChild);
  }
}

class FrozenElementList implements ElementList {
  final _ptr;

  FrozenElementList._wrap(this._ptr);

  Element get first() {
    return this[0];
  }

  void forEach(void f(Element element)) {
    for (var element in _ptr) {
      f(LevelDom.wrapElement(element));
    }
  }

  Collection<Element> filter(bool f(Element element)) {
    throw 'Not impl yet. todo(jacobr)';
  }

  bool every(bool f(Element element)) {
    throw 'Not impl yet. todo(jacobr)';
  }

  bool some(bool f(Element element)) {
    throw 'Not impl yet. todo(jacobr)';
  }

  bool isEmpty() {
    return _ptr.length == 0;
  }

  int get length() {
    return _ptr.length;
  }

  Element operator [](int index) {
    return LevelDom.wrapElement(_ptr[index]);
  }

  void operator []=(int index, Element value) {
    throw const UnsupportedOperationException('');
  }

   void set length(int newLength) {
    throw const UnsupportedOperationException('');
   }

  void add(Element value) {
    throw const UnsupportedOperationException('');
  }


  void addLast(Element value) {
    throw const UnsupportedOperationException('');
  }

  Iterator<Element> iterator() => new FrozenElementListIterator(this);

  void addAll(Collection<Element> collection) {
    throw const UnsupportedOperationException('');
  }

  void sort(int compare(Element a, Element b)) {
    throw const UnsupportedOperationException('');
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw 'Not impl yet. todo(jacobr)';
  }

  int indexOf(Element element, int startIndex) {
    throw 'Not impl yet. todo(jacobr)';
  }

  int lastIndexOf(Element element, int startIndex) {
    throw 'Not impl yet. todo(jacobr)';
  }

  void clear() {
    throw 'Not impl yet. todo(jacobr)';
  }

  Element removeLast() {
    throw 'Not impl yet. todo(jacobr)';
  }

  Element last() {
    return this[length-1];
  }
}

class FrozenElementListIterator implements Iterator<Element> {
  final FrozenElementList _list;
  int _index = 0;

  FrozenElementListIterator(this._list);

  /**
   * Gets the next element in the iteration. Throws a
   * [NoMoreElementsException] if no element is left.
   */
  Element next() {
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }

    return _list[_index++];
  }

  /**
   * Returns whether the [Iterator] has elements left.
   */
  bool hasNext() => _index < _list.length;
}

class ElementAttributeMap implements Map<String, String> {

  final _element;

  ElementAttributeMap._wrap(this._element);

  bool containsValue(String value) {
    final attributes = _element.attributes;
    for (int i = 0, len = attributes.length; i < len; i++) {
      if(value == attributes.item(i).value) {
        return true;
      }
    }
    return false;
  }

  bool containsKey(String key) {
    return _element.hasAttribute(key);
  }

  String operator [](String key) {
    return _element.getAttribute(key);
  }

  void operator []=(String key, String value) {
    _element.setAttribute(key, value);
  }

  String putIfAbsent(String key, String ifAbsent()) {
    if (!containsKey(key)) {
      this[key] = ifAbsent();
    }
  }

  String remove(String key) {
    _element.removeAttribute(key);
  }

  void clear() {
    final attributes = _element.attributes;
    for (int i = 0, len = attributes.length; i < len; i++) {
      _element.removeAttribute(attributes[0].name);
    }
  }

  void forEach(void f(String key, String value)) {
    final attributes = _element.attributes;
    for (int i = 0, len = attributes.length; i < len; i++) {
      final item = attributes.item(i);
      f(item.name, item.value);
    }
  }

  Collection<String> getKeys() {
    // TODO(jacobr): generate a lazy collection instead.
    final attributes = _element.attributes;
    final keys = new List<String>(attributes.length);
    for (int i = 0, len = attributes.length; i < len; i++) {
      keys[i] = attributes.item(i).name;
    }
    return keys;
  }

  Collection<String> getValues() {
    // TODO(jacobr): generate a lazy collection instead.
    final attributes = _element.attributes;
    final values = new List<String>(attributes.length);
    for (int i = 0, len = attributes.length; i < len; i++) {
      values[i] = attributes.item(i).value;
    }
    return values;
  }

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length() {
    return _element.attributes.length;
  }

  /**
   * Returns true if there is no {key, value} pair in the map.
   */
  bool isEmpty() {
    return !_element.hasAttributes();
  }
}

class ElementEventsImplementation extends EventsImplementation implements ElementEvents {
  ElementEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get abort() => _get("abort");
  EventListenerList get beforeCopy() => _get("beforecopy");
  EventListenerList get beforeCut() => _get("beforecut");
  EventListenerList get beforePaste() => _get("beforepaste");
  EventListenerList get blur() => _get("blur");
  EventListenerList get change() => _get("change");
  EventListenerList get click() => _get("click");
  EventListenerList get contextMenu() => _get("contextmenu");
  EventListenerList get copy() => _get("copy");
  EventListenerList get cut() => _get("cut");
  EventListenerList get dblClick() => _get("dblclick");
  EventListenerList get drag() => _get("drag");
  EventListenerList get dragEnd() => _get("dragend");
  EventListenerList get dragEnter() => _get("dragenter");
  EventListenerList get dragLeave() => _get("dragleave");
  EventListenerList get dragOver() => _get("dragover");
  EventListenerList get dragStart() => _get("dragstart");
  EventListenerList get drop() => _get("drop");
  EventListenerList get error() => _get("error");
  EventListenerList get focus() => _get("focus");
  EventListenerList get input() => _get("input");
  EventListenerList get invalid() => _get("invalid");
  EventListenerList get keyDown() => _get("keydown");
  EventListenerList get keyPress() => _get("keypress");
  EventListenerList get keyUp() => _get("keyup");
  EventListenerList get load() => _get("load");
  EventListenerList get mouseDown() => _get("mousedown");
  EventListenerList get mouseMove() => _get("mousemove");
  EventListenerList get mouseOut() => _get("mouseout");
  EventListenerList get mouseOver() => _get("mouseover");
  EventListenerList get mouseUp() => _get("mouseup");
  EventListenerList get mouseWheel() => _get("mousewheel");
  EventListenerList get paste() => _get("paste");
  EventListenerList get reset() => _get("reset");
  EventListenerList get scroll() => _get("scroll");
  EventListenerList get search() => _get("search");
  EventListenerList get select() => _get("select");
  EventListenerList get selectStart() => _get("selectstart");
  EventListenerList get submit() => _get("submit");
  EventListenerList get touchCancel() => _get("touchcancel");
  EventListenerList get touchEnd() => _get("touchend");
  EventListenerList get touchLeave() => _get("touchleave");
  EventListenerList get touchMove() => _get("touchmove");
  EventListenerList get touchStart() => _get("touchstart");
  EventListenerList get transitionEnd() => _get("webkitTransitionEnd");
  EventListenerList get fullscreenChange() => _get("fullscreenchange");
}

class ElementWrappingImplementation extends NodeWrappingImplementation implements Element {
 
   factory ElementWrappingImplementation.html(String html) {
    final temp = _rawDocument.createElement('div');
    temp.innerHTML = html;

    if (temp.childElementCount != 1) {
      throw 'HTML had ${temp.childElementCount} top level elements but 1 expected';
    }

    return LevelDom.wrapElement(temp.firstElementChild);
  }

  factory ElementWrappingImplementation.tag(String tag) {
    return LevelDom.wrapElement(_rawDocument.createElement(tag));
  }

  ElementWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  _CssClassSet _cssClassSet;

  Map<String, String> get attributes() {
    return new ElementAttributeMap._wrap(_ptr);
  }

  ElementList get elements() => new _ChildrenElementList._wrap(_ptr);

  Set<String> get classes() {
    if (_cssClassSet === null) {
      _cssClassSet = new _CssClassSet(_ptr);
    }
    return _cssClassSet;
  }

  void set classes(Collection<String> value) {
    _CssClassSet classSet = classes;
    classSet.clear();
    classSet.addAll(value);
  }

  int get clientHeight() => _ptr.clientHeight;

  int get clientLeft() => _ptr.clientLeft;

  int get clientTop() => _ptr.clientTop;

  int get clientWidth() => _ptr.clientWidth;

  String get contentEditable() => _ptr.contentEditable;

  void set contentEditable(String value) { _ptr.contentEditable = value; }

  String get dir() => _ptr.dir;

  void set dir(String value) { _ptr.dir = value; }

  bool get draggable() => _ptr.draggable;

  void set draggable(bool value) { _ptr.draggable = value; }

  Element get firstElementChild() => LevelDom.wrapElement(_ptr.firstElementChild);

  bool get hidden() => _ptr.hidden;

  void set hidden(bool value) { _ptr.hidden = value; }

  String get id() => _ptr.id;

  void set id(String value) { _ptr.id = value; }

  String get innerHTML() => _ptr.innerHTML;

  void set innerHTML(String value) { _ptr.innerHTML = value; }

  bool get isContentEditable() => _ptr.isContentEditable;

  String get lang() => _ptr.lang;

  void set lang(String value) { _ptr.lang = value; }

  Element get lastElementChild() => LevelDom.wrapElement(_ptr.lastElementChild);

  Element get nextElementSibling() => LevelDom.wrapElement(_ptr.nextElementSibling);

  int get offsetHeight() => _ptr.offsetHeight;

  int get offsetLeft() => _ptr.offsetLeft;

  Element get offsetParent() => LevelDom.wrapElement(_ptr.offsetParent);

  int get offsetTop() => _ptr.offsetTop;

  int get offsetWidth() => _ptr.offsetWidth;

  String get outerHTML() => _ptr.outerHTML;

  Element get previousElementSibling() => LevelDom.wrapElement(_ptr.previousElementSibling);

  int get scrollHeight() => _ptr.scrollHeight;

  int get scrollLeft() => _ptr.scrollLeft;

  void set scrollLeft(int value) { _ptr.scrollLeft = value; }

  int get scrollTop() => _ptr.scrollTop;

  void set scrollTop(int value) { _ptr.scrollTop = value; }

  int get scrollWidth() => _ptr.scrollWidth;

  bool get spellcheck() => _ptr.spellcheck;

  void set spellcheck(bool value) { _ptr.spellcheck = value; }

  CSSStyleDeclaration get style() => LevelDom.wrapCSSStyleDeclaration(_ptr.style);

  int get tabIndex() => _ptr.tabIndex;

  void set tabIndex(int value) { _ptr.tabIndex = value; }

  String get tagName() => _ptr.tagName;

  String get title() => _ptr.title;

  void set title(String value) { _ptr.title = value; }

  String get webkitdropzone() => _ptr.webkitdropzone;

  void set webkitdropzone(String value) { _ptr.webkitdropzone = value; }

  void blur() {
    _ptr.blur();
  }

  bool contains(Node element) {
    return _ptr.contains(LevelDom.unwrap(element));
  }

  void focus() {
    _ptr.focus();
  }

  ClientRect getBoundingClientRect() {
    return LevelDom.wrapClientRect(_ptr.getBoundingClientRect());
  }

  ClientRectList getClientRects() {
    return LevelDom.wrapClientRectList(_ptr.getClientRects());
  }

  Element insertAdjacentElement([String where = null, Element element = null]) {
    return LevelDom.wrapElement(_ptr.insertAdjacentElement(where, LevelDom.unwrap(element)));
  }

  void insertAdjacentHTML([String position_OR_where = null, String text = null]) {
    _ptr.insertAdjacentHTML(position_OR_where, text);
  }

  void insertAdjacentText([String where = null, String text = null]) {
    _ptr.insertAdjacentText(where, text);
  }

  Element queryOne(String selectors) {
    // TODO(jacobr): scope fix.
    return LevelDom.wrapElement(_ptr.querySelector(selectors));
  }

  ElementList query(String selectors) {
    // TODO(jacobr): scope fix.
    return new FrozenElementList._wrap(_ptr.querySelectorAll(selectors));
  }

  void scrollByLines([int lines = null]) {
    _ptr.scrollByLines(lines);
  }

  void scrollByPages([int pages = null]) {
    _ptr.scrollByPages(pages);
  }

  void scrollIntoView([bool centerIfNeeded = null]) {
    _ptr.scrollIntoViewIfNeeded(centerIfNeeded);
  }

  bool matchesSelector([String selectors = null]) {
    return _ptr.webkitMatchesSelector(selectors);
  }

  ElementEvents get on() {
    if (_on === null) {
      _on = new ElementEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
