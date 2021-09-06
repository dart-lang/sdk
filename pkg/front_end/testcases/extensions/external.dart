// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension Extension<T extends num> on List<T> {
  external T field;
  external static int staticField;
  external final T finalField;
  external static final int staticFinalField;
  external T method();
  external static int staticMethod();
  external T get getter;
  external static int get staticGetter;
  external void set setter(T value);
  external static void set staticSetter(int value);
  external T get property;
  external void set property(T value);
  external static int get staticProperty;
  external static void set staticProperty(int value);
  external final T fieldSetter;
  external void set fieldSetter(T value);
  external static final int staticFieldSetter;
  external static void set staticFieldSetter(int value);
}

test() {
  List<int> list = [];
  int value = list.field;
  list.field = value;
  value = list.finalField;
  value = list.method();
  value = list.getter;
  list.setter = value;
  value = list.property;
  list.property = value;
  value = list.fieldSetter;
  list.fieldSetter = value;

  List<int> iterable = list;
  num n = Extension<num>(iterable).field;
  Extension<num>(iterable).field = n;
  n = Extension<num>(iterable).finalField;
  n = Extension<num>(iterable).method();
  n = Extension<num>(iterable).getter;
  Extension<num>(iterable).setter = n;
  n = Extension<num>(iterable).property;
  Extension<num>(iterable).property = n;
  n = Extension<num>(iterable).fieldSetter;
  Extension<num>(iterable).fieldSetter = n;

  value = Extension.staticField;
  Extension.staticField = value;
  value = Extension.staticFinalField;
  value = Extension.staticMethod();
  value = Extension.staticGetter;
  Extension.staticSetter = value;
  value = Extension.staticProperty;
  Extension.staticProperty = value;
  value = Extension.staticFieldSetter;
  Extension.staticFieldSetter = value;
}

main() {}
