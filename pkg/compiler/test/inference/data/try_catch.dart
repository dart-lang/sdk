// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: returnInt1:[exact=JSUInt31|powerset={I}{O}{N}]*/
returnInt1() {
  var a = 42;
  try {
    a = 54;
  } catch (e) {}
  return a;
}

/*member: returnDyn1:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
returnDyn1() {
  dynamic a = 42;
  try {
    a = 'foo';
  } catch (e) {}
  return a;
}

/*member: returnInt2:[exact=JSUInt31|powerset={I}{O}{N}]*/
returnInt2() {
  var a = 42;
  try {
    a = 54;
  } catch (e) {
    a = 2;
  }
  return a;
}

/*member: returnDyn2:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
returnDyn2() {
  dynamic a = 42;
  try {
    a = 54;
  } catch (e) {
    a = 'foo';
  }
  return a;
}

/*member: returnInt3:[exact=JSUInt31|powerset={I}{O}{N}]*/
returnInt3() {
  dynamic a = 42;
  try {
    a = 54;
  } catch (e) {
    a = 'foo';
  } finally {
    a = 4;
  }
  return a;
}

/*member: returnDyn3:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
returnDyn3() {
  dynamic a = 42;
  try {
    a = 54;
    // ignore: unused_catch_clause
  } on String catch (e) {
    a = 2;
    // ignore: unused_catch_clause
  } on Object catch (e) {
    a = 'foo';
  }
  return a;
}

/*member: returnInt4:[exact=JSUInt31|powerset={I}{O}{N}]*/
returnInt4() {
  var a = 42;
  try {
    a = 54;
    // ignore: unused_catch_clause
  } on String catch (e) {
    a = 2;
    // ignore: unused_catch_clause
  } on Object catch (e) {
    a = 32;
  }
  return a;
}

/*member: returnDyn4:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
returnDyn4() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ == 54) {
    try {
      a = 'foo';
    } catch (e) {}
  }
  return a;
}

/*member: returnInt5:[exact=JSUInt31|powerset={I}{O}{N}]*/
returnInt5() {
  var a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ == 54) {
    try {
      a = 42;
    } catch (e) {}
  }
  return a;
}

/*member: returnDyn5:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
returnDyn5() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ == 54) {
    try {
      a = 'foo';
      print(a);
      a = 42;
    } catch (e) {}
  }
  return a;
}

/*member: returnInt6:[subclass=JSInt|powerset={I}{O}{N}]*/
returnInt6() {
  try {
    throw 42;
  } on int catch (e) {
    return e;
  }
  // ignore: dead_code
  return 42;
}

/*member: returnDyn6:[subclass=Object|powerset={IN}{GFUO}{IMN}]*/
returnDyn6() {
  try {
    throw 42;
  } catch (e) {
    return e;
  }
}

/*member: returnDyn7:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
returnDyn7() {
  try {
    // Do nothing
  } catch (e) {
    return e;
  }
}

/*member: returnInt7:[exact=JSUInt31|powerset={I}{O}{N}]*/
returnInt7() {
  dynamic a = 'foo';
  try {
    a = 42;
    return a;
  } catch (e) {}
  return 2;
}

/*member: returnInt8:[exact=JSUInt31|powerset={I}{O}{N}]*/
returnInt8() {
  dynamic a = 'foo';
  try {
    a = 42;
    return a;
  } catch (e) {
    a = 29;
    return a;
  }
  // ignore: dead_code
  a = 'bar';
  return a;
}

/*member: returnUnion1:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
returnUnion1() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ == 54) {
    try {
      a = 'foo';
      throw a;
    } catch (e) {
      a = null;
    }
  }
  return a;
}

/*member: returnUnion2:Union(null, [exact=JSBool|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{IN})*/
returnUnion2() {
  dynamic a = 42;
  try {
    a = 'foo';
    a = null;
  } catch (e) {
    a = true;
  }
  return a;
}

/*member: returnUnion3:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
returnUnion3() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ == 54) {
    try {
      a = 'foo';
      a = null;
    } catch (e) {
      a = true;
    } finally {
      a = 'bar';
    }
  }
  return a;
}

/*member: returnUnion4:Union(null, [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{IN})*/
returnUnion4() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ == 54) {
    try {
      a = 'foo';
      a = null;
    } catch (e) {}
  }
  return a;
}

/*member: returnUnion5:Union([exact=JSBool|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N})*/
returnUnion5() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ == 54) {
    try {
      a = 'foo';
    } catch (e) {
      a = null;
    } finally {
      a = true;
    }
  }
  return a;
}

/*member: returnUnion6:Union(null, [exact=JSBool|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], powerset: {null}{I}{O}{IN})*/
returnUnion6() {
  dynamic a = 42;
  try {
    return 'foo';
  } catch (e) {
    return null;
  } finally {
    return true;
  }
  // ignore: dead_code
  return a;
}

/*member: returnUnion7:Union([exact=JSBool|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], powerset: {I}{O}{IN})*/
returnUnion7() {
  dynamic a = 42;
  try {
    return 'foo';
  } catch (e) {
    return true;
  } finally {
    a = 55;
  }
}

/*member: returnUnion8:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
returnUnion8() {
  dynamic a = 5.5;
  try {
    a = 'foo';
    throw a;
  } catch (e) {
    a = null;
  } catch (e) {
    a = true;
    return 3;
  }
  return a;
}

/*member: returnUnion9:[exact=JSBool|powerset={I}{O}{N}]*/
returnUnion9() {
  dynamic a = 5.5;
  try {
    a = 'foo';
    throw a;
  } catch (e) {
    a = false;
  } catch (e) {
    a = true;
  }
  return a;
}

/*member: returnUnion10:Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/
returnUnion10() {
  dynamic a = 5;
  try {
    a = 6;
    throw 0;
  } catch (e) {
    a = 7;
    throw 0;
  } finally {
    a = 10;
    a = true;
    return a;
  }
}

/*member: returnNull1:[null|powerset={null}]*/
returnNull1() {
  dynamic a = 42;
  try {
    a = 'foo';
  } catch (e) {
    a = true;
  } finally {
    return null;
  }
  return a;
}

/*member: returnNull2:[null|powerset={null}]*/
returnNull2() {
  dynamic a = 5.5;
  try {
    a = 'foo';
    throw a;
  } catch (e) {
    a = null;
  } catch (e) {
    a = true;
    throw 3;
  }
  return a;
}

/*member: A.:[exact=A|powerset={N}{O}{N}]*/
class A {
  /*member: A.a:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
  dynamic a;
  /*member: A.b:Union(null, [exact=JSUInt31|powerset={I}{O}{N}], [exact=JsLinkedHashMap|powerset={N}{O}{N}], powerset: {null}{IN}{O}{N})*/
  dynamic b;
  /*member: A.c:Union(null, [exact=JSBool|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], powerset: {null}{I}{O}{IN})*/
  dynamic c;
  /*member: A.d:Value([null|exact=JSString|powerset={null}{I}{O}{I}], value: "foo", powerset: {null}{I}{O}{I})*/
  dynamic d;
  /*member: A.e:Union(null, [exact=JSBool|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], powerset: {null}{I}{O}{IN})*/
  dynamic e;
  /*member: A.f:Union(null, [exact=JSBool|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], powerset: {null}{I}{O}{IN})*/
  dynamic f;
  /*member: A.g:Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], powerset: {null}{I}{GO}{IMN})*/
  dynamic g;

  /*member: A.testa:Union([exact=JSBool|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], powerset: {I}{O}{IN})*/
  testa() {
    try {
      return 'foo';
    } catch (e) {
      return true;
    } finally {
      /*update: [exact=A|powerset={N}{O}{N}]*/
      a = 55;
    }
  }

  /*member: A.testb:Union([exact=JSBool|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], powerset: {I}{O}{IN})*/
  testb() {
    try {
      return 'foo';
    } catch (e) {
      return true;
    } finally {
      /*update: [exact=A|powerset={N}{O}{N}]*/
      b = 55;
    }
    return b;
  }

  /*member: A.testc:Union(null, [exact=JSBool|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], powerset: {null}{I}{O}{IN})*/
  testc() {
    try {
      /*update: [exact=A|powerset={N}{O}{N}]*/
      c = 'foo';
      throw /*[exact=A|powerset={N}{O}{N}]*/ c;
    } catch (e) {
      /*update: [exact=A|powerset={N}{O}{N}]*/
      c = false;
    } catch (e) {
      /*update: [exact=A|powerset={N}{O}{N}]*/
      c = true;
    }
    return /*[exact=A|powerset={N}{O}{N}]*/ c;
  }

  /*member: A.testd:Value([null|exact=JSString|powerset={null}{I}{O}{I}], value: "foo", powerset: {null}{I}{O}{I})*/
  testd() {
    try {
      /*update: [exact=A|powerset={N}{O}{N}]*/
      d = 'foo';
    } catch (e) {
      // Do nothing
    }
    return /*[exact=A|powerset={N}{O}{N}]*/ d;
  }

  /*member: A.teste:Union(null, [exact=JSBool|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], powerset: {null}{I}{O}{IN})*/
  teste() {
    try {
      /*update: [exact=A|powerset={N}{O}{N}]*/
      e = 'foo';
    } catch (_) {
      /*update: [exact=A|powerset={N}{O}{N}]*/
      e = true;
    }
    return /*[exact=A|powerset={N}{O}{N}]*/ e;
  }

  /*member: A.testf:Union(null, [exact=JSBool|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{IN})*/
  testf() {
    try {
      /*update: [exact=A|powerset={N}{O}{N}]*/
      f = 'foo';
      return 3;
    } catch (e) {
      /*update: [exact=A|powerset={N}{O}{N}]*/
      f = true;
    }
    return /*[exact=A|powerset={N}{O}{N}]*/ f;
  }

  /*member: A.testg:Union(null, [exact=JSUInt31|powerset={I}{O}{N}], [exact=JsLinkedHashMap|powerset={N}{O}{N}], powerset: {null}{IN}{O}{N})*/
  testg() {
    try {
      /*update: [exact=A|powerset={N}{O}{N}]*/
      g = 'foo';
      /*update: [exact=A|powerset={N}{O}{N}]*/
      g = 5.5;
    } catch (e) {
      /*update: [exact=A|powerset={N}{O}{N}]*/
      g = [];
      /*update: [exact=A|powerset={N}{O}{N}]*/
      b = {};
    }
    return /*[exact=A|powerset={N}{O}{N}]*/ b;
  }
}

/*member: main:[null|powerset={null}]*/
main() {
  returnInt1();
  returnDyn1();
  returnInt2();
  returnDyn2();
  returnInt3();
  returnDyn3();
  returnInt4();
  returnDyn4();
  returnInt5();
  returnDyn5();
  returnInt6();
  returnDyn6();
  returnDyn7();
  returnInt7();
  returnInt8();
  returnUnion1();
  returnUnion2();
  returnUnion3();
  returnUnion4();
  returnUnion5();
  returnUnion6();
  returnUnion7();
  returnUnion8();
  returnUnion9();
  returnUnion10();
  returnNull1();
  returnNull2();

  final a = A();
  a. /*invoke: [exact=A|powerset={N}{O}{N}]*/ testa();
  a. /*invoke: [exact=A|powerset={N}{O}{N}]*/ testb();
  a. /*invoke: [exact=A|powerset={N}{O}{N}]*/ testc();
  a. /*invoke: [exact=A|powerset={N}{O}{N}]*/ testd();
  a. /*invoke: [exact=A|powerset={N}{O}{N}]*/ teste();
  a. /*invoke: [exact=A|powerset={N}{O}{N}]*/ testf();
  a. /*invoke: [exact=A|powerset={N}{O}{N}]*/ testg();
}
