// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
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
  test21();
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

/*element: A1.:[exact=A1]*/
class A1 {
  /*element: A1.f1:[null]*/
  int f1;
}

/*element: test1:[null]*/
test1() {
  new A1();
}

/*element: A2.:[exact=A2]*/
class A2 {
  /*element: A2.f2a:[null]*/
  int f2a;

  /*element: A2.f2b:[exact=JSUInt31]*/
  int f2b = 1;
}

/*element: test2:[null]*/
test2() {
  new A2();
}

class A3 {
  /*element: A3.f3a:[exact=JSUInt31]*/
  int f3a;

  /*element: A3.f3b:[null|exact=JSUInt31]*/
  int f3b;

  /*element: A3.:[exact=A3]*/
  A3() : f3a = 1;
}

/*element: test3:[null]*/
test3() {
  new A3(). /*update: [exact=A3]*/ f3b = 2;
}

class A4 {
  /*element: A4.f4a:Union([exact=JSString], [exact=JSUInt31])*/
  dynamic f4a;

  /*element: A4.f4b:Value([null|exact=JSString], value: "a")*/
  dynamic f4b;

  /*element: A4.:[exact=A4]*/
  A4() : f4a = 1;
}

/*element: test4:[null]*/
test4() {
  A4 a = new A4();
  a. /*update: [exact=A4]*/ f4a = "a";
  a. /*update: [exact=A4]*/ f4b = "a";
}

class A5 {
  /*element: A5.f5a:Union([exact=JSString], [exact=JSUInt31])*/
  dynamic f5a = 1;

  /*element: A5.f5b:Union([exact=JSString], [exact=JSUInt31])*/
  dynamic f5b = 1;

  /*element: A5.:[exact=A5]*/
  A5(/*[exact=JSBool]*/ x) {
    /*update: [exact=A5]*/ f5a = "1";
    if (x) {
      /*update: [exact=A5]*/ f5b = "1";
    } else {
      /*update: [exact=A5]*/ f5b = "2";
    }
  }
}

/*element: test5:[null]*/
test5() {
  new A5(true);
  new A5(false);
}

class A6 {
  /*element: A6.f6a:Union([exact=JSString], [exact=JSUInt31])*/
  dynamic f6a = 1;

  /*element: A6.f6b:Union([exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31])*/
  dynamic f6b = 1;

  /*element: A6.:[exact=A6]*/
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

/*element: test6:[null]*/
test6() {
  new A6(true);
  new A6(false);
}

class A7 {
  /*element: A7.f7a:Union([exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31])*/
  dynamic f7a = 1;

  /*element: A7.f7b:Union([exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31])*/
  dynamic f7b = 1;

  /*element: A7.:[exact=A7]*/
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

/*element: test7:[null]*/
test7() {
  new A7(true);
  new A7(false);
}

class A8 {
  /*element: A8.f8:Value([null|exact=JSString], value: "1")*/
  dynamic f8;

  /*element: A8.:[exact=A8]*/
  A8(/*[exact=JSBool]*/ x) {
    if (x) {
      /*update: [exact=A8]*/ f8 = "1";
    } else {}
  }
}

/*element: test8:[null]*/
test8() {
  new A8(true);
  new A8(false);
}

class A9 {
  /*element: A9.f9:Value([null|exact=JSString], value: "1")*/
  dynamic f9;

  /*element: A9.:[exact=A9]*/
  A9(/*[exact=JSBool]*/ x) {
    if (x) {
    } else {
      /*update: [exact=A9]*/ f9 = "1";
    }
  }
}

/*element: test9:[null]*/
test9() {
  new A9(true);
  new A9(false);
}

class A10 {
  /*element: A10.f10:[exact=JSUInt31]*/
  int f10;

  /*element: A10.:[exact=A10]*/
  A10() {
    /*update: [exact=A10]*/ f10 = 1;
  }
  /*element: A10.m10:[subclass=JSUInt32]*/
  m10() => /*[exact=A10]*/ f10 /*invoke: [exact=JSUInt31]*/ + 1;
}

/*element: f10:[null]*/
void f10(/*[null]*/ x) {
  x. /*update: [null]*/ f10 = "2";
}

/*element: test10:[null]*/
test10() {
  A10 a;
  f10(a);
  a = new A10();
  a. /*invoke: [exact=A10]*/ m10();
}

/*element: S11.:[exact=S11]*/
class S11 {
  /*element: S11.fs11:[exact=JSUInt31]*/
  int fs11 = 1;

  /*element: S11.ms11:[null]*/
  ms11() {
    /*update: [exact=A11]*/ fs11 = 1;
  }
}

/*element: A11.:[exact=A11]*/
class A11 extends S11 {
  /*element: A11.m11:[null]*/
  m11() {
    /*invoke: [exact=A11]*/ ms11();
  }
}

/*element: test11:[null]*/
test11() {
  A11 a = new A11();
  a. /*invoke: [exact=A11]*/ m11();
}

class S12 {
  /*element: S12.fs12:Union([exact=JSString], [exact=JSUInt31])*/
  dynamic fs12 = 1;

  /*element: S12.:[exact=S12]*/
  S12() {
    /*update: [exact=A12]*/ fs12 = "2";
  }
}

/*element: A12.:[exact=A12]*/
class A12 extends S12 {}

/*element: test12:[null]*/
test12() {
  new A12();
}

class S13 {
/*element: S13.fs13:[exact=JSUInt31]*/
  int fs13;

  /*element: S13.:[exact=S13]*/
  S13() {
    /*update: [exact=A13]*/ fs13 = 1;
  }
}

class A13 extends S13 {
  /*element: A13.:[exact=A13]*/
  A13() {
    /*update: [exact=A13]*/ fs13 = 1;
  }
}

/*element: test13:[null]*/
test13() {
  new A13();
}

class A14 {
  /*element: A14.f14:[exact=JSUInt31]*/
  var f14;

  /*element: A14.:[exact=A14]*/
  A14() {
    /*update: [exact=A14]*/ f14 = 1;
  }
  /*element: A14.other:[exact=A14]*/
  A14.other() {
    /*update: [exact=A14]*/ f14 = 2;
  }
}

/*element: test14:[null]*/
test14() {
  // ignore: unused_local_variable
  A14 a = new A14();
  a = new A14.other();
}

class A15 {
  /*element: A15.f15:Union([exact=JSExtendableArray], [exact=JSString])*/
  var f15;

  /*element: A15.:[exact=A15]*/
  A15() {
    /*update: [exact=A15]*/ f15 = "1";
  }

  /*element: A15.other:[exact=A15]*/
  A15.other() {
    /*update: [exact=A15]*/ f15 = new List();
  }
}

/*element: test15:[null]*/
test15() {
  // ignore: unused_local_variable
  A15 a = new A15();
  a = new A15.other();
}

class A16 {
  // TODO(johnniwinther): Investigate why these include `null`. The ast version
  // didn't.
  /*kernel.element: A16.f16:Union([exact=JSString], [null|exact=JSUInt31])*/
  /*strong.element: A16.f16:Union([exact=JSString], [null|exact=JSUInt31])*/
  var f16;

  /*element: A16.:[exact=A16]*/
  A16() {
    /*update: [exact=A16]*/ f16 = "1";
  }

  /*element: A16.other:[exact=A16]*/
  A16.other() : f16 = 1 {}
}

/*element: test16:[null]*/
test16() {
  // ignore: unused_local_variable
  A16 a = new A16();
  a = new A16.other();
}

/*element: g17:[exact=JSUInt31]*/
g17([/*[exact=A17]*/ p]) => p. /*update: [exact=A17]*/ f17 = 1;

class A17 {
/*element: A17.f17:[null|exact=JSUInt31]*/
  var f17;

  /*element: A17.:[exact=A17]*/
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

/*element: test17:[null]*/
test17() {
  new A17(true);
  new A17(false);
}

class A18 {
  /*element: A18.f18a:[exact=JSUInt31]*/
  var f18a;

  /*element: A18.f18b:Value([exact=JSString], value: "1")*/
  var f18b;

  /*element: A18.f18c:Union([exact=JSUInt31], [null|exact=A18])*/
  var f18c;

  /*element: A18.:[exact=A18]*/
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

/*element: test18:[null]*/
test18() {
  new A18(true);
  new A18(false);
}

class A19 {
  /*element: A19.f19a:[exact=JSUInt31]*/
  var f19a;

  /*element: A19.f19b:Value([exact=JSString], value: "1")*/
  var f19b;

  /*element: A19.f19c:Union([exact=JSUInt31], [null|exact=A19])*/
  var f19c;

  /*element: A19.:[exact=A19]*/
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

/*element: test19:[null]*/
test19() {
  new A19(true);
  new A19(false);
}

class A20 {
  /*element: A20.f20:[null|exact=JSUInt31]*/
  var f20;

  /*element: A20.:[exact=A20]*/
  A20() {
    dynamic a = this;
    // TODO(johnniwinther): Fix ast equivalence on instance fields in for.
    /*iterator: [exact=A20]*/
    /*current: [exact=A20]*/
    /*moveNext: [exact=A20]*/
    for (/*kernel.update: [exact=A20]*/ /*strong.update: [exact=A20]*/ f20
        in a) {}
  }

  /*element: A20.iterator:[exact=A20]*/
  get iterator => this;

  /*element: A20.current:[exact=JSUInt31]*/
  get current => 42;

  /*element: A20.moveNext:Value([exact=JSBool], value: false)*/
  bool moveNext() => false;
}

/*element: test20:[null]*/
test20() {
  new A20();
}

class A21 {
  /*element: A21.f21:[null|exact=JSUInt31]*/
  var f21;

  /*element: A21.:[exact=A21]*/
  A21() {
    dynamic a = this;
    /*iterator: [exact=A21]*/
    /*current: [null]*/
    /*moveNext: [null]*/
    for (
        // ignore: unused_local_variable
        var i in a) {}
    /*update: [exact=A21]*/ f21 = 42;
  }
  /*element: A21.iterator:[null]*/
  get iterator => null;
}

/*element: test21:[null]*/
test21() {
  new A21();
}

class A22 {
  /*element: A22.f22a:[exact=JSUInt31]*/
  var f22a;

  /*element: A22.f22b:[exact=JSUInt31]*/
  var f22b;

  /*element: A22.f22c:Value([null|exact=JSString], value: "foo")*/
  var f22c;

  /*element: A22.:[exact=A22]*/
  A22() {
    /*update: [exact=A22]*/ f22a = 42;
    /*update: [exact=A22]*/ f22b = /*[exact=A22]*/ f22a == null
        ? 42
        : /*[exact=A22]*/ f22c == null ? 41 : 43;
    /*update: [exact=A22]*/ f22c = 'foo';
  }
}

/*element: test22:[null]*/
test22() {
  new A22();
}

class A23 {
  /*element: A23.f23a:[null|exact=JSUInt31]*/
  var f23a = 42;

  /*element: A23.f23b:[null|exact=JSUInt31]*/
  var f23b = 42;

  /*element: A23.f23c:[null|exact=JSUInt31]*/
  var f23c = 42;

  /*element: A23.f23d:[null|exact=JSUInt31]*/
  var f23d = 42;

  /*element: A23.:[exact=A23]*/
  A23() {
    // Test string interpolation.
    '${/*update: [exact=A23]*/f23a = null}';
    // Test string juxtaposition.
    ''
        '${/*update: [exact=A23]*/f23b = null}';
    // Test list literal.
    [/*update: [exact=A23]*/ f23c = null];
    // Test map literal.
    // ignore: unused_local_variable
    var c = {'foo': /*update: [exact=A23]*/ f23d = null};
  }
}

/*element: test23:[null]*/
test23() {
  new A23();
}

class A24 {
  /*element: A24.f24a:[subclass=JSPositiveInt]*/
  var f24a = 42;

  /*element: A24.f24b:[subclass=JSPositiveInt]*/
  var f24b = 42;

  /*element: A24.f24c:[exact=JSUInt31]*/
  var f24c = 42;

  /*element: A24.f24d:[exact=JSUInt31]*/
  final f24d;

  /*element: A24.f24e:Union([exact=JSUInt31], [null|exact=JSDouble])*/
  var f24e;

/*element: A24.f24f:Value([null|exact=JSString], value: "foo")*/
  var f24f = null;

  /*element: A24.:[exact=A24]*/
  A24() : f24d = 42 {
    /*[subclass=A24]*/ /*update: [subclass=A24]*/ f24a
        /*invoke: [subclass=JSPositiveInt]*/ ++;
    /*[subclass=A24]*/ /*update: [subclass=A24]*/ f24b
        /*invoke: [subclass=JSPositiveInt]*/ += 42;
    var f24f = 'foo';
    this. /*update: [subclass=A24]*/ f24f = f24f;
  }

  /*element: A24.foo:[exact=A24]*/
  A24.foo(/*[subclass=A24]*/ other)
      : f24c = other. /*[subclass=A24]*/ f24c,
        f24d = other. /*[subclass=A24]*/ f24d,
        f24e = other
            . /*invoke: [subclass=A24]*/
            bar24();

  /*element: A24.+:Value([exact=JSString], value: "foo")*/
  operator +(
          /*kernel.[exact=JSUInt31]*/
          /*strong.[empty]*/
          other) =>
      'foo';

  /*element: A24.bar24:[exact=JSDouble]*/
  bar24() => 42.5;
}

/*element: B24.:[exact=B24]*/
class B24 extends A24 {
  /*element: B24.bar24:[exact=JSUInt31]*/
  bar24() => 42;
}

/*element: test24:[null]*/
test24() {
  new A24();
  new A24.foo(new A24());
  new A24.foo(new B24());
}

/*element: A25.:[exact=A25]*/
class A25 {
  /*element: A25.f25:[exact=JSUInt31]*/
  var f25 = 42;
}

/*element: B25.:[exact=B25]*/
class B25 {
  /*element: B25.f25:Value([exact=JSString], value: "42")*/
  var f25 = '42';
}

/*element: test25:[null]*/
test25() {
  new B25();
  new A25(). /*update: [exact=A25]*/ f25 = new A25(). /*[exact=A25]*/ f25;
}

/*element: A26.:[exact=A26]*/
class A26 {
  /*element: A26.f26:[subclass=JSPositiveInt]*/
  var f26 = 42;
}

/*element: B26.:[exact=B26]*/
class B26 {
  /*element: B26.f26:[exact=JSUInt31]*/
  var f26 = 54;
}

/*element: test26:[null]*/
test26() {
  new A26(). /*update: [exact=A26]*/ f26 = <dynamic>[new B26(), new A26()]
              /*Container([exact=JSExtendableArray], element: Union([exact=A26], [exact=B26]), length: 2)*/
              [0]
          . /*Union([exact=A26], [exact=B26])*/ f26
      /*invoke: [subclass=JSPositiveInt]*/ +
      42;
}

class A27 {
  /*element: A27.f27a:[exact=JSUInt31]*/
  var f27a;

  /*element: A27.f27b:[null|exact=JSUInt31]*/
  var f27b;

  /*element: A27.:[exact=A27]*/
  A27() {
    this. /*update: [subclass=A27]*/ f27a = 42;
    this. /*update: [subclass=A27]*/ f27b = 42;
  }
}

/*element: B27.:[exact=B27]*/
class B27 extends A27 {
  set f27b(/*[exact=JSUInt31]*/ value) {}
}

/*element: test27:[null]*/
test27() {
  new A27();
  new B27();
}

class A28 {
  /*element: A28.f28a:[exact=JSUInt31]*/
  var f28a;

  /*element: A28.f28b:[null|exact=JSUInt31]*/
  var f28b;

  /*element: A28.:[exact=A28]*/
  A28(/*[exact=JSUInt31]*/ x) {
    this. /*update: [exact=A28]*/ f28a = x;
    if (x /*invoke: [exact=JSUInt31]*/ == 0) return;
    this. /*update: [exact=A28]*/ f28b = x;
  }
}

/*element: test28:[null]*/
test28() {
  new A28(0);
  new A28(1);
}

class A29 {
  /*element: A29.f29a:[exact=JSUInt31]*/
  var f29a;

  /*element: A29.f29b:[null|exact=JSUInt31]*/
  var f29b;

  /*element: A29.:[exact=A29]*/
  A29(/*[exact=JSUInt31]*/ x) {
    this. /*update: [exact=A29]*/ f29a = x;
    if (x /*invoke: [exact=JSUInt31]*/ == 0) {
    } else {
      return;
    }
    this. /*update: [exact=A29]*/ f29b = x;
  }
}

/*element: test29:[null]*/
test29() {
  new A29(0);
  new A29(1);
}

class A30 {
  /*element: A30.f30a:[exact=JSUInt31]*/
  var f30a;

  /*element: A30.f30b:[exact=JSUInt31]*/
  var f30b;

  /*element: A30.f30c:[null|exact=JSUInt31]*/
  var f30c;

  /*element: A30.:[exact=A30]*/
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

/*element: test30:[null]*/
test30() {
  new A30(0);
  new A30(1);
}
