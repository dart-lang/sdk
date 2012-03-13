// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class FactoryProviderImplementation {
  static AudioContext createAudioContext() native "AudioContext_constructor_Callback";
  static DOMParser createDOMParser() native "DOMParser_constructor_Callback";
  static DOMURL createDOMURL() native "DOMURL_constructor_Callback";
  static FileReader createFileReader() native "FileReader_constructor_Callback";
  static FileReaderSync createFileReaderSync() native "FileReaderSync_constructor_Callback";

  static EventSource createEventSource(String scriptUrl) native "EventSource_constructor_Callback";

  static HTMLAudioElement createHTMLAudioElement([String src]) native "HTMLAudioElement_constructor_Callback";

  static HTMLOptionElement createHTMLOptionElement([String data, String value, bool defaultSelected, bool selected]) native "HTMLOptionElement_constructor_Callback";

  static  MediaController createMediaController() native "MediaController_constructor_Callback";

  static MediaStream createMediaStream(MediaStreamTrackList audioTracks,
                                       MediaStreamTrackList videoTracks)
      native "MediaStream_constructor_Callback";

  static  MessageChannel createMessageChannel() native "MessageChannel_constructor_Callback";

  static PeerConnection createPeerConnection(
      String serverConfiguration,
      SignalingCallback signalingCallback)
      native "PeerConnection_constructor_Callback";

  static ShadowRoot createShadowRoot(Element host)
      native "ShadowRoot_constructor_Callback";

  static SharedWorker createSharedWorker(String scriptURL, String name)
      native "SharedWorker_constructor_Callback";

  static SpeechGrammar createSpeechGrammar() native "SpeechGrammar_constructor_Callback";
  static SpeechGrammarList createSpeechGrammarList() native "SpeechGrammarList_constructor_Callback";

  static TextTrackCue createTextTrackCue(
      String id, num startTime, num endTime, String text,
               String settings, bool pauseOnExit)
      native "TextTrackCue_constructor_Callback";

  static Float32Array F32(_arg0, [_arg1, _arg2]) native "Float32Array_constructor_Callback";
  static Float64Array F64(_arg0, [_arg1, _arg2]) native "Float64Array_constructor_Callback";
  static Int8Array I8(_arg0, [_arg1, _arg2]) native "Int8Array_constructor_Callback";
  static Int16Array I16(_arg0, [_arg1, _arg2]) native "Int16Array_constructor_Callback";
  static Int32Array I32(_arg0, [_arg1, _arg2]) native "Int32Array_constructor_Callback";
  static Uint8Array U8(_arg0, [_arg1, _arg2]) native "Uint8Array_constructor_Callback";
  static Uint16Array U16(_arg0, [_arg1, _arg2]) native "Uint16Array_constructor_Callback";
  static Uint32Array U32(_arg0, [_arg1, _arg2]) native "Uint32Array_constructor_Callback";
  
  static  WebKitBlobBuilder createWebKitBlobBuilder() native "WebKitBlobBuilder_constructor_Callback";
  static WebKitCSSMatrix createWebKitCSSMatrix([String spec = '']) native "WebKitCSSMatrix_constructor_Callback";
  static WebKitPoint createWebKitPoint(num x, num y) native "WebKitPoint_constructor_Callback";
  static WebSocket createWebSocket(String url) native "WebSocket_constructor_Callback";
  static Worker createWorkder(String scriptUrl) native "Worker_constructor_Callback";
  static XMLHttpRequest createXMLHttpRequest() native "XMLHttpRequest_constructor_Callback";
  static XMLSerializer createXMLSerializer() native "XMLSerializer_constructor_Callback";
  static XPathEvaluator createXPathEvaluator() native "XPathEvaluator_constructor_Callback";
  static XSLTProcessor createXSLTProcessor() native "XSLTProcessor_constructor_Callback";
}
