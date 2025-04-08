// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: returnInt1:[exact=JSUInt31|powerset=0]*/
returnInt1() {
  var a = 42;
  try {
    a = 54;
  } catch (e) {}
  return a;
}

/*member: returnDyn1:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
returnDyn1() {
  dynamic a = 42;
  try {
    a = 'foo';
  } catch (e) {}
  return a;
}

/*member: returnInt2:[exact=JSUInt31|powerset=0]*/
returnInt2() {
  var a = 42;
  try {
    a = 54;
  } catch (e) {
    a = 2;
  }
  return a;
}

/*member: returnDyn2:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
returnDyn2() {
  dynamic a = 42;
  try {
    a = 54;
  } catch (e) {
    a = 'foo';
  }
  return a;
}

/*member: returnInt3:[exact=JSUInt31|powerset=0]*/
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

/*member: returnDyn3:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
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

/*member: returnInt4:[exact=JSUInt31|powerset=0]*/
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

/*member: returnDyn4:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
returnDyn4() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset=0]*/ == 54) {
    try {
      a = 'foo';
    } catch (e) {}
  }
  return a;
}

/*member: returnInt5:[exact=JSUInt31|powerset=0]*/
returnInt5() {
  var a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset=0]*/ == 54) {
    try {
      a = 42;
    } catch (e) {}
  }
  return a;
}

/*member: returnDyn5:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
returnDyn5() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset=0]*/ == 54) {
    try {
      a = 'foo';
      print(a);
      a = 42;
    } catch (e) {}
  }
  return a;
}

/*member: returnInt6:[subclass=JSInt|powerset=0]*/
returnInt6() {
  try {
    throw 42;
  } on int catch (e) {
    return e;
  }
  // ignore: dead_code
  return 42;
}

/*member: returnDyn6:[subclass=Object|powerset=0]*/
returnDyn6() {
  try {
    throw 42;
  } catch (e) {
    return e;
  }
}

/*member: returnDyn7:[null|subclass=Object|powerset=1]*/
returnDyn7() {
  try {
    // Do nothing
  } catch (e) {
    return e;
  }
}

/*member: returnInt7:[exact=JSUInt31|powerset=0]*/
returnInt7() {
  dynamic a = 'foo';
  try {
    a = 42;
    return a;
  } catch (e) {}
  return 2;
}

/*member: returnInt8:[exact=JSUInt31|powerset=0]*/
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

/*member: returnUnion1:[null|exact=JSUInt31|powerset=1]*/
returnUnion1() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset=0]*/ == 54) {
    try {
      a = 'foo';
      throw a;
    } catch (e) {
      a = null;
    }
  }
  return a;
}

/*member: returnUnion2:Union(null, [exact=JSBool|powerset=0], [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1)*/
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

/*member: returnUnion3:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
returnUnion3() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset=0]*/ == 54) {
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

/*member: returnUnion4:Union(null, [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1)*/
returnUnion4() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset=0]*/ == 54) {
    try {
      a = 'foo';
      a = null;
    } catch (e) {}
  }
  return a;
}

/*member: returnUnion5:Union([exact=JSBool|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
returnUnion5() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset=0]*/ == 54) {
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

/*member: returnUnion6:Union(null, [exact=JSBool|powerset=0], [exact=JSString|powerset=0], powerset: 1)*/
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

/*member: returnUnion7:Union([exact=JSBool|powerset=0], [exact=JSString|powerset=0], powerset: 0)*/
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

/*member: returnUnion8:[null|exact=JSUInt31|powerset=1]*/
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

/*member: returnUnion9:[exact=JSBool|powerset=0]*/
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

/*member: returnUnion10:Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/
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

/*member: returnNull1:[null|powerset=1]*/
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

/*member: returnNull2:[null|powerset=1]*/
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

/*member: A.:[exact=A|powerset=0]*/
class A {
  /*member: A.a:[null|exact=JSUInt31|powerset=1]*/
  dynamic a;
  /*member: A.b:Union(null, [exact=JSUInt31|powerset=0], [exact=JsLinkedHashMap|powerset=0], powerset: 1)*/
  dynamic b;
  /*member: A.c:Union(null, [exact=JSBool|powerset=0], [exact=JSString|powerset=0], powerset: 1)*/
  dynamic c;
  /*member: A.d:Value([null|exact=JSString|powerset=1], value: "foo", powerset: 1)*/
  dynamic d;
  /*member: A.e:Union(null, [exact=JSBool|powerset=0], [exact=JSString|powerset=0], powerset: 1)*/
  dynamic e;
  /*member: A.f:Union(null, [exact=JSBool|powerset=0], [exact=JSString|powerset=0], powerset: 1)*/
  dynamic f;
  /*member: A.g:Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSNumNotInt|powerset=0], [exact=JSString|powerset=0], powerset: 1)*/
  dynamic g;

  /*member: A.testa:Union([exact=JSBool|powerset=0], [exact=JSString|powerset=0], powerset: 0)*/
  testa() {
    try {
      return 'foo';
    } catch (e) {
      return true;
    } finally {
      /*update: [exact=A|powerset=0]*/
      a = 55;
    }
  }

  /*member: A.testb:Union([exact=JSBool|powerset=0], [exact=JSString|powerset=0], powerset: 0)*/
  testb() {
    try {
      return 'foo';
    } catch (e) {
      return true;
    } finally {
      /*update: [exact=A|powerset=0]*/
      b = 55;
    }
    return b;
  }

  /*member: A.testc:Union(null, [exact=JSBool|powerset=0], [exact=JSString|powerset=0], powerset: 1)*/
  testc() {
    try {
      /*update: [exact=A|powerset=0]*/
      c = 'foo';
      throw /*[exact=A|powerset=0]*/ c;
    } catch (e) {
      /*update: [exact=A|powerset=0]*/
      c = false;
    } catch (e) {
      /*update: [exact=A|powerset=0]*/
      c = true;
    }
    return /*[exact=A|powerset=0]*/ c;
  }

  /*member: A.testd:Value([null|exact=JSString|powerset=1], value: "foo", powerset: 1)*/
  testd() {
    try {
      /*update: [exact=A|powerset=0]*/
      d = 'foo';
    } catch (e) {
      // Do nothing
    }
    return /*[exact=A|powerset=0]*/ d;
  }

  /*member: A.teste:Union(null, [exact=JSBool|powerset=0], [exact=JSString|powerset=0], powerset: 1)*/
  teste() {
    try {
      /*update: [exact=A|powerset=0]*/
      e = 'foo';
    } catch (_) {
      /*update: [exact=A|powerset=0]*/
      e = true;
    }
    return /*[exact=A|powerset=0]*/ e;
  }

  /*member: A.testf:Union(null, [exact=JSBool|powerset=0], [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1)*/
  testf() {
    try {
      /*update: [exact=A|powerset=0]*/
      f = 'foo';
      return 3;
    } catch (e) {
      /*update: [exact=A|powerset=0]*/
      f = true;
    }
    return /*[exact=A|powerset=0]*/ f;
  }

  /*member: A.testg:Union(null, [exact=JSUInt31|powerset=0], [exact=JsLinkedHashMap|powerset=0], powerset: 1)*/
  testg() {
    try {
      /*update: [exact=A|powerset=0]*/
      g = 'foo';
      /*update: [exact=A|powerset=0]*/
      g = 5.5;
    } catch (e) {
      /*update: [exact=A|powerset=0]*/
      g = [];
      /*update: [exact=A|powerset=0]*/
      b = {};
    }
    return /*[exact=A|powerset=0]*/ b;
  }
}

/*member: main:[null|powerset=1]*/
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
  a. /*invoke: [exact=A|powerset=0]*/ testa();
  a. /*invoke: [exact=A|powerset=0]*/ testb();
  a. /*invoke: [exact=A|powerset=0]*/ testc();
  a. /*invoke: [exact=A|powerset=0]*/ testd();
  a. /*invoke: [exact=A|powerset=0]*/ teste();
  a. /*invoke: [exact=A|powerset=0]*/ testf();
  a. /*invoke: [exact=A|powerset=0]*/ testg();
}
