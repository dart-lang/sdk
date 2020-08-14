// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Class1 {
  method1() {
    num local<T>(num n) => null as dynamic;
    return local;
  }

  method2() {
    num local<T>(int n) => null as dynamic;
    return local;
  }

  method3() {
    int local<T>(num n) => null as dynamic;
    return local;
  }
}

class Class2 {
  method4<T>() {
    num local(T n) => null as dynamic;
    return local;
  }
}

class Class3 {
  method5<T>() {
    T local(num n) => null as dynamic;
    return local;
  }
}

class Class4 {
  method6<T>() {
    num local(num n, T t) => null as dynamic;
    return local;
  }
}

method7<T>() {
  num local(T n) => null as dynamic;
  return local;
}

method8<T>() {
  T local(num n) => null as dynamic;
  return local;
}

method9<T>() {
  num local(num n, T t) => null as dynamic;
  return local;
}

method10() {
  num local<T>(T n) => null as dynamic;
  return local;
}

method11() {
  T local<T>(num n) => null as dynamic;
  return local;
}

method12() {
  num local<T>(num n, T t) => null as dynamic;
  return local;
}

num Function(num) //# 01: ok
    method13() {
  num local<T>(num n) => null as dynamic;
  return local;
}

num Function(num) //# 01: continued
    method14() {
  num local<T>(T n) => null as dynamic;
  return local;
}

num Function(num) //# 01: continued
    method15() {
  T local<T>(num n) => null as dynamic;
  return local;
}

@pragma('dart2js:noInline')
test(o) => o is num Function(num);

main() {
  Expect.isFalse(test(new Class1().method1()));
  Expect.isFalse(test(new Class1().method2()));
  Expect.isFalse(test(new Class1().method3()));
  Expect.isTrue(test(new Class2().method4<num>()));
  Expect.isTrue(test(new Class3().method5<num>()));
  Expect.isFalse(test(new Class4().method6<num>()));
  Expect.isTrue(test(method7<num>()));
  Expect.isTrue(test(method8<num>()));
  Expect.isFalse(test(method9()));
  Expect.isFalse(test(method10()));
  Expect.isFalse(test(method11()));
  Expect.isFalse(test(method12()));
  Expect.isTrue(test(method13())); //# 01: continued
  Expect.isTrue(test(method14())); //# 01: continued
  Expect.isTrue(test(method15())); //# 01: continued
}
