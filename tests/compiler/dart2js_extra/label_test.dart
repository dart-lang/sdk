// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A break label must be declared where it's used.
undeclaredBreakLabel1() {
  foo: { break bar; break foo; }  /// 01: compile-time error
}

undeclaredBreakLabel2() {
  foo: while (true) { break bar; break foo; }  /// 02: compile-time error
}

// An unlabeled break must be inside a loop or switch.
noBreakTarget() {
  foo: if (true) { break; break foo; }  /// 03: compile-time error
}

// A continue label must be declared where it's used.
undeclaredContinueLabel() {
  foo: for (;;) { continue bar; break foo; }  /// 04: compile-time error
}

// An unlabeled continue must be inside a loop.
noContinueTarget() {
  foo: if (true) continue; else break foo;  /// 05: compile-time error
}

// A continue label must point to a continue-able statement.
wrongContinueLabel() {
  foo: if (true) continue foo;  /// 06: compile-time error
}

// Labels are not captured by closures.
noncaptureLabel() {
  foo: {                    /// 07: compile-time error
    (() { break foo; })();  /// 07: continued
    break foo;              /// 07: continued
  }                         /// 07: continued
}

// Implicit break targets are not captured by closures.
noncaptureBreak() {
  while(true) (() { break; })();  /// 08: compile-time error
}

// Implicit continue targets are not captured by closures.
noncaptureContinue() {
  while(true) (() { continue; })();  /// 09: compile-time error
}

main() {
  undeclaredBreakLabel1();
  undeclaredBreakLabel2();
  noBreakTarget();
  undeclaredContinueLabel();
  noContinueTarget();
  wrongContinueLabel();
  noncaptureLabel();
  noncaptureBreak();
  noncaptureContinue();
}
