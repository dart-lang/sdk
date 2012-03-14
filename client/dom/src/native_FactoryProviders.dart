// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _AudioContextFactoryProvider {
  factory AudioContext() => FactoryProviderImplementation.createAudioContext();
}

class _DOMParserFactoryProvider {
  factory DOMParser() => FactoryProviderImplementation.createDOMParser();
}

class _DOMURLFactoryProvider {
  factory DOMURL() => FactoryProviderImplementation.createDOMURL();
}

class _EventSourceFactoryProvider {
  factory EventSource(String scriptUrl) =>
      FactoryProviderImplementation.createEventSource(scriptUrl);
}

class _DeprecatedPeerConnectionFactoryProvider {
  factory DeprecatedPeerConnection(String serverConfiguration,
                         SignalingCallback signalingCallback) =>
      FactoryProviderImplementation.createDeprecatedPeerConnection(serverConfiguration, signalingCallback);
}

class _FileReaderFactoryProvider {
  factory FileReader() => FactoryProviderImplementation.createFileReader();
}

class _FileReaderSyncFactoryProvider {
  factory FileReaderSync() => FactoryProviderImplementation.createFileReaderSync();
}

class _HTMLAudioElementFactoryProvider {
  factory HTMLAudioElement([String src]) => FactoryProviderImplementation.createHTMLAudioElement(src);
}

class _HTMLOptionElementFactoryProvider {
  factory HTMLOptionElement([String data, String value, bool defaultSelected, bool selected]) =>
      FactoryProviderImplementation.createHTMLOptionElement(data, value, defaultSelected, selected);
}

class _MediaControllerFactoryProvider {
  factory MediaController() => FactoryProviderImplementation.createMediaController();
}

class _MediaStreamFactoryProvider {
  factory MediaStream(MediaStreamTrackList audioTracks,
                      MediaStreamTrackList videoTracks) =>
      FactoryProviderImplementation.createMediaStream(audioTracks, videoTracks);
}

class _MessageChannelFactoryProvider {
  factory MessageChannel() => FactoryProviderImplementation.createMessageChannel();
}

class _ShadowRootFactoryProvider {
  factory ShadowRoot(Element host) =>
      FactoryProviderImplementation.createShadowRoot(host);
}

class _SharedWorkerFactoryProvider {
  factory SharedWorker(String scriptURL, [String name]) =>
      FactoryProviderImplementation.createSharedWorker(scriptURL, name);
}

class _SpeechGrammarFactoryProvider {
  factory SpeechGrammar() => FactoryProviderImplementation.createSpeechGrammar();
}

class _SpeechGrammarListFactoryProvider {
  factory SpeechGrammarList() => FactoryProviderImplementation.createSpeechGrammarList();
}

class _TextTrackCueFactoryProvider {
  factory TextTrackCue(String id, num startTime, num endTime, String text,
                       [String settings, bool pauseOnExit]) =>
      FactoryProviderImplementation.createTextTrackQue(
          id, startTime, endTime, text, settings, pauseOnExit);
}

class _TypedArrayFactoryProvider {
  factory Float32Array(int length) => FactoryProviderImplementation.F32(length);
  factory Float32Array.fromList(List<num> list) => FactoryProviderImplementation.F32(list);
  factory Float32Array.fromBuffer(ArrayBuffer buffer) => FactoryProviderImplementation.F32(buffer);

  factory Float64Array(int length) => FactoryProviderImplementation.F64(length);
  factory Float64Array.fromList(List<num> list) => FactoryProviderImplementation.F64(list);
  factory Float64Array.fromBuffer(ArrayBuffer buffer) => FactoryProviderImplementation.F64(buffer);

  factory Int8Array(int length) => FactoryProviderImplementation.I8(length);
  factory Int8Array.fromList(List<num> list) => FactoryProviderImplementation.I8(list);
  factory Int8Array.fromBuffer(ArrayBuffer buffer) => FactoryProviderImplementation.I8(buffer);

  factory Int16Array(int length) => FactoryProviderImplementation.I16(length);
  factory Int16Array.fromList(List<num> list) => FactoryProviderImplementation.I16(list);
  factory Int16Array.fromBuffer(ArrayBuffer buffer) => FactoryProviderImplementation.I16(buffer);

  factory Int32Array(int length) => FactoryProviderImplementation.I32(length);
  factory Int32Array.fromList(List<num> list) => FactoryProviderImplementation.I32(list);
  factory Int32Array.fromBuffer(ArrayBuffer buffer) => FactoryProviderImplementation.I32(buffer);

  factory Uint8Array(int length) => FactoryProviderImplementation.U8(length);
  factory Uint8Array.fromList(List<num> list) => FactoryProviderImplementation.U8(list);
  factory Uint8Array.fromBuffer(ArrayBuffer buffer) => FactoryProviderImplementation.U8(buffer);

  factory Uint16Array(int length) => FactoryProviderImplementation.U16(length);
  factory Uint16Array.fromList(List<num> list) => FactoryProviderImplementation.U16(list);
  factory Uint16Array.fromBuffer(ArrayBuffer buffer) => FactoryProviderImplementation.U16(buffer);

  factory Uint32Array(int length) => FactoryProviderImplementation.U32(length);
  factory Uint32Array.fromList(List<num> list) => FactoryProviderImplementation.U32(list);
  factory Uint32Array.fromBuffer(ArrayBuffer buffer) => FactoryProviderImplementation.U32(buffer);
}

class _WebKitCSSMatrixFactoryProvider {
  factory WebKitCSSMatrix([String spec = '']) => FactoryProviderImplementation.createWebKitCSSMatrix(spec);
}

class _WebKitBlobBuilderFactoryProvider {
  factory WebKitBlobBuilder() => FactoryProviderImplementation.createWebKitBlobBuilder();
}

class _WebKitPointFactoryProvider {
  factory WebKitPoint(num x, num y) => FactoryProviderImplementation.createWebKitPoint(x, y);
}

class _WebSocketFactoryProvider {
  factory WebSocket(String url) => FactoryProviderImplementation.createWebSocket(url);
}

class _WorkerFactoryProvider {
  factory Worker(String scriptUrl) =>
      FactoryProviderImplementation.createWorker(scriptUrl);
}
class _XMLHttpRequestFactoryProvider {
  factory XMLHttpRequest() => FactoryProviderImplementation.createXMLHttpRequest();
}

class _XMLSerializerFactoryProvider {
  factory XMLSerializer() => FactoryProviderImplementation.createXMLSerializer();
}

class _XPathEvaluatorFactoryProvider {
  factory XPathEvaluator() => FactoryProviderImplementation.createXPathEvaluator();
}

class _XSLTProcessorFactoryProvider {
  factory XSLTProcessor() => FactoryProviderImplementation.createXSLTProcessor();
}
