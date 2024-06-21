// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch, unsafeCast;
import 'dart:_string' show JSStringImpl;
import 'dart:_wasm';

@patch
@pragma('wasm:prefer-inline')
JSStringImpl jsStringFromDartString(String s) => unsafeCast<JSStringImpl>(s);

@patch
@pragma('wasm:prefer-inline')
String jsStringToDartString(JSStringImpl s) => s;
