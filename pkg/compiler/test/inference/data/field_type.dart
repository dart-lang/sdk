// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
  test7();
  test8();
  test9();
  test10();
  test11();
  test12();
  test13();
  test14();
  test15();
  test16();
  test17();
  test18();
  test19();
  test20();
  test20b();
  test22();
  test23();
  test24();
  test25();
  test26();
  test27();
  test28();
  test29();
  test30();
}

/*member: A1.:[exact=A1|powerset={N}]*/
class A1 {
  /*member: A1.f1:[null|powerset={null}]*/
  int? f1;
}

/*member: test1:[null|powerset={null}]*/
test1() {
  A1();
}

/*member: A2.:[exact=A2|powerset={N}]*/
class A2 {
  /*member: A2.f2a:[null|powerset={null}]*/
  int? f2a;

  /*member: A2.f2b:[exact=JSUInt31|powerset={I}]*/
  int f2b = 1;
}

/*member: test2:[null|powerset={null}]*/
test2() {
  A2();
}

class A3 {
  /*member: A3.f3a:[exact=JSUInt31|powerset={I}]*/
  int f3a;

  /*member: A3.f3b:[null|exact=JSUInt31|powerset={null}{I}]*/
  int? f3b;

  /*member: A3.:[exact=A3|powerset={N}]*/
  A3() : f3a = 1;
}

/*member: test3:[null|powerset={null}]*/
test3() {
  A3(). /*update: [exact=A3|powerset={N}]*/ f3b = 2;
}

class A4 {
  /*member: A4.f4a:Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  dynamic f4a;

  /*member: A4.f4b:Value([null|exact=JSString|powerset={null}{I}], value: "a", powerset: {null}{I})*/
  dynamic f4b;

  /*member: A4.:[exact=A4|powerset={N}]*/
  A4() : f4a = 1;
}

/*member: test4:[null|powerset={null}]*/
test4() {
  A4 a = A4();
  a. /*update: [exact=A4|powerset={N}]*/ f4a = "a";
  a. /*update: [exact=A4|powerset={N}]*/ f4b = "a";
}

class A5 {
  /*member: A5.f5a:Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  dynamic f5a = 1;

  /*member: A5.f5b:Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  dynamic f5b = 1;

  /*member: A5.:[exact=A5|powerset={N}]*/
  A5(/*[exact=JSBool|powerset={I}]*/ x) {
    /*update: [exact=A5|powerset={N}]*/
    f5a = "1";
    if (x) {
      /*update: [exact=A5|powerset={N}]*/
      f5b = "1";
    } else {
      /*update: [exact=A5|powerset={N}]*/
      f5b = "2";
    }
  }
}

/*member: test5:[null|powerset={null}]*/
test5() {
  A5(true);
  A5(false);
}

class A6 {
  /*member: A6.f6a:Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  dynamic f6a = 1;

  /*member: A6.f6b:Union([exact=JSExtendableArray|powerset={I}], [exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  dynamic f6b = 1;

  /*member: A6.:[exact=A6|powerset={N}]*/
  A6(/*[exact=JSBool|powerset={I}]*/ x) {
    /*update: [exact=A6|powerset={N}]*/
    f6a = "1";
    if (x) {
      /*update: [exact=A6|powerset={N}]*/
      f6b = "1";
    } else {
      /*update: [exact=A6|powerset={N}]*/
      f6b = "2";
    }
    if (x) {
      /*update: [exact=A6|powerset={N}]*/
      f6b = [];
    } else {
      /*update: [exact=A6|powerset={N}]*/
      f6b = [];
    }
  }
}

/*member: test6:[null|powerset={null}]*/
test6() {
  A6(true);
  A6(false);
}

class A7 {
  /*member: A7.f7a:Union([exact=JSExtendableArray|powerset={I}], [exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  dynamic f7a = 1;

  /*member: A7.f7b:Union([exact=JSExtendableArray|powerset={I}], [exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  dynamic f7b = 1;

  /*member: A7.:[exact=A7|powerset={N}]*/
  A7(/*[exact=JSBool|powerset={I}]*/ x) {
    /*update: [exact=A7|powerset={N}]*/
    f7a = "1";
    if (x) {
      /*update: [exact=A7|powerset={N}]*/
      f7b = "1";
    } else {
      /*update: [exact=A7|powerset={N}]*/
      f7b = "2";
    }
    if (x) {
      /*update: [exact=A7|powerset={N}]*/
      f7a = [];
      /*update: [exact=A7|powerset={N}]*/
      f7b = [];
    } else {
      /*update: [exact=A7|powerset={N}]*/
      f7b = [];
    }
  }
}

/*member: test7:[null|powerset={null}]*/
test7() {
  A7(true);
  A7(false);
}

class A8 {
  /*member: A8.f8:Value([null|exact=JSString|powerset={null}{I}], value: "1", powerset: {null}{I})*/
  dynamic f8;

  /*member: A8.:[exact=A8|powerset={N}]*/
  A8(/*[exact=JSBool|powerset={I}]*/ x) {
    if (x) {
      /*update: [exact=A8|powerset={N}]*/
      f8 = "1";
    } else {}
  }
}

/*member: test8:[null|powerset={null}]*/
test8() {
  A8(true);
  A8(false);
}

class A9 {
  /*member: A9.f9:Value([null|exact=JSString|powerset={null}{I}], value: "1", powerset: {null}{I})*/
  dynamic f9;

  /*member: A9.:[exact=A9|powerset={N}]*/
  A9(/*[exact=JSBool|powerset={I}]*/ x) {
    if (x) {
    } else {
      /*update: [exact=A9|powerset={N}]*/
      f9 = "1";
    }
  }
}

/*member: test9:[null|powerset={null}]*/
test9() {
  A9(true);
  A9(false);
}

class A10 {
  /*member: A10.f10:[exact=JSUInt31|powerset={I}]*/
  int? f10;

  /*member: A10.:[exact=A10|powerset={N}]*/
  A10() {
    /*update: [exact=A10|powerset={N}]*/
    f10 = 1;
  }
  /*member: A10.m10:[subclass=JSUInt32|powerset={I}]*/
  m10() => /*[exact=A10|powerset={N}]*/
      f10! /*invoke: [exact=JSUInt31|powerset={I}]*/ + 1;
}

/*member: f10:[null|powerset={null}]*/
void f10(/*[null|powerset={null}]*/ x) {
  x. /*update: [null|powerset={null}]*/ f10 = "2";
}

/*member: test10:[null|powerset={null}]*/
test10() {
  A10? a;
  f10(a);
  a = A10();
  a. /*invoke: [exact=A10|powerset={N}]*/ m10();
}

/*member: S11.:[exact=S11|powerset={N}]*/
class S11 {
  /*member: S11.fs11:[exact=JSUInt31|powerset={I}]*/
  int fs11 = 1;

  /*member: S11.ms11:[null|powerset={null}]*/
  ms11() {
    /*update: [exact=A11|powerset={N}]*/
    fs11 = 1;
  }
}

/*member: A11.:[exact=A11|powerset={N}]*/
class A11 extends S11 {
  /*member: A11.m11:[null|powerset={null}]*/
  m11() {
    /*invoke: [exact=A11|powerset={N}]*/
    ms11();
  }
}

/*member: test11:[null|powerset={null}]*/
test11() {
  A11 a = A11();
  a. /*invoke: [exact=A11|powerset={N}]*/ m11();
}

class S12 {
  /*member: S12.fs12:Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  dynamic fs12 = 1;

  /*member: S12.:[exact=S12|powerset={N}]*/
  S12() {
    /*update: [exact=A12|powerset={N}]*/
    fs12 = "2";
  }
}

/*member: A12.:[exact=A12|powerset={N}]*/
class A12 extends S12 {}

/*member: test12:[null|powerset={null}]*/
test12() {
  A12();
}

class S13 {
  /*member: S13.fs13:[exact=JSUInt31|powerset={I}]*/
  int? fs13;

  /*member: S13.:[exact=S13|powerset={N}]*/
  S13() {
    /*update: [exact=A13|powerset={N}]*/
    fs13 = 1;
  }
}

class A13 extends S13 {
  /*member: A13.:[exact=A13|powerset={N}]*/
  A13() {
    /*update: [exact=A13|powerset={N}]*/
    fs13 = 1;
  }
}

/*member: test13:[null|powerset={null}]*/
test13() {
  A13();
}

class A14 {
  /*member: A14.f14:[exact=JSUInt31|powerset={I}]*/
  var f14;

  /*member: A14.:[exact=A14|powerset={N}]*/
  A14() {
    /*update: [exact=A14|powerset={N}]*/
    f14 = 1;
  }
  /*member: A14.other:[exact=A14|powerset={N}]*/
  A14.other() {
    /*update: [exact=A14|powerset={N}]*/
    f14 = 2;
  }
}

/*member: test14:[null|powerset={null}]*/
test14() {
  // ignore: unused_local_variable
  A14 a = A14();
  a = A14.other();
}

class A15 {
  /*member: A15.f15:Union([exact=JSExtendableArray|powerset={I}], [exact=JSString|powerset={I}], powerset: {I})*/
  var f15;

  /*member: A15.:[exact=A15|powerset={N}]*/
  A15() {
    /*update: [exact=A15|powerset={N}]*/
    f15 = "1";
  }

  /*member: A15.other:[exact=A15|powerset={N}]*/
  A15.other() {
    /*update: [exact=A15|powerset={N}]*/
    f15 = [];
  }
}

/*member: test15:[null|powerset={null}]*/
test15() {
  // ignore: unused_local_variable
  A15 a = A15();
  a = A15.other();
}

class A16 {
  // TODO(johnniwinther): Investigate why these include `null`. The ast version
  // didn't.

  /*member: A16.f16:Union(null, [exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {null}{I})*/
  var f16;

  /*member: A16.:[exact=A16|powerset={N}]*/
  A16() {
    /*update: [exact=A16|powerset={N}]*/
    f16 = "1";
  }

  /*member: A16.other:[exact=A16|powerset={N}]*/
  A16.other() : f16 = 1 {}
}

/*member: test16:[null|powerset={null}]*/
test16() {
  // ignore: unused_local_variable
  A16 a = A16();
  a = A16.other();
}

/*member: g17:[exact=JSUInt31|powerset={I}]*/
g17([/*[exact=A17|powerset={N}]*/ p]) =>
    p. /*update: [exact=A17|powerset={N}]*/ f17 = 1;

class A17 {
  /*member: A17.f17:[null|exact=JSUInt31|powerset={null}{I}]*/
  var f17;

  /*member: A17.:[exact=A17|powerset={N}]*/
  A17(/*[exact=JSBool|powerset={I}]*/ x) {
    var a;
    if (x) {
      a = this;
    } else {
      a = g17;
    }
    a(this);
  }
}

/*member: test17:[null|powerset={null}]*/
test17() {
  A17(true);
  A17(false);
}

class A18 {
  /*member: A18.f18a:[exact=JSUInt31|powerset={I}]*/
  var f18a;

  /*member: A18.f18b:Value([exact=JSString|powerset={I}], value: "1", powerset: {I})*/
  var f18b;

  /*member: A18.f18c:Union(null, [exact=A18|powerset={N}], [exact=JSUInt31|powerset={I}], powerset: {null}{IN})*/
  var f18c;

  /*member: A18.:[exact=A18|powerset={N}]*/
  A18(/*[exact=JSBool|powerset={I}]*/ x) {
    /*update: [exact=A18|powerset={N}]*/
    f18a = 1;
    var a;
    if (x) {
      /*update: [exact=A18|powerset={N}]*/
      f18b = "1";
      a = this;
    } else {
      a = 1;
      /*update: [exact=A18|powerset={N}]*/
      f18b = "1";
    }
    /*update: [exact=A18|powerset={N}]*/
    f18c = a;
  }
}

/*member: test18:[null|powerset={null}]*/
test18() {
  A18(true);
  A18(false);
}

class A19 {
  /*member: A19.f19a:[exact=JSUInt31|powerset={I}]*/
  var f19a;

  /*member: A19.f19b:Value([exact=JSString|powerset={I}], value: "1", powerset: {I})*/
  var f19b;

  /*member: A19.f19c:Union(null, [exact=A19|powerset={N}], [exact=JSUInt31|powerset={I}], powerset: {null}{IN})*/
  var f19c;

  /*member: A19.:[exact=A19|powerset={N}]*/
  A19(/*[exact=JSBool|powerset={I}]*/ x) {
    /*update: [exact=A19|powerset={N}]*/
    f19a = 1;
    var a;
    if (x) {
      /*update: [exact=A19|powerset={N}]*/
      f19b = "1";
      a = this;
    } else {
      a = 1;
      /*update: [exact=A19|powerset={N}]*/
      f19b = "1";
    }
    /*update: [exact=A19|powerset={N}]*/
    f19c = a;
    a();
  }
}

/*member: test19:[null|powerset={null}]*/
test19() {
  A19(true);
  A19(false);
}

class A20 {
  /*member: A20.f20:[null|powerset={null}]*/
  var f20;

  /*member: A20.:[exact=A20|powerset={N}]*/
  A20() {
    dynamic a = this;
    /*iterator: [exact=A20|powerset={N}]*/
    /*current: [empty|powerset=empty]*/
    /*moveNext: [empty|powerset=empty]*/
    for ( /*update: [exact=A20|powerset={N}]*/ f20 in a) {}
  }

  get iterator => this;

  get current => 42;

  bool moveNext() => false;
}

/*member: test20:[null|powerset={null}]*/
test20() {
  A20();
}

class A20b extends Iterable implements Iterator {
  /*member: A20b.f20b:[null|exact=JSUInt31|powerset={null}{I}]*/
  var f20b;

  /*member: A20b.:[exact=A20b|powerset={N}]*/
  A20b() {
    dynamic a = this;
    /*iterator: [exact=A20b|powerset={N}]*/
    /*current: [exact=A20b|powerset={N}]*/
    /*moveNext: [exact=A20b|powerset={N}]*/
    for ( /*update: [exact=A20b|powerset={N}]*/ f20b in a) {}
  }

  /*member: A20b.iterator:[exact=A20b|powerset={N}]*/
  @override
  get iterator => this;

  /*member: A20b.current:[exact=JSUInt31|powerset={I}]*/
  @override
  get current => 42;

  /*member: A20b.moveNext:Value([exact=JSBool|powerset={I}], value: false, powerset: {I})*/
  @override
  bool moveNext() => false;
}

/*member: test20b:[null|powerset={null}]*/
test20b() {
  A20b();
}

class A22 {
  /*member: A22.f22a:[exact=JSUInt31|powerset={I}]*/
  var f22a;

  /*member: A22.f22b:[exact=JSUInt31|powerset={I}]*/
  var f22b;

  /*member: A22.f22c:Value([null|exact=JSString|powerset={null}{I}], value: "foo", powerset: {null}{I})*/
  var f22c;

  /*member: A22.:[exact=A22|powerset={N}]*/
  A22() {
    /*update: [exact=A22|powerset={N}]*/
    f22a = 42;
    /*update: [exact=A22|powerset={N}]*/
    f22b = /*[exact=A22|powerset={N}]*/
        f22a == null
            ? 42
            : /*[exact=A22|powerset={N}]*/ f22c == null
            ? 41
            : 43;
    /*update: [exact=A22|powerset={N}]*/
    f22c = 'foo';
  }
}

/*member: test22:[null|powerset={null}]*/
test22() {
  A22();
}

class A23 {
  /*member: A23.f23a:[null|exact=JSUInt31|powerset={null}{I}]*/
  int? f23a = 42;

  /*member: A23.f23b:[null|exact=JSUInt31|powerset={null}{I}]*/
  int? f23b = 42;

  /*member: A23.f23c:[null|exact=JSUInt31|powerset={null}{I}]*/
  int? f23c = 42;

  /*member: A23.f23d:[null|exact=JSUInt31|powerset={null}{I}]*/
  int? f23d = 42;

  /*member: A23.:[exact=A23|powerset={N}]*/
  A23() {
    // Test string interpolation.
    '${ /*update: [exact=A23|powerset={N}]*/ f23a = null}';
    // Test string juxtaposition.
    ''
        '${ /*update: [exact=A23|powerset={N}]*/ f23b = null}';
    // Test list literal.
    [/*update: [exact=A23|powerset={N}]*/ f23c = null];
    // Test map literal.
    // ignore: unused_local_variable
    var c = {'foo': /*update: [exact=A23|powerset={N}]*/ f23d = null};
  }
}

/*member: test23:[null|powerset={null}]*/
test23() {
  A23();
}

class A24 {
  /*member: A24.f24a:[subclass=JSPositiveInt|powerset={I}]*/
  var f24a = 42;

  /*member: A24.f24b:[subclass=JSPositiveInt|powerset={I}]*/
  var f24b = 42;

  /*member: A24.f24c:[exact=JSUInt31|powerset={I}]*/
  var f24c = 42;

  /*member: A24.f24d:[exact=JSUInt31|powerset={I}]*/
  final f24d;

  /*member: A24.f24e:Union(null, [exact=JSNumNotInt|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {null}{I})*/
  var f24e;

  /*member: A24.f24f:Value([null|exact=JSString|powerset={null}{I}], value: "foo", powerset: {null}{I})*/
  var f24f = null;

  /*member: A24.:[exact=A24|powerset={N}]*/
  A24() : f24d = 42 {
    /*[subclass=A24|powerset={N}]*/ /*update: [subclass=A24|powerset={N}]*/
    f24a /*invoke: [subclass=JSPositiveInt|powerset={I}]*/ ++;
    /*[subclass=A24|powerset={N}]*/ /*update: [subclass=A24|powerset={N}]*/
    f24b /*invoke: [subclass=JSPositiveInt|powerset={I}]*/ += 42;
    var f24f = 'foo';
    this. /*update: [subclass=A24|powerset={N}]*/ f24f = f24f;
  }

  /*member: A24.foo:[exact=A24|powerset={N}]*/
  A24.foo(/*[subclass=A24|powerset={N}]*/ other)
    : f24c = other. /*[subclass=A24|powerset={N}]*/ f24c,
      f24d = other. /*[subclass=A24|powerset={N}]*/ f24d,
      f24e = other. /*invoke: [subclass=A24|powerset={N}]*/ bar24();

  /*member: A24.+:Value([exact=JSString|powerset={I}], value: "foo", powerset: {I})*/
  operator +(/*[empty|powerset=empty]*/ other) => 'foo';

  /*member: A24.bar24:[exact=JSNumNotInt|powerset={I}]*/
  bar24() => 42.5;
}

/*member: B24.:[exact=B24|powerset={N}]*/
class B24 extends A24 {
  /*member: B24.bar24:[exact=JSUInt31|powerset={I}]*/
  @override
  bar24() => 42;
}

/*member: test24:[null|powerset={null}]*/
test24() {
  A24();
  A24.foo(new A24());
  A24.foo(new B24());
}

/*member: A25.:[exact=A25|powerset={N}]*/
class A25 {
  /*member: A25.f25:[exact=JSUInt31|powerset={I}]*/
  var f25 = 42;
}

/*member: B25.:[exact=B25|powerset={N}]*/
class B25 {
  /*member: B25.f25:Value([exact=JSString|powerset={I}], value: "42", powerset: {I})*/
  var f25 = '42';
}

/*member: test25:[null|powerset={null}]*/
test25() {
  B25();
  A25(). /*update: [exact=A25|powerset={N}]*/ f25 =
      A25(). /*[exact=A25|powerset={N}]*/ f25;
}

/*member: A26.:[exact=A26|powerset={N}]*/
class A26 {
  /*member: A26.f26:[subclass=JSPositiveInt|powerset={I}]*/
  var f26 = 42;
}

/*member: B26.:[exact=B26|powerset={N}]*/
class B26 {
  /*member: B26.f26:[exact=JSUInt31|powerset={I}]*/
  var f26 = 54;
}

/*member: test26:[null|powerset={null}]*/
test26() {
  A26(). /*update: [exact=A26|powerset={N}]*/ f26 =
      <dynamic>[new B26(), A26()]
      /*Container([exact=JSExtendableArray|powerset={I}], element: Union([exact=A26|powerset={N}], [exact=B26|powerset={N}], powerset: {N}), length: 2, powerset: {I})*/
      [0]. /*Union([exact=A26|powerset={N}], [exact=B26|powerset={N}], powerset: {N})*/ f26 /*invoke: [subclass=JSPositiveInt|powerset={I}]*/ +
      42;
}

class A27 {
  /*member: A27.f27a:[exact=JSUInt31|powerset={I}]*/
  var f27a;

  /*member: A27.f27b:[null|exact=JSUInt31|powerset={null}{I}]*/
  var f27b;

  /*member: A27.:[exact=A27|powerset={N}]*/
  A27() {
    this. /*update: [subclass=A27|powerset={N}]*/ f27a = 42;
    this. /*update: [subclass=A27|powerset={N}]*/ f27b = 42;
  }
}

/*member: B27.:[exact=B27|powerset={N}]*/
class B27 extends A27 {
  @override
  set f27b(/*[null|exact=JSUInt31|powerset={null}{I}]*/ value) {}
}

/*member: test27:[null|powerset={null}]*/
test27() {
  A27();
  B27();
}

class A28 {
  /*member: A28.f28a:[exact=JSUInt31|powerset={I}]*/
  var f28a;

  /*member: A28.f28b:[null|exact=JSUInt31|powerset={null}{I}]*/
  var f28b;

  /*member: A28.:[exact=A28|powerset={N}]*/
  A28(/*[exact=JSUInt31|powerset={I}]*/ x) {
    this. /*update: [exact=A28|powerset={N}]*/ f28a = x;
    if (x /*invoke: [exact=JSUInt31|powerset={I}]*/ == 0) return;
    this. /*update: [exact=A28|powerset={N}]*/ f28b = x;
  }
}

/*member: test28:[null|powerset={null}]*/
test28() {
  A28(0);
  A28(1);
}

class A29 {
  /*member: A29.f29a:[exact=JSUInt31|powerset={I}]*/
  var f29a;

  /*member: A29.f29b:[null|exact=JSUInt31|powerset={null}{I}]*/
  var f29b;

  /*member: A29.:[exact=A29|powerset={N}]*/
  A29(/*[exact=JSUInt31|powerset={I}]*/ x) {
    this. /*update: [exact=A29|powerset={N}]*/ f29a = x;
    if (x /*invoke: [exact=JSUInt31|powerset={I}]*/ == 0) {
    } else {
      return;
    }
    this. /*update: [exact=A29|powerset={N}]*/ f29b = x;
  }
}

/*member: test29:[null|powerset={null}]*/
test29() {
  A29(0);
  A29(1);
}

class A30 {
  /*member: A30.f30a:[exact=JSUInt31|powerset={I}]*/
  var f30a;

  /*member: A30.f30b:[exact=JSUInt31|powerset={I}]*/
  var f30b;

  /*member: A30.f30c:[null|exact=JSUInt31|powerset={null}{I}]*/
  var f30c;

  /*member: A30.:[exact=A30|powerset={N}]*/
  A30(/*[exact=JSUInt31|powerset={I}]*/ x) {
    this. /*update: [exact=A30|powerset={N}]*/ f30a = x;
    if (x /*invoke: [exact=JSUInt31|powerset={I}]*/ == 0) {
      this. /*update: [exact=A30|powerset={N}]*/ f30b = 1;
    } else {
      this. /*update: [exact=A30|powerset={N}]*/ f30b = x;
      return;
    }
    this. /*update: [exact=A30|powerset={N}]*/ f30c = x;
  }
}

/*member: test30:[null|powerset={null}]*/
test30() {
  A30(0);
  A30(1);
}
