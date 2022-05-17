// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {}

class ConcreteClass implements Class<ConcreteClass> {}

typedef F<X extends Class<X>> = X;

class G<X extends Class<X>> {}

F t1() => throw ''; // Ok
F<dynamic> t2() => throw ''; // Ok
F<Class> t3() => throw ''; // Ok
F<Class<dynamic>> t4() => throw ''; // Ok
F<ConcreteClass> t5() => throw ''; // Ok
F<Class<ConcreteClass>> t6() => throw ''; // Ok
F<Object> t7() => throw ''; // Error
F<int> t8() => throw ''; // Error
G s1() => throw ''; // Ok
G<dynamic> s2() => throw ''; // Ok
G<Class> s3() => throw ''; // Ok
G<Class<dynamic>> s4() => throw ''; // Ok
G<ConcreteClass> s5() => throw ''; // Ok
G<Class<ConcreteClass>> s6() => throw ''; // Ok
G<Object> s7() => throw ''; // Error
G<int> s8() => throw ''; // Error

method1() {
  F t1() => throw ''; // Ok
  F<dynamic> t2() => throw ''; // Ok
  F<Class> t3() => throw ''; // Ok
  F<Class<dynamic>> t4() => throw ''; // Ok
  F<ConcreteClass> t5() => throw ''; // Ok
  F<Class<ConcreteClass>> t6() => throw ''; // Ok
  F<Object> t7() => throw ''; // Error
  F<int> t8() => throw ''; // Error
  G s1() => throw ''; // Ok
  G<dynamic> s2() => throw ''; // Ok
  G<Class> s3() => throw ''; // Ok
  G<Class<dynamic>> s4() => throw ''; // Ok
  G<ConcreteClass> s5() => throw ''; // Ok
  G<Class<ConcreteClass>> s6() => throw ''; // Ok
  G<Object> s7() => throw ''; // Error
  G<int> s8() => throw ''; // Error
}

class Class1 {
  F t1() => throw ''; // Ok
  F<dynamic> t2() => throw ''; // Ok
  F<Class> t3() => throw ''; // Ok
  F<Class<dynamic>> t4() => throw ''; // Ok
  F<ConcreteClass> t5() => throw ''; // Ok
  F<Class<ConcreteClass>> t6() => throw ''; // Ok
  F<Object> t7() => throw ''; // Error
  F<int> t8() => throw ''; // Error
  G s1() => throw ''; // Ok
  G<dynamic> s2() => throw ''; // Ok
  G<Class> s3() => throw ''; // Ok
  G<Class<dynamic>> s4() => throw ''; // Ok
  G<ConcreteClass> s5() => throw ''; // Ok
  G<Class<ConcreteClass>> s6() => throw ''; // Ok
  G<Object> s7() => throw ''; // Error
  G<int> s8() => throw ''; // Error
}

extension Extension1 on int {
  F t1() => throw ''; // Ok
  F<dynamic> t2() => throw ''; // Ok
  F<Class> t3() => throw ''; // Ok
  F<Class<dynamic>> t4() => throw ''; // Ok
  F<ConcreteClass> t5() => throw ''; // Ok
  F<Class<ConcreteClass>> t6() => throw ''; // Ok
  F<Object> t7() => throw ''; // Error
  F<int> t8() => throw ''; // Error
  G s1() => throw ''; // Ok
  G<dynamic> s2() => throw ''; // Ok
  G<Class> s3() => throw ''; // Ok
  G<Class<dynamic>> s4() => throw ''; // Ok
  G<ConcreteClass> s5() => throw ''; // Ok
  G<Class<ConcreteClass>> s6() => throw ''; // Ok
  G<Object> s7() => throw ''; // Error
  G<int> s8() => throw ''; // Error
}

main() {}
