// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib1.dart';
import 'main_lib2.dart';
import 'main_lib4.dart';
import 'main_lib5.dart';

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
  // Dynamic uses are not allowed except for dynamically-callable members.
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

  // Not allowed - redirecting factories are not callable
  // (although their targets are callable).
  print(C8.fact1());
  print(C8.fact2());
  print(const C8.fact4());

  // Allowed - redirecting factories are callable.
  print(C9.fact1());
  print(C9.fact2());
  print(const C9.fact4());

  // Not allowed.
  print(ExtType1);
  print(ExtType1(42));
  print(42.isPositive);

  // Allowed - all three extension types are exposed as callable.
  print(ExtType2);
  print(ExtType2(42));
  print(ExtType2(42).isPositive);
  print(ExtType3);
  print(ExtType3(42));
  print(ExtType3(42).isPositive);
  print(ExtType4);
  print(ExtType4(42));
  print(ExtType4(42).isPositive);

  // Allowed - Ext2, Ext3, Ext4 are specified as callable.
  print(1.isNegative2);
  print(1.isNegative3);
  print(1.isNegative4);
  print(Ext4(1).isNegative4);

  // Not allowed - Ext1 is not exposed.
  print(Ext1(1).isPositive);

  // Allowed - Ext5.isNegative5 is exposed directly.
  print(1.isNegative5);

  // Not allowed - Ext5 as an extension is not exposed.
  print(Ext5(1).isNegative5);

  // Not allowed - ExtType5 is not exposed as a whole.
  print(ExtType5);

  // ExtType5.plus1 is callable and can be used from a dynamic module.
  print(ExtType5.plus1(3));

  // Not allowed - member not exposed.
  print(ExtType5.plus1(3).isPositive);

  // Allowed - re-exported through main_lib2.dart
  print(Lib3Class());
  lib3Method();
  lib3Field = 42;
  print(Lib3ExtType);
  print(Lib3ExtType(42));
  print(42.lib3IsPositive);
}

void testCanBeUsedAsType(Object? o) {
  // Allowed, exposed as types individually or in groups
  o is C10;
  o as C10;
  List<C10> list1;
  print(C10);
  print(<C10>[]);

  o is ExtType10;
  o as ExtType10;
  List<ExtType10> list2;
  print(ExtType10);
  print(<ExtType10>[]);

  o is C11;
  o as C11;
  List<C11> list3;
  print(C11);
  print(<C11>[]);

  o is ExtType11;
  o as ExtType11;
  List<ExtType11> list4;
  print(ExtType11);
  print(<ExtType11>[]);

  o is C12;
  o as C12;
  List<C12> list5;
  print(C12);
  print(<C12>[]);

  o is ExtType12;
  o as ExtType12;
  List<ExtType12> list6;
  print(ExtType12);
  print(<ExtType12>[]);

  // Allowed, exposed as types from the library level
  o is Lib4Class;
  o as Lib4Class;
  List<Lib4Class> list7;
  print(Lib4Class);
  print(<Lib4Class>[]);

  o is Lib4ExtType;
  o as Lib4ExtType;
  List<Lib4ExtType> list8;
  print(Lib4ExtType);
  print(<Lib4ExtType>[]);

  // Not allowed - type is not automatically callable
  print(C10());
  print(ExtType10(20));

  // Not allowed - type is not exposed as type or callable.
  o is C13;
  o as C13;
  List<C13> list9;
  print(C13);
  print(<C13>[]);
  print(<ExtType13>[]);

  // Not allowed - inferred LUB type (C14) is not exposed.
  final inferredList = [C15(), C16()];
}

void testDynamicallyCallable() {
  // Allowed, C17 exposed as a whole.
  x.dcMethod1();
  x.dcMethod2('a', 2);
  x.dcGetter1;
  x.dcSetter1 = 42;
  // Allowed, C18 members exposed individually.
  x.dcMethod3();
  x.dcMethod4('a', 2);
  x.dcGetter2;
  x.dcSetter2 = 42;
  x.dcField1;
  x.dcField2;
  x.dcField2 = 42;
  // Not allowed - getter was not exposed because field is final.
  x.dcField1 = 42;
  // Allowed - exposed via library
  x.dcField5;
  x.dcField5 = 42;
  x.dcMethod5();

  C26WithM3().method6();

  // Allowed - selectors in the allowlist
  x.allowedMethod();
  x.allowedMethod; // tearoff implicitly allowed too.
  x.allowedGetter;
  x.allowedSetter = 2;

  // Not allowed - selectors not in the allowlist or used in non intended
  // ways (getter used for a call, setter used for a getter).
  x.notAllowedGetter;
  x.notAllowedMethod();
  x.allowedGetter(); // not meant to be called
  x.allowedSetter; // not meant to be used as getter
}

void main() {}

// Child class that attempts to override noSuchMethod on a dynamically-callable
// class.
class Lib5WithNSM extends Lib5C1 {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Mixin transformation that copies a dynamic call to a private member.
class C26WithM3 extends C26 with M3 {}
