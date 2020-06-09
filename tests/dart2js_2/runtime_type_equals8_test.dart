// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--strong

import 'package:expect/expect.dart';

class Class1a {
  Class1a();
}

class Class1b<T> extends Class1a {
  Class1b();
}

class Class1c<T> extends Class1a {
  Class1c();
}

class Class2<T> {
  Class2();
}

class Class3<T> {
  final Class1a field;

  Class3(this.field);
}

test(Class3 c, Type type) {
  return c.field.runtimeType == type;
}

main() {
  Expect.isTrue(test(new Class3<int>(new Class1a()), Class1a));
  Expect.isFalse(test(new Class3<int>(new Class1b<int>()), Class1a));
  Expect.isFalse(test(new Class3<int>(new Class1c<int>()), Class1a));
  new Class2<int>();
}
