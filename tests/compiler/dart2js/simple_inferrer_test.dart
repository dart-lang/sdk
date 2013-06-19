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

testIsCheck1(a) {
  if (a is int) {
    return a;
  } else {
    return 42;
  }
}

testIsCheck2(a) {
  if (a is !int) {
    return 0;
  } else {
    return a;
  }
}

testIsCheck3(a) {
  if (a is !int) {
    print('hello');
  } else {
    return a;
  }
}

testIsCheck4(a) {
  if (a is int) {
    return a;
  } else {
    return 42;
  }
}

testIsCheck5(a) {
  if (a is !int) {
    return 42;
  } else {
    return a;
  }
}

testIsCheck6(a) {
  if (a is !int) {
    return a;
  } else {
    return 42;
  }
}

testIsCheck7(a) {
  if (a == 'foo' && a is int) {
    return a;
  } else {
    return 42;
  }
}

testIsCheck8(a) {
  if (a == 'foo' || a is int) {
    return a;
  } else {
    return 42;
  }
}

testIsCheck9(a) {
  return a is int ? a : 42;
}

testIsCheck10(a) {
  return a is !int ? a : 42;
}

testIsCheck11(a) {
  return a is !int ? 42 : a;
}

testIsCheck12(a) {
  return a is int ? 42 : a;
}

testIsCheck13(a) {
  while (a is int) {
    return a;
  }
  return 42;
}

testIsCheck14(a) {
  while (a is !int) {
    return 42;
  }
  return a;
}

testIsCheck15(a) {
  var c = 42;
  do {
    if (a) return c;
    c = topLevelGetter();
  } while (c is int);
  return 42;
}

testIsCheck16(a) {
  var c = 42;
  do {
    if (a) return c;
    c = topLevelGetter();
  } while (c is !int);
  return 42;
}

testIsCheck17(a) {
  var c = 42;
  for (; c is int;) {
    if (a) return c;
    c = topLevelGetter();
  }
  return 42;
}

testIsCheck18(a) {
  var c = 42;
  for (; c is int;) {
    if (a) return c;
    c = topLevelGetter();
  }
  return c;
}

testIsCheck19(a) {
  var c = 42;
  for (; c is !int;) {
    if (a) return c;
    c = topLevelGetter();
  }
  return 42;
}

testIsCheck20() {
  var c = topLevelGetter();
  if (c != null && c is! bool && c is! int) {
    return 42;
  } else if (c is String) {
    return c;
  } else {
    return 68;
  }
}

returnAsString() {
  return topLevelGetter() as String;
}

returnIntAsNum() {
  return 0 as num;
}

typedef int Foo();

returnAsTypedef() {
  return topLevelGetter() as Foo;
}

testDeadCode() {
  return 42;
  return 'foo';
}

testLabeledIf(a) {
  var c;
  L1: if (a > 1) {
    if (a == 2) {
      break L1;
    }
    c = 42;
  } else {
    c = 38;
  }
  return c;
}

testSwitch1() {
  var a = null;
  switch (topLevelGetter) {
    case 100: a = 42.5; break;
    case 200: a = 42; break;
  }
  return a;
}

testSwitch2() {
  var a = null;
  switch (topLevelGetter) {
    case 100: a = 42; break;
    case 200: a = 42; break;
    default:
      a = 43;
  }
  return a;
}

testSwitch3() {
  var a = 42;
  var b;
  switch (topLevelGetter) {
    L1: case 1: b = a + 42; break;
    case 2: a = 'foo'; continue L1;
  }
  return b;
}

testSwitch4() {
  switch(topLevelGetter) {
    case 1: break;
    default: break;
  }
  return 42;
}

testContinue1() {
  var a = 42;
  var b;
  while (true) {
    b = a + 54;
    if (b == 42) continue;
    a = 'foo';
  }
  return b;
}

testBreak1() {
  var a = 42;
  var b;
  while (true) {
    b = a + 54;
    if (b == 42) break;
    b = 'foo';
  }
  return b;
}

testContinue2() {
  var a = 42;
  var b;
  while (true) {
    b = a + 54;
    if (b == 42) {
      b = 'foo';
      continue;
    }
  }
  return b;
}

testBreak2() {
  var a = 42;
  var b;
  while (true) {
    b = a + 54;
    if (b == 42) {
      a = 'foo';
      break;
    }
  }
  return b;
}

testReturnElementOfConstList1() {
  return const [42][0];
}

testReturnElementOfConstList2() {
  return topLevelConstList[0];
}

testReturnItselfOrInt(a) {
  if (a) return 42;
  return testReturnItselfOrInt(a);
}

var topLevelConstList = const [42];

get topLevelGetter => 42;
returnDynamic() => topLevelGetter(42);
returnTopLevelGetter() => topLevelGetter;

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
  returnInt9() => super.myField;
}

main() {
  // Ensure a function class is being instantiated.
  () => 42;
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
  testIsCheck1(topLevelGetter());
  testIsCheck2(topLevelGetter());
  testIsCheck3(topLevelGetter());
  testIsCheck4(topLevelGetter());
  testIsCheck5(topLevelGetter());
  testIsCheck6(topLevelGetter());
  testIsCheck7(topLevelGetter());
  testIsCheck8(topLevelGetter());
  testIsCheck9(topLevelGetter());
  testIsCheck10(topLevelGetter());
  testIsCheck11(topLevelGetter());
  testIsCheck12(topLevelGetter());
  testIsCheck13(topLevelGetter());
  testIsCheck14(topLevelGetter());
  testIsCheck15(topLevelGetter());
  testIsCheck16(topLevelGetter());
  testIsCheck17(topLevelGetter());
  testIsCheck18(topLevelGetter());
  testIsCheck19(topLevelGetter());
  testIsCheck20();
  returnAsString();
  returnIntAsNum();
  returnAsTypedef();
  returnTopLevelGetter();
  testDeadCode();
  testLabeledIf();
  testSwitch1();
  testSwitch2();
  testSwitch3();
  testSwitch4();
  testContinue1();
  testBreak1();
  testContinue2();
  testBreak2();
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
         ..returnInt8()
         ..returnInt9();
  testReturnElementOfConstList1();
  testReturnElementOfConstList2();
  testReturnItselfOrInt(topLevelGetter());
}
""";

void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  compiler.runCompiler(uri);
  var typesInferrer = compiler.typesTask.typesInferrer;

  checkReturn(String name, type) {
    var element = findElement(compiler, name);
    Expect.equals(
        type,
        typesInferrer.internal.returnTypeOf[element].simplify(compiler),
        name);
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
  TypeMask intType = new TypeMask.nonNullSubtype(compiler.intClass.rawType);
  checkReturn('testIsCheck1', intType);
  checkReturn('testIsCheck2', intType);
  checkReturn('testIsCheck3', intType.nullable());
  checkReturn('testIsCheck4', intType);
  checkReturn('testIsCheck5', intType);
  checkReturn('testIsCheck6', typesInferrer.dynamicType);
  checkReturn('testIsCheck7', intType);
  checkReturn('testIsCheck8', typesInferrer.dynamicType);
  checkReturn('testIsCheck9', intType);
  checkReturn('testIsCheck10', typesInferrer.dynamicType);
  checkReturn('testIsCheck11', intType);
  checkReturn('testIsCheck12', typesInferrer.dynamicType);
  checkReturn('testIsCheck13', intType);
  checkReturn('testIsCheck14', typesInferrer.dynamicType);
  checkReturn('testIsCheck15', intType);
  checkReturn('testIsCheck16', typesInferrer.dynamicType);
  checkReturn('testIsCheck17', intType);
  checkReturn('testIsCheck18', typesInferrer.dynamicType);
  checkReturn('testIsCheck19', typesInferrer.dynamicType);
  checkReturn('testIsCheck20', typesInferrer.dynamicType.nonNullable());
  checkReturn('returnAsString',
      new TypeMask.subtype(compiler.stringClass.computeType(compiler)));
  checkReturn('returnIntAsNum', typesInferrer.intType);
  checkReturn('returnAsTypedef', typesInferrer.functionType.nullable());
  checkReturn('returnTopLevelGetter', typesInferrer.intType);
  checkReturn('testDeadCode', typesInferrer.intType);
  checkReturn('testLabeledIf', typesInferrer.intType.nullable());
  checkReturn('testSwitch1', typesInferrer.intType
      .union(typesInferrer.doubleType, compiler).nullable().simplify(compiler));
  checkReturn('testSwitch2', typesInferrer.intType);
  checkReturn('testSwitch3', interceptorType.nullable());
  checkReturn('testSwitch4', typesInferrer.intType);
  checkReturn('testContinue1', interceptorType.nullable());
  checkReturn('testBreak1', interceptorType.nullable());
  checkReturn('testContinue2', interceptorType.nullable());
  checkReturn('testBreak2', typesInferrer.intType.nullable());
  checkReturn('testReturnElementOfConstList1', typesInferrer.intType);
  checkReturn('testReturnElementOfConstList2', typesInferrer.intType);
  checkReturn('testReturnItselfOrInt', typesInferrer.intType);

  checkReturnInClass(String className, String methodName, type) {
    var cls = findElement(compiler, className);
    var element = cls.lookupLocalMember(buildSourceString(methodName));
    Expect.equals(type,
        typesInferrer.internal.returnTypeOf[element].simplify(compiler));
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
  checkReturnInClass('B', 'returnInt9', typesInferrer.intType);

  checkFactoryConstructor(String className) {
    var cls = findElement(compiler, className);
    var element = cls.localLookup(buildSourceString(className));
    Expect.equals(new TypeMask.nonNullExact(cls.rawType),
                  typesInferrer.internal.returnTypeOf[element]);
  }
  checkFactoryConstructor('A');
}
