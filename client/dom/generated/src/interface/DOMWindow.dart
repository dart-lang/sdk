// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Window extends EventTarget {

  final DOMApplicationCache applicationCache;

  Navigator clientInformation;

  final bool closed;

  Console console;

  final Crypto crypto;

  String defaultStatus;

  String defaultstatus;

  num devicePixelRatio;

  final Document document;

  Event event;

  final Element frameElement;

  DOMWindow frames;

  History history;

  int innerHeight;

  int innerWidth;

  int length;

  final Storage localStorage;

  Location location;

  BarInfo locationbar;

  BarInfo menubar;

  String name;

  Navigator navigator;

  bool offscreenBuffering;

  DOMWindow opener;

  int outerHeight;

  int outerWidth;

  final int pageXOffset;

  final int pageYOffset;

  DOMWindow parent;

  Performance performance;

  BarInfo personalbar;

  Screen screen;

  int screenLeft;

  int screenTop;

  int screenX;

  int screenY;

  int scrollX;

  int scrollY;

  BarInfo scrollbars;

  DOMWindow self;

  final Storage sessionStorage;

  String status;

  BarInfo statusbar;

  final StyleMedia styleMedia;

  BarInfo toolbar;

  DOMWindow top;

  final IDBFactory webkitIndexedDB;

  final NotificationCenter webkitNotifications;

  final StorageInfo webkitStorageInfo;

  final DOMURL webkitURL;

  final DOMWindow window;

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  void alert(String message);

  String atob(String string);

  void blur();

  String btoa(String string);

  void captureEvents();

  void clearInterval(int handle);

  void clearTimeout(int handle);

  void close();

  bool confirm(String message);

  bool dispatchEvent(Event evt);

  bool find(String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog);

  void focus();

  CSSStyleDeclaration getComputedStyle(Element element, String pseudoElement);

  CSSRuleList getMatchedCSSRules(Element element, String pseudoElement);

  DOMSelection getSelection();

  MediaQueryList matchMedia(String query);

  void moveBy(num x, num y);

  void moveTo(num x, num y);

  DOMWindow open(String url, String name, [String options]);

  Database openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]);

  void postMessage(Dynamic message, String targetOrigin, [List messagePorts]);

  void print();

  String prompt(String message, String defaultValue);

  void releaseEvents();

  void removeEventListener(String type, EventListener listener, [bool useCapture]);

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

  WebKitPoint webkitConvertPointFromNodeToPage(Node node, WebKitPoint p);

  WebKitPoint webkitConvertPointFromPageToNode(Node node, WebKitPoint p);

  void webkitPostMessage(Dynamic message, String targetOrigin, [List transferList]);

  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback, Element element);

  void webkitRequestFileSystem(int type, int size, FileSystemCallback successCallback, [ErrorCallback errorCallback]);

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback, ErrorCallback errorCallback]);
}

interface DOMWindow extends Window {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;
}
