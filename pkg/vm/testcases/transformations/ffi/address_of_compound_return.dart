// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:nativewrappers';
import 'dart:typed_data';

final class Result extends Struct {
  @Int64()
  external int value;
}

final class UnionResult extends Union {
  @Int64()
  external int value;
}

@Native<Result Function(Pointer<Uint8>, Pointer<Uint8>)>(isLeaf: true)
external Result makeResult(Pointer<Uint8> a, Pointer<Uint8> b);

class Natives {
  @Native<UnionResult Function(Pointer<Uint8>)>(isLeaf: true)
  external static UnionResult makeUnion(Pointer<Uint8> a);
}

base class Peer extends NativeFieldWrapperClass1 {}

@Native<Result Function(Pointer<Void>, Pointer<Uint8>, Pointer<Uint8>)>(
  isLeaf: true,
)
external Result makeWithPeer(Peer peer, Pointer<Uint8> a, Pointer<Uint8> b);

@Native<Int64 Function(Pointer<Void>, Pointer<Uint8>)>(isLeaf: true)
external int integerWithPeer(Peer peer, Pointer<Uint8> a);

void main() {
  final data = Uint8List(2);
  final peer = Peer();
  print(makeWithPeer(peer, data.address, nullptr).value);
  print(makeWithPeer(peer, data.address, nullptr).value);
  print(makeWithPeer(peer, nullptr, data[1].address).value);
  print(makeWithPeer(peer, data.address, data[1].address).value);
  print(integerWithPeer(peer, data.address));
  print(makeResult(nullptr, nullptr).value);
  print(makeResult(data.address, data.address).value);
  // Reuse the same specialization, then specialize different arguments.
  print(makeResult(data.address, data.address).value);
  print(makeResult(nullptr, data.address).value);
  print(makeResult(data[1].address, nullptr).value);
  // This union is only constructed by an address call. Its constructor must
  // survive AOT tree shaking even though the original wrapper is unused.
  print(Natives.makeUnion(data.address).value);
}
