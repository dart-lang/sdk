// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _DocumentImpl extends _ElementImpl
    implements Document
    native "*HTMLHtmlElement" {

  _ElementImpl get activeElement() native "return this.parentNode.activeElement;";

  _ElementImpl get body() native "return this.parentNode.body;";

  void set body(_ElementImpl value) native "this.parentNode.body = value;";

  String get charset() native "return this.parentNode.charset;";

  void set charset(String value) native "this.parentNode.charset = value;";

  String get cookie() native "return this.parentNode.cookie;";

  void set cookie(String value) native "this.parentNode.cookie = value;";

  _WindowImpl get window() native "return this.parentNode.defaultView;";

  String get domain() native "return this.parentNode.domain;";

  _HeadElementImpl get head() native "return this.parentNode.head;";

  String get lastModified() native "return this.parentNode.lastModified;";

  String get preferredStylesheetSet() native "return this.parentNode.preferredStylesheetSet;";

  String get readyState() native "return this.parentNode.readyState;";

  String get referrer() native "return this.parentNode.referrer;";

  String get selectedStylesheetSet() native "return this.parentNode.selectedStylesheetSet;";

  void set selectedStylesheetSet(String value) native "this.parentNode.selectedStylesheetSet = value;";

  _StyleSheetListImpl get styleSheets() native "return this.parentNode.styleSheets;";

  String get title() native "return this.parentNode.title;";

  void set title(String value) native "this.parentNode.title = value;";

  _ElementImpl get webkitCurrentFullScreenElement() native "return this.parentNode.webkitCurrentFullScreenElement;";

  bool get webkitFullScreenKeyboardInputAllowed() native "return this.parentNode.webkitFullScreenKeyboardInputAllowed;";

  bool get webkitHidden() native "return this.parentNode.webkitHidden;";

  bool get webkitIsFullScreen() native "return this.parentNode.webkitIsFullScreen;";

  String get webkitVisibilityState() native "return this.parentNode.webkitVisibilityState;";

  _DocumentEventsImpl get on() =>
    new _DocumentEventsImpl(_jsDocument);

  _RangeImpl caretRangeFromPoint(int x, int y) native "return this.parentNode.caretRangeFromPoint(x, y);";

  _CDATASectionImpl createCDATASection(String data) native "return this.parentNode.createCDATASection(data);";

  _DocumentFragmentImpl createDocumentFragment() native "return this.parentNode.createDocumentFragment();";

  _ElementImpl _createElement(String tagName) native "return this.parentNode.createElement(tagName);";

  _EventImpl _createEvent(String eventType) native "return this.parentNode.createEvent(eventType);";

  _RangeImpl createRange() native "return this.parentNode.createRange();";

  _TextImpl _createTextNode(String data) native "return this.parentNode.createTextNode(data);";

  _TouchImpl createTouch(_WindowImpl window, _EventTargetImpl target, int identifier, int pageX, int pageY, int screenX, int screenY, int webkitRadiusX, int webkitRadiusY, num webkitRotationAngle, num webkitForce) native "return this.parentNode.createTouch(window, target, identifier, pageX, pageY, screenX, screenY, webkitRadiusX, webkitRadiusY, webkitRotationAngle, webkitForce);";

  _TouchListImpl _createTouchList() native "return this.parentNode.createTouchList();";

  _ElementImpl elementFromPoint(int x, int y) native "return this.parentNode.elementFromPoint(x, y);";

  bool execCommand(String command, bool userInterface, String value) native "return this.parentNode.execCommand(command, userInterface, value);";

  _CanvasRenderingContextImpl getCSSCanvasContext(String contextId, String name, int width, int height) native "return this.parentNode.getCSSCanvasContext(contextId, name, width, height);";

  bool queryCommandEnabled(String command) native "return this.parentNode.queryCommandEnabled(command);";

  bool queryCommandIndeterm(String command) native "return this.parentNode.queryCommandIndeterm(command);";

  bool queryCommandState(String command) native "return this.parentNode.queryCommandState(command);";

  bool queryCommandSupported(String command) native "return this.parentNode.queryCommandSupported(command);";

  String queryCommandValue(String command) native "return this.parentNode.queryCommandValue(command);";

  void webkitCancelFullScreen() native "this.parentNode.webkitCancelFullScreen();";

  _WebKitNamedFlowImpl webkitGetFlowByName(String name) native "return this.parentNode.webkitGetFlowByName(name);";


  // For efficiency and simplicity, we always use the HtmlElement as the
  // Document but sometimes internally we need the real JS document object.
  _NodeImpl get _jsDocument() native "return this.parentNode;";

  // The document doesn't have a parent element.
  _ElementImpl get parent() => null;
}

// This class should not be externally visible.  If a user ever gets access to
// a _SecretHtmlDocumentImpl object that is a bug.  This object is hidden by
// adding checks to all methods that could an HTMLDocument.  We believe that
// list is limited to Event.target, and HTMLHtmlElement.parent.
class _SecretHtmlDocumentImpl extends _NodeImpl implements Node
    native "*HTMLDocument" {
  _DocumentImpl get _documentElement() native "return this.documentElement;";
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
