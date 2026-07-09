// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the `SharedArrayBuffer` interface exposed through `dart:html` and make
// sure it's well-typed.

import 'dart:html';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:expect/expect.dart';

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(f) => f;

@JS('SharedArrayBuffer')
external JSAny? get _sharedArrayBufferConstructor;

bool supportsSharedArrayBuffer = _sharedArrayBufferConstructor != null;

void main() {
  // TODO(https://github.com/dart-lang/sdk/issues/61043): Support this in the
  // test runner.
  if (!supportsSharedArrayBuffer) return;
  final buf = SharedArrayBuffer(3);
  Expect.equals(3, buf.byteLength);
  final bufNoArgs = SharedArrayBuffer();
  Expect.equals(0, bufNoArgs.byteLength);

  final slice1 = buf.slice();
  Expect.equals(3, slice1.byteLength);
  final slice2 = buf.slice(1);
  Expect.equals(2, slice2.byteLength);
  final slice3 = buf.slice(1, 2);
  Expect.equals(1, slice3.byteLength);

  Expect.isTrue(buf is SharedArrayBuffer);
  buf as SharedArrayBuffer;
  Expect.isTrue(confuse(buf) is SharedArrayBuffer);
  confuse(buf) as SharedArrayBuffer;

  // This should be true in order to allow typed lists to contain
  // `SharedArrayBuffer`s.
  Expect.isTrue(buf is ByteBuffer);
  buf as ByteBuffer;
  Expect.isTrue(confuse(buf) is ByteBuffer);
  confuse(buf) as ByteBuffer;
}
