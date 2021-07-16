// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups --no-enable-fast-object-copy
// VMOptions=--enable-isolate-groups --enable-fast-object-copy
// VMOptions=--enable-isolate-groups --no-enable-fast-object-copy --gc-on-foc-slow-path --force-evacuation
// VMOptions=--enable-isolate-groups --enable-fast-object-copy --gc-on-foc-slow-path --force-evacuation

// The tests in this file will only succeed when isolate groups are enabled
// (hence the VMOptions above).

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:expect/expect.dart';

import 'fast_object_copy_test.dart'
    show UserObject, SendReceiveTestBase, notAllocatableInTLAB;

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
  const [1, 2, 3],
  const {1: 1, 2: 2, 3: 2},
  const {1, 2, 3},
  RegExp('a'),
  Isolate.current.pauseCapability,
  Int32x4(1, 2, 3, 4),
];

class SendReceiveTest extends SendReceiveTestBase {
  Future runTests() async {
    await testSharable();
    await testSharable2();
  }

  Future testSharable() async {
    final sharableObjectsCopy = await sendReceive([
      ...sharableObjects,
    ]);
    Expect.notIdentical(sharableObjects, sharableObjectsCopy);
    for (int i = 0; i < sharableObjects.length; ++i) {
      Expect.identical(sharableObjects[i], sharableObjectsCopy[i]);
    }
  }

  Future testSharable2() async {
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
}

main() async {
  await SendReceiveTest().run();
}
