// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class Class1 {
  double method(int o) => 0.5;
}

class Class2<T> {
  T field;

  Class2(this.field, this.nonNullableFunctionField,
      this.nonNullableFunctionTypedField);

  T call() => field;

  T method(int o) => field;

  Function nonNullableFunctionField;

  Function get nonNullableFunctionGetter => nonNullableFunctionTypedField;

  Function? nullableFunctionField;

  Function? get nullableFunctionGetter => nonNullableFunctionTypedField;

  void Function() nonNullableFunctionTypedField;

  void Function() get nonNullableFunctionTypedGetter =>
      nonNullableFunctionTypedField;

  void Function()? nullableFunctionTypedField;

  void Function()? get nullableFunctionTypedGetter =>
      nonNullableFunctionTypedField;
}

const int i = 4;
const int j = 24;
const int k = i * j;

test<T1 extends Function, T2 extends int Function(int), T3>(
    Class1 nonNullableClass1,
    Class1? nullableClass1,
    dynamic dyn,
    Never never,
    Class2<String> nonNullableClass2,
    Class2<String>? nullableClass2,
    Function nonNullableFunction,
    Function? nullableFunction,
    int Function(int) nonNullableFunctionType,
    int Function(int)? nullableFunctionType,
    T Function<T>(T) genericFunctionType,
    T1 nonNullableTypeVariable1,
    T1? nullableTypeVariable1,
    T2 nonNullableTypeVariable2,
    T2? nullableTypeVariable2,
    T3 undeterminedTypeVariable) {
  print('InstanceInvocation');
  nonNullableClass1.method(0);
  nullableClass1?.method(0);

  print('InstanceGet calls');
  nonNullableClass2.nonNullableFunctionField();
  nonNullableClass2.nonNullableFunctionGetter();
  nonNullableClass2.nonNullableFunctionTypedField();
  nonNullableClass2.nonNullableFunctionTypedGetter();
  nonNullableClass2.nullableFunctionField();
  nonNullableClass2.nullableFunctionGetter();
  nonNullableClass2.nullableFunctionTypedField();
  nonNullableClass2.nullableFunctionTypedGetter();
  nonNullableClass2.nonNullableFunctionField(0);
  nonNullableClass2.nonNullableFunctionGetter(0);
  nonNullableClass2.nonNullableFunctionTypedField(0);
  nonNullableClass2.nonNullableFunctionTypedGetter(0);

  print('InstanceInvocation (Nullable)');
  nullableClass1.method(0);

  print('DynamicInvocation');
  dyn.method(0);
  dyn?.method(0);
  dyn.toString(0);
  const int call_dyn = dyn.toString(0);
  print(call_dyn);

  print('InstanceInvocation (Object)');
  dyn.toString();
  nullableClass1.toString();
  nullableClass2.toString();
  nullableFunction.toString();
  nullableFunctionType.toString();
  nullableTypeVariable1.toString();
  nullableTypeVariable2.toString();
  undeterminedTypeVariable.toString();

  print('DynamicInvocation (Never)');
  never.method(0);
  never.toString();

  print('DynamicInvocation (Unresolved)');
  nonNullableClass1.unresolved();

  print('DynamicInvocation (Inapplicable)');
  nonNullableClass1.method();
  nonNullableFunctionType();

  print('InstanceInvocation (generic)');
  nonNullableClass2.method(0);
  nullableClass2?.method(0);
  nonNullableClass2();
  nonNullableClass2.call();

  print('FunctionInvocation');
  nonNullableFunction(0);
  nonNullableFunction.call(0);
  nullableFunction?.call(0);
  nonNullableFunctionType(0);
  nonNullableFunctionType.call(0);
  nullableFunctionType?.call(0);
  genericFunctionType(0);
  genericFunctionType<num>(0);
  num i = genericFunctionType(0);
  nonNullableTypeVariable1(0);
  nonNullableTypeVariable1.call(0);
  nullableTypeVariable1?.call(0);
  nonNullableTypeVariable2(0);
  nonNullableTypeVariable2.call(0);
  nullableTypeVariable2?.call(0);

  print('FunctionInvocation (Nullable)');
  nullableFunction(0);
  nullableFunction.call(0);
  nullableFunctionType(0);
  nullableFunctionType.call(0);

  print('DynamicInvocation (Invalid)');
  nonNullableClass1.method().method(0);

  print('LocalFunctionInvocation');
  int localFunction() => 42;
  T genericLocalFunction<T>(T t) => t;
  localFunction();
  genericLocalFunction(0);
  genericLocalFunction<num>(0);

  const int call_localFunction = localFunction();
  print(call_localFunction);

  int Function() f = () => 42;

  const int call_f = f();
  print(call_f);
  const int? nullable = 0;
  const bool equals_null = nullable == null;
  print(equals_null);
  const bool equals = i == j;
  print(equals);
}

main() {}
