// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'package:compiler/src/types/types.dart' show TypeMask;
import 'type_mask_test_helper.dart';

import 'compiler_helper.dart';

const String TEST = """
returnNum1(a) {
  if (a) return 1;
  else return 2.5;
}

returnNum2(a) {
  if (a) return 1.4;
  else return 2;
}

returnInt1(a) {
  if (a) return 1;
  else return 2;
}

returnDouble(a) {
  if (a) return 1.5;
  else return 2.5;
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

returnEmpty1() {
  // Ensure that we don't intrisify a wrong call to [int.remainder].
  return 42.remainder();
}

returnEmpty2() {
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

testIsCheck21(a) {
  if (a is int || a is List) {
    return a;
  } else {
    return 42;
  }
}

testIsCheck22(a) {
  return (a is int || a is List) ? a : 42;
}

testIsCheck23(a) {
  if (a is! int) throw 'foo';
  return a;
}

testIsCheck24(a) {
  if (a is! int) return 42;
  return a;
}

testIsCheck25(a) {
  if (a is int) throw 'foo';
  return a;
}

testIsCheck26(a) {
  if (a is int) {
  } else {
    throw 42;
  }
  return a;
}

testIsCheck27(a) {
  if (a is int) {
  } else {
    return 42;
  }
  return a;
}

testIsCheck28(a) {
  if (a is int) {
  } else {
  }
  return a;
}

testIsCheck29(a) {
  if (a is int) {}
  return a;
}

testIf1(a) {
  var c = null;
  if (a) {
    c = 10;
  } else {
  }
  return c;
}

testIf2(a) {
  var c = null;
  if (a) {
  } else {
    c = 10;
  }
  return c;
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
  switch (topLevelGetter) {
    case 1: break;
    default: break;
  }
  return 42;
}

testSwitch5() {
  switch (topLevelGetter) {
    case 1: return 1;
    default: return 2;
  }
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

testDoWhile1() {
  var a = 42;
  do {
    a = 'foo';
  } while (true);
  return a;
}

testDoWhile2() {
  var a = 42;
  do {
    a = 'foo';
    return;
  } while (true);
  return a;
}

testDoWhile3() {
  var a = 42;
  do {
    a = 'foo';
    if (true) continue;
    return 42;
  } while (true);
  return a;
}

testDoWhile4() {
  var a = 'foo';
  do {
    a = 54;
    if (true) break;
    return 3.5;
  } while (true);
  return a;
}

testSpecialization1() {
  var a = topLevelGetter();
  a - 42;
  return a;
}

testSpecialization2() {
  var a = topLevelGetter();
  // Make [a] a captured variable. This should disable receiver
  // specialization on [a].
  (() => a.toString())();
  a - 42;
  return a;
}

testSpecialization3() {
  var a = returnDynamic() ? null : 42;
  a.toString();
  // Test that calling an [Object] method on [a] will not lead to
  // infer that [a] is not null;
  return a;
}

testReturnNull1(a) {
  if (a == null) return a;
  return null;
}

testReturnNull2(a) {
  if (a != null) return null;
  return a;
}

testReturnNull3(a) {
  if (a == null) return 42;
  return a;
}

testReturnNull4() {
  var a = topLeveGetter();
  if (a == null) return a;
  return null;
}

testReturnNull5() {
  var a = topLeveGetter();
  if (a != null) return null;
  return a;
}

testReturnNull6() {
  var a = topLeveGetter();
  if (a == null) return 42;
  return a;
}

testReturnNotEquals() {
  return new A() != 54;
}

testReturnInvokeDynamicGetter() => new A().myFactory();

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

  get myFactory => () => 42;
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

class C {
  var myField = 42;
  C();

  returnInt1() => ++myField;
  returnInt2() => ++this.myField;
  returnInt3() => this.myField += 42;
  returnInt4() => myField += 42;
  operator[](index) => myField;
  operator[]= (index, value) {}
  returnInt5() => ++this[0];
  returnInt6() => this[0] += 1;
}

testCascade1() {
  return [1, 2, 3]..add(4)..add(5);
}

testCascade2() {
  return new CascadeHelper()
      ..a = "hello"
      ..b = 42
      ..i += 1;
}

class CascadeHelper {
  var a, b;
  var i = 0;
}

main() {
  // Ensure a function class is being instantiated.
  () => 42;
  returnNum1(true);
  returnNum2(true);
  returnInt1(true);
  returnInt2();
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
  returnEmpty1();
  returnEmpty2();
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
  testIsCheck21(topLevelGetter());
  testIsCheck22(topLevelGetter());
  testIsCheck23(topLevelGetter());
  testIsCheck24(topLevelGetter());
  testIsCheck25(topLevelGetter());
  testIsCheck26(topLevelGetter());
  testIsCheck27(topLevelGetter());
  testIsCheck28(topLevelGetter());
  testIsCheck29(topLevelGetter());
  testIf1(topLevelGetter());
  testIf2(topLevelGetter());
  returnAsString();
  returnIntAsNum();
  returnAsTypedef();
  returnTopLevelGetter();
  testDeadCode();
  testLabeledIf(true);
  testSwitch1();
  testSwitch2();
  testSwitch3();
  testSwitch4();
  testSwitch5();
  testContinue1();
  testBreak1();
  testContinue2();
  testBreak2();
  testDoWhile1();
  testDoWhile2();
  testDoWhile3();
  testDoWhile4();
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

  new C()..returnInt1()
         ..returnInt2()
         ..returnInt3()
         ..returnInt4()
         ..returnInt5()
         ..returnInt6();
  testReturnElementOfConstList1();
  testReturnElementOfConstList2();
  testReturnItselfOrInt(topLevelGetter());
  testReturnInvokeDynamicGetter();
  testCascade1();
  testCascade2();
  testSpecialization1();
  testSpecialization2();
  testSpecialization3();
  testReturnNull1(topLevelGetter());
  testReturnNull2(topLevelGetter());
  testReturnNull3(topLevelGetter());
  testReturnNull4();
  testReturnNull5();
  testReturnNull6();
  testReturnNotEquals();
}
""";

void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  compiler.diagnosticHandler = createHandler(compiler, TEST);
  asyncTest(() => compiler.run(uri).then((_) {
        var typesInferrer = compiler.globalInference.typesInferrerInternal;
        var closedWorld = typesInferrer.closedWorld;
        var commonMasks = closedWorld.commonMasks;

        checkReturn(String name, type) {
          var element = findElement(compiler, name);
          Expect.equals(
              type,
              simplify(
                  typesInferrer.getReturnTypeOfElement(element), closedWorld),
              name);
        }

        var interceptorType = commonMasks.interceptorType;

        checkReturn('returnNum1', commonMasks.numType);
        checkReturn('returnNum2', commonMasks.numType);
        checkReturn('returnInt1', commonMasks.uint31Type);
        checkReturn('returnInt2', commonMasks.uint31Type);
        checkReturn('returnDouble', commonMasks.doubleType);
        checkReturn('returnGiveUp', interceptorType);
        checkReturn(
            'returnInt5', commonMasks.uint32Type); // uint31+uint31->uint32
        checkReturn(
            'returnInt6', commonMasks.uint32Type); // uint31+uint31->uint32
        checkReturn('returnIntOrNull', commonMasks.uint31Type.nullable());
        checkReturn('returnInt3', commonMasks.uint31Type);
        checkReturn('returnDynamic', commonMasks.dynamicType);
        checkReturn('returnInt4', commonMasks.uint31Type);
        checkReturn('returnInt7', commonMasks.positiveIntType);
        checkReturn('returnInt8', commonMasks.positiveIntType);
        checkReturn('returnEmpty1', const TypeMask.nonNullEmpty());
        checkReturn('returnEmpty2', const TypeMask.nonNullEmpty());
        TypeMask intType = new TypeMask.nonNullSubtype(
            closedWorld.commonElements.intClass, closedWorld);
        checkReturn('testIsCheck1', intType);
        checkReturn('testIsCheck2', intType);
        checkReturn('testIsCheck3', intType.nullable());
        checkReturn('testIsCheck4', intType);
        checkReturn('testIsCheck5', intType);
        checkReturn('testIsCheck6', commonMasks.dynamicType);
        checkReturn('testIsCheck7', intType);
        checkReturn('testIsCheck8', commonMasks.dynamicType);
        checkReturn('testIsCheck9', intType);
        checkReturn('testIsCheck10', commonMasks.dynamicType);
        checkReturn('testIsCheck11', intType);
        checkReturn('testIsCheck12', commonMasks.dynamicType);
        checkReturn('testIsCheck13', intType);
        checkReturn('testIsCheck14', commonMasks.dynamicType);
        // TODO(29309): Re-enable when 29309 is fixed.
        // checkReturn('testIsCheck15', intType);
        checkReturn('testIsCheck16', commonMasks.dynamicType);
        checkReturn('testIsCheck17', intType);
        checkReturn('testIsCheck18', commonMasks.dynamicType);
        checkReturn('testIsCheck19', commonMasks.dynamicType);
        checkReturn('testIsCheck20', interceptorType);
        checkReturn('testIsCheck21', commonMasks.dynamicType);
        checkReturn('testIsCheck22', commonMasks.dynamicType);
        checkReturn('testIsCheck23', intType);
        checkReturn('testIsCheck24', intType);
        checkReturn('testIsCheck25', commonMasks.dynamicType);
        checkReturn('testIsCheck26', intType);
        checkReturn('testIsCheck27', intType);
        checkReturn('testIsCheck28', commonMasks.dynamicType);
        checkReturn('testIsCheck29', commonMasks.dynamicType);
        checkReturn('testIf1', commonMasks.uint31Type.nullable());
        checkReturn('testIf2', commonMasks.uint31Type.nullable());
        checkReturn(
            'returnAsString',
            new TypeMask.subtype(
                closedWorld.commonElements.stringClass, closedWorld));
        checkReturn('returnIntAsNum', commonMasks.uint31Type);
        checkReturn('returnAsTypedef', commonMasks.functionType.nullable());
        checkReturn('returnTopLevelGetter', commonMasks.uint31Type);
        checkReturn('testDeadCode', commonMasks.uint31Type);
        checkReturn('testLabeledIf', commonMasks.uint31Type.nullable());
        checkReturn(
            'testSwitch1',
            simplify(
                commonMasks.intType
                    .union(commonMasks.doubleType, closedWorld)
                    .nullable(),
                closedWorld));
        checkReturn('testSwitch2', commonMasks.uint31Type);
        checkReturn('testSwitch3', interceptorType.nullable());
        checkReturn('testSwitch4', commonMasks.uint31Type);
        checkReturn('testSwitch5', commonMasks.uint31Type);
        checkReturn('testContinue1', interceptorType.nullable());
        checkReturn('testBreak1', interceptorType.nullable());
        checkReturn('testContinue2', interceptorType.nullable());
        checkReturn('testBreak2', commonMasks.uint32Type.nullable());
        checkReturn('testReturnElementOfConstList1', commonMasks.uint31Type);
        checkReturn('testReturnElementOfConstList2', commonMasks.uint31Type);
        checkReturn('testReturnItselfOrInt', commonMasks.uint31Type);
        checkReturn('testReturnInvokeDynamicGetter', commonMasks.dynamicType);

        checkReturn('testDoWhile1', commonMasks.stringType);
        checkReturn('testDoWhile2', commonMasks.nullType);
        checkReturn('testDoWhile3', commonMasks.uint31Type);
        checkReturn('testDoWhile4', commonMasks.numType);

        checkReturnInClass(String className, String methodName, type) {
          dynamic cls = findElement(compiler, className);
          var element = cls.lookupLocalMember(methodName);
          Expect.equals(
              type,
              simplify(
                  typesInferrer.getReturnTypeOfElement(element), closedWorld),
              '$className:$methodName');
        }

        checkReturnInClass('A', 'returnInt1', commonMasks.uint32Type);
        checkReturnInClass('A', 'returnInt2', commonMasks.uint32Type);
        checkReturnInClass('A', 'returnInt3', commonMasks.uint32Type);
        checkReturnInClass('A', 'returnInt4', commonMasks.uint32Type);
        checkReturnInClass('A', 'returnInt5', commonMasks.uint32Type);
        checkReturnInClass('A', 'returnInt6', commonMasks.uint32Type);
        checkReturnInClass('A', '==', interceptorType);

        checkReturnInClass('B', 'returnInt1', commonMasks.uint32Type);
        checkReturnInClass('B', 'returnInt2', commonMasks.uint32Type);
        checkReturnInClass('B', 'returnInt3', commonMasks.uint32Type);
        checkReturnInClass('B', 'returnInt4', commonMasks.uint32Type);
        checkReturnInClass('B', 'returnInt5', commonMasks.uint32Type);
        checkReturnInClass('B', 'returnInt6', commonMasks.uint32Type);
        checkReturnInClass('B', 'returnInt7', commonMasks.uint32Type);
        checkReturnInClass('B', 'returnInt8', commonMasks.uint32Type);
        checkReturnInClass('B', 'returnInt9', commonMasks.uint31Type);

        checkReturnInClass('C', 'returnInt1', commonMasks.positiveIntType);
        checkReturnInClass('C', 'returnInt2', commonMasks.positiveIntType);
        checkReturnInClass('C', 'returnInt3', commonMasks.positiveIntType);
        checkReturnInClass('C', 'returnInt4', commonMasks.positiveIntType);
        checkReturnInClass('C', 'returnInt5', commonMasks.positiveIntType);
        checkReturnInClass('C', 'returnInt6', commonMasks.positiveIntType);

        checkFactoryConstructor(String className, String factoryName) {
          dynamic cls = findElement(compiler, className);
          var element = cls.localLookup(factoryName);
          Expect.equals(new TypeMask.nonNullExact(cls, closedWorld),
              typesInferrer.getReturnTypeOfElement(element));
        }

        checkFactoryConstructor('A', '');

        checkReturn('testCascade1', commonMasks.growableListType);
        ClassElement clsCascadeHelper = findElement(compiler, 'CascadeHelper');
        checkReturn('testCascade2',
            new TypeMask.nonNullExact(clsCascadeHelper, closedWorld));
        checkReturn('testSpecialization1', commonMasks.numType);
        checkReturn('testSpecialization2', commonMasks.dynamicType);
        checkReturn('testSpecialization3', commonMasks.uint31Type.nullable());
        checkReturn('testReturnNull1', commonMasks.nullType);
        checkReturn('testReturnNull2', commonMasks.nullType);
        checkReturn('testReturnNull3', commonMasks.dynamicType);
        checkReturn('testReturnNull4', commonMasks.nullType);
        checkReturn('testReturnNull5', commonMasks.nullType);
        checkReturn('testReturnNull6', commonMasks.dynamicType);
        checkReturn('testReturnNotEquals', commonMasks.boolType);
      }));
}
