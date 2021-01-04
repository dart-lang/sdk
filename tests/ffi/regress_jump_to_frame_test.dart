// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that JumpToFrame does not use LR clobbered by slow path of
// TransitionNativeToGenerated.
// VMOptions=--use-slow-path --enable-testing-pragmas

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:expect/expect.dart';

typedef CallbackDartType = Object Function();
typedef CallbackNativeType = Handle Function();

Object alwaysThrows() {
  throw 'exception';
}

void alwaysCatches(CallbackDartType f) {
  try {
    propagateError(f());
  } catch (e) {
    Expect.equals('exception', e);
    return;
  }
  Expect.isTrue(false);
}

void main() {
  final ptr = Pointer.fromFunction<CallbackNativeType>(alwaysThrows);
  final f = ptr.asFunction<CallbackDartType>();
  alwaysCatches(f);
}

typedef Dart_PropagateError_NativeType = Void Function(Handle);
typedef Dart_PropagateError_DartType = void Function(Object);

final Dart_PropagateError_DartType propagateError = () {
  final Pointer<_DartApi> dlapi = NativeApi.initializeApiDLData.cast();
  for (int i = 0; dlapi.ref.functions[i].name != nullptr; i++) {
    final name = Utf8.fromUtf8(dlapi.ref.functions[i].name.cast<Utf8>());
    if (name == 'Dart_PropagateError') {
      return dlapi.ref.functions[i].function
          .cast<NativeFunction<Dart_PropagateError_NativeType>>()
          .asFunction<Dart_PropagateError_DartType>();
    }
  }
  throw 'Not found';
}();

class _DartEntry extends Struct {
  external Pointer<Int8> name;
  external Pointer<Void> function;
}

class _DartApi extends Struct {
  @Int32()
  external int major;
  @Int32()
  external int minor;
  external Pointer<_DartEntry> functions;
}
