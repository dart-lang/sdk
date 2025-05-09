// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: returnNum1:Union([exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N})*/
returnNum1(
  /*Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/ a,
) {
  if (a)
    return 1;
  else
    return 2.5;
}

/*member: returnNum2:Union([exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N})*/
returnNum2(
  /*Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/ a,
) {
  if (a)
    return 1.4;
  else
    return 2;
}

/*member: returnInt1:[exact=JSUInt31|powerset={I}{O}{N}]*/
returnInt1(
  /*Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/ a,
) {
  if (a)
    return 1;
  else
    return 2;
}

/*member: returnDouble:[exact=JSNumNotInt|powerset={I}{O}{N}]*/
returnDouble(
  /*Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/ a,
) {
  if (a)
    return 1.5;
  else
    return 2.5;
}

/*member: returnGiveUp:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
returnGiveUp(
  /*Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/ a,
) {
  if (a)
    return 1;
  else
    return 'foo';
}

/*member: returnInt2:[exact=JSUInt31|powerset={I}{O}{N}]*/
returnInt2() {
  var a = 42;
  return a /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ ++;
}

/*member: returnInt5:[subclass=JSUInt32|powerset={I}{O}{N}]*/
returnInt5() {
  var a = 42;
  return /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ ++a;
}

/*member: returnInt6:[subclass=JSUInt32|powerset={I}{O}{N}]*/
returnInt6() {
  var a = 42;
  a /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ ++;
  return a;
}

/*member: returnIntOrNull:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
returnIntOrNull(
  /*Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/ a,
) {
  if (a) return 42;
}

/*member: returnInt3:[exact=JSUInt31|powerset={I}{O}{N}]*/
returnInt3(
  /*Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/ a,
) {
  if (a) return 42;
  throw 42;
}

/*member: returnInt4:[exact=JSUInt31|powerset={I}{O}{N}]*/
returnInt4() {
  return (42);
}

/*member: returnInt7:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
returnInt7() {
  return 42. /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ abs();
}

/*member: returnInt8:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
returnInt8() {
  return 42. /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ remainder(54);
}

/*member: returnEmpty1:[empty|powerset=empty]*/
returnEmpty1() {
  // Ensure that we don't intrinsify a wrong call to [int.remainder].
  dynamic a = 42;
  return a. /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ remainder();
}

/*member: returnEmpty2:[empty|powerset=empty]*/
returnEmpty2() {
  // Ensure that we don't intrinsify a wrong call to [int.abs].
  dynamic a = 42;
  return a. /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ abs(42);
}

/*member: testIsCheck1:[subclass=JSInt|powerset={I}{O}{N}]*/
testIsCheck1(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  if (a is int) {
    return a;
  } else {
    return 42;
  }
}

/*member: testIsCheck2:[subclass=JSInt|powerset={I}{O}{N}]*/
testIsCheck2(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  if (a is! int) {
    return 0;
  } else {
    return a;
  }
}

/*member: testIsCheck3:[null|subclass=JSInt|powerset={null}{I}{O}{N}]*/
testIsCheck3(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  if (a is! int) {
    print('hello');
  } else {
    return a;
  }
}

/*member: testIsCheck4:[subclass=JSInt|powerset={I}{O}{N}]*/
testIsCheck4(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  if (a is int) {
    return a;
  } else {
    return 42;
  }
}

/*member: testIsCheck5:[subclass=JSInt|powerset={I}{O}{N}]*/
testIsCheck5(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  if (a is! int) {
    return 42;
  } else {
    return a;
  }
}

/*member: testIsCheck6:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
testIsCheck6(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  if (a is! int) {
    return a;
  } else {
    return 42;
  }
}

/*member: testIsCheck7:[subclass=JSInt|powerset={I}{O}{N}]*/
testIsCheck7(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  if (a == 'foo' && a is int) {
    return a;
  } else {
    return 42;
  }
}

/*member: testIsCheck8:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
testIsCheck8(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  if (a == 'foo' || a is int) {
    return a;
  } else {
    return 42;
  }
}

/*member: testIsCheck9:[subclass=JSInt|powerset={I}{O}{N}]*/
testIsCheck9(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  return a is int ? a : 42;
}

/*member: testIsCheck10:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
testIsCheck10(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  return a is! int ? a : 42;
}

/*member: testIsCheck11:[subclass=JSInt|powerset={I}{O}{N}]*/
testIsCheck11(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  return a is! int ? 42 : a;
}

/*member: testIsCheck12:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
testIsCheck12(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  return a is int ? 42 : a;
}

/*member: testIsCheck13:[subclass=JSInt|powerset={I}{O}{N}]*/
testIsCheck13(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  while (a is int) {
    return a;
  }
  return 42;
}

/*member: testIsCheck14:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
testIsCheck14(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  while (a is! int) {
    return 42;
  }
  return a;
}

// TODO(29309): Change to [subclass=JSInt] when 29309 is fixed.
/*member: testIsCheck15:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
testIsCheck15(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  dynamic c = 42;
  do {
    if (a) return c;
    c = topLevelGetter();
  } while (c is int);
  return 42;
}

/*member: testIsCheck16:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
testIsCheck16(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  dynamic c = 42;
  do {
    if (a) return c;
    c = topLevelGetter();
  } while (c is! int);
  return 42;
}

/*member: testIsCheck17:[subclass=JSInt|powerset={I}{O}{N}]*/
testIsCheck17(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  dynamic c = 42;
  for (; c is int;) {
    if (a) return c;
    c = topLevelGetter();
  }
  return 42;
}

/*member: testIsCheck18:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
testIsCheck18(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  dynamic c = 42;
  for (; c is int;) {
    if (a) return c;
    c = topLevelGetter();
  }
  return c;
}

/*member: testIsCheck19:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
testIsCheck19(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  dynamic c = 42;
  for (; c is! int;) {
    if (a) return c;
    c = topLevelGetter();
  }
  return 42;
}

/*member: testIsCheck20:[exact=JSUInt31|powerset={I}{O}{N}]*/
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

/*member: testIsCheck21:Union([subclass=JSArray|powerset={I}{GFU}{IM}], [subclass=JSInt|powerset={I}{O}{N}], powerset: {I}{GFUO}{IMN})*/
testIsCheck21(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  if (a is int || a is List) {
    return a;
  } else {
    return 42;
  }
}

/*member: testIsCheck22:Union([subclass=JSArray|powerset={I}{GFU}{IM}], [subclass=JSInt|powerset={I}{O}{N}], powerset: {I}{GFUO}{IMN})*/
testIsCheck22(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  return (a is int || a is List) ? a : 42;
}

/*member: testIsCheck23:[subclass=JSInt|powerset={I}{O}{N}]*/
testIsCheck23(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  if (a is! int) throw 'foo';
  return a;
}

/*member: testIsCheck24:[subclass=JSInt|powerset={I}{O}{N}]*/
testIsCheck24(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  if (a is! int) return 42;
  return a;
}

/*member: testIsCheck25:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
testIsCheck25(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  if (a is int) throw 'foo';
  return a;
}

/*member: testIsCheck26:[subclass=JSInt|powerset={I}{O}{N}]*/
testIsCheck26(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  if (a is int) {
  } else {
    throw 42;
  }
  return a;
}

/*member: testIsCheck27:[subclass=JSInt|powerset={I}{O}{N}]*/
testIsCheck27(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  if (a is int) {
  } else {
    return 42;
  }
  return a;
}

/*member: testIsCheck28:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
testIsCheck28(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  if (a is int) {
  } else {}
  return a;
}

/*member: testIsCheck29:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
testIsCheck29(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  if (a is int) {}
  return a;
}

/*member: testIf1:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
testIf1(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  var c = null;
  if (a) {
    c = 10;
  } else {}
  return c;
}

/*member: testIf2:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
testIf2(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  var c = null;
  if (a) {
  } else {
    c = 10;
  }
  return c;
}

/*member: returnAsString:[exact=JSString|powerset={I}{O}{I}]*/
returnAsString() {
  return topLevelGetter() as String;
}

/*member: returnIntAsNum:[exact=JSUInt31|powerset={I}{O}{N}]*/
returnIntAsNum() {
  dynamic a = 0;
  return a as num;
}

typedef int Foo();

/*member: returnAsTypedef:[subclass=Closure|powerset={N}{O}{N}]*/
returnAsTypedef() {
  return topLevelGetter() as Foo;
}

/*member: testDeadCode:[exact=JSUInt31|powerset={I}{O}{N}]*/
testDeadCode() {
  return 42;
  // ignore: dead_code
  return 'foo';
}

/*member: testLabeledIf:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
testLabeledIf(
  /*Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/ a,
) {
  var c;
  L1:
  if (a /*invoke: Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/ >
      1) {
    if (a /*invoke: Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/ ==
        2) {
      break L1;
    }
    c = 42;
  } else {
    c = 38;
  }
  return c;
}

/*member: testSwitch1:Union(null, [exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{N})*/
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

/*member: testSwitch2:[exact=JSUInt31|powerset={I}{O}{N}]*/
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

/*member: testSwitch3:Union(null, [exact=JSString|powerset={I}{O}{I}], [subclass=JSNumber|powerset={I}{O}{N}], powerset: {null}{I}{O}{IN})*/
testSwitch3() {
  dynamic a = 42;
  var b;
  switch (topLevelGetter) {
    L1:
    case 1:
      b =
          a /*invoke: Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/ +
          42;
      break;
    case 2:
      a = 'foo';
      continue L1;
  }
  return b;
}

/*member: testSwitch4:[exact=JSUInt31|powerset={I}{O}{N}]*/
testSwitch4() {
  switch (topLevelGetter) {
    case 1:
      break;
    default:
      break;
  }
  return 42;
}

/*member: testSwitch5:[exact=JSUInt31|powerset={I}{O}{N}]*/
testSwitch5() {
  switch (topLevelGetter) {
    case 1:
      return 1;
    default:
      return 2;
  }
}

/*member: testContinue1:Union(null, [exact=JSString|powerset={I}{O}{I}], [subclass=JSNumber|powerset={I}{O}{N}], powerset: {null}{I}{O}{IN})*/
testContinue1() {
  dynamic a = 42;
  var b;
  while (true) {
    b =
        a /*invoke: Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/ +
        54;
    if (b /*invoke: Union([exact=JSString|powerset={I}{O}{I}], [subclass=JSNumber|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/ ==
        42)
      continue;
    a = 'foo';
  }
  // ignore: dead_code
  return b;
}

/*member: testBreak1:Union(null, [exact=JSString|powerset={I}{O}{I}], [subclass=JSUInt32|powerset={I}{O}{N}], powerset: {null}{I}{O}{IN})*/
testBreak1() {
  var a = 42;
  var b;
  while (true) {
    b = a /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ + 54;
    if (b /*invoke: [subclass=JSUInt32|powerset={I}{O}{N}]*/ == 42) break;
    b = 'foo';
  }
  return b;
}

/*member: testContinue2:Union(null, [exact=JSString|powerset={I}{O}{I}], [subclass=JSUInt32|powerset={I}{O}{N}], powerset: {null}{I}{O}{IN})*/
testContinue2() {
  var a = 42;
  var b;
  while (true) {
    b = a /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ + 54;
    if (b /*invoke: [subclass=JSUInt32|powerset={I}{O}{N}]*/ == 42) {
      b = 'foo';
      continue;
    }
  }
  // ignore: dead_code
  return b;
}

/*member: testBreak2:[null|subclass=JSUInt32|powerset={null}{I}{O}{N}]*/
testBreak2() {
  dynamic a = 42;
  var b;
  while (true) {
    b = a /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ + 54;
    if (b /*invoke: [subclass=JSUInt32|powerset={I}{O}{N}]*/ == 42) {
      a = 'foo';
      break;
    }
  }
  return b;
}

/*member: testReturnElementOfConstList1:[exact=JSUInt31|powerset={I}{O}{N}]*/
testReturnElementOfConstList1() {
  return const [
    42,
  ] /*Container([exact=JSUnmodifiableArray|powerset={I}{U}{I}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{U}{I})*/ [0];
}

/*member: testReturnElementOfConstList2:[exact=JSUInt31|powerset={I}{O}{N}]*/
testReturnElementOfConstList2() {
  return topLevelConstList /*Container([exact=JSUnmodifiableArray|powerset={I}{U}{I}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{U}{I})*/ [0];
}

/*member: testReturnItselfOrInt:[exact=JSUInt31|powerset={I}{O}{N}]*/
testReturnItselfOrInt(
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a,
) {
  if (a) return 42;
  return testReturnItselfOrInt(a);
}

/*member: testDoWhile1:Value([exact=JSString|powerset={I}{O}{I}], value: "foo", powerset: {I}{O}{I})*/
testDoWhile1() {
  dynamic a = 42;
  do {
    a = 'foo';
  } while (true);
  // ignore: dead_code
  return a;
}

/*member: testDoWhile2:[null|powerset={null}]*/
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

/*member: _#flag:[exact=_Cell|powerset={N}{O}{N}]*/
late bool /*Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/ /*update: [exact=_Cell|powerset={N}{O}{N}]*/
flag;

/*member: testDoWhile3:Value([exact=JSBool|powerset={I}{O}{N}], value: false, powerset: {I}{O}{N})*/
testDoWhile3() {
  dynamic a = 42;
  do {
    a = 'foo';
    if (flag = true) continue;
    return false;
  } while (true);
  // ignore: dead_code
  return a;
}

/*member: testDoWhile4:Union([exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N})*/
testDoWhile4() {
  dynamic a = 'foo';
  do {
    a = 54;
    if (flag = true) break;
    return 3.5;
  } while (true);
  return a;
}

/*member: testSpecialization1:[subclass=Object|powerset={IN}{GFUO}{IMN}]*/
testSpecialization1() {
  var a = topLevelGetter();
  a - 42;
  return a;
}

/*member: testSpecialization2:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
testSpecialization2() {
  var a = topLevelGetter();
  // Make [a] a captured variable. This should disable receiver
  // specialization on [a].
  (
  /*[exact=JSString|powerset={I}{O}{I}]*/
  () => a.toString())();
  a - 42;
  return a;
}

/*member: testSpecialization3:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
testSpecialization3() {
  var a = returnDynamic() ? null : 42;
  a. /*invoke: [null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/ toString();
  // Test that calling an [Object] method on [a] will not lead to
  // infer that [a] is not null;
  return a;
}

/*member: testReturnNull1:[null|powerset={null}]*/
testReturnNull1(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  if (a == null) return a;
  return null;
}

/*member: testReturnNull2:[null|powerset={null}]*/
testReturnNull2(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  if (a != null) return null;
  return a;
}

/*member: testReturnNull3:[subclass=Object|powerset={IN}{GFUO}{IMN}]*/
testReturnNull3(/*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a) {
  if (a == null) return 42;
  return a;
}

/*member: testReturnNull4:[null|powerset={null}]*/
testReturnNull4() {
  var a = topLevelGetter();
  if (a == null) return a;
  return null;
}

/*member: testReturnNull5:[null|powerset={null}]*/
testReturnNull5() {
  var a = topLevelGetter();
  if (a != null) return null;
  return a;
}

/*member: testReturnNull6:[subclass=Object|powerset={IN}{GFUO}{IMN}]*/
testReturnNull6() {
  var a = topLevelGetter();
  if (a == null) return 42;
  return a;
}

/*member: testReturnNotEquals:[exact=JSBool|powerset={I}{O}{N}]*/
testReturnNotEquals() {
  return A() /*invoke: [exact=A|powerset={N}{O}{N}]*/ != 54;
}

/*member: testReturnInvokeDynamicGetter:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
testReturnInvokeDynamicGetter() =>
    A().myFactory /*invoke: [exact=A|powerset={N}{O}{N}]*/ ();

/*member: topLevelConstList:Container([exact=JSUnmodifiableArray|powerset={I}{U}{I}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{U}{I})*/
var topLevelConstList = const [42];

/*member: topLevelGetter:[exact=JSUInt31|powerset={I}{O}{N}]*/
get topLevelGetter => 42;

/*member: returnDynamic:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
returnDynamic() => topLevelGetter(42);

/*member: returnTopLevelGetter:[exact=JSUInt31|powerset={I}{O}{N}]*/
returnTopLevelGetter() => topLevelGetter;

class A {
  factory A() = A.generative;

  /*member: A.generative:[exact=A|powerset={N}{O}{N}]*/
  A.generative();

  /*member: A.==:[exact=JSBool|powerset={I}{O}{N}]*/
  operator ==(
    /*Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/ other,
  ) => 42 as dynamic;

  /*member: A.myField:[exact=JSUInt31|powerset={I}{O}{N}]*/
  get myField => 42;

  set myField(/*[subclass=JSUInt32|powerset={I}{O}{N}]*/ a) {}

  /*member: A.returnInt1:[subclass=JSUInt32|powerset={I}{O}{N}]*/
  returnInt1() => /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/
      ++ /*[subclass=A|powerset={N}{O}{N}]*/ /*update: [subclass=A|powerset={N}{O}{N}]*/ myField;

  /*member: A.returnInt2:[subclass=JSUInt32|powerset={I}{O}{N}]*/
  returnInt2() => /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ ++this
      . /*[subclass=A|powerset={N}{O}{N}]*/ /*update: [subclass=A|powerset={N}{O}{N}]*/ myField;

  /*member: A.returnInt3:[subclass=JSUInt32|powerset={I}{O}{N}]*/
  returnInt3() =>
      this. /*[subclass=A|powerset={N}{O}{N}]*/ /*update: [subclass=A|powerset={N}{O}{N}]*/ myField /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ +=
          42;

  /*member: A.returnInt4:[subclass=JSUInt32|powerset={I}{O}{N}]*/
  returnInt4() => /*[subclass=A|powerset={N}{O}{N}]*/ /*update: [subclass=A|powerset={N}{O}{N}]*/
      myField /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ += 42;

  /*member: A.[]:[exact=JSUInt31|powerset={I}{O}{N}]*/
  operator [](/*[exact=JSUInt31|powerset={I}{O}{N}]*/ index) => 42;

  /*member: A.[]=:[null|powerset={null}]*/
  operator []=(
    /*[exact=JSUInt31|powerset={I}{O}{N}]*/ index,
    /*[subclass=JSUInt32|powerset={I}{O}{N}]*/ value,
  ) {}

  /*member: A.returnInt5:[subclass=JSUInt32|powerset={I}{O}{N}]*/
  returnInt5() => /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/
      ++this /*[subclass=A|powerset={N}{O}{N}]*/ /*update: [subclass=A|powerset={N}{O}{N}]*/ [0];

  /*member: A.returnInt6:[subclass=JSUInt32|powerset={I}{O}{N}]*/
  returnInt6() =>
      this /*[subclass=A|powerset={N}{O}{N}]*/ /*update: [subclass=A|powerset={N}{O}{N}]*/ [0] /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ +=
          1;

  /*member: A.myFactory:[subclass=Closure|powerset={N}{O}{N}]*/
  get myFactory => /*[exact=JSUInt31|powerset={I}{O}{N}]*/
      () => 42;
}

class B extends A {
  /*member: B.:[exact=B|powerset={N}{O}{N}]*/
  B() : super.generative();

  /*member: B.returnInt1:[subclass=JSUInt32|powerset={I}{O}{N}]*/
  returnInt1() => /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ ++new A()
      . /*[exact=A|powerset={N}{O}{N}]*/ /*update: [exact=A|powerset={N}{O}{N}]*/ myField;

  /*member: B.returnInt2:[subclass=JSUInt32|powerset={I}{O}{N}]*/
  returnInt2() =>
      A(). /*[exact=A|powerset={N}{O}{N}]*/ /*update: [exact=A|powerset={N}{O}{N}]*/ myField /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ +=
          4;

  /*member: B.returnInt3:[subclass=JSUInt32|powerset={I}{O}{N}]*/
  returnInt3() => /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/
      ++new A() /*[exact=A|powerset={N}{O}{N}]*/ /*update: [exact=A|powerset={N}{O}{N}]*/ [0];

  /*member: B.returnInt4:[subclass=JSUInt32|powerset={I}{O}{N}]*/
  returnInt4() =>
      A() /*[exact=A|powerset={N}{O}{N}]*/ /*update: [exact=A|powerset={N}{O}{N}]*/ [0] /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ +=
          42;

  /*member: B.returnInt5:[subclass=JSUInt32|powerset={I}{O}{N}]*/
  returnInt5() => /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/
      ++super.myField;

  /*member: B.returnInt6:[subclass=JSUInt32|powerset={I}{O}{N}]*/
  returnInt6() =>
      super.myField /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ += 4;

  /*member: B.returnInt7:[subclass=JSUInt32|powerset={I}{O}{N}]*/
  returnInt7() => /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ ++super[0];

  /*member: B.returnInt8:[subclass=JSUInt32|powerset={I}{O}{N}]*/
  returnInt8() =>
      super[0] /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ += 54;

  /*member: B.returnInt9:[exact=JSUInt31|powerset={I}{O}{N}]*/
  returnInt9() => super.myField;
}

class C {
  /*member: C.myField:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
  var myField = 42;

  /*member: C.:[exact=C|powerset={N}{O}{N}]*/
  C();

  /*member: C.returnInt1:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
  returnInt1() => /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/
      ++ /*update: [exact=C|powerset={N}{O}{N}]*/ /*[exact=C|powerset={N}{O}{N}]*/ myField;

  /*member: C.returnInt2:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
  returnInt2() => /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/ ++this
      . /*[exact=C|powerset={N}{O}{N}]*/ /*update: [exact=C|powerset={N}{O}{N}]*/ myField;

  /*member: C.returnInt3:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
  returnInt3() =>
      this. /*[exact=C|powerset={N}{O}{N}]*/ /*update: [exact=C|powerset={N}{O}{N}]*/ myField /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/ +=
          42;

  /*member: C.returnInt4:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
  returnInt4() => /*[exact=C|powerset={N}{O}{N}]*/ /*update: [exact=C|powerset={N}{O}{N}]*/
      myField /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/ += 42;

  /*member: C.[]:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
  operator [](
    /*[exact=JSUInt31|powerset={I}{O}{N}]*/ index,
  ) => /*[exact=C|powerset={N}{O}{N}]*/ myField;

  /*member: C.[]=:[null|powerset={null}]*/
  operator []=(
    /*[exact=JSUInt31|powerset={I}{O}{N}]*/ index,
    /*[subclass=JSPositiveInt|powerset={I}{O}{N}]*/ value,
  ) {}

  /*member: C.returnInt5:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
  returnInt5() => /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/
      ++this /*[exact=C|powerset={N}{O}{N}]*/ /*update: [exact=C|powerset={N}{O}{N}]*/ [0];

  /*member: C.returnInt6:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
  returnInt6() =>
      this /*[exact=C|powerset={N}{O}{N}]*/ /*update: [exact=C|powerset={N}{O}{N}]*/ [0] /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/ +=
          1;
}

/*member: testCascade1:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: null, powerset: {I}{G}{M})*/
testCascade1() {
  return [1, 2, 3]
    .. /*invoke: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: null, powerset: {I}{G}{M})*/ add(
      4,
    )
    .. /*invoke: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: null, powerset: {I}{G}{M})*/ add(
      5,
    );
}

/*member: testCascade2:[exact=CascadeHelper|powerset={N}{O}{N}]*/
testCascade2() {
  return CascadeHelper()
    .. /*update: [exact=CascadeHelper|powerset={N}{O}{N}]*/ a = "hello"
    .. /*update: [exact=CascadeHelper|powerset={N}{O}{N}]*/ b = 42
    .. /*[exact=CascadeHelper|powerset={N}{O}{N}]*/ i /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/ /*update: [exact=CascadeHelper|powerset={N}{O}{N}]*/ +=
        1;
}

/*member: CascadeHelper.:[exact=CascadeHelper|powerset={N}{O}{N}]*/
class CascadeHelper {
  /*member: CascadeHelper.a:Value([null|exact=JSString|powerset={null}{I}{O}{I}], value: "hello", powerset: {null}{I}{O}{I})*/
  var a;

  /*member: CascadeHelper.b:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
  var b;

  /*member: CascadeHelper.i:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
  var i = 0;
}

/*member: main:[null|powerset={null}]*/
main() {
  // Ensure a function class is being instantiated.
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/
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
  A() /*invoke: [subclass=A|powerset={N}{O}{N}]*/ == null;
  A()
    .. /*invoke: [exact=A|powerset={N}{O}{N}]*/ returnInt1()
    .. /*invoke: [exact=A|powerset={N}{O}{N}]*/ returnInt2()
    .. /*invoke: [exact=A|powerset={N}{O}{N}]*/ returnInt3()
    .. /*invoke: [exact=A|powerset={N}{O}{N}]*/ returnInt4()
    .. /*invoke: [exact=A|powerset={N}{O}{N}]*/ returnInt5()
    .. /*invoke: [exact=A|powerset={N}{O}{N}]*/ returnInt6();

  B()
    .. /*invoke: [exact=B|powerset={N}{O}{N}]*/ returnInt1()
    .. /*invoke: [exact=B|powerset={N}{O}{N}]*/ returnInt2()
    .. /*invoke: [exact=B|powerset={N}{O}{N}]*/ returnInt3()
    .. /*invoke: [exact=B|powerset={N}{O}{N}]*/ returnInt4()
    .. /*invoke: [exact=B|powerset={N}{O}{N}]*/ returnInt5()
    .. /*invoke: [exact=B|powerset={N}{O}{N}]*/ returnInt6()
    .. /*invoke: [exact=B|powerset={N}{O}{N}]*/ returnInt7()
    .. /*invoke: [exact=B|powerset={N}{O}{N}]*/ returnInt8()
    .. /*invoke: [exact=B|powerset={N}{O}{N}]*/ returnInt9();

  C()
    .. /*invoke: [exact=C|powerset={N}{O}{N}]*/ returnInt1()
    .. /*invoke: [exact=C|powerset={N}{O}{N}]*/ returnInt2()
    .. /*invoke: [exact=C|powerset={N}{O}{N}]*/ returnInt3()
    .. /*invoke: [exact=C|powerset={N}{O}{N}]*/ returnInt4()
    .. /*invoke: [exact=C|powerset={N}{O}{N}]*/ returnInt5()
    .. /*invoke: [exact=C|powerset={N}{O}{N}]*/ returnInt6();
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
