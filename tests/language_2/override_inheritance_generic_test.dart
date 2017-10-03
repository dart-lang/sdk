// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  method1(T t) => null; //# 01: ok
  method2(T t) => null; //# 02: ok
  method4(T t) => null; //# 04: compile-time error
  method5(T t) => null; //# 05: ok
  method7(T t) => null; //# 07: compile-time error
}

class B<S> extends A
<S> //# 01: continued
<num> //# 02: continued
<S> //# 04: continued
<S> //# 05: continued
{
  method1(S s) => null; //# 01: continued
  method2(int i) => null; //# 02: continued
  method3(S s) => null; //# 03: ok
  method4(int i) => null; //# 04: continued
  method6(S s) => null; //# 06: compile-time error
}

abstract class I<U> {
  method3(U u) => null; //# 03: continued
  method6(U u) => null; //# 06: continued
  method7(U u) => null; //# 07: continued
  method8(U u) => null; //# 08: compile-time error
  method9(U u) => null; //# 09: compile-time error
  method10(U u) => null; //# 10: compile-time error
}

abstract class J<V> {
  method8(V v) => null; //# 08: continued
  method9(V v) => null; //# 09: continued
  method10(V v) => null; //# 10: continued
}

abstract class Class<W> extends B
<double> //# 03: continued
<W> //# 05: continued
<W> //# 06: continued
<int> //# 07: continued
    implements
        I
<int> //# 03: continued
<num> //# 06: continued
<String> //# 07: continued
<int> //# 08: continued
<int> //# 09: continued
<int> //# 10: continued
        ,
        J
<String> //# 08: continued
<num> //# 09: continued
<num> //# 10: continued
{
  method3(num i) => null; //# 03: continued
  method5(W w) => null; //# 05: continued
  method6(int i) => null; //# 06: continued
  method7(double d) => null; //# 07: continued
  method8(double d) => null; //# 08: continued
}

class SubClass extends Class {
  method9(double d) => null; //# 09: continued
  method10(String s) => null; //# 10: continued
}

main() {
  new SubClass();
}
