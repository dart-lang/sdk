// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {}

class ConcreteClass implements Class<ConcreteClass> {}

typedef F<X extends Class<X>> = X;

class G<X extends Class<X>> {}

void method1(
  F t1, // Ok
  F<dynamic> t2, // Ok
  F<Class> t3, // Ok
  F<Class<dynamic>> t4, // Ok
  F<ConcreteClass> t5, // Ok
  F<Class<ConcreteClass>> t6, // Ok
  F<Object> t7, // Error
  F<int> t8, // Error
  {
  required G s1, // Ok
  required G<dynamic> s2, // Ok
  required G<Class> s3, // Ok
  required G<Class<dynamic>> s4, // Ok
  required G<ConcreteClass> s5, // Ok
  required G<Class<ConcreteClass>> s6, // Ok
  required G<Object> s7, // Error
  required G<int> s8, // Error
}) {
  void local(
    F t1, // Ok
    F<dynamic> t2, // Ok
    F<Class> t3, // Ok
    F<Class<dynamic>> t4, // Ok
    F<ConcreteClass> t5, // Ok
    F<Class<ConcreteClass>> t6, // Ok
    F<Object> t7, // Error
    F<int> t8, // Error
    {
    required G s1, // Ok
    required G<dynamic> s2, // Ok
    required G<Class> s3, // Ok
    required G<Class<dynamic>> s4, // Ok
    required G<ConcreteClass> s5, // Ok
    required G<Class<ConcreteClass>> s6, // Ok
    required G<Object> s7, // Error
    required G<int> s8, // Error
  }) {}
  (
    F t1, // Ok
    F<dynamic> t2, // Ok
    F<Class> t3, // Ok
    F<Class<dynamic>> t4, // Ok
    F<ConcreteClass> t5, // Ok
    F<Class<ConcreteClass>> t6, // Ok
    F<Object> t7, // Error
    F<int> t8, // Error
    {
    required G s1, // Ok
    required G<dynamic> s2, // Ok
    required G<Class> s3, // Ok
    required G<Class<dynamic>> s4, // Ok
    required G<ConcreteClass> s5, // Ok
    required G<Class<ConcreteClass>> s6, // Ok
    required G<Object> s7, // Error
    required G<int> s8, // Error
  }) {};
}

class Class1 {
  Class1(
    F t1, // Ok
    F<dynamic> t2, // Ok
    F<Class> t3, // Ok
    F<Class<dynamic>> t4, // Ok
    F<ConcreteClass> t5, // Ok
    F<Class<ConcreteClass>> t6, // Ok
    F<Object> t7, // Error
    F<int> t8, // Error
    {
    required G s1, // Ok
    required G<dynamic> s2, // Ok
    required G<Class> s3, // Ok
    required G<Class<dynamic>> s4, // Ok
    required G<ConcreteClass> s5, // Ok
    required G<Class<ConcreteClass>> s6, // Ok
    required G<Object> s7, // Error
    required G<int> s8, // Error
  });
  void method2(
    F t1, // Ok
    F<dynamic> t2, // Ok
    F<Class> t3, // Ok
    F<Class<dynamic>> t4, // Ok
    F<ConcreteClass> t5, // Ok
    F<Class<ConcreteClass>> t6, // Ok
    F<Object> t7, // Error
    F<int> t8, // Error
    {
    required G s1, // Ok
    required G<dynamic> s2, // Ok
    required G<Class> s3, // Ok
    required G<Class<dynamic>> s4, // Ok
    required G<ConcreteClass> s5, // Ok
    required G<Class<ConcreteClass>> s6, // Ok
    required G<Object> s7, // Error
    required G<int> s8, // Error
  }) {}
}

extension Extension1 on int {
  void method3(
    F t1, // Ok
    F<dynamic> t2, // Ok
    F<Class> t3, // Ok
    F<Class<dynamic>> t4, // Ok
    F<ConcreteClass> t5, // Ok
    F<Class<ConcreteClass>> t6, // Ok
    F<Object> t7, // Error
    F<int> t8, // Error
    {
    required G s1, // Ok
    required G<dynamic> s2, // Ok
    required G<Class> s3, // Ok
    required G<Class<dynamic>> s4, // Ok
    required G<ConcreteClass> s5, // Ok
    required G<Class<ConcreteClass>> s6, // Ok
    required G<Object> s7, // Error
    required G<int> s8, // Error
  }) {}
}

main() {}
