// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

class Class1 {
  /*member: Class1.method1:*/
  num method1(num n) => null;

  /*member: Class1.method2:*/
  num method2(int n) => null;

  /*member: Class1.method3:*/
  Object method3(num n) => null;
}

/*spec.class: Class2:direct,explicit=[Class2.T*],needsArgs*/
class Class2<T> {
  num method4(T n) => null;
}

/*class: Class3:needsArgs*/
class Class3<T> {
  /*member: Class3.method5:needsSignature*/
  T method5(num n) => null;
}

/*spec.class: Class4:direct,explicit=[Class4.T*],needsArgs*/
class Class4<T> {
  /*member: Class4.method6:*/
  num method6(num n, T t) => null;
}

/*member: method7:*/
num method7(num n) => null;

/*member: method8:*/
num method8(int n) => null;

/*member: method9:*/
Object method9(num n) => null;

@pragma('dart2js:noInline')
test(o) => o is num Function(num);

main() {
  Expect.isTrue(test(new Class1().method1));
  Expect.isFalse(test(new Class1().method2));
  Expect.isFalse(test(new Class1().method3));
  Expect.isTrue(test(new Class2<num>().method4));
  Expect.isTrue(test(new Class3<num>().method5));
  Expect.isFalse(test(new Class4<num>().method6));
  Expect.isTrue(test(method7));
  Expect.isFalse(test(method8));
  Expect.isFalse(test(method9));
}
