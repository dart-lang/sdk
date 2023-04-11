// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies proper functionality of the "fallback exhaustiveness
// algorithm", which we are using as a stopgap measure to allow people to try
// out the "patterns" feature before the full exhaustiveness algorithm is ready.
//
// The fallback exhaustiveness algorithm works as follows: a switch is
// considered exhaustive if either (a) it is recognized as exhaustive by flow
// analysis, or (b) it is recognized as exhaustive by the old (pre-patterns)
// exhaustiveness algorithm for enums.
//
// With the enabling of the real exhaustiveness algorithm, these switches should
// in most cases no longer cause errors.

// SharedOptions=--enable-experiment=patterns --enable-experiment=records --enable-experiment=sealed-class

sealed class A {}
class B extends A {}
class C extends A {}
class D extends A {}

enum E {
  e1,
  e2
}

void ignore(Object? value) {}

void typedWildcard(A a) {
  // Neither flow analysis nor the old exhaustiveness algorithm understand that
  // a sealed class factors into its subclasses.
  //
  // The real exhaustiveness handles this.
  switch (a) {
    case B _:
      break;
    case C _:
      break;
    case D _:
      break;
  }
  ignore(switch (a) {
      B _ => 0,
      C _ => 1,
      D _ => 2
  });
}

void typedVariable(A a) {
  // Neither flow analysis nor the old exhaustiveness algorithm understand that
  // a sealed class factors into its subclasses.
  //
  // The real exhaustiveness handles this.
  switch (a) {
    case B x:
      break;
    case C x:
      break;
    case D x:
      break;
  }
  ignore(switch (a) {
      B x => 0,
      C x => 1,
      D x => 2
  });
}

void typedObjectPattern(A a) {
  // Neither flow analysis nor the old exhaustiveness algorithm understand that
  // a sealed class factors into its subclasses.
  //
  // The real exhaustiveness handles this.
  switch (a) {
    case B():
      break;
    case C():
      break;
    case D():
      break;
  }
  ignore(switch (a) {
      B() => 0,
      C() => 1,
      D() => 2
  });
}

void logicalOrPattern(E e) {
  // Neither flow analysis nor the old exhaustiveness algorithm understand that
  // an enum value is exhausted by enum constants separated by `||`.
  //
  // The real exhaustiveness handles this.
  switch (e) {
    case E.e1 || E.e2:
      break;
  }
  ignore(switch (e) {
      E.e1 || E.e2 => 0
  });
}

void logicalAndPattern(E e) {
  // Neither flow analysis nor the old exhaustiveness algorithm understand enum
  // constants appearing on either side of `&&`.
  //
  // The real exhaustiveness handles this.
  switch (e) {
    case E.e1 && E():
      break;
    case E.e2 && E():
      break;
  }
  switch (e) {
    case E() && E.e1:
      break;
    case E() && E.e2:
      break;
  }
  ignore(switch (e) {
      E.e1 && E() => 0,
      E.e2 && E() => 1
  });
  ignore(switch (e) {
      E() && E.e1 => 0,
      E() && E.e2 => 1
  });
}

void castPattern(E? e) {
  // Neither flow analysis nor the old exhaustiveness algorithm understand enum
  // constants appearing inside a cast pattern.
  //
  // The real exhaustiveness handles this.
  switch (e) {
    case E.e1 as E:
      break;
    case E.e2:
      break;
  }
  ignore(switch (e) {
      E.e1 as E => 0,
      E.e2 => 1
  });
}

void nullCheckPattern(E? e) {
  // Neither flow analysis nor the old exhaustiveness algorithm understand enum
  // constants appearing inside a null-check pattern.
  //
  // The real exhaustiveness handles this.
  switch (e) {
    case E.e1?:
      break;
    case E.e2:
      break;
    case null:
      break;
  }
  ignore(switch (e) {
      E.e1? => 0,
      E.e2 => 1,
      null => 2
  });
}

void nullAssertPattern(E? e) {
  // Neither flow analysis nor the old exhaustiveness algorithm understand enum
  // constants appearing inside a null-assert pattern.
  //
  // The real exhaustiveness handles this.
  switch (e) {
    case E.e1!:
      break;
    case E.e2:
      break;
  }
  ignore(switch (e) {
      E.e1! => 0,
      //  ^
      // [analyzer] STATIC_WARNING.UNNECESSARY_NULL_ASSERT_PATTERN
      // [cfe] The null-assert pattern will have no effect because the matched type isn't nullable.
      E.e2 => 1
  });
}

void recordPattern((E, E) r) {
  // Neither flow analysis nor the old exhaustiveness algorithm split record
  // patterns up into cases.
  //
  // The real exhaustiveness handles this.
  switch (r) {
    case (E.e1, E.e1):
      break;
    case (E.e1, E.e2):
      break;
    case (E.e2, E.e1):
      break;
    case (E.e2, E.e2):
      break;
  }
  ignore(switch (r) {
      (E.e1, E.e1) => 0,
      (E.e1, E.e2) => 1,
      (E.e2, E.e1) => 2,
      (E.e2, E.e2) => 3
  });
}

void listPattern(List<int> l) {
  // Neither flow analysis nor the old exhaustiveness algorithm understand that
  // `[...]` matches all lists.
  //
  // The real exhaustiveness handles this.
  ignore(switch (l) {
      [...] => 0
  });
}

void mapPattern(Map<String, int> m) {
  // Neither flow analysis nor the old exhaustiveness algorithm understand that
  // `{...}` matches all maps.
  //
  // The real exhaustiveness handles this.
  ignore(switch (m) {
      Map() => 0
  });
}

void exhaustiveBoolean(bool b) {
  // Neither flow analysis nor the old exhaustiveness algorithm understand that
  // `bool` is exhausted by `true` and `false`.
  //
  // The real exhaustiveness handles this.
  switch (b) {
    case true:
      break;
    case false:
      break;
  }
  ignore(switch (b) {
      true => 0,
      false => 1
  });
}

void relationalPattern(E e) {
  // Neither flow analysis nor the old exhaustiveness algorithm understand that
  // `== enumValue` matches an enum value.
  //
  // TODO(johnniwinther): Should the real exhaustiveness handle this? The
  // call is on the expression which we do not control.
  switch (e) {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'E' is not exhaustively matched by the switch cases since it doesn't match 'E.e1'.
    case == E.e1:
      break;
    case == E.e2:
      break;
  }
  ignore(switch (e) {
  //     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
  //             ^
  // [cfe] The type 'E' is not exhaustively matched by the switch cases since it doesn't match 'E.e1'.
      == E.e1 => 0,
      == E.e2 => 1
  });
}

void withGuard(E e) {
  // The old exhaustiveness algorithm doesn't understand guards, but for
  // soundness it will ignore any cases that are guarded.
  //
  // The real exhaustiveness handles this.
  switch (e) {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'E' is not exhaustively matched by the switch cases since it doesn't match 'E.e1'.
    case E.e1 when true:
      break;
    case E.e2:
      break;
  }
  ignore(switch (e) {
  //     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
  //             ^
  // [cfe] The type 'E' is not exhaustively matched by the switch cases since it doesn't match 'E.e1'.
      E.e1 when true => 0,
      E.e2 => 1
  });
}

main() {
  typedWildcard(B());
  typedVariable(B());
  typedObjectPattern(B());
  logicalOrPattern(E.e1);
  logicalAndPattern(E.e1);
  castPattern(E.e1);
  nullCheckPattern(E.e1);
  nullAssertPattern(E.e1);
  recordPattern((E.e1, E.e1));
  listPattern([]);
  mapPattern({});
  exhaustiveBoolean(false);
  relationalPattern(E.e1);
  withGuard(E.e1);
}
