// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



// Test parsing around ambiguities in grammar for explicit type instantiation.
//
// If an expression is followed by a  `<`
// which is then followed by potential type arguments and a `>`,
// it is parsed as type arguments if the next token is one of
// `)`, `}`, `]`, `:`, `;`, `,`, `(`, `.`, `==` or `!=`.
// Otherwise it's (attempted) parsed as a `<` infix operator.
// This decision is made no matter whether what otherwise follows
// is valid for that choice.

typedef X<_> = Class;

typedef Z<_, __> = Class;

const Object? v = null;
const dynamic d = null;

class Class {
  Class([_]);
  Class.named([_]);

  static Class get instance => Class();

  Class get value => this;
  Class call([_]) => this;
}

int f1<X>([_]) => 0;
int f2<X, Y>([_]) => 0;
int f3<X, Y, Z>([_]) => 0;

// Type of the instantiation of the functions above.
typedef F = int Function([Object? _]);

void expect1<T extends Object?>(T? a) {}
void expect2(Object? a, Object? b) {}
void expect3(Object? a, Object? b, Object? c) {}
void expect4(Object? a, Object? b, Object? c, Object? d) {}

// Anything goes!
// We only care about parsing here, if it parses,
// all objects support all the operations.
extension <T extends Object?> on T {
  T get self => this;
  dynamic get any => null;
  Object? operator *(_) => null;
  Object? operator -(_) => null;
  Object? operator <(_) => null;
  Object? operator >(_) => null;
  Object? operator >>(_) => null;
  Object? operator >>>(_) => null;
  Object? operator [](_) => null;
  Object? call<R, S>([_]) => null;
  bool get asBool => true;
  int get prop => 0;
  set prop(int _) {}
}

void main() {
  Object? as = "gotcha!"; // Built-in identifier declared as variable.

  // Validly parsed as type instantiation.
  // Continuation tokens are: `(`, `.`, `==` and `!=`.
  expect1<Class>(Z<X, X>(2));
  expect1<Class>(Z<X, X>.named(2));
  expect1<Function>(Z<X, X>.named); // constructor tear-off
  expect1<bool>(Z<X, X> == Class);
  expect1<bool>(Z<X, X> != Class);
  // Stop tokens are `)`, `,`, `}`, `]`, `:` and `;`.
  expect1<Type>(Z<X, X>);
  expect1<Type>(Z<X, X>,);
  expect1<Set<Type>>({Z<X, X>});
  expect1<List<Type>>([Z<X, X>]);
  expect1<Type>(v.asBool ? Z<X, X> : int);
  expect1<Map<Type, int>>({Z<X, X>: 1});
  {
    Type _ = Z<X, X>;
  }

  // Validly parsed as generic function instantiation.
  expect1<int>(f2<X, X>(1));
  expect1<F>(f2<X, X>.self);
  expect1<int>(f2<X, X>.self());
  expect1<bool>(f2<X, X> == null);
  expect1<bool>(f2<X, X> != null);

  expect1<F>(f2<X, X>);
  expect1<F>(f2<X, X>,);
  expect1<Set<F>>({f2<X, X>});
  expect1<List<F>>([f2<X, X>]);
  expect1<F>(v.asBool ? f2<X, X> : ([_]) => 2);
  expect1<Map<F, int>>({f2<X, X> : 2});
  {
    F _ = f2<X, X>;
  }

  // Also works if ending in `>>` or `>>>`
  expect1<Class>(Z<X, Z<X, X>>(2));
  expect1<Class>(Z<X, Z<X, X>>.named(2));
  expect1<Function>(Z<X, Z<X, X>>.named); // constructor tear-off
  expect1<bool>(Z<X, Z<X, X>> == Class);
  expect1<bool>(Z<X, Z<X, X>> != Class);
  // Stop tokens are `)`, `,`, `}`, `]`, `:` and `;`.
  expect1<Type>(Z<X, Z<X, X>>);
  expect1<Type>(Z<X, Z<X, X>>,);
  expect1<Set<Type>>({Z<X, Z<X, X>>});
  expect1<List<Type>>([Z<X, Z<X, X>>]);
  expect1<Type>(v.asBool ? Z<X, Z<X, X>> : int);
  expect1<Map<Type, int>>({Z<X, Z<X, X>> : 1});
  {
    Type _ = Z<X, Z<X, X>>;
  }

  // Validly parsed as generic function instantiation.
  expect1<int>(f2<X, Z<X, X>>(1));
  expect1<F>(f2<X, Z<X, X>>.self);
  expect1<int>(f2<X, Z<X, X>>.self());
  expect1<bool>(f2<X, Z<X, X>> == null);
  expect1<bool>(f2<X, Z<X, X>> != null);

  expect1<F>(f2<X, Z<X, X>>);
  expect1<F>(f2<X, Z<X, X>>,);
  expect1<Set<F>>({f2<X, Z<X, X>>});
  expect1<List<F>>([f2<X, Z<X, X>>]);
  expect1<F>(v.asBool ? f2<X, Z<X, X>> : ([_]) => 2);
  expect1<Map<F, int>>({f2<X, Z<X, X>> : 2});
  {
    F _ = f2<X, Z<X, X>>;
  }

  expect1<Class>(Z<X, Z<X, Z<X, X>>>(2));
  expect1<Class>(Z<X, Z<X, Z<X, X>>>.named(2));
  expect1<Function>(Z<X, Z<X, Z<X, X>>>.named); // constructor tear-off
  expect1<bool>(Z<X, Z<X, Z<X, X>>> == Class);
  expect1<bool>(Z<X, Z<X, Z<X, X>>> != Class);
  // Stop tokens are `)`, `,`, `}`, `]`, `:` and `;`.
  expect1<Type>(Z<X, Z<X, Z<X, X>>>);
  expect1<Type>(Z<X, Z<X, Z<X, X>>>,);
  expect1<Set<Type>>({Z<X, Z<X, Z<X, X>>>});
  expect1<List<Type>>([Z<X, Z<X, Z<X, X>>>]);
  expect1<Type>(v.asBool ? Z<X, Z<X, Z<X, X>>> : int);
  expect1<Map<Type, int>>({Z<X, Z<X, Z<X, X>>>: 1});
  {
    Type _ = Z<X, Z<X, Z<X, X>>>;
  }

  // Validly parsed as generic function instantiation.
  expect1<int>(f2<X, Z<X, Z<X, X>>>(1));
  expect1<F>(f2<X, Z<X, Z<X, X>>>.self);
  expect1<int>(f2<X, Z<X, Z<X, X>>>.self());
  expect1<bool>(f2<X, Z<X, Z<X, X>>> == null);
  expect1<bool>(f2<X, Z<X, Z<X, X>>> != null);

  expect1<F>(f2<X, Z<X, Z<X, X>>>);
  expect1<F>(f2<X, Z<X, Z<X, X>>>,);
  expect1<Set<F>>({f2<X, Z<X, Z<X, X>>>});
  expect1<List<F>>([f2<X, Z<X, Z<X, X>>>]);
  expect1<F>(v.asBool ? f2<X, Z<X, Z<X, X>>> : ([_]) => 2);
  expect1<Map<F, int>>({f2<X, Z<X, Z<X, X>>> : 2});
  {
    F _ = f2<X, Z<X, Z<X, X>>>;
  }

  // Parsed as instantiation, can't access statics on instantiated type literal.
  expect1<Class>(Z<X, X>.instance);
  //                     ^^^^^^^^
  // [cfe] Cannot access static member on an instantiated generic class.
  // [analyzer] unspecified


  // Not valid <typeList> inside `<..>`, so always parsed as operators.
  // The expect2 function requires two arguments, so it would be a type
  // error to parse as type arguments.
  expect2(Z < X, 2 > (2));
  expect2(Z < 2, X > (2));
  expect2(Z < X, 2 > (2));
  expect2(Z < X, v! > (2));
  expect3(Z < X, Z < X, 2 >> (2));
  expect4(Z < X, Z < X, Z < X, 2 >>> (2));
  // `as` is a built-in identifier, so it cannot be a *type*,
  // preventing the lookahead from `<` from matching <typeList>,
  // and therefore it's parsed as an operator.
  expect2(Z < X, as > (2));
  expect3(Z < X, Z < X, as >> (2));
  expect4(Z < X, Z < X, Z < X, as >>> (2));

  // Validly parsed as operators due to disambiguation.
  expect2(Z < X, X > X);
  expect2(Z < X, X > 2);
  expect2(Z < X, X > .2); // That `.` is part of the number literal, not a `.` token.
  expect2(Z < X, X > -2);
  expect2(Z < X, X > as);
  expect2(Z < X, X > [1]);
  expect2(Z < X, X > ![1].asBool);
  expect2(Z < X, X > ++[1].prop);
  expect2(Z < X, X > <int>[1]);

  // Some would be valid as instantiation too, as proven by parenthefication.
  expect1((Z<X, X>) - 2);
  expect1((Z<X, X>)[1]);
  expect1((Z<X, X>)![1].asBool);  // ignore: unnecessary_non_null_assertion
  //       ^
  // [cfe] Operand of null-aware operation '!' has type 'Type' which excludes null.

  // Works if the type argument would end in `>>` or `>>>` too.
  expect3(Z < X, Z < X, X >> X);
  expect3(Z < X, Z < X, X >> 2);
  expect3(Z < X, Z < X, X >> .2);
  expect3(Z < X, Z < X, X >> -2);
  expect3(Z < X, Z < X, X >> as);
  expect3(Z < X, Z < X, X >> [1]);
  expect3(Z < X, Z < X, X >> ![1].asBool);
  expect3(Z < X, Z < X, X >> ++[1].prop);

  expect4(Z < X, Z < X, Z < X, X >>> X);
  expect4(Z < X, Z < X, Z < X, X >>> 2);
  expect4(Z < X, Z < X, Z < X, X >>> .2);
  expect4(Z < X, Z < X, Z < X, X >>> -2);
  expect4(Z < X, Z < X, Z < X, X >>> as);
  expect4(Z < X, Z < X, Z < X, X >>> [1]);
  expect4(Z < X, Z < X, Z < X, X >>> ![1].asBool);
  expect4(Z < X, Z < X, Z < X, X >>> ++[1].prop);

  // No valid parsing either way.

  // Content of type arguments not valid types.
  // Cannot parse as operators since grammar doesn't allow chaining.
  X<2>(2);
  // ^
  // [cfe] A comparison expression can't be an operand of another comparison expression.
  // [analyzer] SYNTACTIC_ERROR.EQUALITY_CANNOT_BE_EQUALITY_OPERAND

  X<2>;
  //  ^
  // [cfe] Expected an identifier, but got ';'.
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // ^
  // [cfe] A comparison expression can't be an operand of another comparison expression.
  // [analyzer] SYNTACTIC_ERROR.EQUALITY_CANNOT_BE_EQUALITY_OPERAND

  X<2>.instance; // Not type argument.
  //  ^
  // [cfe] Expected an identifier, but got '.'.
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // ^
  // [cfe] A comparison expression can't be an operand of another comparison expression.
  // [analyzer] SYNTACTIC_ERROR.EQUALITY_CANNOT_BE_EQUALITY_OPERAND

  X<2>.any;
  //  ^
  // [cfe] Expected an identifier, but got '.'.
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // ^
  // [cfe] A comparison expression can't be an operand of another comparison expression.
  // [analyzer] SYNTACTIC_ERROR.EQUALITY_CANNOT_BE_EQUALITY_OPERAND

  // This would be invalid even if `X` had an `any` member. See next.
  X<X>.any; // Invalid, Class does not have any static `any` member.
  //   ^^^
  // [cfe] Member not found: 'any'.
  // [analyzer] unspecified

  X<X>.instance; // Does have static `instance` member, can't access this way.
  //   ^^^^^^^^
  // [cfe] Cannot access static member on an instantiated generic class.
  // [analyzer] unspecified

  // Parse error.

  X<X>2;
  // ^
  // [cfe] A comparison expression can't be an operand of another comparison expression.
  // [analyzer] SYNTACTIC_ERROR.EQUALITY_CANNOT_BE_EQUALITY_OPERAND

  // Doesn't parse as operators, would be valid if type arguments.

  // The following `-` forces operators, but those can't parse like this.
  X<X>-1;
  // ^
  // [cfe] A comparison expression can't be an operand of another comparison expression.
  // [analyzer] SYNTACTIC_ERROR.EQUALITY_CANNOT_BE_EQUALITY_OPERAND

  // Parsed as operators on function instantiation too (parsing doesn't know.)
  f1<X> - 1;
  //  ^
  // [cfe] A comparison expression can't be an operand of another comparison expression.
  // [analyzer] SYNTACTIC_ERROR.EQUALITY_CANNOT_BE_EQUALITY_OPERAND

  // Parsed as a generic invocation. Valid because of the `call` extension
  // method on `Object?`.
  expect1(v < X, X > (2));

  // Parsed as a generic invocation. Valid because this is an *invocation*
  // rather than an *instantiation*. We don't allow instantiation on `dynamic`,
  // but we do allow calling.
  expect1(d < X, X > (2));

  // Valid only if parenthesized.
  expect1((Z < X, X >) * 2);

  // Valid only if parenthesized.
  expect1((Z < X, X >) < 4);

  // Since `v` has type `Object?`, this is an extension invocation of the
  // implicit `call` tear off.
  /**/ v<int, String>;
}
