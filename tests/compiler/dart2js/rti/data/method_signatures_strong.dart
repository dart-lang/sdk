// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Class1 {
  /*element: Class1.method1:*/
  num method1<T>(num n) => null;

  /*element: Class1.method2:*/
  num method2<T>(int n) => null;

  /*element: Class1.method3:*/
  int method3<T>(num n) => null;
}

class Class2 {
  /*strong.element: Class2.method4:direct,explicit=[method4.T],needsArgs*/
  /*omit.element: Class2.method4:*/
  num method4<T>(T n) => null;
}

class Class3 {
  /*element: Class3.method5:*/
  T method5<T>(num n) => null;
}

class Class4 {
  /*strong.element: Class4.method6:direct,explicit=[method6.T],needsArgs*/
  /*omit.element: Class4.method6:*/
  num method6<T>(num n, T t) => null;
}

/*strong.element: method7:direct,explicit=[method7.T],needsArgs*/
/*omit.element: method7:*/
num method7<T>(T n) => null;

/*element: method8:*/
T method8<T>(num n) => null;

/*strong.element: method9:direct,explicit=[method9.T],needsArgs*/
/*omit.element: method9:*/
num method9<T>(num n, T t) => null;

@NoInline()
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
