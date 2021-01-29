// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

bool caughtInF = false;
bool caughtInMain = false;

class A {}

class AAndFutureOfA implements A, Future<A> {
  noSuchMethod(Invocation i) => throw 0;
}

Future<A> f(A a) async {
  try {
    // Statically looks like no `await` is needed, but dynamically it is needed.
    // So we should check dynamically whether to await.
    return a;
  } catch (e) {
    caughtInF = true;
  }
  return new A();
}

void main() async {
  try {
    print(await f(AAndFutureOfA()));
    print('Done');
  } catch (e) {
    caughtInMain = true;
  }
  Expect.isTrue(caughtInF, "Exception should be caught in 'f'.");
  Expect.isFalse(caughtInMain, "Exception should not be caught in 'main'.");
}
