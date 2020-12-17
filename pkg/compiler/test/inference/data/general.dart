// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: returnNum1:Union([exact=JSDouble], [exact=JSUInt31])*/
returnNum1(/*Value([exact=JSBool], value: true)*/ a) {
  if (a)
    return 1;
  else
    return 2.5;
}

/*member: returnNum2:Union([exact=JSDouble], [exact=JSUInt31])*/
returnNum2(/*Value([exact=JSBool], value: true)*/ a) {
  if (a)
    return 1.4;
  else
    return 2;
}

/*member: returnInt1:[exact=JSUInt31]*/
returnInt1(/*Value([exact=JSBool], value: true)*/ a) {
  if (a)
    return 1;
  else
    return 2;
}

/*member: returnDouble:[exact=JSDouble]*/
returnDouble(/*Value([exact=JSBool], value: true)*/ a) {
  if (a)
    return 1.5;
  else
    return 2.5;
}

/*member: returnGiveUp:Union([exact=JSString], [exact=JSUInt31])*/
returnGiveUp(/*Value([exact=JSBool], value: true)*/ a) {
  if (a)
    return 1;
  else
    return 'foo';
}

/*member: returnInt2:[exact=JSUInt31]*/
returnInt2() {
  var a = 42;
  return a /*invoke: [exact=JSUInt31]*/ ++;
}

/*member: returnInt5:[subclass=JSUInt32]*/
returnInt5() {
  var a = 42;
  return /*invoke: [exact=JSUInt31]*/ ++a;
}

/*member: returnInt6:[subclass=JSUInt32]*/
returnInt6() {
  var a = 42;
  a /*invoke: [exact=JSUInt31]*/ ++;
  return a;
}

/*member: returnIntOrNull:[null|exact=JSUInt31]*/
returnIntOrNull(/*Value([exact=JSBool], value: true)*/ a) {
  if (a) return 42;
}

/*member: returnInt3:[exact=JSUInt31]*/
returnInt3(/*Value([exact=JSBool], value: true)*/ a) {
  if (a) return 42;
  throw 42;
}

/*member: returnInt4:[exact=JSUInt31]*/
returnInt4() {
  return (42);
}

/*member: returnInt7:[subclass=JSPositiveInt]*/
returnInt7() {
  return 42. /*invoke: [exact=JSUInt31]*/ abs();
}

/*member: returnInt8:[subclass=JSPositiveInt]*/
returnInt8() {
  return 42. /*invoke: [exact=JSUInt31]*/ remainder(54);
}

/*member: returnEmpty1:[empty]*/
returnEmpty1() {
  // Ensure that we don't intrisify a wrong call to [int.remainder].
  dynamic a = 42;
  return a. /*invoke: [exact=JSUInt31]*/ remainder();
}

/*member: returnEmpty2:[empty]*/
returnEmpty2() {
  // Ensure that we don't intrisify a wrong call to [int.abs].
  dynamic a = 42;
  return a. /*invoke: [exact=JSUInt31]*/ abs(42);
}

/*member: testIsCheck1:[subclass=JSInt]*/
testIsCheck1(/*[null|subclass=Object]*/ a) {
  if (a is int) {
    return a;
  } else {
    return 42;
  }
}

/*member: testIsCheck2:[subclass=JSInt]*/
testIsCheck2(/*[null|subclass=Object]*/ a) {
  if (a is! int) {
    return 0;
  } else {
    return a;
  }
}

/*member: testIsCheck3:[null|subclass=JSInt]*/
testIsCheck3(/*[null|subclass=Object]*/ a) {
  if (a is! int) {
    print('hello');
  } else {
    return a;
  }
}

/*member: testIsCheck4:[subclass=JSInt]*/
testIsCheck4(/*[null|subclass=Object]*/ a) {
  if (a is int) {
    return a;
  } else {
    return 42;
  }
}

/*member: testIsCheck5:[subclass=JSInt]*/
testIsCheck5(/*[null|subclass=Object]*/ a) {
  if (a is! int) {
    return 42;
  } else {
    return a;
  }
}

/*member: testIsCheck6:[null|subclass=Object]*/
testIsCheck6(/*[null|subclass=Object]*/ a) {
  if (a is! int) {
    return a;
  } else {
    return 42;
  }
}

/*member: testIsCheck7:[subclass=JSInt]*/
testIsCheck7(/*[null|subclass=Object]*/ a) {
  if (a == 'foo' && a is int) {
    return a;
  } else {
    return 42;
  }
}

/*member: testIsCheck8:[null|subclass=Object]*/
testIsCheck8(/*[null|subclass=Object]*/ a) {
  if (a == 'foo' || a is int) {
    return a;
  } else {
    return 42;
  }
}

/*member: testIsCheck9:[subclass=JSInt]*/
testIsCheck9(/*[null|subclass=Object]*/ a) {
  return a is int ? a : 42;
}

/*member: testIsCheck10:[null|subclass=Object]*/
testIsCheck10(/*[null|subclass=Object]*/ a) {
  return a is! int ? a : 42;
}

/*member: testIsCheck11:[subclass=JSInt]*/
testIsCheck11(/*[null|subclass=Object]*/ a) {
  return a is! int ? 42 : a;
}

/*member: testIsCheck12:[null|subclass=Object]*/
testIsCheck12(/*[null|subclass=Object]*/ a) {
  return a is int ? 42 : a;
}

/*member: testIsCheck13:[subclass=JSInt]*/
testIsCheck13(/*[null|subclass=Object]*/ a) {
  while (a is int) {
    return a;
  }
  return 42;
}

/*member: testIsCheck14:[null|subclass=Object]*/
testIsCheck14(/*[null|subclass=Object]*/ a) {
  while (a is! int) {
    return 42;
  }
  return a;
}

// TODO(29309): Change to [subclass=JSInt] when 29309 is fixed.
/*member: testIsCheck15:[null|subclass=Object]*/
testIsCheck15(/*[null|subclass=Object]*/ a) {
  dynamic c = 42;
  do {
    if (a) return c;
    c = topLevelGetter();
  } while (c is int);
  return 42;
}

/*member: testIsCheck16:[null|subclass=Object]*/
testIsCheck16(/*[null|subclass=Object]*/ a) {
  dynamic c = 42;
  do {
    if (a) return c;
    c = topLevelGetter();
  } while (c is! int);
  return 42;
}

/*member: testIsCheck17:[subclass=JSInt]*/
testIsCheck17(/*[null|subclass=Object]*/ a) {
  dynamic c = 42;
  for (; c is int;) {
    if (a) return c;
    c = topLevelGetter();
  }
  return 42;
}

/*member: testIsCheck18:[null|subclass=Object]*/
testIsCheck18(/*[null|subclass=Object]*/ a) {
  dynamic c = 42;
  for (; c is int;) {
    if (a) return c;
    c = topLevelGetter();
  }
  return c;
}

/*member: testIsCheck19:[null|subclass=Object]*/
testIsCheck19(/*[null|subclass=Object]*/ a) {
  dynamic c = 42;
  for (; c is! int;) {
    if (a) return c;
    c = topLevelGetter();
  }
  return 42;
}

/*member: testIsCheck20:[exact=JSUInt31]*/
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

/*member: testIsCheck21:Union([subclass=JSArray], [subclass=JSInt])*/
testIsCheck21(/*[null|subclass=Object]*/ a) {
  if (a is int || a is List) {
    return a;
  } else {
    return 42;
  }
}

/*member: testIsCheck22:Union([subclass=JSArray], [subclass=JSInt])*/
testIsCheck22(/*[null|subclass=Object]*/ a) {
  return (a is int || a is List) ? a : 42;
}

/*member: testIsCheck23:[subclass=JSInt]*/
testIsCheck23(/*[null|subclass=Object]*/ a) {
  if (a is! int) throw 'foo';
  return a;
}

/*member: testIsCheck24:[subclass=JSInt]*/
testIsCheck24(/*[null|subclass=Object]*/ a) {
  if (a is! int) return 42;
  return a;
}

/*member: testIsCheck25:[null|subclass=Object]*/
testIsCheck25(/*[null|subclass=Object]*/ a) {
  if (a is int) throw 'foo';
  return a;
}

/*member: testIsCheck26:[subclass=JSInt]*/
testIsCheck26(/*[null|subclass=Object]*/ a) {
  if (a is int) {
  } else {
    throw 42;
  }
  return a;
}

/*member: testIsCheck27:[subclass=JSInt]*/
testIsCheck27(/*[null|subclass=Object]*/ a) {
  if (a is int) {
  } else {
    return 42;
  }
  return a;
}

/*member: testIsCheck28:[null|subclass=Object]*/
testIsCheck28(/*[null|subclass=Object]*/ a) {
  if (a is int) {
  } else {}
  return a;
}

/*member: testIsCheck29:[null|subclass=Object]*/
testIsCheck29(/*[null|subclass=Object]*/ a) {
  if (a is int) {}
  return a;
}

/*member: testIf1:[null|exact=JSUInt31]*/
testIf1(/*[null|subclass=Object]*/ a) {
  var c = null;
  if (a) {
    c = 10;
  } else {}
  return c;
}

/*member: testIf2:[null|exact=JSUInt31]*/
testIf2(/*[null|subclass=Object]*/ a) {
  var c = null;
  if (a) {
  } else {
    c = 10;
  }
  return c;
}

/*member: returnAsString:[null|exact=JSString]*/
returnAsString() {
  return topLevelGetter() as String;
}

/*member: returnIntAsNum:[exact=JSUInt31]*/
returnIntAsNum() {
  dynamic a = 0;
  return a as num;
}

typedef int Foo();

/*member: returnAsTypedef:[null|subclass=Closure]*/
returnAsTypedef() {
  return topLevelGetter() as Foo;
}

/*member: testDeadCode:[exact=JSUInt31]*/
testDeadCode() {
  return 42;
  // ignore: dead_code
  return 'foo';
}

/*member: testLabeledIf:[null|exact=JSUInt31]*/
testLabeledIf(/*Value([exact=JSBool], value: true)*/ a) {
  var c;
  L1:
  if (a /*invoke: Value([exact=JSBool], value: true)*/ > 1) {
    if (a /*invoke: Value([exact=JSBool], value: true)*/ == 2) {
      break L1;
    }
    c = 42;
  } else {
    c = 38;
  }
  return c;
}

/*member: testSwitch1:Union(null, [exact=JSDouble], [exact=JSUInt31])*/
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

/*member: testSwitch2:[exact=JSUInt31]*/
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

/*member: testSwitch3:Union(null, [exact=JSString], [subclass=JSNumber])*/
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

/*member: testSwitch4:[exact=JSUInt31]*/
testSwitch4() {
  switch (topLevelGetter) {
    case 1:
      break;
    default:
      break;
  }
  return 42;
}

/*member: testSwitch5:[exact=JSUInt31]*/
testSwitch5() {
  switch (topLevelGetter) {
    case 1:
      return 1;
    default:
      return 2;
  }
}

/*member: testContinue1:Union(null, [exact=JSString], [subclass=JSNumber])*/
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

/*member: testBreak1:Union(null, [exact=JSString], [subclass=JSUInt32])*/
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

/*member: testContinue2:Union(null, [exact=JSString], [subclass=JSUInt32])*/
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

/*member: testBreak2:[null|subclass=JSUInt32]*/
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

/*member: testReturnElementOfConstList1:[exact=JSUInt31]*/
testReturnElementOfConstList1() {
  return const [
    42
  ] /*Container([exact=JSUnmodifiableArray], element: [exact=JSUInt31], length: 1)*/ [
      0];
}

/*member: testReturnElementOfConstList2:[exact=JSUInt31]*/
testReturnElementOfConstList2() {
  return topLevelConstList /*Container([exact=JSUnmodifiableArray], element: [exact=JSUInt31], length: 1)*/ [
      0];
}

/*member: testReturnItselfOrInt:[exact=JSUInt31]*/
testReturnItselfOrInt(/*[null|subclass=Object]*/ a) {
  if (a) return 42;
  return testReturnItselfOrInt(a);
}

/*member: testDoWhile1:Value([exact=JSString], value: "foo")*/
testDoWhile1() {
  dynamic a = 42;
  do {
    a = 'foo';
  } while (true);
  // ignore: dead_code
  return a;
}

/*member: testDoWhile2:[null]*/
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

/*member: testDoWhile3:[exact=JSUInt31]*/
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

/*member: testDoWhile4:Union([exact=JSDouble], [exact=JSUInt31])*/
testDoWhile4() {
  dynamic a = 'foo';
  do {
    a = 54;
    if (true) break;
    return 3.5;
  } while (true);
  return a;
}

/*member: testSpecialization1:[subclass=Object]*/
testSpecialization1() {
  var a = topLevelGetter();
  a - 42;
  return a;
}

/*member: testSpecialization2:[null|subclass=Object]*/
testSpecialization2() {
  var a = topLevelGetter();
  // Make [a] a captured variable. This should disable receiver
  // specialization on [a].
  (
      /*[null|exact=JSString]*/
      () => a.toString())();
  a - 42;
  return a;
}

/*member: testSpecialization3:[null|exact=JSUInt31]*/
testSpecialization3() {
  var a = returnDynamic() ? null : 42;
  a. /*invoke: [null|exact=JSUInt31]*/ toString();
  // Test that calling an [Object] method on [a] will not lead to
  // infer that [a] is not null;
  return a;
}

/*member: testReturnNull1:[null]*/
testReturnNull1(/*[null|subclass=Object]*/ a) {
  if (a == null) return a;
  return null;
}

/*member: testReturnNull2:[null]*/
testReturnNull2(/*[null|subclass=Object]*/ a) {
  if (a != null) return null;
  return a;
}

/*member: testReturnNull3:[subclass=Object]*/
testReturnNull3(/*[null|subclass=Object]*/ a) {
  if (a == null) return 42;
  return a;
}

/*member: testReturnNull4:[null]*/
testReturnNull4() {
  var a = topLevelGetter();
  if (a == null) return a;
  return null;
}

/*member: testReturnNull5:[null]*/
testReturnNull5() {
  var a = topLevelGetter();
  if (a != null) return null;
  return a;
}

/*member: testReturnNull6:[subclass=Object]*/
testReturnNull6() {
  var a = topLevelGetter();
  if (a == null) return 42;
  return a;
}

/*member: testReturnNotEquals:[exact=JSBool]*/
testReturnNotEquals() {
  return new A() /*invoke: [exact=A]*/ != 54;
}

/*member: testReturnInvokeDynamicGetter:[null|subclass=Object]*/
testReturnInvokeDynamicGetter() => new A().myFactory /*invoke: [exact=A]*/ ();

/*member: topLevelConstList:Container([exact=JSUnmodifiableArray], element: [exact=JSUInt31], length: 1)*/
var topLevelConstList = const [42];

/*member: topLevelGetter:[exact=JSUInt31]*/
get topLevelGetter => 42;

/*member: returnDynamic:[null|subclass=Object]*/
returnDynamic() => topLevelGetter(42);

/*member: returnTopLevelGetter:[exact=JSUInt31]*/
returnTopLevelGetter() => topLevelGetter;

class A {
  factory A() = A.generative;

  /*member: A.generative:[exact=A]*/
  A.generative();

  /*member: A.==:[exact=JSBool]*/
  operator ==(/*Union([exact=JSString], [exact=JSUInt31])*/ other) =>
      42 as dynamic;

  /*member: A.myField:[exact=JSUInt31]*/
  get myField => 42;

  set myField(/*[subclass=JSUInt32]*/ a) {}

  /*member: A.returnInt1:[subclass=JSUInt32]*/
  returnInt1() => /*invoke: [exact=JSUInt31]*/ ++ /*[subclass=A]*/ /*update: [subclass=A]*/ myField;

  /*member: A.returnInt2:[subclass=JSUInt32]*/
  returnInt2() => /*invoke: [exact=JSUInt31]*/ ++this
      . /*[subclass=A]*/ /*update: [subclass=A]*/ myField;

  /*member: A.returnInt3:[subclass=JSUInt32]*/
  returnInt3() =>
      this. /*[subclass=A]*/ /*update: [subclass=A]*/ myField /*invoke: [exact=JSUInt31]*/ +=
          42;

  /*member: A.returnInt4:[subclass=JSUInt32]*/
  returnInt4() => /*[subclass=A]*/ /*update: [subclass=A]*/ myField /*invoke: [exact=JSUInt31]*/ +=
      42;

  /*member: A.[]:[exact=JSUInt31]*/
  operator [](/*[exact=JSUInt31]*/ index) => 42;

  /*member: A.[]=:[null]*/
  operator []=(/*[exact=JSUInt31]*/ index, /*[subclass=JSUInt32]*/ value) {}

  /*member: A.returnInt5:[subclass=JSUInt32]*/
  returnInt5() => /*invoke: [exact=JSUInt31]*/ ++this /*[subclass=A]*/ /*update: [subclass=A]*/ [
      0];

  /*member: A.returnInt6:[subclass=JSUInt32]*/
  returnInt6() => this /*[subclass=A]*/ /*update: [subclass=A]*/ [
      0] /*invoke: [exact=JSUInt31]*/ += 1;

  /*member: A.myFactory:[subclass=Closure]*/
  get myFactory => /*[exact=JSUInt31]*/ () => 42;
}

class B extends A {
  /*member: B.:[exact=B]*/
  B() : super.generative();

  /*member: B.returnInt1:[subclass=JSUInt32]*/
  returnInt1() => /*invoke: [exact=JSUInt31]*/ ++new A()
      . /*[exact=A]*/ /*update: [exact=A]*/ myField;

  /*member: B.returnInt2:[subclass=JSUInt32]*/
  returnInt2() => new A()
      . /*[exact=A]*/ /*update: [exact=A]*/ myField /*invoke: [exact=JSUInt31]*/ += 4;

  /*member: B.returnInt3:[subclass=JSUInt32]*/
  returnInt3() => /*invoke: [exact=JSUInt31]*/ ++new A() /*[exact=A]*/ /*update: [exact=A]*/ [
      0];

  /*member: B.returnInt4:[subclass=JSUInt32]*/
  returnInt4() => new A() /*[exact=A]*/ /*update: [exact=A]*/ [
      0] /*invoke: [exact=JSUInt31]*/ += 42;

  /*member: B.returnInt5:[subclass=JSUInt32]*/
  returnInt5() => /*invoke: [exact=JSUInt31]*/ ++super.myField;

  /*member: B.returnInt6:[subclass=JSUInt32]*/
  returnInt6() => super.myField /*invoke: [exact=JSUInt31]*/ += 4;

  /*member: B.returnInt7:[subclass=JSUInt32]*/
  returnInt7() => /*invoke: [exact=JSUInt31]*/ ++super[0];

  /*member: B.returnInt8:[subclass=JSUInt32]*/
  returnInt8() => super[0] /*invoke: [exact=JSUInt31]*/ += 54;

  /*member: B.returnInt9:[exact=JSUInt31]*/
  returnInt9() => super.myField;
}

class C {
  /*member: C.myField:[subclass=JSPositiveInt]*/
  var myField = 42;

  /*member: C.:[exact=C]*/
  C();

  /*member: C.returnInt1:[subclass=JSPositiveInt]*/
  returnInt1() => /*invoke: [subclass=JSPositiveInt]*/ ++ /*update: [exact=C]*/ /*[exact=C]*/ myField;

  /*member: C.returnInt2:[subclass=JSPositiveInt]*/
  returnInt2() => /*invoke: [subclass=JSPositiveInt]*/ ++this
      . /*[exact=C]*/ /*update: [exact=C]*/ myField;

  /*member: C.returnInt3:[subclass=JSPositiveInt]*/
  returnInt3() =>
      this. /*[exact=C]*/ /*update: [exact=C]*/ myField /*invoke: [subclass=JSPositiveInt]*/ +=
          42;

  /*member: C.returnInt4:[subclass=JSPositiveInt]*/
  returnInt4() => /*[exact=C]*/ /*update: [exact=C]*/ myField /*invoke: [subclass=JSPositiveInt]*/ +=
      42;

  /*member: C.[]:[subclass=JSPositiveInt]*/
  operator [](/*[exact=JSUInt31]*/ index) => /*[exact=C]*/ myField;

  /*member: C.[]=:[null]*/
  operator []=(
      /*[exact=JSUInt31]*/ index,
      /*[subclass=JSPositiveInt]*/ value) {}

  /*member: C.returnInt5:[subclass=JSPositiveInt]*/
  returnInt5() => /*invoke: [subclass=JSPositiveInt]*/ ++this /*[exact=C]*/ /*update: [exact=C]*/ [
      0];

  /*member: C.returnInt6:[subclass=JSPositiveInt]*/
  returnInt6() => this /*[exact=C]*/ /*update: [exact=C]*/ [
      0] /*invoke: [subclass=JSPositiveInt]*/ += 1;
}

/*member: testCascade1:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: null)*/
testCascade1() {
  return [1, 2, 3]
    .. /*invoke: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: null)*/
        add(4)
    .. /*invoke: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: null)*/
        add(5);
}

/*member: testCascade2:[exact=CascadeHelper]*/
testCascade2() {
  return new CascadeHelper()
    .. /*update: [exact=CascadeHelper]*/ a = "hello"
    .. /*update: [exact=CascadeHelper]*/ b = 42
    .. /*[exact=CascadeHelper]*/ i
        /*invoke: [subclass=JSPositiveInt]*/ /*update: [exact=CascadeHelper]*/ +=
        1;
}

/*member: CascadeHelper.:[exact=CascadeHelper]*/
class CascadeHelper {
  /*member: CascadeHelper.a:Value([null|exact=JSString], value: "hello")*/
  var a;

  /*member: CascadeHelper.b:[null|exact=JSUInt31]*/
  var b;

  /*member: CascadeHelper.i:[subclass=JSPositiveInt]*/
  var i = 0;
}

/*member: main:[null]*/
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
  new A() /*invoke: [null|subclass=A]*/ == null;
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
