// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.serialization;

import '../common/backend_api.dart' show BackendSerialization;
import '../elements/elements.dart';
import '../serialization/serialization.dart'
    show DeserializerPlugin, ObjectDecoder, ObjectEncoder, SerializerPlugin;
import '../serialization/keys.dart';
import 'js_backend.dart';

const String _BACKEND_DATA_TAG = 'jsBackendData';

class JavaScriptBackendSerialization implements BackendSerialization {
  final JavaScriptBackendSerializer serializer;
  final JavaScriptBackendDeserializer deserializer;

  JavaScriptBackendSerialization(JavaScriptBackend backend)
      : serializer = new JavaScriptBackendSerializer(backend),
        deserializer = new JavaScriptBackendDeserializer(backend);
}

class JavaScriptBackendSerializer implements SerializerPlugin {
  final JavaScriptBackend backend;

  JavaScriptBackendSerializer(this.backend);

  @override
  void onElement(Element element, ObjectEncoder createEncoder(String tag)) {
    // TODO(johnniwinther): Add more data, e.g. js-interop names, native tags,
    // etc.
    String nativeName = backend.nativeData.nativeMemberName[element];
    if (nativeName != null) {
      ObjectEncoder encoder = createEncoder(_BACKEND_DATA_TAG);
      encoder.setString(Key.NAME, nativeName);
    }
  }
}

class JavaScriptBackendDeserializer implements DeserializerPlugin {
  final JavaScriptBackend backend;

  JavaScriptBackendDeserializer(this.backend);

  @override
  void onElement(Element element, ObjectDecoder getDecoder(String tag)) {
    ObjectDecoder decoder = getDecoder(_BACKEND_DATA_TAG);
    if (decoder != null) {
      String nativeName = decoder.getString(Key.NAME);
      backend.nativeData.nativeMemberName[element] = nativeName;
    }
  }
}
