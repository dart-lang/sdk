// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Based on tests/language_2/type_variable_function_type_test.dart

import 'package:expect/expect.dart';

typedef T Func<T>();

/*class: Foo:checks=[],instance*/
class Foo<S> {
  m(x) => x is Func<S>;
}

/*class: Bar:checks=[],instance*/
class Bar<T> {
  f() {
    /*checks=[$signature],instance*/
    T local() => null;
    return local;
  }
}

void main() {
  dynamic x = new Foo<List<String>>();
  if (new DateTime.now().millisecondsSinceEpoch == 42) x = new Foo<int>();
  Expect.isFalse(x.m(new Bar<String>().f()));
  Expect.isTrue(x.m(new Bar<List<String>>().f()));
}
