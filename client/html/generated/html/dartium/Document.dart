// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _DocumentImpl extends _ElementImpl
    implements Document {

  Element get activeElement() => _wrap(_documentPtr.activeElement);

  Element get body() => _wrap(_documentPtr.body);

  void set body(Element value) { _documentPtr.body = _unwrap(value); }

  String get charset() => _wrap(_documentPtr.charset);

  void set charset(String value) { _documentPtr.charset = _unwrap(value); }

  String get cookie() => _wrap(_documentPtr.cookie);

  void set cookie(String value) { _documentPtr.cookie = _unwrap(value); }

  Window get window() => _wrap(_documentPtr.defaultView);

  String get domain() => _wrap(_documentPtr.domain);

  HeadElement get head() => _wrap(_documentPtr.head);

  String get lastModified() => _wrap(_documentPtr.lastModified);

  String get preferredStylesheetSet() => _wrap(_documentPtr.preferredStylesheetSet);

  String get readyState() => _wrap(_documentPtr.readyState);

  String get referrer() => _wrap(_documentPtr.referrer);

  String get selectedStylesheetSet() => _wrap(_documentPtr.selectedStylesheetSet);

  void set selectedStylesheetSet(String value) { _documentPtr.selectedStylesheetSet = _unwrap(value); }

  StyleSheetList get styleSheets() => _wrap(_documentPtr.styleSheets);

  String get title() => _wrap(_documentPtr.title);

  void set title(String value) { _documentPtr.title = _unwrap(value); }

  Element get webkitCurrentFullScreenElement() => _wrap(_documentPtr.webkitCurrentFullScreenElement);

  bool get webkitFullScreenKeyboardInputAllowed() => _wrap(_documentPtr.webkitFullScreenKeyboardInputAllowed);

  bool get webkitHidden() => _wrap(_documentPtr.webkitHidden);

  bool get webkitIsFullScreen() => _wrap(_documentPtr.webkitIsFullScreen);

  String get webkitVisibilityState() => _wrap(_documentPtr.webkitVisibilityState);

  _DocumentEventsImpl get on() {
    if (_on == null) _on = new _DocumentEventsImpl(_wrappedDocumentPtr);
    return _on;
  }

  Range caretRangeFromPoint(int x, int y) {
    return _wrap(_documentPtr.caretRangeFromPoint(_unwrap(x), _unwrap(y)));
  }

  CDATASection createCDATASection(String data) {
    return _wrap(_documentPtr.createCDATASection(_unwrap(data)));
  }

  DocumentFragment createDocumentFragment() {
    return _wrap(_documentPtr.createDocumentFragment());
  }

  Element _createElement(String tagName) {
    return _wrap(_documentPtr.createElement(_unwrap(tagName)));
  }

  Event _createEvent(String eventType) {
    return _wrap(_documentPtr.createEvent(_unwrap(eventType)));
  }

  Range createRange() {
    return _wrap(_documentPtr.createRange());
  }

  Text _createTextNode(String data) {
    return _wrap(_documentPtr.createTextNode(_unwrap(data)));
  }

  Touch createTouch(Window window, EventTarget target, int identifier, int pageX, int pageY, int screenX, int screenY, int webkitRadiusX, int webkitRadiusY, num webkitRotationAngle, num webkitForce) {
    return _wrap(_documentPtr.createTouch(_unwrap(window), _unwrap(target), _unwrap(identifier), _unwrap(pageX), _unwrap(pageY), _unwrap(screenX), _unwrap(screenY), _unwrap(webkitRadiusX), _unwrap(webkitRadiusY), _unwrap(webkitRotationAngle), _unwrap(webkitForce)));
  }

  TouchList _createTouchList() {
    return _wrap(_documentPtr.createTouchList());
  }

  Element elementFromPoint(int x, int y) {
    return _wrap(_documentPtr.elementFromPoint(_unwrap(x), _unwrap(y)));
  }

  bool execCommand(String command, bool userInterface, String value) {
    return _wrap(_documentPtr.execCommand(_unwrap(command), _unwrap(userInterface), _unwrap(value)));
  }

  CanvasRenderingContext getCSSCanvasContext(String contextId, String name, int width, int height) {
    return _wrap(_documentPtr.getCSSCanvasContext(_unwrap(contextId), _unwrap(name), _unwrap(width), _unwrap(height)));
  }

  bool queryCommandEnabled(String command) {
    return _wrap(_documentPtr.queryCommandEnabled(_unwrap(command)));
  }

  bool queryCommandIndeterm(String command) {
    return _wrap(_documentPtr.queryCommandIndeterm(_unwrap(command)));
  }

  bool queryCommandState(String command) {
    return _wrap(_documentPtr.queryCommandState(_unwrap(command)));
  }

  bool queryCommandSupported(String command) {
    return _wrap(_documentPtr.queryCommandSupported(_unwrap(command)));
  }

  String queryCommandValue(String command) {
    return _wrap(_documentPtr.queryCommandValue(_unwrap(command)));
  }

  void webkitCancelFullScreen() {
    _documentPtr.webkitCancelFullScreen();
    return;
  }

  WebKitNamedFlow webkitGetFlowByName(String name) {
    return _wrap(_documentPtr.webkitGetFlowByName(_unwrap(name)));
  }


  final dom.HTMLDocument _documentPtr;
  final _NodeImpl _wrappedDocumentPtr;
 
_DocumentImpl._wrap(ptr) :
  super._wrap(ptr),
  _documentPtr = ptr.parentNode,
  _wrappedDocumentPtr = ptr.parentNode != null ?
      new _SecretHtmlDocumentImpl._wrap(ptr.parentNode) : null;

  // For efficiency and simplicity, we always use the HtmlElement as the
  // Document but sometimes internally we need the real JS document object.
  _NodeImpl get _rawDocument() => _wrappedDocumentPtr;

  // The document doesn't have a parent element.
  _ElementImpl get parent() => null;
}

// This class should not be externally visible.  If a user ever gets access to
// a _SecretHtmlDocumentImpl object that is a bug.  This object is hidden by
// adding checks to all methods that could an HTMLDocument.  We believe that
// list is limited to Event.target, and HTMLHtmlElement.parent.
// In a wrapper based world there isn't a need for this complexity but we
// use this design for consistency with the wrapperless implementation so
// that bugs show up in both cases.
class _SecretHtmlDocumentImpl extends _NodeImpl implements Node {

  _SecretHtmlDocumentImpl._wrap(ptr) : super._wrap(ptr);

  _DocumentImpl get _documentElement() => _wrap(_ptr.documentElement);
}

EventTarget _FixHtmlDocumentReference(EventTarget eventTarget) {
  if (eventTarget is _SecretHtmlDocumentImpl) {
    _SecretHtmlDocumentImpl secretDocument = eventTarget;
    return secretDocument._documentElement;
  } else {
    return eventTarget;
  }
}

class _DocumentEventsImpl extends _ElementEventsImpl implements DocumentEvents {
  _DocumentEventsImpl(_ptr) : super(_ptr);

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

  EventListenerList get readyStateChange() => _get('readystatechange');

  EventListenerList get reset() => _get('reset');

  EventListenerList get scroll() => _get('scroll');

  EventListenerList get search() => _get('search');

  EventListenerList get select() => _get('select');

  EventListenerList get selectStart() => _get('selectstart');

  EventListenerList get selectionChange() => _get('selectionchange');

  EventListenerList get submit() => _get('submit');

  EventListenerList get touchCancel() => _get('touchcancel');

  EventListenerList get touchEnd() => _get('touchend');

  EventListenerList get touchMove() => _get('touchmove');

  EventListenerList get touchStart() => _get('touchstart');
}
