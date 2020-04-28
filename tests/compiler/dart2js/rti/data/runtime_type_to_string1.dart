// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec:nnbd-off.class: Class1:*/
/*prod:nnbd-off.class: Class1:*/
class Class1 {
  /*spec:nnbd-off.member: Class1.:*/
  /*prod:nnbd-off.member: Class1.:*/
  Class1();
}

/*spec:nnbd-off.class: Class2:*/
/*prod:nnbd-off.class: Class2:*/
class Class2<T> {
  /*spec:nnbd-off.member: Class2.:*/
  /*prod:nnbd-off.member: Class2.:*/
  Class2();
}

/*spec:nnbd-off.class: Class3:needsArgs*/
/*prod:nnbd-off.class: Class3:*/
class Class3<T> implements Class1 {
  /*spec:nnbd-off.member: Class3.:*/
  /*prod:nnbd-off.member: Class3.:*/
  Class3();
}

/*spec:nnbd-off.member: main:*/
/*prod:nnbd-off.member: main:*/
main() {
  Class1 cls1 = new Class1();
  print(cls1.runtimeType.toString());
  new Class2<int>();
  Class1 cls3 = new Class3<int>();
  print(cls3.runtimeType.toString());
}
