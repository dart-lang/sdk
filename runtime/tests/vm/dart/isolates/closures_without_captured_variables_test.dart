// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The tests in this file will only succeed when isolate groups are enabled
// (hence the VMOptions above).

import 'dart:async';
import 'dart:isolate';

import 'package:expect/expect.dart';

import 'fast_object_copy_test.dart' show ClassWithNativeFields;

main() async {
  final rp = ReceivePort();

  testNormalEnclosingFunction(rp);
  testNormalNestedEnclosingFunction(rp);
  testNormalNestedEnclosingFunction2(rp);

  final si = StreamIterator(rp);
  for (int i = 0; i < 3; ++i) {
    Expect.isTrue(await si.moveNext());
    Expect.equals(42, (si.current)());
  }
  si.cancel(); // closes the port
}

testNormalEnclosingFunction(ReceivePort rp) {
  final invalidObject = ClassWithNativeFields();
  final normalObject = Object();

  captureInvalidObject() => invalidObject;
  captureNormalObject() => normalObject;
  captureNothing() => 42;

  Expect.throwsArgumentError(() => rp.sendPort.send(captureInvalidObject));

  // TODO(http://dartbug.com/36983): Avoid capturing more than needed.
  Expect.throwsArgumentError(() => rp.sendPort.send(captureNormalObject));

  // Should not throw, since the [captureNothing] closure should not have a
  // parent context and therefore not transitively refer [rp].
  rp.sendPort.send(captureNothing);
}

testNormalNestedEnclosingFunction(ReceivePort rp) {
  final invalidObject = ClassWithNativeFields();
  final normalObject = Object();
  nested() {
    captureInvalidObject() => invalidObject;
    captureNormalObject() => normalObject;
    captureNothing() => 42;

    Expect.throwsArgumentError(() => rp.sendPort.send(captureInvalidObject));

    // TODO(http://dartbug.com/36983): Avoid capturing more than needed.
    Expect.throwsArgumentError(() => rp.sendPort.send(captureNormalObject));

    // Should not throw, since the [captureNothing] closure should not have a
    // parent context and therefore not transitively refer [rp].
    rp.sendPort.send(captureNothing);
  }

  nested();
}

testNormalNestedEnclosingFunction2(ReceivePort rp) {
  final invalidObject = ClassWithNativeFields();
  final normalObject = Object();

  captureInvalidObject() {
    local() => invalidObject;
    return local;
  }

  captureNormalObject() {
    local() => normalObject;
    return local;
  }

  captureNothing() => 42;

  Expect.throwsArgumentError(() => rp.sendPort.send(captureInvalidObject));

  // TODO(http://dartbug.com/36983): Avoid capturing more than needed.
  Expect.throwsArgumentError(() => rp.sendPort.send(captureNormalObject));

  // Should not throw, since the [captureNothing] closure should not have a
  // parent context and therefore not transitively refer [rp].
  rp.sendPort.send(captureNothing);
}
