// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*strong.class: Class1a:explicit=[Class1a]*/
class Class1a {
  Class1a();
}

/*strong.class: Class1b:needsArgs*/
/*omit.class: Class1b:needsArgs*/
class Class1b<T> extends Class1a {
  Class1b();
}

/*strong.class: Class1c:needsArgs*/
/*omit.class: Class1c:needsArgs*/
class Class1c<T> extends Class1a {
  Class1c();
}

/*strong.class: Class2:*/
/*omit.class: Class2:*/
class Class2<T> {
  Class2();
}

/*strong.class: Class3:explicit=[Class3]*/
/*omit.class: Class3:*/
class Class3<T> {
  final Class1a field;

  Class3(this.field);
}

/*strong.member: test:*/
/*omit.member: test:*/
test(Class3 c, Type type) {
  return c.field.runtimeType == type;
}

/*strong.member: main:*/
/*omit.member: main:*/
main() {
  Expect.isTrue(test(new Class3<int>(new Class1a()), Class1a));
  Expect.isFalse(test(new Class3<int>(new Class1b<int>()), Class1a));
  Expect.isFalse(test(new Class3<int>(new Class1c<int>()), Class1a));
  new Class2<int>();
}
