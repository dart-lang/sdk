// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jacobr): define a base class containing the overlap between
// this class and ElementEvents.
class WindowEventsImplementation extends EventsImplementation
      implements WindowEvents {
  WindowEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get abort() => _get('abort');
  EventListenerList get beforeUnload() => _get('beforeunload');
  EventListenerList get blur() => _get('blur');
  EventListenerList get canPlay() => _get('canplay');
  EventListenerList get canPlayThrough() => _get('canplaythrough');
  EventListenerList get change() => _get('change');
  EventListenerList get click() => _get('click');
  EventListenerList get contextMenu() => _get('contextmenu');
  EventListenerList get dblClick() => _get('dblclick');
  EventListenerList get deviceMotion() => _get('devicemotion');
  EventListenerList get deviceOrientation() => _get('deviceorientation');
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
  EventListenerList get loadedData() => _get('loadeddata');
  EventListenerList get loadedMetaData() => _get('loadedmetadata');
  EventListenerList get loadStart() => _get('loadstart');
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
  EventListenerList get unLoad() => _get('unload');
  EventListenerList get volumeChange() => _get('volumechange');
  EventListenerList get waiting() => _get('waiting');
  EventListenerList get animationEnd() => _get('webkitAnimationEnd');
  EventListenerList get animationIteration() => _get('webkitAnimationIteration');
  EventListenerList get animationStart() => _get('webkitAnimationStart');
  EventListenerList get transitionEnd() => _get('webkitTransitionEnd');
  EventListenerList get contentLoaded() => _get('DOMContentLoaded');
}

class WindowWrappingImplementation extends EventTargetWrappingImplementation implements Window {
  WindowWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  DOMApplicationCache get applicationCache() => LevelDom.wrapDOMApplicationCache(_ptr.applicationCache);

  Navigator get clientInformation() => LevelDom.wrapNavigator(_ptr.clientInformation);

  void set clientInformation(Navigator value) { _ptr.clientInformation = LevelDom.unwrap(value); }

  bool get closed() => _ptr.closed;

  Console get console() => LevelDom.wrapConsole(_ptr.console);

  void set console(Console value) { _ptr.console = LevelDom.unwrap(value); }

  Crypto get crypto() => LevelDom.wrapCrypto(_ptr.crypto);

  String get defaultStatus() => _ptr.defaultStatus;

  void set defaultStatus(String value) { _ptr.defaultStatus = value; }

  num get devicePixelRatio() => _ptr.devicePixelRatio;

  void set devicePixelRatio(num value) { _ptr.devicePixelRatio = value; }

  Document get document() => LevelDom.wrapDocument(_ptr.document);

  Event get event() => LevelDom.wrapEvent(_ptr.event);

  void set event(Event value) { _ptr.event = LevelDom.unwrap(value); }

  Element get frameElement() => LevelDom.wrapElement(_ptr.frameElement);

  Window get frames() => LevelDom.wrapWindow(_ptr.frames);

  void set frames(Window value) { _ptr.frames = LevelDom.unwrap(value); }

  History get history() => LevelDom.wrapHistory(_ptr.history);

  void set history(History value) { _ptr.history = LevelDom.unwrap(value); }

  int get innerHeight() => _ptr.innerHeight;

  void set innerHeight(int value) { _ptr.innerHeight = value; }

  int get innerWidth() => _ptr.innerWidth;

  void set innerWidth(int value) { _ptr.innerWidth = value; }

  int get length() => _ptr.length;

  void set length(int value) { _ptr.length = value; }

  Storage get localStorage() => LevelDom.wrapStorage(_ptr.localStorage);

  Location get location() => LevelDom.wrapLocation(_ptr.location);

  void set location(Location value) { _ptr.location = LevelDom.unwrap(value); }

  BarInfo get locationbar() => LevelDom.wrapBarInfo(_ptr.locationbar);

  void set locationbar(BarInfo value) { _ptr.locationbar = LevelDom.unwrap(value); }

  BarInfo get menubar() => LevelDom.wrapBarInfo(_ptr.menubar);

  void set menubar(BarInfo value) { _ptr.menubar = LevelDom.unwrap(value); }

  String get name() => _ptr.name;

  void set name(String value) { _ptr.name = value; }

  Navigator get navigator() => LevelDom.wrapNavigator(_ptr.navigator);

  void set navigator(Navigator value) { _ptr.navigator = LevelDom.unwrap(value); }

  bool get offscreenBuffering() => _ptr.offscreenBuffering;

  void set offscreenBuffering(bool value) { _ptr.offscreenBuffering = value; }

  EventListener get onabort() => LevelDom.wrapEventListener(_ptr.onabort);

  void set onabort(EventListener value) { _ptr.onabort = LevelDom.unwrap(value); }

  EventListener get onbeforeunload() => LevelDom.wrapEventListener(_ptr.onbeforeunload);

  void set onbeforeunload(EventListener value) { _ptr.onbeforeunload = LevelDom.unwrap(value); }

  EventListener get onblur() => LevelDom.wrapEventListener(_ptr.onblur);

  void set onblur(EventListener value) { _ptr.onblur = LevelDom.unwrap(value); }

  EventListener get oncanplay() => LevelDom.wrapEventListener(_ptr.oncanplay);

  void set oncanplay(EventListener value) { _ptr.oncanplay = LevelDom.unwrap(value); }

  EventListener get oncanplaythrough() => LevelDom.wrapEventListener(_ptr.oncanplaythrough);

  void set oncanplaythrough(EventListener value) { _ptr.oncanplaythrough = LevelDom.unwrap(value); }

  EventListener get onchange() => LevelDom.wrapEventListener(_ptr.onchange);

  void set onchange(EventListener value) { _ptr.onchange = LevelDom.unwrap(value); }

  EventListener get onclick() => LevelDom.wrapEventListener(_ptr.onclick);

  void set onclick(EventListener value) { _ptr.onclick = LevelDom.unwrap(value); }

  EventListener get oncontextmenu() => LevelDom.wrapEventListener(_ptr.oncontextmenu);

  void set oncontextmenu(EventListener value) { _ptr.oncontextmenu = LevelDom.unwrap(value); }

  EventListener get ondblclick() => LevelDom.wrapEventListener(_ptr.ondblclick);

  void set ondblclick(EventListener value) { _ptr.ondblclick = LevelDom.unwrap(value); }

  EventListener get ondevicemotion() => LevelDom.wrapEventListener(_ptr.ondevicemotion);

  void set ondevicemotion(EventListener value) { _ptr.ondevicemotion = LevelDom.unwrap(value); }

  EventListener get ondeviceorientation() => LevelDom.wrapEventListener(_ptr.ondeviceorientation);

  void set ondeviceorientation(EventListener value) { _ptr.ondeviceorientation = LevelDom.unwrap(value); }

  EventListener get ondrag() => LevelDom.wrapEventListener(_ptr.ondrag);

  void set ondrag(EventListener value) { _ptr.ondrag = LevelDom.unwrap(value); }

  EventListener get ondragend() => LevelDom.wrapEventListener(_ptr.ondragend);

  void set ondragend(EventListener value) { _ptr.ondragend = LevelDom.unwrap(value); }

  EventListener get ondragenter() => LevelDom.wrapEventListener(_ptr.ondragenter);

  void set ondragenter(EventListener value) { _ptr.ondragenter = LevelDom.unwrap(value); }

  EventListener get ondragleave() => LevelDom.wrapEventListener(_ptr.ondragleave);

  void set ondragleave(EventListener value) { _ptr.ondragleave = LevelDom.unwrap(value); }

  EventListener get ondragover() => LevelDom.wrapEventListener(_ptr.ondragover);

  void set ondragover(EventListener value) { _ptr.ondragover = LevelDom.unwrap(value); }

  EventListener get ondragstart() => LevelDom.wrapEventListener(_ptr.ondragstart);

  void set ondragstart(EventListener value) { _ptr.ondragstart = LevelDom.unwrap(value); }

  EventListener get ondrop() => LevelDom.wrapEventListener(_ptr.ondrop);

  void set ondrop(EventListener value) { _ptr.ondrop = LevelDom.unwrap(value); }

  EventListener get ondurationchange() => LevelDom.wrapEventListener(_ptr.ondurationchange);

  void set ondurationchange(EventListener value) { _ptr.ondurationchange = LevelDom.unwrap(value); }

  EventListener get onemptied() => LevelDom.wrapEventListener(_ptr.onemptied);

  void set onemptied(EventListener value) { _ptr.onemptied = LevelDom.unwrap(value); }

  EventListener get onended() => LevelDom.wrapEventListener(_ptr.onended);

  void set onended(EventListener value) { _ptr.onended = LevelDom.unwrap(value); }

  EventListener get onerror() => LevelDom.wrapEventListener(_ptr.onerror);

  void set onerror(EventListener value) { _ptr.onerror = LevelDom.unwrap(value); }

  EventListener get onfocus() => LevelDom.wrapEventListener(_ptr.onfocus);

  void set onfocus(EventListener value) { _ptr.onfocus = LevelDom.unwrap(value); }

  EventListener get onhashchange() => LevelDom.wrapEventListener(_ptr.onhashchange);

  void set onhashchange(EventListener value) { _ptr.onhashchange = LevelDom.unwrap(value); }

  EventListener get oninput() => LevelDom.wrapEventListener(_ptr.oninput);

  void set oninput(EventListener value) { _ptr.oninput = LevelDom.unwrap(value); }

  EventListener get oninvalid() => LevelDom.wrapEventListener(_ptr.oninvalid);

  void set oninvalid(EventListener value) { _ptr.oninvalid = LevelDom.unwrap(value); }

  EventListener get onkeydown() => LevelDom.wrapEventListener(_ptr.onkeydown);

  void set onkeydown(EventListener value) { _ptr.onkeydown = LevelDom.unwrap(value); }

  EventListener get onkeypress() => LevelDom.wrapEventListener(_ptr.onkeypress);

  void set onkeypress(EventListener value) { _ptr.onkeypress = LevelDom.unwrap(value); }

  EventListener get onkeyup() => LevelDom.wrapEventListener(_ptr.onkeyup);

  void set onkeyup(EventListener value) { _ptr.onkeyup = LevelDom.unwrap(value); }

  EventListener get onload() => LevelDom.wrapEventListener(_ptr.onload);

  void set onload(EventListener value) { _ptr.onload = LevelDom.unwrap(value); }

  EventListener get onloadeddata() => LevelDom.wrapEventListener(_ptr.onloadeddata);

  void set onloadeddata(EventListener value) { _ptr.onloadeddata = LevelDom.unwrap(value); }

  EventListener get onloadedmetadata() => LevelDom.wrapEventListener(_ptr.onloadedmetadata);

  void set onloadedmetadata(EventListener value) { _ptr.onloadedmetadata = LevelDom.unwrap(value); }

  EventListener get onloadstart() => LevelDom.wrapEventListener(_ptr.onloadstart);

  void set onloadstart(EventListener value) { _ptr.onloadstart = LevelDom.unwrap(value); }

  EventListener get onmessage() => LevelDom.wrapEventListener(_ptr.onmessage);

  void set onmessage(EventListener value) { _ptr.onmessage = LevelDom.unwrap(value); }

  EventListener get onmousedown() => LevelDom.wrapEventListener(_ptr.onmousedown);

  void set onmousedown(EventListener value) { _ptr.onmousedown = LevelDom.unwrap(value); }

  EventListener get onmousemove() => LevelDom.wrapEventListener(_ptr.onmousemove);

  void set onmousemove(EventListener value) { _ptr.onmousemove = LevelDom.unwrap(value); }

  EventListener get onmouseout() => LevelDom.wrapEventListener(_ptr.onmouseout);

  void set onmouseout(EventListener value) { _ptr.onmouseout = LevelDom.unwrap(value); }

  EventListener get onmouseover() => LevelDom.wrapEventListener(_ptr.onmouseover);

  void set onmouseover(EventListener value) { _ptr.onmouseover = LevelDom.unwrap(value); }

  EventListener get onmouseup() => LevelDom.wrapEventListener(_ptr.onmouseup);

  void set onmouseup(EventListener value) { _ptr.onmouseup = LevelDom.unwrap(value); }

  EventListener get onmousewheel() => LevelDom.wrapEventListener(_ptr.onmousewheel);

  void set onmousewheel(EventListener value) { _ptr.onmousewheel = LevelDom.unwrap(value); }

  EventListener get onoffline() => LevelDom.wrapEventListener(_ptr.onoffline);

  void set onoffline(EventListener value) { _ptr.onoffline = LevelDom.unwrap(value); }

  EventListener get ononline() => LevelDom.wrapEventListener(_ptr.ononline);

  void set ononline(EventListener value) { _ptr.ononline = LevelDom.unwrap(value); }

  EventListener get onpagehide() => LevelDom.wrapEventListener(_ptr.onpagehide);

  void set onpagehide(EventListener value) { _ptr.onpagehide = LevelDom.unwrap(value); }

  EventListener get onpageshow() => LevelDom.wrapEventListener(_ptr.onpageshow);

  void set onpageshow(EventListener value) { _ptr.onpageshow = LevelDom.unwrap(value); }

  EventListener get onpause() => LevelDom.wrapEventListener(_ptr.onpause);

  void set onpause(EventListener value) { _ptr.onpause = LevelDom.unwrap(value); }

  EventListener get onplay() => LevelDom.wrapEventListener(_ptr.onplay);

  void set onplay(EventListener value) { _ptr.onplay = LevelDom.unwrap(value); }

  EventListener get onplaying() => LevelDom.wrapEventListener(_ptr.onplaying);

  void set onplaying(EventListener value) { _ptr.onplaying = LevelDom.unwrap(value); }

  EventListener get onpopstate() => LevelDom.wrapEventListener(_ptr.onpopstate);

  void set onpopstate(EventListener value) { _ptr.onpopstate = LevelDom.unwrap(value); }

  EventListener get onprogress() => LevelDom.wrapEventListener(_ptr.onprogress);

  void set onprogress(EventListener value) { _ptr.onprogress = LevelDom.unwrap(value); }

  EventListener get onratechange() => LevelDom.wrapEventListener(_ptr.onratechange);

  void set onratechange(EventListener value) { _ptr.onratechange = LevelDom.unwrap(value); }

  EventListener get onreset() => LevelDom.wrapEventListener(_ptr.onreset);

  void set onreset(EventListener value) { _ptr.onreset = LevelDom.unwrap(value); }

  EventListener get onresize() => LevelDom.wrapEventListener(_ptr.onresize);

  void set onresize(EventListener value) { _ptr.onresize = LevelDom.unwrap(value); }

  EventListener get onscroll() => LevelDom.wrapEventListener(_ptr.onscroll);

  void set onscroll(EventListener value) { _ptr.onscroll = LevelDom.unwrap(value); }

  EventListener get onsearch() => LevelDom.wrapEventListener(_ptr.onsearch);

  void set onsearch(EventListener value) { _ptr.onsearch = LevelDom.unwrap(value); }

  EventListener get onseeked() => LevelDom.wrapEventListener(_ptr.onseeked);

  void set onseeked(EventListener value) { _ptr.onseeked = LevelDom.unwrap(value); }

  EventListener get onseeking() => LevelDom.wrapEventListener(_ptr.onseeking);

  void set onseeking(EventListener value) { _ptr.onseeking = LevelDom.unwrap(value); }

  EventListener get onselect() => LevelDom.wrapEventListener(_ptr.onselect);

  void set onselect(EventListener value) { _ptr.onselect = LevelDom.unwrap(value); }

  EventListener get onstalled() => LevelDom.wrapEventListener(_ptr.onstalled);

  void set onstalled(EventListener value) { _ptr.onstalled = LevelDom.unwrap(value); }

  EventListener get onstorage() => LevelDom.wrapEventListener(_ptr.onstorage);

  void set onstorage(EventListener value) { _ptr.onstorage = LevelDom.unwrap(value); }

  EventListener get onsubmit() => LevelDom.wrapEventListener(_ptr.onsubmit);

  void set onsubmit(EventListener value) { _ptr.onsubmit = LevelDom.unwrap(value); }

  EventListener get onsuspend() => LevelDom.wrapEventListener(_ptr.onsuspend);

  void set onsuspend(EventListener value) { _ptr.onsuspend = LevelDom.unwrap(value); }

  EventListener get ontimeupdate() => LevelDom.wrapEventListener(_ptr.ontimeupdate);

  void set ontimeupdate(EventListener value) { _ptr.ontimeupdate = LevelDom.unwrap(value); }

  EventListener get ontouchcancel() => LevelDom.wrapEventListener(_ptr.ontouchcancel);

  void set ontouchcancel(EventListener value) { _ptr.ontouchcancel = LevelDom.unwrap(value); }

  EventListener get ontouchend() => LevelDom.wrapEventListener(_ptr.ontouchend);

  void set ontouchend(EventListener value) { _ptr.ontouchend = LevelDom.unwrap(value); }

  EventListener get ontouchmove() => LevelDom.wrapEventListener(_ptr.ontouchmove);

  void set ontouchmove(EventListener value) { _ptr.ontouchmove = LevelDom.unwrap(value); }

  EventListener get ontouchstart() => LevelDom.wrapEventListener(_ptr.ontouchstart);

  void set ontouchstart(EventListener value) { _ptr.ontouchstart = LevelDom.unwrap(value); }

  EventListener get onunload() => LevelDom.wrapEventListener(_ptr.onunload);

  void set onunload(EventListener value) { _ptr.onunload = LevelDom.unwrap(value); }

  EventListener get onvolumechange() => LevelDom.wrapEventListener(_ptr.onvolumechange);

  void set onvolumechange(EventListener value) { _ptr.onvolumechange = LevelDom.unwrap(value); }

  EventListener get onwaiting() => LevelDom.wrapEventListener(_ptr.onwaiting);

  void set onwaiting(EventListener value) { _ptr.onwaiting = LevelDom.unwrap(value); }

  EventListener get onwebkitanimationend() => LevelDom.wrapEventListener(_ptr.onwebkitanimationend);

  void set onwebkitanimationend(EventListener value) { _ptr.onwebkitanimationend = LevelDom.unwrap(value); }

  EventListener get onwebkitanimationiteration() => LevelDom.wrapEventListener(_ptr.onwebkitanimationiteration);

  void set onwebkitanimationiteration(EventListener value) { _ptr.onwebkitanimationiteration = LevelDom.unwrap(value); }

  EventListener get onwebkitanimationstart() => LevelDom.wrapEventListener(_ptr.onwebkitanimationstart);

  void set onwebkitanimationstart(EventListener value) { _ptr.onwebkitanimationstart = LevelDom.unwrap(value); }

  EventListener get onwebkittransitionend() => LevelDom.wrapEventListener(_ptr.onwebkittransitionend);

  void set onwebkittransitionend(EventListener value) { _ptr.onwebkittransitionend = LevelDom.unwrap(value); }

  Window get opener() => LevelDom.wrapWindow(_ptr.opener);

  void set opener(Window value) { _ptr.opener = LevelDom.unwrap(value); }

  int get outerHeight() => _ptr.outerHeight;

  void set outerHeight(int value) { _ptr.outerHeight = value; }

  int get outerWidth() => _ptr.outerWidth;

  void set outerWidth(int value) { _ptr.outerWidth = value; }

  int get pageXOffset() => _ptr.pageXOffset;

  int get pageYOffset() => _ptr.pageYOffset;

  Window get parent() => LevelDom.wrapWindow(_ptr.parent);

  void set parent(Window value) { _ptr.parent = LevelDom.unwrap(value); }

  BarInfo get personalbar() => LevelDom.wrapBarInfo(_ptr.personalbar);

  void set personalbar(BarInfo value) { _ptr.personalbar = LevelDom.unwrap(value); }

  Screen get screen() => LevelDom.wrapScreen(_ptr.screen);

  void set screen(Screen value) { _ptr.screen = LevelDom.unwrap(value); }

  int get screenLeft() => _ptr.screenLeft;

  void set screenLeft(int value) { _ptr.screenLeft = value; }

  int get screenTop() => _ptr.screenTop;

  void set screenTop(int value) { _ptr.screenTop = value; }

  int get screenX() => _ptr.screenX;

  void set screenX(int value) { _ptr.screenX = value; }

  int get screenY() => _ptr.screenY;

  void set screenY(int value) { _ptr.screenY = value; }

  int get scrollX() => _ptr.scrollX;

  void set scrollX(int value) { _ptr.scrollX = value; }

  int get scrollY() => _ptr.scrollY;

  void set scrollY(int value) { _ptr.scrollY = value; }

  BarInfo get scrollbars() => LevelDom.wrapBarInfo(_ptr.scrollbars);

  void set scrollbars(BarInfo value) { _ptr.scrollbars = LevelDom.unwrap(value); }

  Window get self() => LevelDom.wrapWindow(_ptr.self);

  void set self(Window value) { _ptr.self = LevelDom.unwrap(value); }

  Storage get sessionStorage() => LevelDom.wrapStorage(_ptr.sessionStorage);

  String get status() => _ptr.status;

  void set status(String value) { _ptr.status = value; }

  BarInfo get statusbar() => LevelDom.wrapBarInfo(_ptr.statusbar);

  void set statusbar(BarInfo value) { _ptr.statusbar = LevelDom.unwrap(value); }

  StyleMedia get styleMedia() => LevelDom.wrapStyleMedia(_ptr.styleMedia);

  BarInfo get toolbar() => LevelDom.wrapBarInfo(_ptr.toolbar);

  void set toolbar(BarInfo value) { _ptr.toolbar = LevelDom.unwrap(value); }

  Window get top() => LevelDom.wrapWindow(_ptr.top);

  void set top(Window value) { _ptr.top = LevelDom.unwrap(value); }

  NotificationCenter get webkitNotifications() => LevelDom.wrapNotificationCenter(_ptr.webkitNotifications);

  void alert([String message = null]) {
    if (message === null) {
      _ptr.alert();
    } else {
      _ptr.alert(message);
    }
  }

  String atob([String string = null]) {
    if (string === null) {
      return _ptr.atob();
    } else {
      return _ptr.atob(string);
    }
  }

  void blur() {
    _ptr.blur();
  }

  String btoa([String string = null]) {
    if (string === null) {
      return _ptr.btoa();
    } else {
      return _ptr.btoa(string);
    }
  }

  void captureEvents() {
    _ptr.captureEvents();
  }

  void clearInterval([int handle = null]) {
    if (handle === null) {
      _ptr.clearInterval();
    } else {
      _ptr.clearInterval(handle);
    }
  }

  void clearTimeout([int handle = null]) {
    if (handle === null) {
      _ptr.clearTimeout();
    } else {
      _ptr.clearTimeout(handle);
    }
  }

  void close() {
    _ptr.close();
  }

  bool confirm([String message = null]) {
    if (message === null) {
      return _ptr.confirm();
    } else {
      return _ptr.confirm(message);
    }
  }

  FileReader createFileReader() =>
    LevelDom.wrapFileReader(_ptr.createFileReader());

  CSSMatrix createCSSMatrix([String cssValue = null]) {
    if (cssValue === null) {
      return LevelDom.wrapCSSMatrix(_ptr.createWebKitCSSMatrix());
    } else {
      return LevelDom.wrapCSSMatrix(_ptr.createWebKitCSSMatrix(cssValue));
    }
  }

  bool find([String string = null, bool caseSensitive = null, bool backwards = null, bool wrap = null, bool wholeWord = null, bool searchInFrames = null, bool showDialog = null]) {
    if (string === null) {
      if (caseSensitive === null) {
        if (backwards === null) {
          if (wrap === null) {
            if (wholeWord === null) {
              if (searchInFrames === null) {
                if (showDialog === null) {
                  return _ptr.find();
                }
              }
            }
          }
        }
      }
    } else {
      if (caseSensitive === null) {
        if (backwards === null) {
          if (wrap === null) {
            if (wholeWord === null) {
              if (searchInFrames === null) {
                if (showDialog === null) {
                  return _ptr.find(string);
                }
              }
            }
          }
        }
      } else {
        if (backwards === null) {
          if (wrap === null) {
            if (wholeWord === null) {
              if (searchInFrames === null) {
                if (showDialog === null) {
                  return _ptr.find(string, caseSensitive);
                }
              }
            }
          }
        } else {
          if (wrap === null) {
            if (wholeWord === null) {
              if (searchInFrames === null) {
                if (showDialog === null) {
                  return _ptr.find(string, caseSensitive, backwards);
                }
              }
            }
          } else {
            if (wholeWord === null) {
              if (searchInFrames === null) {
                if (showDialog === null) {
                  return _ptr.find(string, caseSensitive, backwards, wrap);
                }
              }
            } else {
              if (searchInFrames === null) {
                if (showDialog === null) {
                  return _ptr.find(string, caseSensitive, backwards, wrap, wholeWord);
                }
              } else {
                if (showDialog === null) {
                  return _ptr.find(string, caseSensitive, backwards, wrap, wholeWord, searchInFrames);
                } else {
                  return _ptr.find(string, caseSensitive, backwards, wrap, wholeWord, searchInFrames, showDialog);
                }
              }
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void focus() {
    _ptr.focus();
  }

  DOMSelection getSelection() =>
    LevelDom.wrapDOMSelection(_ptr.getSelection());

  MediaQueryList matchMedia(String query) {
    return LevelDom.wrapMediaQueryList(_ptr.matchMedia(query));
  }

  void moveBy(num x, num y) {
    _ptr.moveBy(x, y);
  }

  void moveTo(num x, num y) {
    _ptr.moveTo(x, y);
  }

  Window open(String url, String target, [String features = null]) {
    if (features === null) {
      return LevelDom.wrapWindow(_ptr.open(url, target));
    } else {
      return LevelDom.wrapWindow(_ptr.open(url, target, features));
    }
  }

  // TODO(jacobr): cleanup.
  void postMessage(String message, [var messagePort = null, var targetOrigin = null]) {
    if (targetOrigin === null) {
      if (messagePort === null) {
        _ptr.postMessage(message);
        return;
      } else {
        // messagePort is really the targetOrigin string.
        _ptr.postMessage(message, messagePort);
        return;
      }
    } else {
      _ptr.postMessage(message, LevelDom.unwrap(messagePort), targetOrigin);
      return;
    }
    throw "Incorrect number or type of arguments";
  }

  void print() {
    _ptr.print();
  }

  String prompt([String message = null, String defaultValue = null]) {
    if (message === null) {
      if (defaultValue === null) {
        return _ptr.prompt();
      }
    } else {
      if (defaultValue === null) {
        return _ptr.prompt(message);
      } else {
        return _ptr.prompt(message, defaultValue);
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void releaseEvents() {
    _ptr.releaseEvents();
  }

  void resizeBy(num x, num y) {
    _ptr.resizeBy(x, y);
  }

  void resizeTo(num width, num height) {
    _ptr.resizeTo(width, height);
  }

  void scroll(int x, int y) {
    _ptr.scroll(x, y);
  }

  void scrollBy(int x, int y) {
    _ptr.scrollBy(x, y);
  }

  void scrollTo(int x, int y) {
    _ptr.scrollTo(x, y);
  }

  int setInterval(TimeoutHandler handler, int timeout) =>
    _ptr.setInterval(handler, timeout);

  int setTimeout(TimeoutHandler handler, int timeout) =>
    _ptr.setTimeout(handler, timeout);

  Object showModalDialog(String url, [Object dialogArgs = null, String featureArgs = null]) {
    if (dialogArgs === null) {
      if (featureArgs === null) {
        return _ptr.showModalDialog(url);
      }
    } else {
      if (featureArgs === null) {
        return _ptr.showModalDialog(url, LevelDom.unwrap(dialogArgs));
      } else {
        return _ptr.showModalDialog(url, LevelDom.unwrap(dialogArgs),
                                    featureArgs);
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void stop() {
    _ptr.stop();
  }

  void webkitCancelRequestAnimationFrame(int id) {
    _ptr.webkitCancelRequestAnimationFrame(id);
  }

  Point webkitConvertPointFromNodeToPage([Node node = null, Point p = null]) {
    if (node === null) {
      if (p === null) {
        return LevelDom.wrapPoint(_ptr.webkitConvertPointFromNodeToPage());
      }
    } else {
      if (p === null) {
        return LevelDom.wrapPoint(_ptr.webkitConvertPointFromNodeToPage(LevelDom.unwrap(node)));
      } else {
        return LevelDom.wrapPoint(_ptr.webkitConvertPointFromNodeToPage(LevelDom.unwrap(node), LevelDom.unwrap(p)));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  Point webkitConvertPointFromPageToNode([Node node = null, Point p = null]) {
    if (node === null) {
      if (p === null) {
        return LevelDom.wrapPoint(_ptr.webkitConvertPointFromPageToNode());
      }
    } else {
      if (p === null) {
        return LevelDom.wrapPoint(_ptr.webkitConvertPointFromPageToNode(LevelDom.unwrap(node)));
      } else {
        return LevelDom.wrapPoint(_ptr.webkitConvertPointFromPageToNode(LevelDom.unwrap(node), LevelDom.unwrap(p)));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback, [Element element = null]) {
    if (element === null) {
      return _ptr.webkitRequestAnimationFrame(callback);
    } else {
      return _ptr.webkitRequestAnimationFrame(
          callback, LevelDom.unwrap(element));
    }
  }

  void requestLayoutFrame(TimeoutHandler callback) {
    _addMeasurementFrameCallback(callback);
  }

  WindowEvents get on() {
    if (_on === null) {
      _on = new WindowEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
