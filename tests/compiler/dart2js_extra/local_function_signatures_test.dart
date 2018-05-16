// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--strong

import 'package:expect/expect.dart';

class Class1 {
  method1() {
    num local(num n) => null;
    return local;
  }

  method2() {
    num local(int n) => null;
    return local;
  }

  method3() {
    Object local(num n) => null;
    return local;
  }
}

class Class2<T> {
  method4() {
    num local(T n) => null;
    return local;
  }
}

class Class3<T> {
  method5() {
    T local(num n) => null;
    return local;
  }
}

class Class4<T> {
  method6() {
    num local(num n, T t) => null;
    return local;
  }
}

@NoInline()
test(o) => o is num Function(num);

main() {
  Expect.isTrue(test(new Class1().method1()));
  Expect.isFalse(test(new Class1().method2()));
  Expect.isFalse(test(new Class1().method3()));
  Expect.isTrue(test(new Class2<num>().method4()));
  Expect.isTrue(test(new Class3<num>().method5()));
  Expect.isFalse(test(new Class4<num>().method6()));
}
