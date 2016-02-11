dart_library.library('dart/html', null, /* Imports */[
  'dart/_runtime',
  'dart/math',
  'dart/core',
  'dart/_metadata',
  'dart/_js_helper',
  'dart/collection',
  'dart/async',
  'dart/_foreign_helper',
  'dart/isolate'
], /* Lazy imports */[
  'dart/html_common'
], function(exports, dart, math, core, _metadata, _js_helper, collection, async, _foreign_helper, isolate, html_common) {
  'use strict';
  let dartx = dart.dartx;
  dart.export(exports, math, ['Rectangle', 'Point'], []);
  class DartHtmlDomObject extends core.Object {
    DartHtmlDomObject() {
      this.raw = null;
    }
    internal_() {
      this.raw = null;
    }
  }
  dart.defineNamedConstructor(DartHtmlDomObject, 'internal_');
  dart.setSignature(DartHtmlDomObject, {
    constructors: () => ({
      DartHtmlDomObject: [DartHtmlDomObject, []],
      internal_: [DartHtmlDomObject, []]
    })
  });
  const _addEventListener = Symbol('_addEventListener');
  const _removeEventListener = Symbol('_removeEventListener');
  const _addEventListener_1 = Symbol('_addEventListener_1');
  const _addEventListener_2 = Symbol('_addEventListener_2');
  const _addEventListener_3 = Symbol('_addEventListener_3');
  const _addEventListener_4 = Symbol('_addEventListener_4');
  const _dispatchEvent_1 = Symbol('_dispatchEvent_1');
  const _removeEventListener_1 = Symbol('_removeEventListener_1');
  const _removeEventListener_2 = Symbol('_removeEventListener_2');
  const _removeEventListener_3 = Symbol('_removeEventListener_3');
  const _removeEventListener_4 = Symbol('_removeEventListener_4');
  class EventTarget extends DartHtmlDomObject {
    _created() {
      super.DartHtmlDomObject();
    }
    get on() {
      return new Events(this);
    }
    addEventListener(type, listener, useCapture) {
      if (useCapture === void 0) useCapture = null;
      if (listener != null) {
        this[_addEventListener](type, listener, useCapture);
      }
    }
    removeEventListener(type, listener, useCapture) {
      if (useCapture === void 0) useCapture = null;
      if (listener != null) {
        this[_removeEventListener](type, listener, useCapture);
      }
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateEventTarget() {
      return new EventTarget.internal_();
    }
    internal_() {
      super.DartHtmlDomObject();
    }
    ['=='](other) {
      return dart.equals(unwrap_jso(other), unwrap_jso(this)) || dart.notNull(core.identical(this, other));
    }
    get hashCode() {
      return dart.hashCode(unwrap_jso(this));
    }
    [_addEventListener](type, listener, useCapture) {
      if (type === void 0) type = null;
      if (listener === void 0) listener = null;
      if (useCapture === void 0) useCapture = null;
      if (useCapture != null) {
        this[_addEventListener_1](type, listener, useCapture);
        return;
      }
      if (listener != null) {
        this[_addEventListener_2](type, listener);
        return;
      }
      if (type != null) {
        this[_addEventListener_3](type);
        return;
      }
      this[_addEventListener_4]();
      return;
    }
    [_addEventListener_1](type, listener, useCapture) {
      return wrap_jso(this.raw.addEventListener(unwrap_jso(type), unwrap_jso(listener), unwrap_jso(useCapture)));
    }
    [_addEventListener_2](type, listener) {
      return wrap_jso(this.raw.addEventListener(unwrap_jso(type), unwrap_jso(listener)));
    }
    [_addEventListener_3](type) {
      return wrap_jso(this.raw.addEventListener(unwrap_jso(type)));
    }
    [_addEventListener_4]() {
      return wrap_jso(this.raw.addEventListener());
    }
    dispatchEvent(event) {
      return this[_dispatchEvent_1](event);
    }
    [_dispatchEvent_1](event) {
      return dart.as(wrap_jso(this.raw.dispatchEvent(unwrap_jso(event))), core.bool);
    }
    [_removeEventListener](type, listener, useCapture) {
      if (type === void 0) type = null;
      if (listener === void 0) listener = null;
      if (useCapture === void 0) useCapture = null;
      if (useCapture != null) {
        this[_removeEventListener_1](type, listener, useCapture);
        return;
      }
      if (listener != null) {
        this[_removeEventListener_2](type, listener);
        return;
      }
      if (type != null) {
        this[_removeEventListener_3](type);
        return;
      }
      this[_removeEventListener_4]();
      return;
    }
    [_removeEventListener_1](type, listener, useCapture) {
      return wrap_jso(this.raw.removeEventListener(unwrap_jso(type), unwrap_jso(listener), unwrap_jso(useCapture)));
    }
    [_removeEventListener_2](type, listener) {
      return wrap_jso(this.raw.removeEventListener(unwrap_jso(type), unwrap_jso(listener)));
    }
    [_removeEventListener_3](type) {
      return wrap_jso(this.raw.removeEventListener(unwrap_jso(type)));
    }
    [_removeEventListener_4]() {
      return wrap_jso(this.raw.removeEventListener());
    }
  }
  dart.defineNamedConstructor(EventTarget, '_created');
  dart.defineNamedConstructor(EventTarget, 'internal_');
  dart.setSignature(EventTarget, {
    constructors: () => ({
      _created: [EventTarget, []],
      _: [EventTarget, []],
      internal_: [EventTarget, []]
    }),
    methods: () => ({
      addEventListener: [dart.void, [core.String, EventListener], [core.bool]],
      removeEventListener: [dart.void, [core.String, EventListener], [core.bool]],
      [_addEventListener]: [dart.void, [], [core.String, EventListener, core.bool]],
      [_addEventListener_1]: [dart.void, [dart.dynamic, EventListener, dart.dynamic]],
      [_addEventListener_2]: [dart.void, [dart.dynamic, EventListener]],
      [_addEventListener_3]: [dart.void, [dart.dynamic]],
      [_addEventListener_4]: [dart.void, []],
      dispatchEvent: [core.bool, [Event]],
      [_dispatchEvent_1]: [core.bool, [Event]],
      [_removeEventListener]: [dart.void, [], [core.String, EventListener, core.bool]],
      [_removeEventListener_1]: [dart.void, [dart.dynamic, EventListener, dart.dynamic]],
      [_removeEventListener_2]: [dart.void, [dart.dynamic, EventListener]],
      [_removeEventListener_3]: [dart.void, [dart.dynamic]],
      [_removeEventListener_4]: [dart.void, []]
    }),
    statics: () => ({internalCreateEventTarget: [EventTarget, []]}),
    names: ['internalCreateEventTarget']
  });
  EventTarget[dart.metadata] = () => [dart.const(new _metadata.DomName('EventTarget')), dart.const(new _js_helper.Native("EventTarget"))];
  const _removeChild = Symbol('_removeChild');
  const _replaceChild = Symbol('_replaceChild');
  const _this = Symbol('_this');
  const _clearChildren = Symbol('_clearChildren');
  const _localName = Symbol('_localName');
  const _namespaceUri = Symbol('_namespaceUri');
  const _append_1 = Symbol('_append_1');
  const _clone_1 = Symbol('_clone_1');
  const _contains_1 = Symbol('_contains_1');
  const _hasChildNodes_1 = Symbol('_hasChildNodes_1');
  const _insertBefore_1 = Symbol('_insertBefore_1');
  const _removeChild_1 = Symbol('_removeChild_1');
  const _replaceChild_1 = Symbol('_replaceChild_1');
  class Node extends EventTarget {
    _created() {
      super._created();
    }
    get nodes() {
      return new _ChildNodeListLazy(this);
    }
    set nodes(value) {
      let copy = core.List.from(value);
      this.text = '';
      for (let node of dart.as(copy, core.Iterable$(Node))) {
        this.append(node);
      }
    }
    remove() {
      if (this.parentNode != null) {
        let parent = this.parentNode;
        this.parentNode[_removeChild](this);
      }
    }
    replaceWith(otherNode) {
      try {
        let parent = this.parentNode;
        parent[_replaceChild](otherNode, this);
      } catch (e) {
      }

      ;
      return this;
    }
    insertAllBefore(newNodes, refChild) {
      if (dart.is(newNodes, _ChildNodeListLazy)) {
        let otherList = newNodes;
        if (dart.notNull(core.identical(otherList[_this], this))) {
          dart.throw(new core.ArgumentError(newNodes));
        }
        for (let i = 0, len = otherList.length; i < dart.notNull(len); ++i) {
          this.insertBefore(otherList[_this].firstChild, refChild);
        }
      } else {
        for (let node of newNodes) {
          this.insertBefore(node, refChild);
        }
      }
    }
    [_clearChildren]() {
      while (this.firstChild != null) {
        this[_removeChild](this.firstChild);
      }
    }
    toString() {
      let value = this.nodeValue;
      return value == null ? super.toString() : value;
    }
    get childNodes() {
      return dart.as(wrap_jso(this.raw.childNodes), core.List$(Node));
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateNode() {
      return new Node.internal_();
    }
    internal_() {
      super.internal_();
    }
    get baseUri() {
      return dart.as(wrap_jso(this.raw.baseURI), core.String);
    }
    get firstChild() {
      return dart.as(wrap_jso(this.raw.firstChild), Node);
    }
    get lastChild() {
      return dart.as(wrap_jso(this.raw.lastChild), Node);
    }
    get [_localName]() {
      return dart.as(wrap_jso(this.raw.localName), core.String);
    }
    get [_namespaceUri]() {
      return dart.as(wrap_jso(this.raw.namespaceURI), core.String);
    }
    get nextNode() {
      return dart.as(wrap_jso(this.raw.nextSibling), Node);
    }
    get nodeName() {
      return dart.as(wrap_jso(this.raw.nodeName), core.String);
    }
    get nodeType() {
      return dart.as(wrap_jso(this.raw.nodeType), core.int);
    }
    get nodeValue() {
      return dart.as(wrap_jso(this.raw.nodeValue), core.String);
    }
    get ownerDocument() {
      return dart.as(wrap_jso(this.raw.ownerDocument), Document);
    }
    get parent() {
      return dart.as(wrap_jso(this.raw.parentElement), Element);
    }
    get parentNode() {
      return dart.as(wrap_jso(this.raw.parentNode), Node);
    }
    get previousNode() {
      return dart.as(wrap_jso(this.raw.previousSibling), Node);
    }
    get text() {
      return dart.as(wrap_jso(this.raw.textContent), core.String);
    }
    set text(val) {
      return this.raw.textContent = unwrap_jso(val);
    }
    append(newChild) {
      return this[_append_1](newChild);
    }
    [_append_1](newChild) {
      return dart.as(wrap_jso(this.raw.appendChild(unwrap_jso(newChild))), Node);
    }
    clone(deep) {
      return this[_clone_1](deep);
    }
    [_clone_1](deep) {
      return dart.as(wrap_jso(this.raw.cloneNode(unwrap_jso(deep))), Node);
    }
    contains(other) {
      return this[_contains_1](other);
    }
    [_contains_1](other) {
      return dart.as(wrap_jso(this.raw.contains(unwrap_jso(other))), core.bool);
    }
    hasChildNodes() {
      return this[_hasChildNodes_1]();
    }
    [_hasChildNodes_1]() {
      return dart.as(wrap_jso(this.raw.hasChildNodes()), core.bool);
    }
    insertBefore(newChild, refChild) {
      return this[_insertBefore_1](newChild, refChild);
    }
    [_insertBefore_1](newChild, refChild) {
      return dart.as(wrap_jso(this.raw.insertBefore(unwrap_jso(newChild), unwrap_jso(refChild))), Node);
    }
    [_removeChild](oldChild) {
      return this[_removeChild_1](oldChild);
    }
    [_removeChild_1](oldChild) {
      return dart.as(wrap_jso(this.raw.removeChild(unwrap_jso(oldChild))), Node);
    }
    [_replaceChild](newChild, oldChild) {
      return this[_replaceChild_1](newChild, oldChild);
    }
    [_replaceChild_1](newChild, oldChild) {
      return dart.as(wrap_jso(this.raw.replaceChild(unwrap_jso(newChild), unwrap_jso(oldChild))), Node);
    }
  }
  dart.defineNamedConstructor(Node, '_created');
  dart.defineNamedConstructor(Node, 'internal_');
  dart.setSignature(Node, {
    constructors: () => ({
      _created: [Node, []],
      _: [Node, []],
      internal_: [Node, []]
    }),
    methods: () => ({
      remove: [dart.void, []],
      replaceWith: [Node, [Node]],
      insertAllBefore: [Node, [core.Iterable$(Node), Node]],
      [_clearChildren]: [dart.void, []],
      append: [Node, [Node]],
      [_append_1]: [Node, [Node]],
      clone: [Node, [core.bool]],
      [_clone_1]: [Node, [dart.dynamic]],
      contains: [core.bool, [Node]],
      [_contains_1]: [core.bool, [Node]],
      hasChildNodes: [core.bool, []],
      [_hasChildNodes_1]: [core.bool, []],
      insertBefore: [Node, [Node, Node]],
      [_insertBefore_1]: [Node, [Node, Node]],
      [_removeChild]: [Node, [Node]],
      [_removeChild_1]: [Node, [Node]],
      [_replaceChild]: [Node, [Node, Node]],
      [_replaceChild_1]: [Node, [Node, Node]]
    }),
    statics: () => ({internalCreateNode: [Node, []]}),
    names: ['internalCreateNode']
  });
  Node[dart.metadata] = () => [dart.const(new _metadata.DomName('Node')), dart.const(new _js_helper.Native("Node"))];
  Node.ATTRIBUTE_NODE = 2;
  Node.CDATA_SECTION_NODE = 4;
  Node.COMMENT_NODE = 8;
  Node.DOCUMENT_FRAGMENT_NODE = 11;
  Node.DOCUMENT_NODE = 9;
  Node.DOCUMENT_TYPE_NODE = 10;
  Node.ELEMENT_NODE = 1;
  Node.ENTITY_NODE = 6;
  Node.ENTITY_REFERENCE_NODE = 5;
  Node.NOTATION_NODE = 12;
  Node.PROCESSING_INSTRUCTION_NODE = 7;
  Node.TEXT_NODE = 3;
  const _xtag = Symbol('_xtag');
  const _querySelectorAll = Symbol('_querySelectorAll');
  const _getComputedStyle = Symbol('_getComputedStyle');
  const _scrollIntoView = Symbol('_scrollIntoView');
  const _scrollIntoViewIfNeeded = Symbol('_scrollIntoViewIfNeeded');
  const _insertAdjacentHtml = Symbol('_insertAdjacentHtml');
  const _insertAdjacentNode = Symbol('_insertAdjacentNode');
  const _canBeUsedToCreateContextualFragment = Symbol('_canBeUsedToCreateContextualFragment');
  const _innerHtml = Symbol('_innerHtml');
  const _cannotBeUsedToCreateContextualFragment = Symbol('_cannotBeUsedToCreateContextualFragment');
  const _click_1 = Symbol('_click_1');
  const _attributes = Symbol('_attributes');
  const _clientHeight = Symbol('_clientHeight');
  const _clientLeft = Symbol('_clientLeft');
  const _clientTop = Symbol('_clientTop');
  const _clientWidth = Symbol('_clientWidth');
  const _offsetHeight = Symbol('_offsetHeight');
  const _offsetLeft = Symbol('_offsetLeft');
  const _offsetTop = Symbol('_offsetTop');
  const _offsetWidth = Symbol('_offsetWidth');
  const _scrollHeight = Symbol('_scrollHeight');
  const _scrollLeft = Symbol('_scrollLeft');
  const _scrollTop = Symbol('_scrollTop');
  const _scrollWidth = Symbol('_scrollWidth');
  const _blur_1 = Symbol('_blur_1');
  const _focus_1 = Symbol('_focus_1');
  const _getAttribute_1 = Symbol('_getAttribute_1');
  const _getAttributeNS_1 = Symbol('_getAttributeNS_1');
  const _getBoundingClientRect_1 = Symbol('_getBoundingClientRect_1');
  const _getDestinationInsertionPoints_1 = Symbol('_getDestinationInsertionPoints_1');
  const _getElementsByClassName_1 = Symbol('_getElementsByClassName_1');
  const _getElementsByTagName_1 = Symbol('_getElementsByTagName_1');
  const _getElementsByTagName = Symbol('_getElementsByTagName');
  const _hasAttribute_1 = Symbol('_hasAttribute_1');
  const _hasAttribute = Symbol('_hasAttribute');
  const _hasAttributeNS_1 = Symbol('_hasAttributeNS_1');
  const _hasAttributeNS = Symbol('_hasAttributeNS');
  const _removeAttribute_1 = Symbol('_removeAttribute_1');
  const _removeAttribute = Symbol('_removeAttribute');
  const _removeAttributeNS_1 = Symbol('_removeAttributeNS_1');
  const _removeAttributeNS = Symbol('_removeAttributeNS');
  const _requestFullscreen_1 = Symbol('_requestFullscreen_1');
  const _requestPointerLock_1 = Symbol('_requestPointerLock_1');
  const _scrollIntoView_1 = Symbol('_scrollIntoView_1');
  const _scrollIntoView_2 = Symbol('_scrollIntoView_2');
  const _scrollIntoViewIfNeeded_1 = Symbol('_scrollIntoViewIfNeeded_1');
  const _scrollIntoViewIfNeeded_2 = Symbol('_scrollIntoViewIfNeeded_2');
  const _setAttribute_1 = Symbol('_setAttribute_1');
  const _setAttributeNS_1 = Symbol('_setAttributeNS_1');
  const _childElementCount = Symbol('_childElementCount');
  const _children = Symbol('_children');
  const _firstElementChild = Symbol('_firstElementChild');
  const _lastElementChild = Symbol('_lastElementChild');
  const _querySelector_1 = Symbol('_querySelector_1');
  const _querySelectorAll_1 = Symbol('_querySelectorAll_1');
  class Element extends Node {
    static html(html, opts) {
      let validator = opts && 'validator' in opts ? opts.validator : null;
      let treeSanitizer = opts && 'treeSanitizer' in opts ? opts.treeSanitizer : null;
      let fragment = exports.document.body.createFragment(html, {validator: validator, treeSanitizer: treeSanitizer});
      return dart.as(fragment.nodes[dartx.where](dart.fn(e => dart.is(e, Element), core.bool, [Node]))[dartx.single], Element);
    }
    created() {
      this[_xtag] = null;
      super._created();
    }
    static tag(tag, typeExtention) {
      if (typeExtention === void 0) typeExtention = null;
      return _ElementFactoryProvider.createElement_tag(tag, typeExtention);
    }
    static a() {
      return Element.tag('a');
    }
    static article() {
      return Element.tag('article');
    }
    static aside() {
      return Element.tag('aside');
    }
    static audio() {
      return Element.tag('audio');
    }
    static br() {
      return Element.tag('br');
    }
    static canvas() {
      return Element.tag('canvas');
    }
    static div() {
      return Element.tag('div');
    }
    static footer() {
      return Element.tag('footer');
    }
    static header() {
      return Element.tag('header');
    }
    static hr() {
      return Element.tag('hr');
    }
    static iframe() {
      return Element.tag('iframe');
    }
    static img() {
      return Element.tag('img');
    }
    static li() {
      return Element.tag('li');
    }
    static nav() {
      return Element.tag('nav');
    }
    static ol() {
      return Element.tag('ol');
    }
    static option() {
      return Element.tag('option');
    }
    static p() {
      return Element.tag('p');
    }
    static pre() {
      return Element.tag('pre');
    }
    static section() {
      return Element.tag('section');
    }
    static select() {
      return Element.tag('select');
    }
    static span() {
      return Element.tag('span');
    }
    static svg() {
      return Element.tag('svg');
    }
    static table() {
      return Element.tag('table');
    }
    static td() {
      return Element.tag('td');
    }
    static textarea() {
      return Element.tag('textarea');
    }
    static th() {
      return Element.tag('th');
    }
    static tr() {
      return Element.tag('tr');
    }
    static ul() {
      return Element.tag('ul');
    }
    static video() {
      return Element.tag('video');
    }
    get attributes() {
      return new _ElementAttributeMap(this);
    }
    set attributes(value) {
      let attributes = this.attributes;
      attributes.clear();
      for (let key of value.keys) {
        attributes.set(key, value.get(key));
      }
    }
    get children() {
      return new _ChildrenElementList._wrap(this);
    }
    set children(value) {
      let copy = core.List.from(value);
      let children = this.children;
      children[dartx.clear]();
      children[dartx.addAll](dart.as(copy, core.Iterable$(Element)));
    }
    querySelectorAll(selectors) {
      return new _FrozenElementList._wrap(this[_querySelectorAll](selectors));
    }
    query(relativeSelectors) {
      return this.querySelector(relativeSelectors);
    }
    queryAll(relativeSelectors) {
      return this.querySelectorAll(relativeSelectors);
    }
    get classes() {
      return new exports._ElementCssClassSet(this);
    }
    set classes(value) {
      let classSet = this.classes;
      classSet.clear();
      classSet.addAll(value);
    }
    get dataset() {
      return new _DataAttributeMap(this.attributes);
    }
    set dataset(value) {
      let data = this.dataset;
      data.clear();
      for (let key of value.keys) {
        data.set(key, value.get(key));
      }
    }
    getNamespacedAttributes(namespace) {
      return new _NamespacedAttributeMap(this, namespace);
    }
    getComputedStyle(pseudoElement) {
      if (pseudoElement === void 0) pseudoElement = null;
      if (pseudoElement == null) {
        pseudoElement = '';
      }
      return exports.window[_getComputedStyle](this, pseudoElement);
    }
    get client() {
      return new math.Rectangle(this.clientLeft, this.clientTop, this.clientWidth, this.clientHeight);
    }
    get offset() {
      return new math.Rectangle(this.offsetLeft, this.offsetTop, this.offsetWidth, this.offsetHeight);
    }
    appendText(text) {
      this.append(Text.new(text));
    }
    appendHtml(text, opts) {
      let validator = opts && 'validator' in opts ? opts.validator : null;
      let treeSanitizer = opts && 'treeSanitizer' in opts ? opts.treeSanitizer : null;
      this.insertAdjacentHtml('beforeend', text, {validator: validator, treeSanitizer: treeSanitizer});
    }
    static isTagSupported(tag) {
      let e = _ElementFactoryProvider.createElement_tag(tag, null);
      return dart.is(e, Element) && !(e.constructor.name == "HTMLUnknownElement");
    }
    attached() {
      this.enteredView();
    }
    detached() {
      this.leftView();
    }
    enteredView() {}
    leftView() {}
    attributeChanged(name, oldValue, newValue) {}
    get xtag() {
      return this[_xtag] != null ? this[_xtag] : this;
    }
    set xtag(value) {
      this[_xtag] = value;
    }
    get localName() {
      return this[_localName];
    }
    get namespaceUri() {
      return this[_namespaceUri];
    }
    toString() {
      return this.localName;
    }
    scrollIntoView(alignment) {
      if (alignment === void 0) alignment = null;
      let hasScrollIntoViewIfNeeded = true;
      if (dart.equals(alignment, ScrollAlignment.TOP)) {
        this[_scrollIntoView](true);
      } else if (dart.equals(alignment, ScrollAlignment.BOTTOM)) {
        this[_scrollIntoView](false);
      } else if (hasScrollIntoViewIfNeeded) {
        if (dart.equals(alignment, ScrollAlignment.CENTER)) {
          this[_scrollIntoViewIfNeeded](true);
        } else {
          this[_scrollIntoViewIfNeeded]();
        }
      } else {
        this[_scrollIntoView]();
      }
    }
    insertAdjacentHtml(where, html, opts) {
      let validator = opts && 'validator' in opts ? opts.validator : null;
      let treeSanitizer = opts && 'treeSanitizer' in opts ? opts.treeSanitizer : null;
      if (dart.is(treeSanitizer, _TrustedHtmlTreeSanitizer)) {
        this[_insertAdjacentHtml](where, html);
      } else {
        this[_insertAdjacentNode](where, this.createFragment(html, {validator: validator, treeSanitizer: treeSanitizer}));
      }
    }
    [_insertAdjacentHtml](where, text) {
      return this.raw.insertAdjacentHTML(where, text);
    }
    [_insertAdjacentNode](where, node) {
      switch (where[dartx.toLowerCase]()) {
        case 'beforebegin':
        {
          this.parentNode.insertBefore(node, this);
          break;
        }
        case 'afterbegin':
        {
          let first = dart.notNull(this.nodes[dartx.length]) > 0 ? this.nodes[dartx.get](0) : null;
          this.insertBefore(node, first);
          break;
        }
        case 'beforeend':
        {
          this.append(node);
          break;
        }
        case 'afterend':
        {
          this.parentNode.insertBefore(node, this.nextNode);
          break;
        }
        default:
        {
          dart.throw(new core.ArgumentError(`Invalid position ${where}`));
        }
      }
    }
    matches(selectors) {
      return this.raw.matches(selectors);
    }
    matchesWithAncestors(selectors) {
      let elem = this;
      do {
        if (dart.notNull(elem.matches(selectors))) return true;
        elem = elem.parent;
      } while (elem != null);
      return false;
    }
    get contentEdge() {
      return new _ContentCssRect(this);
    }
    get paddingEdge() {
      return new _PaddingCssRect(this);
    }
    get borderEdge() {
      return new _BorderCssRect(this);
    }
    get marginEdge() {
      return new _MarginCssRect(this);
    }
    get documentOffset() {
      return this.offsetTo(exports.document.documentElement);
    }
    offsetTo(parent) {
      return Element._offsetToHelper(this, parent);
    }
    static _offsetToHelper(current, parent) {
      let sameAsParent = dart.equals(current, parent);
      let foundAsParent = sameAsParent || parent.tagName == 'HTML';
      if (current == null || sameAsParent) {
        if (foundAsParent) return new math.Point(0, 0);
        dart.throw(new core.ArgumentError("Specified element is not a transitive offset " + "parent of this element."));
      }
      let parentOffset = current.offsetParent;
      let p = Element._offsetToHelper(parentOffset, parent);
      return new math.Point(dart.dsend(p.x, '+', current.offsetLeft), dart.dsend(p.y, '+', current.offsetTop));
    }
    createFragment(html, opts) {
      let validator = opts && 'validator' in opts ? opts.validator : null;
      let treeSanitizer = opts && 'treeSanitizer' in opts ? opts.treeSanitizer : null;
      if (treeSanitizer == null) {
        if (validator == null) {
          if (Element._defaultValidator == null) {
            Element._defaultValidator = new NodeValidatorBuilder.common();
          }
          validator = Element._defaultValidator;
        }
        if (Element._defaultSanitizer == null) {
          Element._defaultSanitizer = new _ValidatingTreeSanitizer(validator);
        } else {
          Element._defaultSanitizer.validator = validator;
        }
        treeSanitizer = Element._defaultSanitizer;
      } else if (validator != null) {
        dart.throw(new core.ArgumentError('validator can only be passed if treeSanitizer is null'));
      }
      if (Element._parseDocument == null) {
        Element._parseDocument = exports.document.implementation.createHtmlDocument('');
        Element._parseRange = Element._parseDocument.createRange();
        let base = dart.as(Element._parseDocument.createElement('base'), BaseElement);
        base.href = exports.document.baseUri;
        Element._parseDocument.head.append(base);
      }
      let contextElement = null;
      if (dart.is(this, BodyElement)) {
        contextElement = Element._parseDocument.body;
      } else {
        contextElement = Element._parseDocument.createElement(this.tagName);
        Element._parseDocument.body.append(dart.as(contextElement, Node));
      }
      let fragment = null;
      if (dart.notNull(Range.supportsCreateContextualFragment) && dart.notNull(this[_canBeUsedToCreateContextualFragment])) {
        Element._parseRange.selectNodeContents(dart.as(contextElement, Node));
        fragment = Element._parseRange.createContextualFragment(html);
      } else {
        dart.dput(contextElement, _innerHtml, html);
        fragment = Element._parseDocument.createDocumentFragment();
        while (dart.dload(contextElement, 'firstChild') != null) {
          dart.dsend(fragment, 'append', dart.dload(contextElement, 'firstChild'));
        }
      }
      if (!dart.equals(contextElement, Element._parseDocument.body)) {
        dart.dsend(contextElement, 'remove');
      }
      treeSanitizer.sanitizeTree(dart.as(fragment, Node));
      exports.document.adoptNode(dart.as(fragment, Node));
      return dart.as(fragment, DocumentFragment);
    }
    get [_canBeUsedToCreateContextualFragment]() {
      return !dart.notNull(this[_cannotBeUsedToCreateContextualFragment]);
    }
    get [_cannotBeUsedToCreateContextualFragment]() {
      return Element._tagsForWhichCreateContextualFragmentIsNotSupported[dartx.contains](this.tagName);
    }
    set innerHtml(html) {
      this.setInnerHtml(html);
    }
    setInnerHtml(html, opts) {
      let validator = opts && 'validator' in opts ? opts.validator : null;
      let treeSanitizer = opts && 'treeSanitizer' in opts ? opts.treeSanitizer : null;
      this.text = null;
      if (dart.is(treeSanitizer, _TrustedHtmlTreeSanitizer)) {
        this[_innerHtml] = html;
      } else {
        this.append(this.createFragment(html, {validator: validator, treeSanitizer: treeSanitizer}));
      }
    }
    get innerHtml() {
      return this[_innerHtml];
    }
    get on() {
      return new ElementEvents(this);
    }
    static _hasCorruptedAttributes(element) {
      return (function(element) {
        if (!(element.attributes instanceof NamedNodeMap)) {
          return true;
        }
        var childNodes = element.childNodes;
        if (element.lastChild && element.lastChild !== childNodes[childNodes.length - 1]) {
          return true;
        }
        if (element.children) {
          if (!(element.children instanceof HTMLCollection || element.children instanceof NodeList)) {
            return true;
          }
        }
        var length = 0;
        if (element.children) {
          length = element.children.length;
        }
        for (var i = 0; i < length; i++) {
          var child = element.children[i];
          if (child.id == 'attributes' || child.name == 'attributes' || child.id == 'lastChild' || child.name == 'lastChild' || child.id == 'children' || child.name == 'children') {
            return true;
          }
        }
        return false;
      })(element.raw);
    }
    static _hasCorruptedAttributesAdditionalCheck(element) {
      return !(element.raw.attributes instanceof NamedNodeMap);
    }
    static _safeTagName(element) {
      let result = 'element tag unavailable';
      try {
        if (typeof dart.dload(element, 'tagName') == 'string') {
          result = dart.as(dart.dload(element, 'tagName'), core.String);
        }
      } catch (e) {
      }

      return result;
    }
    get offsetHeight() {
      return this.raw.offsetHeight[dartx.round]();
    }
    get offsetLeft() {
      return this.raw.offsetLeft[dartx.round]();
    }
    get offsetTop() {
      return this.raw.offsetTop[dartx.round]();
    }
    get offsetWidth() {
      return this.raw.offsetWidth[dartx.round]();
    }
    get clientHeight() {
      return this.raw.clientHeight[dartx.round]();
    }
    get clientLeft() {
      return this.raw.clientLeft[dartx.round]();
    }
    get clientTop() {
      return this.raw.clientTop[dartx.round]();
    }
    get clientWidth() {
      return this.raw.clientWidth[dartx.round]();
    }
    get scrollHeight() {
      return this.raw.scrollHeight[dartx.round]();
    }
    get scrollLeft() {
      return this.raw.scrollLeft[dartx.round]();
    }
    set scrollLeft(value) {
      this.raw.scrollLeft = value[dartx.round]();
    }
    get scrollTop() {
      return this.raw.scrollTop[dartx.round]();
    }
    set scrollTop(value) {
      this.raw.scrollTop = value[dartx.round]();
    }
    get scrollWidth() {
      return this.raw.scrollWidth[dartx.round]();
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateElement() {
      return new Element.internal_();
    }
    internal_() {
      this[_xtag] = null;
      super.internal_();
    }
    get contentEditable() {
      return dart.as(wrap_jso(this.raw.contentEditable), core.String);
    }
    set contentEditable(val) {
      return this.raw.contentEditable = unwrap_jso(val);
    }
    get contextMenu() {
      return dart.as(wrap_jso(this.raw.contextMenu), HtmlElement);
    }
    set contextMenu(val) {
      return this.raw.contextMenu = unwrap_jso(val);
    }
    get dir() {
      return dart.as(wrap_jso(this.raw.dir), core.String);
    }
    set dir(val) {
      return this.raw.dir = unwrap_jso(val);
    }
    get draggable() {
      return dart.as(wrap_jso(this.raw.draggable), core.bool);
    }
    set draggable(val) {
      return this.raw.draggable = unwrap_jso(val);
    }
    get hidden() {
      return dart.as(wrap_jso(this.raw.hidden), core.bool);
    }
    set hidden(val) {
      return this.raw.hidden = unwrap_jso(val);
    }
    get isContentEditable() {
      return dart.as(wrap_jso(this.raw.isContentEditable), core.bool);
    }
    get lang() {
      return dart.as(wrap_jso(this.raw.lang), core.String);
    }
    set lang(val) {
      return this.raw.lang = unwrap_jso(val);
    }
    get spellcheck() {
      return dart.as(wrap_jso(this.raw.spellcheck), core.bool);
    }
    set spellcheck(val) {
      return this.raw.spellcheck = unwrap_jso(val);
    }
    get tabIndex() {
      return dart.as(wrap_jso(this.raw.tabIndex), core.int);
    }
    set tabIndex(val) {
      return this.raw.tabIndex = unwrap_jso(val);
    }
    get title() {
      return dart.as(wrap_jso(this.raw.title), core.String);
    }
    set title(val) {
      return this.raw.title = unwrap_jso(val);
    }
    get translate() {
      return dart.as(wrap_jso(this.raw.translate), core.bool);
    }
    set translate(val) {
      return this.raw.translate = unwrap_jso(val);
    }
    get dropzone() {
      return dart.as(wrap_jso(this.raw.webkitdropzone), core.String);
    }
    set dropzone(val) {
      return this.raw.webkitdropzone = unwrap_jso(val);
    }
    click() {
      this[_click_1]();
      return;
    }
    [_click_1]() {
      return wrap_jso(this.raw.click());
    }
    get [_attributes]() {
      return dart.as(wrap_jso(this.raw.attributes), _NamedNodeMap);
    }
    get className() {
      return dart.as(wrap_jso(this.raw.className), core.String);
    }
    set className(val) {
      return this.raw.className = unwrap_jso(val);
    }
    get [_clientHeight]() {
      return dart.as(wrap_jso(this.raw.clientHeight), core.int);
    }
    get [_clientLeft]() {
      return dart.as(wrap_jso(this.raw.clientLeft), core.int);
    }
    get [_clientTop]() {
      return dart.as(wrap_jso(this.raw.clientTop), core.int);
    }
    get [_clientWidth]() {
      return dart.as(wrap_jso(this.raw.clientWidth), core.int);
    }
    get id() {
      return dart.as(wrap_jso(this.raw.id), core.String);
    }
    set id(val) {
      return this.raw.id = unwrap_jso(val);
    }
    get [_innerHtml]() {
      return dart.as(wrap_jso(this.raw.innerHTML), core.String);
    }
    set [_innerHtml](val) {
      return this.raw.innerHTML = unwrap_jso(val);
    }
    get [_offsetHeight]() {
      return dart.as(wrap_jso(this.raw.offsetHeight), core.int);
    }
    get [_offsetLeft]() {
      return dart.as(wrap_jso(this.raw.offsetLeft), core.int);
    }
    get offsetParent() {
      return dart.as(wrap_jso(this.raw.offsetParent), Element);
    }
    get [_offsetTop]() {
      return dart.as(wrap_jso(this.raw.offsetTop), core.int);
    }
    get [_offsetWidth]() {
      return dart.as(wrap_jso(this.raw.offsetWidth), core.int);
    }
    get outerHtml() {
      return dart.as(wrap_jso(this.raw.outerHTML), core.String);
    }
    get [_scrollHeight]() {
      return dart.as(wrap_jso(this.raw.scrollHeight), core.int);
    }
    get [_scrollLeft]() {
      return dart.as(wrap_jso(this.raw.scrollLeft), core.num);
    }
    set [_scrollLeft](val) {
      return this.raw.scrollLeft = unwrap_jso(val);
    }
    get [_scrollTop]() {
      return dart.as(wrap_jso(this.raw.scrollTop), core.num);
    }
    set [_scrollTop](val) {
      return this.raw.scrollTop = unwrap_jso(val);
    }
    get [_scrollWidth]() {
      return dart.as(wrap_jso(this.raw.scrollWidth), core.int);
    }
    get style() {
      return dart.as(wrap_jso(this.raw.style), CssStyleDeclaration);
    }
    get tagName() {
      return dart.as(wrap_jso(this.raw.tagName), core.String);
    }
    blur() {
      this[_blur_1]();
      return;
    }
    [_blur_1]() {
      return wrap_jso(this.raw.blur());
    }
    focus() {
      this[_focus_1]();
      return;
    }
    [_focus_1]() {
      return wrap_jso(this.raw.focus());
    }
    getAttribute(name) {
      return this[_getAttribute_1](name);
    }
    [_getAttribute_1](name) {
      return dart.as(wrap_jso(this.raw.getAttribute(unwrap_jso(name))), core.String);
    }
    getAttributeNS(namespaceURI, localName) {
      return this[_getAttributeNS_1](namespaceURI, localName);
    }
    [_getAttributeNS_1](namespaceURI, localName) {
      return dart.as(wrap_jso(this.raw.getAttributeNS(unwrap_jso(namespaceURI), unwrap_jso(localName))), core.String);
    }
    getBoundingClientRect() {
      return this[_getBoundingClientRect_1]();
    }
    [_getBoundingClientRect_1]() {
      return dart.as(wrap_jso(this.raw.getBoundingClientRect()), math.Rectangle);
    }
    getDestinationInsertionPoints() {
      return this[_getDestinationInsertionPoints_1]();
    }
    [_getDestinationInsertionPoints_1]() {
      return dart.as(wrap_jso(this.raw.getDestinationInsertionPoints()), NodeList);
    }
    getElementsByClassName(classNames) {
      return this[_getElementsByClassName_1](classNames);
    }
    [_getElementsByClassName_1](classNames) {
      return dart.as(wrap_jso(this.raw.getElementsByClassName(unwrap_jso(classNames))), HtmlCollection);
    }
    [_getElementsByTagName](name) {
      return this[_getElementsByTagName_1](name);
    }
    [_getElementsByTagName_1](name) {
      return dart.as(wrap_jso(this.raw.getElementsByTagName(unwrap_jso(name))), HtmlCollection);
    }
    [_hasAttribute](name) {
      return this[_hasAttribute_1](name);
    }
    [_hasAttribute_1](name) {
      return dart.as(wrap_jso(this.raw.hasAttribute(unwrap_jso(name))), core.bool);
    }
    [_hasAttributeNS](namespaceURI, localName) {
      return this[_hasAttributeNS_1](namespaceURI, localName);
    }
    [_hasAttributeNS_1](namespaceURI, localName) {
      return dart.as(wrap_jso(this.raw.hasAttributeNS(unwrap_jso(namespaceURI), unwrap_jso(localName))), core.bool);
    }
    [_removeAttribute](name) {
      this[_removeAttribute_1](name);
      return;
    }
    [_removeAttribute_1](name) {
      return wrap_jso(this.raw.removeAttribute(unwrap_jso(name)));
    }
    [_removeAttributeNS](namespaceURI, localName) {
      this[_removeAttributeNS_1](namespaceURI, localName);
      return;
    }
    [_removeAttributeNS_1](namespaceURI, localName) {
      return wrap_jso(this.raw.removeAttributeNS(unwrap_jso(namespaceURI), unwrap_jso(localName)));
    }
    requestFullscreen() {
      this[_requestFullscreen_1]();
      return;
    }
    [_requestFullscreen_1]() {
      return wrap_jso(this.raw.requestFullscreen());
    }
    requestPointerLock() {
      this[_requestPointerLock_1]();
      return;
    }
    [_requestPointerLock_1]() {
      return wrap_jso(this.raw.requestPointerLock());
    }
    [_scrollIntoView](alignWithTop) {
      if (alignWithTop === void 0) alignWithTop = null;
      if (alignWithTop != null) {
        this[_scrollIntoView_1](alignWithTop);
        return;
      }
      this[_scrollIntoView_2]();
      return;
    }
    [_scrollIntoView_1](alignWithTop) {
      return wrap_jso(this.raw.scrollIntoView(unwrap_jso(alignWithTop)));
    }
    [_scrollIntoView_2]() {
      return wrap_jso(this.raw.scrollIntoView());
    }
    [_scrollIntoViewIfNeeded](centerIfNeeded) {
      if (centerIfNeeded === void 0) centerIfNeeded = null;
      if (centerIfNeeded != null) {
        this[_scrollIntoViewIfNeeded_1](centerIfNeeded);
        return;
      }
      this[_scrollIntoViewIfNeeded_2]();
      return;
    }
    [_scrollIntoViewIfNeeded_1](centerIfNeeded) {
      return wrap_jso(this.raw.scrollIntoViewIfNeeded(unwrap_jso(centerIfNeeded)));
    }
    [_scrollIntoViewIfNeeded_2]() {
      return wrap_jso(this.raw.scrollIntoViewIfNeeded());
    }
    setAttribute(name, value) {
      this[_setAttribute_1](name, value);
      return;
    }
    [_setAttribute_1](name, value) {
      return wrap_jso(this.raw.setAttribute(unwrap_jso(name), unwrap_jso(value)));
    }
    setAttributeNS(namespaceURI, qualifiedName, value) {
      this[_setAttributeNS_1](namespaceURI, qualifiedName, value);
      return;
    }
    [_setAttributeNS_1](namespaceURI, qualifiedName, value) {
      return wrap_jso(this.raw.setAttributeNS(unwrap_jso(namespaceURI), unwrap_jso(qualifiedName), unwrap_jso(value)));
    }
    get nextElementSibling() {
      return dart.as(wrap_jso(this.raw.nextElementSibling), Element);
    }
    get previousElementSibling() {
      return dart.as(wrap_jso(this.raw.previousElementSibling), Element);
    }
    get [_childElementCount]() {
      return dart.as(wrap_jso(this.raw.childElementCount), core.int);
    }
    get [_children]() {
      return dart.as(wrap_jso(this.raw.children), core.List$(Node));
    }
    get [_firstElementChild]() {
      return dart.as(wrap_jso(this.raw.firstElementChild), Element);
    }
    get [_lastElementChild]() {
      return dart.as(wrap_jso(this.raw.lastElementChild), Element);
    }
    querySelector(selectors) {
      return this[_querySelector_1](selectors);
    }
    [_querySelector_1](selectors) {
      return dart.as(wrap_jso(this.raw.querySelector(unwrap_jso(selectors))), Element);
    }
    [_querySelectorAll](selectors) {
      return this[_querySelectorAll_1](selectors);
    }
    [_querySelectorAll_1](selectors) {
      return dart.as(wrap_jso(this.raw.querySelectorAll(unwrap_jso(selectors))), NodeList);
    }
    get onBeforeCopy() {
      return Element.beforeCopyEvent.forElement(this);
    }
    get onBeforeCut() {
      return Element.beforeCutEvent.forElement(this);
    }
    get onBeforePaste() {
      return Element.beforePasteEvent.forElement(this);
    }
    get onCopy() {
      return Element.copyEvent.forElement(this);
    }
    get onCut() {
      return Element.cutEvent.forElement(this);
    }
    get onPaste() {
      return Element.pasteEvent.forElement(this);
    }
    get onSearch() {
      return Element.searchEvent.forElement(this);
    }
    get onSelectStart() {
      return Element.selectStartEvent.forElement(this);
    }
    get onFullscreenChange() {
      return Element.fullscreenChangeEvent.forElement(this);
    }
    get onFullscreenError() {
      return Element.fullscreenErrorEvent.forElement(this);
    }
  }
  Element[dart.implements] = () => [ParentNode, ChildNode];
  dart.defineNamedConstructor(Element, 'created');
  dart.defineNamedConstructor(Element, 'internal_');
  dart.setSignature(Element, {
    constructors: () => ({
      html: [Element, [core.String], {validator: NodeValidator, treeSanitizer: NodeTreeSanitizer}],
      created: [Element, []],
      tag: [Element, [core.String], [core.String]],
      a: [Element, []],
      article: [Element, []],
      aside: [Element, []],
      audio: [Element, []],
      br: [Element, []],
      canvas: [Element, []],
      div: [Element, []],
      footer: [Element, []],
      header: [Element, []],
      hr: [Element, []],
      iframe: [Element, []],
      img: [Element, []],
      li: [Element, []],
      nav: [Element, []],
      ol: [Element, []],
      option: [Element, []],
      p: [Element, []],
      pre: [Element, []],
      section: [Element, []],
      select: [Element, []],
      span: [Element, []],
      svg: [Element, []],
      table: [Element, []],
      td: [Element, []],
      textarea: [Element, []],
      th: [Element, []],
      tr: [Element, []],
      ul: [Element, []],
      video: [Element, []],
      _: [Element, []],
      internal_: [Element, []]
    }),
    methods: () => ({
      querySelectorAll: [ElementList$(Element), [core.String]],
      query: [Element, [core.String]],
      queryAll: [ElementList$(Element), [core.String]],
      getNamespacedAttributes: [core.Map$(core.String, core.String), [core.String]],
      getComputedStyle: [CssStyleDeclaration, [], [core.String]],
      appendText: [dart.void, [core.String]],
      appendHtml: [dart.void, [core.String], {validator: NodeValidator, treeSanitizer: NodeTreeSanitizer}],
      attached: [dart.void, []],
      detached: [dart.void, []],
      enteredView: [dart.void, []],
      leftView: [dart.void, []],
      attributeChanged: [dart.void, [core.String, core.String, core.String]],
      scrollIntoView: [dart.void, [], [ScrollAlignment]],
      insertAdjacentHtml: [dart.void, [core.String, core.String], {validator: NodeValidator, treeSanitizer: NodeTreeSanitizer}],
      [_insertAdjacentHtml]: [dart.void, [core.String, core.String]],
      [_insertAdjacentNode]: [dart.void, [core.String, Node]],
      matches: [core.bool, [core.String]],
      matchesWithAncestors: [core.bool, [core.String]],
      offsetTo: [math.Point, [Element]],
      createFragment: [DocumentFragment, [core.String], {validator: NodeValidator, treeSanitizer: NodeTreeSanitizer}],
      setInnerHtml: [dart.void, [core.String], {validator: NodeValidator, treeSanitizer: NodeTreeSanitizer}],
      click: [dart.void, []],
      [_click_1]: [dart.void, []],
      blur: [dart.void, []],
      [_blur_1]: [dart.void, []],
      focus: [dart.void, []],
      [_focus_1]: [dart.void, []],
      getAttribute: [core.String, [core.String]],
      [_getAttribute_1]: [core.String, [dart.dynamic]],
      getAttributeNS: [core.String, [core.String, core.String]],
      [_getAttributeNS_1]: [core.String, [dart.dynamic, dart.dynamic]],
      getBoundingClientRect: [math.Rectangle, []],
      [_getBoundingClientRect_1]: [math.Rectangle, []],
      getDestinationInsertionPoints: [NodeList, []],
      [_getDestinationInsertionPoints_1]: [NodeList, []],
      getElementsByClassName: [HtmlCollection, [core.String]],
      [_getElementsByClassName_1]: [HtmlCollection, [dart.dynamic]],
      [_getElementsByTagName]: [HtmlCollection, [core.String]],
      [_getElementsByTagName_1]: [HtmlCollection, [dart.dynamic]],
      [_hasAttribute]: [core.bool, [core.String]],
      [_hasAttribute_1]: [core.bool, [dart.dynamic]],
      [_hasAttributeNS]: [core.bool, [core.String, core.String]],
      [_hasAttributeNS_1]: [core.bool, [dart.dynamic, dart.dynamic]],
      [_removeAttribute]: [dart.void, [core.String]],
      [_removeAttribute_1]: [dart.void, [dart.dynamic]],
      [_removeAttributeNS]: [dart.void, [core.String, core.String]],
      [_removeAttributeNS_1]: [dart.void, [dart.dynamic, dart.dynamic]],
      requestFullscreen: [dart.void, []],
      [_requestFullscreen_1]: [dart.void, []],
      requestPointerLock: [dart.void, []],
      [_requestPointerLock_1]: [dart.void, []],
      [_scrollIntoView]: [dart.void, [], [core.bool]],
      [_scrollIntoView_1]: [dart.void, [dart.dynamic]],
      [_scrollIntoView_2]: [dart.void, []],
      [_scrollIntoViewIfNeeded]: [dart.void, [], [core.bool]],
      [_scrollIntoViewIfNeeded_1]: [dart.void, [dart.dynamic]],
      [_scrollIntoViewIfNeeded_2]: [dart.void, []],
      setAttribute: [dart.void, [core.String, core.String]],
      [_setAttribute_1]: [dart.void, [dart.dynamic, dart.dynamic]],
      setAttributeNS: [dart.void, [core.String, core.String, core.String]],
      [_setAttributeNS_1]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic]],
      querySelector: [Element, [core.String]],
      [_querySelector_1]: [Element, [dart.dynamic]],
      [_querySelectorAll]: [NodeList, [core.String]],
      [_querySelectorAll_1]: [NodeList, [dart.dynamic]]
    }),
    statics: () => ({
      isTagSupported: [core.bool, [core.String]],
      _offsetToHelper: [math.Point, [Element, Element]],
      _hasCorruptedAttributes: [core.bool, [Element]],
      _hasCorruptedAttributesAdditionalCheck: [core.bool, [Element]],
      _safeTagName: [core.String, [dart.dynamic]],
      internalCreateElement: [Element, []]
    }),
    names: ['isTagSupported', '_offsetToHelper', '_hasCorruptedAttributes', '_hasCorruptedAttributesAdditionalCheck', '_safeTagName', 'internalCreateElement']
  });
  Element[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('Element')), dart.const(new _js_helper.Native("Element"))];
  Element._parseDocument = null;
  Element._parseRange = null;
  Element._defaultValidator = null;
  Element._defaultSanitizer = null;
  Element._tagsForWhichCreateContextualFragmentIsNotSupported = dart.const(['HEAD', 'AREA', 'BASE', 'BASEFONT', 'BR', 'COL', 'COLGROUP', 'EMBED', 'FRAME', 'FRAMESET', 'HR', 'IMAGE', 'IMG', 'INPUT', 'ISINDEX', 'LINK', 'META', 'PARAM', 'SOURCE', 'STYLE', 'TITLE', 'WBR']);
  dart.defineLazyProperties(Element, {
    get beforeCopyEvent() {
      return dart.const(new (EventStreamProvider$(Event))('beforecopy'));
    },
    get beforeCutEvent() {
      return dart.const(new (EventStreamProvider$(Event))('beforecut'));
    },
    get beforePasteEvent() {
      return dart.const(new (EventStreamProvider$(Event))('beforepaste'));
    },
    get copyEvent() {
      return dart.const(new (EventStreamProvider$(Event))('copy'));
    },
    get cutEvent() {
      return dart.const(new (EventStreamProvider$(Event))('cut'));
    },
    get pasteEvent() {
      return dart.const(new (EventStreamProvider$(Event))('paste'));
    },
    get searchEvent() {
      return dart.const(new (EventStreamProvider$(Event))('search'));
    },
    get selectStartEvent() {
      return dart.const(new (EventStreamProvider$(Event))('selectstart'));
    },
    get fullscreenChangeEvent() {
      return dart.const(new (EventStreamProvider$(Event))('webkitfullscreenchange'));
    },
    get fullscreenErrorEvent() {
      return dart.const(new (EventStreamProvider$(Event))('webkitfullscreenerror'));
    }
  });
  class HtmlElement extends Element {
    static new() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    created() {
      super.created();
    }
    internal_() {
      super.internal_();
    }
    static internalCreateHtmlElement() {
      return HtmlElement._internalWrap();
    }
    static _internalWrap() {
      return new HtmlElement.internal_();
    }
  }
  dart.defineNamedConstructor(HtmlElement, 'created');
  dart.defineNamedConstructor(HtmlElement, 'internal_');
  dart.setSignature(HtmlElement, {
    constructors: () => ({
      new: [HtmlElement, []],
      created: [HtmlElement, []],
      internal_: [HtmlElement, []],
      _internalWrap: [HtmlElement, []]
    }),
    statics: () => ({internalCreateHtmlElement: [HtmlElement, []]}),
    names: ['internalCreateHtmlElement']
  });
  HtmlElement[dart.metadata] = () => [dart.const(new _js_helper.Native("HTMLElement"))];
  class AnchorElement extends HtmlElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new(opts) {
      let href = opts && 'href' in opts ? opts.href : null;
      let e = dart.as(exports.document.createElement("a"), AnchorElement);
      if (href != null) e.href = href;
      return e;
    }
    static internalCreateAnchorElement() {
      return new AnchorElement.internal_();
    }
    internal_() {
      super.internal_();
    }
    get download() {
      return dart.as(wrap_jso(this.raw.download), core.String);
    }
    set download(val) {
      return this.raw.download = unwrap_jso(val);
    }
    get hreflang() {
      return dart.as(wrap_jso(this.raw.hreflang), core.String);
    }
    set hreflang(val) {
      return this.raw.hreflang = unwrap_jso(val);
    }
    get integrity() {
      return dart.as(wrap_jso(this.raw.integrity), core.String);
    }
    set integrity(val) {
      return this.raw.integrity = unwrap_jso(val);
    }
    get rel() {
      return dart.as(wrap_jso(this.raw.rel), core.String);
    }
    set rel(val) {
      return this.raw.rel = unwrap_jso(val);
    }
    get target() {
      return dart.as(wrap_jso(this.raw.target), core.String);
    }
    set target(val) {
      return this.raw.target = unwrap_jso(val);
    }
    get type() {
      return dart.as(wrap_jso(this.raw.type), core.String);
    }
    set type(val) {
      return this.raw.type = unwrap_jso(val);
    }
    get hash() {
      return dart.as(wrap_jso(this.raw.hash), core.String);
    }
    set hash(val) {
      return this.raw.hash = unwrap_jso(val);
    }
    get host() {
      return dart.as(wrap_jso(this.raw.host), core.String);
    }
    set host(val) {
      return this.raw.host = unwrap_jso(val);
    }
    get hostname() {
      return dart.as(wrap_jso(this.raw.hostname), core.String);
    }
    set hostname(val) {
      return this.raw.hostname = unwrap_jso(val);
    }
    get href() {
      return dart.as(wrap_jso(this.raw.href), core.String);
    }
    set href(val) {
      return this.raw.href = unwrap_jso(val);
    }
    get origin() {
      return dart.as(wrap_jso(this.raw.origin), core.String);
    }
    get password() {
      return dart.as(wrap_jso(this.raw.password), core.String);
    }
    set password(val) {
      return this.raw.password = unwrap_jso(val);
    }
    get pathname() {
      return dart.as(wrap_jso(this.raw.pathname), core.String);
    }
    set pathname(val) {
      return this.raw.pathname = unwrap_jso(val);
    }
    get port() {
      return dart.as(wrap_jso(this.raw.port), core.String);
    }
    set port(val) {
      return this.raw.port = unwrap_jso(val);
    }
    get protocol() {
      return dart.as(wrap_jso(this.raw.protocol), core.String);
    }
    set protocol(val) {
      return this.raw.protocol = unwrap_jso(val);
    }
    get search() {
      return dart.as(wrap_jso(this.raw.search), core.String);
    }
    set search(val) {
      return this.raw.search = unwrap_jso(val);
    }
    get username() {
      return dart.as(wrap_jso(this.raw.username), core.String);
    }
    set username(val) {
      return this.raw.username = unwrap_jso(val);
    }
  }
  AnchorElement[dart.implements] = () => [UrlUtils];
  dart.defineNamedConstructor(AnchorElement, 'internal_');
  dart.setSignature(AnchorElement, {
    constructors: () => ({
      _: [AnchorElement, []],
      new: [AnchorElement, [], {href: core.String}],
      internal_: [AnchorElement, []]
    }),
    statics: () => ({internalCreateAnchorElement: [AnchorElement, []]}),
    names: ['internalCreateAnchorElement']
  });
  AnchorElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('HTMLAnchorElement')), dart.const(new _js_helper.Native("HTMLAnchorElement"))];
  class BaseElement extends HtmlElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(exports.document.createElement("base"), BaseElement);
    }
    static internalCreateBaseElement() {
      return new BaseElement.internal_();
    }
    internal_() {
      super.internal_();
    }
    get href() {
      return dart.as(wrap_jso(this.raw.href), core.String);
    }
    set href(val) {
      return this.raw.href = unwrap_jso(val);
    }
    get target() {
      return dart.as(wrap_jso(this.raw.target), core.String);
    }
    set target(val) {
      return this.raw.target = unwrap_jso(val);
    }
  }
  dart.defineNamedConstructor(BaseElement, 'internal_');
  dart.setSignature(BaseElement, {
    constructors: () => ({
      _: [BaseElement, []],
      new: [BaseElement, []],
      internal_: [BaseElement, []]
    }),
    statics: () => ({internalCreateBaseElement: [BaseElement, []]}),
    names: ['internalCreateBaseElement']
  });
  BaseElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('HTMLBaseElement')), dart.const(new _js_helper.Native("HTMLBaseElement"))];
  class BodyElement extends HtmlElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(exports.document.createElement("body"), BodyElement);
    }
    static internalCreateBodyElement() {
      return new BodyElement.internal_();
    }
    internal_() {
      super.internal_();
    }
    get onBlur() {
      return BodyElement.blurEvent.forElement(this);
    }
    get onError() {
      return BodyElement.errorEvent.forElement(this);
    }
    get onFocus() {
      return BodyElement.focusEvent.forElement(this);
    }
    get onLoad() {
      return BodyElement.loadEvent.forElement(this);
    }
    get onResize() {
      return BodyElement.resizeEvent.forElement(this);
    }
    get onScroll() {
      return BodyElement.scrollEvent.forElement(this);
    }
  }
  dart.defineNamedConstructor(BodyElement, 'internal_');
  dart.setSignature(BodyElement, {
    constructors: () => ({
      _: [BodyElement, []],
      new: [BodyElement, []],
      internal_: [BodyElement, []]
    }),
    statics: () => ({internalCreateBodyElement: [BodyElement, []]}),
    names: ['internalCreateBodyElement']
  });
  BodyElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('HTMLBodyElement')), dart.const(new _js_helper.Native("HTMLBodyElement"))];
  dart.defineLazyProperties(BodyElement, {
    get blurEvent() {
      return dart.const(new (EventStreamProvider$(Event))('blur'));
    },
    get errorEvent() {
      return dart.const(new (EventStreamProvider$(Event))('error'));
    },
    get focusEvent() {
      return dart.const(new (EventStreamProvider$(Event))('focus'));
    },
    get loadEvent() {
      return dart.const(new (EventStreamProvider$(Event))('load'));
    },
    get resizeEvent() {
      return dart.const(new (EventStreamProvider$(Event))('resize'));
    },
    get scrollEvent() {
      return dart.const(new (EventStreamProvider$(Event))('scroll'));
    }
  });
  const _appendData_1 = Symbol('_appendData_1');
  const _deleteData_1 = Symbol('_deleteData_1');
  const _insertData_1 = Symbol('_insertData_1');
  const _replaceData_1 = Symbol('_replaceData_1');
  const _substringData_1 = Symbol('_substringData_1');
  class CharacterData extends Node {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateCharacterData() {
      return new CharacterData.internal_();
    }
    internal_() {
      super.internal_();
    }
    get data() {
      return dart.as(wrap_jso(this.raw.data), core.String);
    }
    set data(val) {
      return this.raw.data = unwrap_jso(val);
    }
    get length() {
      return dart.as(wrap_jso(this.raw.length), core.int);
    }
    appendData(data) {
      this[_appendData_1](data);
      return;
    }
    [_appendData_1](data) {
      return wrap_jso(this.raw.appendData(unwrap_jso(data)));
    }
    deleteData(offset, length) {
      this[_deleteData_1](offset, length);
      return;
    }
    [_deleteData_1](offset, length) {
      return wrap_jso(this.raw.deleteData(unwrap_jso(offset), unwrap_jso(length)));
    }
    insertData(offset, data) {
      this[_insertData_1](offset, data);
      return;
    }
    [_insertData_1](offset, data) {
      return wrap_jso(this.raw.insertData(unwrap_jso(offset), unwrap_jso(data)));
    }
    replaceData(offset, length, data) {
      this[_replaceData_1](offset, length, data);
      return;
    }
    [_replaceData_1](offset, length, data) {
      return wrap_jso(this.raw.replaceData(unwrap_jso(offset), unwrap_jso(length), unwrap_jso(data)));
    }
    substringData(offset, length) {
      return this[_substringData_1](offset, length);
    }
    [_substringData_1](offset, length) {
      return dart.as(wrap_jso(this.raw.substringData(unwrap_jso(offset), unwrap_jso(length))), core.String);
    }
    get nextElementSibling() {
      return dart.as(wrap_jso(this.raw.nextElementSibling), Element);
    }
    get previousElementSibling() {
      return dart.as(wrap_jso(this.raw.previousElementSibling), Element);
    }
  }
  CharacterData[dart.implements] = () => [ChildNode];
  dart.defineNamedConstructor(CharacterData, 'internal_');
  dart.setSignature(CharacterData, {
    constructors: () => ({
      _: [CharacterData, []],
      internal_: [CharacterData, []]
    }),
    methods: () => ({
      appendData: [dart.void, [core.String]],
      [_appendData_1]: [dart.void, [dart.dynamic]],
      deleteData: [dart.void, [core.int, core.int]],
      [_deleteData_1]: [dart.void, [dart.dynamic, dart.dynamic]],
      insertData: [dart.void, [core.int, core.String]],
      [_insertData_1]: [dart.void, [dart.dynamic, dart.dynamic]],
      replaceData: [dart.void, [core.int, core.int, core.String]],
      [_replaceData_1]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic]],
      substringData: [core.String, [core.int, core.int]],
      [_substringData_1]: [core.String, [dart.dynamic, dart.dynamic]]
    }),
    statics: () => ({internalCreateCharacterData: [CharacterData, []]}),
    names: ['internalCreateCharacterData']
  });
  CharacterData[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('CharacterData')), dart.const(new _js_helper.Native("CharacterData"))];
  class ChildNode extends DartHtmlDomObject {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get nextElementSibling() {
      return dart.as(wrap_jso(this.raw.nextElementSibling), Element);
    }
    get previousElementSibling() {
      return dart.as(wrap_jso(this.raw.previousElementSibling), Element);
    }
    remove() {
      return wrap_jso(this.raw.remove());
    }
  }
  dart.setSignature(ChildNode, {
    constructors: () => ({_: [ChildNode, []]}),
    methods: () => ({remove: [dart.void, []]})
  });
  ChildNode[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('ChildNode')), dart.const(new _metadata.Experimental())];
  class Comment extends CharacterData {
    static new(data) {
      if (data === void 0) data = null;
      if (data != null) {
        return dart.as(wrap_jso(exports.document.raw.createComment(data)), Comment);
      }
      return dart.as(wrap_jso(exports.document.raw.createComment("")), Comment);
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateComment() {
      return new Comment.internal_();
    }
    internal_() {
      super.internal_();
    }
  }
  dart.defineNamedConstructor(Comment, 'internal_');
  dart.setSignature(Comment, {
    constructors: () => ({
      new: [Comment, [], [core.String]],
      _: [Comment, []],
      internal_: [Comment, []]
    }),
    statics: () => ({internalCreateComment: [Comment, []]}),
    names: ['internalCreateComment']
  });
  Comment[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('Comment')), dart.const(new _js_helper.Native("Comment"))];
  const _isConsoleDefined = Symbol('_isConsoleDefined');
  class Console extends DartHtmlDomObject {
    _safe() {
      super.DartHtmlDomObject();
    }
    get [_isConsoleDefined]() {
      return typeof console != "undefined";
    }
    assertCondition(condition, arg) {
      return dart.notNull(this[_isConsoleDefined]) ? console.assertCondition(condition, arg) : null;
    }
    clear(arg) {
      return dart.notNull(this[_isConsoleDefined]) ? console.clear(arg) : null;
    }
    count(arg) {
      return dart.notNull(this[_isConsoleDefined]) ? console.count(arg) : null;
    }
    debug(arg) {
      return dart.notNull(this[_isConsoleDefined]) ? console.debug(arg) : null;
    }
    dir(arg) {
      return dart.notNull(this[_isConsoleDefined]) ? console.dir(arg) : null;
    }
    dirxml(arg) {
      return dart.notNull(this[_isConsoleDefined]) ? console.dirxml(arg) : null;
    }
    error(arg) {
      return dart.notNull(this[_isConsoleDefined]) ? console.error(arg) : null;
    }
    group(arg) {
      return dart.notNull(this[_isConsoleDefined]) ? console.group(arg) : null;
    }
    groupCollapsed(arg) {
      return dart.notNull(this[_isConsoleDefined]) ? console.groupCollapsed(arg) : null;
    }
    groupEnd() {
      return dart.notNull(this[_isConsoleDefined]) ? console.groupEnd() : null;
    }
    info(arg) {
      return dart.notNull(this[_isConsoleDefined]) ? console.info(arg) : null;
    }
    log(arg) {
      return dart.notNull(this[_isConsoleDefined]) ? console.log(arg) : null;
    }
    markTimeline(arg) {
      return dart.notNull(this[_isConsoleDefined]) ? console.markTimeline(arg) : null;
    }
    profile(title) {
      return dart.notNull(this[_isConsoleDefined]) ? console.profile(title) : null;
    }
    profileEnd(title) {
      return dart.notNull(this[_isConsoleDefined]) ? console.profileEnd(title) : null;
    }
    table(arg) {
      return dart.notNull(this[_isConsoleDefined]) ? console.table(arg) : null;
    }
    time(title) {
      return dart.notNull(this[_isConsoleDefined]) ? console.time(title) : null;
    }
    timeEnd(title) {
      return dart.notNull(this[_isConsoleDefined]) ? console.timeEnd(title) : null;
    }
    timeStamp(arg) {
      return dart.notNull(this[_isConsoleDefined]) ? console.timeStamp(arg) : null;
    }
    trace(arg) {
      return dart.notNull(this[_isConsoleDefined]) ? console.trace(arg) : null;
    }
    warn(arg) {
      return dart.notNull(this[_isConsoleDefined]) ? console.warn(arg) : null;
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateConsole() {
      return new Console.internal_();
    }
    internal_() {
      super.internal_();
    }
  }
  dart.defineNamedConstructor(Console, '_safe');
  dart.defineNamedConstructor(Console, 'internal_');
  dart.setSignature(Console, {
    constructors: () => ({
      _safe: [Console, []],
      _: [Console, []],
      internal_: [Console, []]
    }),
    methods: () => ({
      assertCondition: [dart.void, [core.bool, core.Object]],
      clear: [dart.void, [core.Object]],
      count: [dart.void, [core.Object]],
      debug: [dart.void, [core.Object]],
      dir: [dart.void, [core.Object]],
      dirxml: [dart.void, [core.Object]],
      error: [dart.void, [core.Object]],
      group: [dart.void, [core.Object]],
      groupCollapsed: [dart.void, [core.Object]],
      groupEnd: [dart.void, []],
      info: [dart.void, [core.Object]],
      log: [dart.void, [core.Object]],
      markTimeline: [dart.void, [core.Object]],
      profile: [dart.void, [core.String]],
      profileEnd: [dart.void, [core.String]],
      table: [dart.void, [core.Object]],
      time: [dart.void, [core.String]],
      timeEnd: [dart.void, [core.String]],
      timeStamp: [dart.void, [core.Object]],
      trace: [dart.void, [core.Object]],
      warn: [dart.void, [core.Object]]
    }),
    statics: () => ({internalCreateConsole: [Console, []]}),
    names: ['internalCreateConsole']
  });
  Console[dart.metadata] = () => [dart.const(new _metadata.DomName('Console'))];
  dart.defineLazyProperties(Console, {
    get _safeConsole() {
      return new Console._safe();
    }
  });
  const _timeline_1 = Symbol('_timeline_1');
  const _timelineEnd_1 = Symbol('_timelineEnd_1');
  class ConsoleBase extends DartHtmlDomObject {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateConsoleBase() {
      return new ConsoleBase.internal_();
    }
    internal_() {
      super.DartHtmlDomObject();
    }
    ['=='](other) {
      return dart.equals(unwrap_jso(other), unwrap_jso(this)) || dart.notNull(core.identical(this, other));
    }
    get hashCode() {
      return dart.hashCode(unwrap_jso(this));
    }
    timeline(title) {
      this[_timeline_1](title);
      return;
    }
    [_timeline_1](title) {
      return wrap_jso(this.raw.timeline(unwrap_jso(title)));
    }
    timelineEnd(title) {
      this[_timelineEnd_1](title);
      return;
    }
    [_timelineEnd_1](title) {
      return wrap_jso(this.raw.timelineEnd(unwrap_jso(title)));
    }
  }
  dart.defineNamedConstructor(ConsoleBase, 'internal_');
  dart.setSignature(ConsoleBase, {
    constructors: () => ({
      _: [ConsoleBase, []],
      internal_: [ConsoleBase, []]
    }),
    methods: () => ({
      timeline: [dart.void, [core.String]],
      [_timeline_1]: [dart.void, [dart.dynamic]],
      timelineEnd: [dart.void, [core.String]],
      [_timelineEnd_1]: [dart.void, [dart.dynamic]]
    }),
    statics: () => ({internalCreateConsoleBase: [ConsoleBase, []]}),
    names: ['internalCreateConsoleBase']
  });
  ConsoleBase[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('ConsoleBase')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("ConsoleBase"))];
  class CssStyleDeclarationBase extends core.Object {
    getPropertyValue(propertyName) {
      return dart.throw(new core.StateError('getProperty not overridden in dart:html'));
    }
    setProperty(propertyName, value, priority) {
      if (priority === void 0) priority = null;
      return dart.throw(new core.StateError('setProperty not overridden in dart:html'));
    }
    get alignContent() {
      return this.getPropertyValue('align-content');
    }
    set alignContent(value) {
      this.setProperty('align-content', value, '');
    }
    get alignItems() {
      return this.getPropertyValue('align-items');
    }
    set alignItems(value) {
      this.setProperty('align-items', value, '');
    }
    get alignSelf() {
      return this.getPropertyValue('align-self');
    }
    set alignSelf(value) {
      this.setProperty('align-self', value, '');
    }
    get animation() {
      return this.getPropertyValue('animation');
    }
    set animation(value) {
      this.setProperty('animation', value, '');
    }
    get animationDelay() {
      return this.getPropertyValue('animation-delay');
    }
    set animationDelay(value) {
      this.setProperty('animation-delay', value, '');
    }
    get animationDirection() {
      return this.getPropertyValue('animation-direction');
    }
    set animationDirection(value) {
      this.setProperty('animation-direction', value, '');
    }
    get animationDuration() {
      return this.getPropertyValue('animation-duration');
    }
    set animationDuration(value) {
      this.setProperty('animation-duration', value, '');
    }
    get animationFillMode() {
      return this.getPropertyValue('animation-fill-mode');
    }
    set animationFillMode(value) {
      this.setProperty('animation-fill-mode', value, '');
    }
    get animationIterationCount() {
      return this.getPropertyValue('animation-iteration-count');
    }
    set animationIterationCount(value) {
      this.setProperty('animation-iteration-count', value, '');
    }
    get animationName() {
      return this.getPropertyValue('animation-name');
    }
    set animationName(value) {
      this.setProperty('animation-name', value, '');
    }
    get animationPlayState() {
      return this.getPropertyValue('animation-play-state');
    }
    set animationPlayState(value) {
      this.setProperty('animation-play-state', value, '');
    }
    get animationTimingFunction() {
      return this.getPropertyValue('animation-timing-function');
    }
    set animationTimingFunction(value) {
      this.setProperty('animation-timing-function', value, '');
    }
    get appRegion() {
      return this.getPropertyValue('app-region');
    }
    set appRegion(value) {
      this.setProperty('app-region', value, '');
    }
    get appearance() {
      return this.getPropertyValue('appearance');
    }
    set appearance(value) {
      this.setProperty('appearance', value, '');
    }
    get aspectRatio() {
      return this.getPropertyValue('aspect-ratio');
    }
    set aspectRatio(value) {
      this.setProperty('aspect-ratio', value, '');
    }
    get backfaceVisibility() {
      return this.getPropertyValue('backface-visibility');
    }
    set backfaceVisibility(value) {
      this.setProperty('backface-visibility', value, '');
    }
    get background() {
      return this.getPropertyValue('background');
    }
    set background(value) {
      this.setProperty('background', value, '');
    }
    get backgroundAttachment() {
      return this.getPropertyValue('background-attachment');
    }
    set backgroundAttachment(value) {
      this.setProperty('background-attachment', value, '');
    }
    get backgroundBlendMode() {
      return this.getPropertyValue('background-blend-mode');
    }
    set backgroundBlendMode(value) {
      this.setProperty('background-blend-mode', value, '');
    }
    get backgroundClip() {
      return this.getPropertyValue('background-clip');
    }
    set backgroundClip(value) {
      this.setProperty('background-clip', value, '');
    }
    get backgroundColor() {
      return this.getPropertyValue('background-color');
    }
    set backgroundColor(value) {
      this.setProperty('background-color', value, '');
    }
    get backgroundComposite() {
      return this.getPropertyValue('background-composite');
    }
    set backgroundComposite(value) {
      this.setProperty('background-composite', value, '');
    }
    get backgroundImage() {
      return this.getPropertyValue('background-image');
    }
    set backgroundImage(value) {
      this.setProperty('background-image', value, '');
    }
    get backgroundOrigin() {
      return this.getPropertyValue('background-origin');
    }
    set backgroundOrigin(value) {
      this.setProperty('background-origin', value, '');
    }
    get backgroundPosition() {
      return this.getPropertyValue('background-position');
    }
    set backgroundPosition(value) {
      this.setProperty('background-position', value, '');
    }
    get backgroundPositionX() {
      return this.getPropertyValue('background-position-x');
    }
    set backgroundPositionX(value) {
      this.setProperty('background-position-x', value, '');
    }
    get backgroundPositionY() {
      return this.getPropertyValue('background-position-y');
    }
    set backgroundPositionY(value) {
      this.setProperty('background-position-y', value, '');
    }
    get backgroundRepeat() {
      return this.getPropertyValue('background-repeat');
    }
    set backgroundRepeat(value) {
      this.setProperty('background-repeat', value, '');
    }
    get backgroundRepeatX() {
      return this.getPropertyValue('background-repeat-x');
    }
    set backgroundRepeatX(value) {
      this.setProperty('background-repeat-x', value, '');
    }
    get backgroundRepeatY() {
      return this.getPropertyValue('background-repeat-y');
    }
    set backgroundRepeatY(value) {
      this.setProperty('background-repeat-y', value, '');
    }
    get backgroundSize() {
      return this.getPropertyValue('background-size');
    }
    set backgroundSize(value) {
      this.setProperty('background-size', value, '');
    }
    get border() {
      return this.getPropertyValue('border');
    }
    set border(value) {
      this.setProperty('border', value, '');
    }
    get borderAfter() {
      return this.getPropertyValue('border-after');
    }
    set borderAfter(value) {
      this.setProperty('border-after', value, '');
    }
    get borderAfterColor() {
      return this.getPropertyValue('border-after-color');
    }
    set borderAfterColor(value) {
      this.setProperty('border-after-color', value, '');
    }
    get borderAfterStyle() {
      return this.getPropertyValue('border-after-style');
    }
    set borderAfterStyle(value) {
      this.setProperty('border-after-style', value, '');
    }
    get borderAfterWidth() {
      return this.getPropertyValue('border-after-width');
    }
    set borderAfterWidth(value) {
      this.setProperty('border-after-width', value, '');
    }
    get borderBefore() {
      return this.getPropertyValue('border-before');
    }
    set borderBefore(value) {
      this.setProperty('border-before', value, '');
    }
    get borderBeforeColor() {
      return this.getPropertyValue('border-before-color');
    }
    set borderBeforeColor(value) {
      this.setProperty('border-before-color', value, '');
    }
    get borderBeforeStyle() {
      return this.getPropertyValue('border-before-style');
    }
    set borderBeforeStyle(value) {
      this.setProperty('border-before-style', value, '');
    }
    get borderBeforeWidth() {
      return this.getPropertyValue('border-before-width');
    }
    set borderBeforeWidth(value) {
      this.setProperty('border-before-width', value, '');
    }
    get borderBottom() {
      return this.getPropertyValue('border-bottom');
    }
    set borderBottom(value) {
      this.setProperty('border-bottom', value, '');
    }
    get borderBottomColor() {
      return this.getPropertyValue('border-bottom-color');
    }
    set borderBottomColor(value) {
      this.setProperty('border-bottom-color', value, '');
    }
    get borderBottomLeftRadius() {
      return this.getPropertyValue('border-bottom-left-radius');
    }
    set borderBottomLeftRadius(value) {
      this.setProperty('border-bottom-left-radius', value, '');
    }
    get borderBottomRightRadius() {
      return this.getPropertyValue('border-bottom-right-radius');
    }
    set borderBottomRightRadius(value) {
      this.setProperty('border-bottom-right-radius', value, '');
    }
    get borderBottomStyle() {
      return this.getPropertyValue('border-bottom-style');
    }
    set borderBottomStyle(value) {
      this.setProperty('border-bottom-style', value, '');
    }
    get borderBottomWidth() {
      return this.getPropertyValue('border-bottom-width');
    }
    set borderBottomWidth(value) {
      this.setProperty('border-bottom-width', value, '');
    }
    get borderCollapse() {
      return this.getPropertyValue('border-collapse');
    }
    set borderCollapse(value) {
      this.setProperty('border-collapse', value, '');
    }
    get borderColor() {
      return this.getPropertyValue('border-color');
    }
    set borderColor(value) {
      this.setProperty('border-color', value, '');
    }
    get borderEnd() {
      return this.getPropertyValue('border-end');
    }
    set borderEnd(value) {
      this.setProperty('border-end', value, '');
    }
    get borderEndColor() {
      return this.getPropertyValue('border-end-color');
    }
    set borderEndColor(value) {
      this.setProperty('border-end-color', value, '');
    }
    get borderEndStyle() {
      return this.getPropertyValue('border-end-style');
    }
    set borderEndStyle(value) {
      this.setProperty('border-end-style', value, '');
    }
    get borderEndWidth() {
      return this.getPropertyValue('border-end-width');
    }
    set borderEndWidth(value) {
      this.setProperty('border-end-width', value, '');
    }
    get borderFit() {
      return this.getPropertyValue('border-fit');
    }
    set borderFit(value) {
      this.setProperty('border-fit', value, '');
    }
    get borderHorizontalSpacing() {
      return this.getPropertyValue('border-horizontal-spacing');
    }
    set borderHorizontalSpacing(value) {
      this.setProperty('border-horizontal-spacing', value, '');
    }
    get borderImage() {
      return this.getPropertyValue('border-image');
    }
    set borderImage(value) {
      this.setProperty('border-image', value, '');
    }
    get borderImageOutset() {
      return this.getPropertyValue('border-image-outset');
    }
    set borderImageOutset(value) {
      this.setProperty('border-image-outset', value, '');
    }
    get borderImageRepeat() {
      return this.getPropertyValue('border-image-repeat');
    }
    set borderImageRepeat(value) {
      this.setProperty('border-image-repeat', value, '');
    }
    get borderImageSlice() {
      return this.getPropertyValue('border-image-slice');
    }
    set borderImageSlice(value) {
      this.setProperty('border-image-slice', value, '');
    }
    get borderImageSource() {
      return this.getPropertyValue('border-image-source');
    }
    set borderImageSource(value) {
      this.setProperty('border-image-source', value, '');
    }
    get borderImageWidth() {
      return this.getPropertyValue('border-image-width');
    }
    set borderImageWidth(value) {
      this.setProperty('border-image-width', value, '');
    }
    get borderLeft() {
      return this.getPropertyValue('border-left');
    }
    set borderLeft(value) {
      this.setProperty('border-left', value, '');
    }
    get borderLeftColor() {
      return this.getPropertyValue('border-left-color');
    }
    set borderLeftColor(value) {
      this.setProperty('border-left-color', value, '');
    }
    get borderLeftStyle() {
      return this.getPropertyValue('border-left-style');
    }
    set borderLeftStyle(value) {
      this.setProperty('border-left-style', value, '');
    }
    get borderLeftWidth() {
      return this.getPropertyValue('border-left-width');
    }
    set borderLeftWidth(value) {
      this.setProperty('border-left-width', value, '');
    }
    get borderRadius() {
      return this.getPropertyValue('border-radius');
    }
    set borderRadius(value) {
      this.setProperty('border-radius', value, '');
    }
    get borderRight() {
      return this.getPropertyValue('border-right');
    }
    set borderRight(value) {
      this.setProperty('border-right', value, '');
    }
    get borderRightColor() {
      return this.getPropertyValue('border-right-color');
    }
    set borderRightColor(value) {
      this.setProperty('border-right-color', value, '');
    }
    get borderRightStyle() {
      return this.getPropertyValue('border-right-style');
    }
    set borderRightStyle(value) {
      this.setProperty('border-right-style', value, '');
    }
    get borderRightWidth() {
      return this.getPropertyValue('border-right-width');
    }
    set borderRightWidth(value) {
      this.setProperty('border-right-width', value, '');
    }
    get borderSpacing() {
      return this.getPropertyValue('border-spacing');
    }
    set borderSpacing(value) {
      this.setProperty('border-spacing', value, '');
    }
    get borderStart() {
      return this.getPropertyValue('border-start');
    }
    set borderStart(value) {
      this.setProperty('border-start', value, '');
    }
    get borderStartColor() {
      return this.getPropertyValue('border-start-color');
    }
    set borderStartColor(value) {
      this.setProperty('border-start-color', value, '');
    }
    get borderStartStyle() {
      return this.getPropertyValue('border-start-style');
    }
    set borderStartStyle(value) {
      this.setProperty('border-start-style', value, '');
    }
    get borderStartWidth() {
      return this.getPropertyValue('border-start-width');
    }
    set borderStartWidth(value) {
      this.setProperty('border-start-width', value, '');
    }
    get borderStyle() {
      return this.getPropertyValue('border-style');
    }
    set borderStyle(value) {
      this.setProperty('border-style', value, '');
    }
    get borderTop() {
      return this.getPropertyValue('border-top');
    }
    set borderTop(value) {
      this.setProperty('border-top', value, '');
    }
    get borderTopColor() {
      return this.getPropertyValue('border-top-color');
    }
    set borderTopColor(value) {
      this.setProperty('border-top-color', value, '');
    }
    get borderTopLeftRadius() {
      return this.getPropertyValue('border-top-left-radius');
    }
    set borderTopLeftRadius(value) {
      this.setProperty('border-top-left-radius', value, '');
    }
    get borderTopRightRadius() {
      return this.getPropertyValue('border-top-right-radius');
    }
    set borderTopRightRadius(value) {
      this.setProperty('border-top-right-radius', value, '');
    }
    get borderTopStyle() {
      return this.getPropertyValue('border-top-style');
    }
    set borderTopStyle(value) {
      this.setProperty('border-top-style', value, '');
    }
    get borderTopWidth() {
      return this.getPropertyValue('border-top-width');
    }
    set borderTopWidth(value) {
      this.setProperty('border-top-width', value, '');
    }
    get borderVerticalSpacing() {
      return this.getPropertyValue('border-vertical-spacing');
    }
    set borderVerticalSpacing(value) {
      this.setProperty('border-vertical-spacing', value, '');
    }
    get borderWidth() {
      return this.getPropertyValue('border-width');
    }
    set borderWidth(value) {
      this.setProperty('border-width', value, '');
    }
    get bottom() {
      return this.getPropertyValue('bottom');
    }
    set bottom(value) {
      this.setProperty('bottom', value, '');
    }
    get boxAlign() {
      return this.getPropertyValue('box-align');
    }
    set boxAlign(value) {
      this.setProperty('box-align', value, '');
    }
    get boxDecorationBreak() {
      return this.getPropertyValue('box-decoration-break');
    }
    set boxDecorationBreak(value) {
      this.setProperty('box-decoration-break', value, '');
    }
    get boxDirection() {
      return this.getPropertyValue('box-direction');
    }
    set boxDirection(value) {
      this.setProperty('box-direction', value, '');
    }
    get boxFlex() {
      return this.getPropertyValue('box-flex');
    }
    set boxFlex(value) {
      this.setProperty('box-flex', value, '');
    }
    get boxFlexGroup() {
      return this.getPropertyValue('box-flex-group');
    }
    set boxFlexGroup(value) {
      this.setProperty('box-flex-group', value, '');
    }
    get boxLines() {
      return this.getPropertyValue('box-lines');
    }
    set boxLines(value) {
      this.setProperty('box-lines', value, '');
    }
    get boxOrdinalGroup() {
      return this.getPropertyValue('box-ordinal-group');
    }
    set boxOrdinalGroup(value) {
      this.setProperty('box-ordinal-group', value, '');
    }
    get boxOrient() {
      return this.getPropertyValue('box-orient');
    }
    set boxOrient(value) {
      this.setProperty('box-orient', value, '');
    }
    get boxPack() {
      return this.getPropertyValue('box-pack');
    }
    set boxPack(value) {
      this.setProperty('box-pack', value, '');
    }
    get boxReflect() {
      return this.getPropertyValue('box-reflect');
    }
    set boxReflect(value) {
      this.setProperty('box-reflect', value, '');
    }
    get boxShadow() {
      return this.getPropertyValue('box-shadow');
    }
    set boxShadow(value) {
      this.setProperty('box-shadow', value, '');
    }
    get boxSizing() {
      return this.getPropertyValue('box-sizing');
    }
    set boxSizing(value) {
      this.setProperty('box-sizing', value, '');
    }
    get captionSide() {
      return this.getPropertyValue('caption-side');
    }
    set captionSide(value) {
      this.setProperty('caption-side', value, '');
    }
    get clear() {
      return this.getPropertyValue('clear');
    }
    set clear(value) {
      this.setProperty('clear', value, '');
    }
    get clip() {
      return this.getPropertyValue('clip');
    }
    set clip(value) {
      this.setProperty('clip', value, '');
    }
    get clipPath() {
      return this.getPropertyValue('clip-path');
    }
    set clipPath(value) {
      this.setProperty('clip-path', value, '');
    }
    get color() {
      return this.getPropertyValue('color');
    }
    set color(value) {
      this.setProperty('color', value, '');
    }
    get columnBreakAfter() {
      return this.getPropertyValue('column-break-after');
    }
    set columnBreakAfter(value) {
      this.setProperty('column-break-after', value, '');
    }
    get columnBreakBefore() {
      return this.getPropertyValue('column-break-before');
    }
    set columnBreakBefore(value) {
      this.setProperty('column-break-before', value, '');
    }
    get columnBreakInside() {
      return this.getPropertyValue('column-break-inside');
    }
    set columnBreakInside(value) {
      this.setProperty('column-break-inside', value, '');
    }
    get columnCount() {
      return this.getPropertyValue('column-count');
    }
    set columnCount(value) {
      this.setProperty('column-count', value, '');
    }
    get columnFill() {
      return this.getPropertyValue('column-fill');
    }
    set columnFill(value) {
      this.setProperty('column-fill', value, '');
    }
    get columnGap() {
      return this.getPropertyValue('column-gap');
    }
    set columnGap(value) {
      this.setProperty('column-gap', value, '');
    }
    get columnRule() {
      return this.getPropertyValue('column-rule');
    }
    set columnRule(value) {
      this.setProperty('column-rule', value, '');
    }
    get columnRuleColor() {
      return this.getPropertyValue('column-rule-color');
    }
    set columnRuleColor(value) {
      this.setProperty('column-rule-color', value, '');
    }
    get columnRuleStyle() {
      return this.getPropertyValue('column-rule-style');
    }
    set columnRuleStyle(value) {
      this.setProperty('column-rule-style', value, '');
    }
    get columnRuleWidth() {
      return this.getPropertyValue('column-rule-width');
    }
    set columnRuleWidth(value) {
      this.setProperty('column-rule-width', value, '');
    }
    get columnSpan() {
      return this.getPropertyValue('column-span');
    }
    set columnSpan(value) {
      this.setProperty('column-span', value, '');
    }
    get columnWidth() {
      return this.getPropertyValue('column-width');
    }
    set columnWidth(value) {
      this.setProperty('column-width', value, '');
    }
    get columns() {
      return this.getPropertyValue('columns');
    }
    set columns(value) {
      this.setProperty('columns', value, '');
    }
    get content() {
      return this.getPropertyValue('content');
    }
    set content(value) {
      this.setProperty('content', value, '');
    }
    get counterIncrement() {
      return this.getPropertyValue('counter-increment');
    }
    set counterIncrement(value) {
      this.setProperty('counter-increment', value, '');
    }
    get counterReset() {
      return this.getPropertyValue('counter-reset');
    }
    set counterReset(value) {
      this.setProperty('counter-reset', value, '');
    }
    get cursor() {
      return this.getPropertyValue('cursor');
    }
    set cursor(value) {
      this.setProperty('cursor', value, '');
    }
    get direction() {
      return this.getPropertyValue('direction');
    }
    set direction(value) {
      this.setProperty('direction', value, '');
    }
    get display() {
      return this.getPropertyValue('display');
    }
    set display(value) {
      this.setProperty('display', value, '');
    }
    get emptyCells() {
      return this.getPropertyValue('empty-cells');
    }
    set emptyCells(value) {
      this.setProperty('empty-cells', value, '');
    }
    get filter() {
      return this.getPropertyValue('filter');
    }
    set filter(value) {
      this.setProperty('filter', value, '');
    }
    get flex() {
      return this.getPropertyValue('flex');
    }
    set flex(value) {
      this.setProperty('flex', value, '');
    }
    get flexBasis() {
      return this.getPropertyValue('flex-basis');
    }
    set flexBasis(value) {
      this.setProperty('flex-basis', value, '');
    }
    get flexDirection() {
      return this.getPropertyValue('flex-direction');
    }
    set flexDirection(value) {
      this.setProperty('flex-direction', value, '');
    }
    get flexFlow() {
      return this.getPropertyValue('flex-flow');
    }
    set flexFlow(value) {
      this.setProperty('flex-flow', value, '');
    }
    get flexGrow() {
      return this.getPropertyValue('flex-grow');
    }
    set flexGrow(value) {
      this.setProperty('flex-grow', value, '');
    }
    get flexShrink() {
      return this.getPropertyValue('flex-shrink');
    }
    set flexShrink(value) {
      this.setProperty('flex-shrink', value, '');
    }
    get flexWrap() {
      return this.getPropertyValue('flex-wrap');
    }
    set flexWrap(value) {
      this.setProperty('flex-wrap', value, '');
    }
    get float() {
      return this.getPropertyValue('float');
    }
    set float(value) {
      this.setProperty('float', value, '');
    }
    get font() {
      return this.getPropertyValue('font');
    }
    set font(value) {
      this.setProperty('font', value, '');
    }
    get fontFamily() {
      return this.getPropertyValue('font-family');
    }
    set fontFamily(value) {
      this.setProperty('font-family', value, '');
    }
    get fontFeatureSettings() {
      return this.getPropertyValue('font-feature-settings');
    }
    set fontFeatureSettings(value) {
      this.setProperty('font-feature-settings', value, '');
    }
    get fontKerning() {
      return this.getPropertyValue('font-kerning');
    }
    set fontKerning(value) {
      this.setProperty('font-kerning', value, '');
    }
    get fontSize() {
      return this.getPropertyValue('font-size');
    }
    set fontSize(value) {
      this.setProperty('font-size', value, '');
    }
    get fontSizeDelta() {
      return this.getPropertyValue('font-size-delta');
    }
    set fontSizeDelta(value) {
      this.setProperty('font-size-delta', value, '');
    }
    get fontSmoothing() {
      return this.getPropertyValue('font-smoothing');
    }
    set fontSmoothing(value) {
      this.setProperty('font-smoothing', value, '');
    }
    get fontStretch() {
      return this.getPropertyValue('font-stretch');
    }
    set fontStretch(value) {
      this.setProperty('font-stretch', value, '');
    }
    get fontStyle() {
      return this.getPropertyValue('font-style');
    }
    set fontStyle(value) {
      this.setProperty('font-style', value, '');
    }
    get fontVariant() {
      return this.getPropertyValue('font-variant');
    }
    set fontVariant(value) {
      this.setProperty('font-variant', value, '');
    }
    get fontVariantLigatures() {
      return this.getPropertyValue('font-variant-ligatures');
    }
    set fontVariantLigatures(value) {
      this.setProperty('font-variant-ligatures', value, '');
    }
    get fontWeight() {
      return this.getPropertyValue('font-weight');
    }
    set fontWeight(value) {
      this.setProperty('font-weight', value, '');
    }
    get grid() {
      return this.getPropertyValue('grid');
    }
    set grid(value) {
      this.setProperty('grid', value, '');
    }
    get gridArea() {
      return this.getPropertyValue('grid-area');
    }
    set gridArea(value) {
      this.setProperty('grid-area', value, '');
    }
    get gridAutoColumns() {
      return this.getPropertyValue('grid-auto-columns');
    }
    set gridAutoColumns(value) {
      this.setProperty('grid-auto-columns', value, '');
    }
    get gridAutoFlow() {
      return this.getPropertyValue('grid-auto-flow');
    }
    set gridAutoFlow(value) {
      this.setProperty('grid-auto-flow', value, '');
    }
    get gridAutoRows() {
      return this.getPropertyValue('grid-auto-rows');
    }
    set gridAutoRows(value) {
      this.setProperty('grid-auto-rows', value, '');
    }
    get gridColumn() {
      return this.getPropertyValue('grid-column');
    }
    set gridColumn(value) {
      this.setProperty('grid-column', value, '');
    }
    get gridColumnEnd() {
      return this.getPropertyValue('grid-column-end');
    }
    set gridColumnEnd(value) {
      this.setProperty('grid-column-end', value, '');
    }
    get gridColumnStart() {
      return this.getPropertyValue('grid-column-start');
    }
    set gridColumnStart(value) {
      this.setProperty('grid-column-start', value, '');
    }
    get gridRow() {
      return this.getPropertyValue('grid-row');
    }
    set gridRow(value) {
      this.setProperty('grid-row', value, '');
    }
    get gridRowEnd() {
      return this.getPropertyValue('grid-row-end');
    }
    set gridRowEnd(value) {
      this.setProperty('grid-row-end', value, '');
    }
    get gridRowStart() {
      return this.getPropertyValue('grid-row-start');
    }
    set gridRowStart(value) {
      this.setProperty('grid-row-start', value, '');
    }
    get gridTemplate() {
      return this.getPropertyValue('grid-template');
    }
    set gridTemplate(value) {
      this.setProperty('grid-template', value, '');
    }
    get gridTemplateAreas() {
      return this.getPropertyValue('grid-template-areas');
    }
    set gridTemplateAreas(value) {
      this.setProperty('grid-template-areas', value, '');
    }
    get gridTemplateColumns() {
      return this.getPropertyValue('grid-template-columns');
    }
    set gridTemplateColumns(value) {
      this.setProperty('grid-template-columns', value, '');
    }
    get gridTemplateRows() {
      return this.getPropertyValue('grid-template-rows');
    }
    set gridTemplateRows(value) {
      this.setProperty('grid-template-rows', value, '');
    }
    get height() {
      return this.getPropertyValue('height');
    }
    set height(value) {
      this.setProperty('height', value, '');
    }
    get highlight() {
      return this.getPropertyValue('highlight');
    }
    set highlight(value) {
      this.setProperty('highlight', value, '');
    }
    get hyphenateCharacter() {
      return this.getPropertyValue('hyphenate-character');
    }
    set hyphenateCharacter(value) {
      this.setProperty('hyphenate-character', value, '');
    }
    get imageRendering() {
      return this.getPropertyValue('image-rendering');
    }
    set imageRendering(value) {
      this.setProperty('image-rendering', value, '');
    }
    get isolation() {
      return this.getPropertyValue('isolation');
    }
    set isolation(value) {
      this.setProperty('isolation', value, '');
    }
    get justifyContent() {
      return this.getPropertyValue('justify-content');
    }
    set justifyContent(value) {
      this.setProperty('justify-content', value, '');
    }
    get justifySelf() {
      return this.getPropertyValue('justify-self');
    }
    set justifySelf(value) {
      this.setProperty('justify-self', value, '');
    }
    get left() {
      return this.getPropertyValue('left');
    }
    set left(value) {
      this.setProperty('left', value, '');
    }
    get letterSpacing() {
      return this.getPropertyValue('letter-spacing');
    }
    set letterSpacing(value) {
      this.setProperty('letter-spacing', value, '');
    }
    get lineBoxContain() {
      return this.getPropertyValue('line-box-contain');
    }
    set lineBoxContain(value) {
      this.setProperty('line-box-contain', value, '');
    }
    get lineBreak() {
      return this.getPropertyValue('line-break');
    }
    set lineBreak(value) {
      this.setProperty('line-break', value, '');
    }
    get lineClamp() {
      return this.getPropertyValue('line-clamp');
    }
    set lineClamp(value) {
      this.setProperty('line-clamp', value, '');
    }
    get lineHeight() {
      return this.getPropertyValue('line-height');
    }
    set lineHeight(value) {
      this.setProperty('line-height', value, '');
    }
    get listStyle() {
      return this.getPropertyValue('list-style');
    }
    set listStyle(value) {
      this.setProperty('list-style', value, '');
    }
    get listStyleImage() {
      return this.getPropertyValue('list-style-image');
    }
    set listStyleImage(value) {
      this.setProperty('list-style-image', value, '');
    }
    get listStylePosition() {
      return this.getPropertyValue('list-style-position');
    }
    set listStylePosition(value) {
      this.setProperty('list-style-position', value, '');
    }
    get listStyleType() {
      return this.getPropertyValue('list-style-type');
    }
    set listStyleType(value) {
      this.setProperty('list-style-type', value, '');
    }
    get locale() {
      return this.getPropertyValue('locale');
    }
    set locale(value) {
      this.setProperty('locale', value, '');
    }
    get logicalHeight() {
      return this.getPropertyValue('logical-height');
    }
    set logicalHeight(value) {
      this.setProperty('logical-height', value, '');
    }
    get logicalWidth() {
      return this.getPropertyValue('logical-width');
    }
    set logicalWidth(value) {
      this.setProperty('logical-width', value, '');
    }
    get margin() {
      return this.getPropertyValue('margin');
    }
    set margin(value) {
      this.setProperty('margin', value, '');
    }
    get marginAfter() {
      return this.getPropertyValue('margin-after');
    }
    set marginAfter(value) {
      this.setProperty('margin-after', value, '');
    }
    get marginAfterCollapse() {
      return this.getPropertyValue('margin-after-collapse');
    }
    set marginAfterCollapse(value) {
      this.setProperty('margin-after-collapse', value, '');
    }
    get marginBefore() {
      return this.getPropertyValue('margin-before');
    }
    set marginBefore(value) {
      this.setProperty('margin-before', value, '');
    }
    get marginBeforeCollapse() {
      return this.getPropertyValue('margin-before-collapse');
    }
    set marginBeforeCollapse(value) {
      this.setProperty('margin-before-collapse', value, '');
    }
    get marginBottom() {
      return this.getPropertyValue('margin-bottom');
    }
    set marginBottom(value) {
      this.setProperty('margin-bottom', value, '');
    }
    get marginBottomCollapse() {
      return this.getPropertyValue('margin-bottom-collapse');
    }
    set marginBottomCollapse(value) {
      this.setProperty('margin-bottom-collapse', value, '');
    }
    get marginCollapse() {
      return this.getPropertyValue('margin-collapse');
    }
    set marginCollapse(value) {
      this.setProperty('margin-collapse', value, '');
    }
    get marginEnd() {
      return this.getPropertyValue('margin-end');
    }
    set marginEnd(value) {
      this.setProperty('margin-end', value, '');
    }
    get marginLeft() {
      return this.getPropertyValue('margin-left');
    }
    set marginLeft(value) {
      this.setProperty('margin-left', value, '');
    }
    get marginRight() {
      return this.getPropertyValue('margin-right');
    }
    set marginRight(value) {
      this.setProperty('margin-right', value, '');
    }
    get marginStart() {
      return this.getPropertyValue('margin-start');
    }
    set marginStart(value) {
      this.setProperty('margin-start', value, '');
    }
    get marginTop() {
      return this.getPropertyValue('margin-top');
    }
    set marginTop(value) {
      this.setProperty('margin-top', value, '');
    }
    get marginTopCollapse() {
      return this.getPropertyValue('margin-top-collapse');
    }
    set marginTopCollapse(value) {
      this.setProperty('margin-top-collapse', value, '');
    }
    get mask() {
      return this.getPropertyValue('mask');
    }
    set mask(value) {
      this.setProperty('mask', value, '');
    }
    get maskBoxImage() {
      return this.getPropertyValue('mask-box-image');
    }
    set maskBoxImage(value) {
      this.setProperty('mask-box-image', value, '');
    }
    get maskBoxImageOutset() {
      return this.getPropertyValue('mask-box-image-outset');
    }
    set maskBoxImageOutset(value) {
      this.setProperty('mask-box-image-outset', value, '');
    }
    get maskBoxImageRepeat() {
      return this.getPropertyValue('mask-box-image-repeat');
    }
    set maskBoxImageRepeat(value) {
      this.setProperty('mask-box-image-repeat', value, '');
    }
    get maskBoxImageSlice() {
      return this.getPropertyValue('mask-box-image-slice');
    }
    set maskBoxImageSlice(value) {
      this.setProperty('mask-box-image-slice', value, '');
    }
    get maskBoxImageSource() {
      return this.getPropertyValue('mask-box-image-source');
    }
    set maskBoxImageSource(value) {
      this.setProperty('mask-box-image-source', value, '');
    }
    get maskBoxImageWidth() {
      return this.getPropertyValue('mask-box-image-width');
    }
    set maskBoxImageWidth(value) {
      this.setProperty('mask-box-image-width', value, '');
    }
    get maskClip() {
      return this.getPropertyValue('mask-clip');
    }
    set maskClip(value) {
      this.setProperty('mask-clip', value, '');
    }
    get maskComposite() {
      return this.getPropertyValue('mask-composite');
    }
    set maskComposite(value) {
      this.setProperty('mask-composite', value, '');
    }
    get maskImage() {
      return this.getPropertyValue('mask-image');
    }
    set maskImage(value) {
      this.setProperty('mask-image', value, '');
    }
    get maskOrigin() {
      return this.getPropertyValue('mask-origin');
    }
    set maskOrigin(value) {
      this.setProperty('mask-origin', value, '');
    }
    get maskPosition() {
      return this.getPropertyValue('mask-position');
    }
    set maskPosition(value) {
      this.setProperty('mask-position', value, '');
    }
    get maskPositionX() {
      return this.getPropertyValue('mask-position-x');
    }
    set maskPositionX(value) {
      this.setProperty('mask-position-x', value, '');
    }
    get maskPositionY() {
      return this.getPropertyValue('mask-position-y');
    }
    set maskPositionY(value) {
      this.setProperty('mask-position-y', value, '');
    }
    get maskRepeat() {
      return this.getPropertyValue('mask-repeat');
    }
    set maskRepeat(value) {
      this.setProperty('mask-repeat', value, '');
    }
    get maskRepeatX() {
      return this.getPropertyValue('mask-repeat-x');
    }
    set maskRepeatX(value) {
      this.setProperty('mask-repeat-x', value, '');
    }
    get maskRepeatY() {
      return this.getPropertyValue('mask-repeat-y');
    }
    set maskRepeatY(value) {
      this.setProperty('mask-repeat-y', value, '');
    }
    get maskSize() {
      return this.getPropertyValue('mask-size');
    }
    set maskSize(value) {
      this.setProperty('mask-size', value, '');
    }
    get maskSourceType() {
      return this.getPropertyValue('mask-source-type');
    }
    set maskSourceType(value) {
      this.setProperty('mask-source-type', value, '');
    }
    get maxHeight() {
      return this.getPropertyValue('max-height');
    }
    set maxHeight(value) {
      this.setProperty('max-height', value, '');
    }
    get maxLogicalHeight() {
      return this.getPropertyValue('max-logical-height');
    }
    set maxLogicalHeight(value) {
      this.setProperty('max-logical-height', value, '');
    }
    get maxLogicalWidth() {
      return this.getPropertyValue('max-logical-width');
    }
    set maxLogicalWidth(value) {
      this.setProperty('max-logical-width', value, '');
    }
    get maxWidth() {
      return this.getPropertyValue('max-width');
    }
    set maxWidth(value) {
      this.setProperty('max-width', value, '');
    }
    get maxZoom() {
      return this.getPropertyValue('max-zoom');
    }
    set maxZoom(value) {
      this.setProperty('max-zoom', value, '');
    }
    get minHeight() {
      return this.getPropertyValue('min-height');
    }
    set minHeight(value) {
      this.setProperty('min-height', value, '');
    }
    get minLogicalHeight() {
      return this.getPropertyValue('min-logical-height');
    }
    set minLogicalHeight(value) {
      this.setProperty('min-logical-height', value, '');
    }
    get minLogicalWidth() {
      return this.getPropertyValue('min-logical-width');
    }
    set minLogicalWidth(value) {
      this.setProperty('min-logical-width', value, '');
    }
    get minWidth() {
      return this.getPropertyValue('min-width');
    }
    set minWidth(value) {
      this.setProperty('min-width', value, '');
    }
    get minZoom() {
      return this.getPropertyValue('min-zoom');
    }
    set minZoom(value) {
      this.setProperty('min-zoom', value, '');
    }
    get mixBlendMode() {
      return this.getPropertyValue('mix-blend-mode');
    }
    set mixBlendMode(value) {
      this.setProperty('mix-blend-mode', value, '');
    }
    get objectFit() {
      return this.getPropertyValue('object-fit');
    }
    set objectFit(value) {
      this.setProperty('object-fit', value, '');
    }
    get objectPosition() {
      return this.getPropertyValue('object-position');
    }
    set objectPosition(value) {
      this.setProperty('object-position', value, '');
    }
    get opacity() {
      return this.getPropertyValue('opacity');
    }
    set opacity(value) {
      this.setProperty('opacity', value, '');
    }
    get order() {
      return this.getPropertyValue('order');
    }
    set order(value) {
      this.setProperty('order', value, '');
    }
    get orientation() {
      return this.getPropertyValue('orientation');
    }
    set orientation(value) {
      this.setProperty('orientation', value, '');
    }
    get orphans() {
      return this.getPropertyValue('orphans');
    }
    set orphans(value) {
      this.setProperty('orphans', value, '');
    }
    get outline() {
      return this.getPropertyValue('outline');
    }
    set outline(value) {
      this.setProperty('outline', value, '');
    }
    get outlineColor() {
      return this.getPropertyValue('outline-color');
    }
    set outlineColor(value) {
      this.setProperty('outline-color', value, '');
    }
    get outlineOffset() {
      return this.getPropertyValue('outline-offset');
    }
    set outlineOffset(value) {
      this.setProperty('outline-offset', value, '');
    }
    get outlineStyle() {
      return this.getPropertyValue('outline-style');
    }
    set outlineStyle(value) {
      this.setProperty('outline-style', value, '');
    }
    get outlineWidth() {
      return this.getPropertyValue('outline-width');
    }
    set outlineWidth(value) {
      this.setProperty('outline-width', value, '');
    }
    get overflow() {
      return this.getPropertyValue('overflow');
    }
    set overflow(value) {
      this.setProperty('overflow', value, '');
    }
    get overflowWrap() {
      return this.getPropertyValue('overflow-wrap');
    }
    set overflowWrap(value) {
      this.setProperty('overflow-wrap', value, '');
    }
    get overflowX() {
      return this.getPropertyValue('overflow-x');
    }
    set overflowX(value) {
      this.setProperty('overflow-x', value, '');
    }
    get overflowY() {
      return this.getPropertyValue('overflow-y');
    }
    set overflowY(value) {
      this.setProperty('overflow-y', value, '');
    }
    get padding() {
      return this.getPropertyValue('padding');
    }
    set padding(value) {
      this.setProperty('padding', value, '');
    }
    get paddingAfter() {
      return this.getPropertyValue('padding-after');
    }
    set paddingAfter(value) {
      this.setProperty('padding-after', value, '');
    }
    get paddingBefore() {
      return this.getPropertyValue('padding-before');
    }
    set paddingBefore(value) {
      this.setProperty('padding-before', value, '');
    }
    get paddingBottom() {
      return this.getPropertyValue('padding-bottom');
    }
    set paddingBottom(value) {
      this.setProperty('padding-bottom', value, '');
    }
    get paddingEnd() {
      return this.getPropertyValue('padding-end');
    }
    set paddingEnd(value) {
      this.setProperty('padding-end', value, '');
    }
    get paddingLeft() {
      return this.getPropertyValue('padding-left');
    }
    set paddingLeft(value) {
      this.setProperty('padding-left', value, '');
    }
    get paddingRight() {
      return this.getPropertyValue('padding-right');
    }
    set paddingRight(value) {
      this.setProperty('padding-right', value, '');
    }
    get paddingStart() {
      return this.getPropertyValue('padding-start');
    }
    set paddingStart(value) {
      this.setProperty('padding-start', value, '');
    }
    get paddingTop() {
      return this.getPropertyValue('padding-top');
    }
    set paddingTop(value) {
      this.setProperty('padding-top', value, '');
    }
    get page() {
      return this.getPropertyValue('page');
    }
    set page(value) {
      this.setProperty('page', value, '');
    }
    get pageBreakAfter() {
      return this.getPropertyValue('page-break-after');
    }
    set pageBreakAfter(value) {
      this.setProperty('page-break-after', value, '');
    }
    get pageBreakBefore() {
      return this.getPropertyValue('page-break-before');
    }
    set pageBreakBefore(value) {
      this.setProperty('page-break-before', value, '');
    }
    get pageBreakInside() {
      return this.getPropertyValue('page-break-inside');
    }
    set pageBreakInside(value) {
      this.setProperty('page-break-inside', value, '');
    }
    get perspective() {
      return this.getPropertyValue('perspective');
    }
    set perspective(value) {
      this.setProperty('perspective', value, '');
    }
    get perspectiveOrigin() {
      return this.getPropertyValue('perspective-origin');
    }
    set perspectiveOrigin(value) {
      this.setProperty('perspective-origin', value, '');
    }
    get perspectiveOriginX() {
      return this.getPropertyValue('perspective-origin-x');
    }
    set perspectiveOriginX(value) {
      this.setProperty('perspective-origin-x', value, '');
    }
    get perspectiveOriginY() {
      return this.getPropertyValue('perspective-origin-y');
    }
    set perspectiveOriginY(value) {
      this.setProperty('perspective-origin-y', value, '');
    }
    get pointerEvents() {
      return this.getPropertyValue('pointer-events');
    }
    set pointerEvents(value) {
      this.setProperty('pointer-events', value, '');
    }
    get position() {
      return this.getPropertyValue('position');
    }
    set position(value) {
      this.setProperty('position', value, '');
    }
    get printColorAdjust() {
      return this.getPropertyValue('print-color-adjust');
    }
    set printColorAdjust(value) {
      this.setProperty('print-color-adjust', value, '');
    }
    get quotes() {
      return this.getPropertyValue('quotes');
    }
    set quotes(value) {
      this.setProperty('quotes', value, '');
    }
    get resize() {
      return this.getPropertyValue('resize');
    }
    set resize(value) {
      this.setProperty('resize', value, '');
    }
    get right() {
      return this.getPropertyValue('right');
    }
    set right(value) {
      this.setProperty('right', value, '');
    }
    get rtlOrdering() {
      return this.getPropertyValue('rtl-ordering');
    }
    set rtlOrdering(value) {
      this.setProperty('rtl-ordering', value, '');
    }
    get rubyPosition() {
      return this.getPropertyValue('ruby-position');
    }
    set rubyPosition(value) {
      this.setProperty('ruby-position', value, '');
    }
    get scrollBehavior() {
      return this.getPropertyValue('scroll-behavior');
    }
    set scrollBehavior(value) {
      this.setProperty('scroll-behavior', value, '');
    }
    get shapeImageThreshold() {
      return this.getPropertyValue('shape-image-threshold');
    }
    set shapeImageThreshold(value) {
      this.setProperty('shape-image-threshold', value, '');
    }
    get shapeMargin() {
      return this.getPropertyValue('shape-margin');
    }
    set shapeMargin(value) {
      this.setProperty('shape-margin', value, '');
    }
    get shapeOutside() {
      return this.getPropertyValue('shape-outside');
    }
    set shapeOutside(value) {
      this.setProperty('shape-outside', value, '');
    }
    get size() {
      return this.getPropertyValue('size');
    }
    set size(value) {
      this.setProperty('size', value, '');
    }
    get speak() {
      return this.getPropertyValue('speak');
    }
    set speak(value) {
      this.setProperty('speak', value, '');
    }
    get src() {
      return this.getPropertyValue('src');
    }
    set src(value) {
      this.setProperty('src', value, '');
    }
    get tabSize() {
      return this.getPropertyValue('tab-size');
    }
    set tabSize(value) {
      this.setProperty('tab-size', value, '');
    }
    get tableLayout() {
      return this.getPropertyValue('table-layout');
    }
    set tableLayout(value) {
      this.setProperty('table-layout', value, '');
    }
    get tapHighlightColor() {
      return this.getPropertyValue('tap-highlight-color');
    }
    set tapHighlightColor(value) {
      this.setProperty('tap-highlight-color', value, '');
    }
    get textAlign() {
      return this.getPropertyValue('text-align');
    }
    set textAlign(value) {
      this.setProperty('text-align', value, '');
    }
    get textAlignLast() {
      return this.getPropertyValue('text-align-last');
    }
    set textAlignLast(value) {
      this.setProperty('text-align-last', value, '');
    }
    get textCombine() {
      return this.getPropertyValue('text-combine');
    }
    set textCombine(value) {
      this.setProperty('text-combine', value, '');
    }
    get textDecoration() {
      return this.getPropertyValue('text-decoration');
    }
    set textDecoration(value) {
      this.setProperty('text-decoration', value, '');
    }
    get textDecorationColor() {
      return this.getPropertyValue('text-decoration-color');
    }
    set textDecorationColor(value) {
      this.setProperty('text-decoration-color', value, '');
    }
    get textDecorationLine() {
      return this.getPropertyValue('text-decoration-line');
    }
    set textDecorationLine(value) {
      this.setProperty('text-decoration-line', value, '');
    }
    get textDecorationStyle() {
      return this.getPropertyValue('text-decoration-style');
    }
    set textDecorationStyle(value) {
      this.setProperty('text-decoration-style', value, '');
    }
    get textDecorationsInEffect() {
      return this.getPropertyValue('text-decorations-in-effect');
    }
    set textDecorationsInEffect(value) {
      this.setProperty('text-decorations-in-effect', value, '');
    }
    get textEmphasis() {
      return this.getPropertyValue('text-emphasis');
    }
    set textEmphasis(value) {
      this.setProperty('text-emphasis', value, '');
    }
    get textEmphasisColor() {
      return this.getPropertyValue('text-emphasis-color');
    }
    set textEmphasisColor(value) {
      this.setProperty('text-emphasis-color', value, '');
    }
    get textEmphasisPosition() {
      return this.getPropertyValue('text-emphasis-position');
    }
    set textEmphasisPosition(value) {
      this.setProperty('text-emphasis-position', value, '');
    }
    get textEmphasisStyle() {
      return this.getPropertyValue('text-emphasis-style');
    }
    set textEmphasisStyle(value) {
      this.setProperty('text-emphasis-style', value, '');
    }
    get textFillColor() {
      return this.getPropertyValue('text-fill-color');
    }
    set textFillColor(value) {
      this.setProperty('text-fill-color', value, '');
    }
    get textIndent() {
      return this.getPropertyValue('text-indent');
    }
    set textIndent(value) {
      this.setProperty('text-indent', value, '');
    }
    get textJustify() {
      return this.getPropertyValue('text-justify');
    }
    set textJustify(value) {
      this.setProperty('text-justify', value, '');
    }
    get textLineThroughColor() {
      return this.getPropertyValue('text-line-through-color');
    }
    set textLineThroughColor(value) {
      this.setProperty('text-line-through-color', value, '');
    }
    get textLineThroughMode() {
      return this.getPropertyValue('text-line-through-mode');
    }
    set textLineThroughMode(value) {
      this.setProperty('text-line-through-mode', value, '');
    }
    get textLineThroughStyle() {
      return this.getPropertyValue('text-line-through-style');
    }
    set textLineThroughStyle(value) {
      this.setProperty('text-line-through-style', value, '');
    }
    get textLineThroughWidth() {
      return this.getPropertyValue('text-line-through-width');
    }
    set textLineThroughWidth(value) {
      this.setProperty('text-line-through-width', value, '');
    }
    get textOrientation() {
      return this.getPropertyValue('text-orientation');
    }
    set textOrientation(value) {
      this.setProperty('text-orientation', value, '');
    }
    get textOverflow() {
      return this.getPropertyValue('text-overflow');
    }
    set textOverflow(value) {
      this.setProperty('text-overflow', value, '');
    }
    get textOverlineColor() {
      return this.getPropertyValue('text-overline-color');
    }
    set textOverlineColor(value) {
      this.setProperty('text-overline-color', value, '');
    }
    get textOverlineMode() {
      return this.getPropertyValue('text-overline-mode');
    }
    set textOverlineMode(value) {
      this.setProperty('text-overline-mode', value, '');
    }
    get textOverlineStyle() {
      return this.getPropertyValue('text-overline-style');
    }
    set textOverlineStyle(value) {
      this.setProperty('text-overline-style', value, '');
    }
    get textOverlineWidth() {
      return this.getPropertyValue('text-overline-width');
    }
    set textOverlineWidth(value) {
      this.setProperty('text-overline-width', value, '');
    }
    get textRendering() {
      return this.getPropertyValue('text-rendering');
    }
    set textRendering(value) {
      this.setProperty('text-rendering', value, '');
    }
    get textSecurity() {
      return this.getPropertyValue('text-security');
    }
    set textSecurity(value) {
      this.setProperty('text-security', value, '');
    }
    get textShadow() {
      return this.getPropertyValue('text-shadow');
    }
    set textShadow(value) {
      this.setProperty('text-shadow', value, '');
    }
    get textStroke() {
      return this.getPropertyValue('text-stroke');
    }
    set textStroke(value) {
      this.setProperty('text-stroke', value, '');
    }
    get textStrokeColor() {
      return this.getPropertyValue('text-stroke-color');
    }
    set textStrokeColor(value) {
      this.setProperty('text-stroke-color', value, '');
    }
    get textStrokeWidth() {
      return this.getPropertyValue('text-stroke-width');
    }
    set textStrokeWidth(value) {
      this.setProperty('text-stroke-width', value, '');
    }
    get textTransform() {
      return this.getPropertyValue('text-transform');
    }
    set textTransform(value) {
      this.setProperty('text-transform', value, '');
    }
    get textUnderlineColor() {
      return this.getPropertyValue('text-underline-color');
    }
    set textUnderlineColor(value) {
      this.setProperty('text-underline-color', value, '');
    }
    get textUnderlineMode() {
      return this.getPropertyValue('text-underline-mode');
    }
    set textUnderlineMode(value) {
      this.setProperty('text-underline-mode', value, '');
    }
    get textUnderlinePosition() {
      return this.getPropertyValue('text-underline-position');
    }
    set textUnderlinePosition(value) {
      this.setProperty('text-underline-position', value, '');
    }
    get textUnderlineStyle() {
      return this.getPropertyValue('text-underline-style');
    }
    set textUnderlineStyle(value) {
      this.setProperty('text-underline-style', value, '');
    }
    get textUnderlineWidth() {
      return this.getPropertyValue('text-underline-width');
    }
    set textUnderlineWidth(value) {
      this.setProperty('text-underline-width', value, '');
    }
    get top() {
      return this.getPropertyValue('top');
    }
    set top(value) {
      this.setProperty('top', value, '');
    }
    get touchAction() {
      return this.getPropertyValue('touch-action');
    }
    set touchAction(value) {
      this.setProperty('touch-action', value, '');
    }
    get touchActionDelay() {
      return this.getPropertyValue('touch-action-delay');
    }
    set touchActionDelay(value) {
      this.setProperty('touch-action-delay', value, '');
    }
    get transform() {
      return this.getPropertyValue('transform');
    }
    set transform(value) {
      this.setProperty('transform', value, '');
    }
    get transformOrigin() {
      return this.getPropertyValue('transform-origin');
    }
    set transformOrigin(value) {
      this.setProperty('transform-origin', value, '');
    }
    get transformOriginX() {
      return this.getPropertyValue('transform-origin-x');
    }
    set transformOriginX(value) {
      this.setProperty('transform-origin-x', value, '');
    }
    get transformOriginY() {
      return this.getPropertyValue('transform-origin-y');
    }
    set transformOriginY(value) {
      this.setProperty('transform-origin-y', value, '');
    }
    get transformOriginZ() {
      return this.getPropertyValue('transform-origin-z');
    }
    set transformOriginZ(value) {
      this.setProperty('transform-origin-z', value, '');
    }
    get transformStyle() {
      return this.getPropertyValue('transform-style');
    }
    set transformStyle(value) {
      this.setProperty('transform-style', value, '');
    }
    get transition() {
      return this.getPropertyValue('transition');
    }
    set transition(value) {
      this.setProperty('transition', value, '');
    }
    get transitionDelay() {
      return this.getPropertyValue('transition-delay');
    }
    set transitionDelay(value) {
      this.setProperty('transition-delay', value, '');
    }
    get transitionDuration() {
      return this.getPropertyValue('transition-duration');
    }
    set transitionDuration(value) {
      this.setProperty('transition-duration', value, '');
    }
    get transitionProperty() {
      return this.getPropertyValue('transition-property');
    }
    set transitionProperty(value) {
      this.setProperty('transition-property', value, '');
    }
    get transitionTimingFunction() {
      return this.getPropertyValue('transition-timing-function');
    }
    set transitionTimingFunction(value) {
      this.setProperty('transition-timing-function', value, '');
    }
    get unicodeBidi() {
      return this.getPropertyValue('unicode-bidi');
    }
    set unicodeBidi(value) {
      this.setProperty('unicode-bidi', value, '');
    }
    get unicodeRange() {
      return this.getPropertyValue('unicode-range');
    }
    set unicodeRange(value) {
      this.setProperty('unicode-range', value, '');
    }
    get userDrag() {
      return this.getPropertyValue('user-drag');
    }
    set userDrag(value) {
      this.setProperty('user-drag', value, '');
    }
    get userModify() {
      return this.getPropertyValue('user-modify');
    }
    set userModify(value) {
      this.setProperty('user-modify', value, '');
    }
    get userSelect() {
      return this.getPropertyValue('user-select');
    }
    set userSelect(value) {
      this.setProperty('user-select', value, '');
    }
    get userZoom() {
      return this.getPropertyValue('user-zoom');
    }
    set userZoom(value) {
      this.setProperty('user-zoom', value, '');
    }
    get verticalAlign() {
      return this.getPropertyValue('vertical-align');
    }
    set verticalAlign(value) {
      this.setProperty('vertical-align', value, '');
    }
    get visibility() {
      return this.getPropertyValue('visibility');
    }
    set visibility(value) {
      this.setProperty('visibility', value, '');
    }
    get whiteSpace() {
      return this.getPropertyValue('white-space');
    }
    set whiteSpace(value) {
      this.setProperty('white-space', value, '');
    }
    get widows() {
      return this.getPropertyValue('widows');
    }
    set widows(value) {
      this.setProperty('widows', value, '');
    }
    get width() {
      return this.getPropertyValue('width');
    }
    set width(value) {
      this.setProperty('width', value, '');
    }
    get willChange() {
      return this.getPropertyValue('will-change');
    }
    set willChange(value) {
      this.setProperty('will-change', value, '');
    }
    get wordBreak() {
      return this.getPropertyValue('word-break');
    }
    set wordBreak(value) {
      this.setProperty('word-break', value, '');
    }
    get wordSpacing() {
      return this.getPropertyValue('word-spacing');
    }
    set wordSpacing(value) {
      this.setProperty('word-spacing', value, '');
    }
    get wordWrap() {
      return this.getPropertyValue('word-wrap');
    }
    set wordWrap(value) {
      this.setProperty('word-wrap', value, '');
    }
    get wrapFlow() {
      return this.getPropertyValue('wrap-flow');
    }
    set wrapFlow(value) {
      this.setProperty('wrap-flow', value, '');
    }
    get wrapThrough() {
      return this.getPropertyValue('wrap-through');
    }
    set wrapThrough(value) {
      this.setProperty('wrap-through', value, '');
    }
    get writingMode() {
      return this.getPropertyValue('writing-mode');
    }
    set writingMode(value) {
      this.setProperty('writing-mode', value, '');
    }
    get zIndex() {
      return this.getPropertyValue('z-index');
    }
    set zIndex(value) {
      this.setProperty('z-index', value, '');
    }
    get zoom() {
      return this.getPropertyValue('zoom');
    }
    set zoom(value) {
      this.setProperty('zoom', value, '');
    }
  }
  dart.setSignature(CssStyleDeclarationBase, {
    methods: () => ({
      getPropertyValue: [core.String, [core.String]],
      setProperty: [dart.void, [core.String, core.String], [core.String]]
    })
  });
  const _getPropertyValueHelper = Symbol('_getPropertyValueHelper');
  const _supportsProperty = Symbol('_supportsProperty');
  const _getPropertyValue = Symbol('_getPropertyValue');
  const _setPropertyHelper = Symbol('_setPropertyHelper');
  const _browserPropertyName = Symbol('_browserPropertyName');
  const __getter___1 = Symbol('__getter___1');
  const __getter__ = Symbol('__getter__');
  const __setter___1 = Symbol('__setter___1');
  const __setter__ = Symbol('__setter__');
  const _getPropertyPriority_1 = Symbol('_getPropertyPriority_1');
  const _getPropertyValue_1 = Symbol('_getPropertyValue_1');
  const _item_1 = Symbol('_item_1');
  const _removeProperty_1 = Symbol('_removeProperty_1');
  class CssStyleDeclaration extends dart.mixin(DartHtmlDomObject, CssStyleDeclarationBase) {
    static new() {
      return CssStyleDeclaration.css('');
    }
    static css(css) {
      let style = Element.tag('div').style;
      style.cssText = css;
      return style;
    }
    getPropertyValue(propertyName) {
      let propValue = this[_getPropertyValueHelper](propertyName);
      return propValue != null ? propValue : '';
    }
    [_getPropertyValueHelper](propertyName) {
      if (dart.notNull(this[_supportsProperty](CssStyleDeclaration._camelCase(propertyName)))) {
        return this[_getPropertyValue](propertyName);
      } else {
        return this[_getPropertyValue](dart.notNull(html_common.Device.cssPrefix) + dart.notNull(propertyName));
      }
    }
    supportsProperty(propertyName) {
      return dart.notNull(this[_supportsProperty](propertyName)) || dart.notNull(this[_supportsProperty](CssStyleDeclaration._camelCase(dart.notNull(html_common.Device.cssPrefix) + dart.notNull(propertyName))));
    }
    [_supportsProperty](propertyName) {
      return propertyName in this.raw;
    }
    setProperty(propertyName, value, priority) {
      if (priority === void 0) priority = null;
      return this[_setPropertyHelper](this[_browserPropertyName](propertyName), value, priority);
    }
    [_browserPropertyName](propertyName) {
      let name = CssStyleDeclaration._readCache(propertyName);
      if (typeof name == 'string') return name;
      if (dart.notNull(this[_supportsProperty](CssStyleDeclaration._camelCase(propertyName)))) {
        name = propertyName;
      } else {
        name = dart.notNull(html_common.Device.cssPrefix) + dart.notNull(propertyName);
      }
      CssStyleDeclaration._writeCache(propertyName, name);
      return name;
    }
    static _readCache(key) {
      return null;
    }
    static _writeCache(key, value) {}
    static _camelCase(hyphenated) {
      return hyphenated[dartx.replaceFirst](core.RegExp.new('^-ms-'), 'ms-')[dartx.replaceAllMapped](core.RegExp.new('-([a-z]+)', {caseSensitive: false}), dart.fn(match => dart.notNull(match.get(0)[dartx.get](1)[dartx.toUpperCase]()) + dart.notNull(match.get(0)[dartx.substring](2)), core.String, [core.Match]));
    }
    [_setPropertyHelper](propertyName, value, priority) {
      if (priority === void 0) priority = null;
      if (value == null) value = '';
      if (priority == null) priority = '';
      this.raw.setProperty(propertyName, value, priority);
    }
    static get supportsTransitions() {
      return exports.document.body.style.supportsProperty('transition');
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateCssStyleDeclaration() {
      return new CssStyleDeclaration.internal_();
    }
    internal_() {
      super.DartHtmlDomObject();
    }
    ['=='](other) {
      return dart.equals(unwrap_jso(other), unwrap_jso(this)) || dart.notNull(core.identical(this, other));
    }
    get hashCode() {
      return dart.hashCode(unwrap_jso(this));
    }
    get cssText() {
      return dart.as(wrap_jso(this.raw.cssText), core.String);
    }
    set cssText(val) {
      return this.raw.cssText = unwrap_jso(val);
    }
    get length() {
      return dart.as(wrap_jso(this.raw.length), core.int);
    }
    [__getter__](name) {
      return this[__getter___1](name);
    }
    [__getter___1](name) {
      return wrap_jso(this.raw.__getter__(unwrap_jso(name)));
    }
    [__setter__](propertyName, propertyValue) {
      this[__setter___1](propertyName, propertyValue);
      return;
    }
    [__setter___1](propertyName, propertyValue) {
      return wrap_jso(this.raw.__setter__(unwrap_jso(propertyName), unwrap_jso(propertyValue)));
    }
    getPropertyPriority(propertyName) {
      return this[_getPropertyPriority_1](propertyName);
    }
    [_getPropertyPriority_1](propertyName) {
      return dart.as(wrap_jso(this.raw.getPropertyPriority(unwrap_jso(propertyName))), core.String);
    }
    [_getPropertyValue](propertyName) {
      return this[_getPropertyValue_1](propertyName);
    }
    [_getPropertyValue_1](propertyName) {
      return dart.as(wrap_jso(this.raw.getPropertyValue(unwrap_jso(propertyName))), core.String);
    }
    item(index) {
      return this[_item_1](index);
    }
    [_item_1](index) {
      return dart.as(wrap_jso(this.raw.item(unwrap_jso(index))), core.String);
    }
    removeProperty(propertyName) {
      return this[_removeProperty_1](propertyName);
    }
    [_removeProperty_1](propertyName) {
      return dart.as(wrap_jso(this.raw.removeProperty(unwrap_jso(propertyName))), core.String);
    }
  }
  dart.defineNamedConstructor(CssStyleDeclaration, 'internal_');
  dart.setSignature(CssStyleDeclaration, {
    constructors: () => ({
      new: [CssStyleDeclaration, []],
      css: [CssStyleDeclaration, [core.String]],
      _: [CssStyleDeclaration, []],
      internal_: [CssStyleDeclaration, []]
    }),
    methods: () => ({
      [_getPropertyValueHelper]: [core.String, [core.String]],
      supportsProperty: [core.bool, [core.String]],
      [_supportsProperty]: [core.bool, [core.String]],
      [_browserPropertyName]: [core.String, [core.String]],
      [_setPropertyHelper]: [dart.void, [core.String, core.String], [core.String]],
      [__getter__]: [core.Object, [core.String]],
      [__getter___1]: [core.Object, [dart.dynamic]],
      [__setter__]: [dart.void, [core.String, core.String]],
      [__setter___1]: [dart.void, [dart.dynamic, dart.dynamic]],
      getPropertyPriority: [core.String, [core.String]],
      [_getPropertyPriority_1]: [core.String, [dart.dynamic]],
      [_getPropertyValue]: [core.String, [core.String]],
      [_getPropertyValue_1]: [core.String, [dart.dynamic]],
      item: [core.String, [core.int]],
      [_item_1]: [core.String, [dart.dynamic]],
      removeProperty: [core.String, [core.String]],
      [_removeProperty_1]: [core.String, [dart.dynamic]]
    }),
    statics: () => ({
      _readCache: [core.String, [core.String]],
      _writeCache: [dart.void, [core.String, dart.dynamic]],
      _camelCase: [core.String, [core.String]],
      internalCreateCssStyleDeclaration: [CssStyleDeclaration, []]
    }),
    names: ['_readCache', '_writeCache', '_camelCase', 'internalCreateCssStyleDeclaration']
  });
  CssStyleDeclaration[dart.metadata] = () => [dart.const(new _metadata.DomName('CSSStyleDeclaration')), dart.const(new _js_helper.Native("CSSStyleDeclaration,MSStyleCSSProperties,CSS2Properties"))];
  const _elementIterable = Symbol('_elementIterable');
  const _elementCssStyleDeclarationSetIterable = Symbol('_elementCssStyleDeclarationSetIterable');
  class _CssStyleDeclarationSet extends dart.mixin(core.Object, CssStyleDeclarationBase) {
    _CssStyleDeclarationSet(elementIterable) {
      this[_elementIterable] = elementIterable;
      this[_elementCssStyleDeclarationSetIterable] = null;
      this[_elementCssStyleDeclarationSetIterable] = dart.as(core.List.from(this[_elementIterable])[dartx.map](dart.fn(e => dart.dload(e, 'style'))), core.Iterable$(CssStyleDeclaration));
    }
    getPropertyValue(propertyName) {
      return this[_elementCssStyleDeclarationSetIterable][dartx.first].getPropertyValue(propertyName);
    }
    setProperty(propertyName, value, priority) {
      if (priority === void 0) priority = null;
      this[_elementCssStyleDeclarationSetIterable][dartx.forEach](dart.fn(e => e.setProperty(propertyName, value, priority), dart.void, [CssStyleDeclaration]));
    }
  }
  dart.setSignature(_CssStyleDeclarationSet, {
    constructors: () => ({_CssStyleDeclarationSet: [_CssStyleDeclarationSet, [core.Iterable$(Element)]]})
  });
  const _createEvent = Symbol('_createEvent');
  const _initEvent = Symbol('_initEvent');
  const _selector = Symbol('_selector');
  const _get_currentTarget = Symbol('_get_currentTarget');
  const _get_target = Symbol('_get_target');
  const _initEvent_1 = Symbol('_initEvent_1');
  const _preventDefault_1 = Symbol('_preventDefault_1');
  const _stopImmediatePropagation_1 = Symbol('_stopImmediatePropagation_1');
  const _stopPropagation_1 = Symbol('_stopPropagation_1');
  class Event extends DartHtmlDomObject {
    static new(type, opts) {
      let canBubble = opts && 'canBubble' in opts ? opts.canBubble : true;
      let cancelable = opts && 'cancelable' in opts ? opts.cancelable : true;
      return Event.eventType('Event', type, {canBubble: canBubble, cancelable: cancelable});
    }
    static eventType(type, name, opts) {
      let canBubble = opts && 'canBubble' in opts ? opts.canBubble : true;
      let cancelable = opts && 'cancelable' in opts ? opts.cancelable : true;
      let e = exports.document[_createEvent](type);
      e[_initEvent](name, canBubble, cancelable);
      return e;
    }
    get matchingTarget() {
      if (this[_selector] == null) {
        dart.throw(new core.UnsupportedError('Cannot call matchingTarget if this Event did' + ' not arise as a result of event delegation.'));
      }
      let currentTarget = dart.as(this.currentTarget, Element);
      let target = dart.as(this.target, Element);
      let matchedTarget = null;
      do {
        if (dart.notNull(target.matches(this[_selector]))) return target;
        target = target.parent;
      } while (target != null && !dart.equals(target, currentTarget.parent));
      dart.throw(new core.StateError('No selector matched for populating matchedTarget.'));
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateEvent() {
      return new Event.internal_();
    }
    internal_() {
      this[_selector] = null;
      super.DartHtmlDomObject();
    }
    ['=='](other) {
      return dart.equals(unwrap_jso(other), unwrap_jso(this)) || dart.notNull(core.identical(this, other));
    }
    get hashCode() {
      return dart.hashCode(unwrap_jso(this));
    }
    get bubbles() {
      return dart.as(wrap_jso(this.raw.bubbles), core.bool);
    }
    get cancelable() {
      return dart.as(wrap_jso(this.raw.cancelable), core.bool);
    }
    get currentTarget() {
      return _convertNativeToDart_EventTarget(this[_get_currentTarget]);
    }
    get [_get_currentTarget]() {
      return wrap_jso(this.raw.currentTarget);
    }
    get defaultPrevented() {
      return dart.as(wrap_jso(this.raw.defaultPrevented), core.bool);
    }
    get eventPhase() {
      return dart.as(wrap_jso(this.raw.eventPhase), core.int);
    }
    get path() {
      return dart.as(wrap_jso(this.raw.path), core.List$(Node));
    }
    get target() {
      return _convertNativeToDart_EventTarget(this[_get_target]);
    }
    get [_get_target]() {
      return wrap_jso(this.raw.target);
    }
    get timeStamp() {
      return dart.as(wrap_jso(this.raw.timeStamp), core.int);
    }
    get type() {
      return dart.as(wrap_jso(this.raw.type), core.String);
    }
    [_initEvent](eventTypeArg, canBubbleArg, cancelableArg) {
      this[_initEvent_1](eventTypeArg, canBubbleArg, cancelableArg);
      return;
    }
    [_initEvent_1](eventTypeArg, canBubbleArg, cancelableArg) {
      return wrap_jso(this.raw.initEvent(unwrap_jso(eventTypeArg), unwrap_jso(canBubbleArg), unwrap_jso(cancelableArg)));
    }
    preventDefault() {
      this[_preventDefault_1]();
      return;
    }
    [_preventDefault_1]() {
      return wrap_jso(this.raw.preventDefault());
    }
    stopImmediatePropagation() {
      this[_stopImmediatePropagation_1]();
      return;
    }
    [_stopImmediatePropagation_1]() {
      return wrap_jso(this.raw.stopImmediatePropagation());
    }
    stopPropagation() {
      this[_stopPropagation_1]();
      return;
    }
    [_stopPropagation_1]() {
      return wrap_jso(this.raw.stopPropagation());
    }
  }
  dart.defineNamedConstructor(Event, 'internal_');
  dart.setSignature(Event, {
    constructors: () => ({
      new: [Event, [core.String], {canBubble: core.bool, cancelable: core.bool}],
      eventType: [Event, [core.String, core.String], {canBubble: core.bool, cancelable: core.bool}],
      _: [Event, []],
      internal_: [Event, []]
    }),
    methods: () => ({
      [_initEvent]: [dart.void, [core.String, core.bool, core.bool]],
      [_initEvent_1]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic]],
      preventDefault: [dart.void, []],
      [_preventDefault_1]: [dart.void, []],
      stopImmediatePropagation: [dart.void, []],
      [_stopImmediatePropagation_1]: [dart.void, []],
      stopPropagation: [dart.void, []],
      [_stopPropagation_1]: [dart.void, []]
    }),
    statics: () => ({internalCreateEvent: [Event, []]}),
    names: ['internalCreateEvent']
  });
  Event[dart.metadata] = () => [dart.const(new _metadata.DomName('Event')), dart.const(new _js_helper.Native("Event,InputEvent,ClipboardEvent"))];
  Event.AT_TARGET = 2;
  Event.BUBBLING_PHASE = 3;
  Event.CAPTURING_PHASE = 1;
  const _dartDetail = Symbol('_dartDetail');
  const _initCustomEvent = Symbol('_initCustomEvent');
  const _detail = Symbol('_detail');
  const _get__detail = Symbol('_get__detail');
  const _initCustomEvent_1 = Symbol('_initCustomEvent_1');
  class CustomEvent extends Event {
    static new(type, opts) {
      let canBubble = opts && 'canBubble' in opts ? opts.canBubble : true;
      let cancelable = opts && 'cancelable' in opts ? opts.cancelable : true;
      let detail = opts && 'detail' in opts ? opts.detail : null;
      let e = dart.as(exports.document[_createEvent]('CustomEvent'), CustomEvent);
      e[_dartDetail] = detail;
      if (dart.is(detail, core.List) || dart.is(detail, core.Map) || typeof detail == 'string' || typeof detail == 'number') {
        try {
          e[_initCustomEvent](type, canBubble, cancelable, detail);
        } catch (_) {
          e[_initCustomEvent](type, canBubble, cancelable, null);
        }

      } else {
        e[_initCustomEvent](type, canBubble, cancelable, null);
      }
      return e;
    }
    get detail() {
      if (this[_dartDetail] != null) {
        return this[_dartDetail];
      }
      return this[_detail];
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateCustomEvent() {
      return new CustomEvent.internal_();
    }
    internal_() {
      this[_dartDetail] = null;
      super.internal_();
    }
    get [_detail]() {
      return html_common.convertNativeToDart_SerializedScriptValue(this[_get__detail]);
    }
    get [_get__detail]() {
      return wrap_jso(this.raw.detail);
    }
    [_initCustomEvent](typeArg, canBubbleArg, cancelableArg, detailArg) {
      this[_initCustomEvent_1](typeArg, canBubbleArg, cancelableArg, detailArg);
      return;
    }
    [_initCustomEvent_1](typeArg, canBubbleArg, cancelableArg, detailArg) {
      return wrap_jso(this.raw.initCustomEvent(unwrap_jso(typeArg), unwrap_jso(canBubbleArg), unwrap_jso(cancelableArg), unwrap_jso(detailArg)));
    }
  }
  dart.defineNamedConstructor(CustomEvent, 'internal_');
  dart.setSignature(CustomEvent, {
    constructors: () => ({
      new: [CustomEvent, [core.String], {canBubble: core.bool, cancelable: core.bool, detail: core.Object}],
      _: [CustomEvent, []],
      internal_: [CustomEvent, []]
    }),
    methods: () => ({
      [_initCustomEvent]: [dart.void, [core.String, core.bool, core.bool, core.Object]],
      [_initCustomEvent_1]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]]
    }),
    statics: () => ({internalCreateCustomEvent: [CustomEvent, []]}),
    names: ['internalCreateCustomEvent']
  });
  CustomEvent[dart.metadata] = () => [dart.const(new _metadata.DomName('CustomEvent')), dart.const(new _js_helper.Native("CustomEvent"))];
  class DivElement extends HtmlElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(exports.document.createElement("div"), DivElement);
    }
    static internalCreateDivElement() {
      return new DivElement.internal_();
    }
    internal_() {
      super.internal_();
    }
  }
  dart.defineNamedConstructor(DivElement, 'internal_');
  dart.setSignature(DivElement, {
    constructors: () => ({
      _: [DivElement, []],
      new: [DivElement, []],
      internal_: [DivElement, []]
    }),
    statics: () => ({internalCreateDivElement: [DivElement, []]}),
    names: ['internalCreateDivElement']
  });
  DivElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('HTMLDivElement')), dart.const(new _js_helper.Native("HTMLDivElement"))];
  const _body = Symbol('_body');
  const _get_window = Symbol('_get_window');
  const _head = Symbol('_head');
  const _lastModified = Symbol('_lastModified');
  const _preferredStylesheetSet = Symbol('_preferredStylesheetSet');
  const _referrer = Symbol('_referrer');
  const _selectedStylesheetSet = Symbol('_selectedStylesheetSet');
  const _title = Symbol('_title');
  const _webkitFullscreenElement = Symbol('_webkitFullscreenElement');
  const _webkitFullscreenEnabled = Symbol('_webkitFullscreenEnabled');
  const _webkitHidden = Symbol('_webkitHidden');
  const _webkitVisibilityState = Symbol('_webkitVisibilityState');
  const _adoptNode_1 = Symbol('_adoptNode_1');
  const _caretRangeFromPoint_1 = Symbol('_caretRangeFromPoint_1');
  const _caretRangeFromPoint = Symbol('_caretRangeFromPoint');
  const _createDocumentFragment_1 = Symbol('_createDocumentFragment_1');
  const _createElement_1 = Symbol('_createElement_1');
  const _createElement_2 = Symbol('_createElement_2');
  const _createElement = Symbol('_createElement');
  const _createElementNS_1 = Symbol('_createElementNS_1');
  const _createElementNS_2 = Symbol('_createElementNS_2');
  const _createElementNS = Symbol('_createElementNS');
  const _createEvent_1 = Symbol('_createEvent_1');
  const _createRange_1 = Symbol('_createRange_1');
  const _createTextNode_1 = Symbol('_createTextNode_1');
  const _createTextNode = Symbol('_createTextNode');
  const _elementFromPoint_1 = Symbol('_elementFromPoint_1');
  const _elementFromPoint = Symbol('_elementFromPoint');
  const _execCommand_1 = Symbol('_execCommand_1');
  const _exitFullscreen_1 = Symbol('_exitFullscreen_1');
  const _exitPointerLock_1 = Symbol('_exitPointerLock_1');
  const _getCssCanvasContext_1 = Symbol('_getCssCanvasContext_1');
  const _getCssCanvasContext = Symbol('_getCssCanvasContext');
  const _getElementById_1 = Symbol('_getElementById_1');
  const _getElementsByName_1 = Symbol('_getElementsByName_1');
  const _importNode_1 = Symbol('_importNode_1');
  const _importNode_2 = Symbol('_importNode_2');
  const _queryCommandEnabled_1 = Symbol('_queryCommandEnabled_1');
  const _queryCommandIndeterm_1 = Symbol('_queryCommandIndeterm_1');
  const _queryCommandState_1 = Symbol('_queryCommandState_1');
  const _queryCommandSupported_1 = Symbol('_queryCommandSupported_1');
  const _queryCommandValue_1 = Symbol('_queryCommandValue_1');
  const _transformDocumentToTreeView_1 = Symbol('_transformDocumentToTreeView_1');
  const _webkitExitFullscreen_1 = Symbol('_webkitExitFullscreen_1');
  const _webkitExitFullscreen = Symbol('_webkitExitFullscreen');
  class Document extends Node {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateDocument() {
      return new Document.internal_();
    }
    internal_() {
      super.internal_();
    }
    get activeElement() {
      return dart.as(wrap_jso(this.raw.activeElement), Element);
    }
    get [_body]() {
      return dart.as(wrap_jso(this.raw.body), HtmlElement);
    }
    set [_body](val) {
      return this.raw.body = unwrap_jso(val);
    }
    get contentType() {
      return dart.as(wrap_jso(this.raw.contentType), core.String);
    }
    get cookie() {
      return dart.as(wrap_jso(this.raw.cookie), core.String);
    }
    set cookie(val) {
      return this.raw.cookie = unwrap_jso(val);
    }
    get currentScript() {
      return dart.as(wrap_jso(this.raw.currentScript), HtmlElement);
    }
    get window() {
      return _convertNativeToDart_Window(this[_get_window]);
    }
    get [_get_window]() {
      return wrap_jso(this.raw.defaultView);
    }
    get documentElement() {
      return dart.as(wrap_jso(this.raw.documentElement), Element);
    }
    get domain() {
      return dart.as(wrap_jso(this.raw.domain), core.String);
    }
    get fullscreenElement() {
      return dart.as(wrap_jso(this.raw.fullscreenElement), Element);
    }
    get fullscreenEnabled() {
      return dart.as(wrap_jso(this.raw.fullscreenEnabled), core.bool);
    }
    get [_head]() {
      return dart.as(wrap_jso(this.raw.head), HeadElement);
    }
    get hidden() {
      return dart.as(wrap_jso(this.raw.hidden), core.bool);
    }
    get implementation() {
      return dart.as(wrap_jso(this.raw.implementation), DomImplementation);
    }
    get [_lastModified]() {
      return dart.as(wrap_jso(this.raw.lastModified), core.String);
    }
    get pointerLockElement() {
      return dart.as(wrap_jso(this.raw.pointerLockElement), Element);
    }
    get [_preferredStylesheetSet]() {
      return dart.as(wrap_jso(this.raw.preferredStylesheetSet), core.String);
    }
    get readyState() {
      return dart.as(wrap_jso(this.raw.readyState), core.String);
    }
    get [_referrer]() {
      return dart.as(wrap_jso(this.raw.referrer), core.String);
    }
    get rootElement() {
      return dart.as(wrap_jso(this.raw.rootElement), Element);
    }
    get [_selectedStylesheetSet]() {
      return dart.as(wrap_jso(this.raw.selectedStylesheetSet), core.String);
    }
    set [_selectedStylesheetSet](val) {
      return this.raw.selectedStylesheetSet = unwrap_jso(val);
    }
    get [_title]() {
      return dart.as(wrap_jso(this.raw.title), core.String);
    }
    set [_title](val) {
      return this.raw.title = unwrap_jso(val);
    }
    get visibilityState() {
      return dart.as(wrap_jso(this.raw.visibilityState), core.String);
    }
    get [_webkitFullscreenElement]() {
      return dart.as(wrap_jso(this.raw.webkitFullscreenElement), Element);
    }
    get [_webkitFullscreenEnabled]() {
      return dart.as(wrap_jso(this.raw.webkitFullscreenEnabled), core.bool);
    }
    get [_webkitHidden]() {
      return dart.as(wrap_jso(this.raw.webkitHidden), core.bool);
    }
    get [_webkitVisibilityState]() {
      return dart.as(wrap_jso(this.raw.webkitVisibilityState), core.String);
    }
    adoptNode(node) {
      return this[_adoptNode_1](node);
    }
    [_adoptNode_1](node) {
      return dart.as(wrap_jso(this.raw.adoptNode(unwrap_jso(node))), Node);
    }
    [_caretRangeFromPoint](x, y) {
      return this[_caretRangeFromPoint_1](x, y);
    }
    [_caretRangeFromPoint_1](x, y) {
      return dart.as(wrap_jso(this.raw.caretRangeFromPoint(unwrap_jso(x), unwrap_jso(y))), Range);
    }
    createDocumentFragment() {
      return this[_createDocumentFragment_1]();
    }
    [_createDocumentFragment_1]() {
      return dart.as(wrap_jso(this.raw.createDocumentFragment()), DocumentFragment);
    }
    [_createElement](localName_OR_tagName, typeExtension) {
      if (typeExtension === void 0) typeExtension = null;
      if (typeExtension == null) {
        return this[_createElement_1](localName_OR_tagName);
      }
      if (typeExtension != null) {
        return this[_createElement_2](localName_OR_tagName, typeExtension);
      }
      dart.throw(new core.ArgumentError("Incorrect number or type of arguments"));
    }
    [_createElement_1](tagName) {
      return dart.as(wrap_jso(this.raw.createElement(unwrap_jso(tagName))), Element);
    }
    [_createElement_2](localName, typeExtension) {
      return dart.as(wrap_jso(this.raw.createElement(unwrap_jso(localName), unwrap_jso(typeExtension))), Element);
    }
    [_createElementNS](namespaceURI, qualifiedName, typeExtension) {
      if (typeExtension === void 0) typeExtension = null;
      if (typeExtension == null) {
        return this[_createElementNS_1](namespaceURI, qualifiedName);
      }
      if (typeExtension != null) {
        return this[_createElementNS_2](namespaceURI, qualifiedName, typeExtension);
      }
      dart.throw(new core.ArgumentError("Incorrect number or type of arguments"));
    }
    [_createElementNS_1](namespaceURI, qualifiedName) {
      return dart.as(wrap_jso(this.raw.createElementNS(unwrap_jso(namespaceURI), unwrap_jso(qualifiedName))), Element);
    }
    [_createElementNS_2](namespaceURI, qualifiedName, typeExtension) {
      return dart.as(wrap_jso(this.raw.createElementNS(unwrap_jso(namespaceURI), unwrap_jso(qualifiedName), unwrap_jso(typeExtension))), Element);
    }
    [_createEvent](eventType) {
      return this[_createEvent_1](eventType);
    }
    [_createEvent_1](eventType) {
      return dart.as(wrap_jso(this.raw.createEvent(unwrap_jso(eventType))), Event);
    }
    createRange() {
      return this[_createRange_1]();
    }
    [_createRange_1]() {
      return dart.as(wrap_jso(this.raw.createRange()), Range);
    }
    [_createTextNode](data) {
      return this[_createTextNode_1](data);
    }
    [_createTextNode_1](data) {
      return dart.as(wrap_jso(this.raw.createTextNode(unwrap_jso(data))), Text);
    }
    [_elementFromPoint](x, y) {
      return this[_elementFromPoint_1](x, y);
    }
    [_elementFromPoint_1](x, y) {
      return dart.as(wrap_jso(this.raw.elementFromPoint(unwrap_jso(x), unwrap_jso(y))), Element);
    }
    execCommand(command, userInterface, value) {
      return this[_execCommand_1](command, userInterface, value);
    }
    [_execCommand_1](command, userInterface, value) {
      return dart.as(wrap_jso(this.raw.execCommand(unwrap_jso(command), unwrap_jso(userInterface), unwrap_jso(value))), core.bool);
    }
    exitFullscreen() {
      this[_exitFullscreen_1]();
      return;
    }
    [_exitFullscreen_1]() {
      return wrap_jso(this.raw.exitFullscreen());
    }
    exitPointerLock() {
      this[_exitPointerLock_1]();
      return;
    }
    [_exitPointerLock_1]() {
      return wrap_jso(this.raw.exitPointerLock());
    }
    [_getCssCanvasContext](contextId, name, width, height) {
      return this[_getCssCanvasContext_1](contextId, name, width, height);
    }
    [_getCssCanvasContext_1](contextId, name, width, height) {
      return wrap_jso(this.raw.getCSSCanvasContext(unwrap_jso(contextId), unwrap_jso(name), unwrap_jso(width), unwrap_jso(height)));
    }
    getElementById(elementId) {
      return this[_getElementById_1](elementId);
    }
    [_getElementById_1](elementId) {
      return dart.as(wrap_jso(this.raw.getElementById(unwrap_jso(elementId))), Element);
    }
    getElementsByClassName(classNames) {
      return this[_getElementsByClassName_1](classNames);
    }
    [_getElementsByClassName_1](classNames) {
      return dart.as(wrap_jso(this.raw.getElementsByClassName(unwrap_jso(classNames))), HtmlCollection);
    }
    getElementsByName(elementName) {
      return this[_getElementsByName_1](elementName);
    }
    [_getElementsByName_1](elementName) {
      return dart.as(wrap_jso(this.raw.getElementsByName(unwrap_jso(elementName))), NodeList);
    }
    getElementsByTagName(localName) {
      return this[_getElementsByTagName_1](localName);
    }
    [_getElementsByTagName_1](localName) {
      return dart.as(wrap_jso(this.raw.getElementsByTagName(unwrap_jso(localName))), HtmlCollection);
    }
    importNode(node, deep) {
      if (deep === void 0) deep = null;
      if (deep != null) {
        return this[_importNode_1](node, deep);
      }
      return this[_importNode_2](node);
    }
    [_importNode_1](node, deep) {
      return dart.as(wrap_jso(this.raw.importNode(unwrap_jso(node), unwrap_jso(deep))), Node);
    }
    [_importNode_2](node) {
      return dart.as(wrap_jso(this.raw.importNode(unwrap_jso(node))), Node);
    }
    queryCommandEnabled(command) {
      return this[_queryCommandEnabled_1](command);
    }
    [_queryCommandEnabled_1](command) {
      return dart.as(wrap_jso(this.raw.queryCommandEnabled(unwrap_jso(command))), core.bool);
    }
    queryCommandIndeterm(command) {
      return this[_queryCommandIndeterm_1](command);
    }
    [_queryCommandIndeterm_1](command) {
      return dart.as(wrap_jso(this.raw.queryCommandIndeterm(unwrap_jso(command))), core.bool);
    }
    queryCommandState(command) {
      return this[_queryCommandState_1](command);
    }
    [_queryCommandState_1](command) {
      return dart.as(wrap_jso(this.raw.queryCommandState(unwrap_jso(command))), core.bool);
    }
    queryCommandSupported(command) {
      return this[_queryCommandSupported_1](command);
    }
    [_queryCommandSupported_1](command) {
      return dart.as(wrap_jso(this.raw.queryCommandSupported(unwrap_jso(command))), core.bool);
    }
    queryCommandValue(command) {
      return this[_queryCommandValue_1](command);
    }
    [_queryCommandValue_1](command) {
      return dart.as(wrap_jso(this.raw.queryCommandValue(unwrap_jso(command))), core.String);
    }
    transformDocumentToTreeView(noStyleMessage) {
      this[_transformDocumentToTreeView_1](noStyleMessage);
      return;
    }
    [_transformDocumentToTreeView_1](noStyleMessage) {
      return wrap_jso(this.raw.transformDocumentToTreeView(unwrap_jso(noStyleMessage)));
    }
    [_webkitExitFullscreen]() {
      this[_webkitExitFullscreen_1]();
      return;
    }
    [_webkitExitFullscreen_1]() {
      return wrap_jso(this.raw.webkitExitFullscreen());
    }
    get [_childElementCount]() {
      return dart.as(wrap_jso(this.raw.childElementCount), core.int);
    }
    get [_children]() {
      return dart.as(wrap_jso(this.raw.children), core.List$(Node));
    }
    get [_firstElementChild]() {
      return dart.as(wrap_jso(this.raw.firstElementChild), Element);
    }
    get [_lastElementChild]() {
      return dart.as(wrap_jso(this.raw.lastElementChild), Element);
    }
    querySelector(selectors) {
      return this[_querySelector_1](selectors);
    }
    [_querySelector_1](selectors) {
      return dart.as(wrap_jso(this.raw.querySelector(unwrap_jso(selectors))), Element);
    }
    [_querySelectorAll](selectors) {
      return this[_querySelectorAll_1](selectors);
    }
    [_querySelectorAll_1](selectors) {
      return dart.as(wrap_jso(this.raw.querySelectorAll(unwrap_jso(selectors))), NodeList);
    }
    get onBeforeCopy() {
      return Element.beforeCopyEvent.forTarget(this);
    }
    get onBeforeCut() {
      return Element.beforeCutEvent.forTarget(this);
    }
    get onBeforePaste() {
      return Element.beforePasteEvent.forTarget(this);
    }
    get onCopy() {
      return Element.copyEvent.forTarget(this);
    }
    get onCut() {
      return Element.cutEvent.forTarget(this);
    }
    get onPaste() {
      return Element.pasteEvent.forTarget(this);
    }
    get onPointerLockChange() {
      return Document.pointerLockChangeEvent.forTarget(this);
    }
    get onPointerLockError() {
      return Document.pointerLockErrorEvent.forTarget(this);
    }
    get onReadyStateChange() {
      return Document.readyStateChangeEvent.forTarget(this);
    }
    get onSearch() {
      return Element.searchEvent.forTarget(this);
    }
    get onSelectionChange() {
      return Document.selectionChangeEvent.forTarget(this);
    }
    get onSelectStart() {
      return Element.selectStartEvent.forTarget(this);
    }
    get onFullscreenChange() {
      return Element.fullscreenChangeEvent.forTarget(this);
    }
    get onFullscreenError() {
      return Element.fullscreenErrorEvent.forTarget(this);
    }
    querySelectorAll(selectors) {
      return new _FrozenElementList._wrap(this[_querySelectorAll](selectors));
    }
    query(relativeSelectors) {
      return this.querySelector(relativeSelectors);
    }
    queryAll(relativeSelectors) {
      return this.querySelectorAll(relativeSelectors);
    }
    get supportsRegisterElement() {
      return true;
    }
    get supportsRegister() {
      return this.supportsRegisterElement;
    }
    createElement(tagName, typeExtension) {
      if (typeExtension === void 0) typeExtension = null;
      return this[_createElement](tagName, typeExtension);
    }
    createElementNS(namespaceURI, qualifiedName, typeExtension) {
      if (typeExtension === void 0) typeExtension = null;
      return this[_createElementNS](namespaceURI, qualifiedName, typeExtension);
    }
  }
  dart.defineNamedConstructor(Document, 'internal_');
  dart.setSignature(Document, {
    constructors: () => ({
      _: [Document, []],
      internal_: [Document, []]
    }),
    methods: () => ({
      adoptNode: [Node, [Node]],
      [_adoptNode_1]: [Node, [Node]],
      [_caretRangeFromPoint]: [Range, [core.int, core.int]],
      [_caretRangeFromPoint_1]: [Range, [dart.dynamic, dart.dynamic]],
      createDocumentFragment: [DocumentFragment, []],
      [_createDocumentFragment_1]: [DocumentFragment, []],
      [_createElement]: [Element, [core.String], [core.String]],
      [_createElement_1]: [Element, [dart.dynamic]],
      [_createElement_2]: [Element, [dart.dynamic, dart.dynamic]],
      [_createElementNS]: [Element, [core.String, core.String], [core.String]],
      [_createElementNS_1]: [Element, [dart.dynamic, dart.dynamic]],
      [_createElementNS_2]: [Element, [dart.dynamic, dart.dynamic, dart.dynamic]],
      [_createEvent]: [Event, [core.String]],
      [_createEvent_1]: [Event, [dart.dynamic]],
      createRange: [Range, []],
      [_createRange_1]: [Range, []],
      [_createTextNode]: [Text, [core.String]],
      [_createTextNode_1]: [Text, [dart.dynamic]],
      [_elementFromPoint]: [Element, [core.int, core.int]],
      [_elementFromPoint_1]: [Element, [dart.dynamic, dart.dynamic]],
      execCommand: [core.bool, [core.String, core.bool, core.String]],
      [_execCommand_1]: [core.bool, [dart.dynamic, dart.dynamic, dart.dynamic]],
      exitFullscreen: [dart.void, []],
      [_exitFullscreen_1]: [dart.void, []],
      exitPointerLock: [dart.void, []],
      [_exitPointerLock_1]: [dart.void, []],
      [_getCssCanvasContext]: [core.Object, [core.String, core.String, core.int, core.int]],
      [_getCssCanvasContext_1]: [core.Object, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]],
      getElementById: [Element, [core.String]],
      [_getElementById_1]: [Element, [dart.dynamic]],
      getElementsByClassName: [HtmlCollection, [core.String]],
      [_getElementsByClassName_1]: [HtmlCollection, [dart.dynamic]],
      getElementsByName: [NodeList, [core.String]],
      [_getElementsByName_1]: [NodeList, [dart.dynamic]],
      getElementsByTagName: [HtmlCollection, [core.String]],
      [_getElementsByTagName_1]: [HtmlCollection, [dart.dynamic]],
      importNode: [Node, [Node], [core.bool]],
      [_importNode_1]: [Node, [Node, dart.dynamic]],
      [_importNode_2]: [Node, [Node]],
      queryCommandEnabled: [core.bool, [core.String]],
      [_queryCommandEnabled_1]: [core.bool, [dart.dynamic]],
      queryCommandIndeterm: [core.bool, [core.String]],
      [_queryCommandIndeterm_1]: [core.bool, [dart.dynamic]],
      queryCommandState: [core.bool, [core.String]],
      [_queryCommandState_1]: [core.bool, [dart.dynamic]],
      queryCommandSupported: [core.bool, [core.String]],
      [_queryCommandSupported_1]: [core.bool, [dart.dynamic]],
      queryCommandValue: [core.String, [core.String]],
      [_queryCommandValue_1]: [core.String, [dart.dynamic]],
      transformDocumentToTreeView: [dart.void, [core.String]],
      [_transformDocumentToTreeView_1]: [dart.void, [dart.dynamic]],
      [_webkitExitFullscreen]: [dart.void, []],
      [_webkitExitFullscreen_1]: [dart.void, []],
      querySelector: [Element, [core.String]],
      [_querySelector_1]: [Element, [dart.dynamic]],
      [_querySelectorAll]: [NodeList, [core.String]],
      [_querySelectorAll_1]: [NodeList, [dart.dynamic]],
      querySelectorAll: [ElementList$(Element), [core.String]],
      query: [Element, [core.String]],
      queryAll: [ElementList$(Element), [core.String]],
      createElement: [Element, [core.String], [core.String]],
      createElementNS: [Element, [core.String, core.String], [core.String]]
    }),
    statics: () => ({internalCreateDocument: [Document, []]}),
    names: ['internalCreateDocument']
  });
  Document[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('Document')), dart.const(new _js_helper.Native("Document"))];
  dart.defineLazyProperties(Document, {
    get pointerLockChangeEvent() {
      return dart.const(new (EventStreamProvider$(Event))('pointerlockchange'));
    },
    get pointerLockErrorEvent() {
      return dart.const(new (EventStreamProvider$(Event))('pointerlockerror'));
    },
    get readyStateChangeEvent() {
      return dart.const(new (EventStreamProvider$(Event))('readystatechange'));
    },
    get selectionChangeEvent() {
      return dart.const(new (EventStreamProvider$(Event))('selectionchange'));
    }
  });
  const _docChildren = Symbol('_docChildren');
  class DocumentFragment extends Node {
    static new() {
      return exports.document.createDocumentFragment();
    }
    static html(html, opts) {
      let validator = opts && 'validator' in opts ? opts.validator : null;
      let treeSanitizer = opts && 'treeSanitizer' in opts ? opts.treeSanitizer : null;
      return exports.document.body.createFragment(html, {validator: validator, treeSanitizer: treeSanitizer});
    }
    static svg(svgContent, opts) {
      let validator = opts && 'validator' in opts ? opts.validator : null;
      let treeSanitizer = opts && 'treeSanitizer' in opts ? opts.treeSanitizer : null;
      dart.throw('SVG not supported in DDC');
    }
    get [_children]() {
      return dart.throw(new core.UnimplementedError('Use _docChildren instead'));
    }
    get children() {
      if (this[_docChildren] == null) {
        this[_docChildren] = new html_common.FilteredElementList(this);
      }
      return this[_docChildren];
    }
    set children(value) {
      let copy = core.List.from(value);
      let children = this.children;
      children[dartx.clear]();
      children[dartx.addAll](dart.as(copy, core.Iterable$(Element)));
    }
    querySelectorAll(selectors) {
      return new _FrozenElementList._wrap(this[_querySelectorAll](selectors));
    }
    get innerHtml() {
      let e = Element.tag("div");
      e.append(this.clone(true));
      return e.innerHtml;
    }
    set innerHtml(value) {
      this.setInnerHtml(value);
    }
    setInnerHtml(html, opts) {
      let validator = opts && 'validator' in opts ? opts.validator : null;
      let treeSanitizer = opts && 'treeSanitizer' in opts ? opts.treeSanitizer : null;
      this.nodes[dartx.clear]();
      this.append(exports.document.body.createFragment(html, {validator: validator, treeSanitizer: treeSanitizer}));
    }
    appendText(text) {
      this.append(Text.new(text));
    }
    appendHtml(text, opts) {
      let validator = opts && 'validator' in opts ? opts.validator : null;
      let NodeTreeSanitizer = opts && 'NodeTreeSanitizer' in opts ? opts.NodeTreeSanitizer : null;
      let treeSanitizer = opts && 'treeSanitizer' in opts ? opts.treeSanitizer : null;
      this.append(DocumentFragment.html(text, {validator: validator, treeSanitizer: dart.as(treeSanitizer, NodeTreeSanitizer)}));
    }
    query(relativeSelectors) {
      return this.querySelector(relativeSelectors);
    }
    queryAll(relativeSelectors) {
      return this.querySelectorAll(relativeSelectors);
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateDocumentFragment() {
      return new DocumentFragment.internal_();
    }
    internal_() {
      this[_docChildren] = null;
      super.internal_();
    }
    getElementById(elementId) {
      return this[_getElementById_1](elementId);
    }
    [_getElementById_1](elementId) {
      return dart.as(wrap_jso(this.raw.getElementById(unwrap_jso(elementId))), Element);
    }
    get [_childElementCount]() {
      return dart.as(wrap_jso(this.raw.childElementCount), core.int);
    }
    get [_firstElementChild]() {
      return dart.as(wrap_jso(this.raw.firstElementChild), Element);
    }
    get [_lastElementChild]() {
      return dart.as(wrap_jso(this.raw.lastElementChild), Element);
    }
    querySelector(selectors) {
      return this[_querySelector_1](selectors);
    }
    [_querySelector_1](selectors) {
      return dart.as(wrap_jso(this.raw.querySelector(unwrap_jso(selectors))), Element);
    }
    [_querySelectorAll](selectors) {
      return this[_querySelectorAll_1](selectors);
    }
    [_querySelectorAll_1](selectors) {
      return dart.as(wrap_jso(this.raw.querySelectorAll(unwrap_jso(selectors))), NodeList);
    }
  }
  DocumentFragment[dart.implements] = () => [ParentNode];
  dart.defineNamedConstructor(DocumentFragment, 'internal_');
  dart.setSignature(DocumentFragment, {
    constructors: () => ({
      new: [DocumentFragment, []],
      html: [DocumentFragment, [core.String], {validator: NodeValidator, treeSanitizer: NodeTreeSanitizer}],
      svg: [DocumentFragment, [core.String], {validator: NodeValidator, treeSanitizer: NodeTreeSanitizer}],
      _: [DocumentFragment, []],
      internal_: [DocumentFragment, []]
    }),
    methods: () => ({
      querySelectorAll: [ElementList$(Element), [core.String]],
      setInnerHtml: [dart.void, [core.String], {validator: NodeValidator, treeSanitizer: NodeTreeSanitizer}],
      appendText: [dart.void, [core.String]],
      appendHtml: [dart.void, [core.String], {validator: NodeValidator, NodeTreeSanitizer: dart.dynamic, treeSanitizer: dart.dynamic}],
      query: [Element, [core.String]],
      queryAll: [ElementList$(Element), [core.String]],
      getElementById: [Element, [core.String]],
      [_getElementById_1]: [Element, [dart.dynamic]],
      querySelector: [Element, [core.String]],
      [_querySelector_1]: [Element, [dart.dynamic]],
      [_querySelectorAll]: [NodeList, [core.String]],
      [_querySelectorAll_1]: [NodeList, [dart.dynamic]]
    }),
    statics: () => ({internalCreateDocumentFragment: [DocumentFragment, []]}),
    names: ['internalCreateDocumentFragment']
  });
  DocumentFragment[dart.metadata] = () => [dart.const(new _metadata.DomName('DocumentFragment')), dart.const(new _js_helper.Native("DocumentFragment"))];
  const _createDocument_1 = Symbol('_createDocument_1');
  const _createDocumentType_1 = Symbol('_createDocumentType_1');
  const _createHtmlDocument_1 = Symbol('_createHtmlDocument_1');
  const _hasFeature_1 = Symbol('_hasFeature_1');
  class DomImplementation extends DartHtmlDomObject {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateDomImplementation() {
      return new DomImplementation.internal_();
    }
    internal_() {
      super.DartHtmlDomObject();
    }
    ['=='](other) {
      return dart.equals(unwrap_jso(other), unwrap_jso(this)) || dart.notNull(core.identical(this, other));
    }
    get hashCode() {
      return dart.hashCode(unwrap_jso(this));
    }
    createDocument(namespaceURI, qualifiedName, doctype) {
      return this[_createDocument_1](namespaceURI, qualifiedName, doctype);
    }
    [_createDocument_1](namespaceURI, qualifiedName, doctype) {
      return dart.as(wrap_jso(this.raw.createDocument(unwrap_jso(namespaceURI), unwrap_jso(qualifiedName), unwrap_jso(doctype))), Document);
    }
    createDocumentType(qualifiedName, publicId, systemId) {
      return this[_createDocumentType_1](qualifiedName, publicId, systemId);
    }
    [_createDocumentType_1](qualifiedName, publicId, systemId) {
      return dart.as(wrap_jso(this.raw.createDocumentType(unwrap_jso(qualifiedName), unwrap_jso(publicId), unwrap_jso(systemId))), Node);
    }
    createHtmlDocument(title) {
      return this[_createHtmlDocument_1](title);
    }
    [_createHtmlDocument_1](title) {
      return dart.as(wrap_jso(this.raw.createHTMLDocument(unwrap_jso(title))), HtmlDocument);
    }
    hasFeature(feature, version) {
      return this[_hasFeature_1](feature, version);
    }
    [_hasFeature_1](feature, version) {
      return dart.as(wrap_jso(this.raw.hasFeature(unwrap_jso(feature), unwrap_jso(version))), core.bool);
    }
  }
  dart.defineNamedConstructor(DomImplementation, 'internal_');
  dart.setSignature(DomImplementation, {
    constructors: () => ({
      _: [DomImplementation, []],
      internal_: [DomImplementation, []]
    }),
    methods: () => ({
      createDocument: [Document, [core.String, core.String, Node]],
      [_createDocument_1]: [Document, [dart.dynamic, dart.dynamic, Node]],
      createDocumentType: [Node, [core.String, core.String, core.String]],
      [_createDocumentType_1]: [Node, [dart.dynamic, dart.dynamic, dart.dynamic]],
      createHtmlDocument: [HtmlDocument, [core.String]],
      [_createHtmlDocument_1]: [HtmlDocument, [dart.dynamic]],
      hasFeature: [core.bool, [core.String, core.String]],
      [_hasFeature_1]: [core.bool, [dart.dynamic, dart.dynamic]]
    }),
    statics: () => ({internalCreateDomImplementation: [DomImplementation, []]}),
    names: ['internalCreateDomImplementation']
  });
  DomImplementation[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('DOMImplementation')), dart.const(new _js_helper.Native("DOMImplementation"))];
  const _add_1 = Symbol('_add_1');
  const _remove_1 = Symbol('_remove_1');
  const _toggle_1 = Symbol('_toggle_1');
  const _toggle_2 = Symbol('_toggle_2');
  class DomTokenList extends DartHtmlDomObject {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateDomTokenList() {
      return new DomTokenList.internal_();
    }
    internal_() {
      super.DartHtmlDomObject();
    }
    ['=='](other) {
      return dart.equals(unwrap_jso(other), unwrap_jso(this)) || dart.notNull(core.identical(this, other));
    }
    get hashCode() {
      return dart.hashCode(unwrap_jso(this));
    }
    get length() {
      return dart.as(wrap_jso(this.raw.length), core.int);
    }
    add(tokens) {
      this[_add_1](tokens);
      return;
    }
    [_add_1](tokens) {
      return wrap_jso(this.raw.add(unwrap_jso(tokens)));
    }
    contains(token) {
      return this[_contains_1](token);
    }
    [_contains_1](token) {
      return dart.as(wrap_jso(this.raw.contains(unwrap_jso(token))), core.bool);
    }
    item(index) {
      return this[_item_1](index);
    }
    [_item_1](index) {
      return dart.as(wrap_jso(this.raw.item(unwrap_jso(index))), core.String);
    }
    remove(tokens) {
      this[_remove_1](tokens);
      return;
    }
    [_remove_1](tokens) {
      return wrap_jso(this.raw.remove(unwrap_jso(tokens)));
    }
    toggle(token, force) {
      if (force === void 0) force = null;
      if (force != null) {
        return this[_toggle_1](token, force);
      }
      return this[_toggle_2](token);
    }
    [_toggle_1](token, force) {
      return dart.as(wrap_jso(this.raw.toggle(unwrap_jso(token), unwrap_jso(force))), core.bool);
    }
    [_toggle_2](token) {
      return dart.as(wrap_jso(this.raw.toggle(unwrap_jso(token))), core.bool);
    }
  }
  dart.defineNamedConstructor(DomTokenList, 'internal_');
  dart.setSignature(DomTokenList, {
    constructors: () => ({
      _: [DomTokenList, []],
      internal_: [DomTokenList, []]
    }),
    methods: () => ({
      add: [dart.void, [core.String]],
      [_add_1]: [dart.void, [dart.dynamic]],
      contains: [core.bool, [core.String]],
      [_contains_1]: [core.bool, [dart.dynamic]],
      item: [core.String, [core.int]],
      [_item_1]: [core.String, [dart.dynamic]],
      remove: [dart.void, [core.String]],
      [_remove_1]: [dart.void, [dart.dynamic]],
      toggle: [core.bool, [core.String], [core.bool]],
      [_toggle_1]: [core.bool, [dart.dynamic, dart.dynamic]],
      [_toggle_2]: [core.bool, [dart.dynamic]]
    }),
    statics: () => ({internalCreateDomTokenList: [DomTokenList, []]}),
    names: ['internalCreateDomTokenList']
  });
  DomTokenList[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('DOMTokenList')), dart.const(new _js_helper.Native("DOMTokenList"))];
  const _childElements = Symbol('_childElements');
  const _element = Symbol('_element');
  const _filter = Symbol('_filter');
  class _ChildrenElementList extends collection.ListBase$(Element) {
    _wrap(element) {
      this[_childElements] = dart.as(element[_children], HtmlCollection);
      this[_element] = element;
    }
    contains(element) {
      return this[_childElements].contains(element);
    }
    get isEmpty() {
      return this[_element][_firstElementChild] == null;
    }
    get length() {
      return this[_childElements].length;
    }
    get(index) {
      return dart.as(this[_childElements].get(index), Element);
    }
    set(index, value) {
      this[_element][_replaceChild](value, this[_childElements].get(index));
      return value;
    }
    set length(newLength) {
      dart.throw(new core.UnsupportedError('Cannot resize element lists'));
    }
    add(value) {
      this[_element].append(value);
      return value;
    }
    get iterator() {
      return this[dartx.toList]()[dartx.iterator];
    }
    addAll(iterable) {
      if (dart.is(iterable, _ChildNodeListLazy)) {
        iterable = core.List$(Element).from(iterable);
      }
      for (let element of iterable) {
        this[_element].append(element);
      }
    }
    sort(compare) {
      if (compare === void 0) compare = null;
      dart.throw(new core.UnsupportedError('Cannot sort element lists'));
    }
    shuffle(random) {
      if (random === void 0) random = null;
      dart.throw(new core.UnsupportedError('Cannot shuffle element lists'));
    }
    removeWhere(test) {
      this[_filter](test, false);
    }
    retainWhere(test) {
      this[_filter](test, true);
    }
    [_filter](test, retainMatching) {
      let removed = null;
      if (dart.notNull(retainMatching)) {
        removed = this[_element].children[dartx.where](dart.fn(e => !dart.notNull(dart.dcall(test, e)), core.bool, [Element]));
      } else {
        removed = this[_element].children[dartx.where](dart.as(test, __CastType0));
      }
      for (let e of dart.as(removed, core.Iterable))
        dart.dsend(e, 'remove');
    }
    setRange(start, end, iterable, skipCount) {
      if (skipCount === void 0) skipCount = 0;
      dart.throw(new core.UnimplementedError());
    }
    replaceRange(start, end, iterable) {
      dart.throw(new core.UnimplementedError());
    }
    fillRange(start, end, fillValue) {
      if (fillValue === void 0) fillValue = null;
      dart.throw(new core.UnimplementedError());
    }
    remove(object) {
      if (dart.is(object, Element)) {
        let element = object;
        if (dart.equals(element.parentNode, this[_element])) {
          this[_element][_removeChild](element);
          return true;
        }
      }
      return false;
    }
    insert(index, element) {
      if (dart.notNull(index) < 0 || dart.notNull(index) > dart.notNull(this.length)) {
        dart.throw(new core.RangeError.range(index, 0, this.length));
      }
      if (index == this.length) {
        this[_element].append(element);
      } else {
        this[_element].insertBefore(element, this.get(index));
      }
    }
    setAll(index, iterable) {
      dart.throw(new core.UnimplementedError());
    }
    clear() {
      this[_element][_clearChildren]();
    }
    removeAt(index) {
      let result = this.get(index);
      if (result != null) {
        this[_element][_removeChild](result);
      }
      return result;
    }
    removeLast() {
      let result = this.last;
      if (result != null) {
        this[_element][_removeChild](result);
      }
      return result;
    }
    get first() {
      let result = this[_element][_firstElementChild];
      if (result == null) dart.throw(new core.StateError("No elements"));
      return result;
    }
    get last() {
      let result = this[_element][_lastElementChild];
      if (result == null) dart.throw(new core.StateError("No elements"));
      return result;
    }
    get single() {
      if (dart.notNull(this.length) > 1) dart.throw(new core.StateError("More than one element"));
      return this.first;
    }
    get rawList() {
      return this[_childElements];
    }
  }
  _ChildrenElementList[dart.implements] = () => [html_common.NodeListWrapper];
  dart.defineNamedConstructor(_ChildrenElementList, '_wrap');
  dart.setSignature(_ChildrenElementList, {
    constructors: () => ({_wrap: [_ChildrenElementList, [Element]]}),
    methods: () => ({
      get: [Element, [core.int]],
      set: [dart.void, [core.int, Element]],
      add: [Element, [Element]],
      addAll: [dart.void, [core.Iterable$(Element)]],
      sort: [dart.void, [], [dart.functionType(core.int, [Element, Element])]],
      removeWhere: [dart.void, [dart.functionType(core.bool, [Element])]],
      retainWhere: [dart.void, [dart.functionType(core.bool, [Element])]],
      [_filter]: [dart.void, [dart.functionType(core.bool, [dart.dynamic]), core.bool]],
      setRange: [dart.void, [core.int, core.int, core.Iterable$(Element)], [core.int]],
      replaceRange: [dart.void, [core.int, core.int, core.Iterable$(Element)]],
      fillRange: [dart.void, [core.int, core.int], [Element]],
      insert: [dart.void, [core.int, Element]],
      setAll: [dart.void, [core.int, core.Iterable$(Element)]],
      removeAt: [Element, [core.int]],
      removeLast: [Element, []]
    })
  });
  dart.defineExtensionMembers(_ChildrenElementList, [
    'contains',
    'get',
    'set',
    'add',
    'addAll',
    'sort',
    'shuffle',
    'removeWhere',
    'retainWhere',
    'setRange',
    'replaceRange',
    'fillRange',
    'remove',
    'insert',
    'setAll',
    'clear',
    'removeAt',
    'removeLast',
    'isEmpty',
    'length',
    'length',
    'iterator',
    'first',
    'last',
    'single'
  ]);
  const ElementList$ = dart.generic(function(T) {
    class ElementList extends collection.ListBase$(T) {}
    return ElementList;
  });
  let ElementList = ElementList$();
  const _nodeList = Symbol('_nodeList');
  const _forElementList = Symbol('_forElementList');
  class _FrozenElementList extends collection.ListBase$(Element) {
    _wrap(nodeList) {
      this[_nodeList] = nodeList;
      this.dartClass_instance = null;
      this.dartClass_instance = this[_nodeList];
    }
    get length() {
      return this[_nodeList][dartx.length];
    }
    get(index) {
      return dart.as(this[_nodeList][dartx.get](index), Element);
    }
    set(index, value) {
      dart.throw(new core.UnsupportedError('Cannot modify list'));
      return value;
    }
    set length(newLength) {
      dart.throw(new core.UnsupportedError('Cannot modify list'));
    }
    sort(compare) {
      if (compare === void 0) compare = null;
      dart.throw(new core.UnsupportedError('Cannot sort list'));
    }
    shuffle(random) {
      if (random === void 0) random = null;
      dart.throw(new core.UnsupportedError('Cannot shuffle list'));
    }
    get first() {
      return dart.as(this[_nodeList][dartx.first], Element);
    }
    get last() {
      return dart.as(this[_nodeList][dartx.last], Element);
    }
    get single() {
      return dart.as(this[_nodeList][dartx.single], Element);
    }
    get classes() {
      return exports._MultiElementCssClassSet.new(this);
    }
    get style() {
      return new _CssStyleDeclarationSet(this);
    }
    set classes(value) {
      this[_nodeList][dartx.forEach](dart.fn(e => dart.dput(e, 'classes', value), core.Iterable$(core.String), [Node]));
    }
    get contentEdge() {
      return new _ContentCssListRect(this);
    }
    get paddingEdge() {
      return this.first.paddingEdge;
    }
    get borderEdge() {
      return this.first.borderEdge;
    }
    get marginEdge() {
      return this.first.marginEdge;
    }
    get rawList() {
      return this[_nodeList];
    }
    get onBeforeCopy() {
      return Element.beforeCopyEvent[_forElementList](this);
    }
    get onBeforeCut() {
      return Element.beforeCutEvent[_forElementList](this);
    }
    get onBeforePaste() {
      return Element.beforePasteEvent[_forElementList](this);
    }
    get onCopy() {
      return Element.copyEvent[_forElementList](this);
    }
    get onCut() {
      return Element.cutEvent[_forElementList](this);
    }
    get onPaste() {
      return Element.pasteEvent[_forElementList](this);
    }
    get onSearch() {
      return Element.searchEvent[_forElementList](this);
    }
    get onSelectStart() {
      return Element.selectStartEvent[_forElementList](this);
    }
    get onFullscreenChange() {
      return Element.fullscreenChangeEvent[_forElementList](this);
    }
    get onFullscreenError() {
      return Element.fullscreenErrorEvent[_forElementList](this);
    }
  }
  _FrozenElementList[dart.implements] = () => [ElementList$(Element), html_common.NodeListWrapper];
  dart.defineNamedConstructor(_FrozenElementList, '_wrap');
  dart.setSignature(_FrozenElementList, {
    constructors: () => ({_wrap: [_FrozenElementList, [core.List$(Node)]]}),
    methods: () => ({
      get: [Element, [core.int]],
      set: [dart.void, [core.int, Element]],
      sort: [dart.void, [], [core.Comparator$(Element)]]
    })
  });
  dart.defineExtensionMembers(_FrozenElementList, [
    'get',
    'set',
    'sort',
    'shuffle',
    'length',
    'length',
    'first',
    'last',
    'single'
  ]);
  class _ElementFactoryProvider extends core.Object {
    static createElement_tag(tag, typeExtension) {
      return exports.document.createElement(tag, typeExtension);
    }
  }
  dart.setSignature(_ElementFactoryProvider, {
    statics: () => ({createElement_tag: [Element, [core.String, core.String]]}),
    names: ['createElement_tag']
  });
  const _value = Symbol('_value');
  class ScrollAlignment extends core.Object {
    _internal(value) {
      this[_value] = value;
    }
    toString() {
      return `ScrollAlignment.${this[_value]}`;
    }
  }
  dart.defineNamedConstructor(ScrollAlignment, '_internal');
  dart.setSignature(ScrollAlignment, {
    constructors: () => ({_internal: [ScrollAlignment, [dart.dynamic]]})
  });
  dart.defineLazyProperties(ScrollAlignment, {
    get TOP() {
      return dart.const(new ScrollAlignment._internal('TOP'));
    },
    get CENTER() {
      return dart.const(new ScrollAlignment._internal('CENTER'));
    },
    get BOTTOM() {
      return dart.const(new ScrollAlignment._internal('BOTTOM'));
    }
  });
  const _ptr = Symbol('_ptr');
  class Events extends core.Object {
    Events(ptr) {
      this[_ptr] = ptr;
    }
    get(type) {
      return new _EventStream(this[_ptr], type, false);
    }
  }
  dart.setSignature(Events, {
    constructors: () => ({Events: [Events, [EventTarget]]}),
    methods: () => ({get: [async.Stream, [core.String]]})
  });
  class ElementEvents extends Events {
    ElementEvents(ptr) {
      super.Events(ptr);
    }
    get(type) {
      if (dart.notNull(ElementEvents.webkitEvents.keys[dartx.contains](type[dartx.toLowerCase]()))) {
        if (dart.notNull(html_common.Device.isWebKit)) {
          return new _ElementEventStreamImpl(this[_ptr], ElementEvents.webkitEvents.get(type[dartx.toLowerCase]()), false);
        }
      }
      return new _ElementEventStreamImpl(this[_ptr], type, false);
    }
  }
  dart.setSignature(ElementEvents, {
    constructors: () => ({ElementEvents: [ElementEvents, [Element]]})
  });
  dart.defineLazyProperties(ElementEvents, {
    get webkitEvents() {
      return dart.map({animationend: 'webkitAnimationEnd', animationiteration: 'webkitAnimationIteration', animationstart: 'webkitAnimationStart', fullscreenchange: 'webkitfullscreenchange', fullscreenerror: 'webkitfullscreenerror', keyadded: 'webkitkeyadded', keyerror: 'webkitkeyerror', keymessage: 'webkitkeymessage', needkey: 'webkitneedkey', pointerlockchange: 'webkitpointerlockchange', pointerlockerror: 'webkitpointerlockerror', resourcetimingbufferfull: 'webkitresourcetimingbufferfull', transitionend: 'webkitTransitionEnd', speechchange: 'webkitSpeechChange'});
    }
  });
  class HeadElement extends HtmlElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(exports.document.createElement("head"), HeadElement);
    }
    static internalCreateHeadElement() {
      return new HeadElement.internal_();
    }
    internal_() {
      super.internal_();
    }
  }
  dart.defineNamedConstructor(HeadElement, 'internal_');
  dart.setSignature(HeadElement, {
    constructors: () => ({
      _: [HeadElement, []],
      new: [HeadElement, []],
      internal_: [HeadElement, []]
    }),
    statics: () => ({internalCreateHeadElement: [HeadElement, []]}),
    names: ['internalCreateHeadElement']
  });
  HeadElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('HTMLHeadElement')), dart.const(new _js_helper.Native("HTMLHeadElement"))];
  const _get_state = Symbol('_get_state');
  const _back_1 = Symbol('_back_1');
  const _forward_1 = Symbol('_forward_1');
  const _go_1 = Symbol('_go_1');
  const _pushState_1 = Symbol('_pushState_1');
  const _pushState_2 = Symbol('_pushState_2');
  const _replaceState_1 = Symbol('_replaceState_1');
  const _replaceState_2 = Symbol('_replaceState_2');
  class History extends DartHtmlDomObject {
    static get supportsState() {
      return true;
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateHistory() {
      return new History.internal_();
    }
    internal_() {
      super.DartHtmlDomObject();
    }
    ['=='](other) {
      return dart.equals(unwrap_jso(other), unwrap_jso(this)) || dart.notNull(core.identical(this, other));
    }
    get hashCode() {
      return dart.hashCode(unwrap_jso(this));
    }
    get length() {
      return dart.as(wrap_jso(this.raw.length), core.int);
    }
    get state() {
      return html_common.convertNativeToDart_SerializedScriptValue(this[_get_state]);
    }
    get [_get_state]() {
      return wrap_jso(this.raw.state);
    }
    back() {
      this[_back_1]();
      return;
    }
    [_back_1]() {
      return wrap_jso(this.raw.back());
    }
    forward() {
      this[_forward_1]();
      return;
    }
    [_forward_1]() {
      return wrap_jso(this.raw.forward());
    }
    go(distance) {
      this[_go_1](distance);
      return;
    }
    [_go_1](distance) {
      return wrap_jso(this.raw.go(unwrap_jso(distance)));
    }
    pushState(data, title, url) {
      if (url === void 0) url = null;
      if (url != null) {
        let data_1 = html_common.convertDartToNative_SerializedScriptValue(data);
        this[_pushState_1](data_1, title, url);
        return;
      }
      let data_1 = html_common.convertDartToNative_SerializedScriptValue(data);
      this[_pushState_2](data_1, title);
      return;
    }
    [_pushState_1](data, title, url) {
      return wrap_jso(this.raw.pushState(unwrap_jso(data), unwrap_jso(title), unwrap_jso(url)));
    }
    [_pushState_2](data, title) {
      return wrap_jso(this.raw.pushState(unwrap_jso(data), unwrap_jso(title)));
    }
    replaceState(data, title, url) {
      if (url === void 0) url = null;
      if (url != null) {
        let data_1 = html_common.convertDartToNative_SerializedScriptValue(data);
        this[_replaceState_1](data_1, title, url);
        return;
      }
      let data_1 = html_common.convertDartToNative_SerializedScriptValue(data);
      this[_replaceState_2](data_1, title);
      return;
    }
    [_replaceState_1](data, title, url) {
      return wrap_jso(this.raw.replaceState(unwrap_jso(data), unwrap_jso(title), unwrap_jso(url)));
    }
    [_replaceState_2](data, title) {
      return wrap_jso(this.raw.replaceState(unwrap_jso(data), unwrap_jso(title)));
    }
  }
  History[dart.implements] = () => [HistoryBase];
  dart.defineNamedConstructor(History, 'internal_');
  dart.setSignature(History, {
    constructors: () => ({
      _: [History, []],
      internal_: [History, []]
    }),
    methods: () => ({
      back: [dart.void, []],
      [_back_1]: [dart.void, []],
      forward: [dart.void, []],
      [_forward_1]: [dart.void, []],
      go: [dart.void, [core.int]],
      [_go_1]: [dart.void, [dart.dynamic]],
      pushState: [dart.void, [dart.dynamic, core.String], [core.String]],
      [_pushState_1]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic]],
      [_pushState_2]: [dart.void, [dart.dynamic, dart.dynamic]],
      replaceState: [dart.void, [dart.dynamic, core.String], [core.String]],
      [_replaceState_1]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic]],
      [_replaceState_2]: [dart.void, [dart.dynamic, dart.dynamic]]
    }),
    statics: () => ({internalCreateHistory: [History, []]}),
    names: ['internalCreateHistory']
  });
  History[dart.metadata] = () => [dart.const(new _metadata.DomName('History')), dart.const(new _js_helper.Native("History"))];
  const ImmutableListMixin$ = dart.generic(function(E) {
    class ImmutableListMixin extends core.Object {
      get iterator() {
        return new (FixedSizeListIterator$(E))(this);
      }
      [Symbol.iterator]() {
        return new dart.JsIterator(this.iterator);
      }
      add(value) {
        dart.as(value, E);
        dart.throw(new core.UnsupportedError("Cannot add to immutable List."));
      }
      addAll(iterable) {
        dart.as(iterable, core.Iterable$(E));
        dart.throw(new core.UnsupportedError("Cannot add to immutable List."));
      }
      sort(compare) {
        if (compare === void 0) compare = null;
        dart.as(compare, dart.functionType(core.int, [E, E]));
        dart.throw(new core.UnsupportedError("Cannot sort immutable List."));
      }
      shuffle(random) {
        if (random === void 0) random = null;
        dart.throw(new core.UnsupportedError("Cannot shuffle immutable List."));
      }
      insert(index, element) {
        dart.as(element, E);
        dart.throw(new core.UnsupportedError("Cannot add to immutable List."));
      }
      insertAll(index, iterable) {
        dart.as(iterable, core.Iterable$(E));
        dart.throw(new core.UnsupportedError("Cannot add to immutable List."));
      }
      setAll(index, iterable) {
        dart.as(iterable, core.Iterable$(E));
        dart.throw(new core.UnsupportedError("Cannot modify an immutable List."));
      }
      removeAt(pos) {
        dart.throw(new core.UnsupportedError("Cannot remove from immutable List."));
      }
      removeLast() {
        dart.throw(new core.UnsupportedError("Cannot remove from immutable List."));
      }
      remove(object) {
        dart.throw(new core.UnsupportedError("Cannot remove from immutable List."));
      }
      removeWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        dart.throw(new core.UnsupportedError("Cannot remove from immutable List."));
      }
      retainWhere(test) {
        dart.as(test, dart.functionType(core.bool, [E]));
        dart.throw(new core.UnsupportedError("Cannot remove from immutable List."));
      }
      setRange(start, end, iterable, skipCount) {
        dart.as(iterable, core.Iterable$(E));
        if (skipCount === void 0) skipCount = 0;
        dart.throw(new core.UnsupportedError("Cannot setRange on immutable List."));
      }
      removeRange(start, end) {
        dart.throw(new core.UnsupportedError("Cannot removeRange on immutable List."));
      }
      replaceRange(start, end, iterable) {
        dart.as(iterable, core.Iterable$(E));
        dart.throw(new core.UnsupportedError("Cannot modify an immutable List."));
      }
      fillRange(start, end, fillValue) {
        if (fillValue === void 0) fillValue = null;
        dart.as(fillValue, E);
        dart.throw(new core.UnsupportedError("Cannot modify an immutable List."));
      }
    }
    ImmutableListMixin[dart.implements] = () => [core.List$(E)];
    dart.setSignature(ImmutableListMixin, {
      methods: () => ({
        add: [dart.void, [E]],
        addAll: [dart.void, [core.Iterable$(E)]],
        sort: [dart.void, [], [dart.functionType(core.int, [E, E])]],
        shuffle: [dart.void, [], [math.Random]],
        insert: [dart.void, [core.int, E]],
        insertAll: [dart.void, [core.int, core.Iterable$(E)]],
        setAll: [dart.void, [core.int, core.Iterable$(E)]],
        removeAt: [E, [core.int]],
        removeLast: [E, []],
        remove: [core.bool, [core.Object]],
        removeWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        retainWhere: [dart.void, [dart.functionType(core.bool, [E])]],
        setRange: [dart.void, [core.int, core.int, core.Iterable$(E)], [core.int]],
        removeRange: [dart.void, [core.int, core.int]],
        replaceRange: [dart.void, [core.int, core.int, core.Iterable$(E)]],
        fillRange: [dart.void, [core.int, core.int], [E]]
      })
    });
    dart.defineExtensionMembers(ImmutableListMixin, [
      'add',
      'addAll',
      'sort',
      'shuffle',
      'insert',
      'insertAll',
      'setAll',
      'removeAt',
      'removeLast',
      'remove',
      'removeWhere',
      'retainWhere',
      'setRange',
      'removeRange',
      'replaceRange',
      'fillRange',
      'iterator'
    ]);
    return ImmutableListMixin;
  });
  let ImmutableListMixin = ImmutableListMixin$();
  const _namedItem_1 = Symbol('_namedItem_1');
  class HtmlCollection extends dart.mixin(DartHtmlDomObject, collection.ListMixin$(Node), ImmutableListMixin$(Node)) {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateHtmlCollection() {
      return new HtmlCollection.internal_();
    }
    internal_() {
      super.DartHtmlDomObject();
    }
    ['=='](other) {
      return dart.equals(unwrap_jso(other), unwrap_jso(this)) || dart.notNull(core.identical(this, other));
    }
    get hashCode() {
      return dart.hashCode(unwrap_jso(this));
    }
    get length() {
      return dart.as(wrap_jso(this.raw.length), core.int);
    }
    get(index) {
      if (index >>> 0 !== index || index >= this.length) dart.throw(core.RangeError.index(index, this));
      return dart.as(wrap_jso(this.raw[index]), Node);
    }
    set(index, value) {
      dart.throw(new core.UnsupportedError("Cannot assign element of immutable List."));
      return value;
    }
    set length(value) {
      dart.throw(new core.UnsupportedError("Cannot resize immutable List."));
    }
    get first() {
      if (dart.notNull(this.length) > 0) {
        return dart.as(wrap_jso(this.raw[0]), Node);
      }
      dart.throw(new core.StateError("No elements"));
    }
    get last() {
      let len = this.length;
      if (dart.notNull(len) > 0) {
        return dart.as(wrap_jso(this.raw[dart.notNull(len) - 1]), Node);
      }
      dart.throw(new core.StateError("No elements"));
    }
    get single() {
      let len = this.length;
      if (len == 1) {
        return dart.as(wrap_jso(this.raw[0]), Node);
      }
      if (len == 0) dart.throw(new core.StateError("No elements"));
      dart.throw(new core.StateError("More than one element"));
    }
    elementAt(index) {
      return this.get(index);
    }
    item(index) {
      return this[_item_1](index);
    }
    [_item_1](index) {
      return dart.as(wrap_jso(this.raw.item(unwrap_jso(index))), Element);
    }
    namedItem(name) {
      return this[_namedItem_1](name);
    }
    [_namedItem_1](name) {
      return dart.as(wrap_jso(this.raw.namedItem(unwrap_jso(name))), Element);
    }
  }
  HtmlCollection[dart.implements] = () => [_js_helper.JavaScriptIndexingBehavior, core.List$(Node)];
  dart.defineNamedConstructor(HtmlCollection, 'internal_');
  dart.setSignature(HtmlCollection, {
    constructors: () => ({
      _: [HtmlCollection, []],
      internal_: [HtmlCollection, []]
    }),
    methods: () => ({
      get: [Node, [core.int]],
      set: [dart.void, [core.int, Node]],
      elementAt: [Node, [core.int]],
      item: [Element, [core.int]],
      [_item_1]: [Element, [dart.dynamic]],
      namedItem: [Element, [core.String]],
      [_namedItem_1]: [Element, [dart.dynamic]]
    }),
    statics: () => ({internalCreateHtmlCollection: [HtmlCollection, []]}),
    names: ['internalCreateHtmlCollection']
  });
  dart.defineExtensionMembers(HtmlCollection, [
    'get',
    'set',
    'elementAt',
    'length',
    'length',
    'first',
    'last',
    'single'
  ]);
  HtmlCollection[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('HTMLCollection')), dart.const(new _js_helper.Native("HTMLCollection"))];
  class HtmlDocument extends Document {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateHtmlDocument() {
      return new HtmlDocument.internal_();
    }
    internal_() {
      super.internal_();
    }
    get body() {
      return dart.as(this[_body], BodyElement);
    }
    set body(value) {
      this[_body] = value;
    }
    caretRangeFromPoint(x, y) {
      return this[_caretRangeFromPoint](x, y);
    }
    elementFromPoint(x, y) {
      return this[_elementFromPoint](x, y);
    }
    static get supportsCssCanvasContext() {
      return !!document.getCSSCanvasContext;
    }
    get head() {
      return this[_head];
    }
    get lastModified() {
      return this[_lastModified];
    }
    get preferredStylesheetSet() {
      return this[_preferredStylesheetSet];
    }
    get referrer() {
      return this[_referrer];
    }
    get selectedStylesheetSet() {
      return this[_selectedStylesheetSet];
    }
    set selectedStylesheetSet(value) {
      this[_selectedStylesheetSet] = value;
    }
    get title() {
      return this[_title];
    }
    set title(value) {
      this[_title] = value;
    }
    exitFullscreen() {
      this[_webkitExitFullscreen]();
    }
    get fullscreenElement() {
      return this[_webkitFullscreenElement];
    }
    get fullscreenEnabled() {
      return this[_webkitFullscreenEnabled];
    }
    get hidden() {
      return this[_webkitHidden];
    }
    get visibilityState() {
      return this[_webkitVisibilityState];
    }
    registerElement(tag, customElementClass, opts) {
      let extendsTag = opts && 'extendsTag' in opts ? opts.extendsTag : null;
      dart.dcall(/* Unimplemented unknown name */_registerCustomElement, window, this, tag, customElementClass, extendsTag);
    }
    register(tag, customElementClass, opts) {
      let extendsTag = opts && 'extendsTag' in opts ? opts.extendsTag : null;
      return this.registerElement(tag, customElementClass, {extendsTag: extendsTag});
    }
    static _determineVisibilityChangeEventType(e) {
      return 'webkitvisibilitychange';
    }
    get onVisibilityChange() {
      return HtmlDocument.visibilityChangeEvent.forTarget(this);
    }
    createElementUpgrader(type, opts) {
      let extendsTag = opts && 'extendsTag' in opts ? opts.extendsTag : null;
      dart.throw('ElementUpgrader not yet supported on DDC');
    }
  }
  dart.defineNamedConstructor(HtmlDocument, 'internal_');
  dart.setSignature(HtmlDocument, {
    constructors: () => ({
      _: [HtmlDocument, []],
      internal_: [HtmlDocument, []]
    }),
    methods: () => ({
      caretRangeFromPoint: [Range, [core.int, core.int]],
      elementFromPoint: [Element, [core.int, core.int]],
      registerElement: [dart.void, [core.String, core.Type], {extendsTag: core.String}],
      register: [dart.void, [core.String, core.Type], {extendsTag: core.String}],
      createElementUpgrader: [ElementUpgrader, [core.Type], {extendsTag: core.String}]
    }),
    statics: () => ({
      internalCreateHtmlDocument: [HtmlDocument, []],
      _determineVisibilityChangeEventType: [core.String, [EventTarget]]
    }),
    names: ['internalCreateHtmlDocument', '_determineVisibilityChangeEventType']
  });
  HtmlDocument[dart.metadata] = () => [dart.const(new _metadata.DomName('HTMLDocument')), dart.const(new _js_helper.Native("HTMLDocument"))];
  dart.defineLazyProperties(HtmlDocument, {
    get visibilityChangeEvent() {
      return dart.const(new (_CustomEventStreamProvider$(Event))(HtmlDocument._determineVisibilityChangeEventType));
    }
  });
  class HtmlHtmlElement extends HtmlElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(exports.document.createElement("html"), HtmlHtmlElement);
    }
    static internalCreateHtmlHtmlElement() {
      return new HtmlHtmlElement.internal_();
    }
    internal_() {
      super.internal_();
    }
  }
  dart.defineNamedConstructor(HtmlHtmlElement, 'internal_');
  dart.setSignature(HtmlHtmlElement, {
    constructors: () => ({
      _: [HtmlHtmlElement, []],
      new: [HtmlHtmlElement, []],
      internal_: [HtmlHtmlElement, []]
    }),
    statics: () => ({internalCreateHtmlHtmlElement: [HtmlHtmlElement, []]}),
    names: ['internalCreateHtmlHtmlElement']
  });
  HtmlHtmlElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('HTMLHtmlElement')), dart.const(new _js_helper.Native("HTMLHtmlElement"))];
  class HttpRequestEventTarget extends EventTarget {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateHttpRequestEventTarget() {
      return new HttpRequestEventTarget.internal_();
    }
    internal_() {
      super.internal_();
    }
    get onAbort() {
      return HttpRequestEventTarget.abortEvent.forTarget(this);
    }
    get onError() {
      return HttpRequestEventTarget.errorEvent.forTarget(this);
    }
    get onLoad() {
      return HttpRequestEventTarget.loadEvent.forTarget(this);
    }
    get onLoadEnd() {
      return HttpRequestEventTarget.loadEndEvent.forTarget(this);
    }
    get onLoadStart() {
      return HttpRequestEventTarget.loadStartEvent.forTarget(this);
    }
    get onProgress() {
      return HttpRequestEventTarget.progressEvent.forTarget(this);
    }
    get onTimeout() {
      return HttpRequestEventTarget.timeoutEvent.forTarget(this);
    }
  }
  dart.defineNamedConstructor(HttpRequestEventTarget, 'internal_');
  dart.setSignature(HttpRequestEventTarget, {
    constructors: () => ({
      _: [HttpRequestEventTarget, []],
      internal_: [HttpRequestEventTarget, []]
    }),
    statics: () => ({internalCreateHttpRequestEventTarget: [HttpRequestEventTarget, []]}),
    names: ['internalCreateHttpRequestEventTarget']
  });
  HttpRequestEventTarget[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('XMLHttpRequestEventTarget')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("XMLHttpRequestEventTarget"))];
  dart.defineLazyProperties(HttpRequestEventTarget, {
    get abortEvent() {
      return dart.const(new (EventStreamProvider$(ProgressEvent))('abort'));
    },
    get errorEvent() {
      return dart.const(new (EventStreamProvider$(ProgressEvent))('error'));
    },
    get loadEvent() {
      return dart.const(new (EventStreamProvider$(ProgressEvent))('load'));
    },
    get loadEndEvent() {
      return dart.const(new (EventStreamProvider$(ProgressEvent))('loadend'));
    },
    get loadStartEvent() {
      return dart.const(new (EventStreamProvider$(ProgressEvent))('loadstart'));
    },
    get progressEvent() {
      return dart.const(new (EventStreamProvider$(ProgressEvent))('progress'));
    },
    get timeoutEvent() {
      return dart.const(new (EventStreamProvider$(ProgressEvent))('timeout'));
    }
  });
  const _get_response = Symbol('_get_response');
  const _abort_1 = Symbol('_abort_1');
  const _getAllResponseHeaders_1 = Symbol('_getAllResponseHeaders_1');
  const _getResponseHeader_1 = Symbol('_getResponseHeader_1');
  const _overrideMimeType_1 = Symbol('_overrideMimeType_1');
  const _send_1 = Symbol('_send_1');
  const _send_2 = Symbol('_send_2');
  const _send_3 = Symbol('_send_3');
  const _setRequestHeader_1 = Symbol('_setRequestHeader_1');
  class HttpRequest extends HttpRequestEventTarget {
    static getString(url, opts) {
      let withCredentials = opts && 'withCredentials' in opts ? opts.withCredentials : null;
      let onProgress = opts && 'onProgress' in opts ? opts.onProgress : null;
      return HttpRequest.request(url, {withCredentials: withCredentials, onProgress: onProgress}).then(dart.fn(xhr => xhr.responseText, core.String, [HttpRequest]));
    }
    static postFormData(url, data, opts) {
      let withCredentials = opts && 'withCredentials' in opts ? opts.withCredentials : null;
      let responseType = opts && 'responseType' in opts ? opts.responseType : null;
      let requestHeaders = opts && 'requestHeaders' in opts ? opts.requestHeaders : null;
      let onProgress = opts && 'onProgress' in opts ? opts.onProgress : null;
      let parts = [];
      data.forEach(dart.fn((key, value) => {
        parts[dartx.add](`${core.Uri.encodeQueryComponent(key)}=` + `${core.Uri.encodeQueryComponent(value)}`);
      }, dart.void, [core.String, core.String]));
      let formData = parts[dartx.join]('&');
      if (requestHeaders == null) {
        requestHeaders = dart.map({}, core.String, core.String);
      }
      requestHeaders.putIfAbsent('Content-Type', dart.fn(() => 'application/x-www-form-urlencoded; charset=UTF-8', core.String, []));
      return HttpRequest.request(url, {method: 'POST', withCredentials: withCredentials, responseType: responseType, requestHeaders: requestHeaders, sendData: formData, onProgress: onProgress});
    }
    static request(url, opts) {
      let method = opts && 'method' in opts ? opts.method : null;
      let withCredentials = opts && 'withCredentials' in opts ? opts.withCredentials : null;
      let responseType = opts && 'responseType' in opts ? opts.responseType : null;
      let mimeType = opts && 'mimeType' in opts ? opts.mimeType : null;
      let requestHeaders = opts && 'requestHeaders' in opts ? opts.requestHeaders : null;
      let sendData = opts && 'sendData' in opts ? opts.sendData : null;
      let onProgress = opts && 'onProgress' in opts ? opts.onProgress : null;
      let completer = async.Completer$(HttpRequest).new();
      let xhr = HttpRequest.new();
      if (method == null) {
        method = 'GET';
      }
      xhr.open(method, url, {async: true});
      if (withCredentials != null) {
        xhr.withCredentials = withCredentials;
      }
      if (responseType != null) {
        xhr.responseType = responseType;
      }
      if (mimeType != null) {
        xhr.overrideMimeType(mimeType);
      }
      if (requestHeaders != null) {
        requestHeaders.forEach(dart.fn((header, value) => {
          xhr.setRequestHeader(header, value);
        }, dart.void, [core.String, core.String]));
      }
      if (onProgress != null) {
        xhr.onProgress.listen(onProgress);
      }
      xhr.onLoad.listen(dart.fn(e => {
        let accepted = dart.notNull(xhr.status) >= 200 && dart.notNull(xhr.status) < 300;
        let fileUri = xhr.status == 0;
        let notModified = xhr.status == 304;
        let unknownRedirect = dart.notNull(xhr.status) > 307 && dart.notNull(xhr.status) < 400;
        if (accepted || fileUri || notModified || unknownRedirect) {
          completer.complete(xhr);
        } else {
          completer.completeError(e);
        }
      }, dart.void, [ProgressEvent]));
      xhr.onError.listen(dart.bind(completer, 'completeError'));
      if (sendData != null) {
        xhr.send(sendData);
      } else {
        xhr.send();
      }
      return completer.future;
    }
    static get supportsProgressEvent() {
      return true;
    }
    static get supportsCrossOrigin() {
      return true;
    }
    static get supportsLoadEndEvent() {
      return true;
    }
    static get supportsOverrideMimeType() {
      return true;
    }
    static requestCrossOrigin(url, opts) {
      let method = opts && 'method' in opts ? opts.method : null;
      let sendData = opts && 'sendData' in opts ? opts.sendData : null;
      if (dart.notNull(HttpRequest.supportsCrossOrigin)) {
        return dart.as(HttpRequest.request(url, {method: method, sendData: sendData}).then(dart.fn(xhr => {
          return xhr.responseText;
        }, dart.dynamic, [HttpRequest])), async.Future$(core.String));
      }
    }
    get responseHeaders() {
      let headers = dart.map({}, core.String, core.String);
      let headersString = this.getAllResponseHeaders();
      if (headersString == null) {
        return headers;
      }
      let headersList = headersString[dartx.split]('\r\n');
      for (let header of headersList) {
        if (dart.notNull(header[dartx.isEmpty])) {
          continue;
        }
        let splitIdx = header[dartx.indexOf](': ');
        if (splitIdx == -1) {
          continue;
        }
        let key = header[dartx.substring](0, splitIdx)[dartx.toLowerCase]();
        let value = header[dartx.substring](dart.notNull(splitIdx) + 2);
        if (dart.notNull(headers.containsKey(key))) {
          headers.set(key, `${headers.get(key)}, ${value}`);
        } else {
          headers.set(key, value);
        }
      }
      return headers;
    }
    open(method, url, opts) {
      let async = opts && 'async' in opts ? opts.async : null;
      let user = opts && 'user' in opts ? opts.user : null;
      let password = opts && 'password' in opts ? opts.password : null;
      if (async == null && user == null && password == null) {
        this.raw.open(method, url);
      } else {
        this.raw.open(method, url, async, user, password);
      }
    }
    get responseType() {
      return this.raw.responseType;
    }
    set responseType(value) {
      this.raw.responseType = value;
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return HttpRequest._create_1();
    }
    static _create_1() {
      return dart.as(wrap_jso(new XMLHttpRequest()), HttpRequest);
    }
    static internalCreateHttpRequest() {
      return new HttpRequest.internal_();
    }
    internal_() {
      super.internal_();
    }
    get readyState() {
      return dart.as(wrap_jso(this.raw.readyState), core.int);
    }
    get response() {
      return _convertNativeToDart_XHR_Response(this[_get_response]);
    }
    get [_get_response]() {
      return wrap_jso(this.raw.response);
    }
    get responseText() {
      return dart.as(wrap_jso(this.raw.responseText), core.String);
    }
    get responseUrl() {
      return dart.as(wrap_jso(this.raw.responseURL), core.String);
    }
    get responseXml() {
      return dart.as(wrap_jso(this.raw.responseXML), Document);
    }
    get status() {
      return dart.as(wrap_jso(this.raw.status), core.int);
    }
    get statusText() {
      return dart.as(wrap_jso(this.raw.statusText), core.String);
    }
    get timeout() {
      return dart.as(wrap_jso(this.raw.timeout), core.int);
    }
    set timeout(val) {
      return this.raw.timeout = unwrap_jso(val);
    }
    get upload() {
      return dart.as(wrap_jso(this.raw.upload), HttpRequestEventTarget);
    }
    get withCredentials() {
      return dart.as(wrap_jso(this.raw.withCredentials), core.bool);
    }
    set withCredentials(val) {
      return this.raw.withCredentials = unwrap_jso(val);
    }
    abort() {
      this[_abort_1]();
      return;
    }
    [_abort_1]() {
      return wrap_jso(this.raw.abort());
    }
    getAllResponseHeaders() {
      return this[_getAllResponseHeaders_1]();
    }
    [_getAllResponseHeaders_1]() {
      return dart.as(wrap_jso(this.raw.getAllResponseHeaders()), core.String);
    }
    getResponseHeader(header) {
      return this[_getResponseHeader_1](header);
    }
    [_getResponseHeader_1](header) {
      return dart.as(wrap_jso(this.raw.getResponseHeader(unwrap_jso(header))), core.String);
    }
    overrideMimeType(override) {
      this[_overrideMimeType_1](override);
      return;
    }
    [_overrideMimeType_1](override) {
      return wrap_jso(this.raw.overrideMimeType(unwrap_jso(override)));
    }
    send(data) {
      if (data === void 0) data = null;
      if (data == null) {
        this[_send_1]();
        return;
      }
      if (dart.is(data, Document) || data == null) {
        this[_send_2](dart.as(data, Document));
        return;
      }
      if (typeof data == 'string' || data == null) {
        this[_send_3](dart.as(data, core.String));
        return;
      }
      dart.throw(new core.ArgumentError("Incorrect number or type of arguments"));
    }
    [_send_1]() {
      return wrap_jso(this.raw.send());
    }
    [_send_2](data) {
      return wrap_jso(this.raw.send(unwrap_jso(data)));
    }
    [_send_3](data) {
      return wrap_jso(this.raw.send(unwrap_jso(data)));
    }
    setRequestHeader(header, value) {
      this[_setRequestHeader_1](header, value);
      return;
    }
    [_setRequestHeader_1](header, value) {
      return wrap_jso(this.raw.setRequestHeader(unwrap_jso(header), unwrap_jso(value)));
    }
    get onReadyStateChange() {
      return HttpRequest.readyStateChangeEvent.forTarget(this);
    }
  }
  dart.defineNamedConstructor(HttpRequest, 'internal_');
  dart.setSignature(HttpRequest, {
    constructors: () => ({
      _: [HttpRequest, []],
      new: [HttpRequest, []],
      internal_: [HttpRequest, []]
    }),
    methods: () => ({
      open: [dart.void, [core.String, core.String], {async: core.bool, user: core.String, password: core.String}],
      abort: [dart.void, []],
      [_abort_1]: [dart.void, []],
      getAllResponseHeaders: [core.String, []],
      [_getAllResponseHeaders_1]: [core.String, []],
      getResponseHeader: [core.String, [core.String]],
      [_getResponseHeader_1]: [core.String, [dart.dynamic]],
      overrideMimeType: [dart.void, [core.String]],
      [_overrideMimeType_1]: [dart.void, [dart.dynamic]],
      send: [dart.void, [], [dart.dynamic]],
      [_send_1]: [dart.void, []],
      [_send_2]: [dart.void, [Document]],
      [_send_3]: [dart.void, [core.String]],
      setRequestHeader: [dart.void, [core.String, core.String]],
      [_setRequestHeader_1]: [dart.void, [dart.dynamic, dart.dynamic]]
    }),
    statics: () => ({
      getString: [async.Future$(core.String), [core.String], {withCredentials: core.bool, onProgress: dart.functionType(dart.void, [ProgressEvent])}],
      postFormData: [async.Future$(HttpRequest), [core.String, core.Map$(core.String, core.String)], {withCredentials: core.bool, responseType: core.String, requestHeaders: core.Map$(core.String, core.String), onProgress: dart.functionType(dart.void, [ProgressEvent])}],
      request: [async.Future$(HttpRequest), [core.String], {method: core.String, withCredentials: core.bool, responseType: core.String, mimeType: core.String, requestHeaders: core.Map$(core.String, core.String), sendData: dart.dynamic, onProgress: dart.functionType(dart.void, [ProgressEvent])}],
      requestCrossOrigin: [async.Future$(core.String), [core.String], {method: core.String, sendData: core.String}],
      _create_1: [HttpRequest, []],
      internalCreateHttpRequest: [HttpRequest, []]
    }),
    names: ['getString', 'postFormData', 'request', 'requestCrossOrigin', '_create_1', 'internalCreateHttpRequest']
  });
  HttpRequest[dart.metadata] = () => [dart.const(new _metadata.DomName('XMLHttpRequest')), dart.const(new _js_helper.Native("XMLHttpRequest"))];
  HttpRequest.DONE = 4;
  HttpRequest.HEADERS_RECEIVED = 2;
  HttpRequest.LOADING = 3;
  HttpRequest.OPENED = 1;
  HttpRequest.UNSENT = 0;
  dart.defineLazyProperties(HttpRequest, {
    get readyStateChangeEvent() {
      return dart.const(new (EventStreamProvider$(ProgressEvent))('readystatechange'));
    }
  });
  const _get_valueAsDate = Symbol('_get_valueAsDate');
  const _set_valueAsDate = Symbol('_set_valueAsDate');
  const _checkValidity_1 = Symbol('_checkValidity_1');
  const _select_1 = Symbol('_select_1');
  const _setCustomValidity_1 = Symbol('_setCustomValidity_1');
  const _setRangeText_1 = Symbol('_setRangeText_1');
  const _setRangeText_2 = Symbol('_setRangeText_2');
  const _setRangeText_3 = Symbol('_setRangeText_3');
  const _setSelectionRange_1 = Symbol('_setSelectionRange_1');
  const _setSelectionRange_2 = Symbol('_setSelectionRange_2');
  const _stepDown_1 = Symbol('_stepDown_1');
  const _stepDown_2 = Symbol('_stepDown_2');
  const _stepUp_1 = Symbol('_stepUp_1');
  const _stepUp_2 = Symbol('_stepUp_2');
  class InputElement extends HtmlElement {
    static new(opts) {
      let type = opts && 'type' in opts ? opts.type : null;
      let e = dart.as(exports.document.createElement("input"), InputElement);
      if (type != null) {
        try {
          e.type = type;
        } catch (_) {
        }

      }
      return e;
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateInputElement() {
      return new InputElement.internal_();
    }
    internal_() {
      super.internal_();
    }
    get accept() {
      return dart.as(wrap_jso(this.raw.accept), core.String);
    }
    set accept(val) {
      return this.raw.accept = unwrap_jso(val);
    }
    get alt() {
      return dart.as(wrap_jso(this.raw.alt), core.String);
    }
    set alt(val) {
      return this.raw.alt = unwrap_jso(val);
    }
    get autocomplete() {
      return dart.as(wrap_jso(this.raw.autocomplete), core.String);
    }
    set autocomplete(val) {
      return this.raw.autocomplete = unwrap_jso(val);
    }
    get autofocus() {
      return dart.as(wrap_jso(this.raw.autofocus), core.bool);
    }
    set autofocus(val) {
      return this.raw.autofocus = unwrap_jso(val);
    }
    get capture() {
      return dart.as(wrap_jso(this.raw.capture), core.bool);
    }
    set capture(val) {
      return this.raw.capture = unwrap_jso(val);
    }
    get checked() {
      return dart.as(wrap_jso(this.raw.checked), core.bool);
    }
    set checked(val) {
      return this.raw.checked = unwrap_jso(val);
    }
    get defaultChecked() {
      return dart.as(wrap_jso(this.raw.defaultChecked), core.bool);
    }
    set defaultChecked(val) {
      return this.raw.defaultChecked = unwrap_jso(val);
    }
    get defaultValue() {
      return dart.as(wrap_jso(this.raw.defaultValue), core.String);
    }
    set defaultValue(val) {
      return this.raw.defaultValue = unwrap_jso(val);
    }
    get dirName() {
      return dart.as(wrap_jso(this.raw.dirName), core.String);
    }
    set dirName(val) {
      return this.raw.dirName = unwrap_jso(val);
    }
    get disabled() {
      return dart.as(wrap_jso(this.raw.disabled), core.bool);
    }
    set disabled(val) {
      return this.raw.disabled = unwrap_jso(val);
    }
    get form() {
      return dart.as(wrap_jso(this.raw.form), HtmlElement);
    }
    get formAction() {
      return dart.as(wrap_jso(this.raw.formAction), core.String);
    }
    set formAction(val) {
      return this.raw.formAction = unwrap_jso(val);
    }
    get formEnctype() {
      return dart.as(wrap_jso(this.raw.formEnctype), core.String);
    }
    set formEnctype(val) {
      return this.raw.formEnctype = unwrap_jso(val);
    }
    get formMethod() {
      return dart.as(wrap_jso(this.raw.formMethod), core.String);
    }
    set formMethod(val) {
      return this.raw.formMethod = unwrap_jso(val);
    }
    get formNoValidate() {
      return dart.as(wrap_jso(this.raw.formNoValidate), core.bool);
    }
    set formNoValidate(val) {
      return this.raw.formNoValidate = unwrap_jso(val);
    }
    get formTarget() {
      return dart.as(wrap_jso(this.raw.formTarget), core.String);
    }
    set formTarget(val) {
      return this.raw.formTarget = unwrap_jso(val);
    }
    get height() {
      return dart.as(wrap_jso(this.raw.height), core.int);
    }
    set height(val) {
      return this.raw.height = unwrap_jso(val);
    }
    get incremental() {
      return dart.as(wrap_jso(this.raw.incremental), core.bool);
    }
    set incremental(val) {
      return this.raw.incremental = unwrap_jso(val);
    }
    get indeterminate() {
      return dart.as(wrap_jso(this.raw.indeterminate), core.bool);
    }
    set indeterminate(val) {
      return this.raw.indeterminate = unwrap_jso(val);
    }
    get inputMode() {
      return dart.as(wrap_jso(this.raw.inputMode), core.String);
    }
    set inputMode(val) {
      return this.raw.inputMode = unwrap_jso(val);
    }
    get labels() {
      return dart.as(wrap_jso(this.raw.labels), core.List$(Node));
    }
    get list() {
      return dart.as(wrap_jso(this.raw.list), HtmlElement);
    }
    get max() {
      return dart.as(wrap_jso(this.raw.max), core.String);
    }
    set max(val) {
      return this.raw.max = unwrap_jso(val);
    }
    get maxLength() {
      return dart.as(wrap_jso(this.raw.maxLength), core.int);
    }
    set maxLength(val) {
      return this.raw.maxLength = unwrap_jso(val);
    }
    get min() {
      return dart.as(wrap_jso(this.raw.min), core.String);
    }
    set min(val) {
      return this.raw.min = unwrap_jso(val);
    }
    get multiple() {
      return dart.as(wrap_jso(this.raw.multiple), core.bool);
    }
    set multiple(val) {
      return this.raw.multiple = unwrap_jso(val);
    }
    get name() {
      return dart.as(wrap_jso(this.raw.name), core.String);
    }
    set name(val) {
      return this.raw.name = unwrap_jso(val);
    }
    get pattern() {
      return dart.as(wrap_jso(this.raw.pattern), core.String);
    }
    set pattern(val) {
      return this.raw.pattern = unwrap_jso(val);
    }
    get placeholder() {
      return dart.as(wrap_jso(this.raw.placeholder), core.String);
    }
    set placeholder(val) {
      return this.raw.placeholder = unwrap_jso(val);
    }
    get readOnly() {
      return dart.as(wrap_jso(this.raw.readOnly), core.bool);
    }
    set readOnly(val) {
      return this.raw.readOnly = unwrap_jso(val);
    }
    get required() {
      return dart.as(wrap_jso(this.raw.required), core.bool);
    }
    set required(val) {
      return this.raw.required = unwrap_jso(val);
    }
    get selectionDirection() {
      return dart.as(wrap_jso(this.raw.selectionDirection), core.String);
    }
    set selectionDirection(val) {
      return this.raw.selectionDirection = unwrap_jso(val);
    }
    get selectionEnd() {
      return dart.as(wrap_jso(this.raw.selectionEnd), core.int);
    }
    set selectionEnd(val) {
      return this.raw.selectionEnd = unwrap_jso(val);
    }
    get selectionStart() {
      return dart.as(wrap_jso(this.raw.selectionStart), core.int);
    }
    set selectionStart(val) {
      return this.raw.selectionStart = unwrap_jso(val);
    }
    get size() {
      return dart.as(wrap_jso(this.raw.size), core.int);
    }
    set size(val) {
      return this.raw.size = unwrap_jso(val);
    }
    get src() {
      return dart.as(wrap_jso(this.raw.src), core.String);
    }
    set src(val) {
      return this.raw.src = unwrap_jso(val);
    }
    get step() {
      return dart.as(wrap_jso(this.raw.step), core.String);
    }
    set step(val) {
      return this.raw.step = unwrap_jso(val);
    }
    get type() {
      return dart.as(wrap_jso(this.raw.type), core.String);
    }
    set type(val) {
      return this.raw.type = unwrap_jso(val);
    }
    get validationMessage() {
      return dart.as(wrap_jso(this.raw.validationMessage), core.String);
    }
    get value() {
      return dart.as(wrap_jso(this.raw.value), core.String);
    }
    set value(val) {
      return this.raw.value = unwrap_jso(val);
    }
    get valueAsDate() {
      return html_common.convertNativeToDart_DateTime(this[_get_valueAsDate]);
    }
    get [_get_valueAsDate]() {
      return wrap_jso(this.raw.valueAsDate);
    }
    set valueAsDate(value) {
      this[_set_valueAsDate] = html_common.convertDartToNative_DateTime(value);
    }
    set [_set_valueAsDate](value) {
      this.raw.valueAsDate = unwrap_jso(value);
    }
    get valueAsNumber() {
      return dart.as(wrap_jso(this.raw.valueAsNumber), core.num);
    }
    set valueAsNumber(val) {
      return this.raw.valueAsNumber = unwrap_jso(val);
    }
    get directory() {
      return dart.as(wrap_jso(this.raw.webkitdirectory), core.bool);
    }
    set directory(val) {
      return this.raw.webkitdirectory = unwrap_jso(val);
    }
    get width() {
      return dart.as(wrap_jso(this.raw.width), core.int);
    }
    set width(val) {
      return this.raw.width = unwrap_jso(val);
    }
    get willValidate() {
      return dart.as(wrap_jso(this.raw.willValidate), core.bool);
    }
    checkValidity() {
      return this[_checkValidity_1]();
    }
    [_checkValidity_1]() {
      return dart.as(wrap_jso(this.raw.checkValidity()), core.bool);
    }
    select() {
      this[_select_1]();
      return;
    }
    [_select_1]() {
      return wrap_jso(this.raw.select());
    }
    setCustomValidity(error) {
      this[_setCustomValidity_1](error);
      return;
    }
    [_setCustomValidity_1](error) {
      return wrap_jso(this.raw.setCustomValidity(unwrap_jso(error)));
    }
    setRangeText(replacement, opts) {
      let start = opts && 'start' in opts ? opts.start : null;
      let end = opts && 'end' in opts ? opts.end : null;
      let selectionMode = opts && 'selectionMode' in opts ? opts.selectionMode : null;
      if (start == null && end == null && selectionMode == null) {
        this[_setRangeText_1](replacement);
        return;
      }
      if (end != null && start != null && selectionMode == null) {
        this[_setRangeText_2](replacement, start, end);
        return;
      }
      if (selectionMode != null && end != null && start != null) {
        this[_setRangeText_3](replacement, start, end, selectionMode);
        return;
      }
      dart.throw(new core.ArgumentError("Incorrect number or type of arguments"));
    }
    [_setRangeText_1](replacement) {
      return wrap_jso(this.raw.setRangeText(unwrap_jso(replacement)));
    }
    [_setRangeText_2](replacement, start, end) {
      return wrap_jso(this.raw.setRangeText(unwrap_jso(replacement), unwrap_jso(start), unwrap_jso(end)));
    }
    [_setRangeText_3](replacement, start, end, selectionMode) {
      return wrap_jso(this.raw.setRangeText(unwrap_jso(replacement), unwrap_jso(start), unwrap_jso(end), unwrap_jso(selectionMode)));
    }
    setSelectionRange(start, end, direction) {
      if (direction === void 0) direction = null;
      if (direction != null) {
        this[_setSelectionRange_1](start, end, direction);
        return;
      }
      this[_setSelectionRange_2](start, end);
      return;
    }
    [_setSelectionRange_1](start, end, direction) {
      return wrap_jso(this.raw.setSelectionRange(unwrap_jso(start), unwrap_jso(end), unwrap_jso(direction)));
    }
    [_setSelectionRange_2](start, end) {
      return wrap_jso(this.raw.setSelectionRange(unwrap_jso(start), unwrap_jso(end)));
    }
    stepDown(n) {
      if (n === void 0) n = null;
      if (n != null) {
        this[_stepDown_1](n);
        return;
      }
      this[_stepDown_2]();
      return;
    }
    [_stepDown_1](n) {
      return wrap_jso(this.raw.stepDown(unwrap_jso(n)));
    }
    [_stepDown_2]() {
      return wrap_jso(this.raw.stepDown());
    }
    stepUp(n) {
      if (n === void 0) n = null;
      if (n != null) {
        this[_stepUp_1](n);
        return;
      }
      this[_stepUp_2]();
      return;
    }
    [_stepUp_1](n) {
      return wrap_jso(this.raw.stepUp(unwrap_jso(n)));
    }
    [_stepUp_2]() {
      return wrap_jso(this.raw.stepUp());
    }
  }
  InputElement[dart.implements] = () => [HiddenInputElement, SearchInputElement, TextInputElement, UrlInputElement, TelephoneInputElement, EmailInputElement, PasswordInputElement, DateInputElement, MonthInputElement, WeekInputElement, TimeInputElement, LocalDateTimeInputElement, NumberInputElement, RangeInputElement, CheckboxInputElement, RadioButtonInputElement, FileUploadInputElement, SubmitButtonInputElement, ImageButtonInputElement, ResetButtonInputElement, ButtonInputElement];
  dart.defineNamedConstructor(InputElement, 'internal_');
  dart.setSignature(InputElement, {
    constructors: () => ({
      new: [InputElement, [], {type: core.String}],
      _: [InputElement, []],
      internal_: [InputElement, []]
    }),
    methods: () => ({
      checkValidity: [core.bool, []],
      [_checkValidity_1]: [core.bool, []],
      select: [dart.void, []],
      [_select_1]: [dart.void, []],
      setCustomValidity: [dart.void, [core.String]],
      [_setCustomValidity_1]: [dart.void, [dart.dynamic]],
      setRangeText: [dart.void, [core.String], {start: core.int, end: core.int, selectionMode: core.String}],
      [_setRangeText_1]: [dart.void, [dart.dynamic]],
      [_setRangeText_2]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic]],
      [_setRangeText_3]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]],
      setSelectionRange: [dart.void, [core.int, core.int], [core.String]],
      [_setSelectionRange_1]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic]],
      [_setSelectionRange_2]: [dart.void, [dart.dynamic, dart.dynamic]],
      stepDown: [dart.void, [], [core.int]],
      [_stepDown_1]: [dart.void, [dart.dynamic]],
      [_stepDown_2]: [dart.void, []],
      stepUp: [dart.void, [], [core.int]],
      [_stepUp_1]: [dart.void, [dart.dynamic]],
      [_stepUp_2]: [dart.void, []]
    }),
    statics: () => ({internalCreateInputElement: [InputElement, []]}),
    names: ['internalCreateInputElement']
  });
  InputElement[dart.metadata] = () => [dart.const(new _metadata.DomName('HTMLInputElement')), dart.const(new _js_helper.Native("HTMLInputElement"))];
  class InputElementBase extends core.Object {
    InputElementBase() {
      this.autofocus = null;
      this.disabled = null;
      this.incremental = null;
      this.indeterminate = null;
      this.name = null;
      this.value = null;
    }
  }
  InputElementBase[dart.implements] = () => [Element];
  class HiddenInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'hidden'});
    }
  }
  HiddenInputElement[dart.implements] = () => [InputElementBase];
  dart.setSignature(HiddenInputElement, {
    constructors: () => ({new: [HiddenInputElement, []]})
  });
  class TextInputElementBase extends core.Object {
    TextInputElementBase() {
      this.autocomplete = null;
      this.maxLength = null;
      this.pattern = null;
      this.placeholder = null;
      this.readOnly = null;
      this.required = null;
      this.size = null;
      this.selectionDirection = null;
      this.selectionEnd = null;
      this.selectionStart = null;
    }
  }
  TextInputElementBase[dart.implements] = () => [InputElementBase];
  class SearchInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'search'});
    }
    static get supported() {
      return InputElement.new({type: 'search'}).type == 'search';
    }
  }
  SearchInputElement[dart.implements] = () => [TextInputElementBase];
  dart.setSignature(SearchInputElement, {
    constructors: () => ({new: [SearchInputElement, []]})
  });
  SearchInputElement[dart.metadata] = () => [dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI))];
  class TextInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'text'});
    }
  }
  TextInputElement[dart.implements] = () => [TextInputElementBase];
  dart.setSignature(TextInputElement, {
    constructors: () => ({new: [TextInputElement, []]})
  });
  class UrlInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'url'});
    }
    static get supported() {
      return InputElement.new({type: 'url'}).type == 'url';
    }
  }
  UrlInputElement[dart.implements] = () => [TextInputElementBase];
  dart.setSignature(UrlInputElement, {
    constructors: () => ({new: [UrlInputElement, []]})
  });
  UrlInputElement[dart.metadata] = () => [dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI))];
  class TelephoneInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'tel'});
    }
    static get supported() {
      return InputElement.new({type: 'tel'}).type == 'tel';
    }
  }
  TelephoneInputElement[dart.implements] = () => [TextInputElementBase];
  dart.setSignature(TelephoneInputElement, {
    constructors: () => ({new: [TelephoneInputElement, []]})
  });
  TelephoneInputElement[dart.metadata] = () => [dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI))];
  class EmailInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'email'});
    }
    static get supported() {
      return InputElement.new({type: 'email'}).type == 'email';
    }
  }
  EmailInputElement[dart.implements] = () => [TextInputElementBase];
  dart.setSignature(EmailInputElement, {
    constructors: () => ({new: [EmailInputElement, []]})
  });
  EmailInputElement[dart.metadata] = () => [dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI))];
  class PasswordInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'password'});
    }
  }
  PasswordInputElement[dart.implements] = () => [TextInputElementBase];
  dart.setSignature(PasswordInputElement, {
    constructors: () => ({new: [PasswordInputElement, []]})
  });
  class RangeInputElementBase extends core.Object {
    RangeInputElementBase() {
      this.max = null;
      this.min = null;
      this.step = null;
      this.valueAsNumber = null;
    }
  }
  RangeInputElementBase[dart.implements] = () => [InputElementBase];
  class DateInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'date'});
    }
    static get supported() {
      return InputElement.new({type: 'date'}).type == 'date';
    }
  }
  DateInputElement[dart.implements] = () => [RangeInputElementBase];
  dart.setSignature(DateInputElement, {
    constructors: () => ({new: [DateInputElement, []]})
  });
  DateInputElement[dart.metadata] = () => [dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME, '25')), dart.const(new _metadata.Experimental())];
  class MonthInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'month'});
    }
    static get supported() {
      return InputElement.new({type: 'month'}).type == 'month';
    }
  }
  MonthInputElement[dart.implements] = () => [RangeInputElementBase];
  dart.setSignature(MonthInputElement, {
    constructors: () => ({new: [MonthInputElement, []]})
  });
  MonthInputElement[dart.metadata] = () => [dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME, '25')), dart.const(new _metadata.Experimental())];
  class WeekInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'week'});
    }
    static get supported() {
      return InputElement.new({type: 'week'}).type == 'week';
    }
  }
  WeekInputElement[dart.implements] = () => [RangeInputElementBase];
  dart.setSignature(WeekInputElement, {
    constructors: () => ({new: [WeekInputElement, []]})
  });
  WeekInputElement[dart.metadata] = () => [dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME, '25')), dart.const(new _metadata.Experimental())];
  class TimeInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'time'});
    }
    static get supported() {
      return InputElement.new({type: 'time'}).type == 'time';
    }
  }
  TimeInputElement[dart.implements] = () => [RangeInputElementBase];
  dart.setSignature(TimeInputElement, {
    constructors: () => ({new: [TimeInputElement, []]})
  });
  TimeInputElement[dart.metadata] = () => [dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.Experimental())];
  class LocalDateTimeInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'datetime-local'});
    }
    static get supported() {
      return InputElement.new({type: 'datetime-local'}).type == 'datetime-local';
    }
  }
  LocalDateTimeInputElement[dart.implements] = () => [RangeInputElementBase];
  dart.setSignature(LocalDateTimeInputElement, {
    constructors: () => ({new: [LocalDateTimeInputElement, []]})
  });
  LocalDateTimeInputElement[dart.metadata] = () => [dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME, '25')), dart.const(new _metadata.Experimental())];
  class NumberInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'number'});
    }
    static get supported() {
      return InputElement.new({type: 'number'}).type == 'number';
    }
  }
  NumberInputElement[dart.implements] = () => [RangeInputElementBase];
  dart.setSignature(NumberInputElement, {
    constructors: () => ({new: [NumberInputElement, []]})
  });
  NumberInputElement[dart.metadata] = () => [dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Experimental())];
  class RangeInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'range'});
    }
    static get supported() {
      return InputElement.new({type: 'range'}).type == 'range';
    }
  }
  RangeInputElement[dart.implements] = () => [RangeInputElementBase];
  dart.setSignature(RangeInputElement, {
    constructors: () => ({new: [RangeInputElement, []]})
  });
  RangeInputElement[dart.metadata] = () => [dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.Experimental())];
  class CheckboxInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'checkbox'});
    }
  }
  CheckboxInputElement[dart.implements] = () => [InputElementBase];
  dart.setSignature(CheckboxInputElement, {
    constructors: () => ({new: [CheckboxInputElement, []]})
  });
  class RadioButtonInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'radio'});
    }
  }
  RadioButtonInputElement[dart.implements] = () => [InputElementBase];
  dart.setSignature(RadioButtonInputElement, {
    constructors: () => ({new: [RadioButtonInputElement, []]})
  });
  class FileUploadInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'file'});
    }
  }
  FileUploadInputElement[dart.implements] = () => [InputElementBase];
  dart.setSignature(FileUploadInputElement, {
    constructors: () => ({new: [FileUploadInputElement, []]})
  });
  class SubmitButtonInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'submit'});
    }
  }
  SubmitButtonInputElement[dart.implements] = () => [InputElementBase];
  dart.setSignature(SubmitButtonInputElement, {
    constructors: () => ({new: [SubmitButtonInputElement, []]})
  });
  class ImageButtonInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'image'});
    }
  }
  ImageButtonInputElement[dart.implements] = () => [InputElementBase];
  dart.setSignature(ImageButtonInputElement, {
    constructors: () => ({new: [ImageButtonInputElement, []]})
  });
  class ResetButtonInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'reset'});
    }
  }
  ResetButtonInputElement[dart.implements] = () => [InputElementBase];
  dart.setSignature(ResetButtonInputElement, {
    constructors: () => ({new: [ResetButtonInputElement, []]})
  });
  class ButtonInputElement extends core.Object {
    static new() {
      return InputElement.new({type: 'button'});
    }
  }
  ButtonInputElement[dart.implements] = () => [InputElementBase];
  dart.setSignature(ButtonInputElement, {
    constructors: () => ({new: [ButtonInputElement, []]})
  });
  const _initUIEvent = Symbol('_initUIEvent');
  const _charCode = Symbol('_charCode');
  const _keyCode = Symbol('_keyCode');
  const _layerX = Symbol('_layerX');
  const _layerY = Symbol('_layerY');
  const _pageX = Symbol('_pageX');
  const _pageY = Symbol('_pageY');
  const _get_view = Symbol('_get_view');
  const _initUIEvent_1 = Symbol('_initUIEvent_1');
  class UIEvent extends Event {
    static new(type, opts) {
      let view = opts && 'view' in opts ? opts.view : null;
      let detail = opts && 'detail' in opts ? opts.detail : 0;
      let canBubble = opts && 'canBubble' in opts ? opts.canBubble : true;
      let cancelable = opts && 'cancelable' in opts ? opts.cancelable : true;
      if (view == null) {
        view = exports.window;
      }
      let e = dart.as(exports.document[_createEvent]("UIEvent"), UIEvent);
      e[_initUIEvent](type, canBubble, cancelable, view, detail);
      return e;
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateUIEvent() {
      return new UIEvent.internal_();
    }
    internal_() {
      super.internal_();
    }
    get [_charCode]() {
      return dart.as(wrap_jso(this.raw.charCode), core.int);
    }
    get detail() {
      return dart.as(wrap_jso(this.raw.detail), core.int);
    }
    get [_keyCode]() {
      return dart.as(wrap_jso(this.raw.keyCode), core.int);
    }
    get [_layerX]() {
      return dart.as(wrap_jso(this.raw.layerX), core.int);
    }
    get [_layerY]() {
      return dart.as(wrap_jso(this.raw.layerY), core.int);
    }
    get [_pageX]() {
      return dart.as(wrap_jso(this.raw.pageX), core.int);
    }
    get [_pageY]() {
      return dart.as(wrap_jso(this.raw.pageY), core.int);
    }
    get view() {
      return _convertNativeToDart_Window(this[_get_view]);
    }
    get [_get_view]() {
      return wrap_jso(this.raw.view);
    }
    get which() {
      return dart.as(wrap_jso(this.raw.which), core.int);
    }
    [_initUIEvent](type, canBubble, cancelable, view, detail) {
      this[_initUIEvent_1](type, canBubble, cancelable, view, detail);
      return;
    }
    [_initUIEvent_1](type, canBubble, cancelable, view, detail) {
      return wrap_jso(this.raw.initUIEvent(unwrap_jso(type), unwrap_jso(canBubble), unwrap_jso(cancelable), unwrap_jso(view), unwrap_jso(detail)));
    }
    get layer() {
      return new math.Point(this[_layerX], this[_layerY]);
    }
    get page() {
      return new math.Point(this[_pageX], this[_pageY]);
    }
  }
  dart.defineNamedConstructor(UIEvent, 'internal_');
  dart.setSignature(UIEvent, {
    constructors: () => ({
      new: [UIEvent, [core.String], {view: Window, detail: core.int, canBubble: core.bool, cancelable: core.bool}],
      _: [UIEvent, []],
      internal_: [UIEvent, []]
    }),
    methods: () => ({
      [_initUIEvent]: [dart.void, [core.String, core.bool, core.bool, Window, core.int]],
      [_initUIEvent_1]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, Window, dart.dynamic]]
    }),
    statics: () => ({internalCreateUIEvent: [UIEvent, []]}),
    names: ['internalCreateUIEvent']
  });
  UIEvent[dart.metadata] = () => [dart.const(new _metadata.DomName('UIEvent')), dart.const(new _js_helper.Native("UIEvent"))];
  const _initKeyboardEvent = Symbol('_initKeyboardEvent');
  const _keyIdentifier = Symbol('_keyIdentifier');
  const _getModifierState_1 = Symbol('_getModifierState_1');
  class KeyboardEvent extends UIEvent {
    static new(type, opts) {
      let view = opts && 'view' in opts ? opts.view : null;
      let canBubble = opts && 'canBubble' in opts ? opts.canBubble : true;
      let cancelable = opts && 'cancelable' in opts ? opts.cancelable : true;
      let keyLocation = opts && 'keyLocation' in opts ? opts.keyLocation : 1;
      let ctrlKey = opts && 'ctrlKey' in opts ? opts.ctrlKey : false;
      let altKey = opts && 'altKey' in opts ? opts.altKey : false;
      let shiftKey = opts && 'shiftKey' in opts ? opts.shiftKey : false;
      let metaKey = opts && 'metaKey' in opts ? opts.metaKey : false;
      if (view == null) {
        view = exports.window;
      }
      let e = dart.as(exports.document[_createEvent]("KeyboardEvent"), KeyboardEvent);
      e[_initKeyboardEvent](type, canBubble, cancelable, view, "", keyLocation, ctrlKey, altKey, shiftKey, metaKey);
      return e;
    }
    [_initKeyboardEvent](type, canBubble, cancelable, view, keyIdentifier, keyLocation, ctrlKey, altKey, shiftKey, metaKey) {
      if (typeof this.raw.initKeyEvent == "function") {
        this.raw.initKeyEvent(type, canBubble, cancelable, unwrap_jso(view), ctrlKey, altKey, shiftKey, metaKey, 0, 0);
      } else {
        this.raw.initKeyboardEvent(type, canBubble, cancelable, unwrap_jso(view), keyIdentifier, keyLocation, ctrlKey, altKey, shiftKey, metaKey);
      }
    }
    get keyCode() {
      return this[_keyCode];
    }
    get charCode() {
      return this[_charCode];
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateKeyboardEvent() {
      return new KeyboardEvent.internal_();
    }
    internal_() {
      super.internal_();
    }
    get altKey() {
      return dart.as(wrap_jso(this.raw.altKey), core.bool);
    }
    get ctrlKey() {
      return dart.as(wrap_jso(this.raw.ctrlKey), core.bool);
    }
    get [_keyIdentifier]() {
      return dart.as(wrap_jso(this.raw.keyIdentifier), core.String);
    }
    get keyLocation() {
      return dart.as(wrap_jso(this.raw.keyLocation), core.int);
    }
    get location() {
      return dart.as(wrap_jso(this.raw.location), core.int);
    }
    get metaKey() {
      return dart.as(wrap_jso(this.raw.metaKey), core.bool);
    }
    get repeat() {
      return dart.as(wrap_jso(this.raw.repeat), core.bool);
    }
    get shiftKey() {
      return dart.as(wrap_jso(this.raw.shiftKey), core.bool);
    }
    getModifierState(keyArgument) {
      return this[_getModifierState_1](keyArgument);
    }
    [_getModifierState_1](keyArgument) {
      return dart.as(wrap_jso(this.raw.getModifierState(unwrap_jso(keyArgument))), core.bool);
    }
  }
  dart.defineNamedConstructor(KeyboardEvent, 'internal_');
  dart.setSignature(KeyboardEvent, {
    constructors: () => ({
      new: [KeyboardEvent, [core.String], {view: Window, canBubble: core.bool, cancelable: core.bool, keyLocation: core.int, ctrlKey: core.bool, altKey: core.bool, shiftKey: core.bool, metaKey: core.bool}],
      _: [KeyboardEvent, []],
      internal_: [KeyboardEvent, []]
    }),
    methods: () => ({
      [_initKeyboardEvent]: [dart.void, [core.String, core.bool, core.bool, Window, core.String, core.int, core.bool, core.bool, core.bool, core.bool]],
      getModifierState: [core.bool, [core.String]],
      [_getModifierState_1]: [core.bool, [dart.dynamic]]
    }),
    statics: () => ({internalCreateKeyboardEvent: [KeyboardEvent, []]}),
    names: ['internalCreateKeyboardEvent']
  });
  KeyboardEvent[dart.metadata] = () => [dart.const(new _metadata.DomName('KeyboardEvent')), dart.const(new _js_helper.Native("KeyboardEvent"))];
  KeyboardEvent.DOM_KEY_LOCATION_LEFT = 1;
  KeyboardEvent.DOM_KEY_LOCATION_NUMPAD = 3;
  KeyboardEvent.DOM_KEY_LOCATION_RIGHT = 2;
  KeyboardEvent.DOM_KEY_LOCATION_STANDARD = 0;
  const _assign_1 = Symbol('_assign_1');
  const _assign_2 = Symbol('_assign_2');
  const _reload_1 = Symbol('_reload_1');
  const _replace_1 = Symbol('_replace_1');
  class Location extends DartHtmlDomObject {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateLocation() {
      return new Location.internal_();
    }
    internal_() {
      super.DartHtmlDomObject();
    }
    ['=='](other) {
      return dart.equals(unwrap_jso(other), unwrap_jso(this)) || dart.notNull(core.identical(this, other));
    }
    get hashCode() {
      return dart.hashCode(unwrap_jso(this));
    }
    get hash() {
      return dart.as(wrap_jso(this.raw.hash), core.String);
    }
    set hash(val) {
      return this.raw.hash = unwrap_jso(val);
    }
    get host() {
      return dart.as(wrap_jso(this.raw.host), core.String);
    }
    set host(val) {
      return this.raw.host = unwrap_jso(val);
    }
    get hostname() {
      return dart.as(wrap_jso(this.raw.hostname), core.String);
    }
    set hostname(val) {
      return this.raw.hostname = unwrap_jso(val);
    }
    get href() {
      return dart.as(wrap_jso(this.raw.href), core.String);
    }
    set href(val) {
      return this.raw.href = unwrap_jso(val);
    }
    get pathname() {
      return dart.as(wrap_jso(this.raw.pathname), core.String);
    }
    set pathname(val) {
      return this.raw.pathname = unwrap_jso(val);
    }
    get port() {
      return dart.as(wrap_jso(this.raw.port), core.String);
    }
    set port(val) {
      return this.raw.port = unwrap_jso(val);
    }
    get protocol() {
      return dart.as(wrap_jso(this.raw.protocol), core.String);
    }
    set protocol(val) {
      return this.raw.protocol = unwrap_jso(val);
    }
    get search() {
      return dart.as(wrap_jso(this.raw.search), core.String);
    }
    set search(val) {
      return this.raw.search = unwrap_jso(val);
    }
    assign(url) {
      if (url === void 0) url = null;
      if (url != null) {
        this[_assign_1](url);
        return;
      }
      this[_assign_2]();
      return;
    }
    [_assign_1](url) {
      return wrap_jso(this.raw.assign(unwrap_jso(url)));
    }
    [_assign_2]() {
      return wrap_jso(this.raw.assign());
    }
    reload() {
      this[_reload_1]();
      return;
    }
    [_reload_1]() {
      return wrap_jso(this.raw.reload());
    }
    replace(url) {
      this[_replace_1](url);
      return;
    }
    [_replace_1](url) {
      return wrap_jso(this.raw.replace(unwrap_jso(url)));
    }
  }
  Location[dart.implements] = () => [LocationBase];
  dart.defineNamedConstructor(Location, 'internal_');
  dart.setSignature(Location, {
    constructors: () => ({
      _: [Location, []],
      internal_: [Location, []]
    }),
    methods: () => ({
      assign: [dart.void, [], [core.String]],
      [_assign_1]: [dart.void, [dart.dynamic]],
      [_assign_2]: [dart.void, []],
      reload: [dart.void, []],
      [_reload_1]: [dart.void, []],
      replace: [dart.void, [core.String]],
      [_replace_1]: [dart.void, [dart.dynamic]]
    }),
    statics: () => ({internalCreateLocation: [Location, []]}),
    names: ['internalCreateLocation']
  });
  Location[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('Location')), dart.const(new _js_helper.Native("Location"))];
  const _clientX = Symbol('_clientX');
  const _clientY = Symbol('_clientY');
  const _movementX = Symbol('_movementX');
  const _movementY = Symbol('_movementY');
  const _get_relatedTarget = Symbol('_get_relatedTarget');
  const _screenX = Symbol('_screenX');
  const _screenY = Symbol('_screenY');
  const _webkitMovementX = Symbol('_webkitMovementX');
  const _webkitMovementY = Symbol('_webkitMovementY');
  const _initMouseEvent_1 = Symbol('_initMouseEvent_1');
  const _initMouseEvent = Symbol('_initMouseEvent');
  class MouseEvent extends UIEvent {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateMouseEvent() {
      return new MouseEvent.internal_();
    }
    internal_() {
      super.internal_();
    }
    get altKey() {
      return dart.as(wrap_jso(this.raw.altKey), core.bool);
    }
    get button() {
      return dart.as(wrap_jso(this.raw.button), core.int);
    }
    get [_clientX]() {
      return dart.as(wrap_jso(this.raw.clientX), core.int);
    }
    get [_clientY]() {
      return dart.as(wrap_jso(this.raw.clientY), core.int);
    }
    get ctrlKey() {
      return dart.as(wrap_jso(this.raw.ctrlKey), core.bool);
    }
    get fromElement() {
      return dart.as(wrap_jso(this.raw.fromElement), Node);
    }
    get metaKey() {
      return dart.as(wrap_jso(this.raw.metaKey), core.bool);
    }
    get [_movementX]() {
      return dart.as(wrap_jso(this.raw.movementX), core.int);
    }
    get [_movementY]() {
      return dart.as(wrap_jso(this.raw.movementY), core.int);
    }
    get region() {
      return dart.as(wrap_jso(this.raw.region), core.String);
    }
    get relatedTarget() {
      return _convertNativeToDart_EventTarget(this[_get_relatedTarget]);
    }
    get [_get_relatedTarget]() {
      return wrap_jso(this.raw.relatedTarget);
    }
    get [_screenX]() {
      return dart.as(wrap_jso(this.raw.screenX), core.int);
    }
    get [_screenY]() {
      return dart.as(wrap_jso(this.raw.screenY), core.int);
    }
    get shiftKey() {
      return dart.as(wrap_jso(this.raw.shiftKey), core.bool);
    }
    get toElement() {
      return dart.as(wrap_jso(this.raw.toElement), Node);
    }
    get [_webkitMovementX]() {
      return dart.as(wrap_jso(this.raw.webkitMovementX), core.int);
    }
    get [_webkitMovementY]() {
      return dart.as(wrap_jso(this.raw.webkitMovementY), core.int);
    }
    [_initMouseEvent](type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget) {
      let relatedTarget_1 = _convertDartToNative_EventTarget(relatedTarget);
      this[_initMouseEvent_1](type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget_1);
      return;
    }
    [_initMouseEvent_1](type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget) {
      return wrap_jso(this.raw.initMouseEvent(unwrap_jso(type), unwrap_jso(canBubble), unwrap_jso(cancelable), unwrap_jso(view), unwrap_jso(detail), unwrap_jso(screenX), unwrap_jso(screenY), unwrap_jso(clientX), unwrap_jso(clientY), unwrap_jso(ctrlKey), unwrap_jso(altKey), unwrap_jso(shiftKey), unwrap_jso(metaKey), unwrap_jso(button), unwrap_jso(relatedTarget)));
    }
  }
  dart.defineNamedConstructor(MouseEvent, 'internal_');
  dart.setSignature(MouseEvent, {
    constructors: () => ({
      _: [MouseEvent, []],
      internal_: [MouseEvent, []]
    }),
    methods: () => ({
      [_initMouseEvent]: [dart.void, [core.String, core.bool, core.bool, Window, core.int, core.int, core.int, core.int, core.int, core.bool, core.bool, core.bool, core.bool, core.int, EventTarget]],
      [_initMouseEvent_1]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, Window, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]]
    }),
    statics: () => ({internalCreateMouseEvent: [MouseEvent, []]}),
    names: ['internalCreateMouseEvent']
  });
  MouseEvent[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('MouseEvent')), dart.const(new _js_helper.Native("MouseEvent,DragEvent,PointerEvent,MSPointerEvent"))];
  const _getBattery_1 = Symbol('_getBattery_1');
  const _getStorageUpdates_1 = Symbol('_getStorageUpdates_1');
  const _registerProtocolHandler_1 = Symbol('_registerProtocolHandler_1');
  const _sendBeacon_1 = Symbol('_sendBeacon_1');
  class Navigator extends DartHtmlDomObject {
    get language() {
      return this.raw.language || this.raw.userLanguage;
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateNavigator() {
      return new Navigator.internal_();
    }
    internal_() {
      super.DartHtmlDomObject();
    }
    ['=='](other) {
      return dart.equals(unwrap_jso(other), unwrap_jso(this)) || dart.notNull(core.identical(this, other));
    }
    get hashCode() {
      return dart.hashCode(unwrap_jso(this));
    }
    get cookieEnabled() {
      return dart.as(wrap_jso(this.raw.cookieEnabled), core.bool);
    }
    get doNotTrack() {
      return dart.as(wrap_jso(this.raw.doNotTrack), core.String);
    }
    get maxTouchPoints() {
      return dart.as(wrap_jso(this.raw.maxTouchPoints), core.int);
    }
    get productSub() {
      return dart.as(wrap_jso(this.raw.productSub), core.String);
    }
    get vendor() {
      return dart.as(wrap_jso(this.raw.vendor), core.String);
    }
    get vendorSub() {
      return dart.as(wrap_jso(this.raw.vendorSub), core.String);
    }
    getBattery() {
      return this[_getBattery_1]();
    }
    [_getBattery_1]() {
      return dart.as(wrap_jso(this.raw.getBattery()), async.Future);
    }
    getStorageUpdates() {
      this[_getStorageUpdates_1]();
      return;
    }
    [_getStorageUpdates_1]() {
      return wrap_jso(this.raw.getStorageUpdates());
    }
    registerProtocolHandler(scheme, url, title) {
      this[_registerProtocolHandler_1](scheme, url, title);
      return;
    }
    [_registerProtocolHandler_1](scheme, url, title) {
      return wrap_jso(this.raw.registerProtocolHandler(unwrap_jso(scheme), unwrap_jso(url), unwrap_jso(title)));
    }
    sendBeacon(url, data) {
      return this[_sendBeacon_1](url, data);
    }
    [_sendBeacon_1](url, data) {
      return dart.as(wrap_jso(this.raw.sendBeacon(unwrap_jso(url), unwrap_jso(data))), core.bool);
    }
    get hardwareConcurrency() {
      return dart.as(wrap_jso(this.raw.hardwareConcurrency), core.int);
    }
  }
  Navigator[dart.implements] = () => [NavigatorCpu];
  dart.defineNamedConstructor(Navigator, 'internal_');
  dart.setSignature(Navigator, {
    constructors: () => ({
      _: [Navigator, []],
      internal_: [Navigator, []]
    }),
    methods: () => ({
      getBattery: [async.Future, []],
      [_getBattery_1]: [async.Future, []],
      getStorageUpdates: [dart.void, []],
      [_getStorageUpdates_1]: [dart.void, []],
      registerProtocolHandler: [dart.void, [core.String, core.String, core.String]],
      [_registerProtocolHandler_1]: [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic]],
      sendBeacon: [core.bool, [core.String, core.String]],
      [_sendBeacon_1]: [core.bool, [dart.dynamic, dart.dynamic]]
    }),
    statics: () => ({internalCreateNavigator: [Navigator, []]}),
    names: ['internalCreateNavigator']
  });
  Navigator[dart.metadata] = () => [dart.const(new _metadata.DomName('Navigator')), dart.const(new _js_helper.Native("Navigator"))];
  class NavigatorCpu extends DartHtmlDomObject {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get hardwareConcurrency() {
      return dart.as(wrap_jso(this.raw.hardwareConcurrency), core.int);
    }
  }
  dart.setSignature(NavigatorCpu, {
    constructors: () => ({_: [NavigatorCpu, []]})
  });
  NavigatorCpu[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('NavigatorCPU')), dart.const(new _metadata.Experimental())];
  class _ChildNodeListLazy extends collection.ListBase$(Node) {
    _ChildNodeListLazy(this$) {
      this[_this] = this$;
    }
    get first() {
      let result = this[_this].firstChild;
      if (result == null) dart.throw(new core.StateError("No elements"));
      return result;
    }
    get last() {
      let result = this[_this].lastChild;
      if (result == null) dart.throw(new core.StateError("No elements"));
      return result;
    }
    get single() {
      let l = this.length;
      if (l == 0) dart.throw(new core.StateError("No elements"));
      if (dart.notNull(l) > 1) dart.throw(new core.StateError("More than one element"));
      return this[_this].firstChild;
    }
    add(value) {
      this[_this].append(value);
    }
    addAll(iterable) {
      if (dart.is(iterable, _ChildNodeListLazy)) {
        let otherList = iterable;
        if (!dart.notNull(core.identical(otherList[_this], this[_this]))) {
          for (let i = 0, len = otherList.length; i < dart.notNull(len); ++i) {
            this[_this].append(otherList[_this].firstChild);
          }
        }
        return;
      }
      for (let node of iterable) {
        this[_this].append(node);
      }
    }
    insert(index, node) {
      if (dart.notNull(index) < 0 || dart.notNull(index) > dart.notNull(this.length)) {
        dart.throw(new core.RangeError.range(index, 0, this.length));
      }
      if (index == this.length) {
        this[_this].append(node);
      } else {
        this[_this].insertBefore(node, this.get(index));
      }
    }
    insertAll(index, iterable) {
      if (index == this.length) {
        this.addAll(iterable);
      } else {
        let item = this.get(index);
        this[_this].insertAllBefore(iterable, item);
      }
    }
    setAll(index, iterable) {
      dart.throw(new core.UnsupportedError("Cannot setAll on Node list"));
    }
    removeLast() {
      let result = this.last;
      if (result != null) {
        this[_this][_removeChild](result);
      }
      return result;
    }
    removeAt(index) {
      let result = this.get(index);
      if (result != null) {
        this[_this][_removeChild](result);
      }
      return result;
    }
    remove(object) {
      if (!dart.is(object, Node)) return false;
      let node = dart.as(object, Node);
      if (!dart.equals(this[_this], node.parentNode)) return false;
      this[_this][_removeChild](node);
      return true;
    }
    [_filter](test, removeMatching) {
      let child = this[_this].firstChild;
      while (child != null) {
        let nextChild = child.nextNode;
        if (test(child) == removeMatching) {
          this[_this][_removeChild](child);
        }
        child = nextChild;
      }
    }
    removeWhere(test) {
      this[_filter](test, true);
    }
    retainWhere(test) {
      this[_filter](test, false);
    }
    clear() {
      this[_this][_clearChildren]();
    }
    set(index, value) {
      this[_this][_replaceChild](value, this.get(index));
      return value;
    }
    get iterator() {
      return this[_this].childNodes[dartx.iterator];
    }
    sort(compare) {
      if (compare === void 0) compare = null;
      dart.throw(new core.UnsupportedError("Cannot sort Node list"));
    }
    shuffle(random) {
      if (random === void 0) random = null;
      dart.throw(new core.UnsupportedError("Cannot shuffle Node list"));
    }
    setRange(start, end, iterable, skipCount) {
      if (skipCount === void 0) skipCount = 0;
      dart.throw(new core.UnsupportedError("Cannot setRange on Node list"));
    }
    fillRange(start, end, fill) {
      if (fill === void 0) fill = null;
      dart.throw(new core.UnsupportedError("Cannot fillRange on Node list"));
    }
    get length() {
      return this[_this].childNodes[dartx.length];
    }
    set length(value) {
      dart.throw(new core.UnsupportedError("Cannot set length on immutable List."));
    }
    get(index) {
      return this[_this].childNodes[dartx.get](index);
    }
    get rawList() {
      return this[_this].childNodes;
    }
  }
  _ChildNodeListLazy[dart.implements] = () => [html_common.NodeListWrapper];
  dart.setSignature(_ChildNodeListLazy, {
    constructors: () => ({_ChildNodeListLazy: [_ChildNodeListLazy, [Node]]}),
    methods: () => ({
      add: [dart.void, [Node]],
      addAll: [dart.void, [core.Iterable$(Node)]],
      insert: [dart.void, [core.int, Node]],
      insertAll: [dart.void, [core.int, core.Iterable$(Node)]],
      setAll: [dart.void, [core.int, core.Iterable$(Node)]],
      removeLast: [Node, []],
      removeAt: [Node, [core.int]],
      [_filter]: [dart.void, [dart.functionType(core.bool, [Node]), core.bool]],
      removeWhere: [dart.void, [dart.functionType(core.bool, [Node])]],
      retainWhere: [dart.void, [dart.functionType(core.bool, [Node])]],
      set: [dart.void, [core.int, Node]],
      sort: [dart.void, [], [core.Comparator$(Node)]],
      setRange: [dart.void, [core.int, core.int, core.Iterable$(Node)], [core.int]],
      fillRange: [dart.void, [core.int, core.int], [Node]],
      get: [Node, [core.int]]
    })
  });
  dart.defineExtensionMembers(_ChildNodeListLazy, [
    'add',
    'addAll',
    'insert',
    'insertAll',
    'setAll',
    'removeLast',
    'removeAt',
    'remove',
    'removeWhere',
    'retainWhere',
    'clear',
    'set',
    'sort',
    'shuffle',
    'setRange',
    'fillRange',
    'get',
    'first',
    'last',
    'single',
    'iterator',
    'length',
    'length'
  ]);
  const _item = Symbol('_item');
  class NodeList extends dart.mixin(DartHtmlDomObject, collection.ListMixin$(Node), ImmutableListMixin$(Node)) {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateNodeList() {
      return new NodeList.internal_();
    }
    internal_() {
      super.DartHtmlDomObject();
    }
    ['=='](other) {
      return dart.equals(unwrap_jso(other), unwrap_jso(this)) || dart.notNull(core.identical(this, other));
    }
    get hashCode() {
      return dart.hashCode(unwrap_jso(this));
    }
    get length() {
      return dart.as(wrap_jso(this.raw.length), core.int);
    }
    get(index) {
      if (index >>> 0 !== index || index >= this.length) dart.throw(core.RangeError.index(index, this));
      return dart.as(wrap_jso(this.raw[index]), Node);
    }
    set(index, value) {
      dart.throw(new core.UnsupportedError("Cannot assign element of immutable List."));
      return value;
    }
    set length(value) {
      dart.throw(new core.UnsupportedError("Cannot resize immutable List."));
    }
    get first() {
      if (dart.notNull(this.length) > 0) {
        return dart.as(wrap_jso(this.raw[0]), Node);
      }
      dart.throw(new core.StateError("No elements"));
    }
    get last() {
      let len = this.length;
      if (dart.notNull(len) > 0) {
        return dart.as(wrap_jso(this.raw[dart.notNull(len) - 1]), Node);
      }
      dart.throw(new core.StateError("No elements"));
    }
    get single() {
      let len = this.length;
      if (len == 1) {
        return dart.as(wrap_jso(this.raw[0]), Node);
      }
      if (len == 0) dart.throw(new core.StateError("No elements"));
      dart.throw(new core.StateError("More than one element"));
    }
    elementAt(index) {
      return this.get(index);
    }
    [_item](index) {
      return this[_item_1](index);
    }
    [_item_1](index) {
      return dart.as(wrap_jso(this.raw.item(unwrap_jso(index))), Node);
    }
  }
  NodeList[dart.implements] = () => [_js_helper.JavaScriptIndexingBehavior, core.List$(Node)];
  dart.defineNamedConstructor(NodeList, 'internal_');
  dart.setSignature(NodeList, {
    constructors: () => ({
      _: [NodeList, []],
      internal_: [NodeList, []]
    }),
    methods: () => ({
      get: [Node, [core.int]],
      set: [dart.void, [core.int, Node]],
      elementAt: [Node, [core.int]],
      [_item]: [Node, [core.int]],
      [_item_1]: [Node, [dart.dynamic]]
    }),
    statics: () => ({internalCreateNodeList: [NodeList, []]}),
    names: ['internalCreateNodeList']
  });
  dart.defineExtensionMembers(NodeList, [
    'get',
    'set',
    'elementAt',
    'length',
    'length',
    'first',
    'last',
    'single'
  ]);
  NodeList[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('NodeList')), dart.const(new _js_helper.Native("NodeList,RadioNodeList"))];
  class ParentNode extends DartHtmlDomObject {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [_childElementCount]() {
      return dart.as(wrap_jso(this.raw.childElementCount), core.int);
    }
    get [_children]() {
      return dart.as(wrap_jso(this.raw.children), core.List$(Node));
    }
    get [_firstElementChild]() {
      return dart.as(wrap_jso(this.raw.firstElementChild), Element);
    }
    get [_lastElementChild]() {
      return dart.as(wrap_jso(this.raw.lastElementChild), Element);
    }
    querySelector(selectors) {
      return dart.as(wrap_jso(this.raw.querySelector(unwrap_jso(selectors))), Element);
    }
    [_querySelectorAll](selectors) {
      return dart.as(wrap_jso(this.raw.querySelectorAll(unwrap_jso(selectors))), core.List$(Node));
    }
  }
  dart.setSignature(ParentNode, {
    constructors: () => ({_: [ParentNode, []]}),
    methods: () => ({
      querySelector: [Element, [core.String]],
      [_querySelectorAll]: [core.List$(Node), [core.String]]
    })
  });
  ParentNode[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('ParentNode')), dart.const(new _metadata.Experimental())];
  class ProgressEvent extends Event {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateProgressEvent() {
      return new ProgressEvent.internal_();
    }
    internal_() {
      super.internal_();
    }
    get lengthComputable() {
      return dart.as(wrap_jso(this.raw.lengthComputable), core.bool);
    }
    get loaded() {
      return dart.as(wrap_jso(this.raw.loaded), core.int);
    }
    get total() {
      return dart.as(wrap_jso(this.raw.total), core.int);
    }
  }
  dart.defineNamedConstructor(ProgressEvent, 'internal_');
  dart.setSignature(ProgressEvent, {
    constructors: () => ({
      _: [ProgressEvent, []],
      internal_: [ProgressEvent, []]
    }),
    statics: () => ({internalCreateProgressEvent: [ProgressEvent, []]}),
    names: ['internalCreateProgressEvent']
  });
  ProgressEvent[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('ProgressEvent')), dart.const(new _js_helper.Native("ProgressEvent"))];
  const _cloneContents_1 = Symbol('_cloneContents_1');
  const _cloneRange_1 = Symbol('_cloneRange_1');
  const _collapse_1 = Symbol('_collapse_1');
  const _collapse_2 = Symbol('_collapse_2');
  const _compareBoundaryPoints_1 = Symbol('_compareBoundaryPoints_1');
  const _comparePoint_1 = Symbol('_comparePoint_1');
  const _createContextualFragment_1 = Symbol('_createContextualFragment_1');
  const _deleteContents_1 = Symbol('_deleteContents_1');
  const _detach_1 = Symbol('_detach_1');
  const _expand_1 = Symbol('_expand_1');
  const _extractContents_1 = Symbol('_extractContents_1');
  const _insertNode_1 = Symbol('_insertNode_1');
  const _isPointInRange_1 = Symbol('_isPointInRange_1');
  const _selectNode_1 = Symbol('_selectNode_1');
  const _selectNodeContents_1 = Symbol('_selectNodeContents_1');
  const _setEnd_1 = Symbol('_setEnd_1');
  const _setEndAfter_1 = Symbol('_setEndAfter_1');
  const _setEndBefore_1 = Symbol('_setEndBefore_1');
  const _setStart_1 = Symbol('_setStart_1');
  const _setStartAfter_1 = Symbol('_setStartAfter_1');
  const _setStartBefore_1 = Symbol('_setStartBefore_1');
  const _surroundContents_1 = Symbol('_surroundContents_1');
  class Range extends DartHtmlDomObject {
    static new() {
      return exports.document.createRange();
    }
    static fromPoint(point) {
      return exports.document[_caretRangeFromPoint](dart.as(point.x, core.int), dart.as(point.y, core.int));
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateRange() {
      return new Range.internal_();
    }
    internal_() {
      super.DartHtmlDomObject();
    }
    ['=='](other) {
      return dart.equals(unwrap_jso(other), unwrap_jso(this)) || dart.notNull(core.identical(this, other));
    }
    get hashCode() {
      return dart.hashCode(unwrap_jso(this));
    }
    get collapsed() {
      return dart.as(wrap_jso(this.raw.collapsed), core.bool);
    }
    get commonAncestorContainer() {
      return dart.as(wrap_jso(this.raw.commonAncestorContainer), Node);
    }
    get endContainer() {
      return dart.as(wrap_jso(this.raw.endContainer), Node);
    }
    get endOffset() {
      return dart.as(wrap_jso(this.raw.endOffset), core.int);
    }
    get startContainer() {
      return dart.as(wrap_jso(this.raw.startContainer), Node);
    }
    get startOffset() {
      return dart.as(wrap_jso(this.raw.startOffset), core.int);
    }
    cloneContents() {
      return this[_cloneContents_1]();
    }
    [_cloneContents_1]() {
      return dart.as(wrap_jso(this.raw.cloneContents()), DocumentFragment);
    }
    cloneRange() {
      return this[_cloneRange_1]();
    }
    [_cloneRange_1]() {
      return dart.as(wrap_jso(this.raw.cloneRange()), Range);
    }
    collapse(toStart) {
      if (toStart === void 0) toStart = null;
      if (toStart != null) {
        this[_collapse_1](toStart);
        return;
      }
      this[_collapse_2]();
      return;
    }
    [_collapse_1](toStart) {
      return wrap_jso(this.raw.collapse(unwrap_jso(toStart)));
    }
    [_collapse_2]() {
      return wrap_jso(this.raw.collapse());
    }
    compareBoundaryPoints(how, sourceRange) {
      return this[_compareBoundaryPoints_1](how, sourceRange);
    }
    [_compareBoundaryPoints_1](how, sourceRange) {
      return dart.as(wrap_jso(this.raw.compareBoundaryPoints(unwrap_jso(how), unwrap_jso(sourceRange))), core.int);
    }
    comparePoint(refNode, offset) {
      return this[_comparePoint_1](refNode, offset);
    }
    [_comparePoint_1](refNode, offset) {
      return dart.as(wrap_jso(this.raw.comparePoint(unwrap_jso(refNode), unwrap_jso(offset))), core.int);
    }
    createContextualFragment(html) {
      return this[_createContextualFragment_1](html);
    }
    [_createContextualFragment_1](html) {
      return dart.as(wrap_jso(this.raw.createContextualFragment(unwrap_jso(html))), DocumentFragment);
    }
    deleteContents() {
      this[_deleteContents_1]();
      return;
    }
    [_deleteContents_1]() {
      return wrap_jso(this.raw.deleteContents());
    }
    detach() {
      this[_detach_1]();
      return;
    }
    [_detach_1]() {
      return wrap_jso(this.raw.detach());
    }
    expand(unit) {
      this[_expand_1](unit);
      return;
    }
    [_expand_1](unit) {
      return wrap_jso(this.raw.expand(unwrap_jso(unit)));
    }
    extractContents() {
      return this[_extractContents_1]();
    }
    [_extractContents_1]() {
      return dart.as(wrap_jso(this.raw.extractContents()), DocumentFragment);
    }
    getBoundingClientRect() {
      return this[_getBoundingClientRect_1]();
    }
    [_getBoundingClientRect_1]() {
      return dart.as(wrap_jso(this.raw.getBoundingClientRect()), math.Rectangle);
    }
    insertNode(newNode) {
      this[_insertNode_1](newNode);
      return;
    }
    [_insertNode_1](newNode) {
      return wrap_jso(this.raw.insertNode(unwrap_jso(newNode)));
    }
    isPointInRange(refNode, offset) {
      return this[_isPointInRange_1](refNode, offset);
    }
    [_isPointInRange_1](refNode, offset) {
      return dart.as(wrap_jso(this.raw.isPointInRange(unwrap_jso(refNode), unwrap_jso(offset))), core.bool);
    }
    selectNode(refNode) {
      this[_selectNode_1](refNode);
      return;
    }
    [_selectNode_1](refNode) {
      return wrap_jso(this.raw.selectNode(unwrap_jso(refNode)));
    }
    selectNodeContents(refNode) {
      this[_selectNodeContents_1](refNode);
      return;
    }
    [_selectNodeContents_1](refNode) {
      return wrap_jso(this.raw.selectNodeContents(unwrap_jso(refNode)));
    }
    setEnd(refNode, offset) {
      this[_setEnd_1](refNode, offset);
      return;
    }
    [_setEnd_1](refNode, offset) {
      return wrap_jso(this.raw.setEnd(unwrap_jso(refNode), unwrap_jso(offset)));
    }
    setEndAfter(refNode) {
      this[_setEndAfter_1](refNode);
      return;
    }
    [_setEndAfter_1](refNode) {
      return wrap_jso(this.raw.setEndAfter(unwrap_jso(refNode)));
    }
    setEndBefore(refNode) {
      this[_setEndBefore_1](refNode);
      return;
    }
    [_setEndBefore_1](refNode) {
      return wrap_jso(this.raw.setEndBefore(unwrap_jso(refNode)));
    }
    setStart(refNode, offset) {
      this[_setStart_1](refNode, offset);
      return;
    }
    [_setStart_1](refNode, offset) {
      return wrap_jso(this.raw.setStart(unwrap_jso(refNode), unwrap_jso(offset)));
    }
    setStartAfter(refNode) {
      this[_setStartAfter_1](refNode);
      return;
    }
    [_setStartAfter_1](refNode) {
      return wrap_jso(this.raw.setStartAfter(unwrap_jso(refNode)));
    }
    setStartBefore(refNode) {
      this[_setStartBefore_1](refNode);
      return;
    }
    [_setStartBefore_1](refNode) {
      return wrap_jso(this.raw.setStartBefore(unwrap_jso(refNode)));
    }
    surroundContents(newParent) {
      this[_surroundContents_1](newParent);
      return;
    }
    [_surroundContents_1](newParent) {
      return wrap_jso(this.raw.surroundContents(unwrap_jso(newParent)));
    }
    static get supportsCreateContextualFragment() {
      return true;
    }
  }
  dart.defineNamedConstructor(Range, 'internal_');
  dart.setSignature(Range, {
    constructors: () => ({
      new: [Range, []],
      fromPoint: [Range, [math.Point]],
      _: [Range, []],
      internal_: [Range, []]
    }),
    methods: () => ({
      cloneContents: [DocumentFragment, []],
      [_cloneContents_1]: [DocumentFragment, []],
      cloneRange: [Range, []],
      [_cloneRange_1]: [Range, []],
      collapse: [dart.void, [], [core.bool]],
      [_collapse_1]: [dart.void, [dart.dynamic]],
      [_collapse_2]: [dart.void, []],
      compareBoundaryPoints: [core.int, [core.int, Range]],
      [_compareBoundaryPoints_1]: [core.int, [dart.dynamic, Range]],
      comparePoint: [core.int, [Node, core.int]],
      [_comparePoint_1]: [core.int, [Node, dart.dynamic]],
      createContextualFragment: [DocumentFragment, [core.String]],
      [_createContextualFragment_1]: [DocumentFragment, [dart.dynamic]],
      deleteContents: [dart.void, []],
      [_deleteContents_1]: [dart.void, []],
      detach: [dart.void, []],
      [_detach_1]: [dart.void, []],
      expand: [dart.void, [core.String]],
      [_expand_1]: [dart.void, [dart.dynamic]],
      extractContents: [DocumentFragment, []],
      [_extractContents_1]: [DocumentFragment, []],
      getBoundingClientRect: [math.Rectangle, []],
      [_getBoundingClientRect_1]: [math.Rectangle, []],
      insertNode: [dart.void, [Node]],
      [_insertNode_1]: [dart.void, [Node]],
      isPointInRange: [core.bool, [Node, core.int]],
      [_isPointInRange_1]: [core.bool, [Node, dart.dynamic]],
      selectNode: [dart.void, [Node]],
      [_selectNode_1]: [dart.void, [Node]],
      selectNodeContents: [dart.void, [Node]],
      [_selectNodeContents_1]: [dart.void, [Node]],
      setEnd: [dart.void, [Node, core.int]],
      [_setEnd_1]: [dart.void, [Node, dart.dynamic]],
      setEndAfter: [dart.void, [Node]],
      [_setEndAfter_1]: [dart.void, [Node]],
      setEndBefore: [dart.void, [Node]],
      [_setEndBefore_1]: [dart.void, [Node]],
      setStart: [dart.void, [Node, core.int]],
      [_setStart_1]: [dart.void, [Node, dart.dynamic]],
      setStartAfter: [dart.void, [Node]],
      [_setStartAfter_1]: [dart.void, [Node]],
      setStartBefore: [dart.void, [Node]],
      [_setStartBefore_1]: [dart.void, [Node]],
      surroundContents: [dart.void, [Node]],
      [_surroundContents_1]: [dart.void, [Node]]
    }),
    statics: () => ({internalCreateRange: [Range, []]}),
    names: ['internalCreateRange']
  });
  Range[dart.metadata] = () => [dart.const(new _metadata.DomName('Range')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("Range"))];
  Range.END_TO_END = 2;
  Range.END_TO_START = 3;
  Range.NODE_AFTER = 1;
  Range.NODE_BEFORE = 0;
  Range.NODE_BEFORE_AND_AFTER = 2;
  Range.NODE_INSIDE = 3;
  Range.START_TO_END = 1;
  Range.START_TO_START = 0;
  const RequestAnimationFrameCallback = dart.typedef('RequestAnimationFrameCallback', () => dart.functionType(dart.void, [core.num]));
  const _availLeft = Symbol('_availLeft');
  const _availTop = Symbol('_availTop');
  const _availWidth = Symbol('_availWidth');
  const _availHeight = Symbol('_availHeight');
  class Screen extends DartHtmlDomObject {
    get available() {
      return new math.Rectangle(this[_availLeft], this[_availTop], this[_availWidth], this[_availHeight]);
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateScreen() {
      return new Screen.internal_();
    }
    internal_() {
      super.DartHtmlDomObject();
    }
    ['=='](other) {
      return dart.equals(unwrap_jso(other), unwrap_jso(this)) || dart.notNull(core.identical(this, other));
    }
    get hashCode() {
      return dart.hashCode(unwrap_jso(this));
    }
    get [_availHeight]() {
      return dart.as(wrap_jso(this.raw.availHeight), core.int);
    }
    get [_availLeft]() {
      return dart.as(wrap_jso(this.raw.availLeft), core.int);
    }
    get [_availTop]() {
      return dart.as(wrap_jso(this.raw.availTop), core.int);
    }
    get [_availWidth]() {
      return dart.as(wrap_jso(this.raw.availWidth), core.int);
    }
    get colorDepth() {
      return dart.as(wrap_jso(this.raw.colorDepth), core.int);
    }
    get height() {
      return dart.as(wrap_jso(this.raw.height), core.int);
    }
    get pixelDepth() {
      return dart.as(wrap_jso(this.raw.pixelDepth), core.int);
    }
    get width() {
      return dart.as(wrap_jso(this.raw.width), core.int);
    }
  }
  dart.defineNamedConstructor(Screen, 'internal_');
  dart.setSignature(Screen, {
    constructors: () => ({
      _: [Screen, []],
      internal_: [Screen, []]
    }),
    statics: () => ({internalCreateScreen: [Screen, []]}),
    names: ['internalCreateScreen']
  });
  Screen[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('Screen')), dart.const(new _js_helper.Native("Screen"))];
  class ShadowRoot extends DocumentFragment {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateShadowRoot() {
      return new ShadowRoot.internal_();
    }
    internal_() {
      super.internal_();
    }
    get activeElement() {
      return dart.as(wrap_jso(this.raw.activeElement), Element);
    }
    get host() {
      return dart.as(wrap_jso(this.raw.host), Element);
    }
    get innerHtml() {
      return dart.as(wrap_jso(this.raw.innerHTML), core.String);
    }
    set innerHtml(val) {
      return this.raw.innerHTML = unwrap_jso(val);
    }
    get olderShadowRoot() {
      return dart.as(wrap_jso(this.raw.olderShadowRoot), ShadowRoot);
    }
    clone(deep) {
      return this[_clone_1](deep);
    }
    [_clone_1](deep) {
      return dart.as(wrap_jso(this.raw.cloneNode(unwrap_jso(deep))), Node);
    }
    elementFromPoint(x, y) {
      return this[_elementFromPoint_1](x, y);
    }
    [_elementFromPoint_1](x, y) {
      return dart.as(wrap_jso(this.raw.elementFromPoint(unwrap_jso(x), unwrap_jso(y))), Element);
    }
    getElementsByClassName(className) {
      return this[_getElementsByClassName_1](className);
    }
    [_getElementsByClassName_1](className) {
      return dart.as(wrap_jso(this.raw.getElementsByClassName(unwrap_jso(className))), HtmlCollection);
    }
    getElementsByTagName(tagName) {
      return this[_getElementsByTagName_1](tagName);
    }
    [_getElementsByTagName_1](tagName) {
      return dart.as(wrap_jso(this.raw.getElementsByTagName(unwrap_jso(tagName))), HtmlCollection);
    }
    static _shadowRootDeprecationReport() {
      if (!dart.notNull(ShadowRoot._shadowRootDeprecationReported)) {
        exports.window.console.warn('ShadowRoot.resetStyleInheritance and ShadowRoot.applyAuthorStyles now deprecated in dart:html.\nPlease remove them from your code.\n');
        ShadowRoot._shadowRootDeprecationReported = true;
      }
    }
    get resetStyleInheritance() {
      ShadowRoot._shadowRootDeprecationReport();
      return false;
    }
    set resetStyleInheritance(value) {
      ShadowRoot._shadowRootDeprecationReport();
    }
    get applyAuthorStyles() {
      ShadowRoot._shadowRootDeprecationReport();
      return false;
    }
    set applyAuthorStyles(value) {
      ShadowRoot._shadowRootDeprecationReport();
    }
  }
  dart.defineNamedConstructor(ShadowRoot, 'internal_');
  dart.setSignature(ShadowRoot, {
    constructors: () => ({
      _: [ShadowRoot, []],
      internal_: [ShadowRoot, []]
    }),
    methods: () => ({
      elementFromPoint: [Element, [core.int, core.int]],
      [_elementFromPoint_1]: [Element, [dart.dynamic, dart.dynamic]],
      getElementsByClassName: [HtmlCollection, [core.String]],
      [_getElementsByClassName_1]: [HtmlCollection, [dart.dynamic]],
      getElementsByTagName: [HtmlCollection, [core.String]],
      [_getElementsByTagName_1]: [HtmlCollection, [dart.dynamic]]
    }),
    statics: () => ({
      internalCreateShadowRoot: [ShadowRoot, []],
      _shadowRootDeprecationReport: [dart.void, []]
    }),
    names: ['internalCreateShadowRoot', '_shadowRootDeprecationReport']
  });
  ShadowRoot[dart.metadata] = () => [dart.const(new _metadata.DomName('ShadowRoot')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME, '26')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("ShadowRoot"))];
  ShadowRoot.supported = true;
  ShadowRoot._shadowRootDeprecationReported = false;
  class StyleElement extends HtmlElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(exports.document.createElement("style"), StyleElement);
    }
    static internalCreateStyleElement() {
      return new StyleElement.internal_();
    }
    internal_() {
      super.internal_();
    }
    get disabled() {
      return dart.as(wrap_jso(this.raw.disabled), core.bool);
    }
    set disabled(val) {
      return this.raw.disabled = unwrap_jso(val);
    }
    get media() {
      return dart.as(wrap_jso(this.raw.media), core.String);
    }
    set media(val) {
      return this.raw.media = unwrap_jso(val);
    }
    get type() {
      return dart.as(wrap_jso(this.raw.type), core.String);
    }
    set type(val) {
      return this.raw.type = unwrap_jso(val);
    }
  }
  dart.defineNamedConstructor(StyleElement, 'internal_');
  dart.setSignature(StyleElement, {
    constructors: () => ({
      _: [StyleElement, []],
      new: [StyleElement, []],
      internal_: [StyleElement, []]
    }),
    statics: () => ({internalCreateStyleElement: [StyleElement, []]}),
    names: ['internalCreateStyleElement']
  });
  StyleElement[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('HTMLStyleElement')), dart.const(new _js_helper.Native("HTMLStyleElement"))];
  class TemplateElement extends HtmlElement {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new() {
      return dart.as(exports.document.createElement("template"), TemplateElement);
    }
    static internalCreateTemplateElement() {
      return new TemplateElement.internal_();
    }
    internal_() {
      super.internal_();
    }
    static get supported() {
      return Element.isTagSupported('template');
    }
    get content() {
      return dart.as(wrap_jso(this.raw.content), DocumentFragment);
    }
    setInnerHtml(html, opts) {
      let validator = opts && 'validator' in opts ? opts.validator : null;
      let treeSanitizer = opts && 'treeSanitizer' in opts ? opts.treeSanitizer : null;
      this.text = null;
      let fragment = this.createFragment(html, {validator: validator, treeSanitizer: treeSanitizer});
      this.content.append(fragment);
    }
  }
  dart.defineNamedConstructor(TemplateElement, 'internal_');
  dart.setSignature(TemplateElement, {
    constructors: () => ({
      _: [TemplateElement, []],
      new: [TemplateElement, []],
      internal_: [TemplateElement, []]
    }),
    statics: () => ({internalCreateTemplateElement: [TemplateElement, []]}),
    names: ['internalCreateTemplateElement']
  });
  TemplateElement[dart.metadata] = () => [dart.const(new _metadata.Experimental()), dart.const(new _metadata.DomName('HTMLTemplateElement')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("HTMLTemplateElement"))];
  const _splitText_1 = Symbol('_splitText_1');
  class Text extends CharacterData {
    static new(data) {
      return exports.document[_createTextNode](data);
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateText() {
      return new Text.internal_();
    }
    internal_() {
      super.internal_();
    }
    get wholeText() {
      return dart.as(wrap_jso(this.raw.wholeText), core.String);
    }
    getDestinationInsertionPoints() {
      return this[_getDestinationInsertionPoints_1]();
    }
    [_getDestinationInsertionPoints_1]() {
      return dart.as(wrap_jso(this.raw.getDestinationInsertionPoints()), NodeList);
    }
    splitText(offset) {
      return this[_splitText_1](offset);
    }
    [_splitText_1](offset) {
      return dart.as(wrap_jso(this.raw.splitText(unwrap_jso(offset))), Text);
    }
  }
  dart.defineNamedConstructor(Text, 'internal_');
  dart.setSignature(Text, {
    constructors: () => ({
      new: [Text, [core.String]],
      _: [Text, []],
      internal_: [Text, []]
    }),
    methods: () => ({
      getDestinationInsertionPoints: [NodeList, []],
      [_getDestinationInsertionPoints_1]: [NodeList, []],
      splitText: [Text, [core.int]],
      [_splitText_1]: [Text, [dart.dynamic]]
    }),
    statics: () => ({internalCreateText: [Text, []]}),
    names: ['internalCreateText']
  });
  Text[dart.metadata] = () => [dart.const(new _metadata.DomName('Text')), dart.const(new _js_helper.Native("Text"))];
  class UrlUtils extends DartHtmlDomObject {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get hash() {
      return dart.as(wrap_jso(this.raw.hash), core.String);
    }
    set hash(val) {
      return this.raw.hash = unwrap_jso(val);
    }
    get host() {
      return dart.as(wrap_jso(this.raw.host), core.String);
    }
    set host(val) {
      return this.raw.host = unwrap_jso(val);
    }
    get hostname() {
      return dart.as(wrap_jso(this.raw.hostname), core.String);
    }
    set hostname(val) {
      return this.raw.hostname = unwrap_jso(val);
    }
    get href() {
      return dart.as(wrap_jso(this.raw.href), core.String);
    }
    set href(val) {
      return this.raw.href = unwrap_jso(val);
    }
    get origin() {
      return dart.as(wrap_jso(this.raw.origin), core.String);
    }
    get password() {
      return dart.as(wrap_jso(this.raw.password), core.String);
    }
    set password(val) {
      return this.raw.password = unwrap_jso(val);
    }
    get pathname() {
      return dart.as(wrap_jso(this.raw.pathname), core.String);
    }
    set pathname(val) {
      return this.raw.pathname = unwrap_jso(val);
    }
    get port() {
      return dart.as(wrap_jso(this.raw.port), core.String);
    }
    set port(val) {
      return this.raw.port = unwrap_jso(val);
    }
    get protocol() {
      return dart.as(wrap_jso(this.raw.protocol), core.String);
    }
    set protocol(val) {
      return this.raw.protocol = unwrap_jso(val);
    }
    get search() {
      return dart.as(wrap_jso(this.raw.search), core.String);
    }
    set search(val) {
      return this.raw.search = unwrap_jso(val);
    }
    get username() {
      return dart.as(wrap_jso(this.raw.username), core.String);
    }
    set username(val) {
      return this.raw.username = unwrap_jso(val);
    }
    toString() {
      return dart.as(wrap_jso(this.raw.toString()), core.String);
    }
  }
  dart.setSignature(UrlUtils, {
    constructors: () => ({_: [UrlUtils, []]})
  });
  UrlUtils[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('URLUtils')), dart.const(new _metadata.Experimental())];
  const _open2 = Symbol('_open2');
  const _open3 = Symbol('_open3');
  const _location = Symbol('_location');
  const _ensureRequestAnimationFrame = Symbol('_ensureRequestAnimationFrame');
  const _requestAnimationFrame = Symbol('_requestAnimationFrame');
  const _cancelAnimationFrame = Symbol('_cancelAnimationFrame');
  const _get_opener = Symbol('_get_opener');
  const _pageXOffset = Symbol('_pageXOffset');
  const _pageYOffset = Symbol('_pageYOffset');
  const _get_parent = Symbol('_get_parent');
  const _get_self = Symbol('_get_self');
  const _get_top = Symbol('_get_top');
  const __getter___2 = Symbol('__getter___2');
  const _alert_1 = Symbol('_alert_1');
  const _alert_2 = Symbol('_alert_2');
  const _close_1 = Symbol('_close_1');
  const _confirm_1 = Symbol('_confirm_1');
  const _confirm_2 = Symbol('_confirm_2');
  const _find_1 = Symbol('_find_1');
  const _getComputedStyle_1 = Symbol('_getComputedStyle_1');
  const _moveBy_1 = Symbol('_moveBy_1');
  const _moveTo_1 = Symbol('_moveTo_1');
  const _moveTo = Symbol('_moveTo');
  const _print_1 = Symbol('_print_1');
  const _resizeBy_1 = Symbol('_resizeBy_1');
  const _resizeTo_1 = Symbol('_resizeTo_1');
  const _scroll_1 = Symbol('_scroll_1');
  const _scroll_2 = Symbol('_scroll_2');
  const _scroll_3 = Symbol('_scroll_3');
  const _scroll_4 = Symbol('_scroll_4');
  const _scrollBy_1 = Symbol('_scrollBy_1');
  const _scrollBy_2 = Symbol('_scrollBy_2');
  const _scrollBy_3 = Symbol('_scrollBy_3');
  const _scrollBy_4 = Symbol('_scrollBy_4');
  const _scrollTo_1 = Symbol('_scrollTo_1');
  const _scrollTo_2 = Symbol('_scrollTo_2');
  const _scrollTo_3 = Symbol('_scrollTo_3');
  const _scrollTo_4 = Symbol('_scrollTo_4');
  const _showModalDialog_1 = Symbol('_showModalDialog_1');
  const _showModalDialog_2 = Symbol('_showModalDialog_2');
  const _showModalDialog_3 = Symbol('_showModalDialog_3');
  const _stop_1 = Symbol('_stop_1');
  class Window extends EventTarget {
    get animationFrame() {
      let completer = async.Completer$(core.num).sync();
      this.requestAnimationFrame(dart.fn(time => {
        completer.complete(time);
      }, dart.void, [core.num]));
      return completer.future;
    }
    get document() {
      return dart.as(wrap_jso(this.raw.document), Document);
    }
    [_open2](url, name) {
      return dart.as(wrap_jso(this.raw.open(url, name)), WindowBase);
    }
    [_open3](url, name, options) {
      return dart.as(wrap_jso(this.raw.open(url, name, options)), WindowBase);
    }
    open(url, name, options) {
      if (options === void 0) options = null;
      if (options == null) {
        return _DOMWindowCrossFrame._createSafe(this[_open2](url, name));
      } else {
        return _DOMWindowCrossFrame._createSafe(this[_open3](url, name, options));
      }
    }
    get location() {
      return dart.as(this[_location], Location);
    }
    set location(value) {
      this[_location] = value;
    }
    get [_location]() {
      return wrap_jso(this.raw.location);
    }
    set [_location](value) {
      this.raw.location = unwrap_jso(value);
    }
    requestAnimationFrame(callback) {
      this[_ensureRequestAnimationFrame]();
      return this[_requestAnimationFrame](dart.as(_wrapZone(callback), RequestAnimationFrameCallback));
    }
    cancelAnimationFrame(id) {
      this[_ensureRequestAnimationFrame]();
      this[_cancelAnimationFrame](id);
    }
    [_requestAnimationFrame](callback) {
      return this.raw.requestAnimationFrame;
    }
    [_cancelAnimationFrame](id) {
      this.raw.cancelAnimationFrame(id);
    }
    [_ensureRequestAnimationFrame]() {
      if (!!(this.raw.requestAnimationFrame && this.raw.cancelAnimationFrame)) return;
      (function($this) {
        var vendors = ['ms', 'moz', 'webkit', 'o'];
        for (var i = 0; i < vendors.length && !$this.requestAnimationFrame; ++i) {
          $this.requestAnimationFrame = $this[vendors[i] + 'RequestAnimationFrame'];
          $this.cancelAnimationFrame = $this[vendors[i] + 'CancelAnimationFrame'] || $this[vendors[i] + 'CancelRequestAnimationFrame'];
        }
        if ($this.requestAnimationFrame && $this.cancelAnimationFrame) return;
        $this.requestAnimationFrame = function(callback) {
          return window.setTimeout(function() {
            callback(Date.now());
          }, 16);
        };
        $this.cancelAnimationFrame = function(id) {
          clearTimeout(id);
        };
      })(this.raw);
    }
    get console() {
      return Console._safeConsole;
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreateWindow() {
      return new Window.internal_();
    }
    internal_() {
      super.internal_();
    }
    get closed() {
      return dart.as(wrap_jso(this.raw.closed), core.bool);
    }
    get defaultStatus() {
      return dart.as(wrap_jso(this.raw.defaultStatus), core.String);
    }
    set defaultStatus(val) {
      return this.raw.defaultStatus = unwrap_jso(val);
    }
    get defaultstatus() {
      return dart.as(wrap_jso(this.raw.defaultstatus), core.String);
    }
    set defaultstatus(val) {
      return this.raw.defaultstatus = unwrap_jso(val);
    }
    get devicePixelRatio() {
      return dart.as(wrap_jso(this.raw.devicePixelRatio), core.double);
    }
    get history() {
      return dart.as(wrap_jso(this.raw.history), History);
    }
    get innerHeight() {
      return dart.as(wrap_jso(this.raw.innerHeight), core.int);
    }
    get innerWidth() {
      return dart.as(wrap_jso(this.raw.innerWidth), core.int);
    }
    get name() {
      return dart.as(wrap_jso(this.raw.name), core.String);
    }
    set name(val) {
      return this.raw.name = unwrap_jso(val);
    }
    get navigator() {
      return dart.as(wrap_jso(this.raw.navigator), Navigator);
    }
    get offscreenBuffering() {
      return dart.as(wrap_jso(this.raw.offscreenBuffering), core.bool);
    }
    get opener() {
      return _convertNativeToDart_Window(this[_get_opener]);
    }
    get [_get_opener]() {
      return wrap_jso(this.raw.opener);
    }
    set opener(value) {
      this.raw.opener = unwrap_jso(value);
    }
    get orientation() {
      return dart.as(wrap_jso(this.raw.orientation), core.int);
    }
    get outerHeight() {
      return dart.as(wrap_jso(this.raw.outerHeight), core.int);
    }
    get outerWidth() {
      return dart.as(wrap_jso(this.raw.outerWidth), core.int);
    }
    get [_pageXOffset]() {
      return dart.as(wrap_jso(this.raw.pageXOffset), core.double);
    }
    get [_pageYOffset]() {
      return dart.as(wrap_jso(this.raw.pageYOffset), core.double);
    }
    get parent() {
      return _convertNativeToDart_Window(this[_get_parent]);
    }
    get [_get_parent]() {
      return wrap_jso(this.raw.parent);
    }
    get screen() {
      return dart.as(wrap_jso(this.raw.screen), Screen);
    }
    get screenLeft() {
      return dart.as(wrap_jso(this.raw.screenLeft), core.int);
    }
    get screenTop() {
      return dart.as(wrap_jso(this.raw.screenTop), core.int);
    }
    get screenX() {
      return dart.as(wrap_jso(this.raw.screenX), core.int);
    }
    get screenY() {
      return dart.as(wrap_jso(this.raw.screenY), core.int);
    }
    get self() {
      return _convertNativeToDart_Window(this[_get_self]);
    }
    get [_get_self]() {
      return wrap_jso(this.raw.self);
    }
    get status() {
      return dart.as(wrap_jso(this.raw.status), core.String);
    }
    set status(val) {
      return this.raw.status = unwrap_jso(val);
    }
    get top() {
      return _convertNativeToDart_Window(this[_get_top]);
    }
    get [_get_top]() {
      return wrap_jso(this.raw.top);
    }
    get window() {
      return _convertNativeToDart_Window(this[_get_window]);
    }
    get [_get_window]() {
      return wrap_jso(this.raw.window);
    }
    [__getter__](index_OR_name) {
      if (typeof index_OR_name == 'number') {
        return _convertNativeToDart_Window(this[__getter___1](index_OR_name));
      }
      if (typeof index_OR_name == 'string') {
        return _convertNativeToDart_Window(this[__getter___2](index_OR_name));
      }
      dart.throw(new core.ArgumentError("Incorrect number or type of arguments"));
    }
    [__getter___1](index) {
      return wrap_jso(this.raw.__getter__(unwrap_jso(index)));
    }
    [__getter___2](name) {
      return wrap_jso(this.raw.__getter__(unwrap_jso(name)));
    }
    alert(message) {
      if (message === void 0) message = null;
      if (message != null) {
        this[_alert_1](message);
        return;
      }
      this[_alert_2]();
      return;
    }
    [_alert_1](message) {
      return wrap_jso(this.raw.alert(unwrap_jso(message)));
    }
    [_alert_2]() {
      return wrap_jso(this.raw.alert());
    }
    close() {
      this[_close_1]();
      return;
    }
    [_close_1]() {
      return wrap_jso(this.raw.close());
    }
    confirm(message) {
      if (message === void 0) message = null;
      if (message != null) {
        return this[_confirm_1](message);
      }
      return this[_confirm_2]();
    }
    [_confirm_1](message) {
      return dart.as(wrap_jso(this.raw.confirm(unwrap_jso(message))), core.bool);
    }
    [_confirm_2]() {
      return dart.as(wrap_jso(this.raw.confirm()), core.bool);
    }
    find(string, caseSensitive, backwards, wrap, wholeWord, searchInFrames, showDialog) {
      return this[_find_1](string, caseSensitive, backwards, wrap, wholeWord, searchInFrames, showDialog);
    }
    [_find_1](string, caseSensitive, backwards, wrap, wholeWord, searchInFrames, showDialog) {
      return dart.as(wrap_jso(this.raw.find(unwrap_jso(string), unwrap_jso(caseSensitive), unwrap_jso(backwards), unwrap_jso(wrap), unwrap_jso(wholeWord), unwrap_jso(searchInFrames), unwrap_jso(showDialog))), core.bool);
    }
    [_getComputedStyle](element, pseudoElement) {
      return this[_getComputedStyle_1](element, pseudoElement);
    }
    [_getComputedStyle_1](element, pseudoElement) {
      return dart.as(wrap_jso(this.raw.getComputedStyle(unwrap_jso(element), unwrap_jso(pseudoElement))), CssStyleDeclaration);
    }
    moveBy(x, y) {
      this[_moveBy_1](x, y);
      return;
    }
    [_moveBy_1](x, y) {
      return wrap_jso(this.raw.moveBy(unwrap_jso(x), unwrap_jso(y)));
    }
    [_moveTo](x, y) {
      this[_moveTo_1](x, y);
      return;
    }
    [_moveTo_1](x, y) {
      return wrap_jso(this.raw.moveTo(unwrap_jso(x), unwrap_jso(y)));
    }
    print() {
      this[_print_1]();
      return;
    }
    [_print_1]() {
      return wrap_jso(this.raw.print());
    }
    resizeBy(x, y) {
      this[_resizeBy_1](x, y);
      return;
    }
    [_resizeBy_1](x, y) {
      return wrap_jso(this.raw.resizeBy(unwrap_jso(x), unwrap_jso(y)));
    }
    resizeTo(width, height) {
      this[_resizeTo_1](width, height);
      return;
    }
    [_resizeTo_1](width, height) {
      return wrap_jso(this.raw.resizeTo(unwrap_jso(width), unwrap_jso(height)));
    }
    scroll(x, y, scrollOptions) {
      if (scrollOptions === void 0) scrollOptions = null;
      if (typeof y == 'number' && typeof x == 'number' && scrollOptions == null) {
        this[_scroll_1](x, y);
        return;
      }
      if (scrollOptions != null && typeof y == 'number' && typeof x == 'number') {
        let scrollOptions_1 = html_common.convertDartToNative_Dictionary(scrollOptions);
        this[_scroll_2](x, y, scrollOptions_1);
        return;
      }
      if (typeof y == 'number' && typeof x == 'number' && scrollOptions == null) {
        this[_scroll_3](x, y);
        return;
      }
      if (scrollOptions != null && typeof y == 'number' && typeof x == 'number') {
        let scrollOptions_1 = html_common.convertDartToNative_Dictionary(scrollOptions);
        this[_scroll_4](x, y, scrollOptions_1);
        return;
      }
      dart.throw(new core.ArgumentError("Incorrect number or type of arguments"));
    }
    [_scroll_1](x, y) {
      return wrap_jso(this.raw.scroll(unwrap_jso(x), unwrap_jso(y)));
    }
    [_scroll_2](x, y, scrollOptions) {
      return wrap_jso(this.raw.scroll(unwrap_jso(x), unwrap_jso(y), unwrap_jso(scrollOptions)));
    }
    [_scroll_3](x, y) {
      return wrap_jso(this.raw.scroll(unwrap_jso(x), unwrap_jso(y)));
    }
    [_scroll_4](x, y, scrollOptions) {
      return wrap_jso(this.raw.scroll(unwrap_jso(x), unwrap_jso(y), unwrap_jso(scrollOptions)));
    }
    scrollBy(x, y, scrollOptions) {
      if (scrollOptions === void 0) scrollOptions = null;
      if (typeof y == 'number' && typeof x == 'number' && scrollOptions == null) {
        this[_scrollBy_1](x, y);
        return;
      }
      if (scrollOptions != null && typeof y == 'number' && typeof x == 'number') {
        let scrollOptions_1 = html_common.convertDartToNative_Dictionary(scrollOptions);
        this[_scrollBy_2](x, y, scrollOptions_1);
        return;
      }
      if (typeof y == 'number' && typeof x == 'number' && scrollOptions == null) {
        this[_scrollBy_3](x, y);
        return;
      }
      if (scrollOptions != null && typeof y == 'number' && typeof x == 'number') {
        let scrollOptions_1 = html_common.convertDartToNative_Dictionary(scrollOptions);
        this[_scrollBy_4](x, y, scrollOptions_1);
        return;
      }
      dart.throw(new core.ArgumentError("Incorrect number or type of arguments"));
    }
    [_scrollBy_1](x, y) {
      return wrap_jso(this.raw.scrollBy(unwrap_jso(x), unwrap_jso(y)));
    }
    [_scrollBy_2](x, y, scrollOptions) {
      return wrap_jso(this.raw.scrollBy(unwrap_jso(x), unwrap_jso(y), unwrap_jso(scrollOptions)));
    }
    [_scrollBy_3](x, y) {
      return wrap_jso(this.raw.scrollBy(unwrap_jso(x), unwrap_jso(y)));
    }
    [_scrollBy_4](x, y, scrollOptions) {
      return wrap_jso(this.raw.scrollBy(unwrap_jso(x), unwrap_jso(y), unwrap_jso(scrollOptions)));
    }
    scrollTo(x, y, scrollOptions) {
      if (scrollOptions === void 0) scrollOptions = null;
      if (typeof y == 'number' && typeof x == 'number' && scrollOptions == null) {
        this[_scrollTo_1](x, y);
        return;
      }
      if (scrollOptions != null && typeof y == 'number' && typeof x == 'number') {
        let scrollOptions_1 = html_common.convertDartToNative_Dictionary(scrollOptions);
        this[_scrollTo_2](x, y, scrollOptions_1);
        return;
      }
      if (typeof y == 'number' && typeof x == 'number' && scrollOptions == null) {
        this[_scrollTo_3](x, y);
        return;
      }
      if (scrollOptions != null && typeof y == 'number' && typeof x == 'number') {
        let scrollOptions_1 = html_common.convertDartToNative_Dictionary(scrollOptions);
        this[_scrollTo_4](x, y, scrollOptions_1);
        return;
      }
      dart.throw(new core.ArgumentError("Incorrect number or type of arguments"));
    }
    [_scrollTo_1](x, y) {
      return wrap_jso(this.raw.scrollTo(unwrap_jso(x), unwrap_jso(y)));
    }
    [_scrollTo_2](x, y, scrollOptions) {
      return wrap_jso(this.raw.scrollTo(unwrap_jso(x), unwrap_jso(y), unwrap_jso(scrollOptions)));
    }
    [_scrollTo_3](x, y) {
      return wrap_jso(this.raw.scrollTo(unwrap_jso(x), unwrap_jso(y)));
    }
    [_scrollTo_4](x, y, scrollOptions) {
      return wrap_jso(this.raw.scrollTo(unwrap_jso(x), unwrap_jso(y), unwrap_jso(scrollOptions)));
    }
    showModalDialog(url, dialogArgs, featureArgs) {
      if (dialogArgs === void 0) dialogArgs = null;
      if (featureArgs === void 0) featureArgs = null;
      if (featureArgs != null) {
        return this[_showModalDialog_1](url, dialogArgs, featureArgs);
      }
      if (dialogArgs != null) {
        return this[_showModalDialog_2](url, dialogArgs);
      }
      return this[_showModalDialog_3](url);
    }
    [_showModalDialog_1](url, dialogArgs, featureArgs) {
      return wrap_jso(this.raw.showModalDialog(unwrap_jso(url), unwrap_jso(dialogArgs), unwrap_jso(featureArgs)));
    }
    [_showModalDialog_2](url, dialogArgs) {
      return wrap_jso(this.raw.showModalDialog(unwrap_jso(url), unwrap_jso(dialogArgs)));
    }
    [_showModalDialog_3](url) {
      return wrap_jso(this.raw.showModalDialog(unwrap_jso(url)));
    }
    stop() {
      this[_stop_1]();
      return;
    }
    [_stop_1]() {
      return wrap_jso(this.raw.stop());
    }
    get onContentLoaded() {
      return Window.contentLoadedEvent.forTarget(this);
    }
    get onSearch() {
      return Element.searchEvent.forTarget(this);
    }
    moveTo(p) {
      this[_moveTo](dart.as(p.x, core.num), dart.as(p.y, core.num));
    }
    get pageXOffset() {
      return this.raw.pageXOffset[dartx.round]();
    }
    get pageYOffset() {
      return this.raw.pageYOffset[dartx.round]();
    }
    get scrollX() {
      return "scrollX" in this.raw ? this.raw.scrollX[dartx.round]() : this.document.documentElement.scrollLeft;
    }
    get scrollY() {
      return "scrollY" in this.raw ? this.raw.scrollY[dartx.round]() : this.document.documentElement.scrollTop;
    }
    postMessage(message, targetOrigin, messagePorts) {
      if (messagePorts === void 0) messagePorts = null;
      if (messagePorts != null) {
        dart.throw('postMessage unsupported');
      }
      this.raw.postMessage(message, targetOrigin);
    }
  }
  Window[dart.implements] = () => [WindowBase];
  dart.defineNamedConstructor(Window, 'internal_');
  dart.setSignature(Window, {
    constructors: () => ({
      _: [Window, []],
      internal_: [Window, []]
    }),
    methods: () => ({
      [_open2]: [WindowBase, [dart.dynamic, dart.dynamic]],
      [_open3]: [WindowBase, [dart.dynamic, dart.dynamic, dart.dynamic]],
      open: [WindowBase, [core.String, core.String], [core.String]],
      requestAnimationFrame: [core.int, [RequestAnimationFrameCallback]],
      cancelAnimationFrame: [dart.void, [core.int]],
      [_requestAnimationFrame]: [core.int, [RequestAnimationFrameCallback]],
      [_cancelAnimationFrame]: [dart.void, [core.int]],
      [_ensureRequestAnimationFrame]: [dart.dynamic, []],
      [__getter__]: [WindowBase, [dart.dynamic]],
      [__getter___1]: [dart.dynamic, [core.int]],
      [__getter___2]: [dart.dynamic, [core.String]],
      alert: [dart.void, [], [core.String]],
      [_alert_1]: [dart.void, [dart.dynamic]],
      [_alert_2]: [dart.void, []],
      close: [dart.void, []],
      [_close_1]: [dart.void, []],
      confirm: [core.bool, [], [core.String]],
      [_confirm_1]: [core.bool, [dart.dynamic]],
      [_confirm_2]: [core.bool, []],
      find: [core.bool, [core.String, core.bool, core.bool, core.bool, core.bool, core.bool, core.bool]],
      [_find_1]: [core.bool, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]],
      [_getComputedStyle]: [CssStyleDeclaration, [Element, core.String]],
      [_getComputedStyle_1]: [CssStyleDeclaration, [Element, dart.dynamic]],
      moveBy: [dart.void, [core.num, core.num]],
      [_moveBy_1]: [dart.void, [dart.dynamic, dart.dynamic]],
      [_moveTo]: [dart.void, [core.num, core.num]],
      [_moveTo_1]: [dart.void, [dart.dynamic, dart.dynamic]],
      print: [dart.void, []],
      [_print_1]: [dart.void, []],
      resizeBy: [dart.void, [core.num, core.num]],
      [_resizeBy_1]: [dart.void, [dart.dynamic, dart.dynamic]],
      resizeTo: [dart.void, [core.num, core.num]],
      [_resizeTo_1]: [dart.void, [dart.dynamic, dart.dynamic]],
      scroll: [dart.void, [dart.dynamic, dart.dynamic], [core.Map]],
      [_scroll_1]: [dart.void, [core.num, core.num]],
      [_scroll_2]: [dart.void, [core.num, core.num, dart.dynamic]],
      [_scroll_3]: [dart.void, [core.int, core.int]],
      [_scroll_4]: [dart.void, [core.int, core.int, dart.dynamic]],
      scrollBy: [dart.void, [dart.dynamic, dart.dynamic], [core.Map]],
      [_scrollBy_1]: [dart.void, [core.num, core.num]],
      [_scrollBy_2]: [dart.void, [core.num, core.num, dart.dynamic]],
      [_scrollBy_3]: [dart.void, [core.int, core.int]],
      [_scrollBy_4]: [dart.void, [core.int, core.int, dart.dynamic]],
      scrollTo: [dart.void, [dart.dynamic, dart.dynamic], [core.Map]],
      [_scrollTo_1]: [dart.void, [core.num, core.num]],
      [_scrollTo_2]: [dart.void, [core.num, core.num, dart.dynamic]],
      [_scrollTo_3]: [dart.void, [core.int, core.int]],
      [_scrollTo_4]: [dart.void, [core.int, core.int, dart.dynamic]],
      showModalDialog: [core.Object, [core.String], [core.Object, core.String]],
      [_showModalDialog_1]: [core.Object, [dart.dynamic, dart.dynamic, dart.dynamic]],
      [_showModalDialog_2]: [core.Object, [dart.dynamic, dart.dynamic]],
      [_showModalDialog_3]: [core.Object, [dart.dynamic]],
      stop: [dart.void, []],
      [_stop_1]: [dart.void, []],
      moveTo: [dart.void, [math.Point]],
      postMessage: [dart.void, [dart.dynamic, core.String], [core.List]]
    }),
    statics: () => ({internalCreateWindow: [Window, []]}),
    names: ['internalCreateWindow']
  });
  Window[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('Window')), dart.const(new _js_helper.Native("Window"))];
  Window.PERSISTENT = 1;
  Window.TEMPORARY = 0;
  dart.defineLazyProperties(Window, {
    get contentLoadedEvent() {
      return dart.const(new (EventStreamProvider$(Event))('DOMContentLoaded'));
    }
  });
  class _Attr extends Node {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreate_Attr() {
      return new _Attr.internal_();
    }
    internal_() {
      super.internal_();
    }
    get name() {
      return dart.as(wrap_jso(this.raw.name), core.String);
    }
    get text() {
      return dart.as(wrap_jso(this.raw.textContent), core.String);
    }
    set text(value) {
      this.raw.textContent = unwrap_jso(value);
    }
    get value() {
      return dart.as(wrap_jso(this.raw.value), core.String);
    }
    set value(val) {
      return this.raw.value = unwrap_jso(val);
    }
  }
  dart.defineNamedConstructor(_Attr, 'internal_');
  dart.setSignature(_Attr, {
    constructors: () => ({
      _: [_Attr, []],
      internal_: [_Attr, []]
    }),
    statics: () => ({internalCreate_Attr: [_Attr, []]}),
    names: ['internalCreate_Attr']
  });
  _Attr[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('Attr')), dart.const(new _js_helper.Native("Attr"))];
  class _ClientRect extends DartHtmlDomObject {
    toString() {
      return `Rectangle (${this.left}, ${this.top}) ${this.width} x ${this.height}`;
    }
    ['=='](other) {
      if (!dart.is(other, math.Rectangle)) return false;
      return dart.equals(this.left, dart.dload(other, 'left')) && dart.equals(this.top, dart.dload(other, 'top')) && dart.equals(this.width, dart.dload(other, 'width')) && dart.equals(this.height, dart.dload(other, 'height'));
    }
    get hashCode() {
      return _JenkinsSmiHash.hash4(dart.hashCode(this.left), dart.hashCode(this.top), dart.hashCode(this.width), dart.hashCode(this.height));
    }
    intersection(other) {
      let x0 = math.max(this.left, dart.as(other.left, core.num));
      let x1 = math.min(dart.notNull(this.left) + dart.notNull(this.width), dart.as(dart.dsend(other.left, '+', other.width), core.num));
      if (dart.notNull(x0) <= dart.notNull(x1)) {
        let y0 = math.max(this.top, dart.as(other.top, core.num));
        let y1 = math.min(dart.notNull(this.top) + dart.notNull(this.height), dart.as(dart.dsend(other.top, '+', other.height), core.num));
        if (dart.notNull(y0) <= dart.notNull(y1)) {
          return new math.Rectangle(x0, y0, dart.notNull(x1) - dart.notNull(x0), dart.notNull(y1) - dart.notNull(y0));
        }
      }
      return null;
    }
    intersects(other) {
      return dart.notNull(this.left) <= dart.notNull(other.left) + dart.notNull(other.width) && dart.notNull(other.left) <= dart.notNull(this.left) + dart.notNull(this.width) && dart.notNull(this.top) <= dart.notNull(other.top) + dart.notNull(other.height) && dart.notNull(other.top) <= dart.notNull(this.top) + dart.notNull(this.height);
    }
    boundingBox(other) {
      let right = math.max(dart.notNull(this.left) + dart.notNull(this.width), dart.as(dart.dsend(other.left, '+', other.width), core.num));
      let bottom = math.max(dart.notNull(this.top) + dart.notNull(this.height), dart.as(dart.dsend(other.top, '+', other.height), core.num));
      let left = math.min(this.left, dart.as(other.left, core.num));
      let top = math.min(this.top, dart.as(other.top, core.num));
      return new math.Rectangle(left, top, dart.notNull(right) - dart.notNull(left), dart.notNull(bottom) - dart.notNull(top));
    }
    containsRectangle(another) {
      return dart.notNull(this.left) <= dart.notNull(another.left) && dart.notNull(this.left) + dart.notNull(this.width) >= dart.notNull(another.left) + dart.notNull(another.width) && dart.notNull(this.top) <= dart.notNull(another.top) && dart.notNull(this.top) + dart.notNull(this.height) >= dart.notNull(another.top) + dart.notNull(another.height);
    }
    containsPoint(another) {
      return dart.notNull(another.x) >= dart.notNull(this.left) && dart.notNull(another.x) <= dart.notNull(this.left) + dart.notNull(this.width) && dart.notNull(another.y) >= dart.notNull(this.top) && dart.notNull(another.y) <= dart.notNull(this.top) + dart.notNull(this.height);
    }
    get topLeft() {
      return new math.Point(this.left, this.top);
    }
    get topRight() {
      return new math.Point(dart.notNull(this.left) + dart.notNull(this.width), this.top);
    }
    get bottomRight() {
      return new math.Point(dart.notNull(this.left) + dart.notNull(this.width), dart.notNull(this.top) + dart.notNull(this.height));
    }
    get bottomLeft() {
      return new math.Point(this.left, dart.notNull(this.top) + dart.notNull(this.height));
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreate_ClientRect() {
      return new _ClientRect.internal_();
    }
    internal_() {
      super.DartHtmlDomObject();
    }
    get bottom() {
      return dart.as(wrap_jso(this.raw.bottom), core.double);
    }
    get height() {
      return dart.as(wrap_jso(this.raw.height), core.double);
    }
    get left() {
      return dart.as(wrap_jso(this.raw.left), core.double);
    }
    get right() {
      return dart.as(wrap_jso(this.raw.right), core.double);
    }
    get top() {
      return dart.as(wrap_jso(this.raw.top), core.double);
    }
    get width() {
      return dart.as(wrap_jso(this.raw.width), core.double);
    }
  }
  _ClientRect[dart.implements] = () => [math.Rectangle];
  dart.defineNamedConstructor(_ClientRect, 'internal_');
  dart.setSignature(_ClientRect, {
    constructors: () => ({
      _: [_ClientRect, []],
      internal_: [_ClientRect, []]
    }),
    methods: () => ({
      intersection: [math.Rectangle, [math.Rectangle]],
      intersects: [core.bool, [math.Rectangle$(core.num)]],
      boundingBox: [math.Rectangle, [math.Rectangle]],
      containsRectangle: [core.bool, [math.Rectangle$(core.num)]],
      containsPoint: [core.bool, [math.Point$(core.num)]]
    }),
    statics: () => ({internalCreate_ClientRect: [_ClientRect, []]}),
    names: ['internalCreate_ClientRect']
  });
  _ClientRect[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('ClientRect')), dart.const(new _js_helper.Native("ClientRect"))];
  class _JenkinsSmiHash extends core.Object {
    static combine(hash, value) {
      hash = 536870911 & dart.notNull(hash) + dart.notNull(value);
      hash = 536870911 & dart.notNull(hash) + ((524287 & dart.notNull(hash)) << 10);
      return dart.notNull(hash) ^ dart.notNull(hash) >> 6;
    }
    static finish(hash) {
      hash = 536870911 & dart.notNull(hash) + ((67108863 & dart.notNull(hash)) << 3);
      hash = dart.notNull(hash) ^ dart.notNull(hash) >> 11;
      return 536870911 & dart.notNull(hash) + ((16383 & dart.notNull(hash)) << 15);
    }
    static hash2(a, b) {
      return _JenkinsSmiHash.finish(_JenkinsSmiHash.combine(_JenkinsSmiHash.combine(0, dart.as(a, core.int)), dart.as(b, core.int)));
    }
    static hash4(a, b, c, d) {
      return _JenkinsSmiHash.finish(_JenkinsSmiHash.combine(_JenkinsSmiHash.combine(_JenkinsSmiHash.combine(_JenkinsSmiHash.combine(0, dart.as(a, core.int)), dart.as(b, core.int)), dart.as(c, core.int)), dart.as(d, core.int)));
    }
  }
  dart.setSignature(_JenkinsSmiHash, {
    statics: () => ({
      combine: [core.int, [core.int, core.int]],
      finish: [core.int, [core.int]],
      hash2: [core.int, [dart.dynamic, dart.dynamic]],
      hash4: [core.int, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]]
    }),
    names: ['combine', 'finish', 'hash2', 'hash4']
  });
  const _getNamedItem_1 = Symbol('_getNamedItem_1');
  const _getNamedItemNS_1 = Symbol('_getNamedItemNS_1');
  const _removeNamedItem_1 = Symbol('_removeNamedItem_1');
  const _removeNamedItemNS_1 = Symbol('_removeNamedItemNS_1');
  const _setNamedItem_1 = Symbol('_setNamedItem_1');
  const _setNamedItemNS_1 = Symbol('_setNamedItemNS_1');
  class _NamedNodeMap extends dart.mixin(DartHtmlDomObject, collection.ListMixin$(Node), ImmutableListMixin$(Node)) {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreate_NamedNodeMap() {
      return new _NamedNodeMap.internal_();
    }
    internal_() {
      super.DartHtmlDomObject();
    }
    ['=='](other) {
      return dart.equals(unwrap_jso(other), unwrap_jso(this)) || dart.notNull(core.identical(this, other));
    }
    get hashCode() {
      return dart.hashCode(unwrap_jso(this));
    }
    get length() {
      return dart.as(wrap_jso(this.raw.length), core.int);
    }
    get(index) {
      if (index >>> 0 !== index || index >= this.length) dart.throw(core.RangeError.index(index, this));
      return dart.as(wrap_jso(this.raw[index]), Node);
    }
    set(index, value) {
      dart.throw(new core.UnsupportedError("Cannot assign element of immutable List."));
      return value;
    }
    set length(value) {
      dart.throw(new core.UnsupportedError("Cannot resize immutable List."));
    }
    get first() {
      if (dart.notNull(this.length) > 0) {
        return dart.as(wrap_jso(this.raw[0]), Node);
      }
      dart.throw(new core.StateError("No elements"));
    }
    get last() {
      let len = this.length;
      if (dart.notNull(len) > 0) {
        return dart.as(wrap_jso(this.raw[dart.notNull(len) - 1]), Node);
      }
      dart.throw(new core.StateError("No elements"));
    }
    get single() {
      let len = this.length;
      if (len == 1) {
        return dart.as(wrap_jso(this.raw[0]), Node);
      }
      if (len == 0) dart.throw(new core.StateError("No elements"));
      dart.throw(new core.StateError("More than one element"));
    }
    elementAt(index) {
      return this.get(index);
    }
    [__getter__](name) {
      return this[__getter___1](name);
    }
    [__getter___1](name) {
      return dart.as(wrap_jso(this.raw.__getter__(unwrap_jso(name))), Node);
    }
    getNamedItem(name) {
      return this[_getNamedItem_1](name);
    }
    [_getNamedItem_1](name) {
      return dart.as(wrap_jso(this.raw.getNamedItem(unwrap_jso(name))), Node);
    }
    getNamedItemNS(namespaceURI, localName) {
      return this[_getNamedItemNS_1](namespaceURI, localName);
    }
    [_getNamedItemNS_1](namespaceURI, localName) {
      return dart.as(wrap_jso(this.raw.getNamedItemNS(unwrap_jso(namespaceURI), unwrap_jso(localName))), Node);
    }
    item(index) {
      return this[_item_1](index);
    }
    [_item_1](index) {
      return dart.as(wrap_jso(this.raw.item(unwrap_jso(index))), Node);
    }
    removeNamedItem(name) {
      return this[_removeNamedItem_1](name);
    }
    [_removeNamedItem_1](name) {
      return dart.as(wrap_jso(this.raw.removeNamedItem(unwrap_jso(name))), Node);
    }
    removeNamedItemNS(namespaceURI, localName) {
      return this[_removeNamedItemNS_1](namespaceURI, localName);
    }
    [_removeNamedItemNS_1](namespaceURI, localName) {
      return dart.as(wrap_jso(this.raw.removeNamedItemNS(unwrap_jso(namespaceURI), unwrap_jso(localName))), Node);
    }
    setNamedItem(node) {
      return this[_setNamedItem_1](node);
    }
    [_setNamedItem_1](node) {
      return dart.as(wrap_jso(this.raw.setNamedItem(unwrap_jso(node))), Node);
    }
    setNamedItemNS(node) {
      return this[_setNamedItemNS_1](node);
    }
    [_setNamedItemNS_1](node) {
      return dart.as(wrap_jso(this.raw.setNamedItemNS(unwrap_jso(node))), Node);
    }
  }
  _NamedNodeMap[dart.implements] = () => [_js_helper.JavaScriptIndexingBehavior, core.List$(Node)];
  dart.defineNamedConstructor(_NamedNodeMap, 'internal_');
  dart.setSignature(_NamedNodeMap, {
    constructors: () => ({
      _: [_NamedNodeMap, []],
      internal_: [_NamedNodeMap, []]
    }),
    methods: () => ({
      get: [Node, [core.int]],
      set: [dart.void, [core.int, Node]],
      elementAt: [Node, [core.int]],
      [__getter__]: [Node, [core.String]],
      [__getter___1]: [Node, [dart.dynamic]],
      getNamedItem: [Node, [core.String]],
      [_getNamedItem_1]: [Node, [dart.dynamic]],
      getNamedItemNS: [Node, [core.String, core.String]],
      [_getNamedItemNS_1]: [Node, [dart.dynamic, dart.dynamic]],
      item: [Node, [core.int]],
      [_item_1]: [Node, [dart.dynamic]],
      removeNamedItem: [Node, [core.String]],
      [_removeNamedItem_1]: [Node, [dart.dynamic]],
      removeNamedItemNS: [Node, [core.String, core.String]],
      [_removeNamedItemNS_1]: [Node, [dart.dynamic, dart.dynamic]],
      setNamedItem: [Node, [Node]],
      [_setNamedItem_1]: [Node, [Node]],
      setNamedItemNS: [Node, [Node]],
      [_setNamedItemNS_1]: [Node, [Node]]
    }),
    statics: () => ({internalCreate_NamedNodeMap: [_NamedNodeMap, []]}),
    names: ['internalCreate_NamedNodeMap']
  });
  dart.defineExtensionMembers(_NamedNodeMap, [
    'get',
    'set',
    'elementAt',
    'length',
    'length',
    'first',
    'last',
    'single'
  ]);
  _NamedNodeMap[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('NamedNodeMap')), core.deprecated, dart.const(new _js_helper.Native("NamedNodeMap,MozNamedAttrMap"))];
  class _XMLHttpRequestProgressEvent extends ProgressEvent {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static internalCreate_XMLHttpRequestProgressEvent() {
      return new _XMLHttpRequestProgressEvent.internal_();
    }
    internal_() {
      super.internal_();
    }
  }
  dart.defineNamedConstructor(_XMLHttpRequestProgressEvent, 'internal_');
  dart.setSignature(_XMLHttpRequestProgressEvent, {
    constructors: () => ({
      _: [_XMLHttpRequestProgressEvent, []],
      internal_: [_XMLHttpRequestProgressEvent, []]
    }),
    statics: () => ({internalCreate_XMLHttpRequestProgressEvent: [_XMLHttpRequestProgressEvent, []]}),
    names: ['internalCreate_XMLHttpRequestProgressEvent']
  });
  _XMLHttpRequestProgressEvent[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('XMLHttpRequestProgressEvent')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("XMLHttpRequestProgressEvent"))];
  const _matches = Symbol('_matches');
  class _AttributeMap extends core.Object {
    _AttributeMap(element) {
      this[_element] = element;
    }
    addAll(other) {
      other.forEach(dart.fn((k, v) => {
        this.set(k, v);
      }, dart.void, [core.String, core.String]));
    }
    containsValue(value) {
      for (let v of this.values) {
        if (dart.equals(value, v)) {
          return true;
        }
      }
      return false;
    }
    putIfAbsent(key, ifAbsent) {
      if (!dart.notNull(this.containsKey(key))) {
        this.set(key, ifAbsent());
      }
      return this.get(key);
    }
    clear() {
      for (let key of this.keys) {
        this.remove(key);
      }
    }
    forEach(f) {
      for (let key of this.keys) {
        let value = this.get(key);
        f(key, value);
      }
    }
    get keys() {
      let attributes = this[_element][_attributes];
      let keys = core.List$(core.String).new();
      for (let i = 0, len = attributes.length; i < dart.notNull(len); i++) {
        if (dart.notNull(this[_matches](attributes.get(i)))) {
          keys[dartx.add](dart.as(dart.dload(attributes.get(i), 'name'), core.String));
        }
      }
      return keys;
    }
    get values() {
      let attributes = this[_element][_attributes];
      let values = core.List$(core.String).new();
      for (let i = 0, len = attributes.length; i < dart.notNull(len); i++) {
        if (dart.notNull(this[_matches](attributes.get(i)))) {
          values[dartx.add](dart.as(dart.dload(attributes.get(i), 'value'), core.String));
        }
      }
      return values;
    }
    get isEmpty() {
      return this.length == 0;
    }
    get isNotEmpty() {
      return !dart.notNull(this.isEmpty);
    }
  }
  _AttributeMap[dart.implements] = () => [core.Map$(core.String, core.String)];
  dart.setSignature(_AttributeMap, {
    constructors: () => ({_AttributeMap: [_AttributeMap, [Element]]}),
    methods: () => ({
      addAll: [dart.void, [core.Map$(core.String, core.String)]],
      containsValue: [core.bool, [core.Object]],
      putIfAbsent: [core.String, [core.String, dart.functionType(core.String, [])]],
      clear: [dart.void, []],
      forEach: [dart.void, [dart.functionType(dart.void, [core.String, core.String])]]
    })
  });
  class _ElementAttributeMap extends _AttributeMap {
    _ElementAttributeMap(element) {
      super._AttributeMap(element);
    }
    containsKey(key) {
      return this[_element][_hasAttribute](dart.as(key, core.String));
    }
    get(key) {
      return this[_element].getAttribute(dart.as(key, core.String));
    }
    set(key, value) {
      this[_element].setAttribute(key, value);
      return value;
    }
    remove(key) {
      let value = this[_element].getAttribute(dart.as(key, core.String));
      this[_element][_removeAttribute](dart.as(key, core.String));
      return value;
    }
    get length() {
      return this.keys[dartx.length];
    }
    [_matches](node) {
      return node[_namespaceUri] == null;
    }
  }
  dart.setSignature(_ElementAttributeMap, {
    constructors: () => ({_ElementAttributeMap: [_ElementAttributeMap, [Element]]}),
    methods: () => ({
      containsKey: [core.bool, [core.Object]],
      get: [core.String, [core.Object]],
      set: [dart.void, [core.String, core.String]],
      remove: [core.String, [core.Object]],
      [_matches]: [core.bool, [Node]]
    })
  });
  const _namespace = Symbol('_namespace');
  class _NamespacedAttributeMap extends _AttributeMap {
    _NamespacedAttributeMap(element, namespace) {
      this[_namespace] = namespace;
      super._AttributeMap(element);
    }
    containsKey(key) {
      return this[_element][_hasAttributeNS](this[_namespace], dart.as(key, core.String));
    }
    get(key) {
      return this[_element].getAttributeNS(this[_namespace], dart.as(key, core.String));
    }
    set(key, value) {
      this[_element].setAttributeNS(this[_namespace], key, value);
      return value;
    }
    remove(key) {
      let value = this.get(key);
      this[_element][_removeAttributeNS](this[_namespace], dart.as(key, core.String));
      return value;
    }
    get length() {
      return this.keys[dartx.length];
    }
    [_matches](node) {
      return node[_namespaceUri] == this[_namespace];
    }
  }
  dart.setSignature(_NamespacedAttributeMap, {
    constructors: () => ({_NamespacedAttributeMap: [_NamespacedAttributeMap, [Element, core.String]]}),
    methods: () => ({
      containsKey: [core.bool, [core.Object]],
      get: [core.String, [core.Object]],
      set: [dart.void, [core.String, core.String]],
      remove: [core.String, [core.Object]],
      [_matches]: [core.bool, [Node]]
    })
  });
  const _attr = Symbol('_attr');
  const _strip = Symbol('_strip');
  const _toHyphenedName = Symbol('_toHyphenedName');
  const _toCamelCase = Symbol('_toCamelCase');
  class _DataAttributeMap extends core.Object {
    _DataAttributeMap(attributes) {
      this[_attributes] = attributes;
    }
    addAll(other) {
      other.forEach(dart.fn((k, v) => {
        this.set(k, v);
      }, dart.void, [core.String, core.String]));
    }
    containsValue(value) {
      return this.values[dartx.any](dart.fn(v => dart.equals(v, value), core.bool, [core.String]));
    }
    containsKey(key) {
      return this[_attributes].containsKey(this[_attr](dart.as(key, core.String)));
    }
    get(key) {
      return this[_attributes].get(this[_attr](dart.as(key, core.String)));
    }
    set(key, value) {
      this[_attributes].set(this[_attr](key), value);
      return value;
    }
    putIfAbsent(key, ifAbsent) {
      return this[_attributes].putIfAbsent(this[_attr](key), ifAbsent);
    }
    remove(key) {
      return this[_attributes].remove(this[_attr](dart.as(key, core.String)));
    }
    clear() {
      for (let key of this.keys) {
        this.remove(key);
      }
    }
    forEach(f) {
      this[_attributes].forEach(dart.fn((key, value) => {
        if (dart.notNull(this[_matches](key))) {
          f(this[_strip](key), value);
        }
      }, dart.void, [core.String, core.String]));
    }
    get keys() {
      let keys = core.List$(core.String).new();
      this[_attributes].forEach(dart.fn((key, value) => {
        if (dart.notNull(this[_matches](key))) {
          keys[dartx.add](this[_strip](key));
        }
      }, dart.void, [core.String, core.String]));
      return keys;
    }
    get values() {
      let values = core.List$(core.String).new();
      this[_attributes].forEach(dart.fn((key, value) => {
        if (dart.notNull(this[_matches](key))) {
          values[dartx.add](value);
        }
      }, dart.void, [core.String, core.String]));
      return values;
    }
    get length() {
      return this.keys[dartx.length];
    }
    get isEmpty() {
      return this.length == 0;
    }
    get isNotEmpty() {
      return !dart.notNull(this.isEmpty);
    }
    [_attr](key) {
      return `data-${this[_toHyphenedName](key)}`;
    }
    [_matches](key) {
      return key[dartx.startsWith]('data-');
    }
    [_strip](key) {
      return this[_toCamelCase](key[dartx.substring](5));
    }
    [_toCamelCase](hyphenedName, opts) {
      let startUppercase = opts && 'startUppercase' in opts ? opts.startUppercase : false;
      let segments = hyphenedName[dartx.split]('-');
      let start = dart.notNull(startUppercase) ? 0 : 1;
      for (let i = start; i < dart.notNull(segments[dartx.length]); i++) {
        let segment = segments[dartx.get](i);
        if (dart.notNull(segment[dartx.length]) > 0) {
          segments[dartx.set](i, `${segment[dartx.get](0)[dartx.toUpperCase]()}${segment[dartx.substring](1)}`);
        }
      }
      return segments[dartx.join]('');
    }
    [_toHyphenedName](word) {
      let sb = new core.StringBuffer();
      for (let i = 0; i < dart.notNull(word[dartx.length]); i++) {
        let lower = word[dartx.get](i)[dartx.toLowerCase]();
        if (word[dartx.get](i) != lower && i > 0) sb.write('-');
        sb.write(lower);
      }
      return dart.toString(sb);
    }
  }
  _DataAttributeMap[dart.implements] = () => [core.Map$(core.String, core.String)];
  dart.setSignature(_DataAttributeMap, {
    constructors: () => ({_DataAttributeMap: [_DataAttributeMap, [core.Map$(core.String, core.String)]]}),
    methods: () => ({
      addAll: [dart.void, [core.Map$(core.String, core.String)]],
      containsValue: [core.bool, [core.Object]],
      containsKey: [core.bool, [core.Object]],
      get: [core.String, [core.Object]],
      set: [dart.void, [core.String, core.String]],
      putIfAbsent: [core.String, [core.String, dart.functionType(core.String, [])]],
      remove: [core.String, [core.Object]],
      clear: [dart.void, []],
      forEach: [dart.void, [dart.functionType(dart.void, [core.String, core.String])]],
      [_attr]: [core.String, [core.String]],
      [_matches]: [core.bool, [core.String]],
      [_strip]: [core.String, [core.String]],
      [_toCamelCase]: [core.String, [core.String], {startUppercase: core.bool}],
      [_toHyphenedName]: [core.String, [core.String]]
    })
  });
  class CanvasImageSource extends core.Object {}
  class WindowBase extends core.Object {}
  WindowBase[dart.implements] = () => [EventTarget];
  class LocationBase extends core.Object {}
  class HistoryBase extends core.Object {}
  class CssClassSet extends core.Object {}
  CssClassSet[dart.implements] = () => [core.Set$(core.String)];
  const _addOrSubtractToBoxModel = Symbol('_addOrSubtractToBoxModel');
  class CssRect extends math.MutableRectangle$(core.num) {
    CssRect(element) {
      this[_element] = element;
      super.MutableRectangle(0, 0, 0, 0);
    }
    set height(newHeight) {
      dart.throw(new core.UnsupportedError("Can only set height for content rect."));
    }
    set width(newWidth) {
      dart.throw(new core.UnsupportedError("Can only set width for content rect."));
    }
    [_addOrSubtractToBoxModel](dimensions, augmentingMeasurement) {
      let styles = this[_element].getComputedStyle();
      let val = 0;
      for (let measurement of dimensions) {
        if (augmentingMeasurement == exports._MARGIN) {
          val = dart.notNull(val) + dart.notNull(dart.asInt(new Dimension.css(styles.getPropertyValue(`${augmentingMeasurement}-${measurement}`)).value));
        }
        if (augmentingMeasurement == exports._CONTENT) {
          val = dart.notNull(val) - dart.notNull(dart.asInt(new Dimension.css(styles.getPropertyValue(`${exports._PADDING}-${measurement}`)).value));
        }
        if (augmentingMeasurement != exports._MARGIN) {
          val = dart.notNull(val) - dart.notNull(dart.asInt(new Dimension.css(styles.getPropertyValue(`border-${measurement}-width`)).value));
        }
      }
      return val;
    }
  }
  dart.setSignature(CssRect, {
    constructors: () => ({CssRect: [CssRect, [Element]]}),
    methods: () => ({[_addOrSubtractToBoxModel]: [core.num, [core.List$(core.String), core.String]]})
  });
  class _ContentCssRect extends CssRect {
    _ContentCssRect(element) {
      super.CssRect(dart.as(element, Element));
    }
    get height() {
      return dart.notNull(this[_element].offsetHeight) + dart.notNull(this[_addOrSubtractToBoxModel](dart.as(exports._HEIGHT, core.List$(core.String)), exports._CONTENT));
    }
    get width() {
      return dart.notNull(this[_element].offsetWidth) + dart.notNull(this[_addOrSubtractToBoxModel](dart.as(exports._WIDTH, core.List$(core.String)), exports._CONTENT));
    }
    set height(newHeight) {
      if (dart.is(newHeight, Dimension)) {
        let result = dart.notNull(newHeight.value) < 0 ? new Dimension.px(0) : newHeight;
        this[_element].style.height = dart.toString(result);
      } else {
        let result = dart.notNull(dart.as(newHeight, core.int)) < 0 ? 0 : newHeight;
        this[_element].style.height = `${result}px`;
      }
    }
    set width(newWidth) {
      if (dart.is(newWidth, Dimension)) {
        let result = dart.notNull(newWidth.value) < 0 ? new Dimension.px(0) : newWidth;
        this[_element].style.width = dart.toString(result);
      } else {
        let result = dart.notNull(dart.as(newWidth, core.int)) < 0 ? 0 : newWidth;
        this[_element].style.width = `${result}px`;
      }
    }
    get left() {
      return dart.as(dart.dsend(this[_element].getBoundingClientRect().left, '-', this[_addOrSubtractToBoxModel](dart.list(['left'], core.String), exports._CONTENT)), core.num);
    }
    get top() {
      return dart.as(dart.dsend(this[_element].getBoundingClientRect().top, '-', this[_addOrSubtractToBoxModel](dart.list(['top'], core.String), exports._CONTENT)), core.num);
    }
  }
  dart.setSignature(_ContentCssRect, {
    constructors: () => ({_ContentCssRect: [_ContentCssRect, [dart.dynamic]]})
  });
  const _elementList = Symbol('_elementList');
  class _ContentCssListRect extends _ContentCssRect {
    _ContentCssListRect(elementList) {
      this[_elementList] = null;
      super._ContentCssRect(dart.dload(elementList, 'first'));
      this[_elementList] = dart.as(elementList, core.List$(Element));
    }
    set height(newHeight) {
      this[_elementList][dartx.forEach](dart.fn(e => e.contentEdge.height = dart.as(newHeight, core.num), core.Object, [Element]));
    }
    set width(newWidth) {
      this[_elementList][dartx.forEach](dart.fn(e => e.contentEdge.width = dart.as(newWidth, core.num), core.Object, [Element]));
    }
  }
  dart.setSignature(_ContentCssListRect, {
    constructors: () => ({_ContentCssListRect: [_ContentCssListRect, [dart.dynamic]]})
  });
  class _PaddingCssRect extends CssRect {
    _PaddingCssRect(element) {
      super.CssRect(dart.as(element, Element));
    }
    get height() {
      return dart.notNull(this[_element].offsetHeight) + dart.notNull(this[_addOrSubtractToBoxModel](dart.as(exports._HEIGHT, core.List$(core.String)), exports._PADDING));
    }
    get width() {
      return dart.notNull(this[_element].offsetWidth) + dart.notNull(this[_addOrSubtractToBoxModel](dart.as(exports._WIDTH, core.List$(core.String)), exports._PADDING));
    }
    get left() {
      return dart.as(dart.dsend(this[_element].getBoundingClientRect().left, '-', this[_addOrSubtractToBoxModel](dart.list(['left'], core.String), exports._PADDING)), core.num);
    }
    get top() {
      return dart.as(dart.dsend(this[_element].getBoundingClientRect().top, '-', this[_addOrSubtractToBoxModel](dart.list(['top'], core.String), exports._PADDING)), core.num);
    }
  }
  dart.setSignature(_PaddingCssRect, {
    constructors: () => ({_PaddingCssRect: [_PaddingCssRect, [dart.dynamic]]})
  });
  class _BorderCssRect extends CssRect {
    _BorderCssRect(element) {
      super.CssRect(dart.as(element, Element));
    }
    get height() {
      return this[_element].offsetHeight;
    }
    get width() {
      return this[_element].offsetWidth;
    }
    get left() {
      return dart.as(this[_element].getBoundingClientRect().left, core.num);
    }
    get top() {
      return dart.as(this[_element].getBoundingClientRect().top, core.num);
    }
  }
  dart.setSignature(_BorderCssRect, {
    constructors: () => ({_BorderCssRect: [_BorderCssRect, [dart.dynamic]]})
  });
  class _MarginCssRect extends CssRect {
    _MarginCssRect(element) {
      super.CssRect(dart.as(element, Element));
    }
    get height() {
      return dart.notNull(this[_element].offsetHeight) + dart.notNull(this[_addOrSubtractToBoxModel](dart.as(exports._HEIGHT, core.List$(core.String)), exports._MARGIN));
    }
    get width() {
      return dart.notNull(this[_element].offsetWidth) + dart.notNull(this[_addOrSubtractToBoxModel](dart.as(exports._WIDTH, core.List$(core.String)), exports._MARGIN));
    }
    get left() {
      return dart.as(dart.dsend(this[_element].getBoundingClientRect().left, '-', this[_addOrSubtractToBoxModel](dart.list(['left'], core.String), exports._MARGIN)), core.num);
    }
    get top() {
      return dart.as(dart.dsend(this[_element].getBoundingClientRect().top, '-', this[_addOrSubtractToBoxModel](dart.list(['top'], core.String), exports._MARGIN)), core.num);
    }
  }
  dart.setSignature(_MarginCssRect, {
    constructors: () => ({_MarginCssRect: [_MarginCssRect, [dart.dynamic]]})
  });
  dart.defineLazyProperties(exports, {
    get _HEIGHT() {
      return ['top', 'bottom'];
    }
  });
  dart.defineLazyProperties(exports, {
    get _WIDTH() {
      return ['right', 'left'];
    }
  });
  exports._CONTENT = 'content';
  exports._PADDING = 'padding';
  exports._MARGIN = 'margin';
  const _sets = Symbol('_sets');
  dart.defineLazyClass(exports, {
    get _MultiElementCssClassSet() {
      class _MultiElementCssClassSet extends html_common.CssClassSetImpl {
        static new(elements) {
          return new exports._MultiElementCssClassSet._(elements, dart.as(elements[dartx.map](dart.fn(e => e.classes, CssClassSet, [Element]))[dartx.toList](), core.List$(html_common.CssClassSetImpl)));
        }
        _(elementIterable, sets) {
          this[_elementIterable] = elementIterable;
          this[_sets] = sets;
        }
        readClasses() {
          let s = collection.LinkedHashSet$(core.String).new();
          this[_sets][dartx.forEach](dart.fn(e => s.addAll(e.readClasses()), dart.void, [html_common.CssClassSetImpl]));
          return s;
        }
        writeClasses(s) {
          let classes = s.join(' ');
          for (let e of this[_elementIterable]) {
            e.className = classes;
          }
        }
        modify(f) {
          this[_sets][dartx.forEach](dart.fn(e => e.modify(f), dart.void, [html_common.CssClassSetImpl]));
        }
        toggle(value, shouldAdd) {
          if (shouldAdd === void 0) shouldAdd = null;
          return this[_sets][dartx.fold](false, dart.fn((changed, e) => dart.notNull(e.toggle(value, shouldAdd)) || dart.notNull(changed), core.bool, [core.bool, html_common.CssClassSetImpl]));
        }
        remove(value) {
          return this[_sets][dartx.fold](false, dart.fn((changed, e) => dart.notNull(e.remove(value)) || dart.notNull(changed), core.bool, [core.bool, html_common.CssClassSetImpl]));
        }
      }
      dart.defineNamedConstructor(_MultiElementCssClassSet, '_');
      dart.setSignature(_MultiElementCssClassSet, {
        constructors: () => ({
          new: [exports._MultiElementCssClassSet, [core.Iterable$(Element)]],
          _: [exports._MultiElementCssClassSet, [core.Iterable$(Element), core.List$(html_common.CssClassSetImpl)]]
        }),
        methods: () => ({
          readClasses: [core.Set$(core.String), []],
          writeClasses: [dart.void, [core.Set$(core.String)]]
        })
      });
      return _MultiElementCssClassSet;
    }
  });
  dart.defineLazyClass(exports, {
    get _ElementCssClassSet() {
      class _ElementCssClassSet extends html_common.CssClassSetImpl {
        _ElementCssClassSet(element) {
          this[_element] = element;
        }
        readClasses() {
          let s = collection.LinkedHashSet$(core.String).new();
          let classname = this[_element].className;
          for (let name of classname[dartx.split](' ')) {
            let trimmed = name[dartx.trim]();
            if (!dart.notNull(trimmed[dartx.isEmpty])) {
              s.add(trimmed);
            }
          }
          return s;
        }
        writeClasses(s) {
          this[_element].className = s.join(' ');
        }
        get length() {
          return exports._ElementCssClassSet._classListLength(exports._ElementCssClassSet._classListOf(this[_element]));
        }
        get isEmpty() {
          return this.length == 0;
        }
        get isNotEmpty() {
          return this.length != 0;
        }
        clear() {
          this[_element].className = '';
        }
        contains(value) {
          return exports._ElementCssClassSet._contains(this[_element], value);
        }
        add(value) {
          return exports._ElementCssClassSet._add(this[_element], value);
        }
        remove(value) {
          return typeof value == 'string' && dart.notNull(exports._ElementCssClassSet._remove(this[_element], value));
        }
        toggle(value, shouldAdd) {
          if (shouldAdd === void 0) shouldAdd = null;
          return exports._ElementCssClassSet._toggle(this[_element], value, shouldAdd);
        }
        addAll(iterable) {
          exports._ElementCssClassSet._addAll(this[_element], iterable);
        }
        removeAll(iterable) {
          exports._ElementCssClassSet._removeAll(this[_element], dart.as(iterable, core.Iterable$(core.String)));
        }
        retainAll(iterable) {
          exports._ElementCssClassSet._removeWhere(this[_element], dart.bind(iterable[dartx.toSet](), 'contains'), false);
        }
        removeWhere(test) {
          exports._ElementCssClassSet._removeWhere(this[_element], test, true);
        }
        retainWhere(test) {
          exports._ElementCssClassSet._removeWhere(this[_element], test, false);
        }
        static _contains(_element, value) {
          return typeof value == 'string' && dart.notNull(exports._ElementCssClassSet._classListContains(exports._ElementCssClassSet._classListOf(_element), value));
        }
        static _add(_element, value) {
          let list = exports._ElementCssClassSet._classListOf(_element);
          let added = !dart.notNull(exports._ElementCssClassSet._classListContainsBeforeAddOrRemove(list, value));
          exports._ElementCssClassSet._classListAdd(list, value);
          return added;
        }
        static _remove(_element, value) {
          let list = exports._ElementCssClassSet._classListOf(_element);
          let removed = exports._ElementCssClassSet._classListContainsBeforeAddOrRemove(list, value);
          exports._ElementCssClassSet._classListRemove(list, value);
          return removed;
        }
        static _toggle(_element, value, shouldAdd) {
          return shouldAdd == null ? exports._ElementCssClassSet._toggleDefault(_element, value) : exports._ElementCssClassSet._toggleOnOff(_element, value, shouldAdd);
        }
        static _toggleDefault(_element, value) {
          let list = exports._ElementCssClassSet._classListOf(_element);
          return exports._ElementCssClassSet._classListToggle1(list, value);
        }
        static _toggleOnOff(_element, value, shouldAdd) {
          let list = exports._ElementCssClassSet._classListOf(_element);
          if (dart.notNull(shouldAdd)) {
            exports._ElementCssClassSet._classListAdd(list, value);
            return true;
          } else {
            exports._ElementCssClassSet._classListRemove(list, value);
            return false;
          }
        }
        static _addAll(_element, iterable) {
          let list = exports._ElementCssClassSet._classListOf(_element);
          for (let value of iterable) {
            exports._ElementCssClassSet._classListAdd(list, value);
          }
        }
        static _removeAll(_element, iterable) {
          let list = exports._ElementCssClassSet._classListOf(_element);
          for (let value of iterable) {
            exports._ElementCssClassSet._classListRemove(list, value);
          }
        }
        static _removeWhere(_element, test, doRemove) {
          let list = exports._ElementCssClassSet._classListOf(_element);
          let i = 0;
          while (i < dart.notNull(exports._ElementCssClassSet._classListLength(list))) {
            let item = list.item(i);
            if (doRemove == test(item)) {
              exports._ElementCssClassSet._classListRemove(list, item);
            } else {
              ++i;
            }
          }
        }
        static _classListOf(e) {
          return dart.as(wrap_jso(e.raw.classList), DomTokenList);
        }
        static _classListLength(list) {
          return dart.as(list.raw.length, core.int);
        }
        static _classListContains(list, value) {
          return dart.as(list.raw.contains(value), core.bool);
        }
        static _classListContainsBeforeAddOrRemove(list, value) {
          return dart.as(list.raw.contains(value), core.bool);
        }
        static _classListAdd(list, value) {
          list.raw.add(value);
        }
        static _classListRemove(list, value) {
          list.raw.remove(value);
        }
        static _classListToggle1(list, value) {
          return list.raw.toggle(value);
        }
        static _classListToggle2(list, value, shouldAdd) {
          return list.raw.toggle(value, shouldAdd);
        }
      }
      dart.setSignature(_ElementCssClassSet, {
        constructors: () => ({_ElementCssClassSet: [exports._ElementCssClassSet, [Element]]}),
        methods: () => ({
          readClasses: [core.Set$(core.String), []],
          writeClasses: [dart.void, [core.Set$(core.String)]]
        }),
        statics: () => ({
          _contains: [core.bool, [Element, core.Object]],
          _add: [core.bool, [Element, core.String]],
          _remove: [core.bool, [Element, core.String]],
          _toggle: [core.bool, [Element, core.String, core.bool]],
          _toggleDefault: [core.bool, [Element, core.String]],
          _toggleOnOff: [core.bool, [Element, core.String, core.bool]],
          _addAll: [dart.void, [Element, core.Iterable$(core.String)]],
          _removeAll: [dart.void, [Element, core.Iterable$(core.String)]],
          _removeWhere: [dart.void, [Element, dart.functionType(core.bool, [core.String]), core.bool]],
          _classListOf: [DomTokenList, [Element]],
          _classListLength: [core.int, [DomTokenList]],
          _classListContains: [core.bool, [DomTokenList, core.String]],
          _classListContainsBeforeAddOrRemove: [core.bool, [DomTokenList, core.String]],
          _classListAdd: [dart.void, [DomTokenList, core.String]],
          _classListRemove: [dart.void, [DomTokenList, core.String]],
          _classListToggle1: [core.bool, [DomTokenList, core.String]],
          _classListToggle2: [core.bool, [DomTokenList, core.String, core.bool]]
        }),
        names: ['_contains', '_add', '_remove', '_toggle', '_toggleDefault', '_toggleOnOff', '_addAll', '_removeAll', '_removeWhere', '_classListOf', '_classListLength', '_classListContains', '_classListContainsBeforeAddOrRemove', '_classListAdd', '_classListRemove', '_classListToggle1', '_classListToggle2']
      });
      dart.defineExtensionMembers(_ElementCssClassSet, ['contains', 'length', 'isEmpty', 'isNotEmpty']);
      return _ElementCssClassSet;
    }
  });
  const _unit = Symbol('_unit');
  class Dimension extends core.Object {
    percent(value) {
      this[_value] = value;
      this[_unit] = '%';
    }
    px(value) {
      this[_value] = value;
      this[_unit] = 'px';
    }
    pc(value) {
      this[_value] = value;
      this[_unit] = 'pc';
    }
    pt(value) {
      this[_value] = value;
      this[_unit] = 'pt';
    }
    inch(value) {
      this[_value] = value;
      this[_unit] = 'in';
    }
    cm(value) {
      this[_value] = value;
      this[_unit] = 'cm';
    }
    mm(value) {
      this[_value] = value;
      this[_unit] = 'mm';
    }
    em(value) {
      this[_value] = value;
      this[_unit] = 'em';
    }
    ex(value) {
      this[_value] = value;
      this[_unit] = 'ex';
    }
    css(cssValue) {
      this[_value] = null;
      this[_unit] = null;
      if (cssValue == '') cssValue = '0px';
      if (dart.notNull(cssValue[dartx.endsWith]('%'))) {
        this[_unit] = '%';
      } else {
        this[_unit] = cssValue[dartx.substring](dart.notNull(cssValue[dartx.length]) - 2);
      }
      if (dart.notNull(cssValue[dartx.contains]('.'))) {
        this[_value] = core.double.parse(cssValue[dartx.substring](0, dart.notNull(cssValue[dartx.length]) - dart.notNull(this[_unit][dartx.length])));
      } else {
        this[_value] = core.int.parse(cssValue[dartx.substring](0, dart.notNull(cssValue[dartx.length]) - dart.notNull(this[_unit][dartx.length])));
      }
    }
    toString() {
      return `${this[_value]}${this[_unit]}`;
    }
    get value() {
      return this[_value];
    }
  }
  dart.defineNamedConstructor(Dimension, 'percent');
  dart.defineNamedConstructor(Dimension, 'px');
  dart.defineNamedConstructor(Dimension, 'pc');
  dart.defineNamedConstructor(Dimension, 'pt');
  dart.defineNamedConstructor(Dimension, 'inch');
  dart.defineNamedConstructor(Dimension, 'cm');
  dart.defineNamedConstructor(Dimension, 'mm');
  dart.defineNamedConstructor(Dimension, 'em');
  dart.defineNamedConstructor(Dimension, 'ex');
  dart.defineNamedConstructor(Dimension, 'css');
  dart.setSignature(Dimension, {
    constructors: () => ({
      percent: [Dimension, [core.num]],
      px: [Dimension, [core.num]],
      pc: [Dimension, [core.num]],
      pt: [Dimension, [core.num]],
      inch: [Dimension, [core.num]],
      cm: [Dimension, [core.num]],
      mm: [Dimension, [core.num]],
      em: [Dimension, [core.num]],
      ex: [Dimension, [core.num]],
      css: [Dimension, [core.String]]
    })
  });
  Dimension[dart.metadata] = () => [dart.const(new _metadata.Experimental())];
  const EventListener = dart.typedef('EventListener', () => dart.functionType(dart.dynamic, [Event]));
  const _eventType = Symbol('_eventType');
  const EventStreamProvider$ = dart.generic(function(T) {
    class EventStreamProvider extends core.Object {
      EventStreamProvider(eventType) {
        this[_eventType] = eventType;
      }
      forTarget(e, opts) {
        let useCapture = opts && 'useCapture' in opts ? opts.useCapture : false;
        return new (_EventStream$(T))(e, this[_eventType], useCapture);
      }
      forElement(e, opts) {
        let useCapture = opts && 'useCapture' in opts ? opts.useCapture : false;
        return new (_ElementEventStreamImpl$(T))(e, this[_eventType], useCapture);
      }
      [_forElementList](e, opts) {
        let useCapture = opts && 'useCapture' in opts ? opts.useCapture : false;
        return new (_ElementListEventStreamImpl$(T))(dart.as(e, core.Iterable$(Element)), this[_eventType], useCapture);
      }
      getEventType(target) {
        return this[_eventType];
      }
    }
    dart.setSignature(EventStreamProvider, {
      constructors: () => ({EventStreamProvider: [EventStreamProvider$(T), [core.String]]}),
      methods: () => ({
        forTarget: [async.Stream$(T), [EventTarget], {useCapture: core.bool}],
        forElement: [ElementStream$(T), [Element], {useCapture: core.bool}],
        [_forElementList]: [ElementStream$(T), [ElementList], {useCapture: core.bool}],
        getEventType: [core.String, [EventTarget]]
      })
    });
    return EventStreamProvider;
  });
  let EventStreamProvider = EventStreamProvider$();
  const ElementStream$ = dart.generic(function(T) {
    class ElementStream extends core.Object {}
    ElementStream[dart.implements] = () => [async.Stream$(T)];
    return ElementStream;
  });
  let ElementStream = ElementStream$();
  const _target = Symbol('_target');
  const _useCapture = Symbol('_useCapture');
  const _EventStream$ = dart.generic(function(T) {
    class _EventStream extends async.Stream$(T) {
      _EventStream(target, eventType, useCapture) {
        this[_target] = target;
        this[_eventType] = eventType;
        this[_useCapture] = useCapture;
        super.Stream();
      }
      asBroadcastStream(opts) {
        let onListen = opts && 'onListen' in opts ? opts.onListen : null;
        dart.as(onListen, dart.functionType(dart.void, [async.StreamSubscription$(T)]));
        let onCancel = opts && 'onCancel' in opts ? opts.onCancel : null;
        dart.as(onCancel, dart.functionType(dart.void, [async.StreamSubscription$(T)]));
        return this;
      }
      get isBroadcast() {
        return true;
      }
      listen(onData, opts) {
        dart.as(onData, dart.functionType(dart.void, [T]));
        let onError = opts && 'onError' in opts ? opts.onError : null;
        let onDone = opts && 'onDone' in opts ? opts.onDone : null;
        dart.as(onDone, dart.functionType(dart.void, []));
        let cancelOnError = opts && 'cancelOnError' in opts ? opts.cancelOnError : null;
        return new (_EventStreamSubscription$(T))(this[_target], this[_eventType], onData, this[_useCapture]);
      }
    }
    dart.setSignature(_EventStream, {
      constructors: () => ({_EventStream: [_EventStream$(T), [EventTarget, core.String, core.bool]]}),
      methods: () => ({
        asBroadcastStream: [async.Stream$(T), [], {onListen: dart.functionType(dart.void, [async.StreamSubscription$(T)]), onCancel: dart.functionType(dart.void, [async.StreamSubscription$(T)])}],
        listen: [async.StreamSubscription$(T), [dart.functionType(dart.void, [T])], {onError: core.Function, onDone: dart.functionType(dart.void, []), cancelOnError: core.bool}]
      })
    });
    return _EventStream;
  });
  let _EventStream = _EventStream$();
  const _ElementEventStreamImpl$ = dart.generic(function(T) {
    class _ElementEventStreamImpl extends _EventStream$(T) {
      _ElementEventStreamImpl(target, eventType, useCapture) {
        super._EventStream(dart.as(target, EventTarget), dart.as(eventType, core.String), dart.as(useCapture, core.bool));
      }
      matches(selector) {
        return dart.as(this.where(dart.fn(event => dart.as(dart.dcall(event.target.matchesWithAncestors, selector), core.bool), core.bool, [T])).map(dart.fn(e => {
          dart.as(e, T);
          e[_selector] = selector;
          return e;
        }, dart.dynamic, [T])), async.Stream$(T));
      }
      capture(onData) {
        dart.as(onData, dart.functionType(dart.void, [T]));
        return new (_EventStreamSubscription$(T))(this[_target], this[_eventType], onData, true);
      }
    }
    _ElementEventStreamImpl[dart.implements] = () => [ElementStream$(T)];
    dart.setSignature(_ElementEventStreamImpl, {
      constructors: () => ({_ElementEventStreamImpl: [_ElementEventStreamImpl$(T), [dart.dynamic, dart.dynamic, dart.dynamic]]}),
      methods: () => ({
        matches: [async.Stream$(T), [core.String]],
        capture: [async.StreamSubscription$(T), [dart.functionType(dart.void, [T])]]
      })
    });
    return _ElementEventStreamImpl;
  });
  let _ElementEventStreamImpl = _ElementEventStreamImpl$();
  const _targetList = Symbol('_targetList');
  const _ElementListEventStreamImpl$ = dart.generic(function(T) {
    class _ElementListEventStreamImpl extends async.Stream$(T) {
      _ElementListEventStreamImpl(targetList, eventType, useCapture) {
        this[_targetList] = targetList;
        this[_eventType] = eventType;
        this[_useCapture] = useCapture;
        super.Stream();
      }
      matches(selector) {
        return dart.as(this.where(dart.fn(event => dart.as(dart.dcall(event.target.matchesWithAncestors, selector), core.bool), core.bool, [T])).map(dart.fn(e => {
          dart.as(e, T);
          e[_selector] = selector;
          return e;
        }, dart.dynamic, [T])), async.Stream$(T));
      }
      listen(onData, opts) {
        dart.as(onData, dart.functionType(dart.void, [T]));
        let onError = opts && 'onError' in opts ? opts.onError : null;
        let onDone = opts && 'onDone' in opts ? opts.onDone : null;
        dart.as(onDone, dart.functionType(dart.void, []));
        let cancelOnError = opts && 'cancelOnError' in opts ? opts.cancelOnError : null;
        let pool = new _StreamPool.broadcast();
        for (let target of this[_targetList]) {
          pool.add(new _EventStream(target, this[_eventType], this[_useCapture]));
        }
        return dart.as(pool.stream.listen(onData, {onError: onError, onDone: onDone, cancelOnError: cancelOnError}), async.StreamSubscription$(T));
      }
      capture(onData) {
        dart.as(onData, dart.functionType(dart.void, [T]));
        let pool = new _StreamPool.broadcast();
        for (let target of this[_targetList]) {
          pool.add(new _EventStream(target, this[_eventType], true));
        }
        return dart.as(pool.stream.listen(onData), async.StreamSubscription$(T));
      }
      asBroadcastStream(opts) {
        let onListen = opts && 'onListen' in opts ? opts.onListen : null;
        dart.as(onListen, dart.functionType(dart.void, [async.StreamSubscription$(T)]));
        let onCancel = opts && 'onCancel' in opts ? opts.onCancel : null;
        dart.as(onCancel, dart.functionType(dart.void, [async.StreamSubscription$(T)]));
        return this;
      }
      get isBroadcast() {
        return true;
      }
    }
    _ElementListEventStreamImpl[dart.implements] = () => [ElementStream$(T)];
    dart.setSignature(_ElementListEventStreamImpl, {
      constructors: () => ({_ElementListEventStreamImpl: [_ElementListEventStreamImpl$(T), [core.Iterable$(Element), core.String, core.bool]]}),
      methods: () => ({
        matches: [async.Stream$(T), [core.String]],
        listen: [async.StreamSubscription$(T), [dart.functionType(dart.void, [T])], {onError: core.Function, onDone: dart.functionType(dart.void, []), cancelOnError: core.bool}],
        capture: [async.StreamSubscription$(T), [dart.functionType(dart.void, [T])]],
        asBroadcastStream: [async.Stream$(T), [], {onListen: dart.functionType(dart.void, [async.StreamSubscription$(T)]), onCancel: dart.functionType(dart.void, [async.StreamSubscription$(T)])}]
      })
    });
    return _ElementListEventStreamImpl;
  });
  let _ElementListEventStreamImpl = _ElementListEventStreamImpl$();
  const _onData = Symbol('_onData');
  const _pauseCount = Symbol('_pauseCount');
  const _tryResume = Symbol('_tryResume');
  const _canceled = Symbol('_canceled');
  const _unlisten = Symbol('_unlisten');
  const _EventStreamSubscription$ = dart.generic(function(T) {
    class _EventStreamSubscription extends async.StreamSubscription$(T) {
      _EventStreamSubscription(target, eventType, onData, useCapture) {
        this[_target] = target;
        this[_eventType] = eventType;
        this[_useCapture] = useCapture;
        this[_onData] = _wrapZone(dart.as(onData, __CastType2));
        this[_pauseCount] = 0;
        this[_tryResume]();
      }
      cancel() {
        if (dart.notNull(this[_canceled])) return null;
        this[_unlisten]();
        this[_target] = null;
        this[_onData] = null;
        return null;
      }
      get [_canceled]() {
        return this[_target] == null;
      }
      onData(handleData) {
        dart.as(handleData, dart.functionType(dart.void, [T]));
        if (dart.notNull(this[_canceled])) {
          dart.throw(new core.StateError("Subscription has been canceled."));
        }
        this[_unlisten]();
        this[_onData] = _wrapZone(handleData);
        this[_tryResume]();
      }
      onError(handleError) {}
      onDone(handleDone) {
        dart.as(handleDone, dart.functionType(dart.void, []));
      }
      pause(resumeSignal) {
        if (resumeSignal === void 0) resumeSignal = null;
        if (dart.notNull(this[_canceled])) return;
        this[_pauseCount] = dart.notNull(this[_pauseCount]) + 1;
        this[_unlisten]();
        if (resumeSignal != null) {
          resumeSignal.whenComplete(dart.bind(this, 'resume'));
        }
      }
      get isPaused() {
        return dart.notNull(this[_pauseCount]) > 0;
      }
      resume() {
        if (dart.notNull(this[_canceled]) || !dart.notNull(this.isPaused)) return;
        this[_pauseCount] = dart.notNull(this[_pauseCount]) - 1;
        this[_tryResume]();
      }
      [_tryResume]() {
        if (this[_onData] != null && !dart.notNull(this.isPaused)) {
          this[_target].addEventListener(this[_eventType], dart.as(this[_onData], EventListener), this[_useCapture]);
        }
      }
      [_unlisten]() {
        if (this[_onData] != null) {
          this[_target].removeEventListener(this[_eventType], dart.as(this[_onData], EventListener), this[_useCapture]);
        }
      }
      asFuture(futureValue) {
        if (futureValue === void 0) futureValue = null;
        let completer = async.Completer.new();
        return completer.future;
      }
    }
    dart.setSignature(_EventStreamSubscription, {
      constructors: () => ({_EventStreamSubscription: [_EventStreamSubscription$(T), [EventTarget, core.String, dart.dynamic, core.bool]]}),
      methods: () => ({
        cancel: [async.Future, []],
        onData: [dart.void, [dart.functionType(dart.void, [T])]],
        onError: [dart.void, [core.Function]],
        onDone: [dart.void, [dart.functionType(dart.void, [])]],
        pause: [dart.void, [], [async.Future]],
        resume: [dart.void, []],
        [_tryResume]: [dart.void, []],
        [_unlisten]: [dart.void, []],
        asFuture: [async.Future, [], [dart.dynamic]]
      })
    });
    return _EventStreamSubscription;
  });
  let _EventStreamSubscription = _EventStreamSubscription$();
  const CustomStream$ = dart.generic(function(T) {
    class CustomStream extends core.Object {}
    CustomStream[dart.implements] = () => [async.Stream$(T)];
    return CustomStream;
  });
  let CustomStream = CustomStream$();
  const _streamController = Symbol('_streamController');
  const _type = Symbol('_type');
  const _CustomEventStreamImpl$ = dart.generic(function(T) {
    class _CustomEventStreamImpl extends async.Stream$(T) {
      _CustomEventStreamImpl(type) {
        this[_streamController] = null;
        this[_type] = null;
        super.Stream();
        this[_type] = type;
        this[_streamController] = async.StreamController$(T).broadcast({sync: true});
      }
      listen(onData, opts) {
        dart.as(onData, dart.functionType(dart.void, [T]));
        let onError = opts && 'onError' in opts ? opts.onError : null;
        let onDone = opts && 'onDone' in opts ? opts.onDone : null;
        dart.as(onDone, dart.functionType(dart.void, []));
        let cancelOnError = opts && 'cancelOnError' in opts ? opts.cancelOnError : null;
        return this[_streamController].stream.listen(onData, {onError: onError, onDone: onDone, cancelOnError: cancelOnError});
      }
      asBroadcastStream(opts) {
        let onListen = opts && 'onListen' in opts ? opts.onListen : null;
        dart.as(onListen, dart.functionType(dart.void, [async.StreamSubscription$(T)]));
        let onCancel = opts && 'onCancel' in opts ? opts.onCancel : null;
        dart.as(onCancel, dart.functionType(dart.void, [async.StreamSubscription$(T)]));
        return this[_streamController].stream;
      }
      get isBroadcast() {
        return true;
      }
      add(event) {
        dart.as(event, T);
        if (event.type == this[_type]) this[_streamController].add(event);
      }
    }
    _CustomEventStreamImpl[dart.implements] = () => [CustomStream$(T)];
    dart.setSignature(_CustomEventStreamImpl, {
      constructors: () => ({_CustomEventStreamImpl: [_CustomEventStreamImpl$(T), [core.String]]}),
      methods: () => ({
        listen: [async.StreamSubscription$(T), [dart.functionType(dart.void, [T])], {onError: core.Function, onDone: dart.functionType(dart.void, []), cancelOnError: core.bool}],
        asBroadcastStream: [async.Stream$(T), [], {onListen: dart.functionType(dart.void, [async.StreamSubscription$(T)]), onCancel: dart.functionType(dart.void, [async.StreamSubscription$(T)])}],
        add: [dart.void, [T]]
      })
    });
    return _CustomEventStreamImpl;
  });
  let _CustomEventStreamImpl = _CustomEventStreamImpl$();
  class _WrappedEvent extends core.Object {
    _WrappedEvent(wrapped) {
      this.wrapped = wrapped;
      this[_selector] = null;
    }
    get bubbles() {
      return this.wrapped.bubbles;
    }
    get cancelable() {
      return this.wrapped.cancelable;
    }
    get clipboardData() {
      return dart.dload(this.wrapped, 'clipboardData');
    }
    get currentTarget() {
      return this.wrapped.currentTarget;
    }
    get defaultPrevented() {
      return this.wrapped.defaultPrevented;
    }
    get eventPhase() {
      return this.wrapped.eventPhase;
    }
    get target() {
      return this.wrapped.target;
    }
    get timeStamp() {
      return this.wrapped.timeStamp;
    }
    get type() {
      return this.wrapped.type;
    }
    [_initEvent](eventTypeArg, canBubbleArg, cancelableArg) {
      dart.throw(new core.UnsupportedError('Cannot initialize this Event.'));
    }
    preventDefault() {
      this.wrapped.preventDefault();
    }
    stopImmediatePropagation() {
      this.wrapped.stopImmediatePropagation();
    }
    stopPropagation() {
      this.wrapped.stopPropagation();
    }
    get matchingTarget() {
      if (this[_selector] == null) {
        dart.throw(new core.UnsupportedError('Cannot call matchingTarget if this Event did' + ' not arise as a result of event delegation.'));
      }
      let currentTarget = this.currentTarget;
      let target = this.target;
      let matchedTarget = null;
      do {
        if (dart.notNull(dart.as(dart.dcall(target.matches, this[_selector]), core.bool))) return dart.as(target, Element);
        target = dart.as(dart.dload(target, 'parent'), EventTarget);
      } while (target != null && !dart.equals(target, dart.dload(currentTarget, 'parent')));
      dart.throw(new core.StateError('No selector matched for populating matchedTarget.'));
    }
    get path() {
      return this.wrapped.path;
    }
    get [_get_currentTarget]() {
      return this.wrapped[_get_currentTarget];
    }
    get [_get_target]() {
      return this.wrapped[_get_target];
    }
  }
  _WrappedEvent[dart.implements] = () => [Event];
  dart.setSignature(_WrappedEvent, {
    constructors: () => ({_WrappedEvent: [_WrappedEvent, [Event]]}),
    methods: () => ({
      [_initEvent]: [dart.void, [core.String, core.bool, core.bool]],
      preventDefault: [dart.void, []],
      stopImmediatePropagation: [dart.void, []],
      stopPropagation: [dart.void, []]
    })
  });
  const _shadowKeyCode = Symbol('_shadowKeyCode');
  const _shadowCharCode = Symbol('_shadowCharCode');
  const _shadowAltKey = Symbol('_shadowAltKey');
  const _parent = Symbol('_parent');
  const _realKeyCode = Symbol('_realKeyCode');
  const _realCharCode = Symbol('_realCharCode');
  const _realAltKey = Symbol('_realAltKey');
  const _currentTarget = Symbol('_currentTarget');
  const _shadowKeyIdentifier = Symbol('_shadowKeyIdentifier');
  class KeyEvent extends _WrappedEvent {
    get keyCode() {
      return this[_shadowKeyCode];
    }
    get charCode() {
      return this.type == 'keypress' ? this[_shadowCharCode] : 0;
    }
    get altKey() {
      return this[_shadowAltKey];
    }
    get which() {
      return this.keyCode;
    }
    get [_realKeyCode]() {
      return this[_parent].keyCode;
    }
    get [_realCharCode]() {
      return this[_parent].charCode;
    }
    get [_realAltKey]() {
      return this[_parent].altKey;
    }
    static _makeRecord() {
      let interceptor = _foreign_helper.JS_INTERCEPTOR_CONSTANT(KeyboardEvent);
      return dart.dcall(/* Unimplemented unknown name */makeLeafDispatchRecord, interceptor);
    }
    wrap(parent) {
      this[_parent] = null;
      this[_shadowAltKey] = null;
      this[_shadowCharCode] = null;
      this[_shadowKeyCode] = null;
      this[_currentTarget] = null;
      super._WrappedEvent(parent);
      this[_parent] = parent;
      this[_shadowAltKey] = this[_realAltKey];
      this[_shadowCharCode] = this[_realCharCode];
      this[_shadowKeyCode] = this[_realKeyCode];
      this[_currentTarget] = this[_parent].currentTarget;
    }
    static new(type, opts) {
      let view = opts && 'view' in opts ? opts.view : null;
      let canBubble = opts && 'canBubble' in opts ? opts.canBubble : true;
      let cancelable = opts && 'cancelable' in opts ? opts.cancelable : true;
      let keyCode = opts && 'keyCode' in opts ? opts.keyCode : 0;
      let charCode = opts && 'charCode' in opts ? opts.charCode : 0;
      let keyLocation = opts && 'keyLocation' in opts ? opts.keyLocation : 1;
      let ctrlKey = opts && 'ctrlKey' in opts ? opts.ctrlKey : false;
      let altKey = opts && 'altKey' in opts ? opts.altKey : false;
      let shiftKey = opts && 'shiftKey' in opts ? opts.shiftKey : false;
      let metaKey = opts && 'metaKey' in opts ? opts.metaKey : false;
      let currentTarget = opts && 'currentTarget' in opts ? opts.currentTarget : null;
      if (view == null) {
        view = exports.window;
      }
      let eventObj = null;
      if (dart.notNull(KeyEvent.canUseDispatchEvent)) {
        eventObj = Event.eventType('Event', type, {canBubble: canBubble, cancelable: cancelable});
        eventObj.keyCode = keyCode;
        eventObj.which = keyCode;
        eventObj.charCode = charCode;
        eventObj.keyLocation = keyLocation;
        eventObj.ctrlKey = ctrlKey;
        eventObj.altKey = altKey;
        eventObj.shiftKey = shiftKey;
        eventObj.metaKey = metaKey;
      } else {
        eventObj = Event.eventType('KeyboardEvent', type, {canBubble: canBubble, cancelable: cancelable});
        Object.defineProperty(eventObj, 'keyCode', {
          get: function() {
            return this.keyCodeVal;
          }
        });
        Object.defineProperty(eventObj, 'which', {
          get: function() {
            return this.keyCodeVal;
          }
        });
        Object.defineProperty(eventObj, 'charCode', {
          get: function() {
            return this.charCodeVal;
          }
        });
        let keyIdentifier = KeyEvent._convertToHexString(charCode, keyCode);
        dart.dsend(eventObj, _initKeyboardEvent, type, canBubble, cancelable, view, keyIdentifier, keyLocation, ctrlKey, altKey, shiftKey, metaKey);
        eventObj.keyCodeVal = keyCode;
        eventObj.charCodeVal = charCode;
      }
      dart.dcall(/* Unimplemented unknown name */setDispatchProperty, eventObj, KeyEvent._keyboardEventDispatchRecord);
      let keyEvent = new KeyEvent.wrap(dart.as(eventObj, KeyboardEvent));
      if (keyEvent[_currentTarget] == null) {
        keyEvent[_currentTarget] = currentTarget == null ? exports.window : currentTarget;
      }
      return keyEvent;
    }
    static get canUseDispatchEvent() {
      return typeof document.body.dispatchEvent == "function" && document.body.dispatchEvent.length > 0;
    }
    get currentTarget() {
      return this[_currentTarget];
    }
    static _convertToHexString(charCode, keyCode) {
      if (charCode != -1) {
        let hex = charCode[dartx.toRadixString](16);
        let sb = new core.StringBuffer('U+');
        for (let i = 0; i < 4 - dart.notNull(hex[dartx.length]); i++)
          sb.write('0');
        sb.write(hex);
        return dart.toString(sb);
      } else {
        return KeyCode._convertKeyCodeToKeyName(keyCode);
      }
    }
    get clipboardData() {
      return dart.dload(this[_parent], 'clipboardData');
    }
    get ctrlKey() {
      return this[_parent].ctrlKey;
    }
    get detail() {
      return this[_parent].detail;
    }
    get keyLocation() {
      return this[_parent].keyLocation;
    }
    get layer() {
      return this[_parent].layer;
    }
    get metaKey() {
      return this[_parent].metaKey;
    }
    get page() {
      return this[_parent].page;
    }
    get shiftKey() {
      return this[_parent].shiftKey;
    }
    get view() {
      return dart.as(this[_parent].view, Window);
    }
    [_initUIEvent](type, canBubble, cancelable, view, detail) {
      dart.throw(new core.UnsupportedError("Cannot initialize a UI Event from a KeyEvent."));
    }
    get [_shadowKeyIdentifier]() {
      return this[_parent].keyIdentifier;
    }
    get [_charCode]() {
      return this.charCode;
    }
    get [_keyCode]() {
      return this.keyCode;
    }
    get [_keyIdentifier]() {
      dart.throw(new core.UnsupportedError("keyIdentifier is unsupported."));
    }
    [_initKeyboardEvent](type, canBubble, cancelable, view, keyIdentifier, keyLocation, ctrlKey, altKey, shiftKey, metaKey) {
      dart.throw(new core.UnsupportedError("Cannot initialize a KeyboardEvent from a KeyEvent."));
    }
    get [_layerX]() {
      return dart.throw(new core.UnsupportedError('Not applicable to KeyEvent'));
    }
    get [_layerY]() {
      return dart.throw(new core.UnsupportedError('Not applicable to KeyEvent'));
    }
    get [_pageX]() {
      return dart.throw(new core.UnsupportedError('Not applicable to KeyEvent'));
    }
    get [_pageY]() {
      return dart.throw(new core.UnsupportedError('Not applicable to KeyEvent'));
    }
    getModifierState(keyArgument) {
      return dart.throw(new core.UnimplementedError());
    }
    get location() {
      return dart.throw(new core.UnimplementedError());
    }
    get repeat() {
      return dart.throw(new core.UnimplementedError());
    }
    get [_get_view]() {
      return dart.throw(new core.UnimplementedError());
    }
  }
  KeyEvent[dart.implements] = () => [KeyboardEvent];
  dart.defineNamedConstructor(KeyEvent, 'wrap');
  dart.setSignature(KeyEvent, {
    constructors: () => ({
      wrap: [KeyEvent, [KeyboardEvent]],
      new: [KeyEvent, [core.String], {view: Window, canBubble: core.bool, cancelable: core.bool, keyCode: core.int, charCode: core.int, keyLocation: core.int, ctrlKey: core.bool, altKey: core.bool, shiftKey: core.bool, metaKey: core.bool, currentTarget: EventTarget}]
    }),
    methods: () => ({
      [_initUIEvent]: [dart.void, [core.String, core.bool, core.bool, Window, core.int]],
      [_initKeyboardEvent]: [dart.void, [core.String, core.bool, core.bool, Window, core.String, core.int, core.bool, core.bool, core.bool, core.bool]],
      getModifierState: [core.bool, [core.String]]
    }),
    statics: () => ({
      _makeRecord: [dart.dynamic, []],
      _convertToHexString: [core.String, [core.int, core.int]]
    }),
    names: ['_makeRecord', '_convertToHexString']
  });
  KeyEvent[dart.metadata] = () => [dart.const(new _metadata.Experimental())];
  dart.defineLazyProperties(KeyEvent, {
    get _keyboardEventDispatchRecord() {
      return KeyEvent._makeRecord();
    },
    get keyDownEvent() {
      return new _KeyboardEventHandler('keydown');
    },
    set keyDownEvent(_) {},
    get keyUpEvent() {
      return new _KeyboardEventHandler('keyup');
    },
    set keyUpEvent(_) {},
    get keyPressEvent() {
      return new _KeyboardEventHandler('keypress');
    },
    set keyPressEvent(_) {}
  });
  class _CustomKeyEventStreamImpl extends _CustomEventStreamImpl$(KeyEvent) {
    _CustomKeyEventStreamImpl(type) {
      super._CustomEventStreamImpl(type);
    }
    add(event) {
      if (event.type == this[_type]) {
        event.currentTarget.dispatchEvent(event[_parent]);
        this[_streamController].add(event);
      }
    }
  }
  _CustomKeyEventStreamImpl[dart.implements] = () => [CustomStream$(KeyEvent)];
  dart.setSignature(_CustomKeyEventStreamImpl, {
    constructors: () => ({_CustomKeyEventStreamImpl: [_CustomKeyEventStreamImpl, [core.String]]}),
    methods: () => ({add: [dart.void, [KeyEvent]]})
  });
  const _subscriptions = Symbol('_subscriptions');
  const _controller = Symbol('_controller');
  const _StreamPool$ = dart.generic(function(T) {
    class _StreamPool extends core.Object {
      broadcast() {
        this[_subscriptions] = core.Map$(async.Stream$(T), async.StreamSubscription$(T)).new();
        this[_controller] = null;
        this[_controller] = async.StreamController$(T).broadcast({sync: true, onCancel: dart.bind(this, 'close')});
      }
      get stream() {
        return this[_controller].stream;
      }
      add(stream) {
        dart.as(stream, async.Stream$(T));
        if (dart.notNull(this[_subscriptions].containsKey(stream))) return;
        this[_subscriptions].set(stream, stream.listen(dart.bind(this[_controller], 'add'), {onError: dart.bind(this[_controller], 'addError'), onDone: dart.fn(() => this.remove(stream), dart.void, [])}));
      }
      remove(stream) {
        dart.as(stream, async.Stream$(T));
        let subscription = this[_subscriptions].remove(stream);
        if (subscription != null) subscription.cancel();
      }
      close() {
        for (let subscription of this[_subscriptions].values) {
          subscription.cancel();
        }
        this[_subscriptions].clear();
        this[_controller].close();
      }
    }
    dart.defineNamedConstructor(_StreamPool, 'broadcast');
    dart.setSignature(_StreamPool, {
      constructors: () => ({broadcast: [_StreamPool$(T), []]}),
      methods: () => ({
        add: [dart.void, [async.Stream$(T)]],
        remove: [dart.void, [async.Stream$(T)]],
        close: [dart.void, []]
      })
    });
    return _StreamPool;
  });
  let _StreamPool = _StreamPool$();
  const _eventTypeGetter = Symbol('_eventTypeGetter');
  const _CustomEventStreamProvider$ = dart.generic(function(T) {
    class _CustomEventStreamProvider extends core.Object {
      _CustomEventStreamProvider(eventTypeGetter) {
        this[_eventTypeGetter] = eventTypeGetter;
      }
      forTarget(e, opts) {
        let useCapture = opts && 'useCapture' in opts ? opts.useCapture : false;
        return new (_EventStream$(T))(e, dart.as(dart.dcall(this[_eventTypeGetter], e), core.String), useCapture);
      }
      forElement(e, opts) {
        let useCapture = opts && 'useCapture' in opts ? opts.useCapture : false;
        return new (_ElementEventStreamImpl$(T))(e, dart.dcall(this[_eventTypeGetter], e), useCapture);
      }
      [_forElementList](e, opts) {
        let useCapture = opts && 'useCapture' in opts ? opts.useCapture : false;
        return new (_ElementListEventStreamImpl$(T))(dart.as(e, core.Iterable$(Element)), dart.as(dart.dcall(this[_eventTypeGetter], e), core.String), useCapture);
      }
      getEventType(target) {
        return dart.as(dart.dcall(this[_eventTypeGetter], target), core.String);
      }
      get [_eventType]() {
        return dart.throw(new core.UnsupportedError('Access type through getEventType method.'));
      }
    }
    _CustomEventStreamProvider[dart.implements] = () => [EventStreamProvider$(T)];
    dart.setSignature(_CustomEventStreamProvider, {
      constructors: () => ({_CustomEventStreamProvider: [_CustomEventStreamProvider$(T), [dart.dynamic]]}),
      methods: () => ({
        forTarget: [async.Stream$(T), [EventTarget], {useCapture: core.bool}],
        forElement: [ElementStream$(T), [Element], {useCapture: core.bool}],
        [_forElementList]: [ElementStream$(T), [ElementList], {useCapture: core.bool}],
        getEventType: [core.String, [EventTarget]]
      })
    });
    return _CustomEventStreamProvider;
  });
  let _CustomEventStreamProvider = _CustomEventStreamProvider$();
  class _Html5NodeValidator extends core.Object {
    _Html5NodeValidator(opts) {
      let uriPolicy = opts && 'uriPolicy' in opts ? opts.uriPolicy : null;
      this.uriPolicy = uriPolicy != null ? uriPolicy : UriPolicy.new();
      if (dart.notNull(_Html5NodeValidator._attributeValidators.isEmpty)) {
        for (let attr of _Html5NodeValidator._standardAttributes) {
          _Html5NodeValidator._attributeValidators.set(attr, _Html5NodeValidator._standardAttributeValidator);
        }
        for (let attr of _Html5NodeValidator._uriAttributes) {
          _Html5NodeValidator._attributeValidators.set(attr, _Html5NodeValidator._uriAttributeValidator);
        }
      }
    }
    allowsElement(element) {
      return _Html5NodeValidator._allowedElements.contains(Element._safeTagName(element));
    }
    allowsAttribute(element, attributeName, value) {
      let tagName = Element._safeTagName(element);
      let validator = _Html5NodeValidator._attributeValidators.get(`${tagName}::${attributeName}`);
      if (validator == null) {
        validator = _Html5NodeValidator._attributeValidators.get(`*::${attributeName}`);
      }
      if (validator == null) {
        return false;
      }
      return dart.as(dart.dcall(validator, element, attributeName, value, this), core.bool);
    }
    static _standardAttributeValidator(element, attributeName, value, context) {
      return true;
    }
    static _uriAttributeValidator(element, attributeName, value, context) {
      return context.uriPolicy.allowsUri(value);
    }
  }
  _Html5NodeValidator[dart.implements] = () => [NodeValidator];
  dart.setSignature(_Html5NodeValidator, {
    constructors: () => ({_Html5NodeValidator: [_Html5NodeValidator, [], {uriPolicy: UriPolicy}]}),
    methods: () => ({
      allowsElement: [core.bool, [Element]],
      allowsAttribute: [core.bool, [Element, core.String, core.String]]
    }),
    statics: () => ({
      _standardAttributeValidator: [core.bool, [Element, core.String, core.String, _Html5NodeValidator]],
      _uriAttributeValidator: [core.bool, [Element, core.String, core.String, _Html5NodeValidator]]
    }),
    names: ['_standardAttributeValidator', '_uriAttributeValidator']
  });
  _Html5NodeValidator._standardAttributes = dart.const(dart.list(['*::class', '*::dir', '*::draggable', '*::hidden', '*::id', '*::inert', '*::itemprop', '*::itemref', '*::itemscope', '*::lang', '*::spellcheck', '*::title', '*::translate', 'A::accesskey', 'A::coords', 'A::hreflang', 'A::name', 'A::shape', 'A::tabindex', 'A::target', 'A::type', 'AREA::accesskey', 'AREA::alt', 'AREA::coords', 'AREA::nohref', 'AREA::shape', 'AREA::tabindex', 'AREA::target', 'AUDIO::controls', 'AUDIO::loop', 'AUDIO::mediagroup', 'AUDIO::muted', 'AUDIO::preload', 'BDO::dir', 'BODY::alink', 'BODY::bgcolor', 'BODY::link', 'BODY::text', 'BODY::vlink', 'BR::clear', 'BUTTON::accesskey', 'BUTTON::disabled', 'BUTTON::name', 'BUTTON::tabindex', 'BUTTON::type', 'BUTTON::value', 'CANVAS::height', 'CANVAS::width', 'CAPTION::align', 'COL::align', 'COL::char', 'COL::charoff', 'COL::span', 'COL::valign', 'COL::width', 'COLGROUP::align', 'COLGROUP::char', 'COLGROUP::charoff', 'COLGROUP::span', 'COLGROUP::valign', 'COLGROUP::width', 'COMMAND::checked', 'COMMAND::command', 'COMMAND::disabled', 'COMMAND::label', 'COMMAND::radiogroup', 'COMMAND::type', 'DATA::value', 'DEL::datetime', 'DETAILS::open', 'DIR::compact', 'DIV::align', 'DL::compact', 'FIELDSET::disabled', 'FONT::color', 'FONT::face', 'FONT::size', 'FORM::accept', 'FORM::autocomplete', 'FORM::enctype', 'FORM::method', 'FORM::name', 'FORM::novalidate', 'FORM::target', 'FRAME::name', 'H1::align', 'H2::align', 'H3::align', 'H4::align', 'H5::align', 'H6::align', 'HR::align', 'HR::noshade', 'HR::size', 'HR::width', 'HTML::version', 'IFRAME::align', 'IFRAME::frameborder', 'IFRAME::height', 'IFRAME::marginheight', 'IFRAME::marginwidth', 'IFRAME::width', 'IMG::align', 'IMG::alt', 'IMG::border', 'IMG::height', 'IMG::hspace', 'IMG::ismap', 'IMG::name', 'IMG::usemap', 'IMG::vspace', 'IMG::width', 'INPUT::accept', 'INPUT::accesskey', 'INPUT::align', 'INPUT::alt', 'INPUT::autocomplete', 'INPUT::checked', 'INPUT::disabled', 'INPUT::inputmode', 'INPUT::ismap', 'INPUT::list', 'INPUT::max', 'INPUT::maxlength', 'INPUT::min', 'INPUT::multiple', 'INPUT::name', 'INPUT::placeholder', 'INPUT::readonly', 'INPUT::required', 'INPUT::size', 'INPUT::step', 'INPUT::tabindex', 'INPUT::type', 'INPUT::usemap', 'INPUT::value', 'INS::datetime', 'KEYGEN::disabled', 'KEYGEN::keytype', 'KEYGEN::name', 'LABEL::accesskey', 'LABEL::for', 'LEGEND::accesskey', 'LEGEND::align', 'LI::type', 'LI::value', 'LINK::sizes', 'MAP::name', 'MENU::compact', 'MENU::label', 'MENU::type', 'METER::high', 'METER::low', 'METER::max', 'METER::min', 'METER::value', 'OBJECT::typemustmatch', 'OL::compact', 'OL::reversed', 'OL::start', 'OL::type', 'OPTGROUP::disabled', 'OPTGROUP::label', 'OPTION::disabled', 'OPTION::label', 'OPTION::selected', 'OPTION::value', 'OUTPUT::for', 'OUTPUT::name', 'P::align', 'PRE::width', 'PROGRESS::max', 'PROGRESS::min', 'PROGRESS::value', 'SELECT::autocomplete', 'SELECT::disabled', 'SELECT::multiple', 'SELECT::name', 'SELECT::required', 'SELECT::size', 'SELECT::tabindex', 'SOURCE::type', 'TABLE::align', 'TABLE::bgcolor', 'TABLE::border', 'TABLE::cellpadding', 'TABLE::cellspacing', 'TABLE::frame', 'TABLE::rules', 'TABLE::summary', 'TABLE::width', 'TBODY::align', 'TBODY::char', 'TBODY::charoff', 'TBODY::valign', 'TD::abbr', 'TD::align', 'TD::axis', 'TD::bgcolor', 'TD::char', 'TD::charoff', 'TD::colspan', 'TD::headers', 'TD::height', 'TD::nowrap', 'TD::rowspan', 'TD::scope', 'TD::valign', 'TD::width', 'TEXTAREA::accesskey', 'TEXTAREA::autocomplete', 'TEXTAREA::cols', 'TEXTAREA::disabled', 'TEXTAREA::inputmode', 'TEXTAREA::name', 'TEXTAREA::placeholder', 'TEXTAREA::readonly', 'TEXTAREA::required', 'TEXTAREA::rows', 'TEXTAREA::tabindex', 'TEXTAREA::wrap', 'TFOOT::align', 'TFOOT::char', 'TFOOT::charoff', 'TFOOT::valign', 'TH::abbr', 'TH::align', 'TH::axis', 'TH::bgcolor', 'TH::char', 'TH::charoff', 'TH::colspan', 'TH::headers', 'TH::height', 'TH::nowrap', 'TH::rowspan', 'TH::scope', 'TH::valign', 'TH::width', 'THEAD::align', 'THEAD::char', 'THEAD::charoff', 'THEAD::valign', 'TR::align', 'TR::bgcolor', 'TR::char', 'TR::charoff', 'TR::valign', 'TRACK::default', 'TRACK::kind', 'TRACK::label', 'TRACK::srclang', 'UL::compact', 'UL::type', 'VIDEO::controls', 'VIDEO::height', 'VIDEO::loop', 'VIDEO::mediagroup', 'VIDEO::muted', 'VIDEO::preload', 'VIDEO::width'], core.String));
  _Html5NodeValidator._uriAttributes = dart.const(dart.list(['A::href', 'AREA::href', 'BLOCKQUOTE::cite', 'BODY::background', 'COMMAND::icon', 'DEL::cite', 'FORM::action', 'IMG::src', 'INPUT::src', 'INS::cite', 'Q::cite', 'VIDEO::poster'], core.String));
  dart.defineLazyProperties(_Html5NodeValidator, {
    get _allowedElements() {
      return core.Set$(core.String).from(dart.list(['A', 'ABBR', 'ACRONYM', 'ADDRESS', 'AREA', 'ARTICLE', 'ASIDE', 'AUDIO', 'B', 'BDI', 'BDO', 'BIG', 'BLOCKQUOTE', 'BR', 'BUTTON', 'CANVAS', 'CAPTION', 'CENTER', 'CITE', 'CODE', 'COL', 'COLGROUP', 'COMMAND', 'DATA', 'DATALIST', 'DD', 'DEL', 'DETAILS', 'DFN', 'DIR', 'DIV', 'DL', 'DT', 'EM', 'FIELDSET', 'FIGCAPTION', 'FIGURE', 'FONT', 'FOOTER', 'FORM', 'H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'HEADER', 'HGROUP', 'HR', 'I', 'IFRAME', 'IMG', 'INPUT', 'INS', 'KBD', 'LABEL', 'LEGEND', 'LI', 'MAP', 'MARK', 'MENU', 'METER', 'NAV', 'NOBR', 'OL', 'OPTGROUP', 'OPTION', 'OUTPUT', 'P', 'PRE', 'PROGRESS', 'Q', 'S', 'SAMP', 'SECTION', 'SELECT', 'SMALL', 'SOURCE', 'SPAN', 'STRIKE', 'STRONG', 'SUB', 'SUMMARY', 'SUP', 'TABLE', 'TBODY', 'TD', 'TEXTAREA', 'TFOOT', 'TH', 'THEAD', 'TIME', 'TR', 'TRACK', 'TT', 'U', 'UL', 'VAR', 'VIDEO', 'WBR'], core.String));
    },
    get _attributeValidators() {
      return dart.map();
    }
  });
  class KeyCode extends core.Object {
    static isCharacterKey(keyCode) {
      if (dart.notNull(keyCode) >= dart.notNull(KeyCode.ZERO) && dart.notNull(keyCode) <= dart.notNull(KeyCode.NINE) || dart.notNull(keyCode) >= dart.notNull(KeyCode.NUM_ZERO) && dart.notNull(keyCode) <= dart.notNull(KeyCode.NUM_MULTIPLY) || dart.notNull(keyCode) >= dart.notNull(KeyCode.A) && dart.notNull(keyCode) <= dart.notNull(KeyCode.Z)) {
        return true;
      }
      if (dart.notNull(html_common.Device.isWebKit) && keyCode == 0) {
        return true;
      }
      return keyCode == KeyCode.SPACE || keyCode == KeyCode.QUESTION_MARK || keyCode == KeyCode.NUM_PLUS || keyCode == KeyCode.NUM_MINUS || keyCode == KeyCode.NUM_PERIOD || keyCode == KeyCode.NUM_DIVISION || keyCode == KeyCode.SEMICOLON || keyCode == KeyCode.FF_SEMICOLON || keyCode == KeyCode.DASH || keyCode == KeyCode.EQUALS || keyCode == KeyCode.FF_EQUALS || keyCode == KeyCode.COMMA || keyCode == KeyCode.PERIOD || keyCode == KeyCode.SLASH || keyCode == KeyCode.APOSTROPHE || keyCode == KeyCode.SINGLE_QUOTE || keyCode == KeyCode.OPEN_SQUARE_BRACKET || keyCode == KeyCode.BACKSLASH || keyCode == KeyCode.CLOSE_SQUARE_BRACKET;
    }
    static _convertKeyCodeToKeyName(keyCode) {
      switch (keyCode) {
        case KeyCode.ALT:
        {
          return _KeyName.ALT;
        }
        case KeyCode.BACKSPACE:
        {
          return _KeyName.BACKSPACE;
        }
        case KeyCode.CAPS_LOCK:
        {
          return _KeyName.CAPS_LOCK;
        }
        case KeyCode.CTRL:
        {
          return _KeyName.CONTROL;
        }
        case KeyCode.DELETE:
        {
          return _KeyName.DEL;
        }
        case KeyCode.DOWN:
        {
          return _KeyName.DOWN;
        }
        case KeyCode.END:
        {
          return _KeyName.END;
        }
        case KeyCode.ENTER:
        {
          return _KeyName.ENTER;
        }
        case KeyCode.ESC:
        {
          return _KeyName.ESC;
        }
        case KeyCode.F1:
        {
          return _KeyName.F1;
        }
        case KeyCode.F2:
        {
          return _KeyName.F2;
        }
        case KeyCode.F3:
        {
          return _KeyName.F3;
        }
        case KeyCode.F4:
        {
          return _KeyName.F4;
        }
        case KeyCode.F5:
        {
          return _KeyName.F5;
        }
        case KeyCode.F6:
        {
          return _KeyName.F6;
        }
        case KeyCode.F7:
        {
          return _KeyName.F7;
        }
        case KeyCode.F8:
        {
          return _KeyName.F8;
        }
        case KeyCode.F9:
        {
          return _KeyName.F9;
        }
        case KeyCode.F10:
        {
          return _KeyName.F10;
        }
        case KeyCode.F11:
        {
          return _KeyName.F11;
        }
        case KeyCode.F12:
        {
          return _KeyName.F12;
        }
        case KeyCode.HOME:
        {
          return _KeyName.HOME;
        }
        case KeyCode.INSERT:
        {
          return _KeyName.INSERT;
        }
        case KeyCode.LEFT:
        {
          return _KeyName.LEFT;
        }
        case KeyCode.META:
        {
          return _KeyName.META;
        }
        case KeyCode.NUMLOCK:
        {
          return _KeyName.NUM_LOCK;
        }
        case KeyCode.PAGE_DOWN:
        {
          return _KeyName.PAGE_DOWN;
        }
        case KeyCode.PAGE_UP:
        {
          return _KeyName.PAGE_UP;
        }
        case KeyCode.PAUSE:
        {
          return _KeyName.PAUSE;
        }
        case KeyCode.PRINT_SCREEN:
        {
          return _KeyName.PRINT_SCREEN;
        }
        case KeyCode.RIGHT:
        {
          return _KeyName.RIGHT;
        }
        case KeyCode.SCROLL_LOCK:
        {
          return _KeyName.SCROLL;
        }
        case KeyCode.SHIFT:
        {
          return _KeyName.SHIFT;
        }
        case KeyCode.SPACE:
        {
          return _KeyName.SPACEBAR;
        }
        case KeyCode.TAB:
        {
          return _KeyName.TAB;
        }
        case KeyCode.UP:
        {
          return _KeyName.UP;
        }
        case KeyCode.WIN_IME:
        case KeyCode.WIN_KEY:
        case KeyCode.WIN_KEY_LEFT:
        case KeyCode.WIN_KEY_RIGHT:
        {
          return _KeyName.WIN;
        }
        default:
        {
          return _KeyName.UNIDENTIFIED;
        }
      }
      return _KeyName.UNIDENTIFIED;
    }
  }
  dart.setSignature(KeyCode, {
    statics: () => ({
      isCharacterKey: [core.bool, [core.int]],
      _convertKeyCodeToKeyName: [core.String, [core.int]]
    }),
    names: ['isCharacterKey', '_convertKeyCodeToKeyName']
  });
  KeyCode.WIN_KEY_FF_LINUX = 0;
  KeyCode.MAC_ENTER = 3;
  KeyCode.BACKSPACE = 8;
  KeyCode.TAB = 9;
  KeyCode.NUM_CENTER = 12;
  KeyCode.ENTER = 13;
  KeyCode.SHIFT = 16;
  KeyCode.CTRL = 17;
  KeyCode.ALT = 18;
  KeyCode.PAUSE = 19;
  KeyCode.CAPS_LOCK = 20;
  KeyCode.ESC = 27;
  KeyCode.SPACE = 32;
  KeyCode.PAGE_UP = 33;
  KeyCode.PAGE_DOWN = 34;
  KeyCode.END = 35;
  KeyCode.HOME = 36;
  KeyCode.LEFT = 37;
  KeyCode.UP = 38;
  KeyCode.RIGHT = 39;
  KeyCode.DOWN = 40;
  KeyCode.NUM_NORTH_EAST = 33;
  KeyCode.NUM_SOUTH_EAST = 34;
  KeyCode.NUM_SOUTH_WEST = 35;
  KeyCode.NUM_NORTH_WEST = 36;
  KeyCode.NUM_WEST = 37;
  KeyCode.NUM_NORTH = 38;
  KeyCode.NUM_EAST = 39;
  KeyCode.NUM_SOUTH = 40;
  KeyCode.PRINT_SCREEN = 44;
  KeyCode.INSERT = 45;
  KeyCode.NUM_INSERT = 45;
  KeyCode.DELETE = 46;
  KeyCode.NUM_DELETE = 46;
  KeyCode.ZERO = 48;
  KeyCode.ONE = 49;
  KeyCode.TWO = 50;
  KeyCode.THREE = 51;
  KeyCode.FOUR = 52;
  KeyCode.FIVE = 53;
  KeyCode.SIX = 54;
  KeyCode.SEVEN = 55;
  KeyCode.EIGHT = 56;
  KeyCode.NINE = 57;
  KeyCode.FF_SEMICOLON = 59;
  KeyCode.FF_EQUALS = 61;
  KeyCode.QUESTION_MARK = 63;
  KeyCode.A = 65;
  KeyCode.B = 66;
  KeyCode.C = 67;
  KeyCode.D = 68;
  KeyCode.E = 69;
  KeyCode.F = 70;
  KeyCode.G = 71;
  KeyCode.H = 72;
  KeyCode.I = 73;
  KeyCode.J = 74;
  KeyCode.K = 75;
  KeyCode.L = 76;
  KeyCode.M = 77;
  KeyCode.N = 78;
  KeyCode.O = 79;
  KeyCode.P = 80;
  KeyCode.Q = 81;
  KeyCode.R = 82;
  KeyCode.S = 83;
  KeyCode.T = 84;
  KeyCode.U = 85;
  KeyCode.V = 86;
  KeyCode.W = 87;
  KeyCode.X = 88;
  KeyCode.Y = 89;
  KeyCode.Z = 90;
  KeyCode.META = 91;
  KeyCode.WIN_KEY_LEFT = 91;
  KeyCode.WIN_KEY_RIGHT = 92;
  KeyCode.CONTEXT_MENU = 93;
  KeyCode.NUM_ZERO = 96;
  KeyCode.NUM_ONE = 97;
  KeyCode.NUM_TWO = 98;
  KeyCode.NUM_THREE = 99;
  KeyCode.NUM_FOUR = 100;
  KeyCode.NUM_FIVE = 101;
  KeyCode.NUM_SIX = 102;
  KeyCode.NUM_SEVEN = 103;
  KeyCode.NUM_EIGHT = 104;
  KeyCode.NUM_NINE = 105;
  KeyCode.NUM_MULTIPLY = 106;
  KeyCode.NUM_PLUS = 107;
  KeyCode.NUM_MINUS = 109;
  KeyCode.NUM_PERIOD = 110;
  KeyCode.NUM_DIVISION = 111;
  KeyCode.F1 = 112;
  KeyCode.F2 = 113;
  KeyCode.F3 = 114;
  KeyCode.F4 = 115;
  KeyCode.F5 = 116;
  KeyCode.F6 = 117;
  KeyCode.F7 = 118;
  KeyCode.F8 = 119;
  KeyCode.F9 = 120;
  KeyCode.F10 = 121;
  KeyCode.F11 = 122;
  KeyCode.F12 = 123;
  KeyCode.NUMLOCK = 144;
  KeyCode.SCROLL_LOCK = 145;
  KeyCode.FIRST_MEDIA_KEY = 166;
  KeyCode.LAST_MEDIA_KEY = 183;
  KeyCode.SEMICOLON = 186;
  KeyCode.DASH = 189;
  KeyCode.EQUALS = 187;
  KeyCode.COMMA = 188;
  KeyCode.PERIOD = 190;
  KeyCode.SLASH = 191;
  KeyCode.APOSTROPHE = 192;
  KeyCode.TILDE = 192;
  KeyCode.SINGLE_QUOTE = 222;
  KeyCode.OPEN_SQUARE_BRACKET = 219;
  KeyCode.BACKSLASH = 220;
  KeyCode.CLOSE_SQUARE_BRACKET = 221;
  KeyCode.WIN_KEY = 224;
  KeyCode.MAC_FF_META = 224;
  KeyCode.WIN_IME = 229;
  KeyCode.UNKNOWN = -1;
  class KeyLocation extends core.Object {}
  KeyLocation.STANDARD = 0;
  KeyLocation.LEFT = 1;
  KeyLocation.RIGHT = 2;
  KeyLocation.NUMPAD = 3;
  KeyLocation.MOBILE = 4;
  KeyLocation.JOYSTICK = 5;
  class _KeyName extends core.Object {}
  _KeyName.ACCEPT = "Accept";
  _KeyName.ADD = "Add";
  _KeyName.AGAIN = "Again";
  _KeyName.ALL_CANDIDATES = "AllCandidates";
  _KeyName.ALPHANUMERIC = "Alphanumeric";
  _KeyName.ALT = "Alt";
  _KeyName.ALT_GRAPH = "AltGraph";
  _KeyName.APPS = "Apps";
  _KeyName.ATTN = "Attn";
  _KeyName.BROWSER_BACK = "BrowserBack";
  _KeyName.BROWSER_FAVORTIES = "BrowserFavorites";
  _KeyName.BROWSER_FORWARD = "BrowserForward";
  _KeyName.BROWSER_NAME = "BrowserHome";
  _KeyName.BROWSER_REFRESH = "BrowserRefresh";
  _KeyName.BROWSER_SEARCH = "BrowserSearch";
  _KeyName.BROWSER_STOP = "BrowserStop";
  _KeyName.CAMERA = "Camera";
  _KeyName.CAPS_LOCK = "CapsLock";
  _KeyName.CLEAR = "Clear";
  _KeyName.CODE_INPUT = "CodeInput";
  _KeyName.COMPOSE = "Compose";
  _KeyName.CONTROL = "Control";
  _KeyName.CRSEL = "Crsel";
  _KeyName.CONVERT = "Convert";
  _KeyName.COPY = "Copy";
  _KeyName.CUT = "Cut";
  _KeyName.DECIMAL = "Decimal";
  _KeyName.DIVIDE = "Divide";
  _KeyName.DOWN = "Down";
  _KeyName.DOWN_LEFT = "DownLeft";
  _KeyName.DOWN_RIGHT = "DownRight";
  _KeyName.EJECT = "Eject";
  _KeyName.END = "End";
  _KeyName.ENTER = "Enter";
  _KeyName.ERASE_EOF = "EraseEof";
  _KeyName.EXECUTE = "Execute";
  _KeyName.EXSEL = "Exsel";
  _KeyName.FN = "Fn";
  _KeyName.F1 = "F1";
  _KeyName.F2 = "F2";
  _KeyName.F3 = "F3";
  _KeyName.F4 = "F4";
  _KeyName.F5 = "F5";
  _KeyName.F6 = "F6";
  _KeyName.F7 = "F7";
  _KeyName.F8 = "F8";
  _KeyName.F9 = "F9";
  _KeyName.F10 = "F10";
  _KeyName.F11 = "F11";
  _KeyName.F12 = "F12";
  _KeyName.F13 = "F13";
  _KeyName.F14 = "F14";
  _KeyName.F15 = "F15";
  _KeyName.F16 = "F16";
  _KeyName.F17 = "F17";
  _KeyName.F18 = "F18";
  _KeyName.F19 = "F19";
  _KeyName.F20 = "F20";
  _KeyName.F21 = "F21";
  _KeyName.F22 = "F22";
  _KeyName.F23 = "F23";
  _KeyName.F24 = "F24";
  _KeyName.FINAL_MODE = "FinalMode";
  _KeyName.FIND = "Find";
  _KeyName.FULL_WIDTH = "FullWidth";
  _KeyName.HALF_WIDTH = "HalfWidth";
  _KeyName.HANGUL_MODE = "HangulMode";
  _KeyName.HANJA_MODE = "HanjaMode";
  _KeyName.HELP = "Help";
  _KeyName.HIRAGANA = "Hiragana";
  _KeyName.HOME = "Home";
  _KeyName.INSERT = "Insert";
  _KeyName.JAPANESE_HIRAGANA = "JapaneseHiragana";
  _KeyName.JAPANESE_KATAKANA = "JapaneseKatakana";
  _KeyName.JAPANESE_ROMAJI = "JapaneseRomaji";
  _KeyName.JUNJA_MODE = "JunjaMode";
  _KeyName.KANA_MODE = "KanaMode";
  _KeyName.KANJI_MODE = "KanjiMode";
  _KeyName.KATAKANA = "Katakana";
  _KeyName.LAUNCH_APPLICATION_1 = "LaunchApplication1";
  _KeyName.LAUNCH_APPLICATION_2 = "LaunchApplication2";
  _KeyName.LAUNCH_MAIL = "LaunchMail";
  _KeyName.LEFT = "Left";
  _KeyName.MENU = "Menu";
  _KeyName.META = "Meta";
  _KeyName.MEDIA_NEXT_TRACK = "MediaNextTrack";
  _KeyName.MEDIA_PAUSE_PLAY = "MediaPlayPause";
  _KeyName.MEDIA_PREVIOUS_TRACK = "MediaPreviousTrack";
  _KeyName.MEDIA_STOP = "MediaStop";
  _KeyName.MODE_CHANGE = "ModeChange";
  _KeyName.NEXT_CANDIDATE = "NextCandidate";
  _KeyName.NON_CONVERT = "Nonconvert";
  _KeyName.NUM_LOCK = "NumLock";
  _KeyName.PAGE_DOWN = "PageDown";
  _KeyName.PAGE_UP = "PageUp";
  _KeyName.PASTE = "Paste";
  _KeyName.PAUSE = "Pause";
  _KeyName.PLAY = "Play";
  _KeyName.POWER = "Power";
  _KeyName.PREVIOUS_CANDIDATE = "PreviousCandidate";
  _KeyName.PRINT_SCREEN = "PrintScreen";
  _KeyName.PROCESS = "Process";
  _KeyName.PROPS = "Props";
  _KeyName.RIGHT = "Right";
  _KeyName.ROMAN_CHARACTERS = "RomanCharacters";
  _KeyName.SCROLL = "Scroll";
  _KeyName.SELECT = "Select";
  _KeyName.SELECT_MEDIA = "SelectMedia";
  _KeyName.SEPARATOR = "Separator";
  _KeyName.SHIFT = "Shift";
  _KeyName.SOFT_1 = "Soft1";
  _KeyName.SOFT_2 = "Soft2";
  _KeyName.SOFT_3 = "Soft3";
  _KeyName.SOFT_4 = "Soft4";
  _KeyName.STOP = "Stop";
  _KeyName.SUBTRACT = "Subtract";
  _KeyName.SYMBOL_LOCK = "SymbolLock";
  _KeyName.UP = "Up";
  _KeyName.UP_LEFT = "UpLeft";
  _KeyName.UP_RIGHT = "UpRight";
  _KeyName.UNDO = "Undo";
  _KeyName.VOLUME_DOWN = "VolumeDown";
  _KeyName.VOLUMN_MUTE = "VolumeMute";
  _KeyName.VOLUMN_UP = "VolumeUp";
  _KeyName.WIN = "Win";
  _KeyName.ZOOM = "Zoom";
  _KeyName.BACKSPACE = "Backspace";
  _KeyName.TAB = "Tab";
  _KeyName.CANCEL = "Cancel";
  _KeyName.ESC = "Esc";
  _KeyName.SPACEBAR = "Spacebar";
  _KeyName.DEL = "Del";
  _KeyName.DEAD_GRAVE = "DeadGrave";
  _KeyName.DEAD_EACUTE = "DeadEacute";
  _KeyName.DEAD_CIRCUMFLEX = "DeadCircumflex";
  _KeyName.DEAD_TILDE = "DeadTilde";
  _KeyName.DEAD_MACRON = "DeadMacron";
  _KeyName.DEAD_BREVE = "DeadBreve";
  _KeyName.DEAD_ABOVE_DOT = "DeadAboveDot";
  _KeyName.DEAD_UMLAUT = "DeadUmlaut";
  _KeyName.DEAD_ABOVE_RING = "DeadAboveRing";
  _KeyName.DEAD_DOUBLEACUTE = "DeadDoubleacute";
  _KeyName.DEAD_CARON = "DeadCaron";
  _KeyName.DEAD_CEDILLA = "DeadCedilla";
  _KeyName.DEAD_OGONEK = "DeadOgonek";
  _KeyName.DEAD_IOTA = "DeadIota";
  _KeyName.DEAD_VOICED_SOUND = "DeadVoicedSound";
  _KeyName.DEC_SEMIVOICED_SOUND = "DeadSemivoicedSound";
  _KeyName.UNIDENTIFIED = "Unidentified";
  const _stream = Symbol('_stream');
  const _keyDownList = Symbol('_keyDownList');
  const _capsLockOn = Symbol('_capsLockOn');
  const _determineKeyCodeForKeypress = Symbol('_determineKeyCodeForKeypress');
  const _findCharCodeKeyDown = Symbol('_findCharCodeKeyDown');
  const _firesKeyPressEvent = Symbol('_firesKeyPressEvent');
  const _normalizeKeyCodes = Symbol('_normalizeKeyCodes');
  class _KeyboardEventHandler extends EventStreamProvider$(KeyEvent) {
    forTarget(e, opts) {
      let useCapture = opts && 'useCapture' in opts ? opts.useCapture : false;
      let handler = new _KeyboardEventHandler.initializeAllEventListeners(this[_type], e);
      return handler[_stream];
    }
    _KeyboardEventHandler(type) {
      this[_keyDownList] = dart.list([], KeyEvent);
      this[_type] = type;
      this[_stream] = new _CustomKeyEventStreamImpl('event');
      this[_target] = null;
      super.EventStreamProvider(_KeyboardEventHandler._EVENT_TYPE);
    }
    initializeAllEventListeners(type, target) {
      this[_keyDownList] = dart.list([], KeyEvent);
      this[_type] = type;
      this[_target] = target;
      this[_stream] = null;
      super.EventStreamProvider(_KeyboardEventHandler._EVENT_TYPE);
      dart.throw('Key event handling not supported in DDC');
    }
    get [_capsLockOn]() {
      return this[_keyDownList][dartx.any](dart.fn(element => element.keyCode == KeyCode.CAPS_LOCK, core.bool, [KeyEvent]));
    }
    [_determineKeyCodeForKeypress](event) {
      for (let prevEvent of this[_keyDownList]) {
        if (prevEvent[_shadowCharCode] == event.charCode) {
          return prevEvent.keyCode;
        }
        if ((dart.notNull(event.shiftKey) || dart.notNull(this[_capsLockOn])) && dart.notNull(event.charCode) >= dart.notNull("A"[dartx.codeUnits][dartx.get](0)) && dart.notNull(event.charCode) <= dart.notNull("Z"[dartx.codeUnits][dartx.get](0)) && dart.notNull(event.charCode) + dart.notNull(_KeyboardEventHandler._ROMAN_ALPHABET_OFFSET) == prevEvent[_shadowCharCode]) {
          return prevEvent.keyCode;
        }
      }
      return KeyCode.UNKNOWN;
    }
    [_findCharCodeKeyDown](event) {
      if (event.keyLocation == 3) {
        switch (event.keyCode) {
          case KeyCode.NUM_ZERO:
          {
            return KeyCode.ZERO;
          }
          case KeyCode.NUM_ONE:
          {
            return KeyCode.ONE;
          }
          case KeyCode.NUM_TWO:
          {
            return KeyCode.TWO;
          }
          case KeyCode.NUM_THREE:
          {
            return KeyCode.THREE;
          }
          case KeyCode.NUM_FOUR:
          {
            return KeyCode.FOUR;
          }
          case KeyCode.NUM_FIVE:
          {
            return KeyCode.FIVE;
          }
          case KeyCode.NUM_SIX:
          {
            return KeyCode.SIX;
          }
          case KeyCode.NUM_SEVEN:
          {
            return KeyCode.SEVEN;
          }
          case KeyCode.NUM_EIGHT:
          {
            return KeyCode.EIGHT;
          }
          case KeyCode.NUM_NINE:
          {
            return KeyCode.NINE;
          }
          case KeyCode.NUM_MULTIPLY:
          {
            return 42;
          }
          case KeyCode.NUM_PLUS:
          {
            return 43;
          }
          case KeyCode.NUM_MINUS:
          {
            return 45;
          }
          case KeyCode.NUM_PERIOD:
          {
            return 46;
          }
          case KeyCode.NUM_DIVISION:
          {
            return 47;
          }
        }
      } else if (dart.notNull(event.keyCode) >= 65 && dart.notNull(event.keyCode) <= 90) {
        return dart.notNull(event.keyCode) + dart.notNull(_KeyboardEventHandler._ROMAN_ALPHABET_OFFSET);
      }
      switch (event.keyCode) {
        case KeyCode.SEMICOLON:
        {
          return KeyCode.FF_SEMICOLON;
        }
        case KeyCode.EQUALS:
        {
          return KeyCode.FF_EQUALS;
        }
        case KeyCode.COMMA:
        {
          return 44;
        }
        case KeyCode.DASH:
        {
          return 45;
        }
        case KeyCode.PERIOD:
        {
          return 46;
        }
        case KeyCode.SLASH:
        {
          return 47;
        }
        case KeyCode.APOSTROPHE:
        {
          return 96;
        }
        case KeyCode.OPEN_SQUARE_BRACKET:
        {
          return 91;
        }
        case KeyCode.BACKSLASH:
        {
          return 92;
        }
        case KeyCode.CLOSE_SQUARE_BRACKET:
        {
          return 93;
        }
        case KeyCode.SINGLE_QUOTE:
        {
          return 39;
        }
      }
      return event.keyCode;
    }
    [_firesKeyPressEvent](event) {
      if (!dart.notNull(html_common.Device.isIE) && !dart.notNull(html_common.Device.isWebKit)) {
        return true;
      }
      if (dart.notNull(html_common.Device.userAgent[dartx.contains]('Mac')) && dart.notNull(event.altKey)) {
        return KeyCode.isCharacterKey(event.keyCode);
      }
      if (dart.notNull(event.altKey) && !dart.notNull(event.ctrlKey)) {
        return false;
      }
      if (!dart.notNull(event.shiftKey) && (this[_keyDownList][dartx.last].keyCode == KeyCode.CTRL || this[_keyDownList][dartx.last].keyCode == KeyCode.ALT || dart.notNull(html_common.Device.userAgent[dartx.contains]('Mac')) && this[_keyDownList][dartx.last].keyCode == KeyCode.META)) {
        return false;
      }
      if (dart.notNull(html_common.Device.isWebKit) && dart.notNull(event.ctrlKey) && dart.notNull(event.shiftKey) && (event.keyCode == KeyCode.BACKSLASH || event.keyCode == KeyCode.OPEN_SQUARE_BRACKET || event.keyCode == KeyCode.CLOSE_SQUARE_BRACKET || event.keyCode == KeyCode.TILDE || event.keyCode == KeyCode.SEMICOLON || event.keyCode == KeyCode.DASH || event.keyCode == KeyCode.EQUALS || event.keyCode == KeyCode.COMMA || event.keyCode == KeyCode.PERIOD || event.keyCode == KeyCode.SLASH || event.keyCode == KeyCode.APOSTROPHE || event.keyCode == KeyCode.SINGLE_QUOTE)) {
        return false;
      }
      switch (event.keyCode) {
        case KeyCode.ENTER:
        {
          return !dart.notNull(html_common.Device.isIE);
        }
        case KeyCode.ESC:
        {
          return !dart.notNull(html_common.Device.isWebKit);
        }
      }
      return KeyCode.isCharacterKey(event.keyCode);
    }
    [_normalizeKeyCodes](event) {
      if (dart.notNull(html_common.Device.isFirefox)) {
        switch (event.keyCode) {
          case KeyCode.FF_EQUALS:
          {
            return KeyCode.EQUALS;
          }
          case KeyCode.FF_SEMICOLON:
          {
            return KeyCode.SEMICOLON;
          }
          case KeyCode.MAC_FF_META:
          {
            return KeyCode.META;
          }
          case KeyCode.WIN_KEY_FF_LINUX:
          {
            return KeyCode.WIN_KEY;
          }
        }
      }
      return event.keyCode;
    }
    processKeyDown(e) {
      if (dart.notNull(this[_keyDownList][dartx.length]) > 0 && (this[_keyDownList][dartx.last].keyCode == KeyCode.CTRL && !dart.notNull(e.ctrlKey) || this[_keyDownList][dartx.last].keyCode == KeyCode.ALT && !dart.notNull(e.altKey) || dart.notNull(html_common.Device.userAgent[dartx.contains]('Mac')) && this[_keyDownList][dartx.last].keyCode == KeyCode.META && !dart.notNull(e.metaKey))) {
        this[_keyDownList][dartx.clear]();
      }
      let event = new KeyEvent.wrap(e);
      event[_shadowKeyCode] = this[_normalizeKeyCodes](event);
      event[_shadowCharCode] = this[_findCharCodeKeyDown](event);
      if (dart.notNull(this[_keyDownList][dartx.length]) > 0 && event.keyCode != this[_keyDownList][dartx.last].keyCode && !dart.notNull(this[_firesKeyPressEvent](event))) {
        this.processKeyPress(e);
      }
      this[_keyDownList][dartx.add](event);
      this[_stream].add(event);
    }
    processKeyPress(event) {
      let e = new KeyEvent.wrap(event);
      if (dart.notNull(html_common.Device.isIE)) {
        if (e.keyCode == KeyCode.ENTER || e.keyCode == KeyCode.ESC) {
          e[_shadowCharCode] = 0;
        } else {
          e[_shadowCharCode] = e.keyCode;
        }
      } else if (dart.notNull(html_common.Device.isOpera)) {
        e[_shadowCharCode] = dart.notNull(KeyCode.isCharacterKey(e.keyCode)) ? e.keyCode : 0;
      }
      e[_shadowKeyCode] = this[_determineKeyCodeForKeypress](e);
      if (e[_shadowKeyIdentifier] != null && dart.notNull(_KeyboardEventHandler._keyIdentifier.containsKey(e[_shadowKeyIdentifier]))) {
        e[_shadowKeyCode] = _KeyboardEventHandler._keyIdentifier.get(e[_shadowKeyIdentifier]);
      }
      e[_shadowAltKey] = this[_keyDownList][dartx.any](dart.fn(element => element.altKey, core.bool, [KeyEvent]));
      this[_stream].add(e);
    }
    processKeyUp(event) {
      let e = new KeyEvent.wrap(event);
      let toRemove = null;
      for (let key of this[_keyDownList]) {
        if (key.keyCode == e.keyCode) {
          toRemove = key;
        }
      }
      if (toRemove != null) {
        this[_keyDownList][dartx.removeWhere](dart.fn(element => dart.equals(element, toRemove), core.bool, [KeyEvent]));
      } else if (dart.notNull(this[_keyDownList][dartx.length]) > 0) {
        this[_keyDownList][dartx.removeLast]();
      }
      this[_stream].add(e);
    }
  }
  dart.defineNamedConstructor(_KeyboardEventHandler, 'initializeAllEventListeners');
  dart.setSignature(_KeyboardEventHandler, {
    constructors: () => ({
      _KeyboardEventHandler: [_KeyboardEventHandler, [core.String]],
      initializeAllEventListeners: [_KeyboardEventHandler, [core.String, EventTarget]]
    }),
    methods: () => ({
      forTarget: [CustomStream$(KeyEvent), [EventTarget], {useCapture: core.bool}],
      [_determineKeyCodeForKeypress]: [core.int, [KeyboardEvent]],
      [_findCharCodeKeyDown]: [core.int, [KeyboardEvent]],
      [_firesKeyPressEvent]: [core.bool, [KeyEvent]],
      [_normalizeKeyCodes]: [core.int, [KeyboardEvent]],
      processKeyDown: [dart.void, [KeyboardEvent]],
      processKeyPress: [dart.void, [KeyboardEvent]],
      processKeyUp: [dart.void, [KeyboardEvent]]
    })
  });
  _KeyboardEventHandler._EVENT_TYPE = 'KeyEvent';
  _KeyboardEventHandler._keyIdentifier = dart.const(dart.map({Up: KeyCode.UP, Down: KeyCode.DOWN, Left: KeyCode.LEFT, Right: KeyCode.RIGHT, Enter: KeyCode.ENTER, F1: KeyCode.F1, F2: KeyCode.F2, F3: KeyCode.F3, F4: KeyCode.F4, F5: KeyCode.F5, F6: KeyCode.F6, F7: KeyCode.F7, F8: KeyCode.F8, F9: KeyCode.F9, F10: KeyCode.F10, F11: KeyCode.F11, F12: KeyCode.F12, 'U+007F': KeyCode.DELETE, Home: KeyCode.HOME, End: KeyCode.END, PageUp: KeyCode.PAGE_UP, PageDown: KeyCode.PAGE_DOWN, Insert: KeyCode.INSERT}));
  dart.defineLazyProperties(_KeyboardEventHandler, {
    get _ROMAN_ALPHABET_OFFSET() {
      return dart.notNull("a"[dartx.codeUnits][dartx.get](0)) - dart.notNull("A"[dartx.codeUnits][dartx.get](0));
    }
  });
  class KeyboardEventStream extends core.Object {
    static onKeyPress(target) {
      return new _KeyboardEventHandler('keypress').forTarget(target);
    }
    static onKeyUp(target) {
      return new _KeyboardEventHandler('keyup').forTarget(target);
    }
    static onKeyDown(target) {
      return new _KeyboardEventHandler('keydown').forTarget(target);
    }
  }
  dart.setSignature(KeyboardEventStream, {
    statics: () => ({
      onKeyPress: [CustomStream$(KeyEvent), [EventTarget]],
      onKeyUp: [CustomStream$(KeyEvent), [EventTarget]],
      onKeyDown: [CustomStream$(KeyEvent), [EventTarget]]
    }),
    names: ['onKeyPress', 'onKeyUp', 'onKeyDown']
  });
  const _validators = Symbol('_validators');
  class NodeValidatorBuilder extends core.Object {
    NodeValidatorBuilder() {
      this[_validators] = dart.list([], NodeValidator);
    }
    common() {
      this[_validators] = dart.list([], NodeValidator);
      this.allowHtml5();
      this.allowTemplating();
    }
    allowNavigation(uriPolicy) {
      if (uriPolicy === void 0) uriPolicy = null;
      if (uriPolicy == null) {
        uriPolicy = UriPolicy.new();
      }
      this.add(_SimpleNodeValidator.allowNavigation(uriPolicy));
    }
    allowImages(uriPolicy) {
      if (uriPolicy === void 0) uriPolicy = null;
      if (uriPolicy == null) {
        uriPolicy = UriPolicy.new();
      }
      this.add(_SimpleNodeValidator.allowImages(uriPolicy));
    }
    allowTextElements() {
      this.add(_SimpleNodeValidator.allowTextElements());
    }
    allowInlineStyles(opts) {
      let tagName = opts && 'tagName' in opts ? opts.tagName : null;
      if (tagName == null) {
        tagName = '*';
      } else {
        tagName = tagName[dartx.toUpperCase]();
      }
      this.add(new _SimpleNodeValidator(null, {allowedAttributes: dart.list([`${tagName}::style`], core.String)}));
    }
    allowHtml5(opts) {
      let uriPolicy = opts && 'uriPolicy' in opts ? opts.uriPolicy : null;
      this.add(new _Html5NodeValidator({uriPolicy: uriPolicy}));
    }
    allowSvg() {
      dart.throw('SVG not supported with DDC');
    }
    allowCustomElement(tagName, opts) {
      let uriPolicy = opts && 'uriPolicy' in opts ? opts.uriPolicy : null;
      let attributes = opts && 'attributes' in opts ? opts.attributes : null;
      let uriAttributes = opts && 'uriAttributes' in opts ? opts.uriAttributes : null;
      let tagNameUpper = tagName[dartx.toUpperCase]();
      let attrs = null;
      if (attributes != null) {
        attrs = attributes[dartx.map](dart.fn(name => `${tagNameUpper}::${name[dartx.toLowerCase]()}`, core.String, [core.String]));
      }
      let uriAttrs = null;
      if (uriAttributes != null) {
        uriAttrs = uriAttributes[dartx.map](dart.fn(name => `${tagNameUpper}::${name[dartx.toLowerCase]()}`, core.String, [core.String]));
      }
      if (uriPolicy == null) {
        uriPolicy = UriPolicy.new();
      }
      this.add(new _CustomElementNodeValidator(uriPolicy, dart.list([tagNameUpper], core.String), dart.as(attrs, core.Iterable$(core.String)), dart.as(uriAttrs, core.Iterable$(core.String)), false, true));
    }
    allowTagExtension(tagName, baseName, opts) {
      let uriPolicy = opts && 'uriPolicy' in opts ? opts.uriPolicy : null;
      let attributes = opts && 'attributes' in opts ? opts.attributes : null;
      let uriAttributes = opts && 'uriAttributes' in opts ? opts.uriAttributes : null;
      let baseNameUpper = baseName[dartx.toUpperCase]();
      let tagNameUpper = tagName[dartx.toUpperCase]();
      let attrs = null;
      if (attributes != null) {
        attrs = attributes[dartx.map](dart.fn(name => `${baseNameUpper}::${name[dartx.toLowerCase]()}`, core.String, [core.String]));
      }
      let uriAttrs = null;
      if (uriAttributes != null) {
        uriAttrs = uriAttributes[dartx.map](dart.fn(name => `${baseNameUpper}::${name[dartx.toLowerCase]()}`, core.String, [core.String]));
      }
      if (uriPolicy == null) {
        uriPolicy = UriPolicy.new();
      }
      this.add(new _CustomElementNodeValidator(uriPolicy, dart.list([tagNameUpper, baseNameUpper], core.String), dart.as(attrs, core.Iterable$(core.String)), dart.as(uriAttrs, core.Iterable$(core.String)), true, false));
    }
    allowElement(tagName, opts) {
      let uriPolicy = opts && 'uriPolicy' in opts ? opts.uriPolicy : null;
      let attributes = opts && 'attributes' in opts ? opts.attributes : null;
      let uriAttributes = opts && 'uriAttributes' in opts ? opts.uriAttributes : null;
      this.allowCustomElement(tagName, {uriPolicy: uriPolicy, attributes: attributes, uriAttributes: uriAttributes});
    }
    allowTemplating() {
      this.add(new _TemplatingNodeValidator());
    }
    add(validator) {
      this[_validators][dartx.add](validator);
    }
    allowsElement(element) {
      return this[_validators][dartx.any](dart.fn(v => v.allowsElement(element), core.bool, [NodeValidator]));
    }
    allowsAttribute(element, attributeName, value) {
      return this[_validators][dartx.any](dart.fn(v => v.allowsAttribute(element, attributeName, value), core.bool, [NodeValidator]));
    }
  }
  NodeValidatorBuilder[dart.implements] = () => [NodeValidator];
  dart.defineNamedConstructor(NodeValidatorBuilder, 'common');
  dart.setSignature(NodeValidatorBuilder, {
    constructors: () => ({
      NodeValidatorBuilder: [NodeValidatorBuilder, []],
      common: [NodeValidatorBuilder, []]
    }),
    methods: () => ({
      allowNavigation: [dart.void, [], [UriPolicy]],
      allowImages: [dart.void, [], [UriPolicy]],
      allowTextElements: [dart.void, []],
      allowInlineStyles: [dart.void, [], {tagName: core.String}],
      allowHtml5: [dart.void, [], {uriPolicy: UriPolicy}],
      allowSvg: [dart.void, []],
      allowCustomElement: [dart.void, [core.String], {uriPolicy: UriPolicy, attributes: core.Iterable$(core.String), uriAttributes: core.Iterable$(core.String)}],
      allowTagExtension: [dart.void, [core.String, core.String], {uriPolicy: UriPolicy, attributes: core.Iterable$(core.String), uriAttributes: core.Iterable$(core.String)}],
      allowElement: [dart.void, [core.String], {uriPolicy: UriPolicy, attributes: core.Iterable$(core.String), uriAttributes: core.Iterable$(core.String)}],
      allowTemplating: [dart.void, []],
      add: [dart.void, [NodeValidator]],
      allowsElement: [core.bool, [Element]],
      allowsAttribute: [core.bool, [Element, core.String, core.String]]
    })
  });
  class _SimpleNodeValidator extends core.Object {
    static allowNavigation(uriPolicy) {
      return new _SimpleNodeValidator(uriPolicy, {allowedElements: dart.const(dart.list(['A', 'FORM'], core.String)), allowedAttributes: dart.const(dart.list(['A::accesskey', 'A::coords', 'A::hreflang', 'A::name', 'A::shape', 'A::tabindex', 'A::target', 'A::type', 'FORM::accept', 'FORM::autocomplete', 'FORM::enctype', 'FORM::method', 'FORM::name', 'FORM::novalidate', 'FORM::target'], core.String)), allowedUriAttributes: dart.const(dart.list(['A::href', 'FORM::action'], core.String))});
    }
    static allowImages(uriPolicy) {
      return new _SimpleNodeValidator(uriPolicy, {allowedElements: dart.const(dart.list(['IMG'], core.String)), allowedAttributes: dart.const(dart.list(['IMG::align', 'IMG::alt', 'IMG::border', 'IMG::height', 'IMG::hspace', 'IMG::ismap', 'IMG::name', 'IMG::usemap', 'IMG::vspace', 'IMG::width'], core.String)), allowedUriAttributes: dart.const(dart.list(['IMG::src'], core.String))});
    }
    static allowTextElements() {
      return new _SimpleNodeValidator(null, {allowedElements: dart.const(dart.list(['B', 'BLOCKQUOTE', 'BR', 'EM', 'H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'HR', 'I', 'LI', 'OL', 'P', 'SPAN', 'UL'], core.String))});
    }
    _SimpleNodeValidator(uriPolicy, opts) {
      let allowedElements = opts && 'allowedElements' in opts ? opts.allowedElements : null;
      let allowedAttributes = opts && 'allowedAttributes' in opts ? opts.allowedAttributes : null;
      let allowedUriAttributes = opts && 'allowedUriAttributes' in opts ? opts.allowedUriAttributes : null;
      this.allowedElements = core.Set$(core.String).new();
      this.allowedAttributes = core.Set$(core.String).new();
      this.allowedUriAttributes = core.Set$(core.String).new();
      this.uriPolicy = uriPolicy;
      this.allowedElements.addAll((allowedElements != null ? allowedElements : dart.const(dart.list([], core.String))));
      allowedAttributes = allowedAttributes != null ? allowedAttributes : dart.const(dart.list([], core.String));
      allowedUriAttributes = allowedUriAttributes != null ? allowedUriAttributes : dart.const(dart.list([], core.String));
      let legalAttributes = allowedAttributes[dartx.where](dart.fn(x => !dart.notNull(_Html5NodeValidator._uriAttributes[dartx.contains](x)), core.bool, [core.String]));
      let extraUriAttributes = allowedAttributes[dartx.where](dart.fn(x => _Html5NodeValidator._uriAttributes[dartx.contains](x), core.bool, [core.String]));
      this.allowedAttributes.addAll(legalAttributes);
      this.allowedUriAttributes.addAll(allowedUriAttributes);
      this.allowedUriAttributes.addAll(extraUriAttributes);
    }
    allowsElement(element) {
      return this.allowedElements.contains(Element._safeTagName(element));
    }
    allowsAttribute(element, attributeName, value) {
      let tagName = Element._safeTagName(element);
      if (dart.notNull(this.allowedUriAttributes.contains(`${tagName}::${attributeName}`))) {
        return this.uriPolicy.allowsUri(value);
      } else if (dart.notNull(this.allowedUriAttributes.contains(`*::${attributeName}`))) {
        return this.uriPolicy.allowsUri(value);
      } else if (dart.notNull(this.allowedAttributes.contains(`${tagName}::${attributeName}`))) {
        return true;
      } else if (dart.notNull(this.allowedAttributes.contains(`*::${attributeName}`))) {
        return true;
      } else if (dart.notNull(this.allowedAttributes.contains(`${tagName}::*`))) {
        return true;
      } else if (dart.notNull(this.allowedAttributes.contains('*::*'))) {
        return true;
      }
      return false;
    }
  }
  _SimpleNodeValidator[dart.implements] = () => [NodeValidator];
  dart.setSignature(_SimpleNodeValidator, {
    constructors: () => ({
      allowNavigation: [_SimpleNodeValidator, [UriPolicy]],
      allowImages: [_SimpleNodeValidator, [UriPolicy]],
      allowTextElements: [_SimpleNodeValidator, []],
      _SimpleNodeValidator: [_SimpleNodeValidator, [UriPolicy], {allowedElements: core.Iterable$(core.String), allowedAttributes: core.Iterable$(core.String), allowedUriAttributes: core.Iterable$(core.String)}]
    }),
    methods: () => ({
      allowsElement: [core.bool, [Element]],
      allowsAttribute: [core.bool, [Element, core.String, core.String]]
    })
  });
  class _CustomElementNodeValidator extends _SimpleNodeValidator {
    _CustomElementNodeValidator(uriPolicy, allowedElements, allowedAttributes, allowedUriAttributes, allowTypeExtension, allowCustomTag) {
      this.allowTypeExtension = allowTypeExtension == true;
      this.allowCustomTag = allowCustomTag == true;
      super._SimpleNodeValidator(uriPolicy, {allowedElements: allowedElements, allowedAttributes: allowedAttributes, allowedUriAttributes: allowedUriAttributes});
    }
    allowsElement(element) {
      if (dart.notNull(this.allowTypeExtension)) {
        let isAttr = element.attributes.get('is');
        if (isAttr != null) {
          return dart.notNull(this.allowedElements.contains(isAttr[dartx.toUpperCase]())) && dart.notNull(this.allowedElements.contains(Element._safeTagName(element)));
        }
      }
      return dart.notNull(this.allowCustomTag) && dart.notNull(this.allowedElements.contains(Element._safeTagName(element)));
    }
    allowsAttribute(element, attributeName, value) {
      if (dart.notNull(this.allowsElement(element))) {
        if (dart.notNull(this.allowTypeExtension) && attributeName == 'is' && dart.notNull(this.allowedElements.contains(value[dartx.toUpperCase]()))) {
          return true;
        }
        return super.allowsAttribute(element, attributeName, value);
      }
      return false;
    }
  }
  dart.setSignature(_CustomElementNodeValidator, {
    constructors: () => ({_CustomElementNodeValidator: [_CustomElementNodeValidator, [UriPolicy, core.Iterable$(core.String), core.Iterable$(core.String), core.Iterable$(core.String), core.bool, core.bool]]})
  });
  const _templateAttrs = Symbol('_templateAttrs');
  class _TemplatingNodeValidator extends _SimpleNodeValidator {
    _TemplatingNodeValidator() {
      this[_templateAttrs] = core.Set$(core.String).from(_TemplatingNodeValidator._TEMPLATE_ATTRS);
      super._SimpleNodeValidator(null, {allowedElements: dart.list(['TEMPLATE'], core.String), allowedAttributes: _TemplatingNodeValidator._TEMPLATE_ATTRS[dartx.map](dart.fn(attr => `TEMPLATE::${attr}`, core.String, [core.String]))});
    }
    allowsAttribute(element, attributeName, value) {
      if (dart.notNull(super.allowsAttribute(element, attributeName, value))) {
        return true;
      }
      if (attributeName == 'template' && value == "") {
        return true;
      }
      if (element.attributes.get('template') == "") {
        return this[_templateAttrs].contains(attributeName);
      }
      return false;
    }
  }
  dart.setSignature(_TemplatingNodeValidator, {
    constructors: () => ({_TemplatingNodeValidator: [_TemplatingNodeValidator, []]})
  });
  _TemplatingNodeValidator._TEMPLATE_ATTRS = dart.const(dart.list(['bind', 'if', 'ref', 'repeat', 'syntax'], core.String));
  class ReadyState extends core.Object {}
  ReadyState.LOADING = "loading";
  ReadyState.INTERACTIVE = "interactive";
  ReadyState.COMPLETE = "complete";
  const _list = Symbol('_list');
  const _WrappedList$ = dart.generic(function(E) {
    class _WrappedList extends collection.ListBase$(E) {
      _WrappedList(list) {
        this[_list] = list;
      }
      get iterator() {
        return new (_WrappedIterator$(E))(this[_list][dartx.iterator]);
      }
      get length() {
        return this[_list][dartx.length];
      }
      add(element) {
        dart.as(element, E);
        this[_list][dartx.add](element);
      }
      remove(element) {
        return this[_list][dartx.remove](element);
      }
      clear() {
        this[_list][dartx.clear]();
      }
      get(index) {
        return dart.as(this[_list][dartx.get](index), E);
      }
      set(index, value) {
        dart.as(value, E);
        this[_list][dartx.set](index, value);
        return value;
      }
      set length(newLength) {
        this[_list][dartx.length] = newLength;
      }
      sort(compare) {
        if (compare === void 0) compare = null;
        dart.as(compare, dart.functionType(core.int, [E, E]));
        this[_list][dartx.sort](compare);
      }
      indexOf(element, start) {
        if (start === void 0) start = 0;
        return this[_list][dartx.indexOf](element, start);
      }
      lastIndexOf(element, start) {
        if (start === void 0) start = null;
        return this[_list][dartx.lastIndexOf](element, start);
      }
      insert(index, element) {
        dart.as(element, E);
        return this[_list][dartx.insert](index, element);
      }
      removeAt(index) {
        return dart.as(this[_list][dartx.removeAt](index), E);
      }
      setRange(start, end, iterable, skipCount) {
        dart.as(iterable, core.Iterable$(E));
        if (skipCount === void 0) skipCount = 0;
        this[_list][dartx.setRange](start, end, iterable, skipCount);
      }
      removeRange(start, end) {
        this[_list][dartx.removeRange](start, end);
      }
      replaceRange(start, end, iterable) {
        dart.as(iterable, core.Iterable$(E));
        this[_list][dartx.replaceRange](start, end, iterable);
      }
      fillRange(start, end, fillValue) {
        if (fillValue === void 0) fillValue = null;
        dart.as(fillValue, E);
        this[_list][dartx.fillRange](start, end, fillValue);
      }
      get rawList() {
        return dart.as(this[_list], core.List$(Node));
      }
    }
    _WrappedList[dart.implements] = () => [html_common.NodeListWrapper];
    dart.setSignature(_WrappedList, {
      constructors: () => ({_WrappedList: [_WrappedList$(E), [core.List]]}),
      methods: () => ({
        add: [dart.void, [E]],
        get: [E, [core.int]],
        set: [dart.void, [core.int, E]],
        sort: [dart.void, [], [dart.functionType(core.int, [E, E])]],
        insert: [dart.void, [core.int, E]],
        removeAt: [E, [core.int]],
        setRange: [dart.void, [core.int, core.int, core.Iterable$(E)], [core.int]],
        replaceRange: [dart.void, [core.int, core.int, core.Iterable$(E)]],
        fillRange: [dart.void, [core.int, core.int], [E]]
      })
    });
    dart.defineExtensionMembers(_WrappedList, [
      'add',
      'remove',
      'clear',
      'get',
      'set',
      'sort',
      'indexOf',
      'lastIndexOf',
      'insert',
      'removeAt',
      'setRange',
      'removeRange',
      'replaceRange',
      'fillRange',
      'iterator',
      'length',
      'length'
    ]);
    return _WrappedList;
  });
  let _WrappedList = _WrappedList$();
  const _iterator = Symbol('_iterator');
  const _WrappedIterator$ = dart.generic(function(E) {
    class _WrappedIterator extends core.Object {
      _WrappedIterator(iterator) {
        this[_iterator] = iterator;
      }
      moveNext() {
        return this[_iterator].moveNext();
      }
      get current() {
        return dart.as(this[_iterator].current, E);
      }
    }
    _WrappedIterator[dart.implements] = () => [core.Iterator$(E)];
    dart.setSignature(_WrappedIterator, {
      constructors: () => ({_WrappedIterator: [_WrappedIterator$(E), [core.Iterator]]}),
      methods: () => ({moveNext: [core.bool, []]})
    });
    return _WrappedIterator;
  });
  let _WrappedIterator = _WrappedIterator$();
  class _HttpRequestUtils extends core.Object {
    static get(url, onComplete, withCredentials) {
      let request = HttpRequest.new();
      request.open('GET', url, {async: true});
      request.withCredentials = withCredentials;
      request.onReadyStateChange.listen(dart.fn(e => {
        if (request.readyState == HttpRequest.DONE) {
          onComplete(request);
        }
      }, dart.void, [ProgressEvent]));
      request.send();
      return request;
    }
  }
  dart.setSignature(_HttpRequestUtils, {
    statics: () => ({get: [HttpRequest, [core.String, dart.functionType(dart.dynamic, [HttpRequest]), core.bool]]}),
    names: ['get']
  });
  const _array = Symbol('_array');
  const _position = Symbol('_position');
  const _length = Symbol('_length');
  const _current = Symbol('_current');
  const FixedSizeListIterator$ = dart.generic(function(T) {
    class FixedSizeListIterator extends core.Object {
      FixedSizeListIterator(array) {
        this[_array] = array;
        this[_position] = -1;
        this[_length] = array[dartx.length];
        this[_current] = null;
      }
      moveNext() {
        let nextPosition = dart.notNull(this[_position]) + 1;
        if (nextPosition < dart.notNull(this[_length])) {
          this[_current] = this[_array][dartx.get](nextPosition);
          this[_position] = nextPosition;
          return true;
        }
        this[_current] = null;
        this[_position] = this[_length];
        return false;
      }
      get current() {
        return this[_current];
      }
    }
    FixedSizeListIterator[dart.implements] = () => [core.Iterator$(T)];
    dart.setSignature(FixedSizeListIterator, {
      constructors: () => ({FixedSizeListIterator: [FixedSizeListIterator$(T), [core.List$(T)]]}),
      methods: () => ({moveNext: [core.bool, []]})
    });
    return FixedSizeListIterator;
  });
  let FixedSizeListIterator = FixedSizeListIterator$();
  const _VariableSizeListIterator$ = dart.generic(function(T) {
    class _VariableSizeListIterator extends core.Object {
      _VariableSizeListIterator(array) {
        this[_array] = array;
        this[_position] = -1;
        this[_current] = null;
      }
      moveNext() {
        let nextPosition = dart.notNull(this[_position]) + 1;
        if (nextPosition < dart.notNull(this[_array][dartx.length])) {
          this[_current] = this[_array][dartx.get](nextPosition);
          this[_position] = nextPosition;
          return true;
        }
        this[_current] = null;
        this[_position] = this[_array][dartx.length];
        return false;
      }
      get current() {
        return this[_current];
      }
    }
    _VariableSizeListIterator[dart.implements] = () => [core.Iterator$(T)];
    dart.setSignature(_VariableSizeListIterator, {
      constructors: () => ({_VariableSizeListIterator: [_VariableSizeListIterator$(T), [core.List$(T)]]}),
      methods: () => ({moveNext: [core.bool, []]})
    });
    return _VariableSizeListIterator;
  });
  let _VariableSizeListIterator = _VariableSizeListIterator$();
  function _convertNativeToDart_Window(win) {
    if (win == null) return null;
    return _DOMWindowCrossFrame._createSafe(win);
  }
  dart.fn(_convertNativeToDart_Window, WindowBase, [dart.dynamic]);
  function _convertNativeToDart_EventTarget(e) {
    if (e == null) {
      return null;
    }
    if ("postMessage" in e) {
      let window = _DOMWindowCrossFrame._createSafe(e);
      if (dart.is(window, EventTarget)) {
        return window;
      }
      return null;
    } else
      return dart.as(e, EventTarget);
  }
  dart.fn(_convertNativeToDart_EventTarget, EventTarget, [dart.dynamic]);
  const _window = Symbol('_window');
  function _convertDartToNative_EventTarget(e) {
    if (dart.is(e, _DOMWindowCrossFrame)) {
      return dart.as(e[_window], EventTarget);
    } else {
      return dart.as(e, EventTarget);
    }
  }
  dart.fn(_convertDartToNative_EventTarget, EventTarget, [dart.dynamic]);
  function _convertNativeToDart_XHR_Response(o) {
    if (dart.is(o, Document)) {
      return o;
    }
    return html_common.convertNativeToDart_SerializedScriptValue(o);
  }
  dart.fn(_convertNativeToDart_XHR_Response);
  class _DOMWindowCrossFrame extends core.Object {
    get history() {
      return _HistoryCrossFrame._createSafe(this[_window].history);
    }
    get location() {
      return _LocationCrossFrame._createSafe(this[_window].location);
    }
    get closed() {
      return this[_window].closed;
    }
    get opener() {
      return _DOMWindowCrossFrame._createSafe(this[_window].opener);
    }
    get parent() {
      return _DOMWindowCrossFrame._createSafe(this[_window].parent);
    }
    get top() {
      return _DOMWindowCrossFrame._createSafe(this[_window].top);
    }
    close() {
      return this[_window].close();
    }
    postMessage(message, targetOrigin, messagePorts) {
      if (messagePorts === void 0) messagePorts = null;
      if (messagePorts == null) {
        this[_window].postMessage(html_common.convertDartToNative_SerializedScriptValue(message), targetOrigin);
      } else {
        this[_window].postMessage(html_common.convertDartToNative_SerializedScriptValue(message), targetOrigin, messagePorts);
      }
    }
    _DOMWindowCrossFrame(window) {
      this[_window] = window;
    }
    static _createSafe(w) {
      if (dart.notNull(core.identical(w, exports.window))) {
        return dart.as(w, WindowBase);
      } else {
        return new _DOMWindowCrossFrame(w);
      }
    }
    get on() {
      return dart.throw(new core.UnsupportedError('You can only attach EventListeners to your own window.'));
    }
    [_addEventListener](type, listener, useCapture) {
      if (type === void 0) type = null;
      if (listener === void 0) listener = null;
      if (useCapture === void 0) useCapture = null;
      return dart.throw(new core.UnsupportedError('You can only attach EventListeners to your own window.'));
    }
    addEventListener(type, listener, useCapture) {
      if (useCapture === void 0) useCapture = null;
      return dart.throw(new core.UnsupportedError('You can only attach EventListeners to your own window.'));
    }
    dispatchEvent(event) {
      return dart.throw(new core.UnsupportedError('You can only attach EventListeners to your own window.'));
    }
    [_removeEventListener](type, listener, useCapture) {
      if (type === void 0) type = null;
      if (listener === void 0) listener = null;
      if (useCapture === void 0) useCapture = null;
      return dart.throw(new core.UnsupportedError('You can only attach EventListeners to your own window.'));
    }
    removeEventListener(type, listener, useCapture) {
      if (useCapture === void 0) useCapture = null;
      return dart.throw(new core.UnsupportedError('You can only attach EventListeners to your own window.'));
    }
  }
  _DOMWindowCrossFrame[dart.implements] = () => [WindowBase];
  dart.setSignature(_DOMWindowCrossFrame, {
    constructors: () => ({_DOMWindowCrossFrame: [_DOMWindowCrossFrame, [dart.dynamic]]}),
    methods: () => ({
      close: [dart.void, []],
      postMessage: [dart.void, [dart.dynamic, core.String], [core.List]],
      [_addEventListener]: [dart.void, [], [core.String, EventListener, core.bool]],
      addEventListener: [dart.void, [core.String, EventListener], [core.bool]],
      dispatchEvent: [core.bool, [Event]],
      [_removeEventListener]: [dart.void, [], [core.String, EventListener, core.bool]],
      removeEventListener: [dart.void, [core.String, EventListener], [core.bool]]
    }),
    statics: () => ({_createSafe: [WindowBase, [dart.dynamic]]}),
    names: ['_createSafe']
  });
  class _LocationCrossFrame extends core.Object {
    set href(val) {
      return _LocationCrossFrame._setHref(this[_location], val);
    }
    static _setHref(location, val) {
      location.href = val;
    }
    _LocationCrossFrame(location) {
      this[_location] = location;
    }
    static _createSafe(location) {
      if (dart.notNull(core.identical(location, exports.window.location))) {
        return dart.as(location, LocationBase);
      } else {
        return new _LocationCrossFrame(location);
      }
    }
  }
  _LocationCrossFrame[dart.implements] = () => [LocationBase];
  dart.setSignature(_LocationCrossFrame, {
    constructors: () => ({_LocationCrossFrame: [_LocationCrossFrame, [dart.dynamic]]}),
    statics: () => ({
      _setHref: [dart.void, [dart.dynamic, dart.dynamic]],
      _createSafe: [LocationBase, [dart.dynamic]]
    }),
    names: ['_setHref', '_createSafe']
  });
  const _history = Symbol('_history');
  class _HistoryCrossFrame extends core.Object {
    back() {
      return this[_history].back();
    }
    forward() {
      return this[_history].forward();
    }
    go(distance) {
      return this[_history].go(distance);
    }
    _HistoryCrossFrame(history) {
      this[_history] = history;
    }
    static _createSafe(h) {
      if (dart.notNull(core.identical(h, exports.window.history))) {
        return dart.as(h, HistoryBase);
      } else {
        return new _HistoryCrossFrame(h);
      }
    }
  }
  _HistoryCrossFrame[dart.implements] = () => [HistoryBase];
  dart.setSignature(_HistoryCrossFrame, {
    constructors: () => ({_HistoryCrossFrame: [_HistoryCrossFrame, [dart.dynamic]]}),
    methods: () => ({
      back: [dart.void, []],
      forward: [dart.void, []],
      go: [dart.void, [core.int]]
    }),
    statics: () => ({_createSafe: [HistoryBase, [dart.dynamic]]}),
    names: ['_createSafe']
  });
  class Platform extends core.Object {}
  Platform.supportsSimd = false;
  dart.defineLazyProperties(Platform, {
    get supportsTypedData() {
      return !!dart.global.ArrayBuffer;
    }
  });
  function _wrapZone(callback) {
    if (dart.equals(async.Zone.current, async.Zone.ROOT)) return callback;
    if (callback == null) return null;
    return async.Zone.current.bindUnaryCallback(callback, {runGuarded: true});
  }
  dart.fn(_wrapZone, dart.dynamic, [dart.functionType(dart.dynamic, [dart.dynamic])]);
  function _wrapBinaryZone(callback) {
    if (dart.equals(async.Zone.current, async.Zone.ROOT)) return callback;
    if (callback == null) return null;
    return async.Zone.current.bindBinaryCallback(callback, {runGuarded: true});
  }
  dart.fn(_wrapBinaryZone, dart.dynamic, [dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic])]);
  function query(relativeSelectors) {
    return exports.document.query(relativeSelectors);
  }
  dart.fn(query, Element, [core.String]);
  function queryAll(relativeSelectors) {
    return exports.document.queryAll(relativeSelectors);
  }
  dart.fn(queryAll, ElementList$(Element), [core.String]);
  function querySelector(selectors) {
    return exports.document.querySelector(selectors);
  }
  dart.fn(querySelector, Element, [core.String]);
  function querySelectorAll(selectors) {
    return exports.document.querySelectorAll(selectors);
  }
  dart.fn(querySelectorAll, ElementList$(Element), [core.String]);
  class ElementUpgrader extends core.Object {}
  class NodeValidator extends core.Object {
    static new(opts) {
      let uriPolicy = opts && 'uriPolicy' in opts ? opts.uriPolicy : null;
      return new _Html5NodeValidator({uriPolicy: uriPolicy});
    }
    static throws(base) {
      return new _ThrowsNodeValidator(base);
    }
  }
  dart.setSignature(NodeValidator, {
    constructors: () => ({
      new: [NodeValidator, [], {uriPolicy: UriPolicy}],
      throws: [NodeValidator, [NodeValidator]]
    })
  });
  class NodeTreeSanitizer extends core.Object {
    static new(validator) {
      return new _ValidatingTreeSanitizer(validator);
    }
  }
  dart.setSignature(NodeTreeSanitizer, {
    constructors: () => ({new: [NodeTreeSanitizer, [NodeValidator]]})
  });
  dart.defineLazyProperties(NodeTreeSanitizer, {
    get trusted() {
      return dart.const(new _TrustedHtmlTreeSanitizer());
    }
  });
  class _TrustedHtmlTreeSanitizer extends core.Object {
    _TrustedHtmlTreeSanitizer() {
    }
    sanitizeTree(node) {}
  }
  _TrustedHtmlTreeSanitizer[dart.implements] = () => [NodeTreeSanitizer];
  dart.setSignature(_TrustedHtmlTreeSanitizer, {
    constructors: () => ({_TrustedHtmlTreeSanitizer: [_TrustedHtmlTreeSanitizer, []]}),
    methods: () => ({sanitizeTree: [dart.void, [Node]]})
  });
  class UriPolicy extends core.Object {
    static new() {
      return new _SameOriginUriPolicy();
    }
  }
  dart.setSignature(UriPolicy, {
    constructors: () => ({new: [UriPolicy, []]})
  });
  const _hiddenAnchor = Symbol('_hiddenAnchor');
  const _loc = Symbol('_loc');
  class _SameOriginUriPolicy extends core.Object {
    _SameOriginUriPolicy() {
      this[_hiddenAnchor] = AnchorElement.new();
      this[_loc] = exports.window.location;
    }
    allowsUri(uri) {
      this[_hiddenAnchor].href = uri;
      return this[_hiddenAnchor].hostname == this[_loc].hostname && this[_hiddenAnchor].port == this[_loc].port && this[_hiddenAnchor].protocol == this[_loc].protocol || this[_hiddenAnchor].hostname == '' && this[_hiddenAnchor].port == '' && (this[_hiddenAnchor].protocol == ':' || this[_hiddenAnchor].protocol == '');
    }
  }
  _SameOriginUriPolicy[dart.implements] = () => [UriPolicy];
  dart.setSignature(_SameOriginUriPolicy, {
    methods: () => ({allowsUri: [core.bool, [core.String]]})
  });
  class _ThrowsNodeValidator extends core.Object {
    _ThrowsNodeValidator(validator) {
      this.validator = validator;
    }
    allowsElement(element) {
      if (!dart.notNull(this.validator.allowsElement(element))) {
        dart.throw(new core.ArgumentError(Element._safeTagName(element)));
      }
      return true;
    }
    allowsAttribute(element, attributeName, value) {
      if (!dart.notNull(this.validator.allowsAttribute(element, attributeName, value))) {
        dart.throw(new core.ArgumentError(`${Element._safeTagName(element)}[${attributeName}="${value}"]`));
      }
    }
  }
  _ThrowsNodeValidator[dart.implements] = () => [NodeValidator];
  dart.setSignature(_ThrowsNodeValidator, {
    constructors: () => ({_ThrowsNodeValidator: [_ThrowsNodeValidator, [NodeValidator]]}),
    methods: () => ({
      allowsElement: [core.bool, [Element]],
      allowsAttribute: [core.bool, [Element, core.String, core.String]]
    })
  });
  const _removeNode = Symbol('_removeNode');
  const _sanitizeElement = Symbol('_sanitizeElement');
  const _sanitizeUntrustedElement = Symbol('_sanitizeUntrustedElement');
  class _ValidatingTreeSanitizer extends core.Object {
    _ValidatingTreeSanitizer(validator) {
      this.validator = validator;
    }
    sanitizeTree(node) {
      const walk = (function(node, parent) {
        this.sanitizeNode(node, parent);
        let child = node.lastChild;
        while (child != null) {
          let nextChild = child.previousNode;
          walk(child, node);
          child = nextChild;
        }
      }).bind(this);
      dart.fn(walk, dart.void, [Node, Node]);
      walk(node, null);
    }
    [_removeNode](node, parent) {
      if (parent == null) {
        node.remove();
      } else {
        parent[_removeChild](node);
      }
    }
    [_sanitizeUntrustedElement](element, parent) {
      let corrupted = true;
      let attrs = null;
      let isAttr = null;
      try {
        attrs = dart.dload(element, 'attributes');
        isAttr = dart.dindex(attrs, 'is');
        let corruptedTest1 = Element._hasCorruptedAttributes(dart.as(element, Element));
        corrupted = dart.notNull(corruptedTest1) ? true : Element._hasCorruptedAttributesAdditionalCheck(dart.as(element, Element));
      } catch (e) {
      }

      let elementText = 'element unprintable';
      try {
        elementText = dart.toString(element);
      } catch (e) {
      }

      try {
        let elementTagName = Element._safeTagName(element);
        this[_sanitizeElement](dart.as(element, Element), parent, corrupted, elementText, elementTagName, dart.as(attrs, core.Map), dart.as(isAttr, core.String));
      } catch (e$) {
        if (dart.is(e$, core.ArgumentError)) {
          throw e$;
        } else {
          let e = e$;
          this[_removeNode](dart.as(element, Node), parent);
          exports.window.console.warn(`Removing corrupted element ${elementText}`);
        }
      }

    }
    [_sanitizeElement](element, parent, corrupted, text, tag, attrs, isAttr) {
      if (false != corrupted) {
        this[_removeNode](element, parent);
        exports.window.console.warn(`Removing element due to corrupted attributes on <${text}>`);
        return;
      }
      if (!dart.notNull(this.validator.allowsElement(element))) {
        this[_removeNode](element, parent);
        exports.window.console.warn(`Removing disallowed element <${tag}> from ${parent}`);
        return;
      }
      if (isAttr != null) {
        if (!dart.notNull(this.validator.allowsAttribute(element, 'is', isAttr))) {
          this[_removeNode](element, parent);
          exports.window.console.warn('Removing disallowed type extension ' + `<${tag} is="${isAttr}">`);
          return;
        }
      }
      let keys = attrs.keys[dartx.toList]();
      for (let i = dart.notNull(attrs.length) - 1; i >= 0; --i) {
        let name = keys[dartx.get](i);
        if (!dart.notNull(this.validator.allowsAttribute(element, dart.as(dart.dsend(name, 'toLowerCase'), core.String), dart.as(attrs.get(name), core.String)))) {
          exports.window.console.warn('Removing disallowed attribute ' + `<${tag} ${name}="${attrs.get(name)}">`);
          attrs.remove(name);
        }
      }
      if (dart.is(element, TemplateElement)) {
        let template = element;
        this.sanitizeTree(template.content);
      }
    }
    sanitizeNode(node, parent) {
      switch (node.nodeType) {
        case Node.ELEMENT_NODE:
        {
          this[_sanitizeUntrustedElement](node, parent);
          break;
        }
        case Node.COMMENT_NODE:
        case Node.DOCUMENT_FRAGMENT_NODE:
        case Node.TEXT_NODE:
        case Node.CDATA_SECTION_NODE:
        {
          break;
        }
        default:
        {
          this[_removeNode](node, parent);
        }
      }
    }
  }
  _ValidatingTreeSanitizer[dart.implements] = () => [NodeTreeSanitizer];
  dart.setSignature(_ValidatingTreeSanitizer, {
    constructors: () => ({_ValidatingTreeSanitizer: [_ValidatingTreeSanitizer, [NodeValidator]]}),
    methods: () => ({
      sanitizeTree: [dart.void, [Node]],
      [_removeNode]: [dart.void, [Node, Node]],
      [_sanitizeUntrustedElement]: [dart.void, [dart.dynamic, Node]],
      [_sanitizeElement]: [dart.void, [Element, Node, core.bool, core.String, core.String, core.Map, core.String]],
      sanitizeNode: [dart.void, [Node, Node]]
    })
  });
  dart.defineLazyProperties(exports, {
    get window() {
      return dart.as(wrap_jso(dart.global), Window);
    }
  });
  dart.copyProperties(exports, {
    get document() {
      return dart.as(wrap_jso(document), HtmlDocument);
    }
  });
  class _EntryArray extends core.Object {}
  _EntryArray[dart.implements] = () => [core.List$(dart.dynamic)];
  _EntryArray[dart.metadata] = () => [dart.const(new _js_helper.Native("EntryArray"))];
  function spawnDomUri(uri, args, message) {
    dart.throw(new core.UnimplementedError());
  }
  dart.fn(spawnDomUri, async.Future$(isolate.Isolate), [core.Uri, core.List$(core.String), dart.dynamic]);
  const _F1 = dart.typedef('_F1', () => dart.functionType(dart.dynamic, [dart.dynamic]));
  const _wrapper = Symbol("dart_wrapper");
  function unwrap_jso(wrapped) {
    if (dart.is(wrapped, DartHtmlDomObject)) {
      return wrapped.raw;
    }
    if (dart.is(wrapped, _F1)) {
      if (wrapped.hasOwnProperty(_wrapper)) {
        return wrapped[_wrapper];
      }
      let f = dart.fn(e => dart.dcall(wrapped, wrap_jso(e)));
      wrapped[_wrapper] = f;
      return f;
    }
    return wrapped;
  }
  dart.fn(unwrap_jso);
  function wrap_jso(jso) {
    if (jso == null || typeof jso == 'boolean' || typeof jso == 'number' || typeof jso == 'string') {
      return jso;
    }
    if (jso.hasOwnProperty(_wrapper)) {
      return jso[_wrapper];
    }
    let constructor = jso.constructor;
    let f = null;
    let name = null;
    let skip = null;
    while (f == null) {
      name = constructor.name;
      f = getHtmlCreateFunction(name);
      if (f == null) {
        if (skip == null) {
          skip = name;
        }
        constructor = constructor.__proto__;
      }
    }
    if (skip != null) {
      dart.dsend(/* Unimplemented unknown name */console, 'warn', `Instantiated ${name} instead of ${skip}`);
    }
    let wrapped = dart.dcall(f);
    dart.dput(wrapped, 'raw', jso);
    jso[_wrapper] = wrapped;
    return wrapped;
  }
  dart.fn(wrap_jso);
  function createCustomUpgrader(customElementClass, $this) {
    return $this;
  }
  dart.fn(createCustomUpgrader, dart.dynamic, [core.Type, dart.dynamic]);
  dart.defineLazyProperties(exports, {
    get htmlBlinkMap() {
      return dart.map({_HistoryCrossFrame: dart.fn(() => _HistoryCrossFrame, core.Type, []), _LocationCrossFrame: dart.fn(() => _LocationCrossFrame, core.Type, []), _DOMWindowCrossFrame: dart.fn(() => _DOMWindowCrossFrame, core.Type, []), DateTime: dart.fn(() => core.DateTime, core.Type, []), JsObject: dart.fn(() => dart.dload(/* Unimplemented unknown name */js, 'JsObjectImpl')), JsFunction: dart.fn(() => dart.dload(/* Unimplemented unknown name */js, 'JsFunctionImpl')), JsArray: dart.fn(() => dart.dload(/* Unimplemented unknown name */js, 'JsArrayImpl')), Attr: dart.fn(() => _Attr, core.Type, []), CSSStyleDeclaration: dart.fn(() => CssStyleDeclaration, core.Type, []), CharacterData: dart.fn(() => CharacterData, core.Type, []), ChildNode: dart.fn(() => ChildNode, core.Type, []), ClientRect: dart.fn(() => _ClientRect, core.Type, []), Comment: dart.fn(() => Comment, core.Type, []), Console: dart.fn(() => Console, core.Type, []), ConsoleBase: dart.fn(() => ConsoleBase, core.Type, []), CustomEvent: dart.fn(() => CustomEvent, core.Type, []), DOMImplementation: dart.fn(() => DomImplementation, core.Type, []), DOMTokenList: dart.fn(() => DomTokenList, core.Type, []), Document: dart.fn(() => Document, core.Type, []), DocumentFragment: dart.fn(() => DocumentFragment, core.Type, []), Element: dart.fn(() => Element, core.Type, []), Event: dart.fn(() => Event, core.Type, []), EventTarget: dart.fn(() => EventTarget, core.Type, []), HTMLAnchorElement: dart.fn(() => AnchorElement, core.Type, []), HTMLBaseElement: dart.fn(() => BaseElement, core.Type, []), HTMLBodyElement: dart.fn(() => BodyElement, core.Type, []), HTMLCollection: dart.fn(() => HtmlCollection, core.Type, []), HTMLDivElement: dart.fn(() => DivElement, core.Type, []), HTMLDocument: dart.fn(() => HtmlDocument, core.Type, []), HTMLElement: dart.fn(() => HtmlElement, core.Type, []), HTMLHeadElement: dart.fn(() => HeadElement, core.Type, []), HTMLHtmlElement: dart.fn(() => HtmlHtmlElement, core.Type, []), HTMLInputElement: dart.fn(() => InputElement, core.Type, []), HTMLStyleElement: dart.fn(() => StyleElement, core.Type, []), HTMLTemplateElement: dart.fn(() => TemplateElement, core.Type, []), History: dart.fn(() => History, core.Type, []), KeyboardEvent: dart.fn(() => KeyboardEvent, core.Type, []), Location: dart.fn(() => Location, core.Type, []), MouseEvent: dart.fn(() => MouseEvent, core.Type, []), NamedNodeMap: dart.fn(() => _NamedNodeMap, core.Type, []), Navigator: dart.fn(() => Navigator, core.Type, []), NavigatorCPU: dart.fn(() => NavigatorCpu, core.Type, []), Node: dart.fn(() => Node, core.Type, []), NodeList: dart.fn(() => NodeList, core.Type, []), ParentNode: dart.fn(() => ParentNode, core.Type, []), ProgressEvent: dart.fn(() => ProgressEvent, core.Type, []), Range: dart.fn(() => Range, core.Type, []), Screen: dart.fn(() => Screen, core.Type, []), ShadowRoot: dart.fn(() => ShadowRoot, core.Type, []), Text: dart.fn(() => Text, core.Type, []), UIEvent: dart.fn(() => UIEvent, core.Type, []), URLUtils: dart.fn(() => UrlUtils, core.Type, []), Window: dart.fn(() => Window, core.Type, []), XMLHttpRequest: dart.fn(() => HttpRequest, core.Type, []), XMLHttpRequestEventTarget: dart.fn(() => HttpRequestEventTarget, core.Type, []), XMLHttpRequestProgressEvent: dart.fn(() => _XMLHttpRequestProgressEvent, core.Type, [])});
    }
  });
  dart.defineLazyProperties(exports, {
    get htmlBlinkFunctionMap() {
      return dart.map({Attr: dart.fn(() => _Attr.internalCreate_Attr, dart.functionType(_Attr, []), []), CSSStyleDeclaration: dart.fn(() => CssStyleDeclaration.internalCreateCssStyleDeclaration, dart.functionType(CssStyleDeclaration, []), []), CharacterData: dart.fn(() => CharacterData.internalCreateCharacterData, dart.functionType(CharacterData, []), []), ClientRect: dart.fn(() => _ClientRect.internalCreate_ClientRect, dart.functionType(_ClientRect, []), []), Comment: dart.fn(() => Comment.internalCreateComment, dart.functionType(Comment, []), []), Console: dart.fn(() => Console.internalCreateConsole, dart.functionType(Console, []), []), ConsoleBase: dart.fn(() => ConsoleBase.internalCreateConsoleBase, dart.functionType(ConsoleBase, []), []), CustomEvent: dart.fn(() => CustomEvent.internalCreateCustomEvent, dart.functionType(CustomEvent, []), []), DOMImplementation: dart.fn(() => DomImplementation.internalCreateDomImplementation, dart.functionType(DomImplementation, []), []), DOMTokenList: dart.fn(() => DomTokenList.internalCreateDomTokenList, dart.functionType(DomTokenList, []), []), Document: dart.fn(() => Document.internalCreateDocument, dart.functionType(Document, []), []), DocumentFragment: dart.fn(() => DocumentFragment.internalCreateDocumentFragment, dart.functionType(DocumentFragment, []), []), Element: dart.fn(() => Element.internalCreateElement, dart.functionType(Element, []), []), Event: dart.fn(() => Event.internalCreateEvent, dart.functionType(Event, []), []), EventTarget: dart.fn(() => EventTarget.internalCreateEventTarget, dart.functionType(EventTarget, []), []), HTMLAnchorElement: dart.fn(() => AnchorElement.internalCreateAnchorElement, dart.functionType(AnchorElement, []), []), HTMLBaseElement: dart.fn(() => BaseElement.internalCreateBaseElement, dart.functionType(BaseElement, []), []), HTMLBodyElement: dart.fn(() => BodyElement.internalCreateBodyElement, dart.functionType(BodyElement, []), []), HTMLCollection: dart.fn(() => HtmlCollection.internalCreateHtmlCollection, dart.functionType(HtmlCollection, []), []), HTMLDivElement: dart.fn(() => DivElement.internalCreateDivElement, dart.functionType(DivElement, []), []), HTMLDocument: dart.fn(() => HtmlDocument.internalCreateHtmlDocument, dart.functionType(HtmlDocument, []), []), HTMLElement: dart.fn(() => HtmlElement.internalCreateHtmlElement, dart.functionType(HtmlElement, []), []), HTMLHeadElement: dart.fn(() => HeadElement.internalCreateHeadElement, dart.functionType(HeadElement, []), []), HTMLHtmlElement: dart.fn(() => HtmlHtmlElement.internalCreateHtmlHtmlElement, dart.functionType(HtmlHtmlElement, []), []), HTMLInputElement: dart.fn(() => InputElement.internalCreateInputElement, dart.functionType(InputElement, []), []), HTMLStyleElement: dart.fn(() => StyleElement.internalCreateStyleElement, dart.functionType(StyleElement, []), []), HTMLTemplateElement: dart.fn(() => TemplateElement.internalCreateTemplateElement, dart.functionType(TemplateElement, []), []), History: dart.fn(() => History.internalCreateHistory, dart.functionType(History, []), []), KeyboardEvent: dart.fn(() => KeyboardEvent.internalCreateKeyboardEvent, dart.functionType(KeyboardEvent, []), []), Location: dart.fn(() => Location.internalCreateLocation, dart.functionType(Location, []), []), MouseEvent: dart.fn(() => MouseEvent.internalCreateMouseEvent, dart.functionType(MouseEvent, []), []), NamedNodeMap: dart.fn(() => _NamedNodeMap.internalCreate_NamedNodeMap, dart.functionType(_NamedNodeMap, []), []), Navigator: dart.fn(() => Navigator.internalCreateNavigator, dart.functionType(Navigator, []), []), Node: dart.fn(() => Node.internalCreateNode, dart.functionType(Node, []), []), NodeList: dart.fn(() => NodeList.internalCreateNodeList, dart.functionType(NodeList, []), []), ProgressEvent: dart.fn(() => ProgressEvent.internalCreateProgressEvent, dart.functionType(ProgressEvent, []), []), Range: dart.fn(() => Range.internalCreateRange, dart.functionType(Range, []), []), Screen: dart.fn(() => Screen.internalCreateScreen, dart.functionType(Screen, []), []), ShadowRoot: dart.fn(() => ShadowRoot.internalCreateShadowRoot, dart.functionType(ShadowRoot, []), []), Text: dart.fn(() => Text.internalCreateText, dart.functionType(Text, []), []), UIEvent: dart.fn(() => UIEvent.internalCreateUIEvent, dart.functionType(UIEvent, []), []), Window: dart.fn(() => Window.internalCreateWindow, dart.functionType(Window, []), []), XMLHttpRequest: dart.fn(() => HttpRequest.internalCreateHttpRequest, dart.functionType(HttpRequest, []), []), XMLHttpRequestEventTarget: dart.fn(() => HttpRequestEventTarget.internalCreateHttpRequestEventTarget, dart.functionType(HttpRequestEventTarget, []), []), XMLHttpRequestProgressEvent: dart.fn(() => _XMLHttpRequestProgressEvent.internalCreate_XMLHttpRequestProgressEvent, dart.functionType(_XMLHttpRequestProgressEvent, []), [])});
    }
  });
  function getHtmlCreateFunction(key) {
    let result = null;
    result = _getHtmlFunction(key);
    if (result != null) {
      return result;
    }
    return null;
  }
  dart.fn(getHtmlCreateFunction, dart.dynamic, [core.String]);
  function _getHtmlFunction(key) {
    if (dart.notNull(exports.htmlBlinkFunctionMap.containsKey(key))) {
      return dart.as(dart.dcall(exports.htmlBlinkFunctionMap.get(key)), core.Function);
    }
    return null;
  }
  dart.fn(_getHtmlFunction, core.Function, [core.String]);
  const __CastType0 = dart.typedef('__CastType0', () => dart.functionType(core.bool, [Element]));
  const __CastType2 = dart.typedef('__CastType2', () => dart.functionType(dart.dynamic, [dart.dynamic]));
  // Exports:
  exports.DartHtmlDomObject = DartHtmlDomObject;
  exports.EventTarget = EventTarget;
  exports.Node = Node;
  exports.Element = Element;
  exports.HtmlElement = HtmlElement;
  exports.AnchorElement = AnchorElement;
  exports.BaseElement = BaseElement;
  exports.BodyElement = BodyElement;
  exports.CharacterData = CharacterData;
  exports.ChildNode = ChildNode;
  exports.Comment = Comment;
  exports.Console = Console;
  exports.ConsoleBase = ConsoleBase;
  exports.CssStyleDeclarationBase = CssStyleDeclarationBase;
  exports.CssStyleDeclaration = CssStyleDeclaration;
  exports.Event = Event;
  exports.CustomEvent = CustomEvent;
  exports.DivElement = DivElement;
  exports.Document = Document;
  exports.DocumentFragment = DocumentFragment;
  exports.DomImplementation = DomImplementation;
  exports.DomTokenList = DomTokenList;
  exports.ElementList$ = ElementList$;
  exports.ElementList = ElementList;
  exports.ScrollAlignment = ScrollAlignment;
  exports.Events = Events;
  exports.ElementEvents = ElementEvents;
  exports.HeadElement = HeadElement;
  exports.History = History;
  exports.ImmutableListMixin$ = ImmutableListMixin$;
  exports.ImmutableListMixin = ImmutableListMixin;
  exports.HtmlCollection = HtmlCollection;
  exports.HtmlDocument = HtmlDocument;
  exports.HtmlHtmlElement = HtmlHtmlElement;
  exports.HttpRequestEventTarget = HttpRequestEventTarget;
  exports.HttpRequest = HttpRequest;
  exports.InputElement = InputElement;
  exports.InputElementBase = InputElementBase;
  exports.HiddenInputElement = HiddenInputElement;
  exports.TextInputElementBase = TextInputElementBase;
  exports.SearchInputElement = SearchInputElement;
  exports.TextInputElement = TextInputElement;
  exports.UrlInputElement = UrlInputElement;
  exports.TelephoneInputElement = TelephoneInputElement;
  exports.EmailInputElement = EmailInputElement;
  exports.PasswordInputElement = PasswordInputElement;
  exports.RangeInputElementBase = RangeInputElementBase;
  exports.DateInputElement = DateInputElement;
  exports.MonthInputElement = MonthInputElement;
  exports.WeekInputElement = WeekInputElement;
  exports.TimeInputElement = TimeInputElement;
  exports.LocalDateTimeInputElement = LocalDateTimeInputElement;
  exports.NumberInputElement = NumberInputElement;
  exports.RangeInputElement = RangeInputElement;
  exports.CheckboxInputElement = CheckboxInputElement;
  exports.RadioButtonInputElement = RadioButtonInputElement;
  exports.FileUploadInputElement = FileUploadInputElement;
  exports.SubmitButtonInputElement = SubmitButtonInputElement;
  exports.ImageButtonInputElement = ImageButtonInputElement;
  exports.ResetButtonInputElement = ResetButtonInputElement;
  exports.ButtonInputElement = ButtonInputElement;
  exports.UIEvent = UIEvent;
  exports.KeyboardEvent = KeyboardEvent;
  exports.Location = Location;
  exports.MouseEvent = MouseEvent;
  exports.Navigator = Navigator;
  exports.NavigatorCpu = NavigatorCpu;
  exports.NodeList = NodeList;
  exports.ParentNode = ParentNode;
  exports.ProgressEvent = ProgressEvent;
  exports.Range = Range;
  exports.RequestAnimationFrameCallback = RequestAnimationFrameCallback;
  exports.Screen = Screen;
  exports.ShadowRoot = ShadowRoot;
  exports.StyleElement = StyleElement;
  exports.TemplateElement = TemplateElement;
  exports.Text = Text;
  exports.UrlUtils = UrlUtils;
  exports.Window = Window;
  exports.CanvasImageSource = CanvasImageSource;
  exports.WindowBase = WindowBase;
  exports.LocationBase = LocationBase;
  exports.HistoryBase = HistoryBase;
  exports.CssClassSet = CssClassSet;
  exports.CssRect = CssRect;
  exports.Dimension = Dimension;
  exports.EventListener = EventListener;
  exports.EventStreamProvider$ = EventStreamProvider$;
  exports.EventStreamProvider = EventStreamProvider;
  exports.ElementStream$ = ElementStream$;
  exports.ElementStream = ElementStream;
  exports.CustomStream$ = CustomStream$;
  exports.CustomStream = CustomStream;
  exports.KeyEvent = KeyEvent;
  exports.KeyCode = KeyCode;
  exports.KeyLocation = KeyLocation;
  exports.KeyboardEventStream = KeyboardEventStream;
  exports.NodeValidatorBuilder = NodeValidatorBuilder;
  exports.ReadyState = ReadyState;
  exports.FixedSizeListIterator$ = FixedSizeListIterator$;
  exports.FixedSizeListIterator = FixedSizeListIterator;
  exports.Platform = Platform;
  exports.query = query;
  exports.queryAll = queryAll;
  exports.querySelector = querySelector;
  exports.querySelectorAll = querySelectorAll;
  exports.ElementUpgrader = ElementUpgrader;
  exports.NodeValidator = NodeValidator;
  exports.NodeTreeSanitizer = NodeTreeSanitizer;
  exports.UriPolicy = UriPolicy;
  exports.spawnDomUri = spawnDomUri;
  exports.unwrap_jso = unwrap_jso;
  exports.wrap_jso = wrap_jso;
  exports.createCustomUpgrader = createCustomUpgrader;
  exports.getHtmlCreateFunction = getHtmlCreateFunction;
});
