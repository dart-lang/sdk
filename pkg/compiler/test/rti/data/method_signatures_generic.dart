// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

class Class1 {
  /*member: Class1.method1:*/
  num method1<T>(num n) => null;

  /*member: Class1.method2:*/
  num method2<T>(int n) => null;

  /*member: Class1.method3:*/
  int method3<T>(num n) => null;
}

class Class2 {
  /*spec.member: Class2.method4:direct,explicit=[method4.T*],needsArgs,needsInst=[<num*>,<num*>,<num*>,<num*>]*/
  num method4<T>(T n) => null;
}

class Class3 {
  /*member: Class3.method5:*/
  T method5<T>(num n) => null;
}

class Class4 {
  /*spec.member: Class4.method6:direct,explicit=[method6.T*],needsArgs,needsInst=[<num*>,<num*>,<num*>,<num*>]*/
  num method6<T>(num n, T t) => null;
}

/*spec.member: method7:direct,explicit=[method7.T*],needsArgs,needsInst=[<num*>,<num*>,<num*>,<num*>]*/
num method7<T>(T n) => null;

/*member: method8:*/
T method8<T>(num n) => null;

/*spec.member: method9:direct,explicit=[method9.T*],needsArgs,needsInst=[<num*>,<num*>,<num*>,<num*>]*/
num method9<T>(num n, T t) => null;

@pragma('dart2js:noInline')
test(o) => o is num Function(num);

forceInstantiation(num Function(num) f) => f;

main() {
  Expect.isFalse(test(new Class1().method1));
  Expect.isFalse(test(new Class1().method2));
  Expect.isFalse(test(new Class1().method3));
  Expect.isTrue(test(forceInstantiation(new Class2().method4)));
  Expect.isTrue(test(forceInstantiation(new Class3().method5)));
  Expect.isFalse(test(new Class4().method6));
  Expect.isTrue(test(forceInstantiation(method7)));
  Expect.isTrue(test(forceInstantiation(method8)));
  Expect.isFalse(test(method9));
}
