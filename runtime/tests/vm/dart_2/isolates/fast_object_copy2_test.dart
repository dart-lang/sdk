// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// VMOptions=--no-enable-fast-object-copy
// VMOptions=--enable-fast-object-copy
// VMOptions=--no-enable-fast-object-copy --gc-on-foc-slow-path --force-evacuation
// VMOptions=--enable-fast-object-copy --gc-on-foc-slow-path --force-evacuation

// The tests in this file will only succeed when isolate groups are enabled
// (hence the VMOptions above).

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:expect/expect.dart';

import 'fast_object_copy_test.dart'
    show UserObject, SendReceiveTestBase, notAllocatableInTLAB;

topLevelClosure(a, b) {}
topLevelClosureG<T>(T a, T b) {}
Type getType<T>() => T;

class A<T> {
  dynamic m<H>(T a, H b) => this;
}

// When running with isolate groups enabled, we can share all of the following
// objects.
final sharableObjects = [
  1,
  0xffffffffffffffff,
  'foobar',
  const UserObject(1, 1.2, ''),
  (() {
    final rp = ReceivePort();
    final sp = rp.sendPort;
    rp.close();
    return sp;
  })(),
  () {
    innerClosure(a, b) {}
    return innerClosure;
  }(),
  () {
    innerClosureG<T>(T a, T b) {}
    return innerClosureG;
  }(),
  () {
    innerClosureG<T>() {
      innerClosureG2<H>(T a, H b) {}
      return innerClosureG2;
    }

    return innerClosureG<int>();
  }(),
  () {
    innerClosureG<T>(T a, T b) {}
    final Function(int, int) partialInstantiatedInnerClosure = innerClosureG;
    return partialInstantiatedInnerClosure;
  }(),
  () {
    return topLevelClosureG;
  }(),
  () {
    final Function(int, int) partialInstantiatedInnerClosure = topLevelClosureG;
    return partialInstantiatedInnerClosure;
  }(),
  getType<void Function(int, double, Object)>(),
  const [1, 2, 3],
  const {1: 1, 2: 2, 3: 2},
  const {1, 2, 3},
  RegExp('a'),
  Isolate.current.pauseCapability,
  Int32x4(1, 2, 3, 4),
  StackTrace.current,
];

final copyableClosures = <dynamic>[
  () {
    final a = A<int>();
    final Function<T>(int, T) genericMethod = a.m;
    return genericMethod;
  }(),
  () {
    final a = A<int>();
    final Function(int, double) partialInstantiatedMethod = a.m;
    return partialInstantiatedMethod;
  }(),
  () {
    final a = Object();
    dynamic inner() => a;
    return inner;
  }(),
  () {
    foo(var arg) {
      return () => arg;
    }

    return foo(1);
  }(),
];

class SendReceiveTest extends SendReceiveTestBase {
  Future runTests() async {
    await testSharable();
    await testSharable2();
    await testCopyableClosures();
  }

  Future testSharable() async {
    print('testSharable');
    final sharableObjectsCopy = await sendReceive([
      ...sharableObjects,
    ]);
    Expect.notIdentical(sharableObjects, sharableObjectsCopy);
    for (int i = 0; i < sharableObjects.length; ++i) {
      Expect.identical(sharableObjects[i], sharableObjectsCopy[i]);
    }
  }

  Future testSharable2() async {
    print('testSharable2');
    final sharableObjectsCopy = await sendReceive([
      notAllocatableInTLAB,
      ...sharableObjects,
    ]);
    Expect.notIdentical(sharableObjects, sharableObjectsCopy);
    Expect.equals(
        notAllocatableInTLAB[0], (sharableObjectsCopy[0] as Uint8List)[0]);
    for (int i = 0; i < sharableObjects.length; ++i) {
      Expect.identical(sharableObjects[i], sharableObjectsCopy[i + 1]);
    }
  }

  Future testCopyableClosures() async {
    print('testCopyableClosures');
    final copy = await sendReceive([
      notAllocatableInTLAB,
      ...copyableClosures,
    ]);
    for (int i = 0; i < copyableClosures.length; ++i) {
      Expect.notIdentical(copyableClosures[i], copy[1 + i]);
      Expect.equals(copyableClosures[i].runtimeType, copy[1 + i].runtimeType);
    }

    final copy2 = await sendReceive([
      ...copyableClosures,
      notAllocatableInTLAB,
    ]);
    for (int i = 0; i < copyableClosures.length; ++i) {
      Expect.notIdentical(copyableClosures[i], copy2[i]);
      Expect.equals(copyableClosures[i].runtimeType, copy2[i].runtimeType);
    }
  }
}

main() async {
  await SendReceiveTest().run();
}
