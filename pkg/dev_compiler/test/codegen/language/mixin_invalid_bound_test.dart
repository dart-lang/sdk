// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class S0<T> { }

class S<T extends num> extends S0<String> { }

class M<T extends num> { }

class A<T extends num> extends S with M { }

// A StaticWarning is reported here and in C, D, and E below, because T is not
// bounded. The purpose of this test is to verify bound checking in S, M, and A,
// the reason no bound is declared for T here.
class B<T> extends S<T> with M<int> { }

class C<T> extends S<int> with M<T> { }

class D<T> extends S<T> with M<bool> { }

class E<T> extends S<bool> with M<T> { }

main() {
  new A<int>();  /// 01: static type warning
  new A<bool>();  /// 02: static type warning, dynamic type error
  new B<int>();  /// 03: static type warning
  new B<bool>();  /// 04: static type warning, dynamic type error
  new C<int>();  /// 05: static type warning
  new C<bool>();  /// 06: static type warning, dynamic type error
  new D<int>();  /// 07: static type warning, dynamic type error
  new D<bool>();  /// 08: static type warning, dynamic type error
  new E<int>();  /// 09: static type warning, dynamic type error
  new E<bool>();  /// 10: static type warning, dynamic type error
}
