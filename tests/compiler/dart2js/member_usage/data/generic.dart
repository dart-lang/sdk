// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: Class.:invoke*/
class Class {
  // The type parameter is never provided but needed nonetheless.
  /*member: Class.method1:invoke=(0)*/
  method1<S>([a]) => S;

  /*member: Class.method2:invoke=<1>(0)*/
  method2<S>([a]) => S;

  /*member: Class.method3:invoke=<1>(0)*/
  method3<S>([a]) => S;

  /*member: Class.method4:invoke=(1)*/
  method4<S>([a]) => S;

  /*member: Class.method5:invoke*/
  method5<S>([a]) => S;

  /*member: Class.method6:invoke*/
  method6<S>([a]) => S;
}

/*member: main:invoke*/
main() {
  dynamic c = new Class();
  c.method1();
  c.method2<int>();
  c.method3();
  c.method3<int>();
  c.method4(0);
  c.method5<int>(0);
  c.method6(0);
  c.method6<int>(0);
}
