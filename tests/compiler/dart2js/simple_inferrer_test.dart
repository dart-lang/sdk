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

returnNum3() {
  var a = 42;
  return ++a;
}

returnNum4() {
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

get topLevelGetter => 42;
returnDynamic() => topLevelGetter(42);

class A {
  factory A() = A.generative;
  A.generative();
  operator==(other) => 42;

  get myField => 42;
  set myField(a) {}
  returnNum1() => ++myField;
  returnNum2() => ++this.myField;
  returnNum3() => this.myField += 42;
  returnNum4() => myField += 42;
  operator[](index) => 42;
  operator[]= (index, value) {}
  returnNum5() => ++this[0];
  returnNum6() => this[0] += 1;
}

class B extends A {
  B() : super.generative();
  returnNum1() => ++new A().myField;
  returnNum2() => new A().myField += 4;
  returnNum3() => ++new A()[0];
  returnNum4() => new A()[0] += 42;
  returnNum5() => ++super.myField;
  returnNum6() => super.myField += 4;
  returnNum7() => ++super[0];
  returnNum8() => super[0] += 54;
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
  returnNum3();
  returnNum4();
  returnIntOrNull(true);
  returnDynamic();
  new A() == null;
  new A()..returnNum1()
         ..returnNum2()
         ..returnNum3()
         ..returnNum4()
         ..returnNum5()
         ..returnNum6();

  new B()..returnNum1()
         ..returnNum2()
         ..returnNum3()
         ..returnNum4()
         ..returnNum5()
         ..returnNum6()
         ..returnNum7()
         ..returnNum8();
}
""";

void main() {
  Uri uri = new Uri.fromComponents(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  compiler.runCompiler(uri);
  var typesInferrer = compiler.typesTask.typesInferrer;

  checkReturn(String name, type) {
    var element = findElement(compiler, name);
    Expect.equals(type, typesInferrer.returnTypeOf[element], name);
  }
  var interceptorType =
      findTypeMask(compiler, 'Interceptor', 'nonNullSubclass');

  checkReturn('returnNum1', typesInferrer.numType);
  checkReturn('returnNum2', typesInferrer.numType);
  checkReturn('returnInt1', typesInferrer.intType);
  checkReturn('returnInt2', typesInferrer.intType);
  checkReturn('returnDouble', typesInferrer.doubleType);
  checkReturn('returnGiveUp', interceptorType);
  checkReturn('returnNum3', typesInferrer.numType);
  checkReturn('returnNum4', typesInferrer.numType);
  checkReturn('returnIntOrNull', typesInferrer.intType.nullable());
  checkReturn('returnInt3', typesInferrer.intType);
  checkReturn('returnDynamic', typesInferrer.dynamicType);
  checkReturn('returnInt4', typesInferrer.intType);

  checkReturnInClass(String className, String methodName, type) {
    var cls = findElement(compiler, className);
    var element = cls.lookupLocalMember(buildSourceString(methodName));
    Expect.equals(type, typesInferrer.returnTypeOf[element]);
  }

  checkReturnInClass('A', 'returnNum1', typesInferrer.numType);
  checkReturnInClass('A', 'returnNum2', typesInferrer.numType);
  checkReturnInClass('A', 'returnNum3', typesInferrer.numType);
  checkReturnInClass('A', 'returnNum4', typesInferrer.numType);
  checkReturnInClass('A', 'returnNum5', typesInferrer.numType);
  checkReturnInClass('A', 'returnNum6', typesInferrer.numType);
  checkReturnInClass('A', '==', interceptorType);

  checkReturnInClass('B', 'returnNum1', typesInferrer.numType);
  checkReturnInClass('B', 'returnNum2', typesInferrer.numType);
  checkReturnInClass('B', 'returnNum3', typesInferrer.numType);
  checkReturnInClass('B', 'returnNum4', typesInferrer.numType);
  checkReturnInClass('B', 'returnNum5', typesInferrer.numType);
  checkReturnInClass('B', 'returnNum6', typesInferrer.numType);
  checkReturnInClass('B', 'returnNum7', typesInferrer.numType);
  checkReturnInClass('B', 'returnNum8', typesInferrer.numType);

  checkFactoryConstructor(String className) {
    var cls = findElement(compiler, className);
    var element = cls.localLookup(buildSourceString(className));
    Expect.equals(new TypeMask.nonNullExact(cls.rawType),
                  typesInferrer.returnTypeOf[element]);
  }
  checkFactoryConstructor('A');
}
