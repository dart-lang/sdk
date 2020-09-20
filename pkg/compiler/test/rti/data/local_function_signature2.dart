// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

class Class1 {
  method1() {
    /*needsArgs,needsSignature*/num local<T>(num n) => null;
    return local;
  }

  method2() {
    /*needsArgs,needsSignature*/num local<T>(int n) => null;
    return local;
  }

  method3() {
    /*needsArgs,needsSignature*/int local<T>(num n) => null;
    return local;
  }
}

class Class2 {
  /*spec.member: Class2.method4:direct,explicit=[method4.T*],needsArgs,selectors=[Selector(call, method4, arity=0, types=1)]*/
  /*prod.member: Class2.method4:needsArgs,selectors=[Selector(call, method4, arity=0, types=1)]*/
  method4<T>() {
    /*needsSignature*/
    num local(T n) => null;
    return local;
  }
}

class Class3 {
  /*member: Class3.method5:needsArgs,selectors=[Selector(call, method5, arity=0, types=1)]*/
  method5<T>() {
    /*needsSignature*/
    T local(num n) => null;
    return local;
  }
}

class Class4 {
  /*prod.member: Class4.method6:needsArgs,selectors=[Selector(call, method6, arity=0, types=1)]*/
  /*spec.member: Class4.method6:direct,explicit=[method6.T*],needsArgs,selectors=[Selector(call, method6, arity=0, types=1)]*/
  method6<T>() {
    /*needsSignature*/num local(num n, T t) => null;
    return local;
  }
}

/*spec.member: method7:direct,explicit=[method7.T*],needsArgs*/
/*prod.member: method7:needsArgs*/
method7<T>() {
  /*needsSignature*/
  num local(T n) => null;
  return local;
}

/*member: method8:needsArgs*/
method8<T>() {
  /*needsSignature*/
  T local(num n) => null;
  return local;
}

/*spec.member: method9:direct,explicit=[method9.T*],needsArgs*/
/*prod.member: method9:needsArgs*/
method9<T>() {
  /*needsSignature*/num local(num n, T t) => null;
  return local;
}

method10() {
  /*spec.direct,explicit=[local.T*],needsArgs,needsSignature*/
  /*prod.needsArgs,needsSignature*/num local<T>(T n) => null;
  return local;
}

method11() {
  /*needsArgs,needsSignature*/T local<T>(num n) => null;
  return local;
}

method12() {
  /*spec.direct,explicit=[local.T*],needsArgs,needsSignature*/
  /*prod.needsArgs,needsSignature*/num local<T>(num n, T t) => null;
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
}
