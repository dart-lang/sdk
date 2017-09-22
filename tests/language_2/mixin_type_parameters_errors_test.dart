// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class S<T> {}

class M<U> {}

class A<X> extends S<int> with M<double> {}
class B<U, V> extends S with M<U, V> { } // //# 01: compile-time error
class C<A, B> extends S<A, int> with M { } // //# 02: compile-time error

class F<X> = S<X> with M<X>;
class G = S<int> with M<double, double>; // //# 05: compile-time error

main() {
  var a;
  a = new A();
  a = new A<int>();
  a = new A<String, String>(); // //# 03: compile-time error
  a = new F<int>();
  a = new F<int, String>(); //  //# 04: compile-time error
}
