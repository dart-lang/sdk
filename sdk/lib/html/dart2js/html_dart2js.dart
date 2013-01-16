library html;

import 'dart:async';
import 'dart:collection';
import 'dart:html_common';
import 'dart:indexed_db';
import 'dart:isolate';
import 'dart:json' as json;
import 'dart:math';
import 'dart:svg' as svg;
import 'dart:web_audio' as web_audio;
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

  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  AbstractWorkerEvents get on =>
    new AbstractWorkerEvents(this);

  @JSName('addEventListener')
  @DocsEditable @DomName('AbstractWorker.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('AbstractWorker.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('AbstractWorker.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  Stream<Event> get onError => errorEvent.forTarget(this);
}

@DocsEditable
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

  @DocsEditable @DomName('HTMLAnchorElement.download')
  String download;

  @DocsEditable @DomName('HTMLAnchorElement.hash')
  String hash;

  @DocsEditable @DomName('HTMLAnchorElement.host')
  String host;

  @DocsEditable @DomName('HTMLAnchorElement.hostname')
  String hostname;

  @DocsEditable @DomName('HTMLAnchorElement.href')
  String href;

  @DocsEditable @DomName('HTMLAnchorElement.hreflang')
  String hreflang;

  @DocsEditable @DomName('HTMLAnchorElement.name')
  String name;

  @DocsEditable @DomName('HTMLAnchorElement.origin')
  final String origin;

  @DocsEditable @DomName('HTMLAnchorElement.pathname')
  String pathname;

  @DocsEditable @DomName('HTMLAnchorElement.ping')
  String ping;

  @DocsEditable @DomName('HTMLAnchorElement.port')
  String port;

  @DocsEditable @DomName('HTMLAnchorElement.protocol')
  String protocol;

  @DocsEditable @DomName('HTMLAnchorElement.rel')
  String rel;

  @DocsEditable @DomName('HTMLAnchorElement.search')
  String search;

  @DocsEditable @DomName('HTMLAnchorElement.target')
  String target;

  @DocsEditable @DomName('HTMLAnchorElement.type')
  String type;

  @DocsEditable @DomName('HTMLAnchorElement.toString')
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('WebKitAnimationEvent')
class AnimationEvent extends Event native "*WebKitAnimationEvent" {

  @DocsEditable @DomName('WebKitAnimationEvent.animationName')
  final String animationName;

  @DocsEditable @DomName('WebKitAnimationEvent.elapsedTime')
  final num elapsedTime;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('HTMLAppletElement')
class AppletElement extends Element native "*HTMLAppletElement" {

  @DocsEditable @DomName('HTMLAppletElement.align')
  String align;

  @DocsEditable @DomName('HTMLAppletElement.alt')
  String alt;

  @DocsEditable @DomName('HTMLAppletElement.archive')
  String archive;

  @DocsEditable @DomName('HTMLAppletElement.code')
  String code;

  @DocsEditable @DomName('HTMLAppletElement.codeBase')
  String codeBase;

  @DocsEditable @DomName('HTMLAppletElement.height')
  String height;

  @DocsEditable @DomName('HTMLAppletElement.hspace')
  String hspace;

  @DocsEditable @DomName('HTMLAppletElement.name')
  String name;

  @DocsEditable @DomName('HTMLAppletElement.object')
  String object;

  @DocsEditable @DomName('HTMLAppletElement.vspace')
  String vspace;

  @DocsEditable @DomName('HTMLAppletElement.width')
  String width;
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

  static const EventStreamProvider<Event> cachedEvent = const EventStreamProvider<Event>('cached');

  static const EventStreamProvider<Event> checkingEvent = const EventStreamProvider<Event>('checking');

  static const EventStreamProvider<Event> downloadingEvent = const EventStreamProvider<Event>('downloading');

  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  static const EventStreamProvider<Event> noUpdateEvent = const EventStreamProvider<Event>('noupdate');

  static const EventStreamProvider<Event> obsoleteEvent = const EventStreamProvider<Event>('obsolete');

  static const EventStreamProvider<Event> progressEvent = const EventStreamProvider<Event>('progress');

  static const EventStreamProvider<Event> updateReadyEvent = const EventStreamProvider<Event>('updateready');

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.applicationCache)');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  ApplicationCacheEvents get on =>
    new ApplicationCacheEvents(this);

  static const int CHECKING = 2;

  static const int DOWNLOADING = 3;

  static const int IDLE = 1;

  static const int OBSOLETE = 5;

  static const int UNCACHED = 0;

  static const int UPDATEREADY = 4;

  @DocsEditable @DomName('DOMApplicationCache.status')
  final int status;

  @DocsEditable @DomName('DOMApplicationCache.abort')
  void abort() native;

  @JSName('addEventListener')
  @DocsEditable @DomName('DOMApplicationCache.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('DOMApplicationCache.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('DOMApplicationCache.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('DOMApplicationCache.swapCache')
  void swapCache() native;

  @DocsEditable @DomName('DOMApplicationCache.update')
  void update() native;

  Stream<Event> get onCached => cachedEvent.forTarget(this);

  Stream<Event> get onChecking => checkingEvent.forTarget(this);

  Stream<Event> get onDownloading => downloadingEvent.forTarget(this);

  Stream<Event> get onError => errorEvent.forTarget(this);

  Stream<Event> get onNoUpdate => noUpdateEvent.forTarget(this);

  Stream<Event> get onObsolete => obsoleteEvent.forTarget(this);

  Stream<Event> get onProgress => progressEvent.forTarget(this);

  Stream<Event> get onUpdateReady => updateReadyEvent.forTarget(this);
}

@DocsEditable
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

  @DocsEditable @DomName('HTMLAreaElement.alt')
  String alt;

  @DocsEditable @DomName('HTMLAreaElement.coords')
  String coords;

  @DocsEditable @DomName('HTMLAreaElement.hash')
  final String hash;

  @DocsEditable @DomName('HTMLAreaElement.host')
  final String host;

  @DocsEditable @DomName('HTMLAreaElement.hostname')
  final String hostname;

  @DocsEditable @DomName('HTMLAreaElement.href')
  String href;

  @DocsEditable @DomName('HTMLAreaElement.pathname')
  final String pathname;

  @DocsEditable @DomName('HTMLAreaElement.ping')
  String ping;

  @DocsEditable @DomName('HTMLAreaElement.port')
  final String port;

  @DocsEditable @DomName('HTMLAreaElement.protocol')
  final String protocol;

  @DocsEditable @DomName('HTMLAreaElement.search')
  final String search;

  @DocsEditable @DomName('HTMLAreaElement.shape')
  String shape;

  @DocsEditable @DomName('HTMLAreaElement.target')
  String target;
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
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

  @DocsEditable @DomName('ArrayBuffer.byteLength')
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

  @DocsEditable @DomName('ArrayBufferView.buffer')
  final ArrayBuffer buffer;

  @DocsEditable @DomName('ArrayBufferView.byteLength')
  final int byteLength;

  @DocsEditable @DomName('ArrayBufferView.byteOffset')
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

  @DocsEditable @DomName('BarInfo.visible')
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

  @DocsEditable @DomName('HTMLBaseElement.href')
  String href;

  @DocsEditable @DomName('HTMLBaseElement.target')
  String target;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('HTMLBaseFontElement')
class BaseFontElement extends Element native "*HTMLBaseFontElement" {

  @DocsEditable @DomName('HTMLBaseFontElement.color')
  String color;

  @DocsEditable @DomName('HTMLBaseFontElement.face')
  String face;

  @DocsEditable @DomName('HTMLBaseFontElement.size')
  int size;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('BatteryManager')
class BatteryManager extends EventTarget native "*BatteryManager" {

  static const EventStreamProvider<Event> chargingChangeEvent = const EventStreamProvider<Event>('chargingchange');

  static const EventStreamProvider<Event> chargingTimeChangeEvent = const EventStreamProvider<Event>('chargingtimechange');

  static const EventStreamProvider<Event> dischargingTimeChangeEvent = const EventStreamProvider<Event>('dischargingtimechange');

  static const EventStreamProvider<Event> levelChangeEvent = const EventStreamProvider<Event>('levelchange');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  BatteryManagerEvents get on =>
    new BatteryManagerEvents(this);

  @DocsEditable @DomName('BatteryManager.charging')
  final bool charging;

  @DocsEditable @DomName('BatteryManager.chargingTime')
  final num chargingTime;

  @DocsEditable @DomName('BatteryManager.dischargingTime')
  final num dischargingTime;

  @DocsEditable @DomName('BatteryManager.level')
  final num level;

  @JSName('addEventListener')
  @DocsEditable @DomName('BatteryManager.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('BatteryManager.dispatchEvent')
  bool $dom_dispatchEvent(Event event) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('BatteryManager.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  Stream<Event> get onChargingChange => chargingChangeEvent.forTarget(this);

  Stream<Event> get onChargingTimeChange => chargingTimeChangeEvent.forTarget(this);

  Stream<Event> get onDischargingTimeChange => dischargingTimeChangeEvent.forTarget(this);

  Stream<Event> get onLevelChange => levelChangeEvent.forTarget(this);
}

@DocsEditable
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

  @DocsEditable @DomName('BeforeLoadEvent.url')
  final String url;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
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

  @DocsEditable @DomName('Blob.size')
  final int size;

  @DocsEditable @DomName('Blob.type')
  final String type;

  @DocsEditable @DomName('Blob.slice')
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

  static const EventStreamProvider<Event> beforeUnloadEvent = const EventStreamProvider<Event>('beforeunload');

  static const EventStreamProvider<Event> blurEvent = const EventStreamProvider<Event>('blur');

  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  static const EventStreamProvider<Event> focusEvent = const EventStreamProvider<Event>('focus');

  static const EventStreamProvider<HashChangeEvent> hashChangeEvent = const EventStreamProvider<HashChangeEvent>('hashchange');

  static const EventStreamProvider<Event> loadEvent = const EventStreamProvider<Event>('load');

  static const EventStreamProvider<MessageEvent> messageEvent = const EventStreamProvider<MessageEvent>('message');

  static const EventStreamProvider<Event> offlineEvent = const EventStreamProvider<Event>('offline');

  static const EventStreamProvider<Event> onlineEvent = const EventStreamProvider<Event>('online');

  static const EventStreamProvider<PopStateEvent> popStateEvent = const EventStreamProvider<PopStateEvent>('popstate');

  static const EventStreamProvider<Event> resizeEvent = const EventStreamProvider<Event>('resize');

  static const EventStreamProvider<StorageEvent> storageEvent = const EventStreamProvider<StorageEvent>('storage');

  static const EventStreamProvider<Event> unloadEvent = const EventStreamProvider<Event>('unload');

  @DocsEditable
  factory BodyElement() => document.$dom_createElement("body");

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  BodyElementEvents get on =>
    new BodyElementEvents(this);

  Stream<Event> get onBeforeUnload => beforeUnloadEvent.forTarget(this);

  Stream<Event> get onBlur => blurEvent.forTarget(this);

  Stream<Event> get onError => errorEvent.forTarget(this);

  Stream<Event> get onFocus => focusEvent.forTarget(this);

  Stream<HashChangeEvent> get onHashChange => hashChangeEvent.forTarget(this);

  Stream<Event> get onLoad => loadEvent.forTarget(this);

  Stream<MessageEvent> get onMessage => messageEvent.forTarget(this);

  Stream<Event> get onOffline => offlineEvent.forTarget(this);

  Stream<Event> get onOnline => onlineEvent.forTarget(this);

  Stream<PopStateEvent> get onPopState => popStateEvent.forTarget(this);

  Stream<Event> get onResize => resizeEvent.forTarget(this);

  Stream<StorageEvent> get onStorage => storageEvent.forTarget(this);

  Stream<Event> get onUnload => unloadEvent.forTarget(this);
}

@DocsEditable
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

  @DocsEditable @DomName('HTMLButtonElement.autofocus')
  bool autofocus;

  @DocsEditable @DomName('HTMLButtonElement.disabled')
  bool disabled;

  @DocsEditable @DomName('HTMLButtonElement.form')
  final FormElement form;

  @DocsEditable @DomName('HTMLButtonElement.formAction')
  String formAction;

  @DocsEditable @DomName('HTMLButtonElement.formEnctype')
  String formEnctype;

  @DocsEditable @DomName('HTMLButtonElement.formMethod')
  String formMethod;

  @DocsEditable @DomName('HTMLButtonElement.formNoValidate')
  bool formNoValidate;

  @DocsEditable @DomName('HTMLButtonElement.formTarget')
  String formTarget;

  @DocsEditable @DomName('HTMLButtonElement.labels')
  @Returns('NodeList') @Creates('NodeList')
  final List<Node> labels;

  @DocsEditable @DomName('HTMLButtonElement.name')
  String name;

  @DocsEditable @DomName('HTMLButtonElement.type')
  String type;

  @DocsEditable @DomName('HTMLButtonElement.validationMessage')
  final String validationMessage;

  @DocsEditable @DomName('HTMLButtonElement.validity')
  final ValidityState validity;

  @DocsEditable @DomName('HTMLButtonElement.value')
  String value;

  @DocsEditable @DomName('HTMLButtonElement.willValidate')
  final bool willValidate;

  @DocsEditable @DomName('HTMLButtonElement.checkValidity')
  bool checkValidity() native;

  @DocsEditable @DomName('HTMLButtonElement.setCustomValidity')
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


@DocsEditable
@DomName('HTMLCanvasElement')
class CanvasElement extends Element native "*HTMLCanvasElement" {

  @DocsEditable
  factory CanvasElement({int width, int height}) {
    var e = document.$dom_createElement("canvas");
    if (width != null) e.width = width;
    if (height != null) e.height = height;
    return e;
  }

  @DocsEditable @DomName('HTMLCanvasElement.height')
  int height;

  @DocsEditable @DomName('HTMLCanvasElement.width')
  int width;

  @JSName('toDataURL')
  @DocsEditable @DomName('HTMLCanvasElement.toDataURL')
  String toDataUrl(String type, [num quality]) native;


  CanvasRenderingContext getContext(String contextId) native;
  CanvasRenderingContext2D get context2d => getContext('2d');
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('CanvasGradient')
class CanvasGradient native "*CanvasGradient" {

  @DocsEditable @DomName('CanvasGradient.addColorStop')
  void addColorStop(num offset, String color) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('CanvasPattern')
class CanvasPattern native "*CanvasPattern" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('CanvasRenderingContext')
class CanvasRenderingContext native "*CanvasRenderingContext" {

  @DocsEditable @DomName('CanvasRenderingContext.canvas')
  final CanvasElement canvas;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('CanvasRenderingContext2D')
class CanvasRenderingContext2D extends CanvasRenderingContext native "*CanvasRenderingContext2D" {

  @DocsEditable @DomName('CanvasRenderingContext2D.fillStyle') @Creates('String|CanvasGradient|CanvasPattern') @Returns('String|CanvasGradient|CanvasPattern')
  dynamic fillStyle;

  @DocsEditable @DomName('CanvasRenderingContext2D.font')
  String font;

  @DocsEditable @DomName('CanvasRenderingContext2D.globalAlpha')
  num globalAlpha;

  @DocsEditable @DomName('CanvasRenderingContext2D.globalCompositeOperation')
  String globalCompositeOperation;

  @DocsEditable @DomName('CanvasRenderingContext2D.lineCap')
  String lineCap;

  @DocsEditable @DomName('CanvasRenderingContext2D.lineDashOffset')
  num lineDashOffset;

  @DocsEditable @DomName('CanvasRenderingContext2D.lineJoin')
  String lineJoin;

  @DocsEditable @DomName('CanvasRenderingContext2D.lineWidth')
  num lineWidth;

  @DocsEditable @DomName('CanvasRenderingContext2D.miterLimit')
  num miterLimit;

  @DocsEditable @DomName('CanvasRenderingContext2D.shadowBlur')
  num shadowBlur;

  @DocsEditable @DomName('CanvasRenderingContext2D.shadowColor')
  String shadowColor;

  @DocsEditable @DomName('CanvasRenderingContext2D.shadowOffsetX')
  num shadowOffsetX;

  @DocsEditable @DomName('CanvasRenderingContext2D.shadowOffsetY')
  num shadowOffsetY;

  @DocsEditable @DomName('CanvasRenderingContext2D.strokeStyle') @Creates('String|CanvasGradient|CanvasPattern') @Returns('String|CanvasGradient|CanvasPattern')
  dynamic strokeStyle;

  @DocsEditable @DomName('CanvasRenderingContext2D.textAlign')
  String textAlign;

  @DocsEditable @DomName('CanvasRenderingContext2D.textBaseline')
  String textBaseline;

  @DocsEditable @DomName('CanvasRenderingContext2D.webkitBackingStorePixelRatio')
  final num webkitBackingStorePixelRatio;

  @DocsEditable @DomName('CanvasRenderingContext2D.webkitImageSmoothingEnabled')
  bool webkitImageSmoothingEnabled;

  @DocsEditable @DomName('CanvasRenderingContext2D.webkitLineDash')
  List webkitLineDash;

  @DocsEditable @DomName('CanvasRenderingContext2D.webkitLineDashOffset')
  num webkitLineDashOffset;

  @DocsEditable @DomName('CanvasRenderingContext2D.arc')
  void arc(num x, num y, num radius, num startAngle, num endAngle, bool anticlockwise) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.arcTo')
  void arcTo(num x1, num y1, num x2, num y2, num radius) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.beginPath')
  void beginPath() native;

  @DocsEditable @DomName('CanvasRenderingContext2D.bezierCurveTo')
  void bezierCurveTo(num cp1x, num cp1y, num cp2x, num cp2y, num x, num y) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.clearRect')
  void clearRect(num x, num y, num width, num height) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.clip')
  void clip() native;

  @DocsEditable @DomName('CanvasRenderingContext2D.closePath')
  void closePath() native;

  ImageData createImageData(imagedata_OR_sw, [num sh]) {
    if ((imagedata_OR_sw is ImageData || imagedata_OR_sw == null) &&
        !?sh) {
      var imagedata_1 = _convertDartToNative_ImageData(imagedata_OR_sw);
      return _convertNativeToDart_ImageData(_createImageData_1(imagedata_1));
    }
    if ((imagedata_OR_sw is num || imagedata_OR_sw == null)) {
      return _convertNativeToDart_ImageData(_createImageData_2(imagedata_OR_sw, sh));
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('createImageData')
  @DocsEditable @DomName('CanvasRenderingContext2D.createImageData') @Creates('ImageData|=Object')
  _createImageData_1(imagedata) native;
  @JSName('createImageData')
  @DocsEditable @DomName('CanvasRenderingContext2D.createImageData') @Creates('ImageData|=Object')
  _createImageData_2(num sw, sh) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.createLinearGradient')
  CanvasGradient createLinearGradient(num x0, num y0, num x1, num y1) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.createPattern')
  CanvasPattern createPattern(canvas_OR_image, String repetitionType) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.createRadialGradient')
  CanvasGradient createRadialGradient(num x0, num y0, num r0, num x1, num y1, num r1) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.drawImage')
  void drawImage(canvas_OR_image_OR_video, num sx_OR_x, num sy_OR_y, [num sw_OR_width, num height_OR_sh, num dx, num dy, num dw, num dh]) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.fill')
  void fill() native;

  @DocsEditable @DomName('CanvasRenderingContext2D.fillRect')
  void fillRect(num x, num y, num width, num height) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.fillText')
  void fillText(String text, num x, num y, [num maxWidth]) native;

  ImageData getImageData(num sx, num sy, num sw, num sh) {
    return _convertNativeToDart_ImageData(_getImageData_1(sx, sy, sw, sh));
  }
  @JSName('getImageData')
  @DocsEditable @DomName('CanvasRenderingContext2D.getImageData') @Creates('ImageData|=Object')
  _getImageData_1(sx, sy, sw, sh) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.getLineDash')
  List<num> getLineDash() native;

  @DocsEditable @DomName('CanvasRenderingContext2D.isPointInPath')
  bool isPointInPath(num x, num y) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.lineTo')
  void lineTo(num x, num y) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.measureText')
  TextMetrics measureText(String text) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.moveTo')
  void moveTo(num x, num y) native;

  void putImageData(ImageData imagedata, num dx, num dy, [num dirtyX, num dirtyY, num dirtyWidth, num dirtyHeight]) {
    if (!?dirtyX &&
        !?dirtyY &&
        !?dirtyWidth &&
        !?dirtyHeight) {
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
  @DocsEditable @DomName('CanvasRenderingContext2D.putImageData')
  void _putImageData_1(imagedata, dx, dy) native;
  @JSName('putImageData')
  @DocsEditable @DomName('CanvasRenderingContext2D.putImageData')
  void _putImageData_2(imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.quadraticCurveTo')
  void quadraticCurveTo(num cpx, num cpy, num x, num y) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.rect')
  void rect(num x, num y, num width, num height) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.restore')
  void restore() native;

  @DocsEditable @DomName('CanvasRenderingContext2D.rotate')
  void rotate(num angle) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.save')
  void save() native;

  @DocsEditable @DomName('CanvasRenderingContext2D.scale')
  void scale(num sx, num sy) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.setLineDash')
  void setLineDash(List<num> dash) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.setTransform')
  void setTransform(num m11, num m12, num m21, num m22, num dx, num dy) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.stroke')
  void stroke() native;

  @DocsEditable @DomName('CanvasRenderingContext2D.strokeRect')
  void strokeRect(num x, num y, num width, num height, [num lineWidth]) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.strokeText')
  void strokeText(String text, num x, num y, [num maxWidth]) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.transform')
  void transform(num m11, num m12, num m21, num m22, num dx, num dy) native;

  @DocsEditable @DomName('CanvasRenderingContext2D.translate')
  void translate(num tx, num ty) native;

  ImageData webkitGetImageDataHD(num sx, num sy, num sw, num sh) {
    return _convertNativeToDart_ImageData(_webkitGetImageDataHD_1(sx, sy, sw, sh));
  }
  @JSName('webkitGetImageDataHD')
  @DocsEditable @DomName('CanvasRenderingContext2D.webkitGetImageDataHD') @Creates('ImageData|=Object')
  _webkitGetImageDataHD_1(sx, sy, sw, sh) native;

  void webkitPutImageDataHD(ImageData imagedata, num dx, num dy, [num dirtyX, num dirtyY, num dirtyWidth, num dirtyHeight]) {
    if (!?dirtyX &&
        !?dirtyY &&
        !?dirtyWidth &&
        !?dirtyHeight) {
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
  @DocsEditable @DomName('CanvasRenderingContext2D.webkitPutImageDataHD')
  void _webkitPutImageDataHD_1(imagedata, dx, dy) native;
  @JSName('webkitPutImageDataHD')
  @DocsEditable @DomName('CanvasRenderingContext2D.webkitPutImageDataHD')
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

  @DocsEditable @DomName('CharacterData.data')
  String data;

  @DocsEditable @DomName('CharacterData.length')
  final int length;

  @DocsEditable @DomName('CharacterData.appendData')
  void appendData(String data) native;

  @DocsEditable @DomName('CharacterData.deleteData')
  void deleteData(int offset, int length) native;

  @DocsEditable @DomName('CharacterData.insertData')
  void insertData(int offset, String data) native;

  @DocsEditable @DomName('CharacterData.remove')
  void remove() native;

  @DocsEditable @DomName('CharacterData.replaceData')
  void replaceData(int offset, int length, String data) native;

  @DocsEditable @DomName('CharacterData.substringData')
  String substringData(int offset, int length) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('ClientRect')
class ClientRect native "*ClientRect" {

  @DocsEditable @DomName('ClientRect.bottom')
  final num bottom;

  @DocsEditable @DomName('ClientRect.height')
  final num height;

  @DocsEditable @DomName('ClientRect.left')
  final num left;

  @DocsEditable @DomName('ClientRect.right')
  final num right;

  @DocsEditable @DomName('ClientRect.top')
  final num top;

  @DocsEditable @DomName('ClientRect.width')
  final num width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('Clipboard')
class Clipboard native "*Clipboard" {

  @DocsEditable @DomName('Clipboard.dropEffect')
  String dropEffect;

  @DocsEditable @DomName('Clipboard.effectAllowed')
  String effectAllowed;

  @DocsEditable @DomName('Clipboard.files')
  @Returns('FileList') @Creates('FileList')
  final List<File> files;

  @DocsEditable @DomName('Clipboard.items')
  final DataTransferItemList items;

  @DocsEditable @DomName('Clipboard.types')
  final List types;

  @DocsEditable @DomName('Clipboard.clearData')
  void clearData([String type]) native;

  @DocsEditable @DomName('Clipboard.getData')
  String getData(String type) native;

  @DocsEditable @DomName('Clipboard.setData')
  bool setData(String type, String data) native;

  @DocsEditable @DomName('Clipboard.setDragImage')
  void setDragImage(ImageElement image, int x, int y) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('CloseEvent')
class CloseEvent extends Event native "*CloseEvent" {

  @DocsEditable @DomName('CloseEvent.code')
  final int code;

  @DocsEditable @DomName('CloseEvent.reason')
  final String reason;

  @DocsEditable @DomName('CloseEvent.wasClean')
  final bool wasClean;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('Comment')
class Comment extends CharacterData native "*Comment" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('CompositionEvent')
class CompositionEvent extends UIEvent native "*CompositionEvent" {

  @DocsEditable @DomName('CompositionEvent.data')
  final String data;

  @DocsEditable @DomName('CompositionEvent.initCompositionEvent')
  void initCompositionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Window viewArg, String dataArg) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Console')
class Console {

  static Console safeConsole = new Console();

  bool get _isConsoleDefined => JS('bool', "typeof console != 'undefined'");

  @DocsEditable
  @DomName('Console.memory')
  MemoryInfo get memory => _isConsoleDefined ?
      JS('MemoryInfo', 'console.memory') : null;

  @DocsEditable
  @DomName('Console.profiles')
  List<ScriptProfile> get profiles => _isConsoleDefined ?
      JS('List<ScriptProfile>', 'console.profiles') : null;

  @DocsEditable
  @DomName('Console.assertCondition')
  void assertCondition(bool condition, Object arg) => _isConsoleDefined ?
      JS('void', 'console.assertCondition(#, #)', condition, arg) : null;

  @DocsEditable
  @DomName('Console.count')
  void count(Object arg) => _isConsoleDefined ?
      JS('void', 'console.count(#)', arg) : null;

  @DocsEditable
  @DomName('Console.debug')
  void debug(Object arg) => _isConsoleDefined ?
      JS('void', 'console.debug(#)', arg) : null;

  @DocsEditable
  @DomName('Console.dir')
  void dir(Object arg) => _isConsoleDefined ?
      JS('void', 'console.debug(#)', arg) : null;

  @DocsEditable
  @DomName('Console.dirxml')
  void dirxml(Object arg) => _isConsoleDefined ?
      JS('void', 'console.dirxml(#)', arg) : null;

  @DocsEditable
  @DomName('Console.error')
  void error(Object arg) => _isConsoleDefined ?
      JS('void', 'console.error(#)', arg) : null;

  @DocsEditable
  @DomName('Console.group')
  void group(Object arg) => _isConsoleDefined ?
      JS('void', 'console.group(#)', arg) : null;

  @DocsEditable
  @DomName('Console.groupCollapsed')
  void groupCollapsed(Object arg) => _isConsoleDefined ?
      JS('void', 'console.groupCollapsed(#)', arg) : null;

  @DocsEditable
  @DomName('Console.groupEnd')
  void groupEnd() => _isConsoleDefined ?
      JS('void', 'console.groupEnd()') : null;

  @DocsEditable
  @DomName('Console.info')
  void info(Object arg) => _isConsoleDefined ?
      JS('void', 'console.info(#)', arg) : null;

  @DocsEditable
  @DomName('Console.log')
  void log(Object arg) => _isConsoleDefined ?
      JS('void', 'console.log(#)', arg) : null;

  @DocsEditable
  @DomName('Console.markTimeline')
  void markTimeline(Object arg) => _isConsoleDefined ?
      JS('void', 'console.markTimeline(#)', arg) : null;

  @DocsEditable
  @DomName('Console.profile')
  void profile(String title) => _isConsoleDefined ?
      JS('void', 'console.profile(#)', title) : null;

  @DocsEditable
  @DomName('Console.profileEnd')
  void profileEnd(String title) => _isConsoleDefined ?
      JS('void', 'console.profileEnd(#)', title) : null;

  @DocsEditable
  @DomName('Console.time')
  void time(String title) => _isConsoleDefined ?
      JS('void', 'console.time(#)', title) : null;

  @DocsEditable
  @DomName('Console.timeEnd')
  void timeEnd(String title, Object arg) => _isConsoleDefined ?
      JS('void', 'console.timeEnd(#, #)', title, arg) : null;

  @DocsEditable
  @DomName('Console.timeStamp')
  void timeStamp(Object arg) => _isConsoleDefined ?
      JS('void', 'console.timeStamp(#)', arg) : null;

  @DocsEditable
  @DomName('Console.trace')
  void trace(Object arg) => _isConsoleDefined ?
      JS('void', 'console.trace(#)', arg) : null;

  @DocsEditable
  @DomName('Console.warn')
  void warn(Object arg) => _isConsoleDefined ?
      JS('void', 'console.warn(#)', arg) : null;

  @DocsEditable @DomName('Console.clear')
  void clear(Object arg) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('HTMLContentElement')
@SupportedBrowser(SupportedBrowser.CHROME, '25')
@Experimental()
class ContentElement extends Element native "*HTMLContentElement" {

  @DocsEditable
  factory ContentElement() => document.$dom_createElement("content");

  /// Checks if this type is supported on the current platform.
  static bool get supported => Element.isTagSupported('content');

  @DocsEditable @DomName('HTMLContentElement.resetStyleInheritance')
  bool resetStyleInheritance;

  @DocsEditable @DomName('HTMLContentElement.select')
  String select;

  @DocsEditable @DomName('HTMLContentElement.getDistributedNodes')
  @Returns('NodeList') @Creates('NodeList')
  List<Node> getDistributedNodes() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('Coordinates')
class Coordinates native "*Coordinates" {

  @DocsEditable @DomName('Coordinates.accuracy')
  final num accuracy;

  @DocsEditable @DomName('Coordinates.altitude')
  final num altitude;

  @DocsEditable @DomName('Coordinates.altitudeAccuracy')
  final num altitudeAccuracy;

  @DocsEditable @DomName('Coordinates.heading')
  final num heading;

  @DocsEditable @DomName('Coordinates.latitude')
  final num latitude;

  @DocsEditable @DomName('Coordinates.longitude')
  final num longitude;

  @DocsEditable @DomName('Coordinates.speed')
  final num speed;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('Counter')
class Counter native "*Counter" {

  @DocsEditable @DomName('Counter.identifier')
  final String identifier;

  @DocsEditable @DomName('Counter.listStyle')
  final String listStyle;

  @DocsEditable @DomName('Counter.separator')
  final String separator;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('Crypto')
class Crypto native "*Crypto" {

  @DocsEditable @DomName('Crypto.getRandomValues')
  void getRandomValues(ArrayBufferView array) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('CSSCharsetRule')
class CssCharsetRule extends CssRule native "*CSSCharsetRule" {

  @DocsEditable @DomName('CSSCharsetRule.encoding')
  String encoding;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('CSSFontFaceRule')
class CssFontFaceRule extends CssRule native "*CSSFontFaceRule" {

  @DocsEditable @DomName('CSSFontFaceRule.style')
  final CssStyleDeclaration style;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('CSSImportRule')
class CssImportRule extends CssRule native "*CSSImportRule" {

  @DocsEditable @DomName('CSSImportRule.href')
  final String href;

  @DocsEditable @DomName('CSSImportRule.media')
  final MediaList media;

  @DocsEditable @DomName('CSSImportRule.styleSheet')
  final CssStyleSheet styleSheet;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('WebKitCSSKeyframeRule')
class CssKeyframeRule extends CssRule native "*WebKitCSSKeyframeRule" {

  @DocsEditable @DomName('WebKitCSSKeyframeRule.keyText')
  String keyText;

  @DocsEditable @DomName('WebKitCSSKeyframeRule.style')
  final CssStyleDeclaration style;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('WebKitCSSKeyframesRule')
class CssKeyframesRule extends CssRule native "*WebKitCSSKeyframesRule" {

  @DocsEditable @DomName('WebKitCSSKeyframesRule.cssRules')
  @Returns('_CssRuleList') @Creates('_CssRuleList')
  final List<CssRule> cssRules;

  @DocsEditable @DomName('WebKitCSSKeyframesRule.name')
  String name;

  @DocsEditable @DomName('WebKitCSSKeyframesRule.deleteRule')
  void deleteRule(String key) native;

  @DocsEditable @DomName('WebKitCSSKeyframesRule.findRule')
  CssKeyframeRule findRule(String key) native;

  @DocsEditable @DomName('WebKitCSSKeyframesRule.insertRule')
  void insertRule(String rule) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('WebKitCSSMatrix')
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

  @DocsEditable @DomName('WebKitCSSMatrix.a')
  num a;

  @DocsEditable @DomName('WebKitCSSMatrix.b')
  num b;

  @DocsEditable @DomName('WebKitCSSMatrix.c')
  num c;

  @DocsEditable @DomName('WebKitCSSMatrix.d')
  num d;

  @DocsEditable @DomName('WebKitCSSMatrix.e')
  num e;

  @DocsEditable @DomName('WebKitCSSMatrix.f')
  num f;

  @DocsEditable @DomName('WebKitCSSMatrix.m11')
  num m11;

  @DocsEditable @DomName('WebKitCSSMatrix.m12')
  num m12;

  @DocsEditable @DomName('WebKitCSSMatrix.m13')
  num m13;

  @DocsEditable @DomName('WebKitCSSMatrix.m14')
  num m14;

  @DocsEditable @DomName('WebKitCSSMatrix.m21')
  num m21;

  @DocsEditable @DomName('WebKitCSSMatrix.m22')
  num m22;

  @DocsEditable @DomName('WebKitCSSMatrix.m23')
  num m23;

  @DocsEditable @DomName('WebKitCSSMatrix.m24')
  num m24;

  @DocsEditable @DomName('WebKitCSSMatrix.m31')
  num m31;

  @DocsEditable @DomName('WebKitCSSMatrix.m32')
  num m32;

  @DocsEditable @DomName('WebKitCSSMatrix.m33')
  num m33;

  @DocsEditable @DomName('WebKitCSSMatrix.m34')
  num m34;

  @DocsEditable @DomName('WebKitCSSMatrix.m41')
  num m41;

  @DocsEditable @DomName('WebKitCSSMatrix.m42')
  num m42;

  @DocsEditable @DomName('WebKitCSSMatrix.m43')
  num m43;

  @DocsEditable @DomName('WebKitCSSMatrix.m44')
  num m44;

  @DocsEditable @DomName('WebKitCSSMatrix.inverse')
  CssMatrix inverse() native;

  @DocsEditable @DomName('WebKitCSSMatrix.multiply')
  CssMatrix multiply(CssMatrix secondMatrix) native;

  @DocsEditable @DomName('WebKitCSSMatrix.rotate')
  CssMatrix rotate(num rotX, num rotY, num rotZ) native;

  @DocsEditable @DomName('WebKitCSSMatrix.rotateAxisAngle')
  CssMatrix rotateAxisAngle(num x, num y, num z, num angle) native;

  @DocsEditable @DomName('WebKitCSSMatrix.scale')
  CssMatrix scale(num scaleX, num scaleY, num scaleZ) native;

  @DocsEditable @DomName('WebKitCSSMatrix.setMatrixValue')
  void setMatrixValue(String string) native;

  @DocsEditable @DomName('WebKitCSSMatrix.skewX')
  CssMatrix skewX(num angle) native;

  @DocsEditable @DomName('WebKitCSSMatrix.skewY')
  CssMatrix skewY(num angle) native;

  @DocsEditable @DomName('WebKitCSSMatrix.toString')
  String toString() native;

  @DocsEditable @DomName('WebKitCSSMatrix.translate')
  CssMatrix translate(num x, num y, num z) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('CSSMediaRule')
class CssMediaRule extends CssRule native "*CSSMediaRule" {

  @DocsEditable @DomName('CSSMediaRule.cssRules')
  @Returns('_CssRuleList') @Creates('_CssRuleList')
  final List<CssRule> cssRules;

  @DocsEditable @DomName('CSSMediaRule.media')
  final MediaList media;

  @DocsEditable @DomName('CSSMediaRule.deleteRule')
  void deleteRule(int index) native;

  @DocsEditable @DomName('CSSMediaRule.insertRule')
  int insertRule(String rule, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('CSSPageRule')
class CssPageRule extends CssRule native "*CSSPageRule" {

  @DocsEditable @DomName('CSSPageRule.selectorText')
  String selectorText;

  @DocsEditable @DomName('CSSPageRule.style')
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

  @DocsEditable @DomName('CSSPrimitiveValue.primitiveType')
  final int primitiveType;

  @DocsEditable @DomName('CSSPrimitiveValue.getCounterValue')
  Counter getCounterValue() native;

  @DocsEditable @DomName('CSSPrimitiveValue.getFloatValue')
  num getFloatValue(int unitType) native;

  @JSName('getRGBColorValue')
  @DocsEditable @DomName('CSSPrimitiveValue.getRGBColorValue')
  RgbColor getRgbColorValue() native;

  @DocsEditable @DomName('CSSPrimitiveValue.getRectValue')
  Rect getRectValue() native;

  @DocsEditable @DomName('CSSPrimitiveValue.getStringValue')
  String getStringValue() native;

  @DocsEditable @DomName('CSSPrimitiveValue.setFloatValue')
  void setFloatValue(int unitType, num floatValue) native;

  @DocsEditable @DomName('CSSPrimitiveValue.setStringValue')
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

  @DocsEditable @DomName('CSSRule.cssText')
  String cssText;

  @DocsEditable @DomName('CSSRule.parentRule')
  final CssRule parentRule;

  @DocsEditable @DomName('CSSRule.parentStyleSheet')
  final CssStyleSheet parentStyleSheet;

  @DocsEditable @DomName('CSSRule.type')
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

@DocsEditable
@DomName('CSSStyleDeclaration')
class CssStyleDeclaration native "*CSSStyleDeclaration" {
  factory CssStyleDeclaration() => _CssStyleDeclarationFactoryProvider.createCssStyleDeclaration();
  factory CssStyleDeclaration.css(String css) =>
      _CssStyleDeclarationFactoryProvider.createCssStyleDeclaration_css(css);


  @DocsEditable @DomName('CSSStyleDeclaration.cssText')
  String cssText;

  @DocsEditable @DomName('CSSStyleDeclaration.length')
  final int length;

  @DocsEditable @DomName('CSSStyleDeclaration.parentRule')
  final CssRule parentRule;

  @JSName('getPropertyCSSValue')
  @DocsEditable @DomName('CSSStyleDeclaration.getPropertyCSSValue')
  CssValue getPropertyCssValue(String propertyName) native;

  @DocsEditable @DomName('CSSStyleDeclaration.getPropertyPriority')
  String getPropertyPriority(String propertyName) native;

  @DocsEditable @DomName('CSSStyleDeclaration.getPropertyShorthand')
  String getPropertyShorthand(String propertyName) native;

  @JSName('getPropertyValue')
  @DocsEditable @DomName('CSSStyleDeclaration.getPropertyValue')
  String _getPropertyValue(String propertyName) native;

  @DocsEditable @DomName('CSSStyleDeclaration.isPropertyImplicit')
  bool isPropertyImplicit(String propertyName) native;

  @DocsEditable @DomName('CSSStyleDeclaration.item')
  String item(int index) native;

  @DocsEditable @DomName('CSSStyleDeclaration.removeProperty')
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

  @DocsEditable @DomName('CSSStyleRule.selectorText')
  String selectorText;

  @DocsEditable @DomName('CSSStyleRule.style')
  final CssStyleDeclaration style;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('CSSStyleSheet')
class CssStyleSheet extends StyleSheet native "*CSSStyleSheet" {

  @DocsEditable @DomName('CSSStyleSheet.cssRules')
  @Returns('_CssRuleList') @Creates('_CssRuleList')
  final List<CssRule> cssRules;

  @DocsEditable @DomName('CSSStyleSheet.ownerRule')
  final CssRule ownerRule;

  @DocsEditable @DomName('CSSStyleSheet.rules')
  @Returns('_CssRuleList') @Creates('_CssRuleList')
  final List<CssRule> rules;

  @DocsEditable @DomName('CSSStyleSheet.addRule')
  int addRule(String selector, String style, [int index]) native;

  @DocsEditable @DomName('CSSStyleSheet.deleteRule')
  void deleteRule(int index) native;

  @DocsEditable @DomName('CSSStyleSheet.insertRule')
  int insertRule(String rule, int index) native;

  @DocsEditable @DomName('CSSStyleSheet.removeRule')
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

  @DocsEditable @DomName('WebKitCSSTransformValue.operationType')
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

  @DocsEditable @DomName('CSSValue.cssText')
  String cssText;

  @DocsEditable @DomName('CSSValue.cssValueType')
  final int cssValueType;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('CustomEvent')
class CustomEvent extends Event native "*CustomEvent" {
  factory CustomEvent(String type, [bool canBubble = true, bool cancelable = true,
      Object detail]) => _CustomEventFactoryProvider.createCustomEvent(
      type, canBubble, cancelable, detail);

  @DocsEditable @DomName('CustomEvent.detail')
  final Object detail;

  @JSName('initCustomEvent')
  @DocsEditable @DomName('CustomEvent.initCustomEvent')
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

  @DocsEditable @DomName('HTMLDataListElement.options')
  final HtmlCollection options;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('DataTransferItem')
class DataTransferItem native "*DataTransferItem" {

  @DocsEditable @DomName('DataTransferItem.kind')
  final String kind;

  @DocsEditable @DomName('DataTransferItem.type')
  final String type;

  @DocsEditable @DomName('DataTransferItem.getAsFile')
  Blob getAsFile() native;

  @DocsEditable @DomName('DataTransferItem.getAsString')
  void getAsString([StringCallback callback]) native;

  @DocsEditable @DomName('DataTransferItem.webkitGetAsEntry')
  Entry webkitGetAsEntry() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('DataTransferItemList')
class DataTransferItemList native "*DataTransferItemList" {

  @DocsEditable @DomName('DataTransferItemList.length')
  final int length;

  @DocsEditable @DomName('DataTransferItemList.add')
  void add(data_OR_file, [String type]) native;

  @DocsEditable @DomName('DataTransferItemList.clear')
  void clear() native;

  @DocsEditable @DomName('DataTransferItemList.item')
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

  @DocsEditable @DomName('DataView.getFloat32')
  num getFloat32(int byteOffset, {bool littleEndian}) native;

  @DocsEditable @DomName('DataView.getFloat64')
  num getFloat64(int byteOffset, {bool littleEndian}) native;

  @DocsEditable @DomName('DataView.getInt16')
  int getInt16(int byteOffset, {bool littleEndian}) native;

  @DocsEditable @DomName('DataView.getInt32')
  int getInt32(int byteOffset, {bool littleEndian}) native;

  @DocsEditable @DomName('DataView.getInt8')
  int getInt8(int byteOffset) native;

  @DocsEditable @DomName('DataView.getUint16')
  int getUint16(int byteOffset, {bool littleEndian}) native;

  @DocsEditable @DomName('DataView.getUint32')
  int getUint32(int byteOffset, {bool littleEndian}) native;

  @DocsEditable @DomName('DataView.getUint8')
  int getUint8(int byteOffset) native;

  @DocsEditable @DomName('DataView.setFloat32')
  void setFloat32(int byteOffset, num value, {bool littleEndian}) native;

  @DocsEditable @DomName('DataView.setFloat64')
  void setFloat64(int byteOffset, num value, {bool littleEndian}) native;

  @DocsEditable @DomName('DataView.setInt16')
  void setInt16(int byteOffset, int value, {bool littleEndian}) native;

  @DocsEditable @DomName('DataView.setInt32')
  void setInt32(int byteOffset, int value, {bool littleEndian}) native;

  @DocsEditable @DomName('DataView.setInt8')
  void setInt8(int byteOffset, int value) native;

  @DocsEditable @DomName('DataView.setUint16')
  void setUint16(int byteOffset, int value, {bool littleEndian}) native;

  @DocsEditable @DomName('DataView.setUint32')
  void setUint32(int byteOffset, int value, {bool littleEndian}) native;

  @DocsEditable @DomName('DataView.setUint8')
  void setUint8(int byteOffset, int value) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('Database')
class Database native "*Database" {

  @DocsEditable @DomName('Database.version')
  final String version;

  @DocsEditable @DomName('Database.changeVersion')
  void changeVersion(String oldVersion, String newVersion, [SqlTransactionCallback callback, SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) native;

  @DocsEditable @DomName('Database.readTransaction')
  void readTransaction(SqlTransactionCallback callback, [SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) native;

  @DocsEditable @DomName('Database.transaction')
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
class DatabaseSync native "*DatabaseSync" {

  @DocsEditable @DomName('DatabaseSync.lastErrorMessage')
  final String lastErrorMessage;

  @DocsEditable @DomName('DatabaseSync.version')
  final String version;

  @DocsEditable @DomName('DatabaseSync.changeVersion')
  void changeVersion(String oldVersion, String newVersion, [SqlTransactionSyncCallback callback]) native;

  @DocsEditable @DomName('DatabaseSync.readTransaction')
  void readTransaction(SqlTransactionSyncCallback callback) native;

  @DocsEditable @DomName('DatabaseSync.transaction')
  void transaction(SqlTransactionSyncCallback callback) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('DedicatedWorkerContext')
class DedicatedWorkerContext extends WorkerContext native "*DedicatedWorkerContext" {

  static const EventStreamProvider<MessageEvent> messageEvent = const EventStreamProvider<MessageEvent>('message');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
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
  @DocsEditable @DomName('DedicatedWorkerContext.postMessage')
  void _postMessage_1(message, List messagePorts) native;
  @JSName('postMessage')
  @DocsEditable @DomName('DedicatedWorkerContext.postMessage')
  void _postMessage_2(message) native;

  Stream<MessageEvent> get onMessage => messageEvent.forTarget(this);
}

@DocsEditable
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
@Experimental()
class DetailsElement extends Element native "*HTMLDetailsElement" {

  @DocsEditable
  factory DetailsElement() => document.$dom_createElement("details");

  /// Checks if this type is supported on the current platform.
  static bool get supported => Element.isTagSupported('details');

  @DocsEditable @DomName('HTMLDetailsElement.open')
  bool open;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('DeviceMotionEvent')
class DeviceMotionEvent extends Event native "*DeviceMotionEvent" {

  @DocsEditable @DomName('DeviceMotionEvent.interval')
  final num interval;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('DeviceOrientationEvent')
class DeviceOrientationEvent extends Event native "*DeviceOrientationEvent" {

  @DocsEditable @DomName('DeviceOrientationEvent.absolute')
  final bool absolute;

  @DocsEditable @DomName('DeviceOrientationEvent.alpha')
  final num alpha;

  @DocsEditable @DomName('DeviceOrientationEvent.beta')
  final num beta;

  @DocsEditable @DomName('DeviceOrientationEvent.gamma')
  final num gamma;

  @DocsEditable @DomName('DeviceOrientationEvent.initDeviceOrientationEvent')
  void initDeviceOrientationEvent(String type, bool bubbles, bool cancelable, num alpha, num beta, num gamma, bool absolute) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('DirectoryEntry')
class DirectoryEntry extends Entry native "*DirectoryEntry" {

  @DocsEditable @DomName('DirectoryEntry.createReader')
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
  @DocsEditable @DomName('DirectoryEntry.getDirectory')
  void _getDirectory_1(path, options, EntryCallback successCallback, ErrorCallback errorCallback) native;
  @JSName('getDirectory')
  @DocsEditable @DomName('DirectoryEntry.getDirectory')
  void _getDirectory_2(path, options, EntryCallback successCallback) native;
  @JSName('getDirectory')
  @DocsEditable @DomName('DirectoryEntry.getDirectory')
  void _getDirectory_3(path, options) native;
  @JSName('getDirectory')
  @DocsEditable @DomName('DirectoryEntry.getDirectory')
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
  @DocsEditable @DomName('DirectoryEntry.getFile')
  void _getFile_1(path, options, EntryCallback successCallback, ErrorCallback errorCallback) native;
  @JSName('getFile')
  @DocsEditable @DomName('DirectoryEntry.getFile')
  void _getFile_2(path, options, EntryCallback successCallback) native;
  @JSName('getFile')
  @DocsEditable @DomName('DirectoryEntry.getFile')
  void _getFile_3(path, options) native;
  @JSName('getFile')
  @DocsEditable @DomName('DirectoryEntry.getFile')
  void _getFile_4(path) native;

  @DocsEditable @DomName('DirectoryEntry.removeRecursively')
  void removeRecursively(VoidCallback successCallback, [ErrorCallback errorCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('DirectoryEntrySync')
class DirectoryEntrySync extends EntrySync native "*DirectoryEntrySync" {

  @DocsEditable @DomName('DirectoryEntrySync.createReader')
  DirectoryReaderSync createReader() native;

  DirectoryEntrySync getDirectory(String path, Map flags) {
    var flags_1 = convertDartToNative_Dictionary(flags);
    return _getDirectory_1(path, flags_1);
  }
  @JSName('getDirectory')
  @DocsEditable @DomName('DirectoryEntrySync.getDirectory')
  DirectoryEntrySync _getDirectory_1(path, flags) native;

  FileEntrySync getFile(String path, Map flags) {
    var flags_1 = convertDartToNative_Dictionary(flags);
    return _getFile_1(path, flags_1);
  }
  @JSName('getFile')
  @DocsEditable @DomName('DirectoryEntrySync.getFile')
  FileEntrySync _getFile_1(path, flags) native;

  @DocsEditable @DomName('DirectoryEntrySync.removeRecursively')
  void removeRecursively() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('DirectoryReader')
class DirectoryReader native "*DirectoryReader" {

  @DocsEditable @DomName('DirectoryReader.readEntries')
  void readEntries(EntriesCallback successCallback, [ErrorCallback errorCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('DirectoryReaderSync')
class DirectoryReaderSync native "*DirectoryReaderSync" {

  @DocsEditable @DomName('DirectoryReaderSync.readEntries')
  @Returns('_EntryArraySync') @Creates('_EntryArraySync')
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


@DocsEditable
@DomName('Document')
/**
 * The base class for all documents.
 *
 * Each web page loaded in the browser has its own [Document] object, which is
 * typically an [HtmlDocument].
 *
 * If you aren't comfortable with DOM concepts, see the Dart tutorial
 * [Target 2: Connect Dart & HTML](http://www.dartlang.org/docs/tutorials/connect-dart-html/).
 */
class Document extends Node  native "*Document"
{


  static const EventStreamProvider<Event> abortEvent = const EventStreamProvider<Event>('abort');

  static const EventStreamProvider<Event> beforeCopyEvent = const EventStreamProvider<Event>('beforecopy');

  static const EventStreamProvider<Event> beforeCutEvent = const EventStreamProvider<Event>('beforecut');

  static const EventStreamProvider<Event> beforePasteEvent = const EventStreamProvider<Event>('beforepaste');

  static const EventStreamProvider<Event> blurEvent = const EventStreamProvider<Event>('blur');

  static const EventStreamProvider<Event> changeEvent = const EventStreamProvider<Event>('change');

  static const EventStreamProvider<MouseEvent> clickEvent = const EventStreamProvider<MouseEvent>('click');

  static const EventStreamProvider<MouseEvent> contextMenuEvent = const EventStreamProvider<MouseEvent>('contextmenu');

  static const EventStreamProvider<Event> copyEvent = const EventStreamProvider<Event>('copy');

  static const EventStreamProvider<Event> cutEvent = const EventStreamProvider<Event>('cut');

  static const EventStreamProvider<Event> doubleClickEvent = const EventStreamProvider<Event>('dblclick');

  static const EventStreamProvider<MouseEvent> dragEvent = const EventStreamProvider<MouseEvent>('drag');

  static const EventStreamProvider<MouseEvent> dragEndEvent = const EventStreamProvider<MouseEvent>('dragend');

  static const EventStreamProvider<MouseEvent> dragEnterEvent = const EventStreamProvider<MouseEvent>('dragenter');

  static const EventStreamProvider<MouseEvent> dragLeaveEvent = const EventStreamProvider<MouseEvent>('dragleave');

  static const EventStreamProvider<MouseEvent> dragOverEvent = const EventStreamProvider<MouseEvent>('dragover');

  static const EventStreamProvider<MouseEvent> dragStartEvent = const EventStreamProvider<MouseEvent>('dragstart');

  static const EventStreamProvider<MouseEvent> dropEvent = const EventStreamProvider<MouseEvent>('drop');

  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  static const EventStreamProvider<Event> focusEvent = const EventStreamProvider<Event>('focus');

  static const EventStreamProvider<Event> inputEvent = const EventStreamProvider<Event>('input');

  static const EventStreamProvider<Event> invalidEvent = const EventStreamProvider<Event>('invalid');

  static const EventStreamProvider<KeyboardEvent> keyDownEvent = const EventStreamProvider<KeyboardEvent>('keydown');

  static const EventStreamProvider<KeyboardEvent> keyPressEvent = const EventStreamProvider<KeyboardEvent>('keypress');

  static const EventStreamProvider<KeyboardEvent> keyUpEvent = const EventStreamProvider<KeyboardEvent>('keyup');

  static const EventStreamProvider<Event> loadEvent = const EventStreamProvider<Event>('load');

  static const EventStreamProvider<MouseEvent> mouseDownEvent = const EventStreamProvider<MouseEvent>('mousedown');

  static const EventStreamProvider<MouseEvent> mouseMoveEvent = const EventStreamProvider<MouseEvent>('mousemove');

  static const EventStreamProvider<MouseEvent> mouseOutEvent = const EventStreamProvider<MouseEvent>('mouseout');

  static const EventStreamProvider<MouseEvent> mouseOverEvent = const EventStreamProvider<MouseEvent>('mouseover');

  static const EventStreamProvider<MouseEvent> mouseUpEvent = const EventStreamProvider<MouseEvent>('mouseup');

  static const EventStreamProvider<WheelEvent> mouseWheelEvent = const EventStreamProvider<WheelEvent>('mousewheel');

  static const EventStreamProvider<Event> pasteEvent = const EventStreamProvider<Event>('paste');

  static const EventStreamProvider<Event> readyStateChangeEvent = const EventStreamProvider<Event>('readystatechange');

  static const EventStreamProvider<Event> resetEvent = const EventStreamProvider<Event>('reset');

  static const EventStreamProvider<Event> scrollEvent = const EventStreamProvider<Event>('scroll');

  static const EventStreamProvider<Event> searchEvent = const EventStreamProvider<Event>('search');

  static const EventStreamProvider<Event> selectEvent = const EventStreamProvider<Event>('select');

  static const EventStreamProvider<Event> selectionChangeEvent = const EventStreamProvider<Event>('selectionchange');

  static const EventStreamProvider<Event> selectStartEvent = const EventStreamProvider<Event>('selectstart');

  static const EventStreamProvider<Event> submitEvent = const EventStreamProvider<Event>('submit');

  static const EventStreamProvider<TouchEvent> touchCancelEvent = const EventStreamProvider<TouchEvent>('touchcancel');

  static const EventStreamProvider<TouchEvent> touchEndEvent = const EventStreamProvider<TouchEvent>('touchend');

  static const EventStreamProvider<TouchEvent> touchMoveEvent = const EventStreamProvider<TouchEvent>('touchmove');

  static const EventStreamProvider<TouchEvent> touchStartEvent = const EventStreamProvider<TouchEvent>('touchstart');

  static const EventStreamProvider<Event> fullscreenChangeEvent = const EventStreamProvider<Event>('webkitfullscreenchange');

  static const EventStreamProvider<Event> fullscreenErrorEvent = const EventStreamProvider<Event>('webkitfullscreenerror');

  static const EventStreamProvider<Event> pointerLockChangeEvent = const EventStreamProvider<Event>('webkitpointerlockchange');

  static const EventStreamProvider<Event> pointerLockErrorEvent = const EventStreamProvider<Event>('webkitpointerlockerror');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  DocumentEvents get on =>
    new DocumentEvents(this);

  @JSName('body')
  @DocsEditable @DomName('Document.body')
  Element $dom_body;

  @DocsEditable @DomName('Document.charset')
  String charset;

  @DocsEditable @DomName('Document.cookie')
  String cookie;

  WindowBase get window => _convertNativeToDart_Window(this._window);
  @JSName('defaultView')
  @DocsEditable @DomName('Document.window') @Creates('Window|=Object') @Returns('Window|=Object')
  final dynamic _window;

  @DocsEditable @DomName('Document.documentElement')
  final Element documentElement;

  @DocsEditable @DomName('Document.domain')
  final String domain;

  @JSName('head')
  @DocsEditable @DomName('Document.head')
  final HeadElement $dom_head;

  @DocsEditable @DomName('Document.implementation')
  final DomImplementation implementation;

  @JSName('lastModified')
  @DocsEditable @DomName('Document.lastModified')
  final String $dom_lastModified;

  @JSName('preferredStylesheetSet')
  @DocsEditable @DomName('Document.preferredStylesheetSet')
  final String $dom_preferredStylesheetSet;

  @DocsEditable @DomName('Document.readyState')
  final String readyState;

  @JSName('referrer')
  @DocsEditable @DomName('Document.referrer')
  final String $dom_referrer;

  @JSName('selectedStylesheetSet')
  @DocsEditable @DomName('Document.selectedStylesheetSet')
  String $dom_selectedStylesheetSet;

  @JSName('styleSheets')
  @DocsEditable @DomName('Document.styleSheets')
  @Returns('_StyleSheetList') @Creates('_StyleSheetList')
  final List<StyleSheet> $dom_styleSheets;

  @JSName('title')
  @DocsEditable @DomName('Document.title')
  String $dom_title;

  @JSName('webkitFullscreenElement')
  @DocsEditable @DomName('Document.webkitFullscreenElement')
  final Element $dom_webkitFullscreenElement;

  @JSName('webkitFullscreenEnabled')
  @DocsEditable @DomName('Document.webkitFullscreenEnabled')
  final bool $dom_webkitFullscreenEnabled;

  @JSName('webkitHidden')
  @DocsEditable @DomName('Document.webkitHidden')
  final bool $dom_webkitHidden;

  @JSName('webkitIsFullScreen')
  @DocsEditable @DomName('Document.webkitIsFullScreen')
  final bool $dom_webkitIsFullScreen;

  @JSName('webkitPointerLockElement')
  @DocsEditable @DomName('Document.webkitPointerLockElement')
  final Element $dom_webkitPointerLockElement;

  @JSName('webkitVisibilityState')
  @DocsEditable @DomName('Document.webkitVisibilityState')
  final String $dom_webkitVisibilityState;

  @JSName('caretRangeFromPoint')
  @DocsEditable @DomName('Document.caretRangeFromPoint')
  Range $dom_caretRangeFromPoint(int x, int y) native;

  @JSName('createCDATASection')
  @DocsEditable @DomName('Document.createCDATASection')
  CDataSection createCDataSection(String data) native;

  @DocsEditable @DomName('Document.createDocumentFragment')
  DocumentFragment createDocumentFragment() native;

  @JSName('createElement')
  @DocsEditable @DomName('Document.createElement')
  Element $dom_createElement(String tagName) native;

  @JSName('createElementNS')
  @DocsEditable @DomName('Document.createElementNS')
  Element $dom_createElementNS(String namespaceURI, String qualifiedName) native;

  @JSName('createEvent')
  @DocsEditable @DomName('Document.createEvent')
  Event $dom_createEvent(String eventType) native;

  @JSName('createRange')
  @DocsEditable @DomName('Document.createRange')
  Range $dom_createRange() native;

  @JSName('createTextNode')
  @DocsEditable @DomName('Document.createTextNode')
  Text $dom_createTextNode(String data) native;

  Touch $dom_createTouch(Window window, EventTarget target, int identifier, int pageX, int pageY, int screenX, int screenY, int webkitRadiusX, int webkitRadiusY, num webkitRotationAngle, num webkitForce) {
    var target_1 = _convertDartToNative_EventTarget(target);
    return _$dom_createTouch_1(window, target_1, identifier, pageX, pageY, screenX, screenY, webkitRadiusX, webkitRadiusY, webkitRotationAngle, webkitForce);
  }
  @JSName('createTouch')
  @DocsEditable @DomName('Document.createTouch')
  Touch _$dom_createTouch_1(Window window, target, identifier, pageX, pageY, screenX, screenY, webkitRadiusX, webkitRadiusY, webkitRotationAngle, webkitForce) native;

  @JSName('createTouchList')
  @DocsEditable @DomName('Document.createTouchList')
  TouchList $dom_createTouchList() native;

  @JSName('elementFromPoint')
  @DocsEditable @DomName('Document.elementFromPoint')
  Element $dom_elementFromPoint(int x, int y) native;

  @DocsEditable @DomName('Document.execCommand')
  bool execCommand(String command, bool userInterface, String value) native;

  @JSName('getCSSCanvasContext')
  @DocsEditable @DomName('Document.getCSSCanvasContext')
  CanvasRenderingContext $dom_getCssCanvasContext(String contextId, String name, int width, int height) native;

  @JSName('getElementById')
  @DocsEditable @DomName('Document.getElementById')
  Element $dom_getElementById(String elementId) native;

  @JSName('getElementsByClassName')
  @DocsEditable @DomName('Document.getElementsByClassName')
  @Returns('NodeList') @Creates('NodeList')
  List<Node> $dom_getElementsByClassName(String tagname) native;

  @JSName('getElementsByName')
  @DocsEditable @DomName('Document.getElementsByName')
  @Returns('NodeList') @Creates('NodeList')
  List<Node> $dom_getElementsByName(String elementName) native;

  @JSName('getElementsByTagName')
  @DocsEditable @DomName('Document.getElementsByTagName')
  @Returns('NodeList') @Creates('NodeList')
  List<Node> $dom_getElementsByTagName(String tagname) native;

  @DocsEditable @DomName('Document.queryCommandEnabled')
  bool queryCommandEnabled(String command) native;

  @DocsEditable @DomName('Document.queryCommandIndeterm')
  bool queryCommandIndeterm(String command) native;

  @DocsEditable @DomName('Document.queryCommandState')
  bool queryCommandState(String command) native;

  @DocsEditable @DomName('Document.queryCommandSupported')
  bool queryCommandSupported(String command) native;

  @DocsEditable @DomName('Document.queryCommandValue')
  String queryCommandValue(String command) native;

  @JSName('querySelector')
  @DocsEditable @DomName('Document.querySelector')
  Element $dom_querySelector(String selectors) native;

  @JSName('querySelectorAll')
  @DocsEditable @DomName('Document.querySelectorAll')
  @Returns('NodeList') @Creates('NodeList')
  List<Node> $dom_querySelectorAll(String selectors) native;

  @JSName('webkitCancelFullScreen')
  @DocsEditable @DomName('Document.webkitCancelFullScreen')
  void $dom_webkitCancelFullScreen() native;

  @JSName('webkitExitFullscreen')
  @DocsEditable @DomName('Document.webkitExitFullscreen')
  void $dom_webkitExitFullscreen() native;

  @JSName('webkitExitPointerLock')
  @DocsEditable @DomName('Document.webkitExitPointerLock')
  void $dom_webkitExitPointerLock() native;

  Stream<Event> get onAbort => abortEvent.forTarget(this);

  Stream<Event> get onBeforeCopy => beforeCopyEvent.forTarget(this);

  Stream<Event> get onBeforeCut => beforeCutEvent.forTarget(this);

  Stream<Event> get onBeforePaste => beforePasteEvent.forTarget(this);

  Stream<Event> get onBlur => blurEvent.forTarget(this);

  Stream<Event> get onChange => changeEvent.forTarget(this);

  Stream<MouseEvent> get onClick => clickEvent.forTarget(this);

  Stream<MouseEvent> get onContextMenu => contextMenuEvent.forTarget(this);

  Stream<Event> get onCopy => copyEvent.forTarget(this);

  Stream<Event> get onCut => cutEvent.forTarget(this);

  Stream<Event> get onDoubleClick => doubleClickEvent.forTarget(this);

  Stream<MouseEvent> get onDrag => dragEvent.forTarget(this);

  Stream<MouseEvent> get onDragEnd => dragEndEvent.forTarget(this);

  Stream<MouseEvent> get onDragEnter => dragEnterEvent.forTarget(this);

  Stream<MouseEvent> get onDragLeave => dragLeaveEvent.forTarget(this);

  Stream<MouseEvent> get onDragOver => dragOverEvent.forTarget(this);

  Stream<MouseEvent> get onDragStart => dragStartEvent.forTarget(this);

  Stream<MouseEvent> get onDrop => dropEvent.forTarget(this);

  Stream<Event> get onError => errorEvent.forTarget(this);

  Stream<Event> get onFocus => focusEvent.forTarget(this);

  Stream<Event> get onInput => inputEvent.forTarget(this);

  Stream<Event> get onInvalid => invalidEvent.forTarget(this);

  Stream<KeyboardEvent> get onKeyDown => keyDownEvent.forTarget(this);

  Stream<KeyboardEvent> get onKeyPress => keyPressEvent.forTarget(this);

  Stream<KeyboardEvent> get onKeyUp => keyUpEvent.forTarget(this);

  Stream<Event> get onLoad => loadEvent.forTarget(this);

  Stream<MouseEvent> get onMouseDown => mouseDownEvent.forTarget(this);

  Stream<MouseEvent> get onMouseMove => mouseMoveEvent.forTarget(this);

  Stream<MouseEvent> get onMouseOut => mouseOutEvent.forTarget(this);

  Stream<MouseEvent> get onMouseOver => mouseOverEvent.forTarget(this);

  Stream<MouseEvent> get onMouseUp => mouseUpEvent.forTarget(this);

  Stream<WheelEvent> get onMouseWheel => mouseWheelEvent.forTarget(this);

  Stream<Event> get onPaste => pasteEvent.forTarget(this);

  Stream<Event> get onReadyStateChange => readyStateChangeEvent.forTarget(this);

  Stream<Event> get onReset => resetEvent.forTarget(this);

  Stream<Event> get onScroll => scrollEvent.forTarget(this);

  Stream<Event> get onSearch => searchEvent.forTarget(this);

  Stream<Event> get onSelect => selectEvent.forTarget(this);

  Stream<Event> get onSelectionChange => selectionChangeEvent.forTarget(this);

  Stream<Event> get onSelectStart => selectStartEvent.forTarget(this);

  Stream<Event> get onSubmit => submitEvent.forTarget(this);

  Stream<TouchEvent> get onTouchCancel => touchCancelEvent.forTarget(this);

  Stream<TouchEvent> get onTouchEnd => touchEndEvent.forTarget(this);

  Stream<TouchEvent> get onTouchMove => touchMoveEvent.forTarget(this);

  Stream<TouchEvent> get onTouchStart => touchStartEvent.forTarget(this);

  Stream<Event> get onFullscreenChange => fullscreenChangeEvent.forTarget(this);

  Stream<Event> get onFullscreenError => fullscreenErrorEvent.forTarget(this);

  Stream<Event> get onPointerLockChange => pointerLockChangeEvent.forTarget(this);

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


Future<CssStyleDeclaration> _emptyStyleFuture() {
  return _createMeasurementFuture(() => new Element.tag('div').style,
                                  new Completer<CssStyleDeclaration>());
}

class _FrozenCssClassSet extends CssClassSet {
  void writeClasses(Set s) {
    throw new UnsupportedError(
        'frozen class set cannot be modified');
  }
  Set<String> readClasses() => new Set<String>();

  bool get frozen => true;
}

@DocsEditable
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

  String get outerHtml => innerHtml;

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

  Node _insertAdjacentNode(String where, Node node) {
    switch (where.toLowerCase()) {
      case "beforebegin": return null;
      case "afterend": return null;
      case "afterbegin":
        var first = this.nodes.length > 0 ? this.nodes[0] : null;
        this.insertBefore(node, first);
        return node;
      case "beforeend":
        this.nodes.add(node);
        return node;
      default:
        throw new ArgumentError("Invalid position ${where}");
    }
  }

  Element insertAdjacentElement(String where, Element element)
    => this._insertAdjacentNode(where, element);

  void insertAdjacentText(String where, String text) {
    this._insertAdjacentNode(where, new Text(text));
  }

  void insertAdjacentHtml(String where, String text) {
    this._insertAdjacentNode(where, new DocumentFragment.html(text));
  }

  void append(Element element) {
    this.children.add(element);
  }

  void appendText(String text) {
    this.insertAdjacentText('beforeend', text);
  }

  void appendHtml(String text) {
    this.insertAdjacentHtml('beforeend', text);
  }

  // If we can come up with a semi-reasonable default value for an Element
  // getter, we'll use it. In general, these return the same values as an
  // element that has no parent.
  String get contentEditable => "false";
  bool get isContentEditable => false;
  bool get draggable => false;
  bool get hidden => false;
  bool get spellcheck => false;
  bool get translate => false;
  int get tabIndex => -1;
  String get id => "";
  String get title => "";
  String get tagName => "";
  String get webkitdropzone => "";
  String get webkitRegionOverflow => "";
  Element get $m_firstElementChild {
    if (children.length > 0) {
      return children[0];
    }
    return null;
  }
  Element get $m_lastElementChild => children.last;
  Element get nextElementSibling => null;
  Element get previousElementSibling => null;
  Element get offsetParent => null;
  Element get parent => null;
  Map<String, String> get attributes => const {};
  CssClassSet get classes => new _FrozenCssClassSet();
  Map<String, String> get dataAttributes => const {};
  CssStyleDeclaration get style => new Element.tag('div').style;
  Future<CssStyleDeclaration> get computedStyle =>
      _emptyStyleFuture();
  Future<CssStyleDeclaration> getComputedStyle(String pseudoElement) =>
      _emptyStyleFuture();

  // Imperative Element methods are made into no-ops, as they are on parentless
  // elements.
  void blur() {}
  void focus() {}
  void click() {}
  void scrollByLines(int lines) {}
  void scrollByPages(int pages) {}
  void scrollIntoView([bool centerIfNeeded]) {}
  void webkitRequestFullScreen(int flags) {}
  void webkitRequestFullscreen() {}

  // Setters throw errors rather than being no-ops because we aren't going to
  // retain the values that were set, and erroring out seems clearer.
  void set attributes(Map<String, String> value) {
    throw new UnsupportedError(
      "Attributes can't be set for document fragments.");
  }

  void set classes(Collection<String> value) {
    throw new UnsupportedError(
      "Classes can't be set for document fragments.");
  }

  void set dataAttributes(Map<String, String> value) {
    throw new UnsupportedError(
      "Data attributes can't be set for document fragments.");
  }

  void set contentEditable(String value) {
    throw new UnsupportedError(
      "Content editable can't be set for document fragments.");
  }

  String get dir {
    throw new UnsupportedError(
      "Document fragments don't support text direction.");
  }

  void set dir(String value) {
    throw new UnsupportedError(
      "Document fragments don't support text direction.");
  }

  void set draggable(bool value) {
    throw new UnsupportedError(
      "Draggable can't be set for document fragments.");
  }

  void set hidden(bool value) {
    throw new UnsupportedError(
      "Hidden can't be set for document fragments.");
  }

  void set id(String value) {
    throw new UnsupportedError(
      "ID can't be set for document fragments.");
  }

  String get lang {
    throw new UnsupportedError(
      "Document fragments don't support language.");
  }

  void set lang(String value) {
    throw new UnsupportedError(
      "Document fragments don't support language.");
  }

  void set scrollLeft(int value) {
    throw new UnsupportedError(
      "Document fragments don't support scrolling.");
  }

  void set scrollTop(int value) {
    throw new UnsupportedError(
      "Document fragments don't support scrolling.");
  }

  void set spellcheck(bool value) {
     throw new UnsupportedError(
      "Spellcheck can't be set for document fragments.");
  }

  void set translate(bool value) {
     throw new UnsupportedError(
      "Spellcheck can't be set for document fragments.");
  }

  void set tabIndex(int value) {
    throw new UnsupportedError(
      "Tab index can't be set for document fragments.");
  }

  void set title(String value) {
    throw new UnsupportedError(
      "Title can't be set for document fragments.");
  }

  void set webkitdropzone(String value) {
    throw new UnsupportedError(
      "WebKit drop zone can't be set for document fragments.");
  }

  void set webkitRegionOverflow(String value) {
    throw new UnsupportedError(
      "WebKit region overflow can't be set for document fragments.");
  }


  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  ElementEvents get on =>
    new ElementEvents(this);

  @JSName('querySelector')
  @DocsEditable @DomName('DocumentFragment.querySelector')
  Element $dom_querySelector(String selectors) native;

  @JSName('querySelectorAll')
  @DocsEditable @DomName('DocumentFragment.querySelectorAll')
  @Returns('NodeList') @Creates('NodeList')
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

  @DocsEditable @DomName('DOMError.name')
  final String name;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('DOMException')
class DomException native "*DOMException" {

  @DocsEditable @DomName('DOMCoreException.message')
  final String message;

  @DocsEditable @DomName('DOMCoreException.toString')
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('DOMImplementation')
class DomImplementation native "*DOMImplementation" {

  @JSName('createCSSStyleSheet')
  @DocsEditable @DomName('DOMImplementation.createCSSStyleSheet')
  CssStyleSheet createCssStyleSheet(String title, String media) native;

  @DocsEditable @DomName('DOMImplementation.createDocument')
  Document createDocument(String namespaceURI, String qualifiedName, DocumentType doctype) native;

  @DocsEditable @DomName('DOMImplementation.createDocumentType')
  DocumentType createDocumentType(String qualifiedName, String publicId, String systemId) native;

  @JSName('createHTMLDocument')
  @DocsEditable @DomName('DOMImplementation.createHTMLDocument')
  HtmlDocument createHtmlDocument(String title) native;

  @DocsEditable @DomName('DOMImplementation.hasFeature')
  bool hasFeature(String feature, String version) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('MimeType')
class DomMimeType native "*MimeType" {

  @DocsEditable @DomName('DOMMimeType.description')
  final String description;

  @DocsEditable @DomName('DOMMimeType.enabledPlugin')
  final DomPlugin enabledPlugin;

  @DocsEditable @DomName('DOMMimeType.suffixes')
  final String suffixes;

  @DocsEditable @DomName('DOMMimeType.type')
  final String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('MimeTypeArray')
class DomMimeTypeArray implements JavaScriptIndexingBehavior, List<DomMimeType> native "*MimeTypeArray" {

  @DocsEditable @DomName('DOMMimeTypeArray.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(DomMimeType element) => Collections.contains(this, element);

  void forEach(void f(DomMimeType element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(DomMimeType element)) => new MappedList<DomMimeType, dynamic>(this, f);

  Iterable<DomMimeType> where(bool f(DomMimeType element)) => new WhereIterable<DomMimeType>(this, f);

  bool every(bool f(DomMimeType element)) => Collections.every(this, f);

  bool any(bool f(DomMimeType element)) => Collections.any(this, f);

  List<DomMimeType> toList() => new List<DomMimeType>.from(this);
  Set<DomMimeType> toSet() => new Set<DomMimeType>.from(this);

  bool get isEmpty => this.length == 0;

  List<DomMimeType> take(int n) => new ListView<DomMimeType>(this, 0, n);

  Iterable<DomMimeType> takeWhile(bool test(DomMimeType value)) {
    return new TakeWhileIterable<DomMimeType>(this, test);
  }

  List<DomMimeType> skip(int n) => new ListView<DomMimeType>(this, n, null);

  Iterable<DomMimeType> skipWhile(bool test(DomMimeType value)) {
    return new SkipWhileIterable<DomMimeType>(this, test);
  }

  DomMimeType firstMatching(bool test(DomMimeType value), { DomMimeType orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  DomMimeType lastMatching(bool test(DomMimeType value), {DomMimeType orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  DomMimeType singleMatching(bool test(DomMimeType value)) {
    return Collections.singleMatching(this, test);
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

  DomMimeType min([int compare(DomMimeType a, DomMimeType b)]) => Collections.min(this, compare);

  DomMimeType max([int compare(DomMimeType a, DomMimeType b)]) => Collections.max(this, compare);

  DomMimeType removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  DomMimeType removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('DOMMimeTypeArray.item')
  DomMimeType item(int index) native;

  @DocsEditable @DomName('DOMMimeTypeArray.namedItem')
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

  @DocsEditable @DomName('DOMParser.parseFromString')
  Document parseFromString(String str, String contentType) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('Plugin')
class DomPlugin native "*Plugin" {

  @DocsEditable @DomName('DOMPlugin.description')
  final String description;

  @DocsEditable @DomName('DOMPlugin.filename')
  final String filename;

  @DocsEditable @DomName('DOMPlugin.length')
  final int length;

  @DocsEditable @DomName('DOMPlugin.name')
  final String name;

  @DocsEditable @DomName('DOMPlugin.item')
  DomMimeType item(int index) native;

  @DocsEditable @DomName('DOMPlugin.namedItem')
  DomMimeType namedItem(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('PluginArray')
class DomPluginArray implements JavaScriptIndexingBehavior, List<DomPlugin> native "*PluginArray" {

  @DocsEditable @DomName('DOMPluginArray.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(DomPlugin element) => Collections.contains(this, element);

  void forEach(void f(DomPlugin element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(DomPlugin element)) => new MappedList<DomPlugin, dynamic>(this, f);

  Iterable<DomPlugin> where(bool f(DomPlugin element)) => new WhereIterable<DomPlugin>(this, f);

  bool every(bool f(DomPlugin element)) => Collections.every(this, f);

  bool any(bool f(DomPlugin element)) => Collections.any(this, f);

  List<DomPlugin> toList() => new List<DomPlugin>.from(this);
  Set<DomPlugin> toSet() => new Set<DomPlugin>.from(this);

  bool get isEmpty => this.length == 0;

  List<DomPlugin> take(int n) => new ListView<DomPlugin>(this, 0, n);

  Iterable<DomPlugin> takeWhile(bool test(DomPlugin value)) {
    return new TakeWhileIterable<DomPlugin>(this, test);
  }

  List<DomPlugin> skip(int n) => new ListView<DomPlugin>(this, n, null);

  Iterable<DomPlugin> skipWhile(bool test(DomPlugin value)) {
    return new SkipWhileIterable<DomPlugin>(this, test);
  }

  DomPlugin firstMatching(bool test(DomPlugin value), { DomPlugin orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  DomPlugin lastMatching(bool test(DomPlugin value), {DomPlugin orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  DomPlugin singleMatching(bool test(DomPlugin value)) {
    return Collections.singleMatching(this, test);
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

  DomPlugin min([int compare(DomPlugin a, DomPlugin b)]) => Collections.min(this, compare);

  DomPlugin max([int compare(DomPlugin a, DomPlugin b)]) => Collections.max(this, compare);

  DomPlugin removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  DomPlugin removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('DOMPluginArray.item')
  DomPlugin item(int index) native;

  @DocsEditable @DomName('DOMPluginArray.namedItem')
  DomPlugin namedItem(String name) native;

  @DocsEditable @DomName('DOMPluginArray.refresh')
  void refresh(bool reload) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('Selection')
class DomSelection native "*Selection" {

  @DocsEditable @DomName('DOMSelection.anchorNode')
  final Node anchorNode;

  @DocsEditable @DomName('DOMSelection.anchorOffset')
  final int anchorOffset;

  @DocsEditable @DomName('DOMSelection.baseNode')
  final Node baseNode;

  @DocsEditable @DomName('DOMSelection.baseOffset')
  final int baseOffset;

  @DocsEditable @DomName('DOMSelection.extentNode')
  final Node extentNode;

  @DocsEditable @DomName('DOMSelection.extentOffset')
  final int extentOffset;

  @DocsEditable @DomName('DOMSelection.focusNode')
  final Node focusNode;

  @DocsEditable @DomName('DOMSelection.focusOffset')
  final int focusOffset;

  @DocsEditable @DomName('DOMSelection.isCollapsed')
  final bool isCollapsed;

  @DocsEditable @DomName('DOMSelection.rangeCount')
  final int rangeCount;

  @DocsEditable @DomName('DOMSelection.type')
  final String type;

  @DocsEditable @DomName('DOMSelection.addRange')
  void addRange(Range range) native;

  @DocsEditable @DomName('DOMSelection.collapse')
  void collapse(Node node, int index) native;

  @DocsEditable @DomName('DOMSelection.collapseToEnd')
  void collapseToEnd() native;

  @DocsEditable @DomName('DOMSelection.collapseToStart')
  void collapseToStart() native;

  @DocsEditable @DomName('DOMSelection.containsNode')
  bool containsNode(Node node, bool allowPartial) native;

  @DocsEditable @DomName('DOMSelection.deleteFromDocument')
  void deleteFromDocument() native;

  @DocsEditable @DomName('DOMSelection.empty')
  void empty() native;

  @DocsEditable @DomName('DOMSelection.extend')
  void extend(Node node, int offset) native;

  @DocsEditable @DomName('DOMSelection.getRangeAt')
  Range getRangeAt(int index) native;

  @DocsEditable @DomName('DOMSelection.modify')
  void modify(String alter, String direction, String granularity) native;

  @DocsEditable @DomName('DOMSelection.removeAllRanges')
  void removeAllRanges() native;

  @DocsEditable @DomName('DOMSelection.selectAllChildren')
  void selectAllChildren(Node node) native;

  @DocsEditable @DomName('DOMSelection.setBaseAndExtent')
  void setBaseAndExtent(Node baseNode, int baseOffset, Node extentNode, int extentOffset) native;

  @DocsEditable @DomName('DOMSelection.setPosition')
  void setPosition(Node node, int offset) native;

  @DocsEditable @DomName('DOMSelection.toString')
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('DOMSettableTokenList')
class DomSettableTokenList extends DomTokenList native "*DOMSettableTokenList" {

  @DocsEditable @DomName('DOMSettableTokenList.value')
  String value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('DOMStringList')
class DomStringList implements JavaScriptIndexingBehavior, List<String> native "*DOMStringList" {

  @DocsEditable @DomName('DOMStringList.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  // contains() defined by IDL.

  void forEach(void f(String element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(String element)) => new MappedList<String, dynamic>(this, f);

  Iterable<String> where(bool f(String element)) => new WhereIterable<String>(this, f);

  bool every(bool f(String element)) => Collections.every(this, f);

  bool any(bool f(String element)) => Collections.any(this, f);

  List<String> toList() => new List<String>.from(this);
  Set<String> toSet() => new Set<String>.from(this);

  bool get isEmpty => this.length == 0;

  List<String> take(int n) => new ListView<String>(this, 0, n);

  Iterable<String> takeWhile(bool test(String value)) {
    return new TakeWhileIterable<String>(this, test);
  }

  List<String> skip(int n) => new ListView<String>(this, n, null);

  Iterable<String> skipWhile(bool test(String value)) {
    return new SkipWhileIterable<String>(this, test);
  }

  String firstMatching(bool test(String value), { String orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  String lastMatching(bool test(String value), {String orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  String singleMatching(bool test(String value)) {
    return Collections.singleMatching(this, test);
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

  String min([int compare(String a, String b)]) => Collections.min(this, compare);

  String max([int compare(String a, String b)]) => Collections.max(this, compare);

  String removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  String removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('DOMStringList.contains')
  bool contains(String string) native;

  @DocsEditable @DomName('DOMStringList.item')
  String item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DOMStringMap')
abstract class DomStringMap {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('DOMTokenList')
class DomTokenList native "*DOMTokenList" {

  @DocsEditable @DomName('DOMTokenList.length')
  final int length;

  @DocsEditable @DomName('DOMTokenList.contains')
  bool contains(String token) native;

  @DocsEditable @DomName('DOMTokenList.item')
  String item(int index) native;

  @DocsEditable @DomName('DOMTokenList.toString')
  String toString() native;

  @DocsEditable @DomName('DOMTokenList.toggle')
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
    return Collections.joinList(this, separator);
  }

  List mappedBy(f(Element element)) {
    return new MappedList<Element, dynamic>(this, f);
  }

  Iterable<Element> where(bool f(Element element))
      => new WhereIterable(this, f);

  bool get isEmpty {
    return _element.$dom_firstElementChild == null;
  }

  List<Element> take(int n) {
    return new ListView<Element>(this, 0, n);
  }

  Iterable<Element> takeWhile(bool test(Element value)) {
    return new TakeWhileIterable<Element>(this, test);
  }

  List<Element> skip(int n) {
    return new ListView<Element>(this, n, null);
  }

  Iterable<Element> skipWhile(bool test(Element value)) {
    return new SkipWhileIterable<Element>(this, test);
  }

  Element firstMatching(bool test(Element value), {Element orElse()}) {
    return Collections.firstMatching(this, test, orElse);
  }

  Element lastMatching(bool test(Element value), {Element orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  Element singleMatching(bool test(Element value)) {
    return Collections.singleMatching(this, test);
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

  void sort([int compare(Element a, Element b)]) {
    throw new UnsupportedError('TODO(jacobr): should we impl?');
  }

  dynamic reduce(dynamic initialValue,
      dynamic combine(dynamic previousValue, Element element)) {
    return Collections.reduce(this, initialValue, combine);
  }

  void setRange(int start, int rangeLength, List from, [int startFrom = 0]) {
    throw new UnimplementedError();
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
    return Collections.min(this, compare);
  }

  Element max([int compare(Element a, Element b)]) {
    return Collections.max(this, compare);
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
    return Collections.joinList(this, separator);
  }

  List mappedBy(f(Element element)) {
    return new MappedList<Element, dynamic>(this, f);
  }

  Iterable<Element> where(bool f(Element element))
      => new WhereIterable(this, f);

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
    return new ListView<Element>(this, 0, n);
  }

  Iterable<Element> takeWhile(bool test(Element value)) {
    return new TakeWhileIterable<Element>(this, test);
  }

  List<Element> skip(int n) {
    return new ListView<Element>(this, n, null);
  }

  Iterable<Element> skipWhile(bool test(Element value)) {
    return new SkipWhileIterable<Element>(this, test);
  }

  Element firstMatching(bool test(Element value), {Element orElse()}) {
    return Collections.firstMatching(this, test, orElse);
  }

  Element lastMatching(bool test(Element value), {Element orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  Element singleMatching(bool test(Element value)) {
    return Collections.singleMatching(this, test);
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

  void sort([int compare(Element a, Element b)]) {
    throw new UnsupportedError('');
  }

  dynamic reduce(dynamic initialValue,
      dynamic combine(dynamic previousValue, Element element)) {
    return Collections.reduce(this, initialValue, combine);
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

  Element get first => _nodeList.first;

  Element get last => _nodeList.last;

  Element get single => _nodeList.single;

  Element min([int compare(Element a, Element b)]) {
    return Collections.min(this, compare);
  }

  Element max([int compare(Element a, Element b)]) {
    return Collections.max(this, compare);
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
   * See also:
   *
   * * [CSS Inheritance and Cascade](http://docs.webplatform.org/wiki/tutorials/inheritance_and_cascade)
   */
  Future<CssStyleDeclaration> get computedStyle {
     // TODO(jacobr): last param should be null, see b/5045788
     return getComputedStyle('');
  }

  /**
   * Returns the computed styles for pseudo-elements such as `::after`,
   * `::before`, `::marker`, `::line-marker`.
   *
   * See also:
   *
   * * [Pseudo-elements](http://docs.webplatform.org/wiki/css/selectors/pseudo-elements)
   */
  Future<CssStyleDeclaration> getComputedStyle(String pseudoElement) {
    return _createMeasurementFuture(
        () => window.$dom_getComputedStyle(this, pseudoElement),
        new Completer<CssStyleDeclaration>());
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
  @Experimental()
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
  }


  static const EventStreamProvider<Event> abortEvent = const EventStreamProvider<Event>('abort');

  static const EventStreamProvider<Event> beforeCopyEvent = const EventStreamProvider<Event>('beforecopy');

  static const EventStreamProvider<Event> beforeCutEvent = const EventStreamProvider<Event>('beforecut');

  static const EventStreamProvider<Event> beforePasteEvent = const EventStreamProvider<Event>('beforepaste');

  static const EventStreamProvider<Event> blurEvent = const EventStreamProvider<Event>('blur');

  static const EventStreamProvider<Event> changeEvent = const EventStreamProvider<Event>('change');

  static const EventStreamProvider<MouseEvent> clickEvent = const EventStreamProvider<MouseEvent>('click');

  static const EventStreamProvider<MouseEvent> contextMenuEvent = const EventStreamProvider<MouseEvent>('contextmenu');

  static const EventStreamProvider<Event> copyEvent = const EventStreamProvider<Event>('copy');

  static const EventStreamProvider<Event> cutEvent = const EventStreamProvider<Event>('cut');

  static const EventStreamProvider<Event> doubleClickEvent = const EventStreamProvider<Event>('dblclick');

  static const EventStreamProvider<MouseEvent> dragEvent = const EventStreamProvider<MouseEvent>('drag');

  static const EventStreamProvider<MouseEvent> dragEndEvent = const EventStreamProvider<MouseEvent>('dragend');

  static const EventStreamProvider<MouseEvent> dragEnterEvent = const EventStreamProvider<MouseEvent>('dragenter');

  static const EventStreamProvider<MouseEvent> dragLeaveEvent = const EventStreamProvider<MouseEvent>('dragleave');

  static const EventStreamProvider<MouseEvent> dragOverEvent = const EventStreamProvider<MouseEvent>('dragover');

  static const EventStreamProvider<MouseEvent> dragStartEvent = const EventStreamProvider<MouseEvent>('dragstart');

  static const EventStreamProvider<MouseEvent> dropEvent = const EventStreamProvider<MouseEvent>('drop');

  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  static const EventStreamProvider<Event> focusEvent = const EventStreamProvider<Event>('focus');

  static const EventStreamProvider<Event> inputEvent = const EventStreamProvider<Event>('input');

  static const EventStreamProvider<Event> invalidEvent = const EventStreamProvider<Event>('invalid');

  static const EventStreamProvider<KeyboardEvent> keyDownEvent = const EventStreamProvider<KeyboardEvent>('keydown');

  static const EventStreamProvider<KeyboardEvent> keyPressEvent = const EventStreamProvider<KeyboardEvent>('keypress');

  static const EventStreamProvider<KeyboardEvent> keyUpEvent = const EventStreamProvider<KeyboardEvent>('keyup');

  static const EventStreamProvider<Event> loadEvent = const EventStreamProvider<Event>('load');

  static const EventStreamProvider<MouseEvent> mouseDownEvent = const EventStreamProvider<MouseEvent>('mousedown');

  static const EventStreamProvider<MouseEvent> mouseMoveEvent = const EventStreamProvider<MouseEvent>('mousemove');

  static const EventStreamProvider<MouseEvent> mouseOutEvent = const EventStreamProvider<MouseEvent>('mouseout');

  static const EventStreamProvider<MouseEvent> mouseOverEvent = const EventStreamProvider<MouseEvent>('mouseover');

  static const EventStreamProvider<MouseEvent> mouseUpEvent = const EventStreamProvider<MouseEvent>('mouseup');

  static const EventStreamProvider<Event> pasteEvent = const EventStreamProvider<Event>('paste');

  static const EventStreamProvider<Event> resetEvent = const EventStreamProvider<Event>('reset');

  static const EventStreamProvider<Event> scrollEvent = const EventStreamProvider<Event>('scroll');

  static const EventStreamProvider<Event> searchEvent = const EventStreamProvider<Event>('search');

  static const EventStreamProvider<Event> selectEvent = const EventStreamProvider<Event>('select');

  static const EventStreamProvider<Event> selectStartEvent = const EventStreamProvider<Event>('selectstart');

  static const EventStreamProvider<Event> submitEvent = const EventStreamProvider<Event>('submit');

  static const EventStreamProvider<TouchEvent> touchCancelEvent = const EventStreamProvider<TouchEvent>('touchcancel');

  static const EventStreamProvider<TouchEvent> touchEndEvent = const EventStreamProvider<TouchEvent>('touchend');

  static const EventStreamProvider<TouchEvent> touchEnterEvent = const EventStreamProvider<TouchEvent>('touchenter');

  static const EventStreamProvider<TouchEvent> touchLeaveEvent = const EventStreamProvider<TouchEvent>('touchleave');

  static const EventStreamProvider<TouchEvent> touchMoveEvent = const EventStreamProvider<TouchEvent>('touchmove');

  static const EventStreamProvider<TouchEvent> touchStartEvent = const EventStreamProvider<TouchEvent>('touchstart');

  static const EventStreamProvider<TransitionEvent> transitionEndEvent = const EventStreamProvider<TransitionEvent>('webkitTransitionEnd');

  static const EventStreamProvider<Event> fullscreenChangeEvent = const EventStreamProvider<Event>('webkitfullscreenchange');

  static const EventStreamProvider<Event> fullscreenErrorEvent = const EventStreamProvider<Event>('webkitfullscreenerror');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  ElementEvents get on =>
    new ElementEvents(this);

  @JSName('children')
  @DocsEditable @DomName('Element.children')
  final HtmlCollection $dom_children;

  @DocsEditable @DomName('Element.contentEditable')
  String contentEditable;

  @DocsEditable @DomName('Element.dir')
  String dir;

  @DocsEditable @DomName('Element.draggable')
  bool draggable;

  @DocsEditable @DomName('Element.hidden')
  bool hidden;

  @DocsEditable @DomName('Element.id')
  String id;

  @JSName('innerHTML')
  @DocsEditable @DomName('Element.innerHTML')
  String innerHtml;

  @DocsEditable @DomName('Element.isContentEditable')
  final bool isContentEditable;

  @DocsEditable @DomName('Element.lang')
  String lang;

  @JSName('outerHTML')
  @DocsEditable @DomName('Element.outerHTML')
  final String outerHtml;

  @DocsEditable @DomName('Element.spellcheck')
  bool spellcheck;

  @DocsEditable @DomName('Element.tabIndex')
  int tabIndex;

  @DocsEditable @DomName('Element.title')
  String title;

  @DocsEditable @DomName('Element.translate')
  bool translate;

  @DocsEditable @DomName('Element.webkitdropzone')
  String webkitdropzone;

  @DocsEditable @DomName('Element.click')
  void click() native;

  static const int ALLOW_KEYBOARD_INPUT = 1;

  @JSName('childElementCount')
  @DocsEditable @DomName('Element.childElementCount')
  final int $dom_childElementCount;

  @JSName('className')
  @DocsEditable @DomName('Element.className')
  String $dom_className;

  @DocsEditable @DomName('Element.clientHeight')
  final int clientHeight;

  @DocsEditable @DomName('Element.clientLeft')
  final int clientLeft;

  @DocsEditable @DomName('Element.clientTop')
  final int clientTop;

  @DocsEditable @DomName('Element.clientWidth')
  final int clientWidth;

  @DocsEditable @DomName('Element.dataset')
  final Map<String, String> dataset;

  @JSName('firstElementChild')
  @DocsEditable @DomName('Element.firstElementChild')
  final Element $dom_firstElementChild;

  @JSName('lastElementChild')
  @DocsEditable @DomName('Element.lastElementChild')
  final Element $dom_lastElementChild;

  @DocsEditable @DomName('Element.nextElementSibling')
  final Element nextElementSibling;

  @DocsEditable @DomName('Element.offsetHeight')
  final int offsetHeight;

  @DocsEditable @DomName('Element.offsetLeft')
  final int offsetLeft;

  @DocsEditable @DomName('Element.offsetParent')
  final Element offsetParent;

  @DocsEditable @DomName('Element.offsetTop')
  final int offsetTop;

  @DocsEditable @DomName('Element.offsetWidth')
  final int offsetWidth;

  @DocsEditable @DomName('Element.previousElementSibling')
  final Element previousElementSibling;

  @DocsEditable @DomName('Element.scrollHeight')
  final int scrollHeight;

  @DocsEditable @DomName('Element.scrollLeft')
  int scrollLeft;

  @DocsEditable @DomName('Element.scrollTop')
  int scrollTop;

  @DocsEditable @DomName('Element.scrollWidth')
  final int scrollWidth;

  @DocsEditable @DomName('Element.style')
  final CssStyleDeclaration style;

  @DocsEditable @DomName('Element.tagName')
  final String tagName;

  @DocsEditable @DomName('Element.webkitPseudo')
  String webkitPseudo;

  @DocsEditable @DomName('Element.webkitShadowRoot')
  final ShadowRoot webkitShadowRoot;

  @DocsEditable @DomName('Element.blur')
  void blur() native;

  @DocsEditable @DomName('Element.focus')
  void focus() native;

  @JSName('getAttribute')
  @DocsEditable @DomName('Element.getAttribute')
  String $dom_getAttribute(String name) native;

  @JSName('getAttributeNS')
  @DocsEditable @DomName('Element.getAttributeNS')
  String $dom_getAttributeNS(String namespaceURI, String localName) native;

  @DocsEditable @DomName('Element.getBoundingClientRect')
  ClientRect getBoundingClientRect() native;

  @DocsEditable @DomName('Element.getClientRects')
  @Returns('_ClientRectList') @Creates('_ClientRectList')
  List<ClientRect> getClientRects() native;

  @JSName('getElementsByClassName')
  @DocsEditable @DomName('Element.getElementsByClassName')
  @Returns('NodeList') @Creates('NodeList')
  List<Node> $dom_getElementsByClassName(String name) native;

  @JSName('getElementsByTagName')
  @DocsEditable @DomName('Element.getElementsByTagName')
  @Returns('NodeList') @Creates('NodeList')
  List<Node> $dom_getElementsByTagName(String name) native;

  @JSName('hasAttribute')
  @DocsEditable @DomName('Element.hasAttribute')
  bool $dom_hasAttribute(String name) native;

  @JSName('hasAttributeNS')
  @DocsEditable @DomName('Element.hasAttributeNS')
  bool $dom_hasAttributeNS(String namespaceURI, String localName) native;

  @JSName('querySelector')
  @DocsEditable @DomName('Element.querySelector')
  Element $dom_querySelector(String selectors) native;

  @JSName('querySelectorAll')
  @DocsEditable @DomName('Element.querySelectorAll')
  @Returns('NodeList') @Creates('NodeList')
  List<Node> $dom_querySelectorAll(String selectors) native;

  @JSName('removeAttribute')
  @DocsEditable @DomName('Element.removeAttribute')
  void $dom_removeAttribute(String name) native;

  @JSName('removeAttributeNS')
  @DocsEditable @DomName('Element.removeAttributeNS')
  void $dom_removeAttributeNS(String namespaceURI, String localName) native;

  @DocsEditable @DomName('Element.scrollByLines')
  void scrollByLines(int lines) native;

  @DocsEditable @DomName('Element.scrollByPages')
  void scrollByPages(int pages) native;

  @JSName('scrollIntoViewIfNeeded')
  @DocsEditable @DomName('Element.scrollIntoViewIfNeeded')
  void scrollIntoView([bool centerIfNeeded]) native;

  @JSName('setAttribute')
  @DocsEditable @DomName('Element.setAttribute')
  void $dom_setAttribute(String name, String value) native;

  @JSName('setAttributeNS')
  @DocsEditable @DomName('Element.setAttributeNS')
  void $dom_setAttributeNS(String namespaceURI, String qualifiedName, String value) native;

  @JSName('webkitCreateShadowRoot')
  @DocsEditable @DomName('Element.webkitCreateShadowRoot') @SupportedBrowser(SupportedBrowser.CHROME, '25') @Experimental()
  ShadowRoot createShadowRoot() native;

  @DocsEditable @DomName('Element.webkitRequestFullScreen')
  void webkitRequestFullScreen(int flags) native;

  @DocsEditable @DomName('Element.webkitRequestFullscreen')
  void webkitRequestFullscreen() native;

  @DocsEditable @DomName('Element.webkitRequestPointerLock')
  void webkitRequestPointerLock() native;

  Stream<Event> get onAbort => abortEvent.forTarget(this);

  Stream<Event> get onBeforeCopy => beforeCopyEvent.forTarget(this);

  Stream<Event> get onBeforeCut => beforeCutEvent.forTarget(this);

  Stream<Event> get onBeforePaste => beforePasteEvent.forTarget(this);

  Stream<Event> get onBlur => blurEvent.forTarget(this);

  Stream<Event> get onChange => changeEvent.forTarget(this);

  Stream<MouseEvent> get onClick => clickEvent.forTarget(this);

  Stream<MouseEvent> get onContextMenu => contextMenuEvent.forTarget(this);

  Stream<Event> get onCopy => copyEvent.forTarget(this);

  Stream<Event> get onCut => cutEvent.forTarget(this);

  Stream<Event> get onDoubleClick => doubleClickEvent.forTarget(this);

  Stream<MouseEvent> get onDrag => dragEvent.forTarget(this);

  Stream<MouseEvent> get onDragEnd => dragEndEvent.forTarget(this);

  Stream<MouseEvent> get onDragEnter => dragEnterEvent.forTarget(this);

  Stream<MouseEvent> get onDragLeave => dragLeaveEvent.forTarget(this);

  Stream<MouseEvent> get onDragOver => dragOverEvent.forTarget(this);

  Stream<MouseEvent> get onDragStart => dragStartEvent.forTarget(this);

  Stream<MouseEvent> get onDrop => dropEvent.forTarget(this);

  Stream<Event> get onError => errorEvent.forTarget(this);

  Stream<Event> get onFocus => focusEvent.forTarget(this);

  Stream<Event> get onInput => inputEvent.forTarget(this);

  Stream<Event> get onInvalid => invalidEvent.forTarget(this);

  Stream<KeyboardEvent> get onKeyDown => keyDownEvent.forTarget(this);

  Stream<KeyboardEvent> get onKeyPress => keyPressEvent.forTarget(this);

  Stream<KeyboardEvent> get onKeyUp => keyUpEvent.forTarget(this);

  Stream<Event> get onLoad => loadEvent.forTarget(this);

  Stream<MouseEvent> get onMouseDown => mouseDownEvent.forTarget(this);

  Stream<MouseEvent> get onMouseMove => mouseMoveEvent.forTarget(this);

  Stream<MouseEvent> get onMouseOut => mouseOutEvent.forTarget(this);

  Stream<MouseEvent> get onMouseOver => mouseOverEvent.forTarget(this);

  Stream<MouseEvent> get onMouseUp => mouseUpEvent.forTarget(this);

  Stream<Event> get onPaste => pasteEvent.forTarget(this);

  Stream<Event> get onReset => resetEvent.forTarget(this);

  Stream<Event> get onScroll => scrollEvent.forTarget(this);

  Stream<Event> get onSearch => searchEvent.forTarget(this);

  Stream<Event> get onSelect => selectEvent.forTarget(this);

  Stream<Event> get onSelectStart => selectStartEvent.forTarget(this);

  Stream<Event> get onSubmit => submitEvent.forTarget(this);

  Stream<TouchEvent> get onTouchCancel => touchCancelEvent.forTarget(this);

  Stream<TouchEvent> get onTouchEnd => touchEndEvent.forTarget(this);

  Stream<TouchEvent> get onTouchEnter => touchEnterEvent.forTarget(this);

  Stream<TouchEvent> get onTouchLeave => touchLeaveEvent.forTarget(this);

  Stream<TouchEvent> get onTouchMove => touchMoveEvent.forTarget(this);

  Stream<TouchEvent> get onTouchStart => touchStartEvent.forTarget(this);

  Stream<TransitionEvent> get onTransitionEnd => transitionEndEvent.forTarget(this);

  Stream<Event> get onFullscreenChange => fullscreenChangeEvent.forTarget(this);

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


@DocsEditable
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

  @DocsEditable @DomName('HTMLEmbedElement.align')
  String align;

  @DocsEditable @DomName('HTMLEmbedElement.height')
  String height;

  @DocsEditable @DomName('HTMLEmbedElement.name')
  String name;

  @DocsEditable @DomName('HTMLEmbedElement.src')
  String src;

  @DocsEditable @DomName('HTMLEmbedElement.type')
  String type;

  @DocsEditable @DomName('HTMLEmbedElement.width')
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

  @DocsEditable @DomName('Entry.filesystem')
  final FileSystem filesystem;

  @DocsEditable @DomName('Entry.fullPath')
  final String fullPath;

  @DocsEditable @DomName('Entry.isDirectory')
  final bool isDirectory;

  @DocsEditable @DomName('Entry.isFile')
  final bool isFile;

  @DocsEditable @DomName('Entry.name')
  final String name;

  @DocsEditable @DomName('Entry.copyTo')
  void copyTo(DirectoryEntry parent, [String name, EntryCallback successCallback, ErrorCallback errorCallback]) native;

  @DocsEditable @DomName('Entry.getMetadata')
  void getMetadata(MetadataCallback successCallback, [ErrorCallback errorCallback]) native;

  @DocsEditable @DomName('Entry.getParent')
  void getParent([EntryCallback successCallback, ErrorCallback errorCallback]) native;

  @DocsEditable @DomName('Entry.moveTo')
  void moveTo(DirectoryEntry parent, [String name, EntryCallback successCallback, ErrorCallback errorCallback]) native;

  @DocsEditable @DomName('Entry.remove')
  void remove(VoidCallback successCallback, [ErrorCallback errorCallback]) native;

  @JSName('toURL')
  @DocsEditable @DomName('Entry.toURL')
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

  @DocsEditable @DomName('EntrySync.filesystem')
  final FileSystemSync filesystem;

  @DocsEditable @DomName('EntrySync.fullPath')
  final String fullPath;

  @DocsEditable @DomName('EntrySync.isDirectory')
  final bool isDirectory;

  @DocsEditable @DomName('EntrySync.isFile')
  final bool isFile;

  @DocsEditable @DomName('EntrySync.name')
  final String name;

  @DocsEditable @DomName('EntrySync.copyTo')
  EntrySync copyTo(DirectoryEntrySync parent, String name) native;

  @DocsEditable @DomName('EntrySync.getMetadata')
  Metadata getMetadata() native;

  @DocsEditable @DomName('EntrySync.getParent')
  EntrySync getParent() native;

  @DocsEditable @DomName('EntrySync.moveTo')
  EntrySync moveTo(DirectoryEntrySync parent, String name) native;

  @DocsEditable @DomName('EntrySync.remove')
  void remove() native;

  @JSName('toURL')
  @DocsEditable @DomName('EntrySync.toURL')
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

  @DocsEditable @DomName('ErrorEvent.filename')
  final String filename;

  @DocsEditable @DomName('ErrorEvent.lineno')
  final int lineno;

  @DocsEditable @DomName('ErrorEvent.message')
  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('Event')
class Event native "*Event" {
  // In JS, canBubble and cancelable are technically required parameters to
  // init*Event. In practice, though, if they aren't provided they simply
  // default to false (since that's Boolean(undefined)).
  //
  // Contrary to JS, we default canBubble and cancelable to true, since that's
  // what people want most of the time anyway.
  factory Event(String type, [bool canBubble = true, bool cancelable = true]) =>
      _EventFactoryProvider.createEvent(type, canBubble, cancelable);

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

  @DocsEditable @DomName('Event.bubbles')
  final bool bubbles;

  @DocsEditable @DomName('Event.cancelBubble')
  bool cancelBubble;

  @DocsEditable @DomName('Event.cancelable')
  final bool cancelable;

  @DocsEditable @DomName('Event.clipboardData')
  final Clipboard clipboardData;

  EventTarget get currentTarget => _convertNativeToDart_EventTarget(this._currentTarget);
  @JSName('currentTarget')
  @DocsEditable @DomName('Event.currentTarget') @Creates('Null') @Returns('EventTarget|=Object')
  final dynamic _currentTarget;

  @DocsEditable @DomName('Event.defaultPrevented')
  final bool defaultPrevented;

  @DocsEditable @DomName('Event.eventPhase')
  final int eventPhase;

  @DocsEditable @DomName('Event.returnValue')
  bool returnValue;

  EventTarget get target => _convertNativeToDart_EventTarget(this._target);
  @JSName('target')
  @DocsEditable @DomName('Event.target') @Creates('Node') @Returns('EventTarget|=Object')
  final dynamic _target;

  @DocsEditable @DomName('Event.timeStamp')
  final int timeStamp;

  @DocsEditable @DomName('Event.type')
  final String type;

  @JSName('initEvent')
  @DocsEditable @DomName('Event.initEvent')
  void $dom_initEvent(String eventTypeArg, bool canBubbleArg, bool cancelableArg) native;

  @DocsEditable @DomName('Event.preventDefault')
  void preventDefault() native;

  @DocsEditable @DomName('Event.stopImmediatePropagation')
  void stopImmediatePropagation() native;

  @DocsEditable @DomName('Event.stopPropagation')
  void stopPropagation() native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('EventException')
class EventException native "*EventException" {

  static const int DISPATCH_REQUEST_ERR = 1;

  static const int UNSPECIFIED_EVENT_TYPE_ERR = 0;

  @DocsEditable @DomName('EventException.code')
  final int code;

  @DocsEditable @DomName('EventException.message')
  final String message;

  @DocsEditable @DomName('EventException.name')
  final String name;

  @DocsEditable @DomName('EventException.toString')
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('EventSource')
class EventSource extends EventTarget native "*EventSource" {

  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  static const EventStreamProvider<MessageEvent> messageEvent = const EventStreamProvider<MessageEvent>('message');

  static const EventStreamProvider<Event> openEvent = const EventStreamProvider<Event>('open');

  @DocsEditable
  factory EventSource(String scriptUrl) => EventSource._create(scriptUrl);
  static EventSource _create(String scriptUrl) => JS('EventSource', 'new EventSource(#)', scriptUrl);

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  EventSourceEvents get on =>
    new EventSourceEvents(this);

  static const int CLOSED = 2;

  static const int CONNECTING = 0;

  static const int OPEN = 1;

  @DocsEditable @DomName('EventSource.readyState')
  final int readyState;

  @DocsEditable @DomName('EventSource.url')
  final String url;

  @JSName('addEventListener')
  @DocsEditable @DomName('EventSource.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('EventSource.close')
  void close() native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('EventSource.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('EventSource.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  Stream<Event> get onError => errorEvent.forTarget(this);

  Stream<MessageEvent> get onMessage => messageEvent.forTarget(this);

  Stream<Event> get onOpen => openEvent.forTarget(this);
}

@DocsEditable
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
    return _ptr.$dom_dispatchEvent(evt);
  }

  void _add(EventListener listener, bool useCapture) {
    _ptr.$dom_addEventListener(_type, listener, useCapture);
  }

  void _remove(EventListener listener, bool useCapture) {
    _ptr.$dom_removeEventListener(_type, listener, useCapture);
  }
}

@DocsEditable
@DomName('EventTarget')
/**
 * Base class for all browser objects that support events.
 *
 * Use the [on] property to add, remove, and dispatch events (rather than
 * [$dom_addEventListener], [$dom_dispatchEvent], and
 * [$dom_removeEventListener]) for compile-time type checks and a more concise
 * API.
 */ 
class EventTarget native "*EventTarget" {

  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  Events get on => new Events(this);

  @JSName('addEventListener')
  @DocsEditable @DomName('EventTarget.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('EventTarget.dispatchEvent')
  bool $dom_dispatchEvent(Event event) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('EventTarget.removeEventListener')
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

  @DocsEditable @DomName('HTMLFieldSetElement.disabled')
  bool disabled;

  @DocsEditable @DomName('HTMLFieldSetElement.elements')
  final HtmlCollection elements;

  @DocsEditable @DomName('HTMLFieldSetElement.form')
  final FormElement form;

  @DocsEditable @DomName('HTMLFieldSetElement.name')
  String name;

  @DocsEditable @DomName('HTMLFieldSetElement.type')
  final String type;

  @DocsEditable @DomName('HTMLFieldSetElement.validationMessage')
  final String validationMessage;

  @DocsEditable @DomName('HTMLFieldSetElement.validity')
  final ValidityState validity;

  @DocsEditable @DomName('HTMLFieldSetElement.willValidate')
  final bool willValidate;

  @DocsEditable @DomName('HTMLFieldSetElement.checkValidity')
  bool checkValidity() native;

  @DocsEditable @DomName('HTMLFieldSetElement.setCustomValidity')
  void setCustomValidity(String error) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('File')
class File extends Blob native "*File" {

  @DocsEditable @DomName('File.lastModifiedDate')
  final Date lastModifiedDate;

  @DocsEditable @DomName('File.name')
  final String name;

  @DocsEditable @DomName('File.webkitRelativePath')
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

  @DocsEditable @DomName('FileEntry.createWriter')
  void createWriter(FileWriterCallback successCallback, [ErrorCallback errorCallback]) native;

  @DocsEditable @DomName('FileEntry.file')
  void file(FileCallback successCallback, [ErrorCallback errorCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('FileEntrySync')
class FileEntrySync extends EntrySync native "*FileEntrySync" {

  @DocsEditable @DomName('FileEntrySync.createWriter')
  FileWriterSync createWriter() native;

  @DocsEditable @DomName('FileEntrySync.file')
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

  @DocsEditable @DomName('FileError.code')
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

  @DocsEditable @DomName('FileException.code')
  final int code;

  @DocsEditable @DomName('FileException.message')
  final String message;

  @DocsEditable @DomName('FileException.name')
  final String name;

  @DocsEditable @DomName('FileException.toString')
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('FileList')
class FileList implements JavaScriptIndexingBehavior, List<File> native "*FileList" {

  @DocsEditable @DomName('FileList.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(File element) => Collections.contains(this, element);

  void forEach(void f(File element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(File element)) => new MappedList<File, dynamic>(this, f);

  Iterable<File> where(bool f(File element)) => new WhereIterable<File>(this, f);

  bool every(bool f(File element)) => Collections.every(this, f);

  bool any(bool f(File element)) => Collections.any(this, f);

  List<File> toList() => new List<File>.from(this);
  Set<File> toSet() => new Set<File>.from(this);

  bool get isEmpty => this.length == 0;

  List<File> take(int n) => new ListView<File>(this, 0, n);

  Iterable<File> takeWhile(bool test(File value)) {
    return new TakeWhileIterable<File>(this, test);
  }

  List<File> skip(int n) => new ListView<File>(this, n, null);

  Iterable<File> skipWhile(bool test(File value)) {
    return new SkipWhileIterable<File>(this, test);
  }

  File firstMatching(bool test(File value), { File orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  File lastMatching(bool test(File value), {File orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  File singleMatching(bool test(File value)) {
    return Collections.singleMatching(this, test);
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

  File min([int compare(File a, File b)]) => Collections.min(this, compare);

  File max([int compare(File a, File b)]) => Collections.max(this, compare);

  File removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  File removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('FileList.item')
  File item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('FileReader')
class FileReader extends EventTarget native "*FileReader" {

  static const EventStreamProvider<ProgressEvent> abortEvent = const EventStreamProvider<ProgressEvent>('abort');

  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  static const EventStreamProvider<ProgressEvent> loadEvent = const EventStreamProvider<ProgressEvent>('load');

  static const EventStreamProvider<ProgressEvent> loadEndEvent = const EventStreamProvider<ProgressEvent>('loadend');

  static const EventStreamProvider<ProgressEvent> loadStartEvent = const EventStreamProvider<ProgressEvent>('loadstart');

  static const EventStreamProvider<ProgressEvent> progressEvent = const EventStreamProvider<ProgressEvent>('progress');

  @DocsEditable
  factory FileReader() => FileReader._create();
  static FileReader _create() => JS('FileReader', 'new FileReader()');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  FileReaderEvents get on =>
    new FileReaderEvents(this);

  static const int DONE = 2;

  static const int EMPTY = 0;

  static const int LOADING = 1;

  @DocsEditable @DomName('FileReader.error')
  final FileError error;

  @DocsEditable @DomName('FileReader.readyState')
  final int readyState;

  @DocsEditable @DomName('FileReader.result') @Creates('String|ArrayBuffer|Null')
  final Object result;

  @DocsEditable @DomName('FileReader.abort')
  void abort() native;

  @JSName('addEventListener')
  @DocsEditable @DomName('FileReader.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('FileReader.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  @DocsEditable @DomName('FileReader.readAsArrayBuffer')
  void readAsArrayBuffer(Blob blob) native;

  @DocsEditable @DomName('FileReader.readAsBinaryString')
  void readAsBinaryString(Blob blob) native;

  @JSName('readAsDataURL')
  @DocsEditable @DomName('FileReader.readAsDataURL')
  void readAsDataUrl(Blob blob) native;

  @DocsEditable @DomName('FileReader.readAsText')
  void readAsText(Blob blob, [String encoding]) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('FileReader.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  Stream<ProgressEvent> get onAbort => abortEvent.forTarget(this);

  Stream<Event> get onError => errorEvent.forTarget(this);

  Stream<ProgressEvent> get onLoad => loadEvent.forTarget(this);

  Stream<ProgressEvent> get onLoadEnd => loadEndEvent.forTarget(this);

  Stream<ProgressEvent> get onLoadStart => loadStartEvent.forTarget(this);

  Stream<ProgressEvent> get onProgress => progressEvent.forTarget(this);
}

@DocsEditable
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

  @DocsEditable @DomName('FileReaderSync.readAsArrayBuffer')
  ArrayBuffer readAsArrayBuffer(Blob blob) native;

  @DocsEditable @DomName('FileReaderSync.readAsBinaryString')
  String readAsBinaryString(Blob blob) native;

  @JSName('readAsDataURL')
  @DocsEditable @DomName('FileReaderSync.readAsDataURL')
  String readAsDataUrl(Blob blob) native;

  @DocsEditable @DomName('FileReaderSync.readAsText')
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

  @DocsEditable @DomName('DOMFileSystem.name')
  final String name;

  @DocsEditable @DomName('DOMFileSystem.root')
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

  @DocsEditable @DomName('DOMFileSystemSync.name')
  final String name;

  @DocsEditable @DomName('DOMFileSystemSync.root')
  final DirectoryEntrySync root;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('FileWriter')
class FileWriter extends EventTarget native "*FileWriter" {

  static const EventStreamProvider<ProgressEvent> abortEvent = const EventStreamProvider<ProgressEvent>('abort');

  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  static const EventStreamProvider<ProgressEvent> progressEvent = const EventStreamProvider<ProgressEvent>('progress');

  static const EventStreamProvider<ProgressEvent> writeEvent = const EventStreamProvider<ProgressEvent>('write');

  static const EventStreamProvider<ProgressEvent> writeEndEvent = const EventStreamProvider<ProgressEvent>('writeend');

  static const EventStreamProvider<ProgressEvent> writeStartEvent = const EventStreamProvider<ProgressEvent>('writestart');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  FileWriterEvents get on =>
    new FileWriterEvents(this);

  static const int DONE = 2;

  static const int INIT = 0;

  static const int WRITING = 1;

  @DocsEditable @DomName('FileWriter.error')
  final FileError error;

  @DocsEditable @DomName('FileWriter.length')
  final int length;

  @DocsEditable @DomName('FileWriter.position')
  final int position;

  @DocsEditable @DomName('FileWriter.readyState')
  final int readyState;

  @DocsEditable @DomName('FileWriter.abort')
  void abort() native;

  @JSName('addEventListener')
  @DocsEditable @DomName('FileWriter.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('FileWriter.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('FileWriter.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('FileWriter.seek')
  void seek(int position) native;

  @DocsEditable @DomName('FileWriter.truncate')
  void truncate(int size) native;

  @DocsEditable @DomName('FileWriter.write')
  void write(Blob data) native;

  Stream<ProgressEvent> get onAbort => abortEvent.forTarget(this);

  Stream<Event> get onError => errorEvent.forTarget(this);

  Stream<ProgressEvent> get onProgress => progressEvent.forTarget(this);

  Stream<ProgressEvent> get onWrite => writeEvent.forTarget(this);

  Stream<ProgressEvent> get onWriteEnd => writeEndEvent.forTarget(this);

  Stream<ProgressEvent> get onWriteStart => writeStartEvent.forTarget(this);
}

@DocsEditable
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

  @DocsEditable @DomName('FileWriterSync.length')
  final int length;

  @DocsEditable @DomName('FileWriterSync.position')
  final int position;

  @DocsEditable @DomName('FileWriterSync.seek')
  void seek(int position) native;

  @DocsEditable @DomName('FileWriterSync.truncate')
  void truncate(int size) native;

  @DocsEditable @DomName('FileWriterSync.write')
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

  @DocsEditable @DomName('Float32Array.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(num element) => Collections.contains(this, element);

  void forEach(void f(num element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(num element)) => new MappedList<num, dynamic>(this, f);

  Iterable<num> where(bool f(num element)) => new WhereIterable<num>(this, f);

  bool every(bool f(num element)) => Collections.every(this, f);

  bool any(bool f(num element)) => Collections.any(this, f);

  List<num> toList() => new List<num>.from(this);
  Set<num> toSet() => new Set<num>.from(this);

  bool get isEmpty => this.length == 0;

  List<num> take(int n) => new ListView<num>(this, 0, n);

  Iterable<num> takeWhile(bool test(num value)) {
    return new TakeWhileIterable<num>(this, test);
  }

  List<num> skip(int n) => new ListView<num>(this, n, null);

  Iterable<num> skipWhile(bool test(num value)) {
    return new SkipWhileIterable<num>(this, test);
  }

  num firstMatching(bool test(num value), { num orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  num lastMatching(bool test(num value), {num orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  num singleMatching(bool test(num value)) {
    return Collections.singleMatching(this, test);
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

  num min([int compare(num a, num b)]) => Collections.min(this, compare);

  num max([int compare(num a, num b)]) => Collections.max(this, compare);

  num removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  num removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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
  @DocsEditable @DomName('Float32Array.set')
  void setElements(Object array, [int offset]) native;

  @DocsEditable @DomName('Float32Array.subarray')
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

  @DocsEditable @DomName('Float64Array.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(num element) => Collections.contains(this, element);

  void forEach(void f(num element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(num element)) => new MappedList<num, dynamic>(this, f);

  Iterable<num> where(bool f(num element)) => new WhereIterable<num>(this, f);

  bool every(bool f(num element)) => Collections.every(this, f);

  bool any(bool f(num element)) => Collections.any(this, f);

  List<num> toList() => new List<num>.from(this);
  Set<num> toSet() => new Set<num>.from(this);

  bool get isEmpty => this.length == 0;

  List<num> take(int n) => new ListView<num>(this, 0, n);

  Iterable<num> takeWhile(bool test(num value)) {
    return new TakeWhileIterable<num>(this, test);
  }

  List<num> skip(int n) => new ListView<num>(this, n, null);

  Iterable<num> skipWhile(bool test(num value)) {
    return new SkipWhileIterable<num>(this, test);
  }

  num firstMatching(bool test(num value), { num orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  num lastMatching(bool test(num value), {num orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  num singleMatching(bool test(num value)) {
    return Collections.singleMatching(this, test);
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

  num min([int compare(num a, num b)]) => Collections.min(this, compare);

  num max([int compare(num a, num b)]) => Collections.max(this, compare);

  num removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  num removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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
  @DocsEditable @DomName('Float64Array.set')
  void setElements(Object array, [int offset]) native;

  @DocsEditable @DomName('Float64Array.subarray')
  Float64Array subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('HTMLFontElement')
class FontElement extends Element native "*HTMLFontElement" {

  @DocsEditable @DomName('HTMLFontElement.color')
  String color;

  @DocsEditable @DomName('HTMLFontElement.face')
  String face;

  @DocsEditable @DomName('HTMLFontElement.size')
  String size;
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

  @DocsEditable @DomName('DOMFormData.append')
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

  @DocsEditable @DomName('HTMLFormElement.acceptCharset')
  String acceptCharset;

  @DocsEditable @DomName('HTMLFormElement.action')
  String action;

  @DocsEditable @DomName('HTMLFormElement.autocomplete')
  String autocomplete;

  @DocsEditable @DomName('HTMLFormElement.encoding')
  String encoding;

  @DocsEditable @DomName('HTMLFormElement.enctype')
  String enctype;

  @DocsEditable @DomName('HTMLFormElement.length')
  final int length;

  @DocsEditable @DomName('HTMLFormElement.method')
  String method;

  @DocsEditable @DomName('HTMLFormElement.name')
  String name;

  @DocsEditable @DomName('HTMLFormElement.noValidate')
  bool noValidate;

  @DocsEditable @DomName('HTMLFormElement.target')
  String target;

  @DocsEditable @DomName('HTMLFormElement.checkValidity')
  bool checkValidity() native;

  @DocsEditable @DomName('HTMLFormElement.reset')
  void reset() native;

  @DocsEditable @DomName('HTMLFormElement.submit')
  void submit() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('HTMLFrameElement')
class FrameElement extends Element native "*HTMLFrameElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('HTMLFrameSetElement')
class FrameSetElement extends Element native "*HTMLFrameSetElement" {

  static const EventStreamProvider<Event> beforeUnloadEvent = const EventStreamProvider<Event>('beforeunload');

  static const EventStreamProvider<Event> blurEvent = const EventStreamProvider<Event>('blur');

  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  static const EventStreamProvider<Event> focusEvent = const EventStreamProvider<Event>('focus');

  static const EventStreamProvider<HashChangeEvent> hashChangeEvent = const EventStreamProvider<HashChangeEvent>('hashchange');

  static const EventStreamProvider<Event> loadEvent = const EventStreamProvider<Event>('load');

  static const EventStreamProvider<MessageEvent> messageEvent = const EventStreamProvider<MessageEvent>('message');

  static const EventStreamProvider<Event> offlineEvent = const EventStreamProvider<Event>('offline');

  static const EventStreamProvider<Event> onlineEvent = const EventStreamProvider<Event>('online');

  static const EventStreamProvider<PopStateEvent> popStateEvent = const EventStreamProvider<PopStateEvent>('popstate');

  static const EventStreamProvider<Event> resizeEvent = const EventStreamProvider<Event>('resize');

  static const EventStreamProvider<StorageEvent> storageEvent = const EventStreamProvider<StorageEvent>('storage');

  static const EventStreamProvider<Event> unloadEvent = const EventStreamProvider<Event>('unload');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  FrameSetElementEvents get on =>
    new FrameSetElementEvents(this);

  Stream<Event> get onBeforeUnload => beforeUnloadEvent.forTarget(this);

  Stream<Event> get onBlur => blurEvent.forTarget(this);

  Stream<Event> get onError => errorEvent.forTarget(this);

  Stream<Event> get onFocus => focusEvent.forTarget(this);

  Stream<HashChangeEvent> get onHashChange => hashChangeEvent.forTarget(this);

  Stream<Event> get onLoad => loadEvent.forTarget(this);

  Stream<MessageEvent> get onMessage => messageEvent.forTarget(this);

  Stream<Event> get onOffline => offlineEvent.forTarget(this);

  Stream<Event> get onOnline => onlineEvent.forTarget(this);

  Stream<PopStateEvent> get onPopState => popStateEvent.forTarget(this);

  Stream<Event> get onResize => resizeEvent.forTarget(this);

  Stream<StorageEvent> get onStorage => storageEvent.forTarget(this);

  Stream<Event> get onUnload => unloadEvent.forTarget(this);
}

@DocsEditable
class FrameSetElementEvents extends ElementEvents {
  @DocsEditable
  FrameSetElementEvents(EventTarget _ptr) : super(_ptr);

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
@DomName('Gamepad')
class Gamepad native "*Gamepad" {

  @DocsEditable @DomName('Gamepad.axes')
  final List<num> axes;

  @DocsEditable @DomName('Gamepad.buttons')
  final List<num> buttons;

  @DocsEditable @DomName('Gamepad.id')
  final String id;

  @DocsEditable @DomName('Gamepad.index')
  final int index;

  @DocsEditable @DomName('Gamepad.timestamp')
  final int timestamp;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('Geolocation')
class Geolocation native "*Geolocation" {

  @DocsEditable @DomName('Geolocation.clearWatch')
  void clearWatch(int watchId) native;

  @DocsEditable @DomName('Geolocation.getCurrentPosition')
  void getCurrentPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback, Object options]) native;

  @DocsEditable @DomName('Geolocation.watchPosition')
  int watchPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback, Object options]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('Geoposition')
class Geoposition native "*Geoposition" {

  @DocsEditable @DomName('Geoposition.coords')
  final Coordinates coords;

  @DocsEditable @DomName('Geoposition.timestamp')
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
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('HashChangeEvent')
class HashChangeEvent extends Event native "*HashChangeEvent" {

  @JSName('newURL')
  @DocsEditable @DomName('HashChangeEvent.newURL')
  final String newUrl;

  @JSName('oldURL')
  @DocsEditable @DomName('HashChangeEvent.oldURL')
  final String oldUrl;

  @DocsEditable @DomName('HashChangeEvent.initHashChangeEvent')
  void initHashChangeEvent(String type, bool canBubble, bool cancelable, String oldURL, String newURL) native;
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



@DocsEditable
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

  @DocsEditable @DomName('History.length')
  final int length;

  dynamic get state => _convertNativeToDart_SerializedScriptValue(this._state);
  @JSName('state')
  @DocsEditable @DomName('History.state') @annotation_Creates_SerializedScriptValue @annotation_Returns_SerializedScriptValue
  final dynamic _state;

  @DocsEditable @DomName('History.back')
  void back() native;

  @DocsEditable @DomName('History.forward')
  void forward() native;

  @DocsEditable @DomName('History.go')
  void go(int distance) native;

  @DocsEditable @DomName('History.pushState') @SupportedBrowser(SupportedBrowser.CHROME) @SupportedBrowser(SupportedBrowser.FIREFOX) @SupportedBrowser(SupportedBrowser.IE, '10') @SupportedBrowser(SupportedBrowser.SAFARI)
  void pushState(Object data, String title, [String url]) native;

  @DocsEditable @DomName('History.replaceState') @SupportedBrowser(SupportedBrowser.CHROME) @SupportedBrowser(SupportedBrowser.FIREFOX) @SupportedBrowser(SupportedBrowser.IE, '10') @SupportedBrowser(SupportedBrowser.SAFARI)
  void replaceState(Object data, String title, [String url]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('HTMLAllCollection')
class HtmlAllCollection implements JavaScriptIndexingBehavior, List<Node> native "*HTMLAllCollection" {

  @DocsEditable @DomName('HTMLAllCollection.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(Node element) => Collections.contains(this, element);

  void forEach(void f(Node element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(Node element)) => new MappedList<Node, dynamic>(this, f);

  Iterable<Node> where(bool f(Node element)) => new WhereIterable<Node>(this, f);

  bool every(bool f(Node element)) => Collections.every(this, f);

  bool any(bool f(Node element)) => Collections.any(this, f);

  List<Node> toList() => new List<Node>.from(this);
  Set<Node> toSet() => new Set<Node>.from(this);

  bool get isEmpty => this.length == 0;

  List<Node> take(int n) => new ListView<Node>(this, 0, n);

  Iterable<Node> takeWhile(bool test(Node value)) {
    return new TakeWhileIterable<Node>(this, test);
  }

  List<Node> skip(int n) => new ListView<Node>(this, n, null);

  Iterable<Node> skipWhile(bool test(Node value)) {
    return new SkipWhileIterable<Node>(this, test);
  }

  Node firstMatching(bool test(Node value), { Node orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  Node lastMatching(bool test(Node value), {Node orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  Node singleMatching(bool test(Node value)) {
    return Collections.singleMatching(this, test);
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

  Node min([int compare(Node a, Node b)]) => Collections.min(this, compare);

  Node max([int compare(Node a, Node b)]) => Collections.max(this, compare);

  Node removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  Node removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('HTMLAllCollection.item')
  Node item(int index) native;

  @DocsEditable @DomName('HTMLAllCollection.namedItem')
  Node namedItem(String name) native;

  @DocsEditable @DomName('HTMLAllCollection.tags')
  @Returns('NodeList') @Creates('NodeList')
  List<Node> tags(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('HTMLCollection')
class HtmlCollection implements JavaScriptIndexingBehavior, List<Node> native "*HTMLCollection" {

  @DocsEditable @DomName('HTMLCollection.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(Node element) => Collections.contains(this, element);

  void forEach(void f(Node element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(Node element)) => new MappedList<Node, dynamic>(this, f);

  Iterable<Node> where(bool f(Node element)) => new WhereIterable<Node>(this, f);

  bool every(bool f(Node element)) => Collections.every(this, f);

  bool any(bool f(Node element)) => Collections.any(this, f);

  List<Node> toList() => new List<Node>.from(this);
  Set<Node> toSet() => new Set<Node>.from(this);

  bool get isEmpty => this.length == 0;

  List<Node> take(int n) => new ListView<Node>(this, 0, n);

  Iterable<Node> takeWhile(bool test(Node value)) {
    return new TakeWhileIterable<Node>(this, test);
  }

  List<Node> skip(int n) => new ListView<Node>(this, n, null);

  Iterable<Node> skipWhile(bool test(Node value)) {
    return new SkipWhileIterable<Node>(this, test);
  }

  Node firstMatching(bool test(Node value), { Node orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  Node lastMatching(bool test(Node value), {Node orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  Node singleMatching(bool test(Node value)) {
    return Collections.singleMatching(this, test);
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

  Node min([int compare(Node a, Node b)]) => Collections.min(this, compare);

  Node max([int compare(Node a, Node b)]) => Collections.max(this, compare);

  Node removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  Node removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('HTMLCollection.item')
  Node item(int index) native;

  @DocsEditable @DomName('HTMLCollection.namedItem')
  Node namedItem(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('HTMLDocument')
class HtmlDocument extends Document native "*HTMLDocument" {

  @DocsEditable @DomName('HTMLDocument.activeElement')
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
  @Experimental()
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

  @DocsEditable @DomName('HTMLFormControlsCollection.namedItem')
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


  static const EventStreamProvider<ProgressEvent> abortEvent = const EventStreamProvider<ProgressEvent>('abort');

  static const EventStreamProvider<ProgressEvent> errorEvent = const EventStreamProvider<ProgressEvent>('error');

  static const EventStreamProvider<ProgressEvent> loadEvent = const EventStreamProvider<ProgressEvent>('load');

  static const EventStreamProvider<ProgressEvent> loadEndEvent = const EventStreamProvider<ProgressEvent>('loadend');

  static const EventStreamProvider<ProgressEvent> loadStartEvent = const EventStreamProvider<ProgressEvent>('loadstart');

  static const EventStreamProvider<ProgressEvent> progressEvent = const EventStreamProvider<ProgressEvent>('progress');

  static const EventStreamProvider<ProgressEvent> readyStateChangeEvent = const EventStreamProvider<ProgressEvent>('readystatechange');

  @DocsEditable
  factory HttpRequest() => HttpRequest._create();
  static HttpRequest _create() => JS('HttpRequest', 'new XMLHttpRequest()');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  HttpRequestEvents get on =>
    new HttpRequestEvents(this);

  static const int DONE = 4;

  static const int HEADERS_RECEIVED = 2;

  static const int LOADING = 3;

  static const int OPENED = 1;

  static const int UNSENT = 0;

  @DocsEditable @DomName('XMLHttpRequest.readyState')
  final int readyState;

  @DocsEditable @DomName('XMLHttpRequest.response') @Creates('ArrayBuffer|Blob|Document|=Object|=List|String|num')
  final Object response;

  @DocsEditable @DomName('XMLHttpRequest.responseText')
  final String responseText;

  @DocsEditable @DomName('XMLHttpRequest.responseType')
  String responseType;

  @JSName('responseXML')
  @DocsEditable @DomName('XMLHttpRequest.responseXML')
  final Document responseXml;

  @DocsEditable @DomName('XMLHttpRequest.status')
  final int status;

  @DocsEditable @DomName('XMLHttpRequest.statusText')
  final String statusText;

  @DocsEditable @DomName('XMLHttpRequest.upload')
  final HttpRequestUpload upload;

  @DocsEditable @DomName('XMLHttpRequest.withCredentials')
  bool withCredentials;

  @DocsEditable @DomName('XMLHttpRequest.abort')
  void abort() native;

  @JSName('addEventListener')
  @DocsEditable @DomName('XMLHttpRequest.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('XMLHttpRequest.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  @DocsEditable @DomName('XMLHttpRequest.getAllResponseHeaders')
  String getAllResponseHeaders() native;

  @DocsEditable @DomName('XMLHttpRequest.getResponseHeader')
  String getResponseHeader(String header) native;

  @DocsEditable @DomName('XMLHttpRequest.open')
  void open(String method, String url, [bool async, String user, String password]) native;

  @DocsEditable @DomName('XMLHttpRequest.overrideMimeType')
  void overrideMimeType(String override) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('XMLHttpRequest.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('XMLHttpRequest.send')
  void send([data]) native;

  @DocsEditable @DomName('XMLHttpRequest.setRequestHeader')
  void setRequestHeader(String header, String value) native;

  Stream<ProgressEvent> get onAbort => abortEvent.forTarget(this);

  Stream<ProgressEvent> get onError => errorEvent.forTarget(this);

  Stream<ProgressEvent> get onLoad => loadEvent.forTarget(this);

  Stream<ProgressEvent> get onLoadEnd => loadEndEvent.forTarget(this);

  Stream<ProgressEvent> get onLoadStart => loadStartEvent.forTarget(this);

  Stream<ProgressEvent> get onProgress => progressEvent.forTarget(this);

  Stream<ProgressEvent> get onReadyStateChange => readyStateChangeEvent.forTarget(this);

}

@DocsEditable
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

  @DocsEditable @DomName('XMLHttpRequestException.code')
  final int code;

  @DocsEditable @DomName('XMLHttpRequestException.message')
  final String message;

  @DocsEditable @DomName('XMLHttpRequestException.name')
  final String name;

  @DocsEditable @DomName('XMLHttpRequestException.toString')
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('XMLHttpRequestProgressEvent')
class HttpRequestProgressEvent extends ProgressEvent native "*XMLHttpRequestProgressEvent" {

  @DocsEditable @DomName('XMLHttpRequestProgressEvent.position')
  final int position;

  @DocsEditable @DomName('XMLHttpRequestProgressEvent.totalSize')
  final int totalSize;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('XMLHttpRequestUpload')
class HttpRequestUpload extends EventTarget native "*XMLHttpRequestUpload" {

  static const EventStreamProvider<ProgressEvent> abortEvent = const EventStreamProvider<ProgressEvent>('abort');

  static const EventStreamProvider<ProgressEvent> errorEvent = const EventStreamProvider<ProgressEvent>('error');

  static const EventStreamProvider<ProgressEvent> loadEvent = const EventStreamProvider<ProgressEvent>('load');

  static const EventStreamProvider<ProgressEvent> loadEndEvent = const EventStreamProvider<ProgressEvent>('loadend');

  static const EventStreamProvider<ProgressEvent> loadStartEvent = const EventStreamProvider<ProgressEvent>('loadstart');

  static const EventStreamProvider<ProgressEvent> progressEvent = const EventStreamProvider<ProgressEvent>('progress');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  HttpRequestUploadEvents get on =>
    new HttpRequestUploadEvents(this);

  @JSName('addEventListener')
  @DocsEditable @DomName('XMLHttpRequestUpload.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('XMLHttpRequestUpload.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('XMLHttpRequestUpload.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  Stream<ProgressEvent> get onAbort => abortEvent.forTarget(this);

  Stream<ProgressEvent> get onError => errorEvent.forTarget(this);

  Stream<ProgressEvent> get onLoad => loadEvent.forTarget(this);

  Stream<ProgressEvent> get onLoadEnd => loadEndEvent.forTarget(this);

  Stream<ProgressEvent> get onLoadStart => loadStartEvent.forTarget(this);

  Stream<ProgressEvent> get onProgress => progressEvent.forTarget(this);
}

@DocsEditable
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
  @DocsEditable @DomName('HTMLIFrameElement.contentWindow') @Creates('Window|=Object') @Returns('Window|=Object')
  final dynamic _contentWindow;

  @DocsEditable @DomName('HTMLIFrameElement.height')
  String height;

  @DocsEditable @DomName('HTMLIFrameElement.name')
  String name;

  @DocsEditable @DomName('HTMLIFrameElement.sandbox')
  String sandbox;

  @DocsEditable @DomName('HTMLIFrameElement.src')
  String src;

  @DocsEditable @DomName('HTMLIFrameElement.srcdoc')
  String srcdoc;

  @DocsEditable @DomName('HTMLIFrameElement.width')
  String width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('ImageData')
class ImageData native "*ImageData" {

  @DocsEditable @DomName('ImageData.data')
  final Uint8ClampedArray data;

  @DocsEditable @DomName('ImageData.height')
  final int height;

  @DocsEditable @DomName('ImageData.width')
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

  @DocsEditable @DomName('HTMLImageElement.alt')
  String alt;

  @DocsEditable @DomName('HTMLImageElement.border')
  String border;

  @DocsEditable @DomName('HTMLImageElement.complete')
  final bool complete;

  @DocsEditable @DomName('HTMLImageElement.crossOrigin')
  String crossOrigin;

  @DocsEditable @DomName('HTMLImageElement.height')
  int height;

  @DocsEditable @DomName('HTMLImageElement.isMap')
  bool isMap;

  @DocsEditable @DomName('HTMLImageElement.lowsrc')
  String lowsrc;

  @DocsEditable @DomName('HTMLImageElement.naturalHeight')
  final int naturalHeight;

  @DocsEditable @DomName('HTMLImageElement.naturalWidth')
  final int naturalWidth;

  @DocsEditable @DomName('HTMLImageElement.src')
  String src;

  @DocsEditable @DomName('HTMLImageElement.useMap')
  String useMap;

  @DocsEditable @DomName('HTMLImageElement.width')
  int width;

  @DocsEditable @DomName('HTMLImageElement.x')
  final int x;

  @DocsEditable @DomName('HTMLImageElement.y')
  final int y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
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

  @DocsEditable
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

  static const EventStreamProvider<Event> speechChangeEvent = const EventStreamProvider<Event>('webkitSpeechChange');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  InputElementEvents get on =>
    new InputElementEvents(this);

  @DocsEditable @DomName('HTMLInputElement.accept')
  String accept;

  @DocsEditable @DomName('HTMLInputElement.alt')
  String alt;

  @DocsEditable @DomName('HTMLInputElement.autocomplete')
  String autocomplete;

  @DocsEditable @DomName('HTMLInputElement.autofocus')
  bool autofocus;

  @DocsEditable @DomName('HTMLInputElement.checked')
  bool checked;

  @DocsEditable @DomName('HTMLInputElement.defaultChecked')
  bool defaultChecked;

  @DocsEditable @DomName('HTMLInputElement.defaultValue')
  String defaultValue;

  @DocsEditable @DomName('HTMLInputElement.dirName')
  String dirName;

  @DocsEditable @DomName('HTMLInputElement.disabled')
  bool disabled;

  @DocsEditable @DomName('HTMLInputElement.files')
  @Returns('FileList') @Creates('FileList')
  List<File> files;

  @DocsEditable @DomName('HTMLInputElement.form')
  final FormElement form;

  @DocsEditable @DomName('HTMLInputElement.formAction')
  String formAction;

  @DocsEditable @DomName('HTMLInputElement.formEnctype')
  String formEnctype;

  @DocsEditable @DomName('HTMLInputElement.formMethod')
  String formMethod;

  @DocsEditable @DomName('HTMLInputElement.formNoValidate')
  bool formNoValidate;

  @DocsEditable @DomName('HTMLInputElement.formTarget')
  String formTarget;

  @DocsEditable @DomName('HTMLInputElement.height')
  int height;

  @DocsEditable @DomName('HTMLInputElement.incremental')
  bool incremental;

  @DocsEditable @DomName('HTMLInputElement.indeterminate')
  bool indeterminate;

  @DocsEditable @DomName('HTMLInputElement.labels')
  @Returns('NodeList') @Creates('NodeList')
  final List<Node> labels;

  @DocsEditable @DomName('HTMLInputElement.list')
  final Element list;

  @DocsEditable @DomName('HTMLInputElement.max')
  String max;

  @DocsEditable @DomName('HTMLInputElement.maxLength')
  int maxLength;

  @DocsEditable @DomName('HTMLInputElement.min')
  String min;

  @DocsEditable @DomName('HTMLInputElement.multiple')
  bool multiple;

  @DocsEditable @DomName('HTMLInputElement.name')
  String name;

  @DocsEditable @DomName('HTMLInputElement.pattern')
  String pattern;

  @DocsEditable @DomName('HTMLInputElement.placeholder')
  String placeholder;

  @DocsEditable @DomName('HTMLInputElement.readOnly')
  bool readOnly;

  @DocsEditable @DomName('HTMLInputElement.required')
  bool required;

  @DocsEditable @DomName('HTMLInputElement.selectionDirection')
  String selectionDirection;

  @DocsEditable @DomName('HTMLInputElement.selectionEnd')
  int selectionEnd;

  @DocsEditable @DomName('HTMLInputElement.selectionStart')
  int selectionStart;

  @DocsEditable @DomName('HTMLInputElement.size')
  int size;

  @DocsEditable @DomName('HTMLInputElement.src')
  String src;

  @DocsEditable @DomName('HTMLInputElement.step')
  String step;

  @DocsEditable @DomName('HTMLInputElement.type')
  String type;

  @DocsEditable @DomName('HTMLInputElement.useMap')
  String useMap;

  @DocsEditable @DomName('HTMLInputElement.validationMessage')
  final String validationMessage;

  @DocsEditable @DomName('HTMLInputElement.validity')
  final ValidityState validity;

  @DocsEditable @DomName('HTMLInputElement.value')
  String value;

  @DocsEditable @DomName('HTMLInputElement.valueAsDate')
  Date valueAsDate;

  @DocsEditable @DomName('HTMLInputElement.valueAsNumber')
  num valueAsNumber;

  @DocsEditable @DomName('HTMLInputElement.webkitEntries')
  @Returns('_EntryArray') @Creates('_EntryArray')
  final List<Entry> webkitEntries;

  @DocsEditable @DomName('HTMLInputElement.webkitGrammar')
  bool webkitGrammar;

  @DocsEditable @DomName('HTMLInputElement.webkitSpeech')
  bool webkitSpeech;

  @DocsEditable @DomName('HTMLInputElement.webkitdirectory')
  bool webkitdirectory;

  @DocsEditable @DomName('HTMLInputElement.width')
  int width;

  @DocsEditable @DomName('HTMLInputElement.willValidate')
  final bool willValidate;

  @DocsEditable @DomName('HTMLInputElement.checkValidity')
  bool checkValidity() native;

  @DocsEditable @DomName('HTMLInputElement.select')
  void select() native;

  @DocsEditable @DomName('HTMLInputElement.setCustomValidity')
  void setCustomValidity(String error) native;

  @DocsEditable @DomName('HTMLInputElement.setRangeText')
  void setRangeText(String replacement, [int start, int end, String selectionMode]) native;

  @DocsEditable @DomName('HTMLInputElement.setSelectionRange')
  void setSelectionRange(int start, int end, [String direction]) native;

  @DocsEditable @DomName('HTMLInputElement.stepDown')
  void stepDown([int n]) native;

  @DocsEditable @DomName('HTMLInputElement.stepUp')
  void stepUp([int n]) native;

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
@Experimental()
abstract class DateTimeInputElement implements RangeInputElementBase {
  factory DateTimeInputElement() => new InputElement(type: 'datetime');

  @DomName('HTMLInputElement.valueAsDate')
  Date valueAsDate;

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
@Experimental()
abstract class DateInputElement implements RangeInputElementBase {
  factory DateInputElement() => new InputElement(type: 'date');

  @DomName('HTMLInputElement.valueAsDate')
  Date valueAsDate;

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
@Experimental()
abstract class MonthInputElement implements RangeInputElementBase {
  factory MonthInputElement() => new InputElement(type: 'month');

  @DomName('HTMLInputElement.valueAsDate')
  Date valueAsDate;

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
@Experimental()
abstract class WeekInputElement implements RangeInputElementBase {
  factory WeekInputElement() => new InputElement(type: 'week');

  @DomName('HTMLInputElement.valueAsDate')
  Date valueAsDate;

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
@Experimental()
abstract class TimeInputElement implements RangeInputElementBase {
  factory TimeInputElement() => new InputElement(type: 'time');

  @DomName('HTMLInputElement.valueAsDate')
  Date valueAsDate;

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
@Experimental()
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
@Experimental()
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
@Experimental()
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

  @DocsEditable @DomName('Int16Array.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(int element) => Collections.contains(this, element);

  void forEach(void f(int element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(int element)) => new MappedList<int, dynamic>(this, f);

  Iterable<int> where(bool f(int element)) => new WhereIterable<int>(this, f);

  bool every(bool f(int element)) => Collections.every(this, f);

  bool any(bool f(int element)) => Collections.any(this, f);

  List<int> toList() => new List<int>.from(this);
  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  List<int> take(int n) => new ListView<int>(this, 0, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return new TakeWhileIterable<int>(this, test);
  }

  List<int> skip(int n) => new ListView<int>(this, n, null);

  Iterable<int> skipWhile(bool test(int value)) {
    return new SkipWhileIterable<int>(this, test);
  }

  int firstMatching(bool test(int value), { int orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  int lastMatching(bool test(int value), {int orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  int singleMatching(bool test(int value)) {
    return Collections.singleMatching(this, test);
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

  int min([int compare(int a, int b)]) => Collections.min(this, compare);

  int max([int compare(int a, int b)]) => Collections.max(this, compare);

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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
  @DocsEditable @DomName('Int16Array.set')
  void setElements(Object array, [int offset]) native;

  @DocsEditable @DomName('Int16Array.subarray')
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

  @DocsEditable @DomName('Int32Array.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(int element) => Collections.contains(this, element);

  void forEach(void f(int element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(int element)) => new MappedList<int, dynamic>(this, f);

  Iterable<int> where(bool f(int element)) => new WhereIterable<int>(this, f);

  bool every(bool f(int element)) => Collections.every(this, f);

  bool any(bool f(int element)) => Collections.any(this, f);

  List<int> toList() => new List<int>.from(this);
  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  List<int> take(int n) => new ListView<int>(this, 0, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return new TakeWhileIterable<int>(this, test);
  }

  List<int> skip(int n) => new ListView<int>(this, n, null);

  Iterable<int> skipWhile(bool test(int value)) {
    return new SkipWhileIterable<int>(this, test);
  }

  int firstMatching(bool test(int value), { int orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  int lastMatching(bool test(int value), {int orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  int singleMatching(bool test(int value)) {
    return Collections.singleMatching(this, test);
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

  int min([int compare(int a, int b)]) => Collections.min(this, compare);

  int max([int compare(int a, int b)]) => Collections.max(this, compare);

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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
  @DocsEditable @DomName('Int32Array.set')
  void setElements(Object array, [int offset]) native;

  @DocsEditable @DomName('Int32Array.subarray')
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

  @DocsEditable @DomName('Int8Array.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(int element) => Collections.contains(this, element);

  void forEach(void f(int element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(int element)) => new MappedList<int, dynamic>(this, f);

  Iterable<int> where(bool f(int element)) => new WhereIterable<int>(this, f);

  bool every(bool f(int element)) => Collections.every(this, f);

  bool any(bool f(int element)) => Collections.any(this, f);

  List<int> toList() => new List<int>.from(this);
  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  List<int> take(int n) => new ListView<int>(this, 0, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return new TakeWhileIterable<int>(this, test);
  }

  List<int> skip(int n) => new ListView<int>(this, n, null);

  Iterable<int> skipWhile(bool test(int value)) {
    return new SkipWhileIterable<int>(this, test);
  }

  int firstMatching(bool test(int value), { int orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  int lastMatching(bool test(int value), {int orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  int singleMatching(bool test(int value)) {
    return Collections.singleMatching(this, test);
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

  int min([int compare(int a, int b)]) => Collections.min(this, compare);

  int max([int compare(int a, int b)]) => Collections.max(this, compare);

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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
  @DocsEditable @DomName('Int8Array.set')
  void setElements(Object array, [int offset]) native;

  @DocsEditable @DomName('Int8Array.subarray')
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

  @DocsEditable @DomName('JavaScriptCallFrame.caller')
  final JavaScriptCallFrame caller;

  @DocsEditable @DomName('JavaScriptCallFrame.column')
  final int column;

  @DocsEditable @DomName('JavaScriptCallFrame.functionName')
  final String functionName;

  @DocsEditable @DomName('JavaScriptCallFrame.line')
  final int line;

  @DocsEditable @DomName('JavaScriptCallFrame.scopeChain')
  final List scopeChain;

  @DocsEditable @DomName('JavaScriptCallFrame.sourceID')
  final int sourceID;

  @DocsEditable @DomName('JavaScriptCallFrame.thisObject')
  final Object thisObject;

  @DocsEditable @DomName('JavaScriptCallFrame.type')
  final String type;

  @DocsEditable @DomName('JavaScriptCallFrame.evaluate')
  void evaluate(String script) native;

  @DocsEditable @DomName('JavaScriptCallFrame.restart')
  Object restart() native;

  @DocsEditable @DomName('JavaScriptCallFrame.scopeType')
  int scopeType(int scopeIndex) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('KeyboardEvent')
class KeyboardEvent extends UIEvent native "*KeyboardEvent" {

  factory KeyboardEvent(String type, Window view,
      [bool canBubble = true, bool cancelable = true,
      String keyIdentifier = "", int keyLocation = 1, bool ctrlKey = false,
      bool altKey = false, bool shiftKey = false, bool metaKey = false,
      bool altGraphKey = false]) {
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

  @DocsEditable @DomName('KeyboardEvent.altGraphKey')
  final bool altGraphKey;

  @DocsEditable @DomName('KeyboardEvent.altKey')
  final bool altKey;

  @DocsEditable @DomName('KeyboardEvent.ctrlKey')
  final bool ctrlKey;

  @JSName('keyIdentifier')
  @DocsEditable @DomName('KeyboardEvent.keyIdentifier')
  final String $dom_keyIdentifier;

  @DocsEditable @DomName('KeyboardEvent.keyLocation')
  final int keyLocation;

  @DocsEditable @DomName('KeyboardEvent.metaKey')
  final bool metaKey;

  @DocsEditable @DomName('KeyboardEvent.shiftKey')
  final bool shiftKey;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('HTMLKeygenElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental()
class KeygenElement extends Element native "*HTMLKeygenElement" {

  @DocsEditable
  factory KeygenElement() => document.$dom_createElement("keygen");

  /// Checks if this type is supported on the current platform.
  static bool get supported => Element.isTagSupported('keygen') && (new Element.tag('keygen') is KeygenElement);

  @DocsEditable @DomName('HTMLKeygenElement.autofocus')
  bool autofocus;

  @DocsEditable @DomName('HTMLKeygenElement.challenge')
  String challenge;

  @DocsEditable @DomName('HTMLKeygenElement.disabled')
  bool disabled;

  @DocsEditable @DomName('HTMLKeygenElement.form')
  final FormElement form;

  @DocsEditable @DomName('HTMLKeygenElement.keytype')
  String keytype;

  @DocsEditable @DomName('HTMLKeygenElement.labels')
  @Returns('NodeList') @Creates('NodeList')
  final List<Node> labels;

  @DocsEditable @DomName('HTMLKeygenElement.name')
  String name;

  @DocsEditable @DomName('HTMLKeygenElement.type')
  final String type;

  @DocsEditable @DomName('HTMLKeygenElement.validationMessage')
  final String validationMessage;

  @DocsEditable @DomName('HTMLKeygenElement.validity')
  final ValidityState validity;

  @DocsEditable @DomName('HTMLKeygenElement.willValidate')
  final bool willValidate;

  @DocsEditable @DomName('HTMLKeygenElement.checkValidity')
  bool checkValidity() native;

  @DocsEditable @DomName('HTMLKeygenElement.setCustomValidity')
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

  @DocsEditable @DomName('HTMLLIElement.type')
  String type;

  @DocsEditable @DomName('HTMLLIElement.value')
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

  @DocsEditable @DomName('HTMLLabelElement.control')
  final Element control;

  @DocsEditable @DomName('HTMLLabelElement.form')
  final FormElement form;

  @DocsEditable @DomName('HTMLLabelElement.htmlFor')
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

  @DocsEditable @DomName('HTMLLegendElement.form')
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

  @DocsEditable @DomName('HTMLLinkElement.disabled')
  bool disabled;

  @DocsEditable @DomName('HTMLLinkElement.href')
  String href;

  @DocsEditable @DomName('HTMLLinkElement.hreflang')
  String hreflang;

  @DocsEditable @DomName('HTMLLinkElement.media')
  String media;

  @DocsEditable @DomName('HTMLLinkElement.rel')
  String rel;

  @DocsEditable @DomName('HTMLLinkElement.sheet')
  final StyleSheet sheet;

  @DocsEditable @DomName('HTMLLinkElement.sizes')
  DomSettableTokenList sizes;

  @DocsEditable @DomName('HTMLLinkElement.type')
  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('LocalMediaStream')
class LocalMediaStream extends MediaStream implements EventTarget native "*LocalMediaStream" {

  @DocsEditable @DomName('LocalMediaStream.stop')
  void stop() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('Location')
class Location implements LocationBase native "*Location" {

  @DocsEditable @DomName('Location.ancestorOrigins')
  @Returns('DomStringList') @Creates('DomStringList')
  final List<String> ancestorOrigins;

  @DocsEditable @DomName('Location.hash')
  String hash;

  @DocsEditable @DomName('Location.host')
  String host;

  @DocsEditable @DomName('Location.hostname')
  String hostname;

  @DocsEditable @DomName('Location.href')
  String href;

  @DocsEditable @DomName('Location.origin')
  final String origin;

  @DocsEditable @DomName('Location.pathname')
  String pathname;

  @DocsEditable @DomName('Location.port')
  String port;

  @DocsEditable @DomName('Location.protocol')
  String protocol;

  @DocsEditable @DomName('Location.search')
  String search;

  @DocsEditable @DomName('Location.assign')
  void assign(String url) native;

  @DocsEditable @DomName('Location.reload')
  void reload() native;

  @DocsEditable @DomName('Location.replace')
  void replace(String url) native;

  @DocsEditable @DomName('Location.toString')
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

  @DocsEditable @DomName('HTMLMapElement.areas')
  final HtmlCollection areas;

  @DocsEditable @DomName('HTMLMapElement.name')
  String name;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('HTMLMarqueeElement')
class MarqueeElement extends Element native "*HTMLMarqueeElement" {

  /// Checks if this type is supported on the current platform.
  static bool get supported => Element.isTagSupported('marquee')&& (new Element.tag('marquee') is MarqueeElement);

  @DocsEditable @DomName('HTMLMarqueeElement.behavior')
  String behavior;

  @DocsEditable @DomName('HTMLMarqueeElement.bgColor')
  String bgColor;

  @DocsEditable @DomName('HTMLMarqueeElement.direction')
  String direction;

  @DocsEditable @DomName('HTMLMarqueeElement.height')
  String height;

  @DocsEditable @DomName('HTMLMarqueeElement.hspace')
  int hspace;

  @DocsEditable @DomName('HTMLMarqueeElement.loop')
  int loop;

  @DocsEditable @DomName('HTMLMarqueeElement.scrollAmount')
  int scrollAmount;

  @DocsEditable @DomName('HTMLMarqueeElement.scrollDelay')
  int scrollDelay;

  @DocsEditable @DomName('HTMLMarqueeElement.trueSpeed')
  bool trueSpeed;

  @DocsEditable @DomName('HTMLMarqueeElement.vspace')
  int vspace;

  @DocsEditable @DomName('HTMLMarqueeElement.width')
  String width;

  @DocsEditable @DomName('HTMLMarqueeElement.start')
  void start() native;

  @DocsEditable @DomName('HTMLMarqueeElement.stop')
  void stop() native;
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

  @DocsEditable @DomName('MediaController.buffered')
  final TimeRanges buffered;

  @DocsEditable @DomName('MediaController.currentTime')
  num currentTime;

  @DocsEditable @DomName('MediaController.defaultPlaybackRate')
  num defaultPlaybackRate;

  @DocsEditable @DomName('MediaController.duration')
  final num duration;

  @DocsEditable @DomName('MediaController.muted')
  bool muted;

  @DocsEditable @DomName('MediaController.paused')
  final bool paused;

  @DocsEditable @DomName('MediaController.playbackRate')
  num playbackRate;

  @DocsEditable @DomName('MediaController.playbackState')
  final String playbackState;

  @DocsEditable @DomName('MediaController.played')
  final TimeRanges played;

  @DocsEditable @DomName('MediaController.seekable')
  final TimeRanges seekable;

  @DocsEditable @DomName('MediaController.volume')
  num volume;

  @JSName('addEventListener')
  @DocsEditable @DomName('MediaController.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('MediaController.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  @DocsEditable @DomName('MediaController.pause')
  void pause() native;

  @DocsEditable @DomName('MediaController.play')
  void play() native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('MediaController.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('MediaController.unpause')
  void unpause() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('HTMLMediaElement')
class MediaElement extends Element native "*HTMLMediaElement" {

  static const EventStreamProvider<Event> canPlayEvent = const EventStreamProvider<Event>('canplay');

  static const EventStreamProvider<Event> canPlayThroughEvent = const EventStreamProvider<Event>('canplaythrough');

  static const EventStreamProvider<Event> durationChangeEvent = const EventStreamProvider<Event>('durationchange');

  static const EventStreamProvider<Event> emptiedEvent = const EventStreamProvider<Event>('emptied');

  static const EventStreamProvider<Event> endedEvent = const EventStreamProvider<Event>('ended');

  static const EventStreamProvider<Event> loadedDataEvent = const EventStreamProvider<Event>('loadeddata');

  static const EventStreamProvider<Event> loadedMetadataEvent = const EventStreamProvider<Event>('loadedmetadata');

  static const EventStreamProvider<Event> loadStartEvent = const EventStreamProvider<Event>('loadstart');

  static const EventStreamProvider<Event> pauseEvent = const EventStreamProvider<Event>('pause');

  static const EventStreamProvider<Event> playEvent = const EventStreamProvider<Event>('play');

  static const EventStreamProvider<Event> playingEvent = const EventStreamProvider<Event>('playing');

  static const EventStreamProvider<Event> progressEvent = const EventStreamProvider<Event>('progress');

  static const EventStreamProvider<Event> rateChangeEvent = const EventStreamProvider<Event>('ratechange');

  static const EventStreamProvider<Event> seekedEvent = const EventStreamProvider<Event>('seeked');

  static const EventStreamProvider<Event> seekingEvent = const EventStreamProvider<Event>('seeking');

  static const EventStreamProvider<Event> showEvent = const EventStreamProvider<Event>('show');

  static const EventStreamProvider<Event> stalledEvent = const EventStreamProvider<Event>('stalled');

  static const EventStreamProvider<Event> suspendEvent = const EventStreamProvider<Event>('suspend');

  static const EventStreamProvider<Event> timeUpdateEvent = const EventStreamProvider<Event>('timeupdate');

  static const EventStreamProvider<Event> volumeChangeEvent = const EventStreamProvider<Event>('volumechange');

  static const EventStreamProvider<Event> waitingEvent = const EventStreamProvider<Event>('waiting');

  static const EventStreamProvider<MediaKeyEvent> keyAddedEvent = const EventStreamProvider<MediaKeyEvent>('webkitkeyadded');

  static const EventStreamProvider<MediaKeyEvent> keyErrorEvent = const EventStreamProvider<MediaKeyEvent>('webkitkeyerror');

  static const EventStreamProvider<MediaKeyEvent> keyMessageEvent = const EventStreamProvider<MediaKeyEvent>('webkitkeymessage');

  static const EventStreamProvider<MediaKeyEvent> needKeyEvent = const EventStreamProvider<MediaKeyEvent>('webkitneedkey');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
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

  @DocsEditable @DomName('HTMLMediaElement.autoplay')
  bool autoplay;

  @DocsEditable @DomName('HTMLMediaElement.buffered')
  final TimeRanges buffered;

  @DocsEditable @DomName('HTMLMediaElement.controller')
  MediaController controller;

  @DocsEditable @DomName('HTMLMediaElement.controls')
  bool controls;

  @DocsEditable @DomName('HTMLMediaElement.currentSrc')
  final String currentSrc;

  @DocsEditable @DomName('HTMLMediaElement.currentTime')
  num currentTime;

  @DocsEditable @DomName('HTMLMediaElement.defaultMuted')
  bool defaultMuted;

  @DocsEditable @DomName('HTMLMediaElement.defaultPlaybackRate')
  num defaultPlaybackRate;

  @DocsEditable @DomName('HTMLMediaElement.duration')
  final num duration;

  @DocsEditable @DomName('HTMLMediaElement.ended')
  final bool ended;

  @DocsEditable @DomName('HTMLMediaElement.error')
  final MediaError error;

  @DocsEditable @DomName('HTMLMediaElement.initialTime')
  final num initialTime;

  @DocsEditable @DomName('HTMLMediaElement.loop')
  bool loop;

  @DocsEditable @DomName('HTMLMediaElement.mediaGroup')
  String mediaGroup;

  @DocsEditable @DomName('HTMLMediaElement.muted')
  bool muted;

  @DocsEditable @DomName('HTMLMediaElement.networkState')
  final int networkState;

  @DocsEditable @DomName('HTMLMediaElement.paused')
  final bool paused;

  @DocsEditable @DomName('HTMLMediaElement.playbackRate')
  num playbackRate;

  @DocsEditable @DomName('HTMLMediaElement.played')
  final TimeRanges played;

  @DocsEditable @DomName('HTMLMediaElement.preload')
  String preload;

  @DocsEditable @DomName('HTMLMediaElement.readyState')
  final int readyState;

  @DocsEditable @DomName('HTMLMediaElement.seekable')
  final TimeRanges seekable;

  @DocsEditable @DomName('HTMLMediaElement.seeking')
  final bool seeking;

  @DocsEditable @DomName('HTMLMediaElement.src')
  String src;

  @DocsEditable @DomName('HTMLMediaElement.startTime')
  final num startTime;

  @DocsEditable @DomName('HTMLMediaElement.textTracks')
  final TextTrackList textTracks;

  @DocsEditable @DomName('HTMLMediaElement.volume')
  num volume;

  @DocsEditable @DomName('HTMLMediaElement.webkitAudioDecodedByteCount')
  final int webkitAudioDecodedByteCount;

  @DocsEditable @DomName('HTMLMediaElement.webkitClosedCaptionsVisible')
  bool webkitClosedCaptionsVisible;

  @DocsEditable @DomName('HTMLMediaElement.webkitHasClosedCaptions')
  final bool webkitHasClosedCaptions;

  @DocsEditable @DomName('HTMLMediaElement.webkitPreservesPitch')
  bool webkitPreservesPitch;

  @DocsEditable @DomName('HTMLMediaElement.webkitVideoDecodedByteCount')
  final int webkitVideoDecodedByteCount;

  @DocsEditable @DomName('HTMLMediaElement.addTextTrack')
  TextTrack addTextTrack(String kind, [String label, String language]) native;

  @DocsEditable @DomName('HTMLMediaElement.canPlayType')
  String canPlayType(String type, String keySystem) native;

  @DocsEditable @DomName('HTMLMediaElement.load')
  void load() native;

  @DocsEditable @DomName('HTMLMediaElement.pause')
  void pause() native;

  @DocsEditable @DomName('HTMLMediaElement.play')
  void play() native;

  @DocsEditable @DomName('HTMLMediaElement.webkitAddKey')
  void webkitAddKey(String keySystem, Uint8Array key, [Uint8Array initData, String sessionId]) native;

  @DocsEditable @DomName('HTMLMediaElement.webkitCancelKeyRequest')
  void webkitCancelKeyRequest(String keySystem, String sessionId) native;

  @DocsEditable @DomName('HTMLMediaElement.webkitGenerateKeyRequest')
  void webkitGenerateKeyRequest(String keySystem, [Uint8Array initData]) native;

  Stream<Event> get onCanPlay => canPlayEvent.forTarget(this);

  Stream<Event> get onCanPlayThrough => canPlayThroughEvent.forTarget(this);

  Stream<Event> get onDurationChange => durationChangeEvent.forTarget(this);

  Stream<Event> get onEmptied => emptiedEvent.forTarget(this);

  Stream<Event> get onEnded => endedEvent.forTarget(this);

  Stream<Event> get onLoadedData => loadedDataEvent.forTarget(this);

  Stream<Event> get onLoadedMetadata => loadedMetadataEvent.forTarget(this);

  Stream<Event> get onLoadStart => loadStartEvent.forTarget(this);

  Stream<Event> get onPause => pauseEvent.forTarget(this);

  Stream<Event> get onPlay => playEvent.forTarget(this);

  Stream<Event> get onPlaying => playingEvent.forTarget(this);

  Stream<Event> get onProgress => progressEvent.forTarget(this);

  Stream<Event> get onRateChange => rateChangeEvent.forTarget(this);

  Stream<Event> get onSeeked => seekedEvent.forTarget(this);

  Stream<Event> get onSeeking => seekingEvent.forTarget(this);

  Stream<Event> get onShow => showEvent.forTarget(this);

  Stream<Event> get onStalled => stalledEvent.forTarget(this);

  Stream<Event> get onSuspend => suspendEvent.forTarget(this);

  Stream<Event> get onTimeUpdate => timeUpdateEvent.forTarget(this);

  Stream<Event> get onVolumeChange => volumeChangeEvent.forTarget(this);

  Stream<Event> get onWaiting => waitingEvent.forTarget(this);

  Stream<MediaKeyEvent> get onKeyAdded => keyAddedEvent.forTarget(this);

  Stream<MediaKeyEvent> get onKeyError => keyErrorEvent.forTarget(this);

  Stream<MediaKeyEvent> get onKeyMessage => keyMessageEvent.forTarget(this);

  Stream<MediaKeyEvent> get onNeedKey => needKeyEvent.forTarget(this);
}

@DocsEditable
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

  @DocsEditable @DomName('MediaError.code')
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

  @DocsEditable @DomName('MediaKeyError.code')
  final int code;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('MediaKeyEvent')
class MediaKeyEvent extends Event native "*MediaKeyEvent" {

  @JSName('defaultURL')
  @DocsEditable @DomName('MediaKeyEvent.defaultURL')
  final String defaultUrl;

  @DocsEditable @DomName('MediaKeyEvent.errorCode')
  final MediaKeyError errorCode;

  @DocsEditable @DomName('MediaKeyEvent.initData')
  final Uint8Array initData;

  @DocsEditable @DomName('MediaKeyEvent.keySystem')
  final String keySystem;

  @DocsEditable @DomName('MediaKeyEvent.message')
  final Uint8Array message;

  @DocsEditable @DomName('MediaKeyEvent.sessionId')
  final String sessionId;

  @DocsEditable @DomName('MediaKeyEvent.systemCode')
  final int systemCode;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('MediaList')
class MediaList native "*MediaList" {

  @DocsEditable @DomName('MediaList.length')
  final int length;

  @DocsEditable @DomName('MediaList.mediaText')
  String mediaText;

  @DocsEditable @DomName('MediaList.appendMedium')
  void appendMedium(String newMedium) native;

  @DocsEditable @DomName('MediaList.deleteMedium')
  void deleteMedium(String oldMedium) native;

  @DocsEditable @DomName('MediaList.item')
  String item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('MediaQueryList')
class MediaQueryList native "*MediaQueryList" {

  @DocsEditable @DomName('MediaQueryList.matches')
  final bool matches;

  @DocsEditable @DomName('MediaQueryList.media')
  final String media;

  @DocsEditable @DomName('MediaQueryList.addListener')
  void addListener(MediaQueryListListener listener) native;

  @DocsEditable @DomName('MediaQueryList.removeListener')
  void removeListener(MediaQueryListListener listener) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
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

  @DocsEditable @DomName('MediaSource.activeSourceBuffers')
  final SourceBufferList activeSourceBuffers;

  @DocsEditable @DomName('MediaSource.duration')
  num duration;

  @DocsEditable @DomName('MediaSource.readyState')
  final String readyState;

  @DocsEditable @DomName('MediaSource.sourceBuffers')
  final SourceBufferList sourceBuffers;

  @JSName('addEventListener')
  @DocsEditable @DomName('MediaSource.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('MediaSource.addSourceBuffer')
  SourceBuffer addSourceBuffer(String type) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('MediaSource.dispatchEvent')
  bool $dom_dispatchEvent(Event event) native;

  @DocsEditable @DomName('MediaSource.endOfStream')
  void endOfStream(String error) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('MediaSource.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('MediaSource.removeSourceBuffer')
  void removeSourceBuffer(SourceBuffer buffer) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('MediaStream')
class MediaStream extends EventTarget native "*MediaStream" {

  static const EventStreamProvider<Event> endedEvent = const EventStreamProvider<Event>('ended');

  @DocsEditable
  factory MediaStream(MediaStreamTrackList audioTracks, MediaStreamTrackList videoTracks) => MediaStream._create(audioTracks, videoTracks);
  static MediaStream _create(MediaStreamTrackList audioTracks, MediaStreamTrackList videoTracks) => JS('MediaStream', 'new MediaStream(#,#)', audioTracks, videoTracks);

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  MediaStreamEvents get on =>
    new MediaStreamEvents(this);

  static const int ENDED = 2;

  static const int LIVE = 1;

  @DocsEditable @DomName('MediaStream.audioTracks')
  final MediaStreamTrackList audioTracks;

  @DocsEditable @DomName('MediaStream.label')
  final String label;

  @DocsEditable @DomName('MediaStream.readyState')
  final int readyState;

  @DocsEditable @DomName('MediaStream.videoTracks')
  final MediaStreamTrackList videoTracks;

  @JSName('addEventListener')
  @DocsEditable @DomName('MediaStream.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('MediaStream.dispatchEvent')
  bool $dom_dispatchEvent(Event event) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('MediaStream.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  Stream<Event> get onEnded => endedEvent.forTarget(this);
}

@DocsEditable
class MediaStreamEvents extends Events {
  @DocsEditable
  MediaStreamEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get ended => this['ended'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('MediaStreamEvent')
class MediaStreamEvent extends Event native "*MediaStreamEvent" {

  @DocsEditable @DomName('MediaStreamEvent.stream')
  final MediaStream stream;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('MediaStreamTrack')
class MediaStreamTrack extends EventTarget native "*MediaStreamTrack" {

  static const EventStreamProvider<Event> endedEvent = const EventStreamProvider<Event>('ended');

  static const EventStreamProvider<Event> muteEvent = const EventStreamProvider<Event>('mute');

  static const EventStreamProvider<Event> unmuteEvent = const EventStreamProvider<Event>('unmute');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  MediaStreamTrackEvents get on =>
    new MediaStreamTrackEvents(this);

  static const int ENDED = 2;

  static const int LIVE = 0;

  static const int MUTED = 1;

  @DocsEditable @DomName('MediaStreamTrack.enabled')
  bool enabled;

  @DocsEditable @DomName('MediaStreamTrack.kind')
  final String kind;

  @DocsEditable @DomName('MediaStreamTrack.label')
  final String label;

  @DocsEditable @DomName('MediaStreamTrack.readyState')
  final int readyState;

  @JSName('addEventListener')
  @DocsEditable @DomName('MediaStreamTrack.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('MediaStreamTrack.dispatchEvent')
  bool $dom_dispatchEvent(Event event) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('MediaStreamTrack.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  Stream<Event> get onEnded => endedEvent.forTarget(this);

  Stream<Event> get onMute => muteEvent.forTarget(this);

  Stream<Event> get onUnmute => unmuteEvent.forTarget(this);
}

@DocsEditable
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

  @DocsEditable @DomName('MediaStreamTrackEvent.track')
  final MediaStreamTrack track;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('MediaStreamTrackList')
class MediaStreamTrackList extends EventTarget native "*MediaStreamTrackList" {

  static const EventStreamProvider<MediaStreamTrackEvent> addTrackEvent = const EventStreamProvider<MediaStreamTrackEvent>('addtrack');

  static const EventStreamProvider<MediaStreamTrackEvent> removeTrackEvent = const EventStreamProvider<MediaStreamTrackEvent>('removetrack');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  MediaStreamTrackListEvents get on =>
    new MediaStreamTrackListEvents(this);

  @DocsEditable @DomName('MediaStreamTrackList.length')
  final int length;

  @DocsEditable @DomName('MediaStreamTrackList.add')
  void add(MediaStreamTrack track) native;

  @JSName('addEventListener')
  @DocsEditable @DomName('MediaStreamTrackList.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('MediaStreamTrackList.dispatchEvent')
  bool $dom_dispatchEvent(Event event) native;

  @DocsEditable @DomName('MediaStreamTrackList.item')
  MediaStreamTrack item(int index) native;

  @DocsEditable @DomName('MediaStreamTrackList.remove')
  void remove(MediaStreamTrack track) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('MediaStreamTrackList.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  Stream<MediaStreamTrackEvent> get onAddTrack => addTrackEvent.forTarget(this);

  Stream<MediaStreamTrackEvent> get onRemoveTrack => removeTrackEvent.forTarget(this);
}

@DocsEditable
class MediaStreamTrackListEvents extends Events {
  @DocsEditable
  MediaStreamTrackListEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get addTrack => this['addtrack'];

  @DocsEditable
  EventListenerList get removeTrack => this['removetrack'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('MemoryInfo')
class MemoryInfo native "*MemoryInfo" {

  @DocsEditable @DomName('MemoryInfo.jsHeapSizeLimit')
  final int jsHeapSizeLimit;

  @DocsEditable @DomName('MemoryInfo.totalJSHeapSize')
  final int totalJSHeapSize;

  @DocsEditable @DomName('MemoryInfo.usedJSHeapSize')
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

  @DocsEditable @DomName('MessageChannel.port1')
  final MessagePort port1;

  @DocsEditable @DomName('MessageChannel.port2')
  final MessagePort port2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('MessageEvent')
class MessageEvent extends Event native "*MessageEvent" {

  dynamic get data => convertNativeToDart_SerializedScriptValue(this._data);
  @JSName('data')
  @DocsEditable @DomName('MessageEvent.data') @annotation_Creates_SerializedScriptValue @annotation_Returns_SerializedScriptValue
  final dynamic _data;

  @DocsEditable @DomName('MessageEvent.lastEventId')
  final String lastEventId;

  @DocsEditable @DomName('MessageEvent.origin')
  final String origin;

  @DocsEditable @DomName('MessageEvent.ports') @Creates('=List')
  final List ports;

  WindowBase get source => _convertNativeToDart_Window(this._source);
  @JSName('source')
  @DocsEditable @DomName('MessageEvent.source') @Creates('Window|=Object') @Returns('Window|=Object')
  final dynamic _source;

  @DocsEditable @DomName('MessageEvent.initMessageEvent')
  void initMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, Window sourceArg, List messagePorts) native;

  @DocsEditable @DomName('MessageEvent.webkitInitMessageEvent')
  void webkitInitMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, Window sourceArg, List transferables) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('MessagePort')
class MessagePort extends EventTarget native "*MessagePort" {

  static const EventStreamProvider<MessageEvent> messageEvent = const EventStreamProvider<MessageEvent>('message');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  MessagePortEvents get on =>
    new MessagePortEvents(this);

  @JSName('addEventListener')
  @DocsEditable @DomName('MessagePort.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('MessagePort.close')
  void close() native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('MessagePort.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

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
  @DocsEditable @DomName('MessagePort.postMessage')
  void _postMessage_1(message, List messagePorts) native;
  @JSName('postMessage')
  @DocsEditable @DomName('MessagePort.postMessage')
  void _postMessage_2(message) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('MessagePort.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('MessagePort.start')
  void start() native;

  Stream<MessageEvent> get onMessage => messageEvent.forTarget(this);
}

@DocsEditable
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

  @DocsEditable @DomName('HTMLMetaElement.content')
  String content;

  @DocsEditable @DomName('HTMLMetaElement.httpEquiv')
  String httpEquiv;

  @DocsEditable @DomName('HTMLMetaElement.name')
  String name;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('Metadata')
class Metadata native "*Metadata" {

  @DocsEditable @DomName('Metadata.modificationTime')
  final Date modificationTime;

  @DocsEditable @DomName('Metadata.size')
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

  @DocsEditable @DomName('HTMLMeterElement.high')
  num high;

  @DocsEditable @DomName('HTMLMeterElement.labels')
  @Returns('NodeList') @Creates('NodeList')
  final List<Node> labels;

  @DocsEditable @DomName('HTMLMeterElement.low')
  num low;

  @DocsEditable @DomName('HTMLMeterElement.max')
  num max;

  @DocsEditable @DomName('HTMLMeterElement.min')
  num min;

  @DocsEditable @DomName('HTMLMeterElement.optimum')
  num optimum;

  @DocsEditable @DomName('HTMLMeterElement.value')
  num value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('HTMLModElement')
class ModElement extends Element native "*HTMLModElement" {

  @DocsEditable @DomName('HTMLModElement.cite')
  String cite;

  @DocsEditable @DomName('HTMLModElement.dateTime')
  String dateTime;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MouseEvent')
class MouseEvent extends UIEvent native "*MouseEvent" {
  factory MouseEvent(String type, Window view, int detail, int screenX,
      int screenY, int clientX, int clientY, int button, [bool canBubble = true,
      bool cancelable = true, bool ctrlKey = false, bool altKey = false,
      bool shiftKey = false, bool metaKey = false,
      EventTarget relatedTarget = null]) =>
      _MouseEventFactoryProvider.createMouseEvent(
          type, view, detail, screenX, screenY,
          clientX, clientY, button, canBubble, cancelable,
          ctrlKey, altKey, shiftKey, metaKey,
          relatedTarget);

  @DocsEditable @DomName('MouseEvent.altKey')
  final bool altKey;

  @DocsEditable @DomName('MouseEvent.button')
  final int button;

  @DocsEditable @DomName('MouseEvent.clientX')
  final int clientX;

  @DocsEditable @DomName('MouseEvent.clientY')
  final int clientY;

  @DocsEditable @DomName('MouseEvent.ctrlKey')
  final bool ctrlKey;

  @DocsEditable @DomName('MouseEvent.dataTransfer')
  final Clipboard dataTransfer;

  @DocsEditable @DomName('MouseEvent.fromElement')
  final Node fromElement;

  @DocsEditable @DomName('MouseEvent.metaKey')
  final bool metaKey;

  EventTarget get relatedTarget => _convertNativeToDart_EventTarget(this._relatedTarget);
  @JSName('relatedTarget')
  @DocsEditable @DomName('MouseEvent.relatedTarget') @Creates('Node') @Returns('EventTarget|=Object')
  final dynamic _relatedTarget;

  @DocsEditable @DomName('MouseEvent.screenX')
  final int screenX;

  @DocsEditable @DomName('MouseEvent.screenY')
  final int screenY;

  @DocsEditable @DomName('MouseEvent.shiftKey')
  final bool shiftKey;

  @DocsEditable @DomName('MouseEvent.toElement')
  final Node toElement;

  @DocsEditable @DomName('MouseEvent.webkitMovementX')
  final int webkitMovementX;

  @DocsEditable @DomName('MouseEvent.webkitMovementY')
  final int webkitMovementY;

  @DocsEditable @DomName('MouseEvent.x')
  final int x;

  @DocsEditable @DomName('MouseEvent.y')
  final int y;

  void $dom_initMouseEvent(String type, bool canBubble, bool cancelable, Window view, int detail, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, int button, EventTarget relatedTarget) {
    var relatedTarget_1 = _convertDartToNative_EventTarget(relatedTarget);
    _$dom_initMouseEvent_1(type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget_1);
    return;
  }
  @JSName('initMouseEvent')
  @DocsEditable @DomName('MouseEvent.initMouseEvent')
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



@DocsEditable
@DomName('MutationEvent')
class MutationEvent extends Event native "*MutationEvent" {

  static const int ADDITION = 2;

  static const int MODIFICATION = 1;

  static const int REMOVAL = 3;

  @DocsEditable @DomName('MutationEvent.attrChange')
  final int attrChange;

  @DocsEditable @DomName('MutationEvent.attrName')
  final String attrName;

  @DocsEditable @DomName('MutationEvent.newValue')
  final String newValue;

  @DocsEditable @DomName('MutationEvent.prevValue')
  final String prevValue;

  @DocsEditable @DomName('MutationEvent.relatedNode')
  final Node relatedNode;

  @DocsEditable @DomName('MutationEvent.initMutationEvent')
  void initMutationEvent(String type, bool canBubble, bool cancelable, Node relatedNode, String prevValue, String newValue, String attrName, int attrChange) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MutationObserver')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental()
class MutationObserver native "*MutationObserver" {

  @DocsEditable
  factory MutationObserver(MutationCallback callback) => MutationObserver._create(callback);

  @DocsEditable @DomName('MutationObserver.disconnect')
  void disconnect() native;

  void _observe(Node target, Map options) {
    var options_1 = convertDartToNative_Dictionary(options);
    __observe_1(target, options_1);
    return;
  }
  @JSName('observe')
  @DocsEditable @DomName('MutationObserver.observe')
  void __observe_1(Node target, options) native;

  @DocsEditable @DomName('MutationObserver.takeRecords')
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

  @DocsEditable @DomName('MutationRecord.addedNodes')
  @Returns('NodeList') @Creates('NodeList')
  final List<Node> addedNodes;

  @DocsEditable @DomName('MutationRecord.attributeName')
  final String attributeName;

  @DocsEditable @DomName('MutationRecord.attributeNamespace')
  final String attributeNamespace;

  @DocsEditable @DomName('MutationRecord.nextSibling')
  final Node nextSibling;

  @DocsEditable @DomName('MutationRecord.oldValue')
  final String oldValue;

  @DocsEditable @DomName('MutationRecord.previousSibling')
  final Node previousSibling;

  @DocsEditable @DomName('MutationRecord.removedNodes')
  @Returns('NodeList') @Creates('NodeList')
  final List<Node> removedNodes;

  @DocsEditable @DomName('MutationRecord.target')
  final Node target;

  @DocsEditable @DomName('MutationRecord.type')
  final String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('NamedNodeMap')
class NamedNodeMap implements JavaScriptIndexingBehavior, List<Node> native "*NamedNodeMap" {

  @DocsEditable @DomName('NamedNodeMap.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(Node element) => Collections.contains(this, element);

  void forEach(void f(Node element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(Node element)) => new MappedList<Node, dynamic>(this, f);

  Iterable<Node> where(bool f(Node element)) => new WhereIterable<Node>(this, f);

  bool every(bool f(Node element)) => Collections.every(this, f);

  bool any(bool f(Node element)) => Collections.any(this, f);

  List<Node> toList() => new List<Node>.from(this);
  Set<Node> toSet() => new Set<Node>.from(this);

  bool get isEmpty => this.length == 0;

  List<Node> take(int n) => new ListView<Node>(this, 0, n);

  Iterable<Node> takeWhile(bool test(Node value)) {
    return new TakeWhileIterable<Node>(this, test);
  }

  List<Node> skip(int n) => new ListView<Node>(this, n, null);

  Iterable<Node> skipWhile(bool test(Node value)) {
    return new SkipWhileIterable<Node>(this, test);
  }

  Node firstMatching(bool test(Node value), { Node orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  Node lastMatching(bool test(Node value), {Node orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  Node singleMatching(bool test(Node value)) {
    return Collections.singleMatching(this, test);
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

  Node min([int compare(Node a, Node b)]) => Collections.min(this, compare);

  Node max([int compare(Node a, Node b)]) => Collections.max(this, compare);

  Node removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  Node removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('NamedNodeMap.getNamedItem')
  Node getNamedItem(String name) native;

  @DocsEditable @DomName('NamedNodeMap.getNamedItemNS')
  Node getNamedItemNS(String namespaceURI, String localName) native;

  @DocsEditable @DomName('NamedNodeMap.item')
  Node item(int index) native;

  @DocsEditable @DomName('NamedNodeMap.removeNamedItem')
  Node removeNamedItem(String name) native;

  @DocsEditable @DomName('NamedNodeMap.removeNamedItemNS')
  Node removeNamedItemNS(String namespaceURI, String localName) native;

  @DocsEditable @DomName('NamedNodeMap.setNamedItem')
  Node setNamedItem(Node node) native;

  @DocsEditable @DomName('NamedNodeMap.setNamedItemNS')
  Node setNamedItemNS(Node node) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Navigator')
class Navigator native "*Navigator" {

  @DocsEditable
  @DomName('Navigator.language')
  String get language => JS('String', '#.language || #.userLanguage', this,
      this);
  
  @DocsEditable @DomName('Navigator.appCodeName')
  final String appCodeName;

  @DocsEditable @DomName('Navigator.appName')
  final String appName;

  @DocsEditable @DomName('Navigator.appVersion')
  final String appVersion;

  @DocsEditable @DomName('Navigator.cookieEnabled')
  final bool cookieEnabled;

  @DocsEditable @DomName('Navigator.geolocation')
  final Geolocation geolocation;

  @DocsEditable @DomName('Navigator.mimeTypes')
  final DomMimeTypeArray mimeTypes;

  @DocsEditable @DomName('Navigator.onLine')
  final bool onLine;

  @DocsEditable @DomName('Navigator.platform')
  final String platform;

  @DocsEditable @DomName('Navigator.plugins')
  final DomPluginArray plugins;

  @DocsEditable @DomName('Navigator.product')
  final String product;

  @DocsEditable @DomName('Navigator.productSub')
  final String productSub;

  @DocsEditable @DomName('Navigator.userAgent')
  final String userAgent;

  @DocsEditable @DomName('Navigator.vendor')
  final String vendor;

  @DocsEditable @DomName('Navigator.vendorSub')
  final String vendorSub;

  @DocsEditable @DomName('Navigator.webkitBattery')
  final BatteryManager webkitBattery;

  @DocsEditable @DomName('Navigator.getStorageUpdates')
  void getStorageUpdates() native;

  @DocsEditable @DomName('Navigator.javaEnabled')
  bool javaEnabled() native;

  @DocsEditable @DomName('Navigator.webkitGetGamepads')
  @Returns('_GamepadList') @Creates('_GamepadList')
  List<Gamepad> webkitGetGamepads() native;

  void webkitGetUserMedia(Map options, NavigatorUserMediaSuccessCallback successCallback, [NavigatorUserMediaErrorCallback errorCallback]) {
    if (?errorCallback) {
      var options_1 = convertDartToNative_Dictionary(options);
      _webkitGetUserMedia_1(options_1, successCallback, errorCallback);
      return;
    }
    var options_2 = convertDartToNative_Dictionary(options);
    _webkitGetUserMedia_2(options_2, successCallback);
    return;
  }
  @JSName('webkitGetUserMedia')
  @DocsEditable @DomName('Navigator.webkitGetUserMedia')
  void _webkitGetUserMedia_1(options, NavigatorUserMediaSuccessCallback successCallback, NavigatorUserMediaErrorCallback errorCallback) native;
  @JSName('webkitGetUserMedia')
  @DocsEditable @DomName('Navigator.webkitGetUserMedia')
  void _webkitGetUserMedia_2(options, NavigatorUserMediaSuccessCallback successCallback) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('NavigatorUserMediaError')
class NavigatorUserMediaError native "*NavigatorUserMediaError" {

  static const int PERMISSION_DENIED = 1;

  @DocsEditable @DomName('NavigatorUserMediaError.code')
  final int code;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void NavigatorUserMediaErrorCallback(NavigatorUserMediaError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void NavigatorUserMediaSuccessCallback(LocalMediaStream stream);
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
    return Collections.min(this, compare);
  }

  Node max([int compare(Node a, Node b)]) {
    return Collections.max(this, compare);
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

  void clear() {
    _this.text = '';
  }

  void operator []=(int index, Node value) {
    _this.$dom_replaceChild(value, this[index]);
  }

  Iterator<Node> get iterator => _this.$dom_childNodes.iterator;

  // TODO(jacobr): We can implement these methods much more efficiently by
  // looking up the nodeList only once instead of once per iteration.
  bool contains(Node element) => Collections.contains(this, element);

  void forEach(void f(Node element)) => Collections.forEach(this, f);

  dynamic reduce(dynamic initialValue,
      dynamic combine(dynamic previousValue, Node element)) {
    return Collections.reduce(this, initialValue, combine);
  }

  String join([String separator]) {
    return Collections.joinList(this, separator);
  }

  List mappedBy(f(Node element)) =>
      new MappedList<Node, dynamic>(this, f);

  Iterable<Node> where(bool f(Node element)) =>
     new WhereIterable<Node>(this, f);

  bool every(bool f(Node element)) => Collections.every(this, f);

  bool any(bool f(Node element)) => Collections.any(this, f);

  List<Node> toList() => new List<Node>.from(this);
  Set<Node> toSet() => new Set<Node>.from(this);

  bool get isEmpty => this.length == 0;

  // From List<Node>:

  List<Node> take(int n) {
    return new ListView<Node>(this, 0, n);
  }

  Iterable<Node> takeWhile(bool test(Node value)) {
    return new TakeWhileIterable<Node>(this, test);
  }

  List<Node> skip(int n) {
    return new ListView<Node>(this, n, null);
  }

  Iterable<Node> skipWhile(bool test(Node value)) {
    return new SkipWhileIterable<Node>(this, test);
  }

  Node firstMatching(bool test(Node value), {Node orElse()}) {
    return Collections.firstMatching(this, test, orElse);
  }

  Node lastMatching(bool test(Node value), {Node orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  Node singleMatching(bool test(Node value)) {
    return Collections.singleMatching(this, test);
  }

  Node elementAt(int index) {
    return this[index];
  }

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

@DocsEditable
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
  @DocsEditable @DomName('Node.attributes')
  final NamedNodeMap $dom_attributes;

  @JSName('childNodes')
  @DocsEditable @DomName('Node.childNodes')
  @Returns('NodeList') @Creates('NodeList')
  final List<Node> $dom_childNodes;

  @JSName('firstChild')
  @DocsEditable @DomName('Node.firstChild')
  final Node $dom_firstChild;

  @JSName('lastChild')
  @DocsEditable @DomName('Node.lastChild')
  final Node $dom_lastChild;

  @JSName('localName')
  @DocsEditable @DomName('Node.localName')
  final String $dom_localName;

  @JSName('namespaceURI')
  @DocsEditable @DomName('Node.namespaceURI')
  final String $dom_namespaceUri;

  @JSName('nextSibling')
  @DocsEditable @DomName('Node.nextSibling')
  final Node nextNode;

  @DocsEditable @DomName('Node.nodeType')
  final int nodeType;

  @DocsEditable @DomName('Node.nodeValue')
  final String nodeValue;

  @JSName('ownerDocument')
  @DocsEditable @DomName('Node.ownerDocument')
  final Document document;

  @JSName('parentElement')
  @DocsEditable @DomName('Node.parentElement')
  final Element parent;

  @DocsEditable @DomName('Node.parentNode')
  final Node parentNode;

  @JSName('previousSibling')
  @DocsEditable @DomName('Node.previousSibling')
  final Node previousNode;

  @JSName('textContent')
  @DocsEditable @DomName('Node.textContent')
  String text;

  @JSName('addEventListener')
  @DocsEditable @DomName('Node.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('appendChild')
  @DocsEditable @DomName('Node.appendChild')
  Node $dom_appendChild(Node newChild) native;

  @JSName('cloneNode')
  @DocsEditable @DomName('Node.cloneNode')
  Node clone(bool deep) native;

  @DocsEditable @DomName('Node.contains')
  bool contains(Node other) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('Node.dispatchEvent')
  bool $dom_dispatchEvent(Event event) native;

  @DocsEditable @DomName('Node.hasChildNodes')
  bool hasChildNodes() native;

  @DocsEditable @DomName('Node.insertBefore')
  Node insertBefore(Node newChild, Node refChild) native;

  @JSName('removeChild')
  @DocsEditable @DomName('Node.removeChild')
  Node $dom_removeChild(Node oldChild) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('Node.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('replaceChild')
  @DocsEditable @DomName('Node.replaceChild')
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

  @DocsEditable @DomName('NodeFilter.acceptNode')
  int acceptNode(Node n) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('NodeIterator')
class NodeIterator native "*NodeIterator" {

  @DocsEditable @DomName('NodeIterator.expandEntityReferences')
  final bool expandEntityReferences;

  @DocsEditable @DomName('NodeIterator.filter')
  final NodeFilter filter;

  @DocsEditable @DomName('NodeIterator.pointerBeforeReferenceNode')
  final bool pointerBeforeReferenceNode;

  @DocsEditable @DomName('NodeIterator.referenceNode')
  final Node referenceNode;

  @DocsEditable @DomName('NodeIterator.root')
  final Node root;

  @DocsEditable @DomName('NodeIterator.whatToShow')
  final int whatToShow;

  @DocsEditable @DomName('NodeIterator.detach')
  void detach() native;

  @DocsEditable @DomName('NodeIterator.nextNode')
  Node nextNode() native;

  @DocsEditable @DomName('NodeIterator.previousNode')
  Node previousNode() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('NodeList')
class NodeList implements JavaScriptIndexingBehavior, List<Node> native "*NodeList" {

  @DocsEditable @DomName('NodeList.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(Node element) => Collections.contains(this, element);

  void forEach(void f(Node element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(Node element)) => new MappedList<Node, dynamic>(this, f);

  Iterable<Node> where(bool f(Node element)) => new WhereIterable<Node>(this, f);

  bool every(bool f(Node element)) => Collections.every(this, f);

  bool any(bool f(Node element)) => Collections.any(this, f);

  List<Node> toList() => new List<Node>.from(this);
  Set<Node> toSet() => new Set<Node>.from(this);

  bool get isEmpty => this.length == 0;

  List<Node> take(int n) => new ListView<Node>(this, 0, n);

  Iterable<Node> takeWhile(bool test(Node value)) {
    return new TakeWhileIterable<Node>(this, test);
  }

  List<Node> skip(int n) => new ListView<Node>(this, n, null);

  Iterable<Node> skipWhile(bool test(Node value)) {
    return new SkipWhileIterable<Node>(this, test);
  }

  Node firstMatching(bool test(Node value), { Node orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  Node lastMatching(bool test(Node value), {Node orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  Node singleMatching(bool test(Node value)) {
    return Collections.singleMatching(this, test);
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

  Node min([int compare(Node a, Node b)]) => Collections.min(this, compare);

  Node max([int compare(Node a, Node b)]) => Collections.max(this, compare);

  Node removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  Node removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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
  @DocsEditable @DomName('NodeList.item')
  Node _item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('Notation')
class Notation extends Node native "*Notation" {

  @DocsEditable @DomName('Notation.publicId')
  final String publicId;

  @DocsEditable @DomName('Notation.systemId')
  final String systemId;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('Notification')
class Notification extends EventTarget native "*Notification" {

  static const EventStreamProvider<Event> clickEvent = const EventStreamProvider<Event>('click');

  static const EventStreamProvider<Event> closeEvent = const EventStreamProvider<Event>('close');

  static const EventStreamProvider<Event> displayEvent = const EventStreamProvider<Event>('display');

  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

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
  NotificationEvents get on =>
    new NotificationEvents(this);

  @DocsEditable @DomName('Notification.dir')
  String dir;

  @DocsEditable @DomName('Notification.permission')
  final String permission;

  @DocsEditable @DomName('Notification.replaceId')
  String replaceId;

  @DocsEditable @DomName('Notification.tag')
  String tag;

  @JSName('addEventListener')
  @DocsEditable @DomName('Notification.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('Notification.cancel')
  void cancel() native;

  @DocsEditable @DomName('Notification.close')
  void close() native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('Notification.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('Notification.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('Notification.requestPermission')
  static void requestPermission(NotificationPermissionCallback callback) native;

  @DocsEditable @DomName('Notification.show')
  void show() native;

  Stream<Event> get onClick => clickEvent.forTarget(this);

  Stream<Event> get onClose => closeEvent.forTarget(this);

  Stream<Event> get onDisplay => displayEvent.forTarget(this);

  Stream<Event> get onError => errorEvent.forTarget(this);

  Stream<Event> get onShow => showEvent.forTarget(this);
}

@DocsEditable
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
@Experimental()
class NotificationCenter native "*NotificationCenter" {

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.webkitNotifications)');

  @DocsEditable @DomName('NotificationCenter.checkPermission')
  int checkPermission() native;

  @JSName('createHTMLNotification')
  @DocsEditable @DomName('NotificationCenter.createHTMLNotification')
  Notification createHtmlNotification(String url) native;

  @DocsEditable @DomName('NotificationCenter.createNotification')
  Notification createNotification(String iconUrl, String title, String body) native;

  @DocsEditable @DomName('NotificationCenter.requestPermission')
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

  @DocsEditable @DomName('HTMLOListElement.reversed')
  bool reversed;

  @DocsEditable @DomName('HTMLOListElement.start')
  int start;

  @DocsEditable @DomName('HTMLOListElement.type')
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

  @DocsEditable @DomName('HTMLObjectElement.code')
  String code;

  @DocsEditable @DomName('HTMLObjectElement.data')
  String data;

  @DocsEditable @DomName('HTMLObjectElement.form')
  final FormElement form;

  @DocsEditable @DomName('HTMLObjectElement.height')
  String height;

  @DocsEditable @DomName('HTMLObjectElement.name')
  String name;

  @DocsEditable @DomName('HTMLObjectElement.type')
  String type;

  @DocsEditable @DomName('HTMLObjectElement.useMap')
  String useMap;

  @DocsEditable @DomName('HTMLObjectElement.validationMessage')
  final String validationMessage;

  @DocsEditable @DomName('HTMLObjectElement.validity')
  final ValidityState validity;

  @DocsEditable @DomName('HTMLObjectElement.width')
  String width;

  @DocsEditable @DomName('HTMLObjectElement.willValidate')
  final bool willValidate;

  @DocsEditable @DomName('HTMLObjectElement.checkValidity')
  bool checkValidity() native;

  @DocsEditable @DomName('HTMLObjectElement.setCustomValidity')
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
  @DocsEditable @DomName('OESVertexArrayObject.bindVertexArrayOES')
  void bindVertexArray(WebGLVertexArrayObject arrayObject) native;

  @JSName('createVertexArrayOES')
  @DocsEditable @DomName('OESVertexArrayObject.createVertexArrayOES')
  WebGLVertexArrayObject createVertexArray() native;

  @JSName('deleteVertexArrayOES')
  @DocsEditable @DomName('OESVertexArrayObject.deleteVertexArrayOES')
  void deleteVertexArray(WebGLVertexArrayObject arrayObject) native;

  @JSName('isVertexArrayOES')
  @DocsEditable @DomName('OESVertexArrayObject.isVertexArrayOES')
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

  @DocsEditable @DomName('HTMLOptGroupElement.disabled')
  bool disabled;

  @DocsEditable @DomName('HTMLOptGroupElement.label')
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

  @DocsEditable @DomName('HTMLOptionElement.defaultSelected')
  bool defaultSelected;

  @DocsEditable @DomName('HTMLOptionElement.disabled')
  bool disabled;

  @DocsEditable @DomName('HTMLOptionElement.form')
  final FormElement form;

  @DocsEditable @DomName('HTMLOptionElement.index')
  final int index;

  @DocsEditable @DomName('HTMLOptionElement.label')
  String label;

  @DocsEditable @DomName('HTMLOptionElement.selected')
  bool selected;

  @DocsEditable @DomName('HTMLOptionElement.value')
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

  @DocsEditable @DomName('HTMLOutputElement.defaultValue')
  String defaultValue;

  @DocsEditable @DomName('HTMLOutputElement.form')
  final FormElement form;

  @DocsEditable @DomName('HTMLOutputElement.htmlFor')
  DomSettableTokenList htmlFor;

  @DocsEditable @DomName('HTMLOutputElement.labels')
  @Returns('NodeList') @Creates('NodeList')
  final List<Node> labels;

  @DocsEditable @DomName('HTMLOutputElement.name')
  String name;

  @DocsEditable @DomName('HTMLOutputElement.type')
  final String type;

  @DocsEditable @DomName('HTMLOutputElement.validationMessage')
  final String validationMessage;

  @DocsEditable @DomName('HTMLOutputElement.validity')
  final ValidityState validity;

  @DocsEditable @DomName('HTMLOutputElement.value')
  String value;

  @DocsEditable @DomName('HTMLOutputElement.willValidate')
  final bool willValidate;

  @DocsEditable @DomName('HTMLOutputElement.checkValidity')
  bool checkValidity() native;

  @DocsEditable @DomName('HTMLOutputElement.setCustomValidity')
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

  @DocsEditable @DomName('OverflowEvent.horizontalOverflow')
  final bool horizontalOverflow;

  @DocsEditable @DomName('OverflowEvent.orient')
  final int orient;

  @DocsEditable @DomName('OverflowEvent.verticalOverflow')
  final bool verticalOverflow;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('PagePopupController')
class PagePopupController native "*PagePopupController" {

  @DocsEditable @DomName('PagePopupController.formatMonth')
  String formatMonth(int year, int zeroBaseMonth) native;

  @DocsEditable @DomName('PagePopupController.histogramEnumeration')
  void histogramEnumeration(String name, int sample, int boundaryValue) native;

  @DocsEditable @DomName('PagePopupController.localizeNumberString')
  String localizeNumberString(String numberString) native;

  @DocsEditable @DomName('PagePopupController.setValueAndClosePopup')
  void setValueAndClosePopup(int numberValue, String stringValue) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('PageTransitionEvent')
class PageTransitionEvent extends Event native "*PageTransitionEvent" {

  @DocsEditable @DomName('PageTransitionEvent.persisted')
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

  @DocsEditable @DomName('HTMLParamElement.name')
  String name;

  @DocsEditable @DomName('HTMLParamElement.value')
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

  @DocsEditable @DomName('Performance.memory')
  final MemoryInfo memory;

  @DocsEditable @DomName('Performance.navigation')
  final PerformanceNavigation navigation;

  @DocsEditable @DomName('Performance.timing')
  final PerformanceTiming timing;

  @DocsEditable @DomName('Performance.now')
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

  @DocsEditable @DomName('PerformanceNavigation.redirectCount')
  final int redirectCount;

  @DocsEditable @DomName('PerformanceNavigation.type')
  final int type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('PerformanceTiming')
class PerformanceTiming native "*PerformanceTiming" {

  @DocsEditable @DomName('PerformanceTiming.connectEnd')
  final int connectEnd;

  @DocsEditable @DomName('PerformanceTiming.connectStart')
  final int connectStart;

  @DocsEditable @DomName('PerformanceTiming.domComplete')
  final int domComplete;

  @DocsEditable @DomName('PerformanceTiming.domContentLoadedEventEnd')
  final int domContentLoadedEventEnd;

  @DocsEditable @DomName('PerformanceTiming.domContentLoadedEventStart')
  final int domContentLoadedEventStart;

  @DocsEditable @DomName('PerformanceTiming.domInteractive')
  final int domInteractive;

  @DocsEditable @DomName('PerformanceTiming.domLoading')
  final int domLoading;

  @DocsEditable @DomName('PerformanceTiming.domainLookupEnd')
  final int domainLookupEnd;

  @DocsEditable @DomName('PerformanceTiming.domainLookupStart')
  final int domainLookupStart;

  @DocsEditable @DomName('PerformanceTiming.fetchStart')
  final int fetchStart;

  @DocsEditable @DomName('PerformanceTiming.loadEventEnd')
  final int loadEventEnd;

  @DocsEditable @DomName('PerformanceTiming.loadEventStart')
  final int loadEventStart;

  @DocsEditable @DomName('PerformanceTiming.navigationStart')
  final int navigationStart;

  @DocsEditable @DomName('PerformanceTiming.redirectEnd')
  final int redirectEnd;

  @DocsEditable @DomName('PerformanceTiming.redirectStart')
  final int redirectStart;

  @DocsEditable @DomName('PerformanceTiming.requestStart')
  final int requestStart;

  @DocsEditable @DomName('PerformanceTiming.responseEnd')
  final int responseEnd;

  @DocsEditable @DomName('PerformanceTiming.responseStart')
  final int responseStart;

  @DocsEditable @DomName('PerformanceTiming.secureConnectionStart')
  final int secureConnectionStart;

  @DocsEditable @DomName('PerformanceTiming.unloadEventEnd')
  final int unloadEventEnd;

  @DocsEditable @DomName('PerformanceTiming.unloadEventStart')
  final int unloadEventStart;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('WebKitPoint')
class Point native "*WebKitPoint" {

  @DocsEditable
  factory Point(num x, num y) => Point._create(x, y);
  static Point _create(num x, num y) => JS('Point', 'new WebKitPoint(#,#)', x, y);

  @DocsEditable @DomName('WebKitPoint.x')
  num x;

  @DocsEditable @DomName('WebKitPoint.y')
  num y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('PopStateEvent')
class PopStateEvent extends Event native "*PopStateEvent" {

  dynamic get state => convertNativeToDart_SerializedScriptValue(this._state);
  @JSName('state')
  @DocsEditable @DomName('PopStateEvent.state') @annotation_Creates_SerializedScriptValue @annotation_Returns_SerializedScriptValue
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

  @DocsEditable @DomName('PositionError.code')
  final int code;

  @DocsEditable @DomName('PositionError.message')
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

  @DocsEditable @DomName('HTMLPreElement.wrap')
  bool wrap;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('ProcessingInstruction')
class ProcessingInstruction extends Node native "*ProcessingInstruction" {

  @DocsEditable @DomName('ProcessingInstruction.data')
  String data;

  @DocsEditable @DomName('ProcessingInstruction.sheet')
  final StyleSheet sheet;

  @DocsEditable @DomName('ProcessingInstruction.target')
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

  @DocsEditable @DomName('HTMLProgressElement.labels')
  @Returns('NodeList') @Creates('NodeList')
  final List<Node> labels;

  @DocsEditable @DomName('HTMLProgressElement.max')
  num max;

  @DocsEditable @DomName('HTMLProgressElement.position')
  final num position;

  @DocsEditable @DomName('HTMLProgressElement.value')
  num value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('ProgressEvent')
class ProgressEvent extends Event native "*ProgressEvent" {

  @DocsEditable @DomName('ProgressEvent.lengthComputable')
  final bool lengthComputable;

  @DocsEditable @DomName('ProgressEvent.loaded')
  final int loaded;

  @DocsEditable @DomName('ProgressEvent.total')
  final int total;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('HTMLQuoteElement')
class QuoteElement extends Element native "*HTMLQuoteElement" {

  @DocsEditable @DomName('HTMLQuoteElement.cite')
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

  @DocsEditable @DomName('RadioNodeList.value')
  String value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
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

  @DocsEditable @DomName('Range.collapsed')
  final bool collapsed;

  @DocsEditable @DomName('Range.commonAncestorContainer')
  final Node commonAncestorContainer;

  @DocsEditable @DomName('Range.endContainer')
  final Node endContainer;

  @DocsEditable @DomName('Range.endOffset')
  final int endOffset;

  @DocsEditable @DomName('Range.startContainer')
  final Node startContainer;

  @DocsEditable @DomName('Range.startOffset')
  final int startOffset;

  @DocsEditable @DomName('Range.cloneContents')
  DocumentFragment cloneContents() native;

  @DocsEditable @DomName('Range.cloneRange')
  Range cloneRange() native;

  @DocsEditable @DomName('Range.collapse')
  void collapse(bool toStart) native;

  @DocsEditable @DomName('Range.compareNode')
  int compareNode(Node refNode) native;

  @DocsEditable @DomName('Range.comparePoint')
  int comparePoint(Node refNode, int offset) native;

  @DocsEditable @DomName('Range.createContextualFragment')
  DocumentFragment createContextualFragment(String html) native;

  @DocsEditable @DomName('Range.deleteContents')
  void deleteContents() native;

  @DocsEditable @DomName('Range.detach')
  void detach() native;

  @DocsEditable @DomName('Range.expand')
  void expand(String unit) native;

  @DocsEditable @DomName('Range.extractContents')
  DocumentFragment extractContents() native;

  @DocsEditable @DomName('Range.getBoundingClientRect')
  ClientRect getBoundingClientRect() native;

  @DocsEditable @DomName('Range.getClientRects')
  @Returns('_ClientRectList') @Creates('_ClientRectList')
  List<ClientRect> getClientRects() native;

  @DocsEditable @DomName('Range.insertNode')
  void insertNode(Node newNode) native;

  @DocsEditable @DomName('Range.intersectsNode')
  bool intersectsNode(Node refNode) native;

  @DocsEditable @DomName('Range.isPointInRange')
  bool isPointInRange(Node refNode, int offset) native;

  @DocsEditable @DomName('Range.selectNode')
  void selectNode(Node refNode) native;

  @DocsEditable @DomName('Range.selectNodeContents')
  void selectNodeContents(Node refNode) native;

  @DocsEditable @DomName('Range.setEnd')
  void setEnd(Node refNode, int offset) native;

  @DocsEditable @DomName('Range.setEndAfter')
  void setEndAfter(Node refNode) native;

  @DocsEditable @DomName('Range.setEndBefore')
  void setEndBefore(Node refNode) native;

  @DocsEditable @DomName('Range.setStart')
  void setStart(Node refNode, int offset) native;

  @DocsEditable @DomName('Range.setStartAfter')
  void setStartAfter(Node refNode) native;

  @DocsEditable @DomName('Range.setStartBefore')
  void setStartBefore(Node refNode) native;

  @DocsEditable @DomName('Range.surroundContents')
  void surroundContents(Node newParent) native;

  @DocsEditable @DomName('Range.toString')
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

  @DocsEditable @DomName('RangeException.code')
  final int code;

  @DocsEditable @DomName('RangeException.message')
  final String message;

  @DocsEditable @DomName('RangeException.name')
  final String name;

  @DocsEditable @DomName('RangeException.toString')
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('Rect')
class Rect native "*Rect" {

  @DocsEditable @DomName('Rect.bottom')
  final CssPrimitiveValue bottom;

  @DocsEditable @DomName('Rect.left')
  final CssPrimitiveValue left;

  @DocsEditable @DomName('Rect.right')
  final CssPrimitiveValue right;

  @DocsEditable @DomName('Rect.top')
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

  @DocsEditable @DomName('RGBColor.blue')
  final CssPrimitiveValue blue;

  @DocsEditable @DomName('RGBColor.green')
  final CssPrimitiveValue green;

  @DocsEditable @DomName('RGBColor.red')
  final CssPrimitiveValue red;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('RTCDataChannel')
class RtcDataChannel extends EventTarget native "*RTCDataChannel" {

  static const EventStreamProvider<Event> closeEvent = const EventStreamProvider<Event>('close');

  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  static const EventStreamProvider<MessageEvent> messageEvent = const EventStreamProvider<MessageEvent>('message');

  static const EventStreamProvider<Event> openEvent = const EventStreamProvider<Event>('open');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  RtcDataChannelEvents get on =>
    new RtcDataChannelEvents(this);

  @DocsEditable @DomName('RTCDataChannel.binaryType')
  String binaryType;

  @DocsEditable @DomName('RTCDataChannel.bufferedAmount')
  final int bufferedAmount;

  @DocsEditable @DomName('RTCDataChannel.label')
  final String label;

  @DocsEditable @DomName('RTCDataChannel.readyState')
  final String readyState;

  @DocsEditable @DomName('RTCDataChannel.reliable')
  final bool reliable;

  @JSName('addEventListener')
  @DocsEditable @DomName('RTCDataChannel.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('RTCDataChannel.close')
  void close() native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('RTCDataChannel.dispatchEvent')
  bool $dom_dispatchEvent(Event event) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('RTCDataChannel.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('RTCDataChannel.send')
  void send(data) native;

  Stream<Event> get onClose => closeEvent.forTarget(this);

  Stream<Event> get onError => errorEvent.forTarget(this);

  Stream<MessageEvent> get onMessage => messageEvent.forTarget(this);

  Stream<Event> get onOpen => openEvent.forTarget(this);
}

@DocsEditable
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

  @DocsEditable @DomName('RTCDataChannelEvent.channel')
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

  @DocsEditable @DomName('RTCIceCandidate.candidate')
  final String candidate;

  @DocsEditable @DomName('RTCIceCandidate.sdpMLineIndex')
  final int sdpMLineIndex;

  @DocsEditable @DomName('RTCIceCandidate.sdpMid')
  final String sdpMid;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('RTCIceCandidateEvent')
class RtcIceCandidateEvent extends Event native "*RTCIceCandidateEvent" {

  @DocsEditable @DomName('RTCIceCandidateEvent.candidate')
  final RtcIceCandidate candidate;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('RTCPeerConnection')
class RtcPeerConnection extends EventTarget native "*RTCPeerConnection" {

  static const EventStreamProvider<MediaStreamEvent> addStreamEvent = const EventStreamProvider<MediaStreamEvent>('addstream');

  static const EventStreamProvider<RtcDataChannelEvent> dataChannelEvent = const EventStreamProvider<RtcDataChannelEvent>('datachannel');

  static const EventStreamProvider<RtcIceCandidateEvent> iceCandidateEvent = const EventStreamProvider<RtcIceCandidateEvent>('icecandidate');

  static const EventStreamProvider<Event> iceChangeEvent = const EventStreamProvider<Event>('icechange');

  static const EventStreamProvider<Event> negotiationNeededEvent = const EventStreamProvider<Event>('negotiationneeded');

  static const EventStreamProvider<Event> openEvent = const EventStreamProvider<Event>('open');

  static const EventStreamProvider<MediaStreamEvent> removeStreamEvent = const EventStreamProvider<MediaStreamEvent>('removestream');

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
  RtcPeerConnectionEvents get on =>
    new RtcPeerConnectionEvents(this);

  @DocsEditable @DomName('RTCPeerConnection.iceGatheringState')
  final String iceGatheringState;

  @DocsEditable @DomName('RTCPeerConnection.iceState')
  final String iceState;

  @DocsEditable @DomName('RTCPeerConnection.localDescription')
  final RtcSessionDescription localDescription;

  @DocsEditable @DomName('RTCPeerConnection.localStreams')
  @Returns('_MediaStreamList') @Creates('_MediaStreamList')
  final List<MediaStream> localStreams;

  @DocsEditable @DomName('RTCPeerConnection.readyState')
  final String readyState;

  @DocsEditable @DomName('RTCPeerConnection.remoteDescription')
  final RtcSessionDescription remoteDescription;

  @DocsEditable @DomName('RTCPeerConnection.remoteStreams')
  @Returns('_MediaStreamList') @Creates('_MediaStreamList')
  final List<MediaStream> remoteStreams;

  @JSName('addEventListener')
  @DocsEditable @DomName('RTCPeerConnection.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('RTCPeerConnection.addIceCandidate')
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
  @DocsEditable @DomName('RTCPeerConnection.addStream')
  void _addStream_1(MediaStream stream, mediaConstraints) native;
  @JSName('addStream')
  @DocsEditable @DomName('RTCPeerConnection.addStream')
  void _addStream_2(MediaStream stream) native;

  @DocsEditable @DomName('RTCPeerConnection.close')
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
  @DocsEditable @DomName('RTCPeerConnection.createAnswer')
  void _createAnswer_1(RtcSessionDescriptionCallback successCallback, RtcErrorCallback failureCallback, mediaConstraints) native;
  @JSName('createAnswer')
  @DocsEditable @DomName('RTCPeerConnection.createAnswer')
  void _createAnswer_2(RtcSessionDescriptionCallback successCallback, RtcErrorCallback failureCallback) native;

  RtcDataChannel createDataChannel(String label, [Map options]) {
    if (?options) {
      var options_1 = convertDartToNative_Dictionary(options);
      return _createDataChannel_1(label, options_1);
    }
    return _createDataChannel_2(label);
  }
  @JSName('createDataChannel')
  @DocsEditable @DomName('RTCPeerConnection.createDataChannel')
  RtcDataChannel _createDataChannel_1(label, options) native;
  @JSName('createDataChannel')
  @DocsEditable @DomName('RTCPeerConnection.createDataChannel')
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
  @DocsEditable @DomName('RTCPeerConnection.createOffer')
  void _createOffer_1(RtcSessionDescriptionCallback successCallback, RtcErrorCallback failureCallback, mediaConstraints) native;
  @JSName('createOffer')
  @DocsEditable @DomName('RTCPeerConnection.createOffer')
  void _createOffer_2(RtcSessionDescriptionCallback successCallback, RtcErrorCallback failureCallback) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('RTCPeerConnection.dispatchEvent')
  bool $dom_dispatchEvent(Event event) native;

  @DocsEditable @DomName('RTCPeerConnection.getStats')
  void getStats(RtcStatsCallback successCallback, MediaStreamTrack selector) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('RTCPeerConnection.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('RTCPeerConnection.removeStream')
  void removeStream(MediaStream stream) native;

  @DocsEditable @DomName('RTCPeerConnection.setLocalDescription')
  void setLocalDescription(RtcSessionDescription description, [VoidCallback successCallback, RtcErrorCallback failureCallback]) native;

  @DocsEditable @DomName('RTCPeerConnection.setRemoteDescription')
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
  @DocsEditable @DomName('RTCPeerConnection.updateIce')
  void _updateIce_1(configuration, mediaConstraints) native;
  @JSName('updateIce')
  @DocsEditable @DomName('RTCPeerConnection.updateIce')
  void _updateIce_2(configuration) native;
  @JSName('updateIce')
  @DocsEditable @DomName('RTCPeerConnection.updateIce')
  void _updateIce_3() native;

  Stream<MediaStreamEvent> get onAddStream => addStreamEvent.forTarget(this);

  Stream<RtcDataChannelEvent> get onDataChannel => dataChannelEvent.forTarget(this);

  Stream<RtcIceCandidateEvent> get onIceCandidate => iceCandidateEvent.forTarget(this);

  Stream<Event> get onIceChange => iceChangeEvent.forTarget(this);

  Stream<Event> get onNegotiationNeeded => negotiationNeededEvent.forTarget(this);

  Stream<Event> get onOpen => openEvent.forTarget(this);

  Stream<MediaStreamEvent> get onRemoveStream => removeStreamEvent.forTarget(this);

  Stream<Event> get onStateChange => stateChangeEvent.forTarget(this);
}

@DocsEditable
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

  @DocsEditable @DomName('RTCSessionDescription.sdp')
  String sdp;

  @DocsEditable @DomName('RTCSessionDescription.type')
  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('RTCStatsElement')
class RtcStatsElement native "*RTCStatsElement" {

  @DocsEditable @DomName('RTCStatsElement.timestamp')
  final Date timestamp;

  @DocsEditable @DomName('RTCStatsElement.names')
  List<String> names() native;

  @DocsEditable @DomName('RTCStatsElement.stat')
  String stat(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('RTCStatsReport')
class RtcStatsReport native "*RTCStatsReport" {

  @DocsEditable @DomName('RTCStatsReport.local')
  final RtcStatsElement local;

  @DocsEditable @DomName('RTCStatsReport.remote')
  final RtcStatsElement remote;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('RTCStatsResponse')
class RtcStatsResponse native "*RTCStatsResponse" {

  @DocsEditable @DomName('RTCStatsResponse.result')
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

  @DocsEditable @DomName('Screen.availHeight')
  final int availHeight;

  @DocsEditable @DomName('Screen.availLeft')
  final int availLeft;

  @DocsEditable @DomName('Screen.availTop')
  final int availTop;

  @DocsEditable @DomName('Screen.availWidth')
  final int availWidth;

  @DocsEditable @DomName('Screen.colorDepth')
  final int colorDepth;

  @DocsEditable @DomName('Screen.height')
  final int height;

  @DocsEditable @DomName('Screen.pixelDepth')
  final int pixelDepth;

  @DocsEditable @DomName('Screen.width')
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

  @DocsEditable @DomName('HTMLScriptElement.async')
  bool async;

  @DocsEditable @DomName('HTMLScriptElement.charset')
  String charset;

  @DocsEditable @DomName('HTMLScriptElement.crossOrigin')
  String crossOrigin;

  @DocsEditable @DomName('HTMLScriptElement.defer')
  bool defer;

  @DocsEditable @DomName('HTMLScriptElement.event')
  String event;

  @DocsEditable @DomName('HTMLScriptElement.htmlFor')
  String htmlFor;

  @DocsEditable @DomName('HTMLScriptElement.src')
  String src;

  @DocsEditable @DomName('HTMLScriptElement.type')
  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('ScriptProfile')
class ScriptProfile native "*ScriptProfile" {

  @DocsEditable @DomName('ScriptProfile.head')
  final ScriptProfileNode head;

  @DocsEditable @DomName('ScriptProfile.title')
  final String title;

  @DocsEditable @DomName('ScriptProfile.uid')
  final int uid;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('ScriptProfileNode')
class ScriptProfileNode native "*ScriptProfileNode" {

  @JSName('callUID')
  @DocsEditable @DomName('ScriptProfileNode.callUID')
  final int callUid;

  @DocsEditable @DomName('ScriptProfileNode.functionName')
  final String functionName;

  @DocsEditable @DomName('ScriptProfileNode.lineNumber')
  final int lineNumber;

  @DocsEditable @DomName('ScriptProfileNode.numberOfCalls')
  final int numberOfCalls;

  @DocsEditable @DomName('ScriptProfileNode.selfTime')
  final num selfTime;

  @DocsEditable @DomName('ScriptProfileNode.totalTime')
  final num totalTime;

  @DocsEditable @DomName('ScriptProfileNode.url')
  final String url;

  @DocsEditable @DomName('ScriptProfileNode.visible')
  final bool visible;

  @DocsEditable @DomName('ScriptProfileNode.children')
  List<ScriptProfileNode> children() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLSelectElement')
class SelectElement extends Element native "*HTMLSelectElement" {

  @DocsEditable
  factory SelectElement() => document.$dom_createElement("select");

  @DocsEditable @DomName('HTMLSelectElement.autofocus')
  bool autofocus;

  @DocsEditable @DomName('HTMLSelectElement.disabled')
  bool disabled;

  @DocsEditable @DomName('HTMLSelectElement.form')
  final FormElement form;

  @DocsEditable @DomName('HTMLSelectElement.labels')
  @Returns('NodeList') @Creates('NodeList')
  final List<Node> labels;

  @DocsEditable @DomName('HTMLSelectElement.length')
  int length;

  @DocsEditable @DomName('HTMLSelectElement.multiple')
  bool multiple;

  @DocsEditable @DomName('HTMLSelectElement.name')
  String name;

  @DocsEditable @DomName('HTMLSelectElement.required')
  bool required;

  @DocsEditable @DomName('HTMLSelectElement.selectedIndex')
  int selectedIndex;

  @DocsEditable @DomName('HTMLSelectElement.size')
  int size;

  @DocsEditable @DomName('HTMLSelectElement.type')
  final String type;

  @DocsEditable @DomName('HTMLSelectElement.validationMessage')
  final String validationMessage;

  @DocsEditable @DomName('HTMLSelectElement.validity')
  final ValidityState validity;

  @DocsEditable @DomName('HTMLSelectElement.value')
  String value;

  @DocsEditable @DomName('HTMLSelectElement.willValidate')
  final bool willValidate;

  @DocsEditable @DomName('HTMLSelectElement.checkValidity')
  bool checkValidity() native;

  @DocsEditable @DomName('HTMLSelectElement.item')
  Node item(int index) native;

  @DocsEditable @DomName('HTMLSelectElement.namedItem')
  Node namedItem(String name) native;

  @DocsEditable @DomName('HTMLSelectElement.setCustomValidity')
  void setCustomValidity(String error) native;


  // Override default options, since IE returns SelectElement itself and it
  // does not operate as a List.
  List<OptionElement> get options {
    var options = this.children.where((e) => e is OptionElement).toList();
    return new ListView(options, 0, options.length);
  }

  List<OptionElement> get selectedOptions {
    // IE does not change the selected flag for single-selection items.
    if (this.multiple) {
      var options = this.options.where((o) => o.selected).toList();
      return new ListView(options, 0, options.length);
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
@Experimental()
class ShadowElement extends Element native "*HTMLShadowElement" {

  /// Checks if this type is supported on the current platform.
  static bool get supported => Element.isTagSupported('shadow');

  @DocsEditable @DomName('HTMLShadowElement.olderShadowRoot')
  final ShadowRoot olderShadowRoot;

  @DocsEditable @DomName('HTMLShadowElement.resetStyleInheritance')
  bool resetStyleInheritance;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('ShadowRoot')
@SupportedBrowser(SupportedBrowser.CHROME, '25')
@Experimental()
class ShadowRoot extends DocumentFragment native "*ShadowRoot" {

  @DocsEditable @DomName('ShadowRoot.activeElement')
  final Element activeElement;

  @DocsEditable @DomName('ShadowRoot.applyAuthorStyles')
  bool applyAuthorStyles;

  @JSName('innerHTML')
  @DocsEditable @DomName('ShadowRoot.innerHTML')
  String innerHtml;

  @DocsEditable @DomName('ShadowRoot.resetStyleInheritance')
  bool resetStyleInheritance;

  @JSName('cloneNode')
  @DocsEditable @DomName('ShadowRoot.cloneNode')
  Node clone(bool deep) native;

  @JSName('getElementById')
  @DocsEditable @DomName('ShadowRoot.getElementById')
  Element $dom_getElementById(String elementId) native;

  @JSName('getElementsByClassName')
  @DocsEditable @DomName('ShadowRoot.getElementsByClassName')
  @Returns('NodeList') @Creates('NodeList')
  List<Node> $dom_getElementsByClassName(String className) native;

  @JSName('getElementsByTagName')
  @DocsEditable @DomName('ShadowRoot.getElementsByTagName')
  @Returns('NodeList') @Creates('NodeList')
  List<Node> $dom_getElementsByTagName(String tagName) native;

  @DocsEditable @DomName('ShadowRoot.getSelection')
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

  @DocsEditable @DomName('SharedWorker.port')
  final MessagePort port;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SharedWorkerContext')
class SharedWorkerContext extends WorkerContext native "*SharedWorkerContext" {

  static const EventStreamProvider<Event> connectEvent = const EventStreamProvider<Event>('connect');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  SharedWorkerContextEvents get on =>
    new SharedWorkerContextEvents(this);

  @DocsEditable @DomName('SharedWorkerContext.name')
  final String name;

  Stream<Event> get onConnect => connectEvent.forTarget(this);
}

@DocsEditable
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

  @DocsEditable @DomName('SourceBuffer.buffered')
  final TimeRanges buffered;

  @DocsEditable @DomName('SourceBuffer.timestampOffset')
  num timestampOffset;

  @DocsEditable @DomName('SourceBuffer.abort')
  void abort() native;

  @DocsEditable @DomName('SourceBuffer.append')
  void append(Uint8Array data) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SourceBufferList')
class SourceBufferList extends EventTarget implements JavaScriptIndexingBehavior, List<SourceBuffer> native "*SourceBufferList" {

  @DocsEditable @DomName('SourceBufferList.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(SourceBuffer element) => Collections.contains(this, element);

  void forEach(void f(SourceBuffer element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(SourceBuffer element)) => new MappedList<SourceBuffer, dynamic>(this, f);

  Iterable<SourceBuffer> where(bool f(SourceBuffer element)) => new WhereIterable<SourceBuffer>(this, f);

  bool every(bool f(SourceBuffer element)) => Collections.every(this, f);

  bool any(bool f(SourceBuffer element)) => Collections.any(this, f);

  List<SourceBuffer> toList() => new List<SourceBuffer>.from(this);
  Set<SourceBuffer> toSet() => new Set<SourceBuffer>.from(this);

  bool get isEmpty => this.length == 0;

  List<SourceBuffer> take(int n) => new ListView<SourceBuffer>(this, 0, n);

  Iterable<SourceBuffer> takeWhile(bool test(SourceBuffer value)) {
    return new TakeWhileIterable<SourceBuffer>(this, test);
  }

  List<SourceBuffer> skip(int n) => new ListView<SourceBuffer>(this, n, null);

  Iterable<SourceBuffer> skipWhile(bool test(SourceBuffer value)) {
    return new SkipWhileIterable<SourceBuffer>(this, test);
  }

  SourceBuffer firstMatching(bool test(SourceBuffer value), { SourceBuffer orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  SourceBuffer lastMatching(bool test(SourceBuffer value), {SourceBuffer orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  SourceBuffer singleMatching(bool test(SourceBuffer value)) {
    return Collections.singleMatching(this, test);
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

  SourceBuffer min([int compare(SourceBuffer a, SourceBuffer b)]) => Collections.min(this, compare);

  SourceBuffer max([int compare(SourceBuffer a, SourceBuffer b)]) => Collections.max(this, compare);

  SourceBuffer removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  SourceBuffer removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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
  @DocsEditable @DomName('SourceBufferList.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('SourceBufferList.dispatchEvent')
  bool $dom_dispatchEvent(Event event) native;

  @DocsEditable @DomName('SourceBufferList.item')
  SourceBuffer item(int index) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('SourceBufferList.removeEventListener')
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

  @DocsEditable @DomName('HTMLSourceElement.media')
  String media;

  @DocsEditable @DomName('HTMLSourceElement.src')
  String src;

  @DocsEditable @DomName('HTMLSourceElement.type')
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

  @DocsEditable @DomName('SpeechGrammar.src')
  String src;

  @DocsEditable @DomName('SpeechGrammar.weight')
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

  @DocsEditable @DomName('SpeechGrammarList.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(SpeechGrammar element) => Collections.contains(this, element);

  void forEach(void f(SpeechGrammar element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(SpeechGrammar element)) => new MappedList<SpeechGrammar, dynamic>(this, f);

  Iterable<SpeechGrammar> where(bool f(SpeechGrammar element)) => new WhereIterable<SpeechGrammar>(this, f);

  bool every(bool f(SpeechGrammar element)) => Collections.every(this, f);

  bool any(bool f(SpeechGrammar element)) => Collections.any(this, f);

  List<SpeechGrammar> toList() => new List<SpeechGrammar>.from(this);
  Set<SpeechGrammar> toSet() => new Set<SpeechGrammar>.from(this);

  bool get isEmpty => this.length == 0;

  List<SpeechGrammar> take(int n) => new ListView<SpeechGrammar>(this, 0, n);

  Iterable<SpeechGrammar> takeWhile(bool test(SpeechGrammar value)) {
    return new TakeWhileIterable<SpeechGrammar>(this, test);
  }

  List<SpeechGrammar> skip(int n) => new ListView<SpeechGrammar>(this, n, null);

  Iterable<SpeechGrammar> skipWhile(bool test(SpeechGrammar value)) {
    return new SkipWhileIterable<SpeechGrammar>(this, test);
  }

  SpeechGrammar firstMatching(bool test(SpeechGrammar value), { SpeechGrammar orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  SpeechGrammar lastMatching(bool test(SpeechGrammar value), {SpeechGrammar orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  SpeechGrammar singleMatching(bool test(SpeechGrammar value)) {
    return Collections.singleMatching(this, test);
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

  SpeechGrammar min([int compare(SpeechGrammar a, SpeechGrammar b)]) => Collections.min(this, compare);

  SpeechGrammar max([int compare(SpeechGrammar a, SpeechGrammar b)]) => Collections.max(this, compare);

  SpeechGrammar removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  SpeechGrammar removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('SpeechGrammarList.addFromString')
  void addFromString(String string, [num weight]) native;

  @DocsEditable @DomName('SpeechGrammarList.addFromUri')
  void addFromUri(String src, [num weight]) native;

  @DocsEditable @DomName('SpeechGrammarList.item')
  SpeechGrammar item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SpeechInputEvent')
class SpeechInputEvent extends Event native "*SpeechInputEvent" {

  @DocsEditable @DomName('SpeechInputEvent.results')
  @Returns('_SpeechInputResultList') @Creates('_SpeechInputResultList')
  final List<SpeechInputResult> results;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SpeechInputResult')
class SpeechInputResult native "*SpeechInputResult" {

  @DocsEditable @DomName('SpeechInputResult.confidence')
  final num confidence;

  @DocsEditable @DomName('SpeechInputResult.utterance')
  final String utterance;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SpeechRecognition')
class SpeechRecognition extends EventTarget native "*SpeechRecognition" {

  static const EventStreamProvider<Event> audioEndEvent = const EventStreamProvider<Event>('audioend');

  static const EventStreamProvider<Event> audioStartEvent = const EventStreamProvider<Event>('audiostart');

  static const EventStreamProvider<Event> endEvent = const EventStreamProvider<Event>('end');

  static const EventStreamProvider<SpeechRecognitionError> errorEvent = const EventStreamProvider<SpeechRecognitionError>('error');

  static const EventStreamProvider<SpeechRecognitionEvent> noMatchEvent = const EventStreamProvider<SpeechRecognitionEvent>('nomatch');

  static const EventStreamProvider<SpeechRecognitionEvent> resultEvent = const EventStreamProvider<SpeechRecognitionEvent>('result');

  static const EventStreamProvider<Event> soundEndEvent = const EventStreamProvider<Event>('soundend');

  static const EventStreamProvider<Event> soundStartEvent = const EventStreamProvider<Event>('soundstart');

  static const EventStreamProvider<Event> speechEndEvent = const EventStreamProvider<Event>('speechend');

  static const EventStreamProvider<Event> speechStartEvent = const EventStreamProvider<Event>('speechstart');

  static const EventStreamProvider<Event> startEvent = const EventStreamProvider<Event>('start');

  @DocsEditable
  factory SpeechRecognition() => SpeechRecognition._create();
  static SpeechRecognition _create() => JS('SpeechRecognition', 'new SpeechRecognition()');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  SpeechRecognitionEvents get on =>
    new SpeechRecognitionEvents(this);

  @DocsEditable @DomName('SpeechRecognition.continuous')
  bool continuous;

  @DocsEditable @DomName('SpeechRecognition.grammars')
  SpeechGrammarList grammars;

  @DocsEditable @DomName('SpeechRecognition.interimResults')
  bool interimResults;

  @DocsEditable @DomName('SpeechRecognition.lang')
  String lang;

  @DocsEditable @DomName('SpeechRecognition.maxAlternatives')
  int maxAlternatives;

  @DocsEditable @DomName('SpeechRecognition.abort')
  void abort() native;

  @JSName('addEventListener')
  @DocsEditable @DomName('SpeechRecognition.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('SpeechRecognition.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('SpeechRecognition.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('SpeechRecognition.start')
  void start() native;

  @DocsEditable @DomName('SpeechRecognition.stop')
  void stop() native;

  Stream<Event> get onAudioEnd => audioEndEvent.forTarget(this);

  Stream<Event> get onAudioStart => audioStartEvent.forTarget(this);

  Stream<Event> get onEnd => endEvent.forTarget(this);

  Stream<SpeechRecognitionError> get onError => errorEvent.forTarget(this);

  Stream<SpeechRecognitionEvent> get onNoMatch => noMatchEvent.forTarget(this);

  Stream<SpeechRecognitionEvent> get onResult => resultEvent.forTarget(this);

  Stream<Event> get onSoundEnd => soundEndEvent.forTarget(this);

  Stream<Event> get onSoundStart => soundStartEvent.forTarget(this);

  Stream<Event> get onSpeechEnd => speechEndEvent.forTarget(this);

  Stream<Event> get onSpeechStart => speechStartEvent.forTarget(this);

  Stream<Event> get onStart => startEvent.forTarget(this);
}

@DocsEditable
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
class SpeechRecognitionAlternative native "*SpeechRecognitionAlternative" {

  @DocsEditable @DomName('SpeechRecognitionAlternative.confidence')
  final num confidence;

  @DocsEditable @DomName('SpeechRecognitionAlternative.transcript')
  final String transcript;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SpeechRecognitionError')
class SpeechRecognitionError extends Event native "*SpeechRecognitionError" {

  @DocsEditable @DomName('SpeechRecognitionError.error')
  final String error;

  @DocsEditable @DomName('SpeechRecognitionError.message')
  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SpeechRecognitionEvent')
class SpeechRecognitionEvent extends Event native "*SpeechRecognitionEvent" {

  @DocsEditable @DomName('SpeechRecognitionEvent.result')
  final SpeechRecognitionResult result;

  @DocsEditable @DomName('SpeechRecognitionEvent.resultHistory')
  @Returns('_SpeechRecognitionResultList') @Creates('_SpeechRecognitionResultList')
  final List<SpeechRecognitionResult> resultHistory;

  @DocsEditable @DomName('SpeechRecognitionEvent.resultIndex')
  final int resultIndex;

  @DocsEditable @DomName('SpeechRecognitionEvent.results')
  @Returns('_SpeechRecognitionResultList') @Creates('_SpeechRecognitionResultList')
  final List<SpeechRecognitionResult> results;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SpeechRecognitionResult')
class SpeechRecognitionResult native "*SpeechRecognitionResult" {

  @DocsEditable @DomName('SpeechRecognitionResult.isFinal')
  final bool isFinal;

  @DocsEditable @DomName('SpeechRecognitionResult.length')
  final int length;

  @DocsEditable @DomName('SpeechRecognitionResult.item')
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

  @DocsEditable @DomName('SQLError.code')
  final int code;

  @DocsEditable @DomName('SQLError.message')
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

  @DocsEditable @DomName('SQLException.code')
  final int code;

  @DocsEditable @DomName('SQLException.message')
  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SQLResultSet')
class SqlResultSet native "*SQLResultSet" {

  @DocsEditable @DomName('SQLResultSet.insertId')
  final int insertId;

  @DocsEditable @DomName('SQLResultSet.rows')
  final SqlResultSetRowList rows;

  @DocsEditable @DomName('SQLResultSet.rowsAffected')
  final int rowsAffected;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SQLResultSetRowList')
class SqlResultSetRowList implements JavaScriptIndexingBehavior, List<Map> native "*SQLResultSetRowList" {

  @DocsEditable @DomName('SQLResultSetRowList.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(Map element) => Collections.contains(this, element);

  void forEach(void f(Map element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(Map element)) => new MappedList<Map, dynamic>(this, f);

  Iterable<Map> where(bool f(Map element)) => new WhereIterable<Map>(this, f);

  bool every(bool f(Map element)) => Collections.every(this, f);

  bool any(bool f(Map element)) => Collections.any(this, f);

  List<Map> toList() => new List<Map>.from(this);
  Set<Map> toSet() => new Set<Map>.from(this);

  bool get isEmpty => this.length == 0;

  List<Map> take(int n) => new ListView<Map>(this, 0, n);

  Iterable<Map> takeWhile(bool test(Map value)) {
    return new TakeWhileIterable<Map>(this, test);
  }

  List<Map> skip(int n) => new ListView<Map>(this, n, null);

  Iterable<Map> skipWhile(bool test(Map value)) {
    return new SkipWhileIterable<Map>(this, test);
  }

  Map firstMatching(bool test(Map value), { Map orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  Map lastMatching(bool test(Map value), {Map orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  Map singleMatching(bool test(Map value)) {
    return Collections.singleMatching(this, test);
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

  Map min([int compare(Map a, Map b)]) => Collections.min(this, compare);

  Map max([int compare(Map a, Map b)]) => Collections.max(this, compare);

  Map removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  Map removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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
  @DocsEditable @DomName('SQLResultSetRowList.item') @Creates('=Object')
  _item_1(index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SQLTransaction')
class SqlTransaction native "*SQLTransaction" {

  @DocsEditable @DomName('SQLTransaction.executeSql')
  void executeSql(String sqlStatement, List arguments, [SqlStatementCallback callback, SqlStatementErrorCallback errorCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SQLTransactionSync')
class SqlTransactionSync native "*SQLTransactionSync" {

  @DocsEditable @DomName('SQLTransactionSync.executeSql')
  SqlResultSet executeSql(String sqlStatement, List arguments) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('Storage')
class Storage implements Map<String, String>  native "*Storage" {

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
  @DocsEditable @DomName('Storage.length')
  final int $dom_length;

  @JSName('clear')
  @DocsEditable @DomName('Storage.clear')
  void $dom_clear() native;

  @JSName('getItem')
  @DocsEditable @DomName('Storage.getItem')
  String $dom_getItem(String key) native;

  @JSName('key')
  @DocsEditable @DomName('Storage.key')
  String $dom_key(int index) native;

  @JSName('removeItem')
  @DocsEditable @DomName('Storage.removeItem')
  void $dom_removeItem(String key) native;

  @JSName('setItem')
  @DocsEditable @DomName('Storage.setItem')
  void $dom_setItem(String key, String data) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('StorageEvent')
class StorageEvent extends Event native "*StorageEvent" {

  @DocsEditable @DomName('StorageEvent.key')
  final String key;

  @DocsEditable @DomName('StorageEvent.newValue')
  final String newValue;

  @DocsEditable @DomName('StorageEvent.oldValue')
  final String oldValue;

  @DocsEditable @DomName('StorageEvent.storageArea')
  final Storage storageArea;

  @DocsEditable @DomName('StorageEvent.url')
  final String url;

  @DocsEditable @DomName('StorageEvent.initStorageEvent')
  void initStorageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String keyArg, String oldValueArg, String newValueArg, String urlArg, Storage storageAreaArg) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('StorageInfo')
class StorageInfo native "*StorageInfo" {

  static const int PERSISTENT = 1;

  static const int TEMPORARY = 0;

  @DocsEditable @DomName('StorageInfo.queryUsageAndQuota')
  void queryUsageAndQuota(int storageType, [StorageInfoUsageCallback usageCallback, StorageInfoErrorCallback errorCallback]) native;

  @DocsEditable @DomName('StorageInfo.requestQuota')
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

  @DocsEditable @DomName('HTMLStyleElement.disabled')
  bool disabled;

  @DocsEditable @DomName('HTMLStyleElement.media')
  String media;

  @DocsEditable @DomName('HTMLStyleElement.scoped')
  bool scoped;

  @DocsEditable @DomName('HTMLStyleElement.sheet')
  final StyleSheet sheet;

  @DocsEditable @DomName('HTMLStyleElement.type')
  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('StyleMedia')
class StyleMedia native "*StyleMedia" {

  @DocsEditable @DomName('StyleMedia.type')
  final String type;

  @DocsEditable @DomName('StyleMedia.matchMedium')
  bool matchMedium(String mediaquery) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('StyleSheet')
class StyleSheet native "*StyleSheet" {

  @DocsEditable @DomName('StyleSheet.disabled')
  bool disabled;

  @DocsEditable @DomName('StyleSheet.href')
  final String href;

  @DocsEditable @DomName('StyleSheet.media')
  final MediaList media;

  @DocsEditable @DomName('StyleSheet.ownerNode')
  final Node ownerNode;

  @DocsEditable @DomName('StyleSheet.parentStyleSheet')
  final StyleSheet parentStyleSheet;

  @DocsEditable @DomName('StyleSheet.title')
  final String title;

  @DocsEditable @DomName('StyleSheet.type')
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

  @DocsEditable @DomName('HTMLTableCellElement.cellIndex')
  final int cellIndex;

  @DocsEditable @DomName('HTMLTableCellElement.colSpan')
  int colSpan;

  @DocsEditable @DomName('HTMLTableCellElement.headers')
  String headers;

  @DocsEditable @DomName('HTMLTableCellElement.rowSpan')
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

  @DocsEditable @DomName('HTMLTableColElement.span')
  int span;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('HTMLTableElement')
class TableElement extends Element native "*HTMLTableElement" {

  @DocsEditable
  factory TableElement() => document.$dom_createElement("table");

  @DocsEditable @DomName('HTMLTableElement.border')
  String border;

  @DocsEditable @DomName('HTMLTableElement.caption')
  TableCaptionElement caption;

  @DocsEditable @DomName('HTMLTableElement.rows')
  final HtmlCollection rows;

  @DocsEditable @DomName('HTMLTableElement.tBodies')
  final HtmlCollection tBodies;

  @DocsEditable @DomName('HTMLTableElement.tFoot')
  TableSectionElement tFoot;

  @DocsEditable @DomName('HTMLTableElement.tHead')
  TableSectionElement tHead;

  @DocsEditable @DomName('HTMLTableElement.createCaption')
  Element createCaption() native;

  @DocsEditable @DomName('HTMLTableElement.createTFoot')
  Element createTFoot() native;

  @DocsEditable @DomName('HTMLTableElement.createTHead')
  Element createTHead() native;

  @DocsEditable @DomName('HTMLTableElement.deleteCaption')
  void deleteCaption() native;

  @DocsEditable @DomName('HTMLTableElement.deleteRow')
  void deleteRow(int index) native;

  @DocsEditable @DomName('HTMLTableElement.deleteTFoot')
  void deleteTFoot() native;

  @DocsEditable @DomName('HTMLTableElement.deleteTHead')
  void deleteTHead() native;

  @DocsEditable @DomName('HTMLTableElement.insertRow')
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

  @DocsEditable @DomName('HTMLTableRowElement.cells')
  final HtmlCollection cells;

  @DocsEditable @DomName('HTMLTableRowElement.rowIndex')
  final int rowIndex;

  @DocsEditable @DomName('HTMLTableRowElement.sectionRowIndex')
  final int sectionRowIndex;

  @DocsEditable @DomName('HTMLTableRowElement.deleteCell')
  void deleteCell(int index) native;

  @DocsEditable @DomName('HTMLTableRowElement.insertCell')
  Element insertCell(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('HTMLTableSectionElement')
class TableSectionElement extends Element native "*HTMLTableSectionElement" {

  @DocsEditable @DomName('HTMLTableSectionElement.rows')
  final HtmlCollection rows;

  @DocsEditable @DomName('HTMLTableSectionElement.deleteRow')
  void deleteRow(int index) native;

  @DocsEditable @DomName('HTMLTableSectionElement.insertRow')
  Element insertRow(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('Text')
class Text extends CharacterData native "*Text" {
  factory Text(String data) => _TextFactoryProvider.createText(data);

  @DocsEditable @DomName('Text.wholeText')
  final String wholeText;

  @DocsEditable @DomName('Text.replaceWholeText')
  Text replaceWholeText(String content) native;

  @DocsEditable @DomName('Text.splitText')
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

  @DocsEditable @DomName('HTMLTextAreaElement.autofocus')
  bool autofocus;

  @DocsEditable @DomName('HTMLTextAreaElement.cols')
  int cols;

  @DocsEditable @DomName('HTMLTextAreaElement.defaultValue')
  String defaultValue;

  @DocsEditable @DomName('HTMLTextAreaElement.dirName')
  String dirName;

  @DocsEditable @DomName('HTMLTextAreaElement.disabled')
  bool disabled;

  @DocsEditable @DomName('HTMLTextAreaElement.form')
  final FormElement form;

  @DocsEditable @DomName('HTMLTextAreaElement.labels')
  @Returns('NodeList') @Creates('NodeList')
  final List<Node> labels;

  @DocsEditable @DomName('HTMLTextAreaElement.maxLength')
  int maxLength;

  @DocsEditable @DomName('HTMLTextAreaElement.name')
  String name;

  @DocsEditable @DomName('HTMLTextAreaElement.placeholder')
  String placeholder;

  @DocsEditable @DomName('HTMLTextAreaElement.readOnly')
  bool readOnly;

  @DocsEditable @DomName('HTMLTextAreaElement.required')
  bool required;

  @DocsEditable @DomName('HTMLTextAreaElement.rows')
  int rows;

  @DocsEditable @DomName('HTMLTextAreaElement.selectionDirection')
  String selectionDirection;

  @DocsEditable @DomName('HTMLTextAreaElement.selectionEnd')
  int selectionEnd;

  @DocsEditable @DomName('HTMLTextAreaElement.selectionStart')
  int selectionStart;

  @DocsEditable @DomName('HTMLTextAreaElement.textLength')
  final int textLength;

  @DocsEditable @DomName('HTMLTextAreaElement.type')
  final String type;

  @DocsEditable @DomName('HTMLTextAreaElement.validationMessage')
  final String validationMessage;

  @DocsEditable @DomName('HTMLTextAreaElement.validity')
  final ValidityState validity;

  @DocsEditable @DomName('HTMLTextAreaElement.value')
  String value;

  @DocsEditable @DomName('HTMLTextAreaElement.willValidate')
  final bool willValidate;

  @DocsEditable @DomName('HTMLTextAreaElement.wrap')
  String wrap;

  @DocsEditable @DomName('HTMLTextAreaElement.checkValidity')
  bool checkValidity() native;

  @DocsEditable @DomName('HTMLTextAreaElement.select')
  void select() native;

  @DocsEditable @DomName('HTMLTextAreaElement.setCustomValidity')
  void setCustomValidity(String error) native;

  @DocsEditable @DomName('HTMLTextAreaElement.setRangeText')
  void setRangeText(String replacement, [int start, int end, String selectionMode]) native;

  @DocsEditable @DomName('HTMLTextAreaElement.setSelectionRange')
  void setSelectionRange(int start, int end, [String direction]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('TextEvent')
class TextEvent extends UIEvent native "*TextEvent" {

  @DocsEditable @DomName('TextEvent.data')
  final String data;

  @DocsEditable @DomName('TextEvent.initTextEvent')
  void initTextEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Window viewArg, String dataArg) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('TextMetrics')
class TextMetrics native "*TextMetrics" {

  @DocsEditable @DomName('TextMetrics.width')
  final num width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('TextTrack')
class TextTrack extends EventTarget native "*TextTrack" {

  static const EventStreamProvider<Event> cueChangeEvent = const EventStreamProvider<Event>('cuechange');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  TextTrackEvents get on =>
    new TextTrackEvents(this);

  @DocsEditable @DomName('TextTrack.activeCues')
  final TextTrackCueList activeCues;

  @DocsEditable @DomName('TextTrack.cues')
  final TextTrackCueList cues;

  @DocsEditable @DomName('TextTrack.kind')
  final String kind;

  @DocsEditable @DomName('TextTrack.label')
  final String label;

  @DocsEditable @DomName('TextTrack.language')
  final String language;

  @DocsEditable @DomName('TextTrack.mode')
  String mode;

  @DocsEditable @DomName('TextTrack.addCue')
  void addCue(TextTrackCue cue) native;

  @JSName('addEventListener')
  @DocsEditable @DomName('TextTrack.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('TextTrack.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  @DocsEditable @DomName('TextTrack.removeCue')
  void removeCue(TextTrackCue cue) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('TextTrack.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  Stream<Event> get onCueChange => cueChangeEvent.forTarget(this);
}

@DocsEditable
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

  static const EventStreamProvider<Event> enterEvent = const EventStreamProvider<Event>('enter');

  static const EventStreamProvider<Event> exitEvent = const EventStreamProvider<Event>('exit');

  @DocsEditable
  factory TextTrackCue(num startTime, num endTime, String text) => TextTrackCue._create(startTime, endTime, text);
  static TextTrackCue _create(num startTime, num endTime, String text) => JS('TextTrackCue', 'new TextTrackCue(#,#,#)', startTime, endTime, text);

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  TextTrackCueEvents get on =>
    new TextTrackCueEvents(this);

  @DocsEditable @DomName('TextTrackCue.align')
  String align;

  @DocsEditable @DomName('TextTrackCue.endTime')
  num endTime;

  @DocsEditable @DomName('TextTrackCue.id')
  String id;

  @DocsEditable @DomName('TextTrackCue.line')
  int line;

  @DocsEditable @DomName('TextTrackCue.pauseOnExit')
  bool pauseOnExit;

  @DocsEditable @DomName('TextTrackCue.position')
  int position;

  @DocsEditable @DomName('TextTrackCue.size')
  int size;

  @DocsEditable @DomName('TextTrackCue.snapToLines')
  bool snapToLines;

  @DocsEditable @DomName('TextTrackCue.startTime')
  num startTime;

  @DocsEditable @DomName('TextTrackCue.text')
  String text;

  @DocsEditable @DomName('TextTrackCue.track')
  final TextTrack track;

  @DocsEditable @DomName('TextTrackCue.vertical')
  String vertical;

  @JSName('addEventListener')
  @DocsEditable @DomName('TextTrackCue.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('TextTrackCue.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  @JSName('getCueAsHTML')
  @DocsEditable @DomName('TextTrackCue.getCueAsHTML')
  DocumentFragment getCueAsHtml() native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('TextTrackCue.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  Stream<Event> get onEnter => enterEvent.forTarget(this);

  Stream<Event> get onExit => exitEvent.forTarget(this);
}

@DocsEditable
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

  @DocsEditable @DomName('TextTrackCueList.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(TextTrackCue element) => Collections.contains(this, element);

  void forEach(void f(TextTrackCue element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(TextTrackCue element)) => new MappedList<TextTrackCue, dynamic>(this, f);

  Iterable<TextTrackCue> where(bool f(TextTrackCue element)) => new WhereIterable<TextTrackCue>(this, f);

  bool every(bool f(TextTrackCue element)) => Collections.every(this, f);

  bool any(bool f(TextTrackCue element)) => Collections.any(this, f);

  List<TextTrackCue> toList() => new List<TextTrackCue>.from(this);
  Set<TextTrackCue> toSet() => new Set<TextTrackCue>.from(this);

  bool get isEmpty => this.length == 0;

  List<TextTrackCue> take(int n) => new ListView<TextTrackCue>(this, 0, n);

  Iterable<TextTrackCue> takeWhile(bool test(TextTrackCue value)) {
    return new TakeWhileIterable<TextTrackCue>(this, test);
  }

  List<TextTrackCue> skip(int n) => new ListView<TextTrackCue>(this, n, null);

  Iterable<TextTrackCue> skipWhile(bool test(TextTrackCue value)) {
    return new SkipWhileIterable<TextTrackCue>(this, test);
  }

  TextTrackCue firstMatching(bool test(TextTrackCue value), { TextTrackCue orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  TextTrackCue lastMatching(bool test(TextTrackCue value), {TextTrackCue orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  TextTrackCue singleMatching(bool test(TextTrackCue value)) {
    return Collections.singleMatching(this, test);
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

  TextTrackCue min([int compare(TextTrackCue a, TextTrackCue b)]) => Collections.min(this, compare);

  TextTrackCue max([int compare(TextTrackCue a, TextTrackCue b)]) => Collections.max(this, compare);

  TextTrackCue removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  TextTrackCue removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('TextTrackCueList.getCueById')
  TextTrackCue getCueById(String id) native;

  @DocsEditable @DomName('TextTrackCueList.item')
  TextTrackCue item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('TextTrackList')
class TextTrackList extends EventTarget implements JavaScriptIndexingBehavior, List<TextTrack> native "*TextTrackList" {

  static const EventStreamProvider<TrackEvent> addTrackEvent = const EventStreamProvider<TrackEvent>('addtrack');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  TextTrackListEvents get on =>
    new TextTrackListEvents(this);

  @DocsEditable @DomName('TextTrackList.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(TextTrack element) => Collections.contains(this, element);

  void forEach(void f(TextTrack element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(TextTrack element)) => new MappedList<TextTrack, dynamic>(this, f);

  Iterable<TextTrack> where(bool f(TextTrack element)) => new WhereIterable<TextTrack>(this, f);

  bool every(bool f(TextTrack element)) => Collections.every(this, f);

  bool any(bool f(TextTrack element)) => Collections.any(this, f);

  List<TextTrack> toList() => new List<TextTrack>.from(this);
  Set<TextTrack> toSet() => new Set<TextTrack>.from(this);

  bool get isEmpty => this.length == 0;

  List<TextTrack> take(int n) => new ListView<TextTrack>(this, 0, n);

  Iterable<TextTrack> takeWhile(bool test(TextTrack value)) {
    return new TakeWhileIterable<TextTrack>(this, test);
  }

  List<TextTrack> skip(int n) => new ListView<TextTrack>(this, n, null);

  Iterable<TextTrack> skipWhile(bool test(TextTrack value)) {
    return new SkipWhileIterable<TextTrack>(this, test);
  }

  TextTrack firstMatching(bool test(TextTrack value), { TextTrack orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  TextTrack lastMatching(bool test(TextTrack value), {TextTrack orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  TextTrack singleMatching(bool test(TextTrack value)) {
    return Collections.singleMatching(this, test);
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

  TextTrack min([int compare(TextTrack a, TextTrack b)]) => Collections.min(this, compare);

  TextTrack max([int compare(TextTrack a, TextTrack b)]) => Collections.max(this, compare);

  TextTrack removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  TextTrack removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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
  @DocsEditable @DomName('TextTrackList.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('TextTrackList.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  @DocsEditable @DomName('TextTrackList.item')
  TextTrack item(int index) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('TextTrackList.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  Stream<TrackEvent> get onAddTrack => addTrackEvent.forTarget(this);
}

@DocsEditable
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

  @DocsEditable @DomName('TimeRanges.length')
  final int length;

  @DocsEditable @DomName('TimeRanges.end')
  num end(int index) native;

  @DocsEditable @DomName('TimeRanges.start')
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

  @DocsEditable @DomName('Touch.clientX')
  final int clientX;

  @DocsEditable @DomName('Touch.clientY')
  final int clientY;

  @DocsEditable @DomName('Touch.identifier')
  final int identifier;

  @DocsEditable @DomName('Touch.pageX')
  final int pageX;

  @DocsEditable @DomName('Touch.pageY')
  final int pageY;

  @DocsEditable @DomName('Touch.screenX')
  final int screenX;

  @DocsEditable @DomName('Touch.screenY')
  final int screenY;

  EventTarget get target => _convertNativeToDart_EventTarget(this._target);
  @JSName('target')
  @DocsEditable @DomName('Touch.target') @Creates('Element|Document') @Returns('Element|Document')
  final dynamic _target;

  @DocsEditable @DomName('Touch.webkitForce')
  final num webkitForce;

  @DocsEditable @DomName('Touch.webkitRadiusX')
  final int webkitRadiusX;

  @DocsEditable @DomName('Touch.webkitRadiusY')
  final int webkitRadiusY;

  @DocsEditable @DomName('Touch.webkitRotationAngle')
  final num webkitRotationAngle;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('TouchEvent')
class TouchEvent extends UIEvent native "*TouchEvent" {

  @DocsEditable @DomName('TouchEvent.altKey')
  final bool altKey;

  @DocsEditable @DomName('TouchEvent.changedTouches')
  final TouchList changedTouches;

  @DocsEditable @DomName('TouchEvent.ctrlKey')
  final bool ctrlKey;

  @DocsEditable @DomName('TouchEvent.metaKey')
  final bool metaKey;

  @DocsEditable @DomName('TouchEvent.shiftKey')
  final bool shiftKey;

  @DocsEditable @DomName('TouchEvent.targetTouches')
  final TouchList targetTouches;

  @DocsEditable @DomName('TouchEvent.touches')
  final TouchList touches;

  @DocsEditable @DomName('TouchEvent.initTouchEvent')
  void initTouchEvent(TouchList touches, TouchList targetTouches, TouchList changedTouches, String type, Window view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('TouchList')
class TouchList implements JavaScriptIndexingBehavior, List<Touch> native "*TouchList" {

  @DocsEditable @DomName('TouchList.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(Touch element) => Collections.contains(this, element);

  void forEach(void f(Touch element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(Touch element)) => new MappedList<Touch, dynamic>(this, f);

  Iterable<Touch> where(bool f(Touch element)) => new WhereIterable<Touch>(this, f);

  bool every(bool f(Touch element)) => Collections.every(this, f);

  bool any(bool f(Touch element)) => Collections.any(this, f);

  List<Touch> toList() => new List<Touch>.from(this);
  Set<Touch> toSet() => new Set<Touch>.from(this);

  bool get isEmpty => this.length == 0;

  List<Touch> take(int n) => new ListView<Touch>(this, 0, n);

  Iterable<Touch> takeWhile(bool test(Touch value)) {
    return new TakeWhileIterable<Touch>(this, test);
  }

  List<Touch> skip(int n) => new ListView<Touch>(this, n, null);

  Iterable<Touch> skipWhile(bool test(Touch value)) {
    return new SkipWhileIterable<Touch>(this, test);
  }

  Touch firstMatching(bool test(Touch value), { Touch orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  Touch lastMatching(bool test(Touch value), {Touch orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  Touch singleMatching(bool test(Touch value)) {
    return Collections.singleMatching(this, test);
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

  Touch min([int compare(Touch a, Touch b)]) => Collections.min(this, compare);

  Touch max([int compare(Touch a, Touch b)]) => Collections.max(this, compare);

  Touch removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  Touch removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('TouchList.item')
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
  @DocsEditable @DomName('HTMLTrackElement.default')
  bool defaultValue;

  @DocsEditable @DomName('HTMLTrackElement.kind')
  String kind;

  @DocsEditable @DomName('HTMLTrackElement.label')
  String label;

  @DocsEditable @DomName('HTMLTrackElement.readyState')
  final int readyState;

  @DocsEditable @DomName('HTMLTrackElement.src')
  String src;

  @DocsEditable @DomName('HTMLTrackElement.srclang')
  String srclang;

  @DocsEditable @DomName('HTMLTrackElement.track')
  final TextTrack track;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('TrackEvent')
class TrackEvent extends Event native "*TrackEvent" {

  @DocsEditable @DomName('TrackEvent.track')
  final Object track;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('WebKitTransitionEvent')
class TransitionEvent extends Event native "*WebKitTransitionEvent" {

  @DocsEditable @DomName('WebKitTransitionEvent.elapsedTime')
  final num elapsedTime;

  @DocsEditable @DomName('WebKitTransitionEvent.propertyName')
  final String propertyName;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('TreeWalker')
class TreeWalker native "*TreeWalker" {

  @DocsEditable @DomName('TreeWalker.currentNode')
  Node currentNode;

  @DocsEditable @DomName('TreeWalker.expandEntityReferences')
  final bool expandEntityReferences;

  @DocsEditable @DomName('TreeWalker.filter')
  final NodeFilter filter;

  @DocsEditable @DomName('TreeWalker.root')
  final Node root;

  @DocsEditable @DomName('TreeWalker.whatToShow')
  final int whatToShow;

  @DocsEditable @DomName('TreeWalker.firstChild')
  Node firstChild() native;

  @DocsEditable @DomName('TreeWalker.lastChild')
  Node lastChild() native;

  @DocsEditable @DomName('TreeWalker.nextNode')
  Node nextNode() native;

  @DocsEditable @DomName('TreeWalker.nextSibling')
  Node nextSibling() native;

  @DocsEditable @DomName('TreeWalker.parentNode')
  Node parentNode() native;

  @DocsEditable @DomName('TreeWalker.previousNode')
  Node previousNode() native;

  @DocsEditable @DomName('TreeWalker.previousSibling')
  Node previousSibling() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('UIEvent')
class UIEvent extends Event native "*UIEvent" {
  // In JS, canBubble and cancelable are technically required parameters to
  // init*Event. In practice, though, if they aren't provided they simply
  // default to false (since that's Boolean(undefined)).
  //
  // Contrary to JS, we default canBubble and cancelable to true, since that's
  // what people want most of the time anyway.
  factory UIEvent(String type, Window view, int detail,
      [bool canBubble = true, bool cancelable = true]) {
    final e = document.$dom_createEvent("UIEvent");
    e.$dom_initUIEvent(type, canBubble, cancelable, view, detail);
    return e;
  }

  @JSName('charCode')
  @DocsEditable @DomName('UIEvent.charCode')
  final int $dom_charCode;

  @DocsEditable @DomName('UIEvent.detail')
  final int detail;

  @JSName('keyCode')
  @DocsEditable @DomName('UIEvent.keyCode')
  final int $dom_keyCode;

  @DocsEditable @DomName('UIEvent.layerX')
  final int layerX;

  @DocsEditable @DomName('UIEvent.layerY')
  final int layerY;

  @DocsEditable @DomName('UIEvent.pageX')
  final int pageX;

  @DocsEditable @DomName('UIEvent.pageY')
  final int pageY;

  WindowBase get view => _convertNativeToDart_Window(this._view);
  @JSName('view')
  @DocsEditable @DomName('UIEvent.view') @Creates('Window|=Object') @Returns('Window|=Object')
  final dynamic _view;

  @DocsEditable @DomName('UIEvent.which')
  final int which;

  @JSName('initUIEvent')
  @DocsEditable @DomName('UIEvent.initUIEvent')
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

  @DocsEditable @DomName('Uint16Array.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(int element) => Collections.contains(this, element);

  void forEach(void f(int element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(int element)) => new MappedList<int, dynamic>(this, f);

  Iterable<int> where(bool f(int element)) => new WhereIterable<int>(this, f);

  bool every(bool f(int element)) => Collections.every(this, f);

  bool any(bool f(int element)) => Collections.any(this, f);

  List<int> toList() => new List<int>.from(this);
  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  List<int> take(int n) => new ListView<int>(this, 0, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return new TakeWhileIterable<int>(this, test);
  }

  List<int> skip(int n) => new ListView<int>(this, n, null);

  Iterable<int> skipWhile(bool test(int value)) {
    return new SkipWhileIterable<int>(this, test);
  }

  int firstMatching(bool test(int value), { int orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  int lastMatching(bool test(int value), {int orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  int singleMatching(bool test(int value)) {
    return Collections.singleMatching(this, test);
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

  int min([int compare(int a, int b)]) => Collections.min(this, compare);

  int max([int compare(int a, int b)]) => Collections.max(this, compare);

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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
  @DocsEditable @DomName('Uint16Array.set')
  void setElements(Object array, [int offset]) native;

  @DocsEditable @DomName('Uint16Array.subarray')
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

  @DocsEditable @DomName('Uint32Array.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(int element) => Collections.contains(this, element);

  void forEach(void f(int element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(int element)) => new MappedList<int, dynamic>(this, f);

  Iterable<int> where(bool f(int element)) => new WhereIterable<int>(this, f);

  bool every(bool f(int element)) => Collections.every(this, f);

  bool any(bool f(int element)) => Collections.any(this, f);

  List<int> toList() => new List<int>.from(this);
  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  List<int> take(int n) => new ListView<int>(this, 0, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return new TakeWhileIterable<int>(this, test);
  }

  List<int> skip(int n) => new ListView<int>(this, n, null);

  Iterable<int> skipWhile(bool test(int value)) {
    return new SkipWhileIterable<int>(this, test);
  }

  int firstMatching(bool test(int value), { int orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  int lastMatching(bool test(int value), {int orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  int singleMatching(bool test(int value)) {
    return Collections.singleMatching(this, test);
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

  int min([int compare(int a, int b)]) => Collections.min(this, compare);

  int max([int compare(int a, int b)]) => Collections.max(this, compare);

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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
  @DocsEditable @DomName('Uint32Array.set')
  void setElements(Object array, [int offset]) native;

  @DocsEditable @DomName('Uint32Array.subarray')
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

  @DocsEditable @DomName('Uint8Array.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(int element) => Collections.contains(this, element);

  void forEach(void f(int element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(int element)) => new MappedList<int, dynamic>(this, f);

  Iterable<int> where(bool f(int element)) => new WhereIterable<int>(this, f);

  bool every(bool f(int element)) => Collections.every(this, f);

  bool any(bool f(int element)) => Collections.any(this, f);

  List<int> toList() => new List<int>.from(this);
  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  List<int> take(int n) => new ListView<int>(this, 0, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return new TakeWhileIterable<int>(this, test);
  }

  List<int> skip(int n) => new ListView<int>(this, n, null);

  Iterable<int> skipWhile(bool test(int value)) {
    return new SkipWhileIterable<int>(this, test);
  }

  int firstMatching(bool test(int value), { int orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  int lastMatching(bool test(int value), {int orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  int singleMatching(bool test(int value)) {
    return Collections.singleMatching(this, test);
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

  int min([int compare(int a, int b)]) => Collections.min(this, compare);

  int max([int compare(int a, int b)]) => Collections.max(this, compare);

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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
  @DocsEditable @DomName('Uint8Array.set')
  void setElements(Object array, [int offset]) native;

  @DocsEditable @DomName('Uint8Array.subarray')
  Uint8Array subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('Uint8ClampedArray')
class Uint8ClampedArray extends Uint8Array native "*Uint8ClampedArray" {

  factory Uint8ClampedArray(int length) =>
    _TypedArrayFactoryProvider.createUint8ClampedArray(length);

  factory Uint8ClampedArray.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createUint8ClampedArray_fromList(list);

  factory Uint8ClampedArray.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createUint8ClampedArray_fromBuffer(buffer, byteOffset, length);

  // Use implementation from Uint8Array.
  // final int length;

  @JSName('set')
  @DocsEditable @DomName('Uint8ClampedArray.set')
  void setElements(Object array, [int offset]) native;

  @DocsEditable @DomName('Uint8ClampedArray.subarray')
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


@DocsEditable
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

  @DocsEditable @DomName('ValidityState.badInput')
  final bool badInput;

  @DocsEditable @DomName('ValidityState.customError')
  final bool customError;

  @DocsEditable @DomName('ValidityState.patternMismatch')
  final bool patternMismatch;

  @DocsEditable @DomName('ValidityState.rangeOverflow')
  final bool rangeOverflow;

  @DocsEditable @DomName('ValidityState.rangeUnderflow')
  final bool rangeUnderflow;

  @DocsEditable @DomName('ValidityState.stepMismatch')
  final bool stepMismatch;

  @DocsEditable @DomName('ValidityState.tooLong')
  final bool tooLong;

  @DocsEditable @DomName('ValidityState.typeMismatch')
  final bool typeMismatch;

  @DocsEditable @DomName('ValidityState.valid')
  final bool valid;

  @DocsEditable @DomName('ValidityState.valueMissing')
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

  @DocsEditable @DomName('HTMLVideoElement.height')
  int height;

  @DocsEditable @DomName('HTMLVideoElement.poster')
  String poster;

  @DocsEditable @DomName('HTMLVideoElement.videoHeight')
  final int videoHeight;

  @DocsEditable @DomName('HTMLVideoElement.videoWidth')
  final int videoWidth;

  @DocsEditable @DomName('HTMLVideoElement.webkitDecodedFrameCount')
  final int webkitDecodedFrameCount;

  @DocsEditable @DomName('HTMLVideoElement.webkitDisplayingFullscreen')
  final bool webkitDisplayingFullscreen;

  @DocsEditable @DomName('HTMLVideoElement.webkitDroppedFrameCount')
  final int webkitDroppedFrameCount;

  @DocsEditable @DomName('HTMLVideoElement.webkitSupportsFullscreen')
  final bool webkitSupportsFullscreen;

  @DocsEditable @DomName('HTMLVideoElement.width')
  int width;

  @DocsEditable @DomName('HTMLVideoElement.webkitEnterFullScreen')
  void webkitEnterFullScreen() native;

  @DocsEditable @DomName('HTMLVideoElement.webkitEnterFullscreen')
  void webkitEnterFullscreen() native;

  @DocsEditable @DomName('HTMLVideoElement.webkitExitFullScreen')
  void webkitExitFullScreen() native;

  @DocsEditable @DomName('HTMLVideoElement.webkitExitFullscreen')
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

  @DocsEditable @DomName('WebGLActiveInfo.name')
  final String name;

  @DocsEditable @DomName('WebGLActiveInfo.size')
  final int size;

  @DocsEditable @DomName('WebGLActiveInfo.type')
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

  @DocsEditable @DomName('WebGLContextAttributes.alpha')
  bool alpha;

  @DocsEditable @DomName('WebGLContextAttributes.antialias')
  bool antialias;

  @DocsEditable @DomName('WebGLContextAttributes.depth')
  bool depth;

  @DocsEditable @DomName('WebGLContextAttributes.premultipliedAlpha')
  bool premultipliedAlpha;

  @DocsEditable @DomName('WebGLContextAttributes.preserveDrawingBuffer')
  bool preserveDrawingBuffer;

  @DocsEditable @DomName('WebGLContextAttributes.stencil')
  bool stencil;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('WebGLContextEvent')
class WebGLContextEvent extends Event native "*WebGLContextEvent" {

  @DocsEditable @DomName('WebGLContextEvent.statusMessage')
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

  @DocsEditable @DomName('WebGLDebugShaders.getTranslatedShaderSource')
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

  @DocsEditable @DomName('WebGLLoseContext.loseContext')
  void loseContext() native;

  @DocsEditable @DomName('WebGLLoseContext.restoreContext')
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

  @DocsEditable @DomName('WebGLRenderingContext.drawingBufferHeight')
  final int drawingBufferHeight;

  @DocsEditable @DomName('WebGLRenderingContext.drawingBufferWidth')
  final int drawingBufferWidth;

  @DocsEditable @DomName('WebGLRenderingContext.activeTexture')
  void activeTexture(int texture) native;

  @DocsEditable @DomName('WebGLRenderingContext.attachShader')
  void attachShader(WebGLProgram program, WebGLShader shader) native;

  @DocsEditable @DomName('WebGLRenderingContext.bindAttribLocation')
  void bindAttribLocation(WebGLProgram program, int index, String name) native;

  @DocsEditable @DomName('WebGLRenderingContext.bindBuffer')
  void bindBuffer(int target, WebGLBuffer buffer) native;

  @DocsEditable @DomName('WebGLRenderingContext.bindFramebuffer')
  void bindFramebuffer(int target, WebGLFramebuffer framebuffer) native;

  @DocsEditable @DomName('WebGLRenderingContext.bindRenderbuffer')
  void bindRenderbuffer(int target, WebGLRenderbuffer renderbuffer) native;

  @DocsEditable @DomName('WebGLRenderingContext.bindTexture')
  void bindTexture(int target, WebGLTexture texture) native;

  @DocsEditable @DomName('WebGLRenderingContext.blendColor')
  void blendColor(num red, num green, num blue, num alpha) native;

  @DocsEditable @DomName('WebGLRenderingContext.blendEquation')
  void blendEquation(int mode) native;

  @DocsEditable @DomName('WebGLRenderingContext.blendEquationSeparate')
  void blendEquationSeparate(int modeRGB, int modeAlpha) native;

  @DocsEditable @DomName('WebGLRenderingContext.blendFunc')
  void blendFunc(int sfactor, int dfactor) native;

  @DocsEditable @DomName('WebGLRenderingContext.blendFuncSeparate')
  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) native;

  @DocsEditable @DomName('WebGLRenderingContext.bufferData')
  void bufferData(int target, data_OR_size, int usage) native;

  @DocsEditable @DomName('WebGLRenderingContext.bufferSubData')
  void bufferSubData(int target, int offset, data) native;

  @DocsEditable @DomName('WebGLRenderingContext.checkFramebufferStatus')
  int checkFramebufferStatus(int target) native;

  @DocsEditable @DomName('WebGLRenderingContext.clear')
  void clear(int mask) native;

  @DocsEditable @DomName('WebGLRenderingContext.clearColor')
  void clearColor(num red, num green, num blue, num alpha) native;

  @DocsEditable @DomName('WebGLRenderingContext.clearDepth')
  void clearDepth(num depth) native;

  @DocsEditable @DomName('WebGLRenderingContext.clearStencil')
  void clearStencil(int s) native;

  @DocsEditable @DomName('WebGLRenderingContext.colorMask')
  void colorMask(bool red, bool green, bool blue, bool alpha) native;

  @DocsEditable @DomName('WebGLRenderingContext.compileShader')
  void compileShader(WebGLShader shader) native;

  @DocsEditable @DomName('WebGLRenderingContext.compressedTexImage2D')
  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, ArrayBufferView data) native;

  @DocsEditable @DomName('WebGLRenderingContext.compressedTexSubImage2D')
  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, ArrayBufferView data) native;

  @DocsEditable @DomName('WebGLRenderingContext.copyTexImage2D')
  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border) native;

  @DocsEditable @DomName('WebGLRenderingContext.copyTexSubImage2D')
  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height) native;

  @DocsEditable @DomName('WebGLRenderingContext.createBuffer')
  WebGLBuffer createBuffer() native;

  @DocsEditable @DomName('WebGLRenderingContext.createFramebuffer')
  WebGLFramebuffer createFramebuffer() native;

  @DocsEditable @DomName('WebGLRenderingContext.createProgram')
  WebGLProgram createProgram() native;

  @DocsEditable @DomName('WebGLRenderingContext.createRenderbuffer')
  WebGLRenderbuffer createRenderbuffer() native;

  @DocsEditable @DomName('WebGLRenderingContext.createShader')
  WebGLShader createShader(int type) native;

  @DocsEditable @DomName('WebGLRenderingContext.createTexture')
  WebGLTexture createTexture() native;

  @DocsEditable @DomName('WebGLRenderingContext.cullFace')
  void cullFace(int mode) native;

  @DocsEditable @DomName('WebGLRenderingContext.deleteBuffer')
  void deleteBuffer(WebGLBuffer buffer) native;

  @DocsEditable @DomName('WebGLRenderingContext.deleteFramebuffer')
  void deleteFramebuffer(WebGLFramebuffer framebuffer) native;

  @DocsEditable @DomName('WebGLRenderingContext.deleteProgram')
  void deleteProgram(WebGLProgram program) native;

  @DocsEditable @DomName('WebGLRenderingContext.deleteRenderbuffer')
  void deleteRenderbuffer(WebGLRenderbuffer renderbuffer) native;

  @DocsEditable @DomName('WebGLRenderingContext.deleteShader')
  void deleteShader(WebGLShader shader) native;

  @DocsEditable @DomName('WebGLRenderingContext.deleteTexture')
  void deleteTexture(WebGLTexture texture) native;

  @DocsEditable @DomName('WebGLRenderingContext.depthFunc')
  void depthFunc(int func) native;

  @DocsEditable @DomName('WebGLRenderingContext.depthMask')
  void depthMask(bool flag) native;

  @DocsEditable @DomName('WebGLRenderingContext.depthRange')
  void depthRange(num zNear, num zFar) native;

  @DocsEditable @DomName('WebGLRenderingContext.detachShader')
  void detachShader(WebGLProgram program, WebGLShader shader) native;

  @DocsEditable @DomName('WebGLRenderingContext.disable')
  void disable(int cap) native;

  @DocsEditable @DomName('WebGLRenderingContext.disableVertexAttribArray')
  void disableVertexAttribArray(int index) native;

  @DocsEditable @DomName('WebGLRenderingContext.drawArrays')
  void drawArrays(int mode, int first, int count) native;

  @DocsEditable @DomName('WebGLRenderingContext.drawElements')
  void drawElements(int mode, int count, int type, int offset) native;

  @DocsEditable @DomName('WebGLRenderingContext.enable')
  void enable(int cap) native;

  @DocsEditable @DomName('WebGLRenderingContext.enableVertexAttribArray')
  void enableVertexAttribArray(int index) native;

  @DocsEditable @DomName('WebGLRenderingContext.finish')
  void finish() native;

  @DocsEditable @DomName('WebGLRenderingContext.flush')
  void flush() native;

  @DocsEditable @DomName('WebGLRenderingContext.framebufferRenderbuffer')
  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, WebGLRenderbuffer renderbuffer) native;

  @DocsEditable @DomName('WebGLRenderingContext.framebufferTexture2D')
  void framebufferTexture2D(int target, int attachment, int textarget, WebGLTexture texture, int level) native;

  @DocsEditable @DomName('WebGLRenderingContext.frontFace')
  void frontFace(int mode) native;

  @DocsEditable @DomName('WebGLRenderingContext.generateMipmap')
  void generateMipmap(int target) native;

  @DocsEditable @DomName('WebGLRenderingContext.getActiveAttrib')
  WebGLActiveInfo getActiveAttrib(WebGLProgram program, int index) native;

  @DocsEditable @DomName('WebGLRenderingContext.getActiveUniform')
  WebGLActiveInfo getActiveUniform(WebGLProgram program, int index) native;

  @DocsEditable @DomName('WebGLRenderingContext.getAttachedShaders')
  void getAttachedShaders(WebGLProgram program) native;

  @DocsEditable @DomName('WebGLRenderingContext.getAttribLocation')
  int getAttribLocation(WebGLProgram program, String name) native;

  @DocsEditable @DomName('WebGLRenderingContext.getBufferParameter')
  Object getBufferParameter(int target, int pname) native;

  @DocsEditable @DomName('WebGLRenderingContext.getContextAttributes')
  WebGLContextAttributes getContextAttributes() native;

  @DocsEditable @DomName('WebGLRenderingContext.getError')
  int getError() native;

  @DocsEditable @DomName('WebGLRenderingContext.getExtension')
  Object getExtension(String name) native;

  @DocsEditable @DomName('WebGLRenderingContext.getFramebufferAttachmentParameter')
  Object getFramebufferAttachmentParameter(int target, int attachment, int pname) native;

  @DocsEditable @DomName('WebGLRenderingContext.getParameter')
  Object getParameter(int pname) native;

  @DocsEditable @DomName('WebGLRenderingContext.getProgramInfoLog')
  String getProgramInfoLog(WebGLProgram program) native;

  @DocsEditable @DomName('WebGLRenderingContext.getProgramParameter')
  Object getProgramParameter(WebGLProgram program, int pname) native;

  @DocsEditable @DomName('WebGLRenderingContext.getRenderbufferParameter')
  Object getRenderbufferParameter(int target, int pname) native;

  @DocsEditable @DomName('WebGLRenderingContext.getShaderInfoLog')
  String getShaderInfoLog(WebGLShader shader) native;

  @DocsEditable @DomName('WebGLRenderingContext.getShaderParameter')
  Object getShaderParameter(WebGLShader shader, int pname) native;

  @DocsEditable @DomName('WebGLRenderingContext.getShaderPrecisionFormat')
  WebGLShaderPrecisionFormat getShaderPrecisionFormat(int shadertype, int precisiontype) native;

  @DocsEditable @DomName('WebGLRenderingContext.getShaderSource')
  String getShaderSource(WebGLShader shader) native;

  @DocsEditable @DomName('WebGLRenderingContext.getSupportedExtensions')
  List<String> getSupportedExtensions() native;

  @DocsEditable @DomName('WebGLRenderingContext.getTexParameter')
  Object getTexParameter(int target, int pname) native;

  @DocsEditable @DomName('WebGLRenderingContext.getUniform')
  Object getUniform(WebGLProgram program, WebGLUniformLocation location) native;

  @DocsEditable @DomName('WebGLRenderingContext.getUniformLocation')
  WebGLUniformLocation getUniformLocation(WebGLProgram program, String name) native;

  @DocsEditable @DomName('WebGLRenderingContext.getVertexAttrib')
  Object getVertexAttrib(int index, int pname) native;

  @DocsEditable @DomName('WebGLRenderingContext.getVertexAttribOffset')
  int getVertexAttribOffset(int index, int pname) native;

  @DocsEditable @DomName('WebGLRenderingContext.hint')
  void hint(int target, int mode) native;

  @DocsEditable @DomName('WebGLRenderingContext.isBuffer')
  bool isBuffer(WebGLBuffer buffer) native;

  @DocsEditable @DomName('WebGLRenderingContext.isContextLost')
  bool isContextLost() native;

  @DocsEditable @DomName('WebGLRenderingContext.isEnabled')
  bool isEnabled(int cap) native;

  @DocsEditable @DomName('WebGLRenderingContext.isFramebuffer')
  bool isFramebuffer(WebGLFramebuffer framebuffer) native;

  @DocsEditable @DomName('WebGLRenderingContext.isProgram')
  bool isProgram(WebGLProgram program) native;

  @DocsEditable @DomName('WebGLRenderingContext.isRenderbuffer')
  bool isRenderbuffer(WebGLRenderbuffer renderbuffer) native;

  @DocsEditable @DomName('WebGLRenderingContext.isShader')
  bool isShader(WebGLShader shader) native;

  @DocsEditable @DomName('WebGLRenderingContext.isTexture')
  bool isTexture(WebGLTexture texture) native;

  @DocsEditable @DomName('WebGLRenderingContext.lineWidth')
  void lineWidth(num width) native;

  @DocsEditable @DomName('WebGLRenderingContext.linkProgram')
  void linkProgram(WebGLProgram program) native;

  @DocsEditable @DomName('WebGLRenderingContext.pixelStorei')
  void pixelStorei(int pname, int param) native;

  @DocsEditable @DomName('WebGLRenderingContext.polygonOffset')
  void polygonOffset(num factor, num units) native;

  @DocsEditable @DomName('WebGLRenderingContext.readPixels')
  void readPixels(int x, int y, int width, int height, int format, int type, ArrayBufferView pixels) native;

  @DocsEditable @DomName('WebGLRenderingContext.releaseShaderCompiler')
  void releaseShaderCompiler() native;

  @DocsEditable @DomName('WebGLRenderingContext.renderbufferStorage')
  void renderbufferStorage(int target, int internalformat, int width, int height) native;

  @DocsEditable @DomName('WebGLRenderingContext.sampleCoverage')
  void sampleCoverage(num value, bool invert) native;

  @DocsEditable @DomName('WebGLRenderingContext.scissor')
  void scissor(int x, int y, int width, int height) native;

  @DocsEditable @DomName('WebGLRenderingContext.shaderSource')
  void shaderSource(WebGLShader shader, String string) native;

  @DocsEditable @DomName('WebGLRenderingContext.stencilFunc')
  void stencilFunc(int func, int ref, int mask) native;

  @DocsEditable @DomName('WebGLRenderingContext.stencilFuncSeparate')
  void stencilFuncSeparate(int face, int func, int ref, int mask) native;

  @DocsEditable @DomName('WebGLRenderingContext.stencilMask')
  void stencilMask(int mask) native;

  @DocsEditable @DomName('WebGLRenderingContext.stencilMaskSeparate')
  void stencilMaskSeparate(int face, int mask) native;

  @DocsEditable @DomName('WebGLRenderingContext.stencilOp')
  void stencilOp(int fail, int zfail, int zpass) native;

  @DocsEditable @DomName('WebGLRenderingContext.stencilOpSeparate')
  void stencilOpSeparate(int face, int fail, int zfail, int zpass) native;

  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, [int format, int type, ArrayBufferView pixels]) {
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is int || border_OR_canvas_OR_image_OR_pixels_OR_video == null)) {
      _texImage2D_1(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is ImageData || border_OR_canvas_OR_image_OR_pixels_OR_video == null) &&
        !?format &&
        !?type &&
        !?pixels) {
      var pixels_1 = _convertDartToNative_ImageData(border_OR_canvas_OR_image_OR_pixels_OR_video);
      _texImage2D_2(target, level, internalformat, format_OR_width, height_OR_type, pixels_1);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is ImageElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) &&
        !?format &&
        !?type &&
        !?pixels) {
      _texImage2D_3(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is CanvasElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) &&
        !?format &&
        !?type &&
        !?pixels) {
      _texImage2D_4(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is VideoElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) &&
        !?format &&
        !?type &&
        !?pixels) {
      _texImage2D_5(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('texImage2D')
  @DocsEditable @DomName('WebGLRenderingContext.texImage2D')
  void _texImage2D_1(target, level, internalformat, width, height, int border, format, type, ArrayBufferView pixels) native;
  @JSName('texImage2D')
  @DocsEditable @DomName('WebGLRenderingContext.texImage2D')
  void _texImage2D_2(target, level, internalformat, format, type, pixels) native;
  @JSName('texImage2D')
  @DocsEditable @DomName('WebGLRenderingContext.texImage2D')
  void _texImage2D_3(target, level, internalformat, format, type, ImageElement image) native;
  @JSName('texImage2D')
  @DocsEditable @DomName('WebGLRenderingContext.texImage2D')
  void _texImage2D_4(target, level, internalformat, format, type, CanvasElement canvas) native;
  @JSName('texImage2D')
  @DocsEditable @DomName('WebGLRenderingContext.texImage2D')
  void _texImage2D_5(target, level, internalformat, format, type, VideoElement video) native;

  @DocsEditable @DomName('WebGLRenderingContext.texParameterf')
  void texParameterf(int target, int pname, num param) native;

  @DocsEditable @DomName('WebGLRenderingContext.texParameteri')
  void texParameteri(int target, int pname, int param) native;

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, [int type, ArrayBufferView pixels]) {
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is int || canvas_OR_format_OR_image_OR_pixels_OR_video == null)) {
      _texSubImage2D_1(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is ImageData || canvas_OR_format_OR_image_OR_pixels_OR_video == null) &&
        !?type &&
        !?pixels) {
      var pixels_1 = _convertDartToNative_ImageData(canvas_OR_format_OR_image_OR_pixels_OR_video);
      _texSubImage2D_2(target, level, xoffset, yoffset, format_OR_width, height_OR_type, pixels_1);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is ImageElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) &&
        !?type &&
        !?pixels) {
      _texSubImage2D_3(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is CanvasElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) &&
        !?type &&
        !?pixels) {
      _texSubImage2D_4(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is VideoElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) &&
        !?type &&
        !?pixels) {
      _texSubImage2D_5(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('texSubImage2D')
  @DocsEditable @DomName('WebGLRenderingContext.texSubImage2D')
  void _texSubImage2D_1(target, level, xoffset, yoffset, width, height, int format, type, ArrayBufferView pixels) native;
  @JSName('texSubImage2D')
  @DocsEditable @DomName('WebGLRenderingContext.texSubImage2D')
  void _texSubImage2D_2(target, level, xoffset, yoffset, format, type, pixels) native;
  @JSName('texSubImage2D')
  @DocsEditable @DomName('WebGLRenderingContext.texSubImage2D')
  void _texSubImage2D_3(target, level, xoffset, yoffset, format, type, ImageElement image) native;
  @JSName('texSubImage2D')
  @DocsEditable @DomName('WebGLRenderingContext.texSubImage2D')
  void _texSubImage2D_4(target, level, xoffset, yoffset, format, type, CanvasElement canvas) native;
  @JSName('texSubImage2D')
  @DocsEditable @DomName('WebGLRenderingContext.texSubImage2D')
  void _texSubImage2D_5(target, level, xoffset, yoffset, format, type, VideoElement video) native;

  @DocsEditable @DomName('WebGLRenderingContext.uniform1f')
  void uniform1f(WebGLUniformLocation location, num x) native;

  @DocsEditable @DomName('WebGLRenderingContext.uniform1fv')
  void uniform1fv(WebGLUniformLocation location, Float32Array v) native;

  @DocsEditable @DomName('WebGLRenderingContext.uniform1i')
  void uniform1i(WebGLUniformLocation location, int x) native;

  @DocsEditable @DomName('WebGLRenderingContext.uniform1iv')
  void uniform1iv(WebGLUniformLocation location, Int32Array v) native;

  @DocsEditable @DomName('WebGLRenderingContext.uniform2f')
  void uniform2f(WebGLUniformLocation location, num x, num y) native;

  @DocsEditable @DomName('WebGLRenderingContext.uniform2fv')
  void uniform2fv(WebGLUniformLocation location, Float32Array v) native;

  @DocsEditable @DomName('WebGLRenderingContext.uniform2i')
  void uniform2i(WebGLUniformLocation location, int x, int y) native;

  @DocsEditable @DomName('WebGLRenderingContext.uniform2iv')
  void uniform2iv(WebGLUniformLocation location, Int32Array v) native;

  @DocsEditable @DomName('WebGLRenderingContext.uniform3f')
  void uniform3f(WebGLUniformLocation location, num x, num y, num z) native;

  @DocsEditable @DomName('WebGLRenderingContext.uniform3fv')
  void uniform3fv(WebGLUniformLocation location, Float32Array v) native;

  @DocsEditable @DomName('WebGLRenderingContext.uniform3i')
  void uniform3i(WebGLUniformLocation location, int x, int y, int z) native;

  @DocsEditable @DomName('WebGLRenderingContext.uniform3iv')
  void uniform3iv(WebGLUniformLocation location, Int32Array v) native;

  @DocsEditable @DomName('WebGLRenderingContext.uniform4f')
  void uniform4f(WebGLUniformLocation location, num x, num y, num z, num w) native;

  @DocsEditable @DomName('WebGLRenderingContext.uniform4fv')
  void uniform4fv(WebGLUniformLocation location, Float32Array v) native;

  @DocsEditable @DomName('WebGLRenderingContext.uniform4i')
  void uniform4i(WebGLUniformLocation location, int x, int y, int z, int w) native;

  @DocsEditable @DomName('WebGLRenderingContext.uniform4iv')
  void uniform4iv(WebGLUniformLocation location, Int32Array v) native;

  @DocsEditable @DomName('WebGLRenderingContext.uniformMatrix2fv')
  void uniformMatrix2fv(WebGLUniformLocation location, bool transpose, Float32Array array) native;

  @DocsEditable @DomName('WebGLRenderingContext.uniformMatrix3fv')
  void uniformMatrix3fv(WebGLUniformLocation location, bool transpose, Float32Array array) native;

  @DocsEditable @DomName('WebGLRenderingContext.uniformMatrix4fv')
  void uniformMatrix4fv(WebGLUniformLocation location, bool transpose, Float32Array array) native;

  @DocsEditable @DomName('WebGLRenderingContext.useProgram')
  void useProgram(WebGLProgram program) native;

  @DocsEditable @DomName('WebGLRenderingContext.validateProgram')
  void validateProgram(WebGLProgram program) native;

  @DocsEditable @DomName('WebGLRenderingContext.vertexAttrib1f')
  void vertexAttrib1f(int indx, num x) native;

  @DocsEditable @DomName('WebGLRenderingContext.vertexAttrib1fv')
  void vertexAttrib1fv(int indx, Float32Array values) native;

  @DocsEditable @DomName('WebGLRenderingContext.vertexAttrib2f')
  void vertexAttrib2f(int indx, num x, num y) native;

  @DocsEditable @DomName('WebGLRenderingContext.vertexAttrib2fv')
  void vertexAttrib2fv(int indx, Float32Array values) native;

  @DocsEditable @DomName('WebGLRenderingContext.vertexAttrib3f')
  void vertexAttrib3f(int indx, num x, num y, num z) native;

  @DocsEditable @DomName('WebGLRenderingContext.vertexAttrib3fv')
  void vertexAttrib3fv(int indx, Float32Array values) native;

  @DocsEditable @DomName('WebGLRenderingContext.vertexAttrib4f')
  void vertexAttrib4f(int indx, num x, num y, num z, num w) native;

  @DocsEditable @DomName('WebGLRenderingContext.vertexAttrib4fv')
  void vertexAttrib4fv(int indx, Float32Array values) native;

  @DocsEditable @DomName('WebGLRenderingContext.vertexAttribPointer')
  void vertexAttribPointer(int indx, int size, int type, bool normalized, int stride, int offset) native;

  @DocsEditable @DomName('WebGLRenderingContext.viewport')
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

  @DocsEditable @DomName('WebGLShaderPrecisionFormat.precision')
  final int precision;

  @DocsEditable @DomName('WebGLShaderPrecisionFormat.rangeMax')
  final int rangeMax;

  @DocsEditable @DomName('WebGLShaderPrecisionFormat.rangeMin')
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

  @DocsEditable @DomName('WebKitCSSFilterValue.operationType')
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

  @DocsEditable @DomName('WebKitNamedFlow.firstEmptyRegionIndex')
  final int firstEmptyRegionIndex;

  @DocsEditable @DomName('WebKitNamedFlow.name')
  final String name;

  @DocsEditable @DomName('WebKitNamedFlow.overset')
  final bool overset;

  @JSName('addEventListener')
  @DocsEditable @DomName('WebKitNamedFlow.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('WebKitNamedFlow.dispatchEvent')
  bool $dom_dispatchEvent(Event event) native;

  @DocsEditable @DomName('WebKitNamedFlow.getContent')
  @Returns('NodeList') @Creates('NodeList')
  List<Node> getContent() native;

  @DocsEditable @DomName('WebKitNamedFlow.getRegions')
  @Returns('NodeList') @Creates('NodeList')
  List<Node> getRegions() native;

  @DocsEditable @DomName('WebKitNamedFlow.getRegionsByContent')
  @Returns('NodeList') @Creates('NodeList')
  List<Node> getRegionsByContent(Node contentNode) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('WebKitNamedFlow.removeEventListener')
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

  static const EventStreamProvider<CloseEvent> closeEvent = const EventStreamProvider<CloseEvent>('close');

  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  static const EventStreamProvider<MessageEvent> messageEvent = const EventStreamProvider<MessageEvent>('message');

  static const EventStreamProvider<Event> openEvent = const EventStreamProvider<Event>('open');

  @DocsEditable
  factory WebSocket(String url) => WebSocket._create(url);
  static WebSocket _create(String url) => JS('WebSocket', 'new WebSocket(#)', url);

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', 'typeof window.WebSocket != "undefined"');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  WebSocketEvents get on =>
    new WebSocketEvents(this);

  static const int CLOSED = 3;

  static const int CLOSING = 2;

  static const int CONNECTING = 0;

  static const int OPEN = 1;

  @JSName('URL')
  @DocsEditable @DomName('WebSocket.URL')
  final String Url;

  @DocsEditable @DomName('WebSocket.binaryType')
  String binaryType;

  @DocsEditable @DomName('WebSocket.bufferedAmount')
  final int bufferedAmount;

  @DocsEditable @DomName('WebSocket.extensions')
  final String extensions;

  @DocsEditable @DomName('WebSocket.protocol')
  final String protocol;

  @DocsEditable @DomName('WebSocket.readyState')
  final int readyState;

  @DocsEditable @DomName('WebSocket.url')
  final String url;

  @JSName('addEventListener')
  @DocsEditable @DomName('WebSocket.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('WebSocket.close')
  void close([int code, String reason]) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('WebSocket.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('WebSocket.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('WebSocket.send')
  void send(data) native;

  Stream<CloseEvent> get onClose => closeEvent.forTarget(this);

  Stream<Event> get onError => errorEvent.forTarget(this);

  Stream<MessageEvent> get onMessage => messageEvent.forTarget(this);

  Stream<Event> get onOpen => openEvent.forTarget(this);
}

@DocsEditable
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


@DocsEditable
@DomName('WheelEvent')
class WheelEvent extends MouseEvent native "*WheelEvent" {

  @DocsEditable @DomName('WheelEvent.webkitDirectionInvertedFromDevice')
  final bool webkitDirectionInvertedFromDevice;

  @DocsEditable @DomName('WheelEvent.initWebKitWheelEvent')
  void initWebKitWheelEvent(int wheelDeltaX, int wheelDeltaY, Window view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;


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
      if (JS('bool', '#.axis !== undefined && #.axis == MouseScrollEvent.HORIZONTAL_AXIS', this, this)) {
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

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
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
   * Executes a [callback] after the next batch of browser layout measurements
   * has completed or would have completed if any browser layout measurements
   * had been scheduled.
   */
  void requestLayoutFrame(TimeoutHandler callback) {
    _addMeasurementFrameCallback(callback);
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
  @Experimental()
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

  @DocsEditable
  @DomName('Window.console')
  Console get console => Console.safeConsole;


  static const EventStreamProvider<Event> contentLoadedEvent = const EventStreamProvider<Event>('DOMContentLoaded');

  static const EventStreamProvider<Event> abortEvent = const EventStreamProvider<Event>('abort');

  static const EventStreamProvider<Event> beforeUnloadEvent = const EventStreamProvider<Event>('beforeunload');

  static const EventStreamProvider<Event> blurEvent = const EventStreamProvider<Event>('blur');

  static const EventStreamProvider<Event> canPlayEvent = const EventStreamProvider<Event>('canplay');

  static const EventStreamProvider<Event> canPlayThroughEvent = const EventStreamProvider<Event>('canplaythrough');

  static const EventStreamProvider<Event> changeEvent = const EventStreamProvider<Event>('change');

  static const EventStreamProvider<MouseEvent> clickEvent = const EventStreamProvider<MouseEvent>('click');

  static const EventStreamProvider<MouseEvent> contextMenuEvent = const EventStreamProvider<MouseEvent>('contextmenu');

  static const EventStreamProvider<Event> doubleClickEvent = const EventStreamProvider<Event>('dblclick');

  static const EventStreamProvider<DeviceMotionEvent> deviceMotionEvent = const EventStreamProvider<DeviceMotionEvent>('devicemotion');

  static const EventStreamProvider<DeviceOrientationEvent> deviceOrientationEvent = const EventStreamProvider<DeviceOrientationEvent>('deviceorientation');

  static const EventStreamProvider<MouseEvent> dragEvent = const EventStreamProvider<MouseEvent>('drag');

  static const EventStreamProvider<MouseEvent> dragEndEvent = const EventStreamProvider<MouseEvent>('dragend');

  static const EventStreamProvider<MouseEvent> dragEnterEvent = const EventStreamProvider<MouseEvent>('dragenter');

  static const EventStreamProvider<MouseEvent> dragLeaveEvent = const EventStreamProvider<MouseEvent>('dragleave');

  static const EventStreamProvider<MouseEvent> dragOverEvent = const EventStreamProvider<MouseEvent>('dragover');

  static const EventStreamProvider<MouseEvent> dragStartEvent = const EventStreamProvider<MouseEvent>('dragstart');

  static const EventStreamProvider<MouseEvent> dropEvent = const EventStreamProvider<MouseEvent>('drop');

  static const EventStreamProvider<Event> durationChangeEvent = const EventStreamProvider<Event>('durationchange');

  static const EventStreamProvider<Event> emptiedEvent = const EventStreamProvider<Event>('emptied');

  static const EventStreamProvider<Event> endedEvent = const EventStreamProvider<Event>('ended');

  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  static const EventStreamProvider<Event> focusEvent = const EventStreamProvider<Event>('focus');

  static const EventStreamProvider<HashChangeEvent> hashChangeEvent = const EventStreamProvider<HashChangeEvent>('hashchange');

  static const EventStreamProvider<Event> inputEvent = const EventStreamProvider<Event>('input');

  static const EventStreamProvider<Event> invalidEvent = const EventStreamProvider<Event>('invalid');

  static const EventStreamProvider<KeyboardEvent> keyDownEvent = const EventStreamProvider<KeyboardEvent>('keydown');

  static const EventStreamProvider<KeyboardEvent> keyPressEvent = const EventStreamProvider<KeyboardEvent>('keypress');

  static const EventStreamProvider<KeyboardEvent> keyUpEvent = const EventStreamProvider<KeyboardEvent>('keyup');

  static const EventStreamProvider<Event> loadEvent = const EventStreamProvider<Event>('load');

  static const EventStreamProvider<Event> loadedDataEvent = const EventStreamProvider<Event>('loadeddata');

  static const EventStreamProvider<Event> loadedMetadataEvent = const EventStreamProvider<Event>('loadedmetadata');

  static const EventStreamProvider<Event> loadStartEvent = const EventStreamProvider<Event>('loadstart');

  static const EventStreamProvider<MessageEvent> messageEvent = const EventStreamProvider<MessageEvent>('message');

  static const EventStreamProvider<MouseEvent> mouseDownEvent = const EventStreamProvider<MouseEvent>('mousedown');

  static const EventStreamProvider<MouseEvent> mouseMoveEvent = const EventStreamProvider<MouseEvent>('mousemove');

  static const EventStreamProvider<MouseEvent> mouseOutEvent = const EventStreamProvider<MouseEvent>('mouseout');

  static const EventStreamProvider<MouseEvent> mouseOverEvent = const EventStreamProvider<MouseEvent>('mouseover');

  static const EventStreamProvider<MouseEvent> mouseUpEvent = const EventStreamProvider<MouseEvent>('mouseup');

  static const EventStreamProvider<WheelEvent> mouseWheelEvent = const EventStreamProvider<WheelEvent>('mousewheel');

  static const EventStreamProvider<Event> offlineEvent = const EventStreamProvider<Event>('offline');

  static const EventStreamProvider<Event> onlineEvent = const EventStreamProvider<Event>('online');

  static const EventStreamProvider<Event> pageHideEvent = const EventStreamProvider<Event>('pagehide');

  static const EventStreamProvider<Event> pageShowEvent = const EventStreamProvider<Event>('pageshow');

  static const EventStreamProvider<Event> pauseEvent = const EventStreamProvider<Event>('pause');

  static const EventStreamProvider<Event> playEvent = const EventStreamProvider<Event>('play');

  static const EventStreamProvider<Event> playingEvent = const EventStreamProvider<Event>('playing');

  static const EventStreamProvider<PopStateEvent> popStateEvent = const EventStreamProvider<PopStateEvent>('popstate');

  static const EventStreamProvider<Event> progressEvent = const EventStreamProvider<Event>('progress');

  static const EventStreamProvider<Event> rateChangeEvent = const EventStreamProvider<Event>('ratechange');

  static const EventStreamProvider<Event> resetEvent = const EventStreamProvider<Event>('reset');

  static const EventStreamProvider<Event> resizeEvent = const EventStreamProvider<Event>('resize');

  static const EventStreamProvider<Event> scrollEvent = const EventStreamProvider<Event>('scroll');

  static const EventStreamProvider<Event> searchEvent = const EventStreamProvider<Event>('search');

  static const EventStreamProvider<Event> seekedEvent = const EventStreamProvider<Event>('seeked');

  static const EventStreamProvider<Event> seekingEvent = const EventStreamProvider<Event>('seeking');

  static const EventStreamProvider<Event> selectEvent = const EventStreamProvider<Event>('select');

  static const EventStreamProvider<Event> stalledEvent = const EventStreamProvider<Event>('stalled');

  static const EventStreamProvider<StorageEvent> storageEvent = const EventStreamProvider<StorageEvent>('storage');

  static const EventStreamProvider<Event> submitEvent = const EventStreamProvider<Event>('submit');

  static const EventStreamProvider<Event> suspendEvent = const EventStreamProvider<Event>('suspend');

  static const EventStreamProvider<Event> timeUpdateEvent = const EventStreamProvider<Event>('timeupdate');

  static const EventStreamProvider<TouchEvent> touchCancelEvent = const EventStreamProvider<TouchEvent>('touchcancel');

  static const EventStreamProvider<TouchEvent> touchEndEvent = const EventStreamProvider<TouchEvent>('touchend');

  static const EventStreamProvider<TouchEvent> touchMoveEvent = const EventStreamProvider<TouchEvent>('touchmove');

  static const EventStreamProvider<TouchEvent> touchStartEvent = const EventStreamProvider<TouchEvent>('touchstart');

  static const EventStreamProvider<Event> unloadEvent = const EventStreamProvider<Event>('unload');

  static const EventStreamProvider<Event> volumeChangeEvent = const EventStreamProvider<Event>('volumechange');

  static const EventStreamProvider<Event> waitingEvent = const EventStreamProvider<Event>('waiting');

  static const EventStreamProvider<AnimationEvent> animationEndEvent = const EventStreamProvider<AnimationEvent>('webkitAnimationEnd');

  static const EventStreamProvider<AnimationEvent> animationIterationEvent = const EventStreamProvider<AnimationEvent>('webkitAnimationIteration');

  static const EventStreamProvider<AnimationEvent> animationStartEvent = const EventStreamProvider<AnimationEvent>('webkitAnimationStart');

  static const EventStreamProvider<TransitionEvent> transitionEndEvent = const EventStreamProvider<TransitionEvent>('webkitTransitionEnd');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  WindowEvents get on =>
    new WindowEvents(this);

  static const int PERSISTENT = 1;

  static const int TEMPORARY = 0;

  @DocsEditable @DomName('DOMWindow.applicationCache')
  final ApplicationCache applicationCache;

  @DocsEditable @DomName('DOMWindow.closed')
  final bool closed;

  @DocsEditable @DomName('DOMWindow.crypto')
  final Crypto crypto;

  @DocsEditable @DomName('DOMWindow.defaultStatus')
  String defaultStatus;

  @DocsEditable @DomName('DOMWindow.defaultstatus')
  String defaultstatus;

  @DocsEditable @DomName('DOMWindow.devicePixelRatio')
  final num devicePixelRatio;

  @DocsEditable @DomName('DOMWindow.event')
  final Event event;

  @DocsEditable @DomName('DOMWindow.history')
  final History history;

  @DocsEditable @DomName('DOMWindow.innerHeight')
  final int innerHeight;

  @DocsEditable @DomName('DOMWindow.innerWidth')
  final int innerWidth;

  @DocsEditable @DomName('DOMWindow.localStorage')
  final Storage localStorage;

  @DocsEditable @DomName('DOMWindow.locationbar')
  final BarInfo locationbar;

  @DocsEditable @DomName('DOMWindow.menubar')
  final BarInfo menubar;

  @DocsEditable @DomName('DOMWindow.name')
  String name;

  @DocsEditable @DomName('DOMWindow.navigator')
  final Navigator navigator;

  @DocsEditable @DomName('DOMWindow.offscreenBuffering')
  final bool offscreenBuffering;

  WindowBase get opener => _convertNativeToDart_Window(this._opener);
  @JSName('opener')
  @DocsEditable @DomName('DOMWindow.opener') @Creates('Window|=Object') @Returns('Window|=Object')
  final dynamic _opener;

  @DocsEditable @DomName('DOMWindow.outerHeight')
  final int outerHeight;

  @DocsEditable @DomName('DOMWindow.outerWidth')
  final int outerWidth;

  @DocsEditable @DomName('DOMWindow.pagePopupController')
  final PagePopupController pagePopupController;

  @DocsEditable @DomName('DOMWindow.pageXOffset')
  final int pageXOffset;

  @DocsEditable @DomName('DOMWindow.pageYOffset')
  final int pageYOffset;

  WindowBase get parent => _convertNativeToDart_Window(this._parent);
  @JSName('parent')
  @DocsEditable @DomName('DOMWindow.parent') @Creates('Window|=Object') @Returns('Window|=Object')
  final dynamic _parent;

  @DocsEditable @DomName('DOMWindow.performance') @SupportedBrowser(SupportedBrowser.CHROME) @SupportedBrowser(SupportedBrowser.FIREFOX) @SupportedBrowser(SupportedBrowser.IE)
  final Performance performance;

  @DocsEditable @DomName('DOMWindow.personalbar')
  final BarInfo personalbar;

  @DocsEditable @DomName('DOMWindow.screen')
  final Screen screen;

  @DocsEditable @DomName('DOMWindow.screenLeft')
  final int screenLeft;

  @DocsEditable @DomName('DOMWindow.screenTop')
  final int screenTop;

  @DocsEditable @DomName('DOMWindow.screenX')
  final int screenX;

  @DocsEditable @DomName('DOMWindow.screenY')
  final int screenY;

  @DocsEditable @DomName('DOMWindow.scrollX')
  final int scrollX;

  @DocsEditable @DomName('DOMWindow.scrollY')
  final int scrollY;

  @DocsEditable @DomName('DOMWindow.scrollbars')
  final BarInfo scrollbars;

  WindowBase get self => _convertNativeToDart_Window(this._self);
  @JSName('self')
  @DocsEditable @DomName('DOMWindow.self') @Creates('Window|=Object') @Returns('Window|=Object')
  final dynamic _self;

  @DocsEditable @DomName('DOMWindow.sessionStorage')
  final Storage sessionStorage;

  @DocsEditable @DomName('DOMWindow.status')
  String status;

  @DocsEditable @DomName('DOMWindow.statusbar')
  final BarInfo statusbar;

  @DocsEditable @DomName('DOMWindow.styleMedia')
  final StyleMedia styleMedia;

  @DocsEditable @DomName('DOMWindow.toolbar')
  final BarInfo toolbar;

  WindowBase get top => _convertNativeToDart_Window(this._top);
  @JSName('top')
  @DocsEditable @DomName('DOMWindow.top') @Creates('Window|=Object') @Returns('Window|=Object')
  final dynamic _top;

  @JSName('webkitNotifications')
  @DocsEditable @DomName('DOMWindow.webkitNotifications') @SupportedBrowser(SupportedBrowser.CHROME) @SupportedBrowser(SupportedBrowser.SAFARI) @Experimental()
  final NotificationCenter notifications;

  @DocsEditable @DomName('DOMWindow.webkitStorageInfo')
  final StorageInfo webkitStorageInfo;

  WindowBase get window => _convertNativeToDart_Window(this._window);
  @JSName('window')
  @DocsEditable @DomName('DOMWindow.window') @Creates('Window|=Object') @Returns('Window|=Object')
  final dynamic _window;

  @JSName('addEventListener')
  @DocsEditable @DomName('DOMWindow.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('DOMWindow.alert')
  void alert(String message) native;

  @DocsEditable @DomName('DOMWindow.atob')
  String atob(String string) native;

  @DocsEditable @DomName('DOMWindow.btoa')
  String btoa(String string) native;

  @DocsEditable @DomName('DOMWindow.captureEvents')
  void captureEvents() native;

  @DocsEditable @DomName('DOMWindow.clearInterval')
  void clearInterval(int handle) native;

  @DocsEditable @DomName('DOMWindow.clearTimeout')
  void clearTimeout(int handle) native;

  @DocsEditable @DomName('DOMWindow.close')
  void close() native;

  @DocsEditable @DomName('DOMWindow.confirm')
  bool confirm(String message) native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('DOMWindow.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  @DocsEditable @DomName('DOMWindow.find')
  bool find(String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog) native;

  @JSName('getComputedStyle')
  @DocsEditable @DomName('DOMWindow.getComputedStyle')
  CssStyleDeclaration $dom_getComputedStyle(Element element, String pseudoElement) native;

  @JSName('getMatchedCSSRules')
  @DocsEditable @DomName('DOMWindow.getMatchedCSSRules')
  @Returns('_CssRuleList') @Creates('_CssRuleList')
  List<CssRule> getMatchedCssRules(Element element, String pseudoElement) native;

  @DocsEditable @DomName('DOMWindow.getSelection')
  DomSelection getSelection() native;

  @DocsEditable @DomName('DOMWindow.matchMedia')
  MediaQueryList matchMedia(String query) native;

  @DocsEditable @DomName('DOMWindow.moveBy')
  void moveBy(num x, num y) native;

  @DocsEditable @DomName('DOMWindow.moveTo')
  void moveTo(num x, num y) native;

  @DocsEditable @DomName('DOMWindow.openDatabase') @Creates('Database') @Creates('DatabaseSync')
  Database openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]) native;

  void postMessage(/*SerializedScriptValue*/ message, String targetOrigin, [List messagePorts]) {
    if (?message &&
        !?messagePorts) {
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
  @DocsEditable @DomName('DOMWindow.postMessage')
  void _postMessage_1(message, targetOrigin) native;
  @JSName('postMessage')
  @DocsEditable @DomName('DOMWindow.postMessage')
  void _postMessage_2(message, targetOrigin, List messagePorts) native;

  @DocsEditable @DomName('DOMWindow.print')
  void print() native;

  @DocsEditable @DomName('DOMWindow.releaseEvents')
  void releaseEvents() native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('DOMWindow.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('DOMWindow.resizeBy')
  void resizeBy(num x, num y) native;

  @DocsEditable @DomName('DOMWindow.resizeTo')
  void resizeTo(num width, num height) native;

  @DocsEditable @DomName('DOMWindow.scroll')
  void scroll(int x, int y) native;

  @DocsEditable @DomName('DOMWindow.scrollBy')
  void scrollBy(int x, int y) native;

  @DocsEditable @DomName('DOMWindow.scrollTo')
  void scrollTo(int x, int y) native;

  @DocsEditable @DomName('DOMWindow.setInterval')
  int setInterval(TimeoutHandler handler, int timeout) native;

  @DocsEditable @DomName('DOMWindow.setTimeout')
  int setTimeout(TimeoutHandler handler, int timeout) native;

  @DocsEditable @DomName('DOMWindow.showModalDialog')
  Object showModalDialog(String url, [Object dialogArgs, String featureArgs]) native;

  @DocsEditable @DomName('DOMWindow.stop')
  void stop() native;

  @DocsEditable @DomName('DOMWindow.webkitConvertPointFromNodeToPage')
  Point webkitConvertPointFromNodeToPage(Node node, Point p) native;

  @DocsEditable @DomName('DOMWindow.webkitConvertPointFromPageToNode')
  Point webkitConvertPointFromPageToNode(Node node, Point p) native;

  @JSName('webkitRequestFileSystem')
  @DocsEditable @DomName('DOMWindow.webkitRequestFileSystem') @SupportedBrowser(SupportedBrowser.CHROME) @Experimental()
  void requestFileSystem(int type, int size, FileSystemCallback successCallback, [ErrorCallback errorCallback]) native;

  @JSName('webkitResolveLocalFileSystemURL')
  @DocsEditable @DomName('DOMWindow.webkitResolveLocalFileSystemURL') @SupportedBrowser(SupportedBrowser.CHROME) @Experimental()
  void resolveLocalFileSystemUrl(String url, EntryCallback successCallback, [ErrorCallback errorCallback]) native;

  Stream<Event> get onContentLoaded => contentLoadedEvent.forTarget(this);

  Stream<Event> get onAbort => abortEvent.forTarget(this);

  Stream<Event> get onBeforeUnload => beforeUnloadEvent.forTarget(this);

  Stream<Event> get onBlur => blurEvent.forTarget(this);

  Stream<Event> get onCanPlay => canPlayEvent.forTarget(this);

  Stream<Event> get onCanPlayThrough => canPlayThroughEvent.forTarget(this);

  Stream<Event> get onChange => changeEvent.forTarget(this);

  Stream<MouseEvent> get onClick => clickEvent.forTarget(this);

  Stream<MouseEvent> get onContextMenu => contextMenuEvent.forTarget(this);

  Stream<Event> get onDoubleClick => doubleClickEvent.forTarget(this);

  Stream<DeviceMotionEvent> get onDeviceMotion => deviceMotionEvent.forTarget(this);

  Stream<DeviceOrientationEvent> get onDeviceOrientation => deviceOrientationEvent.forTarget(this);

  Stream<MouseEvent> get onDrag => dragEvent.forTarget(this);

  Stream<MouseEvent> get onDragEnd => dragEndEvent.forTarget(this);

  Stream<MouseEvent> get onDragEnter => dragEnterEvent.forTarget(this);

  Stream<MouseEvent> get onDragLeave => dragLeaveEvent.forTarget(this);

  Stream<MouseEvent> get onDragOver => dragOverEvent.forTarget(this);

  Stream<MouseEvent> get onDragStart => dragStartEvent.forTarget(this);

  Stream<MouseEvent> get onDrop => dropEvent.forTarget(this);

  Stream<Event> get onDurationChange => durationChangeEvent.forTarget(this);

  Stream<Event> get onEmptied => emptiedEvent.forTarget(this);

  Stream<Event> get onEnded => endedEvent.forTarget(this);

  Stream<Event> get onError => errorEvent.forTarget(this);

  Stream<Event> get onFocus => focusEvent.forTarget(this);

  Stream<HashChangeEvent> get onHashChange => hashChangeEvent.forTarget(this);

  Stream<Event> get onInput => inputEvent.forTarget(this);

  Stream<Event> get onInvalid => invalidEvent.forTarget(this);

  Stream<KeyboardEvent> get onKeyDown => keyDownEvent.forTarget(this);

  Stream<KeyboardEvent> get onKeyPress => keyPressEvent.forTarget(this);

  Stream<KeyboardEvent> get onKeyUp => keyUpEvent.forTarget(this);

  Stream<Event> get onLoad => loadEvent.forTarget(this);

  Stream<Event> get onLoadedData => loadedDataEvent.forTarget(this);

  Stream<Event> get onLoadedMetadata => loadedMetadataEvent.forTarget(this);

  Stream<Event> get onLoadStart => loadStartEvent.forTarget(this);

  Stream<MessageEvent> get onMessage => messageEvent.forTarget(this);

  Stream<MouseEvent> get onMouseDown => mouseDownEvent.forTarget(this);

  Stream<MouseEvent> get onMouseMove => mouseMoveEvent.forTarget(this);

  Stream<MouseEvent> get onMouseOut => mouseOutEvent.forTarget(this);

  Stream<MouseEvent> get onMouseOver => mouseOverEvent.forTarget(this);

  Stream<MouseEvent> get onMouseUp => mouseUpEvent.forTarget(this);

  Stream<WheelEvent> get onMouseWheel => mouseWheelEvent.forTarget(this);

  Stream<Event> get onOffline => offlineEvent.forTarget(this);

  Stream<Event> get onOnline => onlineEvent.forTarget(this);

  Stream<Event> get onPageHide => pageHideEvent.forTarget(this);

  Stream<Event> get onPageShow => pageShowEvent.forTarget(this);

  Stream<Event> get onPause => pauseEvent.forTarget(this);

  Stream<Event> get onPlay => playEvent.forTarget(this);

  Stream<Event> get onPlaying => playingEvent.forTarget(this);

  Stream<PopStateEvent> get onPopState => popStateEvent.forTarget(this);

  Stream<Event> get onProgress => progressEvent.forTarget(this);

  Stream<Event> get onRateChange => rateChangeEvent.forTarget(this);

  Stream<Event> get onReset => resetEvent.forTarget(this);

  Stream<Event> get onResize => resizeEvent.forTarget(this);

  Stream<Event> get onScroll => scrollEvent.forTarget(this);

  Stream<Event> get onSearch => searchEvent.forTarget(this);

  Stream<Event> get onSeeked => seekedEvent.forTarget(this);

  Stream<Event> get onSeeking => seekingEvent.forTarget(this);

  Stream<Event> get onSelect => selectEvent.forTarget(this);

  Stream<Event> get onStalled => stalledEvent.forTarget(this);

  Stream<StorageEvent> get onStorage => storageEvent.forTarget(this);

  Stream<Event> get onSubmit => submitEvent.forTarget(this);

  Stream<Event> get onSuspend => suspendEvent.forTarget(this);

  Stream<Event> get onTimeUpdate => timeUpdateEvent.forTarget(this);

  Stream<TouchEvent> get onTouchCancel => touchCancelEvent.forTarget(this);

  Stream<TouchEvent> get onTouchEnd => touchEndEvent.forTarget(this);

  Stream<TouchEvent> get onTouchMove => touchMoveEvent.forTarget(this);

  Stream<TouchEvent> get onTouchStart => touchStartEvent.forTarget(this);

  Stream<Event> get onUnload => unloadEvent.forTarget(this);

  Stream<Event> get onVolumeChange => volumeChangeEvent.forTarget(this);

  Stream<Event> get onWaiting => waitingEvent.forTarget(this);

  Stream<AnimationEvent> get onAnimationEnd => animationEndEvent.forTarget(this);

  Stream<AnimationEvent> get onAnimationIteration => animationIterationEvent.forTarget(this);

  Stream<AnimationEvent> get onAnimationStart => animationStartEvent.forTarget(this);

  Stream<TransitionEvent> get onTransitionEnd => transitionEndEvent.forTarget(this);

}

@DocsEditable
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

  static const EventStreamProvider<MessageEvent> messageEvent = const EventStreamProvider<MessageEvent>('message');

  @DocsEditable
  factory Worker(String scriptUrl) => Worker._create(scriptUrl);
  static Worker _create(String scriptUrl) => JS('Worker', 'new Worker(#)', scriptUrl);

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
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
  @DocsEditable @DomName('Worker.postMessage')
  void _postMessage_1(message, List messagePorts) native;
  @JSName('postMessage')
  @DocsEditable @DomName('Worker.postMessage')
  void _postMessage_2(message) native;

  @DocsEditable @DomName('Worker.terminate')
  void terminate() native;

  Stream<MessageEvent> get onMessage => messageEvent.forTarget(this);
}

@DocsEditable
class WorkerEvents extends AbstractWorkerEvents {
  @DocsEditable
  WorkerEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get message => this['message'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WorkerContext')
class WorkerContext extends EventTarget native "*WorkerContext" {

  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  WorkerContextEvents get on =>
    new WorkerContextEvents(this);

  static const int PERSISTENT = 1;

  static const int TEMPORARY = 0;

  @DocsEditable @DomName('WorkerContext.location')
  final WorkerLocation location;

  @DocsEditable @DomName('WorkerContext.navigator')
  final WorkerNavigator navigator;

  @DocsEditable @DomName('WorkerContext.self')
  final WorkerContext self;

  @DocsEditable @DomName('WorkerContext.webkitNotifications')
  final NotificationCenter webkitNotifications;

  @JSName('addEventListener')
  @DocsEditable @DomName('WorkerContext.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('WorkerContext.clearInterval')
  void clearInterval(int handle) native;

  @DocsEditable @DomName('WorkerContext.clearTimeout')
  void clearTimeout(int handle) native;

  @DocsEditable @DomName('WorkerContext.close')
  void close() native;

  @JSName('dispatchEvent')
  @DocsEditable @DomName('WorkerContext.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  @DocsEditable @DomName('WorkerContext.importScripts')
  void importScripts() native;

  @DocsEditable @DomName('WorkerContext.openDatabase')
  Database openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]) native;

  @DocsEditable @DomName('WorkerContext.openDatabaseSync')
  DatabaseSync openDatabaseSync(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]) native;

  @JSName('removeEventListener')
  @DocsEditable @DomName('WorkerContext.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable @DomName('WorkerContext.setInterval')
  int setInterval(TimeoutHandler handler, int timeout) native;

  @DocsEditable @DomName('WorkerContext.setTimeout')
  int setTimeout(TimeoutHandler handler, int timeout) native;

  @JSName('webkitRequestFileSystem')
  @DocsEditable @DomName('WorkerContext.webkitRequestFileSystem') @SupportedBrowser(SupportedBrowser.CHROME) @Experimental()
  void requestFileSystem(int type, int size, [FileSystemCallback successCallback, ErrorCallback errorCallback]) native;

  @JSName('webkitRequestFileSystemSync')
  @DocsEditable @DomName('WorkerContext.webkitRequestFileSystemSync') @SupportedBrowser(SupportedBrowser.CHROME) @Experimental()
  FileSystemSync requestFileSystemSync(int type, int size) native;

  @JSName('webkitResolveLocalFileSystemSyncURL')
  @DocsEditable @DomName('WorkerContext.webkitResolveLocalFileSystemSyncURL') @SupportedBrowser(SupportedBrowser.CHROME) @Experimental()
  EntrySync resolveLocalFileSystemSyncUrl(String url) native;

  @JSName('webkitResolveLocalFileSystemURL')
  @DocsEditable @DomName('WorkerContext.webkitResolveLocalFileSystemURL') @SupportedBrowser(SupportedBrowser.CHROME) @Experimental()
  void resolveLocalFileSystemUrl(String url, EntryCallback successCallback, [ErrorCallback errorCallback]) native;

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
  @Experimental()
  IdbFactory get indexedDB =>
      JS('IdbFactory',
         '#.indexedDB || #.webkitIndexedDB || #.mozIndexedDB',
         this, this, this);
}

@DocsEditable
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

  @DocsEditable @DomName('WorkerLocation.hash')
  final String hash;

  @DocsEditable @DomName('WorkerLocation.host')
  final String host;

  @DocsEditable @DomName('WorkerLocation.hostname')
  final String hostname;

  @DocsEditable @DomName('WorkerLocation.href')
  final String href;

  @DocsEditable @DomName('WorkerLocation.pathname')
  final String pathname;

  @DocsEditable @DomName('WorkerLocation.port')
  final String port;

  @DocsEditable @DomName('WorkerLocation.protocol')
  final String protocol;

  @DocsEditable @DomName('WorkerLocation.search')
  final String search;

  @DocsEditable @DomName('WorkerLocation.toString')
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('WorkerNavigator')
class WorkerNavigator native "*WorkerNavigator" {

  @DocsEditable @DomName('WorkerNavigator.appName')
  final String appName;

  @DocsEditable @DomName('WorkerNavigator.appVersion')
  final String appVersion;

  @DocsEditable @DomName('WorkerNavigator.onLine')
  final bool onLine;

  @DocsEditable @DomName('WorkerNavigator.platform')
  final String platform;

  @DocsEditable @DomName('WorkerNavigator.userAgent')
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

  @DocsEditable @DomName('XPathEvaluator.createExpression')
  XPathExpression createExpression(String expression, XPathNSResolver resolver) native;

  @DocsEditable @DomName('XPathEvaluator.createNSResolver')
  XPathNSResolver createNSResolver(Node nodeResolver) native;

  @DocsEditable @DomName('XPathEvaluator.evaluate')
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

  @DocsEditable @DomName('XPathException.code')
  final int code;

  @DocsEditable @DomName('XPathException.message')
  final String message;

  @DocsEditable @DomName('XPathException.name')
  final String name;

  @DocsEditable @DomName('XPathException.toString')
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('XPathExpression')
class XPathExpression native "*XPathExpression" {

  @DocsEditable @DomName('XPathExpression.evaluate')
  XPathResult evaluate(Node contextNode, int type, XPathResult inResult) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('XPathNSResolver')
class XPathNSResolver native "*XPathNSResolver" {

  @JSName('lookupNamespaceURI')
  @DocsEditable @DomName('XPathNSResolver.lookupNamespaceURI')
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

  @DocsEditable @DomName('XPathResult.booleanValue')
  final bool booleanValue;

  @DocsEditable @DomName('XPathResult.invalidIteratorState')
  final bool invalidIteratorState;

  @DocsEditable @DomName('XPathResult.numberValue')
  final num numberValue;

  @DocsEditable @DomName('XPathResult.resultType')
  final int resultType;

  @DocsEditable @DomName('XPathResult.singleNodeValue')
  final Node singleNodeValue;

  @DocsEditable @DomName('XPathResult.snapshotLength')
  final int snapshotLength;

  @DocsEditable @DomName('XPathResult.stringValue')
  final String stringValue;

  @DocsEditable @DomName('XPathResult.iterateNext')
  Node iterateNext() native;

  @DocsEditable @DomName('XPathResult.snapshotItem')
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

  @DocsEditable @DomName('XMLSerializer.serializeToString')
  String serializeToString(Node node) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('XSLTProcessor')
class XsltProcessor native "*XSLTProcessor" {

  @DocsEditable
  factory XsltProcessor() => XsltProcessor._create();
  static XsltProcessor _create() => JS('XsltProcessor', 'new XSLTProcessor()');

  @DocsEditable @DomName('XSLTProcessor.clearParameters')
  void clearParameters() native;

  @DocsEditable @DomName('XSLTProcessor.getParameter')
  String getParameter(String namespaceURI, String localName) native;

  @DocsEditable @DomName('XSLTProcessor.importStylesheet')
  void importStylesheet(Node stylesheet) native;

  @DocsEditable @DomName('XSLTProcessor.removeParameter')
  void removeParameter(String namespaceURI, String localName) native;

  @DocsEditable @DomName('XSLTProcessor.reset')
  void reset() native;

  @DocsEditable @DomName('XSLTProcessor.setParameter')
  void setParameter(String namespaceURI, String localName, String value) native;

  @DocsEditable @DomName('XSLTProcessor.transformToDocument')
  Document transformToDocument(Node source) native;

  @DocsEditable @DomName('XSLTProcessor.transformToFragment')
  DocumentFragment transformToFragment(Node source, Document docVal) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('ClientRectList')
class _ClientRectList implements JavaScriptIndexingBehavior, List<ClientRect> native "*ClientRectList" {

  @DocsEditable @DomName('ClientRectList.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(ClientRect element) => Collections.contains(this, element);

  void forEach(void f(ClientRect element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(ClientRect element)) => new MappedList<ClientRect, dynamic>(this, f);

  Iterable<ClientRect> where(bool f(ClientRect element)) => new WhereIterable<ClientRect>(this, f);

  bool every(bool f(ClientRect element)) => Collections.every(this, f);

  bool any(bool f(ClientRect element)) => Collections.any(this, f);

  List<ClientRect> toList() => new List<ClientRect>.from(this);
  Set<ClientRect> toSet() => new Set<ClientRect>.from(this);

  bool get isEmpty => this.length == 0;

  List<ClientRect> take(int n) => new ListView<ClientRect>(this, 0, n);

  Iterable<ClientRect> takeWhile(bool test(ClientRect value)) {
    return new TakeWhileIterable<ClientRect>(this, test);
  }

  List<ClientRect> skip(int n) => new ListView<ClientRect>(this, n, null);

  Iterable<ClientRect> skipWhile(bool test(ClientRect value)) {
    return new SkipWhileIterable<ClientRect>(this, test);
  }

  ClientRect firstMatching(bool test(ClientRect value), { ClientRect orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  ClientRect lastMatching(bool test(ClientRect value), {ClientRect orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  ClientRect singleMatching(bool test(ClientRect value)) {
    return Collections.singleMatching(this, test);
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

  ClientRect min([int compare(ClientRect a, ClientRect b)]) => Collections.min(this, compare);

  ClientRect max([int compare(ClientRect a, ClientRect b)]) => Collections.max(this, compare);

  ClientRect removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  ClientRect removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('ClientRectList.item')
  ClientRect item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('CSSRuleList')
class _CssRuleList implements JavaScriptIndexingBehavior, List<CssRule> native "*CSSRuleList" {

  @DocsEditable @DomName('CSSRuleList.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(CssRule element) => Collections.contains(this, element);

  void forEach(void f(CssRule element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(CssRule element)) => new MappedList<CssRule, dynamic>(this, f);

  Iterable<CssRule> where(bool f(CssRule element)) => new WhereIterable<CssRule>(this, f);

  bool every(bool f(CssRule element)) => Collections.every(this, f);

  bool any(bool f(CssRule element)) => Collections.any(this, f);

  List<CssRule> toList() => new List<CssRule>.from(this);
  Set<CssRule> toSet() => new Set<CssRule>.from(this);

  bool get isEmpty => this.length == 0;

  List<CssRule> take(int n) => new ListView<CssRule>(this, 0, n);

  Iterable<CssRule> takeWhile(bool test(CssRule value)) {
    return new TakeWhileIterable<CssRule>(this, test);
  }

  List<CssRule> skip(int n) => new ListView<CssRule>(this, n, null);

  Iterable<CssRule> skipWhile(bool test(CssRule value)) {
    return new SkipWhileIterable<CssRule>(this, test);
  }

  CssRule firstMatching(bool test(CssRule value), { CssRule orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  CssRule lastMatching(bool test(CssRule value), {CssRule orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  CssRule singleMatching(bool test(CssRule value)) {
    return Collections.singleMatching(this, test);
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

  CssRule min([int compare(CssRule a, CssRule b)]) => Collections.min(this, compare);

  CssRule max([int compare(CssRule a, CssRule b)]) => Collections.max(this, compare);

  CssRule removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  CssRule removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('CSSRuleList.item')
  CssRule item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('CSSValueList')
class _CssValueList extends CssValue implements List<CssValue>, JavaScriptIndexingBehavior native "*CSSValueList" {

  @DocsEditable @DomName('CSSValueList.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(CssValue element) => Collections.contains(this, element);

  void forEach(void f(CssValue element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(CssValue element)) => new MappedList<CssValue, dynamic>(this, f);

  Iterable<CssValue> where(bool f(CssValue element)) => new WhereIterable<CssValue>(this, f);

  bool every(bool f(CssValue element)) => Collections.every(this, f);

  bool any(bool f(CssValue element)) => Collections.any(this, f);

  List<CssValue> toList() => new List<CssValue>.from(this);
  Set<CssValue> toSet() => new Set<CssValue>.from(this);

  bool get isEmpty => this.length == 0;

  List<CssValue> take(int n) => new ListView<CssValue>(this, 0, n);

  Iterable<CssValue> takeWhile(bool test(CssValue value)) {
    return new TakeWhileIterable<CssValue>(this, test);
  }

  List<CssValue> skip(int n) => new ListView<CssValue>(this, n, null);

  Iterable<CssValue> skipWhile(bool test(CssValue value)) {
    return new SkipWhileIterable<CssValue>(this, test);
  }

  CssValue firstMatching(bool test(CssValue value), { CssValue orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  CssValue lastMatching(bool test(CssValue value), {CssValue orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  CssValue singleMatching(bool test(CssValue value)) {
    return Collections.singleMatching(this, test);
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

  CssValue min([int compare(CssValue a, CssValue b)]) => Collections.min(this, compare);

  CssValue max([int compare(CssValue a, CssValue b)]) => Collections.max(this, compare);

  CssValue removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  CssValue removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('CSSValueList.item')
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

  @DocsEditable @DomName('EntryArray.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(Entry element) => Collections.contains(this, element);

  void forEach(void f(Entry element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(Entry element)) => new MappedList<Entry, dynamic>(this, f);

  Iterable<Entry> where(bool f(Entry element)) => new WhereIterable<Entry>(this, f);

  bool every(bool f(Entry element)) => Collections.every(this, f);

  bool any(bool f(Entry element)) => Collections.any(this, f);

  List<Entry> toList() => new List<Entry>.from(this);
  Set<Entry> toSet() => new Set<Entry>.from(this);

  bool get isEmpty => this.length == 0;

  List<Entry> take(int n) => new ListView<Entry>(this, 0, n);

  Iterable<Entry> takeWhile(bool test(Entry value)) {
    return new TakeWhileIterable<Entry>(this, test);
  }

  List<Entry> skip(int n) => new ListView<Entry>(this, n, null);

  Iterable<Entry> skipWhile(bool test(Entry value)) {
    return new SkipWhileIterable<Entry>(this, test);
  }

  Entry firstMatching(bool test(Entry value), { Entry orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  Entry lastMatching(bool test(Entry value), {Entry orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  Entry singleMatching(bool test(Entry value)) {
    return Collections.singleMatching(this, test);
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

  Entry min([int compare(Entry a, Entry b)]) => Collections.min(this, compare);

  Entry max([int compare(Entry a, Entry b)]) => Collections.max(this, compare);

  Entry removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  Entry removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('EntryArray.item')
  Entry item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('EntryArraySync')
class _EntryArraySync implements JavaScriptIndexingBehavior, List<EntrySync> native "*EntryArraySync" {

  @DocsEditable @DomName('EntryArraySync.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(EntrySync element) => Collections.contains(this, element);

  void forEach(void f(EntrySync element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(EntrySync element)) => new MappedList<EntrySync, dynamic>(this, f);

  Iterable<EntrySync> where(bool f(EntrySync element)) => new WhereIterable<EntrySync>(this, f);

  bool every(bool f(EntrySync element)) => Collections.every(this, f);

  bool any(bool f(EntrySync element)) => Collections.any(this, f);

  List<EntrySync> toList() => new List<EntrySync>.from(this);
  Set<EntrySync> toSet() => new Set<EntrySync>.from(this);

  bool get isEmpty => this.length == 0;

  List<EntrySync> take(int n) => new ListView<EntrySync>(this, 0, n);

  Iterable<EntrySync> takeWhile(bool test(EntrySync value)) {
    return new TakeWhileIterable<EntrySync>(this, test);
  }

  List<EntrySync> skip(int n) => new ListView<EntrySync>(this, n, null);

  Iterable<EntrySync> skipWhile(bool test(EntrySync value)) {
    return new SkipWhileIterable<EntrySync>(this, test);
  }

  EntrySync firstMatching(bool test(EntrySync value), { EntrySync orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  EntrySync lastMatching(bool test(EntrySync value), {EntrySync orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  EntrySync singleMatching(bool test(EntrySync value)) {
    return Collections.singleMatching(this, test);
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

  EntrySync min([int compare(EntrySync a, EntrySync b)]) => Collections.min(this, compare);

  EntrySync max([int compare(EntrySync a, EntrySync b)]) => Collections.max(this, compare);

  EntrySync removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  EntrySync removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('EntryArraySync.item')
  EntrySync item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('GamepadList')
class _GamepadList implements JavaScriptIndexingBehavior, List<Gamepad> native "*GamepadList" {

  @DocsEditable @DomName('GamepadList.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(Gamepad element) => Collections.contains(this, element);

  void forEach(void f(Gamepad element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(Gamepad element)) => new MappedList<Gamepad, dynamic>(this, f);

  Iterable<Gamepad> where(bool f(Gamepad element)) => new WhereIterable<Gamepad>(this, f);

  bool every(bool f(Gamepad element)) => Collections.every(this, f);

  bool any(bool f(Gamepad element)) => Collections.any(this, f);

  List<Gamepad> toList() => new List<Gamepad>.from(this);
  Set<Gamepad> toSet() => new Set<Gamepad>.from(this);

  bool get isEmpty => this.length == 0;

  List<Gamepad> take(int n) => new ListView<Gamepad>(this, 0, n);

  Iterable<Gamepad> takeWhile(bool test(Gamepad value)) {
    return new TakeWhileIterable<Gamepad>(this, test);
  }

  List<Gamepad> skip(int n) => new ListView<Gamepad>(this, n, null);

  Iterable<Gamepad> skipWhile(bool test(Gamepad value)) {
    return new SkipWhileIterable<Gamepad>(this, test);
  }

  Gamepad firstMatching(bool test(Gamepad value), { Gamepad orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  Gamepad lastMatching(bool test(Gamepad value), {Gamepad orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  Gamepad singleMatching(bool test(Gamepad value)) {
    return Collections.singleMatching(this, test);
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

  Gamepad min([int compare(Gamepad a, Gamepad b)]) => Collections.min(this, compare);

  Gamepad max([int compare(Gamepad a, Gamepad b)]) => Collections.max(this, compare);

  Gamepad removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  Gamepad removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('GamepadList.item')
  Gamepad item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('MediaStreamList')
class _MediaStreamList implements JavaScriptIndexingBehavior, List<MediaStream> native "*MediaStreamList" {

  @DocsEditable @DomName('MediaStreamList.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(MediaStream element) => Collections.contains(this, element);

  void forEach(void f(MediaStream element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(MediaStream element)) => new MappedList<MediaStream, dynamic>(this, f);

  Iterable<MediaStream> where(bool f(MediaStream element)) => new WhereIterable<MediaStream>(this, f);

  bool every(bool f(MediaStream element)) => Collections.every(this, f);

  bool any(bool f(MediaStream element)) => Collections.any(this, f);

  List<MediaStream> toList() => new List<MediaStream>.from(this);
  Set<MediaStream> toSet() => new Set<MediaStream>.from(this);

  bool get isEmpty => this.length == 0;

  List<MediaStream> take(int n) => new ListView<MediaStream>(this, 0, n);

  Iterable<MediaStream> takeWhile(bool test(MediaStream value)) {
    return new TakeWhileIterable<MediaStream>(this, test);
  }

  List<MediaStream> skip(int n) => new ListView<MediaStream>(this, n, null);

  Iterable<MediaStream> skipWhile(bool test(MediaStream value)) {
    return new SkipWhileIterable<MediaStream>(this, test);
  }

  MediaStream firstMatching(bool test(MediaStream value), { MediaStream orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  MediaStream lastMatching(bool test(MediaStream value), {MediaStream orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  MediaStream singleMatching(bool test(MediaStream value)) {
    return Collections.singleMatching(this, test);
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

  MediaStream min([int compare(MediaStream a, MediaStream b)]) => Collections.min(this, compare);

  MediaStream max([int compare(MediaStream a, MediaStream b)]) => Collections.max(this, compare);

  MediaStream removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  MediaStream removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('MediaStreamList.item')
  MediaStream item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SpeechInputResultList')
class _SpeechInputResultList implements JavaScriptIndexingBehavior, List<SpeechInputResult> native "*SpeechInputResultList" {

  @DocsEditable @DomName('SpeechInputResultList.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(SpeechInputResult element) => Collections.contains(this, element);

  void forEach(void f(SpeechInputResult element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(SpeechInputResult element)) => new MappedList<SpeechInputResult, dynamic>(this, f);

  Iterable<SpeechInputResult> where(bool f(SpeechInputResult element)) => new WhereIterable<SpeechInputResult>(this, f);

  bool every(bool f(SpeechInputResult element)) => Collections.every(this, f);

  bool any(bool f(SpeechInputResult element)) => Collections.any(this, f);

  List<SpeechInputResult> toList() => new List<SpeechInputResult>.from(this);
  Set<SpeechInputResult> toSet() => new Set<SpeechInputResult>.from(this);

  bool get isEmpty => this.length == 0;

  List<SpeechInputResult> take(int n) => new ListView<SpeechInputResult>(this, 0, n);

  Iterable<SpeechInputResult> takeWhile(bool test(SpeechInputResult value)) {
    return new TakeWhileIterable<SpeechInputResult>(this, test);
  }

  List<SpeechInputResult> skip(int n) => new ListView<SpeechInputResult>(this, n, null);

  Iterable<SpeechInputResult> skipWhile(bool test(SpeechInputResult value)) {
    return new SkipWhileIterable<SpeechInputResult>(this, test);
  }

  SpeechInputResult firstMatching(bool test(SpeechInputResult value), { SpeechInputResult orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  SpeechInputResult lastMatching(bool test(SpeechInputResult value), {SpeechInputResult orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  SpeechInputResult singleMatching(bool test(SpeechInputResult value)) {
    return Collections.singleMatching(this, test);
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

  SpeechInputResult min([int compare(SpeechInputResult a, SpeechInputResult b)]) => Collections.min(this, compare);

  SpeechInputResult max([int compare(SpeechInputResult a, SpeechInputResult b)]) => Collections.max(this, compare);

  SpeechInputResult removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  SpeechInputResult removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('SpeechInputResultList.item')
  SpeechInputResult item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('SpeechRecognitionResultList')
class _SpeechRecognitionResultList implements JavaScriptIndexingBehavior, List<SpeechRecognitionResult> native "*SpeechRecognitionResultList" {

  @DocsEditable @DomName('SpeechRecognitionResultList.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(SpeechRecognitionResult element) => Collections.contains(this, element);

  void forEach(void f(SpeechRecognitionResult element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(SpeechRecognitionResult element)) => new MappedList<SpeechRecognitionResult, dynamic>(this, f);

  Iterable<SpeechRecognitionResult> where(bool f(SpeechRecognitionResult element)) => new WhereIterable<SpeechRecognitionResult>(this, f);

  bool every(bool f(SpeechRecognitionResult element)) => Collections.every(this, f);

  bool any(bool f(SpeechRecognitionResult element)) => Collections.any(this, f);

  List<SpeechRecognitionResult> toList() => new List<SpeechRecognitionResult>.from(this);
  Set<SpeechRecognitionResult> toSet() => new Set<SpeechRecognitionResult>.from(this);

  bool get isEmpty => this.length == 0;

  List<SpeechRecognitionResult> take(int n) => new ListView<SpeechRecognitionResult>(this, 0, n);

  Iterable<SpeechRecognitionResult> takeWhile(bool test(SpeechRecognitionResult value)) {
    return new TakeWhileIterable<SpeechRecognitionResult>(this, test);
  }

  List<SpeechRecognitionResult> skip(int n) => new ListView<SpeechRecognitionResult>(this, n, null);

  Iterable<SpeechRecognitionResult> skipWhile(bool test(SpeechRecognitionResult value)) {
    return new SkipWhileIterable<SpeechRecognitionResult>(this, test);
  }

  SpeechRecognitionResult firstMatching(bool test(SpeechRecognitionResult value), { SpeechRecognitionResult orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  SpeechRecognitionResult lastMatching(bool test(SpeechRecognitionResult value), {SpeechRecognitionResult orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  SpeechRecognitionResult singleMatching(bool test(SpeechRecognitionResult value)) {
    return Collections.singleMatching(this, test);
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

  SpeechRecognitionResult min([int compare(SpeechRecognitionResult a, SpeechRecognitionResult b)]) => Collections.min(this, compare);

  SpeechRecognitionResult max([int compare(SpeechRecognitionResult a, SpeechRecognitionResult b)]) => Collections.max(this, compare);

  SpeechRecognitionResult removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  SpeechRecognitionResult removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('SpeechRecognitionResultList.item')
  SpeechRecognitionResult item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('StyleSheetList')
class _StyleSheetList implements JavaScriptIndexingBehavior, List<StyleSheet> native "*StyleSheetList" {

  @DocsEditable @DomName('StyleSheetList.length')
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
    return Collections.reduce(this, initialValue, combine);
  }

  bool contains(StyleSheet element) => Collections.contains(this, element);

  void forEach(void f(StyleSheet element)) => Collections.forEach(this, f);

  String join([String separator]) => Collections.joinList(this, separator);

  List mappedBy(f(StyleSheet element)) => new MappedList<StyleSheet, dynamic>(this, f);

  Iterable<StyleSheet> where(bool f(StyleSheet element)) => new WhereIterable<StyleSheet>(this, f);

  bool every(bool f(StyleSheet element)) => Collections.every(this, f);

  bool any(bool f(StyleSheet element)) => Collections.any(this, f);

  List<StyleSheet> toList() => new List<StyleSheet>.from(this);
  Set<StyleSheet> toSet() => new Set<StyleSheet>.from(this);

  bool get isEmpty => this.length == 0;

  List<StyleSheet> take(int n) => new ListView<StyleSheet>(this, 0, n);

  Iterable<StyleSheet> takeWhile(bool test(StyleSheet value)) {
    return new TakeWhileIterable<StyleSheet>(this, test);
  }

  List<StyleSheet> skip(int n) => new ListView<StyleSheet>(this, n, null);

  Iterable<StyleSheet> skipWhile(bool test(StyleSheet value)) {
    return new SkipWhileIterable<StyleSheet>(this, test);
  }

  StyleSheet firstMatching(bool test(StyleSheet value), { StyleSheet orElse() }) {
    return Collections.firstMatching(this, test, orElse);
  }

  StyleSheet lastMatching(bool test(StyleSheet value), {StyleSheet orElse()}) {
    return Collections.lastMatchingInList(this, test, orElse);
  }

  StyleSheet singleMatching(bool test(StyleSheet value)) {
    return Collections.singleMatching(this, test);
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

  StyleSheet min([int compare(StyleSheet a, StyleSheet b)]) => Collections.min(this, compare);

  StyleSheet max([int compare(StyleSheet a, StyleSheet b)]) => Collections.max(this, compare);

  StyleSheet removeAt(int pos) {
    throw new UnsupportedError("Cannot removeAt on immutable List.");
  }

  StyleSheet removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
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

  @DocsEditable @DomName('StyleSheetList.item')
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
    // or if the browser natively does enough
    _modify((s) => s.add(value));
  }

  bool remove(String value) {
    Set<String> s = readClasses();
    bool result = s.remove(value);
    writeClasses(s);
    return result;
  }

  void addAll(Iterable<String> iterable) {
    // TODO - see comment above about validation
    _modify((s) => s.addAll(iterable));
  }

  void removeAll(Iterable<String> iterable) {
    _modify((s) => s.removeAll(iterable));
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
  Stream<T> asMultiSubscriberStream() => this;

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

  // Instance members referring to the internal event handlers because closures
  // are not hashable.
  var _keyUp, _keyDown, _keyPress;

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
    _keyDown = processKeyDown;
    _keyUp = processKeyUp;
    _keyPress = processKeyPress;
  }

  /**
   * Hook up all event listeners under the covers so we can estimate keycodes
   * and charcodes when they are not provided.
   */
  void _initializeAllEventListeners() {
    _keyDownList = [];
    _target.on.keyDown.add(_keyDown, true);
    _target.on.keyPress.add(_keyPress, true);
    _target.on.keyUp.add(_keyUp, true);
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
      _target.on.keyDown.remove(_keyDown);
      _target.on.keyPress.remove(_keyPress);
      _target.on.keyUp.remove(_keyUp);
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

    request.on.readyStateChange.add((e) {
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
  var event = new CustomEvent(receiver, false, false, json.stringify(message));
  window.$dom_dispatchEvent(event);
}

String _getPortSyncEventData(CustomEvent event) => event.detail;
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


typedef Object ComputeValue();

class _MeasurementRequest<T> {
  final ComputeValue computeValue;
  final Completer<T> completer;
  Object value;
  bool exception = false;
  _MeasurementRequest(this.computeValue, this.completer);
}

typedef void _MeasurementCallback();

/**
 * This class attempts to invoke a callback as soon as the current event stack
 * unwinds, but before the browser repaints.
 */
abstract class _MeasurementScheduler {
  bool _nextMeasurementFrameScheduled = false;
  _MeasurementCallback _callback;

  _MeasurementScheduler(this._callback);

  /**
   * Creates the best possible measurement scheduler for the current platform.
   */
  factory _MeasurementScheduler.best(_MeasurementCallback callback) {
    if (MutationObserver.supported) {
      return new _MutationObserverScheduler(callback);
    }
    return new _PostMessageScheduler(callback);
  }

  /**
   * Schedules a measurement callback if one has not been scheduled already.
   */
  void maybeSchedule() {
    if (this._nextMeasurementFrameScheduled) {
      return;
    }
    this._nextMeasurementFrameScheduled = true;
    this._schedule();
  }

  /**
   * Does the actual scheduling of the callback.
   */
  void _schedule();

  /**
   * Handles the measurement callback and forwards it if necessary.
   */
  void _onCallback() {
    // Ignore spurious messages.
    if (!_nextMeasurementFrameScheduled) {
      return;
    }
    _nextMeasurementFrameScheduled = false;
    this._callback();
  }
}

/**
 * Scheduler which uses window.postMessage to schedule events.
 */
class _PostMessageScheduler extends _MeasurementScheduler {
  const _MEASUREMENT_MESSAGE = "DART-MEASURE";

  _PostMessageScheduler(_MeasurementCallback callback): super(callback) {
      // Messages from other windows do not cause a security risk as
      // all we care about is that _handleMessage is called
      // after the current event loop is unwound and calling the function is
      // a noop when zero requests are pending.
      window.on.message.add(this._handleMessage);
  }

  void _schedule() {
    window.postMessage(_MEASUREMENT_MESSAGE, "*");
  }

  _handleMessage(e) {
    this._onCallback();
  }
}

/**
 * Scheduler which uses a MutationObserver to schedule events.
 */
class _MutationObserverScheduler extends _MeasurementScheduler {
  MutationObserver _observer;
  Element _dummy;

  _MutationObserverScheduler(_MeasurementCallback callback): super(callback) {
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


List<_MeasurementRequest> _pendingRequests;
List<TimeoutHandler> _pendingMeasurementFrameCallbacks;
_MeasurementScheduler _measurementScheduler = null;

void _maybeScheduleMeasurementFrame() {
  if (_measurementScheduler == null) {
    _measurementScheduler =
      new _MeasurementScheduler.best(_completeMeasurementFutures);
  }
  _measurementScheduler.maybeSchedule();
}

/**
 * Registers a [callback] which is called after the next batch of measurements
 * completes. Even if no measurements completed, the callback is triggered
 * when they would have completed to avoid confusing bugs if it happened that
 * no measurements were actually requested.
 */
void _addMeasurementFrameCallback(TimeoutHandler callback) {
  if (_pendingMeasurementFrameCallbacks == null) {
    _pendingMeasurementFrameCallbacks = <TimeoutHandler>[];
    _maybeScheduleMeasurementFrame();
  }
  _pendingMeasurementFrameCallbacks.add(callback);
}

/**
 * Returns a [Future] whose value will be the result of evaluating
 * [computeValue] during the next safe measurement interval.
 * The next safe measurement interval is after the current event loop has
 * unwound but before the browser has rendered the page.
 * It is important that the [computeValue] function only queries the html
 * layout and html in any way.
 */
Future _createMeasurementFuture(ComputeValue computeValue,
                                Completer completer) {
  if (_pendingRequests == null) {
    _pendingRequests = <_MeasurementRequest>[];
    _maybeScheduleMeasurementFrame();
  }
  _pendingRequests.add(new _MeasurementRequest(computeValue, completer));
  return completer.future;
}

/**
 * Complete all pending measurement futures evaluating them in a single batch
 * so that the the browser is guaranteed to avoid multiple layouts.
 */
void _completeMeasurementFutures() {
  // We must compute all new values before fulfilling the futures as
  // the onComplete callbacks for the futures could modify the DOM making
  // subsequent measurement calculations expensive to compute.
  if (_pendingRequests != null) {
    for (_MeasurementRequest request in _pendingRequests) {
      try {
        request.value = request.computeValue();
      } catch (e) {
        request.value = e;
        request.exception = true;
      }
    }
  }

  final completedRequests = _pendingRequests;
  final readyMeasurementFrameCallbacks = _pendingMeasurementFrameCallbacks;
  _pendingRequests = null;
  _pendingMeasurementFrameCallbacks = null;
  if (completedRequests != null) {
    for (_MeasurementRequest request in completedRequests) {
      if (request.exception) {
        request.completer.completeError(request.value);
      } else {
        request.completer.complete(request.value);
      }
    }
  }

  if (readyMeasurementFrameCallbacks != null) {
    for (TimeoutHandler handler in readyMeasurementFrameCallbacks) {
      // TODO(jacobr): wrap each call to a handler in a try-catch block.
      handler();
    }
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


class _CustomEventFactoryProvider {
  static CustomEvent createCustomEvent(String type, [bool canBubble = true,
      bool cancelable = true, Object detail = null]) {
    final CustomEvent e = document.$dom_createEvent("CustomEvent");
    e.$dom_initCustomEvent(type, canBubble, cancelable, detail);
    return e;
  }
}

class _EventFactoryProvider {
  static Event createEvent(String type, [bool canBubble = true,
      bool cancelable = true]) {
    final Event e = document.$dom_createEvent("Event");
    e.$dom_initEvent(type, canBubble, cancelable);
    return e;
  }
}

class _MouseEventFactoryProvider {
  static MouseEvent createMouseEvent(String type, Window view, int detail,
      int screenX, int screenY, int clientX, int clientY, int button,
      [bool canBubble = true, bool cancelable = true, bool ctrlKey = false,
      bool altKey = false, bool shiftKey = false, bool metaKey = false,
      EventTarget relatedTarget = null]) {
    final e = document.$dom_createEvent("MouseEvent");
    e.$dom_initMouseEvent(type, canBubble, cancelable, view, detail,
        screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey,
        button, relatedTarget);
    return e;
  }
}

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
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// TODO(rnystrom): add a way to supress public classes from DartDoc output.
// TODO(jacobr): we can remove this class now that we are using the $dom_
// convention for deprecated methods rather than truly private methods.
/**
 * This class is intended for testing purposes only.
 */
class Testing {
  static void addEventListener(EventTarget target, String type, EventListener listener, bool useCapture) {
    target.$dom_addEventListener(type, listener, useCapture);
  }
  static void removeEventListener(EventTarget target, String type, EventListener listener, bool useCapture) {
    target.$dom_removeEventListener(type, listener, useCapture);
  }

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
