// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions
// VMOptions=
// VMOptions=--deterministic --optimization-counter-threshold=90
// VMOptions=--use-slow-path

import 'dart:ffi';
import 'dart:nativewrappers';
import 'dart:typed_data';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

import 'address_of_compound_return_test.dart'
    show Small, Large, IntegerOrDouble, Input, checkSmall, checkLarge;
import 'dylib_utils.dart';

@Native<Handle Function(Handle, IntPtr, IntPtr)>(
  symbol: 'Dart_SetNativeInstanceField',
)
external Object? setNativeField(Object peer, int index, int value);

base class Peer extends NativeFieldWrapperClass1 {
  Peer(Pointer<Uint8> pointer) {
    setNativeField(this, 0, pointer.address);
  }

  Peer.uninitialized();
}

@Native<Small Function(Pointer<Void>, Pointer<Uint8>)>(
  symbol: 'ReturnSmallFromNativeField',
  isLeaf: true,
)
external Small small(Peer peer, Pointer<Uint8> value);

@Native<Large Function(Pointer<Void>, Pointer<Uint8>)>(
  symbol: 'ReturnLargeFromNativeField',
  isLeaf: true,
)
external Large large(Peer peer, Pointer<Uint8> value);

class Natives {
  @Native<IntegerOrDouble Function(Pointer<Uint8>, Pointer<Void>)>(
    symbol: 'ReturnUnionFromNativeField',
    isLeaf: true,
  )
  external static IntegerOrDouble union(Pointer<Uint8> value, Peer peer);
}

@Native<Int64 Function(Pointer<Void>, Pointer<Uint8>)>(
  symbol: 'AddNativeFieldAndPointer',
  isLeaf: true,
)
external int integer(Peer peer, Pointer<Uint8> value);

final evaluations = <String>[];

Peer evaluatePeer(Peer peer) {
  evaluations.add('peer');
  return peer;
}

Uint8List evaluateData(Uint8List data) {
  evaluations.add('data');
  return data;
}

void main() {
  dlopenGlobalPlatformSpecific('ffi_test_functions');
  final storage = calloc<Uint8>()..value = 7;
  try {
    final peer = Peer(storage);
    for (var i = 0; i < 100; i++) {
      testReturns(peer);
    }
  } finally {
    calloc.free(storage);
  }
}

void testReturns(Peer peer) {
  final data = Uint8List.fromList([9, 20, 30]);
  evaluations.clear();
  checkSmall(small(evaluatePeer(peer), evaluateData(data).address), 16);
  Expect.listEquals(['peer', 'data'], evaluations);
  Expect.equals(10, data[0]);
  checkLarge(large(peer, data.address), 17);
  Expect.equals(11, data[0]);

  // The native-field argument occupies a different position in this signature.
  // This union is only constructed by .address calls, including in AOT.
  Expect.equals(18, Natives.union(data.address, peer).integer);
  Expect.equals(12, data[0]);
  Expect.equals(19, integer(peer, data.address));
  Expect.equals(13, data[0]);

  final view = Uint8List.sublistView(data, 1);
  checkSmall(small(peer, view.address), 27);
  checkLarge(large(peer, data[1].address), 28);
  Expect.equals(22, data[1]);
  checkSmall(small(peer, data.address.cast()), 20);
  Expect.equals(14, data[0]);

  final input = Struct.create<Input>()..value = 40;
  checkSmall(small(peer, input.address.cast()), 47);
  checkLarge(large(peer, input.value.address), 48);
  Expect.equals(42, input.value);
  input.values[1] = 50;
  checkSmall(small(peer, input.values[1].address), 57);
  Expect.equals(51, input.values[1]);

  final pointer = calloc<Uint8>()..value = 60;
  try {
    checkSmall(small(peer, pointer), 67);
    checkLarge(large(peer, pointer), 68);
    Expect.equals(62, pointer.value);
  } finally {
    calloc.free(pointer);
  }

  // Argument expressions run before the wrapper tries to extract a native
  // field. Preserve both their order and the error for an uninitialized peer.
  evaluations.clear();
  Expect.throws(
    () => small(evaluatePeer(Peer.uninitialized()), evaluateData(data).address),
  );
  Expect.listEquals(['peer', 'data'], evaluations);
  Expect.equals(14, data[0]);
}
