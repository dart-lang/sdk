// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

class A {
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
  returnDouble(true);
  returnGiveUp(true);
  returnNum3();
  returnNum4();
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
    Expect.equals(type, typesInferrer.returnTypeOf[element]);
  }
  checkReturn('returnNum1', compiler.numClass);
  checkReturn('returnNum2', compiler.numClass);
  checkReturn('returnInt1', compiler.intClass);
  checkReturn('returnInt2', compiler.intClass);
  checkReturn('returnDouble', compiler.doubleClass);
  checkReturn('returnGiveUp', typesInferrer.giveUpType);
  checkReturn('returnNum3', compiler.numClass);
  checkReturn('returnNum4', compiler.numClass);

  checkReturnInClass(String className, String methodName, type) {
    var cls = findElement(compiler, className);
    var element = cls.lookupLocalMember(buildSourceString(methodName));
    Expect.equals(type, typesInferrer.returnTypeOf[element]);
  }

  checkReturnInClass('A', 'returnNum1', compiler.numClass);
  checkReturnInClass('A', 'returnNum2', compiler.numClass);
  checkReturnInClass('A', 'returnNum3', compiler.numClass);
  checkReturnInClass('A', 'returnNum4', compiler.numClass);
  checkReturnInClass('A', 'returnNum5', compiler.numClass);
  checkReturnInClass('A', 'returnNum6', compiler.numClass);

  checkReturnInClass('B', 'returnNum1', compiler.numClass);
  checkReturnInClass('B', 'returnNum2', compiler.numClass);
  checkReturnInClass('B', 'returnNum3', compiler.numClass);
  checkReturnInClass('B', 'returnNum4', compiler.numClass);
  checkReturnInClass('B', 'returnNum5', compiler.numClass);
  checkReturnInClass('B', 'returnNum6', compiler.numClass);
  checkReturnInClass('B', 'returnNum7', compiler.numClass);
  checkReturnInClass('B', 'returnNum8', compiler.numClass);
}
