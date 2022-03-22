// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=
// VMOptions=--use_compactor
// VMOptions=--use_compactor --force_evacuation

import 'package:expect/expect.dart';

import 'helpers.dart';

void main() {
  testWrongArguments();
  testFinalizer();
}

void testWrongArguments() {
  void callback(Object token) {
    throw 'This should never happen!';
  }

  final finalizer = Finalizer<Nonce>(callback);
  final myFinalizable = Nonce(1000);
  final token = Nonce(2000);
  final detach = Nonce(3000);

  Expect.throws(() {
    finalizer.attach(myFinalizable, token, detach: 123);
  });
  Expect.throws(() {
    finalizer.attach(123, token, detach: detach);
  });
}

void testFinalizer() async {
  final finalizerTokens = <Object>{};
  void callback(Object token) {
    print('Running finalizer: token: $token');
    finalizerTokens.add(token);
  }

  final finalizer = Finalizer<Nonce>(callback);

  {
    final detach = Nonce(2022);
    final token = Nonce(42);

    makeObjectWithFinalizer(finalizer, token, detach: detach);

    doGC();

    // We haven't stopped running synchronous dart code yet.
    Expect.isFalse(finalizerTokens.contains(token));

    await Future.delayed(Duration(milliseconds: 1));

    // Now we have.
    Expect.isTrue(finalizerTokens.contains(token));

    // Try detaching after finalizer ran.
    finalizer.detach(detach);
  }

  {
    final token = Nonce(1337);
    final token2 = Nonce(1338);
    final detachkey = Nonce(1984);
    {
      final value = Nonce(2);
      final value2 = Nonce(2000000);
      finalizer.attach(value, token, detach: detachkey);
      finalizer.attach(value2, token2, detach: detachkey);
      // Should detach 2 finalizers.
      finalizer.detach(detachkey);
      // Try detaching again, should do nothing.
      finalizer.detach(detachkey);
    }
    doGC();
    await yieldToMessageLoop();
    Expect.isFalse(finalizerTokens.contains(token));
    Expect.isFalse(finalizerTokens.contains(token2));
  }

  // Not running finalizer on shutdown.
  final value = Nonce(3);
  final token = Nonce(1337);
  finalizer.attach(value, token);
  print('End of test, shutting down.');
}
