// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _AudioContextFactoryProvider {

  factory AudioContext() { return create(); }

  static AudioContext create() native;
}

class _DOMParserFactoryProvider {

  factory DOMParser() { return create(); }

  static DOMParser create() native;
}

class _EventSourceFactoryProvider {

  factory EventSource(String scriptUrl) { return create(scriptUrl); }

  static create(scriptUrl);
}

class _FileReaderFactoryProvider {

  factory FileReader() { return create(); }

  static FileReader create() native;
}

class _MediaStreamFactoryProvider {

  factory MediaStream(MediaStreamTrackList audioTracks,
                      MediaStreamTrackList videoTracks)
      => create(audioTracks, videoTracks);

  static create(audioTracks, videoTracks) native;
}

class _PeerConnectionFactoryProvider {

  factory PeerConnection(String serverConfiguration,
                  SignalingCallback signalingCallback)
      => create(serverConfiguration, signalingCallback);

  static create(serverConfiguration, signalingCallback) native;
}

class _ShadowRootFactoryProvider {

  factory ShadowRoot(Element host) => create(host);

  static create(host) native;
}

class _SharedWorkerFactoryProvider {

  factory SharedWorker(String scriptURL, [String name])
      => create(scriptURL, name);

  static create(scriptURL, name) native;
}

class _TextTrackCueFactoryProvider {

  factory TextTrackCue(String id, num startTime, num endTime, String text,
                       [String settings, bool pauseOnExit])
      => create(id, startTime, endTime, text, settings, pauseOnExit);

  static create(id, startTime, endTime, text, settings, pauseOnExit);
}

class _TypedArrayFactoryProvider {

  factory Float32Array(int length) => _F32(length);
  factory Float32Array.fromList(List<num> list) => _F32(ensureNative(list));
  factory Float32Array.fromBuffer(ArrayBuffer buffer) => _F32(buffer);

  factory Float64Array(int length) => _F64(length);
  factory Float64Array.fromList(List<num> list) => _F64(ensureNative(list));
  factory Float64Array.fromBuffer(ArrayBuffer buffer) => _F64(buffer);

  factory Int8Array(int length) => _I8(length);
  factory Int8Array.fromList(List<num> list) => _I8(ensureNative(list));
  factory Int8Array.fromBuffer(ArrayBuffer buffer) => _I8(buffer);

  factory Int16Array(int length) => _I16(length);
  factory Int16Array.fromList(List<num> list) => _I16(ensureNative(list));
  factory Int16Array.fromBuffer(ArrayBuffer buffer) => _I16(buffer);

  factory Int32Array(int length) => _I32(length);
  factory Int32Array.fromList(List<num> list) => _I32(ensureNative(list));
  factory Int32Array.fromBuffer(ArrayBuffer buffer) => _I32(buffer);

  factory Uint8Array(int length) => _U8(length);
  factory Uint8Array.fromList(List<num> list) => _U8(ensureNative(list));
  factory Uint8Array.fromBuffer(ArrayBuffer buffer) => _U8(buffer);

  factory Uint16Array(int length) => _U16(length);
  factory Uint16Array.fromList(List<num> list) => _U16(ensureNative(list));
  factory Uint16Array.fromBuffer(ArrayBuffer buffer) => _U16(buffer);

  factory Uint32Array(int length) => _U32(length);
  factory Uint32Array.fromList(List<num> list) => _U32(ensureNative(list));
  factory Uint32Array.fromBuffer(ArrayBuffer buffer) => _U32(buffer);

  factory Uint8ClampedArray(int length) => _U8C(length);
  factory Uint8ClampedArray.fromList(List<num> list) => _U8C(ensureNative(list));
  factory Uint8ClampedArray.fromBuffer(ArrayBuffer buffer) => _U8C(buffer);

  static Float32Array _F32(arg) native;
  static Float64Array _F64(arg) native;
  static Int8Array _I8(arg) native;
  static Int16Array _I16(arg) native;
  static Int32Array _I32(arg) native;
  static Uint8Array _U8(arg) native;
  static Uint16Array _U16(arg) native;
  static Uint32Array _U32(arg) native;
  static Uint8ClampedArray _U8C(arg) native;

  static ensureNative(List list) => list;  // TODO: make sure.
}

class _WebKitCSSMatrixFactoryProvider {

  factory WebKitCSSMatrix([String cssValue = '']) { return create(cssValue); }

  static WebKitCSSMatrix create(cssValue) native;
}

class _WebKitPointFactoryProvider {

  factory WebKitPoint(num x, num y) { return create(x, y); }

  static WebKitPoint create(x, y) native;
}

class _WebSocketFactoryProvider {

  factory WebSocket(String url) { return create(url); }

  static WebKitPoint create(url) native;
}

class _WorkerFactoryProvider {

  factory Worker(String scriptUrl) { return create(scriptUrl); }

  static create(scriptUrl) native;
}

class _XMLHttpRequestFactoryProvider {

  factory XMLHttpRequest() { return create(); }

  static XMLHttpRequest create() native;
}

class _XSLTProcessorFactoryProvider {

  factory XSLTProcessor() { return create(); }

  static XSLTProcessor create() native;
}

// TODO(sra): Fill in these:
class _DOMURLFactoryProvider {}
class _FileReaderSyncFactoryProvider {}
class _MediaControllerFactoryProvider {}
class _MessageChannelFactoryProvider {}
class _WebKitBlobBuilderFactoryProvider {}
class _XPathEvaluatorFactoryProvider {}
class _XMLSerializerFactoryProvider {}
