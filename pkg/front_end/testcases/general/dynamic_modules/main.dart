// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib1.dart';
import 'main_lib2.dart';

dynamic x;

// Class C3 is not extendable - error.
class D3 extends C3 {}

// Class C4 is extendable - valid.
class D4 extends C4 {
  // Cannot override.
  void method1() {}
  // Can override.
  void method2() {}
  // Cannot override.
  int? get field1 => null;
  set field1(int? value) {}
  // Can override.
  int? get field2 => null;
  set field2(int? value) {}
}

// Class C3 is not extendable - error.
class E3 implements C3 {}

// Class C4 is extendable - valid.
class E4 implements C4 {
  // Cannot override.
  void method1() {}
  // Can override.
  void method2() {}
  // Cannot override.
  int? field1;
  // Can override.
  int? field2;
}

// Mixin M1 is not extendable - error.
class F1 with M1 {}

// Mixin M1 is extendable - valid.
class F2 with M2 {}

// Cannot override by inheriting member from base class.
class Impl1 extends Base implements Interface {}

// Cannot override by providing implementation in a mixin-in.
class Impl2 with Mixin implements Interface {}

// Super parameters implicitly use default value.
// In this case default value is not callable and cannot be used.
class C6Ext extends C6 {
  C6Ext({super.param});
}

// Super parameters implicitly use default value.
// In this case default value is callable and can be used.
class C7Ext extends C7 {
  C7Ext({super.param});
}

void test() {
  // Dynamic uses are not allowed.
  x.foo().bar.baz = 42;
  if (x case < 3) {
    print('<3');
  }
  switch (x) {
    case dynamic(foo: 42):
      print('dyn');
    case _:
  }

  // Class C1 is not callable - cannot be used in the dynamic module.
  C1 o1 = C1();
  o1.method1();
  print(o1.method1);
  print(o1.getter1);
  o1.setter1 = 42;
  C1.method2();
  print(C1.method2);
  print(C1.getter2);
  C1.setter2 = 42;
  print(C1.new);
  print(o1.field1);
  print(C1.field2);

  // Class C2 is callable and can be used in the dynamic module.
  C2 o2 = C2();
  o2.method1();
  print(o2.method1);
  print(o2.getter1);
  o2.setter1 = 42;
  C2.method2();
  print(C2.method2);
  print(C2.getter2);
  C2.setter2 = 42;
  print(C2.new);
  print(o2.field1);
  print(C2.field2);

  // Not allowed.
  method1();
  print(method1);

  // Allowed.
  method2();
  print(method2);

  // Not allowed.
  print(field1);
  field1 = 42;

  // Allowed.
  print(field2);
  field2 = 42;

  // Not allowed - target of redirecting factory is not callable.
  print(C8());

  // Allowed - target of redirecting factory is callable.
  print(C9());

  // Allowed - re-exported through main_lib2.dart
  print(Lib3Class());
  lib3Method();
  lib3Field = 42;
}

void main() {}
