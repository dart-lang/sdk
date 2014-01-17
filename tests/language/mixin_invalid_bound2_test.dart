// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class S0<T> { }

class S<U extends num, V extends U> extends S0<String> { }

class M<U extends num, V extends U> { }

class A<U extends num, V extends U> extends S with M { }

// A StaticWarning is reported here and in C, D, and E below, because U and V
// are not bounded. The purpose of this test is to verify bound checking in S,
// M, and A, the reason no bounds are declared for U and V here.
class B<U, V> extends S<U, V> with M<int, int> { }

class C<U, V> extends S<int, int> with M<U, V> { }

class D<U, V> extends S<U, V> with M<double, int> { }

class E<U, V> extends S<double, int> with M<U, V> { }

main() {
  new A<int, int>();  /// 01: static type warning
  new A<double, int>();  /// 02: static type warning, dynamic type error
  new A<bool, bool>();  /// 03: static type warning, dynamic type error
  new B<int, int>();  /// 04: static type warning
  new B<double, int>();  /// 05: static type warning, dynamic type error
  new B<bool, bool>();  /// 06: static type warning, dynamic type error
  new C<int, int>();  /// 07: static type warning
  new C<double, int>();  /// 08: static type warning, dynamic type error
  new C<bool, bool>();  /// 09: static type warning, dynamic type error
  new D<int, int>();  /// 10: static type warning, dynamic type error
  new D<double, int>();  /// 11: static type warning, dynamic type error
  new D<bool, bool>();  /// 12: static type warning, dynamic type error
  new E<int, int>();  /// 12: static type warning, dynamic type error
  new E<double, int>();  /// 13: static type warning, dynamic type error
  new E<bool, bool>();  /// 14: static type warning, dynamic type error
}
