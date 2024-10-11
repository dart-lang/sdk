// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:expect/config.dart';

final invalidObjects = [true, 1, 1.2, 'a'];

main() async {
  testFinalizerAttachDetachArgumentValidation();

  // This test doesn't work reliably on the web yet as it's hard to trigger GC
  // that will run finalizer and weak reference processing.
  if (isVmConfiguration) {
    asyncStart();
    await testFinalizerInvocation();
    asyncEnd();
  }
}

void testFinalizerAttachDetachArgumentValidation() {
  final finalizer = Finalizer<Foo?>((Foo? foo) {});
  final foo = Foo();

  // Tests invalid arguments.
  for (final invalid in invalidObjects) {
    // Test invalid targets.
    Expect.throws(() => finalizer.attach(invalid, foo));
    Expect.throws(() => finalizer.attach(invalid, null));
    Expect.throws(() => finalizer.attach(invalid, foo, detach: foo));
    Expect.throws(() => finalizer.attach(invalid, null, detach: null));

    // Test invalid detach tokens.
    Expect.throws(() => finalizer.attach(foo, foo, detach: invalid));
    Expect.throws(() => finalizer.attach(foo, null, detach: invalid));

    Expect.throws(() => finalizer.detach(invalid));
  }

  final target = Foo();

  // Should not cause errors to attach
  finalizer.attach(target, foo);
  finalizer.attach(target, null);
  finalizer.attach(target, foo, detach: target);

  // Can detach with arbitrary (valid) objects.
  finalizer.detach(target);
  finalizer.detach(foo);
  finalizer.detach({});
}

Future testFinalizerInvocation() async {
  final invokedPeers = <Foo>{};
  final expectedPeersInvoked = <Foo>{};
  final finalizer = Finalizer<Foo>((Foo peer) {
    invokedPeers.add(peer);
    asyncEnd();
  });
  {
    for (int i = 0; i < 10; ++i) {
      final peer = Foo();
      finalizer.attach(Foo(), peer, detach: peer);
      if (i % 3 == 0) {
        finalizer.detach(peer);
      } else {
        asyncStart();
        expectedPeersInvoked.add(peer);
      }
    }
  }
  asyncStart();
  while (invokedPeers.length < expectedPeersInvoked.length) {
    produceGarbage();
    await Future.delayed(const Duration(milliseconds: 10));
  }
  finalizer.detach(Foo()); // Dummy use of [finalizer] to ensure it's not GCed.
  for (final peer in expectedPeersInvoked) {
    Expect.isTrue(invokedPeers.contains(peer));
  }
  asyncEnd();
}

void produceGarbage() {
  const approximateWordSize = 4;

  List<dynamic> sink = [];
  for (int i = 0; i < 500; ++i) {
    final filler = i % 2 == 0 ? 1 : sink;
    if (i % 250 == 1) {
      // 2 x 25 MB in old space.
      sink = List.filled(25 * 1024 * 1024 ~/ approximateWordSize, filler);
    } else {
      // 498 x 50 KB in new space
      sink = List.filled(50 * 1024 ~/ approximateWordSize, filler);
    }
  }
  print(sink.hashCode); // Ensure there's real use of the allocation.
}

class Foo {}
