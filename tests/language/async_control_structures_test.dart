// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable_async --optimization-counter-threshold=10

import 'package:expect/expect.dart';

import 'dart:async';

expectThenValue(future, value) {
  Expect.isTrue(future is Future);
  future.then((result) {
    Expect.equals(value, result);
  });
}

asyncIf(condition) async {
  if(condition) {
    return 1;
  } else {
    return 2;
  }
  // This return is never reached as the finally block returns from the
  // function.
  return 3;
}

asyncFor(condition) async {
  for (int i = 0; i < 10; i++) {
    if (i == 5 && condition) {
      return 1;
    }
  }
  return 2;
}

asyncTryCatchFinally(overrideInFinally, doThrow) async {
  try {
    if (doThrow) throw 444;
    return 1;
  } catch (e) {
    return e;
  } finally {
    if (overrideInFinally) return 3;
  }
}

asyncTryCatchLoop() async {
  var i = 0;
  var throws = 13;
  while (true) {
    try {
      throw throws;
    } catch (e) {
      if (i == throws) { return e; }
    } finally {
      i++;
    }
  }
}

asyncImplicitReturn() async {
  try {}
  catch (e) {}
  finally {}
}

main() {
  var asyncReturn;

  for (int i = 0; i < 10; i++) {
    asyncReturn = asyncIf(true);
    expectThenValue(asyncReturn, 1);
    asyncReturn = asyncIf(false);
    expectThenValue(asyncReturn, 2);

    asyncReturn = asyncFor(true);
    expectThenValue(asyncReturn, 1);
    asyncReturn = asyncFor(false);
    expectThenValue(asyncReturn, 2);

    asyncReturn = asyncTryCatchFinally(true, false);
    expectThenValue(asyncReturn, 3);
    asyncReturn = asyncTryCatchFinally(false, false);
    expectThenValue(asyncReturn, 1);
    asyncReturn = asyncTryCatchFinally(true, true);
    expectThenValue(asyncReturn, 3);
    asyncReturn = asyncTryCatchFinally(false, true);
    expectThenValue(asyncReturn, 444);
    asyncReturn = asyncTryCatchLoop();
    expectThenValue(asyncReturn, 13);

    asyncReturn = asyncImplicitReturn();
    expectThenValue(asyncReturn, null);
  }
}
