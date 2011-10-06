// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DocumentEventsImplementation extends ElementEventsImplementation
      implements DocumentEvents {
  
  DocumentEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get readyStateChange() => _get('readystatechange');

  EventListenerList get selectionChange() => _get('selectionchange');

  EventListenerList get contentLoaded() => _get('DOMContentLoaded');
}

class DocumentWrappingImplementation extends ElementWrappingImplementation implements Document {
  final _documentPtr;

  DocumentWrappingImplementation._wrap(this._documentPtr, ptr) : super._wrap(ptr) {
    // We have to set the back ptr on the document as well as the documentElement
    // so that it is always simple to detect when an existing wrapper exists.
    _documentPtr.dartObjectLocalStorage = this;
  }

  Element get activeElement() => LevelDom.wrapElement(_documentPtr.activeElement);

  Node get parent() => null;

  Element get body() => LevelDom.wrapElement(_documentPtr.body);

  void set body(Element value) { _documentPtr.body = LevelDom.unwrap(value); }

  String get charset() => _documentPtr.charset;

  void set charset(String value) { _documentPtr.charset = value; }

  String get cookie() => _documentPtr.cookie;

  void set cookie(String value) { _documentPtr.cookie = value; }

  Window get window() => LevelDom.wrapWindow(_documentPtr.defaultView);

  void set designMode(String value) { _documentPtr.designMode = value; }

  String get domain() => _documentPtr.domain;

  HeadElement get head() => LevelDom.wrapHeadElement(_documentPtr.head);

  String get lastModified() => _documentPtr.lastModified;

  String get readyState() => _documentPtr.readyState;

  String get referrer() => _documentPtr.referrer;

  StyleSheetList get styleSheets() => LevelDom.wrapStyleSheetList(_documentPtr.styleSheets);

  String get title() => _documentPtr.title;

  void set title(String value) { _documentPtr.title = value; }

  bool get webkitHidden() => _documentPtr.webkitHidden;

  String get webkitVisibilityState() => _documentPtr.webkitVisibilityState;

  Promise<Range> caretRangeFromPoint([int x = null, int y = null]) {
    throw 'TODO(jacobr): impl promise.';
    // return LevelDom.wrapRange(_documentPtr.caretRangeFromPoint(x, y));
  }

  Element createElement([String tagName = null]) {
    return LevelDom.wrapElement(_documentPtr.createElement(tagName));
  }

  Event createEvent([String eventType = null]) {
    return LevelDom.wrapEvent(_documentPtr.createEvent(eventType));
  }

  Promise<Element> elementFromPoint([int x = null, int y = null]) {
    throw 'TODO(jacobr): impl using promise';
    // return LevelDom.wrapElement(_documentPtr.elementFromPoint(x, y));
  }

  bool execCommand([String command = null, bool userInterface = null, String value = null]) {
    return _documentPtr.execCommand(command, userInterface, value);
  }

  CanvasRenderingContext getCSSCanvasContext(String contextId, String name,
                                             int width, int height) {
    return LevelDom.wrapCanvasRenderingContext(_documentPtr.getCSSCanvasContext(contextId, name, width, height));
  }

  bool queryCommandEnabled([String command = null]) {
    return _documentPtr.queryCommandEnabled(command);
  }

  bool queryCommandIndeterm([String command = null]) {
    return _documentPtr.queryCommandIndeterm(command);
  }

  bool queryCommandState([String command = null]) {
    return _documentPtr.queryCommandState(command);
  }

  bool queryCommandSupported([String command = null]) {
    return _documentPtr.queryCommandSupported(command);
  }

  String queryCommandValue([String command = null]) {
    return _documentPtr.queryCommandValue(command);
  }

  String get manifest() => _ptr.manifest;

  void set manifest(String value) { _ptr.manifest = value; }

  DocumentEvents get on() {
    if (_on === null) {
      _on = new DocumentEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
