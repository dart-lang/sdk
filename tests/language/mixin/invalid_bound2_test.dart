// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class S0<T> {}

class S<U extends num, V extends U> extends S0<String> {}

class M<U extends num, V extends U> {}

class A<U extends num, V extends U> extends S with M {}

// A StaticWarning is reported here and in C, D, and E below, because U and V
// are not bounded. The purpose of this test is to verify bound checking in S,
// M, and A, the reason no bounds are declared for U and V here.
class B<U, V> extends S<U, V> with M<int, int> {} //# 04: continued
class B<U, V> extends S<U, V> with M<int, int> {} //# 05: continued
class B<U, V> extends S<U, V> with M<int, int> {} //# 06: continued

class C<U, V> extends S<int, int> with M<U, V> {} //# 07: continued
class C<U, V> extends S<int, int> with M<U, V> {} //# 08: continued
class C<U, V> extends S<int, int> with M<U, V> {} //# 09: continued

class D<U, V> extends S<U, V> with M<double, int> {} //# 10: continued
class D<U, V> extends S<U, V> with M<double, int> {} //# 11: continued
class D<U, V> extends S<U, V> with M<double, int> {} //# 12: continued

class E<U, V> extends S<double, int> with M<U, V> {} //# 13: continued
class E<U, V> extends S<double, int> with M<U, V> {} //# 14: continued
class E<U, V> extends S<double, int> with M<U, V> {} //# 15: continued

main() {
  new A<int, int>(); //    //# 01: ok
  new A<double, int>(); // //# 02: compile-time error
  new A<bool, bool>(); //  //# 03: compile-time error
  new B<int, int>(); //    //# 04: compile-time error
  new B<double, int>(); // //# 05: compile-time error
  new B<bool, bool>(); //  //# 06: compile-time error
  new C<int, int>(); //    //# 07: compile-time error
  new C<double, int>(); // //# 08: compile-time error
  new C<bool, bool>(); //  //# 09: compile-time error
  new D<int, int>(); //    //# 10: compile-time error
  new D<double, int>(); // //# 11: compile-time error
  new D<bool, bool>(); //  //# 12: compile-time error
  new E<int, int>(); //    //# 13: compile-time error
  new E<double, int>(); // //# 14: compile-time error
  new E<bool, bool>(); //  //# 15: compile-time error
}
