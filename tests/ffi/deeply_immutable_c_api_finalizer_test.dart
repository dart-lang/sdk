// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'dylib_utils.dart';

void main() async {
  final myFinalizable2 = await Isolate.run(() => MyFinalizable());
  print(myFinalizable2);
  print(myFinalizable2.pointer);
  // This would crash if a NativeFinalizer would have been attached and run
  // eagerly on `Isolate.exit`.
  print(myFinalizable2.pointer.value);
}

@pragma('vm:deeply-immutable')
final class MyFinalizable implements Finalizable {
  final Pointer<Int> pointer;

  MyFinalizable._(this.pointer);

  factory MyFinalizable() {
    final pointer = calloc(sizeOf<Int>(), 10).cast<Int>();
    pointer.value = 123;
    final result = MyFinalizable._(pointer);
    newFinalizableHandle(
      result,
      pointer.cast(),
      0,
      freeFinalizer, // Not the signature of `free`!
    );
    return result;
  }
}

final calloc =
    dlopenPlatformSpecific("ffi_test_functions")
        .lookup<NativeFunction<Pointer<Void> Function(Size, Size)>>('Calloc')
        .asFunction<Pointer<Void> Function(int, int)>();

final freeFinalizer = dlopenPlatformSpecific(
  "ffi_test_functions",
).lookup<NativeFunction<Dart_HandleFinalizerFunction>>('FreeFinalizer');

final Dart_FinalizableHandle Function(
  Object,
  Pointer<Void>,
  int,
  Dart_HandleFinalizer,
)
newFinalizableHandle =
    _findDartApiFunction('Dart_NewFinalizableHandle')
        .cast<
          NativeFunction<
            Dart_FinalizableHandle Function(
              Handle,
              Pointer<Void>,
              IntPtr,
              Dart_HandleFinalizer,
            )
          >
        >()
        .asFunction();

final void Function(Dart_FinalizableHandle, Object) deleteFinalizableHandle =
    _findDartApiFunction('Dart_DeleteFinalizableHandle')
        .cast<NativeFunction<Void Function(Dart_FinalizableHandle, Handle)>>()
        .asFunction();

Pointer<Void> _findDartApiFunction(String name) {
  final dartApi = NativeApi.initializeApiDLData.cast<DartApi>();
  var entry = dartApi.ref.functions;
  while (true) {
    final entryName = entry.ref.name.cast<Utf8>().toDartString();
    if (entryName == name) {
      return entry.ref.function;
    }
    if (name == 'Dart_Null') {
      throw StateError('Dart API function with $name not found.');
    }
    entry++;
  }
}

final class DartApi extends Struct {
  @Int()
  external int major;

  @Int()
  external int minor;

  external Pointer<DartApiEntry> functions;
}

final class DartApiEntry extends Struct {
  external Pointer<Char> name;

  external Pointer<Void> function;
}

final class _Dart_FinalizableHandle extends Opaque {}

typedef Dart_HandleFinalizer =
    Pointer<NativeFunction<Dart_HandleFinalizerFunction>>;
typedef Dart_HandleFinalizerFunction =
    Void Function(Pointer<Void> isolate_callback_data, Pointer<Void> peer);
typedef DartDart_HandleFinalizerFunction =
    void Function(Pointer<Void> isolate_callback_data, Pointer<Void> peer);
typedef Dart_FinalizableHandle = Pointer<_Dart_FinalizableHandle>;
