// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Document extends HtmlElement {


  DocumentEvents get on();

  final Element activeElement;

  Element body;

  String charset;

  String cookie;

  final Window window;

  final String domain;

  final HeadElement head;

  final String lastModified;

  final String preferredStylesheetSet;

  final String readyState;

  final String referrer;

  String selectedStylesheetSet;

  final StyleSheetList styleSheets;

  String title;

  final Element webkitCurrentFullScreenElement;

  final bool webkitFullScreenKeyboardInputAllowed;

  final bool webkitHidden;

  final bool webkitIsFullScreen;

  final String webkitVisibilityState;

  Range caretRangeFromPoint(int x, int y);

  CDATASection createCDATASection(String data);

  DocumentFragment createDocumentFragment();

  Element _createElement(String tagName);

  Event _createEvent(String eventType);

  Range createRange();

  Text _createTextNode(String data);

  Touch createTouch(Window window, EventTarget target, int identifier, int pageX, int pageY, int screenX, int screenY, int webkitRadiusX, int webkitRadiusY, num webkitRotationAngle, num webkitForce);

  TouchList _createTouchList();

  Element elementFromPoint(int x, int y);

  bool execCommand(String command, bool userInterface, String value);

  CanvasRenderingContext getCSSCanvasContext(String contextId, String name, int width, int height);

  bool queryCommandEnabled(String command);

  bool queryCommandIndeterm(String command);

  bool queryCommandState(String command);

  bool queryCommandSupported(String command);

  String queryCommandValue(String command);

  void webkitCancelFullScreen();

  WebKitNamedFlow webkitGetFlowByName(String name);

}

interface DocumentEvents extends ElementEvents {

  EventListenerList get abort();

  EventListenerList get beforeCopy();

  EventListenerList get beforeCut();

  EventListenerList get beforePaste();

  EventListenerList get blur();

  EventListenerList get change();

  EventListenerList get click();

  EventListenerList get contextMenu();

  EventListenerList get copy();

  EventListenerList get cut();

  EventListenerList get doubleClick();

  EventListenerList get drag();

  EventListenerList get dragEnd();

  EventListenerList get dragEnter();

  EventListenerList get dragLeave();

  EventListenerList get dragOver();

  EventListenerList get dragStart();

  EventListenerList get drop();

  EventListenerList get error();

  EventListenerList get focus();

  EventListenerList get fullscreenChange();

  EventListenerList get fullscreenError();

  EventListenerList get input();

  EventListenerList get invalid();

  EventListenerList get keyDown();

  EventListenerList get keyPress();

  EventListenerList get keyUp();

  EventListenerList get load();

  EventListenerList get mouseDown();

  EventListenerList get mouseMove();

  EventListenerList get mouseOut();

  EventListenerList get mouseOver();

  EventListenerList get mouseUp();

  EventListenerList get mouseWheel();

  EventListenerList get paste();

  EventListenerList get readyStateChange();

  EventListenerList get reset();

  EventListenerList get scroll();

  EventListenerList get search();

  EventListenerList get select();

  EventListenerList get selectStart();

  EventListenerList get selectionChange();

  EventListenerList get submit();

  EventListenerList get touchCancel();

  EventListenerList get touchEnd();

  EventListenerList get touchMove();

  EventListenerList get touchStart();
}
