// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec:nnbd-off.class: Class:*/
/*prod:nnbd-off.class: Class:*/
class Class<T> {
  /*spec:nnbd-off.member: Class.:*/
  /*prod:nnbd-off.member: Class.:*/
  Class();
}

/*spec:nnbd-off.member: method1:*/
/*prod:nnbd-off.member: method1:*/
method1() {}

/*spec:nnbd-off.member: method2:*/
/*prod:nnbd-off.member: method2:*/
method2(int i, String s) => i;

/*spec:nnbd-off.member: main:*/
/*prod:nnbd-off.member: main:*/
main() {
  print('${method1.runtimeType}');
  method2(0, '');
  new Class();
}
