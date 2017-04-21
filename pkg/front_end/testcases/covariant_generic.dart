// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
typedef void Callback<T>(T x);

class Foo<T> {
  final T finalField;
  final Callback<T> callbackField;

  T mutableField;
  Callback<T> mutableCallbackField;

  Foo(this.finalField, this.callbackField);

  void method(T x) {}

  set setter(T x) {}

  void withCallback(Callback<T> callback) {
    callback(finalField);
  }
}

main() {
  Foo<int> fooInt = new Foo<int>(1, (int x) {});

  fooInt.method(3);
  fooInt.setter = 3;
  fooInt.withCallback((int x) {});
  fooInt.withCallback((num x) {});
  fooInt.mutableField = 3;
  fooInt.mutableCallbackField = (int x) {};

  Foo<num> fooNum = fooInt;
  fooNum.method(3);
  fooNum.method(2.5);
  fooNum.setter = 3;
  fooNum.setter = 2.5;
  fooNum.withCallback((num x) {});
  fooNum.mutableField = 3;
  fooNum.mutableField = 2.5;
  fooNum.mutableCallbackField(3);
  fooNum.mutableCallbackField(2.5);
  fooNum.mutableCallbackField = (num x) {};
}
