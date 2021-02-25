// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class Class1 {
  int field;

  Class1(this.field);

  int method(double o) => 0;

  static int staticField = 42;

  static int staticMethod(double o) => 0;
}

int topLevelField = 42;

int topLevelMethod(double o) => 0;

class Class2<T> {
  T field;

  Class2(this.field);

  int call() => 42;
}

const String string = 'foo';
const int stringLength = string.length;

const dynamic dynamicString = 'foo';
const int dynamicStringLength = dynamicString.length;

test<T1 extends Function, T2 extends int Function()>(
    Class1 nonNullableClass1,
    Class1? nullableClass1,
    dynamic dyn,
    Never never,
    Class2<String> nonNullableClass2,
    Class2<String>? nullableClass2,
    Function nonNullableFunction,
    Function? nullableFunction,
    int Function() nonNullableFunctionType,
    int Function()? nullableFunctionType,
    T1 nonNullableTypeVariable1,
    T1? nullableTypeVariable1,
    T2 nonNullableTypeVariable2,
    T2? nullableTypeVariable2) {
  print('InstanceGet');
  nonNullableClass1.field;
  nullableClass1?.field;
  nonNullableClass2.field;
  nullableClass2?.field;
  const dynamic instance_get = nullableClass1.field;
  print(instance_get);

  print('InstanceTearOff');
  nonNullableClass1.method;
  nullableClass1?.method;
  nonNullableClass2.call;
  nullableClass2?.call;
  const dynamic instance_tearOff = nonNullableClass1.method;
  print(instance_tearOff);

  Function f1 = nonNullableClass2;
  Function? f2 = nullableClass2;

  print('StaticGet');
  Class1.staticField;
  topLevelField;

  print('StaticTearOff');
  Class1.staticMethod;
  topLevelMethod;
  const dynamic static_tearOff = topLevelMethod;
  print(static_tearOff);

  print('DynamicGet');
  dyn.field;
  dyn?.field;
  const dynamic dyn_get = dyn.field;
  print(dyn_get);

  print('InstanceGet (Object)');
  dyn.hashCode;
  nullableClass1.hashCode;

  print('InstanceGetTearOff (Object)');
  dyn.toString;
  nullableClass1.toString;

  print('DynamicGet (Never)');
  never.field;
  never.hashCode;

  print('FunctionTearOff');
  nonNullableFunction.call;
  nullableFunction?.call;
  nonNullableFunctionType.call;
  nullableFunctionType?.call;
  nonNullableTypeVariable1.call;
  nullableTypeVariable1?.call;
  nonNullableTypeVariable2.call;
  nullableTypeVariable2?.call;
  const dynamic function_tearOff = nonNullableFunction.call;
  print(function_tearOff);

  print('DynamicGet (Invalid)');
  nonNullableClass1.method().field;

  print('DynamicGet (Unresolved)');
  nonNullableClass1.unresolved;
}

main() {}
