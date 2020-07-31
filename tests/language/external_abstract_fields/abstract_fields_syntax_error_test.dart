// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that abstract instance variable declarations are abstract and
// do not allow more than they should.

// Top-level declarations cannot be abstract.
abstract int top0; //# 1: syntax error
abstract var top1; //# 2: syntax error
abstract final top2; //# 3: syntax error
abstract final int top3; //# 4: syntax error
abstract covariant int top4; //# 5: syntax error
abstract covariant var top5; //# 6: syntax error

// Check that only the syntactically correct declarations are allowed.
abstract class C {
  // Abstract fields cannot have initializers.
  abstract int init1 = 0; //# 7: syntax error

  // Abstract fields cannot be late.
  abstract late int late1; //# 8: syntax error

  // Abstract fields cannot be late and final.
  abstract late final int late2; //# 9: syntax error

  // Abstract fields cannot be static.
  abstract static int static1; //# 10: syntax error

  /// Static fields cannot be abstract.
  static abstract int static2; //# 11: syntax error

  /// Abstract fields cannot be const (because const fields must be static).
  abstract const int const1; //# 12: syntax error

  /// Abstract fields cannot be static const.
  abstract static const int staticConst1; //# 13: syntax error

  // Abstract fields cannot be final and covariant (because no declaration can).
  abstract covariant final int covariant1; //# 14: syntax error

  // Abstract fields cannot be final and covariant (because no declaration can).
  abstract final covariant int covariant2; //# 15: syntax error
}

void main() {
  // No abstract local variables
  abstract var x; //# 16: syntax error

  // Make sure `C` is in use.
  print(C);
}
