// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_embedder' as embedder;
import "dart:_js_helper" show jsStringFromDartString, JSExternWrapperExt;
import 'dart:_string' show JSStringImpl;
import 'dart:_wasm';

String jsonEncode(String object) => JSStringImpl.fromRef(
  embedder.jsonEncodeString(jsStringFromDartString(object).wrappedExternRef),
);
