// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for http://dartbug.com/47594.
// FFI leaf calls did not mark the thread for the transition and would cause
// the stack walker to segfault when it was unable to interpret the frame.
//
// VMOptions=--deterministic --enable-vm-service=0 --profiler --disable-dart-dev

import 'dart:ffi';

import 'package:ffi/ffi.dart';

final strerror = DynamicLibrary.process()
    .lookupFunction<Pointer<Utf8> Function(Int32), Pointer<Utf8> Function(int)>(
        'strerror',
        isLeaf: true);

void main() {
  for (var i = 0; i < 10000; i++) strerror(0).toDartString();
}
