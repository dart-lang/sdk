// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*spec:nnbd-off.member: method1a:*/
/*prod:nnbd-off.member: method1a:*/
method1a() => null;

/*spec:nnbd-off.member: method1b:*/
/*prod:nnbd-off.member: method1b:*/
method1b() => null;

/*spec:nnbd-off.member: method2:*/
/*prod:nnbd-off.member: method2:*/
method2(t, s) => t;

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
