// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface Window extends EventTarget {

  final DOMApplicationCache applicationCache;

  final Navigator clientInformation;

  final bool closed;

  final Console console;

  final Crypto crypto;

  String defaultStatus;

  String defaultstatus;

  final num devicePixelRatio;

  final Document document;

  final Event event;

  final Element frameElement;

  final DOMWindow frames;

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

  final DOMWindow opener;

  final int outerHeight;

  final int outerWidth;

  final int pageXOffset;

  final int pageYOffset;

  final DOMWindow parent;

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

  final DOMWindow self;

  final Storage sessionStorage;

  String status;

  final BarInfo statusbar;

  final StyleMedia styleMedia;

  final BarInfo toolbar;

  final DOMWindow top;

  final IDBFactory webkitIndexedDB;

  final NotificationCenter webkitNotifications;

  final StorageInfo webkitStorageInfo;

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
