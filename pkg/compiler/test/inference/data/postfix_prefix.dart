// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: index:[empty|powerset=empty]*/
dynamic get index => throw '';

/*member: A.:[exact=A|powerset={N}{O}{N}]*/
class A {
  /*member: A.foo:Value([exact=JSString|powerset={I}{O}{I}], value: "string", powerset: {I}{O}{I})*/
  get foo => 'string';

  set foo(/*[subclass=JSNumber|powerset={I}{O}{N}]*/ value) {}

  /*member: A.[]:Value([exact=JSString|powerset={I}{O}{I}], value: "string", powerset: {I}{O}{I})*/
  operator [](/*[empty|powerset=empty]*/ index) => 'string';

  /*member: A.[]=:[null|powerset={null}]*/
  operator []=(
    /*[empty|powerset=empty]*/ index,
    /*[subclass=JSNumber|powerset={I}{O}{N}]*/ value,
  ) {}

  /*member: A.returnDynamic1:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
  returnDynamic1() => /*[subclass=A|powerset={N}{O}{N}]*/ /*update: [subclass=A|powerset={N}{O}{N}]*/
      foo /*invoke: Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/ --;

  /*member: A.returnNum1:[subclass=JSNumber|powerset={I}{O}{N}]*/
  returnNum1() => /*invoke: Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
      -- /*[subclass=A|powerset={N}{O}{N}]*/ /*update: [subclass=A|powerset={N}{O}{N}]*/ foo;

  /*member: A.returnNum2:[subclass=JSNumber|powerset={I}{O}{N}]*/
  returnNum2() => /*[subclass=A|powerset={N}{O}{N}]*/ /*update: [subclass=A|powerset={N}{O}{N}]*/
      foo /*invoke: Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/ -=
          42;

  /*member: A.returnDynamic2:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
  returnDynamic2() =>
      this /*[subclass=A|powerset={N}{O}{N}]*/ /*update: [subclass=A|powerset={N}{O}{N}]*/ [index] /*invoke: Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/ --;

  /*member: A.returnNum3:[subclass=JSNumber|powerset={I}{O}{N}]*/
  returnNum3() => /*invoke: Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
      --this /*[subclass=A|powerset={N}{O}{N}]*/ /*update: [subclass=A|powerset={N}{O}{N}]*/ [index];

  /*member: A.returnNum4:[subclass=JSNumber|powerset={I}{O}{N}]*/
  returnNum4() =>
      this /*[subclass=A|powerset={N}{O}{N}]*/ /*update: [subclass=A|powerset={N}{O}{N}]*/ [index] /*invoke: Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/ -=
          42;

  /*member: A.returnEmpty3:[empty|powerset=empty]*/
  returnEmpty3() {
    dynamic a = this;
    return a
        . /*[subclass=A|powerset={N}{O}{N}]*/ /*update: [subclass=A|powerset={N}{O}{N}]*/ bar /*invoke: [empty|powerset=empty]*/ --;
  }

  /*member: A.returnEmpty1:[empty|powerset=empty]*/
  returnEmpty1() {
    dynamic a = this;
    return /*invoke: [empty|powerset=empty]*/ --a
        . /*[subclass=A|powerset={N}{O}{N}]*/ /*update: [subclass=A|powerset={N}{O}{N}]*/ bar;
  }

  /*member: A.returnEmpty2:[empty|powerset=empty]*/
  returnEmpty2() {
    dynamic a = this;
    return a. /*[subclass=A|powerset={N}{O}{N}]*/ /*update: [subclass=A|powerset={N}{O}{N}]*/ bar /*invoke: [empty|powerset=empty]*/ -=
        42;
  }
}

/*member: B.:[exact=B|powerset={N}{O}{N}]*/
class B extends A {
  /*member: B.foo:[exact=JSUInt31|powerset={I}{O}{N}]*/
  get foo => 42;
  /*member: B.[]:[exact=JSUInt31|powerset={I}{O}{N}]*/
  operator [](/*[empty|powerset=empty]*/ index) => 42;

  /*member: B.returnString1:Value([exact=JSString|powerset={I}{O}{I}], value: "string", powerset: {I}{O}{I})*/
  returnString1() => super
      .foo /*invoke: Value([exact=JSString|powerset={I}{O}{I}], value: "string", powerset: {I}{O}{I})*/ --;

  /*member: B.returnDynamic1:[empty|powerset=empty]*/
  returnDynamic1() =>
      /*invoke: Value([exact=JSString|powerset={I}{O}{I}], value: "string", powerset: {I}{O}{I})*/
      --super.foo;

  /*member: B.returnDynamic2:[empty|powerset=empty]*/
  returnDynamic2() =>
      super.foo /*invoke: Value([exact=JSString|powerset={I}{O}{I}], value: "string", powerset: {I}{O}{I})*/ -=
          42;

  /*member: B.returnString2:Value([exact=JSString|powerset={I}{O}{I}], value: "string", powerset: {I}{O}{I})*/
  returnString2() =>
      super[index] /*invoke: Value([exact=JSString|powerset={I}{O}{I}], value: "string", powerset: {I}{O}{I})*/ --;

  /*member: B.returnDynamic3:[empty|powerset=empty]*/
  returnDynamic3() =>
      /*invoke: Value([exact=JSString|powerset={I}{O}{I}], value: "string", powerset: {I}{O}{I})*/
      --super[index];

  /*member: B.returnDynamic4:[empty|powerset=empty]*/
  returnDynamic4() =>
      super[index] /*invoke: Value([exact=JSString|powerset={I}{O}{I}], value: "string", powerset: {I}{O}{I})*/ -=
          42;
}

/*member: main:[null|powerset={null}]*/
main() {
  A()
    .. /*invoke: [exact=A|powerset={N}{O}{N}]*/ returnNum1()
    .. /*invoke: [exact=A|powerset={N}{O}{N}]*/ returnNum2()
    .. /*invoke: [exact=A|powerset={N}{O}{N}]*/ returnNum3()
    .. /*invoke: [exact=A|powerset={N}{O}{N}]*/ returnNum4()
    .. /*invoke: [exact=A|powerset={N}{O}{N}]*/ returnDynamic1()
    .. /*invoke: [exact=A|powerset={N}{O}{N}]*/ returnDynamic2()
    .. /*invoke: [exact=A|powerset={N}{O}{N}]*/ returnEmpty1()
    .. /*invoke: [exact=A|powerset={N}{O}{N}]*/ returnEmpty2()
    .. /*invoke: [exact=A|powerset={N}{O}{N}]*/ returnEmpty3();

  B()
    .. /*invoke: [exact=B|powerset={N}{O}{N}]*/ returnString1()
    .. /*invoke: [exact=B|powerset={N}{O}{N}]*/ returnString2()
    .. /*invoke: [exact=B|powerset={N}{O}{N}]*/ returnDynamic1()
    .. /*invoke: [exact=B|powerset={N}{O}{N}]*/ returnDynamic2()
    .. /*invoke: [exact=B|powerset={N}{O}{N}]*/ returnDynamic3()
    .. /*invoke: [exact=B|powerset={N}{O}{N}]*/ returnDynamic4();
}
