// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Helpers for tests which trigger GC in delicate places.

// ignore: import_internal_library, unused_import
import 'dart:_internal';
import 'dart:ffi';

import 'dylib_utils.dart';

typedef NativeNullaryOp = Void Function();
typedef NullaryOpVoid = void Function();

typedef NativeUnaryOp = Void Function(IntPtr);
typedef UnaryOpVoid = void Function(int);

final DynamicLibrary ffiTestFunctions =
    dlopenPlatformSpecific("ffi_test_functions");

final collectOnNthAllocation = ffiTestFunctions
    .lookupFunction<NativeUnaryOp, UnaryOpVoid>("CollectOnNthAllocation");

extension PointerOffsetBy<T extends NativeType> on Pointer<T> {
  Pointer<T> offsetBy(int bytes) => Pointer.fromAddress(address + bytes);
}

/// Triggers garbage collection.
// Defined in `dart:_internal`.
// ignore: undefined_identifier
void triggerGc() => VMInternalsForTesting.collectAllGarbage();

void Function(String) _namedPrint(String? name) {
  if (name != null) {
    return (String value) => print('$name: $value');
  }
  return (String value) => print(value);
}

/// Does a GC and if [doAwait] awaits a future to enable running finalizers.
///
/// Also prints for debug purposes.
///
/// If provided, [name] prefixes the debug prints.
void doGC({String? name}) {
  final _print = _namedPrint(name);

  _print('Do GC.');
  triggerGc();
  _print('GC done');
}

void createAndLoseFinalizable(Pointer<IntPtr> token) {
  final myFinalizable = MyFinalizable();
  setTokenFinalizer.attach(myFinalizable, token.cast());
}

final setTokenTo42Ptr =
    ffiTestFunctions.lookup<NativeFinalizerFunction>("SetArgumentTo42");
final setTokenFinalizer = NativeFinalizer(setTokenTo42Ptr);

class MyFinalizable implements Finalizable {}
