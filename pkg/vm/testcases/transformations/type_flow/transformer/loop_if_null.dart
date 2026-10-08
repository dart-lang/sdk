// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Base {
  void foo() {}
}

class Middle extends Base {
  @override
  void foo() {}
}

class Sub1 extends Middle {
  @override
  void foo() {}
}

class Sub2 extends Middle {
  @override
  void foo() {}
}

Base? testIfNullAssign(int n) {
  Base? x;
  for (int i = 0; i < n; i++) {
    (x ??= Sub1()).foo();
  }
  return x;
}

Base? testNullBranchUnmodified(int n, bool cond) {
  Base? x = Sub1();
  for (int i = 0; i < n; i++) {
    if (x == null) {
      print('unreachable null');
    } else if (cond) {
      x = Sub2();
    }
    x?.foo();
  }
  return x;
}

Base testIsPromotionAndTypeCast(int n, bool cond1, bool cond2) {
  Base x = Sub1();
  for (int i = 0; i < n; i++) {
    if (x is Middle) {
      if (cond1) {
        x = Sub1();
      }
    }
    if (cond2) {
      x = x as Middle;
    }
    x.foo();
  }
  return x;
}

Base? testMultiBranchAndContinue(int n, int mode) {
  Base? x;
  for (int i = 0; i < n; i++) {
    if (mode == 0) {
      if (x != null) continue;
      x = Sub1();
    } else if (mode == 1) {
      x = Sub1();
    } else if (mode == 2) {
      x = Sub2();
    }
  }
  return x;
}

Base? testNestedLoops(int n) {
  Base? x;
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < n; j++) {
      (x ??= Sub1()).foo();
    }
    x?.foo();
  }
  return x;
}

Base? testTryCatchInLoop(int n) {
  Base? x;
  for (int i = 0; i < n; i++) {
    try {
      (x ??= Sub1()).foo();
    } catch (_) {}
  }
  return x;
}

Base? testSwitchContinue(int n, int mode) {
  Base? x;
  switch (mode) {
    case 0:
      x = Sub1();
      continue case1;
    case1:
    case 1:
      (x ??= Sub1()).foo();
      if (n > 0) continue case2;
      break;
    case2:
    case 2:
      if (x != null) {
        x.foo();
      }
      break;
  }
  return x;
}

void main() {
  final n = int.parse('10');
  final cond1 = n == 1;
  final cond2 = n == 2;
  print(Base());
  print(Middle());
  print(Sub1());
  print(Sub2());
  print(testIfNullAssign(n));
  print(testNullBranchUnmodified(n, cond1));
  print(testIsPromotionAndTypeCast(n, cond1, cond2));
  print(testMultiBranchAndContinue(n, n));
  print(testNestedLoops(n));
  print(testTryCatchInLoop(n));
  print(testSwitchContinue(n, n));
}
