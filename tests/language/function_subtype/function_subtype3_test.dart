// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class FunctionLike<T> {
  T call(T arg) {
    return arg;
  }
}

class Foo<T> {
  testString() => new FunctionLike<String>() is T;
  testInt() => new FunctionLike<int>() is T;
}

class Bar<T> {
  testString() {
    Function f = new FunctionLike<String>();
    return f is T;
  }

  testInt() {
    Function f = new FunctionLike<int>();
    return f is T;
  }
}

typedef String ReturnString(Object arg);
typedef int ReturnInt(Object arg);

main() {
  {
    var stringFoo = new Foo<ReturnString>();
    var intFoo = new Foo<ReturnInt>();
    Expect.isFalse(stringFoo.testString());
    Expect.isFalse(stringFoo.testInt());
    Expect.isFalse(intFoo.testString());
    Expect.isFalse(intFoo.testInt());
  }

  {
    var stringBar = new Bar<ReturnString>();
    var intBar = new Bar<ReturnInt>();
    Expect.isTrue(stringBar.testString());
    Expect.isFalse(stringBar.testInt());
    Expect.isFalse(intBar.testString());
    Expect.isTrue(intBar.testInt());
  }
}
