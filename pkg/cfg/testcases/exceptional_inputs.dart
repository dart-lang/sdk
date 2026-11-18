// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for data flow from try blocks into catch blocks
// (ExceptionalInput instructions and catch block parameters).

void foo() {}

void assignedInTry(int a) {
  var x = 0;
  try {
    foo();
    x = a;
    foo();
  } catch (e) {
    print(x);
  }
}

void nestedTry(int a, int b) {
  var x = 0;
  try {
    x = a;
    try {
      foo();
      x = b;
      foo();
    } catch (e) {
      print(x);
      x = 3;
      foo();
    }
    foo();
  } catch (e) {
    print(x);
  }
}

void loopInTry(int n) {
  var i = 0;
  try {
    for (; i < n; ++i) {
      foo();
    }
  } catch (e) {
    print(i);
  }
}

void assignedParameter(int a) {
  try {
    foo();
    a = a + 1;
    foo();
  } catch (e) {
    print(a);
  }
}

void constantCatchParameter(bool c) {
  var x = 1;
  try {
    foo();
    if (c) {
      x = 1;
    }
    foo();
  } catch (e) {
    print(x);
  }
}

void usedAfterCatch(int a) {
  var x = 0;
  try {
    foo();
    x = a;
    foo();
  } catch (e) {
    print(e);
  }
  print(x);
}

void tryFinally(int a) {
  var x = 0;
  try {
    foo();
    x = a;
    foo();
  } finally {
    print(x);
  }
}

void noThrowInTry(int a) {
  var x = 0;
  try {
    x = a;
  } catch (e) {
    print(x);
  }
  print(x);
}

void unusedCatchParameter(int a) {
  var x = 0;
  try {
    foo();
    x = a;
    foo();
  } catch (e) {
    x = 1;
  }
  print(x);
}

Future<void> awaitInTry(Future<int> f) async {
  var x = 0;
  try {
    x = await f;
    x = await f;
  } catch (e) {
    print(x);
  }
}

// Values saved for one exception handler should not affect
// catch block parameters of unrelated exception handlers.
void unrelatedHandlers(bool c, int n) {
  var x = 1;
  try {
    foo();
    if (c) {
      x = 2;
      foo();
    }
  } catch (e) {
    print(x);
    try {
      x = n;
      foo();
    } catch (e) {
      print(x);
    }
  }
}

// Catch block parameters in unrelated exception handlers
// can have different constant values.
void constantsInUnrelatedHandlers() {
  var x = 1;
  try {
    foo();
    x = 1;
    foo();
  } catch (e) {
    print(x);
  }
  x = 2;
  try {
    foo();
    x = 2;
    foo();
  } catch (e) {
    print(x);
  }
}

void main() {}
