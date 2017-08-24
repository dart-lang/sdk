// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--generic-method-syntax

/// Dart test on the usage of method type arguments in type expressions.

import "package:expect/expect.dart";

bool f1<T>(Object o) => o is T;

bool f2<T>(Object o) => o is List<T>;

bool f3<T>(Object o) => o is! T;

bool f4<T>(Object o) => o is! List<T>;

T f5<T>(Object o) => o as T;

List<T> f6<T>(Object o) => o as List<T>;

Type f7<T>() => T;

class TypeValue<X> {
  Type get value => X;
}

Type f8<T>() => new TypeValue<List<T>>().value;

bool f9<T>(Object o) => o is Map<T, String>;

class IsMap<A> {
  @NoInline()
  bool check<B>(o) => o is Map<A, B>;
}

main() {
  String s = "Hello!";
  List<String> ss = <String>[s];
  Expect.isTrue(f1<int>(42));
  Expect.isFalse(f1<String>(42));
  Expect.isTrue(f2<int>(<int>[42]));
  Expect.isFalse(f2<String>(<int>[42])); // `is List<String>` is false.
  Expect.isFalse(f3<int>(42));
  Expect.isTrue(f3<String>(42));
  Expect.isFalse(f4<int>(<int>[42]));
  Expect.isTrue(f4<String>(<int>[42])); // `is! List<dynamic>` is true.
  Expect.equals(f5<String>(s), s); // `s as String == s`
  Expect.throwsCastError(() => f5<int>(s)); // `s as int == s`
  Expect.equals(f6<String>(ss), ss);
  Expect.throwsCastError(() => f6<int>(ss)); // `as List<int>` fails.
  Expect.equals(f7<int>(), int);

  // Returns `List<int>`.
  Expect.equals(f8<int>(), new TypeValue<List<int>>().value);

  Expect.isTrue(f9<int>(<int, String>{}));
  Expect
      .isTrue(f9<int>(<bool, String>{})); // `is Map<dynamic, String>` is true.
  Expect.isFalse(f9<int>(<int, int>{}));

  Expect.isTrue(new IsMap<int>().check<String>(<int, String>{}));
  Expect.isTrue(new IsMap<int>().check<int>(<int, String>{}));
}
