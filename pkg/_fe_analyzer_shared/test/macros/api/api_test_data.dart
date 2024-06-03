// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'api_test_macro.dart';

main() {}

var field;
get getter => null;
set setter(_) => null;

@ClassMacro()
class Class1 {
  var field1;

  Class1();
}

@ClassMacro()
abstract class Class2 extends Object {}

@ClassMacro()
class Class3 extends Class2 implements Interface1 {
  var field1;
  var field2;

  Class3.new();
  Class3.named();
  factory Class3.fact() => Class3.named();
  factory Class3.redirect() = Class3.named;

  void method1() {}
  void method2() {}

  get getter1 => null;
  set setter1(_) {}

  get property1 => null;
  set property1(_) {}

  static var staticField1;
  static void staticMethod1() {}
}

@ClassMacro()
class Class4 extends Class1 with Mixin1 {}

@ClassMacro()
abstract class Class5 extends Class2
    with Mixin1, Mixin2
    implements Interface1, Interface2 {}

@MixinMacro()
mixin Mixin1 {}

@MixinMacro()
mixin Mixin2 {
  var instanceField;
  static var staticField;
  get instanceGetter => 42;
  set instanceSetter(int value) {}
  static get staticGetter => 42;
  static set staticSetter(int value) {}
  instanceMethod() {}
  abstractMethod();
  static staticMethod() {}
}

@ClassMacro()
abstract class Interface1 {}

@ClassMacro()
abstract class Interface2 {}

@FunctionMacro()
void topLevelFunction1(Class1 a, {Class1? b, required Class2? c}) {}

@FunctionMacro()
external Class2 topLevelFunction2(Class1 a, [Class2? b]);

@ExtensionTypeMacro()
extension type ExtensionType1(int i) {
  ExtensionType1.constructor(this.i);
  factory ExtensionType1.fact(int i) => ExtensionType1(i);
  factory ExtensionType1.redirect(int i) = ExtensionType1.constructor;
  static var staticField;
  get instanceGetter => 42;
  set instanceSetter(int value) {}
  static get staticGetter => 42;
  static set staticSetter(int value) {}
  instanceMethod() {}
  static staticMethod() {}
}
