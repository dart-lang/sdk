// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

const Object? nullValue = null;

class Class<T> {
  operator ==(covariant Class<T> other) => true;

  method(o) {}
}

test<T1 extends Function, T2 extends int Function(int)>(
    Object o,
    Object nonNullableObject,
    Object? nullableObject,
    Class<String> nonNullableClass,
    Class<String>? nullableClass,
    dynamic dyn,
    Never never,
    Never? nullableNever,
    Null nullTypedValue,
    Function nonNullableFunction,
    Function? nullableFunction,
    int Function(int) nonNullableFunctionType,
    int Function(int)? nullableFunctionType,
    T1 nonNullableTypeVariable1,
    T1? nullableTypeVariable1,
    T2 nonNullableTypeVariable2,
    T2? nullableTypeVariable2) {
  print('EqualsNull (literal null)');
  null == null;
  null != null;

  nonNullableObject == null;
  nonNullableObject != null;
  null == nonNullableObject;
  null != nonNullableObject;

  nullableObject == null;
  nullableObject != null;
  null == nullableObject;
  null != nullableObject;

  nullableClass == null;
  nullableClass != null;
  null == nullableClass;
  null != nullableClass;

  nonNullableClass == null;
  nonNullableClass != null;
  null == nonNullableClass;
  null != nonNullableClass;

  dyn == null;
  dyn != null;
  null == dyn;
  null != dyn;

  never == null;
  never != null;
  null == never;
  null != never;

  nullableNever == null;
  nullableNever != null;
  null == nullableNever;
  null != nullableNever;

  nullTypedValue == null;
  nullTypedValue != null;
  null == nullTypedValue;
  null != nullTypedValue;

  nonNullableFunction == null;
  nonNullableFunction != null;
  null == nonNullableFunction;
  null != nonNullableFunction;

  nullableFunction == null;
  nullableFunction != null;
  null == nullableFunction;
  null != nullableFunction;

  nonNullableFunctionType == null;
  nonNullableFunctionType != null;
  null == nonNullableFunctionType;
  null != nonNullableFunctionType;

  nullableFunctionType == null;
  nullableFunctionType != null;
  null == nullableFunctionType;
  null != nullableFunctionType;

  nonNullableTypeVariable1 == null;
  nonNullableTypeVariable1 != null;
  null == nonNullableTypeVariable1;
  null != nonNullableTypeVariable1;

  nullableTypeVariable1 == null;
  nullableTypeVariable1 != null;
  null == nullableTypeVariable1;
  null != nullableTypeVariable1;

  nonNullableTypeVariable2 == null;
  nonNullableTypeVariable2 != null;
  null == nonNullableTypeVariable2;
  null != nonNullableTypeVariable2;

  nullableTypeVariable2 == null;
  nullableTypeVariable2 != null;
  null == nullableTypeVariable2;
  null != nullableTypeVariable2;

  nonNullableClass.method() == null;
  nonNullableClass.method() != null;
  null == nonNullableClass.method();
  null != nonNullableClass.method();

  print('EqualsNull (constant null)');
  nullValue == nullValue;
  nullValue != nullValue;

  nonNullableObject == nullValue;
  nonNullableObject != nullValue;
  nullValue == nonNullableObject;
  nullValue != nonNullableObject;

  nullableObject == nullValue;
  nullableObject != nullValue;
  nullValue == nullableObject;
  nullValue != nullableObject;

  nonNullableClass == nullValue;
  nonNullableClass != nullValue;
  nullValue == nonNullableClass;
  nullValue != nonNullableClass;

  nullableClass == nullValue;
  nullableClass != nullValue;
  nullValue == nullableClass;
  nullValue != nullableClass;

  dyn == nullValue;
  dyn != nullValue;
  nullValue == dyn;
  nullValue != dyn;

  never == nullValue;
  never != nullValue;
  nullValue == never;
  nullValue != never;

  nullableNever == nullValue;
  nullableNever != nullValue;
  nullValue == nullableNever;
  nullValue != nullableNever;

  nullTypedValue == nullValue;
  nullTypedValue != nullValue;
  nullValue == nullTypedValue;
  nullValue != nullTypedValue;

  nonNullableFunction == nullValue;
  nonNullableFunction != nullValue;
  nullValue == nonNullableFunction;
  nullValue != nonNullableFunction;

  nullableFunction == nullValue;
  nullableFunction != nullValue;
  nullValue == nullableFunction;
  nullValue != nullableFunction;

  nonNullableFunctionType == nullValue;
  nonNullableFunctionType != nullValue;
  nullValue == nonNullableFunctionType;
  nullValue != nonNullableFunctionType;

  nullableFunctionType == nullValue;
  nullableFunctionType != nullValue;
  nullValue == nullableFunctionType;
  nullValue != nullableFunctionType;

  nonNullableTypeVariable1 == nullValue;
  nonNullableTypeVariable1 != nullValue;
  nullValue == nonNullableTypeVariable1;
  nullValue != nonNullableTypeVariable1;

  nullableTypeVariable1 == nullValue;
  nullableTypeVariable1 != nullValue;
  nullValue == nullableTypeVariable1;
  nullValue != nullableTypeVariable1;

  nonNullableTypeVariable2 == nullValue;
  nonNullableTypeVariable2 != nullValue;
  nullValue == nonNullableTypeVariable2;
  nullValue != nonNullableTypeVariable2;

  nullableTypeVariable2 == nullValue;
  nullableTypeVariable2 != nullValue;
  nullValue == nullableTypeVariable2;
  nullValue != nullableTypeVariable2;

  nonNullableClass.method() == nullValue;
  nonNullableClass.method() != nullValue;
  nullValue == nonNullableClass.method();
  nullValue != nonNullableClass.method();

  print('EqualsCall');

  nonNullableObject == nullTypedValue;
  nonNullableObject != nullTypedValue;
  nullTypedValue == nonNullableObject;
  nullTypedValue != nonNullableObject;
  nonNullableObject == o;
  nonNullableObject != o;
  o == nonNullableObject;
  o != nonNullableObject;

  nullableObject == nullTypedValue;
  nullableObject != nullTypedValue;
  nullTypedValue == nullableObject;
  nullTypedValue != nullableObject;
  nullableObject == o;
  nullableObject != o;
  o == nullableObject;
  o != nullableObject;

  nonNullableClass == nullTypedValue;
  nonNullableClass != nullTypedValue;
  nullTypedValue == nonNullableClass;
  nullTypedValue != nonNullableClass;
  nonNullableClass == o;
  nonNullableClass != o;
  o == nonNullableClass;
  o != nonNullableClass;

  nullableClass == nullTypedValue;
  nullableClass != nullTypedValue;
  nullTypedValue == nullableClass;
  nullTypedValue != nullableClass;
  nullableClass == o;
  nullableClass != o;
  o == nullableClass;
  o != nullableClass;

  dyn == nullTypedValue;
  dyn != nullTypedValue;
  nullTypedValue == dyn;
  nullTypedValue != dyn;
  dyn == o;
  dyn != o;
  o == dyn;
  o != dyn;

  never == nullTypedValue;
  never != nullTypedValue;
  nullTypedValue == never;
  nullTypedValue != never;
  never == o;
  never != o;
  o == never;
  o != never;

  nullableNever == nullTypedValue;
  nullableNever != nullTypedValue;
  nullTypedValue == nullableNever;
  nullTypedValue != nullableNever;
  nullableNever == o;
  nullableNever != o;
  o == nullableNever;
  o != nullableNever;

  nullTypedValue == nullTypedValue;
  nullTypedValue != nullTypedValue;
  nullTypedValue == nullTypedValue;
  nullTypedValue != nullTypedValue;
  nullTypedValue == o;
  nullTypedValue != o;
  o == nullTypedValue;
  o != nullTypedValue;

  nonNullableFunction == nullTypedValue;
  nonNullableFunction != nullTypedValue;
  nullTypedValue == nonNullableFunction;
  nullTypedValue != nonNullableFunction;
  nonNullableFunction == o;
  nonNullableFunction != o;
  o == nonNullableFunction;
  o != nonNullableFunction;

  nullableFunction == nullTypedValue;
  nullableFunction != nullTypedValue;
  nullTypedValue == nullableFunction;
  nullTypedValue != nullableFunction;
  nullableFunction == o;
  nullableFunction != o;
  o == nullableFunction;
  o != nullableFunction;

  nonNullableFunctionType == nullTypedValue;
  nonNullableFunctionType != nullTypedValue;
  nullTypedValue == nonNullableFunctionType;
  nullTypedValue != nonNullableFunctionType;
  nonNullableFunctionType == o;
  nonNullableFunctionType != o;
  o == nonNullableFunctionType;
  o != nonNullableFunctionType;

  nullableFunctionType == nullTypedValue;
  nullableFunctionType != nullTypedValue;
  nullTypedValue == nullableFunctionType;
  nullTypedValue != nullableFunctionType;
  nullableFunctionType == o;
  nullableFunctionType != o;
  o == nullableFunctionType;
  o != nullableFunctionType;

  nonNullableTypeVariable1 == nullTypedValue;
  nonNullableTypeVariable1 != nullTypedValue;
  nullTypedValue == nonNullableTypeVariable1;
  nullTypedValue != nonNullableTypeVariable1;
  nonNullableTypeVariable1 == o;
  nonNullableTypeVariable1 != o;
  o == nonNullableTypeVariable1;
  o != nonNullableTypeVariable1;

  nullableTypeVariable1 == nullTypedValue;
  nullableTypeVariable1 != nullTypedValue;
  nullTypedValue == nullableTypeVariable1;
  nullTypedValue != nullableTypeVariable1;
  nullableTypeVariable1 == o;
  nullableTypeVariable1 != o;
  o == nullableTypeVariable1;
  o != nullableTypeVariable1;

  nonNullableTypeVariable2 == nullTypedValue;
  nonNullableTypeVariable2 != nullTypedValue;
  nullTypedValue == nonNullableTypeVariable2;
  nullTypedValue != nonNullableTypeVariable2;
  nonNullableTypeVariable2 == o;
  nonNullableTypeVariable2 != o;
  o == nonNullableTypeVariable2;
  o != nonNullableTypeVariable2;

  nullableTypeVariable2 == nullTypedValue;
  nullableTypeVariable2 != nullTypedValue;
  nullTypedValue == nullableTypeVariable2;
  nullTypedValue != nullableTypeVariable2;
  nullableTypeVariable2 == o;
  nullableTypeVariable2 != o;
  o == nullableTypeVariable2;
  o != nullableTypeVariable2;

  nonNullableClass.method() == nullTypedValue;
  nonNullableClass.method() != nullTypedValue;
  nullTypedValue == nonNullableClass.method();
  nullTypedValue != nonNullableClass.method();
  nonNullableClass.method() == o;
  nonNullableClass.method() != o;
  o == nonNullableClass.method();
  o != nonNullableClass.method();
}

nullEqualsIndexGet(Map<int, String> map) {
  null == map[0];
  map[0] == null;
}

main() {}
