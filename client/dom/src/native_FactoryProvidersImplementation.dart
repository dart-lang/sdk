// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class FactoryProviderImplementation {
  static AudioContext createAudioContext() native "AudioContext_constructor_Callback";
  static DOMParser createDOMParser() native "DOMParser_constructor_Callback";
  static FileReader createFileReader() native "FileReader_constructor_Callback";

  static Float32Array F32(_arg0, [_arg1, _arg2]) native "Float32Array_constructor_Callback";
  static Float64Array F64(_arg0, [_arg1, _arg2]) native "Float64Array_constructor_Callback";
  static Int8Array I8(_arg0, [_arg1, _arg2]) native "Int8Array_constructor_Callback";
  static Int16Array I16(_arg0, [_arg1, _arg2]) native "Int16Array_constructor_Callback";
  static Int32Array I32(_arg0, [_arg1, _arg2]) native "Int32Array_constructor_Callback";
  static Uint8Array U8(_arg0, [_arg1, _arg2]) native "Uint8Array_constructor_Callback";
  static Uint16Array U16(_arg0, [_arg1, _arg2]) native "Uint16Array_constructor_Callback";
  static Uint32Array U32(_arg0, [_arg1, _arg2]) native "Uint32Array_constructor_Callback";
  
  static WebKitCSSMatrix createWebKitCSSMatrix([String spec = '']) native "WebKitCSSMatrix_constructor_Callback";
  static WebKitPoint createWebKitPoint(num x, num y) native "WebKitPoint_constructor_Callback";
  static WebSocket createWebSocket(String url) native "WebSocket_constructor_Callback";
  static XMLHttpRequest createXMLHttpRequest() native "XMLHttpRequest_constructor_Callback";
}
