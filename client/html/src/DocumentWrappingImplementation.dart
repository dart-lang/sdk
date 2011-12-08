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

/** @domName Document, HTMLDocument */
class DocumentWrappingImplementation extends ElementWrappingImplementation implements Document {

  final _documentPtr;

  DocumentWrappingImplementation._wrap(this._documentPtr, ptr) : super._wrap(ptr) {
    // We have to set the back ptr on the document as well as the documentElement
    // so that it is always simple to detect when an existing wrapper exists.
    _documentPtr.dynamic.dartObjectLocalStorage = this;
  }

  /** @domName activeElement */
  Element get activeElement() => LevelDom.wrapElement(_documentPtr.dynamic.activeElement);

  Node get parent() => null;

  /** @domName body */
  Element get body() => LevelDom.wrapElement(_documentPtr.body);

  /** @domName body */
  void set body(Element value) { _documentPtr.body = LevelDom.unwrap(value); }

  /** @domName charset */
  String get charset() => _documentPtr.charset;

  /** @domName charset */
  void set charset(String value) { _documentPtr.charset = value; }

  /** @domName cookie */
  String get cookie() => _documentPtr.cookie;

  /** @domName cookie */
  void set cookie(String value) { _documentPtr.cookie = value; }

  /** @domName defaultView */
  Window get window() => LevelDom.wrapWindow(_documentPtr.defaultView);

  /** @domName designMode */
  void set designMode(String value) { _documentPtr.dynamic.designMode = value; }

  /** @domName domain */
  String get domain() => _documentPtr.domain;

  /** @domName head */
  HeadElement get head() => LevelDom.wrapHeadElement(_documentPtr.head);

  /** @domName lastModified */
  String get lastModified() => _documentPtr.lastModified;

  /** @domName readyState */
  String get readyState() => _documentPtr.readyState;

  /** @domName referrer */
  String get referrer() => _documentPtr.referrer;

  /** @domName styleSheets */
  StyleSheetList get styleSheets() => LevelDom.wrapStyleSheetList(_documentPtr.styleSheets);

  /** @domName title */
  String get title() => _documentPtr.title;

  /** @domName title */
  void set title(String value) { _documentPtr.title = value; }

  /** @domName webkitHidden */
  bool get webkitHidden() => _documentPtr.webkitHidden;

  /** @domName webkitVisibilityState */
  String get webkitVisibilityState() => _documentPtr.webkitVisibilityState;

  /** @domName caretRangeFromPoint */
  Future<Range> caretRangeFromPoint([int x = null, int y = null]) {
    return _createMeasurementFuture(
        () => LevelDom.wrapRange(_documentPtr.caretRangeFromPoint(x, y)),
        new Completer<Range>());
  }

  /** @domName createEvent */
  Event createEvent(String eventType) {
    return LevelDom.wrapEvent(_documentPtr.createEvent(eventType));
  }

  /** @domName elementFromPoint */
  Future<Element> elementFromPoint([int x = null, int y = null]) {
    return _createMeasurementFuture(
        () => LevelDom.wrapElement(_documentPtr.elementFromPoint(x, y)),
        new Completer<Element>());
  }

  /** @domName execCommand */
  bool execCommand([String command = null, bool userInterface = null, String value = null]) {
    return _documentPtr.execCommand(command, userInterface, value);
  }

  /** @domName getCSSCanvasContext */
  CanvasRenderingContext getCSSCanvasContext(String contextId, String name,
                                             int width, int height) {
    return LevelDom.wrapCanvasRenderingContext(_documentPtr.getCSSCanvasContext(contextId, name, width, height));
  }

  /** @domName queryCommandEnabled */
  bool queryCommandEnabled([String command = null]) {
    return _documentPtr.queryCommandEnabled(command);
  }

  /** @domName queryCommandIndeterm */
  bool queryCommandIndeterm([String command = null]) {
    return _documentPtr.queryCommandIndeterm(command);
  }

  /** @domName queryCommandState */
  bool queryCommandState([String command = null]) {
    return _documentPtr.queryCommandState(command);
  }

  /** @domName queryCommandSupported */
  bool queryCommandSupported([String command = null]) {
    return _documentPtr.queryCommandSupported(command);
  }

  /** @domName queryCommandValue */
  String queryCommandValue([String command = null]) {
    return _documentPtr.queryCommandValue(command);
  }

  /** @domName HTMLHtmlElement.manifest */
  String get manifest() => _ptr.manifest;

  /** @domName HTMLHtmlElement.manifest */
  void set manifest(String value) { _ptr.manifest = value; }

  DocumentEvents get on() {
    if (_on === null) {
      _on = new DocumentEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
