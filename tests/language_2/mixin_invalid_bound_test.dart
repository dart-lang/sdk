// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class S0<T> {}

class S<T extends num> extends S0<String> {}

class M<T extends num> {}

class A<T extends num> extends S with M {}

// A CompileTimeError is reported here and in C, D, and E below, because T is
// not bounded. The purpose of this test is to verify bound checking in S, M,
// and A, the reason no bound is declared for T here.
class B<T> extends S<T> with M<int> {} //# 03: continued
class B<T> extends S<T> with M<int> {} //# 04: continued

class C<T> extends S<int> with M<T> {} //# 05: continued
class C<T> extends S<int> with M<T> {} //# 06: continued

class D<T> extends S<T> with M<bool> {} //# 07: continued
class D<T> extends S<T> with M<bool> {} //# 08: continued

class E<T> extends S<bool> with M<T> {} //# 09: continued
class E<T> extends S<bool> with M<T> {} //# 10: continued

main() {
  new A<int>(); //  //# 01: ok
  new A<bool>(); // //# 02: compile-time error
  new B<int>(); //  //# 03: compile-time error
  new B<bool>(); // //# 04: compile-time error
  new C<int>(); //  //# 05: compile-time error
  new C<bool>(); // //# 06: compile-time error
  new D<int>(); //  //# 07: compile-time error
  new D<bool>(); // //# 08: compile-time error
  new E<int>(); //  //# 09: compile-time error
  new E<bool>(); // //# 10: compile-time error
}
