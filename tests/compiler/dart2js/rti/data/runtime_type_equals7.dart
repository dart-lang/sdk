// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*spec:nnbd-off.class: Class1a:explicit=[Class1a]*/
class Class1a {
  Class1a();
}

/*spec:nnbd-off.class: Class1b:needsArgs*/
/*prod:nnbd-off.class: Class1b:needsArgs*/
class Class1b<T> extends Class1a {
  Class1b();
}

/*spec:nnbd-off.class: Class1c:needsArgs*/
/*prod:nnbd-off.class: Class1c:needsArgs*/
class Class1c<T> extends Class1a {
  Class1c();
}

/*spec:nnbd-off.class: Class2:*/
/*prod:nnbd-off.class: Class2:*/
class Class2<T> {
  Class2();
}

/*spec:nnbd-off.class: Class3:explicit=[Class3]*/
/*prod:nnbd-off.class: Class3:*/
class Class3<T> {
  final Class1a field;

  Class3(this.field);
}

/*spec:nnbd-off.member: test:*/
/*prod:nnbd-off.member: test:*/
test(Class3 c, Type type) {
  return c.field.runtimeType == type;
}

/*spec:nnbd-off.member: main:*/
/*prod:nnbd-off.member: main:*/
main() {
  Expect.isTrue(test(new Class3<int>(new Class1a()), Class1a));
  Expect.isFalse(test(new Class3<int>(new Class1b<int>()), Class1a));
  Expect.isFalse(test(new Class3<int>(new Class1c<int>()), Class1a));
  new Class2<int>();
}
