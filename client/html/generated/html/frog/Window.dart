// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _WindowImpl extends _EventTargetImpl implements Window native "@*DOMWindow" {

  _DocumentImpl get document() native "return this.document.documentElement;";

  void requestLayoutFrame(TimeoutHandler callback) {
    _addMeasurementFrameCallback(callback);
  }


  _WindowEventsImpl get on() =>
    new _WindowEventsImpl(this);

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  final _DOMApplicationCacheImpl applicationCache;

  final _NavigatorImpl clientInformation;

  final bool closed;

  final _ConsoleImpl console;

  final _CryptoImpl crypto;

  String defaultStatus;

  String defaultstatus;

  final num devicePixelRatio;

  final _EventImpl event;

  final _ElementImpl frameElement;

  final _WindowImpl frames;

  final _HistoryImpl history;

  final int innerHeight;

  final int innerWidth;

  final int length;

  final _StorageImpl localStorage;

  _LocationImpl location;

  final _BarInfoImpl locationbar;

  final _BarInfoImpl menubar;

  String name;

  final _NavigatorImpl navigator;

  final bool offscreenBuffering;

  final _WindowImpl opener;

  final int outerHeight;

  final int outerWidth;

  final int pageXOffset;

  final int pageYOffset;

  final _WindowImpl parent;

  final _PerformanceImpl performance;

  final _BarInfoImpl personalbar;

  final _ScreenImpl screen;

  final int screenLeft;

  final int screenTop;

  final int screenX;

  final int screenY;

  final int scrollX;

  final int scrollY;

  final _BarInfoImpl scrollbars;

  final _WindowImpl self;

  final _StorageImpl sessionStorage;

  String status;

  final _BarInfoImpl statusbar;

  final _StyleMediaImpl styleMedia;

  final _BarInfoImpl toolbar;

  final _WindowImpl top;

  final _IDBFactoryImpl webkitIndexedDB;

  final _NotificationCenterImpl webkitNotifications;

  final _StorageInfoImpl webkitStorageInfo;

  final _WindowImpl window;

  void _addEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.addEventListener(type, listener, useCapture);";

  void alert(String message) native;

  String atob(String string) native;

  void blur() native;

  String btoa(String string) native;

  void captureEvents() native;

  void clearInterval(int handle) native;

  void clearTimeout(int handle) native;

  void close() native;

  bool confirm(String message) native;

  bool _dispatchEvent(_EventImpl evt) native "return this.dispatchEvent(evt);";

  bool find(String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog) native;

  void focus() native;

  _CSSStyleDeclarationImpl _getComputedStyle(_ElementImpl element, String pseudoElement) native "return this.getComputedStyle(element, pseudoElement);";

  _CSSRuleListImpl getMatchedCSSRules(_ElementImpl element, String pseudoElement) native;

  _DOMSelectionImpl getSelection() native;

  _MediaQueryListImpl matchMedia(String query) native;

  void moveBy(num x, num y) native;

  void moveTo(num x, num y) native;

  _WindowImpl open(String url, String name, [String options = null]) native;

  _DatabaseImpl openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) native;

  void postMessage(Dynamic message, String targetOrigin, [List messagePorts = null]) native;

  void print() native;

  String prompt(String message, String defaultValue) native;

  void releaseEvents() native;

  void _removeEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.removeEventListener(type, listener, useCapture);";

  void resizeBy(num x, num y) native;

  void resizeTo(num width, num height) native;

  void scroll(int x, int y) native;

  void scrollBy(int x, int y) native;

  void scrollTo(int x, int y) native;

  int setInterval(TimeoutHandler handler, int timeout) native;

  int setTimeout(TimeoutHandler handler, int timeout) native;

  Object showModalDialog(String url, [Object dialogArgs = null, String featureArgs = null]) native;

  void stop() native;

  void webkitCancelAnimationFrame(int id) native;

  void webkitCancelRequestAnimationFrame(int id) native;

  _PointImpl webkitConvertPointFromNodeToPage(_NodeImpl node, _PointImpl p) native;

  _PointImpl webkitConvertPointFromPageToNode(_NodeImpl node, _PointImpl p) native;

  void webkitPostMessage(Dynamic message, String targetOrigin, [List transferList = null]) native;

  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback, _ElementImpl element) native;

  void webkitRequestFileSystem(int type, int size, FileSystemCallback successCallback, [ErrorCallback errorCallback = null]) native;

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback = null, ErrorCallback errorCallback = null]) native;

}

class _WindowEventsImpl extends _EventsImpl implements WindowEvents {
  _WindowEventsImpl(_ptr) : super(_ptr);

  EventListenerList get abort() => _get('abort');

  EventListenerList get animationEnd() => _get('webkitAnimationEnd');

  EventListenerList get animationIteration() => _get('webkitAnimationIteration');

  EventListenerList get animationStart() => _get('webkitAnimationStart');

  EventListenerList get beforeUnload() => _get('beforeunload');

  EventListenerList get blur() => _get('blur');

  EventListenerList get canPlay() => _get('canplay');

  EventListenerList get canPlayThrough() => _get('canplaythrough');

  EventListenerList get change() => _get('change');

  EventListenerList get click() => _get('click');

  EventListenerList get contentLoaded() => _get('DOMContentLoaded');

  EventListenerList get contextMenu() => _get('contextmenu');

  EventListenerList get deviceMotion() => _get('devicemotion');

  EventListenerList get deviceOrientation() => _get('deviceorientation');

  EventListenerList get doubleClick() => _get('dblclick');

  EventListenerList get drag() => _get('drag');

  EventListenerList get dragEnd() => _get('dragend');

  EventListenerList get dragEnter() => _get('dragenter');

  EventListenerList get dragLeave() => _get('dragleave');

  EventListenerList get dragOver() => _get('dragover');

  EventListenerList get dragStart() => _get('dragstart');

  EventListenerList get drop() => _get('drop');

  EventListenerList get durationChange() => _get('durationchange');

  EventListenerList get emptied() => _get('emptied');

  EventListenerList get ended() => _get('ended');

  EventListenerList get error() => _get('error');

  EventListenerList get focus() => _get('focus');

  EventListenerList get hashChange() => _get('hashchange');

  EventListenerList get input() => _get('input');

  EventListenerList get invalid() => _get('invalid');

  EventListenerList get keyDown() => _get('keydown');

  EventListenerList get keyPress() => _get('keypress');

  EventListenerList get keyUp() => _get('keyup');

  EventListenerList get load() => _get('load');

  EventListenerList get loadStart() => _get('loadstart');

  EventListenerList get loadedData() => _get('loadeddata');

  EventListenerList get loadedMetadata() => _get('loadedmetadata');

  EventListenerList get message() => _get('message');

  EventListenerList get mouseDown() => _get('mousedown');

  EventListenerList get mouseMove() => _get('mousemove');

  EventListenerList get mouseOut() => _get('mouseout');

  EventListenerList get mouseOver() => _get('mouseover');

  EventListenerList get mouseUp() => _get('mouseup');

  EventListenerList get mouseWheel() => _get('mousewheel');

  EventListenerList get offline() => _get('offline');

  EventListenerList get online() => _get('online');

  EventListenerList get pageHide() => _get('pagehide');

  EventListenerList get pageShow() => _get('pageshow');

  EventListenerList get pause() => _get('pause');

  EventListenerList get play() => _get('play');

  EventListenerList get playing() => _get('playing');

  EventListenerList get popState() => _get('popstate');

  EventListenerList get progress() => _get('progress');

  EventListenerList get rateChange() => _get('ratechange');

  EventListenerList get reset() => _get('reset');

  EventListenerList get resize() => _get('resize');

  EventListenerList get scroll() => _get('scroll');

  EventListenerList get search() => _get('search');

  EventListenerList get seeked() => _get('seeked');

  EventListenerList get seeking() => _get('seeking');

  EventListenerList get select() => _get('select');

  EventListenerList get stalled() => _get('stalled');

  EventListenerList get storage() => _get('storage');

  EventListenerList get submit() => _get('submit');

  EventListenerList get suspend() => _get('suspend');

  EventListenerList get timeUpdate() => _get('timeupdate');

  EventListenerList get touchCancel() => _get('touchcancel');

  EventListenerList get touchEnd() => _get('touchend');

  EventListenerList get touchMove() => _get('touchmove');

  EventListenerList get touchStart() => _get('touchstart');

  EventListenerList get transitionEnd() => _get('webkitTransitionEnd');

  EventListenerList get unload() => _get('unload');

  EventListenerList get volumeChange() => _get('volumechange');

  EventListenerList get waiting() => _get('waiting');
}
