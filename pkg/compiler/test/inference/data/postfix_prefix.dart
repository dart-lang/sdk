// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: index:[empty|powerset=0]*/
dynamic get index => throw '';

/*member: A.:[exact=A|powerset=0]*/
class A {
  /*member: A.foo:Value([exact=JSString|powerset=0], value: "string", powerset: 0)*/
  get foo => 'string';

  set foo(/*[subclass=JSNumber|powerset=0]*/ value) {}

  /*member: A.[]:Value([exact=JSString|powerset=0], value: "string", powerset: 0)*/
  operator [](/*[empty|powerset=0]*/ index) => 'string';

  /*member: A.[]=:[null|powerset=1]*/
  operator []=(
    /*[empty|powerset=0]*/ index,
    /*[subclass=JSNumber|powerset=0]*/ value,
  ) {}

  /*member: A.returnDynamic1:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
  returnDynamic1() => /*[subclass=A|powerset=0]*/ /*update: [subclass=A|powerset=0]*/
      foo /*invoke: Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ --;

  /*member: A.returnNum1:[subclass=JSNumber|powerset=0]*/
  returnNum1() => /*invoke: Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
      -- /*[subclass=A|powerset=0]*/ /*update: [subclass=A|powerset=0]*/ foo;

  /*member: A.returnNum2:[subclass=JSNumber|powerset=0]*/
  returnNum2() => /*[subclass=A|powerset=0]*/ /*update: [subclass=A|powerset=0]*/
      foo /*invoke: Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ -=
          42;

  /*member: A.returnDynamic2:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
  returnDynamic2() =>
      this /*[subclass=A|powerset=0]*/ /*update: [subclass=A|powerset=0]*/ [index] /*invoke: Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ --;

  /*member: A.returnNum3:[subclass=JSNumber|powerset=0]*/
  returnNum3() => /*invoke: Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
      --this /*[subclass=A|powerset=0]*/ /*update: [subclass=A|powerset=0]*/ [index];

  /*member: A.returnNum4:[subclass=JSNumber|powerset=0]*/
  returnNum4() =>
      this /*[subclass=A|powerset=0]*/ /*update: [subclass=A|powerset=0]*/ [index] /*invoke: Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ -=
          42;

  /*member: A.returnEmpty3:[empty|powerset=0]*/
  returnEmpty3() {
    dynamic a = this;
    return a
        . /*[subclass=A|powerset=0]*/ /*update: [subclass=A|powerset=0]*/ bar /*invoke: [empty|powerset=0]*/ --;
  }

  /*member: A.returnEmpty1:[empty|powerset=0]*/
  returnEmpty1() {
    dynamic a = this;
    return /*invoke: [empty|powerset=0]*/ --a
        . /*[subclass=A|powerset=0]*/ /*update: [subclass=A|powerset=0]*/ bar;
  }

  /*member: A.returnEmpty2:[empty|powerset=0]*/
  returnEmpty2() {
    dynamic a = this;
    return a. /*[subclass=A|powerset=0]*/ /*update: [subclass=A|powerset=0]*/ bar /*invoke: [empty|powerset=0]*/ -=
        42;
  }
}

/*member: B.:[exact=B|powerset=0]*/
class B extends A {
  /*member: B.foo:[exact=JSUInt31|powerset=0]*/
  get foo => 42;
  /*member: B.[]:[exact=JSUInt31|powerset=0]*/
  operator [](/*[empty|powerset=0]*/ index) => 42;

  /*member: B.returnString1:Value([exact=JSString|powerset=0], value: "string", powerset: 0)*/
  returnString1() =>
      super
          .foo /*invoke: Value([exact=JSString|powerset=0], value: "string", powerset: 0)*/ --;

  /*member: B.returnDynamic1:[empty|powerset=0]*/
  returnDynamic1() =>
      /*invoke: Value([exact=JSString|powerset=0], value: "string", powerset: 0)*/
      --super.foo;

  /*member: B.returnDynamic2:[empty|powerset=0]*/
  returnDynamic2() =>
      super.foo /*invoke: Value([exact=JSString|powerset=0], value: "string", powerset: 0)*/ -=
          42;

  /*member: B.returnString2:Value([exact=JSString|powerset=0], value: "string", powerset: 0)*/
  returnString2() =>
      super[index] /*invoke: Value([exact=JSString|powerset=0], value: "string", powerset: 0)*/ --;

  /*member: B.returnDynamic3:[empty|powerset=0]*/
  returnDynamic3() =>
      /*invoke: Value([exact=JSString|powerset=0], value: "string", powerset: 0)*/
      --super[index];

  /*member: B.returnDynamic4:[empty|powerset=0]*/
  returnDynamic4() =>
      super[index] /*invoke: Value([exact=JSString|powerset=0], value: "string", powerset: 0)*/ -=
          42;
}

/*member: main:[null|powerset=1]*/
main() {
  A()
    .. /*invoke: [exact=A|powerset=0]*/ returnNum1()
    .. /*invoke: [exact=A|powerset=0]*/ returnNum2()
    .. /*invoke: [exact=A|powerset=0]*/ returnNum3()
    .. /*invoke: [exact=A|powerset=0]*/ returnNum4()
    .. /*invoke: [exact=A|powerset=0]*/ returnDynamic1()
    .. /*invoke: [exact=A|powerset=0]*/ returnDynamic2()
    .. /*invoke: [exact=A|powerset=0]*/ returnEmpty1()
    .. /*invoke: [exact=A|powerset=0]*/ returnEmpty2()
    .. /*invoke: [exact=A|powerset=0]*/ returnEmpty3();

  B()
    .. /*invoke: [exact=B|powerset=0]*/ returnString1()
    .. /*invoke: [exact=B|powerset=0]*/ returnString2()
    .. /*invoke: [exact=B|powerset=0]*/ returnDynamic1()
    .. /*invoke: [exact=B|powerset=0]*/ returnDynamic2()
    .. /*invoke: [exact=B|powerset=0]*/ returnDynamic3()
    .. /*invoke: [exact=B|powerset=0]*/ returnDynamic4();
}
