// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: index:[empty|powerset=empty]*/
dynamic get index => throw '';

/*member: A.:[exact=A|powerset={N}]*/
class A {
  /*member: A.foo:Value([exact=JSString|powerset={I}], value: "string", powerset: {I})*/
  get foo => 'string';

  set foo(/*[subclass=JSNumber|powerset={I}]*/ value) {}

  /*member: A.[]:Value([exact=JSString|powerset={I}], value: "string", powerset: {I})*/
  operator [](/*[empty|powerset=empty]*/ index) => 'string';

  /*member: A.[]=:[null|powerset={null}]*/
  operator []=(
    /*[empty|powerset=empty]*/ index,
    /*[subclass=JSNumber|powerset={I}]*/ value,
  ) {}

  /*member: A.returnDynamic1:Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  returnDynamic1() => /*[subclass=A|powerset={N}]*/ /*update: [subclass=A|powerset={N}]*/
      foo /*invoke: Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/ --;

  /*member: A.returnNum1:[subclass=JSNumber|powerset={I}]*/
  returnNum1() => /*invoke: Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
      -- /*[subclass=A|powerset={N}]*/ /*update: [subclass=A|powerset={N}]*/ foo;

  /*member: A.returnNum2:[subclass=JSNumber|powerset={I}]*/
  returnNum2() => /*[subclass=A|powerset={N}]*/ /*update: [subclass=A|powerset={N}]*/
      foo /*invoke: Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/ -=
          42;

  /*member: A.returnDynamic2:Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  returnDynamic2() =>
      this /*[subclass=A|powerset={N}]*/ /*update: [subclass=A|powerset={N}]*/ [index] /*invoke: Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/ --;

  /*member: A.returnNum3:[subclass=JSNumber|powerset={I}]*/
  returnNum3() => /*invoke: Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
      --this /*[subclass=A|powerset={N}]*/ /*update: [subclass=A|powerset={N}]*/ [index];

  /*member: A.returnNum4:[subclass=JSNumber|powerset={I}]*/
  returnNum4() =>
      this /*[subclass=A|powerset={N}]*/ /*update: [subclass=A|powerset={N}]*/ [index] /*invoke: Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/ -=
          42;

  /*member: A.returnEmpty3:[empty|powerset=empty]*/
  returnEmpty3() {
    dynamic a = this;
    return a
        . /*[subclass=A|powerset={N}]*/ /*update: [subclass=A|powerset={N}]*/ bar /*invoke: [empty|powerset=empty]*/ --;
  }

  /*member: A.returnEmpty1:[empty|powerset=empty]*/
  returnEmpty1() {
    dynamic a = this;
    return /*invoke: [empty|powerset=empty]*/ --a
        . /*[subclass=A|powerset={N}]*/ /*update: [subclass=A|powerset={N}]*/ bar;
  }

  /*member: A.returnEmpty2:[empty|powerset=empty]*/
  returnEmpty2() {
    dynamic a = this;
    return a. /*[subclass=A|powerset={N}]*/ /*update: [subclass=A|powerset={N}]*/ bar /*invoke: [empty|powerset=empty]*/ -=
        42;
  }
}

/*member: B.:[exact=B|powerset={N}]*/
class B extends A {
  /*member: B.foo:[exact=JSUInt31|powerset={I}]*/
  get foo => 42;
  /*member: B.[]:[exact=JSUInt31|powerset={I}]*/
  operator [](/*[empty|powerset=empty]*/ index) => 42;

  /*member: B.returnString1:Value([exact=JSString|powerset={I}], value: "string", powerset: {I})*/
  returnString1() =>
      super
          .foo /*invoke: Value([exact=JSString|powerset={I}], value: "string", powerset: {I})*/ --;

  /*member: B.returnDynamic1:[empty|powerset=empty]*/
  returnDynamic1() =>
      /*invoke: Value([exact=JSString|powerset={I}], value: "string", powerset: {I})*/
      --super.foo;

  /*member: B.returnDynamic2:[empty|powerset=empty]*/
  returnDynamic2() =>
      super.foo /*invoke: Value([exact=JSString|powerset={I}], value: "string", powerset: {I})*/ -=
          42;

  /*member: B.returnString2:Value([exact=JSString|powerset={I}], value: "string", powerset: {I})*/
  returnString2() =>
      super[index] /*invoke: Value([exact=JSString|powerset={I}], value: "string", powerset: {I})*/ --;

  /*member: B.returnDynamic3:[empty|powerset=empty]*/
  returnDynamic3() =>
      /*invoke: Value([exact=JSString|powerset={I}], value: "string", powerset: {I})*/
      --super[index];

  /*member: B.returnDynamic4:[empty|powerset=empty]*/
  returnDynamic4() =>
      super[index] /*invoke: Value([exact=JSString|powerset={I}], value: "string", powerset: {I})*/ -=
          42;
}

/*member: main:[null|powerset={null}]*/
main() {
  A()
    .. /*invoke: [exact=A|powerset={N}]*/ returnNum1()
    .. /*invoke: [exact=A|powerset={N}]*/ returnNum2()
    .. /*invoke: [exact=A|powerset={N}]*/ returnNum3()
    .. /*invoke: [exact=A|powerset={N}]*/ returnNum4()
    .. /*invoke: [exact=A|powerset={N}]*/ returnDynamic1()
    .. /*invoke: [exact=A|powerset={N}]*/ returnDynamic2()
    .. /*invoke: [exact=A|powerset={N}]*/ returnEmpty1()
    .. /*invoke: [exact=A|powerset={N}]*/ returnEmpty2()
    .. /*invoke: [exact=A|powerset={N}]*/ returnEmpty3();

  B()
    .. /*invoke: [exact=B|powerset={N}]*/ returnString1()
    .. /*invoke: [exact=B|powerset={N}]*/ returnString2()
    .. /*invoke: [exact=B|powerset={N}]*/ returnDynamic1()
    .. /*invoke: [exact=B|powerset={N}]*/ returnDynamic2()
    .. /*invoke: [exact=B|powerset={N}]*/ returnDynamic3()
    .. /*invoke: [exact=B|powerset={N}]*/ returnDynamic4();
}
