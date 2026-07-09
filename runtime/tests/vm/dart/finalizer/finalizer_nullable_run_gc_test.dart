// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'helpers.dart';

void main() {
  testFinalizer();
}

void testFinalizer() async {
  final finalizerTokens = <Nonce?>{};
  void callback(Nonce? token) {
    print('Running finalizer: token: $token');
    finalizerTokens.add(token);
  }

  final finalizer = Finalizer<Nonce?>(callback);

  {
    final detach = Nonce(2022);
    final token = null;

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

  print('End of test, shutting down.');
}
