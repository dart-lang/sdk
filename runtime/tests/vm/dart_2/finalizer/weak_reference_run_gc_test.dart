// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// ignore: import_internal_library, unused_import
import 'dart:_internal';

import 'package:expect/expect.dart';

void main() {
  testWeakReferenceNonExpandoKey();
  testWeakReferenceTypeArgument();
  testWeakReference();
}

class Nonce {
  final int value;

  Nonce(this.value);

  String toString() => 'Nonce($value)';
}

void testWeakReferenceNonExpandoKey() {
  Expect.throwsArgumentError(() {
    WeakReference<String>("Hello world!");
  });
}

void testWeakReferenceTypeArgument() {
  final object = Nonce(23);
  final weakRef = WeakReference(object);
  Expect.type<WeakReference<Nonce>>(weakRef);
}

/// Never inline to ensure `object` becomes unreachable.
@pragma('vm:never-inline')
WeakReference<Nonce> makeWeakRef() {
  final object = Nonce(23);
  final weakRef = WeakReference(object);
  // Left to right argument evaluation: evaluate weakRef.target first.
  Expect.equals(weakRef.target, object);
  return weakRef;
}

void testWeakReference() {
  final weakRef = makeWeakRef();

  print('do gc');
  triggerGc();
  print('gc done');

  // The weak reference should not target anything anymore.
  Expect.isNull(weakRef.target);

  print('End of test, shutting down.');
}

// Defined in `dart:_internal`.
// ignore: undefined_identifier
void triggerGc() => VMInternalsForTesting.collectAllGarbage();
