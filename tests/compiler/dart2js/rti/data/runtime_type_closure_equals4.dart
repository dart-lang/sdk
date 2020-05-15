// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*spec:nnbd-off.class: Class1:*/
/*prod:nnbd-off.class: Class1:*/
class Class1<T> {
  /*spec:nnbd-off.member: Class1.:*/
  /*prod:nnbd-off.member: Class1.:*/
  Class1();

  // TODO(johnniwinther): Currently only methods that use class type variables
  // in their signature are marked as 'needs signature'. Change this to mark
  // all methods that need to support access to their function type at runtime.

  /*spec:nnbd-off.member: Class1.method1a:*/
  /*prod:nnbd-off.member: Class1.method1a:*/
  method1a() => null;

  /*spec:nnbd-off.member: Class1.method1b:*/
  /*prod:nnbd-off.member: Class1.method1b:*/
  method1b() => null;

  /*spec:nnbd-off.member: Class1.method2:*/
  /*prod:nnbd-off.member: Class1.method2:*/
  method2(t, s) => t;
}

/*spec:nnbd-off.class: Class2:*/
/*prod:nnbd-off.class: Class2:*/
class Class2<T> {
  /*spec:nnbd-off.member: Class2.:*/
  /*prod:nnbd-off.member: Class2.:*/
  Class2();
}

/*spec:nnbd-off.member: main:*/
/*prod:nnbd-off.member: main:*/
main() {
  var c = new Class1<int>();

  Expect.isTrue(c.method1a.runtimeType == c.method1b.runtimeType);
  Expect.isFalse(c.method1a.runtimeType == c.method2.runtimeType);
  new Class2<int>();
}
