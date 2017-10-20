// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--no-reify-generic-functions

/// Dart test on the usage of method type arguments in type
/// expressions. With '--no-reify-generic-functions', the type
/// argument is available at runtime, but erased to `dynamic`.

library generic_methods_type_expression_test;

import "package:expect/expect.dart";

bool f1<T>(Object o) => o is T; //  //# 01: static type warning

bool f2<T>(Object o) => o is List<T>;

bool f3<T>(Object o) => o is! T; //  //# 03: static type warning

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
  Expect.throws(() => f1<int>(42), (e) => e is TypeError); // //# 01: continued
  Expect.throws(() => f1<String>(42), (e) => e is TypeError); // //# 01: continued
  Expect.equals(f2<int>(<int>[42]), true);
  Expect.equals(f2<String>(<int>[42]), true); // `is List<dynamic>` is true.
  Expect.throws(() => f3<int>(42), (e) => e is TypeError); // //# 03: continued
  Expect.throws(() => f3<String>(42), (e) => e is TypeError); // //# 03: continued
  Expect.equals(f4<int>(<int>[42]), false);
  Expect.equals(f4<String>(<int>[42]), false); // `is! List<dynamic>` is false.
  Expect.equals(f5<String>(s), s); // `s as dynamic == s`
  Expect.equals(f5<int>(s), s); // `s as dynamic == s`
  Expect.equals(f6<String>(ss), ss);
  Expect.equals(f6<int>(ss), ss); // `as List<dynamic>` succeeds.
  Expect.throws(() => f7<int>(), (e) => e is TypeError);
  Expect.equals(f8<int>(), List); // Returns `List<dynamic>`.

  Expect.isTrue(f9<int>(<int, String>{}));
  Expect
      .isTrue(f9<int>(<bool, String>{})); // `is Map<dynamic, String>` is true.
  Expect.isFalse(f9<int>(<int, int>{}));

  Expect.isTrue(new IsMap<int>().check<String>(<int, String>{}));
  Expect.isTrue(new IsMap<int>().check<int>(<int, String>{}));
}
