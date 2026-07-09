// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for https://github.com/dart-lang/sdk/issues/60643.
///
/// Getter invocations where the getter return type is a generic type argument
/// instantiated as `dynamic` or `Function` should get runtime checks to
/// ensure they are called correctly.

import "package:expect/expect.dart";

class GetterContainer<T> {
  T? _value;
  set value(T v) => _value = v;
  T get value => _value!;
}

class FieldContainer<T> {
  T? value;
}

void main() {
  var getterContainer = GetterContainer();
  getterContainer.value = (int i, {required String s}) {
    return 'hello world';
  };
  Expect.throws<NoSuchMethodError>(() => getterContainer.value());
  Expect.throws<NoSuchMethodError>(() => getterContainer.value(10));
  Expect.equals('hello world', getterContainer.value(10, s: 'hello'));

  var fieldContainer = FieldContainer();
  fieldContainer.value = (int i, {required String s}) {
    return 'hello world';
  };
  Expect.throws<NoSuchMethodError>(() => fieldContainer.value());
  Expect.throws<NoSuchMethodError>(() => fieldContainer.value(10));
  Expect.equals('hello world', fieldContainer.value(10, s: 'hello'));

  var outer = FieldContainer<dynamic>();
  var inner = GetterContainer<Function>();
  inner.value = (int i, {required String s}) {
    return 'hello world';
  };
  outer.value = inner;
  Expect.throws<NoSuchMethodError>(() => outer.value.value());
  Expect.throws<NoSuchMethodError>(() => outer.value.value(10));
  Expect.equals('hello world', outer.value.value(10, s: 'hello'));
}
