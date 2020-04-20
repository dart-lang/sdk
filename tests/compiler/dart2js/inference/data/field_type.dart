// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
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
  test21();
  test21b();
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

/*member: A1.:[exact=A1]*/
class A1 {
  /*member: A1.f1:[null]*/
  int f1;
}

/*member: test1:[null]*/
test1() {
  new A1();
}

/*member: A2.:[exact=A2]*/
class A2 {
  /*member: A2.f2a:[null]*/
  int f2a;

  /*member: A2.f2b:[exact=JSUInt31]*/
  int f2b = 1;
}

/*member: test2:[null]*/
test2() {
  new A2();
}

class A3 {
  /*member: A3.f3a:[exact=JSUInt31]*/
  int f3a;

  /*member: A3.f3b:[null|exact=JSUInt31]*/
  int f3b;

  /*member: A3.:[exact=A3]*/
  A3() : f3a = 1;
}

/*member: test3:[null]*/
test3() {
  new A3(). /*update: [exact=A3]*/ f3b = 2;
}

class A4 {
  /*member: A4.f4a:Union([exact=JSString], [exact=JSUInt31])*/
  dynamic f4a;

  /*member: A4.f4b:Value([null|exact=JSString], value: "a")*/
  dynamic f4b;

  /*member: A4.:[exact=A4]*/
  A4() : f4a = 1;
}

/*member: test4:[null]*/
test4() {
  A4 a = new A4();
  a. /*update: [exact=A4]*/ f4a = "a";
  a. /*update: [exact=A4]*/ f4b = "a";
}

class A5 {
  /*member: A5.f5a:Union([exact=JSString], [exact=JSUInt31])*/
  dynamic f5a = 1;

  /*member: A5.f5b:Union([exact=JSString], [exact=JSUInt31])*/
  dynamic f5b = 1;

  /*member: A5.:[exact=A5]*/
  A5(/*[exact=JSBool]*/ x) {
    /*update: [exact=A5]*/ f5a = "1";
    if (x) {
      /*update: [exact=A5]*/ f5b = "1";
    } else {
      /*update: [exact=A5]*/ f5b = "2";
    }
  }
}

/*member: test5:[null]*/
test5() {
  new A5(true);
  new A5(false);
}

class A6 {
  /*member: A6.f6a:Union([exact=JSString], [exact=JSUInt31])*/
  dynamic f6a = 1;

  /*member: A6.f6b:Union([exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31])*/
  dynamic f6b = 1;

  /*member: A6.:[exact=A6]*/
  A6(/*[exact=JSBool]*/ x) {
    /*update: [exact=A6]*/ f6a = "1";
    if (x) {
      /*update: [exact=A6]*/ f6b = "1";
    } else {
      /*update: [exact=A6]*/ f6b = "2";
    }
    if (x) {
      /*update: [exact=A6]*/ f6b = new List();
    } else {
      /*update: [exact=A6]*/ f6b = new List();
    }
  }
}

/*member: test6:[null]*/
test6() {
  new A6(true);
  new A6(false);
}

class A7 {
  /*member: A7.f7a:Union([exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31])*/
  dynamic f7a = 1;

  /*member: A7.f7b:Union([exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31])*/
  dynamic f7b = 1;

  /*member: A7.:[exact=A7]*/
  A7(/*[exact=JSBool]*/ x) {
    /*update: [exact=A7]*/ f7a = "1";
    if (x) {
      /*update: [exact=A7]*/ f7b = "1";
    } else {
      /*update: [exact=A7]*/ f7b = "2";
    }
    if (x) {
      /*update: [exact=A7]*/ f7a = new List();
      /*update: [exact=A7]*/ f7b = new List();
    } else {
      /*update: [exact=A7]*/ f7b = new List();
    }
  }
}

/*member: test7:[null]*/
test7() {
  new A7(true);
  new A7(false);
}

class A8 {
  /*member: A8.f8:Value([null|exact=JSString], value: "1")*/
  dynamic f8;

  /*member: A8.:[exact=A8]*/
  A8(/*[exact=JSBool]*/ x) {
    if (x) {
      /*update: [exact=A8]*/ f8 = "1";
    } else {}
  }
}

/*member: test8:[null]*/
test8() {
  new A8(true);
  new A8(false);
}

class A9 {
  /*member: A9.f9:Value([null|exact=JSString], value: "1")*/
  dynamic f9;

  /*member: A9.:[exact=A9]*/
  A9(/*[exact=JSBool]*/ x) {
    if (x) {
    } else {
      /*update: [exact=A9]*/ f9 = "1";
    }
  }
}

/*member: test9:[null]*/
test9() {
  new A9(true);
  new A9(false);
}

class A10 {
  /*member: A10.f10:[exact=JSUInt31]*/
  int f10;

  /*member: A10.:[exact=A10]*/
  A10() {
    /*update: [exact=A10]*/ f10 = 1;
  }
  /*member: A10.m10:[subclass=JSUInt32]*/
  m10() => /*[exact=A10]*/ f10 /*invoke: [exact=JSUInt31]*/ + 1;
}

/*member: f10:[null]*/
void f10(/*[null]*/ x) {
  x. /*update: [null]*/ f10 = "2";
}

/*member: test10:[null]*/
test10() {
  A10 a;
  f10(a);
  a = new A10();
  a. /*invoke: [exact=A10]*/ m10();
}

/*member: S11.:[exact=S11]*/
class S11 {
  /*member: S11.fs11:[exact=JSUInt31]*/
  int fs11 = 1;

  /*member: S11.ms11:[null]*/
  ms11() {
    /*update: [exact=A11]*/ fs11 = 1;
  }
}

/*member: A11.:[exact=A11]*/
class A11 extends S11 {
  /*member: A11.m11:[null]*/
  m11() {
    /*invoke: [exact=A11]*/ ms11();
  }
}

/*member: test11:[null]*/
test11() {
  A11 a = new A11();
  a. /*invoke: [exact=A11]*/ m11();
}

class S12 {
  /*member: S12.fs12:Union([exact=JSString], [exact=JSUInt31])*/
  dynamic fs12 = 1;

  /*member: S12.:[exact=S12]*/
  S12() {
    /*update: [exact=A12]*/ fs12 = "2";
  }
}

/*member: A12.:[exact=A12]*/
class A12 extends S12 {}

/*member: test12:[null]*/
test12() {
  new A12();
}

class S13 {
/*member: S13.fs13:[exact=JSUInt31]*/
  int fs13;

  /*member: S13.:[exact=S13]*/
  S13() {
    /*update: [exact=A13]*/ fs13 = 1;
  }
}

class A13 extends S13 {
  /*member: A13.:[exact=A13]*/
  A13() {
    /*update: [exact=A13]*/ fs13 = 1;
  }
}

/*member: test13:[null]*/
test13() {
  new A13();
}

class A14 {
  /*member: A14.f14:[exact=JSUInt31]*/
  var f14;

  /*member: A14.:[exact=A14]*/
  A14() {
    /*update: [exact=A14]*/ f14 = 1;
  }
  /*member: A14.other:[exact=A14]*/
  A14.other() {
    /*update: [exact=A14]*/ f14 = 2;
  }
}

/*member: test14:[null]*/
test14() {
  // ignore: unused_local_variable
  A14 a = new A14();
  a = new A14.other();
}

class A15 {
  /*member: A15.f15:Union([exact=JSExtendableArray], [exact=JSString])*/
  var f15;

  /*member: A15.:[exact=A15]*/
  A15() {
    /*update: [exact=A15]*/ f15 = "1";
  }

  /*member: A15.other:[exact=A15]*/
  A15.other() {
    /*update: [exact=A15]*/ f15 = new List();
  }
}

/*member: test15:[null]*/
test15() {
  // ignore: unused_local_variable
  A15 a = new A15();
  a = new A15.other();
}

class A16 {
  // TODO(johnniwinther): Investigate why these include `null`. The ast version
  // didn't.

  /*member: A16.f16:Union(null, [exact=JSString], [exact=JSUInt31])*/
  var f16;

  /*member: A16.:[exact=A16]*/
  A16() {
    /*update: [exact=A16]*/ f16 = "1";
  }

  /*member: A16.other:[exact=A16]*/
  A16.other() : f16 = 1 {}
}

/*member: test16:[null]*/
test16() {
  // ignore: unused_local_variable
  A16 a = new A16();
  a = new A16.other();
}

/*member: g17:[exact=JSUInt31]*/
g17([/*[exact=A17]*/ p]) => p. /*update: [exact=A17]*/ f17 = 1;

class A17 {
/*member: A17.f17:[null|exact=JSUInt31]*/
  var f17;

  /*member: A17.:[exact=A17]*/
  A17(/*[exact=JSBool]*/ x) {
    var a;
    if (x) {
      a = this;
    } else {
      a = g17;
    }
    a(this);
  }
}

/*member: test17:[null]*/
test17() {
  new A17(true);
  new A17(false);
}

class A18 {
  /*member: A18.f18a:[exact=JSUInt31]*/
  var f18a;

  /*member: A18.f18b:Value([exact=JSString], value: "1")*/
  var f18b;

  /*member: A18.f18c:Union(null, [exact=A18], [exact=JSUInt31])*/
  var f18c;

  /*member: A18.:[exact=A18]*/
  A18(/*[exact=JSBool]*/ x) {
    /*update: [exact=A18]*/ f18a = 1;
    var a;
    if (x) {
      /*update: [exact=A18]*/ f18b = "1";
      a = this;
    } else {
      a = 1;
      /*update: [exact=A18]*/ f18b = "1";
    }
    /*update: [exact=A18]*/ f18c = a;
  }
}

/*member: test18:[null]*/
test18() {
  new A18(true);
  new A18(false);
}

class A19 {
  /*member: A19.f19a:[exact=JSUInt31]*/
  var f19a;

  /*member: A19.f19b:Value([exact=JSString], value: "1")*/
  var f19b;

  /*member: A19.f19c:Union(null, [exact=A19], [exact=JSUInt31])*/
  var f19c;

  /*member: A19.:[exact=A19]*/
  A19(/*[exact=JSBool]*/ x) {
    /*update: [exact=A19]*/ f19a = 1;
    var a;
    if (x) {
      /*update: [exact=A19]*/ f19b = "1";
      a = this;
    } else {
      a = 1;
      /*update: [exact=A19]*/ f19b = "1";
    }
    /*update: [exact=A19]*/ f19c = a;
    a();
  }
}

/*member: test19:[null]*/
test19() {
  new A19(true);
  new A19(false);
}

class A20 {
  /*member: A20.f20:[null]*/
  var f20;

  /*member: A20.:[exact=A20]*/
  A20() {
    dynamic a = this;
    /*iterator: [exact=A20]*/
    /*current: [empty]*/
    /*moveNext: [empty]*/
    for (/*update: [exact=A20]*/ f20 in a) {}
  }

  get iterator => this;

  get current => 42;

  bool moveNext() => false;
}

/*member: test20:[null]*/
test20() {
  new A20();
}

class A20b extends Iterable implements Iterator {
  /*member: A20b.f20b:[null|exact=JSUInt31]*/
  var f20b;

  /*member: A20b.:[exact=A20b]*/
  A20b() {
    dynamic a = this;
    /*iterator: [exact=A20b]*/
    /*current: [exact=A20b]*/
    /*moveNext: [exact=A20b]*/
    for (/*update: [exact=A20b]*/ f20b in a) {}
  }

  /*member: A20b.iterator:[exact=A20b]*/
  @override
  get iterator => this;

  /*member: A20b.current:[exact=JSUInt31]*/
  @override
  get current => 42;

  /*member: A20b.moveNext:Value([exact=JSBool], value: false)*/
  @override
  bool moveNext() => false;
}

/*member: test20b:[null]*/
test20b() {
  new A20b();
}

class A21 {
  /*member: A21.f21:[null|exact=JSUInt31]*/
  var f21;

  /*member: A21.:[exact=A21]*/
  A21() {
    dynamic a = this;
    /*iterator: [exact=A21]*/
    /*current: [empty]*/
    /*moveNext: [empty]*/
    for (
        // ignore: unused_local_variable
        var i in a) {}
    /*update: [exact=A21]*/ f21 = 42;
  }

  get iterator => null;
}

/*member: test21:[null]*/
test21() {
  new A21();
}

class A21b extends Iterable {
  /*member: A21b.f21:[null|exact=JSUInt31]*/
  var f21;

  /*member: A21b.:[exact=A21b]*/
  A21b() {
    dynamic a = this;
    /*iterator: [exact=A21b]*/
    /*current: [null]*/
    /*moveNext: [null]*/
    for (
        // ignore: unused_local_variable
        var i in a) {}
    /*update: [exact=A21b]*/ f21 = 42;
  }

  /*member: A21b.iterator:[null]*/
  @override
  get iterator => null;
}

/*member: test21b:[null]*/
test21b() {
  new A21b();
}

class A22 {
  /*member: A22.f22a:[exact=JSUInt31]*/
  var f22a;

  /*member: A22.f22b:[exact=JSUInt31]*/
  var f22b;

  /*member: A22.f22c:Value([null|exact=JSString], value: "foo")*/
  var f22c;

  /*member: A22.:[exact=A22]*/
  A22() {
    /*update: [exact=A22]*/ f22a = 42;
    /*update: [exact=A22]*/ f22b = /*[exact=A22]*/ f22a == null
        ? 42
        : /*[exact=A22]*/ f22c == null ? 41 : 43;
    /*update: [exact=A22]*/ f22c = 'foo';
  }
}

/*member: test22:[null]*/
test22() {
  new A22();
}

class A23 {
  /*member: A23.f23a:[null|exact=JSUInt31]*/
  var f23a = 42;

  /*member: A23.f23b:[null|exact=JSUInt31]*/
  var f23b = 42;

  /*member: A23.f23c:[null|exact=JSUInt31]*/
  var f23c = 42;

  /*member: A23.f23d:[null|exact=JSUInt31]*/
  var f23d = 42;

  /*member: A23.:[exact=A23]*/
  A23() {
    // Test string interpolation.
    '${/*update: [exact=A23]*/ f23a = null}';
    // Test string juxtaposition.
    ''
        '${/*update: [exact=A23]*/ f23b = null}';
    // Test list literal.
    [/*update: [exact=A23]*/ f23c = null];
    // Test map literal.
    // ignore: unused_local_variable
    var c = {'foo': /*update: [exact=A23]*/ f23d = null};
  }
}

/*member: test23:[null]*/
test23() {
  new A23();
}

class A24 {
  /*member: A24.f24a:[subclass=JSPositiveInt]*/
  var f24a = 42;

  /*member: A24.f24b:[subclass=JSPositiveInt]*/
  var f24b = 42;

  /*member: A24.f24c:[exact=JSUInt31]*/
  var f24c = 42;

  /*member: A24.f24d:[exact=JSUInt31]*/
  final f24d;

  /*member: A24.f24e:Union(null, [exact=JSDouble], [exact=JSUInt31])*/
  var f24e;

/*member: A24.f24f:Value([null|exact=JSString], value: "foo")*/
  var f24f = null;

  /*member: A24.:[exact=A24]*/
  A24() : f24d = 42 {
    /*[subclass=A24]*/ /*update: [subclass=A24]*/ f24a
        /*invoke: [subclass=JSPositiveInt]*/ ++;
    /*[subclass=A24]*/ /*update: [subclass=A24]*/ f24b
        /*invoke: [subclass=JSPositiveInt]*/ += 42;
    var f24f = 'foo';
    this. /*update: [subclass=A24]*/ f24f = f24f;
  }

  /*member: A24.foo:[exact=A24]*/
  A24.foo(/*[subclass=A24]*/ other)
      : f24c = other. /*[subclass=A24]*/ f24c,
        f24d = other. /*[subclass=A24]*/ f24d,
        f24e = other
            . /*invoke: [subclass=A24]*/
            bar24();

  /*member: A24.+:Value([exact=JSString], value: "foo")*/
  operator +(/*[empty]*/ other) => 'foo';

  /*member: A24.bar24:[exact=JSDouble]*/
  bar24() => 42.5;
}

/*member: B24.:[exact=B24]*/
class B24 extends A24 {
  /*member: B24.bar24:[exact=JSUInt31]*/
  @override
  bar24() => 42;
}

/*member: test24:[null]*/
test24() {
  new A24();
  new A24.foo(new A24());
  new A24.foo(new B24());
}

/*member: A25.:[exact=A25]*/
class A25 {
  /*member: A25.f25:[exact=JSUInt31]*/
  var f25 = 42;
}

/*member: B25.:[exact=B25]*/
class B25 {
  /*member: B25.f25:Value([exact=JSString], value: "42")*/
  var f25 = '42';
}

/*member: test25:[null]*/
test25() {
  new B25();
  new A25(). /*update: [exact=A25]*/ f25 = new A25(). /*[exact=A25]*/ f25;
}

/*member: A26.:[exact=A26]*/
class A26 {
  /*member: A26.f26:[subclass=JSPositiveInt]*/
  var f26 = 42;
}

/*member: B26.:[exact=B26]*/
class B26 {
  /*member: B26.f26:[exact=JSUInt31]*/
  var f26 = 54;
}

/*member: test26:[null]*/
test26() {
  new A26(). /*update: [exact=A26]*/ f26 = <dynamic>[new B26(), new A26()]
              /*Container([exact=JSExtendableArray], element: Union([exact=A26], [exact=B26]), length: 2)*/
              [0]
          . /*Union([exact=A26], [exact=B26])*/ f26
      /*invoke: [subclass=JSPositiveInt]*/ +
      42;
}

class A27 {
  /*member: A27.f27a:[exact=JSUInt31]*/
  var f27a;

  /*member: A27.f27b:[null|exact=JSUInt31]*/
  var f27b;

  /*member: A27.:[exact=A27]*/
  A27() {
    this. /*update: [subclass=A27]*/ f27a = 42;
    this. /*update: [subclass=A27]*/ f27b = 42;
  }
}

/*member: B27.:[exact=B27]*/
class B27 extends A27 {
  @override
  set f27b(/*[exact=JSUInt31]*/ value) {}
}

/*member: test27:[null]*/
test27() {
  new A27();
  new B27();
}

class A28 {
  /*member: A28.f28a:[exact=JSUInt31]*/
  var f28a;

  /*member: A28.f28b:[null|exact=JSUInt31]*/
  var f28b;

  /*member: A28.:[exact=A28]*/
  A28(/*[exact=JSUInt31]*/ x) {
    this. /*update: [exact=A28]*/ f28a = x;
    if (x /*invoke: [exact=JSUInt31]*/ == 0) return;
    this. /*update: [exact=A28]*/ f28b = x;
  }
}

/*member: test28:[null]*/
test28() {
  new A28(0);
  new A28(1);
}

class A29 {
  /*member: A29.f29a:[exact=JSUInt31]*/
  var f29a;

  /*member: A29.f29b:[null|exact=JSUInt31]*/
  var f29b;

  /*member: A29.:[exact=A29]*/
  A29(/*[exact=JSUInt31]*/ x) {
    this. /*update: [exact=A29]*/ f29a = x;
    if (x /*invoke: [exact=JSUInt31]*/ == 0) {
    } else {
      return;
    }
    this. /*update: [exact=A29]*/ f29b = x;
  }
}

/*member: test29:[null]*/
test29() {
  new A29(0);
  new A29(1);
}

class A30 {
  /*member: A30.f30a:[exact=JSUInt31]*/
  var f30a;

  /*member: A30.f30b:[exact=JSUInt31]*/
  var f30b;

  /*member: A30.f30c:[null|exact=JSUInt31]*/
  var f30c;

  /*member: A30.:[exact=A30]*/
  A30(/*[exact=JSUInt31]*/ x) {
    this. /*update: [exact=A30]*/ f30a = x;
    if (x /*invoke: [exact=JSUInt31]*/ == 0) {
      this. /*update: [exact=A30]*/ f30b = 1;
    } else {
      this. /*update: [exact=A30]*/ f30b = x;
      return;
    }
    this. /*update: [exact=A30]*/ f30c = x;
  }
}

/*member: test30:[null]*/
test30() {
  new A30(0);
  new A30(1);
}
