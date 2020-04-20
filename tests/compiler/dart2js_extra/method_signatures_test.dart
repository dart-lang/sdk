// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--strong

import 'package:expect/expect.dart';

class Class1 {
  num method1(num n) => null;

  num method2(int n) => null;

  Object method3(num n) => null;
}

class Class2<T> {
  num method4(T n) => null;
}

class Class3<T> {
  T method5(num n) => null;
}

class Class4<T> {
  num method6(num n, T t) => null;
}

num method7(num n) => null;

num method8(int n) => null;

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
