// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface WindowEvents extends Events {
  EventListenerList get abort();
  EventListenerList get beforeUnload();
  EventListenerList get blur();
  EventListenerList get canPlay();
  EventListenerList get canPlayThrough();
  EventListenerList get change();
  EventListenerList get click();
  EventListenerList get contextMenu();
  EventListenerList get dblClick();
  EventListenerList get deviceMotion();
  EventListenerList get deviceOrientation();
  EventListenerList get drag();
  EventListenerList get dragEnd();
  EventListenerList get dragEnter();
  EventListenerList get dragLeave();
  EventListenerList get dragOver();
  EventListenerList get dragStart();
  EventListenerList get drop();
  EventListenerList get durationChange();
  EventListenerList get emptied();
  EventListenerList get ended();
  EventListenerList get error();
  EventListenerList get focus();
  EventListenerList get hashChange();
  EventListenerList get input();
  EventListenerList get invalid();
  EventListenerList get keyDown();
  EventListenerList get keyPress();
  EventListenerList get keyUp();
  EventListenerList get load();
  EventListenerList get loadedData();
  EventListenerList get loadedMetaData();
  EventListenerList get loadStart();
  EventListenerList get message();
  EventListenerList get mouseDown();
  EventListenerList get mouseMove();
  EventListenerList get mouseOut();
  EventListenerList get mouseOver();
  EventListenerList get mouseUp();
  EventListenerList get mouseWheel();
  EventListenerList get offline();
  EventListenerList get online();
  EventListenerList get pageHide();
  EventListenerList get pageShow();
  EventListenerList get pause();
  EventListenerList get play();
  EventListenerList get playing();
  EventListenerList get popState();
  EventListenerList get progress();
  EventListenerList get rateChange();
  EventListenerList get reset();
  EventListenerList get resize();
  EventListenerList get scroll();
  EventListenerList get search();
  EventListenerList get seeked();
  EventListenerList get seeking();
  EventListenerList get select();
  EventListenerList get stalled();
  EventListenerList get storage();
  EventListenerList get submit();
  EventListenerList get suspend();
  EventListenerList get timeUpdate();
  EventListenerList get touchCancel();
  EventListenerList get touchEnd();
  EventListenerList get touchMove();
  EventListenerList get touchStart();
  EventListenerList get unLoad();
  EventListenerList get volumeChange();
  EventListenerList get waiting();
  EventListenerList get animationEnd();
  EventListenerList get animationIteration();
  EventListenerList get animationStart();
  EventListenerList get transitionEnd();
  EventListenerList get contentLoaded();
}

interface Window extends EventTarget {

  DOMApplicationCache get applicationCache();

  Navigator get clientInformation();

  void set clientInformation(Navigator value);

  bool get closed();

  Console get console();

  void set console(Console value);

  Crypto get crypto();

  String get defaultStatus();

  void set defaultStatus(String value);

  num get devicePixelRatio();

  void set devicePixelRatio(num value);

  Document get document();

  Event get event();

  void set event(Event value);

  Element get frameElement();

  Window get frames();

  void set frames(Window value);

  History get history();

  void set history(History value);

  int get innerHeight();

  void set innerHeight(int value);

  int get innerWidth();

  void set innerWidth(int value);

  int get length();

  void set length(int value);

  Storage get localStorage();

  Location get location();

  void set location(Location value);

  BarInfo get locationbar();

  void set locationbar(BarInfo value);

  BarInfo get menubar();

  void set menubar(BarInfo value);

  String get name();

  void set name(String value);

  Navigator get navigator();

  void set navigator(Navigator value);

  bool get offscreenBuffering();

  void set offscreenBuffering(bool value);

  Window get opener();

  void set opener(Window value);

  int get outerHeight();

  void set outerHeight(int value);

  int get outerWidth();

  void set outerWidth(int value);

  int get pageXOffset();

  int get pageYOffset();

  Window get parent();

  void set parent(Window value);

  BarInfo get personalbar();

  void set personalbar(BarInfo value);

  Screen get screen();

  void set screen(Screen value);

  int get screenLeft();

  void set screenLeft(int value);

  int get screenTop();

  void set screenTop(int value);

  int get screenX();

  void set screenX(int value);

  int get screenY();

  void set screenY(int value);

  int get scrollX();

  void set scrollX(int value);

  int get scrollY();

  void set scrollY(int value);

  BarInfo get scrollbars();

  void set scrollbars(BarInfo value);

  Window get self();

  void set self(Window value);

  Storage get sessionStorage();

  String get status();

  void set status(String value);

  BarInfo get statusbar();

  void set statusbar(BarInfo value);

  StyleMedia get styleMedia();

  BarInfo get toolbar();

  void set toolbar(BarInfo value);

  Window get top();

  void set top(Window value);

  NotificationCenter get webkitNotifications();

  void alert([String message]);

  String atob([String string]);

  void blur();

  String btoa([String string]);

  void captureEvents();

  void clearInterval([int handle]);

  void clearTimeout([int handle]);

  void close();

  bool confirm([String message]);

  FileReader createFileReader();

  bool find([String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog]);

  void focus();

  CSSStyleDeclaration getComputedStyle([Element element, String pseudoElement]);

  DOMSelection getSelection();

  MediaQueryList matchMedia(String query);

  void moveBy(num x, num y);

  void moveTo(num x, num y);

  Window open(String url, String target, [String features]);

  void postMessage(String message, [var messagePort, String targetOrigin]);

  void print();

  String prompt([String message, String defaultValue]);

  void releaseEvents();

  void resizeBy(num x, num y);

  void resizeTo(num width, num height);

  void scroll(int x, int y);

  void scrollBy(int x, int y);

  void scrollTo(int x, int y);

  int setInterval(TimeoutHandler handler, int timeout);

  int setTimeout([TimeoutHandler handler, int timeout]);

  Object showModalDialog(String url, [Object dialogArgs, String featureArgs]);

  void stop();

  void webkitCancelRequestAnimationFrame(int id);

  Point webkitConvertPointFromNodeToPage([Node node, Point p]);

  Point webkitConvertPointFromPageToNode([Node node, Point p]);

  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback, [Element element]);

  // Window open(String url, String target, WindowSpec features);

  WindowEvents get on();
}
