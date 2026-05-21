// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_embedder' as embedder;
import 'dart:_string' show embedderStringFromDartString, EmbedderStringImpl;
import 'dart:_wasm';

String jsonEncode(String object) => EmbedderStringImpl.fromRefUnchecked(
  embedder.jsonEncodeString(
    embedderStringFromDartString(object).wrappedExternRef,
  ),
);
