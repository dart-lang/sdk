// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic --optimization_counter_threshold=10

import 'dart:typed_data';
import "package:expect/expect.dart";

// Tests a few situations in which invariant instructions
// can be subject to CSE and LICM.

@pragma('vm:never-inline')
int cse1(Int32List? a, int n) {
  int x = a![0];
  for (int i = 0; i < n; i++) {
    // The a[0] null check, bounds check, and the actual load can be
    // CSEed with the instructions above even if loop is not taken.
    x += a[0] * a[i];
  }
  return x;
}

@pragma('vm:never-inline')
int cse2(Int32List? a, int n) {
  int x = a![0];
  for (int i = 0; i < n; i++) {
    // The a[0] null check, bounds check, but not the actual load can be
    // CSEed with the instructions above, since the value of the load
    // changes in the loop.
    a[i] = a[0] + 1;
  }
  return x;
}

@pragma('vm:never-inline')
int licm1(Int32List? a, int n) {
  int x = 0;
  for (int i = 0; i < n; i++) {
    // The a[0] null check, bounds check, and the actual load cannot
    // be LICMed, since the loop may be non-taken.
    x += a![0] * a[i];
  }
  return x;
}

@pragma('vm:never-inline')
int licm2(Int32List? a) {
  int x = 0;
  for (int i = 0; i < 16; i++) {
    // The a[0] null check, bounds check, and the actual load can be
    // LICMed, since the loop is always-taken.
    x += a![0] * a[i];
  }
  return x;
}

@pragma('vm:never-inline')
int licm3(Int32List? a, bool cond) {
  int x = 0;
  for (int i = 0; i < 16; i++) {
    // The a[0] null check, bounds check, and the actual load cannot
    // be LICMed, since the condition may be non-taken (and we don't
    // hoist invariant conditions).
    if (cond) x += a![0] * a[i];
  }
  return x;
}

@pragma('vm:never-inline')
int licm3_brk(Int32List? a, bool cond) {
  int x = 0;
  for (int i = 0; i < 16; i++) {
    // The a[0] null check, bounds check, and the actual load cannot
    // be LICMed, since the condition may be taken (and we don't
    // hoist invariant conditions).
    if (cond) break;
    x += a![0] * a[i];
  }
  return x;
}

int global = -1;

@pragma('vm:never-inline')
int licm4(Int32List? a) {
  int x = 0;
  for (int i = 0; i < 16; i++) {
    // The a[0] null check, bounds check, and the actual load cannot
    // be LICMed, since something visible happens before an exception
    // may be thrown.
    global++;
    x += a![0] * a[i];
  }
  return x;
}

@pragma('vm:never-inline')
int licm5(Int32List? a) {
  int x = 0;
  // Anything in the loop header can be LICMed.
  for (int i = 0; i < a![1]; i++) {
    x++;
  }
  return x;
}

@pragma('vm:never-inline')
int licm6(Int32List? a, int n) {
  int x = 0;
  int i = 0;
  do {
    // The a[0] null check, bounds check, and the actual load can be
    // LICMed, since this "header" is always-taken.
    x += a![0] * a[i++];
  } while (i < n);
  return x;
}

@pragma('vm:never-inline')
int licm7(Int32List? a, int n) {
  int x = 0;
  int i = 0;
  while (true) {
    // The a[0] null check, bounds check, and the actual load can be
    // LICMed, since this "header" is always-taken.
    x += a![0] * a[i++];
    if (i >= n) break;
  }
  return x;
}

@pragma('vm:never-inline')
int licm8(Int32List? a, int n) {
  int x = 0;
  int i = 0;
  while (true) {
    if (i >= n) break;
    // No LICM at this point, loop body may not be taken.
    x += a![0] * a[i++];
  }
  return x;
}

@pragma('vm:never-inline')
int licm9(Int32List? a) {
  int x = 0;
  int i = 0;
  while (true) {
    if (i >= 16) break;
    // The a[0] null check, bounds check, and the actual load can be
    // LICMed, since the loop is always-taken.
    x += a![0] * a[i++];
  }
  return x;
}

@pragma('vm:never-inline')
int licm10(Int32List? a, bool cond) {
  int x = 0;
  int i = 0;
  while (true) {
    if (i >= 16) break;
    // The a[0] null check, bounds check, and the actual load cannot
    // be LICMed, since the condition may be non-taken (and we don't
    // hoist invariant conditions).
    if (cond) x += a![0] * a[i];
    i++;
  }
  return x;
}

@pragma('vm:never-inline')
int licm10_brk(Int32List? a, bool cond) {
  int x = 0;
  int i = 0;
  while (true) {
    if (i >= 16) break;
    // The a[0] null check, bounds check, and the actual load cannot
    // be LICMed, since the condition may be taken (and we don't
    // hoist invariant conditions).
    if (cond) break;
    x += a![0] * a[i++];
  }
  return x;
}

@pragma('vm:never-inline')
int licm11(Int32List? a) {
  int x = 0;
  while (true) {
    // Anything in the loop header can be LICMed.
    if (x > a![1]) break;
    x++;
  }
  return x;
}

@pragma('vm:never-inline')
int foo() {
  return global--;
}

@pragma('vm:never-inline')
int licm12(Int32List? a) {
  int x = 0;
  int i = 0;
  // Side-effect loop bound.
  for (int i = 0; i < foo(); i++) {
    x += a![0] * a[i++];
  }
  return x;
}

doTests() {
  var x = new Int32List(0);
  var a = new Int32List(16);
  for (int i = 0; i < 16; i++) {
    a[i] = i + 1;
  }

  Expect.throwsTypeError(() {
    cse1(null, 0);
  });
  Expect.throwsTypeError(() {
    cse1(null, 1);
  });
  Expect.throws(() {
    cse1(x, 0);
  }, (e) {
    return e is RangeError;
  });
  Expect.throws(() {
    cse1(x, 1);
  }, (e) {
    return e is RangeError;
  });
  Expect.equals(1, cse1(a, 0));
  Expect.equals(137, cse1(a, 16));

  Expect.throwsTypeError(() {
    cse2(null, 0);
  });
  Expect.throwsTypeError(() {
    cse2(null, 1);
  });
  Expect.throws(() {
    cse2(x, 0);
  }, (e) {
    return e is RangeError;
  });
  Expect.throws(() {
    cse2(x, 1);
  }, (e) {
    return e is RangeError;
  });
  Expect.equals(1, cse2(a, 0));
  Expect.equals(1, cse2(a, 16));
  Expect.equals(2, a[0]);
  for (int i = 1; i < 16; i++) {
    Expect.equals(3, a[i]);
  }

  Expect.equals(0, licm1(null, 0));
  Expect.throwsTypeError(() {
    licm1(null, 1);
  });
  Expect.equals(0, licm1(x, 0));
  Expect.throws(() {
    licm1(x, 1);
  }, (e) {
    return e is RangeError;
  });
  Expect.equals(0, licm1(a, 0));
  Expect.equals(94, licm1(a, 16));

  Expect.throwsTypeError(() {
    licm2(null);
  });
  Expect.throws(() {
    licm2(x);
  }, (e) {
    return e is RangeError;
  });
  Expect.equals(94, licm2(a));

  Expect.equals(0, licm3(null, false));
  Expect.throwsTypeError(() {
    licm3(null, true);
  });
  Expect.equals(0, licm3(x, false));
  Expect.throws(() {
    licm3(x, true);
  }, (e) {
    return e is RangeError;
  });
  Expect.equals(0, licm3(a, false));
  Expect.equals(94, licm3(a, true));

  Expect.equals(0, licm3_brk(null, true));
  Expect.throwsTypeError(() {
    licm3_brk(null, false);
  });
  Expect.equals(0, licm3_brk(x, true));
  Expect.throws(() {
    licm3_brk(x, false);
  }, (e) {
    return e is RangeError;
  });
  Expect.equals(0, licm3_brk(a, true));
  Expect.equals(94, licm3_brk(a, false));

  global = 0;
  Expect.throwsTypeError(() {
    licm4(null);
  });
  Expect.equals(1, global);
  Expect.throws(() {
    licm4(x);
  }, (e) {
    return e is RangeError;
  });
  Expect.equals(2, global);
  Expect.equals(94, licm4(a));
  Expect.equals(18, global);

  Expect.throwsTypeError(() {
    licm5(null);
  });
  Expect.throws(() {
    licm5(x);
  }, (e) {
    return e is RangeError;
  });
  Expect.equals(3, licm5(a));

  Expect.throwsTypeError(() {
    licm6(null, 0);
  });
  Expect.throwsTypeError(() {
    licm6(null, 1);
  });
  Expect.throws(() {
    licm6(x, 0);
  }, (e) {
    return e is RangeError;
  });
  Expect.throws(() {
    licm6(x, 1);
  }, (e) {
    return e is RangeError;
  });
  Expect.equals(4, licm6(a, 0));
  Expect.equals(94, licm6(a, 16));

  Expect.throwsTypeError(() {
    licm7(null, 0);
  });
  Expect.throwsTypeError(() {
    licm7(null, 1);
  });
  Expect.throws(() {
    licm7(x, 0);
  }, (e) {
    return e is RangeError;
  });
  Expect.throws(() {
    licm7(x, 1);
  }, (e) {
    return e is RangeError;
  });
  Expect.equals(4, licm7(a, 0));
  Expect.equals(94, licm7(a, 16));

  Expect.equals(0, licm8(null, 0));
  Expect.throwsTypeError(() {
    licm8(null, 1);
  });
  Expect.equals(0, licm8(x, 0));
  Expect.throws(() {
    licm8(x, 1);
  }, (e) {
    return e is RangeError;
  });
  Expect.equals(0, licm8(a, 0));
  Expect.equals(94, licm8(a, 16));

  Expect.throwsTypeError(() {
    licm9(null);
  });
  Expect.throws(() {
    licm9(x);
  }, (e) {
    return e is RangeError;
  });
  Expect.equals(94, licm9(a));

  Expect.equals(0, licm10(null, false));
  Expect.throwsTypeError(() {
    licm10(null, true);
  });
  Expect.equals(0, licm10(x, false));
  Expect.throws(() {
    licm10(x, true);
  }, (e) {
    return e is RangeError;
  });
  Expect.equals(0, licm10(a, false));
  Expect.equals(94, licm10(a, true));

  Expect.equals(0, licm10_brk(null, true));
  Expect.throwsTypeError(() {
    licm10_brk(null, false);
  });
  Expect.equals(0, licm10_brk(x, true));
  Expect.throws(() {
    licm10_brk(x, false);
  }, (e) {
    return e is RangeError;
  });
  Expect.equals(0, licm10_brk(a, true));
  Expect.equals(94, licm10_brk(a, false));

  Expect.throwsTypeError(() {
    licm11(null);
  });
  Expect.throws(() {
    licm11(x);
  }, (e) {
    return e is RangeError;
  });
  Expect.equals(4, licm11(a));

  global = 0;
  Expect.equals(0, licm12(null));
  Expect.equals(-1, global);
  Expect.equals(0, licm12(x));
  Expect.equals(-2, global);
  global = 16;
  Expect.throwsTypeError(() {
    licm12(null);
  });
  Expect.equals(15, global);
  Expect.throws(() {
    licm12(x);
  }, (e) {
    return e is RangeError;
  });
  Expect.equals(14, global);
  Expect.equals(28, licm12(a));
  Expect.equals(8, global);
}

main() {
  // Repeat to enter JIT (when applicable).
  for (int i = 0; i < 20; i++) {
    doTests();
  }
}
