// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: index:[empty|powerset=empty]*/
dynamic get index => throw '';

/*member: A.:[exact=A|powerset={N}{O}]*/
class A {
  /*member: A.foo:Value([exact=JSString|powerset={I}{O}], value: "string", powerset: {I}{O})*/
  get foo => 'string';

  set foo(/*[subclass=JSNumber|powerset={I}{O}]*/ value) {}

  /*member: A.[]:Value([exact=JSString|powerset={I}{O}], value: "string", powerset: {I}{O})*/
  operator [](/*[empty|powerset=empty]*/ index) => 'string';

  /*member: A.[]=:[null|powerset={null}]*/
  operator []=(
    /*[empty|powerset=empty]*/ index,
    /*[subclass=JSNumber|powerset={I}{O}]*/ value,
  ) {}

  /*member: A.returnDynamic1:Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
  returnDynamic1() => /*[subclass=A|powerset={N}{O}]*/ /*update: [subclass=A|powerset={N}{O}]*/
      foo /*invoke: Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/ --;

  /*member: A.returnNum1:[subclass=JSNumber|powerset={I}{O}]*/
  returnNum1() => /*invoke: Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
      -- /*[subclass=A|powerset={N}{O}]*/ /*update: [subclass=A|powerset={N}{O}]*/ foo;

  /*member: A.returnNum2:[subclass=JSNumber|powerset={I}{O}]*/
  returnNum2() => /*[subclass=A|powerset={N}{O}]*/ /*update: [subclass=A|powerset={N}{O}]*/
      foo /*invoke: Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/ -=
          42;

  /*member: A.returnDynamic2:Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
  returnDynamic2() =>
      this /*[subclass=A|powerset={N}{O}]*/ /*update: [subclass=A|powerset={N}{O}]*/ [index] /*invoke: Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/ --;

  /*member: A.returnNum3:[subclass=JSNumber|powerset={I}{O}]*/
  returnNum3() => /*invoke: Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
      --this /*[subclass=A|powerset={N}{O}]*/ /*update: [subclass=A|powerset={N}{O}]*/ [index];

  /*member: A.returnNum4:[subclass=JSNumber|powerset={I}{O}]*/
  returnNum4() =>
      this /*[subclass=A|powerset={N}{O}]*/ /*update: [subclass=A|powerset={N}{O}]*/ [index] /*invoke: Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/ -=
          42;

  /*member: A.returnEmpty3:[empty|powerset=empty]*/
  returnEmpty3() {
    dynamic a = this;
    return a
        . /*[subclass=A|powerset={N}{O}]*/ /*update: [subclass=A|powerset={N}{O}]*/ bar /*invoke: [empty|powerset=empty]*/ --;
  }

  /*member: A.returnEmpty1:[empty|powerset=empty]*/
  returnEmpty1() {
    dynamic a = this;
    return /*invoke: [empty|powerset=empty]*/ --a
        . /*[subclass=A|powerset={N}{O}]*/ /*update: [subclass=A|powerset={N}{O}]*/ bar;
  }

  /*member: A.returnEmpty2:[empty|powerset=empty]*/
  returnEmpty2() {
    dynamic a = this;
    return a. /*[subclass=A|powerset={N}{O}]*/ /*update: [subclass=A|powerset={N}{O}]*/ bar /*invoke: [empty|powerset=empty]*/ -=
        42;
  }
}

/*member: B.:[exact=B|powerset={N}{O}]*/
class B extends A {
  /*member: B.foo:[exact=JSUInt31|powerset={I}{O}]*/
  get foo => 42;
  /*member: B.[]:[exact=JSUInt31|powerset={I}{O}]*/
  operator [](/*[empty|powerset=empty]*/ index) => 42;

  /*member: B.returnString1:Value([exact=JSString|powerset={I}{O}], value: "string", powerset: {I}{O})*/
  returnString1() =>
      super
          .foo /*invoke: Value([exact=JSString|powerset={I}{O}], value: "string", powerset: {I}{O})*/ --;

  /*member: B.returnDynamic1:[empty|powerset=empty]*/
  returnDynamic1() =>
      /*invoke: Value([exact=JSString|powerset={I}{O}], value: "string", powerset: {I}{O})*/
      --super.foo;

  /*member: B.returnDynamic2:[empty|powerset=empty]*/
  returnDynamic2() =>
      super.foo /*invoke: Value([exact=JSString|powerset={I}{O}], value: "string", powerset: {I}{O})*/ -=
          42;

  /*member: B.returnString2:Value([exact=JSString|powerset={I}{O}], value: "string", powerset: {I}{O})*/
  returnString2() =>
      super[index] /*invoke: Value([exact=JSString|powerset={I}{O}], value: "string", powerset: {I}{O})*/ --;

  /*member: B.returnDynamic3:[empty|powerset=empty]*/
  returnDynamic3() =>
      /*invoke: Value([exact=JSString|powerset={I}{O}], value: "string", powerset: {I}{O})*/
      --super[index];

  /*member: B.returnDynamic4:[empty|powerset=empty]*/
  returnDynamic4() =>
      super[index] /*invoke: Value([exact=JSString|powerset={I}{O}], value: "string", powerset: {I}{O})*/ -=
          42;
}

/*member: main:[null|powerset={null}]*/
main() {
  A()
    .. /*invoke: [exact=A|powerset={N}{O}]*/ returnNum1()
    .. /*invoke: [exact=A|powerset={N}{O}]*/ returnNum2()
    .. /*invoke: [exact=A|powerset={N}{O}]*/ returnNum3()
    .. /*invoke: [exact=A|powerset={N}{O}]*/ returnNum4()
    .. /*invoke: [exact=A|powerset={N}{O}]*/ returnDynamic1()
    .. /*invoke: [exact=A|powerset={N}{O}]*/ returnDynamic2()
    .. /*invoke: [exact=A|powerset={N}{O}]*/ returnEmpty1()
    .. /*invoke: [exact=A|powerset={N}{O}]*/ returnEmpty2()
    .. /*invoke: [exact=A|powerset={N}{O}]*/ returnEmpty3();

  B()
    .. /*invoke: [exact=B|powerset={N}{O}]*/ returnString1()
    .. /*invoke: [exact=B|powerset={N}{O}]*/ returnString2()
    .. /*invoke: [exact=B|powerset={N}{O}]*/ returnDynamic1()
    .. /*invoke: [exact=B|powerset={N}{O}]*/ returnDynamic2()
    .. /*invoke: [exact=B|powerset={N}{O}]*/ returnDynamic3()
    .. /*invoke: [exact=B|powerset={N}{O}]*/ returnDynamic4();
}
