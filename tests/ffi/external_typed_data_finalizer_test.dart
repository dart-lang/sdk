// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'dylib_utils.dart';

main() {
  // Force dlopen so @Native lookups in DynamicLibrary.process() succeed.
  dlopenGlobalPlatformSpecific('ffi_test_functions');

  testAsTypedList();
  testRefcounted();
}

void testAsTypedList() {
  const length = 10;
  final ptr = calloc(length, sizeOf<Int16>()).cast<Int16>();
  final typedList = ptr.asTypedList(length, finalizer: freePointer);
  print(typedList);
}

@Native<Pointer<Void> Function(IntPtr num, IntPtr size)>(isLeaf: true)
external Pointer<Void> calloc(int num, int size);

final freePointer = DynamicLibrary.process()
    .lookup<NativeFunction<Void Function(Pointer<Void>)>>('free');

void testRefcounted() {
  final peer = allocateRefcountedResource();
  final resource = peer.ref.resource;
  final typedList1 = resource.asTypedList(
    128,
    finalizer: decreaseRefcountPointer.cast(),
    token: peer.cast(),
  );
  increaseRefcount(peer);
  print(typedList1);
  final typedList2 = resource.asTypedList(
    128,
    finalizer: decreaseRefcountPointer.cast(),
    token: peer.cast(),
  );
  increaseRefcount(peer);
  print(typedList2);
}

@Native<Pointer<RefCountedResource> Function()>(
  symbol: 'AllocateRefcountedResource',
  isLeaf: true,
)
external Pointer<RefCountedResource> allocateRefcountedResource();

@Native<Void Function(Pointer<RefCountedResource>)>(
  symbol: 'IncreaseRefcount',
  isLeaf: true,
)
external void increaseRefcount(Pointer<RefCountedResource> peer);

final decreaseRefcountPointer = DynamicLibrary.process()
    .lookup<NativeFunction<Void Function(Pointer<RefCountedResource>)>>(
      'DecreaseRefcount',
    );

final class RefCountedResource extends Struct {
  external Pointer<Int8> resource;

  @IntPtr()
  external int refcount;
}
