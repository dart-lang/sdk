// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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

  bool get _inDocument() => _nodeInDocument(_element);
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

  void forEach(void f(Element element)) => _toList().forEach(f);

  Collection map(f(Element element)) => _toList().map(f);

  Collection<Element> filter(bool f(Element element)) => _toList().filter(f);

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
    return _element.firstElementChild === null;
  }

  int get length() {
    return _childElements.length;
  }

  Element operator [](int index) {
    return LevelDom.wrapElement(_childElements[index]);
  }

  void operator []=(int index, Element value) {
    assert(!_inMeasurementFrame || (!_inDocument && !value._inDocument));
    _element.replaceChild(LevelDom.unwrap(value), _childElements.item(index));
  }

   void set length(int newLength) {
     // TODO(jacobr): remove children when length is reduced.
     throw const UnsupportedOperationException('');
   }

  Element add(Element value) {
    assert(!_inMeasurementFrame || (!_inDocument && !value._inDocument));
    _element.appendChild(LevelDom.unwrap(value));
    return value;
  }

  Element addLast(Element value) => add(value);

  Iterator<Element> iterator() => _toList().iterator();

  void addAll(Collection<Element> collection) {
    assert(!_inMeasurementFrame || !_inDocument);
    for (Element element in collection) {
      assert(!_inMeasurementFrame || !element._inDocument);
      _element.appendChild(LevelDom.unwrap(element));
    }
  }

  void sort(int compare(Element a, Element b)) {
    throw const UnsupportedOperationException('TODO(jacobr): should we impl?');
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw 'Not impl yet. todo(jacobr)';
  }

  void setRange(int start, int length, List from, [int startFrom = 0]) =>
    Lists.setRange(this, start, length, from, startFrom);

  void removeRange(int start, int length) =>
    Lists.removeRange(this, start, length, (i) => this[i].remove());

  void insertRange(int start, int length, [initialValue = null]) {
    throw const NotImplementedException();
  }

  List getRange(int start, int length) => Lists.getRange(this, start, length);

  int indexOf(Element element, [int start = 0]) {
    return Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(Element element, [int start = null]) {
    if (start === null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  void clear() {
    assert(!_inMeasurementFrame || !_inDocument);
    // It is unclear if we want to keep non element nodes?
    _element.textContent = '';
  }

  Element removeLast() {
    assert(!_inMeasurementFrame || !_inDocument);
    final last = this.last();
    if (last != null) {
      _element.removeChild(LevelDom.unwrap(last));
    }
    return last;
  }

  Element last() {
    return LevelDom.wrapElement(_element.lastElementChild);
  }
}

class FrozenElementList implements ElementList {
  final _ptr;
  List<Element> _list;

  FrozenElementList._wrap(this._ptr);

  List<Element> _toList() {
    if (_list == null) {
      _list = new List(_ptr.length);
      for (int i = 0, len = _ptr.length; i < len; i++) {
        _list[i] = LevelDom.wrapElement(_ptr[i]);
      }
    }
    return _list;
  }

  Element get first() {
    return this[0];
  }

  void forEach(void f(Element element)) => _toList().forEach(f);

  Collection map(f(Element element)) => _toList().map(f);

  Collection<Element> filter(bool f(Element element)) => _toList().filter(f);

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

  void setRange(int start, int length, List from, [int startFrom = 0]) {
    throw const UnsupportedOperationException('');
  }

  void removeRange(int start, int length) {
    throw const UnsupportedOperationException('');
  }

  void insertRange(int start, int length, [initialValue = null]) {
    throw const UnsupportedOperationException('');
  }

  List getRange(int start, int length) => Lists.getRange(this, start, length);

  int indexOf(Element element, [int start = 0]) =>
    Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Element element, [int start = null]) {
    if (start === null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  void clear() {
    throw const UnsupportedOperationException('');
  }

  Element removeLast() {
    throw const UnsupportedOperationException('');
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
    assert(!_inMeasurementFrame || !_nodeInDocument(_element));
    _element.removeAttribute(key);
  }

  void clear() {
    assert(!_inMeasurementFrame || !_nodeInDocument(_element));
    final attributes = _element.attributes;
    for (int i = attributes.length - 1; i >= 0; i--) {
      _element.removeAttribute(attributes.item(i).name);
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
  EventListenerList get fullscreenChange() => _get("webkitfullscreenchange");
}

class SimpleClientRect implements ClientRect {
  final num left;
  final num top;
  final num width;
  final num height;
  num get right() => left + width;
  num get bottom() => top + height;

  const SimpleClientRect(this.left, this.top, this.width, this.height);

  bool operator ==(ClientRect other) {
    return other !== null && left == other.left && top == other.top
        && width == other.width && height == other.height;
  }

  String toString() => "($left, $top, $width, $height)";
}

/**
 * All your element measurement needs in one place.
 * All members of this class can only be cassed when inside a measurement
 * frame or when the element is not attached to the DOM.
 * @domName none
 */
class ElementRectWrappingImplementation implements ElementRect {
  final dom.HTMLElement _element;

  ElementRectWrappingImplementation(this._element);

  ClientRect get client() {
    assert(window.inMeasurementFrame || !_nodeInDocument(_element));
    return new SimpleClientRect(_element.clientLeft,
                                _element.clientTop,
                                _element.clientWidth, 
                                _element.clientHeight);
  }
  
  ClientRect get offset() {
    assert(window.inMeasurementFrame || !_nodeInDocument(_element));
    return new SimpleClientRect(_element.offsetLeft,
                                _element.offsetTop,
                                _element.offsetWidth,
                                _element.offsetHeight);
  }

  ClientRect get scroll() {
    assert(window.inMeasurementFrame || !_nodeInDocument(_element));
    return new SimpleClientRect(_element.scrollLeft,
                                _element.scrollTop,
                                _element.scrollWidth,
                                _element.scrollHeight);
  }

  ClientRect get bounding() {
    assert(window.inMeasurementFrame || !_nodeInDocument(_element));
    return LevelDom.wrapClientRect(_element.getBoundingClientRect());
  }

  List<ClientRect> get clientRects() {
    assert(window.inMeasurementFrame || !_nodeInDocument(_element));
    final clientRects = _element.getClientRects();
    final out = new List(clientRects.length);
    for (num i = 0, len = clientRects.length; i < len; i++) {
      out[i] = LevelDom.wrapClientRect(clientRects.item(i));
    }
    return out;
  }
}

final _START_TAG_REGEXP = const RegExp('<(\\w+)');

/** @domName Element, HTMLElement */
class ElementWrappingImplementation extends NodeWrappingImplementation implements Element {
  
    static final _CUSTOM_PARENT_TAG_MAP = const {
      'body' : 'html',
      'head' : 'html',
      'caption' : 'table',
      'td': 'tr',
      'tbody': 'table',
      'colgroup': 'table',
      'col' : 'colgroup',
      'tr' : 'tbody',
      'tbody' : 'table',
      'tfoot' : 'table',
      'thead' : 'table',
      'track' : 'audio',
    };

  /** @domName Document.createElement */
  factory ElementWrappingImplementation.html(String html) {
    // TODO(jacobr): this method can be made more robust and performant.
    // 1) Cache the dummy parent elements required to use innerHTML rather than
    //    creating them every call.
    // 2) Verify that the html does not contain leading or trailing text nodes.
    // 3) Verify that the html does not contain both <head> and <body> tags.
    // 4) Detatch the created element from its dummy parent.
    String parentTag = 'div';
    String tag;
    final match = _START_TAG_REGEXP.firstMatch(html);
    if (match !== null) {
      tag = match.group(1).toLowerCase();
      if (_CUSTOM_PARENT_TAG_MAP.containsKey(tag)) {
        parentTag = _CUSTOM_PARENT_TAG_MAP[tag];
      }
    }
    // TODO(jacobr): make type dom.HTMLElement when dartium allows it.
    var temp = dom.document.createElement(parentTag);
    temp.innerHTML = html;

    if (temp.childElementCount == 1) {
      return LevelDom.wrapElement(temp.firstElementChild);     
    } else if (parentTag == 'html' && temp.childElementCount == 2) {
      // Work around for edge case in WebKit and possibly other browsers where
      // both body and head elements are created even though the inner html
      // only contains a head or body element.
      return LevelDom.wrapElement(temp.children.item(tag == 'head' ? 0 : 1));
    } else {
      throw new IllegalArgumentException('HTML had ${temp.childElementCount} ' +
          'top level elements but 1 expected');
    }
  }

  /** @domName Document.createElement */
  factory ElementWrappingImplementation.tag(String tag) {
    return LevelDom.wrapElement(dom.document.createElement(tag));
  }

  ElementWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  ElementAttributeMap _elementAttributeMap;
  ElementList _elements;
  _CssClassSet _cssClassSet;
  _DataAttributeMap _dataAttributes;

  /**
   * @domName Element.hasAttribute, Element.getAttribute, Element.setAttribute,
   *   Element.removeAttribute
   */
  Map<String, String> get attributes() {
    if (_elementAttributeMap === null) {
      _elementAttributeMap = new ElementAttributeMap._wrap(_ptr);
    }
    return _elementAttributeMap;
  }

  void set attributes(Map<String, String> value) {
    assert(!_inMeasurementFrame || !_inDocument);
    Map<String, String> attributes = this.attributes;
    attributes.clear();
    for (String key in value.getKeys()) {
      attributes[key] = value[key];
    }
  }

  void set elements(Collection<Element> value) {
    assert(!_inMeasurementFrame || !_inDocument);
    final elements = this.elements;
    elements.clear();
    elements.addAll(value);
  }

  /**
   * @domName childElementCount, firstElementChild, lastElementChild,
   *   children, Node.appendChild
   */
  ElementList get elements() {
    if (_elements == null) {
      _elements = new _ChildrenElementList._wrap(_ptr);
    }
    return _elements;
  }

  /** @domName className, classList */
  Set<String> get classes() {
    if (_cssClassSet === null) {
      _cssClassSet = new _CssClassSet(_ptr);
    }
    return _cssClassSet;
  }

  void set classes(Collection<String> value) {
    assert(!_inMeasurementFrame || !_inDocument);
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
    assert(!_inMeasurementFrame || !_inDocument);
    Map<String, String> dataAttributes = this.dataAttributes;
    dataAttributes.clear();
    for (String key in value.getKeys()) {
      dataAttributes[key] = value[key];
    }
  }

  String get contentEditable() => _ptr.contentEditable;

  void set contentEditable(String value) {
    assert(!_inMeasurementFrame || !_inDocument);
    _ptr.contentEditable = value;
  }

  String get dir() => _ptr.dir;

  void set dir(String value) {
    assert(!_inMeasurementFrame || !_inDocument);
    _ptr.dir = value;
  }

  bool get draggable() => _ptr.draggable;

  void set draggable(bool value) { _ptr.draggable = value; }

  Element get firstElementChild() => LevelDom.wrapElement(_ptr.firstElementChild);

  bool get hidden() => _ptr.hidden;

  void set hidden(bool value) {
    assert(!_inMeasurementFrame || !_inDocument);
    _ptr.hidden = value;
  }

  String get id() => _ptr.id;

  void set id(String value) {
    assert(!_inMeasurementFrame || !_inDocument);
    _ptr.id = value;
  }

  String get innerHTML() => _ptr.innerHTML;

  void set innerHTML(String value) {
    assert(!_inMeasurementFrame || !_inDocument);
    _ptr.innerHTML = value;
  }

  bool get isContentEditable() => _ptr.isContentEditable;

  String get lang() => _ptr.lang;

  void set lang(String value) {
    assert(!_inMeasurementFrame || !_inDocument);
    _ptr.lang = value;
  }

  Element get lastElementChild() => LevelDom.wrapElement(_ptr.lastElementChild);

  Element get nextElementSibling() => LevelDom.wrapElement(_ptr.nextElementSibling);

  Element get offsetParent() => LevelDom.wrapElement(_ptr.offsetParent);

  String get outerHTML() => _ptr.outerHTML;

  Element get previousElementSibling() => LevelDom.wrapElement(_ptr.previousElementSibling);

  bool get spellcheck() => _ptr.spellcheck;

  void set spellcheck(bool value) {
    assert(!_inMeasurementFrame || !_inDocument);
    _ptr.spellcheck = value;
  }

  CSSStyleDeclaration get style() {
    // Changes to this CSSStyleDeclaration dirty the layout so we must pass
    // the associated Element to the CSSStyleDeclaration constructor so that
    // we can compute whether the current element is attached to the document
    // which is required to decide whether modification inside a measurement
    // frame is allowed.
    final raw = _ptr.style;
    return raw.dartObjectLocalStorage !== null ?
        raw.dartObjectLocalStorage :
        new CSSStyleDeclarationWrappingImplementation._wrapWithElement(
            raw, this);
  }

  int get tabIndex() => _ptr.tabIndex;

  void set tabIndex(int value) {
    assert(!_inMeasurementFrame || !_inDocument);
    _ptr.tabIndex = value;
  }

  String get tagName() => _ptr.tagName;

  String get title() => _ptr.title;

  void set title(String value) {
    assert(!_inMeasurementFrame || !_inDocument);
    _ptr.title = value;
  }

  String get webkitdropzone() => _ptr.webkitdropzone;

  void set webkitdropzone(String value) { _ptr.webkitdropzone = value; }

  void blur() {
    assert(!_inMeasurementFrame || !_inDocument);
    _ptr.blur();
  }

  bool contains(Node element) {
    return _ptr.contains(LevelDom.unwrap(element));
  }

  void focus() {
    assert(!_inMeasurementFrame || !_inDocument);
    _ptr.focus();
  }

  Element insertAdjacentElement([String where = null, Element element = null]) {
    assert(!_inMeasurementFrame || !_inDocument);
    return LevelDom.wrapElement(_ptr.insertAdjacentElement(where, LevelDom.unwrap(element)));
  }

  void insertAdjacentHTML([String position_OR_where = null, String text = null]) {
    assert(!_inMeasurementFrame || !_inDocument);
    _ptr.insertAdjacentHTML(position_OR_where, text);
  }

  void insertAdjacentText([String where = null, String text = null]) {
    assert(!_inMeasurementFrame || !_inDocument);
    _ptr.insertAdjacentText(where, text);
  }

  /** @domName querySelector, Document.getElementById */
  Element query(String selectors) {
    // TODO(jacobr): scope fix.
    return LevelDom.wrapElement(_ptr.querySelector(selectors));
  }

  /**
   * @domName querySelectorAll, getElementsByClassName, getElementsByTagName,
   *   getElementsByTagNameNS
   */
  ElementList queryAll(String selectors) {
    // TODO(jacobr): scope fix.
    return new FrozenElementList._wrap(_ptr.querySelectorAll(selectors));
  }

  void scrollByLines([int lines = null]) {
    _ptr.scrollByLines(lines);
  }

  void scrollByPages([int pages = null]) {
    _ptr.scrollByPages(pages);
  }

  /** @domName scrollIntoView, scrollIntoViewIfNeeded */
  void scrollIntoView([bool centerIfNeeded = null]) {
    _ptr.scrollIntoViewIfNeeded(centerIfNeeded);
  }

  bool matchesSelector([String selectors = null]) {
    return _ptr.webkitMatchesSelector(selectors);
  }

  void set scrollLeft(int value) { _ptr.scrollLeft = value; }
 
  void set scrollTop(int value) { _ptr.scrollTop = value; }

  /**
   * @domName getClientRects, getBoundingClientRect, clientHeight, clientWidth,
   * clientTop, clientLeft, offsetHeight, offsetWidth, offsetTop, offsetLeft,
   * scrollHeight, scrollWidth, scrollTop, scrollLeft
   */
  ElementRect get rect() {
    return new ElementRectWrappingImplementation(_ptr);
  }

  /** @domName Window.getComputedStyle */
  CSSStyleDeclaration get computedStyle() {
     // TODO(jacobr): last param should be null, see b/5045788
    return getComputedStyle('');
  }

  /** @domName Window.getComputedStyle */
  CSSStyleDeclaration getComputedStyle(String pseudoElement) {
    assert(window.inMeasurementFrame || !_inDocument);
    return LevelDom.wrapCSSStyleDeclaration(
            dom.window.getComputedStyle(_ptr, pseudoElement));
  }

  ElementEvents get on() {
    if (_on === null) {
      _on = new ElementEventsImplementation._wrap(_ptr);
    }
    return _on;
  }

  Element clone(bool deep) => super.clone(deep);
}
