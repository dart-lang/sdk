// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Foo<T extends num> {}

class Bar<T extends num> {}

class Baz<T extends num> {}

@pragma('dart2js:disableFinal')
main() {
  test(new Foo(), Foo, expectTypeArguments: false);
  test(new Bar() as Bar<num>, Bar, expectTypeArguments: false);
  Baz<num> b = new Baz();
  dynamic c = b;
  test(c as Baz<num>, Baz, expectTypeArguments: true);
}

void test(dynamic object, Type type, {required bool expectTypeArguments}) {
  bool caught = false;
  try {
    print(type);
    object as List<String>;
  } catch (e) {
    String expected = '$type';
    if (!expectTypeArguments!) {
      expected = expected.substring(0, expected.indexOf('<'));
    }
    expected = '$expected';
    Expect.isTrue(e.toString().contains(expected),
        'Expected "$expected" in the message: $e');
    caught = true;
    print(e);
  }
  Expect.isTrue(caught);
}
