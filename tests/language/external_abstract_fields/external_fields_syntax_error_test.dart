// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that external variable declarations do not allow more
// than they should.

// Checks that only the syntactically correct declarations are allowed.

// External variables must not have initializers.
external var topInit = 0; //# 1: syntax error

// External variables must not be const.
external const topConst; //# 2: syntax error

// External variables must not have be late.
external late var topLate; //# 3: syntax error

// External variables must not have be abstract
// (and top-level declaration must not be abstract).
external abstract var topAbstract1; //# 4: syntax error
abstract external var topAbstract2; //# 5: syntax error

class StaticMembers {
  // External static fields cannot have initializers.
  external static int init1 = 0; //# 6: syntax error

  // External static fields cannot be late.
  external static late int late1; //# 7: syntax error

  // External static fields cannot be late and final.
  external static late final int late2; //# 8: syntax error

  // External static fields cannot be const.
  external static const int const1; //# 9: syntax error
  external static const int const1 = 0; //# 10: syntax error

  // External static fields cannot be final and covariant.
  external static covariant final int covariant1; //# 11: syntax error
  external static final covariant int covariant2; //# 12: syntax error

  // External static fields cannot be abstract.
  external static abstract int abstract1; //# 13: syntax error
}

class InstanceMembers {
  // External fields cannot have initializers.
  external int init1 = 0; //# 14: syntax error

  // External fields cannot be late.
  external late int late1; //# 15: syntax error

  // External fields cannot be late and final.
  external late final int late2; //# 16: syntax error

  // External fields cannot be const.
  external const int const1; //# 17: syntax error

  // External fields cannot be final and covariant.
  external covariant final int covariant1; //# 18: syntax error
  external final covariant int covariant2; //# 19: syntax error

  // External fields cannot be abstract.
  external abstract int abstract1; //# 20: syntax error
  abstract external int abstract2; //# 21: syntax error
}

void main() {
  // No external local variables
  external var x; //# 22: syntax error

  // Ensure that the declarations are in use.
  List _ = [
    StaticMembers.init1, //# 6: continued
    StaticMembers.late1, //# 7: continued
    StaticMembers.late2, //# 8: continued
    StaticMembers.const1, //# 9: continued
    StaticMembers.covariant1, //# 10: continued
    StaticMembers.covariant2, //# 11: continued
    StaticMembers.abstract1, //# 12: continued
    InstanceMembers(),
  ];
}
