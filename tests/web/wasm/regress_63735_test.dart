// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:expect/expect.dart';

void main() {
  final ByteBuffer buf = Uint8List.fromList([1, 2, 3]).toJS.toDart.buffer;
  print(buf.lengthInBytes);

  // The dynamic receiver's inferred type set must include JSArrayBufferImpl,
  // so route the JS-backed buffer itself through the dynamic call site.
  final dynamic d = confuse(buf);
  Expect.throwsNoSuchMethodError(() {
    final tearOff = d.view; // dynamic tear-off of a member named `view`
    print(tearOff(0, 1));
    print(d.view(0, 1)); // dynamic invocation, same selector
  });
}

@pragma('dart2wasm:never-inline')
dynamic confuse(dynamic x) => x;
