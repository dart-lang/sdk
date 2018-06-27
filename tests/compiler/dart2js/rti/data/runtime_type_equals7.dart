// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*strong.class: Class1a:explicit=[Class1a]*/
class Class1a {
  /*kernel.element: Class1a.:needsSignature*/
  Class1a();
}

/*kernel.class: Class1b:needsArgs*/
/*strong.class: Class1b:needsArgs*/
/*omit.class: Class1b:needsArgs*/
class Class1b<T> extends Class1a {
  /*kernel.element: Class1b.:needsSignature*/
  Class1b();
}

/*kernel.class: Class1c:needsArgs*/
/*strong.class: Class1c:needsArgs*/
/*omit.class: Class1c:needsArgs*/
class Class1c<T> extends Class1a {
  /*kernel.element: Class1c.:needsSignature*/
  Class1c();
}

/*kernel.class: Class2:needsArgs*/
/*strong.class: Class2:*/
/*omit.class: Class2:*/
class Class2<T> {
  /*kernel.element: Class2.:needsSignature*/
  Class2();
}

/*kernel.class: Class3:needsArgs*/
/*strong.class: Class3:explicit=[Class3]*/
/*omit.class: Class3:*/
class Class3<T> {
  final Class1a field;

  /*kernel.element: Class3.:needsSignature*/
  Class3(this.field);
}

/*kernel.element: test:needsSignature*/
/*strong.element: test:*/
/*omit.element: test:*/
test(Class3 c, Type type) {
  return c.field.runtimeType == type;
}

/*kernel.element: main:needsSignature*/
/*strong.element: main:*/
/*omit.element: main:*/
main() {
  Expect.isTrue(test(new Class3<int>(new Class1a()), Class1a));
  Expect.isFalse(test(new Class3<int>(new Class1b<int>()), Class1a));
  Expect.isFalse(test(new Class3<int>(new Class1c<int>()), Class1a));
  new Class2<int>();
}
