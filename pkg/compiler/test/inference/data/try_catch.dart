// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: returnInt1:[exact=JSUInt31]*/
returnInt1() {
  var a = 42;
  try {
    a = 54;
  } catch (e) {}
  return a;
}

/*member: returnDyn1:Union([exact=JSString], [exact=JSUInt31])*/
returnDyn1() {
  dynamic a = 42;
  try {
    a = 'foo';
  } catch (e) {}
  return a;
}

/*member: returnInt2:[exact=JSUInt31]*/
returnInt2() {
  var a = 42;
  try {
    a = 54;
  } catch (e) {
    a = 2;
  }
  return a;
}

/*member: returnDyn2:Union([exact=JSString], [exact=JSUInt31])*/
returnDyn2() {
  dynamic a = 42;
  try {
    a = 54;
  } catch (e) {
    a = 'foo';
  }
  return a;
}

/*member: returnInt3:[exact=JSUInt31]*/
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

/*member: returnDyn3:Union([exact=JSString], [exact=JSUInt31])*/
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

/*member: returnInt4:[exact=JSUInt31]*/
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

/*member: returnDyn4:Union([exact=JSString], [exact=JSUInt31])*/
returnDyn4() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31]*/ == 54) {
    try {
      a = 'foo';
    } catch (e) {}
  }
  return a;
}

/*member: returnInt5:[exact=JSUInt31]*/
returnInt5() {
  var a = 42;
  if (a /*invoke: [exact=JSUInt31]*/ == 54) {
    try {
      a = 42;
    } catch (e) {}
  }
  return a;
}

/*member: returnDyn5:Union([exact=JSString], [exact=JSUInt31])*/
returnDyn5() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31]*/ == 54) {
    try {
      a = 'foo';
      print(a);
      a = 42;
    } catch (e) {}
  }
  return a;
}

/*member: returnInt6:[subclass=JSInt]*/
returnInt6() {
  try {
    throw 42;
  } on int catch (e) {
    return e;
  }
  // ignore: dead_code
  return 42;
}

/*member: returnDyn6:[subclass=Object]*/
returnDyn6() {
  try {
    throw 42;
  } catch (e) {
    return e;
  }
}

/*member: returnDyn7:[null|subclass=Object]*/
returnDyn7() {
  try {
    // Do nothing
  } catch (e) {
    return e;
  }
}

/*member: returnInt7:[exact=JSUInt31]*/
returnInt7() {
  dynamic a = 'foo';
  try {
    a = 42;
    return a;
  } catch (e) {}
  return 2;
}

/*member: returnInt8:[exact=JSUInt31]*/
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

/*member: returnUnion1:[null|exact=JSUInt31]*/
returnUnion1() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31]*/ == 54) {
    try {
      a = 'foo';
      throw a;
    } catch (e) {
      a = null;
    }
  }
  return a;
}

/*member: returnUnion2:Union(null, [exact=JSBool], [exact=JSString], [exact=JSUInt31])*/
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

/*member: returnUnion3:Union([exact=JSString], [exact=JSUInt31])*/
returnUnion3() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31]*/ == 54) {
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

/*member: returnUnion4:Union(null, [exact=JSString], [exact=JSUInt31])*/
returnUnion4() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31]*/ == 54) {
    try {
      a = 'foo';
      a = null;
    } catch (e) {}
  }
  return a;
}

/*member: returnUnion5:Union([exact=JSBool], [exact=JSUInt31])*/
returnUnion5() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31]*/ == 54) {
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

/*member: returnUnion6:Union(null, [exact=JSBool], [exact=JSString])*/
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

/*member: returnUnion7:Union([exact=JSBool], [exact=JSString])*/
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

/*member: returnUnion8:[null|exact=JSUInt31]*/
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

/*member: returnUnion9:[exact=JSBool]*/
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

/*member: returnUnion10:Value([exact=JSBool], value: true)*/
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

/*member: returnNull1:[null]*/
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

/*member: returnNull2:[null]*/
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

/*member: A.:[exact=A]*/
class A {
  /*member: A.a:[null|exact=JSUInt31]*/
  dynamic a;
  /*member: A.b:Union(null, [exact=JSUInt31], [exact=JsLinkedHashMap])*/
  dynamic b;
  /*member: A.c:Union(null, [exact=JSBool], [exact=JSString])*/
  dynamic c;
  /*member: A.d:Value([null|exact=JSString], value: "foo")*/
  dynamic d;
  /*member: A.e:Union(null, [exact=JSBool], [exact=JSString])*/
  dynamic e;
  /*member: A.f:Union(null, [exact=JSBool], [exact=JSString])*/
  dynamic f;
  /*member: A.g:Union(null, [exact=JSExtendableArray], [exact=JSNumNotInt], [exact=JSString])*/
  dynamic g;

  /*member: A.testa:Union([exact=JSBool], [exact=JSString])*/
  testa() {
    try {
      return 'foo';
    } catch (e) {
      return true;
    } finally {
      /*update: [exact=A]*/ a = 55;
    }
  }

  /*member: A.testb:Union([exact=JSBool], [exact=JSString])*/
  testb() {
    try {
      return 'foo';
    } catch (e) {
      return true;
    } finally {
      /*update: [exact=A]*/ b = 55;
    }
    return b;
  }

  /*member: A.testc:Union(null, [exact=JSBool], [exact=JSString])*/
  testc() {
    try {
      /*update: [exact=A]*/ c = 'foo';
      throw /*[exact=A]*/ c;
    } catch (e) {
      /*update: [exact=A]*/ c = false;
    } catch (e) {
      /*update: [exact=A]*/ c = true;
    }
    return /*[exact=A]*/ c;
  }

  /*member: A.testd:Value([null|exact=JSString], value: "foo")*/
  testd() {
    try {
      /*update: [exact=A]*/ d = 'foo';
    } catch (e) {
      // Do nothing
    }
    return /*[exact=A]*/ d;
  }

  /*member: A.teste:Union(null, [exact=JSBool], [exact=JSString])*/
  teste() {
    try {
      /*update: [exact=A]*/ e = 'foo';
    } catch (_) {
      /*update: [exact=A]*/ e = true;
    }
    return /*[exact=A]*/ e;
  }

  /*member: A.testf:Union(null, [exact=JSBool], [exact=JSString], [exact=JSUInt31])*/
  testf() {
    try {
      /*update: [exact=A]*/ f = 'foo';
      return 3;
    } catch (e) {
      /*update: [exact=A]*/ f = true;
    }
    return /*[exact=A]*/ f;
  }

  /*member: A.testg:Union(null, [exact=JSUInt31], [exact=JsLinkedHashMap])*/
  testg() {
    try {
      /*update: [exact=A]*/ g = 'foo';
      /*update: [exact=A]*/ g = 5.5;
    } catch (e) {
      /*update: [exact=A]*/ g = [];
      /*update: [exact=A]*/ b = {};
    }
    return /*[exact=A]*/ b;
  }
}

/*member: main:[null]*/
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
  a. /*invoke: [exact=A]*/ testa();
  a. /*invoke: [exact=A]*/ testb();
  a. /*invoke: [exact=A]*/ testc();
  a. /*invoke: [exact=A]*/ testd();
  a. /*invoke: [exact=A]*/ teste();
  a. /*invoke: [exact=A]*/ testf();
  a. /*invoke: [exact=A]*/ testg();
}
