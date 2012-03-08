// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Window extends EventTarget {

  final Document document;

  /**
   * Executes a [callback] after the next batch of browser layout measurements
   * has completed or would have completed if any browser layout measurements
   * had been scheduled.
   */
  void requestLayoutFrame(TimeoutHandler callback);


  WindowEvents get on();

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  final DOMApplicationCache applicationCache;

  final Navigator clientInformation;

  final bool closed;

  final Console console;

  final Crypto crypto;

  String defaultStatus;

  String defaultstatus;

  final num devicePixelRatio;

  final Event event;

  final Element frameElement;

  final Window frames;

  final History history;

  final int innerHeight;

  final int innerWidth;

  final int length;

  final Storage localStorage;

  Location location;

  final BarInfo locationbar;

  final BarInfo menubar;

  String name;

  final Navigator navigator;

  final bool offscreenBuffering;

  final Window opener;

  final int outerHeight;

  final int outerWidth;

  final int pageXOffset;

  final int pageYOffset;

  final Window parent;

  final Performance performance;

  final BarInfo personalbar;

  final Screen screen;

  final int screenLeft;

  final int screenTop;

  final int screenX;

  final int screenY;

  final int scrollX;

  final int scrollY;

  final BarInfo scrollbars;

  final Window self;

  final Storage sessionStorage;

  String status;

  final BarInfo statusbar;

  final StyleMedia styleMedia;

  final BarInfo toolbar;

  final Window top;

  final IDBFactory webkitIndexedDB;

  final NotificationCenter webkitNotifications;

  final StorageInfo webkitStorageInfo;

  final Window window;

  void _addEventListener(String type, EventListener listener, [bool useCapture]);

  void alert(String message);

  String atob(String string);

  void blur();

  String btoa(String string);

  void captureEvents();

  void clearInterval(int handle);

  void clearTimeout(int handle);

  void close();

  bool confirm(String message);

  bool _dispatchEvent(Event evt);

  bool find(String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog);

  void focus();

  CSSStyleDeclaration _getComputedStyle(Element element, String pseudoElement);

  CSSRuleList getMatchedCSSRules(Element element, String pseudoElement);

  DOMSelection getSelection();

  MediaQueryList matchMedia(String query);

  void moveBy(num x, num y);

  void moveTo(num x, num y);

  Window open(String url, String name, [String options]);

  Database openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]);

  void postMessage(Dynamic message, String targetOrigin, [List messagePorts]);

  void print();

  String prompt(String message, String defaultValue);

  void releaseEvents();

  void _removeEventListener(String type, EventListener listener, [bool useCapture]);

  void resizeBy(num x, num y);

  void resizeTo(num width, num height);

  void scroll(int x, int y);

  void scrollBy(int x, int y);

  void scrollTo(int x, int y);

  int setInterval(TimeoutHandler handler, int timeout);

  int setTimeout(TimeoutHandler handler, int timeout);

  Object showModalDialog(String url, [Object dialogArgs, String featureArgs]);

  void stop();

  void webkitCancelAnimationFrame(int id);

  void webkitCancelRequestAnimationFrame(int id);

  Point webkitConvertPointFromNodeToPage(Node node, Point p);

  Point webkitConvertPointFromPageToNode(Node node, Point p);

  void webkitPostMessage(Dynamic message, String targetOrigin, [List transferList]);

  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback, Element element);

  void webkitRequestFileSystem(int type, int size, FileSystemCallback successCallback, [ErrorCallback errorCallback]);

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback, ErrorCallback errorCallback]);

}

interface WindowEvents extends Events {

  EventListenerList get abort();

  EventListenerList get animationEnd();

  EventListenerList get animationIteration();

  EventListenerList get animationStart();

  EventListenerList get beforeUnload();

  EventListenerList get blur();

  EventListenerList get canPlay();

  EventListenerList get canPlayThrough();

  EventListenerList get change();

  EventListenerList get click();

  EventListenerList get contentLoaded();

  EventListenerList get contextMenu();

  EventListenerList get deviceMotion();

  EventListenerList get deviceOrientation();

  EventListenerList get doubleClick();

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

  EventListenerList get loadStart();

  EventListenerList get loadedData();

  EventListenerList get loadedMetadata();

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

  EventListenerList get transitionEnd();

  EventListenerList get unload();

  EventListenerList get volumeChange();

  EventListenerList get waiting();
}
