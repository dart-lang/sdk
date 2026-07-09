// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions
//
// VMOptions=--trace-finalizers

import 'dart:ffi';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

import 'dylib_utils.dart';
import 'ffi_test_helpers.dart';

void main() {
  testFinalizerRuns();
  testFinalizerDetach();
  testDoubleDetach();
  testDetachNonDetach();
  testWrongArguments();
}

DynamicLibrary ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

void testFinalizerRuns() {
  using((Arena allocator) {
    final token = allocator<IntPtr>();
    createAndLoseFinalizable(token);
    doGC();
    Expect.equals(42, token.value);
  });
}

void createAndLoseFinalizable(Pointer<IntPtr> token) {
  final myFinalizable = MyFinalizable();
  setTokenFinalizer.attach(myFinalizable, token.cast());
  Expect.equals(0, token.value);
}

void testFinalizerDetach() {
  using((Arena allocator) {
    final token = allocator<IntPtr>();
    attachAndDetach(token);
    doGC();
    Expect.equals(0, token.value);
  });
}

class Detach {
  String identifier;

  Detach(this.identifier);
}

void attachAndDetach(Pointer<IntPtr> token) {
  final myFinalizable = MyFinalizable();
  final detach = Detach('detach 123');
  setTokenFinalizer.attach(myFinalizable, token.cast(), detach: detach);
  setTokenFinalizer.detach(detach);
  Expect.equals(0, token.value);
}

void testDoubleDetach() {
  using((Arena allocator) {
    final token = allocator<IntPtr>();
    final myFinalizable = MyFinalizable();
    final detach = Detach('detach 321');
    setTokenFinalizer.attach(myFinalizable, token.cast(), detach: detach);
    setTokenFinalizer.detach(detach);
    setTokenFinalizer.detach(detach);
    Expect.equals(0, token.value);
  });
}

void testDetachNonDetach() {
  final detach = Detach('detach 456');
  setTokenFinalizer.detach(detach);
  setTokenFinalizer.detach(detach);
}

void testWrongArguments() {
  using((Arena allocator) {
    final token = allocator<IntPtr>().cast<Void>();
    Expect.throws(() {
      final myFinalizable = MyFinalizable();
      setTokenFinalizer.attach(myFinalizable, token, externalSize: -1024);
    });
    Expect.throws(() {
      final myFinalizable = MyFinalizable();
      setTokenFinalizer.attach(myFinalizable, token, detach: 123);
    });
  });
}
