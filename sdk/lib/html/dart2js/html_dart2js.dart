library html;

import 'dart:async';
import 'dart:collection';
import 'dart:collection-dev';
import 'dart:html_common';
import 'dart:indexed_db';
import 'dart:isolate';
import 'dart:json' as json;
import 'dart:math';
import 'dart:svg' as svg;
import 'dart:web_audio' as web_audio;
import 'dart:_js_helper' show convertDartClosureToJS, Creates, JavaScriptIndexingBehavior, JSName, Null, Returns;
import 'dart:_isolate_helper' show IsolateNatives;
import 'dart:_foreign_helper' show JS;
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated dart:html library.


// Not actually used, but imported since dart:html can generate these objects.





Window get window => JS('Window', 'window');

HtmlDocument get document => JS('Document', 'document');

Element query(String selector) => document.query(selector);
List<Element> queryAll(String selector) => document.queryAll(selector);

// Workaround for tags like <cite> that lack their own Element subclass --
// Dart issue 1990.
class _HTMLElement extends Element native "*HTMLElement" {
}

// Support for Send/ReceivePortSync.
int _getNewIsolateId() {
  if (JS('bool', r'!window.$dart$isolate$counter')) {
    JS('void', r'window.$dart$isolate$counter = 1');
  }
  return JS('int', r'window.$dart$isolate$counter++');
}

// Fast path to invoke JS send port.
_callPortSync(int id, message) {
  return JS('var', r'ReceivePortSync.dispatchCall(#, #)', id, message);
}

spawnDomFunction(f) => IsolateNatives.spawnDomFunction(f);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('AbstractWorker')
class AbstractWorker extends EventTarget native "*AbstractWorker" {

  @DomName('AbstractWorker.error')
  @DocsEditable
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  AbstractWorkerEvents get on =>
    new AbstractWorkerEvents(this);

  @JSName('addEventListener')
  @DomName('AbstractWorker.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('AbstractWorker.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native;

  @JSName('removeEventListener')
  @DomName('AbstractWorker.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('AbstractWorker.error')
  @DocsEditable
  Stream<Event> get onError => errorEvent.forTarget(this);
}

@DocsEditable
@deprecated
class AbstractWorkerEvents extends Events {
  @DocsEditable
  AbstractWorkerEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get error => this['error'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLAnchorElement')
class AnchorElement extends Element native "*HTMLAnchorElement" {

  @DocsEditable
  factory AnchorElement({String href}) {
    var e = document.$dom_createElement("a");
    if (href != null) e.href = href;
    return e;
  }

  @DomName('HTMLAnchorElement.download')
  @DocsEditable
  String download;

  @DomName('HTMLAnchorElement.hash')
  @DocsEditable
  String hash;

  @DomName('HTMLAnchorElement.host')
  @DocsEditable
  String host;

  @DomName('HTMLAnchorElement.hostname')
  @DocsEditable
  String hostname;

  @DomName('HTMLAnchorElement.href')
  @DocsEditable
  String href;

  @DomName('HTMLAnchorElement.hreflang')
  @DocsEditable
  String hreflang;

  @DomName('HTMLAnchorElement.name')
  @DocsEditable
  String name;

  @DomName('HTMLAnchorElement.origin')
  @DocsEditable
  final String origin;

  @DomName('HTMLAnchorElement.pathname')
  @DocsEditable
  String pathname;

  @DomName('HTMLAnchorElement.ping')
  @DocsEditable
  String ping;

  @DomName('HTMLAnchorElement.port')
  @DocsEditable
  String port;

  @DomName('HTMLAnchorElement.protocol')
  @DocsEditable
  String protocol;

  @DomName('HTMLAnchorElement.rel')
  @DocsEditable
  String rel;

  @DomName('HTMLAnchorElement.search')
  @DocsEditable
  String search;

  @DomName('HTMLAnchorElement.target')
  @DocsEditable
  String target;

  @DomName('HTMLAnchorElement.type')
  @DocsEditable
  String type;

  @DomName('HTMLAnchorElement.toString')
  @DocsEditable
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebKitAnimationEvent')
class AnimationEvent extends Event native "*WebKitAnimationEvent" {

  @DomName('WebKitAnimationEvent.animationName')
  @DocsEditable
  final String animationName;

  @DomName('WebKitAnimationEvent.elapsedTime')
  @DocsEditable
  final num elapsedTime;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DOMApplicationCache')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.OPERA)
@SupportedBrowser(SupportedBrowser.SAFARI)
class ApplicationCache extends EventTarget native "*DOMApplicationCache" {

  @DomName('DOMApplicationCache.cached')
  @DocsEditable
  static const EventStreamProvider<Event> cachedEvent = const EventStreamProvider<Event>('cached');

  @DomName('DOMApplicationCache.checking')
  @DocsEditable
  static const EventStreamProvider<Event> checkingEvent = const EventStreamProvider<Event>('checking');

  @DomName('DOMApplicationCache.downloading')
  @DocsEditable
  static const EventStreamProvider<Event> downloadingEvent = const EventStreamProvider<Event>('downloading');

  @DomName('DOMApplicationCache.error')
  @DocsEditable
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DomName('DOMApplicationCache.noupdate')
  @DocsEditable
  static const EventStreamProvider<Event> noUpdateEvent = const EventStreamProvider<Event>('noupdate');

  @DomName('DOMApplicationCache.obsolete')
  @DocsEditable
  static const EventStreamProvider<Event> obsoleteEvent = const EventStreamProvider<Event>('obsolete');

  @DomName('DOMApplicationCache.progress')
  @DocsEditable
  static const EventStreamProvider<Event> progressEvent = const EventStreamProvider<Event>('progress');

  @DomName('DOMApplicationCache.updateready')
  @DocsEditable
  static const EventStreamProvider<Event> updateReadyEvent = const EventStreamProvider<Event>('updateready');

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.applicationCache)');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  ApplicationCacheEvents get on =>
    new ApplicationCacheEvents(this);

  static const int CHECKING = 2;

  static const int DOWNLOADING = 3;

  static const int IDLE = 1;

  static const int OBSOLETE = 5;

  static const int UNCACHED = 0;

  static const int UPDATEREADY = 4;

  @DomName('DOMApplicationCache.status')
  @DocsEditable
  final int status;

  @DomName('DOMApplicationCache.abort')
  @DocsEditable
  void abort() native;

  @JSName('addEventListener')
  @DomName('DOMApplicationCache.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('DOMApplicationCache.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native;

  @JSName('removeEventListener')
  @DomName('DOMApplicationCache.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('DOMApplicationCache.swapCache')
  @DocsEditable
  void swapCache() native;

  @DomName('DOMApplicationCache.update')
  @DocsEditable
  void update() native;

  @DomName('DOMApplicationCache.cached')
  @DocsEditable
  Stream<Event> get onCached => cachedEvent.forTarget(this);

  @DomName('DOMApplicationCache.checking')
  @DocsEditable
  Stream<Event> get onChecking => checkingEvent.forTarget(this);

  @DomName('DOMApplicationCache.downloading')
  @DocsEditable
  Stream<Event> get onDownloading => downloadingEvent.forTarget(this);

  @DomName('DOMApplicationCache.error')
  @DocsEditable
  Stream<Event> get onError => errorEvent.forTarget(this);

  @DomName('DOMApplicationCache.noupdate')
  @DocsEditable
  Stream<Event> get onNoUpdate => noUpdateEvent.forTarget(this);

  @DomName('DOMApplicationCache.obsolete')
  @DocsEditable
  Stream<Event> get onObsolete => obsoleteEvent.forTarget(this);

  @DomName('DOMApplicationCache.progress')
  @DocsEditable
  Stream<Event> get onProgress => progressEvent.forTarget(this);

  @DomName('DOMApplicationCache.updateready')
  @DocsEditable
  Stream<Event> get onUpdateReady => updateReadyEvent.forTarget(this);
}

@DocsEditable
@deprecated
class ApplicationCacheEvents extends Events {
  @DocsEditable
  ApplicationCacheEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get cached => this['cached'];

  @DocsEditable
  EventListenerList get checking => this['checking'];

  @DocsEditable
  EventListenerList get downloading => this['downloading'];

  @DocsEditable
  EventListenerList get error => this['error'];

  @DocsEditable
  EventListenerList get noUpdate => this['noupdate'];

  @DocsEditable
  EventListenerList get obsolete => this['obsolete'];

  @DocsEditable
  EventListenerList get progress => this['progress'];

  @DocsEditable
  EventListenerList get updateReady => this['updateready'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLAreaElement')
class AreaElement extends Element native "*HTMLAreaElement" {

  @DocsEditable
  factory AreaElement() => document.$dom_createElement("area");

  @DomName('HTMLAreaElement.alt')
  @DocsEditable
  String alt;

  @DomName('HTMLAreaElement.coords')
  @DocsEditable
  String coords;

  @DomName('HTMLAreaElement.hash')
  @DocsEditable
  final String hash;

  @DomName('HTMLAreaElement.host')
  @DocsEditable
  final String host;

  @DomName('HTMLAreaElement.hostname')
  @DocsEditable
  final String hostname;

  @DomName('HTMLAreaElement.href')
  @DocsEditable
  String href;

  @DomName('HTMLAreaElement.pathname')
  @DocsEditable
  final String pathname;

  @DomName('HTMLAreaElement.ping')
  @DocsEditable
  String ping;

  @DomName('HTMLAreaElement.port')
  @DocsEditable
  final String port;

  @DomName('HTMLAreaElement.protocol')
  @DocsEditable
  final String protocol;

  @DomName('HTMLAreaElement.search')
  @DocsEditable
  final String search;

  @DomName('HTMLAreaElement.shape')
  @DocsEditable
  String shape;

  @DomName('HTMLAreaElement.target')
  @DocsEditable
  String target;
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('ArrayBuffer')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class ArrayBuffer native "*ArrayBuffer" {

  @DocsEditable
  factory ArrayBuffer(int length) => ArrayBuffer._create(length);
  static ArrayBuffer _create(int length) => JS('ArrayBuffer', 'new ArrayBuffer(#)', length);

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', 'typeof window.ArrayBuffer != "undefined"');

  @DomName('ArrayBuffer.byteLength')
  @DocsEditable
  final int byteLength;

  @DomName('ArrayBuffer.slice')
  ArrayBuffer slice(int begin, [int end]) {
    // IE10 supports ArrayBuffers but does not have the slice method.
    if (JS('bool', '!!#.slice', this)) {
      if (?end) {
        return JS('ArrayBuffer', '#.slice(#, #)', this, begin, end);
      }
      return JS('ArrayBuffer', '#.slice(#)', this, begin);
    } else {
      var start = begin;
      // Negative values go from end.
      if (start < 0) {
        start = this.byteLength + start;
      }
      var finish = ?end ? min(end, byteLength) : byteLength;
      if (finish < 0) {
        finish = this.byteLength + finish;
      }
      var length = max(finish - start, 0);

      var clone = new Int8Array(length);
      var source = new Int8Array.fromBuffer(this, start);
      for (var i = 0; i < length; ++i) {
        clone[i] = source[i];
      }
      return clone.buffer;
    }
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('ArrayBufferView')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class ArrayBufferView native "*ArrayBufferView" {

  @DomName('ArrayBufferView.buffer')
  @DocsEditable
  final ArrayBuffer buffer;

  @DomName('ArrayBufferView.byteLength')
  @DocsEditable
  final int byteLength;

  @DomName('ArrayBufferView.byteOffset')
  @DocsEditable
  final int byteOffset;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Attr')
class Attr extends Node native "*Attr" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLAudioElement')
class AudioElement extends MediaElement native "*HTMLAudioElement" {

  @DocsEditable
  factory AudioElement([String src]) {
    if (!?src) {
      return AudioElement._create();
    }
    return AudioElement._create(src);
  }
  static AudioElement _create([String src]) {
    if (!?src) {
      return JS('AudioElement', 'new Audio()');
    }
    return JS('AudioElement', 'new Audio(#)', src);
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLBRElement')
class BRElement extends Element native "*HTMLBRElement" {

  @DocsEditable
  factory BRElement() => document.$dom_createElement("br");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('BarInfo')
class BarInfo native "*BarInfo" {

  @DomName('BarInfo.visible')
  @DocsEditable
  final bool visible;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLBaseElement')
class BaseElement extends Element native "*HTMLBaseElement" {

  @DocsEditable
  factory BaseElement() => document.$dom_createElement("base");

  @DomName('HTMLBaseElement.href')
  @DocsEditable
  String href;

  @DomName('HTMLBaseElement.target')
  @DocsEditable
  String target;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('BatteryManager')
class BatteryManager extends EventTarget native "*BatteryManager" {

  @DomName('BatteryManager.chargingchange')
  @DocsEditable
  static const EventStreamProvider<Event> chargingChangeEvent = const EventStreamProvider<Event>('chargingchange');

  @DomName('BatteryManager.chargingtimechange')
  @DocsEditable
  static const EventStreamProvider<Event> chargingTimeChangeEvent = const EventStreamProvider<Event>('chargingtimechange');

  @DomName('BatteryManager.dischargingtimechange')
  @DocsEditable
  static const EventStreamProvider<Event> dischargingTimeChangeEvent = const EventStreamProvider<Event>('dischargingtimechange');

  @DomName('BatteryManager.levelchange')
  @DocsEditable
  static const EventStreamProvider<Event> levelChangeEvent = const EventStreamProvider<Event>('levelchange');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  BatteryManagerEvents get on =>
    new BatteryManagerEvents(this);

  @DomName('BatteryManager.charging')
  @DocsEditable
  final bool charging;

  @DomName('BatteryManager.chargingTime')
  @DocsEditable
  final num chargingTime;

  @DomName('BatteryManager.dischargingTime')
  @DocsEditable
  final num dischargingTime;

  @DomName('BatteryManager.level')
  @DocsEditable
  final num level;

  @JSName('addEventListener')
  @DomName('BatteryManager.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('BatteryManager.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event event) native;

  @JSName('removeEventListener')
  @DomName('BatteryManager.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('BatteryManager.chargingchange')
  @DocsEditable
  Stream<Event> get onChargingChange => chargingChangeEvent.forTarget(this);

  @DomName('BatteryManager.chargingtimechange')
  @DocsEditable
  Stream<Event> get onChargingTimeChange => chargingTimeChangeEvent.forTarget(this);

  @DomName('BatteryManager.dischargingtimechange')
  @DocsEditable
  Stream<Event> get onDischargingTimeChange => dischargingTimeChangeEvent.forTarget(this);

  @DomName('BatteryManager.levelchange')
  @DocsEditable
  Stream<Event> get onLevelChange => levelChangeEvent.forTarget(this);
}

@DocsEditable
@deprecated
class BatteryManagerEvents extends Events {
  @DocsEditable
  BatteryManagerEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get chargingChange => this['chargingchange'];

  @DocsEditable
  EventListenerList get chargingTimeChange => this['chargingtimechange'];

  @DocsEditable
  EventListenerList get dischargingTimeChange => this['dischargingtimechange'];

  @DocsEditable
  EventListenerList get levelChange => this['levelchange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('BeforeLoadEvent')
class BeforeLoadEvent extends Event native "*BeforeLoadEvent" {

  @DomName('BeforeLoadEvent.url')
  @DocsEditable
  final String url;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('Blob')
class Blob native "*Blob" {

  @DocsEditable
  factory Blob(List blobParts, [String type, String endings]) {
    if (!?type) {
      return Blob._create(blobParts);
    }
    if (!?endings) {
      return Blob._create(blobParts, type);
    }
    return Blob._create(blobParts, type, endings);
  }

  @DomName('Blob.size')
  @DocsEditable
  final int size;

  @DomName('Blob.type')
  @DocsEditable
  final String type;

  @DomName('Blob.slice')
  @DocsEditable
  Blob slice([int start, int end, String contentType]) native;

  static Blob _create([List blobParts = null, String type, String endings]) {
    // TODO: validate that blobParts is a JS Array and convert if not.
    // TODO: any coercions on the elements of blobParts, e.g. coerce a typed
    // array to ArrayBuffer if it is a total view.
    if (type == null && endings == null) {
      return _create_1(blobParts);
    }
    var bag = _create_bag();
    if (type != null) _bag_set(bag, 'type', type);
    if (endings != null) _bag_set(bag, 'endings', endings);
    return _create_2(blobParts, bag);
  }

  static _create_1(parts) => JS('Blob', 'new Blob(#)', parts);
  static _create_2(parts, bag) => JS('Blob', 'new Blob(#, #)', parts, bag);

  static _create_bag() => JS('var', '{}');
  static _bag_set(bag, key, value) { JS('void', '#[#] = #', bag, key, value); }
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLBodyElement')
class BodyElement extends Element native "*HTMLBodyElement" {

  @DomName('HTMLBodyElement.beforeunload')
  @DocsEditable
  static const EventStreamProvider<Event> beforeUnloadEvent = const EventStreamProvider<Event>('beforeunload');

  @DomName('HTMLBodyElement.blur')
  @DocsEditable
  static const EventStreamProvider<Event> blurEvent = const EventStreamProvider<Event>('blur');

  @DomName('HTMLBodyElement.error')
  @DocsEditable
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DomName('HTMLBodyElement.focus')
  @DocsEditable
  static const EventStreamProvider<Event> focusEvent = const EventStreamProvider<Event>('focus');

  @DomName('HTMLBodyElement.hashchange')
  @DocsEditable
  static const EventStreamProvider<Event> hashChangeEvent = const EventStreamProvider<Event>('hashchange');

  @DomName('HTMLBodyElement.load')
  @DocsEditable
  static const EventStreamProvider<Event> loadEvent = const EventStreamProvider<Event>('load');

  @DomName('HTMLBodyElement.message')
  @DocsEditable
  static const EventStreamProvider<MessageEvent> messageEvent = const EventStreamProvider<MessageEvent>('message');

  @DomName('HTMLBodyElement.offline')
  @DocsEditable
  static const EventStreamProvider<Event> offlineEvent = const EventStreamProvider<Event>('offline');

  @DomName('HTMLBodyElement.online')
  @DocsEditable
  static const EventStreamProvider<Event> onlineEvent = const EventStreamProvider<Event>('online');

  @DomName('HTMLBodyElement.popstate')
  @DocsEditable
  static const EventStreamProvider<PopStateEvent> popStateEvent = const EventStreamProvider<PopStateEvent>('popstate');

  @DomName('HTMLBodyElement.resize')
  @DocsEditable
  static const EventStreamProvider<Event> resizeEvent = const EventStreamProvider<Event>('resize');

  @DomName('HTMLBodyElement.storage')
  @DocsEditable
  static const EventStreamProvider<StorageEvent> storageEvent = const EventStreamProvider<StorageEvent>('storage');

  @DomName('HTMLBodyElement.unload')
  @DocsEditable
  static const EventStreamProvider<Event> unloadEvent = const EventStreamProvider<Event>('unload');

  @DocsEditable
  factory BodyElement() => document.$dom_createElement("body");

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  BodyElementEvents get on =>
    new BodyElementEvents(this);

  @DomName('HTMLBodyElement.beforeunload')
  @DocsEditable
  Stream<Event> get onBeforeUnload => beforeUnloadEvent.forTarget(this);

  @DomName('HTMLBodyElement.blur')
  @DocsEditable
  Stream<Event> get onBlur => blurEvent.forTarget(this);

  @DomName('HTMLBodyElement.error')
  @DocsEditable
  Stream<Event> get onError => errorEvent.forTarget(this);

  @DomName('HTMLBodyElement.focus')
  @DocsEditable
  Stream<Event> get onFocus => focusEvent.forTarget(this);

  @DomName('HTMLBodyElement.hashchange')
  @DocsEditable
  Stream<Event> get onHashChange => hashChangeEvent.forTarget(this);

  @DomName('HTMLBodyElement.load')
  @DocsEditable
  Stream<Event> get onLoad => loadEvent.forTarget(this);

  @DomName('HTMLBodyElement.message')
  @DocsEditable
  Stream<MessageEvent> get onMessage => messageEvent.forTarget(this);

  @DomName('HTMLBodyElement.offline')
  @DocsEditable
  Stream<Event> get onOffline => offlineEvent.forTarget(this);

  @DomName('HTMLBodyElement.online')
  @DocsEditable
  Stream<Event> get onOnline => onlineEvent.forTarget(this);

  @DomName('HTMLBodyElement.popstate')
  @DocsEditable
  Stream<PopStateEvent> get onPopState => popStateEvent.forTarget(this);

  @DomName('HTMLBodyElement.resize')
  @DocsEditable
  Stream<Event> get onResize => resizeEvent.forTarget(this);

  @DomName('HTMLBodyElement.storage')
  @DocsEditable
  Stream<StorageEvent> get onStorage => storageEvent.forTarget(this);

  @DomName('HTMLBodyElement.unload')
  @DocsEditable
  Stream<Event> get onUnload => unloadEvent.forTarget(this);
}

@DocsEditable
@deprecated
class BodyElementEvents extends ElementEvents {
  @DocsEditable
  BodyElementEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get beforeUnload => this['beforeunload'];

  @DocsEditable
  EventListenerList get blur => this['blur'];

  @DocsEditable
  EventListenerList get error => this['error'];

  @DocsEditable
  EventListenerList get focus => this['focus'];

  @DocsEditable
  EventListenerList get hashChange => this['hashchange'];

  @DocsEditable
  EventListenerList get load => this['load'];

  @DocsEditable
  EventListenerList get message => this['message'];

  @DocsEditable
  EventListenerList get offline => this['offline'];

  @DocsEditable
  EventListenerList get online => this['online'];

  @DocsEditable
  EventListenerList get popState => this['popstate'];

  @DocsEditable
  EventListenerList get resize => this['resize'];

  @DocsEditable
  EventListenerList get storage => this['storage'];

  @DocsEditable
  EventListenerList get unload => this['unload'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLButtonElement')
class ButtonElement extends Element native "*HTMLButtonElement" {

  @DocsEditable
  factory ButtonElement() => document.$dom_createElement("button");

  @DomName('HTMLButtonElement.autofocus')
  @DocsEditable
  bool autofocus;

  @DomName('HTMLButtonElement.disabled')
  @DocsEditable
  bool disabled;

  @DomName('HTMLButtonElement.form')
  @DocsEditable
  final FormElement form;

  @DomName('HTMLButtonElement.formAction')
  @DocsEditable
  String formAction;

  @DomName('HTMLButtonElement.formEnctype')
  @DocsEditable
  String formEnctype;

  @DomName('HTMLButtonElement.formMethod')
  @DocsEditable
  String formMethod;

  @DomName('HTMLButtonElement.formNoValidate')
  @DocsEditable
  bool formNoValidate;

  @DomName('HTMLButtonElement.formTarget')
  @DocsEditable
  String formTarget;

  @DomName('HTMLButtonElement.labels')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  final List<Node> labels;

  @DomName('HTMLButtonElement.name')
  @DocsEditable
  String name;

  @DomName('HTMLButtonElement.type')
  @DocsEditable
  String type;

  @DomName('HTMLButtonElement.validationMessage')
  @DocsEditable
  final String validationMessage;

  @DomName('HTMLButtonElement.validity')
  @DocsEditable
  final ValidityState validity;

  @DomName('HTMLButtonElement.value')
  @DocsEditable
  String value;

  @DomName('HTMLButtonElement.willValidate')
  @DocsEditable
  final bool willValidate;

  @DomName('HTMLButtonElement.checkValidity')
  @DocsEditable
  bool checkValidity() native;

  @DomName('HTMLButtonElement.setCustomValidity')
  @DocsEditable
  void setCustomValidity(String error) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('CDATASection')
class CDataSection extends Text native "*CDATASection" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('HTMLCanvasElement')
class CanvasElement extends Element native "*HTMLCanvasElement" {

  @DocsEditable
  factory CanvasElement({int width, int height}) {
    var e = document.$dom_createElement("canvas");
    if (width != null) e.width = width;
    if (height != null) e.height = height;
    return e;
  }

  /// The height of this canvas element in CSS pixels.
  @DomName('HTMLCanvasElement.height')
  @DocsEditable
  int height;

  /// The width of this canvas element in CSS pixels.
  @DomName('HTMLCanvasElement.width')
  @DocsEditable
  int width;

  @JSName('toDataURL')
  /**
   * Returns a data URI containing a representation of the image in the
   * format specified by type (defaults to 'image/png').
   *
   * Data Uri format is as follow `data:[<MIME-type>][;charset=<encoding>][;base64],<data>`
   *
   * Optional parameter [quality] in the range of 0.0 and 1.0 can be used when requesting [type]
   * 'image/jpeg' or 'image/webp'. If [quality] is not passed the default
   * value is used. Note: the default value varies by browser.
   *
   * If the height or width of this canvas element is 0, then 'data:' is returned,
   * representing no data.
   *
   * If the type requested is not 'image/png', and the returned value is
   * 'data:image/png', then the requested type is not supported.
   *
   * Example usage:
   *
   *     CanvasElement canvas = new CanvasElement();
   *     var ctx = canvas.context2d
   *     ..fillStyle = "rgb(200,0,0)"
   *     ..fillRect(10, 10, 55, 50);
   *     var dataUrl = canvas.toDataURL("image/jpeg", 0.95);
   *     // The Data Uri would look similar to
   *     // 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA
   *     // AAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO
   *     // 9TXL0Y4OHwAAAABJRU5ErkJggg=='
   *     //Create a new image element from the data URI.
   *     var img = new ImageElement();
   *     img.src = dataUrl;
   *     document.body.children.add(img);
   *
   * See also:
   *
   * * [Data URI Scheme](http://en.wikipedia.org/wiki/Data_URI_scheme) from Wikipedia.
   *
   * * [HTMLCanvasElement](https://developer.mozilla.org/en-US/docs/DOM/HTMLCanvasElement) from MDN.
   *
   * * [toDataUrl](http://dev.w3.org/html5/spec/the-canvas-element.html#dom-canvas-todataurl) from W3C.
   */
  @DomName('HTMLCanvasElement.toDataURL')
  @DocsEditable
  String toDataUrl(String type, [num quality]) native;


  CanvasRenderingContext getContext(String contextId) native;
  CanvasRenderingContext2D get context2d => getContext('2d');
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
/**
 * An opaque canvas object representing a gradient.
 *
 * Created by calling [createLinearGradient] or [createRadialGradient] on a
 * [CanvasRenderingContext2D] object.
 *
 * Example usage:
 *
 *     var canvas = new CanvasElement(width: 600, height: 600);
 *     var ctx = canvas.context2d;
 *     ctx.clearRect(0, 0, 600, 600);
 *     ctx.save();
 *     // Create radial gradient.
 *     CanvasGradient gradient = ctx.createRadialGradient(0, 0, 0, 0, 0, 600);
 *     gradient.addColorStop(0, '#000');
 *     gradient.addColorStop(1, 'rgb(255, 255, 255)');
 *     // Assign gradients to fill.
 *     ctx.fillStyle = gradient;
 *     // Draw a rectangle with a gradient fill.
 *     ctx.fillRect(0, 0, 600, 600);
 *     ctx.save();
 *     document.body.children.add(canvas);
 *
 * See also:
 *
 * * [CanvasGradient](https://developer.mozilla.org/en-US/docs/DOM/CanvasGradient) from MDN.
 * * [CanvasGradient](http://www.whatwg.org/specs/web-apps/current-work/multipage/the-canvas-element.html#canvasgradient) from whatwg.
 * * [CanvasGradient](http://www.w3.org/TR/2010/WD-2dcontext-20100304/#canvasgradient) from W3C.
 */
@DomName('CanvasGradient')
class CanvasGradient native "*CanvasGradient" {

  /**
   * Adds a color stop to this gradient at the offset.
   *
   * The [offset] can range between 0.0 and 1.0.
   *
   * See also:
   *
   * * [Multiple Color Stops](https://developer.mozilla.org/en-US/docs/CSS/linear-gradient#Gradient_with_multiple_color_stops) from MDN.
   */
  @DomName('CanvasGradient.addColorStop')
  @DocsEditable
  void addColorStop(num offset, String color) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
/**
 * An opaque object representing a pattern of image, canvas, or video.
 *
 * Created by calling [createPattern] on a [CanvasRenderingContext2D] object.
 *
 * Example usage:
 *
 *     var canvas = new CanvasElement(width: 600, height: 600);
 *     var ctx = canvas.context2d;
 *     var img = new ImageElement();
 *     // Image src needs to be loaded before pattern is applied.
 *     img.onLoad.listen((event) {
 *       // When the image is loaded, create a pattern
 *       // from the ImageElement.
 *       CanvasPattern pattern = ctx.createPattern(img, 'repeat');
 *       ctx.rect(0, 0, canvas.width, canvas.height);
 *       ctx.fillStyle = pattern;
 *       ctx.fill();
 *     });
 *     img.src = "images/foo.jpg";
 *     document.body.children.add(canvas);
 *
 * See also:
 * * [CanvasPattern](https://developer.mozilla.org/en-US/docs/DOM/CanvasPattern) from MDN.
 * * [CanvasPattern](http://www.whatwg.org/specs/web-apps/current-work/multipage/the-canvas-element.html#canvaspattern) from whatwg.
 * * [CanvasPattern](http://www.w3.org/TR/2010/WD-2dcontext-20100304/#canvaspattern) from W3C.
 */
@DomName('CanvasPattern')
class CanvasPattern native "*CanvasPattern" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
/**
 * A rendering context for a canvas element.
 *
 * This context is extended by [CanvasRenderingContext2D] and
 * [WebGLRenderingContext].
 */
@DomName('CanvasRenderingContext')
class CanvasRenderingContext native "*CanvasRenderingContext" {

  /// Reference to the canvas element to which this context belongs.
  @DomName('CanvasRenderingContext.canvas')
  @DocsEditable
  final CanvasElement canvas;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('CanvasRenderingContext2D')
class CanvasRenderingContext2D extends CanvasRenderingContext native "*CanvasRenderingContext2D" {

  @DomName('CanvasRenderingContext2D.fillStyle')
  @DocsEditable
  @Creates('String|CanvasGradient|CanvasPattern')
  @Returns('String|CanvasGradient|CanvasPattern')
  dynamic fillStyle;

  @DomName('CanvasRenderingContext2D.font')
  @DocsEditable
  String font;

  @DomName('CanvasRenderingContext2D.globalAlpha')
  @DocsEditable
  num globalAlpha;

  @DomName('CanvasRenderingContext2D.globalCompositeOperation')
  @DocsEditable
  String globalCompositeOperation;

  @DomName('CanvasRenderingContext2D.lineCap')
  @DocsEditable
  String lineCap;

  @DomName('CanvasRenderingContext2D.lineDashOffset')
  @DocsEditable
  num lineDashOffset;

  @DomName('CanvasRenderingContext2D.lineJoin')
  @DocsEditable
  String lineJoin;

  @DomName('CanvasRenderingContext2D.lineWidth')
  @DocsEditable
  num lineWidth;

  @DomName('CanvasRenderingContext2D.miterLimit')
  @DocsEditable
  num miterLimit;

  @DomName('CanvasRenderingContext2D.shadowBlur')
  @DocsEditable
  num shadowBlur;

  @DomName('CanvasRenderingContext2D.shadowColor')
  @DocsEditable
  String shadowColor;

  @DomName('CanvasRenderingContext2D.shadowOffsetX')
  @DocsEditable
  num shadowOffsetX;

  @DomName('CanvasRenderingContext2D.shadowOffsetY')
  @DocsEditable
  num shadowOffsetY;

  @DomName('CanvasRenderingContext2D.strokeStyle')
  @DocsEditable
  @Creates('String|CanvasGradient|CanvasPattern')
  @Returns('String|CanvasGradient|CanvasPattern')
  dynamic strokeStyle;

  @DomName('CanvasRenderingContext2D.textAlign')
  @DocsEditable
  String textAlign;

  @DomName('CanvasRenderingContext2D.textBaseline')
  @DocsEditable
  String textBaseline;

  @DomName('CanvasRenderingContext2D.webkitBackingStorePixelRatio')
  @DocsEditable
  final num webkitBackingStorePixelRatio;

  @DomName('CanvasRenderingContext2D.webkitImageSmoothingEnabled')
  @DocsEditable
  bool webkitImageSmoothingEnabled;

  @DomName('CanvasRenderingContext2D.webkitLineDash')
  @DocsEditable
  List webkitLineDash;

  @DomName('CanvasRenderingContext2D.webkitLineDashOffset')
  @DocsEditable
  num webkitLineDashOffset;

  @DomName('CanvasRenderingContext2D.arc')
  @DocsEditable
  void arc(num x, num y, num radius, num startAngle, num endAngle, bool anticlockwise) native;

  @DomName('CanvasRenderingContext2D.arcTo')
  @DocsEditable
  void arcTo(num x1, num y1, num x2, num y2, num radius) native;

  @DomName('CanvasRenderingContext2D.beginPath')
  @DocsEditable
  void beginPath() native;

  @DomName('CanvasRenderingContext2D.bezierCurveTo')
  @DocsEditable
  void bezierCurveTo(num cp1x, num cp1y, num cp2x, num cp2y, num x, num y) native;

  @DomName('CanvasRenderingContext2D.clearRect')
  @DocsEditable
  void clearRect(num x, num y, num width, num height) native;

  @DomName('CanvasRenderingContext2D.clip')
  @DocsEditable
  void clip() native;

  @DomName('CanvasRenderingContext2D.closePath')
  @DocsEditable
  void closePath() native;

  ImageData createImageData(imagedata_OR_sw, [num sh]) {
    if ((imagedata_OR_sw is ImageData || imagedata_OR_sw == null) && !?sh) {
      var imagedata_1 = _convertDartToNative_ImageData(imagedata_OR_sw);
      return _convertNativeToDart_ImageData(_createImageData_1(imagedata_1));
    }
    if ((imagedata_OR_sw is num || imagedata_OR_sw == null)) {
      return _convertNativeToDart_ImageData(_createImageData_2(imagedata_OR_sw, sh));
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('createImageData')
  @DomName('CanvasRenderingContext2D.createImageData')
  @DocsEditable
  @Creates('ImageData|=Object')
  _createImageData_1(imagedata) native;
  @JSName('createImageData')
  @DomName('CanvasRenderingContext2D.createImageData')
  @DocsEditable
  @Creates('ImageData|=Object')
  _createImageData_2(num sw, sh) native;

  @DomName('CanvasRenderingContext2D.createLinearGradient')
  @DocsEditable
  CanvasGradient createLinearGradient(num x0, num y0, num x1, num y1) native;

  @DomName('CanvasRenderingContext2D.createPattern')
  @DocsEditable
  CanvasPattern createPattern(canvas_OR_image, String repetitionType) native;

  @DomName('CanvasRenderingContext2D.createRadialGradient')
  @DocsEditable
  CanvasGradient createRadialGradient(num x0, num y0, num r0, num x1, num y1, num r1) native;

  @DomName('CanvasRenderingContext2D.drawImage')
  @DocsEditable
  void drawImage(canvas_OR_image_OR_video, num sx_OR_x, num sy_OR_y, [num sw_OR_width, num height_OR_sh, num dx, num dy, num dw, num dh]) native;

  @DomName('CanvasRenderingContext2D.fill')
  @DocsEditable
  void fill() native;

  @DomName('CanvasRenderingContext2D.fillRect')
  @DocsEditable
  void fillRect(num x, num y, num width, num height) native;

  @DomName('CanvasRenderingContext2D.fillText')
  @DocsEditable
  void fillText(String text, num x, num y, [num maxWidth]) native;

  ImageData getImageData(num sx, num sy, num sw, num sh) {
    return _convertNativeToDart_ImageData(_getImageData_1(sx, sy, sw, sh));
  }
  @JSName('getImageData')
  @DomName('CanvasRenderingContext2D.getImageData')
  @DocsEditable
  @Creates('ImageData|=Object')
  _getImageData_1(sx, sy, sw, sh) native;

  @DomName('CanvasRenderingContext2D.getLineDash')
  @DocsEditable
  List<num> getLineDash() native;

  @DomName('CanvasRenderingContext2D.isPointInPath')
  @DocsEditable
  bool isPointInPath(num x, num y) native;

  @DomName('CanvasRenderingContext2D.lineTo')
  @DocsEditable
  void lineTo(num x, num y) native;

  @DomName('CanvasRenderingContext2D.measureText')
  @DocsEditable
  TextMetrics measureText(String text) native;

  @DomName('CanvasRenderingContext2D.moveTo')
  @DocsEditable
  void moveTo(num x, num y) native;

  void putImageData(ImageData imagedata, num dx, num dy, [num dirtyX, num dirtyY, num dirtyWidth, num dirtyHeight]) {
    if (!?dirtyX && !?dirtyY && !?dirtyWidth && !?dirtyHeight) {
      var imagedata_1 = _convertDartToNative_ImageData(imagedata);
      _putImageData_1(imagedata_1, dx, dy);
      return;
    }
    var imagedata_2 = _convertDartToNative_ImageData(imagedata);
    _putImageData_2(imagedata_2, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight);
    return;
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('putImageData')
  @DomName('CanvasRenderingContext2D.putImageData')
  @DocsEditable
  void _putImageData_1(imagedata, dx, dy) native;
  @JSName('putImageData')
  @DomName('CanvasRenderingContext2D.putImageData')
  @DocsEditable
  void _putImageData_2(imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight) native;

  @DomName('CanvasRenderingContext2D.quadraticCurveTo')
  @DocsEditable
  void quadraticCurveTo(num cpx, num cpy, num x, num y) native;

  @DomName('CanvasRenderingContext2D.rect')
  @DocsEditable
  void rect(num x, num y, num width, num height) native;

  @DomName('CanvasRenderingContext2D.restore')
  @DocsEditable
  void restore() native;

  @DomName('CanvasRenderingContext2D.rotate')
  @DocsEditable
  void rotate(num angle) native;

  @DomName('CanvasRenderingContext2D.save')
  @DocsEditable
  void save() native;

  @DomName('CanvasRenderingContext2D.scale')
  @DocsEditable
  void scale(num sx, num sy) native;

  @DomName('CanvasRenderingContext2D.setLineDash')
  @DocsEditable
  void setLineDash(List<num> dash) native;

  @DomName('CanvasRenderingContext2D.setTransform')
  @DocsEditable
  void setTransform(num m11, num m12, num m21, num m22, num dx, num dy) native;

  @DomName('CanvasRenderingContext2D.stroke')
  @DocsEditable
  void stroke() native;

  @DomName('CanvasRenderingContext2D.strokeRect')
  @DocsEditable
  void strokeRect(num x, num y, num width, num height, [num lineWidth]) native;

  @DomName('CanvasRenderingContext2D.strokeText')
  @DocsEditable
  void strokeText(String text, num x, num y, [num maxWidth]) native;

  @DomName('CanvasRenderingContext2D.transform')
  @DocsEditable
  void transform(num m11, num m12, num m21, num m22, num dx, num dy) native;

  @DomName('CanvasRenderingContext2D.translate')
  @DocsEditable
  void translate(num tx, num ty) native;

  ImageData webkitGetImageDataHD(num sx, num sy, num sw, num sh) {
    return _convertNativeToDart_ImageData(_webkitGetImageDataHD_1(sx, sy, sw, sh));
  }
  @JSName('webkitGetImageDataHD')
  @DomName('CanvasRenderingContext2D.webkitGetImageDataHD')
  @DocsEditable
  @Creates('ImageData|=Object')
  _webkitGetImageDataHD_1(sx, sy, sw, sh) native;

  void webkitPutImageDataHD(ImageData imagedata, num dx, num dy, [num dirtyX, num dirtyY, num dirtyWidth, num dirtyHeight]) {
    if (!?dirtyX && !?dirtyY && !?dirtyWidth && !?dirtyHeight) {
      var imagedata_1 = _convertDartToNative_ImageData(imagedata);
      _webkitPutImageDataHD_1(imagedata_1, dx, dy);
      return;
    }
    var imagedata_2 = _convertDartToNative_ImageData(imagedata);
    _webkitPutImageDataHD_2(imagedata_2, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight);
    return;
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('webkitPutImageDataHD')
  @DomName('CanvasRenderingContext2D.webkitPutImageDataHD')
  @DocsEditable
  void _webkitPutImageDataHD_1(imagedata, dx, dy) native;
  @JSName('webkitPutImageDataHD')
  @DomName('CanvasRenderingContext2D.webkitPutImageDataHD')
  @DocsEditable
  void _webkitPutImageDataHD_2(imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight) native;


  /**
   * Sets the color used inside shapes.
   * [r], [g], [b] are 0-255, [a] is 0-1.
   */
  void setFillColorRgb(int r, int g, int b, [num a = 1]) {
    this.fillStyle = 'rgba($r, $g, $b, $a)';
  }

  /**
   * Sets the color used inside shapes.
   * [h] is in degrees, 0-360.
   * [s], [l] are in percent, 0-100.
   * [a] is 0-1.
   */
  void setFillColorHsl(int h, num s, num l, [num a = 1]) {
    this.fillStyle = 'hsla($h, $s%, $l%, $a)';
  }

  /**
   * Sets the color used for stroking shapes.
   * [r], [g], [b] are 0-255, [a] is 0-1.
   */
  void setStrokeColorRgb(int r, int g, int b, [num a = 1]) {
    this.strokeStyle = 'rgba($r, $g, $b, $a)';
  }

  /**
   * Sets the color used for stroking shapes.
   * [h] is in degrees, 0-360.
   * [s], [l] are in percent, 0-100.
   * [a] is 0-1.
   */
  void setStrokeColorHsl(int h, num s, num l, [num a = 1]) {
    this.strokeStyle = 'hsla($h, $s%, $l%, $a)';
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('CharacterData')
class CharacterData extends Node native "*CharacterData" {

  @DomName('CharacterData.data')
  @DocsEditable
  String data;

  @DomName('CharacterData.length')
  @DocsEditable
  final int length;

  @DomName('CharacterData.appendData')
  @DocsEditable
  void appendData(String data) native;

  @DomName('CharacterData.deleteData')
  @DocsEditable
  void deleteData(int offset, int length) native;

  @DomName('CharacterData.insertData')
  @DocsEditable
  void insertData(int offset, String data) native;

  @DomName('CharacterData.remove')
  @DocsEditable
  void remove() native;

  @DomName('CharacterData.replaceData')
  @DocsEditable
  void replaceData(int offset, int length, String data) native;

  @DomName('CharacterData.substringData')
  @DocsEditable
  String substringData(int offset, int length) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('ClientRect')
class ClientRect native "*ClientRect" {

  @DomName('ClientRect.bottom')
  @DocsEditable
  final num bottom;

  @DomName('ClientRect.height')
  @DocsEditable
  final num height;

  @DomName('ClientRect.left')
  @DocsEditable
  final num left;

  @DomName('ClientRect.right')
  @DocsEditable
  final num right;

  @DomName('ClientRect.top')
  @DocsEditable
  final num top;

  @DomName('ClientRect.width')
  @DocsEditable
  final num width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Clipboard')
class Clipboard native "*Clipboard" {

  @DomName('Clipboard.dropEffect')
  @DocsEditable
  String dropEffect;

  @DomName('Clipboard.effectAllowed')
  @DocsEditable
  String effectAllowed;

  @DomName('Clipboard.files')
  @DocsEditable
  @Returns('FileList')
  @Creates('FileList')
  final List<File> files;

  @DomName('Clipboard.items')
  @DocsEditable
  final DataTransferItemList items;

  @DomName('Clipboard.types')
  @DocsEditable
  final List types;

  @DomName('Clipboard.clearData')
  @DocsEditable
  void clearData([String type]) native;

  @DomName('Clipboard.getData')
  @DocsEditable
  String getData(String type) native;

  @DomName('Clipboard.setData')
  @DocsEditable
  bool setData(String type, String data) native;

  @DomName('Clipboard.setDragImage')
  @DocsEditable
  void setDragImage(ImageElement image, int x, int y) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('CloseEvent')
class CloseEvent extends Event native "*CloseEvent" {

  @DomName('CloseEvent.code')
  @DocsEditable
  final int code;

  @DomName('CloseEvent.reason')
  @DocsEditable
  final String reason;

  @DomName('CloseEvent.wasClean')
  @DocsEditable
  final bool wasClean;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Comment')
class Comment extends CharacterData native "*Comment" {
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('CompositionEvent')
class CompositionEvent extends UIEvent native "*CompositionEvent" {
  factory CompositionEvent(String type,
      {bool canBubble: false, bool cancelable: false, Window view,
      String data}) {
    if (view == null) {
      view = window;
    }
    var e = document.$dom_createEvent("CompositionEvent");
    e.$dom_initCompositionEvent(type, canBubble, cancelable, view, data);
    return e;
  }

  @DomName('CompositionEvent.data')
  @DocsEditable
  final String data;

  @JSName('initCompositionEvent')
  @DomName('CompositionEvent.initCompositionEvent')
  @DocsEditable
  void $dom_initCompositionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Window viewArg, String dataArg) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('Console')
class Console {

  static Console safeConsole = new Console();

  bool get _isConsoleDefined => JS('bool', "typeof console != 'undefined'");

  @DomName('Console.memory')
  MemoryInfo get memory => _isConsoleDefined ?
      JS('MemoryInfo', 'console.memory') : null;

  @DomName('Console.profiles')
  List<ScriptProfile> get profiles => _isConsoleDefined ?
      JS('List<ScriptProfile>', 'console.profiles') : null;

  @DomName('Console.assertCondition')
  void assertCondition(bool condition, Object arg) => _isConsoleDefined ?
      JS('void', 'console.assertCondition(#, #)', condition, arg) : null;

  @DomName('Console.count')
  void count(Object arg) => _isConsoleDefined ?
      JS('void', 'console.count(#)', arg) : null;

  @DomName('Console.debug')
  void debug(Object arg) => _isConsoleDefined ?
      JS('void', 'console.debug(#)', arg) : null;

  @DomName('Console.dir')
  void dir(Object arg) => _isConsoleDefined ?
      JS('void', 'console.debug(#)', arg) : null;

  @DomName('Console.dirxml')
  void dirxml(Object arg) => _isConsoleDefined ?
      JS('void', 'console.dirxml(#)', arg) : null;

  @DomName('Console.error')
  void error(Object arg) => _isConsoleDefined ?
      JS('void', 'console.error(#)', arg) : null;

  @DomName('Console.group')
  void group(Object arg) => _isConsoleDefined ?
      JS('void', 'console.group(#)', arg) : null;

  @DomName('Console.groupCollapsed')
  void groupCollapsed(Object arg) => _isConsoleDefined ?
      JS('void', 'console.groupCollapsed(#)', arg) : null;

  @DomName('Console.groupEnd')
  void groupEnd() => _isConsoleDefined ?
      JS('void', 'console.groupEnd()') : null;

  @DomName('Console.info')
  void info(Object arg) => _isConsoleDefined ?
      JS('void', 'console.info(#)', arg) : null;

  @DomName('Console.log')
  void log(Object arg) => _isConsoleDefined ?
      JS('void', 'console.log(#)', arg) : null;

  @DomName('Console.markTimeline')
  void markTimeline(Object arg) => _isConsoleDefined ?
      JS('void', 'console.markTimeline(#)', arg) : null;

  @DomName('Console.profile')
  void profile(String title) => _isConsoleDefined ?
      JS('void', 'console.profile(#)', title) : null;

  @DomName('Console.profileEnd')
  void profileEnd(String title) => _isConsoleDefined ?
      JS('void', 'console.profileEnd(#)', title) : null;

  @DomName('Console.time')
  void time(String title) => _isConsoleDefined ?
      JS('void', 'console.time(#)', title) : null;

  @DomName('Console.timeEnd')
  void timeEnd(String title, Object arg) => _isConsoleDefined ?
      JS('void', 'console.timeEnd(#, #)', title, arg) : null;

  @DomName('Console.timeStamp')
  void timeStamp(Object arg) => _isConsoleDefined ?
      JS('void', 'console.timeStamp(#)', arg) : null;

  @DomName('Console.trace')
  void trace(Object arg) => _isConsoleDefined ?
      JS('void', 'console.trace(#)', arg) : null;

  @DomName('Console.warn')
  void warn(Object arg) => _isConsoleDefined ?
      JS('void', 'console.warn(#)', arg) : null;

  @DomName('Console.clear')
  @DocsEditable
  void clear(Object arg) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLContentElement')
@SupportedBrowser(SupportedBrowser.CHROME, '25')
@Experimental
class ContentElement extends Element native "*HTMLContentElement" {

  @DocsEditable
  factory ContentElement() => document.$dom_createElement("content");

  /// Checks if this type is supported on the current platform.
  static bool get supported => Element.isTagSupported('content');

  @DomName('HTMLContentElement.resetStyleInheritance')
  @DocsEditable
  bool resetStyleInheritance;

  @DomName('HTMLContentElement.select')
  @DocsEditable
  String select;

  @DomName('HTMLContentElement.getDistributedNodes')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> getDistributedNodes() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Coordinates')
class Coordinates native "*Coordinates" {

  @DomName('Coordinates.accuracy')
  @DocsEditable
  final num accuracy;

  @DomName('Coordinates.altitude')
  @DocsEditable
  final num altitude;

  @DomName('Coordinates.altitudeAccuracy')
  @DocsEditable
  final num altitudeAccuracy;

  @DomName('Coordinates.heading')
  @DocsEditable
  final num heading;

  @DomName('Coordinates.latitude')
  @DocsEditable
  final num latitude;

  @DomName('Coordinates.longitude')
  @DocsEditable
  final num longitude;

  @DomName('Coordinates.speed')
  @DocsEditable
  final num speed;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Counter')
class Counter native "*Counter" {

  @DomName('Counter.identifier')
  @DocsEditable
  final String identifier;

  @DomName('Counter.listStyle')
  @DocsEditable
  final String listStyle;

  @DomName('Counter.separator')
  @DocsEditable
  final String separator;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Crypto')
class Crypto native "*Crypto" {

  @DomName('Crypto.getRandomValues')
  @DocsEditable
  ArrayBufferView getRandomValues(ArrayBufferView array) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('CSSCharsetRule')
class CssCharsetRule extends CssRule native "*CSSCharsetRule" {

  @DomName('CSSCharsetRule.encoding')
  @DocsEditable
  String encoding;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('CSSFontFaceRule')
class CssFontFaceRule extends CssRule native "*CSSFontFaceRule" {

  @DomName('CSSFontFaceRule.style')
  @DocsEditable
  final CssStyleDeclaration style;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('CSSImportRule')
class CssImportRule extends CssRule native "*CSSImportRule" {

  @DomName('CSSImportRule.href')
  @DocsEditable
  final String href;

  @DomName('CSSImportRule.media')
  @DocsEditable
  final MediaList media;

  @DomName('CSSImportRule.styleSheet')
  @DocsEditable
  final CssStyleSheet styleSheet;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebKitCSSKeyframeRule')
class CssKeyframeRule extends CssRule native "*WebKitCSSKeyframeRule" {

  @DomName('WebKitCSSKeyframeRule.keyText')
  @DocsEditable
  String keyText;

  @DomName('WebKitCSSKeyframeRule.style')
  @DocsEditable
  final CssStyleDeclaration style;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebKitCSSKeyframesRule')
class CssKeyframesRule extends CssRule native "*WebKitCSSKeyframesRule" {

  @DomName('WebKitCSSKeyframesRule.cssRules')
  @DocsEditable
  @Returns('_CssRuleList')
  @Creates('_CssRuleList')
  final List<CssRule> cssRules;

  @DomName('WebKitCSSKeyframesRule.name')
  @DocsEditable
  String name;

  @DomName('WebKitCSSKeyframesRule.deleteRule')
  @DocsEditable
  void deleteRule(String key) native;

  @DomName('WebKitCSSKeyframesRule.findRule')
  @DocsEditable
  CssKeyframeRule findRule(String key) native;

  @DomName('WebKitCSSKeyframesRule.insertRule')
  @DocsEditable
  void insertRule(String rule) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebKitCSSMatrix')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class CssMatrix native "*WebKitCSSMatrix" {

  @DocsEditable
  factory CssMatrix([String cssValue]) {
    if (!?cssValue) {
      return CssMatrix._create();
    }
    return CssMatrix._create(cssValue);
  }
  static CssMatrix _create([String cssValue]) {
    if (!?cssValue) {
      return JS('CssMatrix', 'new WebKitCSSMatrix()');
    }
    return JS('CssMatrix', 'new WebKitCSSMatrix(#)', cssValue);
  }

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.WebKitCSSMatrix)');

  @DomName('WebKitCSSMatrix.a')
  @DocsEditable
  num a;

  @DomName('WebKitCSSMatrix.b')
  @DocsEditable
  num b;

  @DomName('WebKitCSSMatrix.c')
  @DocsEditable
  num c;

  @DomName('WebKitCSSMatrix.d')
  @DocsEditable
  num d;

  @DomName('WebKitCSSMatrix.e')
  @DocsEditable
  num e;

  @DomName('WebKitCSSMatrix.f')
  @DocsEditable
  num f;

  @DomName('WebKitCSSMatrix.m11')
  @DocsEditable
  num m11;

  @DomName('WebKitCSSMatrix.m12')
  @DocsEditable
  num m12;

  @DomName('WebKitCSSMatrix.m13')
  @DocsEditable
  num m13;

  @DomName('WebKitCSSMatrix.m14')
  @DocsEditable
  num m14;

  @DomName('WebKitCSSMatrix.m21')
  @DocsEditable
  num m21;

  @DomName('WebKitCSSMatrix.m22')
  @DocsEditable
  num m22;

  @DomName('WebKitCSSMatrix.m23')
  @DocsEditable
  num m23;

  @DomName('WebKitCSSMatrix.m24')
  @DocsEditable
  num m24;

  @DomName('WebKitCSSMatrix.m31')
  @DocsEditable
  num m31;

  @DomName('WebKitCSSMatrix.m32')
  @DocsEditable
  num m32;

  @DomName('WebKitCSSMatrix.m33')
  @DocsEditable
  num m33;

  @DomName('WebKitCSSMatrix.m34')
  @DocsEditable
  num m34;

  @DomName('WebKitCSSMatrix.m41')
  @DocsEditable
  num m41;

  @DomName('WebKitCSSMatrix.m42')
  @DocsEditable
  num m42;

  @DomName('WebKitCSSMatrix.m43')
  @DocsEditable
  num m43;

  @DomName('WebKitCSSMatrix.m44')
  @DocsEditable
  num m44;

  @DomName('WebKitCSSMatrix.inverse')
  @DocsEditable
  CssMatrix inverse() native;

  @DomName('WebKitCSSMatrix.multiply')
  @DocsEditable
  CssMatrix multiply(CssMatrix secondMatrix) native;

  @DomName('WebKitCSSMatrix.rotate')
  @DocsEditable
  CssMatrix rotate(num rotX, num rotY, num rotZ) native;

  @DomName('WebKitCSSMatrix.rotateAxisAngle')
  @DocsEditable
  CssMatrix rotateAxisAngle(num x, num y, num z, num angle) native;

  @DomName('WebKitCSSMatrix.scale')
  @DocsEditable
  CssMatrix scale(num scaleX, num scaleY, num scaleZ) native;

  @DomName('WebKitCSSMatrix.setMatrixValue')
  @DocsEditable
  void setMatrixValue(String string) native;

  @DomName('WebKitCSSMatrix.skewX')
  @DocsEditable
  CssMatrix skewX(num angle) native;

  @DomName('WebKitCSSMatrix.skewY')
  @DocsEditable
  CssMatrix skewY(num angle) native;

  @DomName('WebKitCSSMatrix.toString')
  @DocsEditable
  String toString() native;

  @DomName('WebKitCSSMatrix.translate')
  @DocsEditable
  CssMatrix translate(num x, num y, num z) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('CSSMediaRule')
class CssMediaRule extends CssRule native "*CSSMediaRule" {

  @DomName('CSSMediaRule.cssRules')
  @DocsEditable
  @Returns('_CssRuleList')
  @Creates('_CssRuleList')
  final List<CssRule> cssRules;

  @DomName('CSSMediaRule.media')
  @DocsEditable
  final MediaList media;

  @DomName('CSSMediaRule.deleteRule')
  @DocsEditable
  void deleteRule(int index) native;

  @DomName('CSSMediaRule.insertRule')
  @DocsEditable
  int insertRule(String rule, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('CSSPageRule')
class CssPageRule extends CssRule native "*CSSPageRule" {

  @DomName('CSSPageRule.selectorText')
  @DocsEditable
  String selectorText;

  @DomName('CSSPageRule.style')
  @DocsEditable
  final CssStyleDeclaration style;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('CSSPrimitiveValue')
class CssPrimitiveValue extends CssValue native "*CSSPrimitiveValue" {

  static const int CSS_ATTR = 22;

  static const int CSS_CM = 6;

  static const int CSS_COUNTER = 23;

  static const int CSS_DEG = 11;

  static const int CSS_DIMENSION = 18;

  static const int CSS_EMS = 3;

  static const int CSS_EXS = 4;

  static const int CSS_GRAD = 13;

  static const int CSS_HZ = 16;

  static const int CSS_IDENT = 21;

  static const int CSS_IN = 8;

  static const int CSS_KHZ = 17;

  static const int CSS_MM = 7;

  static const int CSS_MS = 14;

  static const int CSS_NUMBER = 1;

  static const int CSS_PC = 10;

  static const int CSS_PERCENTAGE = 2;

  static const int CSS_PT = 9;

  static const int CSS_PX = 5;

  static const int CSS_RAD = 12;

  static const int CSS_RECT = 24;

  static const int CSS_RGBCOLOR = 25;

  static const int CSS_S = 15;

  static const int CSS_STRING = 19;

  static const int CSS_UNKNOWN = 0;

  static const int CSS_URI = 20;

  static const int CSS_VH = 27;

  static const int CSS_VMIN = 28;

  static const int CSS_VW = 26;

  @DomName('CSSPrimitiveValue.primitiveType')
  @DocsEditable
  final int primitiveType;

  @DomName('CSSPrimitiveValue.getCounterValue')
  @DocsEditable
  Counter getCounterValue() native;

  @DomName('CSSPrimitiveValue.getFloatValue')
  @DocsEditable
  num getFloatValue(int unitType) native;

  @JSName('getRGBColorValue')
  @DomName('CSSPrimitiveValue.getRGBColorValue')
  @DocsEditable
  RgbColor getRgbColorValue() native;

  @DomName('CSSPrimitiveValue.getRectValue')
  @DocsEditable
  Rect getRectValue() native;

  @DomName('CSSPrimitiveValue.getStringValue')
  @DocsEditable
  String getStringValue() native;

  @DomName('CSSPrimitiveValue.setFloatValue')
  @DocsEditable
  void setFloatValue(int unitType, num floatValue) native;

  @DomName('CSSPrimitiveValue.setStringValue')
  @DocsEditable
  void setStringValue(int stringType, String stringValue) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('CSSRule')
class CssRule native "*CSSRule" {

  static const int CHARSET_RULE = 2;

  static const int FONT_FACE_RULE = 5;

  static const int IMPORT_RULE = 3;

  static const int MEDIA_RULE = 4;

  static const int PAGE_RULE = 6;

  static const int STYLE_RULE = 1;

  static const int UNKNOWN_RULE = 0;

  static const int WEBKIT_KEYFRAMES_RULE = 7;

  static const int WEBKIT_KEYFRAME_RULE = 8;

  @DomName('CSSRule.cssText')
  @DocsEditable
  String cssText;

  @DomName('CSSRule.parentRule')
  @DocsEditable
  final CssRule parentRule;

  @DomName('CSSRule.parentStyleSheet')
  @DocsEditable
  final CssStyleSheet parentStyleSheet;

  @DomName('CSSRule.type')
  @DocsEditable
  final int type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


String _cachedBrowserPrefix;

String get _browserPrefix {
  if (_cachedBrowserPrefix == null) {
    if (_Device.isFirefox) {
      _cachedBrowserPrefix = '-moz-';
    } else if (_Device.isIE) {
      _cachedBrowserPrefix = '-ms-';
    } else if (_Device.isOpera) {
      _cachedBrowserPrefix = '-o-';
    } else {
      _cachedBrowserPrefix = '-webkit-';
    }
  }
  return _cachedBrowserPrefix;
}

@DomName('CSSStyleDeclaration')
class CssStyleDeclaration native "*CSSStyleDeclaration" {
  factory CssStyleDeclaration() => _CssStyleDeclarationFactoryProvider.createCssStyleDeclaration();
  factory CssStyleDeclaration.css(String css) =>
      _CssStyleDeclarationFactoryProvider.createCssStyleDeclaration_css(css);


  @DomName('CSSStyleDeclaration.cssText')
  @DocsEditable
  String cssText;

  @DomName('CSSStyleDeclaration.length')
  @DocsEditable
  final int length;

  @DomName('CSSStyleDeclaration.parentRule')
  @DocsEditable
  final CssRule parentRule;

  @JSName('getPropertyCSSValue')
  @DomName('CSSStyleDeclaration.getPropertyCSSValue')
  @DocsEditable
  CssValue getPropertyCssValue(String propertyName) native;

  @DomName('CSSStyleDeclaration.getPropertyPriority')
  @DocsEditable
  String getPropertyPriority(String propertyName) native;

  @DomName('CSSStyleDeclaration.getPropertyShorthand')
  @DocsEditable
  String getPropertyShorthand(String propertyName) native;

  @JSName('getPropertyValue')
  @DomName('CSSStyleDeclaration.getPropertyValue')
  @DocsEditable
  String _getPropertyValue(String propertyName) native;

  @DomName('CSSStyleDeclaration.isPropertyImplicit')
  @DocsEditable
  bool isPropertyImplicit(String propertyName) native;

  @DomName('CSSStyleDeclaration.item')
  @DocsEditable
  String item(int index) native;

  @DomName('CSSStyleDeclaration.removeProperty')
  @DocsEditable
  String removeProperty(String propertyName) native;


  String getPropertyValue(String propertyName) {
    var propValue = _getPropertyValue(propertyName);
    return propValue != null ? propValue : '';
  }

  void setProperty(String propertyName, String value, [String priority]) {
    JS('void', '#.setProperty(#, #, #)', this, propertyName, value, priority);
    // Bug #2772, IE9 requires a poke to actually apply the value.
    if (JS('bool', '!!#.setAttribute', this)) {
      JS('void', '#.setAttribute(#, #)', this, propertyName, value);
    }
  }

  // TODO(jacobr): generate this list of properties using the existing script.
  /** Gets the value of "align-content" */
  String get alignContent =>
    getPropertyValue('${_browserPrefix}align-content');

  /** Sets the value of "align-content" */
  void set alignContent(String value) {
    setProperty('${_browserPrefix}align-content', value, '');
  }

  /** Gets the value of "align-items" */
  String get alignItems =>
    getPropertyValue('${_browserPrefix}align-items');

  /** Sets the value of "align-items" */
  void set alignItems(String value) {
    setProperty('${_browserPrefix}align-items', value, '');
  }

  /** Gets the value of "align-self" */
  String get alignSelf =>
    getPropertyValue('${_browserPrefix}align-self');

  /** Sets the value of "align-self" */
  void set alignSelf(String value) {
    setProperty('${_browserPrefix}align-self', value, '');
  }

  /** Gets the value of "animation" */
  String get animation =>
    getPropertyValue('${_browserPrefix}animation');

  /** Sets the value of "animation" */
  void set animation(String value) {
    setProperty('${_browserPrefix}animation', value, '');
  }

  /** Gets the value of "animation-delay" */
  String get animationDelay =>
    getPropertyValue('${_browserPrefix}animation-delay');

  /** Sets the value of "animation-delay" */
  void set animationDelay(String value) {
    setProperty('${_browserPrefix}animation-delay', value, '');
  }

  /** Gets the value of "animation-direction" */
  String get animationDirection =>
    getPropertyValue('${_browserPrefix}animation-direction');

  /** Sets the value of "animation-direction" */
  void set animationDirection(String value) {
    setProperty('${_browserPrefix}animation-direction', value, '');
  }

  /** Gets the value of "animation-duration" */
  String get animationDuration =>
    getPropertyValue('${_browserPrefix}animation-duration');

  /** Sets the value of "animation-duration" */
  void set animationDuration(String value) {
    setProperty('${_browserPrefix}animation-duration', value, '');
  }

  /** Gets the value of "animation-fill-mode" */
  String get animationFillMode =>
    getPropertyValue('${_browserPrefix}animation-fill-mode');

  /** Sets the value of "animation-fill-mode" */
  void set animationFillMode(String value) {
    setProperty('${_browserPrefix}animation-fill-mode', value, '');
  }

  /** Gets the value of "animation-iteration-count" */
  String get animationIterationCount =>
    getPropertyValue('${_browserPrefix}animation-iteration-count');

  /** Sets the value of "animation-iteration-count" */
  void set animationIterationCount(String value) {
    setProperty('${_browserPrefix}animation-iteration-count', value, '');
  }

  /** Gets the value of "animation-name" */
  String get animationName =>
    getPropertyValue('${_browserPrefix}animation-name');

  /** Sets the value of "animation-name" */
  void set animationName(String value) {
    setProperty('${_browserPrefix}animation-name', value, '');
  }

  /** Gets the value of "animation-play-state" */
  String get animationPlayState =>
    getPropertyValue('${_browserPrefix}animation-play-state');

  /** Sets the value of "animation-play-state" */
  void set animationPlayState(String value) {
    setProperty('${_browserPrefix}animation-play-state', value, '');
  }

  /** Gets the value of "animation-timing-function" */
  String get animationTimingFunction =>
    getPropertyValue('${_browserPrefix}animation-timing-function');

  /** Sets the value of "animation-timing-function" */
  void set animationTimingFunction(String value) {
    setProperty('${_browserPrefix}animation-timing-function', value, '');
  }

  /** Gets the value of "app-region" */
  String get appRegion =>
    getPropertyValue('${_browserPrefix}app-region');

  /** Sets the value of "app-region" */
  void set appRegion(String value) {
    setProperty('${_browserPrefix}app-region', value, '');
  }

  /** Gets the value of "appearance" */
  String get appearance =>
    getPropertyValue('${_browserPrefix}appearance');

  /** Sets the value of "appearance" */
  void set appearance(String value) {
    setProperty('${_browserPrefix}appearance', value, '');
  }

  /** Gets the value of "aspect-ratio" */
  String get aspectRatio =>
    getPropertyValue('${_browserPrefix}aspect-ratio');

  /** Sets the value of "aspect-ratio" */
  void set aspectRatio(String value) {
    setProperty('${_browserPrefix}aspect-ratio', value, '');
  }

  /** Gets the value of "backface-visibility" */
  String get backfaceVisibility =>
    getPropertyValue('${_browserPrefix}backface-visibility');

  /** Sets the value of "backface-visibility" */
  void set backfaceVisibility(String value) {
    setProperty('${_browserPrefix}backface-visibility', value, '');
  }

  /** Gets the value of "background" */
  String get background =>
    getPropertyValue('background');

  /** Sets the value of "background" */
  void set background(String value) {
    setProperty('background', value, '');
  }

  /** Gets the value of "background-attachment" */
  String get backgroundAttachment =>
    getPropertyValue('background-attachment');

  /** Sets the value of "background-attachment" */
  void set backgroundAttachment(String value) {
    setProperty('background-attachment', value, '');
  }

  /** Gets the value of "background-clip" */
  String get backgroundClip =>
    getPropertyValue('background-clip');

  /** Sets the value of "background-clip" */
  void set backgroundClip(String value) {
    setProperty('background-clip', value, '');
  }

  /** Gets the value of "background-color" */
  String get backgroundColor =>
    getPropertyValue('background-color');

  /** Sets the value of "background-color" */
  void set backgroundColor(String value) {
    setProperty('background-color', value, '');
  }

  /** Gets the value of "background-composite" */
  String get backgroundComposite =>
    getPropertyValue('${_browserPrefix}background-composite');

  /** Sets the value of "background-composite" */
  void set backgroundComposite(String value) {
    setProperty('${_browserPrefix}background-composite', value, '');
  }

  /** Gets the value of "background-image" */
  String get backgroundImage =>
    getPropertyValue('background-image');

  /** Sets the value of "background-image" */
  void set backgroundImage(String value) {
    setProperty('background-image', value, '');
  }

  /** Gets the value of "background-origin" */
  String get backgroundOrigin =>
    getPropertyValue('background-origin');

  /** Sets the value of "background-origin" */
  void set backgroundOrigin(String value) {
    setProperty('background-origin', value, '');
  }

  /** Gets the value of "background-position" */
  String get backgroundPosition =>
    getPropertyValue('background-position');

  /** Sets the value of "background-position" */
  void set backgroundPosition(String value) {
    setProperty('background-position', value, '');
  }

  /** Gets the value of "background-position-x" */
  String get backgroundPositionX =>
    getPropertyValue('background-position-x');

  /** Sets the value of "background-position-x" */
  void set backgroundPositionX(String value) {
    setProperty('background-position-x', value, '');
  }

  /** Gets the value of "background-position-y" */
  String get backgroundPositionY =>
    getPropertyValue('background-position-y');

  /** Sets the value of "background-position-y" */
  void set backgroundPositionY(String value) {
    setProperty('background-position-y', value, '');
  }

  /** Gets the value of "background-repeat" */
  String get backgroundRepeat =>
    getPropertyValue('background-repeat');

  /** Sets the value of "background-repeat" */
  void set backgroundRepeat(String value) {
    setProperty('background-repeat', value, '');
  }

  /** Gets the value of "background-repeat-x" */
  String get backgroundRepeatX =>
    getPropertyValue('background-repeat-x');

  /** Sets the value of "background-repeat-x" */
  void set backgroundRepeatX(String value) {
    setProperty('background-repeat-x', value, '');
  }

  /** Gets the value of "background-repeat-y" */
  String get backgroundRepeatY =>
    getPropertyValue('background-repeat-y');

  /** Sets the value of "background-repeat-y" */
  void set backgroundRepeatY(String value) {
    setProperty('background-repeat-y', value, '');
  }

  /** Gets the value of "background-size" */
  String get backgroundSize =>
    getPropertyValue('background-size');

  /** Sets the value of "background-size" */
  void set backgroundSize(String value) {
    setProperty('background-size', value, '');
  }

  /** Gets the value of "blend-mode" */
  String get blendMode =>
    getPropertyValue('${_browserPrefix}blend-mode');

  /** Sets the value of "blend-mode" */
  void set blendMode(String value) {
    setProperty('${_browserPrefix}blend-mode', value, '');
  }

  /** Gets the value of "border" */
  String get border =>
    getPropertyValue('border');

  /** Sets the value of "border" */
  void set border(String value) {
    setProperty('border', value, '');
  }

  /** Gets the value of "border-after" */
  String get borderAfter =>
    getPropertyValue('${_browserPrefix}border-after');

  /** Sets the value of "border-after" */
  void set borderAfter(String value) {
    setProperty('${_browserPrefix}border-after', value, '');
  }

  /** Gets the value of "border-after-color" */
  String get borderAfterColor =>
    getPropertyValue('${_browserPrefix}border-after-color');

  /** Sets the value of "border-after-color" */
  void set borderAfterColor(String value) {
    setProperty('${_browserPrefix}border-after-color', value, '');
  }

  /** Gets the value of "border-after-style" */
  String get borderAfterStyle =>
    getPropertyValue('${_browserPrefix}border-after-style');

  /** Sets the value of "border-after-style" */
  void set borderAfterStyle(String value) {
    setProperty('${_browserPrefix}border-after-style', value, '');
  }

  /** Gets the value of "border-after-width" */
  String get borderAfterWidth =>
    getPropertyValue('${_browserPrefix}border-after-width');

  /** Sets the value of "border-after-width" */
  void set borderAfterWidth(String value) {
    setProperty('${_browserPrefix}border-after-width', value, '');
  }

  /** Gets the value of "border-before" */
  String get borderBefore =>
    getPropertyValue('${_browserPrefix}border-before');

  /** Sets the value of "border-before" */
  void set borderBefore(String value) {
    setProperty('${_browserPrefix}border-before', value, '');
  }

  /** Gets the value of "border-before-color" */
  String get borderBeforeColor =>
    getPropertyValue('${_browserPrefix}border-before-color');

  /** Sets the value of "border-before-color" */
  void set borderBeforeColor(String value) {
    setProperty('${_browserPrefix}border-before-color', value, '');
  }

  /** Gets the value of "border-before-style" */
  String get borderBeforeStyle =>
    getPropertyValue('${_browserPrefix}border-before-style');

  /** Sets the value of "border-before-style" */
  void set borderBeforeStyle(String value) {
    setProperty('${_browserPrefix}border-before-style', value, '');
  }

  /** Gets the value of "border-before-width" */
  String get borderBeforeWidth =>
    getPropertyValue('${_browserPrefix}border-before-width');

  /** Sets the value of "border-before-width" */
  void set borderBeforeWidth(String value) {
    setProperty('${_browserPrefix}border-before-width', value, '');
  }

  /** Gets the value of "border-bottom" */
  String get borderBottom =>
    getPropertyValue('border-bottom');

  /** Sets the value of "border-bottom" */
  void set borderBottom(String value) {
    setProperty('border-bottom', value, '');
  }

  /** Gets the value of "border-bottom-color" */
  String get borderBottomColor =>
    getPropertyValue('border-bottom-color');

  /** Sets the value of "border-bottom-color" */
  void set borderBottomColor(String value) {
    setProperty('border-bottom-color', value, '');
  }

  /** Gets the value of "border-bottom-left-radius" */
  String get borderBottomLeftRadius =>
    getPropertyValue('border-bottom-left-radius');

  /** Sets the value of "border-bottom-left-radius" */
  void set borderBottomLeftRadius(String value) {
    setProperty('border-bottom-left-radius', value, '');
  }

  /** Gets the value of "border-bottom-right-radius" */
  String get borderBottomRightRadius =>
    getPropertyValue('border-bottom-right-radius');

  /** Sets the value of "border-bottom-right-radius" */
  void set borderBottomRightRadius(String value) {
    setProperty('border-bottom-right-radius', value, '');
  }

  /** Gets the value of "border-bottom-style" */
  String get borderBottomStyle =>
    getPropertyValue('border-bottom-style');

  /** Sets the value of "border-bottom-style" */
  void set borderBottomStyle(String value) {
    setProperty('border-bottom-style', value, '');
  }

  /** Gets the value of "border-bottom-width" */
  String get borderBottomWidth =>
    getPropertyValue('border-bottom-width');

  /** Sets the value of "border-bottom-width" */
  void set borderBottomWidth(String value) {
    setProperty('border-bottom-width', value, '');
  }

  /** Gets the value of "border-collapse" */
  String get borderCollapse =>
    getPropertyValue('border-collapse');

  /** Sets the value of "border-collapse" */
  void set borderCollapse(String value) {
    setProperty('border-collapse', value, '');
  }

  /** Gets the value of "border-color" */
  String get borderColor =>
    getPropertyValue('border-color');

  /** Sets the value of "border-color" */
  void set borderColor(String value) {
    setProperty('border-color', value, '');
  }

  /** Gets the value of "border-end" */
  String get borderEnd =>
    getPropertyValue('${_browserPrefix}border-end');

  /** Sets the value of "border-end" */
  void set borderEnd(String value) {
    setProperty('${_browserPrefix}border-end', value, '');
  }

  /** Gets the value of "border-end-color" */
  String get borderEndColor =>
    getPropertyValue('${_browserPrefix}border-end-color');

  /** Sets the value of "border-end-color" */
  void set borderEndColor(String value) {
    setProperty('${_browserPrefix}border-end-color', value, '');
  }

  /** Gets the value of "border-end-style" */
  String get borderEndStyle =>
    getPropertyValue('${_browserPrefix}border-end-style');

  /** Sets the value of "border-end-style" */
  void set borderEndStyle(String value) {
    setProperty('${_browserPrefix}border-end-style', value, '');
  }

  /** Gets the value of "border-end-width" */
  String get borderEndWidth =>
    getPropertyValue('${_browserPrefix}border-end-width');

  /** Sets the value of "border-end-width" */
  void set borderEndWidth(String value) {
    setProperty('${_browserPrefix}border-end-width', value, '');
  }

  /** Gets the value of "border-fit" */
  String get borderFit =>
    getPropertyValue('${_browserPrefix}border-fit');

  /** Sets the value of "border-fit" */
  void set borderFit(String value) {
    setProperty('${_browserPrefix}border-fit', value, '');
  }

  /** Gets the value of "border-horizontal-spacing" */
  String get borderHorizontalSpacing =>
    getPropertyValue('${_browserPrefix}border-horizontal-spacing');

  /** Sets the value of "border-horizontal-spacing" */
  void set borderHorizontalSpacing(String value) {
    setProperty('${_browserPrefix}border-horizontal-spacing', value, '');
  }

  /** Gets the value of "border-image" */
  String get borderImage =>
    getPropertyValue('border-image');

  /** Sets the value of "border-image" */
  void set borderImage(String value) {
    setProperty('border-image', value, '');
  }

  /** Gets the value of "border-image-outset" */
  String get borderImageOutset =>
    getPropertyValue('border-image-outset');

  /** Sets the value of "border-image-outset" */
  void set borderImageOutset(String value) {
    setProperty('border-image-outset', value, '');
  }

  /** Gets the value of "border-image-repeat" */
  String get borderImageRepeat =>
    getPropertyValue('border-image-repeat');

  /** Sets the value of "border-image-repeat" */
  void set borderImageRepeat(String value) {
    setProperty('border-image-repeat', value, '');
  }

  /** Gets the value of "border-image-slice" */
  String get borderImageSlice =>
    getPropertyValue('border-image-slice');

  /** Sets the value of "border-image-slice" */
  void set borderImageSlice(String value) {
    setProperty('border-image-slice', value, '');
  }

  /** Gets the value of "border-image-source" */
  String get borderImageSource =>
    getPropertyValue('border-image-source');

  /** Sets the value of "border-image-source" */
  void set borderImageSource(String value) {
    setProperty('border-image-source', value, '');
  }

  /** Gets the value of "border-image-width" */
  String get borderImageWidth =>
    getPropertyValue('border-image-width');

  /** Sets the value of "border-image-width" */
  void set borderImageWidth(String value) {
    setProperty('border-image-width', value, '');
  }

  /** Gets the value of "border-left" */
  String get borderLeft =>
    getPropertyValue('border-left');

  /** Sets the value of "border-left" */
  void set borderLeft(String value) {
    setProperty('border-left', value, '');
  }

  /** Gets the value of "border-left-color" */
  String get borderLeftColor =>
    getPropertyValue('border-left-color');

  /** Sets the value of "border-left-color" */
  void set borderLeftColor(String value) {
    setProperty('border-left-color', value, '');
  }

  /** Gets the value of "border-left-style" */
  String get borderLeftStyle =>
    getPropertyValue('border-left-style');

  /** Sets the value of "border-left-style" */
  void set borderLeftStyle(String value) {
    setProperty('border-left-style', value, '');
  }

  /** Gets the value of "border-left-width" */
  String get borderLeftWidth =>
    getPropertyValue('border-left-width');

  /** Sets the value of "border-left-width" */
  void set borderLeftWidth(String value) {
    setProperty('border-left-width', value, '');
  }

  /** Gets the value of "border-radius" */
  String get borderRadius =>
    getPropertyValue('border-radius');

  /** Sets the value of "border-radius" */
  void set borderRadius(String value) {
    setProperty('border-radius', value, '');
  }

  /** Gets the value of "border-right" */
  String get borderRight =>
    getPropertyValue('border-right');

  /** Sets the value of "border-right" */
  void set borderRight(String value) {
    setProperty('border-right', value, '');
  }

  /** Gets the value of "border-right-color" */
  String get borderRightColor =>
    getPropertyValue('border-right-color');

  /** Sets the value of "border-right-color" */
  void set borderRightColor(String value) {
    setProperty('border-right-color', value, '');
  }

  /** Gets the value of "border-right-style" */
  String get borderRightStyle =>
    getPropertyValue('border-right-style');

  /** Sets the value of "border-right-style" */
  void set borderRightStyle(String value) {
    setProperty('border-right-style', value, '');
  }

  /** Gets the value of "border-right-width" */
  String get borderRightWidth =>
    getPropertyValue('border-right-width');

  /** Sets the value of "border-right-width" */
  void set borderRightWidth(String value) {
    setProperty('border-right-width', value, '');
  }

  /** Gets the value of "border-spacing" */
  String get borderSpacing =>
    getPropertyValue('border-spacing');

  /** Sets the value of "border-spacing" */
  void set borderSpacing(String value) {
    setProperty('border-spacing', value, '');
  }

  /** Gets the value of "border-start" */
  String get borderStart =>
    getPropertyValue('${_browserPrefix}border-start');

  /** Sets the value of "border-start" */
  void set borderStart(String value) {
    setProperty('${_browserPrefix}border-start', value, '');
  }

  /** Gets the value of "border-start-color" */
  String get borderStartColor =>
    getPropertyValue('${_browserPrefix}border-start-color');

  /** Sets the value of "border-start-color" */
  void set borderStartColor(String value) {
    setProperty('${_browserPrefix}border-start-color', value, '');
  }

  /** Gets the value of "border-start-style" */
  String get borderStartStyle =>
    getPropertyValue('${_browserPrefix}border-start-style');

  /** Sets the value of "border-start-style" */
  void set borderStartStyle(String value) {
    setProperty('${_browserPrefix}border-start-style', value, '');
  }

  /** Gets the value of "border-start-width" */
  String get borderStartWidth =>
    getPropertyValue('${_browserPrefix}border-start-width');

  /** Sets the value of "border-start-width" */
  void set borderStartWidth(String value) {
    setProperty('${_browserPrefix}border-start-width', value, '');
  }

  /** Gets the value of "border-style" */
  String get borderStyle =>
    getPropertyValue('border-style');

  /** Sets the value of "border-style" */
  void set borderStyle(String value) {
    setProperty('border-style', value, '');
  }

  /** Gets the value of "border-top" */
  String get borderTop =>
    getPropertyValue('border-top');

  /** Sets the value of "border-top" */
  void set borderTop(String value) {
    setProperty('border-top', value, '');
  }

  /** Gets the value of "border-top-color" */
  String get borderTopColor =>
    getPropertyValue('border-top-color');

  /** Sets the value of "border-top-color" */
  void set borderTopColor(String value) {
    setProperty('border-top-color', value, '');
  }

  /** Gets the value of "border-top-left-radius" */
  String get borderTopLeftRadius =>
    getPropertyValue('border-top-left-radius');

  /** Sets the value of "border-top-left-radius" */
  void set borderTopLeftRadius(String value) {
    setProperty('border-top-left-radius', value, '');
  }

  /** Gets the value of "border-top-right-radius" */
  String get borderTopRightRadius =>
    getPropertyValue('border-top-right-radius');

  /** Sets the value of "border-top-right-radius" */
  void set borderTopRightRadius(String value) {
    setProperty('border-top-right-radius', value, '');
  }

  /** Gets the value of "border-top-style" */
  String get borderTopStyle =>
    getPropertyValue('border-top-style');

  /** Sets the value of "border-top-style" */
  void set borderTopStyle(String value) {
    setProperty('border-top-style', value, '');
  }

  /** Gets the value of "border-top-width" */
  String get borderTopWidth =>
    getPropertyValue('border-top-width');

  /** Sets the value of "border-top-width" */
  void set borderTopWidth(String value) {
    setProperty('border-top-width', value, '');
  }

  /** Gets the value of "border-vertical-spacing" */
  String get borderVerticalSpacing =>
    getPropertyValue('${_browserPrefix}border-vertical-spacing');

  /** Sets the value of "border-vertical-spacing" */
  void set borderVerticalSpacing(String value) {
    setProperty('${_browserPrefix}border-vertical-spacing', value, '');
  }

  /** Gets the value of "border-width" */
  String get borderWidth =>
    getPropertyValue('border-width');

  /** Sets the value of "border-width" */
  void set borderWidth(String value) {
    setProperty('border-width', value, '');
  }

  /** Gets the value of "bottom" */
  String get bottom =>
    getPropertyValue('bottom');

  /** Sets the value of "bottom" */
  void set bottom(String value) {
    setProperty('bottom', value, '');
  }

  /** Gets the value of "box-align" */
  String get boxAlign =>
    getPropertyValue('${_browserPrefix}box-align');

  /** Sets the value of "box-align" */
  void set boxAlign(String value) {
    setProperty('${_browserPrefix}box-align', value, '');
  }

  /** Gets the value of "box-decoration-break" */
  String get boxDecorationBreak =>
    getPropertyValue('${_browserPrefix}box-decoration-break');

  /** Sets the value of "box-decoration-break" */
  void set boxDecorationBreak(String value) {
    setProperty('${_browserPrefix}box-decoration-break', value, '');
  }

  /** Gets the value of "box-direction" */
  String get boxDirection =>
    getPropertyValue('${_browserPrefix}box-direction');

  /** Sets the value of "box-direction" */
  void set boxDirection(String value) {
    setProperty('${_browserPrefix}box-direction', value, '');
  }

  /** Gets the value of "box-flex" */
  String get boxFlex =>
    getPropertyValue('${_browserPrefix}box-flex');

  /** Sets the value of "box-flex" */
  void set boxFlex(String value) {
    setProperty('${_browserPrefix}box-flex', value, '');
  }

  /** Gets the value of "box-flex-group" */
  String get boxFlexGroup =>
    getPropertyValue('${_browserPrefix}box-flex-group');

  /** Sets the value of "box-flex-group" */
  void set boxFlexGroup(String value) {
    setProperty('${_browserPrefix}box-flex-group', value, '');
  }

  /** Gets the value of "box-lines" */
  String get boxLines =>
    getPropertyValue('${_browserPrefix}box-lines');

  /** Sets the value of "box-lines" */
  void set boxLines(String value) {
    setProperty('${_browserPrefix}box-lines', value, '');
  }

  /** Gets the value of "box-ordinal-group" */
  String get boxOrdinalGroup =>
    getPropertyValue('${_browserPrefix}box-ordinal-group');

  /** Sets the value of "box-ordinal-group" */
  void set boxOrdinalGroup(String value) {
    setProperty('${_browserPrefix}box-ordinal-group', value, '');
  }

  /** Gets the value of "box-orient" */
  String get boxOrient =>
    getPropertyValue('${_browserPrefix}box-orient');

  /** Sets the value of "box-orient" */
  void set boxOrient(String value) {
    setProperty('${_browserPrefix}box-orient', value, '');
  }

  /** Gets the value of "box-pack" */
  String get boxPack =>
    getPropertyValue('${_browserPrefix}box-pack');

  /** Sets the value of "box-pack" */
  void set boxPack(String value) {
    setProperty('${_browserPrefix}box-pack', value, '');
  }

  /** Gets the value of "box-reflect" */
  String get boxReflect =>
    getPropertyValue('${_browserPrefix}box-reflect');

  /** Sets the value of "box-reflect" */
  void set boxReflect(String value) {
    setProperty('${_browserPrefix}box-reflect', value, '');
  }

  /** Gets the value of "box-shadow" */
  String get boxShadow =>
    getPropertyValue('box-shadow');

  /** Sets the value of "box-shadow" */
  void set boxShadow(String value) {
    setProperty('box-shadow', value, '');
  }

  /** Gets the value of "box-sizing" */
  String get boxSizing =>
    getPropertyValue('box-sizing');

  /** Sets the value of "box-sizing" */
  void set boxSizing(String value) {
    setProperty('box-sizing', value, '');
  }

  /** Gets the value of "caption-side" */
  String get captionSide =>
    getPropertyValue('caption-side');

  /** Sets the value of "caption-side" */
  void set captionSide(String value) {
    setProperty('caption-side', value, '');
  }

  /** Gets the value of "clear" */
  String get clear =>
    getPropertyValue('clear');

  /** Sets the value of "clear" */
  void set clear(String value) {
    setProperty('clear', value, '');
  }

  /** Gets the value of "clip" */
  String get clip =>
    getPropertyValue('clip');

  /** Sets the value of "clip" */
  void set clip(String value) {
    setProperty('clip', value, '');
  }

  /** Gets the value of "clip-path" */
  String get clipPath =>
    getPropertyValue('${_browserPrefix}clip-path');

  /** Sets the value of "clip-path" */
  void set clipPath(String value) {
    setProperty('${_browserPrefix}clip-path', value, '');
  }

  /** Gets the value of "color" */
  String get color =>
    getPropertyValue('color');

  /** Sets the value of "color" */
  void set color(String value) {
    setProperty('color', value, '');
  }

  /** Gets the value of "color-correction" */
  String get colorCorrection =>
    getPropertyValue('${_browserPrefix}color-correction');

  /** Sets the value of "color-correction" */
  void set colorCorrection(String value) {
    setProperty('${_browserPrefix}color-correction', value, '');
  }

  /** Gets the value of "column-axis" */
  String get columnAxis =>
    getPropertyValue('${_browserPrefix}column-axis');

  /** Sets the value of "column-axis" */
  void set columnAxis(String value) {
    setProperty('${_browserPrefix}column-axis', value, '');
  }

  /** Gets the value of "column-break-after" */
  String get columnBreakAfter =>
    getPropertyValue('${_browserPrefix}column-break-after');

  /** Sets the value of "column-break-after" */
  void set columnBreakAfter(String value) {
    setProperty('${_browserPrefix}column-break-after', value, '');
  }

  /** Gets the value of "column-break-before" */
  String get columnBreakBefore =>
    getPropertyValue('${_browserPrefix}column-break-before');

  /** Sets the value of "column-break-before" */
  void set columnBreakBefore(String value) {
    setProperty('${_browserPrefix}column-break-before', value, '');
  }

  /** Gets the value of "column-break-inside" */
  String get columnBreakInside =>
    getPropertyValue('${_browserPrefix}column-break-inside');

  /** Sets the value of "column-break-inside" */
  void set columnBreakInside(String value) {
    setProperty('${_browserPrefix}column-break-inside', value, '');
  }

  /** Gets the value of "column-count" */
  String get columnCount =>
    getPropertyValue('${_browserPrefix}column-count');

  /** Sets the value of "column-count" */
  void set columnCount(String value) {
    setProperty('${_browserPrefix}column-count', value, '');
  }

  /** Gets the value of "column-gap" */
  String get columnGap =>
    getPropertyValue('${_browserPrefix}column-gap');

  /** Sets the value of "column-gap" */
  void set columnGap(String value) {
    setProperty('${_browserPrefix}column-gap', value, '');
  }

  /** Gets the value of "column-progression" */
  String get columnProgression =>
    getPropertyValue('${_browserPrefix}column-progression');

  /** Sets the value of "column-progression" */
  void set columnProgression(String value) {
    setProperty('${_browserPrefix}column-progression', value, '');
  }

  /** Gets the value of "column-rule" */
  String get columnRule =>
    getPropertyValue('${_browserPrefix}column-rule');

  /** Sets the value of "column-rule" */
  void set columnRule(String value) {
    setProperty('${_browserPrefix}column-rule', value, '');
  }

  /** Gets the value of "column-rule-color" */
  String get columnRuleColor =>
    getPropertyValue('${_browserPrefix}column-rule-color');

  /** Sets the value of "column-rule-color" */
  void set columnRuleColor(String value) {
    setProperty('${_browserPrefix}column-rule-color', value, '');
  }

  /** Gets the value of "column-rule-style" */
  String get columnRuleStyle =>
    getPropertyValue('${_browserPrefix}column-rule-style');

  /** Sets the value of "column-rule-style" */
  void set columnRuleStyle(String value) {
    setProperty('${_browserPrefix}column-rule-style', value, '');
  }

  /** Gets the value of "column-rule-width" */
  String get columnRuleWidth =>
    getPropertyValue('${_browserPrefix}column-rule-width');

  /** Sets the value of "column-rule-width" */
  void set columnRuleWidth(String value) {
    setProperty('${_browserPrefix}column-rule-width', value, '');
  }

  /** Gets the value of "column-span" */
  String get columnSpan =>
    getPropertyValue('${_browserPrefix}column-span');

  /** Sets the value of "column-span" */
  void set columnSpan(String value) {
    setProperty('${_browserPrefix}column-span', value, '');
  }

  /** Gets the value of "column-width" */
  String get columnWidth =>
    getPropertyValue('${_browserPrefix}column-width');

  /** Sets the value of "column-width" */
  void set columnWidth(String value) {
    setProperty('${_browserPrefix}column-width', value, '');
  }

  /** Gets the value of "columns" */
  String get columns =>
    getPropertyValue('${_browserPrefix}columns');

  /** Sets the value of "columns" */
  void set columns(String value) {
    setProperty('${_browserPrefix}columns', value, '');
  }

  /** Gets the value of "content" */
  String get content =>
    getPropertyValue('content');

  /** Sets the value of "content" */
  void set content(String value) {
    setProperty('content', value, '');
  }

  /** Gets the value of "counter-increment" */
  String get counterIncrement =>
    getPropertyValue('counter-increment');

  /** Sets the value of "counter-increment" */
  void set counterIncrement(String value) {
    setProperty('counter-increment', value, '');
  }

  /** Gets the value of "counter-reset" */
  String get counterReset =>
    getPropertyValue('counter-reset');

  /** Sets the value of "counter-reset" */
  void set counterReset(String value) {
    setProperty('counter-reset', value, '');
  }

  /** Gets the value of "cursor" */
  String get cursor =>
    getPropertyValue('cursor');

  /** Sets the value of "cursor" */
  void set cursor(String value) {
    setProperty('cursor', value, '');
  }

  /** Gets the value of "dashboard-region" */
  String get dashboardRegion =>
    getPropertyValue('${_browserPrefix}dashboard-region');

  /** Sets the value of "dashboard-region" */
  void set dashboardRegion(String value) {
    setProperty('${_browserPrefix}dashboard-region', value, '');
  }

  /** Gets the value of "direction" */
  String get direction =>
    getPropertyValue('direction');

  /** Sets the value of "direction" */
  void set direction(String value) {
    setProperty('direction', value, '');
  }

  /** Gets the value of "display" */
  String get display =>
    getPropertyValue('display');

  /** Sets the value of "display" */
  void set display(String value) {
    setProperty('display', value, '');
  }

  /** Gets the value of "empty-cells" */
  String get emptyCells =>
    getPropertyValue('empty-cells');

  /** Sets the value of "empty-cells" */
  void set emptyCells(String value) {
    setProperty('empty-cells', value, '');
  }

  /** Gets the value of "filter" */
  String get filter =>
    getPropertyValue('${_browserPrefix}filter');

  /** Sets the value of "filter" */
  void set filter(String value) {
    setProperty('${_browserPrefix}filter', value, '');
  }

  /** Gets the value of "flex" */
  String get flex =>
    getPropertyValue('${_browserPrefix}flex');

  /** Sets the value of "flex" */
  void set flex(String value) {
    setProperty('${_browserPrefix}flex', value, '');
  }

  /** Gets the value of "flex-basis" */
  String get flexBasis =>
    getPropertyValue('${_browserPrefix}flex-basis');

  /** Sets the value of "flex-basis" */
  void set flexBasis(String value) {
    setProperty('${_browserPrefix}flex-basis', value, '');
  }

  /** Gets the value of "flex-direction" */
  String get flexDirection =>
    getPropertyValue('${_browserPrefix}flex-direction');

  /** Sets the value of "flex-direction" */
  void set flexDirection(String value) {
    setProperty('${_browserPrefix}flex-direction', value, '');
  }

  /** Gets the value of "flex-flow" */
  String get flexFlow =>
    getPropertyValue('${_browserPrefix}flex-flow');

  /** Sets the value of "flex-flow" */
  void set flexFlow(String value) {
    setProperty('${_browserPrefix}flex-flow', value, '');
  }

  /** Gets the value of "flex-grow" */
  String get flexGrow =>
    getPropertyValue('${_browserPrefix}flex-grow');

  /** Sets the value of "flex-grow" */
  void set flexGrow(String value) {
    setProperty('${_browserPrefix}flex-grow', value, '');
  }

  /** Gets the value of "flex-shrink" */
  String get flexShrink =>
    getPropertyValue('${_browserPrefix}flex-shrink');

  /** Sets the value of "flex-shrink" */
  void set flexShrink(String value) {
    setProperty('${_browserPrefix}flex-shrink', value, '');
  }

  /** Gets the value of "flex-wrap" */
  String get flexWrap =>
    getPropertyValue('${_browserPrefix}flex-wrap');

  /** Sets the value of "flex-wrap" */
  void set flexWrap(String value) {
    setProperty('${_browserPrefix}flex-wrap', value, '');
  }

  /** Gets the value of "float" */
  String get float =>
    getPropertyValue('float');

  /** Sets the value of "float" */
  void set float(String value) {
    setProperty('float', value, '');
  }

  /** Gets the value of "flow-from" */
  String get flowFrom =>
    getPropertyValue('${_browserPrefix}flow-from');

  /** Sets the value of "flow-from" */
  void set flowFrom(String value) {
    setProperty('${_browserPrefix}flow-from', value, '');
  }

  /** Gets the value of "flow-into" */
  String get flowInto =>
    getPropertyValue('${_browserPrefix}flow-into');

  /** Sets the value of "flow-into" */
  void set flowInto(String value) {
    setProperty('${_browserPrefix}flow-into', value, '');
  }

  /** Gets the value of "font" */
  String get font =>
    getPropertyValue('font');

  /** Sets the value of "font" */
  void set font(String value) {
    setProperty('font', value, '');
  }

  /** Gets the value of "font-family" */
  String get fontFamily =>
    getPropertyValue('font-family');

  /** Sets the value of "font-family" */
  void set fontFamily(String value) {
    setProperty('font-family', value, '');
  }

  /** Gets the value of "font-feature-settings" */
  String get fontFeatureSettings =>
    getPropertyValue('${_browserPrefix}font-feature-settings');

  /** Sets the value of "font-feature-settings" */
  void set fontFeatureSettings(String value) {
    setProperty('${_browserPrefix}font-feature-settings', value, '');
  }

  /** Gets the value of "font-kerning" */
  String get fontKerning =>
    getPropertyValue('${_browserPrefix}font-kerning');

  /** Sets the value of "font-kerning" */
  void set fontKerning(String value) {
    setProperty('${_browserPrefix}font-kerning', value, '');
  }

  /** Gets the value of "font-size" */
  String get fontSize =>
    getPropertyValue('font-size');

  /** Sets the value of "font-size" */
  void set fontSize(String value) {
    setProperty('font-size', value, '');
  }

  /** Gets the value of "font-size-delta" */
  String get fontSizeDelta =>
    getPropertyValue('${_browserPrefix}font-size-delta');

  /** Sets the value of "font-size-delta" */
  void set fontSizeDelta(String value) {
    setProperty('${_browserPrefix}font-size-delta', value, '');
  }

  /** Gets the value of "font-smoothing" */
  String get fontSmoothing =>
    getPropertyValue('${_browserPrefix}font-smoothing');

  /** Sets the value of "font-smoothing" */
  void set fontSmoothing(String value) {
    setProperty('${_browserPrefix}font-smoothing', value, '');
  }

  /** Gets the value of "font-stretch" */
  String get fontStretch =>
    getPropertyValue('font-stretch');

  /** Sets the value of "font-stretch" */
  void set fontStretch(String value) {
    setProperty('font-stretch', value, '');
  }

  /** Gets the value of "font-style" */
  String get fontStyle =>
    getPropertyValue('font-style');

  /** Sets the value of "font-style" */
  void set fontStyle(String value) {
    setProperty('font-style', value, '');
  }

  /** Gets the value of "font-variant" */
  String get fontVariant =>
    getPropertyValue('font-variant');

  /** Sets the value of "font-variant" */
  void set fontVariant(String value) {
    setProperty('font-variant', value, '');
  }

  /** Gets the value of "font-variant-ligatures" */
  String get fontVariantLigatures =>
    getPropertyValue('${_browserPrefix}font-variant-ligatures');

  /** Sets the value of "font-variant-ligatures" */
  void set fontVariantLigatures(String value) {
    setProperty('${_browserPrefix}font-variant-ligatures', value, '');
  }

  /** Gets the value of "font-weight" */
  String get fontWeight =>
    getPropertyValue('font-weight');

  /** Sets the value of "font-weight" */
  void set fontWeight(String value) {
    setProperty('font-weight', value, '');
  }

  /** Gets the value of "grid-column" */
  String get gridColumn =>
    getPropertyValue('${_browserPrefix}grid-column');

  /** Sets the value of "grid-column" */
  void set gridColumn(String value) {
    setProperty('${_browserPrefix}grid-column', value, '');
  }

  /** Gets the value of "grid-columns" */
  String get gridColumns =>
    getPropertyValue('${_browserPrefix}grid-columns');

  /** Sets the value of "grid-columns" */
  void set gridColumns(String value) {
    setProperty('${_browserPrefix}grid-columns', value, '');
  }

  /** Gets the value of "grid-row" */
  String get gridRow =>
    getPropertyValue('${_browserPrefix}grid-row');

  /** Sets the value of "grid-row" */
  void set gridRow(String value) {
    setProperty('${_browserPrefix}grid-row', value, '');
  }

  /** Gets the value of "grid-rows" */
  String get gridRows =>
    getPropertyValue('${_browserPrefix}grid-rows');

  /** Sets the value of "grid-rows" */
  void set gridRows(String value) {
    setProperty('${_browserPrefix}grid-rows', value, '');
  }

  /** Gets the value of "height" */
  String get height =>
    getPropertyValue('height');

  /** Sets the value of "height" */
  void set height(String value) {
    setProperty('height', value, '');
  }

  /** Gets the value of "highlight" */
  String get highlight =>
    getPropertyValue('${_browserPrefix}highlight');

  /** Sets the value of "highlight" */
  void set highlight(String value) {
    setProperty('${_browserPrefix}highlight', value, '');
  }

  /** Gets the value of "hyphenate-character" */
  String get hyphenateCharacter =>
    getPropertyValue('${_browserPrefix}hyphenate-character');

  /** Sets the value of "hyphenate-character" */
  void set hyphenateCharacter(String value) {
    setProperty('${_browserPrefix}hyphenate-character', value, '');
  }

  /** Gets the value of "hyphenate-limit-after" */
  String get hyphenateLimitAfter =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-after');

  /** Sets the value of "hyphenate-limit-after" */
  void set hyphenateLimitAfter(String value) {
    setProperty('${_browserPrefix}hyphenate-limit-after', value, '');
  }

  /** Gets the value of "hyphenate-limit-before" */
  String get hyphenateLimitBefore =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-before');

  /** Sets the value of "hyphenate-limit-before" */
  void set hyphenateLimitBefore(String value) {
    setProperty('${_browserPrefix}hyphenate-limit-before', value, '');
  }

  /** Gets the value of "hyphenate-limit-lines" */
  String get hyphenateLimitLines =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-lines');

  /** Sets the value of "hyphenate-limit-lines" */
  void set hyphenateLimitLines(String value) {
    setProperty('${_browserPrefix}hyphenate-limit-lines', value, '');
  }

  /** Gets the value of "hyphens" */
  String get hyphens =>
    getPropertyValue('${_browserPrefix}hyphens');

  /** Sets the value of "hyphens" */
  void set hyphens(String value) {
    setProperty('${_browserPrefix}hyphens', value, '');
  }

  /** Gets the value of "image-orientation" */
  String get imageOrientation =>
    getPropertyValue('image-orientation');

  /** Sets the value of "image-orientation" */
  void set imageOrientation(String value) {
    setProperty('image-orientation', value, '');
  }

  /** Gets the value of "image-rendering" */
  String get imageRendering =>
    getPropertyValue('image-rendering');

  /** Sets the value of "image-rendering" */
  void set imageRendering(String value) {
    setProperty('image-rendering', value, '');
  }

  /** Gets the value of "image-resolution" */
  String get imageResolution =>
    getPropertyValue('image-resolution');

  /** Sets the value of "image-resolution" */
  void set imageResolution(String value) {
    setProperty('image-resolution', value, '');
  }

  /** Gets the value of "justify-content" */
  String get justifyContent =>
    getPropertyValue('${_browserPrefix}justify-content');

  /** Sets the value of "justify-content" */
  void set justifyContent(String value) {
    setProperty('${_browserPrefix}justify-content', value, '');
  }

  /** Gets the value of "left" */
  String get left =>
    getPropertyValue('left');

  /** Sets the value of "left" */
  void set left(String value) {
    setProperty('left', value, '');
  }

  /** Gets the value of "letter-spacing" */
  String get letterSpacing =>
    getPropertyValue('letter-spacing');

  /** Sets the value of "letter-spacing" */
  void set letterSpacing(String value) {
    setProperty('letter-spacing', value, '');
  }

  /** Gets the value of "line-align" */
  String get lineAlign =>
    getPropertyValue('${_browserPrefix}line-align');

  /** Sets the value of "line-align" */
  void set lineAlign(String value) {
    setProperty('${_browserPrefix}line-align', value, '');
  }

  /** Gets the value of "line-box-contain" */
  String get lineBoxContain =>
    getPropertyValue('${_browserPrefix}line-box-contain');

  /** Sets the value of "line-box-contain" */
  void set lineBoxContain(String value) {
    setProperty('${_browserPrefix}line-box-contain', value, '');
  }

  /** Gets the value of "line-break" */
  String get lineBreak =>
    getPropertyValue('${_browserPrefix}line-break');

  /** Sets the value of "line-break" */
  void set lineBreak(String value) {
    setProperty('${_browserPrefix}line-break', value, '');
  }

  /** Gets the value of "line-clamp" */
  String get lineClamp =>
    getPropertyValue('${_browserPrefix}line-clamp');

  /** Sets the value of "line-clamp" */
  void set lineClamp(String value) {
    setProperty('${_browserPrefix}line-clamp', value, '');
  }

  /** Gets the value of "line-grid" */
  String get lineGrid =>
    getPropertyValue('${_browserPrefix}line-grid');

  /** Sets the value of "line-grid" */
  void set lineGrid(String value) {
    setProperty('${_browserPrefix}line-grid', value, '');
  }

  /** Gets the value of "line-height" */
  String get lineHeight =>
    getPropertyValue('line-height');

  /** Sets the value of "line-height" */
  void set lineHeight(String value) {
    setProperty('line-height', value, '');
  }

  /** Gets the value of "line-snap" */
  String get lineSnap =>
    getPropertyValue('${_browserPrefix}line-snap');

  /** Sets the value of "line-snap" */
  void set lineSnap(String value) {
    setProperty('${_browserPrefix}line-snap', value, '');
  }

  /** Gets the value of "list-style" */
  String get listStyle =>
    getPropertyValue('list-style');

  /** Sets the value of "list-style" */
  void set listStyle(String value) {
    setProperty('list-style', value, '');
  }

  /** Gets the value of "list-style-image" */
  String get listStyleImage =>
    getPropertyValue('list-style-image');

  /** Sets the value of "list-style-image" */
  void set listStyleImage(String value) {
    setProperty('list-style-image', value, '');
  }

  /** Gets the value of "list-style-position" */
  String get listStylePosition =>
    getPropertyValue('list-style-position');

  /** Sets the value of "list-style-position" */
  void set listStylePosition(String value) {
    setProperty('list-style-position', value, '');
  }

  /** Gets the value of "list-style-type" */
  String get listStyleType =>
    getPropertyValue('list-style-type');

  /** Sets the value of "list-style-type" */
  void set listStyleType(String value) {
    setProperty('list-style-type', value, '');
  }

  /** Gets the value of "locale" */
  String get locale =>
    getPropertyValue('${_browserPrefix}locale');

  /** Sets the value of "locale" */
  void set locale(String value) {
    setProperty('${_browserPrefix}locale', value, '');
  }

  /** Gets the value of "logical-height" */
  String get logicalHeight =>
    getPropertyValue('${_browserPrefix}logical-height');

  /** Sets the value of "logical-height" */
  void set logicalHeight(String value) {
    setProperty('${_browserPrefix}logical-height', value, '');
  }

  /** Gets the value of "logical-width" */
  String get logicalWidth =>
    getPropertyValue('${_browserPrefix}logical-width');

  /** Sets the value of "logical-width" */
  void set logicalWidth(String value) {
    setProperty('${_browserPrefix}logical-width', value, '');
  }

  /** Gets the value of "margin" */
  String get margin =>
    getPropertyValue('margin');

  /** Sets the value of "margin" */
  void set margin(String value) {
    setProperty('margin', value, '');
  }

  /** Gets the value of "margin-after" */
  String get marginAfter =>
    getPropertyValue('${_browserPrefix}margin-after');

  /** Sets the value of "margin-after" */
  void set marginAfter(String value) {
    setProperty('${_browserPrefix}margin-after', value, '');
  }

  /** Gets the value of "margin-after-collapse" */
  String get marginAfterCollapse =>
    getPropertyValue('${_browserPrefix}margin-after-collapse');

  /** Sets the value of "margin-after-collapse" */
  void set marginAfterCollapse(String value) {
    setProperty('${_browserPrefix}margin-after-collapse', value, '');
  }

  /** Gets the value of "margin-before" */
  String get marginBefore =>
    getPropertyValue('${_browserPrefix}margin-before');

  /** Sets the value of "margin-before" */
  void set marginBefore(String value) {
    setProperty('${_browserPrefix}margin-before', value, '');
  }

  /** Gets the value of "margin-before-collapse" */
  String get marginBeforeCollapse =>
    getPropertyValue('${_browserPrefix}margin-before-collapse');

  /** Sets the value of "margin-before-collapse" */
  void set marginBeforeCollapse(String value) {
    setProperty('${_browserPrefix}margin-before-collapse', value, '');
  }

  /** Gets the value of "margin-bottom" */
  String get marginBottom =>
    getPropertyValue('margin-bottom');

  /** Sets the value of "margin-bottom" */
  void set marginBottom(String value) {
    setProperty('margin-bottom', value, '');
  }

  /** Gets the value of "margin-bottom-collapse" */
  String get marginBottomCollapse =>
    getPropertyValue('${_browserPrefix}margin-bottom-collapse');

  /** Sets the value of "margin-bottom-collapse" */
  void set marginBottomCollapse(String value) {
    setProperty('${_browserPrefix}margin-bottom-collapse', value, '');
  }

  /** Gets the value of "margin-collapse" */
  String get marginCollapse =>
    getPropertyValue('${_browserPrefix}margin-collapse');

  /** Sets the value of "margin-collapse" */
  void set marginCollapse(String value) {
    setProperty('${_browserPrefix}margin-collapse', value, '');
  }

  /** Gets the value of "margin-end" */
  String get marginEnd =>
    getPropertyValue('${_browserPrefix}margin-end');

  /** Sets the value of "margin-end" */
  void set marginEnd(String value) {
    setProperty('${_browserPrefix}margin-end', value, '');
  }

  /** Gets the value of "margin-left" */
  String get marginLeft =>
    getPropertyValue('margin-left');

  /** Sets the value of "margin-left" */
  void set marginLeft(String value) {
    setProperty('margin-left', value, '');
  }

  /** Gets the value of "margin-right" */
  String get marginRight =>
    getPropertyValue('margin-right');

  /** Sets the value of "margin-right" */
  void set marginRight(String value) {
    setProperty('margin-right', value, '');
  }

  /** Gets the value of "margin-start" */
  String get marginStart =>
    getPropertyValue('${_browserPrefix}margin-start');

  /** Sets the value of "margin-start" */
  void set marginStart(String value) {
    setProperty('${_browserPrefix}margin-start', value, '');
  }

  /** Gets the value of "margin-top" */
  String get marginTop =>
    getPropertyValue('margin-top');

  /** Sets the value of "margin-top" */
  void set marginTop(String value) {
    setProperty('margin-top', value, '');
  }

  /** Gets the value of "margin-top-collapse" */
  String get marginTopCollapse =>
    getPropertyValue('${_browserPrefix}margin-top-collapse');

  /** Sets the value of "margin-top-collapse" */
  void set marginTopCollapse(String value) {
    setProperty('${_browserPrefix}margin-top-collapse', value, '');
  }

  /** Gets the value of "marquee" */
  String get marquee =>
    getPropertyValue('${_browserPrefix}marquee');

  /** Sets the value of "marquee" */
  void set marquee(String value) {
    setProperty('${_browserPrefix}marquee', value, '');
  }

  /** Gets the value of "marquee-direction" */
  String get marqueeDirection =>
    getPropertyValue('${_browserPrefix}marquee-direction');

  /** Sets the value of "marquee-direction" */
  void set marqueeDirection(String value) {
    setProperty('${_browserPrefix}marquee-direction', value, '');
  }

  /** Gets the value of "marquee-increment" */
  String get marqueeIncrement =>
    getPropertyValue('${_browserPrefix}marquee-increment');

  /** Sets the value of "marquee-increment" */
  void set marqueeIncrement(String value) {
    setProperty('${_browserPrefix}marquee-increment', value, '');
  }

  /** Gets the value of "marquee-repetition" */
  String get marqueeRepetition =>
    getPropertyValue('${_browserPrefix}marquee-repetition');

  /** Sets the value of "marquee-repetition" */
  void set marqueeRepetition(String value) {
    setProperty('${_browserPrefix}marquee-repetition', value, '');
  }

  /** Gets the value of "marquee-speed" */
  String get marqueeSpeed =>
    getPropertyValue('${_browserPrefix}marquee-speed');

  /** Sets the value of "marquee-speed" */
  void set marqueeSpeed(String value) {
    setProperty('${_browserPrefix}marquee-speed', value, '');
  }

  /** Gets the value of "marquee-style" */
  String get marqueeStyle =>
    getPropertyValue('${_browserPrefix}marquee-style');

  /** Sets the value of "marquee-style" */
  void set marqueeStyle(String value) {
    setProperty('${_browserPrefix}marquee-style', value, '');
  }

  /** Gets the value of "mask" */
  String get mask =>
    getPropertyValue('${_browserPrefix}mask');

  /** Sets the value of "mask" */
  void set mask(String value) {
    setProperty('${_browserPrefix}mask', value, '');
  }

  /** Gets the value of "mask-attachment" */
  String get maskAttachment =>
    getPropertyValue('${_browserPrefix}mask-attachment');

  /** Sets the value of "mask-attachment" */
  void set maskAttachment(String value) {
    setProperty('${_browserPrefix}mask-attachment', value, '');
  }

  /** Gets the value of "mask-box-image" */
  String get maskBoxImage =>
    getPropertyValue('${_browserPrefix}mask-box-image');

  /** Sets the value of "mask-box-image" */
  void set maskBoxImage(String value) {
    setProperty('${_browserPrefix}mask-box-image', value, '');
  }

  /** Gets the value of "mask-box-image-outset" */
  String get maskBoxImageOutset =>
    getPropertyValue('${_browserPrefix}mask-box-image-outset');

  /** Sets the value of "mask-box-image-outset" */
  void set maskBoxImageOutset(String value) {
    setProperty('${_browserPrefix}mask-box-image-outset', value, '');
  }

  /** Gets the value of "mask-box-image-repeat" */
  String get maskBoxImageRepeat =>
    getPropertyValue('${_browserPrefix}mask-box-image-repeat');

  /** Sets the value of "mask-box-image-repeat" */
  void set maskBoxImageRepeat(String value) {
    setProperty('${_browserPrefix}mask-box-image-repeat', value, '');
  }

  /** Gets the value of "mask-box-image-slice" */
  String get maskBoxImageSlice =>
    getPropertyValue('${_browserPrefix}mask-box-image-slice');

  /** Sets the value of "mask-box-image-slice" */
  void set maskBoxImageSlice(String value) {
    setProperty('${_browserPrefix}mask-box-image-slice', value, '');
  }

  /** Gets the value of "mask-box-image-source" */
  String get maskBoxImageSource =>
    getPropertyValue('${_browserPrefix}mask-box-image-source');

  /** Sets the value of "mask-box-image-source" */
  void set maskBoxImageSource(String value) {
    setProperty('${_browserPrefix}mask-box-image-source', value, '');
  }

  /** Gets the value of "mask-box-image-width" */
  String get maskBoxImageWidth =>
    getPropertyValue('${_browserPrefix}mask-box-image-width');

  /** Sets the value of "mask-box-image-width" */
  void set maskBoxImageWidth(String value) {
    setProperty('${_browserPrefix}mask-box-image-width', value, '');
  }

  /** Gets the value of "mask-clip" */
  String get maskClip =>
    getPropertyValue('${_browserPrefix}mask-clip');

  /** Sets the value of "mask-clip" */
  void set maskClip(String value) {
    setProperty('${_browserPrefix}mask-clip', value, '');
  }

  /** Gets the value of "mask-composite" */
  String get maskComposite =>
    getPropertyValue('${_browserPrefix}mask-composite');

  /** Sets the value of "mask-composite" */
  void set maskComposite(String value) {
    setProperty('${_browserPrefix}mask-composite', value, '');
  }

  /** Gets the value of "mask-image" */
  String get maskImage =>
    getPropertyValue('${_browserPrefix}mask-image');

  /** Sets the value of "mask-image" */
  void set maskImage(String value) {
    setProperty('${_browserPrefix}mask-image', value, '');
  }

  /** Gets the value of "mask-origin" */
  String get maskOrigin =>
    getPropertyValue('${_browserPrefix}mask-origin');

  /** Sets the value of "mask-origin" */
  void set maskOrigin(String value) {
    setProperty('${_browserPrefix}mask-origin', value, '');
  }

  /** Gets the value of "mask-position" */
  String get maskPosition =>
    getPropertyValue('${_browserPrefix}mask-position');

  /** Sets the value of "mask-position" */
  void set maskPosition(String value) {
    setProperty('${_browserPrefix}mask-position', value, '');
  }

  /** Gets the value of "mask-position-x" */
  String get maskPositionX =>
    getPropertyValue('${_browserPrefix}mask-position-x');

  /** Sets the value of "mask-position-x" */
  void set maskPositionX(String value) {
    setProperty('${_browserPrefix}mask-position-x', value, '');
  }

  /** Gets the value of "mask-position-y" */
  String get maskPositionY =>
    getPropertyValue('${_browserPrefix}mask-position-y');

  /** Sets the value of "mask-position-y" */
  void set maskPositionY(String value) {
    setProperty('${_browserPrefix}mask-position-y', value, '');
  }

  /** Gets the value of "mask-repeat" */
  String get maskRepeat =>
    getPropertyValue('${_browserPrefix}mask-repeat');

  /** Sets the value of "mask-repeat" */
  void set maskRepeat(String value) {
    setProperty('${_browserPrefix}mask-repeat', value, '');
  }

  /** Gets the value of "mask-repeat-x" */
  String get maskRepeatX =>
    getPropertyValue('${_browserPrefix}mask-repeat-x');

  /** Sets the value of "mask-repeat-x" */
  void set maskRepeatX(String value) {
    setProperty('${_browserPrefix}mask-repeat-x', value, '');
  }

  /** Gets the value of "mask-repeat-y" */
  String get maskRepeatY =>
    getPropertyValue('${_browserPrefix}mask-repeat-y');

  /** Sets the value of "mask-repeat-y" */
  void set maskRepeatY(String value) {
    setProperty('${_browserPrefix}mask-repeat-y', value, '');
  }

  /** Gets the value of "mask-size" */
  String get maskSize =>
    getPropertyValue('${_browserPrefix}mask-size');

  /** Sets the value of "mask-size" */
  void set maskSize(String value) {
    setProperty('${_browserPrefix}mask-size', value, '');
  }

  /** Gets the value of "max-height" */
  String get maxHeight =>
    getPropertyValue('max-height');

  /** Sets the value of "max-height" */
  void set maxHeight(String value) {
    setProperty('max-height', value, '');
  }

  /** Gets the value of "max-logical-height" */
  String get maxLogicalHeight =>
    getPropertyValue('${_browserPrefix}max-logical-height');

  /** Sets the value of "max-logical-height" */
  void set maxLogicalHeight(String value) {
    setProperty('${_browserPrefix}max-logical-height', value, '');
  }

  /** Gets the value of "max-logical-width" */
  String get maxLogicalWidth =>
    getPropertyValue('${_browserPrefix}max-logical-width');

  /** Sets the value of "max-logical-width" */
  void set maxLogicalWidth(String value) {
    setProperty('${_browserPrefix}max-logical-width', value, '');
  }

  /** Gets the value of "max-width" */
  String get maxWidth =>
    getPropertyValue('max-width');

  /** Sets the value of "max-width" */
  void set maxWidth(String value) {
    setProperty('max-width', value, '');
  }

  /** Gets the value of "max-zoom" */
  String get maxZoom =>
    getPropertyValue('max-zoom');

  /** Sets the value of "max-zoom" */
  void set maxZoom(String value) {
    setProperty('max-zoom', value, '');
  }

  /** Gets the value of "min-height" */
  String get minHeight =>
    getPropertyValue('min-height');

  /** Sets the value of "min-height" */
  void set minHeight(String value) {
    setProperty('min-height', value, '');
  }

  /** Gets the value of "min-logical-height" */
  String get minLogicalHeight =>
    getPropertyValue('${_browserPrefix}min-logical-height');

  /** Sets the value of "min-logical-height" */
  void set minLogicalHeight(String value) {
    setProperty('${_browserPrefix}min-logical-height', value, '');
  }

  /** Gets the value of "min-logical-width" */
  String get minLogicalWidth =>
    getPropertyValue('${_browserPrefix}min-logical-width');

  /** Sets the value of "min-logical-width" */
  void set minLogicalWidth(String value) {
    setProperty('${_browserPrefix}min-logical-width', value, '');
  }

  /** Gets the value of "min-width" */
  String get minWidth =>
    getPropertyValue('min-width');

  /** Sets the value of "min-width" */
  void set minWidth(String value) {
    setProperty('min-width', value, '');
  }

  /** Gets the value of "min-zoom" */
  String get minZoom =>
    getPropertyValue('min-zoom');

  /** Sets the value of "min-zoom" */
  void set minZoom(String value) {
    setProperty('min-zoom', value, '');
  }

  /** Gets the value of "nbsp-mode" */
  String get nbspMode =>
    getPropertyValue('${_browserPrefix}nbsp-mode');

  /** Sets the value of "nbsp-mode" */
  void set nbspMode(String value) {
    setProperty('${_browserPrefix}nbsp-mode', value, '');
  }

  /** Gets the value of "opacity" */
  String get opacity =>
    getPropertyValue('opacity');

  /** Sets the value of "opacity" */
  void set opacity(String value) {
    setProperty('opacity', value, '');
  }

  /** Gets the value of "order" */
  String get order =>
    getPropertyValue('${_browserPrefix}order');

  /** Sets the value of "order" */
  void set order(String value) {
    setProperty('${_browserPrefix}order', value, '');
  }

  /** Gets the value of "orientation" */
  String get orientation =>
    getPropertyValue('orientation');

  /** Sets the value of "orientation" */
  void set orientation(String value) {
    setProperty('orientation', value, '');
  }

  /** Gets the value of "orphans" */
  String get orphans =>
    getPropertyValue('orphans');

  /** Sets the value of "orphans" */
  void set orphans(String value) {
    setProperty('orphans', value, '');
  }

  /** Gets the value of "outline" */
  String get outline =>
    getPropertyValue('outline');

  /** Sets the value of "outline" */
  void set outline(String value) {
    setProperty('outline', value, '');
  }

  /** Gets the value of "outline-color" */
  String get outlineColor =>
    getPropertyValue('outline-color');

  /** Sets the value of "outline-color" */
  void set outlineColor(String value) {
    setProperty('outline-color', value, '');
  }

  /** Gets the value of "outline-offset" */
  String get outlineOffset =>
    getPropertyValue('outline-offset');

  /** Sets the value of "outline-offset" */
  void set outlineOffset(String value) {
    setProperty('outline-offset', value, '');
  }

  /** Gets the value of "outline-style" */
  String get outlineStyle =>
    getPropertyValue('outline-style');

  /** Sets the value of "outline-style" */
  void set outlineStyle(String value) {
    setProperty('outline-style', value, '');
  }

  /** Gets the value of "outline-width" */
  String get outlineWidth =>
    getPropertyValue('outline-width');

  /** Sets the value of "outline-width" */
  void set outlineWidth(String value) {
    setProperty('outline-width', value, '');
  }

  /** Gets the value of "overflow" */
  String get overflow =>
    getPropertyValue('overflow');

  /** Sets the value of "overflow" */
  void set overflow(String value) {
    setProperty('overflow', value, '');
  }

  /** Gets the value of "overflow-scrolling" */
  String get overflowScrolling =>
    getPropertyValue('${_browserPrefix}overflow-scrolling');

  /** Sets the value of "overflow-scrolling" */
  void set overflowScrolling(String value) {
    setProperty('${_browserPrefix}overflow-scrolling', value, '');
  }

  /** Gets the value of "overflow-wrap" */
  String get overflowWrap =>
    getPropertyValue('overflow-wrap');

  /** Sets the value of "overflow-wrap" */
  void set overflowWrap(String value) {
    setProperty('overflow-wrap', value, '');
  }

  /** Gets the value of "overflow-x" */
  String get overflowX =>
    getPropertyValue('overflow-x');

  /** Sets the value of "overflow-x" */
  void set overflowX(String value) {
    setProperty('overflow-x', value, '');
  }

  /** Gets the value of "overflow-y" */
  String get overflowY =>
    getPropertyValue('overflow-y');

  /** Sets the value of "overflow-y" */
  void set overflowY(String value) {
    setProperty('overflow-y', value, '');
  }

  /** Gets the value of "padding" */
  String get padding =>
    getPropertyValue('padding');

  /** Sets the value of "padding" */
  void set padding(String value) {
    setProperty('padding', value, '');
  }

  /** Gets the value of "padding-after" */
  String get paddingAfter =>
    getPropertyValue('${_browserPrefix}padding-after');

  /** Sets the value of "padding-after" */
  void set paddingAfter(String value) {
    setProperty('${_browserPrefix}padding-after', value, '');
  }

  /** Gets the value of "padding-before" */
  String get paddingBefore =>
    getPropertyValue('${_browserPrefix}padding-before');

  /** Sets the value of "padding-before" */
  void set paddingBefore(String value) {
    setProperty('${_browserPrefix}padding-before', value, '');
  }

  /** Gets the value of "padding-bottom" */
  String get paddingBottom =>
    getPropertyValue('padding-bottom');

  /** Sets the value of "padding-bottom" */
  void set paddingBottom(String value) {
    setProperty('padding-bottom', value, '');
  }

  /** Gets the value of "padding-end" */
  String get paddingEnd =>
    getPropertyValue('${_browserPrefix}padding-end');

  /** Sets the value of "padding-end" */
  void set paddingEnd(String value) {
    setProperty('${_browserPrefix}padding-end', value, '');
  }

  /** Gets the value of "padding-left" */
  String get paddingLeft =>
    getPropertyValue('padding-left');

  /** Sets the value of "padding-left" */
  void set paddingLeft(String value) {
    setProperty('padding-left', value, '');
  }

  /** Gets the value of "padding-right" */
  String get paddingRight =>
    getPropertyValue('padding-right');

  /** Sets the value of "padding-right" */
  void set paddingRight(String value) {
    setProperty('padding-right', value, '');
  }

  /** Gets the value of "padding-start" */
  String get paddingStart =>
    getPropertyValue('${_browserPrefix}padding-start');

  /** Sets the value of "padding-start" */
  void set paddingStart(String value) {
    setProperty('${_browserPrefix}padding-start', value, '');
  }

  /** Gets the value of "padding-top" */
  String get paddingTop =>
    getPropertyValue('padding-top');

  /** Sets the value of "padding-top" */
  void set paddingTop(String value) {
    setProperty('padding-top', value, '');
  }

  /** Gets the value of "page" */
  String get page =>
    getPropertyValue('page');

  /** Sets the value of "page" */
  void set page(String value) {
    setProperty('page', value, '');
  }

  /** Gets the value of "page-break-after" */
  String get pageBreakAfter =>
    getPropertyValue('page-break-after');

  /** Sets the value of "page-break-after" */
  void set pageBreakAfter(String value) {
    setProperty('page-break-after', value, '');
  }

  /** Gets the value of "page-break-before" */
  String get pageBreakBefore =>
    getPropertyValue('page-break-before');

  /** Sets the value of "page-break-before" */
  void set pageBreakBefore(String value) {
    setProperty('page-break-before', value, '');
  }

  /** Gets the value of "page-break-inside" */
  String get pageBreakInside =>
    getPropertyValue('page-break-inside');

  /** Sets the value of "page-break-inside" */
  void set pageBreakInside(String value) {
    setProperty('page-break-inside', value, '');
  }

  /** Gets the value of "perspective" */
  String get perspective =>
    getPropertyValue('${_browserPrefix}perspective');

  /** Sets the value of "perspective" */
  void set perspective(String value) {
    setProperty('${_browserPrefix}perspective', value, '');
  }

  /** Gets the value of "perspective-origin" */
  String get perspectiveOrigin =>
    getPropertyValue('${_browserPrefix}perspective-origin');

  /** Sets the value of "perspective-origin" */
  void set perspectiveOrigin(String value) {
    setProperty('${_browserPrefix}perspective-origin', value, '');
  }

  /** Gets the value of "perspective-origin-x" */
  String get perspectiveOriginX =>
    getPropertyValue('${_browserPrefix}perspective-origin-x');

  /** Sets the value of "perspective-origin-x" */
  void set perspectiveOriginX(String value) {
    setProperty('${_browserPrefix}perspective-origin-x', value, '');
  }

  /** Gets the value of "perspective-origin-y" */
  String get perspectiveOriginY =>
    getPropertyValue('${_browserPrefix}perspective-origin-y');

  /** Sets the value of "perspective-origin-y" */
  void set perspectiveOriginY(String value) {
    setProperty('${_browserPrefix}perspective-origin-y', value, '');
  }

  /** Gets the value of "pointer-events" */
  String get pointerEvents =>
    getPropertyValue('pointer-events');

  /** Sets the value of "pointer-events" */
  void set pointerEvents(String value) {
    setProperty('pointer-events', value, '');
  }

  /** Gets the value of "position" */
  String get position =>
    getPropertyValue('position');

  /** Sets the value of "position" */
  void set position(String value) {
    setProperty('position', value, '');
  }

  /** Gets the value of "print-color-adjust" */
  String get printColorAdjust =>
    getPropertyValue('${_browserPrefix}print-color-adjust');

  /** Sets the value of "print-color-adjust" */
  void set printColorAdjust(String value) {
    setProperty('${_browserPrefix}print-color-adjust', value, '');
  }

  /** Gets the value of "quotes" */
  String get quotes =>
    getPropertyValue('quotes');

  /** Sets the value of "quotes" */
  void set quotes(String value) {
    setProperty('quotes', value, '');
  }

  /** Gets the value of "region-break-after" */
  String get regionBreakAfter =>
    getPropertyValue('${_browserPrefix}region-break-after');

  /** Sets the value of "region-break-after" */
  void set regionBreakAfter(String value) {
    setProperty('${_browserPrefix}region-break-after', value, '');
  }

  /** Gets the value of "region-break-before" */
  String get regionBreakBefore =>
    getPropertyValue('${_browserPrefix}region-break-before');

  /** Sets the value of "region-break-before" */
  void set regionBreakBefore(String value) {
    setProperty('${_browserPrefix}region-break-before', value, '');
  }

  /** Gets the value of "region-break-inside" */
  String get regionBreakInside =>
    getPropertyValue('${_browserPrefix}region-break-inside');

  /** Sets the value of "region-break-inside" */
  void set regionBreakInside(String value) {
    setProperty('${_browserPrefix}region-break-inside', value, '');
  }

  /** Gets the value of "region-overflow" */
  String get regionOverflow =>
    getPropertyValue('${_browserPrefix}region-overflow');

  /** Sets the value of "region-overflow" */
  void set regionOverflow(String value) {
    setProperty('${_browserPrefix}region-overflow', value, '');
  }

  /** Gets the value of "resize" */
  String get resize =>
    getPropertyValue('resize');

  /** Sets the value of "resize" */
  void set resize(String value) {
    setProperty('resize', value, '');
  }

  /** Gets the value of "right" */
  String get right =>
    getPropertyValue('right');

  /** Sets the value of "right" */
  void set right(String value) {
    setProperty('right', value, '');
  }

  /** Gets the value of "rtl-ordering" */
  String get rtlOrdering =>
    getPropertyValue('${_browserPrefix}rtl-ordering');

  /** Sets the value of "rtl-ordering" */
  void set rtlOrdering(String value) {
    setProperty('${_browserPrefix}rtl-ordering', value, '');
  }

  /** Gets the value of "shape-inside" */
  String get shapeInside =>
    getPropertyValue('${_browserPrefix}shape-inside');

  /** Sets the value of "shape-inside" */
  void set shapeInside(String value) {
    setProperty('${_browserPrefix}shape-inside', value, '');
  }

  /** Gets the value of "shape-margin" */
  String get shapeMargin =>
    getPropertyValue('${_browserPrefix}shape-margin');

  /** Sets the value of "shape-margin" */
  void set shapeMargin(String value) {
    setProperty('${_browserPrefix}shape-margin', value, '');
  }

  /** Gets the value of "shape-outside" */
  String get shapeOutside =>
    getPropertyValue('${_browserPrefix}shape-outside');

  /** Sets the value of "shape-outside" */
  void set shapeOutside(String value) {
    setProperty('${_browserPrefix}shape-outside', value, '');
  }

  /** Gets the value of "shape-padding" */
  String get shapePadding =>
    getPropertyValue('${_browserPrefix}shape-padding');

  /** Sets the value of "shape-padding" */
  void set shapePadding(String value) {
    setProperty('${_browserPrefix}shape-padding', value, '');
  }

  /** Gets the value of "size" */
  String get size =>
    getPropertyValue('size');

  /** Sets the value of "size" */
  void set size(String value) {
    setProperty('size', value, '');
  }

  /** Gets the value of "speak" */
  String get speak =>
    getPropertyValue('speak');

  /** Sets the value of "speak" */
  void set speak(String value) {
    setProperty('speak', value, '');
  }

  /** Gets the value of "src" */
  String get src =>
    getPropertyValue('src');

  /** Sets the value of "src" */
  void set src(String value) {
    setProperty('src', value, '');
  }

  /** Gets the value of "tab-size" */
  String get tabSize =>
    getPropertyValue('tab-size');

  /** Sets the value of "tab-size" */
  void set tabSize(String value) {
    setProperty('tab-size', value, '');
  }

  /** Gets the value of "table-layout" */
  String get tableLayout =>
    getPropertyValue('table-layout');

  /** Sets the value of "table-layout" */
  void set tableLayout(String value) {
    setProperty('table-layout', value, '');
  }

  /** Gets the value of "tap-highlight-color" */
  String get tapHighlightColor =>
    getPropertyValue('${_browserPrefix}tap-highlight-color');

  /** Sets the value of "tap-highlight-color" */
  void set tapHighlightColor(String value) {
    setProperty('${_browserPrefix}tap-highlight-color', value, '');
  }

  /** Gets the value of "text-align" */
  String get textAlign =>
    getPropertyValue('text-align');

  /** Sets the value of "text-align" */
  void set textAlign(String value) {
    setProperty('text-align', value, '');
  }

  /** Gets the value of "text-align-last" */
  String get textAlignLast =>
    getPropertyValue('${_browserPrefix}text-align-last');

  /** Sets the value of "text-align-last" */
  void set textAlignLast(String value) {
    setProperty('${_browserPrefix}text-align-last', value, '');
  }

  /** Gets the value of "text-combine" */
  String get textCombine =>
    getPropertyValue('${_browserPrefix}text-combine');

  /** Sets the value of "text-combine" */
  void set textCombine(String value) {
    setProperty('${_browserPrefix}text-combine', value, '');
  }

  /** Gets the value of "text-decoration" */
  String get textDecoration =>
    getPropertyValue('text-decoration');

  /** Sets the value of "text-decoration" */
  void set textDecoration(String value) {
    setProperty('text-decoration', value, '');
  }

  /** Gets the value of "text-decoration-line" */
  String get textDecorationLine =>
    getPropertyValue('${_browserPrefix}text-decoration-line');

  /** Sets the value of "text-decoration-line" */
  void set textDecorationLine(String value) {
    setProperty('${_browserPrefix}text-decoration-line', value, '');
  }

  /** Gets the value of "text-decoration-style" */
  String get textDecorationStyle =>
    getPropertyValue('${_browserPrefix}text-decoration-style');

  /** Sets the value of "text-decoration-style" */
  void set textDecorationStyle(String value) {
    setProperty('${_browserPrefix}text-decoration-style', value, '');
  }

  /** Gets the value of "text-decorations-in-effect" */
  String get textDecorationsInEffect =>
    getPropertyValue('${_browserPrefix}text-decorations-in-effect');

  /** Sets the value of "text-decorations-in-effect" */
  void set textDecorationsInEffect(String value) {
    setProperty('${_browserPrefix}text-decorations-in-effect', value, '');
  }

  /** Gets the value of "text-emphasis" */
  String get textEmphasis =>
    getPropertyValue('${_browserPrefix}text-emphasis');

  /** Sets the value of "text-emphasis" */
  void set textEmphasis(String value) {
    setProperty('${_browserPrefix}text-emphasis', value, '');
  }

  /** Gets the value of "text-emphasis-color" */
  String get textEmphasisColor =>
    getPropertyValue('${_browserPrefix}text-emphasis-color');

  /** Sets the value of "text-emphasis-color" */
  void set textEmphasisColor(String value) {
    setProperty('${_browserPrefix}text-emphasis-color', value, '');
  }

  /** Gets the value of "text-emphasis-position" */
  String get textEmphasisPosition =>
    getPropertyValue('${_browserPrefix}text-emphasis-position');

  /** Sets the value of "text-emphasis-position" */
  void set textEmphasisPosition(String value) {
    setProperty('${_browserPrefix}text-emphasis-position', value, '');
  }

  /** Gets the value of "text-emphasis-style" */
  String get textEmphasisStyle =>
    getPropertyValue('${_browserPrefix}text-emphasis-style');

  /** Sets the value of "text-emphasis-style" */
  void set textEmphasisStyle(String value) {
    setProperty('${_browserPrefix}text-emphasis-style', value, '');
  }

  /** Gets the value of "text-fill-color" */
  String get textFillColor =>
    getPropertyValue('${_browserPrefix}text-fill-color');

  /** Sets the value of "text-fill-color" */
  void set textFillColor(String value) {
    setProperty('${_browserPrefix}text-fill-color', value, '');
  }

  /** Gets the value of "text-indent" */
  String get textIndent =>
    getPropertyValue('text-indent');

  /** Sets the value of "text-indent" */
  void set textIndent(String value) {
    setProperty('text-indent', value, '');
  }

  /** Gets the value of "text-line-through" */
  String get textLineThrough =>
    getPropertyValue('text-line-through');

  /** Sets the value of "text-line-through" */
  void set textLineThrough(String value) {
    setProperty('text-line-through', value, '');
  }

  /** Gets the value of "text-line-through-color" */
  String get textLineThroughColor =>
    getPropertyValue('text-line-through-color');

  /** Sets the value of "text-line-through-color" */
  void set textLineThroughColor(String value) {
    setProperty('text-line-through-color', value, '');
  }

  /** Gets the value of "text-line-through-mode" */
  String get textLineThroughMode =>
    getPropertyValue('text-line-through-mode');

  /** Sets the value of "text-line-through-mode" */
  void set textLineThroughMode(String value) {
    setProperty('text-line-through-mode', value, '');
  }

  /** Gets the value of "text-line-through-style" */
  String get textLineThroughStyle =>
    getPropertyValue('text-line-through-style');

  /** Sets the value of "text-line-through-style" */
  void set textLineThroughStyle(String value) {
    setProperty('text-line-through-style', value, '');
  }

  /** Gets the value of "text-line-through-width" */
  String get textLineThroughWidth =>
    getPropertyValue('text-line-through-width');

  /** Sets the value of "text-line-through-width" */
  void set textLineThroughWidth(String value) {
    setProperty('text-line-through-width', value, '');
  }

  /** Gets the value of "text-orientation" */
  String get textOrientation =>
    getPropertyValue('${_browserPrefix}text-orientation');

  /** Sets the value of "text-orientation" */
  void set textOrientation(String value) {
    setProperty('${_browserPrefix}text-orientation', value, '');
  }

  /** Gets the value of "text-overflow" */
  String get textOverflow =>
    getPropertyValue('text-overflow');

  /** Sets the value of "text-overflow" */
  void set textOverflow(String value) {
    setProperty('text-overflow', value, '');
  }

  /** Gets the value of "text-overline" */
  String get textOverline =>
    getPropertyValue('text-overline');

  /** Sets the value of "text-overline" */
  void set textOverline(String value) {
    setProperty('text-overline', value, '');
  }

  /** Gets the value of "text-overline-color" */
  String get textOverlineColor =>
    getPropertyValue('text-overline-color');

  /** Sets the value of "text-overline-color" */
  void set textOverlineColor(String value) {
    setProperty('text-overline-color', value, '');
  }

  /** Gets the value of "text-overline-mode" */
  String get textOverlineMode =>
    getPropertyValue('text-overline-mode');

  /** Sets the value of "text-overline-mode" */
  void set textOverlineMode(String value) {
    setProperty('text-overline-mode', value, '');
  }

  /** Gets the value of "text-overline-style" */
  String get textOverlineStyle =>
    getPropertyValue('text-overline-style');

  /** Sets the value of "text-overline-style" */
  void set textOverlineStyle(String value) {
    setProperty('text-overline-style', value, '');
  }

  /** Gets the value of "text-overline-width" */
  String get textOverlineWidth =>
    getPropertyValue('text-overline-width');

  /** Sets the value of "text-overline-width" */
  void set textOverlineWidth(String value) {
    setProperty('text-overline-width', value, '');
  }

  /** Gets the value of "text-rendering" */
  String get textRendering =>
    getPropertyValue('text-rendering');

  /** Sets the value of "text-rendering" */
  void set textRendering(String value) {
    setProperty('text-rendering', value, '');
  }

  /** Gets the value of "text-security" */
  String get textSecurity =>
    getPropertyValue('${_browserPrefix}text-security');

  /** Sets the value of "text-security" */
  void set textSecurity(String value) {
    setProperty('${_browserPrefix}text-security', value, '');
  }

  /** Gets the value of "text-shadow" */
  String get textShadow =>
    getPropertyValue('text-shadow');

  /** Sets the value of "text-shadow" */
  void set textShadow(String value) {
    setProperty('text-shadow', value, '');
  }

  /** Gets the value of "text-size-adjust" */
  String get textSizeAdjust =>
    getPropertyValue('${_browserPrefix}text-size-adjust');

  /** Sets the value of "text-size-adjust" */
  void set textSizeAdjust(String value) {
    setProperty('${_browserPrefix}text-size-adjust', value, '');
  }

  /** Gets the value of "text-stroke" */
  String get textStroke =>
    getPropertyValue('${_browserPrefix}text-stroke');

  /** Sets the value of "text-stroke" */
  void set textStroke(String value) {
    setProperty('${_browserPrefix}text-stroke', value, '');
  }

  /** Gets the value of "text-stroke-color" */
  String get textStrokeColor =>
    getPropertyValue('${_browserPrefix}text-stroke-color');

  /** Sets the value of "text-stroke-color" */
  void set textStrokeColor(String value) {
    setProperty('${_browserPrefix}text-stroke-color', value, '');
  }

  /** Gets the value of "text-stroke-width" */
  String get textStrokeWidth =>
    getPropertyValue('${_browserPrefix}text-stroke-width');

  /** Sets the value of "text-stroke-width" */
  void set textStrokeWidth(String value) {
    setProperty('${_browserPrefix}text-stroke-width', value, '');
  }

  /** Gets the value of "text-transform" */
  String get textTransform =>
    getPropertyValue('text-transform');

  /** Sets the value of "text-transform" */
  void set textTransform(String value) {
    setProperty('text-transform', value, '');
  }

  /** Gets the value of "text-underline" */
  String get textUnderline =>
    getPropertyValue('text-underline');

  /** Sets the value of "text-underline" */
  void set textUnderline(String value) {
    setProperty('text-underline', value, '');
  }

  /** Gets the value of "text-underline-color" */
  String get textUnderlineColor =>
    getPropertyValue('text-underline-color');

  /** Sets the value of "text-underline-color" */
  void set textUnderlineColor(String value) {
    setProperty('text-underline-color', value, '');
  }

  /** Gets the value of "text-underline-mode" */
  String get textUnderlineMode =>
    getPropertyValue('text-underline-mode');

  /** Sets the value of "text-underline-mode" */
  void set textUnderlineMode(String value) {
    setProperty('text-underline-mode', value, '');
  }

  /** Gets the value of "text-underline-style" */
  String get textUnderlineStyle =>
    getPropertyValue('text-underline-style');

  /** Sets the value of "text-underline-style" */
  void set textUnderlineStyle(String value) {
    setProperty('text-underline-style', value, '');
  }

  /** Gets the value of "text-underline-width" */
  String get textUnderlineWidth =>
    getPropertyValue('text-underline-width');

  /** Sets the value of "text-underline-width" */
  void set textUnderlineWidth(String value) {
    setProperty('text-underline-width', value, '');
  }

  /** Gets the value of "top" */
  String get top =>
    getPropertyValue('top');

  /** Sets the value of "top" */
  void set top(String value) {
    setProperty('top', value, '');
  }

  /** Gets the value of "transform" */
  String get transform =>
    getPropertyValue('${_browserPrefix}transform');

  /** Sets the value of "transform" */
  void set transform(String value) {
    setProperty('${_browserPrefix}transform', value, '');
  }

  /** Gets the value of "transform-origin" */
  String get transformOrigin =>
    getPropertyValue('${_browserPrefix}transform-origin');

  /** Sets the value of "transform-origin" */
  void set transformOrigin(String value) {
    setProperty('${_browserPrefix}transform-origin', value, '');
  }

  /** Gets the value of "transform-origin-x" */
  String get transformOriginX =>
    getPropertyValue('${_browserPrefix}transform-origin-x');

  /** Sets the value of "transform-origin-x" */
  void set transformOriginX(String value) {
    setProperty('${_browserPrefix}transform-origin-x', value, '');
  }

  /** Gets the value of "transform-origin-y" */
  String get transformOriginY =>
    getPropertyValue('${_browserPrefix}transform-origin-y');

  /** Sets the value of "transform-origin-y" */
  void set transformOriginY(String value) {
    setProperty('${_browserPrefix}transform-origin-y', value, '');
  }

  /** Gets the value of "transform-origin-z" */
  String get transformOriginZ =>
    getPropertyValue('${_browserPrefix}transform-origin-z');

  /** Sets the value of "transform-origin-z" */
  void set transformOriginZ(String value) {
    setProperty('${_browserPrefix}transform-origin-z', value, '');
  }

  /** Gets the value of "transform-style" */
  String get transformStyle =>
    getPropertyValue('${_browserPrefix}transform-style');

  /** Sets the value of "transform-style" */
  void set transformStyle(String value) {
    setProperty('${_browserPrefix}transform-style', value, '');
  }

  /** Gets the value of "transition" */
  String get transition =>
    getPropertyValue('${_browserPrefix}transition');

  /** Sets the value of "transition" */
  void set transition(String value) {
    setProperty('${_browserPrefix}transition', value, '');
  }

  /** Gets the value of "transition-delay" */
  String get transitionDelay =>
    getPropertyValue('${_browserPrefix}transition-delay');

  /** Sets the value of "transition-delay" */
  void set transitionDelay(String value) {
    setProperty('${_browserPrefix}transition-delay', value, '');
  }

  /** Gets the value of "transition-duration" */
  String get transitionDuration =>
    getPropertyValue('${_browserPrefix}transition-duration');

  /** Sets the value of "transition-duration" */
  void set transitionDuration(String value) {
    setProperty('${_browserPrefix}transition-duration', value, '');
  }

  /** Gets the value of "transition-property" */
  String get transitionProperty =>
    getPropertyValue('${_browserPrefix}transition-property');

  /** Sets the value of "transition-property" */
  void set transitionProperty(String value) {
    setProperty('${_browserPrefix}transition-property', value, '');
  }

  /** Gets the value of "transition-timing-function" */
  String get transitionTimingFunction =>
    getPropertyValue('${_browserPrefix}transition-timing-function');

  /** Sets the value of "transition-timing-function" */
  void set transitionTimingFunction(String value) {
    setProperty('${_browserPrefix}transition-timing-function', value, '');
  }

  /** Gets the value of "unicode-bidi" */
  String get unicodeBidi =>
    getPropertyValue('unicode-bidi');

  /** Sets the value of "unicode-bidi" */
  void set unicodeBidi(String value) {
    setProperty('unicode-bidi', value, '');
  }

  /** Gets the value of "unicode-range" */
  String get unicodeRange =>
    getPropertyValue('unicode-range');

  /** Sets the value of "unicode-range" */
  void set unicodeRange(String value) {
    setProperty('unicode-range', value, '');
  }

  /** Gets the value of "user-drag" */
  String get userDrag =>
    getPropertyValue('${_browserPrefix}user-drag');

  /** Sets the value of "user-drag" */
  void set userDrag(String value) {
    setProperty('${_browserPrefix}user-drag', value, '');
  }

  /** Gets the value of "user-modify" */
  String get userModify =>
    getPropertyValue('${_browserPrefix}user-modify');

  /** Sets the value of "user-modify" */
  void set userModify(String value) {
    setProperty('${_browserPrefix}user-modify', value, '');
  }

  /** Gets the value of "user-select" */
  String get userSelect =>
    getPropertyValue('${_browserPrefix}user-select');

  /** Sets the value of "user-select" */
  void set userSelect(String value) {
    setProperty('${_browserPrefix}user-select', value, '');
  }

  /** Gets the value of "user-zoom" */
  String get userZoom =>
    getPropertyValue('user-zoom');

  /** Sets the value of "user-zoom" */
  void set userZoom(String value) {
    setProperty('user-zoom', value, '');
  }

  /** Gets the value of "vertical-align" */
  String get verticalAlign =>
    getPropertyValue('vertical-align');

  /** Sets the value of "vertical-align" */
  void set verticalAlign(String value) {
    setProperty('vertical-align', value, '');
  }

  /** Gets the value of "visibility" */
  String get visibility =>
    getPropertyValue('visibility');

  /** Sets the value of "visibility" */
  void set visibility(String value) {
    setProperty('visibility', value, '');
  }

  /** Gets the value of "white-space" */
  String get whiteSpace =>
    getPropertyValue('white-space');

  /** Sets the value of "white-space" */
  void set whiteSpace(String value) {
    setProperty('white-space', value, '');
  }

  /** Gets the value of "widows" */
  String get widows =>
    getPropertyValue('widows');

  /** Sets the value of "widows" */
  void set widows(String value) {
    setProperty('widows', value, '');
  }

  /** Gets the value of "width" */
  String get width =>
    getPropertyValue('width');

  /** Sets the value of "width" */
  void set width(String value) {
    setProperty('width', value, '');
  }

  /** Gets the value of "word-break" */
  String get wordBreak =>
    getPropertyValue('word-break');

  /** Sets the value of "word-break" */
  void set wordBreak(String value) {
    setProperty('word-break', value, '');
  }

  /** Gets the value of "word-spacing" */
  String get wordSpacing =>
    getPropertyValue('word-spacing');

  /** Sets the value of "word-spacing" */
  void set wordSpacing(String value) {
    setProperty('word-spacing', value, '');
  }

  /** Gets the value of "word-wrap" */
  String get wordWrap =>
    getPropertyValue('word-wrap');

  /** Sets the value of "word-wrap" */
  void set wordWrap(String value) {
    setProperty('word-wrap', value, '');
  }

  /** Gets the value of "wrap" */
  String get wrap =>
    getPropertyValue('${_browserPrefix}wrap');

  /** Sets the value of "wrap" */
  void set wrap(String value) {
    setProperty('${_browserPrefix}wrap', value, '');
  }

  /** Gets the value of "wrap-flow" */
  String get wrapFlow =>
    getPropertyValue('${_browserPrefix}wrap-flow');

  /** Sets the value of "wrap-flow" */
  void set wrapFlow(String value) {
    setProperty('${_browserPrefix}wrap-flow', value, '');
  }

  /** Gets the value of "wrap-through" */
  String get wrapThrough =>
    getPropertyValue('${_browserPrefix}wrap-through');

  /** Sets the value of "wrap-through" */
  void set wrapThrough(String value) {
    setProperty('${_browserPrefix}wrap-through', value, '');
  }

  /** Gets the value of "writing-mode" */
  String get writingMode =>
    getPropertyValue('${_browserPrefix}writing-mode');

  /** Sets the value of "writing-mode" */
  void set writingMode(String value) {
    setProperty('${_browserPrefix}writing-mode', value, '');
  }

  /** Gets the value of "z-index" */
  String get zIndex =>
    getPropertyValue('z-index');

  /** Sets the value of "z-index" */
  void set zIndex(String value) {
    setProperty('z-index', value, '');
  }

  /** Gets the value of "zoom" */
  String get zoom =>
    getPropertyValue('zoom');

  /** Sets the value of "zoom" */
  void set zoom(String value) {
    setProperty('zoom', value, '');
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('CSSStyleRule')
class CssStyleRule extends CssRule native "*CSSStyleRule" {

  @DomName('CSSStyleRule.selectorText')
  @DocsEditable
  String selectorText;

  @DomName('CSSStyleRule.style')
  @DocsEditable
  final CssStyleDeclaration style;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('CSSStyleSheet')
class CssStyleSheet extends StyleSheet native "*CSSStyleSheet" {

  @DomName('CSSStyleSheet.cssRules')
  @DocsEditable
  @Returns('_CssRuleList')
  @Creates('_CssRuleList')
  final List<CssRule> cssRules;

  @DomName('CSSStyleSheet.ownerRule')
  @DocsEditable
  final CssRule ownerRule;

  @DomName('CSSStyleSheet.rules')
  @DocsEditable
  @Returns('_CssRuleList')
  @Creates('_CssRuleList')
  final List<CssRule> rules;

  @DomName('CSSStyleSheet.addRule')
  @DocsEditable
  int addRule(String selector, String style, [int index]) native;

  @DomName('CSSStyleSheet.deleteRule')
  @DocsEditable
  void deleteRule(int index) native;

  @DomName('CSSStyleSheet.insertRule')
  @DocsEditable
  int insertRule(String rule, int index) native;

  @DomName('CSSStyleSheet.removeRule')
  @DocsEditable
  void removeRule(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebKitCSSTransformValue')
class CssTransformValue extends _CssValueList native "*WebKitCSSTransformValue" {

  static const int CSS_MATRIX = 11;

  static const int CSS_MATRIX3D = 21;

  static const int CSS_PERSPECTIVE = 20;

  static const int CSS_ROTATE = 4;

  static const int CSS_ROTATE3D = 17;

  static const int CSS_ROTATEX = 14;

  static const int CSS_ROTATEY = 15;

  static const int CSS_ROTATEZ = 16;

  static const int CSS_SCALE = 5;

  static const int CSS_SCALE3D = 19;

  static const int CSS_SCALEX = 6;

  static const int CSS_SCALEY = 7;

  static const int CSS_SCALEZ = 18;

  static const int CSS_SKEW = 8;

  static const int CSS_SKEWX = 9;

  static const int CSS_SKEWY = 10;

  static const int CSS_TRANSLATE = 1;

  static const int CSS_TRANSLATE3D = 13;

  static const int CSS_TRANSLATEX = 2;

  static const int CSS_TRANSLATEY = 3;

  static const int CSS_TRANSLATEZ = 12;

  @DomName('WebKitCSSTransformValue.operationType')
  @DocsEditable
  final int operationType;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('CSSUnknownRule')
class CssUnknownRule extends CssRule native "*CSSUnknownRule" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('CSSValue')
class CssValue native "*CSSValue" {

  static const int CSS_CUSTOM = 3;

  static const int CSS_INHERIT = 0;

  static const int CSS_PRIMITIVE_VALUE = 1;

  static const int CSS_VALUE_LIST = 2;

  @DomName('CSSValue.cssText')
  @DocsEditable
  String cssText;

  @DomName('CSSValue.cssValueType')
  @DocsEditable
  final int cssValueType;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('CustomEvent')
class CustomEvent extends Event native "*CustomEvent" {
  factory CustomEvent(String type,
      {bool canBubble: true, bool cancelable: true, Object detail}) {

    final CustomEvent e = document.$dom_createEvent("CustomEvent");
    e.$dom_initCustomEvent(type, canBubble, cancelable, detail);

    return e;
  }

  @DomName('CustomEvent.detail')
  @DocsEditable
  final Object detail;

  @JSName('initCustomEvent')
  @DomName('CustomEvent.initCustomEvent')
  @DocsEditable
  void $dom_initCustomEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object detailArg) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLDListElement')
class DListElement extends Element native "*HTMLDListElement" {

  @DocsEditable
  factory DListElement() => document.$dom_createElement("dl");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLDataListElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class DataListElement extends Element native "*HTMLDataListElement" {

  @DocsEditable
  factory DataListElement() => document.$dom_createElement("datalist");

  /// Checks if this type is supported on the current platform.
  static bool get supported => Element.isTagSupported('datalist');

  @DomName('HTMLDataListElement.options')
  @DocsEditable
  final HtmlCollection options;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DataTransferItem')
class DataTransferItem native "*DataTransferItem" {

  @DomName('DataTransferItem.kind')
  @DocsEditable
  final String kind;

  @DomName('DataTransferItem.type')
  @DocsEditable
  final String type;

  @DomName('DataTransferItem.getAsFile')
  @DocsEditable
  Blob getAsFile() native;

  @DomName('DataTransferItem.getAsString')
  @DocsEditable
  void getAsString([StringCallback callback]) native;

  @DomName('DataTransferItem.webkitGetAsEntry')
  @DocsEditable
  Entry webkitGetAsEntry() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DataTransferItemList')
class DataTransferItemList native "*DataTransferItemList" {

  @DomName('DataTransferItemList.length')
  @DocsEditable
  final int length;

  @DomName('DataTransferItemList.add')
  @DocsEditable
  void add(data_OR_file, [String type]) native;

  @DomName('DataTransferItemList.clear')
  @DocsEditable
  void clear() native;

  @DomName('DataTransferItemList.item')
  @DocsEditable
  DataTransferItem item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DataView')
class DataView extends ArrayBufferView native "*DataView" {

  @DocsEditable
  factory DataView(ArrayBuffer buffer, [int byteOffset, int byteLength]) {
    if (!?byteOffset) {
      return DataView._create(buffer);
    }
    if (!?byteLength) {
      return DataView._create(buffer, byteOffset);
    }
    return DataView._create(buffer, byteOffset, byteLength);
  }
  static DataView _create(ArrayBuffer buffer, [int byteOffset, int byteLength]) {
    if (!?byteOffset) {
      return JS('DataView', 'new DataView(#)', buffer);
    }
    if (!?byteLength) {
      return JS('DataView', 'new DataView(#,#)', buffer, byteOffset);
    }
    return JS('DataView', 'new DataView(#,#,#)', buffer, byteOffset, byteLength);
  }

  @DomName('DataView.getFloat32')
  @DocsEditable
  num getFloat32(int byteOffset, {bool littleEndian}) native;

  @DomName('DataView.getFloat64')
  @DocsEditable
  num getFloat64(int byteOffset, {bool littleEndian}) native;

  @DomName('DataView.getInt16')
  @DocsEditable
  int getInt16(int byteOffset, {bool littleEndian}) native;

  @DomName('DataView.getInt32')
  @DocsEditable
  int getInt32(int byteOffset, {bool littleEndian}) native;

  @DomName('DataView.getInt8')
  @DocsEditable
  int getInt8(int byteOffset) native;

  @DomName('DataView.getUint16')
  @DocsEditable
  int getUint16(int byteOffset, {bool littleEndian}) native;

  @DomName('DataView.getUint32')
  @DocsEditable
  int getUint32(int byteOffset, {bool littleEndian}) native;

  @DomName('DataView.getUint8')
  @DocsEditable
  int getUint8(int byteOffset) native;

  @DomName('DataView.setFloat32')
  @DocsEditable
  void setFloat32(int byteOffset, num value, {bool littleEndian}) native;

  @DomName('DataView.setFloat64')
  @DocsEditable
  void setFloat64(int byteOffset, num value, {bool littleEndian}) native;

  @DomName('DataView.setInt16')
  @DocsEditable
  void setInt16(int byteOffset, int value, {bool littleEndian}) native;

  @DomName('DataView.setInt32')
  @DocsEditable
  void setInt32(int byteOffset, int value, {bool littleEndian}) native;

  @DomName('DataView.setInt8')
  @DocsEditable
  void setInt8(int byteOffset, int value) native;

  @DomName('DataView.setUint16')
  @DocsEditable
  void setUint16(int byteOffset, int value, {bool littleEndian}) native;

  @DomName('DataView.setUint32')
  @DocsEditable
  void setUint32(int byteOffset, int value, {bool littleEndian}) native;

  @DomName('DataView.setUint8')
  @DocsEditable
  void setUint8(int byteOffset, int value) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Database')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class Database native "*Database" {

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.openDatabase)');

  @DomName('Database.version')
  @DocsEditable
  final String version;

  @DomName('Database.changeVersion')
  @DocsEditable
  void changeVersion(String oldVersion, String newVersion, [SqlTransactionCallback callback, SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) native;

  @DomName('Database.readTransaction')
  @DocsEditable
  void readTransaction(SqlTransactionCallback callback, [SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) native;

  @DomName('Database.transaction')
  @DocsEditable
  void transaction(SqlTransactionCallback callback, [SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void DatabaseCallback(database);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DatabaseSync')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class DatabaseSync native "*DatabaseSync" {

  @DomName('DatabaseSync.lastErrorMessage')
  @DocsEditable
  final String lastErrorMessage;

  @DomName('DatabaseSync.version')
  @DocsEditable
  final String version;

  @DomName('DatabaseSync.changeVersion')
  @DocsEditable
  void changeVersion(String oldVersion, String newVersion, [SqlTransactionSyncCallback callback]) native;

  @DomName('DatabaseSync.readTransaction')
  @DocsEditable
  void readTransaction(SqlTransactionSyncCallback callback) native;

  @DomName('DatabaseSync.transaction')
  @DocsEditable
  void transaction(SqlTransactionSyncCallback callback) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DedicatedWorkerContext')
class DedicatedWorkerContext extends WorkerContext native "*DedicatedWorkerContext" {

  @DomName('DedicatedWorkerContext.message')
  @DocsEditable
  static const EventStreamProvider<MessageEvent> messageEvent = const EventStreamProvider<MessageEvent>('message');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  DedicatedWorkerContextEvents get on =>
    new DedicatedWorkerContextEvents(this);

  void postMessage(/*any*/ message, [List messagePorts]) {
    if (?messagePorts) {
      var message_1 = convertDartToNative_SerializedScriptValue(message);
      _postMessage_1(message_1, messagePorts);
      return;
    }
    var message_2 = convertDartToNative_SerializedScriptValue(message);
    _postMessage_2(message_2);
    return;
  }
  @JSName('postMessage')
  @DomName('DedicatedWorkerContext.postMessage')
  @DocsEditable
  void _postMessage_1(message, List messagePorts) native;
  @JSName('postMessage')
  @DomName('DedicatedWorkerContext.postMessage')
  @DocsEditable
  void _postMessage_2(message) native;

  @DomName('DedicatedWorkerContext.message')
  @DocsEditable
  Stream<MessageEvent> get onMessage => messageEvent.forTarget(this);
}

@DocsEditable
@deprecated
class DedicatedWorkerContextEvents extends WorkerContextEvents {
  @DocsEditable
  DedicatedWorkerContextEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get message => this['message'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLDetailsElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class DetailsElement extends Element native "*HTMLDetailsElement" {

  @DocsEditable
  factory DetailsElement() => document.$dom_createElement("details");

  /// Checks if this type is supported on the current platform.
  static bool get supported => Element.isTagSupported('details');

  @DomName('HTMLDetailsElement.open')
  @DocsEditable
  bool open;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DeviceMotionEvent')
class DeviceMotionEvent extends Event native "*DeviceMotionEvent" {

  @DomName('DeviceMotionEvent.interval')
  @DocsEditable
  final num interval;
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DomName('DeviceOrientationEvent')

class DeviceOrientationEvent extends Event native "*DeviceOrientationEvent" {
  factory DeviceOrientationEvent(String type,
      {bool canBubble: true, bool cancelable: true, num alpha: 0, num beta: 0,
      num gamma: 0, bool absolute: false}) {
    var e = document.$dom_createEvent("DeviceOrientationEvent");
    e.$dom_initDeviceOrientationEvent(type, canBubble, cancelable, alpha, beta,
        gamma, absolute);
    return e;
  }

  @DomName('DeviceOrientationEvent.absolute')
  @DocsEditable
  final bool absolute;

  @DomName('DeviceOrientationEvent.alpha')
  @DocsEditable
  final num alpha;

  @DomName('DeviceOrientationEvent.beta')
  @DocsEditable
  final num beta;

  @DomName('DeviceOrientationEvent.gamma')
  @DocsEditable
  final num gamma;

  @JSName('initDeviceOrientationEvent')
  @DomName('DeviceOrientationEvent.initDeviceOrientationEvent')
  @DocsEditable
  void $dom_initDeviceOrientationEvent(String type, bool bubbles, bool cancelable, num alpha, num beta, num gamma, bool absolute) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DirectoryEntry')
class DirectoryEntry extends Entry native "*DirectoryEntry" {

  @DomName('DirectoryEntry.createReader')
  @DocsEditable
  DirectoryReader createReader() native;

  void getDirectory(String path, {Map options, EntryCallback successCallback, ErrorCallback errorCallback}) {
    if (?errorCallback) {
      var options_1 = convertDartToNative_Dictionary(options);
      _getDirectory_1(path, options_1, successCallback, errorCallback);
      return;
    }
    if (?successCallback) {
      var options_2 = convertDartToNative_Dictionary(options);
      _getDirectory_2(path, options_2, successCallback);
      return;
    }
    if (?options) {
      var options_3 = convertDartToNative_Dictionary(options);
      _getDirectory_3(path, options_3);
      return;
    }
    _getDirectory_4(path);
    return;
  }
  @JSName('getDirectory')
  @DomName('DirectoryEntry.getDirectory')
  @DocsEditable
  void _getDirectory_1(path, options, EntryCallback successCallback, ErrorCallback errorCallback) native;
  @JSName('getDirectory')
  @DomName('DirectoryEntry.getDirectory')
  @DocsEditable
  void _getDirectory_2(path, options, EntryCallback successCallback) native;
  @JSName('getDirectory')
  @DomName('DirectoryEntry.getDirectory')
  @DocsEditable
  void _getDirectory_3(path, options) native;
  @JSName('getDirectory')
  @DomName('DirectoryEntry.getDirectory')
  @DocsEditable
  void _getDirectory_4(path) native;

  void getFile(String path, {Map options, EntryCallback successCallback, ErrorCallback errorCallback}) {
    if (?errorCallback) {
      var options_1 = convertDartToNative_Dictionary(options);
      _getFile_1(path, options_1, successCallback, errorCallback);
      return;
    }
    if (?successCallback) {
      var options_2 = convertDartToNative_Dictionary(options);
      _getFile_2(path, options_2, successCallback);
      return;
    }
    if (?options) {
      var options_3 = convertDartToNative_Dictionary(options);
      _getFile_3(path, options_3);
      return;
    }
    _getFile_4(path);
    return;
  }
  @JSName('getFile')
  @DomName('DirectoryEntry.getFile')
  @DocsEditable
  void _getFile_1(path, options, EntryCallback successCallback, ErrorCallback errorCallback) native;
  @JSName('getFile')
  @DomName('DirectoryEntry.getFile')
  @DocsEditable
  void _getFile_2(path, options, EntryCallback successCallback) native;
  @JSName('getFile')
  @DomName('DirectoryEntry.getFile')
  @DocsEditable
  void _getFile_3(path, options) native;
  @JSName('getFile')
  @DomName('DirectoryEntry.getFile')
  @DocsEditable
  void _getFile_4(path) native;

  @DomName('DirectoryEntry.removeRecursively')
  @DocsEditable
  void removeRecursively(VoidCallback successCallback, [ErrorCallback errorCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DirectoryEntrySync')
class DirectoryEntrySync extends EntrySync native "*DirectoryEntrySync" {

  @DomName('DirectoryEntrySync.createReader')
  @DocsEditable
  DirectoryReaderSync createReader() native;

  DirectoryEntrySync getDirectory(String path, Map flags) {
    var flags_1 = convertDartToNative_Dictionary(flags);
    return _getDirectory_1(path, flags_1);
  }
  @JSName('getDirectory')
  @DomName('DirectoryEntrySync.getDirectory')
  @DocsEditable
  DirectoryEntrySync _getDirectory_1(path, flags) native;

  FileEntrySync getFile(String path, Map flags) {
    var flags_1 = convertDartToNative_Dictionary(flags);
    return _getFile_1(path, flags_1);
  }
  @JSName('getFile')
  @DomName('DirectoryEntrySync.getFile')
  @DocsEditable
  FileEntrySync _getFile_1(path, flags) native;

  @DomName('DirectoryEntrySync.removeRecursively')
  @DocsEditable
  void removeRecursively() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DirectoryReader')
class DirectoryReader native "*DirectoryReader" {

  @DomName('DirectoryReader.readEntries')
  @DocsEditable
  void readEntries(EntriesCallback successCallback, [ErrorCallback errorCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DirectoryReaderSync')
class DirectoryReaderSync native "*DirectoryReaderSync" {

  @DomName('DirectoryReaderSync.readEntries')
  @DocsEditable
  @Returns('_EntryArraySync')
  @Creates('_EntryArraySync')
  List<EntrySync> readEntries() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLDivElement')
class DivElement extends Element native "*HTMLDivElement" {

  @DocsEditable
  factory DivElement() => document.$dom_createElement("div");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * The base class for all documents.
 *
 * Each web page loaded in the browser has its own [Document] object, which is
 * typically an [HtmlDocument].
 *
 * If you aren't comfortable with DOM concepts, see the Dart tutorial
 * [Target 2: Connect Dart & HTML](http://www.dartlang.org/docs/tutorials/connect-dart-html/).
 */
@DomName('Document')
class Document extends Node  native "*Document"
{


  @DomName('Document.readystatechange')
  @DocsEditable
  static const EventStreamProvider<Event> readyStateChangeEvent = const EventStreamProvider<Event>('readystatechange');

  @DomName('Document.selectionchange')
  @DocsEditable
  static const EventStreamProvider<Event> selectionChangeEvent = const EventStreamProvider<Event>('selectionchange');

  @DomName('Document.webkitpointerlockchange')
  @DocsEditable
  static const EventStreamProvider<Event> pointerLockChangeEvent = const EventStreamProvider<Event>('webkitpointerlockchange');

  @DomName('Document.webkitpointerlockerror')
  @DocsEditable
  static const EventStreamProvider<Event> pointerLockErrorEvent = const EventStreamProvider<Event>('webkitpointerlockerror');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  DocumentEvents get on =>
    new DocumentEvents(this);

  @JSName('body')
  @DomName('Document.body')
  @DocsEditable
  Element $dom_body;

  @DomName('Document.charset')
  @DocsEditable
  String charset;

  @DomName('Document.cookie')
  @DocsEditable
  String cookie;

  WindowBase get window => _convertNativeToDart_Window(this._window);
  @JSName('defaultView')
  @DomName('Document.window')
  @DocsEditable
  @Creates('Window|=Object')
  @Returns('Window|=Object')
  final dynamic _window;

  @DomName('Document.documentElement')
  @DocsEditable
  final Element documentElement;

  @DomName('Document.domain')
  @DocsEditable
  final String domain;

  @JSName('head')
  @DomName('Document.head')
  @DocsEditable
  final HeadElement $dom_head;

  @DomName('Document.implementation')
  @DocsEditable
  final DomImplementation implementation;

  @JSName('lastModified')
  @DomName('Document.lastModified')
  @DocsEditable
  final String $dom_lastModified;

  @JSName('preferredStylesheetSet')
  @DomName('Document.preferredStylesheetSet')
  @DocsEditable
  final String $dom_preferredStylesheetSet;

  @DomName('Document.readyState')
  @DocsEditable
  final String readyState;

  @JSName('referrer')
  @DomName('Document.referrer')
  @DocsEditable
  final String $dom_referrer;

  @JSName('selectedStylesheetSet')
  @DomName('Document.selectedStylesheetSet')
  @DocsEditable
  String $dom_selectedStylesheetSet;

  @JSName('styleSheets')
  @DomName('Document.styleSheets')
  @DocsEditable
  @Returns('_StyleSheetList')
  @Creates('_StyleSheetList')
  final List<StyleSheet> $dom_styleSheets;

  @JSName('title')
  @DomName('Document.title')
  @DocsEditable
  String $dom_title;

  @JSName('webkitFullscreenElement')
  @DomName('Document.webkitFullscreenElement')
  @DocsEditable
  final Element $dom_webkitFullscreenElement;

  @JSName('webkitFullscreenEnabled')
  @DomName('Document.webkitFullscreenEnabled')
  @DocsEditable
  final bool $dom_webkitFullscreenEnabled;

  @JSName('webkitHidden')
  @DomName('Document.webkitHidden')
  @DocsEditable
  final bool $dom_webkitHidden;

  @JSName('webkitIsFullScreen')
  @DomName('Document.webkitIsFullScreen')
  @DocsEditable
  final bool $dom_webkitIsFullScreen;

  @JSName('webkitPointerLockElement')
  @DomName('Document.webkitPointerLockElement')
  @DocsEditable
  final Element $dom_webkitPointerLockElement;

  @JSName('webkitVisibilityState')
  @DomName('Document.webkitVisibilityState')
  @DocsEditable
  final String $dom_webkitVisibilityState;

  @JSName('caretRangeFromPoint')
  @DomName('Document.caretRangeFromPoint')
  @DocsEditable
  Range $dom_caretRangeFromPoint(int x, int y) native;

  @JSName('createCDATASection')
  @DomName('Document.createCDATASection')
  @DocsEditable
  CDataSection createCDataSection(String data) native;

  @DomName('Document.createDocumentFragment')
  @DocsEditable
  DocumentFragment createDocumentFragment() native;

  @JSName('createElement')
  @DomName('Document.createElement')
  @DocsEditable
  Element $dom_createElement(String tagName) native;

  @JSName('createElementNS')
  @DomName('Document.createElementNS')
  @DocsEditable
  Element $dom_createElementNS(String namespaceURI, String qualifiedName) native;

  @JSName('createEvent')
  @DomName('Document.createEvent')
  @DocsEditable
  Event $dom_createEvent(String eventType) native;

  @JSName('createRange')
  @DomName('Document.createRange')
  @DocsEditable
  Range $dom_createRange() native;

  @JSName('createTextNode')
  @DomName('Document.createTextNode')
  @DocsEditable
  Text $dom_createTextNode(String data) native;

  Touch $dom_createTouch(Window window, EventTarget target, int identifier, int pageX, int pageY, int screenX, int screenY, int webkitRadiusX, int webkitRadiusY, num webkitRotationAngle, num webkitForce) {
    var target_1 = _convertDartToNative_EventTarget(target);
    return _$dom_createTouch_1(window, target_1, identifier, pageX, pageY, screenX, screenY, webkitRadiusX, webkitRadiusY, webkitRotationAngle, webkitForce);
  }
  @JSName('createTouch')
  @DomName('Document.createTouch')
  @DocsEditable
  Touch _$dom_createTouch_1(Window window, target, identifier, pageX, pageY, screenX, screenY, webkitRadiusX, webkitRadiusY, webkitRotationAngle, webkitForce) native;

  @JSName('createTouchList')
  @DomName('Document.createTouchList')
  @DocsEditable
  TouchList $dom_createTouchList() native;

  @JSName('elementFromPoint')
  @DomName('Document.elementFromPoint')
  @DocsEditable
  Element $dom_elementFromPoint(int x, int y) native;

  @DomName('Document.execCommand')
  @DocsEditable
  bool execCommand(String command, bool userInterface, String value) native;

  @JSName('getCSSCanvasContext')
  @DomName('Document.getCSSCanvasContext')
  @DocsEditable
  CanvasRenderingContext $dom_getCssCanvasContext(String contextId, String name, int width, int height) native;

  @JSName('getElementById')
  @DomName('Document.getElementById')
  @DocsEditable
  Element $dom_getElementById(String elementId) native;

  @JSName('getElementsByClassName')
  @DomName('Document.getElementsByClassName')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> $dom_getElementsByClassName(String tagname) native;

  @JSName('getElementsByName')
  @DomName('Document.getElementsByName')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> $dom_getElementsByName(String elementName) native;

  @JSName('getElementsByTagName')
  @DomName('Document.getElementsByTagName')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> $dom_getElementsByTagName(String tagname) native;

  @DomName('Document.queryCommandEnabled')
  @DocsEditable
  bool queryCommandEnabled(String command) native;

  @DomName('Document.queryCommandIndeterm')
  @DocsEditable
  bool queryCommandIndeterm(String command) native;

  @DomName('Document.queryCommandState')
  @DocsEditable
  bool queryCommandState(String command) native;

  @DomName('Document.queryCommandSupported')
  @DocsEditable
  bool queryCommandSupported(String command) native;

  @DomName('Document.queryCommandValue')
  @DocsEditable
  String queryCommandValue(String command) native;

  @JSName('querySelector')
  @DomName('Document.querySelector')
  @DocsEditable
  Element $dom_querySelector(String selectors) native;

  @JSName('querySelectorAll')
  @DomName('Document.querySelectorAll')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> $dom_querySelectorAll(String selectors) native;

  @JSName('webkitCancelFullScreen')
  @DomName('Document.webkitCancelFullScreen')
  @DocsEditable
  void $dom_webkitCancelFullScreen() native;

  @JSName('webkitExitFullscreen')
  @DomName('Document.webkitExitFullscreen')
  @DocsEditable
  void $dom_webkitExitFullscreen() native;

  @JSName('webkitExitPointerLock')
  @DomName('Document.webkitExitPointerLock')
  @DocsEditable
  void $dom_webkitExitPointerLock() native;

  @DomName('Document.abort')
  @DocsEditable
  Stream<Event> get onAbort => Element.abortEvent.forTarget(this);

  @DomName('Document.beforecopy')
  @DocsEditable
  Stream<Event> get onBeforeCopy => Element.beforeCopyEvent.forTarget(this);

  @DomName('Document.beforecut')
  @DocsEditable
  Stream<Event> get onBeforeCut => Element.beforeCutEvent.forTarget(this);

  @DomName('Document.beforepaste')
  @DocsEditable
  Stream<Event> get onBeforePaste => Element.beforePasteEvent.forTarget(this);

  @DomName('Document.blur')
  @DocsEditable
  Stream<Event> get onBlur => Element.blurEvent.forTarget(this);

  @DomName('Document.change')
  @DocsEditable
  Stream<Event> get onChange => Element.changeEvent.forTarget(this);

  @DomName('Document.click')
  @DocsEditable
  Stream<MouseEvent> get onClick => Element.clickEvent.forTarget(this);

  @DomName('Document.contextmenu')
  @DocsEditable
  Stream<MouseEvent> get onContextMenu => Element.contextMenuEvent.forTarget(this);

  @DomName('Document.copy')
  @DocsEditable
  Stream<Event> get onCopy => Element.copyEvent.forTarget(this);

  @DomName('Document.cut')
  @DocsEditable
  Stream<Event> get onCut => Element.cutEvent.forTarget(this);

  @DomName('Document.dblclick')
  @DocsEditable
  Stream<Event> get onDoubleClick => Element.doubleClickEvent.forTarget(this);

  @DomName('Document.drag')
  @DocsEditable
  Stream<MouseEvent> get onDrag => Element.dragEvent.forTarget(this);

  @DomName('Document.dragend')
  @DocsEditable
  Stream<MouseEvent> get onDragEnd => Element.dragEndEvent.forTarget(this);

  @DomName('Document.dragenter')
  @DocsEditable
  Stream<MouseEvent> get onDragEnter => Element.dragEnterEvent.forTarget(this);

  @DomName('Document.dragleave')
  @DocsEditable
  Stream<MouseEvent> get onDragLeave => Element.dragLeaveEvent.forTarget(this);

  @DomName('Document.dragover')
  @DocsEditable
  Stream<MouseEvent> get onDragOver => Element.dragOverEvent.forTarget(this);

  @DomName('Document.dragstart')
  @DocsEditable
  Stream<MouseEvent> get onDragStart => Element.dragStartEvent.forTarget(this);

  @DomName('Document.drop')
  @DocsEditable
  Stream<MouseEvent> get onDrop => Element.dropEvent.forTarget(this);

  @DomName('Document.error')
  @DocsEditable
  Stream<Event> get onError => Element.errorEvent.forTarget(this);

  @DomName('Document.focus')
  @DocsEditable
  Stream<Event> get onFocus => Element.focusEvent.forTarget(this);

  @DomName('Document.input')
  @DocsEditable
  Stream<Event> get onInput => Element.inputEvent.forTarget(this);

  @DomName('Document.invalid')
  @DocsEditable
  Stream<Event> get onInvalid => Element.invalidEvent.forTarget(this);

  @DomName('Document.keydown')
  @DocsEditable
  Stream<KeyboardEvent> get onKeyDown => Element.keyDownEvent.forTarget(this);

  @DomName('Document.keypress')
  @DocsEditable
  Stream<KeyboardEvent> get onKeyPress => Element.keyPressEvent.forTarget(this);

  @DomName('Document.keyup')
  @DocsEditable
  Stream<KeyboardEvent> get onKeyUp => Element.keyUpEvent.forTarget(this);

  @DomName('Document.load')
  @DocsEditable
  Stream<Event> get onLoad => Element.loadEvent.forTarget(this);

  @DomName('Document.mousedown')
  @DocsEditable
  Stream<MouseEvent> get onMouseDown => Element.mouseDownEvent.forTarget(this);

  @DomName('Document.mousemove')
  @DocsEditable
  Stream<MouseEvent> get onMouseMove => Element.mouseMoveEvent.forTarget(this);

  @DomName('Document.mouseout')
  @DocsEditable
  Stream<MouseEvent> get onMouseOut => Element.mouseOutEvent.forTarget(this);

  @DomName('Document.mouseover')
  @DocsEditable
  Stream<MouseEvent> get onMouseOver => Element.mouseOverEvent.forTarget(this);

  @DomName('Document.mouseup')
  @DocsEditable
  Stream<MouseEvent> get onMouseUp => Element.mouseUpEvent.forTarget(this);

  @DomName('Document.mousewheel')
  @DocsEditable
  Stream<WheelEvent> get onMouseWheel => Element.mouseWheelEvent.forTarget(this);

  @DomName('Document.paste')
  @DocsEditable
  Stream<Event> get onPaste => Element.pasteEvent.forTarget(this);

  @DomName('Document.readystatechange')
  @DocsEditable
  Stream<Event> get onReadyStateChange => readyStateChangeEvent.forTarget(this);

  @DomName('Document.reset')
  @DocsEditable
  Stream<Event> get onReset => Element.resetEvent.forTarget(this);

  @DomName('Document.scroll')
  @DocsEditable
  Stream<Event> get onScroll => Element.scrollEvent.forTarget(this);

  @DomName('Document.search')
  @DocsEditable
  Stream<Event> get onSearch => Element.searchEvent.forTarget(this);

  @DomName('Document.select')
  @DocsEditable
  Stream<Event> get onSelect => Element.selectEvent.forTarget(this);

  @DomName('Document.selectionchange')
  @DocsEditable
  Stream<Event> get onSelectionChange => selectionChangeEvent.forTarget(this);

  @DomName('Document.selectstart')
  @DocsEditable
  Stream<Event> get onSelectStart => Element.selectStartEvent.forTarget(this);

  @DomName('Document.submit')
  @DocsEditable
  Stream<Event> get onSubmit => Element.submitEvent.forTarget(this);

  @DomName('Document.touchcancel')
  @DocsEditable
  Stream<TouchEvent> get onTouchCancel => Element.touchCancelEvent.forTarget(this);

  @DomName('Document.touchend')
  @DocsEditable
  Stream<TouchEvent> get onTouchEnd => Element.touchEndEvent.forTarget(this);

  @DomName('Document.touchmove')
  @DocsEditable
  Stream<TouchEvent> get onTouchMove => Element.touchMoveEvent.forTarget(this);

  @DomName('Document.touchstart')
  @DocsEditable
  Stream<TouchEvent> get onTouchStart => Element.touchStartEvent.forTarget(this);

  @DomName('Document.webkitfullscreenchange')
  @DocsEditable
  Stream<Event> get onFullscreenChange => Element.fullscreenChangeEvent.forTarget(this);

  @DomName('Document.webkitfullscreenerror')
  @DocsEditable
  Stream<Event> get onFullscreenError => Element.fullscreenErrorEvent.forTarget(this);

  @DomName('Document.webkitpointerlockchange')
  @DocsEditable
  Stream<Event> get onPointerLockChange => pointerLockChangeEvent.forTarget(this);

  @DomName('Document.webkitpointerlockerror')
  @DocsEditable
  Stream<Event> get onPointerLockError => pointerLockErrorEvent.forTarget(this);


  /**
   * Finds the first descendant element of this document that matches the
   * specified group of selectors.
   *
   * Unless your webpage contains multiple documents, the top-level query
   * method behaves the same as this method, so you should use it instead to
   * save typing a few characters.
   *
   * [selectors] should be a string using CSS selector syntax.
   *     var element1 = document.query('.className');
   *     var element2 = document.query('#id');
   *
   * For details about CSS selector syntax, see the
   * [CSS selector specification](http://www.w3.org/TR/css3-selectors/).
   */
  Element query(String selectors) {
    // It is fine for our RegExp to detect element id query selectors to have
    // false negatives but not false positives.
    if (new RegExp("^#[_a-zA-Z]\\w*\$").hasMatch(selectors)) {
      return $dom_getElementById(selectors.substring(1));
    }
    return $dom_querySelector(selectors);
  }

  /**
   * Finds all descendant elements of this document that match the specified
   * group of selectors.
   *
   * Unless your webpage contains multiple documents, the top-level queryAll
   * method behaves the same as this method, so you should use it instead to
   * save typing a few characters.
   *
   * [selectors] should be a string using CSS selector syntax.
   *     var items = document.queryAll('.itemClassName');
   *
   * For details about CSS selector syntax, see the
   * [CSS selector specification](http://www.w3.org/TR/css3-selectors/).
   */
  List<Element> queryAll(String selectors) {
    if (new RegExp("""^\\[name=["'][^'"]+['"]\\]\$""").hasMatch(selectors)) {
      final mutableMatches = $dom_getElementsByName(
          selectors.substring(7,selectors.length - 2));
      int len = mutableMatches.length;
      final copyOfMatches = new List<Element>.fixedLength(len);
      for (int i = 0; i < len; ++i) {
        copyOfMatches[i] = mutableMatches[i];
      }
      return new _FrozenElementList._wrap(copyOfMatches);
    } else if (new RegExp("^[*a-zA-Z0-9]+\$").hasMatch(selectors)) {
      final mutableMatches = $dom_getElementsByTagName(selectors);
      int len = mutableMatches.length;
      final copyOfMatches = new List<Element>.fixedLength(len);
      for (int i = 0; i < len; ++i) {
        copyOfMatches[i] = mutableMatches[i];
      }
      return new _FrozenElementList._wrap(copyOfMatches);
    } else {
      return new _FrozenElementList._wrap($dom_querySelectorAll(selectors));
    }
  }
}

@DocsEditable
@deprecated
class DocumentEvents extends ElementEvents {
  @DocsEditable
  DocumentEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get readyStateChange => this['readystatechange'];

  @DocsEditable
  EventListenerList get selectionChange => this['selectionchange'];

  @DocsEditable
  EventListenerList get pointerLockChange => this['webkitpointerlockchange'];

  @DocsEditable
  EventListenerList get pointerLockError => this['webkitpointerlockerror'];
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('DocumentFragment')
class DocumentFragment extends Node native "*DocumentFragment" {
  factory DocumentFragment() => _DocumentFragmentFactoryProvider.createDocumentFragment();

  factory DocumentFragment.html(String html) =>
      _DocumentFragmentFactoryProvider.createDocumentFragment_html(html);

  factory DocumentFragment.svg(String svgContent) =>
      _DocumentFragmentFactoryProvider.createDocumentFragment_svg(svgContent);

  @deprecated
  List<Element> get elements => this.children;

  // TODO: The type of value should be Collection<Element>. See http://b/5392897
  @deprecated
  void set elements(value) {
    this.children = value;
  }

  // Native field is used only by Dart code so does not lead to instantiation
  // of native classes
  @Creates('Null')
  List<Element> _children;

  List<Element> get children {
    if (_children == null) {
      _children = new FilteredElementList(this);
    }
    return _children;
  }

  void set children(List<Element> value) {
    // Copy list first since we don't want liveness during iteration.
    List copy = new List.from(value);
    var children = this.children;
    children.clear();
    children.addAll(copy);
  }

  Element query(String selectors) => $dom_querySelector(selectors);

  List<Element> queryAll(String selectors) =>
    new _FrozenElementList._wrap($dom_querySelectorAll(selectors));

  String get innerHtml {
    final e = new Element.tag("div");
    e.nodes.add(this.clone(true));
    return e.innerHtml;
  }

  // TODO(nweiz): Do we want to support some variant of innerHtml for XML and/or
  // SVG strings?
  void set innerHtml(String value) {
    this.nodes.clear();

    final e = new Element.tag("div");
    e.innerHtml = value;

    // Copy list first since we don't want liveness during iteration.
    List nodes = new List.from(e.nodes);
    this.nodes.addAll(nodes);
  }

  void append(Element element) {
    this.children.add(element);
  }

  void appendText(String text) {
    this.nodes.add(new Text(text));
  }

  void appendHtml(String text) {
    this.nodes.add(new DocumentFragment.html(text));
  }


  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  ElementEvents get on =>
    new ElementEvents(this);

  @JSName('querySelector')
  @DomName('DocumentFragment.querySelector')
  @DocsEditable
  Element $dom_querySelector(String selectors) native;

  @JSName('querySelectorAll')
  @DomName('DocumentFragment.querySelectorAll')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> $dom_querySelectorAll(String selectors) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DocumentType')
class DocumentType extends Node native "*DocumentType" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DOMError')
class DomError native "*DOMError" {

  @DomName('DOMError.name')
  @DocsEditable
  final String name;
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DOMException
class DomException native "*DOMException" {

  static const String INDEX_SIZE = 'IndexSizeError';
  static const String HIERARCHY_REQUEST = 'HierarchyRequestError';
  static const String WRONG_DOCUMENT = 'WrongDocumentError';
  static const String INVALID_CHARACTER = 'InvalidCharacterError';
  static const String NO_MODIFICATION_ALLOWED = 'NoModificationAllowedError';
  static const String NOT_FOUND = 'NotFoundError';
  static const String NOT_SUPPORTED = 'NotSupportedError';
  static const String INVALID_STATE = 'InvalidStateError';
  static const String SYNTAX = 'SyntaxError';
  static const String INVALID_MODIFICATION = 'InvalidModificationError';
  static const String NAMESPACE = 'NamespaceError';
  static const String INVALID_ACCESS = 'InvalidAccessError';
  static const String TYPE_MISMATCH = 'TypeMismatchError';
  static const String SECURITY = 'SecurityError';
  static const String NETWORK = 'NetworkError';
  static const String ABORT = 'AbortError';
  static const String URL_MISMATCH = 'URLMismatchError';
  static const String QUOTA_EXCEEDED = 'QuotaExceededError';
  static const String TIMEOUT = 'TimeoutError';
  static const String INVALID_NODE_TYPE = 'InvalidNodeTypeError';
  static const String DATA_CLONE = 'DataCloneError';

  String get name {
    var errorName = JS('String', '#.name', this);
    // Although Safari nightly has updated the name to SecurityError, Safari 5
    // and 6 still return SECURITY_ERR.
    if (_Device.isWebKit && errorName == 'SECURITY_ERR') return 'SecurityError';
    // Chrome release still uses old string, remove this line when Chrome stable
    // also prints out SyntaxError.
    if (_Device.isWebKit && errorName == 'SYNTAX_ERR') return 'SyntaxError';
    return errorName;
  }

  @DomName('DOMCoreException.message')
  @DocsEditable
  final String message;

  @DomName('DOMCoreException.toString')
  @DocsEditable
  String toString() native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DOMImplementation')
class DomImplementation native "*DOMImplementation" {

  @JSName('createCSSStyleSheet')
  @DomName('DOMImplementation.createCSSStyleSheet')
  @DocsEditable
  CssStyleSheet createCssStyleSheet(String title, String media) native;

  @DomName('DOMImplementation.createDocument')
  @DocsEditable
  Document createDocument(String namespaceURI, String qualifiedName, DocumentType doctype) native;

  @DomName('DOMImplementation.createDocumentType')
  @DocsEditable
  DocumentType createDocumentType(String qualifiedName, String publicId, String systemId) native;

  @JSName('createHTMLDocument')
  @DomName('DOMImplementation.createHTMLDocument')
  @DocsEditable
  HtmlDocument createHtmlDocument(String title) native;

  @DomName('DOMImplementation.hasFeature')
  @DocsEditable
  bool hasFeature(String feature, String version) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MimeType')
class DomMimeType native "*MimeType" {

  @DomName('DOMMimeType.description')
  @DocsEditable
  final String description;

  @DomName('DOMMimeType.enabledPlugin')
  @DocsEditable
  final DomPlugin enabledPlugin;

  @DomName('DOMMimeType.suffixes')
  @DocsEditable
  final String suffixes;

  @DomName('DOMMimeType.type')
  @DocsEditable
  final String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MimeTypeArray')
class DomMimeTypeArray implements JavaScriptIndexingBehavior, List<DomMimeType> native "*MimeTypeArray" {

  @DomName('DOMMimeTypeArray.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  DomMimeType operator[](int index) => JS("DomMimeType", "#[#]", this, index);

  void operator[]=(int index, DomMimeType value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<DomMimeType> mixins.
  // DomMimeType is the element type.

  // From Iterable<DomMimeType>:

  Iterator<DomMimeType> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<DomMimeType>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, DomMimeType)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(DomMimeType element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(DomMimeType element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(DomMimeType element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<DomMimeType> where(bool f(DomMimeType element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(DomMimeType element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(DomMimeType element)) => IterableMixinWorkaround.any(this, f);

  List<DomMimeType> toList() => new List<DomMimeType>.from(this);
  Set<DomMimeType> toSet() => new Set<DomMimeType>.from(this);

  bool get isEmpty => this.length == 0;

  List<DomMimeType> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<DomMimeType> takeWhile(bool test(DomMimeType value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<DomMimeType> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<DomMimeType> skipWhile(bool test(DomMimeType value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  DomMimeType firstMatching(bool test(DomMimeType value), { DomMimeType orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  DomMimeType lastMatching(bool test(DomMimeType value), {DomMimeType orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  DomMimeType singleMatching(bool test(DomMimeType value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  DomMimeType elementAt(int index) {
    return this[index];
  }

  // From Collection<DomMimeType>:

  void add(DomMimeType value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(DomMimeType value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<DomMimeType> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<DomMimeType>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<DomMimeType> get reversed =>
      new ReversedListView<DomMimeType>(this, 0, null);

  void sort([int compare(DomMimeType a, DomMimeType b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(DomMimeType element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(DomMimeType element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  DomMimeType get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  DomMimeType get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  DomMimeType get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  DomMimeType min([int compare(DomMimeType a, DomMimeType b)]) =>
      IterableMixinWorkaround.min(this, compare);

  DomMimeType max([int compare(DomMimeType a, DomMimeType b)]) =>
      IterableMixinWorkaround.max(this, compare);

  DomMimeType removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  DomMimeType removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(DomMimeType element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(DomMimeType element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<DomMimeType> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [DomMimeType initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<DomMimeType> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <DomMimeType>[]);

  // -- end List<DomMimeType> mixins.

  @DomName('DOMMimeTypeArray.item')
  @DocsEditable
  DomMimeType item(int index) native;

  @DomName('DOMMimeTypeArray.namedItem')
  @DocsEditable
  DomMimeType namedItem(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DOMParser')
class DomParser native "*DOMParser" {

  @DocsEditable
  factory DomParser() => DomParser._create();
  static DomParser _create() => JS('DomParser', 'new DOMParser()');

  @DomName('DOMParser.parseFromString')
  @DocsEditable
  Document parseFromString(String str, String contentType) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Plugin')
class DomPlugin native "*Plugin" {

  @DomName('DOMPlugin.description')
  @DocsEditable
  final String description;

  @DomName('DOMPlugin.filename')
  @DocsEditable
  final String filename;

  @DomName('DOMPlugin.length')
  @DocsEditable
  final int length;

  @DomName('DOMPlugin.name')
  @DocsEditable
  final String name;

  @DomName('DOMPlugin.item')
  @DocsEditable
  DomMimeType item(int index) native;

  @DomName('DOMPlugin.namedItem')
  @DocsEditable
  DomMimeType namedItem(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('PluginArray')
class DomPluginArray implements JavaScriptIndexingBehavior, List<DomPlugin> native "*PluginArray" {

  @DomName('DOMPluginArray.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  DomPlugin operator[](int index) => JS("DomPlugin", "#[#]", this, index);

  void operator[]=(int index, DomPlugin value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<DomPlugin> mixins.
  // DomPlugin is the element type.

  // From Iterable<DomPlugin>:

  Iterator<DomPlugin> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<DomPlugin>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, DomPlugin)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(DomPlugin element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(DomPlugin element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(DomPlugin element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<DomPlugin> where(bool f(DomPlugin element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(DomPlugin element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(DomPlugin element)) => IterableMixinWorkaround.any(this, f);

  List<DomPlugin> toList() => new List<DomPlugin>.from(this);
  Set<DomPlugin> toSet() => new Set<DomPlugin>.from(this);

  bool get isEmpty => this.length == 0;

  List<DomPlugin> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<DomPlugin> takeWhile(bool test(DomPlugin value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<DomPlugin> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<DomPlugin> skipWhile(bool test(DomPlugin value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  DomPlugin firstMatching(bool test(DomPlugin value), { DomPlugin orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  DomPlugin lastMatching(bool test(DomPlugin value), {DomPlugin orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  DomPlugin singleMatching(bool test(DomPlugin value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  DomPlugin elementAt(int index) {
    return this[index];
  }

  // From Collection<DomPlugin>:

  void add(DomPlugin value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(DomPlugin value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<DomPlugin> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<DomPlugin>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<DomPlugin> get reversed =>
      new ReversedListView<DomPlugin>(this, 0, null);

  void sort([int compare(DomPlugin a, DomPlugin b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(DomPlugin element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(DomPlugin element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  DomPlugin get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  DomPlugin get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  DomPlugin get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  DomPlugin min([int compare(DomPlugin a, DomPlugin b)]) =>
      IterableMixinWorkaround.min(this, compare);

  DomPlugin max([int compare(DomPlugin a, DomPlugin b)]) =>
      IterableMixinWorkaround.max(this, compare);

  DomPlugin removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  DomPlugin removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(DomPlugin element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(DomPlugin element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<DomPlugin> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [DomPlugin initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<DomPlugin> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <DomPlugin>[]);

  // -- end List<DomPlugin> mixins.

  @DomName('DOMPluginArray.item')
  @DocsEditable
  DomPlugin item(int index) native;

  @DomName('DOMPluginArray.namedItem')
  @DocsEditable
  DomPlugin namedItem(String name) native;

  @DomName('DOMPluginArray.refresh')
  @DocsEditable
  void refresh(bool reload) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebKitPoint')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class DomPoint native "*WebKitPoint" {

  @DocsEditable
  factory DomPoint(num x, num y) => DomPoint._create(x, y);
  static DomPoint _create(num x, num y) => JS('DomPoint', 'new WebKitPoint(#,#)', x, y);

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.WebKitPoint)');

  @DomName('WebKitPoint.x')
  @DocsEditable
  num x;

  @DomName('WebKitPoint.y')
  @DocsEditable
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Selection')
class DomSelection native "*Selection" {

  @DomName('DOMSelection.anchorNode')
  @DocsEditable
  final Node anchorNode;

  @DomName('DOMSelection.anchorOffset')
  @DocsEditable
  final int anchorOffset;

  @DomName('DOMSelection.baseNode')
  @DocsEditable
  final Node baseNode;

  @DomName('DOMSelection.baseOffset')
  @DocsEditable
  final int baseOffset;

  @DomName('DOMSelection.extentNode')
  @DocsEditable
  final Node extentNode;

  @DomName('DOMSelection.extentOffset')
  @DocsEditable
  final int extentOffset;

  @DomName('DOMSelection.focusNode')
  @DocsEditable
  final Node focusNode;

  @DomName('DOMSelection.focusOffset')
  @DocsEditable
  final int focusOffset;

  @DomName('DOMSelection.isCollapsed')
  @DocsEditable
  final bool isCollapsed;

  @DomName('DOMSelection.rangeCount')
  @DocsEditable
  final int rangeCount;

  @DomName('DOMSelection.type')
  @DocsEditable
  final String type;

  @DomName('DOMSelection.addRange')
  @DocsEditable
  void addRange(Range range) native;

  @DomName('DOMSelection.collapse')
  @DocsEditable
  void collapse(Node node, int index) native;

  @DomName('DOMSelection.collapseToEnd')
  @DocsEditable
  void collapseToEnd() native;

  @DomName('DOMSelection.collapseToStart')
  @DocsEditable
  void collapseToStart() native;

  @DomName('DOMSelection.containsNode')
  @DocsEditable
  bool containsNode(Node node, bool allowPartial) native;

  @DomName('DOMSelection.deleteFromDocument')
  @DocsEditable
  void deleteFromDocument() native;

  @DomName('DOMSelection.empty')
  @DocsEditable
  void empty() native;

  @DomName('DOMSelection.extend')
  @DocsEditable
  void extend(Node node, int offset) native;

  @DomName('DOMSelection.getRangeAt')
  @DocsEditable
  Range getRangeAt(int index) native;

  @DomName('DOMSelection.modify')
  @DocsEditable
  void modify(String alter, String direction, String granularity) native;

  @DomName('DOMSelection.removeAllRanges')
  @DocsEditable
  void removeAllRanges() native;

  @DomName('DOMSelection.selectAllChildren')
  @DocsEditable
  void selectAllChildren(Node node) native;

  @DomName('DOMSelection.setBaseAndExtent')
  @DocsEditable
  void setBaseAndExtent(Node baseNode, int baseOffset, Node extentNode, int extentOffset) native;

  @DomName('DOMSelection.setPosition')
  @DocsEditable
  void setPosition(Node node, int offset) native;

  @DomName('DOMSelection.toString')
  @DocsEditable
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DOMSettableTokenList')
class DomSettableTokenList extends DomTokenList native "*DOMSettableTokenList" {

  @DomName('DOMSettableTokenList.value')
  @DocsEditable
  String value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DOMStringList')
class DomStringList implements JavaScriptIndexingBehavior, List<String> native "*DOMStringList" {

  @DomName('DOMStringList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  String operator[](int index) => JS("String", "#[#]", this, index);

  void operator[]=(int index, String value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<String> mixins.
  // String is the element type.

  // From Iterable<String>:

  Iterator<String> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<String>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, String)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  // contains() defined by IDL.

  void forEach(void f(String element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(String element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<String> where(bool f(String element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(String element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(String element)) => IterableMixinWorkaround.any(this, f);

  List<String> toList() => new List<String>.from(this);
  Set<String> toSet() => new Set<String>.from(this);

  bool get isEmpty => this.length == 0;

  List<String> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<String> takeWhile(bool test(String value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<String> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<String> skipWhile(bool test(String value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  String firstMatching(bool test(String value), { String orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  String lastMatching(bool test(String value), {String orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  String singleMatching(bool test(String value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  String elementAt(int index) {
    return this[index];
  }

  // From Collection<String>:

  void add(String value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(String value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<String> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<String>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<String> get reversed =>
      new ReversedListView<String>(this, 0, null);

  void sort([int compare(String a, String b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(String element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(String element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  String get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  String get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  String get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  String min([int compare(String a, String b)]) =>
      IterableMixinWorkaround.min(this, compare);

  String max([int compare(String a, String b)]) =>
      IterableMixinWorkaround.max(this, compare);

  String removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  String removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(String element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(String element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<String> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [String initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<String> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <String>[]);

  // -- end List<String> mixins.

  @DomName('DOMStringList.contains')
  @DocsEditable
  bool contains(String string) native;

  @DomName('DOMStringList.item')
  @DocsEditable
  String item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('DOMStringMap')
abstract class DomStringMap {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DOMTokenList')
class DomTokenList native "*DOMTokenList" {

  @DomName('DOMTokenList.length')
  @DocsEditable
  final int length;

  @DomName('DOMTokenList.contains')
  @DocsEditable
  bool contains(String token) native;

  @DomName('DOMTokenList.item')
  @DocsEditable
  String item(int index) native;

  @DomName('DOMTokenList.toString')
  @DocsEditable
  String toString() native;

  @DomName('DOMTokenList.toggle')
  @DocsEditable
  bool toggle(String token, [bool force]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// TODO(jacobr): use _Lists.dart to remove some of the duplicated
// functionality.
class _ChildrenElementList implements List {
  // Raw Element.
  final Element _element;
  final HtmlCollection _childElements;

  _ChildrenElementList._wrap(Element element)
    : _childElements = element.$dom_children,
      _element = element;

  List<Element> toList() {
    final output = new List<Element>.fixedLength(_childElements.length);
    for (int i = 0, len = _childElements.length; i < len; i++) {
      output[i] = _childElements[i];
    }
    return output;
  }

  Set<Element> toSet() {
    final output = new Set<Element>();
    for (int i = 0, len = _childElements.length; i < len; i++) {
      output.add(_childElements[i]);
    }
    return output;
  }

  bool contains(Element element) => _childElements.contains(element);

  void forEach(void f(Element element)) {
    for (Element element in _childElements) {
      f(element);
    }
  }

  bool every(bool f(Element element)) {
    for (Element element in this) {
      if (!f(element)) {
        return false;
      }
    }
    return true;
  }

  bool any(bool f(Element element)) {
    for (Element element in this) {
      if (f(element)) {
        return true;
      }
    }
    return false;
  }

  String join([String separator]) {
    return IterableMixinWorkaround.joinList(this, separator);
  }

  List mappedBy(f(Element element)) {
    return IterableMixinWorkaround.mappedByList(this, f);
  }

  Iterable<Element> where(bool f(Element element)) {
    return IterableMixinWorkaround.where(this, f);
  }

  bool get isEmpty {
    return _element.$dom_firstElementChild == null;
  }

  List<Element> take(int n) {
    return IterableMixinWorkaround.takeList(this, n);
  }

  Iterable<Element> takeWhile(bool test(Element value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<Element> skip(int n) {
    return IterableMixinWorkaround.skipList(this, n);
  }

  Iterable<Element> skipWhile(bool test(Element value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  Element firstMatching(bool test(Element value), {Element orElse()}) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  Element lastMatching(bool test(Element value), {Element orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  Element singleMatching(bool test(Element value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  Element elementAt(int index) {
    return this[index];
  }

  int get length {
    return _childElements.length;
  }

  Element operator [](int index) {
    return _childElements[index];
  }

  void operator []=(int index, Element value) {
    _element.$dom_replaceChild(value, _childElements[index]);
  }

  void set length(int newLength) {
    // TODO(jacobr): remove children when length is reduced.
    throw new UnsupportedError('');
  }

  Element add(Element value) {
    _element.$dom_appendChild(value);
    return value;
  }

  Element addLast(Element value) => add(value);

  Iterator<Element> get iterator => toList().iterator;

  void addAll(Iterable<Element> iterable) {
    for (Element element in iterable) {
      _element.$dom_appendChild(element);
    }
  }

  List<Element> get reversed =>
      new ReversedListView<Element>(this, 0, null);

  void sort([int compare(Element a, Element b)]) {
    throw new UnsupportedError('TODO(jacobr): should we impl?');
  }

  dynamic reduce(dynamic initialValue,
      dynamic combine(dynamic previousValue, Element element)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  void setRange(int start, int rangeLength, List from, [int startFrom = 0]) {
    throw new UnimplementedError();
  }

  void remove(Object object) {
    if (object is Element) {
      Element element = object;
      if (identical(element.parentNode, _element)) {
        _element.$dom_removeChild(element);
      }
    }
  }

  void removeAll(Iterable elements) {
    IterableMixinWorkaround.removeAll(this, elements);
  }

  void retainAll(Iterable elements) {
    IterableMixinWorkaround.retainAll(this, elements);
  }

  void removeMatching(bool test(Element element)) {
    IterableMixinWorkaround.removeMatching(this, test);
  }

  void retainMatching(bool test(Element element)) {
    IterableMixinWorkaround.retainMatching(this, test);
  }

  void removeRange(int start, int rangeLength) {
    throw new UnimplementedError();
  }

  void insertRange(int start, int rangeLength, [initialValue = null]) {
    throw new UnimplementedError();
  }

  List getRange(int start, int rangeLength) =>
    new _FrozenElementList._wrap(Lists.getRange(this, start, rangeLength,
        []));

  int indexOf(Element element, [int start = 0]) {
    return Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(Element element, [int start = null]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  void clear() {
    // It is unclear if we want to keep non element nodes?
    _element.text = '';
  }

  Element removeAt(int index) {
    final result = this[index];
    if (result != null) {
      _element.$dom_removeChild(result);
    }
    return result;
  }

  Element removeLast() {
    final result = this.last;
    if (result != null) {
      _element.$dom_removeChild(result);
    }
    return result;
  }

  Element get first {
    Element result = _element.$dom_firstElementChild;
    if (result == null) throw new StateError("No elements");
    return result;
  }


  Element get last {
    Element result = _element.$dom_lastElementChild;
    if (result == null) throw new StateError("No elements");
    return result;
  }

  Element get single {
    if (length > 1) throw new StateError("More than one element");
    return first;
  }

  Element min([int compare(Element a, Element b)]) {
    return IterableMixinWorkaround.min(this, compare);
  }

  Element max([int compare(Element a, Element b)]) {
    return IterableMixinWorkaround.max(this, compare);
  }
}

// TODO(jacobr): this is an inefficient implementation but it is hard to see
// a better option given that we cannot quite force NodeList to be an
// ElementList as there are valid cases where a NodeList JavaScript object
// contains Node objects that are not Elements.
class _FrozenElementList implements List {
  final List<Node> _nodeList;

  _FrozenElementList._wrap(this._nodeList);

  bool contains(Element element) {
    for (Element el in this) {
      if (el == element) return true;
    }
    return false;
  }

  void forEach(void f(Element element)) {
    for (Element el in this) {
      f(el);
    }
  }

  String join([String separator]) {
    return IterableMixinWorkaround.joinList(this, separator);
  }

  List mappedBy(f(Element element)) {
    return IterableMixinWorkaround.mappedByList(this, f);
  }

  Iterable<Element> where(bool f(Element element)) {
    return IterableMixinWorkaround.where(this, f);
  }

  bool every(bool f(Element element)) {
    for(Element element in this) {
      if (!f(element)) {
        return false;
      }
    };
    return true;
  }

  bool any(bool f(Element element)) {
    for(Element element in this) {
      if (f(element)) {
        return true;
      }
    };
    return false;
  }

  List<Element> toList() => new List<Element>.from(this);
  Set<Element> toSet() => new Set<Element>.from(this);

  List<Element> take(int n) {
    return IterableMixinWorkaround.takeList(this, n);
  }

  Iterable<Element> takeWhile(bool test(Element value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<Element> skip(int n) {
    return IterableMixinWorkaround.skipList(this, n);
  }

  Iterable<Element> skipWhile(bool test(Element value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  Element firstMatching(bool test(Element value), {Element orElse()}) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  Element lastMatching(bool test(Element value), {Element orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  Element singleMatching(bool test(Element value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  Element elementAt(int index) {
    return this[index];
  }

  bool get isEmpty => _nodeList.isEmpty;

  int get length => _nodeList.length;

  Element operator [](int index) => _nodeList[index];

  void operator []=(int index, Element value) {
    throw new UnsupportedError('');
  }

  void set length(int newLength) {
    _nodeList.length = newLength;
  }

  void add(Element value) {
    throw new UnsupportedError('');
  }

  void addLast(Element value) {
    throw new UnsupportedError('');
  }

  Iterator<Element> get iterator => new _FrozenElementListIterator(this);

  void addAll(Iterable<Element> iterable) {
    throw new UnsupportedError('');
  }

  List<Element> get reversed =>
      new ReversedListView<Element>(this, 0, null);

  void sort([int compare(Element a, Element b)]) {
    throw new UnsupportedError('');
  }

  dynamic reduce(dynamic initialValue,
      dynamic combine(dynamic previousValue, Element element)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  void setRange(int start, int rangeLength, List from, [int startFrom = 0]) {
    throw new UnsupportedError('');
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError('');
  }

  void insertRange(int start, int rangeLength, [initialValue = null]) {
    throw new UnsupportedError('');
  }

  List<Element> getRange(int start, int rangeLength) =>
    new _FrozenElementList._wrap(_nodeList.getRange(start, rangeLength));

  int indexOf(Element element, [int start = 0]) =>
    _nodeList.indexOf(element, start);

  int lastIndexOf(Element element, [int start = null]) =>
    _nodeList.lastIndexOf(element, start);

  void clear() {
    throw new UnsupportedError('');
  }

  Element removeAt(int index) {
    throw new UnsupportedError('');
  }

  Element removeLast() {
    throw new UnsupportedError('');
  }

  void remove(Object element) {
    throw new UnsupportedError('');
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError('');
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError('');
  }

  void removeMatching(bool test(Element element)) {
    throw new UnsupportedError('');
  }

  void retainMatching(bool test(Element element)) {
    throw new UnsupportedError('');
  }

  Element get first => _nodeList.first;

  Element get last => _nodeList.last;

  Element get single => _nodeList.single;

  Element min([int compare(Element a, Element b)]) {
    return IterableMixinWorkaround.min(this, compare);
  }

  Element max([int compare(Element a, Element b)]) {
    return IterableMixinWorkaround.max(this, compare);
  }
}

class _FrozenElementListIterator implements Iterator<Element> {
  final _FrozenElementList _list;
  int _index = -1;
  Element _current;

  _FrozenElementListIterator(this._list);

  /**
   * Moves to the next element. Returns true if the iterator is positioned
   * at an element. Returns false if it is positioned after the last element.
   */
  bool moveNext() {
    int nextIndex = _index + 1;
    if (nextIndex < _list.length) {
      _current = _list[nextIndex];
      _index = nextIndex;
      return true;
    }
    _index = _list.length;
    _current = null;
    return false;
  }

  /**
   * Returns the element the [Iterator] is positioned at.
   *
   * Return [:null:] if the iterator is positioned before the first, or
   * after the last element.
   */
  Element get current => _current;
}

class _ElementCssClassSet extends CssClassSet {

  final Element _element;

  _ElementCssClassSet(this._element);

  Set<String> readClasses() {
    var s = new Set<String>();
    var classname = _element.$dom_className;

    for (String name in classname.split(' ')) {
      String trimmed = name.trim();
      if (!trimmed.isEmpty) {
        s.add(trimmed);
      }
    }
    return s;
  }

  void writeClasses(Set<String> s) {
    List list = new List.from(s);
    _element.$dom_className = s.join(' ');
  }
}

/**
 * An abstract class, which all HTML elements extend.
 */
@DomName('Element')
abstract class Element extends Node implements ElementTraversal native "*Element" {

  /**
   * Creates an HTML element from a valid fragment of HTML.
   *
   * The [html] fragment must represent valid HTML with a single element root,
   * which will be parsed and returned.
   *
   * Important: the contents of [html] should not contain any user-supplied
   * data. Without strict data validation it is impossible to prevent script
   * injection exploits.
   *
   * It is instead recommended that elements be constructed via [Element.tag]
   * and text be added via [text].
   *
   *     var element = new Element.html('<div class="foo">content</div>');
   */
  factory Element.html(String html) =>
      _ElementFactoryProvider.createElement_html(html);

  /**
   * Creates the HTML element specified by the tag name.
   *
   * This is similar to [Document.createElement].
   * [tag] should be a valid HTML tag name. If [tag] is an unknown tag then
   * this will create an [UnknownElement].
   *
   *     var divElement = new Element.tag('div');
   *     print(divElement is DivElement); // 'true'
   *     var myElement = new Element.tag('unknownTag');
   *     print(myElement is UnknownElement); // 'true'
   *
   * For standard elements it is more preferable to use the type constructors:
   *     var element = new DivElement();
   *
   * See also:
   *
   * * [isTagSupported]
   */
  factory Element.tag(String tag) =>
      _ElementFactoryProvider.createElement_tag(tag);

  /**
   * All attributes on this element.
   *
   * Any modifications to the attribute map will automatically be applied to
   * this element.
   *
   * This only includes attributes which are not in a namespace
   * (such as 'xlink:href'), additional attributes can be accessed via
   * [getNamespacedAttributes].
   */
  Map<String, String> get attributes => new _ElementAttributeMap(this);

  void set attributes(Map<String, String> value) {
    Map<String, String> attributes = this.attributes;
    attributes.clear();
    for (String key in value.keys) {
      attributes[key] = value[key];
    }
  }

  /**
   * Deprecated, use innerHtml instead.
   */
  @deprecated
  String get innerHTML => this.innerHtml;
  @deprecated
  void set innerHTML(String value) {
    this.innerHtml = value;
  }

  @deprecated
  void set elements(Collection<Element> value) {
    this.children = value;
  }

  /**
   * Deprecated, use [children] instead.
   */
  @deprecated
  List<Element> get elements => this.children;

  /**
   * List of the direct children of this element.
   *
   * This collection can be used to add and remove elements from the document.
   *
   *     var item = new DivElement();
   *     item.text = 'Something';
   *     document.body.children.add(item) // Item is now displayed on the page.
   *     for (var element in document.body.children) {
   *       element.style.background = 'red'; // Turns every child of body red.
   *     }
   */
  List<Element> get children => new _ChildrenElementList._wrap(this);

  void set children(List<Element> value) {
    // Copy list first since we don't want liveness during iteration.
    List copy = new List.from(value);
    var children = this.children;
    children.clear();
    children.addAll(copy);
  }

  /**
   * Finds the first descendant element of this element that matches the
   * specified group of selectors.
   *
   * [selectors] should be a string using CSS selector syntax.
   *
   *     // Gets the first descendant with the class 'classname'
   *     var element = element.query('.className');
   *     // Gets the element with id 'id'
   *     var element = element.query('#id');
   *     // Gets the first descendant [ImageElement]
   *     var img = element.query('img');
   *
   * See also:
   *
   * * [CSS Selectors](http://docs.webplatform.org/wiki/css/selectors)
   */
  Element query(String selectors) => $dom_querySelector(selectors);

  /**
   * Finds all descendent elements of this element that match the specified
   * group of selectors.
   *
   * [selectors] should be a string using CSS selector syntax.
   *
   *     var items = element.query('.itemClassName');
   */
  List<Element> queryAll(String selectors) =>
    new _FrozenElementList._wrap($dom_querySelectorAll(selectors));

  /**
   * The set of CSS classes applied to this element.
   *
   * This set makes it easy to add, remove or toggle the classes applied to
   * this element.
   *
   *     element.classes.add('selected');
   *     element.classes.toggle('isOnline');
   *     element.classes.remove('selected');
   */
  CssClassSet get classes => new _ElementCssClassSet(this);

  void set classes(Collection<String> value) {
    CssClassSet classSet = classes;
    classSet.clear();
    classSet.addAll(value);
  }

  /**
   * Allows access to all custom data attributes (data-*) set on this element.
   *
   * The keys for the map must follow these rules:
   *
   * * The name must not begin with 'xml'.
   * * The name cannot contain a semi-colon (';').
   * * The name cannot contain any capital letters.
   *
   * Any keys from markup will be converted to camel-cased keys in the map.
   *
   * For example, HTML specified as:
   *
   *     <div data-my-random-value='value'></div>
   *
   * Would be accessed in Dart as:
   *
   *     var value = element.dataAttributes['myRandomValue'];
   *
   * See also:
   *
   * * [Custom data attributes](http://www.w3.org/TR/html5/global-attributes.html#custom-data-attribute)
   */
  Map<String, String> get dataAttributes =>
    new _DataAttributeMap(attributes);

  void set dataAttributes(Map<String, String> value) {
    final dataAttributes = this.dataAttributes;
    dataAttributes.clear();
    for (String key in value.keys) {
      dataAttributes[key] = value[key];
    }
  }

  /**
   * Gets a map for manipulating the attributes of a particular namespace.
   *
   * This is primarily useful for SVG attributes such as xref:link.
   */
  Map<String, String> getNamespacedAttributes(String namespace) {
    return new _NamespacedAttributeMap(this, namespace);
  }

  /**
   * The set of all CSS values applied to this element, including inherited
   * and default values.
   *
   * The computedStyle contains values that are inherited from other
   * sources, such as parent elements or stylesheets. This differs from the
   * [style] property, which contains only the values specified directly on this
   * element.
   *
   * PseudoElement can be values such as `::after`, `::before`, `::marker`,
   * `::line-marker`.
   *
   * See also:
   *
   * * [CSS Inheritance and Cascade](http://docs.webplatform.org/wiki/tutorials/inheritance_and_cascade)
   * * [Pseudo-elements](http://docs.webplatform.org/wiki/css/selectors/pseudo-elements)
   */
  CssStyleDeclaration getComputedStyle([String pseudoElement]) {
    if (pseudoElement == null) {
      pseudoElement = '';
    }
    // TODO(jacobr): last param should be null, see b/5045788
    return window.$dom_getComputedStyle(this, pseudoElement);
  }

  /**
   * Adds the specified element to after the last child of this element.
   */
  void append(Element e) {
    this.children.add(e);
  }

  /**
   * Adds the specified text as a text node after the last child of this
   * element.
   */
  void appendText(String text) {
    this.insertAdjacentText('beforeend', text);
  }

  /**
   * Parses the specified text as HTML and adds the resulting node after the
   * last child of this element.
   */
  void appendHtml(String text) {
    this.insertAdjacentHtml('beforeend', text);
  }

  /**
   * Checks to see if the tag name is supported by the current platform.
   *
   * The tag should be a valid HTML tag name.
   */
  static bool isTagSupported(String tag) {
    var e = _ElementFactoryProvider.createElement_tag(tag);
    return e is Element && !(e is UnknownElement);
  }

  // Hooks to support custom WebComponents.
  /**
   * Experimental support for [web components][wc]. This field stores a
   * reference to the component implementation. It was inspired by Mozilla's
   * [x-tags][] project. Please note: in the future it may be possible to
   * `extend Element` from your class, in which case this field will be
   * deprecated and will simply return this [Element] object.
   *
   * [wc]: http://dvcs.w3.org/hg/webcomponents/raw-file/tip/explainer/index.html
   * [x-tags]: http://x-tags.org/
   */
  @Creates('Null')  // Set from Dart code; does not instantiate a native type.
  var xtag;

  static const EventStreamProvider<WheelEvent> mouseWheelEvent =
      const _CustomEventStreamProvider<WheelEvent>(
        Element._determineMouseWheelEventType);

  static String _determineMouseWheelEventType(EventTarget e) {
    if (JS('bool', '#.onwheel !== undefined', e)) {
      // W3C spec, and should be IE9+, but IE has a bug exposing onwheel.
      return 'wheel';
    } else if (JS('bool', '#.onmousewheel !== undefined', e)) {
      // Chrome & IE
      return 'mousewheel';
    } else {
      // Firefox
      return 'DOMMouseScroll';
    }
  }

  /**
   * Creates a text node and inserts it into the DOM at the specified location.
   *
   * To see the possible values for [where], read the doc for
   * [insertAdjacentHtml].
   *
   * See also:
   *
   * * [insertAdjacentHtml]
   */
  void insertAdjacentText(String where, String text) {
    if (JS('bool', '!!#.insertAdjacentText', this)) {
      _insertAdjacentText(where, text);
    } else {
      _insertAdjacentNode(where, new Text(text));
    }
  }

  @JSName('insertAdjacentText')
  void _insertAdjacentText(String where, String text) native;

  /**
   * Parses text as an HTML fragment and inserts it into the DOM at the
   * specified location.
   *
   * The [where] parameter indicates where to insert the HTML fragment:
   *
   * * 'beforeBegin': Immediately before this element.
   * * 'afterBegin': As the first child of this element.
   * * 'beforeEnd': As the last child of this element.
   * * 'afterEnd': Immediately after this element.
   *
   *     var html = '<div class="something">content</div>';
   *     // Inserts as the first child
   *     document.body.insertAdjacentHtml('afterBegin', html);
   *     var createdElement = document.body.children[0];
   *     print(createdElement.classes[0]); // Prints 'something'
   *
   * See also:
   *
   * * [insertAdjacentText]
   * * [insertAdjacentElement]
   */
  void insertAdjacentHtml(String where, String text) {
    if (JS('bool', '!!#.insertAdjacentHtml', this)) {
      _insertAdjacentHtml(where, text);
    } else {
      _insertAdjacentNode(where, new DocumentFragment.html(text));
    }
  }

  @JSName('insertAdjacentHTML')
  void _insertAdjacentHTML(String where, String text) native;

  /**
   * Inserts [element] into the DOM at the specified location.
   *
   * To see the possible values for [where], read the doc for
   * [insertAdjacentHtml].
   *
   * See also:
   *
   * * [insertAdjacentHtml]
   */
  Element insertAdjacentElement(String where, Element element) {
    if (JS('bool', '!!#.insertAdjacentElement', this)) {
      _insertAdjacentElement(where, element);
    } else {
      _insertAdjacentNode(where, element);
    }
    return element;
  }

  @JSName('insertAdjacentElement')
  void _insertAdjacentElement(String where, Element element) native;

  void _insertAdjacentNode(String where, Node node) {
    switch (where.toLowerCase()) {
      case 'beforebegin':
        this.parentNode.insertBefore(node, this);
        break;
      case 'afterbegin':
        var first = this.nodes.length > 0 ? this.nodes[0] : null;
        this.insertBefore(node, first);
        break;
      case 'beforeend':
        this.nodes.add(node);
        break;
      case 'afterend':
        this.parentNode.insertBefore(node, this.nextNode);
        break;
      default:
        throw new ArgumentError("Invalid position ${where}");
    }
  }

  /**
   * Checks if this element matches the CSS selectors.
   */
  @Experimental
  bool matches(String selectors) {
    if (JS('bool', '!!#.matches', this)) {
      return JS('bool', '#.matches(#)', this, selectors);
    } else if (JS('bool', '!!#.webkitMatchesSelector', this)) {
      return JS('bool', '#.webkitMatchesSelector(#)', this, selectors);
    } else if (JS('bool', '!!#.mozMatchesSelector', this)) {
      return JS('bool', '#.mozMatchesSelector(#)', this, selectors);
    } else if (JS('bool', '!!#.msMatchesSelector', this)) {
      return JS('bool', '#.msMatchesSelector(#)', this, selectors);
    }
    throw new UnsupportedError("Not supported on this platform");
  }


  @DomName('Element.abort')
  @DocsEditable
  static const EventStreamProvider<Event> abortEvent = const EventStreamProvider<Event>('abort');

  @DomName('Element.beforecopy')
  @DocsEditable
  static const EventStreamProvider<Event> beforeCopyEvent = const EventStreamProvider<Event>('beforecopy');

  @DomName('Element.beforecut')
  @DocsEditable
  static const EventStreamProvider<Event> beforeCutEvent = const EventStreamProvider<Event>('beforecut');

  @DomName('Element.beforepaste')
  @DocsEditable
  static const EventStreamProvider<Event> beforePasteEvent = const EventStreamProvider<Event>('beforepaste');

  @DomName('Element.blur')
  @DocsEditable
  static const EventStreamProvider<Event> blurEvent = const EventStreamProvider<Event>('blur');

  @DomName('Element.change')
  @DocsEditable
  static const EventStreamProvider<Event> changeEvent = const EventStreamProvider<Event>('change');

  @DomName('Element.click')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> clickEvent = const EventStreamProvider<MouseEvent>('click');

  @DomName('Element.contextmenu')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> contextMenuEvent = const EventStreamProvider<MouseEvent>('contextmenu');

  @DomName('Element.copy')
  @DocsEditable
  static const EventStreamProvider<Event> copyEvent = const EventStreamProvider<Event>('copy');

  @DomName('Element.cut')
  @DocsEditable
  static const EventStreamProvider<Event> cutEvent = const EventStreamProvider<Event>('cut');

  @DomName('Element.dblclick')
  @DocsEditable
  static const EventStreamProvider<Event> doubleClickEvent = const EventStreamProvider<Event>('dblclick');

  @DomName('Element.drag')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dragEvent = const EventStreamProvider<MouseEvent>('drag');

  @DomName('Element.dragend')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dragEndEvent = const EventStreamProvider<MouseEvent>('dragend');

  @DomName('Element.dragenter')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dragEnterEvent = const EventStreamProvider<MouseEvent>('dragenter');

  @DomName('Element.dragleave')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dragLeaveEvent = const EventStreamProvider<MouseEvent>('dragleave');

  @DomName('Element.dragover')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dragOverEvent = const EventStreamProvider<MouseEvent>('dragover');

  @DomName('Element.dragstart')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dragStartEvent = const EventStreamProvider<MouseEvent>('dragstart');

  @DomName('Element.drop')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> dropEvent = const EventStreamProvider<MouseEvent>('drop');

  @DomName('Element.error')
  @DocsEditable
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DomName('Element.focus')
  @DocsEditable
  static const EventStreamProvider<Event> focusEvent = const EventStreamProvider<Event>('focus');

  @DomName('Element.input')
  @DocsEditable
  static const EventStreamProvider<Event> inputEvent = const EventStreamProvider<Event>('input');

  @DomName('Element.invalid')
  @DocsEditable
  static const EventStreamProvider<Event> invalidEvent = const EventStreamProvider<Event>('invalid');

  @DomName('Element.keydown')
  @DocsEditable
  static const EventStreamProvider<KeyboardEvent> keyDownEvent = const EventStreamProvider<KeyboardEvent>('keydown');

  @DomName('Element.keypress')
  @DocsEditable
  static const EventStreamProvider<KeyboardEvent> keyPressEvent = const EventStreamProvider<KeyboardEvent>('keypress');

  @DomName('Element.keyup')
  @DocsEditable
  static const EventStreamProvider<KeyboardEvent> keyUpEvent = const EventStreamProvider<KeyboardEvent>('keyup');

  @DomName('Element.load')
  @DocsEditable
  static const EventStreamProvider<Event> loadEvent = const EventStreamProvider<Event>('load');

  @DomName('Element.mousedown')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> mouseDownEvent = const EventStreamProvider<MouseEvent>('mousedown');

  @DomName('Element.mousemove')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> mouseMoveEvent = const EventStreamProvider<MouseEvent>('mousemove');

  @DomName('Element.mouseout')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> mouseOutEvent = const EventStreamProvider<MouseEvent>('mouseout');

  @DomName('Element.mouseover')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> mouseOverEvent = const EventStreamProvider<MouseEvent>('mouseover');

  @DomName('Element.mouseup')
  @DocsEditable
  static const EventStreamProvider<MouseEvent> mouseUpEvent = const EventStreamProvider<MouseEvent>('mouseup');

  @DomName('Element.paste')
  @DocsEditable
  static const EventStreamProvider<Event> pasteEvent = const EventStreamProvider<Event>('paste');

  @DomName('Element.reset')
  @DocsEditable
  static const EventStreamProvider<Event> resetEvent = const EventStreamProvider<Event>('reset');

  @DomName('Element.scroll')
  @DocsEditable
  static const EventStreamProvider<Event> scrollEvent = const EventStreamProvider<Event>('scroll');

  @DomName('Element.search')
  @DocsEditable
  static const EventStreamProvider<Event> searchEvent = const EventStreamProvider<Event>('search');

  @DomName('Element.select')
  @DocsEditable
  static const EventStreamProvider<Event> selectEvent = const EventStreamProvider<Event>('select');

  @DomName('Element.selectstart')
  @DocsEditable
  static const EventStreamProvider<Event> selectStartEvent = const EventStreamProvider<Event>('selectstart');

  @DomName('Element.submit')
  @DocsEditable
  static const EventStreamProvider<Event> submitEvent = const EventStreamProvider<Event>('submit');

  @DomName('Element.touchcancel')
  @DocsEditable
  static const EventStreamProvider<TouchEvent> touchCancelEvent = const EventStreamProvider<TouchEvent>('touchcancel');

  @DomName('Element.touchend')
  @DocsEditable
  static const EventStreamProvider<TouchEvent> touchEndEvent = const EventStreamProvider<TouchEvent>('touchend');

  @DomName('Element.touchenter')
  @DocsEditable
  static const EventStreamProvider<TouchEvent> touchEnterEvent = const EventStreamProvider<TouchEvent>('touchenter');

  @DomName('Element.touchleave')
  @DocsEditable
  static const EventStreamProvider<TouchEvent> touchLeaveEvent = const EventStreamProvider<TouchEvent>('touchleave');

  @DomName('Element.touchmove')
  @DocsEditable
  static const EventStreamProvider<TouchEvent> touchMoveEvent = const EventStreamProvider<TouchEvent>('touchmove');

  @DomName('Element.touchstart')
  @DocsEditable
  static const EventStreamProvider<TouchEvent> touchStartEvent = const EventStreamProvider<TouchEvent>('touchstart');

  @DomName('Element.webkitTransitionEnd')
  @DocsEditable
  static const EventStreamProvider<TransitionEvent> transitionEndEvent = const EventStreamProvider<TransitionEvent>('webkitTransitionEnd');

  @DomName('Element.webkitfullscreenchange')
  @DocsEditable
  static const EventStreamProvider<Event> fullscreenChangeEvent = const EventStreamProvider<Event>('webkitfullscreenchange');

  @DomName('Element.webkitfullscreenerror')
  @DocsEditable
  static const EventStreamProvider<Event> fullscreenErrorEvent = const EventStreamProvider<Event>('webkitfullscreenerror');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  ElementEvents get on =>
    new ElementEvents(this);

  @JSName('children')
  @DomName('Element.children')
  @DocsEditable
  final HtmlCollection $dom_children;

  @DomName('Element.contentEditable')
  @DocsEditable
  String contentEditable;

  @DomName('Element.dir')
  @DocsEditable
  String dir;

  @DomName('Element.draggable')
  @DocsEditable
  bool draggable;

  @DomName('Element.hidden')
  @DocsEditable
  bool hidden;

  @DomName('Element.id')
  @DocsEditable
  String id;

  @JSName('innerHTML')
  @DomName('Element.innerHTML')
  @DocsEditable
  String innerHtml;

  @DomName('Element.isContentEditable')
  @DocsEditable
  final bool isContentEditable;

  @DomName('Element.lang')
  @DocsEditable
  String lang;

  @JSName('outerHTML')
  @DomName('Element.outerHTML')
  @DocsEditable
  final String outerHtml;

  @DomName('Element.spellcheck')
  @DocsEditable
  bool spellcheck;

  @DomName('Element.tabIndex')
  @DocsEditable
  int tabIndex;

  @DomName('Element.title')
  @DocsEditable
  String title;

  @DomName('Element.translate')
  @DocsEditable
  bool translate;

  @DomName('Element.webkitdropzone')
  @DocsEditable
  String webkitdropzone;

  @DomName('Element.click')
  @DocsEditable
  void click() native;

  static const int ALLOW_KEYBOARD_INPUT = 1;

  @JSName('childElementCount')
  @DomName('Element.childElementCount')
  @DocsEditable
  final int $dom_childElementCount;

  @JSName('className')
  @DomName('Element.className')
  @DocsEditable
  String $dom_className;

  @DomName('Element.clientHeight')
  @DocsEditable
  final int clientHeight;

  @DomName('Element.clientLeft')
  @DocsEditable
  final int clientLeft;

  @DomName('Element.clientTop')
  @DocsEditable
  final int clientTop;

  @DomName('Element.clientWidth')
  @DocsEditable
  final int clientWidth;

  @DomName('Element.dataset')
  @DocsEditable
  final Map<String, String> dataset;

  @JSName('firstElementChild')
  @DomName('Element.firstElementChild')
  @DocsEditable
  final Element $dom_firstElementChild;

  @JSName('lastElementChild')
  @DomName('Element.lastElementChild')
  @DocsEditable
  final Element $dom_lastElementChild;

  @DomName('Element.nextElementSibling')
  @DocsEditable
  final Element nextElementSibling;

  @DomName('Element.offsetHeight')
  @DocsEditable
  final int offsetHeight;

  @DomName('Element.offsetLeft')
  @DocsEditable
  final int offsetLeft;

  @DomName('Element.offsetParent')
  @DocsEditable
  final Element offsetParent;

  @DomName('Element.offsetTop')
  @DocsEditable
  final int offsetTop;

  @DomName('Element.offsetWidth')
  @DocsEditable
  final int offsetWidth;

  @DomName('Element.previousElementSibling')
  @DocsEditable
  final Element previousElementSibling;

  @DomName('Element.scrollHeight')
  @DocsEditable
  final int scrollHeight;

  @DomName('Element.scrollLeft')
  @DocsEditable
  int scrollLeft;

  @DomName('Element.scrollTop')
  @DocsEditable
  int scrollTop;

  @DomName('Element.scrollWidth')
  @DocsEditable
  final int scrollWidth;

  @DomName('Element.style')
  @DocsEditable
  final CssStyleDeclaration style;

  @DomName('Element.tagName')
  @DocsEditable
  final String tagName;

  @DomName('Element.webkitPseudo')
  @DocsEditable
  String webkitPseudo;

  @DomName('Element.webkitShadowRoot')
  @DocsEditable
  final ShadowRoot webkitShadowRoot;

  @DomName('Element.blur')
  @DocsEditable
  void blur() native;

  @DomName('Element.focus')
  @DocsEditable
  void focus() native;

  @JSName('getAttribute')
  @DomName('Element.getAttribute')
  @DocsEditable
  String $dom_getAttribute(String name) native;

  @JSName('getAttributeNS')
  @DomName('Element.getAttributeNS')
  @DocsEditable
  String $dom_getAttributeNS(String namespaceURI, String localName) native;

  @DomName('Element.getBoundingClientRect')
  @DocsEditable
  ClientRect getBoundingClientRect() native;

  @DomName('Element.getClientRects')
  @DocsEditable
  @Returns('_ClientRectList')
  @Creates('_ClientRectList')
  List<ClientRect> getClientRects() native;

  @JSName('getElementsByClassName')
  @DomName('Element.getElementsByClassName')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> $dom_getElementsByClassName(String name) native;

  @JSName('getElementsByTagName')
  @DomName('Element.getElementsByTagName')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> $dom_getElementsByTagName(String name) native;

  @JSName('hasAttribute')
  @DomName('Element.hasAttribute')
  @DocsEditable
  bool $dom_hasAttribute(String name) native;

  @JSName('hasAttributeNS')
  @DomName('Element.hasAttributeNS')
  @DocsEditable
  bool $dom_hasAttributeNS(String namespaceURI, String localName) native;

  @JSName('querySelector')
  @DomName('Element.querySelector')
  @DocsEditable
  Element $dom_querySelector(String selectors) native;

  @JSName('querySelectorAll')
  @DomName('Element.querySelectorAll')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> $dom_querySelectorAll(String selectors) native;

  @JSName('removeAttribute')
  @DomName('Element.removeAttribute')
  @DocsEditable
  void $dom_removeAttribute(String name) native;

  @JSName('removeAttributeNS')
  @DomName('Element.removeAttributeNS')
  @DocsEditable
  void $dom_removeAttributeNS(String namespaceURI, String localName) native;

  @DomName('Element.scrollByLines')
  @DocsEditable
  void scrollByLines(int lines) native;

  @DomName('Element.scrollByPages')
  @DocsEditable
  void scrollByPages(int pages) native;

  @JSName('scrollIntoViewIfNeeded')
  @DomName('Element.scrollIntoViewIfNeeded')
  @DocsEditable
  void scrollIntoView([bool centerIfNeeded]) native;

  @JSName('setAttribute')
  @DomName('Element.setAttribute')
  @DocsEditable
  void $dom_setAttribute(String name, String value) native;

  @JSName('setAttributeNS')
  @DomName('Element.setAttributeNS')
  @DocsEditable
  void $dom_setAttributeNS(String namespaceURI, String qualifiedName, String value) native;

  @JSName('webkitCreateShadowRoot')
  @DomName('Element.webkitCreateShadowRoot')
  @DocsEditable
  @SupportedBrowser(SupportedBrowser.CHROME, '25')
  @Experimental
  ShadowRoot createShadowRoot() native;

  @DomName('Element.webkitRequestFullScreen')
  @DocsEditable
  void webkitRequestFullScreen(int flags) native;

  @DomName('Element.webkitRequestFullscreen')
  @DocsEditable
  void webkitRequestFullscreen() native;

  @DomName('Element.webkitRequestPointerLock')
  @DocsEditable
  void webkitRequestPointerLock() native;

  @DomName('Element.abort')
  @DocsEditable
  Stream<Event> get onAbort => abortEvent.forTarget(this);

  @DomName('Element.beforecopy')
  @DocsEditable
  Stream<Event> get onBeforeCopy => beforeCopyEvent.forTarget(this);

  @DomName('Element.beforecut')
  @DocsEditable
  Stream<Event> get onBeforeCut => beforeCutEvent.forTarget(this);

  @DomName('Element.beforepaste')
  @DocsEditable
  Stream<Event> get onBeforePaste => beforePasteEvent.forTarget(this);

  @DomName('Element.blur')
  @DocsEditable
  Stream<Event> get onBlur => blurEvent.forTarget(this);

  @DomName('Element.change')
  @DocsEditable
  Stream<Event> get onChange => changeEvent.forTarget(this);

  @DomName('Element.click')
  @DocsEditable
  Stream<MouseEvent> get onClick => clickEvent.forTarget(this);

  @DomName('Element.contextmenu')
  @DocsEditable
  Stream<MouseEvent> get onContextMenu => contextMenuEvent.forTarget(this);

  @DomName('Element.copy')
  @DocsEditable
  Stream<Event> get onCopy => copyEvent.forTarget(this);

  @DomName('Element.cut')
  @DocsEditable
  Stream<Event> get onCut => cutEvent.forTarget(this);

  @DomName('Element.dblclick')
  @DocsEditable
  Stream<Event> get onDoubleClick => doubleClickEvent.forTarget(this);

  @DomName('Element.drag')
  @DocsEditable
  Stream<MouseEvent> get onDrag => dragEvent.forTarget(this);

  @DomName('Element.dragend')
  @DocsEditable
  Stream<MouseEvent> get onDragEnd => dragEndEvent.forTarget(this);

  @DomName('Element.dragenter')
  @DocsEditable
  Stream<MouseEvent> get onDragEnter => dragEnterEvent.forTarget(this);

  @DomName('Element.dragleave')
  @DocsEditable
  Stream<MouseEvent> get onDragLeave => dragLeaveEvent.forTarget(this);

  @DomName('Element.dragover')
  @DocsEditable
  Stream<MouseEvent> get onDragOver => dragOverEvent.forTarget(this);

  @DomName('Element.dragstart')
  @DocsEditable
  Stream<MouseEvent> get onDragStart => dragStartEvent.forTarget(this);

  @DomName('Element.drop')
  @DocsEditable
  Stream<MouseEvent> get onDrop => dropEvent.forTarget(this);

  @DomName('Element.error')
  @DocsEditable
  Stream<Event> get onError => errorEvent.forTarget(this);

  @DomName('Element.focus')
  @DocsEditable
  Stream<Event> get onFocus => focusEvent.forTarget(this);

  @DomName('Element.input')
  @DocsEditable
  Stream<Event> get onInput => inputEvent.forTarget(this);

  @DomName('Element.invalid')
  @DocsEditable
  Stream<Event> get onInvalid => invalidEvent.forTarget(this);

  @DomName('Element.keydown')
  @DocsEditable
  Stream<KeyboardEvent> get onKeyDown => keyDownEvent.forTarget(this);

  @DomName('Element.keypress')
  @DocsEditable
  Stream<KeyboardEvent> get onKeyPress => keyPressEvent.forTarget(this);

  @DomName('Element.keyup')
  @DocsEditable
  Stream<KeyboardEvent> get onKeyUp => keyUpEvent.forTarget(this);

  @DomName('Element.load')
  @DocsEditable
  Stream<Event> get onLoad => loadEvent.forTarget(this);

  @DomName('Element.mousedown')
  @DocsEditable
  Stream<MouseEvent> get onMouseDown => mouseDownEvent.forTarget(this);

  @DomName('Element.mousemove')
  @DocsEditable
  Stream<MouseEvent> get onMouseMove => mouseMoveEvent.forTarget(this);

  @DomName('Element.mouseout')
  @DocsEditable
  Stream<MouseEvent> get onMouseOut => mouseOutEvent.forTarget(this);

  @DomName('Element.mouseover')
  @DocsEditable
  Stream<MouseEvent> get onMouseOver => mouseOverEvent.forTarget(this);

  @DomName('Element.mouseup')
  @DocsEditable
  Stream<MouseEvent> get onMouseUp => mouseUpEvent.forTarget(this);

  @DomName('Element.mousewheel')
  @DocsEditable
  Stream<WheelEvent> get onMouseWheel => mouseWheelEvent.forTarget(this);

  @DomName('Element.paste')
  @DocsEditable
  Stream<Event> get onPaste => pasteEvent.forTarget(this);

  @DomName('Element.reset')
  @DocsEditable
  Stream<Event> get onReset => resetEvent.forTarget(this);

  @DomName('Element.scroll')
  @DocsEditable
  Stream<Event> get onScroll => scrollEvent.forTarget(this);

  @DomName('Element.search')
  @DocsEditable
  Stream<Event> get onSearch => searchEvent.forTarget(this);

  @DomName('Element.select')
  @DocsEditable
  Stream<Event> get onSelect => selectEvent.forTarget(this);

  @DomName('Element.selectstart')
  @DocsEditable
  Stream<Event> get onSelectStart => selectStartEvent.forTarget(this);

  @DomName('Element.submit')
  @DocsEditable
  Stream<Event> get onSubmit => submitEvent.forTarget(this);

  @DomName('Element.touchcancel')
  @DocsEditable
  Stream<TouchEvent> get onTouchCancel => touchCancelEvent.forTarget(this);

  @DomName('Element.touchend')
  @DocsEditable
  Stream<TouchEvent> get onTouchEnd => touchEndEvent.forTarget(this);

  @DomName('Element.touchenter')
  @DocsEditable
  Stream<TouchEvent> get onTouchEnter => touchEnterEvent.forTarget(this);

  @DomName('Element.touchleave')
  @DocsEditable
  Stream<TouchEvent> get onTouchLeave => touchLeaveEvent.forTarget(this);

  @DomName('Element.touchmove')
  @DocsEditable
  Stream<TouchEvent> get onTouchMove => touchMoveEvent.forTarget(this);

  @DomName('Element.touchstart')
  @DocsEditable
  Stream<TouchEvent> get onTouchStart => touchStartEvent.forTarget(this);

  @DomName('Element.webkitTransitionEnd')
  @DocsEditable
  Stream<TransitionEvent> get onTransitionEnd => transitionEndEvent.forTarget(this);

  @DomName('Element.webkitfullscreenchange')
  @DocsEditable
  Stream<Event> get onFullscreenChange => fullscreenChangeEvent.forTarget(this);

  @DomName('Element.webkitfullscreenerror')
  @DocsEditable
  Stream<Event> get onFullscreenError => fullscreenErrorEvent.forTarget(this);

}

final _START_TAG_REGEXP = new RegExp('<(\\w+)');
class _ElementFactoryProvider {
  static const _CUSTOM_PARENT_TAG_MAP = const {
    'body' : 'html',
    'head' : 'html',
    'caption' : 'table',
    'td': 'tr',
    'th': 'tr',
    'colgroup': 'table',
    'col' : 'colgroup',
    'tr' : 'tbody',
    'tbody' : 'table',
    'tfoot' : 'table',
    'thead' : 'table',
    'track' : 'audio',
  };

  // TODO(jmesserly): const set would be better
  static const _TABLE_TAGS = const {
    'caption': null,
    'col': null,
    'colgroup': null,
    'tbody': null,
    'td': null,
    'tfoot': null,
    'th': null,
    'thead': null,
    'tr': null,
  };

  @DomName('Document.createElement')
  static Element createElement_html(String html) {
    // TODO(jacobr): this method can be made more robust and performant.
    // 1) Cache the dummy parent elements required to use innerHTML rather than
    //    creating them every call.
    // 2) Verify that the html does not contain leading or trailing text nodes.
    // 3) Verify that the html does not contain both <head> and <body> tags.
    // 4) Detatch the created element from its dummy parent.
    String parentTag = 'div';
    String tag;
    final match = _START_TAG_REGEXP.firstMatch(html);
    if (match != null) {
      tag = match.group(1).toLowerCase();
      if (_Device.isIE && _TABLE_TAGS.containsKey(tag)) {
        return _createTableForIE(html, tag);
      }
      parentTag = _CUSTOM_PARENT_TAG_MAP[tag];
      if (parentTag == null) parentTag = 'div';
    }

    final temp = new Element.tag(parentTag);
    temp.innerHtml = html;

    Element element;
    if (temp.children.length == 1) {
      element = temp.children[0];
    } else if (parentTag == 'html' && temp.children.length == 2) {
      // In html5 the root <html> tag will always have a <body> and a <head>,
      // even though the inner html only contains one of them.
      element = temp.children[tag == 'head' ? 0 : 1];
    } else {
      _singleNode(temp.children);
    }
    element.remove();
    return element;
  }

  /**
   * IE table elements don't support innerHTML (even in standards mode).
   * Instead we use a div and inject the table element in the innerHtml string.
   * This technique works on other browsers too, but it's probably slower,
   * so we only use it when running on IE.
   *
   * See also innerHTML:
   * <http://msdn.microsoft.com/en-us/library/ie/ms533897(v=vs.85).aspx>
   * and Building Tables Dynamically:
   * <http://msdn.microsoft.com/en-us/library/ie/ms532998(v=vs.85).aspx>.
   */
  static Element _createTableForIE(String html, String tag) {
    var div = new Element.tag('div');
    div.innerHtml = '<table>$html</table>';
    var table = _singleNode(div.children);
    Element element;
    switch (tag) {
      case 'td':
      case 'th':
        element = _singleNode(_singleNode(table.rows).cells);
        break;
      case 'tr':
        element = _singleNode(table.rows);
        break;
      case 'tbody':
        element = _singleNode(table.tBodies);
        break;
      case 'thead':
        element = table.tHead;
        break;
      case 'tfoot':
        element = table.tFoot;
        break;
      case 'caption':
        element = table.caption;
        break;
      case 'colgroup':
        element = _getColgroup(table);
        break;
      case 'col':
        element = _singleNode(_getColgroup(table).children);
        break;
    }
    element.remove();
    return element;
  }

  static TableColElement _getColgroup(TableElement table) {
    // TODO(jmesserly): is there a better way to do this?
    return _singleNode(table.children.where((n) => n.tagName == 'COLGROUP')
        .toList());
  }

  static Node _singleNode(List<Node> list) {
    if (list.length == 1) return list[0];
    throw new ArgumentError('HTML had ${list.length} '
        'top level elements but 1 expected');
  }

  @DomName('Document.createElement')
  // Optimization to improve performance until the dart2js compiler inlines this
  // method.
  static dynamic createElement_tag(String tag) =>
      JS('Element', 'document.createElement(#)', tag);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@deprecated
class ElementEvents extends Events {
  ElementEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get abort => this['abort'];

  @DocsEditable
  EventListenerList get beforeCopy => this['beforecopy'];

  @DocsEditable
  EventListenerList get beforeCut => this['beforecut'];

  @DocsEditable
  EventListenerList get beforePaste => this['beforepaste'];

  @DocsEditable
  EventListenerList get blur => this['blur'];

  @DocsEditable
  EventListenerList get change => this['change'];

  @DocsEditable
  EventListenerList get click => this['click'];

  @DocsEditable
  EventListenerList get contextMenu => this['contextmenu'];

  @DocsEditable
  EventListenerList get copy => this['copy'];

  @DocsEditable
  EventListenerList get cut => this['cut'];

  @DocsEditable
  EventListenerList get doubleClick => this['dblclick'];

  @DocsEditable
  EventListenerList get drag => this['drag'];

  @DocsEditable
  EventListenerList get dragEnd => this['dragend'];

  @DocsEditable
  EventListenerList get dragEnter => this['dragenter'];

  @DocsEditable
  EventListenerList get dragLeave => this['dragleave'];

  @DocsEditable
  EventListenerList get dragOver => this['dragover'];

  @DocsEditable
  EventListenerList get dragStart => this['dragstart'];

  @DocsEditable
  EventListenerList get drop => this['drop'];

  @DocsEditable
  EventListenerList get error => this['error'];

  @DocsEditable
  EventListenerList get focus => this['focus'];

  @DocsEditable
  EventListenerList get input => this['input'];

  @DocsEditable
  EventListenerList get invalid => this['invalid'];

  @DocsEditable
  EventListenerList get keyDown => this['keydown'];

  @DocsEditable
  EventListenerList get keyPress => this['keypress'];

  @DocsEditable
  EventListenerList get keyUp => this['keyup'];

  @DocsEditable
  EventListenerList get load => this['load'];

  @DocsEditable
  EventListenerList get mouseDown => this['mousedown'];

  @DocsEditable
  EventListenerList get mouseMove => this['mousemove'];

  @DocsEditable
  EventListenerList get mouseOut => this['mouseout'];

  @DocsEditable
  EventListenerList get mouseOver => this['mouseover'];

  @DocsEditable
  EventListenerList get mouseUp => this['mouseup'];

  @DocsEditable
  EventListenerList get paste => this['paste'];

  @DocsEditable
  EventListenerList get reset => this['reset'];

  @DocsEditable
  EventListenerList get scroll => this['scroll'];

  @DocsEditable
  EventListenerList get search => this['search'];

  @DocsEditable
  EventListenerList get select => this['select'];

  @DocsEditable
  EventListenerList get selectStart => this['selectstart'];

  @DocsEditable
  EventListenerList get submit => this['submit'];

  @DocsEditable
  EventListenerList get touchCancel => this['touchcancel'];

  @DocsEditable
  EventListenerList get touchEnd => this['touchend'];

  @DocsEditable
  EventListenerList get touchEnter => this['touchenter'];

  @DocsEditable
  EventListenerList get touchLeave => this['touchleave'];

  @DocsEditable
  EventListenerList get touchMove => this['touchmove'];

  @DocsEditable
  EventListenerList get touchStart => this['touchstart'];

  @DocsEditable
  EventListenerList get transitionEnd => this['webkitTransitionEnd'];

  @DocsEditable
  EventListenerList get fullscreenChange => this['webkitfullscreenchange'];

  @DocsEditable
  EventListenerList get fullscreenError => this['webkitfullscreenerror'];

  EventListenerList get mouseWheel {
    if (JS('bool', '#.onwheel !== undefined', _ptr)) {
      // W3C spec, and should be IE9+, but IE has a bug exposing onwheel.
      return this['wheel'];
    } else if (JS('bool', '#.onmousewheel !== undefined', _ptr)) {
      // Chrome & IE
      return this['mousewheel'];
    } else {
      // Firefox
      return this['DOMMouseScroll'];
    }
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('ElementTraversal')
abstract class ElementTraversal {

  int $dom_childElementCount;

  Element $dom_firstElementChild;

  Element $dom_lastElementChild;

  Element nextElementSibling;

  Element previousElementSibling;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLEmbedElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.IE)
@SupportedBrowser(SupportedBrowser.SAFARI)
class EmbedElement extends Element native "*HTMLEmbedElement" {

  @DocsEditable
  factory EmbedElement() => document.$dom_createElement("embed");

  /// Checks if this type is supported on the current platform.
  static bool get supported => Element.isTagSupported('embed');

  @DomName('HTMLEmbedElement.align')
  @DocsEditable
  String align;

  @DomName('HTMLEmbedElement.height')
  @DocsEditable
  String height;

  @DomName('HTMLEmbedElement.name')
  @DocsEditable
  String name;

  @DomName('HTMLEmbedElement.src')
  @DocsEditable
  String src;

  @DomName('HTMLEmbedElement.type')
  @DocsEditable
  String type;

  @DomName('HTMLEmbedElement.width')
  @DocsEditable
  String width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('EntityReference')
class EntityReference extends Node native "*EntityReference" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void EntriesCallback(List<Entry> entries);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Entry')
class Entry native "*Entry" {

  @DomName('Entry.filesystem')
  @DocsEditable
  final FileSystem filesystem;

  @DomName('Entry.fullPath')
  @DocsEditable
  final String fullPath;

  @DomName('Entry.isDirectory')
  @DocsEditable
  final bool isDirectory;

  @DomName('Entry.isFile')
  @DocsEditable
  final bool isFile;

  @DomName('Entry.name')
  @DocsEditable
  final String name;

  @DomName('Entry.copyTo')
  @DocsEditable
  void copyTo(DirectoryEntry parent, [String name, EntryCallback successCallback, ErrorCallback errorCallback]) native;

  @DomName('Entry.getMetadata')
  @DocsEditable
  void getMetadata(MetadataCallback successCallback, [ErrorCallback errorCallback]) native;

  @DomName('Entry.getParent')
  @DocsEditable
  void getParent([EntryCallback successCallback, ErrorCallback errorCallback]) native;

  @DomName('Entry.moveTo')
  @DocsEditable
  void moveTo(DirectoryEntry parent, [String name, EntryCallback successCallback, ErrorCallback errorCallback]) native;

  @DomName('Entry.remove')
  @DocsEditable
  void remove(VoidCallback successCallback, [ErrorCallback errorCallback]) native;

  @JSName('toURL')
  @DomName('Entry.toURL')
  @DocsEditable
  String toUrl() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void EntryCallback(Entry entry);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('EntrySync')
class EntrySync native "*EntrySync" {

  @DomName('EntrySync.filesystem')
  @DocsEditable
  final FileSystemSync filesystem;

  @DomName('EntrySync.fullPath')
  @DocsEditable
  final String fullPath;

  @DomName('EntrySync.isDirectory')
  @DocsEditable
  final bool isDirectory;

  @DomName('EntrySync.isFile')
  @DocsEditable
  final bool isFile;

  @DomName('EntrySync.name')
  @DocsEditable
  final String name;

  @DomName('EntrySync.copyTo')
  @DocsEditable
  EntrySync copyTo(DirectoryEntrySync parent, String name) native;

  @DomName('EntrySync.getMetadata')
  @DocsEditable
  Metadata getMetadata() native;

  @DomName('EntrySync.getParent')
  @DocsEditable
  EntrySync getParent() native;

  @DomName('EntrySync.moveTo')
  @DocsEditable
  EntrySync moveTo(DirectoryEntrySync parent, String name) native;

  @DomName('EntrySync.remove')
  @DocsEditable
  void remove() native;

  @JSName('toURL')
  @DomName('EntrySync.toURL')
  @DocsEditable
  String toUrl() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void ErrorCallback(FileError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('ErrorEvent')
class ErrorEvent extends Event native "*ErrorEvent" {

  @DomName('ErrorEvent.filename')
  @DocsEditable
  final String filename;

  @DomName('ErrorEvent.lineno')
  @DocsEditable
  final int lineno;

  @DomName('ErrorEvent.message')
  @DocsEditable
  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('Event')
class Event native "*Event" {
  // In JS, canBubble and cancelable are technically required parameters to
  // init*Event. In practice, though, if they aren't provided they simply
  // default to false (since that's Boolean(undefined)).
  //
  // Contrary to JS, we default canBubble and cancelable to true, since that's
  // what people want most of the time anyway.
  factory Event(String type,
      {bool canBubble: true, bool cancelable: true}) {
    return new Event.eventType('Event', type, canBubble: canBubble,
        cancelable: canBubble);
  }

  /**
   * Creates a new Event object of the specified type.
   *
   * This is analogous to document.createEvent.
   * Normally events should be created via their constructors, if available.
   *
   *     var e = new Event.type('MouseEvent', 'mousedown', true, true);
   */
  factory Event.eventType(String type, String name, {bool canBubble: true,
      bool cancelable: true}) {
    final Event e = document.$dom_createEvent(type);
    e.$dom_initEvent(name, canBubble, cancelable);
    return e;
  }

  static const int AT_TARGET = 2;

  static const int BLUR = 8192;

  static const int BUBBLING_PHASE = 3;

  static const int CAPTURING_PHASE = 1;

  static const int CHANGE = 32768;

  static const int CLICK = 64;

  static const int DBLCLICK = 128;

  static const int DRAGDROP = 2048;

  static const int FOCUS = 4096;

  static const int KEYDOWN = 256;

  static const int KEYPRESS = 1024;

  static const int KEYUP = 512;

  static const int MOUSEDOWN = 1;

  static const int MOUSEDRAG = 32;

  static const int MOUSEMOVE = 16;

  static const int MOUSEOUT = 8;

  static const int MOUSEOVER = 4;

  static const int MOUSEUP = 2;

  static const int NONE = 0;

  static const int SELECT = 16384;

  @DomName('Event.bubbles')
  @DocsEditable
  final bool bubbles;

  @DomName('Event.cancelBubble')
  @DocsEditable
  bool cancelBubble;

  @DomName('Event.cancelable')
  @DocsEditable
  final bool cancelable;

  @DomName('Event.clipboardData')
  @DocsEditable
  final Clipboard clipboardData;

  EventTarget get currentTarget => _convertNativeToDart_EventTarget(this._currentTarget);
  @JSName('currentTarget')
  @DomName('Event.currentTarget')
  @DocsEditable
  @Creates('Null')
  @Returns('EventTarget|=Object')
  final dynamic _currentTarget;

  @DomName('Event.defaultPrevented')
  @DocsEditable
  final bool defaultPrevented;

  @DomName('Event.eventPhase')
  @DocsEditable
  final int eventPhase;

  @DomName('Event.returnValue')
  @DocsEditable
  bool returnValue;

  EventTarget get target => _convertNativeToDart_EventTarget(this._target);
  @JSName('target')
  @DomName('Event.target')
  @DocsEditable
  @Creates('Node')
  @Returns('EventTarget|=Object')
  final dynamic _target;

  @DomName('Event.timeStamp')
  @DocsEditable
  final int timeStamp;

  @DomName('Event.type')
  @DocsEditable
  final String type;

  @JSName('initEvent')
  @DomName('Event.initEvent')
  @DocsEditable
  void $dom_initEvent(String eventTypeArg, bool canBubbleArg, bool cancelableArg) native;

  @DomName('Event.preventDefault')
  @DocsEditable
  void preventDefault() native;

  @DomName('Event.stopImmediatePropagation')
  @DocsEditable
  void stopImmediatePropagation() native;

  @DomName('Event.stopPropagation')
  @DocsEditable
  void stopPropagation() native;


  /**
   * Checks to see if the event class is supported by the current platform.
   */
  static bool _isTypeSupported(String eventType) {
    // Browsers throw for unsupported event names.
    try {
      var e = document.$dom_createEvent(eventType);
      return e is Event;
    } catch (_) { }
    return false;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('EventException')
class EventException native "*EventException" {

  static const int DISPATCH_REQUEST_ERR = 1;

  static const int UNSPECIFIED_EVENT_TYPE_ERR = 0;

  @DomName('EventException.code')
  @DocsEditable
  final int code;

  @DomName('EventException.message')
  @DocsEditable
  final String message;

  @DomName('EventException.name')
  @DocsEditable
  final String name;

  @DomName('EventException.toString')
  @DocsEditable
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('EventSource')
class EventSource extends EventTarget native "*EventSource" {

  @DomName('EventSource.error')
  @DocsEditable
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DomName('EventSource.message')
  @DocsEditable
  static const EventStreamProvider<MessageEvent> messageEvent = const EventStreamProvider<MessageEvent>('message');

  @DomName('EventSource.open')
  @DocsEditable
  static const EventStreamProvider<Event> openEvent = const EventStreamProvider<Event>('open');

  @DocsEditable
  factory EventSource(String url, [Map eventSourceInit]) {
    if (!?eventSourceInit) {
      return EventSource._create(url);
    }
    return EventSource._create(url, eventSourceInit);
  }
  static EventSource _create(String url, [Map eventSourceInit]) {
    if (!?eventSourceInit) {
      return JS('EventSource', 'new EventSource(#)', url);
    }
    return JS('EventSource', 'new EventSource(#,#)', url, eventSourceInit);
  }

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  EventSourceEvents get on =>
    new EventSourceEvents(this);

  static const int CLOSED = 2;

  static const int CONNECTING = 0;

  static const int OPEN = 1;

  @DomName('EventSource.readyState')
  @DocsEditable
  final int readyState;

  @DomName('EventSource.url')
  @DocsEditable
  final String url;

  @DomName('EventSource.withCredentials')
  @DocsEditable
  final bool withCredentials;

  @JSName('addEventListener')
  @DomName('EventSource.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('EventSource.close')
  @DocsEditable
  void close() native;

  @DomName('EventSource.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native;

  @JSName('removeEventListener')
  @DomName('EventSource.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('EventSource.error')
  @DocsEditable
  Stream<Event> get onError => errorEvent.forTarget(this);

  @DomName('EventSource.message')
  @DocsEditable
  Stream<MessageEvent> get onMessage => messageEvent.forTarget(this);

  @DomName('EventSource.open')
  @DocsEditable
  Stream<Event> get onOpen => openEvent.forTarget(this);
}

@DocsEditable
@deprecated
class EventSourceEvents extends Events {
  @DocsEditable
  EventSourceEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get error => this['error'];

  @DocsEditable
  EventListenerList get message => this['message'];

  @DocsEditable
  EventListenerList get open => this['open'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Base class that supports listening for and dispatching browser events.
 *
 * Events can either be accessed by string name (using the indexed getter) or by
 * getters exposed by subclasses. Use the getters exposed by subclasses when
 * possible for better compile-time type checks.
 *
 * Using an indexed getter:
 *     events['mouseover'].add((e) => print("Mouse over!"));
 *
 * Using a getter provided by a subclass:
 *     elementEvents.mouseOver.add((e) => print("Mouse over!"));
 */
class Events {
  /* Raw event target. */
  final EventTarget _ptr;

  Events(this._ptr);

  EventListenerList operator [](String type) {
    return new EventListenerList(_ptr, type);
  }
}

/**
 * Supports adding, removing, and dispatching events for a specific event type.
 */
class EventListenerList {

  final EventTarget _ptr;
  final String _type;

  EventListenerList(this._ptr, this._type);

  // TODO(jacobr): implement equals.

  EventListenerList add(EventListener listener,
      [bool useCapture = false]) {
    _add(listener, useCapture);
    return this;
  }

  EventListenerList remove(EventListener listener,
      [bool useCapture = false]) {
    _remove(listener, useCapture);
    return this;
  }

  bool dispatch(Event evt) {
    return _ptr.dispatchEvent(evt);
  }

  void _add(EventListener listener, bool useCapture) {
    _ptr.$dom_addEventListener(_type, listener, useCapture);
  }

  void _remove(EventListener listener, bool useCapture) {
    _ptr.$dom_removeEventListener(_type, listener, useCapture);
  }
}

/**
 * Base class for all browser objects that support events.
 *
 * Use the [on] property to add, remove, and dispatch events (rather than
 * [$dom_addEventListener], [$dom_dispatchEvent], and
 * [$dom_removeEventListener]) for compile-time type checks and a more concise
 * API.
 */
@DomName('EventTarget')
class EventTarget native "*EventTarget" {

  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  Events get on => new Events(this);

  @JSName('addEventListener')
  @DomName('EventTarget.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('EventTarget.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event event) native;

  @JSName('removeEventListener')
  @DomName('EventTarget.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('EXTTextureFilterAnisotropic')
class ExtTextureFilterAnisotropic native "*EXTTextureFilterAnisotropic" {

  static const int MAX_TEXTURE_MAX_ANISOTROPY_EXT = 0x84FF;

  static const int TEXTURE_MAX_ANISOTROPY_EXT = 0x84FE;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLFieldSetElement')
class FieldSetElement extends Element native "*HTMLFieldSetElement" {

  @DocsEditable
  factory FieldSetElement() => document.$dom_createElement("fieldset");

  @DomName('HTMLFieldSetElement.disabled')
  @DocsEditable
  bool disabled;

  @DomName('HTMLFieldSetElement.elements')
  @DocsEditable
  final HtmlCollection elements;

  @DomName('HTMLFieldSetElement.form')
  @DocsEditable
  final FormElement form;

  @DomName('HTMLFieldSetElement.name')
  @DocsEditable
  String name;

  @DomName('HTMLFieldSetElement.type')
  @DocsEditable
  final String type;

  @DomName('HTMLFieldSetElement.validationMessage')
  @DocsEditable
  final String validationMessage;

  @DomName('HTMLFieldSetElement.validity')
  @DocsEditable
  final ValidityState validity;

  @DomName('HTMLFieldSetElement.willValidate')
  @DocsEditable
  final bool willValidate;

  @DomName('HTMLFieldSetElement.checkValidity')
  @DocsEditable
  bool checkValidity() native;

  @DomName('HTMLFieldSetElement.setCustomValidity')
  @DocsEditable
  void setCustomValidity(String error) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('File')
class File extends Blob native "*File" {

  @DomName('File.lastModifiedDate')
  @DocsEditable
  final Date lastModifiedDate;

  @DomName('File.name')
  @DocsEditable
  final String name;

  @DomName('File.webkitRelativePath')
  @DocsEditable
  final String webkitRelativePath;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void FileCallback(File file);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('FileEntry')
class FileEntry extends Entry native "*FileEntry" {

  @DomName('FileEntry.createWriter')
  @DocsEditable
  void createWriter(FileWriterCallback successCallback, [ErrorCallback errorCallback]) native;

  @DomName('FileEntry.file')
  @DocsEditable
  void file(FileCallback successCallback, [ErrorCallback errorCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('FileEntrySync')
class FileEntrySync extends EntrySync native "*FileEntrySync" {

  @DomName('FileEntrySync.createWriter')
  @DocsEditable
  FileWriterSync createWriter() native;

  @DomName('FileEntrySync.file')
  @DocsEditable
  File file() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('FileError')
class FileError native "*FileError" {

  static const int ABORT_ERR = 3;

  static const int ENCODING_ERR = 5;

  static const int INVALID_MODIFICATION_ERR = 9;

  static const int INVALID_STATE_ERR = 7;

  static const int NOT_FOUND_ERR = 1;

  static const int NOT_READABLE_ERR = 4;

  static const int NO_MODIFICATION_ALLOWED_ERR = 6;

  static const int PATH_EXISTS_ERR = 12;

  static const int QUOTA_EXCEEDED_ERR = 10;

  static const int SECURITY_ERR = 2;

  static const int SYNTAX_ERR = 8;

  static const int TYPE_MISMATCH_ERR = 11;

  @DomName('FileError.code')
  @DocsEditable
  final int code;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('FileException')
class FileException native "*FileException" {

  static const int ABORT_ERR = 3;

  static const int ENCODING_ERR = 5;

  static const int INVALID_MODIFICATION_ERR = 9;

  static const int INVALID_STATE_ERR = 7;

  static const int NOT_FOUND_ERR = 1;

  static const int NOT_READABLE_ERR = 4;

  static const int NO_MODIFICATION_ALLOWED_ERR = 6;

  static const int PATH_EXISTS_ERR = 12;

  static const int QUOTA_EXCEEDED_ERR = 10;

  static const int SECURITY_ERR = 2;

  static const int SYNTAX_ERR = 8;

  static const int TYPE_MISMATCH_ERR = 11;

  @DomName('FileException.code')
  @DocsEditable
  final int code;

  @DomName('FileException.message')
  @DocsEditable
  final String message;

  @DomName('FileException.name')
  @DocsEditable
  final String name;

  @DomName('FileException.toString')
  @DocsEditable
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('FileList')
class FileList implements JavaScriptIndexingBehavior, List<File> native "*FileList" {

  @DomName('FileList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  File operator[](int index) => JS("File", "#[#]", this, index);

  void operator[]=(int index, File value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<File> mixins.
  // File is the element type.

  // From Iterable<File>:

  Iterator<File> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<File>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, File)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(File element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(File element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(File element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<File> where(bool f(File element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(File element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(File element)) => IterableMixinWorkaround.any(this, f);

  List<File> toList() => new List<File>.from(this);
  Set<File> toSet() => new Set<File>.from(this);

  bool get isEmpty => this.length == 0;

  List<File> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<File> takeWhile(bool test(File value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<File> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<File> skipWhile(bool test(File value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  File firstMatching(bool test(File value), { File orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  File lastMatching(bool test(File value), {File orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  File singleMatching(bool test(File value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  File elementAt(int index) {
    return this[index];
  }

  // From Collection<File>:

  void add(File value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(File value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<File> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<File>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<File> get reversed =>
      new ReversedListView<File>(this, 0, null);

  void sort([int compare(File a, File b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(File element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(File element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  File get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  File get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  File get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  File min([int compare(File a, File b)]) =>
      IterableMixinWorkaround.min(this, compare);

  File max([int compare(File a, File b)]) =>
      IterableMixinWorkaround.max(this, compare);

  File removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  File removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(File element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(File element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<File> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [File initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<File> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <File>[]);

  // -- end List<File> mixins.

  @DomName('FileList.item')
  @DocsEditable
  File item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('FileReader')
class FileReader extends EventTarget native "*FileReader" {

  @DomName('FileReader.abort')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> abortEvent = const EventStreamProvider<ProgressEvent>('abort');

  @DomName('FileReader.error')
  @DocsEditable
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DomName('FileReader.load')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> loadEvent = const EventStreamProvider<ProgressEvent>('load');

  @DomName('FileReader.loadend')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> loadEndEvent = const EventStreamProvider<ProgressEvent>('loadend');

  @DomName('FileReader.loadstart')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> loadStartEvent = const EventStreamProvider<ProgressEvent>('loadstart');

  @DomName('FileReader.progress')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> progressEvent = const EventStreamProvider<ProgressEvent>('progress');

  @DocsEditable
  factory FileReader() => FileReader._create();
  static FileReader _create() => JS('FileReader', 'new FileReader()');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  FileReaderEvents get on =>
    new FileReaderEvents(this);

  static const int DONE = 2;

  static const int EMPTY = 0;

  static const int LOADING = 1;

  @DomName('FileReader.error')
  @DocsEditable
  final FileError error;

  @DomName('FileReader.readyState')
  @DocsEditable
  final int readyState;

  @DomName('FileReader.result')
  @DocsEditable
  @Creates('String|ArrayBuffer|Null')
  final Object result;

  @DomName('FileReader.abort')
  @DocsEditable
  void abort() native;

  @JSName('addEventListener')
  @DomName('FileReader.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('FileReader.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native;

  @DomName('FileReader.readAsArrayBuffer')
  @DocsEditable
  void readAsArrayBuffer(Blob blob) native;

  @DomName('FileReader.readAsBinaryString')
  @DocsEditable
  void readAsBinaryString(Blob blob) native;

  @JSName('readAsDataURL')
  @DomName('FileReader.readAsDataURL')
  @DocsEditable
  void readAsDataUrl(Blob blob) native;

  @DomName('FileReader.readAsText')
  @DocsEditable
  void readAsText(Blob blob, [String encoding]) native;

  @JSName('removeEventListener')
  @DomName('FileReader.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('FileReader.abort')
  @DocsEditable
  Stream<ProgressEvent> get onAbort => abortEvent.forTarget(this);

  @DomName('FileReader.error')
  @DocsEditable
  Stream<Event> get onError => errorEvent.forTarget(this);

  @DomName('FileReader.load')
  @DocsEditable
  Stream<ProgressEvent> get onLoad => loadEvent.forTarget(this);

  @DomName('FileReader.loadend')
  @DocsEditable
  Stream<ProgressEvent> get onLoadEnd => loadEndEvent.forTarget(this);

  @DomName('FileReader.loadstart')
  @DocsEditable
  Stream<ProgressEvent> get onLoadStart => loadStartEvent.forTarget(this);

  @DomName('FileReader.progress')
  @DocsEditable
  Stream<ProgressEvent> get onProgress => progressEvent.forTarget(this);
}

@DocsEditable
@deprecated
class FileReaderEvents extends Events {
  @DocsEditable
  FileReaderEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get abort => this['abort'];

  @DocsEditable
  EventListenerList get error => this['error'];

  @DocsEditable
  EventListenerList get load => this['load'];

  @DocsEditable
  EventListenerList get loadEnd => this['loadend'];

  @DocsEditable
  EventListenerList get loadStart => this['loadstart'];

  @DocsEditable
  EventListenerList get progress => this['progress'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('FileReaderSync')
class FileReaderSync native "*FileReaderSync" {

  @DocsEditable
  factory FileReaderSync() => FileReaderSync._create();
  static FileReaderSync _create() => JS('FileReaderSync', 'new FileReaderSync()');

  @DomName('FileReaderSync.readAsArrayBuffer')
  @DocsEditable
  ArrayBuffer readAsArrayBuffer(Blob blob) native;

  @DomName('FileReaderSync.readAsBinaryString')
  @DocsEditable
  String readAsBinaryString(Blob blob) native;

  @JSName('readAsDataURL')
  @DomName('FileReaderSync.readAsDataURL')
  @DocsEditable
  String readAsDataUrl(Blob blob) native;

  @DomName('FileReaderSync.readAsText')
  @DocsEditable
  String readAsText(Blob blob, [String encoding]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DOMFileSystem')
class FileSystem native "*DOMFileSystem" {

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.webkitRequestFileSystem)');

  @DomName('DOMFileSystem.name')
  @DocsEditable
  final String name;

  @DomName('DOMFileSystem.root')
  @DocsEditable
  final DirectoryEntry root;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void FileSystemCallback(FileSystem fileSystem);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DOMFileSystemSync')
class FileSystemSync native "*DOMFileSystemSync" {

  @DomName('DOMFileSystemSync.name')
  @DocsEditable
  final String name;

  @DomName('DOMFileSystemSync.root')
  @DocsEditable
  final DirectoryEntrySync root;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('FileWriter')
class FileWriter extends EventTarget native "*FileWriter" {

  @DomName('FileWriter.abort')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> abortEvent = const EventStreamProvider<ProgressEvent>('abort');

  @DomName('FileWriter.error')
  @DocsEditable
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DomName('FileWriter.progress')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> progressEvent = const EventStreamProvider<ProgressEvent>('progress');

  @DomName('FileWriter.write')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> writeEvent = const EventStreamProvider<ProgressEvent>('write');

  @DomName('FileWriter.writeend')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> writeEndEvent = const EventStreamProvider<ProgressEvent>('writeend');

  @DomName('FileWriter.writestart')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> writeStartEvent = const EventStreamProvider<ProgressEvent>('writestart');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  FileWriterEvents get on =>
    new FileWriterEvents(this);

  static const int DONE = 2;

  static const int INIT = 0;

  static const int WRITING = 1;

  @DomName('FileWriter.error')
  @DocsEditable
  final FileError error;

  @DomName('FileWriter.length')
  @DocsEditable
  final int length;

  @DomName('FileWriter.position')
  @DocsEditable
  final int position;

  @DomName('FileWriter.readyState')
  @DocsEditable
  final int readyState;

  @DomName('FileWriter.abort')
  @DocsEditable
  void abort() native;

  @JSName('addEventListener')
  @DomName('FileWriter.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('FileWriter.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native;

  @JSName('removeEventListener')
  @DomName('FileWriter.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('FileWriter.seek')
  @DocsEditable
  void seek(int position) native;

  @DomName('FileWriter.truncate')
  @DocsEditable
  void truncate(int size) native;

  @DomName('FileWriter.write')
  @DocsEditable
  void write(Blob data) native;

  @DomName('FileWriter.abort')
  @DocsEditable
  Stream<ProgressEvent> get onAbort => abortEvent.forTarget(this);

  @DomName('FileWriter.error')
  @DocsEditable
  Stream<Event> get onError => errorEvent.forTarget(this);

  @DomName('FileWriter.progress')
  @DocsEditable
  Stream<ProgressEvent> get onProgress => progressEvent.forTarget(this);

  @DomName('FileWriter.write')
  @DocsEditable
  Stream<ProgressEvent> get onWrite => writeEvent.forTarget(this);

  @DomName('FileWriter.writeend')
  @DocsEditable
  Stream<ProgressEvent> get onWriteEnd => writeEndEvent.forTarget(this);

  @DomName('FileWriter.writestart')
  @DocsEditable
  Stream<ProgressEvent> get onWriteStart => writeStartEvent.forTarget(this);
}

@DocsEditable
@deprecated
class FileWriterEvents extends Events {
  @DocsEditable
  FileWriterEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get abort => this['abort'];

  @DocsEditable
  EventListenerList get error => this['error'];

  @DocsEditable
  EventListenerList get progress => this['progress'];

  @DocsEditable
  EventListenerList get write => this['write'];

  @DocsEditable
  EventListenerList get writeEnd => this['writeend'];

  @DocsEditable
  EventListenerList get writeStart => this['writestart'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void FileWriterCallback(FileWriter fileWriter);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('FileWriterSync')
class FileWriterSync native "*FileWriterSync" {

  @DomName('FileWriterSync.length')
  @DocsEditable
  final int length;

  @DomName('FileWriterSync.position')
  @DocsEditable
  final int position;

  @DomName('FileWriterSync.seek')
  @DocsEditable
  void seek(int position) native;

  @DomName('FileWriterSync.truncate')
  @DocsEditable
  void truncate(int size) native;

  @DomName('FileWriterSync.write')
  @DocsEditable
  void write(Blob data) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Float32Array')
class Float32Array extends ArrayBufferView implements JavaScriptIndexingBehavior, List<num> native "*Float32Array" {

  factory Float32Array(int length) =>
    _TypedArrayFactoryProvider.createFloat32Array(length);

  factory Float32Array.fromList(List<num> list) =>
    _TypedArrayFactoryProvider.createFloat32Array_fromList(list);

  factory Float32Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createFloat32Array_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 4;

  @DomName('Float32Array.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  num operator[](int index) => JS("num", "#[#]", this, index);

  void operator[]=(int index, num value) { JS("void", "#[#] = #", this, index, value); }  // -- start List<num> mixins.
  // num is the element type.

  // From Iterable<num>:

  Iterator<num> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<num>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, num)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(num element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(num element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(num element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<num> where(bool f(num element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(num element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(num element)) => IterableMixinWorkaround.any(this, f);

  List<num> toList() => new List<num>.from(this);
  Set<num> toSet() => new Set<num>.from(this);

  bool get isEmpty => this.length == 0;

  List<num> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<num> takeWhile(bool test(num value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<num> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<num> skipWhile(bool test(num value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  num firstMatching(bool test(num value), { num orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  num lastMatching(bool test(num value), {num orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  num singleMatching(bool test(num value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  num elementAt(int index) {
    return this[index];
  }

  // From Collection<num>:

  void add(num value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(num value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<num> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<num>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<num> get reversed =>
      new ReversedListView<num>(this, 0, null);

  void sort([int compare(num a, num b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(num element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(num element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  num get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  num get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  num get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  num min([int compare(num a, num b)]) =>
      IterableMixinWorkaround.min(this, compare);

  num max([int compare(num a, num b)]) =>
      IterableMixinWorkaround.max(this, compare);

  num removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  num removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(num element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(num element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<num> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [num initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<num> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <num>[]);

  // -- end List<num> mixins.

  @JSName('set')
  @DomName('Float32Array.set')
  @DocsEditable
  void setElements(Object array, [int offset]) native;

  @DomName('Float32Array.subarray')
  @DocsEditable
  Float32Array subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Float64Array')
class Float64Array extends ArrayBufferView implements JavaScriptIndexingBehavior, List<num> native "*Float64Array" {

  factory Float64Array(int length) =>
    _TypedArrayFactoryProvider.createFloat64Array(length);

  factory Float64Array.fromList(List<num> list) =>
    _TypedArrayFactoryProvider.createFloat64Array_fromList(list);

  factory Float64Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createFloat64Array_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 8;

  @DomName('Float64Array.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  num operator[](int index) => JS("num", "#[#]", this, index);

  void operator[]=(int index, num value) { JS("void", "#[#] = #", this, index, value); }  // -- start List<num> mixins.
  // num is the element type.

  // From Iterable<num>:

  Iterator<num> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<num>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, num)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(num element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(num element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(num element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<num> where(bool f(num element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(num element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(num element)) => IterableMixinWorkaround.any(this, f);

  List<num> toList() => new List<num>.from(this);
  Set<num> toSet() => new Set<num>.from(this);

  bool get isEmpty => this.length == 0;

  List<num> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<num> takeWhile(bool test(num value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<num> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<num> skipWhile(bool test(num value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  num firstMatching(bool test(num value), { num orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  num lastMatching(bool test(num value), {num orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  num singleMatching(bool test(num value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  num elementAt(int index) {
    return this[index];
  }

  // From Collection<num>:

  void add(num value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(num value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<num> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<num>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<num> get reversed =>
      new ReversedListView<num>(this, 0, null);

  void sort([int compare(num a, num b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(num element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(num element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  num get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  num get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  num get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  num min([int compare(num a, num b)]) =>
      IterableMixinWorkaround.min(this, compare);

  num max([int compare(num a, num b)]) =>
      IterableMixinWorkaround.max(this, compare);

  num removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  num removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(num element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(num element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<num> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [num initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<num> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <num>[]);

  // -- end List<num> mixins.

  @JSName('set')
  @DomName('Float64Array.set')
  @DocsEditable
  void setElements(Object array, [int offset]) native;

  @DomName('Float64Array.subarray')
  @DocsEditable
  Float64Array subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('FormData')
class FormData native "*FormData" {

  @DocsEditable
  factory FormData([FormElement form]) {
    if (!?form) {
      return FormData._create();
    }
    return FormData._create(form);
  }
  static FormData _create([FormElement form]) {
    if (!?form) {
      return JS('FormData', 'new FormData()');
    }
    return JS('FormData', 'new FormData(#)', form);
  }

  @DomName('DOMFormData.append')
  @DocsEditable
  void append(String name, value, [String filename]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLFormElement')
class FormElement extends Element native "*HTMLFormElement" {

  @DocsEditable
  factory FormElement() => document.$dom_createElement("form");

  @DomName('HTMLFormElement.acceptCharset')
  @DocsEditable
  String acceptCharset;

  @DomName('HTMLFormElement.action')
  @DocsEditable
  String action;

  @DomName('HTMLFormElement.autocomplete')
  @DocsEditable
  String autocomplete;

  @DomName('HTMLFormElement.encoding')
  @DocsEditable
  String encoding;

  @DomName('HTMLFormElement.enctype')
  @DocsEditable
  String enctype;

  @DomName('HTMLFormElement.length')
  @DocsEditable
  final int length;

  @DomName('HTMLFormElement.method')
  @DocsEditable
  String method;

  @DomName('HTMLFormElement.name')
  @DocsEditable
  String name;

  @DomName('HTMLFormElement.noValidate')
  @DocsEditable
  bool noValidate;

  @DomName('HTMLFormElement.target')
  @DocsEditable
  String target;

  @DomName('HTMLFormElement.checkValidity')
  @DocsEditable
  bool checkValidity() native;

  @DomName('HTMLFormElement.reset')
  @DocsEditable
  void reset() native;

  @DomName('HTMLFormElement.submit')
  @DocsEditable
  void submit() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Gamepad')
class Gamepad native "*Gamepad" {

  @DomName('Gamepad.axes')
  @DocsEditable
  final List<num> axes;

  @DomName('Gamepad.buttons')
  @DocsEditable
  final List<num> buttons;

  @DomName('Gamepad.id')
  @DocsEditable
  final String id;

  @DomName('Gamepad.index')
  @DocsEditable
  final int index;

  @DomName('Gamepad.timestamp')
  @DocsEditable
  final int timestamp;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Geolocation')
class Geolocation native "*Geolocation" {

  @DomName('Geolocation.clearWatch')
  @DocsEditable
  void clearWatch(int watchId) native;

  @DomName('Geolocation.getCurrentPosition')
  @DocsEditable
  void getCurrentPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback, Object options]) native;

  @DomName('Geolocation.watchPosition')
  @DocsEditable
  int watchPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback, Object options]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Geoposition')
class Geoposition native "*Geoposition" {

  @DomName('Geoposition.coords')
  @DocsEditable
  final Coordinates coords;

  @DomName('Geoposition.timestamp')
  @DocsEditable
  final int timestamp;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLHRElement')
class HRElement extends Element native "*HTMLHRElement" {

  @DocsEditable
  factory HRElement() => document.$dom_createElement("hr");
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DomName('HashChangeEvent')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)

class HashChangeEvent extends Event native "*HashChangeEvent" {
  factory HashChangeEvent(String type,
      {bool canBubble: true, bool cancelable: true, String oldUrl,
      String newUrl}) {
    var event = document.$dom_createEvent("HashChangeEvent");
    event.$dom_initHashChangeEvent(type, canBubble, cancelable, oldUrl, newUrl);
    return event;
  }

  /// Checks if this type is supported on the current platform.
  static bool get supported => Event._isTypeSupported('HashChangeEvent');

  @JSName('newURL')
  @DomName('HashChangeEvent.newURL')
  @DocsEditable
  final String newUrl;

  @JSName('oldURL')
  @DomName('HashChangeEvent.oldURL')
  @DocsEditable
  final String oldUrl;

  @JSName('initHashChangeEvent')
  @DomName('HashChangeEvent.initHashChangeEvent')
  @DocsEditable
  void $dom_initHashChangeEvent(String type, bool canBubble, bool cancelable, String oldURL, String newURL) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLHeadElement')
class HeadElement extends Element native "*HTMLHeadElement" {

  @DocsEditable
  factory HeadElement() => document.$dom_createElement("head");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLHeadingElement')
class HeadingElement extends Element native "*HTMLHeadingElement" {

  @DocsEditable
  factory HeadingElement.h1() => document.$dom_createElement("h1");

  @DocsEditable
  factory HeadingElement.h2() => document.$dom_createElement("h2");

  @DocsEditable
  factory HeadingElement.h3() => document.$dom_createElement("h3");

  @DocsEditable
  factory HeadingElement.h4() => document.$dom_createElement("h4");

  @DocsEditable
  factory HeadingElement.h5() => document.$dom_createElement("h5");

  @DocsEditable
  factory HeadingElement.h6() => document.$dom_createElement("h6");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('History')
class History implements HistoryBase native "*History" {

  /**
   * Checks if the State APIs are supported on the current platform.
   *
   * See also:
   *
   * * [pushState]
   * * [replaceState]
   * * [state]
   */
  static bool get supportsState => JS('bool', '!!window.history.pushState');

  @DomName('History.length')
  @DocsEditable
  final int length;

  dynamic get state => _convertNativeToDart_SerializedScriptValue(this._state);
  @JSName('state')
  @DomName('History.state')
  @DocsEditable
  @annotation_Creates_SerializedScriptValue
  @annotation_Returns_SerializedScriptValue
  final dynamic _state;

  @DomName('History.back')
  @DocsEditable
  void back() native;

  @DomName('History.forward')
  @DocsEditable
  void forward() native;

  @DomName('History.go')
  @DocsEditable
  void go(int distance) native;

  @DomName('History.pushState')
  @DocsEditable
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.IE, '10')
  @SupportedBrowser(SupportedBrowser.SAFARI)
  void pushState(Object data, String title, [String url]) native;

  @DomName('History.replaceState')
  @DocsEditable
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.IE, '10')
  @SupportedBrowser(SupportedBrowser.SAFARI)
  void replaceState(Object data, String title, [String url]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLAllCollection')
class HtmlAllCollection implements JavaScriptIndexingBehavior, List<Node> native "*HTMLAllCollection" {

  @DomName('HTMLAllCollection.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  Node operator[](int index) => JS("Node", "#[#]", this, index);

  void operator[]=(int index, Node value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Node> mixins.
  // Node is the element type.

  // From Iterable<Node>:

  Iterator<Node> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Node>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, Node)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(Node element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(Node element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(Node element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<Node> where(bool f(Node element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(Node element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(Node element)) => IterableMixinWorkaround.any(this, f);

  List<Node> toList() => new List<Node>.from(this);
  Set<Node> toSet() => new Set<Node>.from(this);

  bool get isEmpty => this.length == 0;

  List<Node> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<Node> takeWhile(bool test(Node value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<Node> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<Node> skipWhile(bool test(Node value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  Node firstMatching(bool test(Node value), { Node orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  Node lastMatching(bool test(Node value), {Node orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  Node singleMatching(bool test(Node value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  Node elementAt(int index) {
    return this[index];
  }

  // From Collection<Node>:

  void add(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<Node> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<Node>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<Node> get reversed =>
      new ReversedListView<Node>(this, 0, null);

  void sort([int compare(Node a, Node b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Node element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Node element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  Node get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  Node get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  Node get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Node min([int compare(Node a, Node b)]) =>
      IterableMixinWorkaround.min(this, compare);

  Node max([int compare(Node a, Node b)]) =>
      IterableMixinWorkaround.max(this, compare);

  Node removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  Node removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(Node element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(Node element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<Node> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Node initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Node> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <Node>[]);

  // -- end List<Node> mixins.

  @DomName('HTMLAllCollection.item')
  @DocsEditable
  Node item(int index) native;

  @DomName('HTMLAllCollection.namedItem')
  @DocsEditable
  Node namedItem(String name) native;

  @DomName('HTMLAllCollection.tags')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> tags(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLCollection')
class HtmlCollection implements JavaScriptIndexingBehavior, List<Node> native "*HTMLCollection" {

  @DomName('HTMLCollection.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  Node operator[](int index) => JS("Node", "#[#]", this, index);

  void operator[]=(int index, Node value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Node> mixins.
  // Node is the element type.

  // From Iterable<Node>:

  Iterator<Node> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Node>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, Node)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(Node element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(Node element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(Node element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<Node> where(bool f(Node element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(Node element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(Node element)) => IterableMixinWorkaround.any(this, f);

  List<Node> toList() => new List<Node>.from(this);
  Set<Node> toSet() => new Set<Node>.from(this);

  bool get isEmpty => this.length == 0;

  List<Node> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<Node> takeWhile(bool test(Node value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<Node> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<Node> skipWhile(bool test(Node value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  Node firstMatching(bool test(Node value), { Node orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  Node lastMatching(bool test(Node value), {Node orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  Node singleMatching(bool test(Node value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  Node elementAt(int index) {
    return this[index];
  }

  // From Collection<Node>:

  void add(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<Node> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<Node>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<Node> get reversed =>
      new ReversedListView<Node>(this, 0, null);

  void sort([int compare(Node a, Node b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Node element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Node element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  Node get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  Node get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  Node get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Node min([int compare(Node a, Node b)]) =>
      IterableMixinWorkaround.min(this, compare);

  Node max([int compare(Node a, Node b)]) =>
      IterableMixinWorkaround.max(this, compare);

  Node removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  Node removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(Node element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(Node element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<Node> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Node initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Node> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <Node>[]);

  // -- end List<Node> mixins.

  @DomName('HTMLCollection.item')
  @DocsEditable
  Node item(int index) native;

  @DomName('HTMLCollection.namedItem')
  @DocsEditable
  Node namedItem(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('HTMLDocument')
class HtmlDocument extends Document native "*HTMLDocument" {

  @DomName('HTMLDocument.activeElement')
  @DocsEditable
  final Element activeElement;

  @DomName('Document.body')
  BodyElement get body => document.$dom_body;

  @DomName('Document.body')
  void set body(BodyElement value) {
    document.$dom_body = value;
  }

  @DomName('Document.caretRangeFromPoint')
  Range caretRangeFromPoint(int x, int y) {
    return document.$dom_caretRangeFromPoint(x, y);
  }

  @DomName('Document.elementFromPoint')
  Element elementFromPoint(int x, int y) {
    return document.$dom_elementFromPoint(x, y);
  }

  /**
   * Checks if the getCssCanvasContext API is supported on the current platform.
   *
   * See also:
   *
   * * [getCssCanvasContext]
   */
  static bool get supportsCssCanvasContext =>
      JS('bool', '!!(document.getCSSCanvasContext)');


  /**
   * Gets a CanvasRenderingContext which can be used as the CSS background of an
   * element.
   *
   * CSS:
   *
   *     background: -webkit-canvas(backgroundCanvas)
   *
   * Generate the canvas:
   *
   *     var context = document.getCssCanvasContext('2d', 'backgroundCanvas',
   *         100, 100);
   *     context.fillStyle = 'red';
   *     context.fillRect(0, 0, 100, 100);
   *
   * See also:
   *
   * * [supportsCssCanvasContext]
   * * [CanvasElement.getContext]
   */
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental
  @DomName('Document.getCSSCanvasContext')
  CanvasRenderingContext getCssCanvasContext(String contextId, String name,
      int width, int height) {
    return document.$dom_getCssCanvasContext(contextId, name, width, height);
  }

  @DomName('Document.head')
  HeadElement get head => document.$dom_head;

  @DomName('Document.lastModified')
  String get lastModified => document.$dom_lastModified;

  @DomName('Document.preferredStylesheetSet')
  String get preferredStylesheetSet => document.$dom_preferredStylesheetSet;

  @DomName('Document.referrer')
  String get referrer => document.$dom_referrer;

  @DomName('Document.selectedStylesheetSet')
  String get selectedStylesheetSet => document.$dom_selectedStylesheetSet;
  void set selectedStylesheetSet(String value) {
    document.$dom_selectedStylesheetSet = value;
  }

  @DomName('Document.styleSheets')
  List<StyleSheet> get styleSheets => document.$dom_styleSheets;

  @DomName('Document.title')
  String get title => document.$dom_title;

  @DomName('Document.title')
  void set title(String value) {
    document.$dom_title = value;
  }

  @DomName('Document.webkitCancelFullScreen')
  void webkitCancelFullScreen() {
    document.$dom_webkitCancelFullScreen();
  }

  @DomName('Document.webkitExitFullscreen')
  void webkitExitFullscreen() {
    document.$dom_webkitExitFullscreen();
  }

  @DomName('Document.webkitExitPointerLock')
  void webkitExitPointerLock() {
    document.$dom_webkitExitPointerLock();
  }

  @DomName('Document.webkitFullscreenElement')
  Element get webkitFullscreenElement => document.$dom_webkitFullscreenElement;

  @DomName('Document.webkitFullscreenEnabled')
  bool get webkitFullscreenEnabled => document.$dom_webkitFullscreenEnabled;

  @DomName('Document.webkitHidden')
  bool get webkitHidden => document.$dom_webkitHidden;

  @DomName('Document.webkitIsFullScreen')
  bool get webkitIsFullScreen => document.$dom_webkitIsFullScreen;

  @DomName('Document.webkitPointerLockElement')
  Element get webkitPointerLockElement =>
      document.$dom_webkitPointerLockElement;

  @DomName('Document.webkitVisibilityState')
  String get webkitVisibilityState => document.$dom_webkitVisibilityState;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLHtmlElement')
class HtmlElement extends Element native "*HTMLHtmlElement" {

  @DocsEditable
  factory HtmlElement() => document.$dom_createElement("html");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLFormControlsCollection')
class HtmlFormControlsCollection extends HtmlCollection native "*HTMLFormControlsCollection" {

  @DomName('HTMLFormControlsCollection.namedItem')
  @DocsEditable
  Node namedItem(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLOptionsCollection')
class HtmlOptionsCollection extends HtmlCollection native "*HTMLOptionsCollection" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * A utility for retrieving data from a URL.
 *
 * HttpRequest can be used to obtain data from http, ftp, and file
 * protocols.
 *
 * For example, suppose we're developing these API docs, and we
 * wish to retrieve the HTML of the top-level page and print it out.
 * The easiest way to do that would be:
 *
 *     var httpRequest = HttpRequest.get('http://api.dartlang.org',
 *         (request) => print(request.responseText));
 *
 * **Important**: With the default behavior of this class, your
 * code making the request should be served from the same origin (domain name,
 * port, and application layer protocol) as the URL you are trying to access
 * with HttpRequest. However, there are ways to
 * [get around this restriction](http://www.dartlang.org/articles/json-web-service/#note-on-jsonp).
 *
 * See also:
 *
 * * [Dart article on using HttpRequests](http://www.dartlang.org/articles/json-web-service/#getting-data)
 * * [JS XMLHttpRequest](https://developer.mozilla.org/en-US/docs/DOM/XMLHttpRequest)
 * * [Using XMLHttpRequest](https://developer.mozilla.org/en-US/docs/DOM/XMLHttpRequest/Using_XMLHttpRequest)
 */
@DomName('XMLHttpRequest')
class HttpRequest extends EventTarget native "*XMLHttpRequest" {
  /**
   * Creates a URL get request for the specified `url`.
   *
   * After completing the request, the object will call the user-provided
   * [onComplete] callback.
   */
  factory HttpRequest.get(String url, onComplete(HttpRequest request)) =>
      _HttpRequestUtils.get(url, onComplete, false);

  // 80 char issue for comments in lists: dartbug.com/7588.
  /**
   * Creates a URL GET request for the specified `url` with
   * credentials such a cookie (already) set in the header or
   * [authorization headers](http://tools.ietf.org/html/rfc1945#section-10.2).
   *
   * After completing the request, the object will call the user-provided
   * [onComplete] callback.
   *
   * A few other details to keep in mind when using credentials:
   *
   * * Using credentials is only useful for cross-origin requests.
   * * The `Access-Control-Allow-Origin` header of `url` cannot contain a wildcard (*).
   * * The `Access-Control-Allow-Credentials` header of `url` must be set to true.
   * * If `Access-Control-Expose-Headers` has not been set to true, only a subset of all the response headers will be returned when calling [getAllRequestHeaders].
   *
   * See also: [authorization headers](http://en.wikipedia.org/wiki/Basic_access_authentication).
   */
  factory HttpRequest.getWithCredentials(String url,
      onComplete(HttpRequest request)) =>
      _HttpRequestUtils.get(url, onComplete, true);


  @DomName('XMLHttpRequest.abort')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> abortEvent = const EventStreamProvider<ProgressEvent>('abort');

  @DomName('XMLHttpRequest.error')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> errorEvent = const EventStreamProvider<ProgressEvent>('error');

  @DomName('XMLHttpRequest.load')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> loadEvent = const EventStreamProvider<ProgressEvent>('load');

  @DomName('XMLHttpRequest.loadend')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> loadEndEvent = const EventStreamProvider<ProgressEvent>('loadend');

  @DomName('XMLHttpRequest.loadstart')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> loadStartEvent = const EventStreamProvider<ProgressEvent>('loadstart');

  @DomName('XMLHttpRequest.progress')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> progressEvent = const EventStreamProvider<ProgressEvent>('progress');

  @DomName('XMLHttpRequest.readystatechange')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> readyStateChangeEvent = const EventStreamProvider<ProgressEvent>('readystatechange');

  @DocsEditable
  factory HttpRequest() => HttpRequest._create();
  static HttpRequest _create() => JS('HttpRequest', 'new XMLHttpRequest()');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  HttpRequestEvents get on =>
    new HttpRequestEvents(this);

  static const int DONE = 4;

  static const int HEADERS_RECEIVED = 2;

  static const int LOADING = 3;

  static const int OPENED = 1;

  static const int UNSENT = 0;

  @DomName('XMLHttpRequest.readyState')
  @DocsEditable
  final int readyState;

  @DomName('XMLHttpRequest.response')
  @DocsEditable
  @Creates('ArrayBuffer|Blob|Document|=Object|=List|String|num')
  final Object response;

  @DomName('XMLHttpRequest.responseText')
  @DocsEditable
  final String responseText;

  @DomName('XMLHttpRequest.responseType')
  @DocsEditable
  String responseType;

  @JSName('responseXML')
  @DomName('XMLHttpRequest.responseXML')
  @DocsEditable
  final Document responseXml;

  @DomName('XMLHttpRequest.status')
  @DocsEditable
  final int status;

  @DomName('XMLHttpRequest.statusText')
  @DocsEditable
  final String statusText;

  @DomName('XMLHttpRequest.upload')
  @DocsEditable
  final HttpRequestUpload upload;

  @DomName('XMLHttpRequest.withCredentials')
  @DocsEditable
  bool withCredentials;

  @DomName('XMLHttpRequest.abort')
  @DocsEditable
  void abort() native;

  @JSName('addEventListener')
  @DomName('XMLHttpRequest.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('XMLHttpRequest.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native;

  @DomName('XMLHttpRequest.getAllResponseHeaders')
  @DocsEditable
  String getAllResponseHeaders() native;

  @DomName('XMLHttpRequest.getResponseHeader')
  @DocsEditable
  String getResponseHeader(String header) native;

  @DomName('XMLHttpRequest.open')
  @DocsEditable
  void open(String method, String url, [bool async, String user, String password]) native;

  @DomName('XMLHttpRequest.overrideMimeType')
  @DocsEditable
  void overrideMimeType(String override) native;

  @JSName('removeEventListener')
  @DomName('XMLHttpRequest.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('XMLHttpRequest.send')
  @DocsEditable
  void send([data]) native;

  @DomName('XMLHttpRequest.setRequestHeader')
  @DocsEditable
  void setRequestHeader(String header, String value) native;

  @DomName('XMLHttpRequest.abort')
  @DocsEditable
  Stream<ProgressEvent> get onAbort => abortEvent.forTarget(this);

  @DomName('XMLHttpRequest.error')
  @DocsEditable
  Stream<ProgressEvent> get onError => errorEvent.forTarget(this);

  @DomName('XMLHttpRequest.load')
  @DocsEditable
  Stream<ProgressEvent> get onLoad => loadEvent.forTarget(this);

  @DomName('XMLHttpRequest.loadend')
  @DocsEditable
  Stream<ProgressEvent> get onLoadEnd => loadEndEvent.forTarget(this);

  @DomName('XMLHttpRequest.loadstart')
  @DocsEditable
  Stream<ProgressEvent> get onLoadStart => loadStartEvent.forTarget(this);

  @DomName('XMLHttpRequest.progress')
  @DocsEditable
  Stream<ProgressEvent> get onProgress => progressEvent.forTarget(this);

  @DomName('XMLHttpRequest.readystatechange')
  @DocsEditable
  Stream<ProgressEvent> get onReadyStateChange => readyStateChangeEvent.forTarget(this);

}

@DocsEditable
@deprecated
class HttpRequestEvents extends Events {
  @DocsEditable
  HttpRequestEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get abort => this['abort'];

  @DocsEditable
  EventListenerList get error => this['error'];

  @DocsEditable
  EventListenerList get load => this['load'];

  @DocsEditable
  EventListenerList get loadEnd => this['loadend'];

  @DocsEditable
  EventListenerList get loadStart => this['loadstart'];

  @DocsEditable
  EventListenerList get progress => this['progress'];

  @DocsEditable
  EventListenerList get readyStateChange => this['readystatechange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('XMLHttpRequestException')
class HttpRequestException native "*XMLHttpRequestException" {

  static const int ABORT_ERR = 102;

  static const int NETWORK_ERR = 101;

  @DomName('XMLHttpRequestException.code')
  @DocsEditable
  final int code;

  @DomName('XMLHttpRequestException.message')
  @DocsEditable
  final String message;

  @DomName('XMLHttpRequestException.name')
  @DocsEditable
  final String name;

  @DomName('XMLHttpRequestException.toString')
  @DocsEditable
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('XMLHttpRequestProgressEvent')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class HttpRequestProgressEvent extends ProgressEvent native "*XMLHttpRequestProgressEvent" {

  /// Checks if this type is supported on the current platform.
  static bool get supported => Event._isTypeSupported('XMLHttpRequestProgressEvent');

  @DomName('XMLHttpRequestProgressEvent.position')
  @DocsEditable
  final int position;

  @DomName('XMLHttpRequestProgressEvent.totalSize')
  @DocsEditable
  final int totalSize;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('XMLHttpRequestUpload')
class HttpRequestUpload extends EventTarget native "*XMLHttpRequestUpload" {

  @DomName('XMLHttpRequestUpload.abort')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> abortEvent = const EventStreamProvider<ProgressEvent>('abort');

  @DomName('XMLHttpRequestUpload.error')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> errorEvent = const EventStreamProvider<ProgressEvent>('error');

  @DomName('XMLHttpRequestUpload.load')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> loadEvent = const EventStreamProvider<ProgressEvent>('load');

  @DomName('XMLHttpRequestUpload.loadend')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> loadEndEvent = const EventStreamProvider<ProgressEvent>('loadend');

  @DomName('XMLHttpRequestUpload.loadstart')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> loadStartEvent = const EventStreamProvider<ProgressEvent>('loadstart');

  @DomName('XMLHttpRequestUpload.progress')
  @DocsEditable
  static const EventStreamProvider<ProgressEvent> progressEvent = const EventStreamProvider<ProgressEvent>('progress');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  HttpRequestUploadEvents get on =>
    new HttpRequestUploadEvents(this);

  @JSName('addEventListener')
  @DomName('XMLHttpRequestUpload.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('XMLHttpRequestUpload.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native;

  @JSName('removeEventListener')
  @DomName('XMLHttpRequestUpload.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('XMLHttpRequestUpload.abort')
  @DocsEditable
  Stream<ProgressEvent> get onAbort => abortEvent.forTarget(this);

  @DomName('XMLHttpRequestUpload.error')
  @DocsEditable
  Stream<ProgressEvent> get onError => errorEvent.forTarget(this);

  @DomName('XMLHttpRequestUpload.load')
  @DocsEditable
  Stream<ProgressEvent> get onLoad => loadEvent.forTarget(this);

  @DomName('XMLHttpRequestUpload.loadend')
  @DocsEditable
  Stream<ProgressEvent> get onLoadEnd => loadEndEvent.forTarget(this);

  @DomName('XMLHttpRequestUpload.loadstart')
  @DocsEditable
  Stream<ProgressEvent> get onLoadStart => loadStartEvent.forTarget(this);

  @DomName('XMLHttpRequestUpload.progress')
  @DocsEditable
  Stream<ProgressEvent> get onProgress => progressEvent.forTarget(this);
}

@DocsEditable
@deprecated
class HttpRequestUploadEvents extends Events {
  @DocsEditable
  HttpRequestUploadEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get abort => this['abort'];

  @DocsEditable
  EventListenerList get error => this['error'];

  @DocsEditable
  EventListenerList get load => this['load'];

  @DocsEditable
  EventListenerList get loadEnd => this['loadend'];

  @DocsEditable
  EventListenerList get loadStart => this['loadstart'];

  @DocsEditable
  EventListenerList get progress => this['progress'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLIFrameElement')
class IFrameElement extends Element native "*HTMLIFrameElement" {

  @DocsEditable
  factory IFrameElement() => document.$dom_createElement("iframe");

  WindowBase get contentWindow => _convertNativeToDart_Window(this._contentWindow);
  @JSName('contentWindow')
  @DomName('HTMLIFrameElement.contentWindow')
  @DocsEditable
  @Creates('Window|=Object')
  @Returns('Window|=Object')
  final dynamic _contentWindow;

  @DomName('HTMLIFrameElement.height')
  @DocsEditable
  String height;

  @DomName('HTMLIFrameElement.name')
  @DocsEditable
  String name;

  @DomName('HTMLIFrameElement.sandbox')
  @DocsEditable
  String sandbox;

  @DomName('HTMLIFrameElement.src')
  @DocsEditable
  String src;

  @DomName('HTMLIFrameElement.srcdoc')
  @DocsEditable
  String srcdoc;

  @DomName('HTMLIFrameElement.width')
  @DocsEditable
  String width;
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DomName('ImageData')

class ImageData native "*ImageData" {


  @DomName('ImageData.data')
  @DocsEditable
  final List<int> data;

  @DomName('ImageData.height')
  @DocsEditable
  final int height;

  @DomName('ImageData.width')
  @DocsEditable
  final int width;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLImageElement')
class ImageElement extends Element native "*HTMLImageElement" {

  @DocsEditable
  factory ImageElement({String src, int width, int height}) {
    var e = document.$dom_createElement("img");
    if (src != null) e.src = src;
    if (width != null) e.width = width;
    if (height != null) e.height = height;
    return e;
  }

  @DomName('HTMLImageElement.alt')
  @DocsEditable
  String alt;

  @DomName('HTMLImageElement.border')
  @DocsEditable
  String border;

  @DomName('HTMLImageElement.complete')
  @DocsEditable
  final bool complete;

  @DomName('HTMLImageElement.crossOrigin')
  @DocsEditable
  String crossOrigin;

  @DomName('HTMLImageElement.height')
  @DocsEditable
  int height;

  @DomName('HTMLImageElement.isMap')
  @DocsEditable
  bool isMap;

  @DomName('HTMLImageElement.lowsrc')
  @DocsEditable
  String lowsrc;

  @DomName('HTMLImageElement.naturalHeight')
  @DocsEditable
  final int naturalHeight;

  @DomName('HTMLImageElement.naturalWidth')
  @DocsEditable
  final int naturalWidth;

  @DomName('HTMLImageElement.src')
  @DocsEditable
  String src;

  @DomName('HTMLImageElement.useMap')
  @DocsEditable
  String useMap;

  @DomName('HTMLImageElement.width')
  @DocsEditable
  int width;

  @DomName('HTMLImageElement.x')
  @DocsEditable
  final int x;

  @DomName('HTMLImageElement.y')
  @DocsEditable
  final int y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('HTMLInputElement')
class InputElement extends Element implements
    HiddenInputElement,
    SearchInputElement,
    TextInputElement,
    UrlInputElement,
    TelephoneInputElement,
    EmailInputElement,
    PasswordInputElement,
    DateTimeInputElement,
    DateInputElement,
    MonthInputElement,
    WeekInputElement,
    TimeInputElement,
    LocalDateTimeInputElement,
    NumberInputElement,
    RangeInputElement,
    CheckboxInputElement,
    RadioButtonInputElement,
    FileUploadInputElement,
    SubmitButtonInputElement,
    ImageButtonInputElement,
    ResetButtonInputElement,
    ButtonInputElement
     native "*HTMLInputElement" {

  factory InputElement({String type}) {
    var e = document.$dom_createElement("input");
    if (type != null) {
      try {
        // IE throws an exception for unknown types.
        e.type = type;
      } catch(_) {}
    }
    return e;
  }

  @DomName('HTMLInputElement.webkitSpeechChange')
  @DocsEditable
  static const EventStreamProvider<Event> speechChangeEvent = const EventStreamProvider<Event>('webkitSpeechChange');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  InputElementEvents get on =>
    new InputElementEvents(this);

  @DomName('HTMLInputElement.accept')
  @DocsEditable
  String accept;

  @DomName('HTMLInputElement.alt')
  @DocsEditable
  String alt;

  @DomName('HTMLInputElement.autocomplete')
  @DocsEditable
  String autocomplete;

  @DomName('HTMLInputElement.autofocus')
  @DocsEditable
  bool autofocus;

  @DomName('HTMLInputElement.checked')
  @DocsEditable
  bool checked;

  @DomName('HTMLInputElement.defaultChecked')
  @DocsEditable
  bool defaultChecked;

  @DomName('HTMLInputElement.defaultValue')
  @DocsEditable
  String defaultValue;

  @DomName('HTMLInputElement.dirName')
  @DocsEditable
  String dirName;

  @DomName('HTMLInputElement.disabled')
  @DocsEditable
  bool disabled;

  @DomName('HTMLInputElement.files')
  @DocsEditable
  @Returns('FileList')
  @Creates('FileList')
  List<File> files;

  @DomName('HTMLInputElement.form')
  @DocsEditable
  final FormElement form;

  @DomName('HTMLInputElement.formAction')
  @DocsEditable
  String formAction;

  @DomName('HTMLInputElement.formEnctype')
  @DocsEditable
  String formEnctype;

  @DomName('HTMLInputElement.formMethod')
  @DocsEditable
  String formMethod;

  @DomName('HTMLInputElement.formNoValidate')
  @DocsEditable
  bool formNoValidate;

  @DomName('HTMLInputElement.formTarget')
  @DocsEditable
  String formTarget;

  @DomName('HTMLInputElement.height')
  @DocsEditable
  int height;

  @DomName('HTMLInputElement.incremental')
  @DocsEditable
  bool incremental;

  @DomName('HTMLInputElement.indeterminate')
  @DocsEditable
  bool indeterminate;

  @DomName('HTMLInputElement.labels')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  final List<Node> labels;

  @DomName('HTMLInputElement.list')
  @DocsEditable
  final Element list;

  @DomName('HTMLInputElement.max')
  @DocsEditable
  String max;

  @DomName('HTMLInputElement.maxLength')
  @DocsEditable
  int maxLength;

  @DomName('HTMLInputElement.min')
  @DocsEditable
  String min;

  @DomName('HTMLInputElement.multiple')
  @DocsEditable
  bool multiple;

  @DomName('HTMLInputElement.name')
  @DocsEditable
  String name;

  @DomName('HTMLInputElement.pattern')
  @DocsEditable
  String pattern;

  @DomName('HTMLInputElement.placeholder')
  @DocsEditable
  String placeholder;

  @DomName('HTMLInputElement.readOnly')
  @DocsEditable
  bool readOnly;

  @DomName('HTMLInputElement.required')
  @DocsEditable
  bool required;

  @DomName('HTMLInputElement.selectionDirection')
  @DocsEditable
  String selectionDirection;

  @DomName('HTMLInputElement.selectionEnd')
  @DocsEditable
  int selectionEnd;

  @DomName('HTMLInputElement.selectionStart')
  @DocsEditable
  int selectionStart;

  @DomName('HTMLInputElement.size')
  @DocsEditable
  int size;

  @DomName('HTMLInputElement.src')
  @DocsEditable
  String src;

  @DomName('HTMLInputElement.step')
  @DocsEditable
  String step;

  @DomName('HTMLInputElement.type')
  @DocsEditable
  String type;

  @DomName('HTMLInputElement.useMap')
  @DocsEditable
  String useMap;

  @DomName('HTMLInputElement.validationMessage')
  @DocsEditable
  final String validationMessage;

  @DomName('HTMLInputElement.validity')
  @DocsEditable
  final ValidityState validity;

  @DomName('HTMLInputElement.value')
  @DocsEditable
  String value;

  @DomName('HTMLInputElement.valueAsDate')
  @DocsEditable
  Date valueAsDate;

  @DomName('HTMLInputElement.valueAsNumber')
  @DocsEditable
  num valueAsNumber;

  @DomName('HTMLInputElement.webkitEntries')
  @DocsEditable
  @Returns('_EntryArray')
  @Creates('_EntryArray')
  final List<Entry> webkitEntries;

  @DomName('HTMLInputElement.webkitGrammar')
  @DocsEditable
  bool webkitGrammar;

  @DomName('HTMLInputElement.webkitSpeech')
  @DocsEditable
  bool webkitSpeech;

  @DomName('HTMLInputElement.webkitdirectory')
  @DocsEditable
  bool webkitdirectory;

  @DomName('HTMLInputElement.width')
  @DocsEditable
  int width;

  @DomName('HTMLInputElement.willValidate')
  @DocsEditable
  final bool willValidate;

  @DomName('HTMLInputElement.checkValidity')
  @DocsEditable
  bool checkValidity() native;

  @DomName('HTMLInputElement.select')
  @DocsEditable
  void select() native;

  @DomName('HTMLInputElement.setCustomValidity')
  @DocsEditable
  void setCustomValidity(String error) native;

  @DomName('HTMLInputElement.setRangeText')
  @DocsEditable
  void setRangeText(String replacement, [int start, int end, String selectionMode]) native;

  @DomName('HTMLInputElement.setSelectionRange')
  @DocsEditable
  void setSelectionRange(int start, int end, [String direction]) native;

  @DomName('HTMLInputElement.stepDown')
  @DocsEditable
  void stepDown([int n]) native;

  @DomName('HTMLInputElement.stepUp')
  @DocsEditable
  void stepUp([int n]) native;

  @DomName('HTMLInputElement.webkitSpeechChange')
  @DocsEditable
  Stream<Event> get onSpeechChange => speechChangeEvent.forTarget(this);

}


// Interfaces representing the InputElement APIs which are supported
// for the various types of InputElement.
// From http://dev.w3.org/html5/spec/the-input-element.html#the-input-element.

/**
 * Exposes the functionality common between all InputElement types.
 */
abstract class InputElementBase implements Element {
  @DomName('HTMLInputElement.autofocus')
  bool autofocus;

  @DomName('HTMLInputElement.disabled')
  bool disabled;

  @DomName('HTMLInputElement.incremental')
  bool incremental;

  @DomName('HTMLInputElement.indeterminate')
  bool indeterminate;

  @DomName('HTMLInputElement.labels')
  List<Node> get labels;

  @DomName('HTMLInputElement.name')
  String name;

  @DomName('HTMLInputElement.validationMessage')
  String get validationMessage;

  @DomName('HTMLInputElement.validity')
  ValidityState get validity;

  @DomName('HTMLInputElement.value')
  String value;

  @DomName('HTMLInputElement.willValidate')
  bool get willValidate;

  @DomName('HTMLInputElement.checkValidity')
  bool checkValidity();

  @DomName('HTMLInputElement.setCustomValidity')
  void setCustomValidity(String error);
}

/**
 * Hidden input which is not intended to be seen or edited by the user.
 */
abstract class HiddenInputElement implements Element {
  factory HiddenInputElement() => new InputElement(type: 'hidden');
}


/**
 * Base interface for all inputs which involve text editing.
 */
abstract class TextInputElementBase implements InputElementBase {
  @DomName('HTMLInputElement.autocomplete')
  String autocomplete;

  @DomName('HTMLInputElement.maxLength')
  int maxLength;

  @DomName('HTMLInputElement.pattern')
  String pattern;

  @DomName('HTMLInputElement.placeholder')
  String placeholder;

  @DomName('HTMLInputElement.readOnly')
  bool readOnly;

  @DomName('HTMLInputElement.required')
  bool required;

  @DomName('HTMLInputElement.size')
  int size;

  @DomName('HTMLInputElement.select')
  void select();

  @DomName('HTMLInputElement.selectionDirection')
  String selectionDirection;

  @DomName('HTMLInputElement.selectionEnd')
  int selectionEnd;

  @DomName('HTMLInputElement.selectionStart')
  int selectionStart;

  @DomName('HTMLInputElement.setSelectionRange')
  void setSelectionRange(int start, int end, [String direction]);
}

/**
 * Similar to [TextInputElement], but on platforms where search is styled
 * differently this will get the search style.
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
abstract class SearchInputElement implements TextInputElementBase {
  factory SearchInputElement() => new InputElement(type: 'search');

  @DomName('HTMLInputElement.dirName')
  String dirName;

  @DomName('HTMLInputElement.list')
  Element get list;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'search')).type == 'search';
  }
}

/**
 * A basic text input editor control.
 */
abstract class TextInputElement implements TextInputElementBase {
  factory TextInputElement() => new InputElement(type: 'text');

  @DomName('HTMLInputElement.dirName')
  String dirName;

  @DomName('HTMLInputElement.list')
  Element get list;
}

/**
 * A control for editing an absolute URL.
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
abstract class UrlInputElement implements TextInputElementBase {
  factory UrlInputElement() => new InputElement(type: 'url');

  @DomName('HTMLInputElement.list')
  Element get list;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'url')).type == 'url';
  }
}

/**
 * Represents a control for editing a telephone number.
 *
 * This provides a single line of text with minimal formatting help since
 * there is a wide variety of telephone numbers.
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
abstract class TelephoneInputElement implements TextInputElementBase {
  factory TelephoneInputElement() => new InputElement(type: 'tel');

  @DomName('HTMLInputElement.list')
  Element get list;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'tel')).type == 'tel';
  }
}

/**
 * An e-mail address or list of e-mail addresses.
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
abstract class EmailInputElement implements TextInputElementBase {
  factory EmailInputElement() => new InputElement(type: 'email');

  @DomName('HTMLInputElement.autocomplete')
  String autocomplete;

  @DomName('HTMLInputElement.autofocus')
  bool autofocus;

  @DomName('HTMLInputElement.list')
  Element get list;

  @DomName('HTMLInputElement.maxLength')
  int maxLength;

  @DomName('HTMLInputElement.multiple')
  bool multiple;

  @DomName('HTMLInputElement.pattern')
  String pattern;

  @DomName('HTMLInputElement.placeholder')
  String placeholder;

  @DomName('HTMLInputElement.readOnly')
  bool readOnly;

  @DomName('HTMLInputElement.required')
  bool required;

  @DomName('HTMLInputElement.size')
  int size;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'email')).type == 'email';
  }
}

/**
 * Text with no line breaks (sensitive information).
 */
abstract class PasswordInputElement implements TextInputElementBase {
  factory PasswordInputElement() => new InputElement(type: 'password');
}

/**
 * Base interface for all input element types which involve ranges.
 */
abstract class RangeInputElementBase implements InputElementBase {

  @DomName('HTMLInputElement.list')
  Element get list;

  @DomName('HTMLInputElement.max')
  String max;

  @DomName('HTMLInputElement.min')
  String min;

  @DomName('HTMLInputElement.step')
  String step;

  @DomName('HTMLInputElement.valueAsNumber')
  num valueAsNumber;

  @DomName('HTMLInputElement.stepDown')
  void stepDown([int n]);

  @DomName('HTMLInputElement.stepUp')
  void stepUp([int n]);
}

/**
 * A date and time (year, month, day, hour, minute, second, fraction of a
 * second) with the time zone set to UTC.
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME, '25')
@Experimental
abstract class DateTimeInputElement implements RangeInputElementBase {
  factory DateTimeInputElement() => new InputElement(type: 'datetime');

  @DomName('HTMLInputElement.valueAsDate')
  DateTime valueAsDate;

  @DomName('HTMLInputElement.readOnly')
  bool readOnly;

  @DomName('HTMLInputElement.required')
  bool required;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'datetime')).type == 'datetime';
  }
}

/**
 * A date (year, month, day) with no time zone.
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME, '25')
@Experimental
abstract class DateInputElement implements RangeInputElementBase {
  factory DateInputElement() => new InputElement(type: 'date');

  @DomName('HTMLInputElement.valueAsDate')
  DateTime valueAsDate;

  @DomName('HTMLInputElement.readOnly')
  bool readOnly;

  @DomName('HTMLInputElement.required')
  bool required;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'date')).type == 'date';
  }
}

/**
 * A date consisting of a year and a month with no time zone.
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME, '25')
@Experimental
abstract class MonthInputElement implements RangeInputElementBase {
  factory MonthInputElement() => new InputElement(type: 'month');

  @DomName('HTMLInputElement.valueAsDate')
  DateTime valueAsDate;

  @DomName('HTMLInputElement.readOnly')
  bool readOnly;

  @DomName('HTMLInputElement.required')
  bool required;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'month')).type == 'month';
  }
}

/**
 * A date consisting of a week-year number and a week number with no time zone.
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME, '25')
@Experimental
abstract class WeekInputElement implements RangeInputElementBase {
  factory WeekInputElement() => new InputElement(type: 'week');

  @DomName('HTMLInputElement.valueAsDate')
  DateTime valueAsDate;

  @DomName('HTMLInputElement.readOnly')
  bool readOnly;

  @DomName('HTMLInputElement.required')
  bool required;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'week')).type == 'week';
  }
}

/**
 * A time (hour, minute, seconds, fractional seconds) with no time zone.
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME)
@Experimental
abstract class TimeInputElement implements RangeInputElementBase {
  factory TimeInputElement() => new InputElement(type: 'time');

  @DomName('HTMLInputElement.valueAsDate')
  DateTime valueAsDate;

  @DomName('HTMLInputElement.readOnly')
  bool readOnly;

  @DomName('HTMLInputElement.required')
  bool required;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'time')).type == 'time';
  }
}

/**
 * A date and time (year, month, day, hour, minute, second, fraction of a
 * second) with no time zone.
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME, '25')
@Experimental
abstract class LocalDateTimeInputElement implements RangeInputElementBase {
  factory LocalDateTimeInputElement() =>
      new InputElement(type: 'datetime-local');

  @DomName('HTMLInputElement.readOnly')
  bool readOnly;

  @DomName('HTMLInputElement.required')
  bool required;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'datetime-local')).type == 'datetime-local';
  }
}

/**
 * A numeric editor control.
 */
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.IE)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
abstract class NumberInputElement implements RangeInputElementBase {
  factory NumberInputElement() => new InputElement(type: 'number');

  @DomName('HTMLInputElement.placeholder')
  String placeholder;

  @DomName('HTMLInputElement.readOnly')
  bool readOnly;

  @DomName('HTMLInputElement.required')
  bool required;

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'number')).type == 'number';
  }
}

/**
 * Similar to [NumberInputElement] but the browser may provide more optimal
 * styling (such as a slider control).
 *
 * Use [supported] to check if this is supported on the current platform.
 */
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.IE, '10')
@Experimental
abstract class RangeInputElement implements RangeInputElementBase {
  factory RangeInputElement() => new InputElement(type: 'range');

  /// Returns true if this input type is supported on the current platform.
  static bool get supported {
    return (new InputElement(type: 'range')).type == 'range';
  }
}

/**
 * A boolean editor control.
 *
 * Note that if [indeterminate] is set then this control is in a third
 * indeterminate state.
 */
abstract class CheckboxInputElement implements InputElementBase {
  factory CheckboxInputElement() => new InputElement(type: 'checkbox');

  @DomName('HTMLInputElement.checked')
  bool checked;

  @DomName('HTMLInputElement.required')
  bool required;
}


/**
 * A control that when used with other [ReadioButtonInputElement] controls
 * forms a radio button group in which only one control can be checked at a
 * time.
 *
 * Radio buttons are considered to be in the same radio button group if:
 *
 * * They are all of type 'radio'.
 * * They all have either the same [FormElement] owner, or no owner.
 * * Their name attributes contain the same name.
 */
abstract class RadioButtonInputElement implements InputElementBase {
  factory RadioButtonInputElement() => new InputElement(type: 'radio');

  @DomName('HTMLInputElement.checked')
  bool checked;

  @DomName('HTMLInputElement.required')
  bool required;
}

/**
 * A control for picking files from the user's computer.
 */
abstract class FileUploadInputElement implements InputElementBase {
  factory FileUploadInputElement() => new InputElement(type: 'file');

  @DomName('HTMLInputElement.accept')
  String accept;

  @DomName('HTMLInputElement.multiple')
  bool multiple;

  @DomName('HTMLInputElement.required')
  bool required;

  @DomName('HTMLInputElement.files')
  List<File> files;
}

/**
 * A button, which when clicked, submits the form.
 */
abstract class SubmitButtonInputElement implements InputElementBase {
  factory SubmitButtonInputElement() => new InputElement(type: 'submit');

  @DomName('HTMLInputElement.formAction')
  String formAction;

  @DomName('HTMLInputElement.formEnctype')
  String formEnctype;

  @DomName('HTMLInputElement.formMethod')
  String formMethod;

  @DomName('HTMLInputElement.formNoValidate')
  bool formNoValidate;

  @DomName('HTMLInputElement.formTarget')
  String formTarget;
}

/**
 * Either an image which the user can select a coordinate to or a form
 * submit button.
 */
abstract class ImageButtonInputElement implements InputElementBase {
  factory ImageButtonInputElement() => new InputElement(type: 'image');

  @DomName('HTMLInputElement.alt')
  String alt;

  @DomName('HTMLInputElement.formAction')
  String formAction;

  @DomName('HTMLInputElement.formEnctype')
  String formEnctype;

  @DomName('HTMLInputElement.formMethod')
  String formMethod;

  @DomName('HTMLInputElement.formNoValidate')
  bool formNoValidate;

  @DomName('HTMLInputElement.formTarget')
  String formTarget;

  @DomName('HTMLInputElement.height')
  int height;

  @DomName('HTMLInputElement.src')
  String src;

  @DomName('HTMLInputElement.width')
  int width;
}

/**
 * A button, which when clicked, resets the form.
 */
abstract class ResetButtonInputElement implements InputElementBase {
  factory ResetButtonInputElement() => new InputElement(type: 'reset');
}

/**
 * A button, with no default behavior.
 */
abstract class ButtonInputElement implements InputElementBase {
  factory ButtonInputElement() => new InputElement(type: 'button');
}


@DocsEditable
@deprecated
class InputElementEvents extends ElementEvents {
  @DocsEditable
  InputElementEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get speechChange => this['webkitSpeechChange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Int16Array')
class Int16Array extends ArrayBufferView implements JavaScriptIndexingBehavior, List<int> native "*Int16Array" {

  factory Int16Array(int length) =>
    _TypedArrayFactoryProvider.createInt16Array(length);

  factory Int16Array.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createInt16Array_fromList(list);

  factory Int16Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createInt16Array_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 2;

  @DomName('Int16Array.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  int operator[](int index) => JS("int", "#[#]", this, index);

  void operator[]=(int index, int value) { JS("void", "#[#] = #", this, index, value); }  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<int>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, int)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(int element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(int element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(int element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<int> where(bool f(int element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(int element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(int element)) => IterableMixinWorkaround.any(this, f);

  List<int> toList() => new List<int>.from(this);
  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  List<int> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<int> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<int> skipWhile(bool test(int value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  int firstMatching(bool test(int value), { int orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  int lastMatching(bool test(int value), {int orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  int singleMatching(bool test(int value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  int elementAt(int index) {
    return this[index];
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<int>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<int> get reversed =>
      new ReversedListView<int>(this, 0, null);

  void sort([int compare(int a, int b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  int get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  int get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  int get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  int min([int compare(int a, int b)]) =>
      IterableMixinWorkaround.min(this, compare);

  int max([int compare(int a, int b)]) =>
      IterableMixinWorkaround.max(this, compare);

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<int> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [int initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <int>[]);

  // -- end List<int> mixins.

  @JSName('set')
  @DomName('Int16Array.set')
  @DocsEditable
  void setElements(Object array, [int offset]) native;

  @DomName('Int16Array.subarray')
  @DocsEditable
  Int16Array subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Int32Array')
class Int32Array extends ArrayBufferView implements JavaScriptIndexingBehavior, List<int> native "*Int32Array" {

  factory Int32Array(int length) =>
    _TypedArrayFactoryProvider.createInt32Array(length);

  factory Int32Array.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createInt32Array_fromList(list);

  factory Int32Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createInt32Array_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 4;

  @DomName('Int32Array.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  int operator[](int index) => JS("int", "#[#]", this, index);

  void operator[]=(int index, int value) { JS("void", "#[#] = #", this, index, value); }  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<int>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, int)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(int element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(int element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(int element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<int> where(bool f(int element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(int element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(int element)) => IterableMixinWorkaround.any(this, f);

  List<int> toList() => new List<int>.from(this);
  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  List<int> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<int> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<int> skipWhile(bool test(int value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  int firstMatching(bool test(int value), { int orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  int lastMatching(bool test(int value), {int orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  int singleMatching(bool test(int value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  int elementAt(int index) {
    return this[index];
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<int>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<int> get reversed =>
      new ReversedListView<int>(this, 0, null);

  void sort([int compare(int a, int b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  int get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  int get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  int get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  int min([int compare(int a, int b)]) =>
      IterableMixinWorkaround.min(this, compare);

  int max([int compare(int a, int b)]) =>
      IterableMixinWorkaround.max(this, compare);

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<int> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [int initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <int>[]);

  // -- end List<int> mixins.

  @JSName('set')
  @DomName('Int32Array.set')
  @DocsEditable
  void setElements(Object array, [int offset]) native;

  @DomName('Int32Array.subarray')
  @DocsEditable
  Int32Array subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Int8Array')
class Int8Array extends ArrayBufferView implements JavaScriptIndexingBehavior, List<int> native "*Int8Array" {

  factory Int8Array(int length) =>
    _TypedArrayFactoryProvider.createInt8Array(length);

  factory Int8Array.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createInt8Array_fromList(list);

  factory Int8Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createInt8Array_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 1;

  @DomName('Int8Array.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  int operator[](int index) => JS("int", "#[#]", this, index);

  void operator[]=(int index, int value) { JS("void", "#[#] = #", this, index, value); }  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<int>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, int)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(int element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(int element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(int element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<int> where(bool f(int element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(int element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(int element)) => IterableMixinWorkaround.any(this, f);

  List<int> toList() => new List<int>.from(this);
  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  List<int> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<int> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<int> skipWhile(bool test(int value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  int firstMatching(bool test(int value), { int orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  int lastMatching(bool test(int value), {int orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  int singleMatching(bool test(int value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  int elementAt(int index) {
    return this[index];
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<int>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<int> get reversed =>
      new ReversedListView<int>(this, 0, null);

  void sort([int compare(int a, int b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  int get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  int get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  int get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  int min([int compare(int a, int b)]) =>
      IterableMixinWorkaround.min(this, compare);

  int max([int compare(int a, int b)]) =>
      IterableMixinWorkaround.max(this, compare);

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<int> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [int initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <int>[]);

  // -- end List<int> mixins.

  @JSName('set')
  @DomName('Int8Array.set')
  @DocsEditable
  void setElements(Object array, [int offset]) native;

  @DomName('Int8Array.subarray')
  @DocsEditable
  Int8Array subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('JavaScriptCallFrame')
class JavaScriptCallFrame native "*JavaScriptCallFrame" {

  static const int CATCH_SCOPE = 4;

  static const int CLOSURE_SCOPE = 3;

  static const int GLOBAL_SCOPE = 0;

  static const int LOCAL_SCOPE = 1;

  static const int WITH_SCOPE = 2;

  @DomName('JavaScriptCallFrame.caller')
  @DocsEditable
  final JavaScriptCallFrame caller;

  @DomName('JavaScriptCallFrame.column')
  @DocsEditable
  final int column;

  @DomName('JavaScriptCallFrame.functionName')
  @DocsEditable
  final String functionName;

  @DomName('JavaScriptCallFrame.line')
  @DocsEditable
  final int line;

  @DomName('JavaScriptCallFrame.scopeChain')
  @DocsEditable
  final List scopeChain;

  @DomName('JavaScriptCallFrame.sourceID')
  @DocsEditable
  final int sourceID;

  @DomName('JavaScriptCallFrame.thisObject')
  @DocsEditable
  final Object thisObject;

  @DomName('JavaScriptCallFrame.type')
  @DocsEditable
  final String type;

  @DomName('JavaScriptCallFrame.evaluate')
  @DocsEditable
  void evaluate(String script) native;

  @DomName('JavaScriptCallFrame.restart')
  @DocsEditable
  Object restart() native;

  @DomName('JavaScriptCallFrame.scopeType')
  @DocsEditable
  int scopeType(int scopeIndex) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('KeyboardEvent')
class KeyboardEvent extends UIEvent native "*KeyboardEvent" {

  factory KeyboardEvent(String type,
      {Window view, bool canBubble: true, bool cancelable: true,
      String keyIdentifier: "", int keyLocation: 1, bool ctrlKey: false,
      bool altKey: false, bool shiftKey: false, bool metaKey: false,
      bool altGraphKey: false}) {
    if (view == null) {
      view = window;
    }
    final e = document.$dom_createEvent("KeyboardEvent");
    e.$dom_initKeyboardEvent(type, canBubble, cancelable, view, keyIdentifier,
        keyLocation, ctrlKey, altKey, shiftKey, metaKey, altGraphKey);
    return e;
  }

  @DomName('KeyboardEvent.initKeyboardEvent')
  void $dom_initKeyboardEvent(String type, bool canBubble, bool cancelable,
      Window view, String keyIdentifier, int keyLocation, bool ctrlKey,
      bool altKey, bool shiftKey, bool metaKey, bool altGraphKey) {
    if (JS('bool', 'typeof(#.initKeyEvent) == "function"', this)) {
      // initKeyEvent is only in Firefox (instead of initKeyboardEvent). It has
      // a slightly different signature, and allows you to specify keyCode and
      // charCode as the last two arguments, but we just set them as the default
      // since they can't be specified in other browsers.
      JS('void', '#.initKeyEvent(#, #, #, #, #, #, #, #, 0, 0)', this,
          type, canBubble, cancelable, view,
          ctrlKey, altKey, shiftKey, metaKey);
    } else {
      // initKeyboardEvent is for all other browsers.
      JS('void', '#.initKeyboardEvent(#, #, #, #, #, #, #, #, #, #, #)', this,
          type, canBubble, cancelable, view, keyIdentifier, keyLocation,
          ctrlKey, altKey, shiftKey, metaKey, altGraphKey);
    }
  }

  @DomName('KeyboardEvent.keyCode')
  int get keyCode => $dom_keyCode;

  @DomName('KeyboardEvent.charCode')
  int get charCode => $dom_charCode;

  @DomName('KeyboardEvent.altGraphKey')
  @DocsEditable
  final bool altGraphKey;

  @DomName('KeyboardEvent.altKey')
  @DocsEditable
  final bool altKey;

  @DomName('KeyboardEvent.ctrlKey')
  @DocsEditable
  final bool ctrlKey;

  @JSName('keyIdentifier')
  @DomName('KeyboardEvent.keyIdentifier')
  @DocsEditable
  final String $dom_keyIdentifier;

  @DomName('KeyboardEvent.keyLocation')
  @DocsEditable
  final int keyLocation;

  @DomName('KeyboardEvent.metaKey')
  @DocsEditable
  final bool metaKey;

  @DomName('KeyboardEvent.shiftKey')
  @DocsEditable
  final bool shiftKey;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLKeygenElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class KeygenElement extends Element native "*HTMLKeygenElement" {

  @DocsEditable
  factory KeygenElement() => document.$dom_createElement("keygen");

  /// Checks if this type is supported on the current platform.
  static bool get supported => Element.isTagSupported('keygen') && (new Element.tag('keygen') is KeygenElement);

  @DomName('HTMLKeygenElement.autofocus')
  @DocsEditable
  bool autofocus;

  @DomName('HTMLKeygenElement.challenge')
  @DocsEditable
  String challenge;

  @DomName('HTMLKeygenElement.disabled')
  @DocsEditable
  bool disabled;

  @DomName('HTMLKeygenElement.form')
  @DocsEditable
  final FormElement form;

  @DomName('HTMLKeygenElement.keytype')
  @DocsEditable
  String keytype;

  @DomName('HTMLKeygenElement.labels')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  final List<Node> labels;

  @DomName('HTMLKeygenElement.name')
  @DocsEditable
  String name;

  @DomName('HTMLKeygenElement.type')
  @DocsEditable
  final String type;

  @DomName('HTMLKeygenElement.validationMessage')
  @DocsEditable
  final String validationMessage;

  @DomName('HTMLKeygenElement.validity')
  @DocsEditable
  final ValidityState validity;

  @DomName('HTMLKeygenElement.willValidate')
  @DocsEditable
  final bool willValidate;

  @DomName('HTMLKeygenElement.checkValidity')
  @DocsEditable
  bool checkValidity() native;

  @DomName('HTMLKeygenElement.setCustomValidity')
  @DocsEditable
  void setCustomValidity(String error) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLLIElement')
class LIElement extends Element native "*HTMLLIElement" {

  @DocsEditable
  factory LIElement() => document.$dom_createElement("li");

  @DomName('HTMLLIElement.type')
  @DocsEditable
  String type;

  @DomName('HTMLLIElement.value')
  @DocsEditable
  int value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLLabelElement')
class LabelElement extends Element native "*HTMLLabelElement" {

  @DocsEditable
  factory LabelElement() => document.$dom_createElement("label");

  @DomName('HTMLLabelElement.control')
  @DocsEditable
  final Element control;

  @DomName('HTMLLabelElement.form')
  @DocsEditable
  final FormElement form;

  @DomName('HTMLLabelElement.htmlFor')
  @DocsEditable
  String htmlFor;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLLegendElement')
class LegendElement extends Element native "*HTMLLegendElement" {

  @DocsEditable
  factory LegendElement() => document.$dom_createElement("legend");

  @DomName('HTMLLegendElement.form')
  @DocsEditable
  final FormElement form;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLLinkElement')
class LinkElement extends Element native "*HTMLLinkElement" {

  @DocsEditable
  factory LinkElement() => document.$dom_createElement("link");

  @DomName('HTMLLinkElement.disabled')
  @DocsEditable
  bool disabled;

  @DomName('HTMLLinkElement.href')
  @DocsEditable
  String href;

  @DomName('HTMLLinkElement.hreflang')
  @DocsEditable
  String hreflang;

  @DomName('HTMLLinkElement.media')
  @DocsEditable
  String media;

  @DomName('HTMLLinkElement.rel')
  @DocsEditable
  String rel;

  @DomName('HTMLLinkElement.sheet')
  @DocsEditable
  final StyleSheet sheet;

  @DomName('HTMLLinkElement.sizes')
  @DocsEditable
  DomSettableTokenList sizes;

  @DomName('HTMLLinkElement.type')
  @DocsEditable
  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('LocalMediaStream')
class LocalMediaStream extends MediaStream implements EventTarget native "*LocalMediaStream" {

  @DomName('LocalMediaStream.stop')
  @DocsEditable
  void stop() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Location')
class Location implements LocationBase native "*Location" {

  @DomName('Location.ancestorOrigins')
  @DocsEditable
  @Returns('DomStringList')
  @Creates('DomStringList')
  final List<String> ancestorOrigins;

  @DomName('Location.hash')
  @DocsEditable
  String hash;

  @DomName('Location.host')
  @DocsEditable
  String host;

  @DomName('Location.hostname')
  @DocsEditable
  String hostname;

  @DomName('Location.href')
  @DocsEditable
  String href;

  @DomName('Location.origin')
  @DocsEditable
  final String origin;

  @DomName('Location.pathname')
  @DocsEditable
  String pathname;

  @DomName('Location.port')
  @DocsEditable
  String port;

  @DomName('Location.protocol')
  @DocsEditable
  String protocol;

  @DomName('Location.search')
  @DocsEditable
  String search;

  @DomName('Location.assign')
  @DocsEditable
  void assign(String url) native;

  @DomName('Location.reload')
  @DocsEditable
  void reload() native;

  @DomName('Location.replace')
  @DocsEditable
  void replace(String url) native;

  @DomName('Location.toString')
  @DocsEditable
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLMapElement')
class MapElement extends Element native "*HTMLMapElement" {

  @DocsEditable
  factory MapElement() => document.$dom_createElement("map");

  @DomName('HTMLMapElement.areas')
  @DocsEditable
  final HtmlCollection areas;

  @DomName('HTMLMapElement.name')
  @DocsEditable
  String name;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MediaController')
class MediaController extends EventTarget native "*MediaController" {

  @DocsEditable
  factory MediaController() => MediaController._create();
  static MediaController _create() => JS('MediaController', 'new MediaController()');

  @DomName('MediaController.buffered')
  @DocsEditable
  final TimeRanges buffered;

  @DomName('MediaController.currentTime')
  @DocsEditable
  num currentTime;

  @DomName('MediaController.defaultPlaybackRate')
  @DocsEditable
  num defaultPlaybackRate;

  @DomName('MediaController.duration')
  @DocsEditable
  final num duration;

  @DomName('MediaController.muted')
  @DocsEditable
  bool muted;

  @DomName('MediaController.paused')
  @DocsEditable
  final bool paused;

  @DomName('MediaController.playbackRate')
  @DocsEditable
  num playbackRate;

  @DomName('MediaController.playbackState')
  @DocsEditable
  final String playbackState;

  @DomName('MediaController.played')
  @DocsEditable
  final TimeRanges played;

  @DomName('MediaController.seekable')
  @DocsEditable
  final TimeRanges seekable;

  @DomName('MediaController.volume')
  @DocsEditable
  num volume;

  @JSName('addEventListener')
  @DomName('MediaController.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('MediaController.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native;

  @DomName('MediaController.pause')
  @DocsEditable
  void pause() native;

  @DomName('MediaController.play')
  @DocsEditable
  void play() native;

  @JSName('removeEventListener')
  @DomName('MediaController.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('MediaController.unpause')
  @DocsEditable
  void unpause() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLMediaElement')
class MediaElement extends Element native "*HTMLMediaElement" {

  @DomName('HTMLMediaElement.canplay')
  @DocsEditable
  static const EventStreamProvider<Event> canPlayEvent = const EventStreamProvider<Event>('canplay');

  @DomName('HTMLMediaElement.canplaythrough')
  @DocsEditable
  static const EventStreamProvider<Event> canPlayThroughEvent = const EventStreamProvider<Event>('canplaythrough');

  @DomName('HTMLMediaElement.durationchange')
  @DocsEditable
  static const EventStreamProvider<Event> durationChangeEvent = const EventStreamProvider<Event>('durationchange');

  @DomName('HTMLMediaElement.emptied')
  @DocsEditable
  static const EventStreamProvider<Event> emptiedEvent = const EventStreamProvider<Event>('emptied');

  @DomName('HTMLMediaElement.ended')
  @DocsEditable
  static const EventStreamProvider<Event> endedEvent = const EventStreamProvider<Event>('ended');

  @DomName('HTMLMediaElement.loadeddata')
  @DocsEditable
  static const EventStreamProvider<Event> loadedDataEvent = const EventStreamProvider<Event>('loadeddata');

  @DomName('HTMLMediaElement.loadedmetadata')
  @DocsEditable
  static const EventStreamProvider<Event> loadedMetadataEvent = const EventStreamProvider<Event>('loadedmetadata');

  @DomName('HTMLMediaElement.loadstart')
  @DocsEditable
  static const EventStreamProvider<Event> loadStartEvent = const EventStreamProvider<Event>('loadstart');

  @DomName('HTMLMediaElement.pause')
  @DocsEditable
  static const EventStreamProvider<Event> pauseEvent = const EventStreamProvider<Event>('pause');

  @DomName('HTMLMediaElement.play')
  @DocsEditable
  static const EventStreamProvider<Event> playEvent = const EventStreamProvider<Event>('play');

  @DomName('HTMLMediaElement.playing')
  @DocsEditable
  static const EventStreamProvider<Event> playingEvent = const EventStreamProvider<Event>('playing');

  @DomName('HTMLMediaElement.progress')
  @DocsEditable
  static const EventStreamProvider<Event> progressEvent = const EventStreamProvider<Event>('progress');

  @DomName('HTMLMediaElement.ratechange')
  @DocsEditable
  static const EventStreamProvider<Event> rateChangeEvent = const EventStreamProvider<Event>('ratechange');

  @DomName('HTMLMediaElement.seeked')
  @DocsEditable
  static const EventStreamProvider<Event> seekedEvent = const EventStreamProvider<Event>('seeked');

  @DomName('HTMLMediaElement.seeking')
  @DocsEditable
  static const EventStreamProvider<Event> seekingEvent = const EventStreamProvider<Event>('seeking');

  @DomName('HTMLMediaElement.show')
  @DocsEditable
  static const EventStreamProvider<Event> showEvent = const EventStreamProvider<Event>('show');

  @DomName('HTMLMediaElement.stalled')
  @DocsEditable
  static const EventStreamProvider<Event> stalledEvent = const EventStreamProvider<Event>('stalled');

  @DomName('HTMLMediaElement.suspend')
  @DocsEditable
  static const EventStreamProvider<Event> suspendEvent = const EventStreamProvider<Event>('suspend');

  @DomName('HTMLMediaElement.timeupdate')
  @DocsEditable
  static const EventStreamProvider<Event> timeUpdateEvent = const EventStreamProvider<Event>('timeupdate');

  @DomName('HTMLMediaElement.volumechange')
  @DocsEditable
  static const EventStreamProvider<Event> volumeChangeEvent = const EventStreamProvider<Event>('volumechange');

  @DomName('HTMLMediaElement.waiting')
  @DocsEditable
  static const EventStreamProvider<Event> waitingEvent = const EventStreamProvider<Event>('waiting');

  @DomName('HTMLMediaElement.webkitkeyadded')
  @DocsEditable
  static const EventStreamProvider<MediaKeyEvent> keyAddedEvent = const EventStreamProvider<MediaKeyEvent>('webkitkeyadded');

  @DomName('HTMLMediaElement.webkitkeyerror')
  @DocsEditable
  static const EventStreamProvider<MediaKeyEvent> keyErrorEvent = const EventStreamProvider<MediaKeyEvent>('webkitkeyerror');

  @DomName('HTMLMediaElement.webkitkeymessage')
  @DocsEditable
  static const EventStreamProvider<MediaKeyEvent> keyMessageEvent = const EventStreamProvider<MediaKeyEvent>('webkitkeymessage');

  @DomName('HTMLMediaElement.webkitneedkey')
  @DocsEditable
  static const EventStreamProvider<MediaKeyEvent> needKeyEvent = const EventStreamProvider<MediaKeyEvent>('webkitneedkey');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  MediaElementEvents get on =>
    new MediaElementEvents(this);

  static const int HAVE_CURRENT_DATA = 2;

  static const int HAVE_ENOUGH_DATA = 4;

  static const int HAVE_FUTURE_DATA = 3;

  static const int HAVE_METADATA = 1;

  static const int HAVE_NOTHING = 0;

  static const int NETWORK_EMPTY = 0;

  static const int NETWORK_IDLE = 1;

  static const int NETWORK_LOADING = 2;

  static const int NETWORK_NO_SOURCE = 3;

  @DomName('HTMLMediaElement.autoplay')
  @DocsEditable
  bool autoplay;

  @DomName('HTMLMediaElement.buffered')
  @DocsEditable
  final TimeRanges buffered;

  @DomName('HTMLMediaElement.controller')
  @DocsEditable
  MediaController controller;

  @DomName('HTMLMediaElement.controls')
  @DocsEditable
  bool controls;

  @DomName('HTMLMediaElement.currentSrc')
  @DocsEditable
  final String currentSrc;

  @DomName('HTMLMediaElement.currentTime')
  @DocsEditable
  num currentTime;

  @DomName('HTMLMediaElement.defaultMuted')
  @DocsEditable
  bool defaultMuted;

  @DomName('HTMLMediaElement.defaultPlaybackRate')
  @DocsEditable
  num defaultPlaybackRate;

  @DomName('HTMLMediaElement.duration')
  @DocsEditable
  final num duration;

  @DomName('HTMLMediaElement.ended')
  @DocsEditable
  final bool ended;

  @DomName('HTMLMediaElement.error')
  @DocsEditable
  final MediaError error;

  @DomName('HTMLMediaElement.initialTime')
  @DocsEditable
  final num initialTime;

  @DomName('HTMLMediaElement.loop')
  @DocsEditable
  bool loop;

  @DomName('HTMLMediaElement.mediaGroup')
  @DocsEditable
  String mediaGroup;

  @DomName('HTMLMediaElement.muted')
  @DocsEditable
  bool muted;

  @DomName('HTMLMediaElement.networkState')
  @DocsEditable
  final int networkState;

  @DomName('HTMLMediaElement.paused')
  @DocsEditable
  final bool paused;

  @DomName('HTMLMediaElement.playbackRate')
  @DocsEditable
  num playbackRate;

  @DomName('HTMLMediaElement.played')
  @DocsEditable
  final TimeRanges played;

  @DomName('HTMLMediaElement.preload')
  @DocsEditable
  String preload;

  @DomName('HTMLMediaElement.readyState')
  @DocsEditable
  final int readyState;

  @DomName('HTMLMediaElement.seekable')
  @DocsEditable
  final TimeRanges seekable;

  @DomName('HTMLMediaElement.seeking')
  @DocsEditable
  final bool seeking;

  @DomName('HTMLMediaElement.src')
  @DocsEditable
  String src;

  @DomName('HTMLMediaElement.startTime')
  @DocsEditable
  final num startTime;

  @DomName('HTMLMediaElement.textTracks')
  @DocsEditable
  final TextTrackList textTracks;

  @DomName('HTMLMediaElement.volume')
  @DocsEditable
  num volume;

  @DomName('HTMLMediaElement.webkitAudioDecodedByteCount')
  @DocsEditable
  final int webkitAudioDecodedByteCount;

  @DomName('HTMLMediaElement.webkitClosedCaptionsVisible')
  @DocsEditable
  bool webkitClosedCaptionsVisible;

  @DomName('HTMLMediaElement.webkitHasClosedCaptions')
  @DocsEditable
  final bool webkitHasClosedCaptions;

  @DomName('HTMLMediaElement.webkitPreservesPitch')
  @DocsEditable
  bool webkitPreservesPitch;

  @DomName('HTMLMediaElement.webkitVideoDecodedByteCount')
  @DocsEditable
  final int webkitVideoDecodedByteCount;

  @DomName('HTMLMediaElement.addTextTrack')
  @DocsEditable
  TextTrack addTextTrack(String kind, [String label, String language]) native;

  @DomName('HTMLMediaElement.canPlayType')
  @DocsEditable
  String canPlayType(String type, String keySystem) native;

  @DomName('HTMLMediaElement.load')
  @DocsEditable
  void load() native;

  @DomName('HTMLMediaElement.pause')
  @DocsEditable
  void pause() native;

  @DomName('HTMLMediaElement.play')
  @DocsEditable
  void play() native;

  @DomName('HTMLMediaElement.webkitAddKey')
  @DocsEditable
  void webkitAddKey(String keySystem, Uint8Array key, [Uint8Array initData, String sessionId]) native;

  @DomName('HTMLMediaElement.webkitCancelKeyRequest')
  @DocsEditable
  void webkitCancelKeyRequest(String keySystem, String sessionId) native;

  @DomName('HTMLMediaElement.webkitGenerateKeyRequest')
  @DocsEditable
  void webkitGenerateKeyRequest(String keySystem, [Uint8Array initData]) native;

  @DomName('HTMLMediaElement.canplay')
  @DocsEditable
  Stream<Event> get onCanPlay => canPlayEvent.forTarget(this);

  @DomName('HTMLMediaElement.canplaythrough')
  @DocsEditable
  Stream<Event> get onCanPlayThrough => canPlayThroughEvent.forTarget(this);

  @DomName('HTMLMediaElement.durationchange')
  @DocsEditable
  Stream<Event> get onDurationChange => durationChangeEvent.forTarget(this);

  @DomName('HTMLMediaElement.emptied')
  @DocsEditable
  Stream<Event> get onEmptied => emptiedEvent.forTarget(this);

  @DomName('HTMLMediaElement.ended')
  @DocsEditable
  Stream<Event> get onEnded => endedEvent.forTarget(this);

  @DomName('HTMLMediaElement.loadeddata')
  @DocsEditable
  Stream<Event> get onLoadedData => loadedDataEvent.forTarget(this);

  @DomName('HTMLMediaElement.loadedmetadata')
  @DocsEditable
  Stream<Event> get onLoadedMetadata => loadedMetadataEvent.forTarget(this);

  @DomName('HTMLMediaElement.loadstart')
  @DocsEditable
  Stream<Event> get onLoadStart => loadStartEvent.forTarget(this);

  @DomName('HTMLMediaElement.pause')
  @DocsEditable
  Stream<Event> get onPause => pauseEvent.forTarget(this);

  @DomName('HTMLMediaElement.play')
  @DocsEditable
  Stream<Event> get onPlay => playEvent.forTarget(this);

  @DomName('HTMLMediaElement.playing')
  @DocsEditable
  Stream<Event> get onPlaying => playingEvent.forTarget(this);

  @DomName('HTMLMediaElement.progress')
  @DocsEditable
  Stream<Event> get onProgress => progressEvent.forTarget(this);

  @DomName('HTMLMediaElement.ratechange')
  @DocsEditable
  Stream<Event> get onRateChange => rateChangeEvent.forTarget(this);

  @DomName('HTMLMediaElement.seeked')
  @DocsEditable
  Stream<Event> get onSeeked => seekedEvent.forTarget(this);

  @DomName('HTMLMediaElement.seeking')
  @DocsEditable
  Stream<Event> get onSeeking => seekingEvent.forTarget(this);

  @DomName('HTMLMediaElement.show')
  @DocsEditable
  Stream<Event> get onShow => showEvent.forTarget(this);

  @DomName('HTMLMediaElement.stalled')
  @DocsEditable
  Stream<Event> get onStalled => stalledEvent.forTarget(this);

  @DomName('HTMLMediaElement.suspend')
  @DocsEditable
  Stream<Event> get onSuspend => suspendEvent.forTarget(this);

  @DomName('HTMLMediaElement.timeupdate')
  @DocsEditable
  Stream<Event> get onTimeUpdate => timeUpdateEvent.forTarget(this);

  @DomName('HTMLMediaElement.volumechange')
  @DocsEditable
  Stream<Event> get onVolumeChange => volumeChangeEvent.forTarget(this);

  @DomName('HTMLMediaElement.waiting')
  @DocsEditable
  Stream<Event> get onWaiting => waitingEvent.forTarget(this);

  @DomName('HTMLMediaElement.webkitkeyadded')
  @DocsEditable
  Stream<MediaKeyEvent> get onKeyAdded => keyAddedEvent.forTarget(this);

  @DomName('HTMLMediaElement.webkitkeyerror')
  @DocsEditable
  Stream<MediaKeyEvent> get onKeyError => keyErrorEvent.forTarget(this);

  @DomName('HTMLMediaElement.webkitkeymessage')
  @DocsEditable
  Stream<MediaKeyEvent> get onKeyMessage => keyMessageEvent.forTarget(this);

  @DomName('HTMLMediaElement.webkitneedkey')
  @DocsEditable
  Stream<MediaKeyEvent> get onNeedKey => needKeyEvent.forTarget(this);
}

@DocsEditable
@deprecated
class MediaElementEvents extends ElementEvents {
  @DocsEditable
  MediaElementEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get canPlay => this['canplay'];

  @DocsEditable
  EventListenerList get canPlayThrough => this['canplaythrough'];

  @DocsEditable
  EventListenerList get durationChange => this['durationchange'];

  @DocsEditable
  EventListenerList get emptied => this['emptied'];

  @DocsEditable
  EventListenerList get ended => this['ended'];

  @DocsEditable
  EventListenerList get loadedData => this['loadeddata'];

  @DocsEditable
  EventListenerList get loadedMetadata => this['loadedmetadata'];

  @DocsEditable
  EventListenerList get loadStart => this['loadstart'];

  @DocsEditable
  EventListenerList get pause => this['pause'];

  @DocsEditable
  EventListenerList get play => this['play'];

  @DocsEditable
  EventListenerList get playing => this['playing'];

  @DocsEditable
  EventListenerList get progress => this['progress'];

  @DocsEditable
  EventListenerList get rateChange => this['ratechange'];

  @DocsEditable
  EventListenerList get seeked => this['seeked'];

  @DocsEditable
  EventListenerList get seeking => this['seeking'];

  @DocsEditable
  EventListenerList get show => this['show'];

  @DocsEditable
  EventListenerList get stalled => this['stalled'];

  @DocsEditable
  EventListenerList get suspend => this['suspend'];

  @DocsEditable
  EventListenerList get timeUpdate => this['timeupdate'];

  @DocsEditable
  EventListenerList get volumeChange => this['volumechange'];

  @DocsEditable
  EventListenerList get waiting => this['waiting'];

  @DocsEditable
  EventListenerList get keyAdded => this['webkitkeyadded'];

  @DocsEditable
  EventListenerList get keyError => this['webkitkeyerror'];

  @DocsEditable
  EventListenerList get keyMessage => this['webkitkeymessage'];

  @DocsEditable
  EventListenerList get needKey => this['webkitneedkey'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MediaError')
class MediaError native "*MediaError" {

  static const int MEDIA_ERR_ABORTED = 1;

  static const int MEDIA_ERR_DECODE = 3;

  static const int MEDIA_ERR_ENCRYPTED = 5;

  static const int MEDIA_ERR_NETWORK = 2;

  static const int MEDIA_ERR_SRC_NOT_SUPPORTED = 4;

  @DomName('MediaError.code')
  @DocsEditable
  final int code;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MediaKeyError')
class MediaKeyError native "*MediaKeyError" {

  static const int MEDIA_KEYERR_CLIENT = 2;

  static const int MEDIA_KEYERR_DOMAIN = 6;

  static const int MEDIA_KEYERR_HARDWARECHANGE = 5;

  static const int MEDIA_KEYERR_OUTPUT = 4;

  static const int MEDIA_KEYERR_SERVICE = 3;

  static const int MEDIA_KEYERR_UNKNOWN = 1;

  @DomName('MediaKeyError.code')
  @DocsEditable
  final int code;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MediaKeyEvent')
class MediaKeyEvent extends Event native "*MediaKeyEvent" {

  @JSName('defaultURL')
  @DomName('MediaKeyEvent.defaultURL')
  @DocsEditable
  final String defaultUrl;

  @DomName('MediaKeyEvent.errorCode')
  @DocsEditable
  final MediaKeyError errorCode;

  @DomName('MediaKeyEvent.initData')
  @DocsEditable
  final Uint8Array initData;

  @DomName('MediaKeyEvent.keySystem')
  @DocsEditable
  final String keySystem;

  @DomName('MediaKeyEvent.message')
  @DocsEditable
  final Uint8Array message;

  @DomName('MediaKeyEvent.sessionId')
  @DocsEditable
  final String sessionId;

  @DomName('MediaKeyEvent.systemCode')
  @DocsEditable
  final int systemCode;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MediaList')
class MediaList native "*MediaList" {

  @DomName('MediaList.length')
  @DocsEditable
  final int length;

  @DomName('MediaList.mediaText')
  @DocsEditable
  String mediaText;

  @DomName('MediaList.appendMedium')
  @DocsEditable
  void appendMedium(String newMedium) native;

  @DomName('MediaList.deleteMedium')
  @DocsEditable
  void deleteMedium(String oldMedium) native;

  @DomName('MediaList.item')
  @DocsEditable
  String item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MediaQueryList')
class MediaQueryList native "*MediaQueryList" {

  @DomName('MediaQueryList.matches')
  @DocsEditable
  final bool matches;

  @DomName('MediaQueryList.media')
  @DocsEditable
  final String media;

  @DomName('MediaQueryList.addListener')
  @DocsEditable
  void addListener(MediaQueryListListener listener) native;

  @DomName('MediaQueryList.removeListener')
  @DocsEditable
  void removeListener(MediaQueryListListener listener) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('MediaQueryListListener')
abstract class MediaQueryListListener {

  void queryChanged(MediaQueryList list);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MediaSource')
class MediaSource extends EventTarget native "*MediaSource" {

  @DocsEditable
  factory MediaSource() => MediaSource._create();
  static MediaSource _create() => JS('MediaSource', 'new MediaSource()');

  @DomName('MediaSource.activeSourceBuffers')
  @DocsEditable
  final SourceBufferList activeSourceBuffers;

  @DomName('MediaSource.duration')
  @DocsEditable
  num duration;

  @DomName('MediaSource.readyState')
  @DocsEditable
  final String readyState;

  @DomName('MediaSource.sourceBuffers')
  @DocsEditable
  final SourceBufferList sourceBuffers;

  @JSName('addEventListener')
  @DomName('MediaSource.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('MediaSource.addSourceBuffer')
  @DocsEditable
  SourceBuffer addSourceBuffer(String type) native;

  @DomName('MediaSource.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event event) native;

  @DomName('MediaSource.endOfStream')
  @DocsEditable
  void endOfStream(String error) native;

  @JSName('removeEventListener')
  @DomName('MediaSource.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('MediaSource.removeSourceBuffer')
  @DocsEditable
  void removeSourceBuffer(SourceBuffer buffer) native;
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MediaStream; @docsEditable true@DomName('MediaStream')

class MediaStream extends EventTarget native "*MediaStream" {

  @DomName('MediaStream.ended')
  @DocsEditable
  static const EventStreamProvider<Event> endedEvent = const EventStreamProvider<Event>('ended');

  @DocsEditable
  factory MediaStream() => MediaStream._create();
  static MediaStream _create() => JS('MediaStream', 'new MediaStream()');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  MediaStreamEvents get on =>
    new MediaStreamEvents(this);

  @DomName('MediaStream.ended')
  @DocsEditable
  final bool ended;

  @DomName('MediaStream.id')
  @DocsEditable
  final String id;

  @DomName('MediaStream.label')
  @DocsEditable
  final String label;

  @JSName('addEventListener')
  @DomName('MediaStream.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('MediaStream.addTrack')
  @DocsEditable
  void addTrack(MediaStreamTrack track) native;

  @DomName('MediaStream.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event event) native;

  @DomName('MediaStream.getAudioTracks')
  @DocsEditable
  List<MediaStreamTrack> getAudioTracks() native;

  @DomName('MediaStream.getTrackById')
  @DocsEditable
  MediaStreamTrack getTrackById(String trackId) native;

  @DomName('MediaStream.getVideoTracks')
  @DocsEditable
  List<MediaStreamTrack> getVideoTracks() native;

  @JSName('removeEventListener')
  @DomName('MediaStream.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('MediaStream.removeTrack')
  @DocsEditable
  void removeTrack(MediaStreamTrack track) native;

  @DomName('MediaStream.ended')
  @DocsEditable
  Stream<Event> get onEnded => endedEvent.forTarget(this);


  /**
   * Checks if the MediaStream APIs are supported on the current platform.
   *
   * See also:
   *
   * * [Navigator.getUserMedia]
   */
  static bool get supported =>
    JS('bool', '''!!(#.getUserMedia || #.webkitGetUserMedia ||
        #.mozGetUserMedia || #.msGetUserMedia)''',
        window.navigator,
        window.navigator,
        window.navigator,
        window.navigator);
}

@DocsEditable
@deprecated
class MediaStreamEvents extends Events {
  @DocsEditable
  MediaStreamEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get addTrack => this['addtrack'];

  @DocsEditable
  EventListenerList get ended => this['ended'];

  @DocsEditable
  EventListenerList get removeTrack => this['removetrack'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MediaStreamEvent')
class MediaStreamEvent extends Event native "*MediaStreamEvent" {

  /// Checks if this type is supported on the current platform.
  static bool get supported => Event._isTypeSupported('MediaStreamEvent');

  @DomName('MediaStreamEvent.stream')
  @DocsEditable
  final MediaStream stream;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MediaStreamTrack')
class MediaStreamTrack extends EventTarget native "*MediaStreamTrack" {

  @DomName('MediaStreamTrack.ended')
  @DocsEditable
  static const EventStreamProvider<Event> endedEvent = const EventStreamProvider<Event>('ended');

  @DomName('MediaStreamTrack.mute')
  @DocsEditable
  static const EventStreamProvider<Event> muteEvent = const EventStreamProvider<Event>('mute');

  @DomName('MediaStreamTrack.unmute')
  @DocsEditable
  static const EventStreamProvider<Event> unmuteEvent = const EventStreamProvider<Event>('unmute');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  MediaStreamTrackEvents get on =>
    new MediaStreamTrackEvents(this);

  static const int ENDED = 2;

  static const int LIVE = 0;

  static const int MUTED = 1;

  @DomName('MediaStreamTrack.enabled')
  @DocsEditable
  bool enabled;

  @DomName('MediaStreamTrack.id')
  @DocsEditable
  final String id;

  @DomName('MediaStreamTrack.kind')
  @DocsEditable
  final String kind;

  @DomName('MediaStreamTrack.label')
  @DocsEditable
  final String label;

  @DomName('MediaStreamTrack.readyState')
  @DocsEditable
  final int readyState;

  @JSName('addEventListener')
  @DomName('MediaStreamTrack.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('MediaStreamTrack.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event event) native;

  @JSName('removeEventListener')
  @DomName('MediaStreamTrack.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('MediaStreamTrack.ended')
  @DocsEditable
  Stream<Event> get onEnded => endedEvent.forTarget(this);

  @DomName('MediaStreamTrack.mute')
  @DocsEditable
  Stream<Event> get onMute => muteEvent.forTarget(this);

  @DomName('MediaStreamTrack.unmute')
  @DocsEditable
  Stream<Event> get onUnmute => unmuteEvent.forTarget(this);
}

@DocsEditable
@deprecated
class MediaStreamTrackEvents extends Events {
  @DocsEditable
  MediaStreamTrackEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get ended => this['ended'];

  @DocsEditable
  EventListenerList get mute => this['mute'];

  @DocsEditable
  EventListenerList get unmute => this['unmute'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MediaStreamTrackEvent')
class MediaStreamTrackEvent extends Event native "*MediaStreamTrackEvent" {

  /// Checks if this type is supported on the current platform.
  static bool get supported => Event._isTypeSupported('MediaStreamTrackEvent');

  @DomName('MediaStreamTrackEvent.track')
  @DocsEditable
  final MediaStreamTrack track;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MemoryInfo')
class MemoryInfo native "*MemoryInfo" {

  @DomName('MemoryInfo.jsHeapSizeLimit')
  @DocsEditable
  final int jsHeapSizeLimit;

  @DomName('MemoryInfo.totalJSHeapSize')
  @DocsEditable
  final int totalJSHeapSize;

  @DomName('MemoryInfo.usedJSHeapSize')
  @DocsEditable
  final int usedJSHeapSize;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLMenuElement')
class MenuElement extends Element native "*HTMLMenuElement" {

  @DocsEditable
  factory MenuElement() => document.$dom_createElement("menu");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MessageChannel')
class MessageChannel native "*MessageChannel" {

  @DocsEditable
  factory MessageChannel() => MessageChannel._create();
  static MessageChannel _create() => JS('MessageChannel', 'new MessageChannel()');

  @DomName('MessageChannel.port1')
  @DocsEditable
  final MessagePort port1;

  @DomName('MessageChannel.port2')
  @DocsEditable
  final MessagePort port2;
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('MessageEvent')
class MessageEvent extends Event native "*MessageEvent" {
  factory MessageEvent(String type,
      {bool canBubble: false, bool cancelable: false, Object data,
      String origin, String lastEventId,
      Window source, List messagePorts}) {
    if (source == null) {
      source = window;
    }
    var event = document.$dom_createEvent("MessageEvent");
    event.$dom_initMessageEvent(type, canBubble, cancelable, data, origin,
        lastEventId, source, messagePorts);
    return event;
  }

  dynamic get data => convertNativeToDart_SerializedScriptValue(this._data);
  @JSName('data')
  @DomName('MessageEvent.data')
  @DocsEditable
  @annotation_Creates_SerializedScriptValue
  @annotation_Returns_SerializedScriptValue
  final dynamic _data;

  @DomName('MessageEvent.lastEventId')
  @DocsEditable
  final String lastEventId;

  @DomName('MessageEvent.origin')
  @DocsEditable
  final String origin;

  @DomName('MessageEvent.ports')
  @DocsEditable
  @Creates('=List')
  final List ports;

  WindowBase get source => _convertNativeToDart_Window(this._source);
  @JSName('source')
  @DomName('MessageEvent.source')
  @DocsEditable
  @Creates('Window|=Object')
  @Returns('Window|=Object')
  final dynamic _source;

  @JSName('initMessageEvent')
  @DomName('MessageEvent.initMessageEvent')
  @DocsEditable
  void $dom_initMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, Window sourceArg, List messagePorts) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MessagePort')
class MessagePort extends EventTarget native "*MessagePort" {

  @DomName('MessagePort.message')
  @DocsEditable
  static const EventStreamProvider<MessageEvent> messageEvent = const EventStreamProvider<MessageEvent>('message');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  MessagePortEvents get on =>
    new MessagePortEvents(this);

  @JSName('addEventListener')
  @DomName('MessagePort.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('MessagePort.close')
  @DocsEditable
  void close() native;

  @DomName('MessagePort.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native;

  void postMessage(/*any*/ message, [List messagePorts]) {
    if (?messagePorts) {
      var message_1 = convertDartToNative_SerializedScriptValue(message);
      _postMessage_1(message_1, messagePorts);
      return;
    }
    var message_2 = convertDartToNative_SerializedScriptValue(message);
    _postMessage_2(message_2);
    return;
  }
  @JSName('postMessage')
  @DomName('MessagePort.postMessage')
  @DocsEditable
  void _postMessage_1(message, List messagePorts) native;
  @JSName('postMessage')
  @DomName('MessagePort.postMessage')
  @DocsEditable
  void _postMessage_2(message) native;

  @JSName('removeEventListener')
  @DomName('MessagePort.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('MessagePort.start')
  @DocsEditable
  void start() native;

  @DomName('MessagePort.message')
  @DocsEditable
  Stream<MessageEvent> get onMessage => messageEvent.forTarget(this);
}

@DocsEditable
@deprecated
class MessagePortEvents extends Events {
  @DocsEditable
  MessagePortEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get message => this['message'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLMetaElement')
class MetaElement extends Element native "*HTMLMetaElement" {

  @DomName('HTMLMetaElement.content')
  @DocsEditable
  String content;

  @DomName('HTMLMetaElement.httpEquiv')
  @DocsEditable
  String httpEquiv;

  @DomName('HTMLMetaElement.name')
  @DocsEditable
  String name;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Metadata')
class Metadata native "*Metadata" {

  @DomName('Metadata.modificationTime')
  @DocsEditable
  final Date modificationTime;

  @DomName('Metadata.size')
  @DocsEditable
  final int size;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void MetadataCallback(Metadata metadata);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLMeterElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
class MeterElement extends Element native "*HTMLMeterElement" {

  @DocsEditable
  factory MeterElement() => document.$dom_createElement("meter");

  /// Checks if this type is supported on the current platform.
  static bool get supported => Element.isTagSupported('meter');

  @DomName('HTMLMeterElement.high')
  @DocsEditable
  num high;

  @DomName('HTMLMeterElement.labels')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  final List<Node> labels;

  @DomName('HTMLMeterElement.low')
  @DocsEditable
  num low;

  @DomName('HTMLMeterElement.max')
  @DocsEditable
  num max;

  @DomName('HTMLMeterElement.min')
  @DocsEditable
  num min;

  @DomName('HTMLMeterElement.optimum')
  @DocsEditable
  num optimum;

  @DomName('HTMLMeterElement.value')
  @DocsEditable
  num value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLModElement')
class ModElement extends Element native "*HTMLModElement" {

  @DomName('HTMLModElement.cite')
  @DocsEditable
  String cite;

  @DomName('HTMLModElement.dateTime')
  @DocsEditable
  String dateTime;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('MouseEvent')
class MouseEvent extends UIEvent native "*MouseEvent" {
  factory MouseEvent(String type,
      {Window view, int detail: 0, int screenX: 0, int screenY: 0,
      int clientX: 0, int clientY: 0, int button: 0, bool canBubble: true,
      bool cancelable: true, bool ctrlKey: false, bool altKey: false,
      bool shiftKey: false, bool metaKey: false, EventTarget relatedTarget}) {

    if (view == null) {
      view = window;
    }
    var event = document.$dom_createEvent('MouseEvent');
    event.$dom_initMouseEvent(type, canBubble, cancelable, view, detail,
        screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey,
        button, relatedTarget);
    return event;
  }

  @DomName('MouseEvent.altKey')
  @DocsEditable
  final bool altKey;

  @DomName('MouseEvent.button')
  @DocsEditable
  final int button;

  @DomName('MouseEvent.clientX')
  @DocsEditable
  final int clientX;

  @DomName('MouseEvent.clientY')
  @DocsEditable
  final int clientY;

  @DomName('MouseEvent.ctrlKey')
  @DocsEditable
  final bool ctrlKey;

  @DomName('MouseEvent.dataTransfer')
  @DocsEditable
  final Clipboard dataTransfer;

  @DomName('MouseEvent.fromElement')
  @DocsEditable
  final Node fromElement;

  @DomName('MouseEvent.metaKey')
  @DocsEditable
  final bool metaKey;

  EventTarget get relatedTarget => _convertNativeToDart_EventTarget(this._relatedTarget);
  @JSName('relatedTarget')
  @DomName('MouseEvent.relatedTarget')
  @DocsEditable
  @Creates('Node')
  @Returns('EventTarget|=Object')
  final dynamic _relatedTarget;

  @DomName('MouseEvent.screenX')
  @DocsEditable
  final int screenX;

  @DomName('MouseEvent.screenY')
  @DocsEditable
  final int screenY;

  @DomName('MouseEvent.shiftKey')
  @DocsEditable
  final bool shiftKey;

  @DomName('MouseEvent.toElement')
  @DocsEditable
  final Node toElement;

  @DomName('MouseEvent.webkitMovementX')
  @DocsEditable
  final int webkitMovementX;

  @DomName('MouseEvent.webkitMovementY')
  @DocsEditable
  final int webkitMovementY;

  @DomName('MouseEvent.x')
  @DocsEditable
  final int x;

  @DomName('MouseEvent.y')
  @DocsEditable
  final int y;

  void $dom_initMouseEvent(String type, bool canBubble, bool cancelable, Window view, int detail, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, int button, EventTarget relatedTarget) {
    var relatedTarget_1 = _convertDartToNative_EventTarget(relatedTarget);
    _$dom_initMouseEvent_1(type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget_1);
    return;
  }
  @JSName('initMouseEvent')
  @DomName('MouseEvent.initMouseEvent')
  @DocsEditable
  void _$dom_initMouseEvent_1(type, canBubble, cancelable, Window view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget) native;


  int get offsetX {
  if (JS('bool', '!!#.offsetX', this)) {
      return JS('int', '#.offsetX', this);
    } else {
      // Firefox does not support offsetX.
      var target = this.target;
      if (!(target is Element)) {
        throw new UnsupportedError(
            'offsetX is only supported on elements');
      }
      return this.clientX - this.target.getBoundingClientRect().left;
    }
  }

  int get offsetY {
    if (JS('bool', '!!#.offsetY', this)) {
      return JS('int', '#.offsetY', this);
    } else {
      // Firefox does not support offsetY.
      var target = this.target;
      if (!(target is Element)) {
        throw new UnsupportedError(
            'offsetY is only supported on elements');
      }
      return this.clientY - this.target.getBoundingClientRect().top;
    }
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void MutationCallback(List<MutationRecord> mutations, MutationObserver observer);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('MutationEvent')
class MutationEvent extends Event native "*MutationEvent" {
  factory MutationEvent(String type,
      {bool canBubble: false, bool cancelable: false, Node relatedNode,
      String prevValue, String newValue, String attrName, int attrChange: 0}) {

    var event = document.$dom_createEvent('MutationEvent');
    event.$dom_initMutationEvent(type, canBubble, cancelable, relatedNode,
        prevValue, newValue, attrName, attrChange);
    return event;
  }

  static const int ADDITION = 2;

  static const int MODIFICATION = 1;

  static const int REMOVAL = 3;

  @DomName('MutationEvent.attrChange')
  @DocsEditable
  final int attrChange;

  @DomName('MutationEvent.attrName')
  @DocsEditable
  final String attrName;

  @DomName('MutationEvent.newValue')
  @DocsEditable
  final String newValue;

  @DomName('MutationEvent.prevValue')
  @DocsEditable
  final String prevValue;

  @DomName('MutationEvent.relatedNode')
  @DocsEditable
  final Node relatedNode;

  @JSName('initMutationEvent')
  @DomName('MutationEvent.initMutationEvent')
  @DocsEditable
  void $dom_initMutationEvent(String type, bool canBubble, bool cancelable, Node relatedNode, String prevValue, String newValue, String attrName, int attrChange) native;

}



// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('MutationObserver')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class MutationObserver native "*MutationObserver" {

  @DocsEditable
  factory MutationObserver(MutationCallback callback) => MutationObserver._create(callback);

  @DomName('MutationObserver.disconnect')
  @DocsEditable
  void disconnect() native;

  void _observe(Node target, Map options) {
    var options_1 = convertDartToNative_Dictionary(options);
    __observe_1(target, options_1);
    return;
  }
  @JSName('observe')
  @DomName('MutationObserver.observe')
  @DocsEditable
  void __observe_1(Node target, options) native;

  @DomName('MutationObserver.takeRecords')
  @DocsEditable
  List<MutationRecord> takeRecords() native;

  /**
   * Checks to see if the mutation observer API is supported on the current
   * platform.
   */
  static bool get supported {
    return JS('bool',
        '!!(window.MutationObserver || window.WebKitMutationObserver)');
  }

  void observe(Node target,
               {Map options,
                bool childList,
                bool attributes,
                bool characterData,
                bool subtree,
                bool attributeOldValue,
                bool characterDataOldValue,
                List<String> attributeFilter}) {

    // Parse options into map of known type.
    var parsedOptions = _createDict();

    if (options != null) {
      options.forEach((k, v) {
          if (_boolKeys.containsKey(k)) {
            _add(parsedOptions, k, true == v);
          } else if (k == 'attributeFilter') {
            _add(parsedOptions, k, _fixupList(v));
          } else {
            throw new ArgumentError(
                "Illegal MutationObserver.observe option '$k'");
          }
        });
    }

    // Override options passed in the map with named optional arguments.
    override(key, value) {
      if (value != null) _add(parsedOptions, key, value);
    }

    override('childList', childList);
    override('attributes', attributes);
    override('characterData', characterData);
    override('subtree', subtree);
    override('attributeOldValue', attributeOldValue);
    override('characterDataOldValue', characterDataOldValue);
    if (attributeFilter != null) {
      override('attributeFilter', _fixupList(attributeFilter));
    }

    _call(target, parsedOptions);
  }

   // TODO: Change to a set when const Sets are available.
  static final _boolKeys =
    const {'childList': true,
           'attributes': true,
           'characterData': true,
           'subtree': true,
           'attributeOldValue': true,
           'characterDataOldValue': true };


  static _createDict() => JS('var', '{}');
  static _add(m, String key, value) { JS('void', '#[#] = #', m, key, value); }
  static _fixupList(list) => list;  // TODO: Ensure is a JavaScript Array.

  // Call native function with no conversions.
  @JSName('observe')
  void _call(target, options) native;

  static MutationObserver _create(MutationCallback callback) {
    // Dummy statement to mark types as instantiated.
    JS('MutationObserver|MutationRecord', '0');

    return JS('MutationObserver',
        'new(window.MutationObserver||window.WebKitMutationObserver||'
        'window.MozMutationObserver)(#)',
        convertDartClosureToJS(callback, 2));
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MutationRecord')
class MutationRecord native "*MutationRecord" {

  @DomName('MutationRecord.addedNodes')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  final List<Node> addedNodes;

  @DomName('MutationRecord.attributeName')
  @DocsEditable
  final String attributeName;

  @DomName('MutationRecord.attributeNamespace')
  @DocsEditable
  final String attributeNamespace;

  @DomName('MutationRecord.nextSibling')
  @DocsEditable
  final Node nextSibling;

  @DomName('MutationRecord.oldValue')
  @DocsEditable
  final String oldValue;

  @DomName('MutationRecord.previousSibling')
  @DocsEditable
  final Node previousSibling;

  @DomName('MutationRecord.removedNodes')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  final List<Node> removedNodes;

  @DomName('MutationRecord.target')
  @DocsEditable
  final Node target;

  @DomName('MutationRecord.type')
  @DocsEditable
  final String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('NamedNodeMap')
class NamedNodeMap implements JavaScriptIndexingBehavior, List<Node> native "*NamedNodeMap" {

  @DomName('NamedNodeMap.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  Node operator[](int index) => JS("Node", "#[#]", this, index);

  void operator[]=(int index, Node value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Node> mixins.
  // Node is the element type.

  // From Iterable<Node>:

  Iterator<Node> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Node>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, Node)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(Node element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(Node element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(Node element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<Node> where(bool f(Node element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(Node element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(Node element)) => IterableMixinWorkaround.any(this, f);

  List<Node> toList() => new List<Node>.from(this);
  Set<Node> toSet() => new Set<Node>.from(this);

  bool get isEmpty => this.length == 0;

  List<Node> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<Node> takeWhile(bool test(Node value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<Node> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<Node> skipWhile(bool test(Node value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  Node firstMatching(bool test(Node value), { Node orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  Node lastMatching(bool test(Node value), {Node orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  Node singleMatching(bool test(Node value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  Node elementAt(int index) {
    return this[index];
  }

  // From Collection<Node>:

  void add(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<Node> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<Node>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<Node> get reversed =>
      new ReversedListView<Node>(this, 0, null);

  void sort([int compare(Node a, Node b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Node element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Node element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  Node get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  Node get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  Node get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Node min([int compare(Node a, Node b)]) =>
      IterableMixinWorkaround.min(this, compare);

  Node max([int compare(Node a, Node b)]) =>
      IterableMixinWorkaround.max(this, compare);

  Node removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  Node removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(Node element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(Node element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<Node> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Node initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Node> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <Node>[]);

  // -- end List<Node> mixins.

  @DomName('NamedNodeMap.getNamedItem')
  @DocsEditable
  Node getNamedItem(String name) native;

  @DomName('NamedNodeMap.getNamedItemNS')
  @DocsEditable
  Node getNamedItemNS(String namespaceURI, String localName) native;

  @DomName('NamedNodeMap.item')
  @DocsEditable
  Node item(int index) native;

  @DomName('NamedNodeMap.removeNamedItem')
  @DocsEditable
  Node removeNamedItem(String name) native;

  @DomName('NamedNodeMap.removeNamedItemNS')
  @DocsEditable
  Node removeNamedItemNS(String namespaceURI, String localName) native;

  @DomName('NamedNodeMap.setNamedItem')
  @DocsEditable
  Node setNamedItem(Node node) native;

  @DomName('NamedNodeMap.setNamedItemNS')
  @DocsEditable
  Node setNamedItemNS(Node node) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('Navigator')
class Navigator native "*Navigator" {

  @DomName('Navigator.language')
  String get language => JS('String', '#.language || #.userLanguage', this,
      this);

  /**
   * Gets a stream (video and or audio) from the local computer.
   *
   * Use [MediaStream.supported] to check if this is supported by the current
   * platform.
   *
   * Example use:
   *
   *     window.navigator.getUserMedia(audio:true, video: true).then((stream) {
   *       var video = new VideoElement()
   *         ..autoplay = true
   *         ..src = Url.createObjectUrl(stream);
   *       document.body.append(video);
   *     });
   *
   * See also:
   * * [MediaStream.supported]
   */
  @DomName('Navigator.webkitGetUserMedia')
  @SupportedBrowser(SupportedBrowser.CHROME)
  @Experimental
  Future<LocalMediaStream> getUserMedia({bool audio: false,
      bool video: false}) {
    var completer = new Completer<LocalMediaStream>();
    var options = {
      'audio': audio,
      'video': video
    };
    _ensureGetUserMedia();
    this._getUserMedia(convertDartToNative_Dictionary(options),
      (stream) {
        completer.complete(stream);
      },
      (error) {
        completer.completeError(error);
      });
    return completer.future;
  }

  _ensureGetUserMedia() {
    if (JS('bool', '!(#.getUserMedia)', this)) {
      JS('void', '#.getUserMedia = '
          '(#.getUserMedia || #.webkitGetUserMedia || #.mozGetUserMedia ||'
          '#.msGetUserMedia)', this, this, this, this, this);
    }
  }

  @JSName('getUserMedia')
  void _getUserMedia(options, _NavigatorUserMediaSuccessCallback success,
      _NavigatorUserMediaErrorCallback error) native;


  @DomName('Navigator.appCodeName')
  @DocsEditable
  final String appCodeName;

  @DomName('Navigator.appName')
  @DocsEditable
  final String appName;

  @DomName('Navigator.appVersion')
  @DocsEditable
  final String appVersion;

  @DomName('Navigator.cookieEnabled')
  @DocsEditable
  final bool cookieEnabled;

  @DomName('Navigator.geolocation')
  @DocsEditable
  final Geolocation geolocation;

  @DomName('Navigator.mimeTypes')
  @DocsEditable
  final DomMimeTypeArray mimeTypes;

  @DomName('Navigator.onLine')
  @DocsEditable
  final bool onLine;

  @DomName('Navigator.platform')
  @DocsEditable
  final String platform;

  @DomName('Navigator.plugins')
  @DocsEditable
  final DomPluginArray plugins;

  @DomName('Navigator.product')
  @DocsEditable
  final String product;

  @DomName('Navigator.productSub')
  @DocsEditable
  final String productSub;

  @DomName('Navigator.userAgent')
  @DocsEditable
  final String userAgent;

  @DomName('Navigator.vendor')
  @DocsEditable
  final String vendor;

  @DomName('Navigator.vendorSub')
  @DocsEditable
  final String vendorSub;

  @DomName('Navigator.webkitBattery')
  @DocsEditable
  final BatteryManager webkitBattery;

  @DomName('Navigator.getStorageUpdates')
  @DocsEditable
  void getStorageUpdates() native;

  @DomName('Navigator.javaEnabled')
  @DocsEditable
  bool javaEnabled() native;

  @DomName('Navigator.webkitGetGamepads')
  @DocsEditable
  @Returns('_GamepadList')
  @Creates('_GamepadList')
  List<Gamepad> webkitGetGamepads() native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('NavigatorUserMediaError')
class NavigatorUserMediaError native "*NavigatorUserMediaError" {

  static const int PERMISSION_DENIED = 1;

  @DomName('NavigatorUserMediaError.code')
  @DocsEditable
  final int code;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void _NavigatorUserMediaErrorCallback(NavigatorUserMediaError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void _NavigatorUserMediaSuccessCallback(LocalMediaStream stream);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Lazy implementation of the child nodes of an element that does not request
 * the actual child nodes of an element until strictly necessary greatly
 * improving performance for the typical cases where it is not required.
 */
class _ChildNodeListLazy implements List {
  final Node _this;

  _ChildNodeListLazy(this._this);


  Node get first {
    Node result = JS('Node', '#.firstChild', _this);
    if (result == null) throw new StateError("No elements");
    return result;
  }
  Node get last {
    Node result = JS('Node', '#.lastChild', _this);
    if (result == null) throw new StateError("No elements");
    return result;
  }
  Node get single {
    int l = this.length;
    if (l == 0) throw new StateError("No elements");
    if (l > 1) throw new StateError("More than one element");
    return JS('Node', '#.firstChild', _this);
  }

  Node min([int compare(Node a, Node b)]) {
    return IterableMixinWorkaround.min(this, compare);
  }

  Node max([int compare(Node a, Node b)]) {
    return IterableMixinWorkaround.max(this, compare);
  }

  void add(Node value) {
    _this.$dom_appendChild(value);
  }

  void addLast(Node value) {
    _this.$dom_appendChild(value);
  }


  void addAll(Iterable<Node> iterable) {
    for (Node node in iterable) {
      _this.$dom_appendChild(node);
    }
  }

  Node removeLast() {
    final result = last;
    if (result != null) {
      _this.$dom_removeChild(result);
    }
    return result;
  }

  Node removeAt(int index) {
    var result = this[index];
    if (result != null) {
      _this.$dom_removeChild(result);
    }
    return result;
  }

  void remove(Object object) {
    if (object is! Node) return;
    Node node = object;
    if (!identical(this, node.parentNode)) return;
    _this.$dom_removeChild(node);
  }

  void removeAll(Iterable elements) {
    IterableMixinWorkaround.removeAll(this, elements);
  }

  void retainAll(Iterable elements) {
    IterableMixinWorkaround.retainAll(this, elements);
  }

  void removeMatching(bool test(Node node)) {
    IterableMixinWorkaround.removeMatching(this, test);
  }

  void retainMatching(bool test(Node node)) {
    IterableMixinWorkaround.retainMatching(this, test);
  }

  void clear() {
    _this.text = '';
  }

  void operator []=(int index, Node value) {
    _this.$dom_replaceChild(value, this[index]);
  }

  Iterator<Node> get iterator => _this.$dom_childNodes.iterator;

  // TODO(jacobr): We can implement these methods much more efficiently by
  // looking up the nodeList only once instead of once per iteration.
  bool contains(Node element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(Node element)) => IterableMixinWorkaround.forEach(this, f);

  dynamic reduce(dynamic initialValue,
      dynamic combine(dynamic previousValue, Node element)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  String join([String separator]) {
    return IterableMixinWorkaround.joinList(this, separator);
  }

  List mappedBy(f(Node element)) {
    return IterableMixinWorkaround.mappedByList(this, f);
  }

  Iterable<Node> where(bool f(Node element)) {
    return IterableMixinWorkaround.where(this, f);
  }

  bool every(bool f(Node element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(Node element)) => IterableMixinWorkaround.any(this, f);

  List<Node> toList() => new List<Node>.from(this);
  Set<Node> toSet() => new Set<Node>.from(this);

  bool get isEmpty => this.length == 0;

  // From List<Node>:

  List<Node> take(int n) {
    return IterableMixinWorkaround.takeList(this, n);
  }

  Iterable<Node> takeWhile(bool test(Node value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<Node> skip(int n) {
    return IterableMixinWorkaround.skipList(this, n);
  }

  Iterable<Node> skipWhile(bool test(Node value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  Node firstMatching(bool test(Node value), {Node orElse()}) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  Node lastMatching(bool test(Node value), {Node orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  Node singleMatching(bool test(Node value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  Node elementAt(int index) {
    return this[index];
  }

  List<Node> get reversed =>
      new ReversedListView<Node>(this, 0, null);

  // TODO(jacobr): this could be implemented for child node lists.
  // The exception we throw here is misleading.
  void sort([int compare(Node a, Node b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Node element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Node element, [int start = 0]) =>
      Lists.lastIndexOf(this, element, start);

  // FIXME: implement these.
  void setRange(int start, int rangeLength, List<Node> from, [int startFrom]) {
    throw new UnsupportedError(
        "Cannot setRange on immutable List.");
  }
  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError(
        "Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int rangeLength, [Node initialValue]) {
    throw new UnsupportedError(
        "Cannot insertRange on immutable List.");
  }
  List<Node> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <Node>[]);

  // -- end List<Node> mixins.

  // TODO(jacobr): benchmark whether this is more efficient or whether caching
  // a local copy of $dom_childNodes is more efficient.
  int get length => _this.$dom_childNodes.length;

  void set length(int value) {
    throw new UnsupportedError(
        "Cannot set length on immutable List.");
  }

  Node operator[](int index) => _this.$dom_childNodes[index];
}

@DomName('Node')
class Node extends EventTarget native "*Node" {
  List<Node> get nodes {
    return new _ChildNodeListLazy(this);
  }

  void set nodes(Collection<Node> value) {
    // Copy list first since we don't want liveness during iteration.
    // TODO(jacobr): there is a better way to do this.
    List copy = new List.from(value);
    text = '';
    for (Node node in copy) {
      $dom_appendChild(node);
    }
  }

  /**
   * Removes this node from the DOM.
   */
  @DomName('Node.removeChild')
  void remove() {
    // TODO(jacobr): should we throw an exception if parent is already null?
    // TODO(vsm): Use the native remove when available.
    if (this.parentNode != null) {
      final Node parent = this.parentNode;
      parentNode.$dom_removeChild(this);
    }
  }

  /**
   * Replaces this node with another node.
   */
  @DomName('Node.replaceChild')
  Node replaceWith(Node otherNode) {
    try {
      final Node parent = this.parentNode;
      parent.$dom_replaceChild(otherNode, this);
    } catch (e) {

    };
    return this;
  }


  @JSName('attributes')
  @DomName('Node.attributes')
  @DocsEditable
  final NamedNodeMap $dom_attributes;

  @JSName('childNodes')
  @DomName('Node.childNodes')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  final List<Node> $dom_childNodes;

  @JSName('firstChild')
  @DomName('Node.firstChild')
  @DocsEditable
  final Node $dom_firstChild;

  @JSName('lastChild')
  @DomName('Node.lastChild')
  @DocsEditable
  final Node $dom_lastChild;

  @JSName('localName')
  @DomName('Node.localName')
  @DocsEditable
  final String $dom_localName;

  @JSName('namespaceURI')
  @DomName('Node.namespaceURI')
  @DocsEditable
  final String $dom_namespaceUri;

  @JSName('nextSibling')
  @DomName('Node.nextSibling')
  @DocsEditable
  final Node nextNode;

  @DomName('Node.nodeType')
  @DocsEditable
  final int nodeType;

  @DomName('Node.nodeValue')
  @DocsEditable
  final String nodeValue;

  @JSName('ownerDocument')
  @DomName('Node.ownerDocument')
  @DocsEditable
  final Document document;

  @JSName('parentElement')
  @DomName('Node.parentElement')
  @DocsEditable
  final Element parent;

  @DomName('Node.parentNode')
  @DocsEditable
  final Node parentNode;

  @JSName('previousSibling')
  @DomName('Node.previousSibling')
  @DocsEditable
  final Node previousNode;

  @JSName('textContent')
  @DomName('Node.textContent')
  @DocsEditable
  String text;

  @JSName('addEventListener')
  @DomName('Node.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('appendChild')
  @DomName('Node.appendChild')
  @DocsEditable
  Node $dom_appendChild(Node newChild) native;

  @JSName('cloneNode')
  @DomName('Node.cloneNode')
  @DocsEditable
  Node clone(bool deep) native;

  @DomName('Node.contains')
  @DocsEditable
  bool contains(Node other) native;

  @DomName('Node.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event event) native;

  @DomName('Node.hasChildNodes')
  @DocsEditable
  bool hasChildNodes() native;

  @DomName('Node.insertBefore')
  @DocsEditable
  Node insertBefore(Node newChild, Node refChild) native;

  @JSName('removeChild')
  @DomName('Node.removeChild')
  @DocsEditable
  Node $dom_removeChild(Node oldChild) native;

  @JSName('removeEventListener')
  @DomName('Node.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('replaceChild')
  @DomName('Node.replaceChild')
  @DocsEditable
  Node $dom_replaceChild(Node newChild, Node oldChild) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('NodeFilter')
class NodeFilter native "*NodeFilter" {

  static const int FILTER_ACCEPT = 1;

  static const int FILTER_REJECT = 2;

  static const int FILTER_SKIP = 3;

  static const int SHOW_ALL = 0xFFFFFFFF;

  static const int SHOW_ATTRIBUTE = 0x00000002;

  static const int SHOW_CDATA_SECTION = 0x00000008;

  static const int SHOW_COMMENT = 0x00000080;

  static const int SHOW_DOCUMENT = 0x00000100;

  static const int SHOW_DOCUMENT_FRAGMENT = 0x00000400;

  static const int SHOW_DOCUMENT_TYPE = 0x00000200;

  static const int SHOW_ELEMENT = 0x00000001;

  static const int SHOW_ENTITY = 0x00000020;

  static const int SHOW_ENTITY_REFERENCE = 0x00000010;

  static const int SHOW_NOTATION = 0x00000800;

  static const int SHOW_PROCESSING_INSTRUCTION = 0x00000040;

  static const int SHOW_TEXT = 0x00000004;

  @DomName('NodeFilter.acceptNode')
  @DocsEditable
  int acceptNode(Node n) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('NodeIterator')
class NodeIterator native "*NodeIterator" {

  @DomName('NodeIterator.expandEntityReferences')
  @DocsEditable
  final bool expandEntityReferences;

  @DomName('NodeIterator.filter')
  @DocsEditable
  final NodeFilter filter;

  @DomName('NodeIterator.pointerBeforeReferenceNode')
  @DocsEditable
  final bool pointerBeforeReferenceNode;

  @DomName('NodeIterator.referenceNode')
  @DocsEditable
  final Node referenceNode;

  @DomName('NodeIterator.root')
  @DocsEditable
  final Node root;

  @DomName('NodeIterator.whatToShow')
  @DocsEditable
  final int whatToShow;

  @DomName('NodeIterator.detach')
  @DocsEditable
  void detach() native;

  @DomName('NodeIterator.nextNode')
  @DocsEditable
  Node nextNode() native;

  @DomName('NodeIterator.previousNode')
  @DocsEditable
  Node previousNode() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('NodeList')
class NodeList implements JavaScriptIndexingBehavior, List<Node> native "*NodeList" {

  @DomName('NodeList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  Node operator[](int index) => JS("Node", "#[#]", this, index);

  void operator[]=(int index, Node value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Node> mixins.
  // Node is the element type.

  // From Iterable<Node>:

  Iterator<Node> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Node>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, Node)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(Node element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(Node element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(Node element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<Node> where(bool f(Node element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(Node element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(Node element)) => IterableMixinWorkaround.any(this, f);

  List<Node> toList() => new List<Node>.from(this);
  Set<Node> toSet() => new Set<Node>.from(this);

  bool get isEmpty => this.length == 0;

  List<Node> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<Node> takeWhile(bool test(Node value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<Node> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<Node> skipWhile(bool test(Node value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  Node firstMatching(bool test(Node value), { Node orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  Node lastMatching(bool test(Node value), {Node orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  Node singleMatching(bool test(Node value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  Node elementAt(int index) {
    return this[index];
  }

  // From Collection<Node>:

  void add(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<Node> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<Node>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<Node> get reversed =>
      new ReversedListView<Node>(this, 0, null);

  void sort([int compare(Node a, Node b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Node element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Node element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  Node get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  Node get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  Node get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Node min([int compare(Node a, Node b)]) =>
      IterableMixinWorkaround.min(this, compare);

  Node max([int compare(Node a, Node b)]) =>
      IterableMixinWorkaround.max(this, compare);

  Node removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  Node removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(Node element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(Node element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<Node> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Node initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Node> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <Node>[]);

  // -- end List<Node> mixins.

  @JSName('item')
  @DomName('NodeList.item')
  @DocsEditable
  Node _item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Notation')
class Notation extends Node native "*Notation" {

  @DomName('Notation.publicId')
  @DocsEditable
  final String publicId;

  @DomName('Notation.systemId')
  @DocsEditable
  final String systemId;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Notification')
class Notification extends EventTarget native "*Notification" {

  @DomName('Notification.click')
  @DocsEditable
  static const EventStreamProvider<Event> clickEvent = const EventStreamProvider<Event>('click');

  @DomName('Notification.close')
  @DocsEditable
  static const EventStreamProvider<Event> closeEvent = const EventStreamProvider<Event>('close');

  @DomName('Notification.display')
  @DocsEditable
  static const EventStreamProvider<Event> displayEvent = const EventStreamProvider<Event>('display');

  @DomName('Notification.error')
  @DocsEditable
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DomName('Notification.show')
  @DocsEditable
  static const EventStreamProvider<Event> showEvent = const EventStreamProvider<Event>('show');

  @DocsEditable
  factory Notification(String title, [Map options]) {
    if (!?options) {
      return Notification._create(title);
    }
    return Notification._create(title, options);
  }
  static Notification _create(String title, [Map options]) {
    if (!?options) {
      return JS('Notification', 'new Notification(#)', title);
    }
    return JS('Notification', 'new Notification(#,#)', title, options);
  }

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  NotificationEvents get on =>
    new NotificationEvents(this);

  @DomName('Notification.dir')
  @DocsEditable
  String dir;

  @DomName('Notification.permission')
  @DocsEditable
  final String permission;

  @DomName('Notification.replaceId')
  @DocsEditable
  String replaceId;

  @DomName('Notification.tag')
  @DocsEditable
  String tag;

  @JSName('addEventListener')
  @DomName('Notification.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('Notification.cancel')
  @DocsEditable
  void cancel() native;

  @DomName('Notification.close')
  @DocsEditable
  void close() native;

  @DomName('Notification.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native;

  @JSName('removeEventListener')
  @DomName('Notification.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('Notification.requestPermission')
  @DocsEditable
  static void requestPermission(NotificationPermissionCallback callback) native;

  @DomName('Notification.show')
  @DocsEditable
  void show() native;

  @DomName('Notification.click')
  @DocsEditable
  Stream<Event> get onClick => clickEvent.forTarget(this);

  @DomName('Notification.close')
  @DocsEditable
  Stream<Event> get onClose => closeEvent.forTarget(this);

  @DomName('Notification.display')
  @DocsEditable
  Stream<Event> get onDisplay => displayEvent.forTarget(this);

  @DomName('Notification.error')
  @DocsEditable
  Stream<Event> get onError => errorEvent.forTarget(this);

  @DomName('Notification.show')
  @DocsEditable
  Stream<Event> get onShow => showEvent.forTarget(this);
}

@DocsEditable
@deprecated
class NotificationEvents extends Events {
  @DocsEditable
  NotificationEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get click => this['click'];

  @DocsEditable
  EventListenerList get close => this['close'];

  @DocsEditable
  EventListenerList get display => this['display'];

  @DocsEditable
  EventListenerList get error => this['error'];

  @DocsEditable
  EventListenerList get show => this['show'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('NotificationCenter')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class NotificationCenter native "*NotificationCenter" {

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.webkitNotifications)');

  @DomName('NotificationCenter.checkPermission')
  @DocsEditable
  int checkPermission() native;

  @JSName('createHTMLNotification')
  @DomName('NotificationCenter.createHTMLNotification')
  @DocsEditable
  Notification createHtmlNotification(String url) native;

  @DomName('NotificationCenter.createNotification')
  @DocsEditable
  Notification createNotification(String iconUrl, String title, String body) native;

  @DomName('NotificationCenter.requestPermission')
  @DocsEditable
  void requestPermission(VoidCallback callback) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void NotificationPermissionCallback(String permission);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLOListElement')
class OListElement extends Element native "*HTMLOListElement" {

  @DocsEditable
  factory OListElement() => document.$dom_createElement("ol");

  @DomName('HTMLOListElement.reversed')
  @DocsEditable
  bool reversed;

  @DomName('HTMLOListElement.start')
  @DocsEditable
  int start;

  @DomName('HTMLOListElement.type')
  @DocsEditable
  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLObjectElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
class ObjectElement extends Element native "*HTMLObjectElement" {

  @DocsEditable
  factory ObjectElement() => document.$dom_createElement("object");

  /// Checks if this type is supported on the current platform.
  static bool get supported => Element.isTagSupported('object');

  @DomName('HTMLObjectElement.code')
  @DocsEditable
  String code;

  @DomName('HTMLObjectElement.data')
  @DocsEditable
  String data;

  @DomName('HTMLObjectElement.form')
  @DocsEditable
  final FormElement form;

  @DomName('HTMLObjectElement.height')
  @DocsEditable
  String height;

  @DomName('HTMLObjectElement.name')
  @DocsEditable
  String name;

  @DomName('HTMLObjectElement.type')
  @DocsEditable
  String type;

  @DomName('HTMLObjectElement.useMap')
  @DocsEditable
  String useMap;

  @DomName('HTMLObjectElement.validationMessage')
  @DocsEditable
  final String validationMessage;

  @DomName('HTMLObjectElement.validity')
  @DocsEditable
  final ValidityState validity;

  @DomName('HTMLObjectElement.width')
  @DocsEditable
  String width;

  @DomName('HTMLObjectElement.willValidate')
  @DocsEditable
  final bool willValidate;

  @DomName('HTMLObjectElement.checkValidity')
  @DocsEditable
  bool checkValidity() native;

  @DomName('HTMLObjectElement.setCustomValidity')
  @DocsEditable
  void setCustomValidity(String error) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('OESElementIndexUint')
class OesElementIndexUint native "*OESElementIndexUint" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('OESStandardDerivatives')
class OesStandardDerivatives native "*OESStandardDerivatives" {

  static const int FRAGMENT_SHADER_DERIVATIVE_HINT_OES = 0x8B8B;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('OESTextureFloat')
class OesTextureFloat native "*OESTextureFloat" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('OESVertexArrayObject')
class OesVertexArrayObject native "*OESVertexArrayObject" {

  static const int VERTEX_ARRAY_BINDING_OES = 0x85B5;

  @JSName('bindVertexArrayOES')
  @DomName('OESVertexArrayObject.bindVertexArrayOES')
  @DocsEditable
  void bindVertexArray(WebGLVertexArrayObject arrayObject) native;

  @JSName('createVertexArrayOES')
  @DomName('OESVertexArrayObject.createVertexArrayOES')
  @DocsEditable
  WebGLVertexArrayObject createVertexArray() native;

  @JSName('deleteVertexArrayOES')
  @DomName('OESVertexArrayObject.deleteVertexArrayOES')
  @DocsEditable
  void deleteVertexArray(WebGLVertexArrayObject arrayObject) native;

  @JSName('isVertexArrayOES')
  @DomName('OESVertexArrayObject.isVertexArrayOES')
  @DocsEditable
  bool isVertexArray(WebGLVertexArrayObject arrayObject) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLOptGroupElement')
class OptGroupElement extends Element native "*HTMLOptGroupElement" {

  @DocsEditable
  factory OptGroupElement() => document.$dom_createElement("optgroup");

  @DomName('HTMLOptGroupElement.disabled')
  @DocsEditable
  bool disabled;

  @DomName('HTMLOptGroupElement.label')
  @DocsEditable
  String label;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLOptionElement')
class OptionElement extends Element native "*HTMLOptionElement" {

  @DocsEditable
  factory OptionElement([String data, String value, bool defaultSelected, bool selected]) {
    if (!?data) {
      return OptionElement._create();
    }
    if (!?value) {
      return OptionElement._create(data);
    }
    if (!?defaultSelected) {
      return OptionElement._create(data, value);
    }
    if (!?selected) {
      return OptionElement._create(data, value, defaultSelected);
    }
    return OptionElement._create(data, value, defaultSelected, selected);
  }
  static OptionElement _create([String data, String value, bool defaultSelected, bool selected]) {
    if (!?data) {
      return JS('OptionElement', 'new Option()');
    }
    if (!?value) {
      return JS('OptionElement', 'new Option(#)', data);
    }
    if (!?defaultSelected) {
      return JS('OptionElement', 'new Option(#,#)', data, value);
    }
    if (!?selected) {
      return JS('OptionElement', 'new Option(#,#,#)', data, value, defaultSelected);
    }
    return JS('OptionElement', 'new Option(#,#,#,#)', data, value, defaultSelected, selected);
  }

  @DomName('HTMLOptionElement.defaultSelected')
  @DocsEditable
  bool defaultSelected;

  @DomName('HTMLOptionElement.disabled')
  @DocsEditable
  bool disabled;

  @DomName('HTMLOptionElement.form')
  @DocsEditable
  final FormElement form;

  @DomName('HTMLOptionElement.index')
  @DocsEditable
  final int index;

  @DomName('HTMLOptionElement.label')
  @DocsEditable
  String label;

  @DomName('HTMLOptionElement.selected')
  @DocsEditable
  bool selected;

  @DomName('HTMLOptionElement.value')
  @DocsEditable
  String value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLOutputElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
class OutputElement extends Element native "*HTMLOutputElement" {

  @DocsEditable
  factory OutputElement() => document.$dom_createElement("output");

  /// Checks if this type is supported on the current platform.
  static bool get supported => Element.isTagSupported('output');

  @DomName('HTMLOutputElement.defaultValue')
  @DocsEditable
  String defaultValue;

  @DomName('HTMLOutputElement.form')
  @DocsEditable
  final FormElement form;

  @DomName('HTMLOutputElement.htmlFor')
  @DocsEditable
  DomSettableTokenList htmlFor;

  @DomName('HTMLOutputElement.labels')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  final List<Node> labels;

  @DomName('HTMLOutputElement.name')
  @DocsEditable
  String name;

  @DomName('HTMLOutputElement.type')
  @DocsEditable
  final String type;

  @DomName('HTMLOutputElement.validationMessage')
  @DocsEditable
  final String validationMessage;

  @DomName('HTMLOutputElement.validity')
  @DocsEditable
  final ValidityState validity;

  @DomName('HTMLOutputElement.value')
  @DocsEditable
  String value;

  @DomName('HTMLOutputElement.willValidate')
  @DocsEditable
  final bool willValidate;

  @DomName('HTMLOutputElement.checkValidity')
  @DocsEditable
  bool checkValidity() native;

  @DomName('HTMLOutputElement.setCustomValidity')
  @DocsEditable
  void setCustomValidity(String error) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('OverflowEvent')
class OverflowEvent extends Event native "*OverflowEvent" {

  static const int BOTH = 2;

  static const int HORIZONTAL = 0;

  static const int VERTICAL = 1;

  @DomName('OverflowEvent.horizontalOverflow')
  @DocsEditable
  final bool horizontalOverflow;

  @DomName('OverflowEvent.orient')
  @DocsEditable
  final int orient;

  @DomName('OverflowEvent.verticalOverflow')
  @DocsEditable
  final bool verticalOverflow;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('PagePopupController')
class PagePopupController native "*PagePopupController" {

  @DomName('PagePopupController.formatMonth')
  @DocsEditable
  String formatMonth(int year, int zeroBaseMonth) native;

  @DomName('PagePopupController.histogramEnumeration')
  @DocsEditable
  void histogramEnumeration(String name, int sample, int boundaryValue) native;

  @DomName('PagePopupController.localizeNumberString')
  @DocsEditable
  String localizeNumberString(String numberString) native;

  @DomName('PagePopupController.setValueAndClosePopup')
  @DocsEditable
  void setValueAndClosePopup(int numberValue, String stringValue) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('PageTransitionEvent')
class PageTransitionEvent extends Event native "*PageTransitionEvent" {

  @DomName('PageTransitionEvent.persisted')
  @DocsEditable
  final bool persisted;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLParagraphElement')
class ParagraphElement extends Element native "*HTMLParagraphElement" {

  @DocsEditable
  factory ParagraphElement() => document.$dom_createElement("p");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLParamElement')
class ParamElement extends Element native "*HTMLParamElement" {

  @DocsEditable
  factory ParamElement() => document.$dom_createElement("param");

  @DomName('HTMLParamElement.name')
  @DocsEditable
  String name;

  @DomName('HTMLParamElement.value')
  @DocsEditable
  String value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Performance')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE)
class Performance extends EventTarget native "*Performance" {

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.performance)');

  @DomName('Performance.memory')
  @DocsEditable
  final MemoryInfo memory;

  @DomName('Performance.navigation')
  @DocsEditable
  final PerformanceNavigation navigation;

  @DomName('Performance.timing')
  @DocsEditable
  final PerformanceTiming timing;

  @DomName('Performance.now')
  @DocsEditable
  num now() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('PerformanceNavigation')
class PerformanceNavigation native "*PerformanceNavigation" {

  static const int TYPE_BACK_FORWARD = 2;

  static const int TYPE_NAVIGATE = 0;

  static const int TYPE_RELOAD = 1;

  static const int TYPE_RESERVED = 255;

  @DomName('PerformanceNavigation.redirectCount')
  @DocsEditable
  final int redirectCount;

  @DomName('PerformanceNavigation.type')
  @DocsEditable
  final int type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('PerformanceTiming')
class PerformanceTiming native "*PerformanceTiming" {

  @DomName('PerformanceTiming.connectEnd')
  @DocsEditable
  final int connectEnd;

  @DomName('PerformanceTiming.connectStart')
  @DocsEditable
  final int connectStart;

  @DomName('PerformanceTiming.domComplete')
  @DocsEditable
  final int domComplete;

  @DomName('PerformanceTiming.domContentLoadedEventEnd')
  @DocsEditable
  final int domContentLoadedEventEnd;

  @DomName('PerformanceTiming.domContentLoadedEventStart')
  @DocsEditable
  final int domContentLoadedEventStart;

  @DomName('PerformanceTiming.domInteractive')
  @DocsEditable
  final int domInteractive;

  @DomName('PerformanceTiming.domLoading')
  @DocsEditable
  final int domLoading;

  @DomName('PerformanceTiming.domainLookupEnd')
  @DocsEditable
  final int domainLookupEnd;

  @DomName('PerformanceTiming.domainLookupStart')
  @DocsEditable
  final int domainLookupStart;

  @DomName('PerformanceTiming.fetchStart')
  @DocsEditable
  final int fetchStart;

  @DomName('PerformanceTiming.loadEventEnd')
  @DocsEditable
  final int loadEventEnd;

  @DomName('PerformanceTiming.loadEventStart')
  @DocsEditable
  final int loadEventStart;

  @DomName('PerformanceTiming.navigationStart')
  @DocsEditable
  final int navigationStart;

  @DomName('PerformanceTiming.redirectEnd')
  @DocsEditable
  final int redirectEnd;

  @DomName('PerformanceTiming.redirectStart')
  @DocsEditable
  final int redirectStart;

  @DomName('PerformanceTiming.requestStart')
  @DocsEditable
  final int requestStart;

  @DomName('PerformanceTiming.responseEnd')
  @DocsEditable
  final int responseEnd;

  @DomName('PerformanceTiming.responseStart')
  @DocsEditable
  final int responseStart;

  @DomName('PerformanceTiming.secureConnectionStart')
  @DocsEditable
  final int secureConnectionStart;

  @DomName('PerformanceTiming.unloadEventEnd')
  @DocsEditable
  final int unloadEventEnd;

  @DomName('PerformanceTiming.unloadEventStart')
  @DocsEditable
  final int unloadEventStart;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('PopStateEvent')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class PopStateEvent extends Event native "*PopStateEvent" {

  dynamic get state => convertNativeToDart_SerializedScriptValue(this._state);
  @JSName('state')
  @DomName('PopStateEvent.state')
  @DocsEditable
  @annotation_Creates_SerializedScriptValue
  @annotation_Returns_SerializedScriptValue
  final dynamic _state;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void PositionCallback(Geoposition position);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('PositionError')
class PositionError native "*PositionError" {

  static const int PERMISSION_DENIED = 1;

  static const int POSITION_UNAVAILABLE = 2;

  static const int TIMEOUT = 3;

  @DomName('PositionError.code')
  @DocsEditable
  final int code;

  @DomName('PositionError.message')
  @DocsEditable
  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void PositionErrorCallback(PositionError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLPreElement')
class PreElement extends Element native "*HTMLPreElement" {

  @DocsEditable
  factory PreElement() => document.$dom_createElement("pre");

  @DomName('HTMLPreElement.wrap')
  @DocsEditable
  bool wrap;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('ProcessingInstruction')
class ProcessingInstruction extends Node native "*ProcessingInstruction" {

  @DomName('ProcessingInstruction.data')
  @DocsEditable
  String data;

  @DomName('ProcessingInstruction.sheet')
  @DocsEditable
  final StyleSheet sheet;

  @DomName('ProcessingInstruction.target')
  @DocsEditable
  final String target;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLProgressElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class ProgressElement extends Element native "*HTMLProgressElement" {

  @DocsEditable
  factory ProgressElement() => document.$dom_createElement("progress");

  /// Checks if this type is supported on the current platform.
  static bool get supported => Element.isTagSupported('progress');

  @DomName('HTMLProgressElement.labels')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  final List<Node> labels;

  @DomName('HTMLProgressElement.max')
  @DocsEditable
  num max;

  @DomName('HTMLProgressElement.position')
  @DocsEditable
  final num position;

  @DomName('HTMLProgressElement.value')
  @DocsEditable
  num value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('ProgressEvent')
class ProgressEvent extends Event native "*ProgressEvent" {

  @DomName('ProgressEvent.lengthComputable')
  @DocsEditable
  final bool lengthComputable;

  @DomName('ProgressEvent.loaded')
  @DocsEditable
  final int loaded;

  @DomName('ProgressEvent.total')
  @DocsEditable
  final int total;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLQuoteElement')
class QuoteElement extends Element native "*HTMLQuoteElement" {

  @DomName('HTMLQuoteElement.cite')
  @DocsEditable
  String cite;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void RtcErrorCallback(String errorInformation);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void RtcSessionDescriptionCallback(RtcSessionDescription sdp);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void RtcStatsCallback(RtcStatsResponse response);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('RadioNodeList')
class RadioNodeList extends NodeList native "*RadioNodeList" {

  @DomName('RadioNodeList.value')
  @DocsEditable
  String value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('Range')
class Range native "*Range" {
  factory Range() => document.$dom_createRange();


  static const int END_TO_END = 2;

  static const int END_TO_START = 3;

  static const int NODE_AFTER = 1;

  static const int NODE_BEFORE = 0;

  static const int NODE_BEFORE_AND_AFTER = 2;

  static const int NODE_INSIDE = 3;

  static const int START_TO_END = 1;

  static const int START_TO_START = 0;

  @DomName('Range.collapsed')
  @DocsEditable
  final bool collapsed;

  @DomName('Range.commonAncestorContainer')
  @DocsEditable
  final Node commonAncestorContainer;

  @DomName('Range.endContainer')
  @DocsEditable
  final Node endContainer;

  @DomName('Range.endOffset')
  @DocsEditable
  final int endOffset;

  @DomName('Range.startContainer')
  @DocsEditable
  final Node startContainer;

  @DomName('Range.startOffset')
  @DocsEditable
  final int startOffset;

  @DomName('Range.cloneContents')
  @DocsEditable
  DocumentFragment cloneContents() native;

  @DomName('Range.cloneRange')
  @DocsEditable
  Range cloneRange() native;

  @DomName('Range.collapse')
  @DocsEditable
  void collapse(bool toStart) native;

  @DomName('Range.compareNode')
  @DocsEditable
  int compareNode(Node refNode) native;

  @DomName('Range.comparePoint')
  @DocsEditable
  int comparePoint(Node refNode, int offset) native;

  @DomName('Range.createContextualFragment')
  @DocsEditable
  DocumentFragment createContextualFragment(String html) native;

  @DomName('Range.deleteContents')
  @DocsEditable
  void deleteContents() native;

  @DomName('Range.detach')
  @DocsEditable
  void detach() native;

  @DomName('Range.expand')
  @DocsEditable
  void expand(String unit) native;

  @DomName('Range.extractContents')
  @DocsEditable
  DocumentFragment extractContents() native;

  @DomName('Range.getBoundingClientRect')
  @DocsEditable
  ClientRect getBoundingClientRect() native;

  @DomName('Range.getClientRects')
  @DocsEditable
  @Returns('_ClientRectList')
  @Creates('_ClientRectList')
  List<ClientRect> getClientRects() native;

  @DomName('Range.insertNode')
  @DocsEditable
  void insertNode(Node newNode) native;

  @DomName('Range.intersectsNode')
  @DocsEditable
  bool intersectsNode(Node refNode) native;

  @DomName('Range.isPointInRange')
  @DocsEditable
  bool isPointInRange(Node refNode, int offset) native;

  @DomName('Range.selectNode')
  @DocsEditable
  void selectNode(Node refNode) native;

  @DomName('Range.selectNodeContents')
  @DocsEditable
  void selectNodeContents(Node refNode) native;

  @DomName('Range.setEnd')
  @DocsEditable
  void setEnd(Node refNode, int offset) native;

  @DomName('Range.setEndAfter')
  @DocsEditable
  void setEndAfter(Node refNode) native;

  @DomName('Range.setEndBefore')
  @DocsEditable
  void setEndBefore(Node refNode) native;

  @DomName('Range.setStart')
  @DocsEditable
  void setStart(Node refNode, int offset) native;

  @DomName('Range.setStartAfter')
  @DocsEditable
  void setStartAfter(Node refNode) native;

  @DomName('Range.setStartBefore')
  @DocsEditable
  void setStartBefore(Node refNode) native;

  @DomName('Range.surroundContents')
  @DocsEditable
  void surroundContents(Node newParent) native;

  @DomName('Range.toString')
  @DocsEditable
  String toString() native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('RangeException')
class RangeException native "*RangeException" {

  static const int BAD_BOUNDARYPOINTS_ERR = 1;

  static const int INVALID_NODE_TYPE_ERR = 2;

  @DomName('RangeException.code')
  @DocsEditable
  final int code;

  @DomName('RangeException.message')
  @DocsEditable
  final String message;

  @DomName('RangeException.name')
  @DocsEditable
  final String name;

  @DomName('RangeException.toString')
  @DocsEditable
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Rect')
class Rect native "*Rect" {

  @DomName('Rect.bottom')
  @DocsEditable
  final CssPrimitiveValue bottom;

  @DomName('Rect.left')
  @DocsEditable
  final CssPrimitiveValue left;

  @DomName('Rect.right')
  @DocsEditable
  final CssPrimitiveValue right;

  @DomName('Rect.top')
  @DocsEditable
  final CssPrimitiveValue top;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void RequestAnimationFrameCallback(num highResTime);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('RGBColor')
class RgbColor native "*RGBColor" {

  @DomName('RGBColor.blue')
  @DocsEditable
  final CssPrimitiveValue blue;

  @DomName('RGBColor.green')
  @DocsEditable
  final CssPrimitiveValue green;

  @DomName('RGBColor.red')
  @DocsEditable
  final CssPrimitiveValue red;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('RTCDataChannel')
class RtcDataChannel extends EventTarget native "*RTCDataChannel" {

  @DomName('RTCDataChannel.close')
  @DocsEditable
  static const EventStreamProvider<Event> closeEvent = const EventStreamProvider<Event>('close');

  @DomName('RTCDataChannel.error')
  @DocsEditable
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DomName('RTCDataChannel.message')
  @DocsEditable
  static const EventStreamProvider<MessageEvent> messageEvent = const EventStreamProvider<MessageEvent>('message');

  @DomName('RTCDataChannel.open')
  @DocsEditable
  static const EventStreamProvider<Event> openEvent = const EventStreamProvider<Event>('open');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  RtcDataChannelEvents get on =>
    new RtcDataChannelEvents(this);

  @DomName('RTCDataChannel.binaryType')
  @DocsEditable
  String binaryType;

  @DomName('RTCDataChannel.bufferedAmount')
  @DocsEditable
  final int bufferedAmount;

  @DomName('RTCDataChannel.label')
  @DocsEditable
  final String label;

  @DomName('RTCDataChannel.readyState')
  @DocsEditable
  final String readyState;

  @DomName('RTCDataChannel.reliable')
  @DocsEditable
  final bool reliable;

  @JSName('addEventListener')
  @DomName('RTCDataChannel.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('RTCDataChannel.close')
  @DocsEditable
  void close() native;

  @DomName('RTCDataChannel.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event event) native;

  @JSName('removeEventListener')
  @DomName('RTCDataChannel.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('RTCDataChannel.send')
  @DocsEditable
  void send(data) native;

  @DomName('RTCDataChannel.close')
  @DocsEditable
  Stream<Event> get onClose => closeEvent.forTarget(this);

  @DomName('RTCDataChannel.error')
  @DocsEditable
  Stream<Event> get onError => errorEvent.forTarget(this);

  @DomName('RTCDataChannel.message')
  @DocsEditable
  Stream<MessageEvent> get onMessage => messageEvent.forTarget(this);

  @DomName('RTCDataChannel.open')
  @DocsEditable
  Stream<Event> get onOpen => openEvent.forTarget(this);
}

@DocsEditable
@deprecated
class RtcDataChannelEvents extends Events {
  @DocsEditable
  RtcDataChannelEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get close => this['close'];

  @DocsEditable
  EventListenerList get error => this['error'];

  @DocsEditable
  EventListenerList get message => this['message'];

  @DocsEditable
  EventListenerList get open => this['open'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('RTCDataChannelEvent')
class RtcDataChannelEvent extends Event native "*RTCDataChannelEvent" {

  @DomName('RTCDataChannelEvent.channel')
  @DocsEditable
  final RtcDataChannel channel;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('RTCIceCandidate')
class RtcIceCandidate native "*RTCIceCandidate" {

  @DocsEditable
  factory RtcIceCandidate(Map dictionary) => RtcIceCandidate._create(dictionary);
  static RtcIceCandidate _create(Map dictionary) => JS('RtcIceCandidate', 'new RTCIceCandidate(#)', dictionary);

  @DomName('RTCIceCandidate.candidate')
  @DocsEditable
  final String candidate;

  @DomName('RTCIceCandidate.sdpMLineIndex')
  @DocsEditable
  final int sdpMLineIndex;

  @DomName('RTCIceCandidate.sdpMid')
  @DocsEditable
  final String sdpMid;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('RTCIceCandidateEvent')
class RtcIceCandidateEvent extends Event native "*RTCIceCandidateEvent" {

  @DomName('RTCIceCandidateEvent.candidate')
  @DocsEditable
  final RtcIceCandidate candidate;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('RTCPeerConnection')
class RtcPeerConnection extends EventTarget native "*RTCPeerConnection" {

  @DomName('RTCPeerConnection.addstream')
  @DocsEditable
  static const EventStreamProvider<MediaStreamEvent> addStreamEvent = const EventStreamProvider<MediaStreamEvent>('addstream');

  @DomName('RTCPeerConnection.datachannel')
  @DocsEditable
  static const EventStreamProvider<RtcDataChannelEvent> dataChannelEvent = const EventStreamProvider<RtcDataChannelEvent>('datachannel');

  @DomName('RTCPeerConnection.icecandidate')
  @DocsEditable
  static const EventStreamProvider<RtcIceCandidateEvent> iceCandidateEvent = const EventStreamProvider<RtcIceCandidateEvent>('icecandidate');

  @DomName('RTCPeerConnection.icechange')
  @DocsEditable
  static const EventStreamProvider<Event> iceChangeEvent = const EventStreamProvider<Event>('icechange');

  @DomName('RTCPeerConnection.negotiationneeded')
  @DocsEditable
  static const EventStreamProvider<Event> negotiationNeededEvent = const EventStreamProvider<Event>('negotiationneeded');

  @DomName('RTCPeerConnection.open')
  @DocsEditable
  static const EventStreamProvider<Event> openEvent = const EventStreamProvider<Event>('open');

  @DomName('RTCPeerConnection.removestream')
  @DocsEditable
  static const EventStreamProvider<MediaStreamEvent> removeStreamEvent = const EventStreamProvider<MediaStreamEvent>('removestream');

  @DomName('RTCPeerConnection.statechange')
  @DocsEditable
  static const EventStreamProvider<Event> stateChangeEvent = const EventStreamProvider<Event>('statechange');

  @DocsEditable
  factory RtcPeerConnection(Map rtcIceServers, [Map mediaConstraints]) {
    if (!?mediaConstraints) {
      return RtcPeerConnection._create(rtcIceServers);
    }
    return RtcPeerConnection._create(rtcIceServers, mediaConstraints);
  }
  static RtcPeerConnection _create(Map rtcIceServers, [Map mediaConstraints]) {
    if (!?mediaConstraints) {
      return JS('RtcPeerConnection', 'new RTCPeerConnection(#)', rtcIceServers);
    }
    return JS('RtcPeerConnection', 'new RTCPeerConnection(#,#)', rtcIceServers, mediaConstraints);
  }

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  RtcPeerConnectionEvents get on =>
    new RtcPeerConnectionEvents(this);

  @DomName('RTCPeerConnection.iceGatheringState')
  @DocsEditable
  final String iceGatheringState;

  @DomName('RTCPeerConnection.iceState')
  @DocsEditable
  final String iceState;

  @DomName('RTCPeerConnection.localDescription')
  @DocsEditable
  final RtcSessionDescription localDescription;

  @DomName('RTCPeerConnection.localStreams')
  @DocsEditable
  @Returns('_MediaStreamList')
  @Creates('_MediaStreamList')
  final List<MediaStream> localStreams;

  @DomName('RTCPeerConnection.readyState')
  @DocsEditable
  final String readyState;

  @DomName('RTCPeerConnection.remoteDescription')
  @DocsEditable
  final RtcSessionDescription remoteDescription;

  @DomName('RTCPeerConnection.remoteStreams')
  @DocsEditable
  @Returns('_MediaStreamList')
  @Creates('_MediaStreamList')
  final List<MediaStream> remoteStreams;

  @JSName('addEventListener')
  @DomName('RTCPeerConnection.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('RTCPeerConnection.addIceCandidate')
  @DocsEditable
  void addIceCandidate(RtcIceCandidate candidate) native;

  void addStream(MediaStream stream, [Map mediaConstraints]) {
    if (?mediaConstraints) {
      var mediaConstraints_1 = convertDartToNative_Dictionary(mediaConstraints);
      _addStream_1(stream, mediaConstraints_1);
      return;
    }
    _addStream_2(stream);
    return;
  }
  @JSName('addStream')
  @DomName('RTCPeerConnection.addStream')
  @DocsEditable
  void _addStream_1(MediaStream stream, mediaConstraints) native;
  @JSName('addStream')
  @DomName('RTCPeerConnection.addStream')
  @DocsEditable
  void _addStream_2(MediaStream stream) native;

  @DomName('RTCPeerConnection.close')
  @DocsEditable
  void close() native;

  void createAnswer(RtcSessionDescriptionCallback successCallback, [RtcErrorCallback failureCallback, Map mediaConstraints]) {
    if (?mediaConstraints) {
      var mediaConstraints_1 = convertDartToNative_Dictionary(mediaConstraints);
      _createAnswer_1(successCallback, failureCallback, mediaConstraints_1);
      return;
    }
    _createAnswer_2(successCallback, failureCallback);
    return;
  }
  @JSName('createAnswer')
  @DomName('RTCPeerConnection.createAnswer')
  @DocsEditable
  void _createAnswer_1(RtcSessionDescriptionCallback successCallback, RtcErrorCallback failureCallback, mediaConstraints) native;
  @JSName('createAnswer')
  @DomName('RTCPeerConnection.createAnswer')
  @DocsEditable
  void _createAnswer_2(RtcSessionDescriptionCallback successCallback, RtcErrorCallback failureCallback) native;

  RtcDataChannel createDataChannel(String label, [Map options]) {
    if (?options) {
      var options_1 = convertDartToNative_Dictionary(options);
      return _createDataChannel_1(label, options_1);
    }
    return _createDataChannel_2(label);
  }
  @JSName('createDataChannel')
  @DomName('RTCPeerConnection.createDataChannel')
  @DocsEditable
  RtcDataChannel _createDataChannel_1(label, options) native;
  @JSName('createDataChannel')
  @DomName('RTCPeerConnection.createDataChannel')
  @DocsEditable
  RtcDataChannel _createDataChannel_2(label) native;

  void createOffer(RtcSessionDescriptionCallback successCallback, [RtcErrorCallback failureCallback, Map mediaConstraints]) {
    if (?mediaConstraints) {
      var mediaConstraints_1 = convertDartToNative_Dictionary(mediaConstraints);
      _createOffer_1(successCallback, failureCallback, mediaConstraints_1);
      return;
    }
    _createOffer_2(successCallback, failureCallback);
    return;
  }
  @JSName('createOffer')
  @DomName('RTCPeerConnection.createOffer')
  @DocsEditable
  void _createOffer_1(RtcSessionDescriptionCallback successCallback, RtcErrorCallback failureCallback, mediaConstraints) native;
  @JSName('createOffer')
  @DomName('RTCPeerConnection.createOffer')
  @DocsEditable
  void _createOffer_2(RtcSessionDescriptionCallback successCallback, RtcErrorCallback failureCallback) native;

  @DomName('RTCPeerConnection.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event event) native;

  @DomName('RTCPeerConnection.getStats')
  @DocsEditable
  void getStats(RtcStatsCallback successCallback, MediaStreamTrack selector) native;

  @JSName('removeEventListener')
  @DomName('RTCPeerConnection.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('RTCPeerConnection.removeStream')
  @DocsEditable
  void removeStream(MediaStream stream) native;

  @DomName('RTCPeerConnection.setLocalDescription')
  @DocsEditable
  void setLocalDescription(RtcSessionDescription description, [VoidCallback successCallback, RtcErrorCallback failureCallback]) native;

  @DomName('RTCPeerConnection.setRemoteDescription')
  @DocsEditable
  void setRemoteDescription(RtcSessionDescription description, [VoidCallback successCallback, RtcErrorCallback failureCallback]) native;

  void updateIce([Map configuration, Map mediaConstraints]) {
    if (?mediaConstraints) {
      var configuration_1 = convertDartToNative_Dictionary(configuration);
      var mediaConstraints_2 = convertDartToNative_Dictionary(mediaConstraints);
      _updateIce_1(configuration_1, mediaConstraints_2);
      return;
    }
    if (?configuration) {
      var configuration_3 = convertDartToNative_Dictionary(configuration);
      _updateIce_2(configuration_3);
      return;
    }
    _updateIce_3();
    return;
  }
  @JSName('updateIce')
  @DomName('RTCPeerConnection.updateIce')
  @DocsEditable
  void _updateIce_1(configuration, mediaConstraints) native;
  @JSName('updateIce')
  @DomName('RTCPeerConnection.updateIce')
  @DocsEditable
  void _updateIce_2(configuration) native;
  @JSName('updateIce')
  @DomName('RTCPeerConnection.updateIce')
  @DocsEditable
  void _updateIce_3() native;

  @DomName('RTCPeerConnection.addstream')
  @DocsEditable
  Stream<MediaStreamEvent> get onAddStream => addStreamEvent.forTarget(this);

  @DomName('RTCPeerConnection.datachannel')
  @DocsEditable
  Stream<RtcDataChannelEvent> get onDataChannel => dataChannelEvent.forTarget(this);

  @DomName('RTCPeerConnection.icecandidate')
  @DocsEditable
  Stream<RtcIceCandidateEvent> get onIceCandidate => iceCandidateEvent.forTarget(this);

  @DomName('RTCPeerConnection.icechange')
  @DocsEditable
  Stream<Event> get onIceChange => iceChangeEvent.forTarget(this);

  @DomName('RTCPeerConnection.negotiationneeded')
  @DocsEditable
  Stream<Event> get onNegotiationNeeded => negotiationNeededEvent.forTarget(this);

  @DomName('RTCPeerConnection.open')
  @DocsEditable
  Stream<Event> get onOpen => openEvent.forTarget(this);

  @DomName('RTCPeerConnection.removestream')
  @DocsEditable
  Stream<MediaStreamEvent> get onRemoveStream => removeStreamEvent.forTarget(this);

  @DomName('RTCPeerConnection.statechange')
  @DocsEditable
  Stream<Event> get onStateChange => stateChangeEvent.forTarget(this);
}

@DocsEditable
@deprecated
class RtcPeerConnectionEvents extends Events {
  @DocsEditable
  RtcPeerConnectionEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get addStream => this['addstream'];

  @DocsEditable
  EventListenerList get iceCandidate => this['icecandidate'];

  @DocsEditable
  EventListenerList get iceChange => this['icechange'];

  @DocsEditable
  EventListenerList get negotiationNeeded => this['negotiationneeded'];

  @DocsEditable
  EventListenerList get open => this['open'];

  @DocsEditable
  EventListenerList get removeStream => this['removestream'];

  @DocsEditable
  EventListenerList get stateChange => this['statechange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('RTCSessionDescription')
class RtcSessionDescription native "*RTCSessionDescription" {

  @DocsEditable
  factory RtcSessionDescription(Map dictionary) => RtcSessionDescription._create(dictionary);
  static RtcSessionDescription _create(Map dictionary) => JS('RtcSessionDescription', 'new RTCSessionDescription(#)', dictionary);

  @DomName('RTCSessionDescription.sdp')
  @DocsEditable
  String sdp;

  @DomName('RTCSessionDescription.type')
  @DocsEditable
  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('RTCStatsElement')
class RtcStatsElement native "*RTCStatsElement" {

  @DomName('RTCStatsElement.timestamp')
  @DocsEditable
  final Date timestamp;

  @DomName('RTCStatsElement.names')
  @DocsEditable
  List<String> names() native;

  @DomName('RTCStatsElement.stat')
  @DocsEditable
  String stat(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('RTCStatsReport')
class RtcStatsReport native "*RTCStatsReport" {

  @DomName('RTCStatsReport.local')
  @DocsEditable
  final RtcStatsElement local;

  @DomName('RTCStatsReport.remote')
  @DocsEditable
  final RtcStatsElement remote;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('RTCStatsResponse')
class RtcStatsResponse native "*RTCStatsResponse" {

  @DomName('RTCStatsResponse.result')
  @DocsEditable
  List<RtcStatsReport> result() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SqlStatementCallback(SqlTransaction transaction, SqlResultSet resultSet);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SqlStatementErrorCallback(SqlTransaction transaction, SqlError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SqlTransactionCallback(SqlTransaction transaction);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SqlTransactionErrorCallback(SqlError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SqlTransactionSyncCallback(SqlTransactionSync transaction);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Screen')
class Screen native "*Screen" {

  @DomName('Screen.availHeight')
  @DocsEditable
  final int availHeight;

  @DomName('Screen.availLeft')
  @DocsEditable
  final int availLeft;

  @DomName('Screen.availTop')
  @DocsEditable
  final int availTop;

  @DomName('Screen.availWidth')
  @DocsEditable
  final int availWidth;

  @DomName('Screen.colorDepth')
  @DocsEditable
  final int colorDepth;

  @DomName('Screen.height')
  @DocsEditable
  final int height;

  @DomName('Screen.pixelDepth')
  @DocsEditable
  final int pixelDepth;

  @DomName('Screen.width')
  @DocsEditable
  final int width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLScriptElement')
class ScriptElement extends Element native "*HTMLScriptElement" {

  @DocsEditable
  factory ScriptElement() => document.$dom_createElement("script");

  @DomName('HTMLScriptElement.async')
  @DocsEditable
  bool async;

  @DomName('HTMLScriptElement.charset')
  @DocsEditable
  String charset;

  @DomName('HTMLScriptElement.crossOrigin')
  @DocsEditable
  String crossOrigin;

  @DomName('HTMLScriptElement.defer')
  @DocsEditable
  bool defer;

  @DomName('HTMLScriptElement.event')
  @DocsEditable
  String event;

  @DomName('HTMLScriptElement.htmlFor')
  @DocsEditable
  String htmlFor;

  @DomName('HTMLScriptElement.src')
  @DocsEditable
  String src;

  @DomName('HTMLScriptElement.type')
  @DocsEditable
  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('ScriptProfile')
class ScriptProfile native "*ScriptProfile" {

  @DomName('ScriptProfile.head')
  @DocsEditable
  final ScriptProfileNode head;

  @DomName('ScriptProfile.idleTime')
  @DocsEditable
  final num idleTime;

  @DomName('ScriptProfile.title')
  @DocsEditable
  final String title;

  @DomName('ScriptProfile.uid')
  @DocsEditable
  final int uid;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('ScriptProfileNode')
class ScriptProfileNode native "*ScriptProfileNode" {

  @JSName('callUID')
  @DomName('ScriptProfileNode.callUID')
  @DocsEditable
  final int callUid;

  @DomName('ScriptProfileNode.functionName')
  @DocsEditable
  final String functionName;

  @DomName('ScriptProfileNode.lineNumber')
  @DocsEditable
  final int lineNumber;

  @DomName('ScriptProfileNode.numberOfCalls')
  @DocsEditable
  final int numberOfCalls;

  @DomName('ScriptProfileNode.selfTime')
  @DocsEditable
  final num selfTime;

  @DomName('ScriptProfileNode.totalTime')
  @DocsEditable
  final num totalTime;

  @DomName('ScriptProfileNode.url')
  @DocsEditable
  final String url;

  @DomName('ScriptProfileNode.visible')
  @DocsEditable
  final bool visible;

  @DomName('ScriptProfileNode.children')
  @DocsEditable
  List<ScriptProfileNode> children() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('HTMLSelectElement')
class SelectElement extends Element native "*HTMLSelectElement" {

  @DocsEditable
  factory SelectElement() => document.$dom_createElement("select");

  @DomName('HTMLSelectElement.autofocus')
  @DocsEditable
  bool autofocus;

  @DomName('HTMLSelectElement.disabled')
  @DocsEditable
  bool disabled;

  @DomName('HTMLSelectElement.form')
  @DocsEditable
  final FormElement form;

  @DomName('HTMLSelectElement.labels')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  final List<Node> labels;

  @DomName('HTMLSelectElement.length')
  @DocsEditable
  int length;

  @DomName('HTMLSelectElement.multiple')
  @DocsEditable
  bool multiple;

  @DomName('HTMLSelectElement.name')
  @DocsEditable
  String name;

  @DomName('HTMLSelectElement.required')
  @DocsEditable
  bool required;

  @DomName('HTMLSelectElement.selectedIndex')
  @DocsEditable
  int selectedIndex;

  @DomName('HTMLSelectElement.size')
  @DocsEditable
  int size;

  @DomName('HTMLSelectElement.type')
  @DocsEditable
  final String type;

  @DomName('HTMLSelectElement.validationMessage')
  @DocsEditable
  final String validationMessage;

  @DomName('HTMLSelectElement.validity')
  @DocsEditable
  final ValidityState validity;

  @DomName('HTMLSelectElement.value')
  @DocsEditable
  String value;

  @DomName('HTMLSelectElement.willValidate')
  @DocsEditable
  final bool willValidate;

  @DomName('HTMLSelectElement.checkValidity')
  @DocsEditable
  bool checkValidity() native;

  @DomName('HTMLSelectElement.item')
  @DocsEditable
  Node item(int index) native;

  @DomName('HTMLSelectElement.namedItem')
  @DocsEditable
  Node namedItem(String name) native;

  @DomName('HTMLSelectElement.setCustomValidity')
  @DocsEditable
  void setCustomValidity(String error) native;


  // Override default options, since IE returns SelectElement itself and it
  // does not operate as a List.
  List<OptionElement> get options {
    var options = this.children.where((e) => e is OptionElement).toList();
    // TODO(floitsch): find better way to create a read-only list view.
    return options.take(options.length);
  }

  List<OptionElement> get selectedOptions {
    // IE does not change the selected flag for single-selection items.
    if (this.multiple) {
      var options = this.options.where((o) => o.selected).toList();
      // TODO(floitsch): find better way to create a read-only list view.
      return options.take(options.length);
    } else {
      return [this.options[this.selectedIndex]];
    }
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLShadowElement')
@SupportedBrowser(SupportedBrowser.CHROME, '25')
@Experimental
class ShadowElement extends Element native "*HTMLShadowElement" {

  /// Checks if this type is supported on the current platform.
  static bool get supported => Element.isTagSupported('shadow');

  @DomName('HTMLShadowElement.olderShadowRoot')
  @DocsEditable
  final ShadowRoot olderShadowRoot;

  @DomName('HTMLShadowElement.resetStyleInheritance')
  @DocsEditable
  bool resetStyleInheritance;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('ShadowRoot')
@SupportedBrowser(SupportedBrowser.CHROME, '25')
@Experimental
class ShadowRoot extends DocumentFragment native "*ShadowRoot" {

  @DomName('ShadowRoot.activeElement')
  @DocsEditable
  final Element activeElement;

  @DomName('ShadowRoot.applyAuthorStyles')
  @DocsEditable
  bool applyAuthorStyles;

  @JSName('innerHTML')
  @DomName('ShadowRoot.innerHTML')
  @DocsEditable
  String innerHtml;

  @DomName('ShadowRoot.resetStyleInheritance')
  @DocsEditable
  bool resetStyleInheritance;

  @JSName('cloneNode')
  @DomName('ShadowRoot.cloneNode')
  @DocsEditable
  Node clone(bool deep) native;

  @DomName('ShadowRoot.elementFromPoint')
  @DocsEditable
  Element elementFromPoint(int x, int y) native;

  @JSName('getElementById')
  @DomName('ShadowRoot.getElementById')
  @DocsEditable
  Element $dom_getElementById(String elementId) native;

  @JSName('getElementsByClassName')
  @DomName('ShadowRoot.getElementsByClassName')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> $dom_getElementsByClassName(String className) native;

  @JSName('getElementsByTagName')
  @DomName('ShadowRoot.getElementsByTagName')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> $dom_getElementsByTagName(String tagName) native;

  @DomName('ShadowRoot.getSelection')
  @DocsEditable
  DomSelection getSelection() native;

  static bool get supported =>
      JS('bool', '!!(Element.prototype.webkitCreateShadowRoot)');
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SharedWorker')
class SharedWorker extends AbstractWorker native "*SharedWorker" {

  @DocsEditable
  factory SharedWorker(String scriptURL, [String name]) {
    if (!?name) {
      return SharedWorker._create(scriptURL);
    }
    return SharedWorker._create(scriptURL, name);
  }
  static SharedWorker _create(String scriptURL, [String name]) {
    if (!?name) {
      return JS('SharedWorker', 'new SharedWorker(#)', scriptURL);
    }
    return JS('SharedWorker', 'new SharedWorker(#,#)', scriptURL, name);
  }

  @DomName('SharedWorker.port')
  @DocsEditable
  final MessagePort port;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SharedWorkerContext')
class SharedWorkerContext extends WorkerContext native "*SharedWorkerContext" {

  @DomName('SharedWorkerContext.connect')
  @DocsEditable
  static const EventStreamProvider<Event> connectEvent = const EventStreamProvider<Event>('connect');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  SharedWorkerContextEvents get on =>
    new SharedWorkerContextEvents(this);

  @DomName('SharedWorkerContext.name')
  @DocsEditable
  final String name;

  @DomName('SharedWorkerContext.connect')
  @DocsEditable
  Stream<Event> get onConnect => connectEvent.forTarget(this);
}

@DocsEditable
@deprecated
class SharedWorkerContextEvents extends WorkerContextEvents {
  @DocsEditable
  SharedWorkerContextEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get connect => this['connect'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SourceBuffer')
class SourceBuffer native "*SourceBuffer" {

  @DomName('SourceBuffer.buffered')
  @DocsEditable
  final TimeRanges buffered;

  @DomName('SourceBuffer.timestampOffset')
  @DocsEditable
  num timestampOffset;

  @DomName('SourceBuffer.abort')
  @DocsEditable
  void abort() native;

  @DomName('SourceBuffer.append')
  @DocsEditable
  void append(Uint8Array data) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SourceBufferList')
class SourceBufferList extends EventTarget implements JavaScriptIndexingBehavior, List<SourceBuffer> native "*SourceBufferList" {

  @DomName('SourceBufferList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  SourceBuffer operator[](int index) => JS("SourceBuffer", "#[#]", this, index);

  void operator[]=(int index, SourceBuffer value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SourceBuffer> mixins.
  // SourceBuffer is the element type.

  // From Iterable<SourceBuffer>:

  Iterator<SourceBuffer> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SourceBuffer>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, SourceBuffer)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(SourceBuffer element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(SourceBuffer element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(SourceBuffer element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<SourceBuffer> where(bool f(SourceBuffer element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(SourceBuffer element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(SourceBuffer element)) => IterableMixinWorkaround.any(this, f);

  List<SourceBuffer> toList() => new List<SourceBuffer>.from(this);
  Set<SourceBuffer> toSet() => new Set<SourceBuffer>.from(this);

  bool get isEmpty => this.length == 0;

  List<SourceBuffer> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<SourceBuffer> takeWhile(bool test(SourceBuffer value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<SourceBuffer> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<SourceBuffer> skipWhile(bool test(SourceBuffer value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  SourceBuffer firstMatching(bool test(SourceBuffer value), { SourceBuffer orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  SourceBuffer lastMatching(bool test(SourceBuffer value), {SourceBuffer orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  SourceBuffer singleMatching(bool test(SourceBuffer value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  SourceBuffer elementAt(int index) {
    return this[index];
  }

  // From Collection<SourceBuffer>:

  void add(SourceBuffer value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SourceBuffer value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<SourceBuffer> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<SourceBuffer>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<SourceBuffer> get reversed =>
      new ReversedListView<SourceBuffer>(this, 0, null);

  void sort([int compare(SourceBuffer a, SourceBuffer b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SourceBuffer element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SourceBuffer element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  SourceBuffer get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  SourceBuffer get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  SourceBuffer get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  SourceBuffer min([int compare(SourceBuffer a, SourceBuffer b)]) =>
      IterableMixinWorkaround.min(this, compare);

  SourceBuffer max([int compare(SourceBuffer a, SourceBuffer b)]) =>
      IterableMixinWorkaround.max(this, compare);

  SourceBuffer removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  SourceBuffer removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(SourceBuffer element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(SourceBuffer element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<SourceBuffer> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SourceBuffer initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SourceBuffer> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <SourceBuffer>[]);

  // -- end List<SourceBuffer> mixins.

  @JSName('addEventListener')
  @DomName('SourceBufferList.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('SourceBufferList.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event event) native;

  @DomName('SourceBufferList.item')
  @DocsEditable
  SourceBuffer item(int index) native;

  @JSName('removeEventListener')
  @DomName('SourceBufferList.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLSourceElement')
class SourceElement extends Element native "*HTMLSourceElement" {

  @DocsEditable
  factory SourceElement() => document.$dom_createElement("source");

  @DomName('HTMLSourceElement.media')
  @DocsEditable
  String media;

  @DomName('HTMLSourceElement.src')
  @DocsEditable
  String src;

  @DomName('HTMLSourceElement.type')
  @DocsEditable
  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLSpanElement')
class SpanElement extends Element native "*HTMLSpanElement" {

  @DocsEditable
  factory SpanElement() => document.$dom_createElement("span");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SpeechGrammar')
class SpeechGrammar native "*SpeechGrammar" {

  @DocsEditable
  factory SpeechGrammar() => SpeechGrammar._create();
  static SpeechGrammar _create() => JS('SpeechGrammar', 'new SpeechGrammar()');

  @DomName('SpeechGrammar.src')
  @DocsEditable
  String src;

  @DomName('SpeechGrammar.weight')
  @DocsEditable
  num weight;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SpeechGrammarList')
class SpeechGrammarList implements JavaScriptIndexingBehavior, List<SpeechGrammar> native "*SpeechGrammarList" {

  @DocsEditable
  factory SpeechGrammarList() => SpeechGrammarList._create();
  static SpeechGrammarList _create() => JS('SpeechGrammarList', 'new SpeechGrammarList()');

  @DomName('SpeechGrammarList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  SpeechGrammar operator[](int index) => JS("SpeechGrammar", "#[#]", this, index);

  void operator[]=(int index, SpeechGrammar value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SpeechGrammar> mixins.
  // SpeechGrammar is the element type.

  // From Iterable<SpeechGrammar>:

  Iterator<SpeechGrammar> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SpeechGrammar>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, SpeechGrammar)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(SpeechGrammar element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(SpeechGrammar element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(SpeechGrammar element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<SpeechGrammar> where(bool f(SpeechGrammar element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(SpeechGrammar element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(SpeechGrammar element)) => IterableMixinWorkaround.any(this, f);

  List<SpeechGrammar> toList() => new List<SpeechGrammar>.from(this);
  Set<SpeechGrammar> toSet() => new Set<SpeechGrammar>.from(this);

  bool get isEmpty => this.length == 0;

  List<SpeechGrammar> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<SpeechGrammar> takeWhile(bool test(SpeechGrammar value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<SpeechGrammar> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<SpeechGrammar> skipWhile(bool test(SpeechGrammar value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  SpeechGrammar firstMatching(bool test(SpeechGrammar value), { SpeechGrammar orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  SpeechGrammar lastMatching(bool test(SpeechGrammar value), {SpeechGrammar orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  SpeechGrammar singleMatching(bool test(SpeechGrammar value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  SpeechGrammar elementAt(int index) {
    return this[index];
  }

  // From Collection<SpeechGrammar>:

  void add(SpeechGrammar value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SpeechGrammar value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<SpeechGrammar> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<SpeechGrammar>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<SpeechGrammar> get reversed =>
      new ReversedListView<SpeechGrammar>(this, 0, null);

  void sort([int compare(SpeechGrammar a, SpeechGrammar b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SpeechGrammar element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SpeechGrammar element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  SpeechGrammar get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  SpeechGrammar get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  SpeechGrammar get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  SpeechGrammar min([int compare(SpeechGrammar a, SpeechGrammar b)]) =>
      IterableMixinWorkaround.min(this, compare);

  SpeechGrammar max([int compare(SpeechGrammar a, SpeechGrammar b)]) =>
      IterableMixinWorkaround.max(this, compare);

  SpeechGrammar removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  SpeechGrammar removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(SpeechGrammar element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(SpeechGrammar element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<SpeechGrammar> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SpeechGrammar initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SpeechGrammar> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <SpeechGrammar>[]);

  // -- end List<SpeechGrammar> mixins.

  @DomName('SpeechGrammarList.addFromString')
  @DocsEditable
  void addFromString(String string, [num weight]) native;

  @DomName('SpeechGrammarList.addFromUri')
  @DocsEditable
  void addFromUri(String src, [num weight]) native;

  @DomName('SpeechGrammarList.item')
  @DocsEditable
  SpeechGrammar item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SpeechInputEvent')
class SpeechInputEvent extends Event native "*SpeechInputEvent" {

  @DomName('SpeechInputEvent.results')
  @DocsEditable
  @Returns('_SpeechInputResultList')
  @Creates('_SpeechInputResultList')
  final List<SpeechInputResult> results;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SpeechInputResult')
class SpeechInputResult native "*SpeechInputResult" {

  @DomName('SpeechInputResult.confidence')
  @DocsEditable
  final num confidence;

  @DomName('SpeechInputResult.utterance')
  @DocsEditable
  final String utterance;
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('SpeechRecognition')
@SupportedBrowser(SupportedBrowser.CHROME, '25')
@Experimental
class SpeechRecognition extends EventTarget native "*SpeechRecognition" {

  @DomName('SpeechRecognition.audioend')
  @DocsEditable
  static const EventStreamProvider<Event> audioEndEvent = const EventStreamProvider<Event>('audioend');

  @DomName('SpeechRecognition.audiostart')
  @DocsEditable
  static const EventStreamProvider<Event> audioStartEvent = const EventStreamProvider<Event>('audiostart');

  @DomName('SpeechRecognition.end')
  @DocsEditable
  static const EventStreamProvider<Event> endEvent = const EventStreamProvider<Event>('end');

  @DomName('SpeechRecognition.error')
  @DocsEditable
  static const EventStreamProvider<SpeechRecognitionError> errorEvent = const EventStreamProvider<SpeechRecognitionError>('error');

  @DomName('SpeechRecognition.nomatch')
  @DocsEditable
  static const EventStreamProvider<SpeechRecognitionEvent> noMatchEvent = const EventStreamProvider<SpeechRecognitionEvent>('nomatch');

  @DomName('SpeechRecognition.result')
  @DocsEditable
  static const EventStreamProvider<SpeechRecognitionEvent> resultEvent = const EventStreamProvider<SpeechRecognitionEvent>('result');

  @DomName('SpeechRecognition.soundend')
  @DocsEditable
  static const EventStreamProvider<Event> soundEndEvent = const EventStreamProvider<Event>('soundend');

  @DomName('SpeechRecognition.soundstart')
  @DocsEditable
  static const EventStreamProvider<Event> soundStartEvent = const EventStreamProvider<Event>('soundstart');

  @DomName('SpeechRecognition.speechend')
  @DocsEditable
  static const EventStreamProvider<Event> speechEndEvent = const EventStreamProvider<Event>('speechend');

  @DomName('SpeechRecognition.speechstart')
  @DocsEditable
  static const EventStreamProvider<Event> speechStartEvent = const EventStreamProvider<Event>('speechstart');

  @DomName('SpeechRecognition.start')
  @DocsEditable
  static const EventStreamProvider<Event> startEvent = const EventStreamProvider<Event>('start');

  @DocsEditable
  factory SpeechRecognition() => SpeechRecognition._create();

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.SpeechRecognition || window.webkitSpeechRecognition)');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  SpeechRecognitionEvents get on =>
    new SpeechRecognitionEvents(this);

  @DomName('SpeechRecognition.continuous')
  @DocsEditable
  bool continuous;

  @DomName('SpeechRecognition.grammars')
  @DocsEditable
  SpeechGrammarList grammars;

  @DomName('SpeechRecognition.interimResults')
  @DocsEditable
  bool interimResults;

  @DomName('SpeechRecognition.lang')
  @DocsEditable
  String lang;

  @DomName('SpeechRecognition.maxAlternatives')
  @DocsEditable
  int maxAlternatives;

  @DomName('SpeechRecognition.abort')
  @DocsEditable
  void abort() native;

  @JSName('addEventListener')
  @DomName('SpeechRecognition.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('SpeechRecognition.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native;

  @JSName('removeEventListener')
  @DomName('SpeechRecognition.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('SpeechRecognition.start')
  @DocsEditable
  void start() native;

  @DomName('SpeechRecognition.stop')
  @DocsEditable
  void stop() native;

  @DomName('SpeechRecognition.audioend')
  @DocsEditable
  Stream<Event> get onAudioEnd => audioEndEvent.forTarget(this);

  @DomName('SpeechRecognition.audiostart')
  @DocsEditable
  Stream<Event> get onAudioStart => audioStartEvent.forTarget(this);

  @DomName('SpeechRecognition.end')
  @DocsEditable
  Stream<Event> get onEnd => endEvent.forTarget(this);

  @DomName('SpeechRecognition.error')
  @DocsEditable
  Stream<SpeechRecognitionError> get onError => errorEvent.forTarget(this);

  @DomName('SpeechRecognition.nomatch')
  @DocsEditable
  Stream<SpeechRecognitionEvent> get onNoMatch => noMatchEvent.forTarget(this);

  @DomName('SpeechRecognition.result')
  @DocsEditable
  Stream<SpeechRecognitionEvent> get onResult => resultEvent.forTarget(this);

  @DomName('SpeechRecognition.soundend')
  @DocsEditable
  Stream<Event> get onSoundEnd => soundEndEvent.forTarget(this);

  @DomName('SpeechRecognition.soundstart')
  @DocsEditable
  Stream<Event> get onSoundStart => soundStartEvent.forTarget(this);

  @DomName('SpeechRecognition.speechend')
  @DocsEditable
  Stream<Event> get onSpeechEnd => speechEndEvent.forTarget(this);

  @DomName('SpeechRecognition.speechstart')
  @DocsEditable
  Stream<Event> get onSpeechStart => speechStartEvent.forTarget(this);

  @DomName('SpeechRecognition.start')
  @DocsEditable
  Stream<Event> get onStart => startEvent.forTarget(this);

  static SpeechRecognition _create() {
    return JS('SpeechRecognition',
        'new (window.SpeechRecognition || window.webkitSpeechRecognition)()');
  }
}

@DocsEditable
@deprecated
class SpeechRecognitionEvents extends Events {
  @DocsEditable
  SpeechRecognitionEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get audioEnd => this['audioend'];

  @DocsEditable
  EventListenerList get audioStart => this['audiostart'];

  @DocsEditable
  EventListenerList get end => this['end'];

  @DocsEditable
  EventListenerList get error => this['error'];

  @DocsEditable
  EventListenerList get noMatch => this['nomatch'];

  @DocsEditable
  EventListenerList get result => this['result'];

  @DocsEditable
  EventListenerList get soundEnd => this['soundend'];

  @DocsEditable
  EventListenerList get soundStart => this['soundstart'];

  @DocsEditable
  EventListenerList get speechEnd => this['speechend'];

  @DocsEditable
  EventListenerList get speechStart => this['speechstart'];

  @DocsEditable
  EventListenerList get start => this['start'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SpeechRecognitionAlternative')
@SupportedBrowser(SupportedBrowser.CHROME, '25')
@Experimental
class SpeechRecognitionAlternative native "*SpeechRecognitionAlternative" {

  @DomName('SpeechRecognitionAlternative.confidence')
  @DocsEditable
  final num confidence;

  @DomName('SpeechRecognitionAlternative.transcript')
  @DocsEditable
  final String transcript;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SpeechRecognitionError')
@SupportedBrowser(SupportedBrowser.CHROME, '25')
@Experimental
class SpeechRecognitionError extends Event native "*SpeechRecognitionError" {

  @DomName('SpeechRecognitionError.error')
  @DocsEditable
  final String error;

  @DomName('SpeechRecognitionError.message')
  @DocsEditable
  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SpeechRecognitionEvent')
@SupportedBrowser(SupportedBrowser.CHROME, '25')
@Experimental
class SpeechRecognitionEvent extends Event native "*SpeechRecognitionEvent" {

  @DomName('SpeechRecognitionEvent.result')
  @DocsEditable
  final SpeechRecognitionResult result;

  @DomName('SpeechRecognitionEvent.resultHistory')
  @DocsEditable
  @Returns('_SpeechRecognitionResultList')
  @Creates('_SpeechRecognitionResultList')
  final List<SpeechRecognitionResult> resultHistory;

  @DomName('SpeechRecognitionEvent.resultIndex')
  @DocsEditable
  final int resultIndex;

  @DomName('SpeechRecognitionEvent.results')
  @DocsEditable
  @Returns('_SpeechRecognitionResultList')
  @Creates('_SpeechRecognitionResultList')
  final List<SpeechRecognitionResult> results;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SpeechRecognitionResult')
@SupportedBrowser(SupportedBrowser.CHROME, '25')
@Experimental
class SpeechRecognitionResult native "*SpeechRecognitionResult" {

  @DomName('SpeechRecognitionResult.isFinal')
  @DocsEditable
  final bool isFinal;

  @DomName('SpeechRecognitionResult.length')
  @DocsEditable
  final int length;

  @DomName('SpeechRecognitionResult.item')
  @DocsEditable
  SpeechRecognitionAlternative item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SQLError')
class SqlError native "*SQLError" {

  static const int CONSTRAINT_ERR = 6;

  static const int DATABASE_ERR = 1;

  static const int QUOTA_ERR = 4;

  static const int SYNTAX_ERR = 5;

  static const int TIMEOUT_ERR = 7;

  static const int TOO_LARGE_ERR = 3;

  static const int UNKNOWN_ERR = 0;

  static const int VERSION_ERR = 2;

  @DomName('SQLError.code')
  @DocsEditable
  final int code;

  @DomName('SQLError.message')
  @DocsEditable
  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SQLException')
class SqlException native "*SQLException" {

  static const int CONSTRAINT_ERR = 6;

  static const int DATABASE_ERR = 1;

  static const int QUOTA_ERR = 4;

  static const int SYNTAX_ERR = 5;

  static const int TIMEOUT_ERR = 7;

  static const int TOO_LARGE_ERR = 3;

  static const int UNKNOWN_ERR = 0;

  static const int VERSION_ERR = 2;

  @DomName('SQLException.code')
  @DocsEditable
  final int code;

  @DomName('SQLException.message')
  @DocsEditable
  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SQLResultSet')
class SqlResultSet native "*SQLResultSet" {

  @DomName('SQLResultSet.insertId')
  @DocsEditable
  final int insertId;

  @DomName('SQLResultSet.rows')
  @DocsEditable
  final SqlResultSetRowList rows;

  @DomName('SQLResultSet.rowsAffected')
  @DocsEditable
  final int rowsAffected;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SQLResultSetRowList')
class SqlResultSetRowList implements JavaScriptIndexingBehavior, List<Map> native "*SQLResultSetRowList" {

  @DomName('SQLResultSetRowList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  Map operator[](int index) => JS("Map", "#[#]", this, index);

  void operator[]=(int index, Map value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Map> mixins.
  // Map is the element type.

  // From Iterable<Map>:

  Iterator<Map> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Map>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, Map)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(Map element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(Map element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(Map element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<Map> where(bool f(Map element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(Map element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(Map element)) => IterableMixinWorkaround.any(this, f);

  List<Map> toList() => new List<Map>.from(this);
  Set<Map> toSet() => new Set<Map>.from(this);

  bool get isEmpty => this.length == 0;

  List<Map> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<Map> takeWhile(bool test(Map value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<Map> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<Map> skipWhile(bool test(Map value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  Map firstMatching(bool test(Map value), { Map orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  Map lastMatching(bool test(Map value), {Map orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  Map singleMatching(bool test(Map value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  Map elementAt(int index) {
    return this[index];
  }

  // From Collection<Map>:

  void add(Map value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Map value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<Map> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<Map>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<Map> get reversed =>
      new ReversedListView<Map>(this, 0, null);

  void sort([int compare(Map a, Map b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Map element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Map element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  Map get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  Map get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  Map get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Map min([int compare(Map a, Map b)]) =>
      IterableMixinWorkaround.min(this, compare);

  Map max([int compare(Map a, Map b)]) =>
      IterableMixinWorkaround.max(this, compare);

  Map removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  Map removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(Map element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(Map element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<Map> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Map initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Map> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <Map>[]);

  // -- end List<Map> mixins.

  Map item(int index) {
    return convertNativeToDart_Dictionary(_item_1(index));
  }
  @JSName('item')
  @DomName('SQLResultSetRowList.item')
  @DocsEditable
  @Creates('=Object')
  _item_1(index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SQLTransaction')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class SqlTransaction native "*SQLTransaction" {

  @DomName('SQLTransaction.executeSql')
  @DocsEditable
  void executeSql(String sqlStatement, List arguments, [SqlStatementCallback callback, SqlStatementErrorCallback errorCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SQLTransactionSync')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class SqlTransactionSync native "*SQLTransactionSync" {

  @DomName('SQLTransactionSync.executeSql')
  @DocsEditable
  SqlResultSet executeSql(String sqlStatement, List arguments) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('Storage')
class Storage implements Map<String, String>
     native "*Storage" {

  // TODO(nweiz): update this when maps support lazy iteration
  bool containsValue(String value) => values.any((e) => e == value);

  bool containsKey(String key) => $dom_getItem(key) != null;

  String operator [](String key) => $dom_getItem(key);

  void operator []=(String key, String value) { $dom_setItem(key, value); }

  String putIfAbsent(String key, String ifAbsent()) {
    if (!containsKey(key)) this[key] = ifAbsent();
    return this[key];
  }

  String remove(String key) {
    final value = this[key];
    $dom_removeItem(key);
    return value;
  }

  void clear() => $dom_clear();

  void forEach(void f(String key, String value)) {
    for (var i = 0; true; i++) {
      final key = $dom_key(i);
      if (key == null) return;

      f(key, this[key]);
    }
  }

  Collection<String> get keys {
    final keys = [];
    forEach((k, v) => keys.add(k));
    return keys;
  }

  Collection<String> get values {
    final values = [];
    forEach((k, v) => values.add(v));
    return values;
  }

  int get length => $dom_length;

  bool get isEmpty => $dom_key(0) == null;

  @JSName('length')
  @DomName('Storage.length')
  @DocsEditable
  final int $dom_length;

  @JSName('clear')
  @DomName('Storage.clear')
  @DocsEditable
  void $dom_clear() native;

  @JSName('getItem')
  @DomName('Storage.getItem')
  @DocsEditable
  String $dom_getItem(String key) native;

  @JSName('key')
  @DomName('Storage.key')
  @DocsEditable
  String $dom_key(int index) native;

  @JSName('removeItem')
  @DomName('Storage.removeItem')
  @DocsEditable
  void $dom_removeItem(String key) native;

  @JSName('setItem')
  @DomName('Storage.setItem')
  @DocsEditable
  void $dom_setItem(String key, String data) native;

}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('StorageEvent')
class StorageEvent extends Event native "*StorageEvent" {
  factory StorageEvent(String type,
    {bool canBubble: false, bool cancelable: false, String key, String oldValue,
    String newValue, String url, Storage storageArea}) {

    var e = document.$dom_createEvent("StorageEvent");
    e.$dom_initStorageEvent(type, canBubble, cancelable, key, oldValue,
        newValue, url, storageArea);
    return e;
  }

  @DomName('StorageEvent.key')
  @DocsEditable
  final String key;

  @DomName('StorageEvent.newValue')
  @DocsEditable
  final String newValue;

  @DomName('StorageEvent.oldValue')
  @DocsEditable
  final String oldValue;

  @DomName('StorageEvent.storageArea')
  @DocsEditable
  final Storage storageArea;

  @DomName('StorageEvent.url')
  @DocsEditable
  final String url;

  @JSName('initStorageEvent')
  @DomName('StorageEvent.initStorageEvent')
  @DocsEditable
  void $dom_initStorageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String keyArg, String oldValueArg, String newValueArg, String urlArg, Storage storageAreaArg) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('StorageInfo')
class StorageInfo native "*StorageInfo" {

  static const int PERSISTENT = 1;

  static const int TEMPORARY = 0;

  @DomName('StorageInfo.queryUsageAndQuota')
  @DocsEditable
  void queryUsageAndQuota(int storageType, [StorageInfoUsageCallback usageCallback, StorageInfoErrorCallback errorCallback]) native;

  @DomName('StorageInfo.requestQuota')
  @DocsEditable
  void requestQuota(int storageType, int newQuotaInBytes, [StorageInfoQuotaCallback quotaCallback, StorageInfoErrorCallback errorCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void StorageInfoErrorCallback(DomException error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void StorageInfoQuotaCallback(int grantedQuotaInBytes);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void StorageInfoUsageCallback(int currentUsageInBytes, int currentQuotaInBytes);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void StringCallback(String data);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLStyleElement')
class StyleElement extends Element native "*HTMLStyleElement" {

  @DocsEditable
  factory StyleElement() => document.$dom_createElement("style");

  @DomName('HTMLStyleElement.disabled')
  @DocsEditable
  bool disabled;

  @DomName('HTMLStyleElement.media')
  @DocsEditable
  String media;

  @DomName('HTMLStyleElement.scoped')
  @DocsEditable
  bool scoped;

  @DomName('HTMLStyleElement.sheet')
  @DocsEditable
  final StyleSheet sheet;

  @DomName('HTMLStyleElement.type')
  @DocsEditable
  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('StyleMedia')
class StyleMedia native "*StyleMedia" {

  @DomName('StyleMedia.type')
  @DocsEditable
  final String type;

  @DomName('StyleMedia.matchMedium')
  @DocsEditable
  bool matchMedium(String mediaquery) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('StyleSheet')
class StyleSheet native "*StyleSheet" {

  @DomName('StyleSheet.disabled')
  @DocsEditable
  bool disabled;

  @DomName('StyleSheet.href')
  @DocsEditable
  final String href;

  @DomName('StyleSheet.media')
  @DocsEditable
  final MediaList media;

  @DomName('StyleSheet.ownerNode')
  @DocsEditable
  final Node ownerNode;

  @DomName('StyleSheet.parentStyleSheet')
  @DocsEditable
  final StyleSheet parentStyleSheet;

  @DomName('StyleSheet.title')
  @DocsEditable
  final String title;

  @DomName('StyleSheet.type')
  @DocsEditable
  final String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLTableCaptionElement')
class TableCaptionElement extends Element native "*HTMLTableCaptionElement" {

  @DocsEditable
  factory TableCaptionElement() => document.$dom_createElement("caption");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLTableCellElement')
class TableCellElement extends Element native "*HTMLTableCellElement" {

  @DocsEditable
  factory TableCellElement() => document.$dom_createElement("td");

  @DomName('HTMLTableCellElement.cellIndex')
  @DocsEditable
  final int cellIndex;

  @DomName('HTMLTableCellElement.colSpan')
  @DocsEditable
  int colSpan;

  @DomName('HTMLTableCellElement.headers')
  @DocsEditable
  String headers;

  @DomName('HTMLTableCellElement.rowSpan')
  @DocsEditable
  int rowSpan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLTableColElement')
class TableColElement extends Element native "*HTMLTableColElement" {

  @DocsEditable
  factory TableColElement() => document.$dom_createElement("col");

  @DomName('HTMLTableColElement.span')
  @DocsEditable
  int span;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('HTMLTableElement')
class TableElement extends Element native "*HTMLTableElement" {

  @DocsEditable
  factory TableElement() => document.$dom_createElement("table");

  @DomName('HTMLTableElement.border')
  @DocsEditable
  String border;

  @DomName('HTMLTableElement.caption')
  @DocsEditable
  TableCaptionElement caption;

  @DomName('HTMLTableElement.rows')
  @DocsEditable
  final HtmlCollection rows;

  @DomName('HTMLTableElement.tBodies')
  @DocsEditable
  final HtmlCollection tBodies;

  @DomName('HTMLTableElement.tFoot')
  @DocsEditable
  TableSectionElement tFoot;

  @DomName('HTMLTableElement.tHead')
  @DocsEditable
  TableSectionElement tHead;

  @DomName('HTMLTableElement.createCaption')
  @DocsEditable
  Element createCaption() native;

  @DomName('HTMLTableElement.createTFoot')
  @DocsEditable
  Element createTFoot() native;

  @DomName('HTMLTableElement.createTHead')
  @DocsEditable
  Element createTHead() native;

  @DomName('HTMLTableElement.deleteCaption')
  @DocsEditable
  void deleteCaption() native;

  @DomName('HTMLTableElement.deleteRow')
  @DocsEditable
  void deleteRow(int index) native;

  @DomName('HTMLTableElement.deleteTFoot')
  @DocsEditable
  void deleteTFoot() native;

  @DomName('HTMLTableElement.deleteTHead')
  @DocsEditable
  void deleteTHead() native;

  @DomName('HTMLTableElement.insertRow')
  @DocsEditable
  Element insertRow(int index) native;


  Element createTBody() {
    if (JS('bool', '!!#.createTBody', this)) {
      return this._createTBody();
    }
    var tbody = new Element.tag('tbody');
    this.elements.add(tbody);
    return tbody;
  }

  @JSName('createTBody')
  Element _createTBody() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLTableRowElement')
class TableRowElement extends Element native "*HTMLTableRowElement" {

  @DocsEditable
  factory TableRowElement() => document.$dom_createElement("tr");

  @DomName('HTMLTableRowElement.cells')
  @DocsEditable
  final HtmlCollection cells;

  @DomName('HTMLTableRowElement.rowIndex')
  @DocsEditable
  final int rowIndex;

  @DomName('HTMLTableRowElement.sectionRowIndex')
  @DocsEditable
  final int sectionRowIndex;

  @DomName('HTMLTableRowElement.deleteCell')
  @DocsEditable
  void deleteCell(int index) native;

  @DomName('HTMLTableRowElement.insertCell')
  @DocsEditable
  Element insertCell(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLTableSectionElement')
class TableSectionElement extends Element native "*HTMLTableSectionElement" {

  @DomName('HTMLTableSectionElement.rows')
  @DocsEditable
  final HtmlCollection rows;

  @DomName('HTMLTableSectionElement.deleteRow')
  @DocsEditable
  void deleteRow(int index) native;

  @DomName('HTMLTableSectionElement.insertRow')
  @DocsEditable
  Element insertRow(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('Text')
class Text extends CharacterData native "*Text" {
  factory Text(String data) => _TextFactoryProvider.createText(data);

  @DomName('Text.wholeText')
  @DocsEditable
  final String wholeText;

  @DomName('Text.replaceWholeText')
  @DocsEditable
  Text replaceWholeText(String content) native;

  @DomName('Text.splitText')
  @DocsEditable
  Text splitText(int offset) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLTextAreaElement')
class TextAreaElement extends Element native "*HTMLTextAreaElement" {

  @DocsEditable
  factory TextAreaElement() => document.$dom_createElement("textarea");

  @DomName('HTMLTextAreaElement.autofocus')
  @DocsEditable
  bool autofocus;

  @DomName('HTMLTextAreaElement.cols')
  @DocsEditable
  int cols;

  @DomName('HTMLTextAreaElement.defaultValue')
  @DocsEditable
  String defaultValue;

  @DomName('HTMLTextAreaElement.dirName')
  @DocsEditable
  String dirName;

  @DomName('HTMLTextAreaElement.disabled')
  @DocsEditable
  bool disabled;

  @DomName('HTMLTextAreaElement.form')
  @DocsEditable
  final FormElement form;

  @DomName('HTMLTextAreaElement.labels')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  final List<Node> labels;

  @DomName('HTMLTextAreaElement.maxLength')
  @DocsEditable
  int maxLength;

  @DomName('HTMLTextAreaElement.name')
  @DocsEditable
  String name;

  @DomName('HTMLTextAreaElement.placeholder')
  @DocsEditable
  String placeholder;

  @DomName('HTMLTextAreaElement.readOnly')
  @DocsEditable
  bool readOnly;

  @DomName('HTMLTextAreaElement.required')
  @DocsEditable
  bool required;

  @DomName('HTMLTextAreaElement.rows')
  @DocsEditable
  int rows;

  @DomName('HTMLTextAreaElement.selectionDirection')
  @DocsEditable
  String selectionDirection;

  @DomName('HTMLTextAreaElement.selectionEnd')
  @DocsEditable
  int selectionEnd;

  @DomName('HTMLTextAreaElement.selectionStart')
  @DocsEditable
  int selectionStart;

  @DomName('HTMLTextAreaElement.textLength')
  @DocsEditable
  final int textLength;

  @DomName('HTMLTextAreaElement.type')
  @DocsEditable
  final String type;

  @DomName('HTMLTextAreaElement.validationMessage')
  @DocsEditable
  final String validationMessage;

  @DomName('HTMLTextAreaElement.validity')
  @DocsEditable
  final ValidityState validity;

  @DomName('HTMLTextAreaElement.value')
  @DocsEditable
  String value;

  @DomName('HTMLTextAreaElement.willValidate')
  @DocsEditable
  final bool willValidate;

  @DomName('HTMLTextAreaElement.wrap')
  @DocsEditable
  String wrap;

  @DomName('HTMLTextAreaElement.checkValidity')
  @DocsEditable
  bool checkValidity() native;

  @DomName('HTMLTextAreaElement.select')
  @DocsEditable
  void select() native;

  @DomName('HTMLTextAreaElement.setCustomValidity')
  @DocsEditable
  void setCustomValidity(String error) native;

  @DomName('HTMLTextAreaElement.setRangeText')
  @DocsEditable
  void setRangeText(String replacement, [int start, int end, String selectionMode]) native;

  @DomName('HTMLTextAreaElement.setSelectionRange')
  @DocsEditable
  void setSelectionRange(int start, int end, [String direction]) native;
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('TextEvent')
class TextEvent extends UIEvent native "*TextEvent" {
  factory TextEvent(String type,
    {bool canBubble: false, bool cancelable: false, Window view, String data}) {
    if (view == null) {
      view = window;
    }
    var e = document.$dom_createEvent("TextEvent");
    e.$dom_initTextEvent(type, canBubble, cancelable, view, data);
    return e;
  }

  @DomName('TextEvent.data')
  @DocsEditable
  final String data;

  @JSName('initTextEvent')
  @DomName('TextEvent.initTextEvent')
  @DocsEditable
  void $dom_initTextEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Window viewArg, String dataArg) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('TextMetrics')
class TextMetrics native "*TextMetrics" {

  @DomName('TextMetrics.width')
  @DocsEditable
  final num width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('TextTrack')
class TextTrack extends EventTarget native "*TextTrack" {

  @DomName('TextTrack.cuechange')
  @DocsEditable
  static const EventStreamProvider<Event> cueChangeEvent = const EventStreamProvider<Event>('cuechange');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  TextTrackEvents get on =>
    new TextTrackEvents(this);

  @DomName('TextTrack.activeCues')
  @DocsEditable
  final TextTrackCueList activeCues;

  @DomName('TextTrack.cues')
  @DocsEditable
  final TextTrackCueList cues;

  @DomName('TextTrack.kind')
  @DocsEditable
  final String kind;

  @DomName('TextTrack.label')
  @DocsEditable
  final String label;

  @DomName('TextTrack.language')
  @DocsEditable
  final String language;

  @DomName('TextTrack.mode')
  @DocsEditable
  String mode;

  @DomName('TextTrack.addCue')
  @DocsEditable
  void addCue(TextTrackCue cue) native;

  @JSName('addEventListener')
  @DomName('TextTrack.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('TextTrack.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native;

  @DomName('TextTrack.removeCue')
  @DocsEditable
  void removeCue(TextTrackCue cue) native;

  @JSName('removeEventListener')
  @DomName('TextTrack.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('TextTrack.cuechange')
  @DocsEditable
  Stream<Event> get onCueChange => cueChangeEvent.forTarget(this);
}

@DocsEditable
@deprecated
class TextTrackEvents extends Events {
  @DocsEditable
  TextTrackEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get cueChange => this['cuechange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('TextTrackCue')
class TextTrackCue extends EventTarget native "*TextTrackCue" {

  @DomName('TextTrackCue.enter')
  @DocsEditable
  static const EventStreamProvider<Event> enterEvent = const EventStreamProvider<Event>('enter');

  @DomName('TextTrackCue.exit')
  @DocsEditable
  static const EventStreamProvider<Event> exitEvent = const EventStreamProvider<Event>('exit');

  @DocsEditable
  factory TextTrackCue(num startTime, num endTime, String text) => TextTrackCue._create(startTime, endTime, text);
  static TextTrackCue _create(num startTime, num endTime, String text) => JS('TextTrackCue', 'new TextTrackCue(#,#,#)', startTime, endTime, text);

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  TextTrackCueEvents get on =>
    new TextTrackCueEvents(this);

  @DomName('TextTrackCue.align')
  @DocsEditable
  String align;

  @DomName('TextTrackCue.endTime')
  @DocsEditable
  num endTime;

  @DomName('TextTrackCue.id')
  @DocsEditable
  String id;

  @DomName('TextTrackCue.line')
  @DocsEditable
  int line;

  @DomName('TextTrackCue.pauseOnExit')
  @DocsEditable
  bool pauseOnExit;

  @DomName('TextTrackCue.position')
  @DocsEditable
  int position;

  @DomName('TextTrackCue.size')
  @DocsEditable
  int size;

  @DomName('TextTrackCue.snapToLines')
  @DocsEditable
  bool snapToLines;

  @DomName('TextTrackCue.startTime')
  @DocsEditable
  num startTime;

  @DomName('TextTrackCue.text')
  @DocsEditable
  String text;

  @DomName('TextTrackCue.track')
  @DocsEditable
  final TextTrack track;

  @DomName('TextTrackCue.vertical')
  @DocsEditable
  String vertical;

  @JSName('addEventListener')
  @DomName('TextTrackCue.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('TextTrackCue.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native;

  @JSName('getCueAsHTML')
  @DomName('TextTrackCue.getCueAsHTML')
  @DocsEditable
  DocumentFragment getCueAsHtml() native;

  @JSName('removeEventListener')
  @DomName('TextTrackCue.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('TextTrackCue.enter')
  @DocsEditable
  Stream<Event> get onEnter => enterEvent.forTarget(this);

  @DomName('TextTrackCue.exit')
  @DocsEditable
  Stream<Event> get onExit => exitEvent.forTarget(this);
}

@DocsEditable
@deprecated
class TextTrackCueEvents extends Events {
  @DocsEditable
  TextTrackCueEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get enter => this['enter'];

  @DocsEditable
  EventListenerList get exit => this['exit'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('TextTrackCueList')
class TextTrackCueList implements List<TextTrackCue>, JavaScriptIndexingBehavior native "*TextTrackCueList" {

  @DomName('TextTrackCueList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  TextTrackCue operator[](int index) => JS("TextTrackCue", "#[#]", this, index);

  void operator[]=(int index, TextTrackCue value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<TextTrackCue> mixins.
  // TextTrackCue is the element type.

  // From Iterable<TextTrackCue>:

  Iterator<TextTrackCue> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<TextTrackCue>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, TextTrackCue)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(TextTrackCue element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(TextTrackCue element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(TextTrackCue element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<TextTrackCue> where(bool f(TextTrackCue element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(TextTrackCue element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(TextTrackCue element)) => IterableMixinWorkaround.any(this, f);

  List<TextTrackCue> toList() => new List<TextTrackCue>.from(this);
  Set<TextTrackCue> toSet() => new Set<TextTrackCue>.from(this);

  bool get isEmpty => this.length == 0;

  List<TextTrackCue> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<TextTrackCue> takeWhile(bool test(TextTrackCue value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<TextTrackCue> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<TextTrackCue> skipWhile(bool test(TextTrackCue value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  TextTrackCue firstMatching(bool test(TextTrackCue value), { TextTrackCue orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  TextTrackCue lastMatching(bool test(TextTrackCue value), {TextTrackCue orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  TextTrackCue singleMatching(bool test(TextTrackCue value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  TextTrackCue elementAt(int index) {
    return this[index];
  }

  // From Collection<TextTrackCue>:

  void add(TextTrackCue value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(TextTrackCue value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<TextTrackCue> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<TextTrackCue>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<TextTrackCue> get reversed =>
      new ReversedListView<TextTrackCue>(this, 0, null);

  void sort([int compare(TextTrackCue a, TextTrackCue b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(TextTrackCue element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(TextTrackCue element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  TextTrackCue get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  TextTrackCue get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  TextTrackCue get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  TextTrackCue min([int compare(TextTrackCue a, TextTrackCue b)]) =>
      IterableMixinWorkaround.min(this, compare);

  TextTrackCue max([int compare(TextTrackCue a, TextTrackCue b)]) =>
      IterableMixinWorkaround.max(this, compare);

  TextTrackCue removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  TextTrackCue removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(TextTrackCue element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(TextTrackCue element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<TextTrackCue> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [TextTrackCue initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<TextTrackCue> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <TextTrackCue>[]);

  // -- end List<TextTrackCue> mixins.

  @DomName('TextTrackCueList.getCueById')
  @DocsEditable
  TextTrackCue getCueById(String id) native;

  @DomName('TextTrackCueList.item')
  @DocsEditable
  TextTrackCue item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('TextTrackList')
class TextTrackList extends EventTarget implements JavaScriptIndexingBehavior, List<TextTrack> native "*TextTrackList" {

  @DomName('TextTrackList.addtrack')
  @DocsEditable
  static const EventStreamProvider<TrackEvent> addTrackEvent = const EventStreamProvider<TrackEvent>('addtrack');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  TextTrackListEvents get on =>
    new TextTrackListEvents(this);

  @DomName('TextTrackList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  TextTrack operator[](int index) => JS("TextTrack", "#[#]", this, index);

  void operator[]=(int index, TextTrack value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<TextTrack> mixins.
  // TextTrack is the element type.

  // From Iterable<TextTrack>:

  Iterator<TextTrack> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<TextTrack>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, TextTrack)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(TextTrack element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(TextTrack element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(TextTrack element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<TextTrack> where(bool f(TextTrack element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(TextTrack element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(TextTrack element)) => IterableMixinWorkaround.any(this, f);

  List<TextTrack> toList() => new List<TextTrack>.from(this);
  Set<TextTrack> toSet() => new Set<TextTrack>.from(this);

  bool get isEmpty => this.length == 0;

  List<TextTrack> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<TextTrack> takeWhile(bool test(TextTrack value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<TextTrack> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<TextTrack> skipWhile(bool test(TextTrack value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  TextTrack firstMatching(bool test(TextTrack value), { TextTrack orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  TextTrack lastMatching(bool test(TextTrack value), {TextTrack orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  TextTrack singleMatching(bool test(TextTrack value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  TextTrack elementAt(int index) {
    return this[index];
  }

  // From Collection<TextTrack>:

  void add(TextTrack value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(TextTrack value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<TextTrack> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<TextTrack>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<TextTrack> get reversed =>
      new ReversedListView<TextTrack>(this, 0, null);

  void sort([int compare(TextTrack a, TextTrack b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(TextTrack element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(TextTrack element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  TextTrack get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  TextTrack get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  TextTrack get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  TextTrack min([int compare(TextTrack a, TextTrack b)]) =>
      IterableMixinWorkaround.min(this, compare);

  TextTrack max([int compare(TextTrack a, TextTrack b)]) =>
      IterableMixinWorkaround.max(this, compare);

  TextTrack removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  TextTrack removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(TextTrack element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(TextTrack element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<TextTrack> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [TextTrack initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<TextTrack> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <TextTrack>[]);

  // -- end List<TextTrack> mixins.

  @JSName('addEventListener')
  @DomName('TextTrackList.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('TextTrackList.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native;

  @DomName('TextTrackList.item')
  @DocsEditable
  TextTrack item(int index) native;

  @JSName('removeEventListener')
  @DomName('TextTrackList.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('TextTrackList.addtrack')
  @DocsEditable
  Stream<TrackEvent> get onAddTrack => addTrackEvent.forTarget(this);
}

@DocsEditable
@deprecated
class TextTrackListEvents extends Events {
  @DocsEditable
  TextTrackListEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get addTrack => this['addtrack'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('TimeRanges')
class TimeRanges native "*TimeRanges" {

  @DomName('TimeRanges.length')
  @DocsEditable
  final int length;

  @DomName('TimeRanges.end')
  @DocsEditable
  num end(int index) native;

  @DomName('TimeRanges.start')
  @DocsEditable
  num start(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void TimeoutHandler();
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLTitleElement')
class TitleElement extends Element native "*HTMLTitleElement" {

  @DocsEditable
  factory TitleElement() => document.$dom_createElement("title");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Touch')
class Touch native "*Touch" {

  @DomName('Touch.clientX')
  @DocsEditable
  final int clientX;

  @DomName('Touch.clientY')
  @DocsEditable
  final int clientY;

  @DomName('Touch.identifier')
  @DocsEditable
  final int identifier;

  @DomName('Touch.pageX')
  @DocsEditable
  final int pageX;

  @DomName('Touch.pageY')
  @DocsEditable
  final int pageY;

  @DomName('Touch.screenX')
  @DocsEditable
  final int screenX;

  @DomName('Touch.screenY')
  @DocsEditable
  final int screenY;

  EventTarget get target => _convertNativeToDart_EventTarget(this._target);
  @JSName('target')
  @DomName('Touch.target')
  @DocsEditable
  @Creates('Element|Document')
  @Returns('Element|Document')
  final dynamic _target;

  @DomName('Touch.webkitForce')
  @DocsEditable
  final num webkitForce;

  @DomName('Touch.webkitRadiusX')
  @DocsEditable
  final int webkitRadiusX;

  @DomName('Touch.webkitRadiusY')
  @DocsEditable
  final int webkitRadiusY;

  @DomName('Touch.webkitRotationAngle')
  @DocsEditable
  final num webkitRotationAngle;
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('TouchEvent')
class TouchEvent extends UIEvent native "*TouchEvent" {
  factory TouchEvent(TouchList touches, TouchList targetTouches,
      TouchList changedTouches, String type,
      {Window view, int screenX: 0, int screenY: 0, int clientX: 0,
      int clientY: 0, bool ctrlKey: false, bool altKey: false,
      bool shiftKey: false, bool metaKey: false}) {
    if (view == null) {
      view = window;
    }
    var e = document.$dom_createEvent("TouchEvent");
    e.$dom_initTouchEvent(touches, targetTouches, changedTouches, type, view,
        screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey);
    return e;
  }

  @DomName('TouchEvent.altKey')
  @DocsEditable
  final bool altKey;

  @DomName('TouchEvent.changedTouches')
  @DocsEditable
  final TouchList changedTouches;

  @DomName('TouchEvent.ctrlKey')
  @DocsEditable
  final bool ctrlKey;

  @DomName('TouchEvent.metaKey')
  @DocsEditable
  final bool metaKey;

  @DomName('TouchEvent.shiftKey')
  @DocsEditable
  final bool shiftKey;

  @DomName('TouchEvent.targetTouches')
  @DocsEditable
  final TouchList targetTouches;

  @DomName('TouchEvent.touches')
  @DocsEditable
  final TouchList touches;

  @JSName('initTouchEvent')
  @DomName('TouchEvent.initTouchEvent')
  @DocsEditable
  void $dom_initTouchEvent(TouchList touches, TouchList targetTouches, TouchList changedTouches, String type, Window view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('TouchList')
class TouchList implements JavaScriptIndexingBehavior, List<Touch> native "*TouchList" {

  @DomName('TouchList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  Touch operator[](int index) => JS("Touch", "#[#]", this, index);

  void operator[]=(int index, Touch value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Touch> mixins.
  // Touch is the element type.

  // From Iterable<Touch>:

  Iterator<Touch> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Touch>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, Touch)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(Touch element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(Touch element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(Touch element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<Touch> where(bool f(Touch element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(Touch element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(Touch element)) => IterableMixinWorkaround.any(this, f);

  List<Touch> toList() => new List<Touch>.from(this);
  Set<Touch> toSet() => new Set<Touch>.from(this);

  bool get isEmpty => this.length == 0;

  List<Touch> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<Touch> takeWhile(bool test(Touch value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<Touch> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<Touch> skipWhile(bool test(Touch value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  Touch firstMatching(bool test(Touch value), { Touch orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  Touch lastMatching(bool test(Touch value), {Touch orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  Touch singleMatching(bool test(Touch value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  Touch elementAt(int index) {
    return this[index];
  }

  // From Collection<Touch>:

  void add(Touch value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Touch value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<Touch> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<Touch>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<Touch> get reversed =>
      new ReversedListView<Touch>(this, 0, null);

  void sort([int compare(Touch a, Touch b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Touch element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Touch element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  Touch get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  Touch get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  Touch get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Touch min([int compare(Touch a, Touch b)]) =>
      IterableMixinWorkaround.min(this, compare);

  Touch max([int compare(Touch a, Touch b)]) =>
      IterableMixinWorkaround.max(this, compare);

  Touch removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  Touch removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(Touch element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(Touch element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<Touch> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Touch initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Touch> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <Touch>[]);

  // -- end List<Touch> mixins.

  @DomName('TouchList.item')
  @DocsEditable
  Touch item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLTrackElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class TrackElement extends Element native "*HTMLTrackElement" {

  @DocsEditable
  factory TrackElement() => document.$dom_createElement("track");

  /// Checks if this type is supported on the current platform.
  static bool get supported => Element.isTagSupported('track');

  static const int ERROR = 3;

  static const int LOADED = 2;

  static const int LOADING = 1;

  static const int NONE = 0;

  @JSName('default')
  @DomName('HTMLTrackElement.default')
  @DocsEditable
  bool defaultValue;

  @DomName('HTMLTrackElement.kind')
  @DocsEditable
  String kind;

  @DomName('HTMLTrackElement.label')
  @DocsEditable
  String label;

  @DomName('HTMLTrackElement.readyState')
  @DocsEditable
  final int readyState;

  @DomName('HTMLTrackElement.src')
  @DocsEditable
  String src;

  @DomName('HTMLTrackElement.srclang')
  @DocsEditable
  String srclang;

  @DomName('HTMLTrackElement.track')
  @DocsEditable
  final TextTrack track;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('TrackEvent')
class TrackEvent extends Event native "*TrackEvent" {

  @DomName('TrackEvent.track')
  @DocsEditable
  final Object track;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebKitTransitionEvent')
class TransitionEvent extends Event native "*WebKitTransitionEvent" {

  @DomName('WebKitTransitionEvent.elapsedTime')
  @DocsEditable
  final num elapsedTime;

  @DomName('WebKitTransitionEvent.propertyName')
  @DocsEditable
  final String propertyName;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('TreeWalker')
class TreeWalker native "*TreeWalker" {

  @DomName('TreeWalker.currentNode')
  @DocsEditable
  Node currentNode;

  @DomName('TreeWalker.expandEntityReferences')
  @DocsEditable
  final bool expandEntityReferences;

  @DomName('TreeWalker.filter')
  @DocsEditable
  final NodeFilter filter;

  @DomName('TreeWalker.root')
  @DocsEditable
  final Node root;

  @DomName('TreeWalker.whatToShow')
  @DocsEditable
  final int whatToShow;

  @DomName('TreeWalker.firstChild')
  @DocsEditable
  Node firstChild() native;

  @DomName('TreeWalker.lastChild')
  @DocsEditable
  Node lastChild() native;

  @DomName('TreeWalker.nextNode')
  @DocsEditable
  Node nextNode() native;

  @DomName('TreeWalker.nextSibling')
  @DocsEditable
  Node nextSibling() native;

  @DomName('TreeWalker.parentNode')
  @DocsEditable
  Node parentNode() native;

  @DomName('TreeWalker.previousNode')
  @DocsEditable
  Node previousNode() native;

  @DomName('TreeWalker.previousSibling')
  @DocsEditable
  Node previousSibling() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('UIEvent')
class UIEvent extends Event native "*UIEvent" {
  // In JS, canBubble and cancelable are technically required parameters to
  // init*Event. In practice, though, if they aren't provided they simply
  // default to false (since that's Boolean(undefined)).
  //
  // Contrary to JS, we default canBubble and cancelable to true, since that's
  // what people want most of the time anyway.
  factory UIEvent(String type,
      {Window view, int detail: 0, bool canBubble: true,
      bool cancelable: true}) {
    if (view == null) {
      view = window;
    }
    final e = document.$dom_createEvent("UIEvent");
    e.$dom_initUIEvent(type, canBubble, cancelable, view, detail);
    return e;
  }

  @JSName('charCode')
  @DomName('UIEvent.charCode')
  @DocsEditable
  final int $dom_charCode;

  @DomName('UIEvent.detail')
  @DocsEditable
  final int detail;

  @JSName('keyCode')
  @DomName('UIEvent.keyCode')
  @DocsEditable
  final int $dom_keyCode;

  @DomName('UIEvent.layerX')
  @DocsEditable
  final int layerX;

  @DomName('UIEvent.layerY')
  @DocsEditable
  final int layerY;

  @DomName('UIEvent.pageX')
  @DocsEditable
  final int pageX;

  @DomName('UIEvent.pageY')
  @DocsEditable
  final int pageY;

  WindowBase get view => _convertNativeToDart_Window(this._view);
  @JSName('view')
  @DomName('UIEvent.view')
  @DocsEditable
  @Creates('Window|=Object')
  @Returns('Window|=Object')
  final dynamic _view;

  @DomName('UIEvent.which')
  @DocsEditable
  final int which;

  @JSName('initUIEvent')
  @DomName('UIEvent.initUIEvent')
  @DocsEditable
  void $dom_initUIEvent(String type, bool canBubble, bool cancelable, Window view, int detail) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLUListElement')
class UListElement extends Element native "*HTMLUListElement" {

  @DocsEditable
  factory UListElement() => document.$dom_createElement("ul");
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Uint16Array')
class Uint16Array extends ArrayBufferView implements JavaScriptIndexingBehavior, List<int> native "*Uint16Array" {

  factory Uint16Array(int length) =>
    _TypedArrayFactoryProvider.createUint16Array(length);

  factory Uint16Array.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createUint16Array_fromList(list);

  factory Uint16Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createUint16Array_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 2;

  @DomName('Uint16Array.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  int operator[](int index) => JS("int", "#[#]", this, index);

  void operator[]=(int index, int value) { JS("void", "#[#] = #", this, index, value); }  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<int>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, int)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(int element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(int element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(int element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<int> where(bool f(int element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(int element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(int element)) => IterableMixinWorkaround.any(this, f);

  List<int> toList() => new List<int>.from(this);
  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  List<int> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<int> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<int> skipWhile(bool test(int value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  int firstMatching(bool test(int value), { int orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  int lastMatching(bool test(int value), {int orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  int singleMatching(bool test(int value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  int elementAt(int index) {
    return this[index];
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<int>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<int> get reversed =>
      new ReversedListView<int>(this, 0, null);

  void sort([int compare(int a, int b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  int get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  int get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  int get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  int min([int compare(int a, int b)]) =>
      IterableMixinWorkaround.min(this, compare);

  int max([int compare(int a, int b)]) =>
      IterableMixinWorkaround.max(this, compare);

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<int> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [int initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <int>[]);

  // -- end List<int> mixins.

  @JSName('set')
  @DomName('Uint16Array.set')
  @DocsEditable
  void setElements(Object array, [int offset]) native;

  @DomName('Uint16Array.subarray')
  @DocsEditable
  Uint16Array subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Uint32Array')
class Uint32Array extends ArrayBufferView implements JavaScriptIndexingBehavior, List<int> native "*Uint32Array" {

  factory Uint32Array(int length) =>
    _TypedArrayFactoryProvider.createUint32Array(length);

  factory Uint32Array.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createUint32Array_fromList(list);

  factory Uint32Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createUint32Array_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 4;

  @DomName('Uint32Array.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  int operator[](int index) => JS("int", "#[#]", this, index);

  void operator[]=(int index, int value) { JS("void", "#[#] = #", this, index, value); }  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<int>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, int)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(int element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(int element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(int element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<int> where(bool f(int element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(int element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(int element)) => IterableMixinWorkaround.any(this, f);

  List<int> toList() => new List<int>.from(this);
  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  List<int> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<int> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<int> skipWhile(bool test(int value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  int firstMatching(bool test(int value), { int orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  int lastMatching(bool test(int value), {int orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  int singleMatching(bool test(int value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  int elementAt(int index) {
    return this[index];
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<int>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<int> get reversed =>
      new ReversedListView<int>(this, 0, null);

  void sort([int compare(int a, int b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  int get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  int get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  int get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  int min([int compare(int a, int b)]) =>
      IterableMixinWorkaround.min(this, compare);

  int max([int compare(int a, int b)]) =>
      IterableMixinWorkaround.max(this, compare);

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<int> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [int initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <int>[]);

  // -- end List<int> mixins.

  @JSName('set')
  @DomName('Uint32Array.set')
  @DocsEditable
  void setElements(Object array, [int offset]) native;

  @DomName('Uint32Array.subarray')
  @DocsEditable
  Uint32Array subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Uint8Array')
class Uint8Array extends ArrayBufferView implements JavaScriptIndexingBehavior, List<int> native "*Uint8Array" {

  factory Uint8Array(int length) =>
    _TypedArrayFactoryProvider.createUint8Array(length);

  factory Uint8Array.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createUint8Array_fromList(list);

  factory Uint8Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createUint8Array_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 1;

  @DomName('Uint8Array.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  int operator[](int index) => JS("int", "#[#]", this, index);

  void operator[]=(int index, int value) { JS("void", "#[#] = #", this, index, value); }  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<int>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, int)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(int element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(int element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(int element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<int> where(bool f(int element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(int element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(int element)) => IterableMixinWorkaround.any(this, f);

  List<int> toList() => new List<int>.from(this);
  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  List<int> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<int> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<int> skipWhile(bool test(int value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  int firstMatching(bool test(int value), { int orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  int lastMatching(bool test(int value), {int orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  int singleMatching(bool test(int value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  int elementAt(int index) {
    return this[index];
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<int>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<int> get reversed =>
      new ReversedListView<int>(this, 0, null);

  void sort([int compare(int a, int b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  int get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  int get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  int get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  int min([int compare(int a, int b)]) =>
      IterableMixinWorkaround.min(this, compare);

  int max([int compare(int a, int b)]) =>
      IterableMixinWorkaround.max(this, compare);

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<int> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [int initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <int>[]);

  // -- end List<int> mixins.

  @JSName('set')
  @DomName('Uint8Array.set')
  @DocsEditable
  void setElements(Object array, [int offset]) native;

  @DomName('Uint8Array.subarray')
  @DocsEditable
  Uint8Array subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Uint8ClampedArray')
class Uint8ClampedArray extends Uint8Array implements JavaScriptIndexingBehavior, List<int> native "*Uint8ClampedArray" {

  factory Uint8ClampedArray(int length) =>
    _TypedArrayFactoryProvider.createUint8ClampedArray(length);

  factory Uint8ClampedArray.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createUint8ClampedArray_fromList(list);

  factory Uint8ClampedArray.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createUint8ClampedArray_fromBuffer(buffer, byteOffset, length);

  // Use implementation from Uint8Array.
  // final int length;

  int operator[](int index) => JS("int", "#[#]", this, index);

  void operator[]=(int index, int value) { JS("void", "#[#] = #", this, index, value); }  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<int>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, int)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(int element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(int element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(int element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<int> where(bool f(int element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(int element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(int element)) => IterableMixinWorkaround.any(this, f);

  List<int> toList() => new List<int>.from(this);
  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  List<int> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<int> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<int> skipWhile(bool test(int value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  int firstMatching(bool test(int value), { int orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  int lastMatching(bool test(int value), {int orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  int singleMatching(bool test(int value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  int elementAt(int index) {
    return this[index];
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<int>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<int> get reversed =>
      new ReversedListView<int>(this, 0, null);

  void sort([int compare(int a, int b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  int get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  int get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  int get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  int min([int compare(int a, int b)]) =>
      IterableMixinWorkaround.min(this, compare);

  int max([int compare(int a, int b)]) =>
      IterableMixinWorkaround.max(this, compare);

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<int> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [int initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <int>[]);

  // -- end List<int> mixins.

  @JSName('set')
  @DomName('Uint8ClampedArray.set')
  @DocsEditable
  void setElements(Object array, [int offset]) native;

  @DomName('Uint8ClampedArray.subarray')
  @DocsEditable
  Uint8ClampedArray subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLUnknownElement')
class UnknownElement extends Element native "*HTMLUnknownElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('URL')
class Url native "*URL" {

  static String createObjectUrl(blob_OR_source_OR_stream) =>
      JS('String',
         '(window.URL || window.webkitURL).createObjectURL(#)',
         blob_OR_source_OR_stream);

  static void revokeObjectUrl(String objectUrl) =>
      JS('void',
         '(window.URL || window.webkitURL).revokeObjectURL(#)', objectUrl);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('ValidityState')
class ValidityState native "*ValidityState" {

  @DomName('ValidityState.badInput')
  @DocsEditable
  final bool badInput;

  @DomName('ValidityState.customError')
  @DocsEditable
  final bool customError;

  @DomName('ValidityState.patternMismatch')
  @DocsEditable
  final bool patternMismatch;

  @DomName('ValidityState.rangeOverflow')
  @DocsEditable
  final bool rangeOverflow;

  @DomName('ValidityState.rangeUnderflow')
  @DocsEditable
  final bool rangeUnderflow;

  @DomName('ValidityState.stepMismatch')
  @DocsEditable
  final bool stepMismatch;

  @DomName('ValidityState.tooLong')
  @DocsEditable
  final bool tooLong;

  @DomName('ValidityState.typeMismatch')
  @DocsEditable
  final bool typeMismatch;

  @DomName('ValidityState.valid')
  @DocsEditable
  final bool valid;

  @DomName('ValidityState.valueMissing')
  @DocsEditable
  final bool valueMissing;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLVideoElement')
class VideoElement extends MediaElement native "*HTMLVideoElement" {

  @DocsEditable
  factory VideoElement() => document.$dom_createElement("video");

  @DomName('HTMLVideoElement.height')
  @DocsEditable
  int height;

  @DomName('HTMLVideoElement.poster')
  @DocsEditable
  String poster;

  @DomName('HTMLVideoElement.videoHeight')
  @DocsEditable
  final int videoHeight;

  @DomName('HTMLVideoElement.videoWidth')
  @DocsEditable
  final int videoWidth;

  @DomName('HTMLVideoElement.webkitDecodedFrameCount')
  @DocsEditable
  final int webkitDecodedFrameCount;

  @DomName('HTMLVideoElement.webkitDisplayingFullscreen')
  @DocsEditable
  final bool webkitDisplayingFullscreen;

  @DomName('HTMLVideoElement.webkitDroppedFrameCount')
  @DocsEditable
  final int webkitDroppedFrameCount;

  @DomName('HTMLVideoElement.webkitSupportsFullscreen')
  @DocsEditable
  final bool webkitSupportsFullscreen;

  @DomName('HTMLVideoElement.width')
  @DocsEditable
  int width;

  @DomName('HTMLVideoElement.webkitEnterFullScreen')
  @DocsEditable
  void webkitEnterFullScreen() native;

  @DomName('HTMLVideoElement.webkitEnterFullscreen')
  @DocsEditable
  void webkitEnterFullscreen() native;

  @DomName('HTMLVideoElement.webkitExitFullScreen')
  @DocsEditable
  void webkitExitFullScreen() native;

  @DomName('HTMLVideoElement.webkitExitFullscreen')
  @DocsEditable
  void webkitExitFullscreen() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void VoidCallback();
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebGLActiveInfo')
class WebGLActiveInfo native "*WebGLActiveInfo" {

  @DomName('WebGLActiveInfo.name')
  @DocsEditable
  final String name;

  @DomName('WebGLActiveInfo.size')
  @DocsEditable
  final int size;

  @DomName('WebGLActiveInfo.type')
  @DocsEditable
  final int type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebGLBuffer')
class WebGLBuffer native "*WebGLBuffer" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebGLCompressedTextureS3TC')
class WebGLCompressedTextureS3TC native "*WebGLCompressedTextureS3TC" {

  static const int COMPRESSED_RGBA_S3TC_DXT1_EXT = 0x83F1;

  static const int COMPRESSED_RGBA_S3TC_DXT3_EXT = 0x83F2;

  static const int COMPRESSED_RGBA_S3TC_DXT5_EXT = 0x83F3;

  static const int COMPRESSED_RGB_S3TC_DXT1_EXT = 0x83F0;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebGLContextAttributes')
class WebGLContextAttributes native "*WebGLContextAttributes" {

  @DomName('WebGLContextAttributes.alpha')
  @DocsEditable
  bool alpha;

  @DomName('WebGLContextAttributes.antialias')
  @DocsEditable
  bool antialias;

  @DomName('WebGLContextAttributes.depth')
  @DocsEditable
  bool depth;

  @DomName('WebGLContextAttributes.premultipliedAlpha')
  @DocsEditable
  bool premultipliedAlpha;

  @DomName('WebGLContextAttributes.preserveDrawingBuffer')
  @DocsEditable
  bool preserveDrawingBuffer;

  @DomName('WebGLContextAttributes.stencil')
  @DocsEditable
  bool stencil;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebGLContextEvent')
class WebGLContextEvent extends Event native "*WebGLContextEvent" {

  @DomName('WebGLContextEvent.statusMessage')
  @DocsEditable
  final String statusMessage;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebGLDebugRendererInfo')
class WebGLDebugRendererInfo native "*WebGLDebugRendererInfo" {

  static const int UNMASKED_RENDERER_WEBGL = 0x9246;

  static const int UNMASKED_VENDOR_WEBGL = 0x9245;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebGLDebugShaders')
class WebGLDebugShaders native "*WebGLDebugShaders" {

  @DomName('WebGLDebugShaders.getTranslatedShaderSource')
  @DocsEditable
  String getTranslatedShaderSource(WebGLShader shader) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebGLDepthTexture')
class WebGLDepthTexture native "*WebGLDepthTexture" {

  static const int UNSIGNED_INT_24_8_WEBGL = 0x84FA;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebGLFramebuffer')
class WebGLFramebuffer native "*WebGLFramebuffer" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebGLLoseContext')
class WebGLLoseContext native "*WebGLLoseContext" {

  @DomName('WebGLLoseContext.loseContext')
  @DocsEditable
  void loseContext() native;

  @DomName('WebGLLoseContext.restoreContext')
  @DocsEditable
  void restoreContext() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebGLProgram')
class WebGLProgram native "*WebGLProgram" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebGLRenderbuffer')
class WebGLRenderbuffer native "*WebGLRenderbuffer" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebGLRenderingContext')
class WebGLRenderingContext extends CanvasRenderingContext native "*WebGLRenderingContext" {

  static const int ACTIVE_ATTRIBUTES = 0x8B89;

  static const int ACTIVE_TEXTURE = 0x84E0;

  static const int ACTIVE_UNIFORMS = 0x8B86;

  static const int ALIASED_LINE_WIDTH_RANGE = 0x846E;

  static const int ALIASED_POINT_SIZE_RANGE = 0x846D;

  static const int ALPHA = 0x1906;

  static const int ALPHA_BITS = 0x0D55;

  static const int ALWAYS = 0x0207;

  static const int ARRAY_BUFFER = 0x8892;

  static const int ARRAY_BUFFER_BINDING = 0x8894;

  static const int ATTACHED_SHADERS = 0x8B85;

  static const int BACK = 0x0405;

  static const int BLEND = 0x0BE2;

  static const int BLEND_COLOR = 0x8005;

  static const int BLEND_DST_ALPHA = 0x80CA;

  static const int BLEND_DST_RGB = 0x80C8;

  static const int BLEND_EQUATION = 0x8009;

  static const int BLEND_EQUATION_ALPHA = 0x883D;

  static const int BLEND_EQUATION_RGB = 0x8009;

  static const int BLEND_SRC_ALPHA = 0x80CB;

  static const int BLEND_SRC_RGB = 0x80C9;

  static const int BLUE_BITS = 0x0D54;

  static const int BOOL = 0x8B56;

  static const int BOOL_VEC2 = 0x8B57;

  static const int BOOL_VEC3 = 0x8B58;

  static const int BOOL_VEC4 = 0x8B59;

  static const int BROWSER_DEFAULT_WEBGL = 0x9244;

  static const int BUFFER_SIZE = 0x8764;

  static const int BUFFER_USAGE = 0x8765;

  static const int BYTE = 0x1400;

  static const int CCW = 0x0901;

  static const int CLAMP_TO_EDGE = 0x812F;

  static const int COLOR_ATTACHMENT0 = 0x8CE0;

  static const int COLOR_BUFFER_BIT = 0x00004000;

  static const int COLOR_CLEAR_VALUE = 0x0C22;

  static const int COLOR_WRITEMASK = 0x0C23;

  static const int COMPILE_STATUS = 0x8B81;

  static const int COMPRESSED_TEXTURE_FORMATS = 0x86A3;

  static const int CONSTANT_ALPHA = 0x8003;

  static const int CONSTANT_COLOR = 0x8001;

  static const int CONTEXT_LOST_WEBGL = 0x9242;

  static const int CULL_FACE = 0x0B44;

  static const int CULL_FACE_MODE = 0x0B45;

  static const int CURRENT_PROGRAM = 0x8B8D;

  static const int CURRENT_VERTEX_ATTRIB = 0x8626;

  static const int CW = 0x0900;

  static const int DECR = 0x1E03;

  static const int DECR_WRAP = 0x8508;

  static const int DELETE_STATUS = 0x8B80;

  static const int DEPTH_ATTACHMENT = 0x8D00;

  static const int DEPTH_BITS = 0x0D56;

  static const int DEPTH_BUFFER_BIT = 0x00000100;

  static const int DEPTH_CLEAR_VALUE = 0x0B73;

  static const int DEPTH_COMPONENT = 0x1902;

  static const int DEPTH_COMPONENT16 = 0x81A5;

  static const int DEPTH_FUNC = 0x0B74;

  static const int DEPTH_RANGE = 0x0B70;

  static const int DEPTH_STENCIL = 0x84F9;

  static const int DEPTH_STENCIL_ATTACHMENT = 0x821A;

  static const int DEPTH_TEST = 0x0B71;

  static const int DEPTH_WRITEMASK = 0x0B72;

  static const int DITHER = 0x0BD0;

  static const int DONT_CARE = 0x1100;

  static const int DST_ALPHA = 0x0304;

  static const int DST_COLOR = 0x0306;

  static const int DYNAMIC_DRAW = 0x88E8;

  static const int ELEMENT_ARRAY_BUFFER = 0x8893;

  static const int ELEMENT_ARRAY_BUFFER_BINDING = 0x8895;

  static const int EQUAL = 0x0202;

  static const int FASTEST = 0x1101;

  static const int FLOAT = 0x1406;

  static const int FLOAT_MAT2 = 0x8B5A;

  static const int FLOAT_MAT3 = 0x8B5B;

  static const int FLOAT_MAT4 = 0x8B5C;

  static const int FLOAT_VEC2 = 0x8B50;

  static const int FLOAT_VEC3 = 0x8B51;

  static const int FLOAT_VEC4 = 0x8B52;

  static const int FRAGMENT_SHADER = 0x8B30;

  static const int FRAMEBUFFER = 0x8D40;

  static const int FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1;

  static const int FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = 0x8CD0;

  static const int FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3;

  static const int FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = 0x8CD2;

  static const int FRAMEBUFFER_BINDING = 0x8CA6;

  static const int FRAMEBUFFER_COMPLETE = 0x8CD5;

  static const int FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6;

  static const int FRAMEBUFFER_INCOMPLETE_DIMENSIONS = 0x8CD9;

  static const int FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7;

  static const int FRAMEBUFFER_UNSUPPORTED = 0x8CDD;

  static const int FRONT = 0x0404;

  static const int FRONT_AND_BACK = 0x0408;

  static const int FRONT_FACE = 0x0B46;

  static const int FUNC_ADD = 0x8006;

  static const int FUNC_REVERSE_SUBTRACT = 0x800B;

  static const int FUNC_SUBTRACT = 0x800A;

  static const int GENERATE_MIPMAP_HINT = 0x8192;

  static const int GEQUAL = 0x0206;

  static const int GREATER = 0x0204;

  static const int GREEN_BITS = 0x0D53;

  static const int HIGH_FLOAT = 0x8DF2;

  static const int HIGH_INT = 0x8DF5;

  static const int INCR = 0x1E02;

  static const int INCR_WRAP = 0x8507;

  static const int INT = 0x1404;

  static const int INT_VEC2 = 0x8B53;

  static const int INT_VEC3 = 0x8B54;

  static const int INT_VEC4 = 0x8B55;

  static const int INVALID_ENUM = 0x0500;

  static const int INVALID_FRAMEBUFFER_OPERATION = 0x0506;

  static const int INVALID_OPERATION = 0x0502;

  static const int INVALID_VALUE = 0x0501;

  static const int INVERT = 0x150A;

  static const int KEEP = 0x1E00;

  static const int LEQUAL = 0x0203;

  static const int LESS = 0x0201;

  static const int LINEAR = 0x2601;

  static const int LINEAR_MIPMAP_LINEAR = 0x2703;

  static const int LINEAR_MIPMAP_NEAREST = 0x2701;

  static const int LINES = 0x0001;

  static const int LINE_LOOP = 0x0002;

  static const int LINE_STRIP = 0x0003;

  static const int LINE_WIDTH = 0x0B21;

  static const int LINK_STATUS = 0x8B82;

  static const int LOW_FLOAT = 0x8DF0;

  static const int LOW_INT = 0x8DF3;

  static const int LUMINANCE = 0x1909;

  static const int LUMINANCE_ALPHA = 0x190A;

  static const int MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D;

  static const int MAX_CUBE_MAP_TEXTURE_SIZE = 0x851C;

  static const int MAX_FRAGMENT_UNIFORM_VECTORS = 0x8DFD;

  static const int MAX_RENDERBUFFER_SIZE = 0x84E8;

  static const int MAX_TEXTURE_IMAGE_UNITS = 0x8872;

  static const int MAX_TEXTURE_SIZE = 0x0D33;

  static const int MAX_VARYING_VECTORS = 0x8DFC;

  static const int MAX_VERTEX_ATTRIBS = 0x8869;

  static const int MAX_VERTEX_TEXTURE_IMAGE_UNITS = 0x8B4C;

  static const int MAX_VERTEX_UNIFORM_VECTORS = 0x8DFB;

  static const int MAX_VIEWPORT_DIMS = 0x0D3A;

  static const int MEDIUM_FLOAT = 0x8DF1;

  static const int MEDIUM_INT = 0x8DF4;

  static const int MIRRORED_REPEAT = 0x8370;

  static const int NEAREST = 0x2600;

  static const int NEAREST_MIPMAP_LINEAR = 0x2702;

  static const int NEAREST_MIPMAP_NEAREST = 0x2700;

  static const int NEVER = 0x0200;

  static const int NICEST = 0x1102;

  static const int NONE = 0;

  static const int NOTEQUAL = 0x0205;

  static const int NO_ERROR = 0;

  static const int ONE = 1;

  static const int ONE_MINUS_CONSTANT_ALPHA = 0x8004;

  static const int ONE_MINUS_CONSTANT_COLOR = 0x8002;

  static const int ONE_MINUS_DST_ALPHA = 0x0305;

  static const int ONE_MINUS_DST_COLOR = 0x0307;

  static const int ONE_MINUS_SRC_ALPHA = 0x0303;

  static const int ONE_MINUS_SRC_COLOR = 0x0301;

  static const int OUT_OF_MEMORY = 0x0505;

  static const int PACK_ALIGNMENT = 0x0D05;

  static const int POINTS = 0x0000;

  static const int POLYGON_OFFSET_FACTOR = 0x8038;

  static const int POLYGON_OFFSET_FILL = 0x8037;

  static const int POLYGON_OFFSET_UNITS = 0x2A00;

  static const int RED_BITS = 0x0D52;

  static const int RENDERBUFFER = 0x8D41;

  static const int RENDERBUFFER_ALPHA_SIZE = 0x8D53;

  static const int RENDERBUFFER_BINDING = 0x8CA7;

  static const int RENDERBUFFER_BLUE_SIZE = 0x8D52;

  static const int RENDERBUFFER_DEPTH_SIZE = 0x8D54;

  static const int RENDERBUFFER_GREEN_SIZE = 0x8D51;

  static const int RENDERBUFFER_HEIGHT = 0x8D43;

  static const int RENDERBUFFER_INTERNAL_FORMAT = 0x8D44;

  static const int RENDERBUFFER_RED_SIZE = 0x8D50;

  static const int RENDERBUFFER_STENCIL_SIZE = 0x8D55;

  static const int RENDERBUFFER_WIDTH = 0x8D42;

  static const int RENDERER = 0x1F01;

  static const int REPEAT = 0x2901;

  static const int REPLACE = 0x1E01;

  static const int RGB = 0x1907;

  static const int RGB565 = 0x8D62;

  static const int RGB5_A1 = 0x8057;

  static const int RGBA = 0x1908;

  static const int RGBA4 = 0x8056;

  static const int SAMPLER_2D = 0x8B5E;

  static const int SAMPLER_CUBE = 0x8B60;

  static const int SAMPLES = 0x80A9;

  static const int SAMPLE_ALPHA_TO_COVERAGE = 0x809E;

  static const int SAMPLE_BUFFERS = 0x80A8;

  static const int SAMPLE_COVERAGE = 0x80A0;

  static const int SAMPLE_COVERAGE_INVERT = 0x80AB;

  static const int SAMPLE_COVERAGE_VALUE = 0x80AA;

  static const int SCISSOR_BOX = 0x0C10;

  static const int SCISSOR_TEST = 0x0C11;

  static const int SHADER_TYPE = 0x8B4F;

  static const int SHADING_LANGUAGE_VERSION = 0x8B8C;

  static const int SHORT = 0x1402;

  static const int SRC_ALPHA = 0x0302;

  static const int SRC_ALPHA_SATURATE = 0x0308;

  static const int SRC_COLOR = 0x0300;

  static const int STATIC_DRAW = 0x88E4;

  static const int STENCIL_ATTACHMENT = 0x8D20;

  static const int STENCIL_BACK_FAIL = 0x8801;

  static const int STENCIL_BACK_FUNC = 0x8800;

  static const int STENCIL_BACK_PASS_DEPTH_FAIL = 0x8802;

  static const int STENCIL_BACK_PASS_DEPTH_PASS = 0x8803;

  static const int STENCIL_BACK_REF = 0x8CA3;

  static const int STENCIL_BACK_VALUE_MASK = 0x8CA4;

  static const int STENCIL_BACK_WRITEMASK = 0x8CA5;

  static const int STENCIL_BITS = 0x0D57;

  static const int STENCIL_BUFFER_BIT = 0x00000400;

  static const int STENCIL_CLEAR_VALUE = 0x0B91;

  static const int STENCIL_FAIL = 0x0B94;

  static const int STENCIL_FUNC = 0x0B92;

  static const int STENCIL_INDEX = 0x1901;

  static const int STENCIL_INDEX8 = 0x8D48;

  static const int STENCIL_PASS_DEPTH_FAIL = 0x0B95;

  static const int STENCIL_PASS_DEPTH_PASS = 0x0B96;

  static const int STENCIL_REF = 0x0B97;

  static const int STENCIL_TEST = 0x0B90;

  static const int STENCIL_VALUE_MASK = 0x0B93;

  static const int STENCIL_WRITEMASK = 0x0B98;

  static const int STREAM_DRAW = 0x88E0;

  static const int SUBPIXEL_BITS = 0x0D50;

  static const int TEXTURE = 0x1702;

  static const int TEXTURE0 = 0x84C0;

  static const int TEXTURE1 = 0x84C1;

  static const int TEXTURE10 = 0x84CA;

  static const int TEXTURE11 = 0x84CB;

  static const int TEXTURE12 = 0x84CC;

  static const int TEXTURE13 = 0x84CD;

  static const int TEXTURE14 = 0x84CE;

  static const int TEXTURE15 = 0x84CF;

  static const int TEXTURE16 = 0x84D0;

  static const int TEXTURE17 = 0x84D1;

  static const int TEXTURE18 = 0x84D2;

  static const int TEXTURE19 = 0x84D3;

  static const int TEXTURE2 = 0x84C2;

  static const int TEXTURE20 = 0x84D4;

  static const int TEXTURE21 = 0x84D5;

  static const int TEXTURE22 = 0x84D6;

  static const int TEXTURE23 = 0x84D7;

  static const int TEXTURE24 = 0x84D8;

  static const int TEXTURE25 = 0x84D9;

  static const int TEXTURE26 = 0x84DA;

  static const int TEXTURE27 = 0x84DB;

  static const int TEXTURE28 = 0x84DC;

  static const int TEXTURE29 = 0x84DD;

  static const int TEXTURE3 = 0x84C3;

  static const int TEXTURE30 = 0x84DE;

  static const int TEXTURE31 = 0x84DF;

  static const int TEXTURE4 = 0x84C4;

  static const int TEXTURE5 = 0x84C5;

  static const int TEXTURE6 = 0x84C6;

  static const int TEXTURE7 = 0x84C7;

  static const int TEXTURE8 = 0x84C8;

  static const int TEXTURE9 = 0x84C9;

  static const int TEXTURE_2D = 0x0DE1;

  static const int TEXTURE_BINDING_2D = 0x8069;

  static const int TEXTURE_BINDING_CUBE_MAP = 0x8514;

  static const int TEXTURE_CUBE_MAP = 0x8513;

  static const int TEXTURE_CUBE_MAP_NEGATIVE_X = 0x8516;

  static const int TEXTURE_CUBE_MAP_NEGATIVE_Y = 0x8518;

  static const int TEXTURE_CUBE_MAP_NEGATIVE_Z = 0x851A;

  static const int TEXTURE_CUBE_MAP_POSITIVE_X = 0x8515;

  static const int TEXTURE_CUBE_MAP_POSITIVE_Y = 0x8517;

  static const int TEXTURE_CUBE_MAP_POSITIVE_Z = 0x8519;

  static const int TEXTURE_MAG_FILTER = 0x2800;

  static const int TEXTURE_MIN_FILTER = 0x2801;

  static const int TEXTURE_WRAP_S = 0x2802;

  static const int TEXTURE_WRAP_T = 0x2803;

  static const int TRIANGLES = 0x0004;

  static const int TRIANGLE_FAN = 0x0006;

  static const int TRIANGLE_STRIP = 0x0005;

  static const int UNPACK_ALIGNMENT = 0x0CF5;

  static const int UNPACK_COLORSPACE_CONVERSION_WEBGL = 0x9243;

  static const int UNPACK_FLIP_Y_WEBGL = 0x9240;

  static const int UNPACK_PREMULTIPLY_ALPHA_WEBGL = 0x9241;

  static const int UNSIGNED_BYTE = 0x1401;

  static const int UNSIGNED_INT = 0x1405;

  static const int UNSIGNED_SHORT = 0x1403;

  static const int UNSIGNED_SHORT_4_4_4_4 = 0x8033;

  static const int UNSIGNED_SHORT_5_5_5_1 = 0x8034;

  static const int UNSIGNED_SHORT_5_6_5 = 0x8363;

  static const int VALIDATE_STATUS = 0x8B83;

  static const int VENDOR = 0x1F00;

  static const int VERSION = 0x1F02;

  static const int VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;

  static const int VERTEX_ATTRIB_ARRAY_ENABLED = 0x8622;

  static const int VERTEX_ATTRIB_ARRAY_NORMALIZED = 0x886A;

  static const int VERTEX_ATTRIB_ARRAY_POINTER = 0x8645;

  static const int VERTEX_ATTRIB_ARRAY_SIZE = 0x8623;

  static const int VERTEX_ATTRIB_ARRAY_STRIDE = 0x8624;

  static const int VERTEX_ATTRIB_ARRAY_TYPE = 0x8625;

  static const int VERTEX_SHADER = 0x8B31;

  static const int VIEWPORT = 0x0BA2;

  static const int ZERO = 0;

  @DomName('WebGLRenderingContext.drawingBufferHeight')
  @DocsEditable
  final int drawingBufferHeight;

  @DomName('WebGLRenderingContext.drawingBufferWidth')
  @DocsEditable
  final int drawingBufferWidth;

  @DomName('WebGLRenderingContext.activeTexture')
  @DocsEditable
  void activeTexture(int texture) native;

  @DomName('WebGLRenderingContext.attachShader')
  @DocsEditable
  void attachShader(WebGLProgram program, WebGLShader shader) native;

  @DomName('WebGLRenderingContext.bindAttribLocation')
  @DocsEditable
  void bindAttribLocation(WebGLProgram program, int index, String name) native;

  @DomName('WebGLRenderingContext.bindBuffer')
  @DocsEditable
  void bindBuffer(int target, WebGLBuffer buffer) native;

  @DomName('WebGLRenderingContext.bindFramebuffer')
  @DocsEditable
  void bindFramebuffer(int target, WebGLFramebuffer framebuffer) native;

  @DomName('WebGLRenderingContext.bindRenderbuffer')
  @DocsEditable
  void bindRenderbuffer(int target, WebGLRenderbuffer renderbuffer) native;

  @DomName('WebGLRenderingContext.bindTexture')
  @DocsEditable
  void bindTexture(int target, WebGLTexture texture) native;

  @DomName('WebGLRenderingContext.blendColor')
  @DocsEditable
  void blendColor(num red, num green, num blue, num alpha) native;

  @DomName('WebGLRenderingContext.blendEquation')
  @DocsEditable
  void blendEquation(int mode) native;

  @DomName('WebGLRenderingContext.blendEquationSeparate')
  @DocsEditable
  void blendEquationSeparate(int modeRGB, int modeAlpha) native;

  @DomName('WebGLRenderingContext.blendFunc')
  @DocsEditable
  void blendFunc(int sfactor, int dfactor) native;

  @DomName('WebGLRenderingContext.blendFuncSeparate')
  @DocsEditable
  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) native;

  @DomName('WebGLRenderingContext.bufferData')
  @DocsEditable
  void bufferData(int target, data_OR_size, int usage) native;

  @DomName('WebGLRenderingContext.bufferSubData')
  @DocsEditable
  void bufferSubData(int target, int offset, data) native;

  @DomName('WebGLRenderingContext.checkFramebufferStatus')
  @DocsEditable
  int checkFramebufferStatus(int target) native;

  @DomName('WebGLRenderingContext.clear')
  @DocsEditable
  void clear(int mask) native;

  @DomName('WebGLRenderingContext.clearColor')
  @DocsEditable
  void clearColor(num red, num green, num blue, num alpha) native;

  @DomName('WebGLRenderingContext.clearDepth')
  @DocsEditable
  void clearDepth(num depth) native;

  @DomName('WebGLRenderingContext.clearStencil')
  @DocsEditable
  void clearStencil(int s) native;

  @DomName('WebGLRenderingContext.colorMask')
  @DocsEditable
  void colorMask(bool red, bool green, bool blue, bool alpha) native;

  @DomName('WebGLRenderingContext.compileShader')
  @DocsEditable
  void compileShader(WebGLShader shader) native;

  @DomName('WebGLRenderingContext.compressedTexImage2D')
  @DocsEditable
  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, ArrayBufferView data) native;

  @DomName('WebGLRenderingContext.compressedTexSubImage2D')
  @DocsEditable
  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, ArrayBufferView data) native;

  @DomName('WebGLRenderingContext.copyTexImage2D')
  @DocsEditable
  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border) native;

  @DomName('WebGLRenderingContext.copyTexSubImage2D')
  @DocsEditable
  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height) native;

  @DomName('WebGLRenderingContext.createBuffer')
  @DocsEditable
  WebGLBuffer createBuffer() native;

  @DomName('WebGLRenderingContext.createFramebuffer')
  @DocsEditable
  WebGLFramebuffer createFramebuffer() native;

  @DomName('WebGLRenderingContext.createProgram')
  @DocsEditable
  WebGLProgram createProgram() native;

  @DomName('WebGLRenderingContext.createRenderbuffer')
  @DocsEditable
  WebGLRenderbuffer createRenderbuffer() native;

  @DomName('WebGLRenderingContext.createShader')
  @DocsEditable
  WebGLShader createShader(int type) native;

  @DomName('WebGLRenderingContext.createTexture')
  @DocsEditable
  WebGLTexture createTexture() native;

  @DomName('WebGLRenderingContext.cullFace')
  @DocsEditable
  void cullFace(int mode) native;

  @DomName('WebGLRenderingContext.deleteBuffer')
  @DocsEditable
  void deleteBuffer(WebGLBuffer buffer) native;

  @DomName('WebGLRenderingContext.deleteFramebuffer')
  @DocsEditable
  void deleteFramebuffer(WebGLFramebuffer framebuffer) native;

  @DomName('WebGLRenderingContext.deleteProgram')
  @DocsEditable
  void deleteProgram(WebGLProgram program) native;

  @DomName('WebGLRenderingContext.deleteRenderbuffer')
  @DocsEditable
  void deleteRenderbuffer(WebGLRenderbuffer renderbuffer) native;

  @DomName('WebGLRenderingContext.deleteShader')
  @DocsEditable
  void deleteShader(WebGLShader shader) native;

  @DomName('WebGLRenderingContext.deleteTexture')
  @DocsEditable
  void deleteTexture(WebGLTexture texture) native;

  @DomName('WebGLRenderingContext.depthFunc')
  @DocsEditable
  void depthFunc(int func) native;

  @DomName('WebGLRenderingContext.depthMask')
  @DocsEditable
  void depthMask(bool flag) native;

  @DomName('WebGLRenderingContext.depthRange')
  @DocsEditable
  void depthRange(num zNear, num zFar) native;

  @DomName('WebGLRenderingContext.detachShader')
  @DocsEditable
  void detachShader(WebGLProgram program, WebGLShader shader) native;

  @DomName('WebGLRenderingContext.disable')
  @DocsEditable
  void disable(int cap) native;

  @DomName('WebGLRenderingContext.disableVertexAttribArray')
  @DocsEditable
  void disableVertexAttribArray(int index) native;

  @DomName('WebGLRenderingContext.drawArrays')
  @DocsEditable
  void drawArrays(int mode, int first, int count) native;

  @DomName('WebGLRenderingContext.drawElements')
  @DocsEditable
  void drawElements(int mode, int count, int type, int offset) native;

  @DomName('WebGLRenderingContext.enable')
  @DocsEditable
  void enable(int cap) native;

  @DomName('WebGLRenderingContext.enableVertexAttribArray')
  @DocsEditable
  void enableVertexAttribArray(int index) native;

  @DomName('WebGLRenderingContext.finish')
  @DocsEditable
  void finish() native;

  @DomName('WebGLRenderingContext.flush')
  @DocsEditable
  void flush() native;

  @DomName('WebGLRenderingContext.framebufferRenderbuffer')
  @DocsEditable
  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, WebGLRenderbuffer renderbuffer) native;

  @DomName('WebGLRenderingContext.framebufferTexture2D')
  @DocsEditable
  void framebufferTexture2D(int target, int attachment, int textarget, WebGLTexture texture, int level) native;

  @DomName('WebGLRenderingContext.frontFace')
  @DocsEditable
  void frontFace(int mode) native;

  @DomName('WebGLRenderingContext.generateMipmap')
  @DocsEditable
  void generateMipmap(int target) native;

  @DomName('WebGLRenderingContext.getActiveAttrib')
  @DocsEditable
  WebGLActiveInfo getActiveAttrib(WebGLProgram program, int index) native;

  @DomName('WebGLRenderingContext.getActiveUniform')
  @DocsEditable
  WebGLActiveInfo getActiveUniform(WebGLProgram program, int index) native;

  @DomName('WebGLRenderingContext.getAttachedShaders')
  @DocsEditable
  void getAttachedShaders(WebGLProgram program) native;

  @DomName('WebGLRenderingContext.getAttribLocation')
  @DocsEditable
  int getAttribLocation(WebGLProgram program, String name) native;

  @DomName('WebGLRenderingContext.getBufferParameter')
  @DocsEditable
  Object getBufferParameter(int target, int pname) native;

  @DomName('WebGLRenderingContext.getContextAttributes')
  @DocsEditable
  WebGLContextAttributes getContextAttributes() native;

  @DomName('WebGLRenderingContext.getError')
  @DocsEditable
  int getError() native;

  @DomName('WebGLRenderingContext.getExtension')
  @DocsEditable
  Object getExtension(String name) native;

  @DomName('WebGLRenderingContext.getFramebufferAttachmentParameter')
  @DocsEditable
  Object getFramebufferAttachmentParameter(int target, int attachment, int pname) native;

  @DomName('WebGLRenderingContext.getParameter')
  @DocsEditable
  Object getParameter(int pname) native;

  @DomName('WebGLRenderingContext.getProgramInfoLog')
  @DocsEditable
  String getProgramInfoLog(WebGLProgram program) native;

  @DomName('WebGLRenderingContext.getProgramParameter')
  @DocsEditable
  Object getProgramParameter(WebGLProgram program, int pname) native;

  @DomName('WebGLRenderingContext.getRenderbufferParameter')
  @DocsEditable
  Object getRenderbufferParameter(int target, int pname) native;

  @DomName('WebGLRenderingContext.getShaderInfoLog')
  @DocsEditable
  String getShaderInfoLog(WebGLShader shader) native;

  @DomName('WebGLRenderingContext.getShaderParameter')
  @DocsEditable
  Object getShaderParameter(WebGLShader shader, int pname) native;

  @DomName('WebGLRenderingContext.getShaderPrecisionFormat')
  @DocsEditable
  WebGLShaderPrecisionFormat getShaderPrecisionFormat(int shadertype, int precisiontype) native;

  @DomName('WebGLRenderingContext.getShaderSource')
  @DocsEditable
  String getShaderSource(WebGLShader shader) native;

  @DomName('WebGLRenderingContext.getSupportedExtensions')
  @DocsEditable
  List<String> getSupportedExtensions() native;

  @DomName('WebGLRenderingContext.getTexParameter')
  @DocsEditable
  Object getTexParameter(int target, int pname) native;

  @DomName('WebGLRenderingContext.getUniform')
  @DocsEditable
  Object getUniform(WebGLProgram program, WebGLUniformLocation location) native;

  @DomName('WebGLRenderingContext.getUniformLocation')
  @DocsEditable
  WebGLUniformLocation getUniformLocation(WebGLProgram program, String name) native;

  @DomName('WebGLRenderingContext.getVertexAttrib')
  @DocsEditable
  Object getVertexAttrib(int index, int pname) native;

  @DomName('WebGLRenderingContext.getVertexAttribOffset')
  @DocsEditable
  int getVertexAttribOffset(int index, int pname) native;

  @DomName('WebGLRenderingContext.hint')
  @DocsEditable
  void hint(int target, int mode) native;

  @DomName('WebGLRenderingContext.isBuffer')
  @DocsEditable
  bool isBuffer(WebGLBuffer buffer) native;

  @DomName('WebGLRenderingContext.isContextLost')
  @DocsEditable
  bool isContextLost() native;

  @DomName('WebGLRenderingContext.isEnabled')
  @DocsEditable
  bool isEnabled(int cap) native;

  @DomName('WebGLRenderingContext.isFramebuffer')
  @DocsEditable
  bool isFramebuffer(WebGLFramebuffer framebuffer) native;

  @DomName('WebGLRenderingContext.isProgram')
  @DocsEditable
  bool isProgram(WebGLProgram program) native;

  @DomName('WebGLRenderingContext.isRenderbuffer')
  @DocsEditable
  bool isRenderbuffer(WebGLRenderbuffer renderbuffer) native;

  @DomName('WebGLRenderingContext.isShader')
  @DocsEditable
  bool isShader(WebGLShader shader) native;

  @DomName('WebGLRenderingContext.isTexture')
  @DocsEditable
  bool isTexture(WebGLTexture texture) native;

  @DomName('WebGLRenderingContext.lineWidth')
  @DocsEditable
  void lineWidth(num width) native;

  @DomName('WebGLRenderingContext.linkProgram')
  @DocsEditable
  void linkProgram(WebGLProgram program) native;

  @DomName('WebGLRenderingContext.pixelStorei')
  @DocsEditable
  void pixelStorei(int pname, int param) native;

  @DomName('WebGLRenderingContext.polygonOffset')
  @DocsEditable
  void polygonOffset(num factor, num units) native;

  @DomName('WebGLRenderingContext.readPixels')
  @DocsEditable
  void readPixels(int x, int y, int width, int height, int format, int type, ArrayBufferView pixels) native;

  @DomName('WebGLRenderingContext.releaseShaderCompiler')
  @DocsEditable
  void releaseShaderCompiler() native;

  @DomName('WebGLRenderingContext.renderbufferStorage')
  @DocsEditable
  void renderbufferStorage(int target, int internalformat, int width, int height) native;

  @DomName('WebGLRenderingContext.sampleCoverage')
  @DocsEditable
  void sampleCoverage(num value, bool invert) native;

  @DomName('WebGLRenderingContext.scissor')
  @DocsEditable
  void scissor(int x, int y, int width, int height) native;

  @DomName('WebGLRenderingContext.shaderSource')
  @DocsEditable
  void shaderSource(WebGLShader shader, String string) native;

  @DomName('WebGLRenderingContext.stencilFunc')
  @DocsEditable
  void stencilFunc(int func, int ref, int mask) native;

  @DomName('WebGLRenderingContext.stencilFuncSeparate')
  @DocsEditable
  void stencilFuncSeparate(int face, int func, int ref, int mask) native;

  @DomName('WebGLRenderingContext.stencilMask')
  @DocsEditable
  void stencilMask(int mask) native;

  @DomName('WebGLRenderingContext.stencilMaskSeparate')
  @DocsEditable
  void stencilMaskSeparate(int face, int mask) native;

  @DomName('WebGLRenderingContext.stencilOp')
  @DocsEditable
  void stencilOp(int fail, int zfail, int zpass) native;

  @DomName('WebGLRenderingContext.stencilOpSeparate')
  @DocsEditable
  void stencilOpSeparate(int face, int fail, int zfail, int zpass) native;

  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, [int format, int type, ArrayBufferView pixels]) {
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is int || border_OR_canvas_OR_image_OR_pixels_OR_video == null)) {
      _texImage2D_1(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is ImageData || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && !?format && !?type && !?pixels) {
      var pixels_1 = _convertDartToNative_ImageData(border_OR_canvas_OR_image_OR_pixels_OR_video);
      _texImage2D_2(target, level, internalformat, format_OR_width, height_OR_type, pixels_1);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is ImageElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && !?format && !?type && !?pixels) {
      _texImage2D_3(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is CanvasElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && !?format && !?type && !?pixels) {
      _texImage2D_4(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is VideoElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && !?format && !?type && !?pixels) {
      _texImage2D_5(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('texImage2D')
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable
  void _texImage2D_1(target, level, internalformat, width, height, int border, format, type, ArrayBufferView pixels) native;
  @JSName('texImage2D')
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable
  void _texImage2D_2(target, level, internalformat, format, type, pixels) native;
  @JSName('texImage2D')
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable
  void _texImage2D_3(target, level, internalformat, format, type, ImageElement image) native;
  @JSName('texImage2D')
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable
  void _texImage2D_4(target, level, internalformat, format, type, CanvasElement canvas) native;
  @JSName('texImage2D')
  @DomName('WebGLRenderingContext.texImage2D')
  @DocsEditable
  void _texImage2D_5(target, level, internalformat, format, type, VideoElement video) native;

  @DomName('WebGLRenderingContext.texParameterf')
  @DocsEditable
  void texParameterf(int target, int pname, num param) native;

  @DomName('WebGLRenderingContext.texParameteri')
  @DocsEditable
  void texParameteri(int target, int pname, int param) native;

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, [int type, ArrayBufferView pixels]) {
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is int || canvas_OR_format_OR_image_OR_pixels_OR_video == null)) {
      _texSubImage2D_1(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is ImageData || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && !?type && !?pixels) {
      var pixels_1 = _convertDartToNative_ImageData(canvas_OR_format_OR_image_OR_pixels_OR_video);
      _texSubImage2D_2(target, level, xoffset, yoffset, format_OR_width, height_OR_type, pixels_1);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is ImageElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && !?type && !?pixels) {
      _texSubImage2D_3(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is CanvasElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && !?type && !?pixels) {
      _texSubImage2D_4(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is VideoElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && !?type && !?pixels) {
      _texSubImage2D_5(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('texSubImage2D')
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable
  void _texSubImage2D_1(target, level, xoffset, yoffset, width, height, int format, type, ArrayBufferView pixels) native;
  @JSName('texSubImage2D')
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable
  void _texSubImage2D_2(target, level, xoffset, yoffset, format, type, pixels) native;
  @JSName('texSubImage2D')
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable
  void _texSubImage2D_3(target, level, xoffset, yoffset, format, type, ImageElement image) native;
  @JSName('texSubImage2D')
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable
  void _texSubImage2D_4(target, level, xoffset, yoffset, format, type, CanvasElement canvas) native;
  @JSName('texSubImage2D')
  @DomName('WebGLRenderingContext.texSubImage2D')
  @DocsEditable
  void _texSubImage2D_5(target, level, xoffset, yoffset, format, type, VideoElement video) native;

  @DomName('WebGLRenderingContext.uniform1f')
  @DocsEditable
  void uniform1f(WebGLUniformLocation location, num x) native;

  @DomName('WebGLRenderingContext.uniform1fv')
  @DocsEditable
  void uniform1fv(WebGLUniformLocation location, Float32Array v) native;

  @DomName('WebGLRenderingContext.uniform1i')
  @DocsEditable
  void uniform1i(WebGLUniformLocation location, int x) native;

  @DomName('WebGLRenderingContext.uniform1iv')
  @DocsEditable
  void uniform1iv(WebGLUniformLocation location, Int32Array v) native;

  @DomName('WebGLRenderingContext.uniform2f')
  @DocsEditable
  void uniform2f(WebGLUniformLocation location, num x, num y) native;

  @DomName('WebGLRenderingContext.uniform2fv')
  @DocsEditable
  void uniform2fv(WebGLUniformLocation location, Float32Array v) native;

  @DomName('WebGLRenderingContext.uniform2i')
  @DocsEditable
  void uniform2i(WebGLUniformLocation location, int x, int y) native;

  @DomName('WebGLRenderingContext.uniform2iv')
  @DocsEditable
  void uniform2iv(WebGLUniformLocation location, Int32Array v) native;

  @DomName('WebGLRenderingContext.uniform3f')
  @DocsEditable
  void uniform3f(WebGLUniformLocation location, num x, num y, num z) native;

  @DomName('WebGLRenderingContext.uniform3fv')
  @DocsEditable
  void uniform3fv(WebGLUniformLocation location, Float32Array v) native;

  @DomName('WebGLRenderingContext.uniform3i')
  @DocsEditable
  void uniform3i(WebGLUniformLocation location, int x, int y, int z) native;

  @DomName('WebGLRenderingContext.uniform3iv')
  @DocsEditable
  void uniform3iv(WebGLUniformLocation location, Int32Array v) native;

  @DomName('WebGLRenderingContext.uniform4f')
  @DocsEditable
  void uniform4f(WebGLUniformLocation location, num x, num y, num z, num w) native;

  @DomName('WebGLRenderingContext.uniform4fv')
  @DocsEditable
  void uniform4fv(WebGLUniformLocation location, Float32Array v) native;

  @DomName('WebGLRenderingContext.uniform4i')
  @DocsEditable
  void uniform4i(WebGLUniformLocation location, int x, int y, int z, int w) native;

  @DomName('WebGLRenderingContext.uniform4iv')
  @DocsEditable
  void uniform4iv(WebGLUniformLocation location, Int32Array v) native;

  @DomName('WebGLRenderingContext.uniformMatrix2fv')
  @DocsEditable
  void uniformMatrix2fv(WebGLUniformLocation location, bool transpose, Float32Array array) native;

  @DomName('WebGLRenderingContext.uniformMatrix3fv')
  @DocsEditable
  void uniformMatrix3fv(WebGLUniformLocation location, bool transpose, Float32Array array) native;

  @DomName('WebGLRenderingContext.uniformMatrix4fv')
  @DocsEditable
  void uniformMatrix4fv(WebGLUniformLocation location, bool transpose, Float32Array array) native;

  @DomName('WebGLRenderingContext.useProgram')
  @DocsEditable
  void useProgram(WebGLProgram program) native;

  @DomName('WebGLRenderingContext.validateProgram')
  @DocsEditable
  void validateProgram(WebGLProgram program) native;

  @DomName('WebGLRenderingContext.vertexAttrib1f')
  @DocsEditable
  void vertexAttrib1f(int indx, num x) native;

  @DomName('WebGLRenderingContext.vertexAttrib1fv')
  @DocsEditable
  void vertexAttrib1fv(int indx, Float32Array values) native;

  @DomName('WebGLRenderingContext.vertexAttrib2f')
  @DocsEditable
  void vertexAttrib2f(int indx, num x, num y) native;

  @DomName('WebGLRenderingContext.vertexAttrib2fv')
  @DocsEditable
  void vertexAttrib2fv(int indx, Float32Array values) native;

  @DomName('WebGLRenderingContext.vertexAttrib3f')
  @DocsEditable
  void vertexAttrib3f(int indx, num x, num y, num z) native;

  @DomName('WebGLRenderingContext.vertexAttrib3fv')
  @DocsEditable
  void vertexAttrib3fv(int indx, Float32Array values) native;

  @DomName('WebGLRenderingContext.vertexAttrib4f')
  @DocsEditable
  void vertexAttrib4f(int indx, num x, num y, num z, num w) native;

  @DomName('WebGLRenderingContext.vertexAttrib4fv')
  @DocsEditable
  void vertexAttrib4fv(int indx, Float32Array values) native;

  @DomName('WebGLRenderingContext.vertexAttribPointer')
  @DocsEditable
  void vertexAttribPointer(int indx, int size, int type, bool normalized, int stride, int offset) native;

  @DomName('WebGLRenderingContext.viewport')
  @DocsEditable
  void viewport(int x, int y, int width, int height) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebGLShader')
class WebGLShader native "*WebGLShader" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebGLShaderPrecisionFormat')
class WebGLShaderPrecisionFormat native "*WebGLShaderPrecisionFormat" {

  @DomName('WebGLShaderPrecisionFormat.precision')
  @DocsEditable
  final int precision;

  @DomName('WebGLShaderPrecisionFormat.rangeMax')
  @DocsEditable
  final int rangeMax;

  @DomName('WebGLShaderPrecisionFormat.rangeMin')
  @DocsEditable
  final int rangeMin;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebGLTexture')
class WebGLTexture native "*WebGLTexture" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebGLUniformLocation')
class WebGLUniformLocation native "*WebGLUniformLocation" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebGLVertexArrayObjectOES')
class WebGLVertexArrayObject native "*WebGLVertexArrayObjectOES" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebKitCSSFilterValue')
class WebKitCssFilterValue extends _CssValueList native "*WebKitCSSFilterValue" {

  static const int CSS_FILTER_BLUR = 10;

  static const int CSS_FILTER_BRIGHTNESS = 8;

  static const int CSS_FILTER_CONTRAST = 9;

  static const int CSS_FILTER_CUSTOM = 12;

  static const int CSS_FILTER_DROP_SHADOW = 11;

  static const int CSS_FILTER_GRAYSCALE = 2;

  static const int CSS_FILTER_HUE_ROTATE = 5;

  static const int CSS_FILTER_INVERT = 6;

  static const int CSS_FILTER_OPACITY = 7;

  static const int CSS_FILTER_REFERENCE = 1;

  static const int CSS_FILTER_SATURATE = 4;

  static const int CSS_FILTER_SEPIA = 3;

  @DomName('WebKitCSSFilterValue.operationType')
  @DocsEditable
  final int operationType;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebKitCSSMixFunctionValue')
class WebKitCssMixFunctionValue extends _CssValueList native "*WebKitCSSMixFunctionValue" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebKitNamedFlow')
class WebKitNamedFlow extends EventTarget native "*WebKitNamedFlow" {

  @DomName('WebKitNamedFlow.firstEmptyRegionIndex')
  @DocsEditable
  final int firstEmptyRegionIndex;

  @DomName('WebKitNamedFlow.name')
  @DocsEditable
  final String name;

  @DomName('WebKitNamedFlow.overset')
  @DocsEditable
  final bool overset;

  @JSName('addEventListener')
  @DomName('WebKitNamedFlow.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('WebKitNamedFlow.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event event) native;

  @DomName('WebKitNamedFlow.getContent')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> getContent() native;

  @DomName('WebKitNamedFlow.getRegions')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> getRegions() native;

  @DomName('WebKitNamedFlow.getRegionsByContent')
  @DocsEditable
  @Returns('NodeList')
  @Creates('NodeList')
  List<Node> getRegionsByContent(Node contentNode) native;

  @JSName('removeEventListener')
  @DomName('WebKitNamedFlow.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WebSocket')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
class WebSocket extends EventTarget native "*WebSocket" {

  @DomName('WebSocket.close')
  @DocsEditable
  static const EventStreamProvider<CloseEvent> closeEvent = const EventStreamProvider<CloseEvent>('close');

  @DomName('WebSocket.error')
  @DocsEditable
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DomName('WebSocket.message')
  @DocsEditable
  static const EventStreamProvider<MessageEvent> messageEvent = const EventStreamProvider<MessageEvent>('message');

  @DomName('WebSocket.open')
  @DocsEditable
  static const EventStreamProvider<Event> openEvent = const EventStreamProvider<Event>('open');

  @DocsEditable
  factory WebSocket(String url) => WebSocket._create(url);
  static WebSocket _create(String url) => JS('WebSocket', 'new WebSocket(#)', url);

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', 'typeof window.WebSocket != "undefined"');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  WebSocketEvents get on =>
    new WebSocketEvents(this);

  static const int CLOSED = 3;

  static const int CLOSING = 2;

  static const int CONNECTING = 0;

  static const int OPEN = 1;

  @JSName('URL')
  @DomName('WebSocket.URL')
  @DocsEditable
  final String Url;

  @DomName('WebSocket.binaryType')
  @DocsEditable
  String binaryType;

  @DomName('WebSocket.bufferedAmount')
  @DocsEditable
  final int bufferedAmount;

  @DomName('WebSocket.extensions')
  @DocsEditable
  final String extensions;

  @DomName('WebSocket.protocol')
  @DocsEditable
  final String protocol;

  @DomName('WebSocket.readyState')
  @DocsEditable
  final int readyState;

  @DomName('WebSocket.url')
  @DocsEditable
  final String url;

  @JSName('addEventListener')
  @DomName('WebSocket.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('WebSocket.close')
  @DocsEditable
  void close([int code, String reason]) native;

  @DomName('WebSocket.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native;

  @JSName('removeEventListener')
  @DomName('WebSocket.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('WebSocket.send')
  @DocsEditable
  void send(data) native;

  @DomName('WebSocket.close')
  @DocsEditable
  Stream<CloseEvent> get onClose => closeEvent.forTarget(this);

  @DomName('WebSocket.error')
  @DocsEditable
  Stream<Event> get onError => errorEvent.forTarget(this);

  @DomName('WebSocket.message')
  @DocsEditable
  Stream<MessageEvent> get onMessage => messageEvent.forTarget(this);

  @DomName('WebSocket.open')
  @DocsEditable
  Stream<Event> get onOpen => openEvent.forTarget(this);
}

@DocsEditable
@deprecated
class WebSocketEvents extends Events {
  @DocsEditable
  WebSocketEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get close => this['close'];

  @DocsEditable
  EventListenerList get error => this['error'];

  @DocsEditable
  EventListenerList get message => this['message'];

  @DocsEditable
  EventListenerList get open => this['open'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('WheelEvent')
class WheelEvent extends MouseEvent native "*WheelEvent" {

  factory WheelEvent(String type,
      {Window view, int deltaX: 0, int deltaY: 0,
      int detail: 0, int screenX: 0, int screenY: 0, int clientX: 0,
      int clientY: 0, int button: 0, bool canBubble: true,
      bool cancelable: true, bool ctrlKey: false, bool altKey: false,
      bool shiftKey: false, bool metaKey: false, EventTarget relatedTarget}) {

    if (view == null) {
      view = window;
    }
    var eventType = 'WheelEvent';
    if (_Device.isFirefox) {
      eventType = 'MouseScrollEvents';
    }
    final event = document.$dom_createEvent(eventType);
    if (event._hasInitWheelEvent) {
      var modifiers = [];
      if (ctrlKey) {
        modifiers.push('Control');
      }
      if (altKey) {
        modifiers.push('Alt');
      }
      if (shiftKey) {
        modifiers.push('Shift');
      }
      if (metaKey) {
        modifiers.push('Meta');
      }
      event._initWheelEvent(type, canBubble, cancelable, view, detail, screenX,
          screenY, clientX, clientY, button, relatedTarget, modifiers.join(' '),
          deltaX, deltaY, 0, 0);
    } else if (event._hasInitMouseScrollEvent) {
      var axis = 0;
      var detail = 0;
      if (deltaX != 0 && deltaY != 0) {
        throw UnsupportedError(
            'Cannot modify deltaX and deltaY simultaneously');
      }
      if (deltaY != 0) {
        detail = deltaY;
        axis = JS('int', 'MouseScrollEvent.VERTICAL_AXIS');
      } else if (deltaX != 0) {
        detail = deltaX;
        axis = JS('int', 'MouseScrollEvent.HORIZONTAL_AXIS');
      }
      event._initMouseScrollEvent(type, canBubble, cancelable, view, detail,
          screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey,
          metaKey, button, relatedTarget, axis);
    } else {
      // Fallthrough for Dartium.
      event.$dom_initMouseEvent(type, canBubble, cancelable, view, detail,
          screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey,
          metaKey, button, relatedTarget);
      event.$dom_initWebKitWheelEvent(deltaX,
          deltaY ~/ 120, // Chrome does an auto-convert to pixels.
          view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey,
          metaKey);
    }

    return event;
  }


  @DomName('WheelEvent.webkitDirectionInvertedFromDevice')
  @DocsEditable
  final bool webkitDirectionInvertedFromDevice;

  @JSName('initWebKitWheelEvent')
  @DomName('WheelEvent.initWebKitWheelEvent')
  @DocsEditable
  void $dom_initWebKitWheelEvent(int wheelDeltaX, int wheelDeltaY, Window view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;


  @DomName('WheelEvent.deltaY')
  num get deltaY {
    if (JS('bool', '#.deltaY !== undefined', this)) {
      // W3C WheelEvent
      return this._deltaY;
    } else if (JS('bool', '#.wheelDelta !== undefined', this)) {
      // Chrome and IE
      return this._wheelDelta;
    } else if (JS('bool', '#.detail !== undefined', this)) {
      // Firefox

      // Handle DOMMouseScroll case where it uses detail and the axis to
      // differentiate.
      if (JS('bool', '#.axis == MouseScrollEvent.VERTICAL_AXIS', this)) {
        var detail = this._detail;
        // Firefox is normally the number of lines to scale (normally 3)
        // so multiply it by 40 to get pixels to move, matching IE & WebKit.
        if (detail < 100) {
          return detail * 40;
        }
        return detail;
      }
      return 0;
    }
    throw new UnsupportedError(
        'deltaY is not supported');
  }

  @DomName('WheelEvent.deltaX')
  num get deltaX {
    if (JS('bool', '#.deltaX !== undefined', this)) {
      // W3C WheelEvent
      return this._deltaX;
    } else if (JS('bool', '#.wheelDeltaX !== undefined', this)) {
      // Chrome
      return this._wheelDeltaX;
    } else if (JS('bool', '#.detail !== undefined', this)) {
      // Firefox and IE.
      // IE will have detail set but will not set axis.

      // Handle DOMMouseScroll case where it uses detail and the axis to
      // differentiate.
      if (JS('bool', '#.axis !== undefined && '
        '#.axis == MouseScrollEvent.HORIZONTAL_AXIS', this, this)) {
        var detail = this._detail;
        // Firefox is normally the number of lines to scale (normally 3)
        // so multiply it by 40 to get pixels to move, matching IE & WebKit.
        if (detail < 100) {
          return detail * 40;
        }
        return detail;
      }
      return 0;
    }
    throw new UnsupportedError(
        'deltaX is not supported');
  }

  int get deltaMode {
    if (JS('bool', '!!#.deltaMode', this)) {
      // If not available then we're poly-filling and doing pixel scroll.
      return 0;
    }
    return this._deltaMode;
  }

  num get _deltaY => JS('num', '#.deltaY', this);
  num get _deltaX => JS('num', '#.deltaX', this);
  num get _wheelDelta => JS('num', '#.wheelDelta', this);
  num get _wheelDeltaX => JS('num', '#.wheelDeltaX', this);
  num get _detail => JS('num', '#.detail', this);
  int get _deltaMode => JS('int', '#.deltaMode', this);

  bool get _hasInitMouseScrollEvent =>
      JS('bool', '!!(#.initMouseScrollEvent)', this);

  @JSName('initMouseScrollEvent')
  void _initMouseScrollEvent(
      String type,
      bool canBubble,
      bool cancelable,
      Window view,
      int detail,
      int screenX,
      int screenY,
      int clientX,
      int clientY,
      bool ctrlKey,
      bool altKey,
      bool shiftKey,
      bool metaKey,
      int button,
      EventTarget relatedTarget,
      int axis) native;

  bool get _hasInitWheelEvent =>
      JS('bool', '!!(#.initWheelEvent)', this);
  @JSName('initWheelEvent')
  void _initWheelEvent(
      String eventType,
      bool canBubble,
      bool cancelable,
      Window view,
      int detail,
      int screenX,
      int screenY,
      int clientX,
      int clientY,
      int button,
      EventTarget relatedTarget,
      String modifiersList,
      int deltaX,
      int deltaY,
      int deltaZ,
      int deltaMode) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('Window')
class Window extends EventTarget implements WindowBase native "@*DOMWindow" {

  Document get document => JS('Document', '#.document', this);

  WindowBase _open2(url, name) => JS('Window', '#.open(#,#)', this, url, name);

  WindowBase _open3(url, name, options) =>
      JS('Window', '#.open(#,#,#)', this, url, name, options);

  WindowBase open(String url, String name, [String options]) {
    if (options == null) {
      return _DOMWindowCrossFrame._createSafe(_open2(url, name));
    } else {
      return _DOMWindowCrossFrame._createSafe(_open3(url, name, options));
    }
  }

  // API level getter and setter for Location.
  // TODO: The cross domain safe wrapper can be inserted here or folded into
  // _LocationWrapper.
  Location get location {
    // Firefox work-around for Location.  The Firefox location object cannot be
    // made to behave like a Dart object so must be wrapped.
    var result = _location;
    if (_isDartLocation(result)) return result;  // e.g. on Chrome.
    if (null == _location_wrapper) {
      _location_wrapper = new _LocationWrapper(result);
    }
    return _location_wrapper;
  }

  // TODO: consider forcing users to do: window.location.assign('string').
  /**
   * Sets the window's location, which causes the browser to navigate to the new
   * location. [value] may be a Location object or a string.
   */
  void set location(value) {
    if (value is _LocationWrapper) {
      _location = value._ptr;
    } else {
      _location = value;
    }
  }

  _LocationWrapper _location_wrapper;  // Cached wrapped Location object.

  // Native getter and setter to access raw Location object.
  dynamic get _location => JS('Location|=Object', '#.location', this);
  void set _location(value) {
    JS('void', '#.location = #', this, value);
  }
  // Prevent compiled from thinking 'location' property is available for a Dart
  // member.
  @JSName('location')
  _protect_location() native;

  static _isDartLocation(thing) {
    // On Firefox the code that implements 'is Location' fails to find the patch
    // stub on Object.prototype and throws an exception.
    try {
      return thing is Location;
    } catch (e) {
      return false;
    }
  }

  /**
   * Executes a [callback] after the immediate execution stack has completed.
   *
   * This will cause the callback to be executed after all processing has
   * completed for the current event, but before any subsequent events.
   */
  void setImmediate(TimeoutHandler callback) {
    _addMicrotaskCallback(callback);
  }

  @DomName('DOMWindow.requestAnimationFrame')
  int requestAnimationFrame(RequestAnimationFrameCallback callback) {
    _ensureRequestAnimationFrame();
    return _requestAnimationFrame(callback);
  }

  void cancelAnimationFrame(id) {
    _ensureRequestAnimationFrame();
    _cancelAnimationFrame(id);
  }

  @JSName('requestAnimationFrame')
  int _requestAnimationFrame(RequestAnimationFrameCallback callback) native;

  @JSName('cancelAnimationFrame')
  void _cancelAnimationFrame(int id) native;

  _ensureRequestAnimationFrame() {
    if (JS('bool',
           '!!(#.requestAnimationFrame && #.cancelAnimationFrame)', this, this))
      return;

    JS('void',
       r"""
  (function($this) {
   var vendors = ['ms', 'moz', 'webkit', 'o'];
   for (var i = 0; i < vendors.length && !$this.requestAnimationFrame; ++i) {
     $this.requestAnimationFrame = $this[vendors[i] + 'RequestAnimationFrame'];
     $this.cancelAnimationFrame =
         $this[vendors[i]+'CancelAnimationFrame'] ||
         $this[vendors[i]+'CancelRequestAnimationFrame'];
   }
   if ($this.requestAnimationFrame && $this.cancelAnimationFrame) return;
   $this.requestAnimationFrame = function(callback) {
      return window.setTimeout(function() {
        callback(Date.now());
      }, 16 /* 16ms ~= 60fps */);
   };
   $this.cancelAnimationFrame = function(id) { clearTimeout(id); }
  })(#)""",
       this);
  }

  /**
   * Gets an instance of the Indexed DB factory to being using Indexed DB.
   *
   * Use [IdbFactory.supported] to check if Indexed DB is supported on the
   * current platform.
   */
  @SupportedBrowser(SupportedBrowser.CHROME, '23.0')
  @SupportedBrowser(SupportedBrowser.FIREFOX, '15.0')
  @SupportedBrowser(SupportedBrowser.IE, '10.0')
  @Experimental
  IdbFactory get indexedDB =>
      JS('IdbFactory',
         '#.indexedDB || #.webkitIndexedDB || #.mozIndexedDB',
         this, this, this);

  /**
   * Lookup a port by its [name].  Return null if no port is
   * registered under [name].
   */
  SendPortSync lookupPort(String name) {
    var port = json.parse(document.documentElement.attributes['dart-port:$name']);
    return _deserialize(port);
  }

  /**
   * Register a [port] on this window under the given [name].  This
   * port may be retrieved by any isolate (or JavaScript script)
   * running in this window.
   */
  void registerPort(String name, var port) {
    var serialized = _serialize(port);
    document.documentElement.attributes['dart-port:$name'] = json.stringify(serialized);
  }

  @DomName('Window.console')
  Console get console => Console.safeConsole;

  /// Checks if _setImmediate is supported.
  static bool get _supportsSetImmediate =>
      JS('bool', '!!(window.setImmediate)');

  // Set immediate implementation for IE
  void _setImmediate(void callback()) {
    JS('void', '#.setImmediate(#)', this, convertDartClosureToJS(callback, 0));
  }


  @DomName('DOMWindow.DOMContentLoaded')
  @DocsEditable
  static const EventStreamProvider<Event> contentLoadedEvent = const EventStreamProvider<Event>('DOMContentLoaded');

  @DomName('DOMWindow.beforeunload')
  @DocsEditable
  static const EventStreamProvider<Event> beforeUnloadEvent = const EventStreamProvider<Event>('beforeunload');

  @DomName('DOMWindow.devicemotion')
  @DocsEditable
  static const EventStreamProvider<DeviceMotionEvent> deviceMotionEvent = const EventStreamProvider<DeviceMotionEvent>('devicemotion');

  @DomName('DOMWindow.deviceorientation')
  @DocsEditable
  static const EventStreamProvider<DeviceOrientationEvent> deviceOrientationEvent = const EventStreamProvider<DeviceOrientationEvent>('deviceorientation');

  @DomName('DOMWindow.hashchange')
  @DocsEditable
  static const EventStreamProvider<Event> hashChangeEvent = const EventStreamProvider<Event>('hashchange');

  @DomName('DOMWindow.message')
  @DocsEditable
  static const EventStreamProvider<MessageEvent> messageEvent = const EventStreamProvider<MessageEvent>('message');

  @DomName('DOMWindow.offline')
  @DocsEditable
  static const EventStreamProvider<Event> offlineEvent = const EventStreamProvider<Event>('offline');

  @DomName('DOMWindow.online')
  @DocsEditable
  static const EventStreamProvider<Event> onlineEvent = const EventStreamProvider<Event>('online');

  @DomName('DOMWindow.pagehide')
  @DocsEditable
  static const EventStreamProvider<Event> pageHideEvent = const EventStreamProvider<Event>('pagehide');

  @DomName('DOMWindow.pageshow')
  @DocsEditable
  static const EventStreamProvider<Event> pageShowEvent = const EventStreamProvider<Event>('pageshow');

  @DomName('DOMWindow.popstate')
  @DocsEditable
  static const EventStreamProvider<PopStateEvent> popStateEvent = const EventStreamProvider<PopStateEvent>('popstate');

  @DomName('DOMWindow.resize')
  @DocsEditable
  static const EventStreamProvider<Event> resizeEvent = const EventStreamProvider<Event>('resize');

  @DomName('DOMWindow.storage')
  @DocsEditable
  static const EventStreamProvider<StorageEvent> storageEvent = const EventStreamProvider<StorageEvent>('storage');

  @DomName('DOMWindow.unload')
  @DocsEditable
  static const EventStreamProvider<Event> unloadEvent = const EventStreamProvider<Event>('unload');

  @DomName('DOMWindow.webkitAnimationEnd')
  @DocsEditable
  static const EventStreamProvider<AnimationEvent> animationEndEvent = const EventStreamProvider<AnimationEvent>('webkitAnimationEnd');

  @DomName('DOMWindow.webkitAnimationIteration')
  @DocsEditable
  static const EventStreamProvider<AnimationEvent> animationIterationEvent = const EventStreamProvider<AnimationEvent>('webkitAnimationIteration');

  @DomName('DOMWindow.webkitAnimationStart')
  @DocsEditable
  static const EventStreamProvider<AnimationEvent> animationStartEvent = const EventStreamProvider<AnimationEvent>('webkitAnimationStart');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  WindowEvents get on =>
    new WindowEvents(this);

  static const int PERSISTENT = 1;

  static const int TEMPORARY = 0;

  @DomName('DOMWindow.applicationCache')
  @DocsEditable
  final ApplicationCache applicationCache;

  @DomName('DOMWindow.closed')
  @DocsEditable
  final bool closed;

  @DomName('DOMWindow.crypto')
  @DocsEditable
  final Crypto crypto;

  @DomName('DOMWindow.defaultStatus')
  @DocsEditable
  String defaultStatus;

  @DomName('DOMWindow.defaultstatus')
  @DocsEditable
  String defaultstatus;

  @DomName('DOMWindow.devicePixelRatio')
  @DocsEditable
  final num devicePixelRatio;

  @DomName('DOMWindow.event')
  @DocsEditable
  final Event event;

  @DomName('DOMWindow.history')
  @DocsEditable
  final History history;

  @DomName('DOMWindow.innerHeight')
  @DocsEditable
  final int innerHeight;

  @DomName('DOMWindow.innerWidth')
  @DocsEditable
  final int innerWidth;

  @DomName('DOMWindow.localStorage')
  @DocsEditable
  final Storage localStorage;

  @DomName('DOMWindow.locationbar')
  @DocsEditable
  final BarInfo locationbar;

  @DomName('DOMWindow.menubar')
  @DocsEditable
  final BarInfo menubar;

  @DomName('DOMWindow.name')
  @DocsEditable
  String name;

  @DomName('DOMWindow.navigator')
  @DocsEditable
  final Navigator navigator;

  @DomName('DOMWindow.offscreenBuffering')
  @DocsEditable
  final bool offscreenBuffering;

  WindowBase get opener => _convertNativeToDart_Window(this._opener);
  @JSName('opener')
  @DomName('DOMWindow.opener')
  @DocsEditable
  @Creates('Window|=Object')
  @Returns('Window|=Object')
  final dynamic _opener;

  @DomName('DOMWindow.outerHeight')
  @DocsEditable
  final int outerHeight;

  @DomName('DOMWindow.outerWidth')
  @DocsEditable
  final int outerWidth;

  @DomName('DOMWindow.pagePopupController')
  @DocsEditable
  final PagePopupController pagePopupController;

  @DomName('DOMWindow.pageXOffset')
  @DocsEditable
  final int pageXOffset;

  @DomName('DOMWindow.pageYOffset')
  @DocsEditable
  final int pageYOffset;

  WindowBase get parent => _convertNativeToDart_Window(this._parent);
  @JSName('parent')
  @DomName('DOMWindow.parent')
  @DocsEditable
  @Creates('Window|=Object')
  @Returns('Window|=Object')
  final dynamic _parent;

  @DomName('DOMWindow.performance')
  @DocsEditable
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.FIREFOX)
  @SupportedBrowser(SupportedBrowser.IE)
  final Performance performance;

  @DomName('DOMWindow.personalbar')
  @DocsEditable
  final BarInfo personalbar;

  @DomName('DOMWindow.screen')
  @DocsEditable
  final Screen screen;

  @DomName('DOMWindow.screenLeft')
  @DocsEditable
  final int screenLeft;

  @DomName('DOMWindow.screenTop')
  @DocsEditable
  final int screenTop;

  @DomName('DOMWindow.screenX')
  @DocsEditable
  final int screenX;

  @DomName('DOMWindow.screenY')
  @DocsEditable
  final int screenY;

  @DomName('DOMWindow.scrollX')
  @DocsEditable
  final int scrollX;

  @DomName('DOMWindow.scrollY')
  @DocsEditable
  final int scrollY;

  @DomName('DOMWindow.scrollbars')
  @DocsEditable
  final BarInfo scrollbars;

  WindowBase get self => _convertNativeToDart_Window(this._self);
  @JSName('self')
  @DomName('DOMWindow.self')
  @DocsEditable
  @Creates('Window|=Object')
  @Returns('Window|=Object')
  final dynamic _self;

  @DomName('DOMWindow.sessionStorage')
  @DocsEditable
  final Storage sessionStorage;

  @DomName('DOMWindow.status')
  @DocsEditable
  String status;

  @DomName('DOMWindow.statusbar')
  @DocsEditable
  final BarInfo statusbar;

  @DomName('DOMWindow.styleMedia')
  @DocsEditable
  final StyleMedia styleMedia;

  @DomName('DOMWindow.toolbar')
  @DocsEditable
  final BarInfo toolbar;

  WindowBase get top => _convertNativeToDart_Window(this._top);
  @JSName('top')
  @DomName('DOMWindow.top')
  @DocsEditable
  @Creates('Window|=Object')
  @Returns('Window|=Object')
  final dynamic _top;

  @JSName('webkitNotifications')
  @DomName('DOMWindow.webkitNotifications')
  @DocsEditable
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental
  final NotificationCenter notifications;

  @DomName('DOMWindow.webkitStorageInfo')
  @DocsEditable
  final StorageInfo webkitStorageInfo;

  WindowBase get window => _convertNativeToDart_Window(this._window);
  @JSName('window')
  @DomName('DOMWindow.window')
  @DocsEditable
  @Creates('Window|=Object')
  @Returns('Window|=Object')
  final dynamic _window;

  @JSName('addEventListener')
  @DomName('DOMWindow.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('DOMWindow.alert')
  @DocsEditable
  void alert(String message) native;

  @DomName('DOMWindow.atob')
  @DocsEditable
  String atob(String string) native;

  @DomName('DOMWindow.btoa')
  @DocsEditable
  String btoa(String string) native;

  @DomName('DOMWindow.captureEvents')
  @DocsEditable
  void captureEvents() native;

  @DomName('DOMWindow.clearInterval')
  @DocsEditable
  void clearInterval(int handle) native;

  @DomName('DOMWindow.clearTimeout')
  @DocsEditable
  void clearTimeout(int handle) native;

  @DomName('DOMWindow.close')
  @DocsEditable
  void close() native;

  @DomName('DOMWindow.confirm')
  @DocsEditable
  bool confirm(String message) native;

  @DomName('DOMWindow.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native;

  @DomName('DOMWindow.find')
  @DocsEditable
  bool find(String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog) native;

  @JSName('getComputedStyle')
  @DomName('DOMWindow.getComputedStyle')
  @DocsEditable
  CssStyleDeclaration $dom_getComputedStyle(Element element, String pseudoElement) native;

  @JSName('getMatchedCSSRules')
  @DomName('DOMWindow.getMatchedCSSRules')
  @DocsEditable
  @Returns('_CssRuleList')
  @Creates('_CssRuleList')
  List<CssRule> getMatchedCssRules(Element element, String pseudoElement) native;

  @DomName('DOMWindow.getSelection')
  @DocsEditable
  DomSelection getSelection() native;

  @DomName('DOMWindow.matchMedia')
  @DocsEditable
  MediaQueryList matchMedia(String query) native;

  @DomName('DOMWindow.moveBy')
  @DocsEditable
  void moveBy(num x, num y) native;

  @DomName('DOMWindow.moveTo')
  @DocsEditable
  void moveTo(num x, num y) native;

  @DomName('DOMWindow.openDatabase')
  @DocsEditable
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental
  @Creates('Database')
  @Creates('DatabaseSync')
  Database openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]) native;

  void postMessage(/*SerializedScriptValue*/ message, String targetOrigin, [List messagePorts]) {
    if (?message && !?messagePorts) {
      var message_1 = convertDartToNative_SerializedScriptValue(message);
      _postMessage_1(message_1, targetOrigin);
      return;
    }
    if (?message) {
      var message_2 = convertDartToNative_SerializedScriptValue(message);
      _postMessage_2(message_2, targetOrigin, messagePorts);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('postMessage')
  @DomName('DOMWindow.postMessage')
  @DocsEditable
  void _postMessage_1(message, targetOrigin) native;
  @JSName('postMessage')
  @DomName('DOMWindow.postMessage')
  @DocsEditable
  void _postMessage_2(message, targetOrigin, List messagePorts) native;

  @DomName('DOMWindow.print')
  @DocsEditable
  void print() native;

  @DomName('DOMWindow.releaseEvents')
  @DocsEditable
  void releaseEvents() native;

  @JSName('removeEventListener')
  @DomName('DOMWindow.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('DOMWindow.resizeBy')
  @DocsEditable
  void resizeBy(num x, num y) native;

  @DomName('DOMWindow.resizeTo')
  @DocsEditable
  void resizeTo(num width, num height) native;

  @DomName('DOMWindow.scroll')
  @DocsEditable
  void scroll(int x, int y) native;

  @DomName('DOMWindow.scrollBy')
  @DocsEditable
  void scrollBy(int x, int y) native;

  @DomName('DOMWindow.scrollTo')
  @DocsEditable
  void scrollTo(int x, int y) native;

  @DomName('DOMWindow.setInterval')
  @DocsEditable
  int setInterval(TimeoutHandler handler, int timeout) native;

  @DomName('DOMWindow.setTimeout')
  @DocsEditable
  int setTimeout(TimeoutHandler handler, int timeout) native;

  @DomName('DOMWindow.showModalDialog')
  @DocsEditable
  Object showModalDialog(String url, [Object dialogArgs, String featureArgs]) native;

  @DomName('DOMWindow.stop')
  @DocsEditable
  void stop() native;

  @JSName('webkitConvertPointFromNodeToPage')
  @DomName('DOMWindow.webkitConvertPointFromNodeToPage')
  @DocsEditable
  DomPoint convertPointFromNodeToPage(Node node, DomPoint p) native;

  @JSName('webkitConvertPointFromPageToNode')
  @DomName('DOMWindow.webkitConvertPointFromPageToNode')
  @DocsEditable
  DomPoint convertPointFromPageToNode(Node node, DomPoint p) native;

  @JSName('webkitRequestFileSystem')
  @DomName('DOMWindow.webkitRequestFileSystem')
  @DocsEditable
  @SupportedBrowser(SupportedBrowser.CHROME)
  @Experimental
  void requestFileSystem(int type, int size, FileSystemCallback successCallback, [ErrorCallback errorCallback]) native;

  @JSName('webkitResolveLocalFileSystemURL')
  @DomName('DOMWindow.webkitResolveLocalFileSystemURL')
  @DocsEditable
  @SupportedBrowser(SupportedBrowser.CHROME)
  @Experimental
  void resolveLocalFileSystemUrl(String url, EntryCallback successCallback, [ErrorCallback errorCallback]) native;

  @DomName('DOMWindow.DOMContentLoaded')
  @DocsEditable
  Stream<Event> get onContentLoaded => contentLoadedEvent.forTarget(this);

  @DomName('DOMWindow.abort')
  @DocsEditable
  Stream<Event> get onAbort => Element.abortEvent.forTarget(this);

  @DomName('DOMWindow.beforeunload')
  @DocsEditable
  Stream<Event> get onBeforeUnload => beforeUnloadEvent.forTarget(this);

  @DomName('DOMWindow.blur')
  @DocsEditable
  Stream<Event> get onBlur => Element.blurEvent.forTarget(this);

  @DomName('DOMWindow.change')
  @DocsEditable
  Stream<Event> get onChange => Element.changeEvent.forTarget(this);

  @DomName('DOMWindow.click')
  @DocsEditable
  Stream<MouseEvent> get onClick => Element.clickEvent.forTarget(this);

  @DomName('DOMWindow.contextmenu')
  @DocsEditable
  Stream<MouseEvent> get onContextMenu => Element.contextMenuEvent.forTarget(this);

  @DomName('DOMWindow.dblclick')
  @DocsEditable
  Stream<Event> get onDoubleClick => Element.doubleClickEvent.forTarget(this);

  @DomName('DOMWindow.devicemotion')
  @DocsEditable
  Stream<DeviceMotionEvent> get onDeviceMotion => deviceMotionEvent.forTarget(this);

  @DomName('DOMWindow.deviceorientation')
  @DocsEditable
  Stream<DeviceOrientationEvent> get onDeviceOrientation => deviceOrientationEvent.forTarget(this);

  @DomName('DOMWindow.drag')
  @DocsEditable
  Stream<MouseEvent> get onDrag => Element.dragEvent.forTarget(this);

  @DomName('DOMWindow.dragend')
  @DocsEditable
  Stream<MouseEvent> get onDragEnd => Element.dragEndEvent.forTarget(this);

  @DomName('DOMWindow.dragenter')
  @DocsEditable
  Stream<MouseEvent> get onDragEnter => Element.dragEnterEvent.forTarget(this);

  @DomName('DOMWindow.dragleave')
  @DocsEditable
  Stream<MouseEvent> get onDragLeave => Element.dragLeaveEvent.forTarget(this);

  @DomName('DOMWindow.dragover')
  @DocsEditable
  Stream<MouseEvent> get onDragOver => Element.dragOverEvent.forTarget(this);

  @DomName('DOMWindow.dragstart')
  @DocsEditable
  Stream<MouseEvent> get onDragStart => Element.dragStartEvent.forTarget(this);

  @DomName('DOMWindow.drop')
  @DocsEditable
  Stream<MouseEvent> get onDrop => Element.dropEvent.forTarget(this);

  @DomName('DOMWindow.error')
  @DocsEditable
  Stream<Event> get onError => Element.errorEvent.forTarget(this);

  @DomName('DOMWindow.focus')
  @DocsEditable
  Stream<Event> get onFocus => Element.focusEvent.forTarget(this);

  @DomName('DOMWindow.hashchange')
  @DocsEditable
  Stream<Event> get onHashChange => hashChangeEvent.forTarget(this);

  @DomName('DOMWindow.input')
  @DocsEditable
  Stream<Event> get onInput => Element.inputEvent.forTarget(this);

  @DomName('DOMWindow.invalid')
  @DocsEditable
  Stream<Event> get onInvalid => Element.invalidEvent.forTarget(this);

  @DomName('DOMWindow.keydown')
  @DocsEditable
  Stream<KeyboardEvent> get onKeyDown => Element.keyDownEvent.forTarget(this);

  @DomName('DOMWindow.keypress')
  @DocsEditable
  Stream<KeyboardEvent> get onKeyPress => Element.keyPressEvent.forTarget(this);

  @DomName('DOMWindow.keyup')
  @DocsEditable
  Stream<KeyboardEvent> get onKeyUp => Element.keyUpEvent.forTarget(this);

  @DomName('DOMWindow.load')
  @DocsEditable
  Stream<Event> get onLoad => Element.loadEvent.forTarget(this);

  @DomName('DOMWindow.message')
  @DocsEditable
  Stream<MessageEvent> get onMessage => messageEvent.forTarget(this);

  @DomName('DOMWindow.mousedown')
  @DocsEditable
  Stream<MouseEvent> get onMouseDown => Element.mouseDownEvent.forTarget(this);

  @DomName('DOMWindow.mousemove')
  @DocsEditable
  Stream<MouseEvent> get onMouseMove => Element.mouseMoveEvent.forTarget(this);

  @DomName('DOMWindow.mouseout')
  @DocsEditable
  Stream<MouseEvent> get onMouseOut => Element.mouseOutEvent.forTarget(this);

  @DomName('DOMWindow.mouseover')
  @DocsEditable
  Stream<MouseEvent> get onMouseOver => Element.mouseOverEvent.forTarget(this);

  @DomName('DOMWindow.mouseup')
  @DocsEditable
  Stream<MouseEvent> get onMouseUp => Element.mouseUpEvent.forTarget(this);

  @DomName('DOMWindow.mousewheel')
  @DocsEditable
  Stream<WheelEvent> get onMouseWheel => Element.mouseWheelEvent.forTarget(this);

  @DomName('DOMWindow.offline')
  @DocsEditable
  Stream<Event> get onOffline => offlineEvent.forTarget(this);

  @DomName('DOMWindow.online')
  @DocsEditable
  Stream<Event> get onOnline => onlineEvent.forTarget(this);

  @DomName('DOMWindow.pagehide')
  @DocsEditable
  Stream<Event> get onPageHide => pageHideEvent.forTarget(this);

  @DomName('DOMWindow.pageshow')
  @DocsEditable
  Stream<Event> get onPageShow => pageShowEvent.forTarget(this);

  @DomName('DOMWindow.popstate')
  @DocsEditable
  Stream<PopStateEvent> get onPopState => popStateEvent.forTarget(this);

  @DomName('DOMWindow.reset')
  @DocsEditable
  Stream<Event> get onReset => Element.resetEvent.forTarget(this);

  @DomName('DOMWindow.resize')
  @DocsEditable
  Stream<Event> get onResize => resizeEvent.forTarget(this);

  @DomName('DOMWindow.scroll')
  @DocsEditable
  Stream<Event> get onScroll => Element.scrollEvent.forTarget(this);

  @DomName('DOMWindow.search')
  @DocsEditable
  Stream<Event> get onSearch => Element.searchEvent.forTarget(this);

  @DomName('DOMWindow.select')
  @DocsEditable
  Stream<Event> get onSelect => Element.selectEvent.forTarget(this);

  @DomName('DOMWindow.storage')
  @DocsEditable
  Stream<StorageEvent> get onStorage => storageEvent.forTarget(this);

  @DomName('DOMWindow.submit')
  @DocsEditable
  Stream<Event> get onSubmit => Element.submitEvent.forTarget(this);

  @DomName('DOMWindow.touchcancel')
  @DocsEditable
  Stream<TouchEvent> get onTouchCancel => Element.touchCancelEvent.forTarget(this);

  @DomName('DOMWindow.touchend')
  @DocsEditable
  Stream<TouchEvent> get onTouchEnd => Element.touchEndEvent.forTarget(this);

  @DomName('DOMWindow.touchmove')
  @DocsEditable
  Stream<TouchEvent> get onTouchMove => Element.touchMoveEvent.forTarget(this);

  @DomName('DOMWindow.touchstart')
  @DocsEditable
  Stream<TouchEvent> get onTouchStart => Element.touchStartEvent.forTarget(this);

  @DomName('DOMWindow.unload')
  @DocsEditable
  Stream<Event> get onUnload => unloadEvent.forTarget(this);

  @DomName('DOMWindow.webkitAnimationEnd')
  @DocsEditable
  Stream<AnimationEvent> get onAnimationEnd => animationEndEvent.forTarget(this);

  @DomName('DOMWindow.webkitAnimationIteration')
  @DocsEditable
  Stream<AnimationEvent> get onAnimationIteration => animationIterationEvent.forTarget(this);

  @DomName('DOMWindow.webkitAnimationStart')
  @DocsEditable
  Stream<AnimationEvent> get onAnimationStart => animationStartEvent.forTarget(this);

  @DomName('DOMWindow.webkitTransitionEnd')
  @DocsEditable
  Stream<TransitionEvent> get onTransitionEnd => Element.transitionEndEvent.forTarget(this);

}

@DocsEditable
@deprecated
class WindowEvents extends Events {
  @DocsEditable
  WindowEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get contentLoaded => this['DOMContentLoaded'];

  @DocsEditable
  EventListenerList get abort => this['abort'];

  @DocsEditable
  EventListenerList get beforeUnload => this['beforeunload'];

  @DocsEditable
  EventListenerList get blur => this['blur'];

  @DocsEditable
  EventListenerList get canPlay => this['canplay'];

  @DocsEditable
  EventListenerList get canPlayThrough => this['canplaythrough'];

  @DocsEditable
  EventListenerList get change => this['change'];

  @DocsEditable
  EventListenerList get click => this['click'];

  @DocsEditable
  EventListenerList get contextMenu => this['contextmenu'];

  @DocsEditable
  EventListenerList get doubleClick => this['dblclick'];

  @DocsEditable
  EventListenerList get deviceMotion => this['devicemotion'];

  @DocsEditable
  EventListenerList get deviceOrientation => this['deviceorientation'];

  @DocsEditable
  EventListenerList get drag => this['drag'];

  @DocsEditable
  EventListenerList get dragEnd => this['dragend'];

  @DocsEditable
  EventListenerList get dragEnter => this['dragenter'];

  @DocsEditable
  EventListenerList get dragLeave => this['dragleave'];

  @DocsEditable
  EventListenerList get dragOver => this['dragover'];

  @DocsEditable
  EventListenerList get dragStart => this['dragstart'];

  @DocsEditable
  EventListenerList get drop => this['drop'];

  @DocsEditable
  EventListenerList get durationChange => this['durationchange'];

  @DocsEditable
  EventListenerList get emptied => this['emptied'];

  @DocsEditable
  EventListenerList get ended => this['ended'];

  @DocsEditable
  EventListenerList get error => this['error'];

  @DocsEditable
  EventListenerList get focus => this['focus'];

  @DocsEditable
  EventListenerList get hashChange => this['hashchange'];

  @DocsEditable
  EventListenerList get input => this['input'];

  @DocsEditable
  EventListenerList get invalid => this['invalid'];

  @DocsEditable
  EventListenerList get keyDown => this['keydown'];

  @DocsEditable
  EventListenerList get keyPress => this['keypress'];

  @DocsEditable
  EventListenerList get keyUp => this['keyup'];

  @DocsEditable
  EventListenerList get load => this['load'];

  @DocsEditable
  EventListenerList get loadedData => this['loadeddata'];

  @DocsEditable
  EventListenerList get loadedMetadata => this['loadedmetadata'];

  @DocsEditable
  EventListenerList get loadStart => this['loadstart'];

  @DocsEditable
  EventListenerList get message => this['message'];

  @DocsEditable
  EventListenerList get mouseDown => this['mousedown'];

  @DocsEditable
  EventListenerList get mouseMove => this['mousemove'];

  @DocsEditable
  EventListenerList get mouseOut => this['mouseout'];

  @DocsEditable
  EventListenerList get mouseOver => this['mouseover'];

  @DocsEditable
  EventListenerList get mouseUp => this['mouseup'];

  @DocsEditable
  EventListenerList get mouseWheel => this['mousewheel'];

  @DocsEditable
  EventListenerList get offline => this['offline'];

  @DocsEditable
  EventListenerList get online => this['online'];

  @DocsEditable
  EventListenerList get pageHide => this['pagehide'];

  @DocsEditable
  EventListenerList get pageShow => this['pageshow'];

  @DocsEditable
  EventListenerList get pause => this['pause'];

  @DocsEditable
  EventListenerList get play => this['play'];

  @DocsEditable
  EventListenerList get playing => this['playing'];

  @DocsEditable
  EventListenerList get popState => this['popstate'];

  @DocsEditable
  EventListenerList get progress => this['progress'];

  @DocsEditable
  EventListenerList get rateChange => this['ratechange'];

  @DocsEditable
  EventListenerList get reset => this['reset'];

  @DocsEditable
  EventListenerList get resize => this['resize'];

  @DocsEditable
  EventListenerList get scroll => this['scroll'];

  @DocsEditable
  EventListenerList get search => this['search'];

  @DocsEditable
  EventListenerList get seeked => this['seeked'];

  @DocsEditable
  EventListenerList get seeking => this['seeking'];

  @DocsEditable
  EventListenerList get select => this['select'];

  @DocsEditable
  EventListenerList get stalled => this['stalled'];

  @DocsEditable
  EventListenerList get storage => this['storage'];

  @DocsEditable
  EventListenerList get submit => this['submit'];

  @DocsEditable
  EventListenerList get suspend => this['suspend'];

  @DocsEditable
  EventListenerList get timeUpdate => this['timeupdate'];

  @DocsEditable
  EventListenerList get touchCancel => this['touchcancel'];

  @DocsEditable
  EventListenerList get touchEnd => this['touchend'];

  @DocsEditable
  EventListenerList get touchMove => this['touchmove'];

  @DocsEditable
  EventListenerList get touchStart => this['touchstart'];

  @DocsEditable
  EventListenerList get unload => this['unload'];

  @DocsEditable
  EventListenerList get volumeChange => this['volumechange'];

  @DocsEditable
  EventListenerList get waiting => this['waiting'];

  @DocsEditable
  EventListenerList get animationEnd => this['webkitAnimationEnd'];

  @DocsEditable
  EventListenerList get animationIteration => this['webkitAnimationIteration'];

  @DocsEditable
  EventListenerList get animationStart => this['webkitAnimationStart'];

  @DocsEditable
  EventListenerList get transitionEnd => this['webkitTransitionEnd'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Worker')
class Worker extends AbstractWorker native "*Worker" {

  @DomName('Worker.message')
  @DocsEditable
  static const EventStreamProvider<MessageEvent> messageEvent = const EventStreamProvider<MessageEvent>('message');

  @DocsEditable
  factory Worker(String scriptUrl) => Worker._create(scriptUrl);
  static Worker _create(String scriptUrl) => JS('Worker', 'new Worker(#)', scriptUrl);

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  WorkerEvents get on =>
    new WorkerEvents(this);

  void postMessage(/*SerializedScriptValue*/ message, [List messagePorts]) {
    if (?messagePorts) {
      var message_1 = convertDartToNative_SerializedScriptValue(message);
      _postMessage_1(message_1, messagePorts);
      return;
    }
    var message_2 = convertDartToNative_SerializedScriptValue(message);
    _postMessage_2(message_2);
    return;
  }
  @JSName('postMessage')
  @DomName('Worker.postMessage')
  @DocsEditable
  void _postMessage_1(message, List messagePorts) native;
  @JSName('postMessage')
  @DomName('Worker.postMessage')
  @DocsEditable
  void _postMessage_2(message) native;

  @DomName('Worker.terminate')
  @DocsEditable
  void terminate() native;

  @DomName('Worker.message')
  @DocsEditable
  Stream<MessageEvent> get onMessage => messageEvent.forTarget(this);
}

@DocsEditable
@deprecated
class WorkerEvents extends AbstractWorkerEvents {
  @DocsEditable
  WorkerEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get message => this['message'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('WorkerContext')
class WorkerContext extends EventTarget native "*WorkerContext" {

  @DomName('WorkerContext.error')
  @DocsEditable
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  WorkerContextEvents get on =>
    new WorkerContextEvents(this);

  static const int PERSISTENT = 1;

  static const int TEMPORARY = 0;

  @DomName('WorkerContext.location')
  @DocsEditable
  final WorkerLocation location;

  @DomName('WorkerContext.navigator')
  @DocsEditable
  final WorkerNavigator navigator;

  @DomName('WorkerContext.self')
  @DocsEditable
  final WorkerContext self;

  @DomName('WorkerContext.webkitNotifications')
  @DocsEditable
  final NotificationCenter webkitNotifications;

  @JSName('addEventListener')
  @DomName('WorkerContext.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('WorkerContext.clearInterval')
  @DocsEditable
  void clearInterval(int handle) native;

  @DomName('WorkerContext.clearTimeout')
  @DocsEditable
  void clearTimeout(int handle) native;

  @DomName('WorkerContext.close')
  @DocsEditable
  void close() native;

  @DomName('WorkerContext.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native;

  @DomName('WorkerContext.importScripts')
  @DocsEditable
  void importScripts() native;

  @DomName('WorkerContext.openDatabase')
  @DocsEditable
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental
  Database openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]) native;

  @DomName('WorkerContext.openDatabaseSync')
  @DocsEditable
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental
  DatabaseSync openDatabaseSync(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]) native;

  @JSName('removeEventListener')
  @DomName('WorkerContext.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('WorkerContext.setInterval')
  @DocsEditable
  int setInterval(TimeoutHandler handler, int timeout) native;

  @DomName('WorkerContext.setTimeout')
  @DocsEditable
  int setTimeout(TimeoutHandler handler, int timeout) native;

  @JSName('webkitRequestFileSystem')
  @DomName('WorkerContext.webkitRequestFileSystem')
  @DocsEditable
  @SupportedBrowser(SupportedBrowser.CHROME)
  @Experimental
  void requestFileSystem(int type, int size, [FileSystemCallback successCallback, ErrorCallback errorCallback]) native;

  @JSName('webkitRequestFileSystemSync')
  @DomName('WorkerContext.webkitRequestFileSystemSync')
  @DocsEditable
  @SupportedBrowser(SupportedBrowser.CHROME)
  @Experimental
  FileSystemSync requestFileSystemSync(int type, int size) native;

  @JSName('webkitResolveLocalFileSystemSyncURL')
  @DomName('WorkerContext.webkitResolveLocalFileSystemSyncURL')
  @DocsEditable
  @SupportedBrowser(SupportedBrowser.CHROME)
  @Experimental
  EntrySync resolveLocalFileSystemSyncUrl(String url) native;

  @JSName('webkitResolveLocalFileSystemURL')
  @DomName('WorkerContext.webkitResolveLocalFileSystemURL')
  @DocsEditable
  @SupportedBrowser(SupportedBrowser.CHROME)
  @Experimental
  void resolveLocalFileSystemUrl(String url, EntryCallback successCallback, [ErrorCallback errorCallback]) native;

  @DomName('WorkerContext.error')
  @DocsEditable
  Stream<Event> get onError => errorEvent.forTarget(this);


  /**
   * Gets an instance of the Indexed DB factory to being using Indexed DB.
   *
   * Use [IdbFactory.supported] to check if Indexed DB is supported on the
   * current platform.
   */
  @SupportedBrowser(SupportedBrowser.CHROME, '23.0')
  @SupportedBrowser(SupportedBrowser.FIREFOX, '15.0')
  @SupportedBrowser(SupportedBrowser.IE, '10.0')
  @Experimental
  IdbFactory get indexedDB =>
      JS('IdbFactory',
         '#.indexedDB || #.webkitIndexedDB || #.mozIndexedDB',
         this, this, this);
}

@DocsEditable
@deprecated
class WorkerContextEvents extends Events {
  @DocsEditable
  WorkerContextEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get error => this['error'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WorkerLocation')
class WorkerLocation native "*WorkerLocation" {

  @DomName('WorkerLocation.hash')
  @DocsEditable
  final String hash;

  @DomName('WorkerLocation.host')
  @DocsEditable
  final String host;

  @DomName('WorkerLocation.hostname')
  @DocsEditable
  final String hostname;

  @DomName('WorkerLocation.href')
  @DocsEditable
  final String href;

  @DomName('WorkerLocation.pathname')
  @DocsEditable
  final String pathname;

  @DomName('WorkerLocation.port')
  @DocsEditable
  final String port;

  @DomName('WorkerLocation.protocol')
  @DocsEditable
  final String protocol;

  @DomName('WorkerLocation.search')
  @DocsEditable
  final String search;

  @DomName('WorkerLocation.toString')
  @DocsEditable
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WorkerNavigator')
class WorkerNavigator native "*WorkerNavigator" {

  @DomName('WorkerNavigator.appName')
  @DocsEditable
  final String appName;

  @DomName('WorkerNavigator.appVersion')
  @DocsEditable
  final String appVersion;

  @DomName('WorkerNavigator.onLine')
  @DocsEditable
  final bool onLine;

  @DomName('WorkerNavigator.platform')
  @DocsEditable
  final String platform;

  @DomName('WorkerNavigator.userAgent')
  @DocsEditable
  final String userAgent;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('XPathEvaluator')
class XPathEvaluator native "*XPathEvaluator" {

  @DocsEditable
  factory XPathEvaluator() => XPathEvaluator._create();
  static XPathEvaluator _create() => JS('XPathEvaluator', 'new XPathEvaluator()');

  @DomName('XPathEvaluator.createExpression')
  @DocsEditable
  XPathExpression createExpression(String expression, XPathNSResolver resolver) native;

  @DomName('XPathEvaluator.createNSResolver')
  @DocsEditable
  XPathNSResolver createNSResolver(Node nodeResolver) native;

  @DomName('XPathEvaluator.evaluate')
  @DocsEditable
  XPathResult evaluate(String expression, Node contextNode, XPathNSResolver resolver, int type, XPathResult inResult) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('XPathException')
class XPathException native "*XPathException" {

  static const int INVALID_EXPRESSION_ERR = 51;

  static const int TYPE_ERR = 52;

  @DomName('XPathException.code')
  @DocsEditable
  final int code;

  @DomName('XPathException.message')
  @DocsEditable
  final String message;

  @DomName('XPathException.name')
  @DocsEditable
  final String name;

  @DomName('XPathException.toString')
  @DocsEditable
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('XPathExpression')
class XPathExpression native "*XPathExpression" {

  @DomName('XPathExpression.evaluate')
  @DocsEditable
  XPathResult evaluate(Node contextNode, int type, XPathResult inResult) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('XPathNSResolver')
class XPathNSResolver native "*XPathNSResolver" {

  @JSName('lookupNamespaceURI')
  @DomName('XPathNSResolver.lookupNamespaceURI')
  @DocsEditable
  String lookupNamespaceUri(String prefix) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('XPathResult')
class XPathResult native "*XPathResult" {

  static const int ANY_TYPE = 0;

  static const int ANY_UNORDERED_NODE_TYPE = 8;

  static const int BOOLEAN_TYPE = 3;

  static const int FIRST_ORDERED_NODE_TYPE = 9;

  static const int NUMBER_TYPE = 1;

  static const int ORDERED_NODE_ITERATOR_TYPE = 5;

  static const int ORDERED_NODE_SNAPSHOT_TYPE = 7;

  static const int STRING_TYPE = 2;

  static const int UNORDERED_NODE_ITERATOR_TYPE = 4;

  static const int UNORDERED_NODE_SNAPSHOT_TYPE = 6;

  @DomName('XPathResult.booleanValue')
  @DocsEditable
  final bool booleanValue;

  @DomName('XPathResult.invalidIteratorState')
  @DocsEditable
  final bool invalidIteratorState;

  @DomName('XPathResult.numberValue')
  @DocsEditable
  final num numberValue;

  @DomName('XPathResult.resultType')
  @DocsEditable
  final int resultType;

  @DomName('XPathResult.singleNodeValue')
  @DocsEditable
  final Node singleNodeValue;

  @DomName('XPathResult.snapshotLength')
  @DocsEditable
  final int snapshotLength;

  @DomName('XPathResult.stringValue')
  @DocsEditable
  final String stringValue;

  @DomName('XPathResult.iterateNext')
  @DocsEditable
  Node iterateNext() native;

  @DomName('XPathResult.snapshotItem')
  @DocsEditable
  Node snapshotItem(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('XMLSerializer')
class XmlSerializer native "*XMLSerializer" {

  @DocsEditable
  factory XmlSerializer() => XmlSerializer._create();
  static XmlSerializer _create() => JS('XmlSerializer', 'new XMLSerializer()');

  @DomName('XMLSerializer.serializeToString')
  @DocsEditable
  String serializeToString(Node node) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('XSLTProcessor')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
class XsltProcessor native "*XSLTProcessor" {

  @DocsEditable
  factory XsltProcessor() => XsltProcessor._create();
  static XsltProcessor _create() => JS('XsltProcessor', 'new XSLTProcessor()');

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.XSLTProcessor)');

  @DomName('XSLTProcessor.clearParameters')
  @DocsEditable
  void clearParameters() native;

  @DomName('XSLTProcessor.getParameter')
  @DocsEditable
  String getParameter(String namespaceURI, String localName) native;

  @DomName('XSLTProcessor.importStylesheet')
  @DocsEditable
  void importStylesheet(Node stylesheet) native;

  @DomName('XSLTProcessor.removeParameter')
  @DocsEditable
  void removeParameter(String namespaceURI, String localName) native;

  @DomName('XSLTProcessor.reset')
  @DocsEditable
  void reset() native;

  @DomName('XSLTProcessor.setParameter')
  @DocsEditable
  void setParameter(String namespaceURI, String localName, String value) native;

  @DomName('XSLTProcessor.transformToDocument')
  @DocsEditable
  Document transformToDocument(Node source) native;

  @DomName('XSLTProcessor.transformToFragment')
  @DocsEditable
  DocumentFragment transformToFragment(Node source, Document docVal) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLAppletElement')
class _AppletElement extends Element native "*HTMLAppletElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLBaseFontElement')
class _BaseFontElement extends Element native "*HTMLBaseFontElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('ClientRectList')
class _ClientRectList implements JavaScriptIndexingBehavior, List<ClientRect> native "*ClientRectList" {

  @DomName('ClientRectList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  ClientRect operator[](int index) => JS("ClientRect", "#[#]", this, index);

  void operator[]=(int index, ClientRect value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<ClientRect> mixins.
  // ClientRect is the element type.

  // From Iterable<ClientRect>:

  Iterator<ClientRect> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<ClientRect>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, ClientRect)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(ClientRect element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(ClientRect element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(ClientRect element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<ClientRect> where(bool f(ClientRect element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(ClientRect element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(ClientRect element)) => IterableMixinWorkaround.any(this, f);

  List<ClientRect> toList() => new List<ClientRect>.from(this);
  Set<ClientRect> toSet() => new Set<ClientRect>.from(this);

  bool get isEmpty => this.length == 0;

  List<ClientRect> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<ClientRect> takeWhile(bool test(ClientRect value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<ClientRect> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<ClientRect> skipWhile(bool test(ClientRect value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  ClientRect firstMatching(bool test(ClientRect value), { ClientRect orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  ClientRect lastMatching(bool test(ClientRect value), {ClientRect orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  ClientRect singleMatching(bool test(ClientRect value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  ClientRect elementAt(int index) {
    return this[index];
  }

  // From Collection<ClientRect>:

  void add(ClientRect value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(ClientRect value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<ClientRect> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<ClientRect>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<ClientRect> get reversed =>
      new ReversedListView<ClientRect>(this, 0, null);

  void sort([int compare(ClientRect a, ClientRect b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(ClientRect element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(ClientRect element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  ClientRect get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  ClientRect get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  ClientRect get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  ClientRect min([int compare(ClientRect a, ClientRect b)]) =>
      IterableMixinWorkaround.min(this, compare);

  ClientRect max([int compare(ClientRect a, ClientRect b)]) =>
      IterableMixinWorkaround.max(this, compare);

  ClientRect removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  ClientRect removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(ClientRect element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(ClientRect element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<ClientRect> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [ClientRect initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<ClientRect> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <ClientRect>[]);

  // -- end List<ClientRect> mixins.

  @DomName('ClientRectList.item')
  @DocsEditable
  ClientRect item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('CSSRuleList')
class _CssRuleList implements JavaScriptIndexingBehavior, List<CssRule> native "*CSSRuleList" {

  @DomName('CSSRuleList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  CssRule operator[](int index) => JS("CssRule", "#[#]", this, index);

  void operator[]=(int index, CssRule value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<CssRule> mixins.
  // CssRule is the element type.

  // From Iterable<CssRule>:

  Iterator<CssRule> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<CssRule>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, CssRule)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(CssRule element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(CssRule element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(CssRule element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<CssRule> where(bool f(CssRule element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(CssRule element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(CssRule element)) => IterableMixinWorkaround.any(this, f);

  List<CssRule> toList() => new List<CssRule>.from(this);
  Set<CssRule> toSet() => new Set<CssRule>.from(this);

  bool get isEmpty => this.length == 0;

  List<CssRule> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<CssRule> takeWhile(bool test(CssRule value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<CssRule> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<CssRule> skipWhile(bool test(CssRule value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  CssRule firstMatching(bool test(CssRule value), { CssRule orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  CssRule lastMatching(bool test(CssRule value), {CssRule orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  CssRule singleMatching(bool test(CssRule value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  CssRule elementAt(int index) {
    return this[index];
  }

  // From Collection<CssRule>:

  void add(CssRule value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(CssRule value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<CssRule> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<CssRule>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<CssRule> get reversed =>
      new ReversedListView<CssRule>(this, 0, null);

  void sort([int compare(CssRule a, CssRule b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(CssRule element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(CssRule element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  CssRule get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  CssRule get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  CssRule get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  CssRule min([int compare(CssRule a, CssRule b)]) =>
      IterableMixinWorkaround.min(this, compare);

  CssRule max([int compare(CssRule a, CssRule b)]) =>
      IterableMixinWorkaround.max(this, compare);

  CssRule removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  CssRule removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(CssRule element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(CssRule element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<CssRule> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [CssRule initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<CssRule> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <CssRule>[]);

  // -- end List<CssRule> mixins.

  @DomName('CSSRuleList.item')
  @DocsEditable
  CssRule item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('CSSValueList')
class _CssValueList extends CssValue implements List<CssValue>, JavaScriptIndexingBehavior native "*CSSValueList" {

  @DomName('CSSValueList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  CssValue operator[](int index) => JS("CssValue", "#[#]", this, index);

  void operator[]=(int index, CssValue value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<CssValue> mixins.
  // CssValue is the element type.

  // From Iterable<CssValue>:

  Iterator<CssValue> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<CssValue>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, CssValue)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(CssValue element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(CssValue element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(CssValue element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<CssValue> where(bool f(CssValue element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(CssValue element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(CssValue element)) => IterableMixinWorkaround.any(this, f);

  List<CssValue> toList() => new List<CssValue>.from(this);
  Set<CssValue> toSet() => new Set<CssValue>.from(this);

  bool get isEmpty => this.length == 0;

  List<CssValue> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<CssValue> takeWhile(bool test(CssValue value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<CssValue> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<CssValue> skipWhile(bool test(CssValue value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  CssValue firstMatching(bool test(CssValue value), { CssValue orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  CssValue lastMatching(bool test(CssValue value), {CssValue orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  CssValue singleMatching(bool test(CssValue value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  CssValue elementAt(int index) {
    return this[index];
  }

  // From Collection<CssValue>:

  void add(CssValue value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(CssValue value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<CssValue> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<CssValue>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<CssValue> get reversed =>
      new ReversedListView<CssValue>(this, 0, null);

  void sort([int compare(CssValue a, CssValue b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(CssValue element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(CssValue element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  CssValue get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  CssValue get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  CssValue get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  CssValue min([int compare(CssValue a, CssValue b)]) =>
      IterableMixinWorkaround.min(this, compare);

  CssValue max([int compare(CssValue a, CssValue b)]) =>
      IterableMixinWorkaround.max(this, compare);

  CssValue removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  CssValue removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(CssValue element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(CssValue element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<CssValue> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [CssValue initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<CssValue> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <CssValue>[]);

  // -- end List<CssValue> mixins.

  @DomName('CSSValueList.item')
  @DocsEditable
  CssValue item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLDirectoryElement')
class _DirectoryElement extends Element native "*HTMLDirectoryElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('EntryArray')
class _EntryArray implements JavaScriptIndexingBehavior, List<Entry> native "*EntryArray" {

  @DomName('EntryArray.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  Entry operator[](int index) => JS("Entry", "#[#]", this, index);

  void operator[]=(int index, Entry value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Entry> mixins.
  // Entry is the element type.

  // From Iterable<Entry>:

  Iterator<Entry> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Entry>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, Entry)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(Entry element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(Entry element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(Entry element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<Entry> where(bool f(Entry element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(Entry element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(Entry element)) => IterableMixinWorkaround.any(this, f);

  List<Entry> toList() => new List<Entry>.from(this);
  Set<Entry> toSet() => new Set<Entry>.from(this);

  bool get isEmpty => this.length == 0;

  List<Entry> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<Entry> takeWhile(bool test(Entry value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<Entry> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<Entry> skipWhile(bool test(Entry value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  Entry firstMatching(bool test(Entry value), { Entry orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  Entry lastMatching(bool test(Entry value), {Entry orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  Entry singleMatching(bool test(Entry value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  Entry elementAt(int index) {
    return this[index];
  }

  // From Collection<Entry>:

  void add(Entry value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Entry value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<Entry> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<Entry>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<Entry> get reversed =>
      new ReversedListView<Entry>(this, 0, null);

  void sort([int compare(Entry a, Entry b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Entry element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Entry element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  Entry get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  Entry get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  Entry get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Entry min([int compare(Entry a, Entry b)]) =>
      IterableMixinWorkaround.min(this, compare);

  Entry max([int compare(Entry a, Entry b)]) =>
      IterableMixinWorkaround.max(this, compare);

  Entry removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  Entry removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(Entry element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(Entry element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<Entry> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Entry initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Entry> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <Entry>[]);

  // -- end List<Entry> mixins.

  @DomName('EntryArray.item')
  @DocsEditable
  Entry item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('EntryArraySync')
class _EntryArraySync implements JavaScriptIndexingBehavior, List<EntrySync> native "*EntryArraySync" {

  @DomName('EntryArraySync.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  EntrySync operator[](int index) => JS("EntrySync", "#[#]", this, index);

  void operator[]=(int index, EntrySync value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<EntrySync> mixins.
  // EntrySync is the element type.

  // From Iterable<EntrySync>:

  Iterator<EntrySync> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<EntrySync>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, EntrySync)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(EntrySync element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(EntrySync element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(EntrySync element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<EntrySync> where(bool f(EntrySync element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(EntrySync element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(EntrySync element)) => IterableMixinWorkaround.any(this, f);

  List<EntrySync> toList() => new List<EntrySync>.from(this);
  Set<EntrySync> toSet() => new Set<EntrySync>.from(this);

  bool get isEmpty => this.length == 0;

  List<EntrySync> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<EntrySync> takeWhile(bool test(EntrySync value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<EntrySync> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<EntrySync> skipWhile(bool test(EntrySync value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  EntrySync firstMatching(bool test(EntrySync value), { EntrySync orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  EntrySync lastMatching(bool test(EntrySync value), {EntrySync orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  EntrySync singleMatching(bool test(EntrySync value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  EntrySync elementAt(int index) {
    return this[index];
  }

  // From Collection<EntrySync>:

  void add(EntrySync value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(EntrySync value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<EntrySync> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<EntrySync>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<EntrySync> get reversed =>
      new ReversedListView<EntrySync>(this, 0, null);

  void sort([int compare(EntrySync a, EntrySync b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(EntrySync element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(EntrySync element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  EntrySync get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  EntrySync get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  EntrySync get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  EntrySync min([int compare(EntrySync a, EntrySync b)]) =>
      IterableMixinWorkaround.min(this, compare);

  EntrySync max([int compare(EntrySync a, EntrySync b)]) =>
      IterableMixinWorkaround.max(this, compare);

  EntrySync removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  EntrySync removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(EntrySync element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(EntrySync element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<EntrySync> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [EntrySync initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<EntrySync> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <EntrySync>[]);

  // -- end List<EntrySync> mixins.

  @DomName('EntryArraySync.item')
  @DocsEditable
  EntrySync item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLFontElement')
class _FontElement extends Element native "*HTMLFontElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLFrameElement')
class _FrameElement extends Element native "*HTMLFrameElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLFrameSetElement')
class _FrameSetElement extends Element native "*HTMLFrameSetElement" {

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  @deprecated
  _FrameSetElementEvents get on =>
    new _FrameSetElementEvents(this);
}

@DocsEditable
@deprecated
class _FrameSetElementEvents extends ElementEvents {
  @DocsEditable
  _FrameSetElementEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get beforeUnload => this['beforeunload'];

  @DocsEditable
  EventListenerList get blur => this['blur'];

  @DocsEditable
  EventListenerList get error => this['error'];

  @DocsEditable
  EventListenerList get focus => this['focus'];

  @DocsEditable
  EventListenerList get hashChange => this['hashchange'];

  @DocsEditable
  EventListenerList get load => this['load'];

  @DocsEditable
  EventListenerList get message => this['message'];

  @DocsEditable
  EventListenerList get offline => this['offline'];

  @DocsEditable
  EventListenerList get online => this['online'];

  @DocsEditable
  EventListenerList get popState => this['popstate'];

  @DocsEditable
  EventListenerList get resize => this['resize'];

  @DocsEditable
  EventListenerList get storage => this['storage'];

  @DocsEditable
  EventListenerList get unload => this['unload'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('GamepadList')
class _GamepadList implements JavaScriptIndexingBehavior, List<Gamepad> native "*GamepadList" {

  @DomName('GamepadList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  Gamepad operator[](int index) => JS("Gamepad", "#[#]", this, index);

  void operator[]=(int index, Gamepad value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Gamepad> mixins.
  // Gamepad is the element type.

  // From Iterable<Gamepad>:

  Iterator<Gamepad> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Gamepad>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, Gamepad)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(Gamepad element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(Gamepad element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(Gamepad element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<Gamepad> where(bool f(Gamepad element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(Gamepad element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(Gamepad element)) => IterableMixinWorkaround.any(this, f);

  List<Gamepad> toList() => new List<Gamepad>.from(this);
  Set<Gamepad> toSet() => new Set<Gamepad>.from(this);

  bool get isEmpty => this.length == 0;

  List<Gamepad> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<Gamepad> takeWhile(bool test(Gamepad value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<Gamepad> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<Gamepad> skipWhile(bool test(Gamepad value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  Gamepad firstMatching(bool test(Gamepad value), { Gamepad orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  Gamepad lastMatching(bool test(Gamepad value), {Gamepad orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  Gamepad singleMatching(bool test(Gamepad value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  Gamepad elementAt(int index) {
    return this[index];
  }

  // From Collection<Gamepad>:

  void add(Gamepad value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Gamepad value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<Gamepad> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<Gamepad>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<Gamepad> get reversed =>
      new ReversedListView<Gamepad>(this, 0, null);

  void sort([int compare(Gamepad a, Gamepad b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Gamepad element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Gamepad element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  Gamepad get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  Gamepad get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  Gamepad get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Gamepad min([int compare(Gamepad a, Gamepad b)]) =>
      IterableMixinWorkaround.min(this, compare);

  Gamepad max([int compare(Gamepad a, Gamepad b)]) =>
      IterableMixinWorkaround.max(this, compare);

  Gamepad removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  Gamepad removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(Gamepad element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(Gamepad element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<Gamepad> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Gamepad initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Gamepad> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <Gamepad>[]);

  // -- end List<Gamepad> mixins.

  @DomName('GamepadList.item')
  @DocsEditable
  Gamepad item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLMarqueeElement')
class _MarqueeElement extends Element native "*HTMLMarqueeElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MediaStreamList')
class _MediaStreamList implements JavaScriptIndexingBehavior, List<MediaStream> native "*MediaStreamList" {

  @DomName('MediaStreamList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  MediaStream operator[](int index) => JS("MediaStream", "#[#]", this, index);

  void operator[]=(int index, MediaStream value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<MediaStream> mixins.
  // MediaStream is the element type.

  // From Iterable<MediaStream>:

  Iterator<MediaStream> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<MediaStream>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, MediaStream)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(MediaStream element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(MediaStream element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(MediaStream element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<MediaStream> where(bool f(MediaStream element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(MediaStream element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(MediaStream element)) => IterableMixinWorkaround.any(this, f);

  List<MediaStream> toList() => new List<MediaStream>.from(this);
  Set<MediaStream> toSet() => new Set<MediaStream>.from(this);

  bool get isEmpty => this.length == 0;

  List<MediaStream> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<MediaStream> takeWhile(bool test(MediaStream value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<MediaStream> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<MediaStream> skipWhile(bool test(MediaStream value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  MediaStream firstMatching(bool test(MediaStream value), { MediaStream orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  MediaStream lastMatching(bool test(MediaStream value), {MediaStream orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  MediaStream singleMatching(bool test(MediaStream value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  MediaStream elementAt(int index) {
    return this[index];
  }

  // From Collection<MediaStream>:

  void add(MediaStream value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(MediaStream value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<MediaStream> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<MediaStream>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<MediaStream> get reversed =>
      new ReversedListView<MediaStream>(this, 0, null);

  void sort([int compare(MediaStream a, MediaStream b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(MediaStream element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(MediaStream element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  MediaStream get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  MediaStream get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  MediaStream get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  MediaStream min([int compare(MediaStream a, MediaStream b)]) =>
      IterableMixinWorkaround.min(this, compare);

  MediaStream max([int compare(MediaStream a, MediaStream b)]) =>
      IterableMixinWorkaround.max(this, compare);

  MediaStream removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  MediaStream removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(MediaStream element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(MediaStream element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<MediaStream> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [MediaStream initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<MediaStream> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <MediaStream>[]);

  // -- end List<MediaStream> mixins.

  @DomName('MediaStreamList.item')
  @DocsEditable
  MediaStream item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SpeechInputResultList')
class _SpeechInputResultList implements JavaScriptIndexingBehavior, List<SpeechInputResult> native "*SpeechInputResultList" {

  @DomName('SpeechInputResultList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  SpeechInputResult operator[](int index) => JS("SpeechInputResult", "#[#]", this, index);

  void operator[]=(int index, SpeechInputResult value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SpeechInputResult> mixins.
  // SpeechInputResult is the element type.

  // From Iterable<SpeechInputResult>:

  Iterator<SpeechInputResult> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SpeechInputResult>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, SpeechInputResult)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(SpeechInputResult element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(SpeechInputResult element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(SpeechInputResult element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<SpeechInputResult> where(bool f(SpeechInputResult element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(SpeechInputResult element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(SpeechInputResult element)) => IterableMixinWorkaround.any(this, f);

  List<SpeechInputResult> toList() => new List<SpeechInputResult>.from(this);
  Set<SpeechInputResult> toSet() => new Set<SpeechInputResult>.from(this);

  bool get isEmpty => this.length == 0;

  List<SpeechInputResult> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<SpeechInputResult> takeWhile(bool test(SpeechInputResult value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<SpeechInputResult> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<SpeechInputResult> skipWhile(bool test(SpeechInputResult value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  SpeechInputResult firstMatching(bool test(SpeechInputResult value), { SpeechInputResult orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  SpeechInputResult lastMatching(bool test(SpeechInputResult value), {SpeechInputResult orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  SpeechInputResult singleMatching(bool test(SpeechInputResult value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  SpeechInputResult elementAt(int index) {
    return this[index];
  }

  // From Collection<SpeechInputResult>:

  void add(SpeechInputResult value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SpeechInputResult value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<SpeechInputResult> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<SpeechInputResult>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<SpeechInputResult> get reversed =>
      new ReversedListView<SpeechInputResult>(this, 0, null);

  void sort([int compare(SpeechInputResult a, SpeechInputResult b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SpeechInputResult element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SpeechInputResult element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  SpeechInputResult get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  SpeechInputResult get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  SpeechInputResult get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  SpeechInputResult min([int compare(SpeechInputResult a, SpeechInputResult b)]) =>
      IterableMixinWorkaround.min(this, compare);

  SpeechInputResult max([int compare(SpeechInputResult a, SpeechInputResult b)]) =>
      IterableMixinWorkaround.max(this, compare);

  SpeechInputResult removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  SpeechInputResult removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(SpeechInputResult element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(SpeechInputResult element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<SpeechInputResult> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SpeechInputResult initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SpeechInputResult> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <SpeechInputResult>[]);

  // -- end List<SpeechInputResult> mixins.

  @DomName('SpeechInputResultList.item')
  @DocsEditable
  SpeechInputResult item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SpeechRecognitionResultList')
class _SpeechRecognitionResultList implements JavaScriptIndexingBehavior, List<SpeechRecognitionResult> native "*SpeechRecognitionResultList" {

  @DomName('SpeechRecognitionResultList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  SpeechRecognitionResult operator[](int index) => JS("SpeechRecognitionResult", "#[#]", this, index);

  void operator[]=(int index, SpeechRecognitionResult value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SpeechRecognitionResult> mixins.
  // SpeechRecognitionResult is the element type.

  // From Iterable<SpeechRecognitionResult>:

  Iterator<SpeechRecognitionResult> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SpeechRecognitionResult>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, SpeechRecognitionResult)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(SpeechRecognitionResult element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(SpeechRecognitionResult element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(SpeechRecognitionResult element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<SpeechRecognitionResult> where(bool f(SpeechRecognitionResult element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(SpeechRecognitionResult element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(SpeechRecognitionResult element)) => IterableMixinWorkaround.any(this, f);

  List<SpeechRecognitionResult> toList() => new List<SpeechRecognitionResult>.from(this);
  Set<SpeechRecognitionResult> toSet() => new Set<SpeechRecognitionResult>.from(this);

  bool get isEmpty => this.length == 0;

  List<SpeechRecognitionResult> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<SpeechRecognitionResult> takeWhile(bool test(SpeechRecognitionResult value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<SpeechRecognitionResult> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<SpeechRecognitionResult> skipWhile(bool test(SpeechRecognitionResult value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  SpeechRecognitionResult firstMatching(bool test(SpeechRecognitionResult value), { SpeechRecognitionResult orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  SpeechRecognitionResult lastMatching(bool test(SpeechRecognitionResult value), {SpeechRecognitionResult orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  SpeechRecognitionResult singleMatching(bool test(SpeechRecognitionResult value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  SpeechRecognitionResult elementAt(int index) {
    return this[index];
  }

  // From Collection<SpeechRecognitionResult>:

  void add(SpeechRecognitionResult value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SpeechRecognitionResult value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<SpeechRecognitionResult> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<SpeechRecognitionResult>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<SpeechRecognitionResult> get reversed =>
      new ReversedListView<SpeechRecognitionResult>(this, 0, null);

  void sort([int compare(SpeechRecognitionResult a, SpeechRecognitionResult b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SpeechRecognitionResult element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SpeechRecognitionResult element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  SpeechRecognitionResult get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  SpeechRecognitionResult get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  SpeechRecognitionResult get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  SpeechRecognitionResult min([int compare(SpeechRecognitionResult a, SpeechRecognitionResult b)]) =>
      IterableMixinWorkaround.min(this, compare);

  SpeechRecognitionResult max([int compare(SpeechRecognitionResult a, SpeechRecognitionResult b)]) =>
      IterableMixinWorkaround.max(this, compare);

  SpeechRecognitionResult removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  SpeechRecognitionResult removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(SpeechRecognitionResult element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(SpeechRecognitionResult element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<SpeechRecognitionResult> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SpeechRecognitionResult initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SpeechRecognitionResult> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <SpeechRecognitionResult>[]);

  // -- end List<SpeechRecognitionResult> mixins.

  @DomName('SpeechRecognitionResultList.item')
  @DocsEditable
  SpeechRecognitionResult item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('StyleSheetList')
class _StyleSheetList implements JavaScriptIndexingBehavior, List<StyleSheet> native "*StyleSheetList" {

  @DomName('StyleSheetList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  StyleSheet operator[](int index) => JS("StyleSheet", "#[#]", this, index);

  void operator[]=(int index, StyleSheet value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<StyleSheet> mixins.
  // StyleSheet is the element type.

  // From Iterable<StyleSheet>:

  Iterator<StyleSheet> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<StyleSheet>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, StyleSheet)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(StyleSheet element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(StyleSheet element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  List mappedBy(f(StyleSheet element)) => IterableMixinWorkaround.mappedByList(this, f);

  Iterable<StyleSheet> where(bool f(StyleSheet element)) =>
      IterableMixinWorkaround.where(this, f);

  bool every(bool f(StyleSheet element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(StyleSheet element)) => IterableMixinWorkaround.any(this, f);

  List<StyleSheet> toList() => new List<StyleSheet>.from(this);
  Set<StyleSheet> toSet() => new Set<StyleSheet>.from(this);

  bool get isEmpty => this.length == 0;

  List<StyleSheet> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<StyleSheet> takeWhile(bool test(StyleSheet value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<StyleSheet> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<StyleSheet> skipWhile(bool test(StyleSheet value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  StyleSheet firstMatching(bool test(StyleSheet value), { StyleSheet orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  StyleSheet lastMatching(bool test(StyleSheet value), {StyleSheet orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  StyleSheet singleMatching(bool test(StyleSheet value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  StyleSheet elementAt(int index) {
    return this[index];
  }

  // From Collection<StyleSheet>:

  void add(StyleSheet value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(StyleSheet value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<StyleSheet> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<StyleSheet>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  List<StyleSheet> get reversed =>
      new ReversedListView<StyleSheet>(this, 0, null);

  void sort([int compare(StyleSheet a, StyleSheet b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(StyleSheet element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(StyleSheet element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  StyleSheet get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  StyleSheet get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  StyleSheet get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  StyleSheet min([int compare(StyleSheet a, StyleSheet b)]) =>
      IterableMixinWorkaround.min(this, compare);

  StyleSheet max([int compare(StyleSheet a, StyleSheet b)]) =>
      IterableMixinWorkaround.max(this, compare);

  StyleSheet removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  StyleSheet removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeMatching(bool test(StyleSheet element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(StyleSheet element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<StyleSheet> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [StyleSheet initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<StyleSheet> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <StyleSheet>[]);

  // -- end List<StyleSheet> mixins.

  @DomName('StyleSheetList.item')
  @DocsEditable
  StyleSheet item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


abstract class _AttributeMap implements Map<String, String> {
  final Element _element;

  _AttributeMap(this._element);

  bool containsValue(String value) {
    for (var v in this.values) {
      if (value == v) {
        return true;
      }
    }
    return false;
  }

  String putIfAbsent(String key, String ifAbsent()) {
    if (!containsKey(key)) {
      this[key] = ifAbsent();
    }
    return this[key];
  }

  void clear() {
    for (var key in keys) {
      remove(key);
    }
  }

  void forEach(void f(String key, String value)) {
    for (var key in keys) {
      var value = this[key];
      f(key, value);
    }
  }

  Collection<String> get keys {
    // TODO: generate a lazy collection instead.
    var attributes = _element.$dom_attributes;
    var keys = new List<String>();
    for (int i = 0, len = attributes.length; i < len; i++) {
      if (_matches(attributes[i])) {
        keys.add(attributes[i].$dom_localName);
      }
    }
    return keys;
  }

  Collection<String> get values {
    // TODO: generate a lazy collection instead.
    var attributes = _element.$dom_attributes;
    var values = new List<String>();
    for (int i = 0, len = attributes.length; i < len; i++) {
      if (_matches(attributes[i])) {
        values.add(attributes[i].value);
      }
    }
    return values;
  }

  /**
   * Returns true if there is no {key, value} pair in the map.
   */
  bool get isEmpty {
    return length == 0;
  }

  /**
   * Checks to see if the node should be included in this map.
   */
  bool _matches(Node node);
}

/**
 * Wrapper to expose [Element.attributes] as a typed map.
 */
class _ElementAttributeMap extends _AttributeMap {

  _ElementAttributeMap(Element element): super(element);

  bool containsKey(String key) {
    return _element.$dom_hasAttribute(key);
  }

  String operator [](String key) {
    return _element.$dom_getAttribute(key);
  }

  void operator []=(String key, value) {
    _element.$dom_setAttribute(key, '$value');
  }

  String remove(String key) {
    String value = _element.$dom_getAttribute(key);
    _element.$dom_removeAttribute(key);
    return value;
  }

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length {
    return keys.length;
  }

  bool _matches(Node node) => node.$dom_namespaceUri == null;
}

/**
 * Wrapper to expose namespaced attributes as a typed map.
 */
class _NamespacedAttributeMap extends _AttributeMap {

  final String _namespace;

  _NamespacedAttributeMap(Element element, this._namespace): super(element);

  bool containsKey(String key) {
    return _element.$dom_hasAttributeNS(_namespace, key);
  }

  String operator [](String key) {
    return _element.$dom_getAttributeNS(_namespace, key);
  }

  void operator []=(String key, value) {
    _element.$dom_setAttributeNS(_namespace, key, '$value');
  }

  String remove(String key) {
    String value = this[key];
    _element.$dom_removeAttributeNS(_namespace, key);
    return value;
  }

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length {
    return keys.length;
  }

  bool _matches(Node node) => node.$dom_namespaceUri == _namespace;
}


/**
 * Provides a Map abstraction on top of data-* attributes, similar to the
 * dataSet in the old DOM.
 */
class _DataAttributeMap implements Map<String, String> {

  final Map<String, String> $dom_attributes;

  _DataAttributeMap(this.$dom_attributes);

  // interface Map

  // TODO: Use lazy iterator when it is available on Map.
  bool containsValue(String value) => values.any((v) => v == value);

  bool containsKey(String key) => $dom_attributes.containsKey(_attr(key));

  String operator [](String key) => $dom_attributes[_attr(key)];

  void operator []=(String key, value) {
    $dom_attributes[_attr(key)] = '$value';
  }

  String putIfAbsent(String key, String ifAbsent()) =>
    $dom_attributes.putIfAbsent(_attr(key), ifAbsent);

  String remove(String key) => $dom_attributes.remove(_attr(key));

  void clear() {
    // Needs to operate on a snapshot since we are mutating the collection.
    for (String key in keys) {
      remove(key);
    }
  }

  void forEach(void f(String key, String value)) {
    $dom_attributes.forEach((String key, String value) {
      if (_matches(key)) {
        f(_strip(key), value);
      }
    });
  }

  Collection<String> get keys {
    final keys = new List<String>();
    $dom_attributes.forEach((String key, String value) {
      if (_matches(key)) {
        keys.add(_strip(key));
      }
    });
    return keys;
  }

  Collection<String> get values {
    final values = new List<String>();
    $dom_attributes.forEach((String key, String value) {
      if (_matches(key)) {
        values.add(value);
      }
    });
    return values;
  }

  int get length => keys.length;

  // TODO: Use lazy iterator when it is available on Map.
  bool get isEmpty => length == 0;

  // Helpers.
  String _attr(String key) => 'data-$key';
  bool _matches(String key) => key.startsWith('data-');
  String _strip(String key) => key.substring(5);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * An object representing the top-level context object for web scripting.
 *
 * In a web browser, a [Window] object represents the actual browser window.
 * In a multi-tabbed browser, each tab has its own [Window] object. A [Window]
 * is the container that displays a [Document]'s content. All web scripting
 * happens within the context of a [Window] object.
 *
 * **Note:** This class represents any window, whereas [Window] is
 * used to access the properties and content of the current window.
 *
 * See also:
 *
 * * [DOM Window](https://developer.mozilla.org/en-US/docs/DOM/window) from MDN.
 * * [Window](http://www.w3.org/TR/Window/) from the W3C.
 */
abstract class WindowBase {
  // Fields.

  /**
   * The current location of this window.
   *
   *     Location currentLocation = window.location;
   *     print(currentLocation.href); // 'http://www.example.com:80/'
   */
  LocationBase get location;
  HistoryBase get history;

  /**
   * Indicates whether this window has been closed.
   *
   *     print(window.closed); // 'false'
   *     window.close();
   *     print(window.closed); // 'true'
   */
  bool get closed;

  /**
   * A reference to the window that opened this one.
   *
   *     Window thisWindow = window;
   *     WindowBase otherWindow = thisWindow.open('http://www.example.com/', 'foo');
   *     print(otherWindow.opener == thisWindow); // 'true'
   */
  WindowBase get opener;

  /**
   * A reference to the parent of this window.
   *
   * If this [WindowBase] has no parent, [parent] will return a reference to
   * the [WindowBase] itself.
   *
   *     IFrameElement myIFrame = new IFrameElement();
   *     window.document.body.elements.add(myIFrame);
   *     print(myIframe.contentWindow.parent == window) // 'true'
   *
   *     print(window.parent == window) // 'true'
   */
  WindowBase get parent;

  /**
   * A reference to the topmost window in the window hierarchy.
   *
   * If this [WindowBase] is the topmost [WindowBase], [top] will return a
   * reference to the [WindowBase] itself.
   *
   *     // Add an IFrame to the current window.
   *     IFrameElement myIFrame = new IFrameElement();
   *     window.document.body.elements.add(myIFrame);
   *
   *     // Add an IFrame inside of the other IFrame.
   *     IFrameElement innerIFrame = new IFrameElement();
   *     myIFrame.elements.add(innerIFrame);
   *
   *     print(myIframe.contentWindow.top == window) // 'true'
   *     print(innerIFrame.contentWindow.top == window) // 'true'
   *
   *     print(window.top == window) // 'true'
   */
  WindowBase get top;

  // Methods.
  /**
   * Closes the window.
   *
   * This method should only succeed if the [WindowBase] object is
   * **script-closeable** and the window calling [close] is allowed to navigate
   * the window.
   *
   * A window is script-closeable if it is either a window
   * that was opened by another window, or if it is a window with only one
   * document in its history.
   *
   * A window might not be allowed to navigate, and therefore close, another
   * window due to browser security features.
   *
   *     var other = window.open('http://www.example.com', 'foo');
   *     // Closes other window, as it is script-closeable.
   *     other.close();
   *     print(other.closed()); // 'true'
   *
   *     window.location('http://www.mysite.com', 'foo');
   *     // Does not close this window, as the history has changed.
   *     window.close();
   *     print(window.closed()); // 'false'
   *
   * See also:
   *
   * * [Window close discussion](http://www.w3.org/TR/html5/browsers.html#dom-window-close) from the W3C
   */
  void close();
  void postMessage(var message, String targetOrigin, [List messagePorts]);
}

abstract class LocationBase {
  void set href(String val);
}

abstract class HistoryBase {
  void back();
  void forward();
  void go(int distance);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


abstract class CssClassSet implements Set<String> {

  String toString() {
    return Strings.join(new List.from(readClasses()), ' ');
  }

  /**
   * Adds the class [token] to the element if it is not on it, removes it if it
   * is.
   */
  bool toggle(String value) {
    Set<String> s = readClasses();
    bool result = false;
    if (s.contains(value)) {
      s.remove(value);
    } else {
      s.add(value);
      result = true;
    }
    writeClasses(s);
    return result;
  }

  /**
   * Returns [:true:] if classes cannot be added or removed from this
   * [:CssClassSet:].
   */
  bool get frozen => false;

  // interface Iterable - BEGIN
  Iterator<String> get iterator => readClasses().iterator;
  // interface Iterable - END

  // interface Collection - BEGIN
  void forEach(void f(String element)) {
    readClasses().forEach(f);
  }

  String join([String separator]) => readClasses().join(separator);

  Iterable mappedBy(f(String element)) => readClasses().mappedBy(f);

  Iterable<String> where(bool f(String element)) => readClasses().where(f);

  bool every(bool f(String element)) => readClasses().every(f);

  bool any(bool f(String element)) => readClasses().any(f);

  bool get isEmpty => readClasses().isEmpty;

  int get length =>readClasses().length;

  dynamic reduce(dynamic initialValue,
      dynamic combine(dynamic previousValue, String element)) {
    return readClasses().reduce(initialValue, combine);
  }
  // interface Collection - END

  // interface Set - BEGIN
  bool contains(String value) => readClasses().contains(value);

  void add(String value) {
    // TODO - figure out if we need to do any validation here
    // or if the browser natively does enough.
    _modify((s) => s.add(value));
  }

  bool remove(Object value) {
    if (value is! String) return false;
    Set<String> s = readClasses();
    bool result = s.remove(value);
    writeClasses(s);
    return result;
  }

  void addAll(Iterable<String> iterable) {
    // TODO - see comment above about validation.
    _modify((s) => s.addAll(iterable));
  }

  void removeAll(Iterable<String> iterable) {
    _modify((s) => s.removeAll(iterable));
  }

  void retainAll(Iterable<String> iterable) {
    _modify((s) => s.retainAll(iterable));
  }

  void removeMatching(bool test(String name)) {
    _modify((s) => s.removeMatching(test));
  }

  void retainMatching(bool test(String name)) {
    _modify((s) => s.retainMatching(test));
  }

  bool isSubsetOf(Collection<String> collection) =>
    readClasses().isSubsetOf(collection);

  bool containsAll(Collection<String> collection) =>
    readClasses().containsAll(collection);

  Set<String> intersection(Collection<String> other) =>
    readClasses().intersection(other);

  String get first => readClasses().first;
  String get last => readClasses().last;
  String get single => readClasses().single;
  List<String> toList() => readClasses().toList();
  Set<String> toSet() => readClasses().toSet();
  String min([int compare(String a, String b)]) =>
      readClasses().min(compare);
  String max([int compare(String a, String b)]) =>
      readClasses().max(compare);
  Iterable<String> take(int n) => readClasses().take(n);
  Iterable<String> takeWhile(bool test(String value)) =>
      readClasses().takeWhile(test);
  Iterable<String> skip(int n) => readClasses().skip(n);
  Iterable<String> skipWhile(bool test(String value)) =>
      readClasses().skipWhile(test);
  String firstMatching(bool test(String value), { String orElse() }) =>
      readClasses().firstMatching(test, orElse: orElse);
  String lastMatching(bool test(String value), {String orElse()}) =>
      readClasses().lastMatching(test, orElse: orElse);
  String singleMatching(bool test(String value)) =>
      readClasses().singleMatching(test);
  String elementAt(int index) => readClasses().elementAt(index);

  void clear() {
    _modify((s) => s.clear());
  }
  // interface Set - END

  /**
   * Helper method used to modify the set of css classes on this element.
   *
   *   f - callback with:
   *      s - a Set of all the css class name currently on this element.
   *
   *   After f returns, the modified set is written to the
   *       className property of this element.
   */
  void _modify( f(Set<String> s)) {
    Set<String> s = readClasses();
    f(s);
    writeClasses(s);
  }

  /**
   * Read the class names from the Element class property,
   * and put them into a set (duplicates are discarded).
   * This is intended to be overridden by specific implementations.
   */
  Set<String> readClasses();

  /**
   * Join all the elements of a set into one string and write
   * back to the element.
   * This is intended to be overridden by specific implementations.
   */
  void writeClasses(Set<String> s);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Utils for device detection.
 */
class _Device {
  /**
   * Gets the browser's user agent. Using this function allows tests to inject
   * the user agent.
   * Returns the user agent.
   */
  static String get userAgent => window.navigator.userAgent;

  /**
   * Determines if the current device is running Opera.
   */
  static bool get isOpera => userAgent.contains("Opera", 0);

  /**
   * Determines if the current device is running Internet Explorer.
   */
  static bool get isIE => !isOpera && userAgent.contains("MSIE", 0);

  /**
   * Determines if the current device is running Firefox.
   */
  static bool get isFirefox => userAgent.contains("Firefox", 0);

  /**
   * Determines if the current device is running WebKit.
   */
  static bool get isWebKit => !isOpera && userAgent.contains("WebKit", 0);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


typedef void EventListener(Event event);
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Adapter for exposing DOM events as Dart streams.
 */
class _EventStream<T extends Event> extends Stream<T> {
  final EventTarget _target;
  final String _eventType;
  final bool _useCapture;

  _EventStream(this._target, this._eventType, this._useCapture);

  // DOM events are inherently multi-subscribers.
  Stream<T> asBroadcastStream() => this;

  StreamSubscription<T> listen(void onData(T event),
      { void onError(AsyncError error),
      void onDone(),
      bool unsubscribeOnError}) {

    return new _EventStreamSubscription<T>(
        this._target, this._eventType, onData, this._useCapture);
  }
}

class _EventStreamSubscription<T extends Event> extends StreamSubscription<T> {
  int _pauseCount = 0;
  EventTarget _target;
  final String _eventType;
  var _onData;
  final bool _useCapture;

  _EventStreamSubscription(this._target, this._eventType, this._onData,
      this._useCapture) {
    _tryResume();
  }

  void cancel() {
    if (_canceled) {
      throw new StateError("Subscription has been canceled.");
    }

    _unlisten();
    // Clear out the target to indicate this is complete.
    _target = null;
    _onData = null;
  }

  bool get _canceled => _target == null;

  void onData(void handleData(T event)) {
    if (_canceled) {
      throw new StateError("Subscription has been canceled.");
    }
    // Remove current event listener.
    _unlisten();

    _onData = handleData;
    _tryResume();
  }

  /// Has no effect.
  void onError(void handleError(AsyncError error)) {}

  /// Has no effect.
  void onDone(void handleDone()) {}

  void pause([Future resumeSignal]) {
    if (_canceled) {
      throw new StateError("Subscription has been canceled.");
    }
    ++_pauseCount;
    _unlisten();

    if (resumeSignal != null) {
      resumeSignal.whenComplete(resume);
    }
  }

  bool get _paused => _pauseCount > 0;

  void resume() {
    if (_canceled) {
      throw new StateError("Subscription has been canceled.");
    }
    if (!_paused) {
      throw new StateError("Subscription is not paused.");
    }
    --_pauseCount;
    _tryResume();
  }

  void _tryResume() {
    if (_onData != null && !_paused) {
      _target.$dom_addEventListener(_eventType, _onData, _useCapture);
    }
  }

  void _unlisten() {
    if (_onData != null) {
      _target.$dom_removeEventListener(_eventType, _onData, _useCapture);
    }
  }
}


/**
 * A factory to expose DOM events as Streams.
 */
class EventStreamProvider<T extends Event> {
  final String _eventType;

  const EventStreamProvider(this._eventType);

  /**
   * Gets a [Stream] for this event type, on the specified target.
   *
   * This may be used to capture DOM events:
   *
   *     Element.keyDownEvent.forTarget(element, useCapture: true).listen(...);
   *
   * Or for listening to an event which will bubble through the DOM tree:
   *
   *     MediaElement.pauseEvent.forTarget(document.body).listen(...);
   *
   * See also:
   *
   * [addEventListener](http://docs.webplatform.org/wiki/dom/methods/addEventListener)
   */
  Stream<T> forTarget(EventTarget e, {bool useCapture: false}) {
    return new _EventStream(e, _eventType, useCapture);
  }
}

/**
 * A factory to expose DOM events as streams, where the DOM event name has to
 * be determined on the fly (for example, mouse wheel events).
 */
class _CustomEventStreamProvider<T extends Event>
    implements EventStreamProvider<T> {

  final _eventTypeGetter;
  const _CustomEventStreamProvider(this._eventTypeGetter);

  Stream<T> forTarget(EventTarget e, {bool useCapture: false}) {
    return new _EventStream(e, _eventTypeGetter(e), useCapture);
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Works with KeyboardEvent and KeyEvent to determine how to expose information
 * about Key(board)Events. This class functions like an EventListenerList, and
 * provides a consistent interface for the Dart
 * user, despite the fact that a multitude of browsers that have varying
 * keyboard default behavior.
 *
 * This class is very much a work in progress, and we'd love to get information
 * on how we can make this class work with as many international keyboards as
 * possible. Bugs welcome!
 */
class KeyboardEventController {
  // This code inspired by Closure's KeyHandling library.
  // http://closure-library.googlecode.com/svn/docs/closure_goog_events_keyhandler.js.source.html

  /**
   * The set of keys that have been pressed down without seeing their
   * corresponding keyup event.
   */
  List<KeyboardEvent> _keyDownList;

  /** The set of functions that wish to be notified when a KeyEvent happens. */
  List<Function> _callbacks;

  /** The type of KeyEvent we are tracking (keyup, keydown, keypress). */
  String _type;

  /** The element we are watching for events to happen on. */
  EventTarget _target;

  // The distance to shift from upper case alphabet Roman letters to lower case.
  final int _ROMAN_ALPHABET_OFFSET = "a".charCodes[0] - "A".charCodes[0];

  StreamSubscription _keyUpSubscription, _keyDownSubscription,
      _keyPressSubscription;

  /**
   * An enumeration of key identifiers currently part of the W3C draft for DOM3
   * and their mappings to keyCodes.
   * http://www.w3.org/TR/DOM-Level-3-Events/keyset.html#KeySet-Set
   */
  static Map<String, int> _keyIdentifier = {
    'Up': KeyCode.UP,
    'Down': KeyCode.DOWN,
    'Left': KeyCode.LEFT,
    'Right': KeyCode.RIGHT,
    'Enter': KeyCode.ENTER,
    'F1': KeyCode.F1,
    'F2': KeyCode.F2,
    'F3': KeyCode.F3,
    'F4': KeyCode.F4,
    'F5': KeyCode.F5,
    'F6': KeyCode.F6,
    'F7': KeyCode.F7,
    'F8': KeyCode.F8,
    'F9': KeyCode.F9,
    'F10': KeyCode.F10,
    'F11': KeyCode.F11,
    'F12': KeyCode.F12,
    'U+007F': KeyCode.DELETE,
    'Home': KeyCode.HOME,
    'End': KeyCode.END,
    'PageUp': KeyCode.PAGE_UP,
    'PageDown': KeyCode.PAGE_DOWN,
    'Insert': KeyCode.INSERT
  };

  /** Named constructor to add an onKeyPress event listener to our handler. */
  KeyboardEventController.keypress(EventTarget target) {
    _KeyboardEventController(target, 'keypress');
  }

  /** Named constructor to add an onKeyUp event listener to our handler. */
  KeyboardEventController.keyup(EventTarget target) {
    _KeyboardEventController(target, 'keyup');
  }

  /** Named constructor to add an onKeyDown event listener to our handler. */
  KeyboardEventController.keydown(EventTarget target) {
    _KeyboardEventController(target, 'keydown');
  }

  /**
   * General constructor, performs basic initialization for our improved
   * KeyboardEvent controller.
   */
  _KeyboardEventController(EventTarget target, String type) {
    _callbacks = [];
    _type = type;
    _target = target;
  }

  /**
   * Hook up all event listeners under the covers so we can estimate keycodes
   * and charcodes when they are not provided.
   */
  void _initializeAllEventListeners() {
    _keyDownList = [];
    if (_keyDownSubscription == null) {
      _keyDownSubscription = Element.keyDownEvent.forTarget(
          _target, useCapture: true).listen(processKeyDown);
      _keyPressSubscription = Element.keyPressEvent.forTarget(
          _target, useCapture: true).listen(processKeyUp);
      _keyUpSubscription = Element.keyUpEvent.forTarget(
          _target, useCapture: true).listen(processKeyPress);
    }
  }

  /** Add a callback that wishes to be notified when a KeyEvent occurs. */
  void add(void callback(KeyEvent)) {
    if (_callbacks.length == 0) {
      _initializeAllEventListeners();
    }
    _callbacks.add(callback);
  }

  /**
   * Notify all callback listeners that a KeyEvent of the relevant type has
   * occurred.
   */
  bool _dispatch(KeyEvent event) {
    if (event.type == _type) {
      // Make a copy of the listeners in case a callback gets removed while
      // dispatching from the list.
      List callbacksCopy = new List.from(_callbacks);
      for(var callback in callbacksCopy) {
        callback(event);
      }
    }
  }

  /** Remove the given callback from the listeners list. */
  void remove(void callback(KeyEvent)) {
    var index = _callbacks.indexOf(callback);
    if (index != -1) {
      _callbacks.removeAt(index);
    }
    if (_callbacks.length == 0) {
      // If we have no listeners, don't bother keeping track of keypresses.
      _keyDownSubscription.cancel();
      _keyDownSubscription = null;
      _keyPressSubscription.cancel();
      _keyPressSubscription = null;
      _keyUpSubscription.cancel();
      _keyUpSubscription = null;
    }
  }

  /** Determine if caps lock is one of the currently depressed keys. */
  bool get _capsLockOn =>
      _keyDownList.any((var element) => element.keyCode == KeyCode.CAPS_LOCK);

  /**
   * Given the previously recorded keydown key codes, see if we can determine
   * the keycode of this keypress [event]. (Generally browsers only provide
   * charCode information for keypress events, but with a little
   * reverse-engineering, we can also determine the keyCode.) Returns
   * KeyCode.UNKNOWN if the keycode could not be determined.
   */
  int _determineKeyCodeForKeypress(KeyboardEvent event) {
    // Note: This function is a work in progress. We'll expand this function
    // once we get more information about other keyboards.
    for (var prevEvent in _keyDownList) {
      if (prevEvent._shadowCharCode == event.charCode) {
        return prevEvent.keyCode;
      }
      if ((event.shiftKey || _capsLockOn) && event.charCode >= "A".charCodes[0]
          && event.charCode <= "Z".charCodes[0] && event.charCode +
          _ROMAN_ALPHABET_OFFSET == prevEvent._shadowCharCode) {
        return prevEvent.keyCode;
      }
    }
    return KeyCode.UNKNOWN;
  }

  /**
   * Given the charater code returned from a keyDown [event], try to ascertain
   * and return the corresponding charCode for the character that was pressed.
   * This information is not shown to the user, but used to help polyfill
   * keypress events.
   */
  int _findCharCodeKeyDown(KeyboardEvent event) {
    if (event.keyLocation == 3) { // Numpad keys.
      switch (event.keyCode) {
        case KeyCode.NUM_ZERO:
          // Even though this function returns _charCodes_, for some cases the
          // KeyCode == the charCode we want, in which case we use the keycode
          // constant for readability.
          return KeyCode.ZERO;
        case KeyCode.NUM_ONE:
          return KeyCode.ONE;
        case KeyCode.NUM_TWO:
          return KeyCode.TWO;
        case KeyCode.NUM_THREE:
          return KeyCode.THREE;
        case KeyCode.NUM_FOUR:
          return KeyCode.FOUR;
        case KeyCode.NUM_FIVE:
          return KeyCode.FIVE;
        case KeyCode.NUM_SIX:
          return KeyCode.SIX;
        case KeyCode.NUM_SEVEN:
          return KeyCode.SEVEN;
        case KeyCode.NUM_EIGHT:
          return KeyCode.EIGHT;
        case KeyCode.NUM_NINE:
          return KeyCode.NINE;
        case KeyCode.NUM_MULTIPLY:
          return 42; // Char code for *
        case KeyCode.NUM_PLUS:
          return 43; // +
        case KeyCode.NUM_MINUS:
          return 45; // -
        case KeyCode.NUM_PERIOD:
          return 46; // .
        case KeyCode.NUM_DIVISION:
          return 47; // /
      }
    } else if (event.keyCode >= 65 && event.keyCode <= 90) {
      // Set the "char code" for key down as the lower case letter. Again, this
      // will not show up for the user, but will be helpful in estimating
      // keyCode locations and other information during the keyPress event.
      return event.keyCode + _ROMAN_ALPHABET_OFFSET;
    }
    switch(event.keyCode) {
      case KeyCode.SEMICOLON:
        return KeyCode.FF_SEMICOLON;
      case KeyCode.EQUALS:
        return KeyCode.FF_EQUALS;
      case KeyCode.COMMA:
        return 44; // Ascii value for ,
      case KeyCode.DASH:
        return 45; // -
      case KeyCode.PERIOD:
        return 46; // .
      case KeyCode.SLASH:
        return 47; // /
      case KeyCode.APOSTROPHE:
        return 96; // `
      case KeyCode.OPEN_SQUARE_BRACKET:
        return 91; // [
      case KeyCode.BACKSLASH:
        return 92; // \
      case KeyCode.CLOSE_SQUARE_BRACKET:
        return 93; // ]
      case KeyCode.SINGLE_QUOTE:
        return 39; // '
    }
    return event.keyCode;
  }

  /**
   * Returns true if the key fires a keypress event in the current browser.
   */
  bool _firesKeyPressEvent(KeyEvent event) {
    if (!_Device.isIE && !_Device.isWebKit) {
      return true;
    }

    if (_Device.userAgent.contains('Mac') && event.altKey) {
      return KeyCode.isCharacterKey(event.keyCode);
    }

    // Alt but not AltGr which is represented as Alt+Ctrl.
    if (event.altKey && !event.ctrlKey) {
      return false;
    }

    // Saves Ctrl or Alt + key for IE and WebKit, which won't fire keypress.
    if (!event.shiftKey &&
        (_keyDownList.last.keyCode == KeyCode.CTRL ||
         _keyDownList.last.keyCode == KeyCode.ALT ||
         _Device.userAgent.contains('Mac') &&
         _keyDownList.last.keyCode == KeyCode.META)) {
      return false;
    }

    // Some keys with Ctrl/Shift do not issue keypress in WebKit.
    if (_Device.isWebKit && event.ctrlKey && event.shiftKey && (
        event.keyCode == KeyCode.BACKSLASH ||
        event.keyCode == KeyCode.OPEN_SQUARE_BRACKET ||
        event.keyCode == KeyCode.CLOSE_SQUARE_BRACKET ||
        event.keyCode == KeyCode.TILDE ||
        event.keyCode == KeyCode.SEMICOLON || event.keyCode == KeyCode.DASH ||
        event.keyCode == KeyCode.EQUALS || event.keyCode == KeyCode.COMMA ||
        event.keyCode == KeyCode.PERIOD || event.keyCode == KeyCode.SLASH ||
        event.keyCode == KeyCode.APOSTROPHE ||
        event.keyCode == KeyCode.SINGLE_QUOTE)) {
      return false;
    }

    switch (event.keyCode) {
      case KeyCode.ENTER:
        // IE9 does not fire keypress on ENTER.
        return !_Device.isIE;
      case KeyCode.ESC:
        return !_Device.isWebKit;
    }

    return KeyCode.isCharacterKey(event.keyCode);
  }

  /**
   * Normalize the keycodes to the IE KeyCodes (this is what Chrome, IE, and
   * Opera all use).
   */
  int _normalizeKeyCodes(KeyboardEvent event) {
    // Note: This may change once we get input about non-US keyboards.
    if (_Device.isFirefox) {
      switch(event.keyCode) {
        case KeyCode.FF_EQUALS:
          return KeyCode.EQUALS;
        case KeyCode.FF_SEMICOLON:
          return KeyCode.SEMICOLON;
        case KeyCode.MAC_FF_META:
          return KeyCode.META;
        case KeyCode.WIN_KEY_FF_LINUX:
          return KeyCode.WIN_KEY;
      }
    }
    return event.keyCode;
  }

  /** Handle keydown events. */
  void processKeyDown(KeyboardEvent e) {
    // Ctrl-Tab and Alt-Tab can cause the focus to be moved to another window
    // before we've caught a key-up event.  If the last-key was one of these
    // we reset the state.
    if (_keyDownList.length > 0 &&
        (_keyDownList.last.keyCode == KeyCode.CTRL && !e.ctrlKey ||
         _keyDownList.last.keyCode == KeyCode.ALT && !e.altKey ||
         _Device.userAgent.contains('Mac') &&
         _keyDownList.last.keyCode == KeyCode.META && !e.metaKey)) {
      _keyDownList = [];
    }

    var event = new KeyEvent(e);
    event._shadowKeyCode = _normalizeKeyCodes(event);
    // Technically a "keydown" event doesn't have a charCode. This is
    // calculated nonetheless to provide us with more information in giving
    // as much information as possible on keypress about keycode and also
    // charCode.
    event._shadowCharCode = _findCharCodeKeyDown(event);
    if (_keyDownList.length > 0 && event.keyCode != _keyDownList.last.keyCode &&
        !_firesKeyPressEvent(event)) {
      // Some browsers have quirks not firing keypress events where all other
      // browsers do. This makes them more consistent.
      processKeyPress(event);
    }
    _keyDownList.add(event);
    _dispatch(event);
  }

  /** Handle keypress events. */
  void processKeyPress(KeyboardEvent event) {
    var e = new KeyEvent(event);
    // IE reports the character code in the keyCode field for keypress events.
    // There are two exceptions however, Enter and Escape.
    if (_Device.isIE) {
      if (e.keyCode == KeyCode.ENTER || e.keyCode == KeyCode.ESC) {
        e._shadowCharCode = 0;
      } else {
        e._shadowCharCode = e.keyCode;
      }
    } else if (_Device.isOpera) {
      // Opera reports the character code in the keyCode field.
      e._shadowCharCode = KeyCode.isCharacterKey(e.keyCode) ? e.keyCode : 0;
    }
    // Now we guestimate about what the keycode is that was actually
    // pressed, given previous keydown information.
    e._shadowKeyCode = _determineKeyCodeForKeypress(e);

    // Correct the key value for certain browser-specific quirks.
    if (e._shadowKeyIdentifier != null &&
        _keyIdentifier.containsKey(e._shadowKeyIdentifier)) {
      // This is needed for Safari Windows because it currently doesn't give a
      // keyCode/which for non printable keys.
      e._shadowKeyCode = _keyIdentifier[e._shadowKeyIdentifier];
    }
    e._shadowAltKey = _keyDownList.any((var element) => element.altKey);
    _dispatch(e);
  }

  /** Handle keyup events. */
  void processKeyUp(KeyboardEvent event) {
    var e = new KeyEvent(event);
    KeyboardEvent toRemove = null;
    for (var key in _keyDownList) {
      if (key.keyCode == e.keyCode) {
        toRemove = key;
      }
    }
    if (toRemove != null) {
      _keyDownList =
          _keyDownList.where((element) => element != toRemove).toList();
    } else if (_keyDownList.length > 0) {
      // This happens when we've reached some international keyboard case we
      // haven't accounted for or we haven't correctly eliminated all browser
      // inconsistencies. Filing bugs on when this is reached is welcome!
      _keyDownList.removeLast();
    }
    _dispatch(e);
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Defines the keycode values for keys that are returned by 
 * KeyboardEvent.keyCode.
 * 
 * Important note: There is substantial divergence in how different browsers
 * handle keycodes and their variants in different locales/keyboard layouts. We
 * provide these constants to help make code processing keys more readable.
 */
abstract class KeyCode {
  // These constant names were borrowed from Closure's Keycode enumeration
  // class.
  // http://closure-library.googlecode.com/svn/docs/closure_goog_events_keycodes.js.source.html  
  static const int WIN_KEY_FF_LINUX = 0;
  static const int MAC_ENTER = 3;
  static const int BACKSPACE = 8;
  static const int TAB = 9;
  /** NUM_CENTER is also NUMLOCK for FF and Safari on Mac. */
  static const int NUM_CENTER = 12;
  static const int ENTER = 13;
  static const int SHIFT = 16;
  static const int CTRL = 17;
  static const int ALT = 18;
  static const int PAUSE = 19;
  static const int CAPS_LOCK = 20;
  static const int ESC = 27;
  static const int SPACE = 32;
  static const int PAGE_UP = 33;
  static const int PAGE_DOWN = 34;
  static const int END = 35;
  static const int HOME = 36;
  static const int LEFT = 37;
  static const int UP = 38;
  static const int RIGHT = 39;
  static const int DOWN = 40;
  static const int NUM_NORTH_EAST = 33;
  static const int NUM_SOUTH_EAST = 34;
  static const int NUM_SOUTH_WEST = 35;
  static const int NUM_NORTH_WEST = 36;
  static const int NUM_WEST = 37;
  static const int NUM_NORTH = 38;
  static const int NUM_EAST = 39;
  static const int NUM_SOUTH = 40;
  static const int PRINT_SCREEN = 44;
  static const int INSERT = 45;
  static const int NUM_INSERT = 45;
  static const int DELETE = 46;
  static const int NUM_DELETE = 46;
  static const int ZERO = 48;
  static const int ONE = 49;
  static const int TWO = 50;
  static const int THREE = 51;
  static const int FOUR = 52;
  static const int FIVE = 53;
  static const int SIX = 54;
  static const int SEVEN = 55;
  static const int EIGHT = 56;
  static const int NINE = 57;
  static const int FF_SEMICOLON = 59;
  static const int FF_EQUALS = 61;
  /**
   * CAUTION: The question mark is for US-keyboard layouts. It varies
   * for other locales and keyboard layouts.
   */
  static const int QUESTION_MARK = 63;
  static const int A = 65;
  static const int B = 66;
  static const int C = 67;
  static const int D = 68;
  static const int E = 69;
  static const int F = 70;
  static const int G = 71;
  static const int H = 72;
  static const int I = 73;
  static const int J = 74;
  static const int K = 75;
  static const int L = 76;
  static const int M = 77;
  static const int N = 78;
  static const int O = 79;
  static const int P = 80;
  static const int Q = 81;
  static const int R = 82;
  static const int S = 83;
  static const int T = 84;
  static const int U = 85;
  static const int V = 86;
  static const int W = 87;
  static const int X = 88;
  static const int Y = 89;
  static const int Z = 90;
  static const int META = 91;
  static const int WIN_KEY_LEFT = 91;
  static const int WIN_KEY_RIGHT = 92;
  static const int CONTEXT_MENU = 93;
  static const int NUM_ZERO = 96;
  static const int NUM_ONE = 97;
  static const int NUM_TWO = 98;
  static const int NUM_THREE = 99;
  static const int NUM_FOUR = 100;
  static const int NUM_FIVE = 101;
  static const int NUM_SIX = 102;
  static const int NUM_SEVEN = 103;
  static const int NUM_EIGHT = 104;
  static const int NUM_NINE = 105;
  static const int NUM_MULTIPLY = 106;
  static const int NUM_PLUS = 107;
  static const int NUM_MINUS = 109;
  static const int NUM_PERIOD = 110;
  static const int NUM_DIVISION = 111;
  static const int F1 = 112;
  static const int F2 = 113;
  static const int F3 = 114;
  static const int F4 = 115;
  static const int F5 = 116;
  static const int F6 = 117;
  static const int F7 = 118;
  static const int F8 = 119;
  static const int F9 = 120;
  static const int F10 = 121;
  static const int F11 = 122;
  static const int F12 = 123;
  static const int NUMLOCK = 144;
  static const int SCROLL_LOCK = 145;

  // OS-specific media keys like volume controls and browser controls.
  static const int FIRST_MEDIA_KEY = 166;
  static const int LAST_MEDIA_KEY = 183;

  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int SEMICOLON = 186;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int DASH = 189;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int EQUALS = 187;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int COMMA = 188;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int PERIOD = 190;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int SLASH = 191;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int APOSTROPHE = 192;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int TILDE = 192;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int SINGLE_QUOTE = 222;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int OPEN_SQUARE_BRACKET = 219;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int BACKSLASH = 220;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int CLOSE_SQUARE_BRACKET = 221;
  static const int WIN_KEY = 224;
  static const int MAC_FF_META = 224;
  static const int WIN_IME = 229;

  /** A sentinel value if the keycode could not be determined. */
  static const int UNKNOWN = -1;

  /**
   * Returns true if the keyCode produces a (US keyboard) character.
   * Note: This does not (yet) cover characters on non-US keyboards (Russian,
   * Hebrew, etc.).
   */
  static bool isCharacterKey(int keyCode) {
    if ((keyCode >= ZERO && keyCode <= NINE) ||
        (keyCode >= NUM_ZERO && keyCode <= NUM_MULTIPLY) ||
        (keyCode >= A && keyCode <= Z)) {
      return true;
    }
 
    // Safari sends zero key code for non-latin characters.
    if (_Device.isWebKit && keyCode == 0) {
      return true;
    }
 
    return (keyCode == SPACE || keyCode == QUESTION_MARK || keyCode == NUM_PLUS
        || keyCode == NUM_MINUS || keyCode == NUM_PERIOD ||
        keyCode == NUM_DIVISION || keyCode == SEMICOLON ||
        keyCode == FF_SEMICOLON || keyCode == DASH || keyCode == EQUALS ||
        keyCode == FF_EQUALS || keyCode == COMMA || keyCode == PERIOD ||
        keyCode == SLASH || keyCode == APOSTROPHE || keyCode == SINGLE_QUOTE ||
        keyCode == OPEN_SQUARE_BRACKET || keyCode == BACKSLASH ||
        keyCode == CLOSE_SQUARE_BRACKET);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Defines the standard key locations returned by
 * KeyboardEvent.getKeyLocation.
 */
abstract class KeyLocation {

  /**
   * The event key is not distinguished as the left or right version
   * of the key, and did not originate from the numeric keypad (or did not
   * originate with a virtual key corresponding to the numeric keypad).
   */
  static const int STANDARD = 0;

  /**
   * The event key is in the left key location.
   */
  static const int LEFT = 1;

  /**
   * The event key is in the right key location.
   */
  static const int RIGHT = 2;

  /**
   * The event key originated on the numeric keypad or with a virtual key
   * corresponding to the numeric keypad.
   */
  static const int NUMPAD = 3;

  /**
   * The event key originated on a mobile device, either on a physical
   * keypad or a virtual keyboard.
   */
  static const int MOBILE = 4;

  /**
   * The event key originated on a game controller or a joystick on a mobile
   * device.
   */
  static const int JOYSTICK = 5;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Defines the standard keyboard identifier names for keys that are returned
 * by KeyEvent.getKeyboardIdentifier when the key does not have a direct
 * unicode mapping.
 */
abstract class KeyName {

  /** The Accept (Commit, OK) key */
  static const String ACCEPT = "Accept";

  /** The Add key */
  static const String ADD = "Add";

  /** The Again key */
  static const String AGAIN = "Again";

  /** The All Candidates key */
  static const String ALL_CANDIDATES = "AllCandidates";

  /** The Alphanumeric key */
  static const String ALPHANUMERIC = "Alphanumeric";

  /** The Alt (Menu) key */
  static const String ALT = "Alt";

  /** The Alt-Graph key */
  static const String ALT_GRAPH = "AltGraph";

  /** The Application key */
  static const String APPS = "Apps";

  /** The ATTN key */
  static const String ATTN = "Attn";

  /** The Browser Back key */
  static const String BROWSER_BACK = "BrowserBack";

  /** The Browser Favorites key */
  static const String BROWSER_FAVORTIES = "BrowserFavorites";

  /** The Browser Forward key */
  static const String BROWSER_FORWARD = "BrowserForward";

  /** The Browser Home key */
  static const String BROWSER_NAME = "BrowserHome";

  /** The Browser Refresh key */
  static const String BROWSER_REFRESH = "BrowserRefresh";

  /** The Browser Search key */
  static const String BROWSER_SEARCH = "BrowserSearch";

  /** The Browser Stop key */
  static const String BROWSER_STOP = "BrowserStop";

  /** The Camera key */
  static const String CAMERA = "Camera";

  /** The Caps Lock (Capital) key */
  static const String CAPS_LOCK = "CapsLock";

  /** The Clear key */
  static const String CLEAR = "Clear";

  /** The Code Input key */
  static const String CODE_INPUT = "CodeInput";

  /** The Compose key */
  static const String COMPOSE = "Compose";

  /** The Control (Ctrl) key */
  static const String CONTROL = "Control";

  /** The Crsel key */
  static const String CRSEL = "Crsel";

  /** The Convert key */
  static const String CONVERT = "Convert";

  /** The Copy key */
  static const String COPY = "Copy";

  /** The Cut key */
  static const String CUT = "Cut";

  /** The Decimal key */
  static const String DECIMAL = "Decimal";

  /** The Divide key */
  static const String DIVIDE = "Divide";

  /** The Down Arrow key */
  static const String DOWN = "Down";

  /** The diagonal Down-Left Arrow key */
  static const String DOWN_LEFT = "DownLeft";

  /** The diagonal Down-Right Arrow key */
  static const String DOWN_RIGHT = "DownRight";

  /** The Eject key */
  static const String EJECT = "Eject";

  /** The End key */
  static const String END = "End";

  /**
   * The Enter key. Note: This key value must also be used for the Return
   *  (Macintosh numpad) key
   */
  static const String ENTER = "Enter";

  /** The Erase EOF key */
  static const String ERASE_EOF= "EraseEof";

  /** The Execute key */
  static const String EXECUTE = "Execute";

  /** The Exsel key */
  static const String EXSEL = "Exsel";

  /** The Function switch key */
  static const String FN = "Fn";

  /** The F1 key */
  static const String F1 = "F1";

  /** The F2 key */
  static const String F2 = "F2";

  /** The F3 key */
  static const String F3 = "F3";

  /** The F4 key */
  static const String F4 = "F4";

  /** The F5 key */
  static const String F5 = "F5";

  /** The F6 key */
  static const String F6 = "F6";

  /** The F7 key */
  static const String F7 = "F7";

  /** The F8 key */
  static const String F8 = "F8";

  /** The F9 key */
  static const String F9 = "F9";

  /** The F10 key */
  static const String F10 = "F10";

  /** The F11 key */
  static const String F11 = "F11";

  /** The F12 key */
  static const String F12 = "F12";

  /** The F13 key */
  static const String F13 = "F13";

  /** The F14 key */
  static const String F14 = "F14";

  /** The F15 key */
  static const String F15 = "F15";

  /** The F16 key */
  static const String F16 = "F16";

  /** The F17 key */
  static const String F17 = "F17";

  /** The F18 key */
  static const String F18 = "F18";

  /** The F19 key */
  static const String F19 = "F19";

  /** The F20 key */
  static const String F20 = "F20";

  /** The F21 key */
  static const String F21 = "F21";

  /** The F22 key */
  static const String F22 = "F22";

  /** The F23 key */
  static const String F23 = "F23";

  /** The F24 key */
  static const String F24 = "F24";

  /** The Final Mode (Final) key used on some asian keyboards */
  static const String FINAL_MODE = "FinalMode";

  /** The Find key */
  static const String FIND = "Find";

  /** The Full-Width Characters key */
  static const String FULL_WIDTH = "FullWidth";

  /** The Half-Width Characters key */
  static const String HALF_WIDTH = "HalfWidth";

  /** The Hangul (Korean characters) Mode key */
  static const String HANGUL_MODE = "HangulMode";

  /** The Hanja (Korean characters) Mode key */
  static const String HANJA_MODE = "HanjaMode";

  /** The Help key */
  static const String HELP = "Help";

  /** The Hiragana (Japanese Kana characters) key */
  static const String HIRAGANA = "Hiragana";

  /** The Home key */
  static const String HOME = "Home";

  /** The Insert (Ins) key */
  static const String INSERT = "Insert";

  /** The Japanese-Hiragana key */
  static const String JAPANESE_HIRAGANA = "JapaneseHiragana";

  /** The Japanese-Katakana key */
  static const String JAPANESE_KATAKANA = "JapaneseKatakana";

  /** The Japanese-Romaji key */
  static const String JAPANESE_ROMAJI = "JapaneseRomaji";

  /** The Junja Mode key */
  static const String JUNJA_MODE = "JunjaMode";

  /** The Kana Mode (Kana Lock) key */
  static const String KANA_MODE = "KanaMode";

  /**
   * The Kanji (Japanese name for ideographic characters of Chinese origin)
   * Mode key
   */
  static const String KANJI_MODE = "KanjiMode";

  /** The Katakana (Japanese Kana characters) key */
  static const String KATAKANA = "Katakana";

  /** The Start Application One key */
  static const String LAUNCH_APPLICATION_1 = "LaunchApplication1";

  /** The Start Application Two key */
  static const String LAUNCH_APPLICATION_2 = "LaunchApplication2";

  /** The Start Mail key */
  static const String LAUNCH_MAIL = "LaunchMail";

  /** The Left Arrow key */
  static const String LEFT = "Left";

  /** The Menu key */
  static const String MENU = "Menu";

  /**
   * The Meta key. Note: This key value shall be also used for the Apple
   * Command key
   */
  static const String META = "Meta";

  /** The Media Next Track key */
  static const String MEDIA_NEXT_TRACK = "MediaNextTrack";

  /** The Media Play Pause key */
  static const String MEDIA_PAUSE_PLAY = "MediaPlayPause";

  /** The Media Previous Track key */
  static const String MEDIA_PREVIOUS_TRACK = "MediaPreviousTrack";

  /** The Media Stop key */
  static const String MEDIA_STOP = "MediaStop";

  /** The Mode Change key */
  static const String MODE_CHANGE = "ModeChange";

  /** The Next Candidate function key */
  static const String NEXT_CANDIDATE = "NextCandidate";

  /** The Nonconvert (Don't Convert) key */
  static const String NON_CONVERT = "Nonconvert";

  /** The Number Lock key */
  static const String NUM_LOCK = "NumLock";

  /** The Page Down (Next) key */
  static const String PAGE_DOWN = "PageDown";

  /** The Page Up key */
  static const String PAGE_UP = "PageUp";

  /** The Paste key */
  static const String PASTE = "Paste";

  /** The Pause key */
  static const String PAUSE = "Pause";

  /** The Play key */
  static const String PLAY = "Play";

  /**
   * The Power key. Note: Some devices may not expose this key to the
   * operating environment
   */
  static const String POWER = "Power";

  /** The Previous Candidate function key */
  static const String PREVIOUS_CANDIDATE = "PreviousCandidate";

  /** The Print Screen (PrintScrn, SnapShot) key */
  static const String PRINT_SCREEN = "PrintScreen";

  /** The Process key */
  static const String PROCESS = "Process";

  /** The Props key */
  static const String PROPS = "Props";

  /** The Right Arrow key */
  static const String RIGHT = "Right";

  /** The Roman Characters function key */
  static const String ROMAN_CHARACTERS = "RomanCharacters";

  /** The Scroll Lock key */
  static const String SCROLL = "Scroll";

  /** The Select key */
  static const String SELECT = "Select";

  /** The Select Media key */
  static const String SELECT_MEDIA = "SelectMedia";

  /** The Separator key */
  static const String SEPARATOR = "Separator";

  /** The Shift key */
  static const String SHIFT = "Shift";

  /** The Soft1 key */
  static const String SOFT_1 = "Soft1";

  /** The Soft2 key */
  static const String SOFT_2 = "Soft2";

  /** The Soft3 key */
  static const String SOFT_3 = "Soft3";

  /** The Soft4 key */
  static const String SOFT_4 = "Soft4";

  /** The Stop key */
  static const String STOP = "Stop";

  /** The Subtract key */
  static const String SUBTRACT = "Subtract";

  /** The Symbol Lock key */
  static const String SYMBOL_LOCK = "SymbolLock";

  /** The Up Arrow key */
  static const String UP = "Up";

  /** The diagonal Up-Left Arrow key */
  static const String UP_LEFT = "UpLeft";

  /** The diagonal Up-Right Arrow key */
  static const String UP_RIGHT = "UpRight";

  /** The Undo key */
  static const String UNDO = "Undo";

  /** The Volume Down key */
  static const String VOLUME_DOWN = "VolumeDown";

  /** The Volume Mute key */
  static const String VOLUMN_MUTE = "VolumeMute";

  /** The Volume Up key */
  static const String VOLUMN_UP = "VolumeUp";

  /** The Windows Logo key */
  static const String WIN = "Win";

  /** The Zoom key */
  static const String ZOOM = "Zoom";

  /**
   * The Backspace (Back) key. Note: This key value shall be also used for the
   * key labeled 'delete' MacOS keyboards when not modified by the 'Fn' key
   */
  static const String BACKSPACE = "Backspace";

  /** The Horizontal Tabulation (Tab) key */
  static const String TAB = "Tab";

  /** The Cancel key */
  static const String CANCEL = "Cancel";

  /** The Escape (Esc) key */
  static const String ESC = "Esc";

  /** The Space (Spacebar) key:   */
  static const String SPACEBAR = "Spacebar";

  /**
   * The Delete (Del) Key. Note: This key value shall be also used for the key
   * labeled 'delete' MacOS keyboards when modified by the 'Fn' key
   */
  static const String DEL = "Del";

  /** The Combining Grave Accent (Greek Varia, Dead Grave) key */
  static const String DEAD_GRAVE = "DeadGrave";

  /**
   * The Combining Acute Accent (Stress Mark, Greek Oxia, Tonos, Dead Eacute)
   * key
   */
  static const String DEAD_EACUTE = "DeadEacute";

  /** The Combining Circumflex Accent (Hat, Dead Circumflex) key */
  static const String DEAD_CIRCUMFLEX = "DeadCircumflex";

  /** The Combining Tilde (Dead Tilde) key */
  static const String DEAD_TILDE = "DeadTilde";

  /** The Combining Macron (Long, Dead Macron) key */
  static const String DEAD_MACRON = "DeadMacron";

  /** The Combining Breve (Short, Dead Breve) key */
  static const String DEAD_BREVE = "DeadBreve";

  /** The Combining Dot Above (Derivative, Dead Above Dot) key */
  static const String DEAD_ABOVE_DOT = "DeadAboveDot";

  /**
   * The Combining Diaeresis (Double Dot Abode, Umlaut, Greek Dialytika,
   * Double Derivative, Dead Diaeresis) key
   */
  static const String DEAD_UMLAUT = "DeadUmlaut";

  /** The Combining Ring Above (Dead Above Ring) key */
  static const String DEAD_ABOVE_RING = "DeadAboveRing";

  /** The Combining Double Acute Accent (Dead Doubleacute) key */
  static const String DEAD_DOUBLEACUTE = "DeadDoubleacute";

  /** The Combining Caron (Hacek, V Above, Dead Caron) key */
  static const String DEAD_CARON = "DeadCaron";

  /** The Combining Cedilla (Dead Cedilla) key */
  static const String DEAD_CEDILLA = "DeadCedilla";

  /** The Combining Ogonek (Nasal Hook, Dead Ogonek) key */
  static const String DEAD_OGONEK = "DeadOgonek";

  /**
   * The Combining Greek Ypogegrammeni (Greek Non-Spacing Iota Below, Iota
   * Subscript, Dead Iota) key
   */
  static const String DEAD_IOTA = "DeadIota";

  /**
   * The Combining Katakana-Hiragana Voiced Sound Mark (Dead Voiced Sound) key
   */
  static const String DEAD_VOICED_SOUND = "DeadVoicedSound";

  /**
   * The Combining Katakana-Hiragana Semi-Voiced Sound Mark (Dead Semivoiced
   * Sound) key
   */
  static const String DEC_SEMIVOICED_SOUND= "DeadSemivoicedSound";

  /**
   * Key value used when an implementation is unable to identify another key
   * value, due to either hardware, platform, or software constraints
   */
  static const String UNIDENTIFIED = "Unidentified";
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Contains the set of standard values returned by HTMLDocument.getReadyState.
 */
abstract class ReadyState {
  /**
   * Indicates the document is still loading and parsing.
   */
  static const String LOADING = "loading";

  /**
   * Indicates the document is finished parsing but is still loading
   * subresources.
   */
  static const String INTERACTIVE = "interactive";

  /**
   * Indicates the document and all subresources have been loaded.
   */
  static const String COMPLETE = "complete";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// TODO(antonm): support not DOM isolates too.
class _Timer implements Timer {
  final canceller;

  _Timer(this.canceller);

  void cancel() { canceller(); }
}

get _timerFactoryClosure => (int milliSeconds, void callback(Timer timer), bool repeating) {
  var maker;
  var canceller;
  if (repeating) {
    maker = window.setInterval;
    canceller = window.clearInterval;
  } else {
    maker = window.setTimeout;
    canceller = window.clearTimeout;
  }
  Timer timer;
  final int id = maker(() { callback(timer); }, milliSeconds);
  timer = new _Timer(() { canceller(id); });
  return timer;
};
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _HttpRequestUtils {

  // Helper for factory HttpRequest.get
  static HttpRequest get(String url,
                            onComplete(HttpRequest request),
                            bool withCredentials) {
    final request = new HttpRequest();
    request.open('GET', url, true);

    request.withCredentials = withCredentials;

    request.onReadyStateChange.listen((e) {
      if (request.readyState == HttpRequest.DONE) {
        onComplete(request);
      }
    });

    request.send();

    return request;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


_serialize(var message) {
  return new _JsSerializer().traverse(message);
}

class _JsSerializer extends _Serializer {

  visitSendPortSync(SendPortSync x) {
    if (x is _JsSendPortSync) return visitJsSendPortSync(x);
    if (x is _LocalSendPortSync) return visitLocalSendPortSync(x);
    if (x is _RemoteSendPortSync) return visitRemoteSendPortSync(x);
    throw "Unknown port type $x";
  }

  visitJsSendPortSync(_JsSendPortSync x) {
    return [ 'sendport', 'nativejs', x._id ];
  }

  visitLocalSendPortSync(_LocalSendPortSync x) {
    return [ 'sendport', 'dart',
             ReceivePortSync._isolateId, x._receivePort._portId ];
  }

  visitSendPort(SendPort x) {
    throw new UnimplementedError('Asynchronous send port not yet implemented.');
  }

  visitRemoteSendPortSync(_RemoteSendPortSync x) {
    return [ 'sendport', 'dart', x._isolateId, x._portId ];
  }
}

_deserialize(var message) {
  return new _JsDeserializer().deserialize(message);
}


class _JsDeserializer extends _Deserializer {

  static const _UNSPECIFIED = const Object();

  deserializeSendPort(List x) {
    String tag = x[1];
    switch (tag) {
      case 'nativejs':
        num id = x[2];
        return new _JsSendPortSync(id);
      case 'dart':
        num isolateId = x[2];
        num portId = x[3];
        return ReceivePortSync._lookup(isolateId, portId);
      default:
        throw 'Illegal SendPortSync type: $tag';
    }
  }
}

// The receiver is JS.
class _JsSendPortSync implements SendPortSync {

  num _id;
  _JsSendPortSync(this._id);

  callSync(var message) {
    var serialized = _serialize(message);
    var result = _callPortSync(_id, serialized);
    return _deserialize(result);
  }

  bool operator==(var other) {
    return (other is _JsSendPortSync) && (_id == other._id);
  }

  int get hashCode => _id;
}

// TODO(vsm): Differentiate between Dart2Js and Dartium isolates.
// The receiver is a different Dart isolate, compiled to JS.
class _RemoteSendPortSync implements SendPortSync {

  int _isolateId;
  int _portId;
  _RemoteSendPortSync(this._isolateId, this._portId);

  callSync(var message) {
    var serialized = _serialize(message);
    var result = _call(_isolateId, _portId, serialized);
    return _deserialize(result);
  }

  static _call(int isolateId, int portId, var message) {
    var target = 'dart-port-$isolateId-$portId';
    // TODO(vsm): Make this re-entrant.
    // TODO(vsm): Set this up set once, on the first call.
    var source = '$target-result';
    var result = null;
    var listener = (Event e) {
      result = json.parse(_getPortSyncEventData(e));
    };
    window.on[source].add(listener);
    _dispatchEvent(target, [source, message]);
    window.on[source].remove(listener);
    return result;
  }

  bool operator==(var other) {
    return (other is _RemoteSendPortSync) && (_isolateId == other._isolateId)
      && (_portId == other._portId);
  }

  int get hashCode => _isolateId >> 16 + _portId;
}

// The receiver is in the same Dart isolate, compiled to JS.
class _LocalSendPortSync implements SendPortSync {

  ReceivePortSync _receivePort;

  _LocalSendPortSync._internal(this._receivePort);

  callSync(var message) {
    // TODO(vsm): Do a more efficient deep copy.
    var copy = _deserialize(_serialize(message));
    var result = _receivePort._callback(copy);
    return _deserialize(_serialize(result));
  }

  bool operator==(var other) {
    return (other is _LocalSendPortSync)
      && (_receivePort == other._receivePort);
  }

  int get hashCode => _receivePort.hashCode;
}

// TODO(vsm): Move this to dart:isolate.  This will take some
// refactoring as there are dependences here on the DOM.  Users
// interact with this class (or interface if we change it) directly -
// new ReceivePortSync.  I think most of the DOM logic could be
// delayed until the corresponding SendPort is registered on the
// window.

// A Dart ReceivePortSync (tagged 'dart' when serialized) is
// identifiable / resolvable by the combination of its isolateid and
// portid.  When a corresponding SendPort is used within the same
// isolate, the _portMap below can be used to obtain the
// ReceivePortSync directly.  Across isolates (or from JS), an
// EventListener can be used to communicate with the port indirectly.
class ReceivePortSync {

  static Map<int, ReceivePortSync> _portMap;
  static int _portIdCount;
  static int _cachedIsolateId;

  num _portId;
  Function _callback;
  EventListener _listener;

  ReceivePortSync() {
    if (_portIdCount == null) {
      _portIdCount = 0;
      _portMap = new Map<int, ReceivePortSync>();
    }
    _portId = _portIdCount++;
    _portMap[_portId] = this;
  }

  static int get _isolateId {
    // TODO(vsm): Make this coherent with existing isolate code.
    if (_cachedIsolateId == null) {
      _cachedIsolateId = _getNewIsolateId();
    }
    return _cachedIsolateId;
  }

  static String _getListenerName(isolateId, portId) =>
      'dart-port-$isolateId-$portId';
  String get _listenerName => _getListenerName(_isolateId, _portId);

  void receive(callback(var message)) {
    _callback = callback;
    if (_listener == null) {
      _listener = (Event e) {
        var data = json.parse(_getPortSyncEventData(e));
        var replyTo = data[0];
        var message = _deserialize(data[1]);
        var result = _callback(message);
        _dispatchEvent(replyTo, _serialize(result));
      };
      window.on[_listenerName].add(_listener);
    }
  }

  void close() {
    _portMap.remove(_portId);
    if (_listener != null) window.on[_listenerName].remove(_listener);
  }

  SendPortSync toSendPort() {
    return new _LocalSendPortSync._internal(this);
  }

  static SendPortSync _lookup(int isolateId, int portId) {
    if (isolateId == _isolateId) {
      return _portMap[portId].toSendPort();
    } else {
      return new _RemoteSendPortSync(isolateId, portId);
    }
  }
}

get _isolateId => ReceivePortSync._isolateId;

void _dispatchEvent(String receiver, var message) {
  var event = new CustomEvent(receiver, canBubble: false, cancelable:false,
    detail: json.stringify(message));
  window.dispatchEvent(event);
}

String _getPortSyncEventData(CustomEvent event) => event.detail;
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


typedef void _MicrotaskCallback();

/**
 * This class attempts to invoke a callback as soon as the current event stack
 * unwinds, but before the browser repaints.
 */
abstract class _MicrotaskScheduler {
  bool _nextMicrotaskFrameScheduled = false;
  _MicrotaskCallback _callback;

  _MicrotaskScheduler(this._callback);

  /**
   * Creates the best possible microtask scheduler for the current platform.
   */
  factory _MicrotaskScheduler.best(_MicrotaskCallback callback) {
    if (Window._supportsSetImmediate) {
      return new _SetImmediateScheduler(callback);
    } else if (MutationObserver.supported) {
      return new _MutationObserverScheduler(callback);
    }
    return new _PostMessageScheduler(callback);
  }

  /**
   * Schedules a microtask callback if one has not been scheduled already.
   */
  void maybeSchedule() {
    if (this._nextMicrotaskFrameScheduled) {
      return;
    }
    this._nextMicrotaskFrameScheduled = true;
    this._schedule();
  }

  /**
   * Does the actual scheduling of the callback.
   */
  void _schedule();

  /**
   * Handles the microtask callback and forwards it if necessary.
   */
  void _onCallback() {
    // Ignore spurious messages.
    if (!_nextMicrotaskFrameScheduled) {
      return;
    }
    _nextMicrotaskFrameScheduled = false;
    this._callback();
  }
}

/**
 * Scheduler which uses window.postMessage to schedule events.
 */
class _PostMessageScheduler extends _MicrotaskScheduler {
  const _MICROTASK_MESSAGE = "DART-MICROTASK";

  _PostMessageScheduler(_MicrotaskCallback callback): super(callback) {
      // Messages from other windows do not cause a security risk as
      // all we care about is that _handleMessage is called
      // after the current event loop is unwound and calling the function is
      // a noop when zero requests are pending.
      window.onMessage.listen(this._handleMessage);
  }

  void _schedule() {
    window.postMessage(_MICROTASK_MESSAGE, "*");
  }

  void _handleMessage(e) {
    this._onCallback();
  }
}

/**
 * Scheduler which uses a MutationObserver to schedule events.
 */
class _MutationObserverScheduler extends _MicrotaskScheduler {
  MutationObserver _observer;
  Element _dummy;

  _MutationObserverScheduler(_MicrotaskCallback callback): super(callback) {
    // Mutation events get fired as soon as the current event stack is unwound
    // so we just make a dummy event and listen for that.
    _observer = new MutationObserver(this._handleMutation);
    _dummy = new DivElement();
    _observer.observe(_dummy, attributes: true);
  }

  void _schedule() {
    // Toggle it to trigger the mutation event.
    _dummy.hidden = !_dummy.hidden;
  }

  _handleMutation(List<MutationRecord> mutations, MutationObserver observer) {
    this._onCallback();
  }
}

/**
 * Scheduler which uses window.setImmediate to schedule events.
 */
class _SetImmediateScheduler extends _MicrotaskScheduler {
  _SetImmediateScheduler(_MicrotaskCallback callback): super(callback);

  void _schedule() {
    window._setImmediate(_handleImmediate);
  }

  void _handleImmediate() {
    this._onCallback();
  }
}

List<TimeoutHandler> _pendingMicrotasks;
_MicrotaskScheduler _microtaskScheduler = null;

void _maybeScheduleMicrotaskFrame() {
  if (_microtaskScheduler == null) {
    _microtaskScheduler =
      new _MicrotaskScheduler.best(_completeMicrotasks);
  }
  _microtaskScheduler.maybeSchedule();
}

/**
 * Registers a [callback] which is called after the current execution stack
 * unwinds.
 */
void _addMicrotaskCallback(TimeoutHandler callback) {
  if (_pendingMicrotasks == null) {
    _pendingMicrotasks = <TimeoutHandler>[];
    _maybeScheduleMicrotaskFrame();
  }
  _pendingMicrotasks.add(callback);
}


/**
 * Complete all pending microtasks.
 */
void _completeMicrotasks() {
  var callbacks = _pendingMicrotasks;
  _pendingMicrotasks = null;
  for (var callback in callbacks) {
    callback();
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:isolate library.


/********************************************************
  Inserted from lib/isolate/serialization.dart
 ********************************************************/

class _MessageTraverserVisitedMap {

  operator[](var object) => null;
  void operator[]=(var object, var info) { }

  void reset() { }
  void cleanup() { }

}

/** Abstract visitor for dart objects that can be sent as isolate messages. */
abstract class _MessageTraverser {

  _MessageTraverserVisitedMap _visited;
  _MessageTraverser() : _visited = new _MessageTraverserVisitedMap();

  /** Visitor's entry point. */
  traverse(var x) {
    if (isPrimitive(x)) return visitPrimitive(x);
    _visited.reset();
    var result;
    try {
      result = _dispatch(x);
    } finally {
      _visited.cleanup();
    }
    return result;
  }

  _dispatch(var x) {
    if (isPrimitive(x)) return visitPrimitive(x);
    if (x is List) return visitList(x);
    if (x is Map) return visitMap(x);
    if (x is SendPort) return visitSendPort(x);
    if (x is SendPortSync) return visitSendPortSync(x);

    // Overridable fallback.
    return visitObject(x);
  }

  visitPrimitive(x);
  visitList(List x);
  visitMap(Map x);
  visitSendPort(SendPort x);
  visitSendPortSync(SendPortSync x);

  visitObject(Object x) {
    // TODO(floitsch): make this a real exception. (which one)?
    throw "Message serialization: Illegal value $x passed";
  }

  static bool isPrimitive(x) {
    return (x == null) || (x is String) || (x is num) || (x is bool);
  }
}


/** Visitor that serializes a message as a JSON array. */
abstract class _Serializer extends _MessageTraverser {
  int _nextFreeRefId = 0;

  visitPrimitive(x) => x;

  visitList(List list) {
    int copyId = _visited[list];
    if (copyId != null) return ['ref', copyId];

    int id = _nextFreeRefId++;
    _visited[list] = id;
    var jsArray = _serializeList(list);
    // TODO(floitsch): we are losing the generic type.
    return ['list', id, jsArray];
  }

  visitMap(Map map) {
    int copyId = _visited[map];
    if (copyId != null) return ['ref', copyId];

    int id = _nextFreeRefId++;
    _visited[map] = id;
    var keys = _serializeList(map.keys.toList());
    var values = _serializeList(map.values.toList());
    // TODO(floitsch): we are losing the generic type.
    return ['map', id, keys, values];
  }

  _serializeList(List list) {
    int len = list.length;
    var result = new List.fixedLength(len);
    for (int i = 0; i < len; i++) {
      result[i] = _dispatch(list[i]);
    }
    return result;
  }
}

/** Deserializes arrays created with [_Serializer]. */
abstract class _Deserializer {
  Map<int, dynamic> _deserialized;

  _Deserializer();

  static bool isPrimitive(x) {
    return (x == null) || (x is String) || (x is num) || (x is bool);
  }

  deserialize(x) {
    if (isPrimitive(x)) return x;
    // TODO(floitsch): this should be new HashMap<int, dynamic>()
    _deserialized = new HashMap();
    return _deserializeHelper(x);
  }

  _deserializeHelper(x) {
    if (isPrimitive(x)) return x;
    assert(x is List);
    switch (x[0]) {
      case 'ref': return _deserializeRef(x);
      case 'list': return _deserializeList(x);
      case 'map': return _deserializeMap(x);
      case 'sendport': return deserializeSendPort(x);
      default: return deserializeObject(x);
    }
  }

  _deserializeRef(List x) {
    int id = x[1];
    var result = _deserialized[id];
    assert(result != null);
    return result;
  }

  List _deserializeList(List x) {
    int id = x[1];
    // We rely on the fact that Dart-lists are directly mapped to Js-arrays.
    List dartList = x[2];
    _deserialized[id] = dartList;
    int len = dartList.length;
    for (int i = 0; i < len; i++) {
      dartList[i] = _deserializeHelper(dartList[i]);
    }
    return dartList;
  }

  Map _deserializeMap(List x) {
    Map result = new Map();
    int id = x[1];
    _deserialized[id] = result;
    List keys = x[2];
    List values = x[3];
    int len = keys.length;
    assert(len == values.length);
    for (int i = 0; i < len; i++) {
      var key = _deserializeHelper(keys[i]);
      var value = _deserializeHelper(values[i]);
      result[key] = value;
    }
    return result;
  }

  deserializeSendPort(List x);

  deserializeObject(List x) {
    // TODO(floitsch): Use real exception (which one?).
    throw "Unexpected serialized object";
  }
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _CssStyleDeclarationFactoryProvider {
  static CssStyleDeclaration createCssStyleDeclaration_css(String css) {
    final style = new Element.tag('div').style;
    style.cssText = css;
    return style;
  }

  static CssStyleDeclaration createCssStyleDeclaration() {
    return new CssStyleDeclaration.css('');
  }
}

class _DocumentFragmentFactoryProvider {
  @DomName('Document.createDocumentFragment')
  static DocumentFragment createDocumentFragment() =>
      document.createDocumentFragment();

  static DocumentFragment createDocumentFragment_html(String html) {
    final fragment = new DocumentFragment();
    fragment.innerHtml = html;
    return fragment;
  }

  // TODO(nweiz): enable this when XML is ported.
  // factory DocumentFragment.xml(String xml) {
  //   final fragment = new DocumentFragment();
  //   final e = new XMLElement.tag("xml");
  //   e.innerHtml = xml;
  //
  //   // Copy list first since we don't want liveness during iteration.
  //   final List nodes = new List.from(e.nodes);
  //   fragment.nodes.addAll(nodes);
  //   return fragment;
  // }

  static DocumentFragment createDocumentFragment_svg(String svgContent) {
    final fragment = new DocumentFragment();
    final e = new svg.SvgSvgElement();
    e.innerHtml = svgContent;

    // Copy list first since we don't want liveness during iteration.
    final List nodes = new List.from(e.nodes);
    fragment.nodes.addAll(nodes);
    return fragment;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Conversions for Window.  These check if the window is the local
// window, and if it's not, wraps or unwraps it with a secure wrapper.
// We need to test for EventTarget here as well as it's a base type.
// We omit an unwrapper for Window as no methods take a non-local
// window as a parameter.


WindowBase _convertNativeToDart_Window(win) {
  return _DOMWindowCrossFrame._createSafe(win);
}

EventTarget _convertNativeToDart_EventTarget(e) {
  // Assume it's a Window if it contains the setInterval property.  It may be
  // from a different frame - without a patched prototype - so we cannot
  // rely on Dart type checking.
  if (JS('bool', r'"setInterval" in #', e))
    return _DOMWindowCrossFrame._createSafe(e);
  else
    return e;
}

EventTarget _convertDartToNative_EventTarget(e) {
  if (e is _DOMWindowCrossFrame) {
    return e._window;
  } else {
    return e;
  }
}

// Conversions for ImageData
//
// On Firefox, the returned ImageData is a plain object.

class _TypedImageData implements ImageData {
  final Uint8ClampedArray data;
  final int height;
  final int width;

  _TypedImageData(this.data, this.height, this.width);
}

ImageData _convertNativeToDart_ImageData(nativeImageData) {

  // None of the native getters that return ImageData have the type ImageData
  // since that is incorrect for FireFox (which returns a plain Object).  So we
  // need something that tells the compiler that the ImageData class has been
  // instantiated.
  // TODO(sra): Remove this when all the ImageData returning APIs have been
  // annotated as returning the union ImageData + Object.
  JS('ImageData', '0');

  if (nativeImageData is ImageData) return nativeImageData;

  // On Firefox the above test fails because imagedata is a plain object.
  // So we create a _TypedImageData.

  return new _TypedImageData(
      JS('var', '#.data', nativeImageData),
      JS('var', '#.height', nativeImageData),
      JS('var', '#.width', nativeImageData));
}

// We can get rid of this conversion if _TypedImageData implements the fields
// with native names.
_convertDartToNative_ImageData(ImageData imageData) {
  if (imageData is _TypedImageData) {
    return JS('', '{data: #, height: #, width: #}',
        imageData.data, imageData.height, imageData.width);
  }
  return imageData;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// TODO(vsm): Unify with Dartium version.
class _DOMWindowCrossFrame implements WindowBase {
  // Private window.  Note, this is a window in another frame, so it
  // cannot be typed as "Window" as its prototype is not patched
  // properly.  Its fields and methods can only be accessed via JavaScript.
  var _window;

  // Fields.
  HistoryBase get history =>
    _HistoryCrossFrame._createSafe(JS('HistoryBase', '#.history', _window));
  LocationBase get location =>
    _LocationCrossFrame._createSafe(JS('LocationBase', '#.location', _window));

  // TODO(vsm): Add frames to navigate subframes.  See 2312.

  bool get closed => JS('bool', '#.closed', _window);

  WindowBase get opener => _createSafe(JS('WindowBase', '#.opener', _window));

  WindowBase get parent => _createSafe(JS('WindowBase', '#.parent', _window));

  WindowBase get top => _createSafe(JS('WindowBase', '#.top', _window));

  // Methods.
  void close() => JS('void', '#.close()', _window);

  void postMessage(var message, String targetOrigin, [List messagePorts = null]) {
    if (messagePorts == null) {
      JS('void', '#.postMessage(#,#)', _window, message, targetOrigin);
    } else {
      JS('void', '#.postMessage(#,#,#)', _window, message, targetOrigin, messagePorts);
    }
  }

  // Implementation support.
  _DOMWindowCrossFrame(this._window);

  static WindowBase _createSafe(w) {
    if (identical(w, window)) {
      return w;
    } else {
      // TODO(vsm): Cache or implement equality.
      return new _DOMWindowCrossFrame(w);
    }
  }
}

class _LocationCrossFrame implements LocationBase {
  // Private location.  Note, this is a location object in another frame, so it
  // cannot be typed as "Location" as its prototype is not patched
  // properly.  Its fields and methods can only be accessed via JavaScript.
  var _location;

  void set href(String val) => _setHref(_location, val);
  static void _setHref(location, val) {
    JS('void', '#.href = #', location, val);
  }

  // Implementation support.
  _LocationCrossFrame(this._location);

  static LocationBase _createSafe(location) {
    if (identical(location, window.location)) {
      return location;
    } else {
      // TODO(vsm): Cache or implement equality.
      return new _LocationCrossFrame(location);
    }
  }
}

class _HistoryCrossFrame implements HistoryBase {
  // Private history.  Note, this is a history object in another frame, so it
  // cannot be typed as "History" as its prototype is not patched
  // properly.  Its fields and methods can only be accessed via JavaScript.
  var _history;

  void back() => JS('void', '#.back()', _history);

  void forward() => JS('void', '#.forward()', _history);

  void go(int distance) => JS('void', '#.go(#)', _history, distance);

  // Implementation support.
  _HistoryCrossFrame(this._history);

  static HistoryBase _createSafe(h) {
    if (identical(h, window.history)) {
      return h;
    } else {
      // TODO(vsm): Cache or implement equality.
      return new _HistoryCrossFrame(h);
    }
  }
}
/**
 * A custom KeyboardEvent that attempts to eliminate cross-browser
 * inconsistencies, and also provide both keyCode and charCode information
 * for all key events (when such information can be determined).
 *
 * This class is very much a work in progress, and we'd love to get information
 * on how we can make this class work with as many international keyboards as
 * possible. Bugs welcome!
 */
class KeyEvent implements KeyboardEvent {
  /** The parent KeyboardEvent that this KeyEvent is wrapping and "fixing". */
  KeyboardEvent _parent;

  /** The "fixed" value of whether the alt key is being pressed. */
  bool _shadowAltKey;

  /** Caculated value of what the estimated charCode is for this event. */
  int _shadowCharCode;

  /** Caculated value of what the estimated keyCode is for this event. */
  int _shadowKeyCode;

  /** Caculated value of what the estimated keyCode is for this event. */
  int get keyCode => _shadowKeyCode;

  /** Caculated value of what the estimated charCode is for this event. */
  int get charCode => this.type == 'keypress' ? _shadowCharCode : 0;

  /** Caculated value of whether the alt key is pressed is for this event. */
  bool get altKey => _shadowAltKey;

  /** Caculated value of what the estimated keyCode is for this event. */
  int get which => keyCode;

  /** Accessor to the underlying keyCode value is the parent event. */
  int get _realKeyCode => JS('int', '#.keyCode', _parent);

  /** Accessor to the underlying charCode value is the parent event. */
  int get _realCharCode => JS('int', '#.charCode', _parent);

  /** Accessor to the underlying altKey value is the parent event. */
  bool get _realAltKey => JS('int', '#.altKey', _parent);

  /** Construct a KeyEvent with [parent] as event we're emulating. */
  KeyEvent(KeyboardEvent parent) {
    _parent = parent;
    _shadowAltKey = _realAltKey;
    _shadowCharCode = _realCharCode;
    _shadowKeyCode = _realKeyCode;
  }

  /** True if the altGraphKey is pressed during this event. */
  bool get altGraphKey => _parent.altGraphKey;
  bool get bubbles => _parent.bubbles;
  /** True if this event can be cancelled. */
  bool get cancelable => _parent.cancelable;
  bool get cancelBubble => _parent.cancelBubble;
  void set cancelBubble(bool cancel) {
    _parent.cancelBubble = cancel;
  }
  /** Accessor to the clipboardData available for this event. */
  Clipboard get clipboardData => _parent.clipboardData;
  /** True if the ctrl key is pressed during this event. */
  bool get ctrlKey => _parent.ctrlKey;
  /** Accessor to the target this event is listening to for changes. */
  EventTarget get currentTarget => _parent.currentTarget;
  bool get defaultPrevented => _parent.defaultPrevented;
  int get detail => _parent.detail;
  int get eventPhase => _parent.eventPhase;
  /**
   * Accessor to the part of the keyboard that the key was pressed from (one of
   * KeyLocation.STANDARD, KeyLocation.RIGHT, KeyLocation.LEFT,
   * KeyLocation.NUMPAD, KeyLocation.MOBILE, KeyLocation.JOYSTICK).
   */
  int get keyLocation => _parent.keyLocation;
  int get layerX => _parent.layerX;
  int get layerY => _parent.layerY;
  /** True if the Meta (or Mac command) key is pressed during this event. */
  bool get metaKey => _parent.metaKey;
  int get pageX => _parent.pageX;
  int get pageY => _parent.pageY;
  bool get returnValue => _parent.returnValue;
  void set returnValue(bool value) {
    _parent.returnValue = value;
  }
  /** True if the shift key was pressed during this event. */
  bool get shiftKey => _parent.shiftKey;
  int get timeStamp => _parent.timeStamp;
  /**
   * The type of key event that occurred. One of "keydown", "keyup", or
   * "keypress".
   */
  String get type => _parent.type;
  Window get view => _parent.view;
  void preventDefault() => _parent.preventDefault();
  void stopImmediatePropagation() => _parent.stopImmediatePropagation();
  void stopPropagation() => _parent.stopPropagation();
  void $dom_initUIEvent(String type, bool canBubble, bool cancelable,
      Window view, int detail) {
    throw new UnsupportedError("Cannot initialize a UI Event from a KeyEvent.");
  }
  void $dom_initEvent(String eventTypeArg, bool canBubbleArg,
      bool cancelableArg) {
    throw new UnsupportedError("Cannot initialize an Event from a KeyEvent.");
  }
  String get _shadowKeyIdentifier => JS('String', '#.keyIdentifier', _parent);

  int get $dom_charCode => charCode;
  int get $dom_keyCode => keyCode;
  EventTarget get target => _parent.target;
  String get $dom_keyIdentifier {
    throw new UnsupportedError("keyIdentifier is unsupported.");
  }
  void $dom_initKeyboardEvent(String type, bool canBubble, bool cancelable,
      Window view, String keyIdentifier, int keyLocation, bool ctrlKey,
      bool altKey, bool shiftKey, bool metaKey,
      bool altGraphKey) {
    throw new UnsupportedError(
        "Cannot initialize a KeyboardEvent from a KeyEvent.");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _TextFactoryProvider {
  static Text createText(String data) =>
      JS('Text', 'document.createTextNode(#)', data);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// On Firefox 11, the object obtained from 'window.location' is very strange.
// It can't be monkey-patched and seems immune to putting methods on
// Object.prototype.  We are forced to wrap the object.

class _LocationWrapper implements Location {

  final _ptr;  // Opaque reference to real location.

  _LocationWrapper(this._ptr);

  // TODO(sra): Replace all the _set and _get calls with 'JS' forms.

  // final List<String> ancestorOrigins;
  List<String> get ancestorOrigins => _get(_ptr, 'ancestorOrigins');

  // String hash;
  String get hash => _get(_ptr, 'hash');
  void set hash(String value) {
    _set(_ptr, 'hash', value);
  }

  // String host;
  String get host => _get(_ptr, 'host');
  void set host(String value) {
    _set(_ptr, 'host', value);
  }

  // String hostname;
  String get hostname => _get(_ptr, 'hostname');
  void set hostname(String value) {
    _set(_ptr, 'hostname', value);
  }

  // String href;
  String get href => _get(_ptr, 'href');
  void set href(String value) {
    _set(_ptr, 'href', value);
  }

  // final String origin;
  String get origin => _get(_ptr, 'origin');

  // String pathname;
  String get pathname => _get(_ptr, 'pathname');
  void set pathname(String value) {
    _set(_ptr, 'pathname', value);
  }

  // String port;
  String get port => _get(_ptr, 'port');
  void set port(String value) {
    _set(_ptr, 'port', value);
  }

  // String protocol;
  String get protocol => _get(_ptr, 'protocol');
  void set protocol(String value) {
    _set(_ptr, 'protocol', value);
  }

  // String search;
  String get search => _get(_ptr, 'search');
  void set search(String value) {
    _set(_ptr, 'search', value);
  }

  void assign(String url) => JS('void', '#.assign(#)', _ptr, url);

  void reload() => JS('void', '#.reload()', _ptr);

  void replace(String url) => JS('void', '#.replace(#)', _ptr, url);

  String toString() => JS('String', '#.toString()', _ptr);


  static _get(p, m) => JS('var', '#[#]', p, m);
  static _set(p, m, v) => JS('void', '#[#] = #', p, m, v);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _TypedArrayFactoryProvider {

  static Float32Array createFloat32Array(int length) => _F32(length);
  static Float32Array createFloat32Array_fromList(List<num> list) =>
      _F32(ensureNative(list));
  static Float32Array createFloat32Array_fromBuffer(ArrayBuffer buffer,
                                  [int byteOffset = 0, int length]) {
    if (length == null) return _F32_2(buffer, byteOffset);
    return _F32_3(buffer, byteOffset, length);
  }

  static Float64Array createFloat64Array(int length) => _F64(length);
  static Float64Array createFloat64Array_fromList(List<num> list) =>
      _F64(ensureNative(list));
  static Float64Array createFloat64Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _F64_2(buffer, byteOffset);
    return _F64_3(buffer, byteOffset, length);
  }

  static Int8Array createInt8Array(int length) => _I8(length);
  static Int8Array createInt8Array_fromList(List<num> list) =>
      _I8(ensureNative(list));
  static Int8Array createInt8Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _I8_2(buffer, byteOffset);
    return _I8_3(buffer, byteOffset, length);
  }

  static Int16Array createInt16Array(int length) => _I16(length);
  static Int16Array createInt16Array_fromList(List<num> list) =>
      _I16(ensureNative(list));
  static Int16Array createInt16Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _I16_2(buffer, byteOffset);
    return _I16_3(buffer, byteOffset, length);
  }

  static Int32Array createInt32Array(int length) => _I32(length);
  static Int32Array createInt32Array_fromList(List<num> list) =>
      _I32(ensureNative(list));
  static Int32Array createInt32Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _I32_2(buffer, byteOffset);
    return _I32_3(buffer, byteOffset, length);
  }

  static Uint8Array createUint8Array(int length) => _U8(length);
  static Uint8Array createUint8Array_fromList(List<num> list) =>
      _U8(ensureNative(list));
  static Uint8Array createUint8Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _U8_2(buffer, byteOffset);
    return _U8_3(buffer, byteOffset, length);
  }

  static Uint16Array createUint16Array(int length) => _U16(length);
  static Uint16Array createUint16Array_fromList(List<num> list) =>
      _U16(ensureNative(list));
  static Uint16Array createUint16Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _U16_2(buffer, byteOffset);
    return _U16_3(buffer, byteOffset, length);
  }

  static Uint32Array createUint32Array(int length) => _U32(length);
  static Uint32Array createUint32Array_fromList(List<num> list) =>
      _U32(ensureNative(list));
  static Uint32Array createUint32Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _U32_2(buffer, byteOffset);
    return _U32_3(buffer, byteOffset, length);
  }

  static Uint8ClampedArray createUint8ClampedArray(int length) => _U8C(length);
  static Uint8ClampedArray createUint8ClampedArray_fromList(List<num> list) =>
      _U8C(ensureNative(list));
  static Uint8ClampedArray createUint8ClampedArray_fromBuffer(
        ArrayBuffer buffer, [int byteOffset = 0, int length]) {
    if (length == null) return _U8C_2(buffer, byteOffset);
    return _U8C_3(buffer, byteOffset, length);
  }

  static Float32Array _F32(arg) =>
      JS('Float32Array', 'new Float32Array(#)', arg);
  static Float64Array _F64(arg) =>
      JS('Float64Array', 'new Float64Array(#)', arg);
  static Int8Array _I8(arg) =>
      JS('Int8Array', 'new Int8Array(#)', arg);
  static Int16Array _I16(arg) =>
      JS('Int16Array', 'new Int16Array(#)', arg);
  static Int32Array _I32(arg) =>
      JS('Int32Array', 'new Int32Array(#)', arg);
  static Uint8Array _U8(arg) =>
      JS('Uint8Array', 'new Uint8Array(#)', arg);
  static Uint16Array _U16(arg) =>
      JS('Uint16Array', 'new Uint16Array(#)', arg);
  static Uint32Array _U32(arg) =>
      JS('Uint32Array', 'new Uint32Array(#)', arg);
  static Uint8ClampedArray _U8C(arg) =>
      JS('Uint8ClampedArray', 'new Uint8ClampedArray(#)', arg);

  static Float32Array _F32_2(arg1, arg2) =>
      JS('Float32Array', 'new Float32Array(#, #)', arg1, arg2);
  static Float64Array _F64_2(arg1, arg2) =>
      JS('Float64Array', 'new Float64Array(#, #)', arg1, arg2);
  static Int8Array _I8_2(arg1, arg2) =>
      JS('Int8Array', 'new Int8Array(#, #)', arg1, arg2);
  static Int16Array _I16_2(arg1, arg2) =>
      JS('Int16Array', 'new Int16Array(#, #)', arg1, arg2);
  static Int32Array _I32_2(arg1, arg2) =>
      JS('Int32Array', 'new Int32Array(#, #)', arg1, arg2);
  static Uint8Array _U8_2(arg1, arg2) =>
      JS('Uint8Array', 'new Uint8Array(#, #)', arg1, arg2);
  static Uint16Array _U16_2(arg1, arg2) =>
      JS('Uint16Array', 'new Uint16Array(#, #)', arg1, arg2);
  static Uint32Array _U32_2(arg1, arg2) =>
      JS('Uint32Array', 'new Uint32Array(#, #)', arg1, arg2);
  static Uint8ClampedArray _U8C_2(arg1, arg2) =>
      JS('Uint8ClampedArray', 'new Uint8ClampedArray(#, #)', arg1, arg2);

  static Float32Array _F32_3(arg1, arg2, arg3) =>
      JS('Float32Array', 'new Float32Array(#, #, #)', arg1, arg2, arg3);
  static Float64Array _F64_3(arg1, arg2, arg3) =>
      JS('Float64Array', 'new Float64Array(#, #, #)', arg1, arg2, arg3);
  static Int8Array _I8_3(arg1, arg2, arg3) =>
      JS('Int8Array', 'new Int8Array(#, #, #)', arg1, arg2, arg3);
  static Int16Array _I16_3(arg1, arg2, arg3) =>
      JS('Int16Array', 'new Int16Array(#, #, #)', arg1, arg2, arg3);
  static Int32Array _I32_3(arg1, arg2, arg3) =>
      JS('Int32Array', 'new Int32Array(#, #, #)', arg1, arg2, arg3);
  static Uint8Array _U8_3(arg1, arg2, arg3) =>
      JS('Uint8Array', 'new Uint8Array(#, #, #)', arg1, arg2, arg3);
  static Uint16Array _U16_3(arg1, arg2, arg3) =>
      JS('Uint16Array', 'new Uint16Array(#, #, #)', arg1, arg2, arg3);
  static Uint32Array _U32_3(arg1, arg2, arg3) =>
      JS('Uint32Array', 'new Uint32Array(#, #, #)', arg1, arg2, arg3);
  static Uint8ClampedArray _U8C_3(arg1, arg2, arg3) =>
      JS('Uint8ClampedArray', 'new Uint8ClampedArray(#, #, #)', arg1, arg2, arg3);


  // Ensures that [list] is a JavaScript Array or a typed array.  If necessary,
  // copies the list.
  static ensureNative(List list) => list;  // TODO: make sure.
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Iterator for arrays with fixed size.
class FixedSizeListIterator<T> implements Iterator<T> {
  final List<T> _array;
  final int _length;  // Cache array length for faster access.
  int _position;
  T _current;
  
  FixedSizeListIterator(List<T> array)
      : _array = array,
        _position = -1,
        _length = array.length;

  bool moveNext() {
    int nextPosition = _position + 1;
    if (nextPosition < _length) {
      _current = _array[nextPosition];
      _position = nextPosition;
      return true;
    }
    _current = null;
    _position = _length;
    return false;
  }

  T get current => _current;
}

// Iterator for arrays with variable size.
class _VariableSizeListIterator<T> implements Iterator<T> {
  final List<T> _array;
  int _position;
  T _current;

  _VariableSizeListIterator(List<T> array)
      : _array = array,
        _position = -1;

  bool moveNext() {
    int nextPosition = _position + 1;
    if (nextPosition < _array.length) {
      _current = _array[nextPosition];
      _position = nextPosition;
      return true;
    }
    _current = null;
    _position = _array.length;
    return false;
  }

  T get current => _current;
}
