// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that an assignment on the left hand side of `&&` defeats promotion after
// the entire `&&` expression, even if the promotion is on the right hand side
// of `&&`.
//
// Note that it is not strictly necessary for soundness to defeat promotion
// under this circumstance, but it is in the spec.

class A {}

class B extends A {}

class C extends A {}

// An invocation of the form `checkNotB(x)` verifies that the static type of `x`
// is not `B`, since `B` is not assignable to `C`.
dynamic checkNotB(C c) => null;

// An invocation of the form `alwaysTrue(x)` always returns `true` regardless of
// `x`.
bool alwaysTrue(dynamic x) => true;

andChainedAndsUnparenthesizedRePromote([A a]) {
  a is B && alwaysTrue(a = null) && a is B && checkNotB(a);
}

andChainedAndsParenLeftRePromote([A a]) {
  (a is B && alwaysTrue(a = null)) && a is B && checkNotB(a);
}

main() {
  andChainedAndsUnparenthesizedRePromote();
  andChainedAndsParenLeftRePromote();
}
