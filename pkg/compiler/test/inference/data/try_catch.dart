// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: returnInt1:[exact=JSUInt31|powerset={I}{O}]*/
returnInt1() {
  var a = 42;
  try {
    a = 54;
  } catch (e) {}
  return a;
}

/*member: returnDyn1:Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
returnDyn1() {
  dynamic a = 42;
  try {
    a = 'foo';
  } catch (e) {}
  return a;
}

/*member: returnInt2:[exact=JSUInt31|powerset={I}{O}]*/
returnInt2() {
  var a = 42;
  try {
    a = 54;
  } catch (e) {
    a = 2;
  }
  return a;
}

/*member: returnDyn2:Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
returnDyn2() {
  dynamic a = 42;
  try {
    a = 54;
  } catch (e) {
    a = 'foo';
  }
  return a;
}

/*member: returnInt3:[exact=JSUInt31|powerset={I}{O}]*/
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

/*member: returnDyn3:Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
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

/*member: returnInt4:[exact=JSUInt31|powerset={I}{O}]*/
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

/*member: returnDyn4:Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
returnDyn4() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ == 54) {
    try {
      a = 'foo';
    } catch (e) {}
  }
  return a;
}

/*member: returnInt5:[exact=JSUInt31|powerset={I}{O}]*/
returnInt5() {
  var a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ == 54) {
    try {
      a = 42;
    } catch (e) {}
  }
  return a;
}

/*member: returnDyn5:Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
returnDyn5() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ == 54) {
    try {
      a = 'foo';
      print(a);
      a = 42;
    } catch (e) {}
  }
  return a;
}

/*member: returnInt6:[subclass=JSInt|powerset={I}{O}]*/
returnInt6() {
  try {
    throw 42;
  } on int catch (e) {
    return e;
  }
  // ignore: dead_code
  return 42;
}

/*member: returnDyn6:[subclass=Object|powerset={IN}{GFUO}]*/
returnDyn6() {
  try {
    throw 42;
  } catch (e) {
    return e;
  }
}

/*member: returnDyn7:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
returnDyn7() {
  try {
    // Do nothing
  } catch (e) {
    return e;
  }
}

/*member: returnInt7:[exact=JSUInt31|powerset={I}{O}]*/
returnInt7() {
  dynamic a = 'foo';
  try {
    a = 42;
    return a;
  } catch (e) {}
  return 2;
}

/*member: returnInt8:[exact=JSUInt31|powerset={I}{O}]*/
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

/*member: returnUnion1:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
returnUnion1() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ == 54) {
    try {
      a = 'foo';
      throw a;
    } catch (e) {
      a = null;
    }
  }
  return a;
}

/*member: returnUnion2:Union(null, [exact=JSBool|powerset={I}{O}], [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{O})*/
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

/*member: returnUnion3:Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
returnUnion3() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ == 54) {
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

/*member: returnUnion4:Union(null, [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{O})*/
returnUnion4() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ == 54) {
    try {
      a = 'foo';
      a = null;
    } catch (e) {}
  }
  return a;
}

/*member: returnUnion5:Union([exact=JSBool|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
returnUnion5() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ == 54) {
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

/*member: returnUnion6:Union(null, [exact=JSBool|powerset={I}{O}], [exact=JSString|powerset={I}{O}], powerset: {null}{I}{O})*/
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

/*member: returnUnion7:Union([exact=JSBool|powerset={I}{O}], [exact=JSString|powerset={I}{O}], powerset: {I}{O})*/
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

/*member: returnUnion8:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
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

/*member: returnUnion9:[exact=JSBool|powerset={I}{O}]*/
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

/*member: returnUnion10:Value([exact=JSBool|powerset={I}{O}], value: true, powerset: {I}{O})*/
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

/*member: A.:[exact=A|powerset={N}{O}]*/
class A {
  /*member: A.a:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
  dynamic a;
  /*member: A.b:Union(null, [exact=JSUInt31|powerset={I}{O}], [exact=JsLinkedHashMap|powerset={N}{O}], powerset: {null}{IN}{O})*/
  dynamic b;
  /*member: A.c:Union(null, [exact=JSBool|powerset={I}{O}], [exact=JSString|powerset={I}{O}], powerset: {null}{I}{O})*/
  dynamic c;
  /*member: A.d:Value([null|exact=JSString|powerset={null}{I}{O}], value: "foo", powerset: {null}{I}{O})*/
  dynamic d;
  /*member: A.e:Union(null, [exact=JSBool|powerset={I}{O}], [exact=JSString|powerset={I}{O}], powerset: {null}{I}{O})*/
  dynamic e;
  /*member: A.f:Union(null, [exact=JSBool|powerset={I}{O}], [exact=JSString|powerset={I}{O}], powerset: {null}{I}{O})*/
  dynamic f;
  /*member: A.g:Union(null, [exact=JSExtendableArray|powerset={I}{G}], [exact=JSNumNotInt|powerset={I}{O}], [exact=JSString|powerset={I}{O}], powerset: {null}{I}{GO})*/
  dynamic g;

  /*member: A.testa:Union([exact=JSBool|powerset={I}{O}], [exact=JSString|powerset={I}{O}], powerset: {I}{O})*/
  testa() {
    try {
      return 'foo';
    } catch (e) {
      return true;
    } finally {
      /*update: [exact=A|powerset={N}{O}]*/
      a = 55;
    }
  }

  /*member: A.testb:Union([exact=JSBool|powerset={I}{O}], [exact=JSString|powerset={I}{O}], powerset: {I}{O})*/
  testb() {
    try {
      return 'foo';
    } catch (e) {
      return true;
    } finally {
      /*update: [exact=A|powerset={N}{O}]*/
      b = 55;
    }
    return b;
  }

  /*member: A.testc:Union(null, [exact=JSBool|powerset={I}{O}], [exact=JSString|powerset={I}{O}], powerset: {null}{I}{O})*/
  testc() {
    try {
      /*update: [exact=A|powerset={N}{O}]*/
      c = 'foo';
      throw /*[exact=A|powerset={N}{O}]*/ c;
    } catch (e) {
      /*update: [exact=A|powerset={N}{O}]*/
      c = false;
    } catch (e) {
      /*update: [exact=A|powerset={N}{O}]*/
      c = true;
    }
    return /*[exact=A|powerset={N}{O}]*/ c;
  }

  /*member: A.testd:Value([null|exact=JSString|powerset={null}{I}{O}], value: "foo", powerset: {null}{I}{O})*/
  testd() {
    try {
      /*update: [exact=A|powerset={N}{O}]*/
      d = 'foo';
    } catch (e) {
      // Do nothing
    }
    return /*[exact=A|powerset={N}{O}]*/ d;
  }

  /*member: A.teste:Union(null, [exact=JSBool|powerset={I}{O}], [exact=JSString|powerset={I}{O}], powerset: {null}{I}{O})*/
  teste() {
    try {
      /*update: [exact=A|powerset={N}{O}]*/
      e = 'foo';
    } catch (_) {
      /*update: [exact=A|powerset={N}{O}]*/
      e = true;
    }
    return /*[exact=A|powerset={N}{O}]*/ e;
  }

  /*member: A.testf:Union(null, [exact=JSBool|powerset={I}{O}], [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{O})*/
  testf() {
    try {
      /*update: [exact=A|powerset={N}{O}]*/
      f = 'foo';
      return 3;
    } catch (e) {
      /*update: [exact=A|powerset={N}{O}]*/
      f = true;
    }
    return /*[exact=A|powerset={N}{O}]*/ f;
  }

  /*member: A.testg:Union(null, [exact=JSUInt31|powerset={I}{O}], [exact=JsLinkedHashMap|powerset={N}{O}], powerset: {null}{IN}{O})*/
  testg() {
    try {
      /*update: [exact=A|powerset={N}{O}]*/
      g = 'foo';
      /*update: [exact=A|powerset={N}{O}]*/
      g = 5.5;
    } catch (e) {
      /*update: [exact=A|powerset={N}{O}]*/
      g = [];
      /*update: [exact=A|powerset={N}{O}]*/
      b = {};
    }
    return /*[exact=A|powerset={N}{O}]*/ b;
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
  a. /*invoke: [exact=A|powerset={N}{O}]*/ testa();
  a. /*invoke: [exact=A|powerset={N}{O}]*/ testb();
  a. /*invoke: [exact=A|powerset={N}{O}]*/ testc();
  a. /*invoke: [exact=A|powerset={N}{O}]*/ testd();
  a. /*invoke: [exact=A|powerset={N}{O}]*/ teste();
  a. /*invoke: [exact=A|powerset={N}{O}]*/ testf();
  a. /*invoke: [exact=A|powerset={N}{O}]*/ testg();
}
