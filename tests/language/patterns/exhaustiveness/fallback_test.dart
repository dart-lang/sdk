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
// still not cause errors.

import 'dart:async';

enum E {
  e1,
  e2
}

void ignore(Object? value) {}

void hasDefault(bool b) {
  // Flow analysis recognizes that the presence of a `default` clause makes a
  // switch statement exhaustive.
  //
  // The real exhaustiveness handles this.
  switch (b) {
    case true:
      break;
    default:
      break;
  }
}

void untypedWildcard(bool b) {
  // Flow analysis recognizes that the presence of an untyped wildcard pattern
  // (`_`) makes a switch exhaustive.
  //
  // The real exhaustiveness handles this.
  switch (b) {
    case true:
      break;
    case _:
      break;
  }
  ignore(switch (b) {
      true => 0,
      _ => 1
  });
}

void untypedVariable(bool b) {
  // Flow analysis recognizes that the presence of an untyped variable pattern
  // makes a switch exhaustive.
  //
  // The real exhaustiveness handles this.
  switch (b) {
    case true:
      break;
    case var x:
      break;
  }
  ignore(switch (b) {
      true => 0,
      var x => 1
  });
}

void typedWildcard(bool b) {
  // Flow analysis recognizes that the presence of a typed wildcard pattern
  // (where the type is a supertype of the scrutinee type) makes a switch
  // exhaustive.
  //
  // The real exhaustiveness handles this.
  switch (b) {
    case true:
      break;
    case bool _:
      break;
  }
  switch (b) {
    case true:
      break;
    case Object _:
      break;
  }
  ignore(switch (b) {
      true => 0,
      bool _ => 1
  });
  ignore(switch (b) {
      true => 0,
      Object _ => 1
  });
}

void typedVariable(bool b) {
  // Flow analysis recognizes that the presence of a typed variable pattern
  // (where the type is a supertype of the scrutinee type) makes a switch
  // exhaustive.
  //
  // The real exhaustiveness handles this.
  switch (b) {
    case true:
      break;
    case bool x:
      break;
  }
  switch (b) {
    case true:
      break;
    case Object x:
      break;
  }
  ignore(switch (b) {
      true => 0,
      bool x => 1,
  });
  ignore(switch (b) {
      true => 0,
      Object x => 1,
  });
}

void objectPattern(bool b) {
  // Flow analysis recognizes that the presence of an object pattern with no
  // fields (where the type is a supertype of the scrutinee type) makes a switch
  // exhaustive.
  //
  // The real exhaustiveness handles this.
  switch (b) {
    case true:
      break;
    case bool():
      break;
  }
  switch (b) {
    case true:
      break;
    case Object():
      break;
  }
  ignore(switch (b) {
      true => 0,
      bool() => 1
  });
  ignore(switch (b) {
      true => 0,
      Object() => 1
  });
}

void logicalOrPattern(bool b) {
  // Flow analysis recognizes that the presence of a logical-or pattern (where
  // one of the arms of the logical-or fully covers the scrutinee type) makes a
  // switch exhaustive.
  //
  // The real exhaustiveness handles this.
  switch (b) {
    case true || bool():
      break;
  }
  switch (b) {
    case bool() || true:
      break;
  }
  ignore(switch (b) {
      true || bool() => 0
  });
  ignore(switch (b) {
      bool() || true => 0
  });
}

void logicalAndPattern(bool b) {
  // Flow analysis recognizes that the presence of a logical-and pattern (where
  // both of the arms of the logical-and fully cover the scrutinee type) makes a
  // switch exhaustive.
  //
  // The real exhaustiveness handles this.
  switch (b) {
    case bool() && Object():
      break;
  }
  ignore(switch (b) {
      bool() && Object() => 0
  });
}

void castPattern(bool? b) {
  // Flow analysis recognizes that the presence of a cast pattern (where the
  // inner pattern fully covers the cast type) makes a switch exhaustive.
  //
  // The real exhaustiveness handles this.
  switch (b) {
    case bool() as bool:
      break;
  }
  ignore(switch (b) {
      bool() as bool => 0
  });
}

void nullAssertPattern(bool? b1, bool? b2) {
  // Flow analysis recognizes that the presence of a null assert pattern (where
  // the inner pattern fully covers the promoted type) makes a switch
  // exhaustive.
  //
  // The real exhaustiveness handles this.
  switch (b1) {
    case bool()!:
      break;
  }
  ignore(switch (b2) {
      bool()! => 0
  });
}

void nullPattern(Null n) {
  // Flow analysis recognizes that the constant `null` fully covers the type
  // `Null`.
  //
  // The real exhaustiveness handles this.
  switch (n) {
    case null:
      break;
  }
  ignore(switch (n) {
      null => 0
  });
}

void parenthesizedPattern(bool b, E e) {
  // Flow analysis recognizes that a parenthesized pattern is equivalent to its
  // inner pattern.
  //
  // The real exhaustiveness handles this.
  switch (b) {
    case (bool()):
      break;
  }
  switch (b) {
    case ((bool())):
      break;
  }
  switch (e) {
    case (E.e1):
      break;
    case ((E.e2)):
      break;
  }
  ignore(switch (b) {
      (bool()) => 0
  });
  ignore(switch (b) {
      ((bool())) => 0
  });
  ignore(switch (e) {
      (E.e1) => 0,
      ((E.e2)) => 1
  });
}

void recordPattern((bool, E) r) {
  // Flow analysis recognizes that a record pattern (where the subpatterns fully
  // cover the respective field types) make a switch exhaustive.
  //
  // The real exhaustiveness handles this.
  switch (r) {
    case (bool(), E()):
      break;
  }
  ignore(switch (r) {
      (bool(), E()) => 0
  });
}

void factorNullable(bool? b) {
  // Flow analysis recognizes that the type `T?` factors into `T` and `Null`.
  //
  // The real exhaustiveness handles this.
  switch (b) {
    case null:
      break;
    case bool():
      break;
  }
  ignore(switch (b) {
      null => 0,
      bool() => 1
  });
}

void factorFutureOr(FutureOr<bool> x) {
  // Flow analysis recognizes that a FutureOr<T> type factors into `T` and
  // `Future<T>`.
  //
  // The real exhaustiveness handles this.
  switch (x) {
    case Future<bool>():
      break;
    case bool():
      break;
  }
  ignore(switch (x) {
      Future<bool>() => 0,
      bool() => 1
  });
}

void exhaustedEnum(E e) {
  // The old exhaustiveness algorithm recognizes that all enum values exhaust an
  // enum type.
  //
  // The real exhaustiveness handles this.
  switch (e) {
    case E.e1:
      break;
    case E.e2:
      break;
  }
  ignore(switch (e) {
      E.e1 => 0,
      E.e2 => 1
  });
}

void exhaustedNullableEnum(E? e) {
  // The old exhaustiveness algorithm recognizes that all enum values, plus
  // `null`, exhaust a nullable enum type.
  //
  // The real exhaustiveness handles this.
  switch (e) {
    case E.e1:
      break;
    case E.e2:
      break;
    case null:
      break;
  }
  ignore(switch (e) {
      E.e1 => 0,
      E.e2 => 1,
      null => 2
  });
}

main() {
  hasDefault(false);
  untypedWildcard(false);
  untypedVariable(false);
  typedWildcard(false);
  typedVariable(false);
  objectPattern(false);
  logicalOrPattern(false);
  logicalAndPattern(false);
  castPattern(false);
  nullAssertPattern(false, false);
  nullPattern(null);
  parenthesizedPattern(false, E.e1);
  recordPattern((false, E.e1));
  factorNullable(null);
  factorFutureOr(false);
  exhaustedEnum(E.e1);
  exhaustedNullableEnum(E.e1);
}
