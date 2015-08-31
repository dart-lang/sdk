// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class FunctionLike<T> {
  call(T arg) {
    return arg;
  }
}

class Foo<T> {
  testString() => new FunctionLike<String>() is T;
  testInt() => new FunctionLike<int>() is T;
}

typedef TakeString(String arg);
typedef TakeInt(int arg);

main() {
  Foo<TakeString> stringFoo = new Foo<TakeString>();
  Foo<TakeInt> intFoo = new Foo<TakeInt>();

  Expect.isTrue(stringFoo.testString());
  Expect.isFalse(stringFoo.testInt());

  Expect.isFalse(intFoo.testString());
  Expect.isTrue(intFoo.testInt());
}
