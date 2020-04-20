// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping for classes with call functions.

import 'package:expect/expect.dart';

typedef void Foo(bool a, [String b]);
typedef void Bar(bool a, [String b]);
typedef void Baz(bool a, {String b});
typedef void Boz(bool a);

class C1<T> {
  void call(T a, [String b]) {}
}

class D1<S, T> extends C1<T> {}

class C2<T> {
  void call(T a, {String b}) {}
}

class D2<S, T> extends C2<T> {}

main() {
  Function d1_String_bool = new D1<String, bool>();
  Expect.isTrue(d1_String_bool is Foo, 'd1_String_bool is Foo');
  Expect.isTrue(d1_String_bool is Bar, 'd1_String_bool is Bar');
  Expect.isFalse(d1_String_bool is Baz, 'd1_String_bool is Baz');
  Expect.isTrue(d1_String_bool is Boz, 'd1_String_bool is Boz');

  Function d1_bool_int = new D1<bool, int>();
  Expect.isTrue(d1_bool_int is Foo, 'd1_bool_int is Foo');
  Expect.isTrue(d1_bool_int is Bar, 'd1_bool_int is Bar');
  Expect.isFalse(d1_bool_int is Baz, 'd1_bool_int is Baz');
  Expect.isTrue(d1_bool_int is Boz, 'd1_bool_int is Boz');

  Function d1 = new D1();
  Expect.isTrue(d1 is Foo, 'd1 is Foo');
  Expect.isTrue(d1 is Bar, 'd1 is Bar');
  Expect.isFalse(d1 is Baz, 'd1 is Baz');
  Expect.isTrue(d1 is Boz, 'd1 is Boz');

  Function d2_String_bool = new D2<String, bool>();
  Expect.isFalse(d2_String_bool is Foo, 'd2_String_bool is Foo');
  Expect.isFalse(d2_String_bool is Bar, 'd2_String_bool is Bar');
  Expect.isTrue(d2_String_bool is Baz, 'd2_String_bool is Baz');
  Expect.isTrue(d2_String_bool is Boz, 'd2_String_bool is Boz');

  Function d2_bool_int = new D2<bool, int>();
  Expect.isFalse(d2_bool_int is Foo, 'd2_bool_int is Foo');
  Expect.isFalse(d2_bool_int is Bar, 'd2_bool_int is Bar');
  Expect.isTrue(d2_bool_int is Baz, 'd2_bool_int is Baz');
  Expect.isTrue(d2_bool_int is Boz, 'd2_bool_int is Boz');

  Function d2 = new D2();
  Expect.isFalse(d2 is Foo, 'd2 is Foo');
  Expect.isFalse(d2 is Bar, 'd2 is Bar');
  Expect.isTrue(d2 is Baz, 'd2 is Baz');
  Expect.isTrue(d2 is Boz, 'd2 is Boz');
}
