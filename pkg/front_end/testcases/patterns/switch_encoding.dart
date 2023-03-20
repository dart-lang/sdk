// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E { a, b, c }

class PrimitiveEquals {
  final int field;

  const PrimitiveEquals(this.field);
}

class NonPrimitiveEquals {
  final int field;

  const NonPrimitiveEquals(this.field);

  int get hashCode => field.hashCode;

  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NonPrimitiveEquals && field == other.field;
  }
}

switchStatement(o) {
  switch (o) {
    case [var a] when a > 5:
    case [_, var a] when a < 5:
      print(a);
    case {1: var a}:
      print(a);
  }
}

switchStatementWithLabel(o) {
  switch (o) {
    case [var a] when a > 5:
    case [_, var a] when a < 5:
      print(a);
    case {1: var a}:
      print(a);
    label:
    case 1:
      print(1);
  }
}

switchStatementWithContinue(o) {
  switch (o) {
    case [var a] when a > 5:
    case [_, var a] when a < 5:
      print(a);
    case {1: var a}:
      print(a);
      continue label1;
    case 0:
      print(o);
    label1:
    case 1:
      print(1);
      continue label2;
    label2:
    case 2:
      print(2);
  }
}

switchStatementWithContinueNested(o1, o2) {
  switch (o1) {
    case [var a]:
      print(a);
    case {1: var a}:
      print(a);
      switch (o2) {
        case [var a] when a > 5:
        case [_, var a] when a < 5:
          print(a);
        case {1: var a}:
          print(a);
          continue label2a;
        case 0:
          print(o2);
          continue label1b;
        label1b:
        case 1:
          print(1);
          continue label2b;
        label2b:
        case 2:
          print(2);
          continue label1a;
      }
    case 0:
      print(o1);
    label1a:
    case 1:
      print(1);
      continue label2a;
    label2a:
    case 2:
      print(2);
      switch (o2) {
        case [var a] when a > 5:
        case [_, var a] when a < 5:
          print(a);
        case {1: var a}:
          print(a);
          continue label2a;
        case 0:
          print(o2);
          continue label1b;
        label1b:
        case 1:
          print(1);
          continue label2b;
        label2b:
        case 2:
          print(2);
          continue label1a;
      }
  }
}

switchStatementEnum(E o) {
  switch (o) {
    case E.a:
      print('a');
    case E.b:
      print('b');
    case E.c:
      print('c');
  }
}

switchStatementEnumWithGuard(E o) {
  switch (o) {
    case E.a when true:
      print('a');
    case E.b:
      print('b');
    case _:
  }
}

switchStatementEnumWithLabel(E o) {
  switch (o) {
    case E.a:
      print('a');
    label:
    case E.b:
      print('b');
    case E.c:
      print('c');
  }
}

switchStatementEnumWithContinue(E o) {
  switch (o) {
    case E.a:
      print('a');
      continue label1;
    label1:
    case E.b:
      print('b');
      continue label2;
    label2:
    case E.c:
      print('c');
  }
}

switchStatementPrimitiveEquals(o) {
  switch (o) {
    case const PrimitiveEquals(0):
      print('a');
    case const PrimitiveEquals(1):
      print('b');
  }
}

switchStatementNonPrimitiveEquals(o) {
  switch (o) {
    case const NonPrimitiveEquals(0):
      print('a');
    case const NonPrimitiveEquals(1):
      print('b');
  }
}

switchExpression(o) {
  return switch (o) {
    [var a] => a,
    {1: var a} => a,
    _ => null,
  };
}

switchExpressionEnum(E o) {
  return switch (o) {
    E.a => 0,
    E.b => 1,
    E.c => 2,
  };
}

switchExpressionEnumWithGuard(E o) {
  return switch (o) {
    E.a when true => 0,
    E.b => 1,
    _ => 2,
  };
}

switchExpressionPrimitiveEquals(o) {
  return switch (o) {
    const PrimitiveEquals(0) => 0,
    const PrimitiveEquals(1) => 1,
    _ => 2,
  };
}

switchExpressionNonPrimitiveEquals(o) {
  return switch (o) {
    const NonPrimitiveEquals(0) => 0,
    const NonPrimitiveEquals(1) => 1,
    _ => 2,
  };
}

switchStatementSymbol(Symbol s) {
  switch (s) {
    case #a:
      return 0;
    case const Symbol('b'):
      return 1;
    default:
      return 2;
  }
}

switchExpressionSymbol(Symbol s) {
  return switch (s) {
    #a => 0,
    const Symbol('b') => 1,
    _ => 2,
  };
}
