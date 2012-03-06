// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jacobr): use _Lists.dart to remove some of the duplicated
// functionality.
class _ChildrenElementList implements ElementList {
  // Raw Element.
  final _ElementImpl _element;
  final _HTMLCollectionImpl _childElements;

  _ChildrenElementList._wrap(_ElementImpl element)
    : _childElements = element._children,
      _element = element;

  List<Element> _toList() {
    final output = new List(_childElements.length);
    for (int i = 0, len = _childElements.length; i < len; i++) {
      output[i] = _childElements[i];
    }
    return output;
  }

  _ElementImpl get first() {
    return _element._firstElementChild;
  }

  void forEach(void f(Element element)) {
    for (_ElementImpl element in _childElements) {
      f(element);
    }
  }

  ElementList filter(bool f(Element element)) {
    final output = <Element>[];
    forEach((Element element) {
      if (f(element)) {
        output.add(element);
      }
    });
    return new _FrozenElementList._wrap(output);
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

  Collection map(f(Element element)) {
    final out = [];
    for (Element el in this) {
      out.add(f(el));
    }
    return out;
  }

  bool isEmpty() {
    return _element._firstElementChild == null;
  }

  int get length() {
    return _childElements.length;
  }

  _ElementImpl operator [](int index) {
    return _childElements[index];
  }

  void operator []=(int index, _ElementImpl value) {
    _element._replaceChild(value, _childElements[index]);
  }

   void set length(int newLength) {
     // TODO(jacobr): remove children when length is reduced.
     throw const UnsupportedOperationException('');
   }

  Element add(_ElementImpl value) {
    _element._appendChild(value);
    return value;
  }

  Element addLast(_ElementImpl value) => add(value);

  Iterator<Element> iterator() => _toList().iterator();

  void addAll(Collection<_ElementImpl> collection) {
    for (_ElementImpl element in collection) {
      _element._appendChild(element);
    }
  }

  void sort(int compare(Element a, Element b)) {
    throw const UnsupportedOperationException('TODO(jacobr): should we impl?');
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw 'Not impl yet. todo(jacobr)';
  }

  void setRange(int start, int length, List from, [int startFrom = 0]) {
    throw const NotImplementedException();
  }

  void removeRange(int start, int length) {
    throw const NotImplementedException();
  }

  void insertRange(int start, int length, [initialValue = null]) {
    throw const NotImplementedException();
  }

  List getRange(int start, int length) =>
    new _FrozenElementList._wrap(_Lists.getRange(this, start, length,
        <Element>[]));

  int indexOf(Element element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(Element element, [int start = null]) {
    if (start === null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  void clear() {
    // It is unclear if we want to keep non element nodes?
    _element.text = '';
  }

  Element removeLast() {
    final last = this.last();
    if (last != null) {
      _element._removeChild(last);
    }
    return last;
  }

  Element last() {
    return _element.lastElementChild;
  }
}

// TODO(jacobr): this is an inefficient implementation but it is hard to see
// a better option given that we cannot quite force NodeList to be an
// ElementList as there are valid cases where a NodeList JavaScript object
// contains Node objects that are not Elements.
class _FrozenElementList implements ElementList {
  final List<Node> _nodeList;

  _FrozenElementList._wrap(this._nodeList);

  Element get first() {
    return _nodeList[0];
  }

  void forEach(void f(Element element)) {
    for (Element el in this) {
      f(el);
    }
  }

  Collection map(f(Element element)) {
    final out = [];
    for (Element el in this) {
      out.add(f(el));
    }
    return out;
  }

  ElementList filter(bool f(Element element)) {
    final out = new _ElementList([]);
    for (Element el in this) {
      if (f(el)) out.add(el);
    }
    return out;
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

  bool isEmpty() => _nodeList.isEmpty();

  int get length() => _nodeList.length;

  Element operator [](int index) => _nodeList[index];

  void operator []=(int index, Element value) {
    throw const UnsupportedOperationException('');
  }

  void set length(int newLength) {
    _nodeList.length = newLength;
  }

  void add(Element value) {
    throw const UnsupportedOperationException('');
  }

  void addLast(Element value) {
    throw const UnsupportedOperationException('');
  }

  Iterator<Element> iterator() => new _FrozenElementListIterator(this);

  void addAll(Collection<Element> collection) {
    throw const UnsupportedOperationException('');
  }

  void sort(int compare(Element a, Element b)) {
    throw const UnsupportedOperationException('');
  }

  void setRange(int start, int length, List from, [int startFrom = 0]) {
    throw const UnsupportedOperationException('');
  }

  void removeRange(int start, int length) {
    throw const UnsupportedOperationException('');
  }

  void insertRange(int start, int length, [initialValue = null]) {
    throw const UnsupportedOperationException('');
  }

  ElementList getRange(int start, int length) =>
    new _FrozenElementList._wrap(_nodeList.getRange(start, length));

  int indexOf(Element element, [int start = 0]) =>
    _nodeList.indexOf(element, start);

  int lastIndexOf(Element element, [int start = null]) =>
    _nodeList.lastIndexOf(element, start);

  void clear() {
    throw const UnsupportedOperationException('');
  }

  Element removeLast() {
    throw const UnsupportedOperationException('');
  }

  Element last() => _nodeList.last();
}

class _FrozenElementListIterator implements Iterator<Element> {
  final _FrozenElementList _list;
  int _index = 0;

  _FrozenElementListIterator(this._list);

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

class _ElementList extends _ListWrapper<Element> implements ElementList {
  _ElementList(List<Element> list) : super(list);

  ElementList filter(bool f(Element element)) =>
    new _ElementList(super.filter(f));

  ElementList getRange(int start, int length) =>
    new _ElementList(super.getRange(start, length));
}

class ElementAttributeMap implements Map<String, String> {

  final _ElementImpl _element;

  ElementAttributeMap._wrap(this._element);

  bool containsValue(String value) {
    final attributes = _element._attributes;
    for (int i = 0, len = attributes.length; i < len; i++) {
      if(value == attributes[i].value) {
        return true;
      }
    }
    return false;
  }

  bool containsKey(String key) {
    return _element._hasAttribute(key);
  }

  String operator [](String key) {
    return _element._getAttribute(key);
  }

  void operator []=(String key, String value) {
    _element._setAttribute(key, value);
  }

  String putIfAbsent(String key, String ifAbsent()) {
    if (!containsKey(key)) {
      this[key] = ifAbsent();
    }
  }

  String remove(String key) {
    _element._removeAttribute(key);
  }

  void clear() {
    final attributes = _element._attributes;
    for (int i = attributes.length - 1; i >= 0; i--) {
      remove(attributes[i].name);
    }
  }

  void forEach(void f(String key, String value)) {
    final attributes = _element._attributes;
    for (int i = 0, len = attributes.length; i < len; i++) {
      final item = attributes[i];
      f(item.name, item.value);
    }
  }

  Collection<String> getKeys() {
    // TODO(jacobr): generate a lazy collection instead.
    final attributes = _element._attributes;
    final keys = new List<String>(attributes.length);
    for (int i = 0, len = attributes.length; i < len; i++) {
      keys[i] = attributes[i].name;
    }
    return keys;
  }

  Collection<String> getValues() {
    // TODO(jacobr): generate a lazy collection instead.
    final attributes = _element._attributes;
    final values = new List<String>(attributes.length);
    for (int i = 0, len = attributes.length; i < len; i++) {
      values[i] = attributes[i].value;
    }
    return values;
  }

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length() {
    return _element._attributes.length;
  }

  /**
   * Returns true if there is no {key, value} pair in the map.
   */
  bool isEmpty() {
    return length == 0;
  }
}

class _SimpleClientRect implements ClientRect {
  final num left;
  final num top;
  final num width;
  final num height;
  num get right() => left + width;
  num get bottom() => top + height;

  const _SimpleClientRect(this.left, this.top, this.width, this.height);

  bool operator ==(ClientRect other) {
    return other !== null && left == other.left && top == other.top
        && width == other.width && height == other.height;
  }

  String toString() => "($left, $top, $width, $height)";
}

// TODO(jacobr): we cannot currently be lazy about calculating the client
// rects as we must perform all measurement queries at a safe point to avoid
// triggering unneeded layouts.
/**
 * All your element measurement needs in one place
 * @domName none
 */
class _ElementRectImpl implements ElementRect {
  final ClientRect client;
  final ClientRect offset;
  final ClientRect scroll;

  // TODO(jacobr): should we move these outside of ElementRect to avoid the
  // overhead of computing them every time even though they are rarely used.
  final _ClientRectImpl _boundingClientRect; 
  final _ClientRectListImpl _clientRects;

  _ElementRectImpl(_ElementImpl element) :
    client = new _SimpleClientRect(element._clientLeft,
                                  element._clientTop,
                                  element._clientWidth, 
                                  element._clientHeight), 
    offset = new _SimpleClientRect(element._offsetLeft,
                                  element._offsetTop,
                                  element._offsetWidth,
                                  element._offsetHeight),
    scroll = new _SimpleClientRect(element._scrollLeft,
                                  element._scrollTop,
                                  element._scrollWidth,
                                  element._scrollHeight),
    _boundingClientRect = element._getBoundingClientRect(),
    _clientRects = element._getClientRects();

  _ClientRectImpl get bounding() => _boundingClientRect;

  // TODO(jacobr): cleanup.
  List<ClientRect> get clientRects() {
    final out = new List(_clientRects.length);
    for (num i = 0; i < _clientRects.length; i++) {
      out[i] = _clientRects.item(i);
    }
    return out;
  }
}

class _ElementImpl extends _NodeImpl implements Element {

  // TODO(jacobr): caching these may hurt performance.
  ElementAttributeMap _elementAttributeMap;
  _CssClassSet _cssClassSet;
  _DataAttributeMap _dataAttributes;

  /**
   * @domName Element.hasAttribute, Element.getAttribute, Element.setAttribute,
   *   Element.removeAttribute
   */
  Map<String, String> get attributes() {
    if (_elementAttributeMap === null) {
      _elementAttributeMap = new ElementAttributeMap._wrap(this);
    }
    return _elementAttributeMap;
  }

  void set attributes(Map<String, String> value) {
    Map<String, String> attributes = this.attributes;
    attributes.clear();
    for (String key in value.getKeys()) {
      attributes[key] = value[key];
    }
  }

  void set elements(Collection<Element> value) {
    final elements = this.elements;
    elements.clear();
    elements.addAll(value);
  }

  ElementList get elements() => new _ChildrenElementList._wrap(this);

  ElementList queryAll(String selectors) =>
    new _FrozenElementList._wrap(_querySelectorAll(selectors));

  Set<String> get classes() {
    if (_cssClassSet === null) {
      _cssClassSet = new _CssClassSet(this);
    }
    return _cssClassSet;
  }

  void set classes(Collection<String> value) {
    _CssClassSet classSet = classes;
    classSet.clear();
    classSet.addAll(value);
  }

  Map<String, String> get dataAttributes() {
    if (_dataAttributes === null) {
      _dataAttributes = new _DataAttributeMap(attributes);
    }
    return _dataAttributes;
  }

  void set dataAttributes(Map<String, String> value) {
    Map<String, String> dataAttributes = this.dataAttributes;
    dataAttributes.clear();
    for (String key in value.getKeys()) {
      dataAttributes[key] = value[key];
    }
  }

  Future<ElementRect> get rect() {
    return _createMeasurementFuture(
        () => new _ElementRectImpl(this),
        new Completer<ElementRect>());
  }

  Future<CSSStyleDeclaration> get computedStyle() {
     // TODO(jacobr): last param should be null, see b/5045788
     return getComputedStyle('');
  }

  Future<CSSStyleDeclaration> getComputedStyle(String pseudoElement) {
    return _createMeasurementFuture(() =>
            window._getComputedStyle(this, pseudoElement),
        new Completer<CSSStyleDeclaration>());
  }
  _ElementImpl._wrap(ptr) : super._wrap(ptr);

  int get _childElementCount() => _wrap(_ptr.childElementCount);

  HTMLCollection get _children() => _wrap(_ptr.children);

  DOMTokenList get classList() => _wrap(_ptr.classList);

  String get _className() => _wrap(_ptr.className);

  void set _className(String value) { _ptr.className = _unwrap(value); }

  int get _clientHeight() => _wrap(_ptr.clientHeight);

  int get _clientLeft() => _wrap(_ptr.clientLeft);

  int get _clientTop() => _wrap(_ptr.clientTop);

  int get _clientWidth() => _wrap(_ptr.clientWidth);

  String get contentEditable() => _wrap(_ptr.contentEditable);

  void set contentEditable(String value) { _ptr.contentEditable = _unwrap(value); }

  String get dir() => _wrap(_ptr.dir);

  void set dir(String value) { _ptr.dir = _unwrap(value); }

  bool get draggable() => _wrap(_ptr.draggable);

  void set draggable(bool value) { _ptr.draggable = _unwrap(value); }

  Element get _firstElementChild() => _wrap(_ptr.firstElementChild);

  bool get hidden() => _wrap(_ptr.hidden);

  void set hidden(bool value) { _ptr.hidden = _unwrap(value); }

  String get id() => _wrap(_ptr.id);

  void set id(String value) { _ptr.id = _unwrap(value); }

  String get innerHTML() => _wrap(_ptr.innerHTML);

  void set innerHTML(String value) { _ptr.innerHTML = _unwrap(value); }

  bool get isContentEditable() => _wrap(_ptr.isContentEditable);

  String get lang() => _wrap(_ptr.lang);

  void set lang(String value) { _ptr.lang = _unwrap(value); }

  Element get lastElementChild() => _wrap(_ptr.lastElementChild);

  Element get nextElementSibling() => _wrap(_ptr.nextElementSibling);

  int get _offsetHeight() => _wrap(_ptr.offsetHeight);

  int get _offsetLeft() => _wrap(_ptr.offsetLeft);

  Element get offsetParent() => _wrap(_ptr.offsetParent);

  int get _offsetTop() => _wrap(_ptr.offsetTop);

  int get _offsetWidth() => _wrap(_ptr.offsetWidth);

  String get outerHTML() => _wrap(_ptr.outerHTML);

  Element get previousElementSibling() => _wrap(_ptr.previousElementSibling);

  int get _scrollHeight() => _wrap(_ptr.scrollHeight);

  int get _scrollLeft() => _wrap(_ptr.scrollLeft);

  void set _scrollLeft(int value) { _ptr.scrollLeft = _unwrap(value); }

  int get _scrollTop() => _wrap(_ptr.scrollTop);

  void set _scrollTop(int value) { _ptr.scrollTop = _unwrap(value); }

  int get _scrollWidth() => _wrap(_ptr.scrollWidth);

  bool get spellcheck() => _wrap(_ptr.spellcheck);

  void set spellcheck(bool value) { _ptr.spellcheck = _unwrap(value); }

  CSSStyleDeclaration get style() => _wrap(_ptr.style);

  int get tabIndex() => _wrap(_ptr.tabIndex);

  void set tabIndex(int value) { _ptr.tabIndex = _unwrap(value); }

  String get tagName() => _wrap(_ptr.tagName);

  String get title() => _wrap(_ptr.title);

  void set title(String value) { _ptr.title = _unwrap(value); }

  String get webkitRegionOverflow() => _wrap(_ptr.webkitRegionOverflow);

  String get webkitdropzone() => _wrap(_ptr.webkitdropzone);

  void set webkitdropzone(String value) { _ptr.webkitdropzone = _unwrap(value); }

  _ElementEventsImpl get on() {
    if (_on == null) _on = new _ElementEventsImpl(this);
    return _on;
  }

  void blur() {
    _ptr.blur();
    return;
  }

  void click() {
    _ptr.click();
    return;
  }

  void focus() {
    _ptr.focus();
    return;
  }

  String _getAttribute(String name) {
    return _wrap(_ptr.getAttribute(_unwrap(name)));
  }

  ClientRect _getBoundingClientRect() {
    return _wrap(_ptr.getBoundingClientRect());
  }

  ClientRectList _getClientRects() {
    return _wrap(_ptr.getClientRects());
  }

  bool _hasAttribute(String name) {
    return _wrap(_ptr.hasAttribute(_unwrap(name)));
  }

  Element insertAdjacentElement(String where, Element element) {
    return _wrap(_ptr.insertAdjacentElement(_unwrap(where), _unwrap(element)));
  }

  void insertAdjacentHTML(String where, String html) {
    _ptr.insertAdjacentHTML(_unwrap(where), _unwrap(html));
    return;
  }

  void insertAdjacentText(String where, String text) {
    _ptr.insertAdjacentText(_unwrap(where), _unwrap(text));
    return;
  }

  Element query(String selectors) {
    return _wrap(_ptr.querySelector(_unwrap(selectors)));
  }

  NodeList _querySelectorAll(String selectors) {
    return _wrap(_ptr.querySelectorAll(_unwrap(selectors)));
  }

  void _removeAttribute(String name) {
    _ptr.removeAttribute(_unwrap(name));
    return;
  }

  void scrollByLines(int lines) {
    _ptr.scrollByLines(_unwrap(lines));
    return;
  }

  void scrollByPages(int pages) {
    _ptr.scrollByPages(_unwrap(pages));
    return;
  }

  void scrollIntoView([bool centerIfNeeded = null]) {
    if (centerIfNeeded === null) {
      _ptr.scrollIntoViewIfNeeded();
      return;
    } else {
      _ptr.scrollIntoViewIfNeeded(_unwrap(centerIfNeeded));
      return;
    }
  }

  void _setAttribute(String name, String value) {
    _ptr.setAttribute(_unwrap(name), _unwrap(value));
    return;
  }

  bool matchesSelector(String selectors) {
    return _wrap(_ptr.webkitMatchesSelector(_unwrap(selectors)));
  }

  void webkitRequestFullScreen(int flags) {
    _ptr.webkitRequestFullScreen(_unwrap(flags));
    return;
  }

}

class _ElementEventsImpl extends _EventsImpl implements ElementEvents {
  _ElementEventsImpl(_ptr) : super(_ptr);

  EventListenerList get abort() => _get('abort');

  EventListenerList get beforeCopy() => _get('beforecopy');

  EventListenerList get beforeCut() => _get('beforecut');

  EventListenerList get beforePaste() => _get('beforepaste');

  EventListenerList get blur() => _get('blur');

  EventListenerList get change() => _get('change');

  EventListenerList get click() => _get('click');

  EventListenerList get contextMenu() => _get('contextmenu');

  EventListenerList get copy() => _get('copy');

  EventListenerList get cut() => _get('cut');

  EventListenerList get doubleClick() => _get('dblclick');

  EventListenerList get drag() => _get('drag');

  EventListenerList get dragEnd() => _get('dragend');

  EventListenerList get dragEnter() => _get('dragenter');

  EventListenerList get dragLeave() => _get('dragleave');

  EventListenerList get dragOver() => _get('dragover');

  EventListenerList get dragStart() => _get('dragstart');

  EventListenerList get drop() => _get('drop');

  EventListenerList get error() => _get('error');

  EventListenerList get focus() => _get('focus');

  EventListenerList get fullscreenChange() => _get('webkitfullscreenchange');

  EventListenerList get fullscreenError() => _get('webkitfullscreenerror');

  EventListenerList get input() => _get('input');

  EventListenerList get invalid() => _get('invalid');

  EventListenerList get keyDown() => _get('keydown');

  EventListenerList get keyPress() => _get('keypress');

  EventListenerList get keyUp() => _get('keyup');

  EventListenerList get load() => _get('load');

  EventListenerList get mouseDown() => _get('mousedown');

  EventListenerList get mouseMove() => _get('mousemove');

  EventListenerList get mouseOut() => _get('mouseout');

  EventListenerList get mouseOver() => _get('mouseover');

  EventListenerList get mouseUp() => _get('mouseup');

  EventListenerList get mouseWheel() => _get('mousewheel');

  EventListenerList get paste() => _get('paste');

  EventListenerList get reset() => _get('reset');

  EventListenerList get scroll() => _get('scroll');

  EventListenerList get search() => _get('search');

  EventListenerList get select() => _get('select');

  EventListenerList get selectStart() => _get('selectstart');

  EventListenerList get submit() => _get('submit');

  EventListenerList get touchCancel() => _get('touchcancel');

  EventListenerList get touchEnd() => _get('touchend');

  EventListenerList get touchLeave() => _get('touchleave');

  EventListenerList get touchMove() => _get('touchmove');

  EventListenerList get touchStart() => _get('touchstart');

  EventListenerList get transitionEnd() => _get('webkitTransitionEnd');
}
