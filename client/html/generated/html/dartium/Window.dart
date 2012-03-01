// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _WindowImpl extends _EventTargetImpl implements Window {

  _DocumentImpl get document() => _wrap(_ptr.document.documentElement);

  void requestLayoutFrame(TimeoutHandler callback) {
    _addMeasurementFrameCallback(callback);
  }

  _WindowImpl._wrap(ptr) : super._wrap(ptr);

  DOMApplicationCache get applicationCache() => _wrap(_ptr.applicationCache);

  Navigator get clientInformation() => _wrap(_ptr.clientInformation);

  bool get closed() => _wrap(_ptr.closed);

  Console get console() => _wrap(_ptr.console);

  Crypto get crypto() => _wrap(_ptr.crypto);

  String get defaultStatus() => _wrap(_ptr.defaultStatus);

  void set defaultStatus(String value) { _ptr.defaultStatus = _unwrap(value); }

  String get defaultstatus() => _wrap(_ptr.defaultstatus);

  void set defaultstatus(String value) { _ptr.defaultstatus = _unwrap(value); }

  num get devicePixelRatio() => _wrap(_ptr.devicePixelRatio);

  Event get event() => _wrap(_ptr.event);

  Element get frameElement() => _wrap(_ptr.frameElement);

  Window get frames() => _wrap(_ptr.frames);

  History get history() => _wrap(_ptr.history);

  int get innerHeight() => _wrap(_ptr.innerHeight);

  int get innerWidth() => _wrap(_ptr.innerWidth);

  int get length() => _wrap(_ptr.length);

  Storage get localStorage() => _wrap(_ptr.localStorage);

  Location get location() => _wrap(_ptr.location);

  void set location(Location value) { _ptr.location = _unwrap(value); }

  BarInfo get locationbar() => _wrap(_ptr.locationbar);

  BarInfo get menubar() => _wrap(_ptr.menubar);

  String get name() => _wrap(_ptr.name);

  void set name(String value) { _ptr.name = _unwrap(value); }

  Navigator get navigator() => _wrap(_ptr.navigator);

  bool get offscreenBuffering() => _wrap(_ptr.offscreenBuffering);

  Window get opener() => _wrap(_ptr.opener);

  int get outerHeight() => _wrap(_ptr.outerHeight);

  int get outerWidth() => _wrap(_ptr.outerWidth);

  int get pageXOffset() => _wrap(_ptr.pageXOffset);

  int get pageYOffset() => _wrap(_ptr.pageYOffset);

  Window get parent() => _wrap(_ptr.parent);

  Performance get performance() => _wrap(_ptr.performance);

  BarInfo get personalbar() => _wrap(_ptr.personalbar);

  Screen get screen() => _wrap(_ptr.screen);

  int get screenLeft() => _wrap(_ptr.screenLeft);

  int get screenTop() => _wrap(_ptr.screenTop);

  int get screenX() => _wrap(_ptr.screenX);

  int get screenY() => _wrap(_ptr.screenY);

  int get scrollX() => _wrap(_ptr.scrollX);

  int get scrollY() => _wrap(_ptr.scrollY);

  BarInfo get scrollbars() => _wrap(_ptr.scrollbars);

  Window get self() => _wrap(_ptr.self);

  Storage get sessionStorage() => _wrap(_ptr.sessionStorage);

  String get status() => _wrap(_ptr.status);

  void set status(String value) { _ptr.status = _unwrap(value); }

  BarInfo get statusbar() => _wrap(_ptr.statusbar);

  StyleMedia get styleMedia() => _wrap(_ptr.styleMedia);

  BarInfo get toolbar() => _wrap(_ptr.toolbar);

  Window get top() => _wrap(_ptr.top);

  IDBFactory get webkitIndexedDB() => _wrap(_ptr.webkitIndexedDB);

  NotificationCenter get webkitNotifications() => _wrap(_ptr.webkitNotifications);

  StorageInfo get webkitStorageInfo() => _wrap(_ptr.webkitStorageInfo);

  Window get window() => _wrap(_ptr.window);

  _WindowEventsImpl get on() {
    if (_on == null) _on = new _WindowEventsImpl(this);
    return _on;
  }

  void _addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener), _unwrap(useCapture));
      return;
    }
  }

  void alert(String message) {
    _ptr.alert(_unwrap(message));
    return;
  }

  String atob(String string) {
    return _wrap(_ptr.atob(_unwrap(string)));
  }

  void blur() {
    _ptr.blur();
    return;
  }

  String btoa(String string) {
    return _wrap(_ptr.btoa(_unwrap(string)));
  }

  void captureEvents() {
    _ptr.captureEvents();
    return;
  }

  void clearInterval(int handle) {
    _ptr.clearInterval(_unwrap(handle));
    return;
  }

  void clearTimeout(int handle) {
    _ptr.clearTimeout(_unwrap(handle));
    return;
  }

  void close() {
    _ptr.close();
    return;
  }

  bool confirm(String message) {
    return _wrap(_ptr.confirm(_unwrap(message)));
  }

  bool _dispatchEvent(Event evt) {
    return _wrap(_ptr.dispatchEvent(_unwrap(evt)));
  }

  bool find(String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog) {
    return _wrap(_ptr.find(_unwrap(string), _unwrap(caseSensitive), _unwrap(backwards), _unwrap(wrap), _unwrap(wholeWord), _unwrap(searchInFrames), _unwrap(showDialog)));
  }

  void focus() {
    _ptr.focus();
    return;
  }

  CSSStyleDeclaration _getComputedStyle(Element element, String pseudoElement) {
    return _wrap(_ptr.getComputedStyle(_unwrap(element), _unwrap(pseudoElement)));
  }

  CSSRuleList getMatchedCSSRules(Element element, String pseudoElement) {
    return _wrap(_ptr.getMatchedCSSRules(_unwrap(element), _unwrap(pseudoElement)));
  }

  DOMSelection getSelection() {
    return _wrap(_ptr.getSelection());
  }

  MediaQueryList matchMedia(String query) {
    return _wrap(_ptr.matchMedia(_unwrap(query)));
  }

  void moveBy(num x, num y) {
    _ptr.moveBy(_unwrap(x), _unwrap(y));
    return;
  }

  void moveTo(num x, num y) {
    _ptr.moveTo(_unwrap(x), _unwrap(y));
    return;
  }

  Window open(String url, String name, [String options = null]) {
    if (options === null) {
      return _wrap(_ptr.open(_unwrap(url), _unwrap(name)));
    } else {
      return _wrap(_ptr.open(_unwrap(url), _unwrap(name), _unwrap(options)));
    }
  }

  Database openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) {
    if (creationCallback === null) {
      return _wrap(_ptr.openDatabase(_unwrap(name), _unwrap(version), _unwrap(displayName), _unwrap(estimatedSize)));
    } else {
      return _wrap(_ptr.openDatabase(_unwrap(name), _unwrap(version), _unwrap(displayName), _unwrap(estimatedSize), _unwrap(creationCallback)));
    }
  }

  void postMessage(Dynamic message, String targetOrigin, [List messagePorts = null]) {
    if (messagePorts === null) {
      _ptr.postMessage(_unwrap(message), _unwrap(targetOrigin));
      return;
    } else {
      _ptr.postMessage(_unwrap(message), _unwrap(targetOrigin), _unwrap(messagePorts));
      return;
    }
  }

  void print() {
    _ptr.print();
    return;
  }

  String prompt(String message, String defaultValue) {
    return _wrap(_ptr.prompt(_unwrap(message), _unwrap(defaultValue)));
  }

  void releaseEvents() {
    _ptr.releaseEvents();
    return;
  }

  void _removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.removeEventListener(_unwrap(type), _unwrap(listener));
      return;
    } else {
      _ptr.removeEventListener(_unwrap(type), _unwrap(listener), _unwrap(useCapture));
      return;
    }
  }

  void resizeBy(num x, num y) {
    _ptr.resizeBy(_unwrap(x), _unwrap(y));
    return;
  }

  void resizeTo(num width, num height) {
    _ptr.resizeTo(_unwrap(width), _unwrap(height));
    return;
  }

  void scroll(int x, int y) {
    _ptr.scroll(_unwrap(x), _unwrap(y));
    return;
  }

  void scrollBy(int x, int y) {
    _ptr.scrollBy(_unwrap(x), _unwrap(y));
    return;
  }

  void scrollTo(int x, int y) {
    _ptr.scrollTo(_unwrap(x), _unwrap(y));
    return;
  }

  int setInterval(TimeoutHandler handler, int timeout) {
    return _wrap(_ptr.setInterval(_unwrap(handler), _unwrap(timeout)));
  }

  int setTimeout(TimeoutHandler handler, int timeout) {
    return _wrap(_ptr.setTimeout(_unwrap(handler), _unwrap(timeout)));
  }

  Object showModalDialog(String url, [Object dialogArgs = null, String featureArgs = null]) {
    if (dialogArgs === null) {
      if (featureArgs === null) {
        return _wrap(_ptr.showModalDialog(_unwrap(url)));
      }
    } else {
      if (featureArgs === null) {
        return _wrap(_ptr.showModalDialog(_unwrap(url), _unwrap(dialogArgs)));
      } else {
        return _wrap(_ptr.showModalDialog(_unwrap(url), _unwrap(dialogArgs), _unwrap(featureArgs)));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void stop() {
    _ptr.stop();
    return;
  }

  void webkitCancelAnimationFrame(int id) {
    _ptr.webkitCancelAnimationFrame(_unwrap(id));
    return;
  }

  void webkitCancelRequestAnimationFrame(int id) {
    _ptr.webkitCancelRequestAnimationFrame(_unwrap(id));
    return;
  }

  Point webkitConvertPointFromNodeToPage(Node node, Point p) {
    return _wrap(_ptr.webkitConvertPointFromNodeToPage(_unwrap(node), _unwrap(p)));
  }

  Point webkitConvertPointFromPageToNode(Node node, Point p) {
    return _wrap(_ptr.webkitConvertPointFromPageToNode(_unwrap(node), _unwrap(p)));
  }

  void webkitPostMessage(Dynamic message, String targetOrigin, [List transferList = null]) {
    if (transferList === null) {
      _ptr.webkitPostMessage(_unwrap(message), _unwrap(targetOrigin));
      return;
    } else {
      _ptr.webkitPostMessage(_unwrap(message), _unwrap(targetOrigin), _unwrap(transferList));
      return;
    }
  }

  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback, Element element) {
    return _wrap(_ptr.webkitRequestAnimationFrame(_unwrap(callback), _unwrap(element)));
  }

  void webkitRequestFileSystem(int type, int size, FileSystemCallback successCallback, [ErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      _ptr.webkitRequestFileSystem(_unwrap(type), _unwrap(size), _unwrap(successCallback));
      return;
    } else {
      _ptr.webkitRequestFileSystem(_unwrap(type), _unwrap(size), _unwrap(successCallback), _unwrap(errorCallback));
      return;
    }
  }

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback = null, ErrorCallback errorCallback = null]) {
    if (successCallback === null) {
      if (errorCallback === null) {
        _ptr.webkitResolveLocalFileSystemURL(_unwrap(url));
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.webkitResolveLocalFileSystemURL(_unwrap(url), _unwrap(successCallback));
        return;
      } else {
        _ptr.webkitResolveLocalFileSystemURL(_unwrap(url), _unwrap(successCallback), _unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

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
