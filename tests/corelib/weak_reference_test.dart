// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:expect/config.dart';

import 'finalizer_test.dart' show invalidObjects, produceGarbage, Foo;

main() async {
  testWeakReferenceArgumentValidation();

  // This test doesn't work reliably on the web yet as it's hard to trigger GC
  // that will run finalizer and weak reference processing.
  if (isVmConfiguration) {
    asyncStart();
    await testWeakReferenceWeakness();
    asyncEnd();
  }
}

void testWeakReferenceArgumentValidation() {
  final foo = Foo();
  final weakRef = WeakReference(foo);
  Expect.equals(weakRef.target, foo);

  for (final invalid in invalidObjects) {
    Expect.throws(() => WeakReference(invalid));
  }
}

Future testWeakReferenceWeakness() async {
  late final WeakReference<Foo> weakReference;
  {
    Foo? foo = Foo();
    weakReference = WeakReference<Foo>(foo);
    Expect.equals(weakReference.target, foo);
    foo = null;
  }
  asyncStart();
  // According to the WeakReference specification:
  //
  // There are no guarantees that a weak reference will ever be cleared
  // even if all references to its target are weak references.
  //
  // Wait a few iterations and give up if target is not cleared.
  const int numIterations = 10;
  int i = 0;
  for (; weakReference.target != null && i < numIterations; ++i) {
    produceGarbage();
    await Future.delayed(const Duration(milliseconds: 10));
  }
  Expect.isTrue(i == numIterations || weakReference.target == null);
  asyncEnd();
}
