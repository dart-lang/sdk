// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import
    '../../../sdk/lib/_internal/compiler/implementation/types/types.dart'
    show TypeMask;

import 'compiler_helper.dart';
import 'parser_helper.dart';

const String TEST = """
returnNum1(a) {
  if (a) return 1;
  else return 2.0;
}

returnNum2(a) {
  if (a) return 1.0;
  else return 2;
}

returnInt1(a) {
  if (a) return 1;
  else return 2;
}

returnDouble(a) {
  if (a) return 1.0;
  else return 2.0;
}

returnGiveUp(a) {
  if (a) return 1;
  else return 'foo';
}

returnInt2() {
  var a = 42;
  return a++;
}

returnInt5() {
  var a = 42;
  return ++a;
}

returnInt6() {
  var a = 42;
  a++;
  return a;
}

returnIntOrNull(a) {
  if (a) return 42;
}

returnInt3(a) {
  if (a) return 42;
  throw 42;
}

returnInt4() {
  return (42);
}

returnInt7() {
  return 42.abs();
}

returnInt8() {
  return 42.remainder(54);
}

returnDynamic1() {
  // Ensure that we don't intrisify a wrong call to [int.remainder].
  return 42.remainder();
}

returnDynamic2() {
  // Ensure that we don't intrisify a wrong call to [int.abs].
  return 42.abs(42);
}

get topLevelGetter => 42;
returnDynamic() => topLevelGetter(42);

class A {
  factory A() = A.generative;
  A.generative();
  operator==(other) => 42;

  get myField => 42;
  set myField(a) {}
  returnInt1() => ++myField;
  returnInt2() => ++this.myField;
  returnInt3() => this.myField += 42;
  returnInt4() => myField += 42;
  operator[](index) => 42;
  operator[]= (index, value) {}
  returnInt5() => ++this[0];
  returnInt6() => this[0] += 1;
}

class B extends A {
  B() : super.generative();
  returnInt1() => ++new A().myField;
  returnInt2() => new A().myField += 4;
  returnInt3() => ++new A()[0];
  returnInt4() => new A()[0] += 42;
  returnInt5() => ++super.myField;
  returnInt6() => super.myField += 4;
  returnInt7() => ++super[0];
  returnInt8() => super[0] += 54;
}

main() {
  returnNum1(true);
  returnNum2(true);
  returnInt1(true);
  returnInt2(true);
  returnInt3(true);
  returnInt4();
  returnDouble(true);
  returnGiveUp(true);
  returnInt5();
  returnInt6();
  returnInt7();
  returnInt8();
  returnIntOrNull(true);
  returnDynamic();
  returnDynamic1();
  returnDynamic2();
  new A() == null;
  new A()..returnInt1()
         ..returnInt2()
         ..returnInt3()
         ..returnInt4()
         ..returnInt5()
         ..returnInt6();

  new B()..returnInt1()
         ..returnInt2()
         ..returnInt3()
         ..returnInt4()
         ..returnInt5()
         ..returnInt6()
         ..returnInt7()
         ..returnInt8();
}
""";

void main() {
  Uri uri = new Uri.fromComponents(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  compiler.runCompiler(uri);
  var typesInferrer = compiler.typesTask.typesInferrer;

  checkReturn(String name, type) {
    var element = findElement(compiler, name);
    Expect.equals(type, typesInferrer.internal.returnTypeOf[element], name);
  }
  var interceptorType =
      findTypeMask(compiler, 'Interceptor', 'nonNullSubclass');

  checkReturn('returnNum1', typesInferrer.numType);
  checkReturn('returnNum2', typesInferrer.numType);
  checkReturn('returnInt1', typesInferrer.intType);
  checkReturn('returnInt2', typesInferrer.intType);
  checkReturn('returnDouble', typesInferrer.doubleType);
  checkReturn('returnGiveUp', interceptorType);
  checkReturn('returnInt5', typesInferrer.intType);
  checkReturn('returnInt6', typesInferrer.intType);
  checkReturn('returnIntOrNull', typesInferrer.intType.nullable());
  checkReturn('returnInt3', typesInferrer.intType);
  checkReturn('returnDynamic', typesInferrer.dynamicType);
  checkReturn('returnInt4', typesInferrer.intType);
  checkReturn('returnInt7', typesInferrer.intType);
  checkReturn('returnInt8', typesInferrer.intType);
  checkReturn('returnDynamic1', typesInferrer.dynamicType);
  checkReturn('returnDynamic2', typesInferrer.dynamicType);

  checkReturnInClass(String className, String methodName, type) {
    var cls = findElement(compiler, className);
    var element = cls.lookupLocalMember(buildSourceString(methodName));
    Expect.equals(type, typesInferrer.internal.returnTypeOf[element]);
  }

  checkReturnInClass('A', 'returnInt1', typesInferrer.intType);
  checkReturnInClass('A', 'returnInt2', typesInferrer.intType);
  checkReturnInClass('A', 'returnInt3', typesInferrer.intType);
  checkReturnInClass('A', 'returnInt4', typesInferrer.intType);
  checkReturnInClass('A', 'returnInt5', typesInferrer.intType);
  checkReturnInClass('A', 'returnInt6', typesInferrer.intType);
  checkReturnInClass('A', '==', interceptorType);

  checkReturnInClass('B', 'returnInt1', typesInferrer.intType);
  checkReturnInClass('B', 'returnInt2', typesInferrer.intType);
  checkReturnInClass('B', 'returnInt3', typesInferrer.intType);
  checkReturnInClass('B', 'returnInt4', typesInferrer.intType);
  checkReturnInClass('B', 'returnInt5', typesInferrer.intType);
  checkReturnInClass('B', 'returnInt6', typesInferrer.intType);
  checkReturnInClass('B', 'returnInt7', typesInferrer.intType);
  checkReturnInClass('B', 'returnInt8', typesInferrer.intType);

  checkFactoryConstructor(String className) {
    var cls = findElement(compiler, className);
    var element = cls.localLookup(buildSourceString(className));
    Expect.equals(new TypeMask.nonNullExact(cls.rawType),
                  typesInferrer.internal.returnTypeOf[element]);
  }
  checkFactoryConstructor('A');
}
