// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Class1 {
  /*element: Class1.method1:*/
  num method1(num n) => null;

  /*element: Class1.method2:*/
  num method2(int n) => null;

  /*element: Class1.method3:*/
  Object method3(num n) => null;
}

/*class: Class2:needsArgs*/
class Class2<T> {
  /*element: Class2.method4:needsSignature*/
  num method4(T n) => null;
}

/*class: Class3:needsArgs*/
class Class3<T> {
  /*element: Class3.method5:needsSignature*/
  T method5(num n) => null;
}

/*class: Class4:*/
class Class4<T> {
  /*element: Class4.method6:*/
  num method6(num n, T t) => null;
}

/*element: method7:*/
num method7(num n) => null;

/*element: method8:*/
num method8(int n) => null;

/*element: method9:*/
Object method9(num n) => null;

@NoInline()
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
