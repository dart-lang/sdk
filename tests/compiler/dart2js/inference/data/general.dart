// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: returnNum1:Union([exact=JSDouble], [exact=JSUInt31])*/
returnNum1(/*Value([exact=JSBool], value: true)*/ a) {
  if (a)
    return 1;
  else
    return 2.5;
}

/*element: returnNum2:Union([exact=JSDouble], [exact=JSUInt31])*/
returnNum2(/*Value([exact=JSBool], value: true)*/ a) {
  if (a)
    return 1.4;
  else
    return 2;
}

/*element: returnInt1:[exact=JSUInt31]*/
returnInt1(/*Value([exact=JSBool], value: true)*/ a) {
  if (a)
    return 1;
  else
    return 2;
}

/*element: returnDouble:[exact=JSDouble]*/
returnDouble(/*Value([exact=JSBool], value: true)*/ a) {
  if (a)
    return 1.5;
  else
    return 2.5;
}

/*element: returnGiveUp:Union([exact=JSString], [exact=JSUInt31])*/
returnGiveUp(/*Value([exact=JSBool], value: true)*/ a) {
  if (a)
    return 1;
  else
    return 'foo';
}

/*element: returnInt2:[exact=JSUInt31]*/
returnInt2() {
  var a = 42;
  return a /*invoke: [exact=JSUInt31]*/ ++;
}

/*element: returnInt5:[subclass=JSUInt32]*/
returnInt5() {
  var a = 42;
  return /*invoke: [exact=JSUInt31]*/ ++a;
}

/*element: returnInt6:[subclass=JSUInt32]*/
returnInt6() {
  var a = 42;
  a /*invoke: [exact=JSUInt31]*/ ++;
  return a;
}

/*element: returnIntOrNull:[null|exact=JSUInt31]*/
returnIntOrNull(/*Value([exact=JSBool], value: true)*/ a) {
  if (a) return 42;
}

/*element: returnInt3:[exact=JSUInt31]*/
returnInt3(/*Value([exact=JSBool], value: true)*/ a) {
  if (a) return 42;
  throw 42;
}

/*element: returnInt4:[exact=JSUInt31]*/
returnInt4() {
  return (42);
}

/*element: returnInt7:[subclass=JSPositiveInt]*/
returnInt7() {
  return 42. /*invoke: [exact=JSUInt31]*/ abs();
}

/*element: returnInt8:[subclass=JSPositiveInt]*/
returnInt8() {
  return 42. /*invoke: [exact=JSUInt31]*/ remainder(54);
}

/*element: returnEmpty1:[empty]*/
returnEmpty1() {
  // Ensure that we don't intrisify a wrong call to [int.remainder].
  dynamic a = 42;
  return a. /*invoke: [exact=JSUInt31]*/ remainder();
}

/*element: returnEmpty2:[empty]*/
returnEmpty2() {
  // Ensure that we don't intrisify a wrong call to [int.abs].
  dynamic a = 42;
  return a. /*invoke: [exact=JSUInt31]*/ abs(42);
}

/*element: testIsCheck1:[subclass=JSInt]*/
testIsCheck1(/*[null|subclass=Object]*/ a) {
  if (a is int) {
    return a;
  } else {
    return 42;
  }
}

/*element: testIsCheck2:[subclass=JSInt]*/
testIsCheck2(/*[null|subclass=Object]*/ a) {
  if (a is! int) {
    return 0;
  } else {
    return a;
  }
}

/*element: testIsCheck3:[null|subclass=JSInt]*/
testIsCheck3(/*[null|subclass=Object]*/ a) {
  if (a is! int) {
    print('hello');
  } else {
    return a;
  }
}

/*element: testIsCheck4:[subclass=JSInt]*/
testIsCheck4(/*[null|subclass=Object]*/ a) {
  if (a is int) {
    return a;
  } else {
    return 42;
  }
}

/*element: testIsCheck5:[subclass=JSInt]*/
testIsCheck5(/*[null|subclass=Object]*/ a) {
  if (a is! int) {
    return 42;
  } else {
    return a;
  }
}

/*element: testIsCheck6:[null|subclass=Object]*/
testIsCheck6(/*[null|subclass=Object]*/ a) {
  if (a is! int) {
    return a;
  } else {
    return 42;
  }
}

/*element: testIsCheck7:[subclass=JSInt]*/
testIsCheck7(/*[null|subclass=Object]*/ a) {
  if (a == 'foo' && a is int) {
    return a;
  } else {
    return 42;
  }
}

/*element: testIsCheck8:[null|subclass=Object]*/
testIsCheck8(/*[null|subclass=Object]*/ a) {
  if (a == 'foo' || a is int) {
    return a;
  } else {
    return 42;
  }
}

/*element: testIsCheck9:[subclass=JSInt]*/
testIsCheck9(/*[null|subclass=Object]*/ a) {
  return a is int ? a : 42;
}

/*element: testIsCheck10:[null|subclass=Object]*/
testIsCheck10(/*[null|subclass=Object]*/ a) {
  return a is! int ? a : 42;
}

/*element: testIsCheck11:[subclass=JSInt]*/
testIsCheck11(/*[null|subclass=Object]*/ a) {
  return a is! int ? 42 : a;
}

/*element: testIsCheck12:[null|subclass=Object]*/
testIsCheck12(/*[null|subclass=Object]*/ a) {
  return a is int ? 42 : a;
}

/*element: testIsCheck13:[subclass=JSInt]*/
testIsCheck13(/*[null|subclass=Object]*/ a) {
  while (a is int) {
    return a;
  }
  return 42;
}

/*element: testIsCheck14:[null|subclass=Object]*/
testIsCheck14(/*[null|subclass=Object]*/ a) {
  while (a is! int) {
    return 42;
  }
  return a;
}

// TODO(29309): Change to [subclass=JSInt] when 29309 is fixed.
/*element: testIsCheck15:[null|subclass=Object]*/
testIsCheck15(/*[null|subclass=Object]*/ a) {
  dynamic c = 42;
  do {
    if (a) return c;
    c = topLevelGetter();
  } while (c is int);
  return 42;
}

/*element: testIsCheck16:[null|subclass=Object]*/
testIsCheck16(/*[null|subclass=Object]*/ a) {
  dynamic c = 42;
  do {
    if (a) return c;
    c = topLevelGetter();
  } while (c is! int);
  return 42;
}

/*element: testIsCheck17:[subclass=JSInt]*/
testIsCheck17(/*[null|subclass=Object]*/ a) {
  dynamic c = 42;
  for (; c is int;) {
    if (a) return c;
    c = topLevelGetter();
  }
  return 42;
}

/*element: testIsCheck18:[null|subclass=Object]*/
testIsCheck18(/*[null|subclass=Object]*/ a) {
  dynamic c = 42;
  for (; c is int;) {
    if (a) return c;
    c = topLevelGetter();
  }
  return c;
}

/*element: testIsCheck19:[null|subclass=Object]*/
testIsCheck19(/*[null|subclass=Object]*/ a) {
  dynamic c = 42;
  for (; c is! int;) {
    if (a) return c;
    c = topLevelGetter();
  }
  return 42;
}

/*element: testIsCheck20:Union([exact=JSString], [exact=JSUInt31])*/
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

/*element: testIsCheck21:[null|subclass=Object]*/
testIsCheck21(/*[null|subclass=Object]*/ a) {
  if (a is int || a is List) {
    return a;
  } else {
    return 42;
  }
}

/*element: testIsCheck22:[null|subclass=Object]*/
testIsCheck22(/*[null|subclass=Object]*/ a) {
  return (a is int || a is List) ? a : 42;
}

/*element: testIsCheck23:[subclass=JSInt]*/
testIsCheck23(/*[null|subclass=Object]*/ a) {
  if (a is! int) throw 'foo';
  return a;
}

/*element: testIsCheck24:[subclass=JSInt]*/
testIsCheck24(/*[null|subclass=Object]*/ a) {
  if (a is! int) return 42;
  return a;
}

/*element: testIsCheck25:[null|subclass=Object]*/
testIsCheck25(/*[null|subclass=Object]*/ a) {
  if (a is int) throw 'foo';
  return a;
}

/*element: testIsCheck26:[subclass=JSInt]*/
testIsCheck26(/*[null|subclass=Object]*/ a) {
  if (a is int) {} else {
    throw 42;
  }
  return a;
}

/*element: testIsCheck27:[subclass=JSInt]*/
testIsCheck27(/*[null|subclass=Object]*/ a) {
  if (a is int) {} else {
    return 42;
  }
  return a;
}

/*element: testIsCheck28:[null|subclass=Object]*/
testIsCheck28(/*[null|subclass=Object]*/ a) {
  if (a is int) {} else {}
  return a;
}

/*element: testIsCheck29:[null|subclass=Object]*/
testIsCheck29(/*[null|subclass=Object]*/ a) {
  if (a is int) {}
  return a;
}

/*element: testIf1:[null|exact=JSUInt31]*/
testIf1(/*[null|subclass=Object]*/ a) {
  var c = null;
  if (a) {
    c = 10;
  } else {}
  return c;
}

/*element: testIf2:[null|exact=JSUInt31]*/
testIf2(/*[null|subclass=Object]*/ a) {
  var c = null;
  if (a) {} else {
    c = 10;
  }
  return c;
}

/*element: returnAsString:[null|exact=JSString]*/
returnAsString() {
  return topLevelGetter() as String;
}

/*element: returnIntAsNum:[exact=JSUInt31]*/
returnIntAsNum() {
  dynamic a = 0;
  return a as num;
}

typedef int Foo();

/*element: returnAsTypedef:[null|subclass=Closure]*/
returnAsTypedef() {
  return topLevelGetter() as Foo;
}

/*element: testDeadCode:[exact=JSUInt31]*/
testDeadCode() {
  return 42;
  // ignore: dead_code
  return 'foo';
}

/*element: testLabeledIf:[null|exact=JSUInt31]*/
testLabeledIf(/*Value([exact=JSBool], value: true)*/ a) {
  var c;
  L1:
  if (a /*invoke: Value([exact=JSBool], value: true)*/ > 1) {
    if (a /*invoke: [empty]*/ == 2) {
      break L1;
    }
    c = 42;
  } else {
    c = 38;
  }
  return c;
}

/*element: testSwitch1:Union([exact=JSUInt31], [null|exact=JSDouble])*/
testSwitch1() {
  var a = null;
  switch (topLevelGetter) {
    case 100:
      a = 42.5;
      break;
    case 200:
      a = 42;
      break;
  }
  return a;
}

/*element: testSwitch2:[exact=JSUInt31]*/
testSwitch2() {
  var a = null;
  switch (topLevelGetter) {
    case 100:
      a = 42;
      break;
    case 200:
      a = 42;
      break;
    default:
      a = 43;
  }
  return a;
}

/*element: testSwitch3:Union([null|exact=JSString], [subclass=JSNumber])*/
testSwitch3() {
  dynamic a = 42;
  var b;
  switch (topLevelGetter) {
    L1:
    case 1:
      b = a /*invoke: Union([exact=JSString], [exact=JSUInt31])*/ + 42;
      break;
    case 2:
      a = 'foo';
      continue L1;
  }
  return b;
}

/*element: testSwitch4:[exact=JSUInt31]*/
testSwitch4() {
  switch (topLevelGetter) {
    case 1:
      break;
    default:
      break;
  }
  return 42;
}

/*element: testSwitch5:[exact=JSUInt31]*/
testSwitch5() {
  switch (topLevelGetter) {
    case 1:
      return 1;
    default:
      return 2;
  }
}

/*element: testContinue1:Union([null|exact=JSString], [subclass=JSNumber])*/
testContinue1() {
  dynamic a = 42;
  var b;
  while (true) {
    b = a /*invoke: Union([exact=JSString], [exact=JSUInt31])*/ + 54;
    if (b /*invoke: Union([exact=JSString], [subclass=JSNumber])*/ == 42)
      continue;
    a = 'foo';
  }
  // ignore: dead_code
  return b;
}

/*element: testBreak1:Union([null|exact=JSString], [subclass=JSUInt32])*/
testBreak1() {
  var a = 42;
  var b;
  while (true) {
    b = a /*invoke: [exact=JSUInt31]*/ + 54;
    if (b /*invoke: [subclass=JSUInt32]*/ == 42) break;
    b = 'foo';
  }
  return b;
}

/*element: testContinue2:Union([exact=JSString], [null|subclass=JSUInt32])*/
testContinue2() {
  var a = 42;
  var b;
  while (true) {
    b = a /*invoke: [exact=JSUInt31]*/ + 54;
    if (b /*invoke: [subclass=JSUInt32]*/ == 42) {
      b = 'foo';
      continue;
    }
  }
  // ignore: dead_code
  return b;
}

/*element: testBreak2:[null|subclass=JSUInt32]*/
testBreak2() {
  dynamic a = 42;
  var b;
  while (true) {
    b = a /*invoke: [exact=JSUInt31]*/ + 54;
    if (b /*invoke: [subclass=JSUInt32]*/ == 42) {
      a = 'foo';
      break;
    }
  }
  return b;
}

/*element: testReturnElementOfConstList1:[exact=JSUInt31]*/
testReturnElementOfConstList1() {
  return const [
    42
  ] /*Container([exact=JSUnmodifiableArray], element: [exact=JSUInt31], length: 1)*/ [
      0];
}

/*element: testReturnElementOfConstList2:[exact=JSUInt31]*/
testReturnElementOfConstList2() {
  return topLevelConstList /*Container([exact=JSUnmodifiableArray], element: [exact=JSUInt31], length: 1)*/ [
      0];
}

/*element: testReturnItselfOrInt:[exact=JSUInt31]*/
testReturnItselfOrInt(/*[null|subclass=Object]*/ a) {
  if (a) return 42;
  return testReturnItselfOrInt(a);
}

/*element: testDoWhile1:Value([exact=JSString], value: "foo")*/
testDoWhile1() {
  dynamic a = 42;
  do {
    a = 'foo';
  } while (true);
  // ignore: dead_code
  return a;
}

/*element: testDoWhile2:[null]*/
testDoWhile2() {
  dynamic a = 42;
  do {
    a = 'foo';
    // ignore: mixed_return_types
    return;
  } while (true);
  // ignore: dead_code,mixed_return_types
  return a;
}

/*element: testDoWhile3:[exact=JSUInt31]*/
testDoWhile3() {
  dynamic a = 42;
  do {
    a = 'foo';
    if (true) continue;
    return 42;
  } while (true);
  // ignore: dead_code
  return a;
}

/*element: testDoWhile4:Union([exact=JSDouble], [exact=JSUInt31])*/
testDoWhile4() {
  dynamic a = 'foo';
  do {
    a = 54;
    if (true) break;
    return 3.5;
  } while (true);
  return a;
}

/*element: testSpecialization1:[subclass=JSNumber]*/
testSpecialization1() {
  var a = topLevelGetter();
  a - 42;
  return a;
}

/*element: testSpecialization2:[null|subclass=Object]*/
testSpecialization2() {
  var a = topLevelGetter();
  // Make [a] a captured variable. This should disable receiver
  // specialization on [a].
  (/*kernel.[null|subclass=Object]*/
      /*strong.[null|exact=JSString]*/
      () => a.toString())();
  a - 42;
  return a;
}

/*element: testSpecialization3:[null|exact=JSUInt31]*/
testSpecialization3() {
  var a = returnDynamic() ? null : 42;
  a. /*invoke: [null|exact=JSUInt31]*/ toString();
  // Test that calling an [Object] method on [a] will not lead to
  // infer that [a] is not null;
  return a;
}

/*element: testReturnNull1:[null]*/
testReturnNull1(/*[null|subclass=Object]*/ a) {
  if (a == null) return a;
  return null;
}

/*element: testReturnNull2:[null]*/
testReturnNull2(/*[null|subclass=Object]*/ a) {
  if (a != null) return null;
  return a;
}

/*element: testReturnNull3:[null|subclass=Object]*/
testReturnNull3(/*[null|subclass=Object]*/ a) {
  if (a == null) return 42;
  return a;
}

/*element: testReturnNull4:[null]*/
testReturnNull4() {
  var a = topLevelGetter();
  if (a == null) return a;
  return null;
}

/*element: testReturnNull5:[null]*/
testReturnNull5() {
  var a = topLevelGetter();
  if (a != null) return null;
  return a;
}

/*element: testReturnNull6:[null|subclass=Object]*/
testReturnNull6() {
  var a = topLevelGetter();
  if (a == null) return 42;
  return a;
}

/*element: testReturnNotEquals:[exact=JSBool]*/
testReturnNotEquals() {
  return new A() /*invoke: [exact=A]*/ != 54;
}

/*element: testReturnInvokeDynamicGetter:[null|subclass=Object]*/
testReturnInvokeDynamicGetter() => new A(). /*invoke: [exact=A]*/ myFactory();

/*element: topLevelConstList:Container([exact=JSUnmodifiableArray], element: [exact=JSUInt31], length: 1)*/
var topLevelConstList = const [42];

/*element: topLevelGetter:[exact=JSUInt31]*/
get topLevelGetter => 42;

/*element: returnDynamic:[null|subclass=Object]*/
returnDynamic() => topLevelGetter(42);

/*element: returnTopLevelGetter:[exact=JSUInt31]*/
returnTopLevelGetter() => topLevelGetter;

class A {
  factory A() = A.generative;

  /*element: A.generative:[exact=A]*/
  A.generative();

  /*kernel.element: A.==:Union([exact=JSBool], [exact=JSUInt31])*/
  /*strong.element: A.==:[exact=JSBool]*/
  operator ==(/*Union([exact=JSString], [exact=JSUInt31])*/ other) =>
      42 as dynamic;

  /*element: A.myField:[exact=JSUInt31]*/
  get myField => 42;

  set myField(/*[subclass=JSUInt32]*/ a) {}

  /*element: A.returnInt1:[subclass=JSUInt32]*/
  returnInt1() => /*invoke: [exact=JSUInt31]*/ ++ /*[subclass=A]*/ /*update: [subclass=A]*/ myField;

  /*element: A.returnInt2:[subclass=JSUInt32]*/
  returnInt2() => /*invoke: [exact=JSUInt31]*/ ++this
      . /*[subclass=A]*/ /*update: [subclass=A]*/ myField;

  /*element: A.returnInt3:[subclass=JSUInt32]*/
  returnInt3() =>
      this. /*[subclass=A]*/ /*update: [subclass=A]*/ myField /*invoke: [exact=JSUInt31]*/ +=
          42;

  /*element: A.returnInt4:[subclass=JSUInt32]*/
  returnInt4() => /*[subclass=A]*/ /*update: [subclass=A]*/ myField /*invoke: [exact=JSUInt31]*/ +=
      42;

  /*element: A.[]:[exact=JSUInt31]*/
  operator [](/*[exact=JSUInt31]*/ index) => 42;

  /*element: A.[]=:[null]*/
  operator []=(/*[exact=JSUInt31]*/ index, /*[subclass=JSUInt32]*/ value) {}

  /*element: A.returnInt5:[subclass=JSUInt32]*/
  returnInt5() => /*invoke: [exact=JSUInt31]*/ ++this /*[subclass=A]*/ /*update: [subclass=A]*/ [
      0];

  /*element: A.returnInt6:[subclass=JSUInt32]*/
  returnInt6() => this /*[subclass=A]*/ /*update: [subclass=A]*/ [
      0] /*invoke: [exact=JSUInt31]*/ += 1;

  /*element: A.myFactory:[subclass=Closure]*/
  get myFactory => /*[exact=JSUInt31]*/ () => 42;
}

class B extends A {
  /*element: B.:[exact=B]*/
  B() : super.generative();

  /*element: B.returnInt1:[subclass=JSUInt32]*/
  returnInt1() => /*invoke: [exact=JSUInt31]*/ ++new A()
      . /*[exact=A]*/ /*update: [exact=A]*/ myField;

  /*element: B.returnInt2:[subclass=JSUInt32]*/
  returnInt2() => new A()
      . /*[exact=A]*/ /*update: [exact=A]*/ myField /*invoke: [exact=JSUInt31]*/ += 4;

  /*element: B.returnInt3:[subclass=JSUInt32]*/
  returnInt3() => /*invoke: [exact=JSUInt31]*/ ++new A() /*[exact=A]*/ /*update: [exact=A]*/ [
      0];

  /*element: B.returnInt4:[subclass=JSUInt32]*/
  returnInt4() => new A() /*[exact=A]*/ /*update: [exact=A]*/ [
      0] /*invoke: [exact=JSUInt31]*/ += 42;

  /*element: B.returnInt5:[subclass=JSUInt32]*/
  returnInt5() => /*invoke: [exact=JSUInt31]*/ ++super.myField;

  /*element: B.returnInt6:[subclass=JSUInt32]*/
  returnInt6() => super.myField /*invoke: [exact=JSUInt31]*/ += 4;

  /*element: B.returnInt7:[subclass=JSUInt32]*/
  returnInt7() => /*invoke: [exact=JSUInt31]*/ ++super[0];

  /*element: B.returnInt8:[subclass=JSUInt32]*/
  returnInt8() => super[0] /*invoke: [exact=JSUInt31]*/ += 54;

  /*element: B.returnInt9:[exact=JSUInt31]*/
  returnInt9() => super.myField;
}

class C {
  /*element: C.myField:[subclass=JSPositiveInt]*/
  var myField = 42;

  /*element: C.:[exact=C]*/
  C();

  /*element: C.returnInt1:[subclass=JSPositiveInt]*/
  returnInt1() => /*invoke: [subclass=JSPositiveInt]*/ ++ /*[exact=C]*/ /*update: [exact=C]*/ myField;

  /*element: C.returnInt2:[subclass=JSPositiveInt]*/
  returnInt2() => /*invoke: [subclass=JSPositiveInt]*/ ++this
      . /*[exact=C]*/ /*update: [exact=C]*/ myField;

  /*element: C.returnInt3:[subclass=JSPositiveInt]*/
  returnInt3() =>
      this. /*[exact=C]*/ /*update: [exact=C]*/ myField /*invoke: [subclass=JSPositiveInt]*/ +=
          42;

  /*element: C.returnInt4:[subclass=JSPositiveInt]*/
  returnInt4() => /*[exact=C]*/ /*update: [exact=C]*/ myField /*invoke: [subclass=JSPositiveInt]*/ +=
      42;

  /*element: C.[]:[subclass=JSPositiveInt]*/
  operator [](/*[exact=JSUInt31]*/ index) => /*[exact=C]*/ myField;

  /*element: C.[]=:[null]*/
  operator []=(
      /*[exact=JSUInt31]*/ index,
      /*[subclass=JSPositiveInt]*/ value) {}

  /*element: C.returnInt5:[subclass=JSPositiveInt]*/
  returnInt5() => /*invoke: [subclass=JSPositiveInt]*/ ++this /*[exact=C]*/ /*update: [exact=C]*/ [
      0];

  /*element: C.returnInt6:[subclass=JSPositiveInt]*/
  returnInt6() => this /*[exact=C]*/ /*update: [exact=C]*/ [
      0] /*invoke: [subclass=JSPositiveInt]*/ += 1;
}

/*element: testCascade1:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: null)*/
testCascade1() {
  return [1, 2, 3]
    .. /*invoke: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: null)*/
        add(4)
    .. /*invoke: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: null)*/
        add(5);
}

/*element: testCascade2:[exact=CascadeHelper]*/
testCascade2() {
  return new CascadeHelper()
    .. /*update: [exact=CascadeHelper]*/ a = "hello"
    .. /*update: [exact=CascadeHelper]*/ b = 42
    .. /*[exact=CascadeHelper]*/ /*update: [exact=CascadeHelper]*/ i
        /*invoke: [subclass=JSPositiveInt]*/ += 1;
}

/*element: CascadeHelper.:[exact=CascadeHelper]*/
class CascadeHelper {
  /*element: CascadeHelper.a:Value([null|exact=JSString], value: "hello")*/
  var a;

  /*element: CascadeHelper.b:[null|exact=JSUInt31]*/
  var b;

  /*element: CascadeHelper.i:[subclass=JSPositiveInt]*/
  var i = 0;
}

/*element: main:[null]*/
main() {
  // Ensure a function class is being instantiated.
  /*[exact=JSUInt31]*/ () => 42;
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
  new A()
    .. /*invoke: [exact=A]*/ returnInt1()
    .. /*invoke: [exact=A]*/ returnInt2()
    .. /*invoke: [exact=A]*/ returnInt3()
    .. /*invoke: [exact=A]*/ returnInt4()
    .. /*invoke: [exact=A]*/ returnInt5()
    .. /*invoke: [exact=A]*/ returnInt6();

  new B()
    .. /*invoke: [exact=B]*/ returnInt1()
    .. /*invoke: [exact=B]*/ returnInt2()
    .. /*invoke: [exact=B]*/ returnInt3()
    .. /*invoke: [exact=B]*/ returnInt4()
    .. /*invoke: [exact=B]*/ returnInt5()
    .. /*invoke: [exact=B]*/ returnInt6()
    .. /*invoke: [exact=B]*/ returnInt7()
    .. /*invoke: [exact=B]*/ returnInt8()
    .. /*invoke: [exact=B]*/ returnInt9();

  new C()
    .. /*invoke: [exact=C]*/ returnInt1()
    .. /*invoke: [exact=C]*/ returnInt2()
    .. /*invoke: [exact=C]*/ returnInt3()
    .. /*invoke: [exact=C]*/ returnInt4()
    .. /*invoke: [exact=C]*/ returnInt5()
    .. /*invoke: [exact=C]*/ returnInt6();
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
