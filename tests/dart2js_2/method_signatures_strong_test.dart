// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--strong

import 'package:expect/expect.dart';

class Class1 {
  num method1<T>(num n) => null;

  num method2<T>(int n) => null;

  int method3<T>(num n) => null;
}

class Class2 {
  num method4<T>(T n) => null;
}

class Class3 {
  T method5<T>(num n) => null;
}

class Class4 {
  num method6<T>(num n, T t) => null;
}

num method7<T>(T n) => null;

T method8<T>(num n) => null;

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
