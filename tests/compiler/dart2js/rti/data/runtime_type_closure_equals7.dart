// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*member: method1a:*/
T method1a<T>() => null;

/*member: method1b:*/
T method1b<T>() => null;

/*spec:nnbd-off.member: method2:direct,explicit=[method2.T],needsArgs*/
/*prod:nnbd-off.member: method2:*/
T method2<T>(T t, String s) => t;

/*spec:nnbd-off.class: Class:*/
/*prod:nnbd-off.class: Class:*/
class Class<T> {
  /*spec:nnbd-off.member: Class.:*/
  /*prod:nnbd-off.member: Class.:*/
  Class();
}

/*spec:nnbd-off.member: main:*/
/*prod:nnbd-off.member: main:*/
main() {
  Expect.isTrue(method1a.runtimeType == method1b.runtimeType);
  Expect.isFalse(method1a.runtimeType == method2.runtimeType);
  new Class<int>();
}
