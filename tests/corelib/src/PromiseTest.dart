// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class PromiseTest {

  static void testMain() {
    testNormalComplete();
    testFromValue();
    testNormalCompleteWithHandler();
    testNormalCompleteManyHandlers();
    testError();
    testErrorWithHandler();
    testCancel();
    testCancelWithHandler();
    testChainComplete();
    testChainError();
    testChainCancel();
    testFlatten();
    testJoinSelectSecond();
    testWaitFor1();
    testWaitForAll();
  }

  static void testNormalComplete() {
    Promise<int> a = new Promise<int>();
    Expect.equals(false, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());

    readValueThrowsException_(a);
    readErrorThrowsException_(a);
    a.complete(3);
    Expect.equals(true, a.isDone());
    Expect.equals(true, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());
    Expect.equals(3, a.value);
    Expect.equals(null, a.error);
  }

  static void testFromValue() {
    Promise<int> a = new Promise<int>.fromValue(3);
    Expect.equals(true, a.isDone());
    Expect.equals(false, a.isCancelled());
    Expect.equals(true, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());
    Expect.equals(3, a.value);
    Expect.equals(null, a.error);
  }

  static void testNormalCompleteWithHandler() {
    Promise<int> a = new Promise<int>();
    Promise<int> b = new Promise<int>();
    Expect.equals(false, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());
    Expect.equals(false, b.isDone());
    Expect.equals(false, b.hasValue());
    Expect.equals(false, b.hasError());
    Expect.equals(false, b.isCancelled());
    readValueThrowsException_(a);
    readErrorThrowsException_(a);
    readValueThrowsException_(b);
    readErrorThrowsException_(b);
    int afterA = null;
    int afterB = null;

    // value computed after setup is done.
    a.addCompleteHandler((int v) { afterA = v; });
    a.complete(3);

    // value computed before setup was done.
    b.complete(4);
    b.addCompleteHandler((int v) { afterB = v; });

    Expect.equals(true, a.isDone());
    Expect.equals(true, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());
    Expect.equals(true, b.isDone());
    Expect.equals(true, b.hasValue());
    Expect.equals(false, b.hasError());
    Expect.equals(false, b.isCancelled());
    Expect.equals(null, a.error);
    Expect.equals(null, b.error);

    Expect.equals(3, a.value);
    Expect.equals(4, b.value);
    Expect.equals(3, afterA);
    Expect.equals(4, afterB);
  }

  static void testNormalCompleteManyHandlers() {
    Promise<int> a = new Promise<int>();
    Expect.equals(false, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());
    readValueThrowsException_(a);
    readErrorThrowsException_(a);
    int afterA1 = null;
    int afterA2 = null;
    int afterA3 = null;

    // value computed after setup is done.
    a.addCompleteHandler((int v) { afterA1 = v; });
    a.complete(3);
    a.addCompleteHandler((int v) { afterA2 = v; });
    a.addCompleteHandler((int v) { afterA3 = v; });

    Expect.equals(true, a.isDone());
    Expect.equals(true, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());
    Expect.equals(null, a.error);
    Expect.equals(3, a.value);
    Expect.equals(3, afterA1);
    Expect.equals(3, afterA2);
    Expect.equals(3, afterA3);
  }

  static void testError() {
    Promise<int> a = new Promise<int>();
    Expect.equals(false, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());
    readValueThrowsException_(a);
    readErrorThrowsException_(a);
    a.fail("Err");
    Expect.equals(true, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(true, a.hasError());
    Expect.equals(false, a.isCancelled());
    Expect.equals("Err", a.error);
    readValueThrowsException_(a, a.error);
  }

  static void testErrorWithHandler() {
    Promise<int> a = new Promise<int>();
    Promise<int> b = new Promise<int>();
    Expect.equals(false, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());
    Expect.equals(false, b.isDone());
    Expect.equals(false, b.hasValue());
    Expect.equals(false, b.hasError());
    Expect.equals(false, b.isCancelled());
    readValueThrowsException_(a);
    readErrorThrowsException_(a);
    readValueThrowsException_(b);
    readErrorThrowsException_(b);
    String afterA = null;
    String afterB = null;

    // error after set up is done
    a.addErrorHandler((v) { afterA = v; });
    a.fail("ErrA");

    // error before setup is done
    b.fail("ErrB");
    b.addErrorHandler((v) { afterB = v; });

    Expect.equals(true, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(true, a.hasError());
    Expect.equals(false, a.isCancelled());

    Expect.equals(true, b.isDone());
    Expect.equals(false, b.hasValue());
    Expect.equals(true, b.hasError());
    Expect.equals(false, b.isCancelled());

    Expect.equals("ErrA", a.error);
    Expect.equals("ErrB", b.error);
    Expect.equals("ErrA", afterA);
    Expect.equals("ErrB", afterB);

    readValueThrowsException_(a, a.error);
    readValueThrowsException_(b, b.error);
  }

  static void testCancel() {
    Promise<int> a = new Promise<int>();
    Expect.equals(false, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());

    readValueThrowsException_(a);
    readErrorThrowsException_(a);
    a.cancel();
    Expect.equals(true, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(true, a.isCancelled());
    Expect.equals(null, a.value);
    Expect.equals(null, a.error);
  }

  static void testCancelWithHandler() {
    Promise<int> a = new Promise<int>();
    Promise<int> b = new Promise<int>();
    Expect.equals(false, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());
    Expect.equals(false, b.isDone());
    Expect.equals(false, b.hasValue());
    Expect.equals(false, b.hasError());
    Expect.equals(false, b.isCancelled());
    readValueThrowsException_(a);
    readErrorThrowsException_(a);
    readValueThrowsException_(b);
    readErrorThrowsException_(b);
    bool aCancel = false;
    bool bCancel = false;

    // cancel after setup
    a.addCancelHandler(() { aCancel = true; });
    a.cancel();

    // cancel before setup is done
    b.cancel();
    b.addCancelHandler(() { bCancel = true; });

    Expect.equals(true, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(true, a.isCancelled());
    Expect.equals(true, b.isDone());
    Expect.equals(false, b.hasValue());
    Expect.equals(false, b.hasError());
    Expect.equals(true, b.isCancelled());
    Expect.equals(null, a.value);
    Expect.equals(null, b.value);
    Expect.equals(null, a.error);
    Expect.equals(null, b.error);
    Expect.equals(true, aCancel);
    Expect.equals(true, bCancel);

    Promise<int> c = new Promise<int>();
    bool cCancel = false;
    c.cancel();
    c.complete(3);
    c.addCancelHandler(() { cCancel = true; });
    Expect.equals(true, cCancel);
    Expect.equals(true, c.isDone());
    Expect.equals(true, c.hasValue());
    Expect.equals(false, c.hasError());
    Expect.equals(true, c.isCancelled());

    Promise<int> d = new Promise<int>();
    bool dCancel = false;
    d.cancel();
    d.fail("fail");
    d.addCancelHandler(() { dCancel = true; });
    Expect.equals(true, dCancel);
    Expect.equals(true, d.isDone());
    Expect.equals(false, d.hasValue());
    Expect.equals(true, d.hasError());
    Expect.equals(true, d.isCancelled());
  }

  static void testChainComplete() {
    Promise<int> a = new Promise<int>();
    Promise<int> b = a.then((int ares) => ares + 1);
    Expect.equals(false, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());
    Expect.equals(false, b.isDone());
    Expect.equals(false, b.hasValue());
    Expect.equals(false, b.hasError());
    Expect.equals(false, b.isCancelled());
    readValueThrowsException_(a);
    readErrorThrowsException_(a);
    readValueThrowsException_(b);
    readErrorThrowsException_(b);
    int resA = null;
    a.addCompleteHandler((int v) { resA = v; });
    int resB = null;
    b.addCompleteHandler((int v) { resB = v; });

    a.complete(3);

    Expect.equals(true, a.isDone());
    Expect.equals(true, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());

    Expect.equals(true, b.isDone());
    Expect.equals(true, b.hasValue());
    Expect.equals(false, b.hasError());
    Expect.equals(false, b.isCancelled());

    Expect.equals(3, a.value);
    Expect.equals(4, b.value);
    Expect.equals(null, a.error);
    Expect.equals(null, b.error);
    Expect.equals(3, resA);
    Expect.equals(4, resB);
  }

  static void testChainError() {
    Promise<int> a = new Promise<int>();
    Promise<int> b = a.then((int ares) => ares + 1);
    Expect.equals(false, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());
    Expect.equals(false, b.isDone());
    Expect.equals(false, b.hasValue());
    Expect.equals(false, b.hasError());
    Expect.equals(false, b.isCancelled());
    readValueThrowsException_(a);
    readErrorThrowsException_(a);
    readValueThrowsException_(b);
    readErrorThrowsException_(b);
    String errA = null;
    a.addErrorHandler((e) { errA = e; });
    String errB = null;
    b.addErrorHandler((e) { errB = e; });

    a.fail("err-from-a");

    Expect.equals(true, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(true, a.hasError());
    Expect.equals(false, a.isCancelled());
    Expect.equals(true, b.isDone());
    Expect.equals(false, b.hasValue());
    Expect.equals(true, b.hasError());
    Expect.equals(false, b.isCancelled());

    Expect.equals("err-from-a", a.error);
    Expect.equals("err-from-a", b.error);
    Expect.equals("err-from-a", errA);
    Expect.equals("err-from-a", errB);

    readValueThrowsException_(a, a.error);
    readValueThrowsException_(b, b.error);
  }

  static void testChainCancel() {
    Promise<int> a = new Promise<int>();
    Promise<int> b = a.then((int ares) => ares + 1);
    Expect.equals(false, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());
    Expect.equals(false, b.isDone());
    Expect.equals(false, b.hasValue());
    Expect.equals(false, b.hasError());
    Expect.equals(false, b.isCancelled());
    readValueThrowsException_(a);
    readErrorThrowsException_(a);
    readValueThrowsException_(b);
    readErrorThrowsException_(b);
    bool bCancel = false;
    b.addCancelHandler(() { bCancel = true; });
    bool bError = false;
    b.addErrorHandler((e) { bError = true; });
    bool aCancel = false;
    a.addCancelHandler(() { aCancel = true; });

    a.cancel();

    Expect.equals(true, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(true, a.isCancelled());
    Expect.equals(true, b.isDone());
    Expect.equals(false, b.hasValue());
    Expect.equals(true, b.hasError());
    Expect.equals(false, b.isCancelled());
    Expect.equals(null, a.value);
    Expect.equals(null, a.error);
    Expect.equals("Source promise was cancelled", b.error);
    readValueThrowsException_(b, b.error);
    Expect.equals(false, bCancel);
    Expect.equals(true, bError);
    Expect.equals(true, aCancel);
  }

  static void testFlatten() {
    Promise<int> a = new Promise<int>();
    Promise<Promise<int>> b = new Promise<Promise<int>>();
    Promise<Promise<Promise<int>>> c = new Promise<Promise<Promise<int>>>();
    Promise<Promise<Promise<Promise<int>>>> d =
        new Promise<Promise<Promise<Promise<int>>>>();
    Promise<int> flat = d.flatten();

    Expect.equals(false, a.isDone());
    Expect.equals(false, b.isDone());
    Expect.equals(false, c.isDone());
    Expect.equals(false, d.isDone());
    Expect.equals(false, flat.isDone());
    readValueThrowsException_(a);
    readValueThrowsException_(b);
    readValueThrowsException_(c);
    readValueThrowsException_(d);
    readValueThrowsException_(flat);

    b.complete(a);

    Expect.equals(false, a.isDone());
    Expect.equals(true, b.isDone());
    Expect.equals(false, c.isDone());
    Expect.equals(false, d.isDone());
    Expect.equals(false, flat.isDone());
    readValueThrowsException_(a);
    Expect.equals(a, b.value);
    readValueThrowsException_(c);
    readValueThrowsException_(d);
    readValueThrowsException_(flat);

    d.complete(c);

    Expect.equals(false, a.isDone());
    Expect.equals(true, b.isDone());
    Expect.equals(false, c.isDone());
    Expect.equals(true, d.isDone());
    Expect.equals(false, flat.isDone());
    readValueThrowsException_(a);
    Expect.equals(a, b.value);
    readValueThrowsException_(c);
    Expect.equals(c, d.value);
    readValueThrowsException_(flat);

    a.complete(2);

    Expect.equals(true, a.isDone());
    Expect.equals(true, b.isDone());
    Expect.equals(false, c.isDone());
    Expect.equals(true, d.isDone());
    Expect.equals(false, flat.isDone());
    Expect.equals(2, a.value);
    Expect.equals(a, b.value);
    readValueThrowsException_(c);
    Expect.equals(c, d.value);
    readValueThrowsException_(flat);

    c.complete(b);

    Expect.equals(true, a.isDone());
    Expect.equals(true, b.isDone());
    Expect.equals(true, c.isDone());
    Expect.equals(true, d.isDone());
    Expect.equals(true, flat.isDone());
    Expect.equals(2, a.value);
    Expect.equals(a, b.value);
    Expect.equals(b, c.value);
    Expect.equals(c, d.value);
    Expect.equals(2, flat.value);
  }

  static void testJoinSelectSecond() {
    Promise<int> a = new Promise<int>();
    Promise<int> b = new Promise<int>();
    Promise<int> c = new Promise<int>();
    Promise<int> second = new Promise<int>();
    bool first = true;
    second.join([a, b, c], (p) {
      if (first == true) {
        first = false;
        return false;
      } else {
        return true;
      }
    });

    Expect.equals(false, a.isDone());
    Expect.equals(false, b.isDone());
    Expect.equals(false, c.isDone());
    readValueThrowsException_(a);
    readErrorThrowsException_(a);
    readValueThrowsException_(b);
    readErrorThrowsException_(b);
    readValueThrowsException_(c);
    readErrorThrowsException_(c);
    Expect.equals(false, second.isDone());
    readValueThrowsException_(second);
    readErrorThrowsException_(second);

    b.complete(2);

    Expect.equals(false, a.isDone());
    Expect.equals(true, b.isDone());
    Expect.equals(false, c.isDone());
    readValueThrowsException_(a);
    readErrorThrowsException_(a);
    Expect.equals(2, b.value);
    Expect.equals(null, b.error);
    readValueThrowsException_(c);
    readErrorThrowsException_(c);
    Expect.equals(false, second.isDone());
    readValueThrowsException_(second);
    readErrorThrowsException_(second);

    c.complete(3);

    Expect.equals(true, second.isDone());
    Expect.equals(false, a.isDone());
    Expect.equals(true, b.isDone());
    Expect.equals(true, c.isDone());

    readValueThrowsException_(a);
    readErrorThrowsException_(a);
    Expect.equals(2, b.value);
    Expect.equals(null, b.error);
    Expect.equals(3, c.value);
    Expect.equals(null, c.error);
    Expect.equals(3, second.value);
  }

  static void testWaitFor1() {
    Promise<int> a = new Promise<int>();
    Promise<int> b = new Promise<int>();
    Promise<int> c = new Promise<int>();
    Promise<int> first = new Promise<int>();
    first.waitFor([a, b, c], 1);

    Expect.equals(false, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());
    Expect.equals(false, b.isDone());
    Expect.equals(false, b.hasValue());
    Expect.equals(false, b.hasError());
    Expect.equals(false, b.isCancelled());
    Expect.equals(false, c.isDone());
    Expect.equals(false, c.hasValue());
    Expect.equals(false, c.hasError());
    Expect.equals(false, c.isCancelled());
    readValueThrowsException_(a);
    readErrorThrowsException_(a);
    readValueThrowsException_(b);
    readErrorThrowsException_(b);
    readValueThrowsException_(c);
    readErrorThrowsException_(c);
    Expect.equals(false, first.isDone());

    b.complete(2);

    // a & c got cancelled
    Expect.equals(true, first.isDone());
    Expect.equals(true, first.hasValue());
    Expect.equals(false, first.hasError());
    Expect.equals(false, first.isCancelled());
    Expect.equals(true, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(true, a.isCancelled());
    Expect.equals(true, b.isDone());
    Expect.equals(true, b.hasValue());
    Expect.equals(false, b.hasError());
    Expect.equals(false, b.isCancelled());
    Expect.equals(true, c.isDone());
    Expect.equals(false, c.hasValue());
    Expect.equals(false, c.hasError());
    Expect.equals(true, c.isCancelled());

    Expect.equals(null, a.value);
    Expect.equals(2, b.value);
    Expect.equals(null, c.value);
    Expect.equals(null, a.error);
    Expect.equals(null, b.error);
    Expect.equals(null, c.error);
    Expect.equals(2, first.value);
  }

  static void testWaitForAll() {
    Promise<int> a = new Promise<int>();
    Promise<int> b = new Promise<int>();
    Promise<int> c = new Promise<int>();
    Promise<int> all = new Promise<int>();
    all.waitFor([a, b, c], 3);

    Expect.equals(false, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());
    Expect.equals(false, b.isDone());
    Expect.equals(false, b.hasValue());
    Expect.equals(false, b.hasError());
    Expect.equals(false, b.isCancelled());
    Expect.equals(false, c.isDone());
    Expect.equals(false, c.hasValue());
    Expect.equals(false, c.hasError());
    Expect.equals(false, c.isCancelled());
    Expect.equals(false, all.isDone());
    Expect.equals(false, all.hasValue());
    Expect.equals(false, all.hasError());
    Expect.equals(false, all.isCancelled());
    readValueThrowsException_(a);
    readErrorThrowsException_(a);
    readValueThrowsException_(b);
    readErrorThrowsException_(b);
    readValueThrowsException_(c);
    readErrorThrowsException_(c);
    readValueThrowsException_(all);
    readErrorThrowsException_(all);

    b.complete(2);

    Expect.equals(false, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());
    Expect.equals(true, b.isDone());
    Expect.equals(true, b.hasValue());
    Expect.equals(false, b.hasError());
    Expect.equals(false, b.isCancelled());
    Expect.equals(false, c.isDone());
    Expect.equals(false, c.hasValue());
    Expect.equals(false, c.hasError());
    Expect.equals(false, c.isCancelled());
    Expect.equals(false, all.isDone());
    Expect.equals(false, all.hasValue());
    Expect.equals(false, all.hasError());
    Expect.equals(false, all.isCancelled());

    readValueThrowsException_(a);
    readErrorThrowsException_(a);
    Expect.equals(2, b.value);
    Expect.equals(null, b.error);
    readValueThrowsException_(c);
    readErrorThrowsException_(c);
    readValueThrowsException_(all);
    readErrorThrowsException_(all);

    c.complete(3);

    Expect.equals(false, a.isDone());
    Expect.equals(false, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());
    Expect.equals(true, b.isDone());
    Expect.equals(true, b.hasValue());
    Expect.equals(false, b.hasError());
    Expect.equals(false, b.isCancelled());
    Expect.equals(true, c.isDone());
    Expect.equals(true, c.hasValue());
    Expect.equals(false, c.hasError());
    Expect.equals(false, c.isCancelled());
    Expect.equals(false, all.isDone());
    Expect.equals(false, all.hasValue());
    Expect.equals(false, all.hasError());
    Expect.equals(false, all.isCancelled());

    readValueThrowsException_(a);
    readErrorThrowsException_(a);
    Expect.equals(2, b.value);
    Expect.equals(null, b.error);
    Expect.equals(3, c.value);
    Expect.equals(null, c.error);
    readValueThrowsException_(all);
    readErrorThrowsException_(all);

    a.complete(1);

    Expect.equals(true, a.isDone());
    Expect.equals(true, a.hasValue());
    Expect.equals(false, a.hasError());
    Expect.equals(false, a.isCancelled());
    Expect.equals(true, b.isDone());
    Expect.equals(true, b.hasValue());
    Expect.equals(false, b.hasError());
    Expect.equals(false, b.isCancelled());
    Expect.equals(true, c.isDone());
    Expect.equals(true, c.hasValue());
    Expect.equals(false, c.hasError());
    Expect.equals(false, c.isCancelled());
    Expect.equals(true, all.isDone());
    Expect.equals(true, all.hasValue());
    Expect.equals(false, all.hasError());
    Expect.equals(false, all.isCancelled());

    Expect.equals(1, a.value);
    Expect.equals(null, a.error);
    Expect.equals(2, b.value);
    Expect.equals(null, b.error);
    Expect.equals(3, c.value);
    Expect.equals(null, c.error);
    Expect.equals(1, all.value);
    Expect.equals(null, all.error);
  }

  static void readValueThrowsException_(Promise p, [var error = null]) {
    bool errorFound = false;
    try {
      var x = p.value;
    } catch (var e) {
      errorFound = true;
      if (error !== null) {
        Expect.equals(true, error === e);
      }
    }
    Expect.equals(true, errorFound);
  }

  static void readErrorThrowsException_(Promise p) {
    bool errorFound = false;
    try {
      var x = p.error;
    } catch (var e) {
      errorFound = true;
    }
    Expect.equals(true, errorFound);
  }
}

main() {
  PromiseTest.testMain();
}
