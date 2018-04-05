// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: index:[empty]*/
dynamic get index => throw '';

/*element: A.:[exact=A]*/
class A {
  /*element: A.foo:Value([exact=JSString], value: "string")*/
  get foo => 'string';

  set foo(/*[subclass=JSNumber]*/ value) {}

  /*element: A.[]:Value([exact=JSString], value: "string")*/
  operator [](/*[empty]*/ index) => 'string';

  /*element: A.[]=:[null]*/
  operator []=(/*[empty]*/ index, /*[subclass=JSNumber]*/ value) {}

  // TODO(johnniwinther): Investigate why these differ.
  /*ast.element: A.returnDynamic1:Union([exact=JSString], [exact=JSUInt31])*/
  /*kernel.element: A.returnDynamic1:[exact=JSUInt31]*/
  /*strong.element: A.returnDynamic1:[exact=JSUInt31]*/
  returnDynamic1() => /*[subclass=A]*/ /*update: [subclass=A]*/ foo
      /*invoke: Union([exact=JSString], [exact=JSUInt31])*/ --;

  /*element: A.returnNum1:[subclass=JSNumber]*/
  returnNum1() => /*invoke: Union([exact=JSString], [exact=JSUInt31])*/ --
      /*[subclass=A]*/ /*update: [subclass=A]*/ foo;

  /*element: A.returnNum2:[subclass=JSNumber]*/
  returnNum2() => /*[subclass=A]*/ /*update: [subclass=A]*/ foo
      /*invoke: Union([exact=JSString], [exact=JSUInt31])*/ -= 42;

  // TODO(johnniwinther): Investigate why these differ.
  /*ast.element: A.returnDynamic2:Union([exact=JSString], [exact=JSUInt31])*/
  /*kernel.element: A.returnDynamic2:[exact=JSUInt31]*/
  /*strong.element: A.returnDynamic2:[exact=JSUInt31]*/
  returnDynamic2() => this
          /*[subclass=A]*/ /*update: [subclass=A]*/ [index]
      /*invoke: Union([exact=JSString], [exact=JSUInt31])*/ --;

  /*element: A.returnNum3:[subclass=JSNumber]*/
  returnNum3() => /*invoke: Union([exact=JSString], [exact=JSUInt31])*/ --this
      /*[subclass=A]*/ /*update: [subclass=A]*/ [index];

  /*element: A.returnNum4:[subclass=JSNumber]*/
  returnNum4() => this
          /*[subclass=A]*/ /*update: [subclass=A]*/ [index]
      /*invoke: Union([exact=JSString], [exact=JSUInt31])*/ -= 42;

  // TODO(johnniwinther): Investigate why implementations differ on update.
  /*element: A.returnEmpty3:[empty]*/
  returnEmpty3() {
    dynamic a = this;
    return a. /*[subclass=A]*/
            /*ast.update: [subclass=A]*/
            /*kernel.update: [empty]*/
            /*strong.update: [empty]*/
            bar
        /*invoke: [empty]*/ --;
  }

  /*element: A.returnEmpty1:[empty]*/
  returnEmpty1() {
    dynamic a = this;
    return /*invoke: [empty]*/ --a
        . /*[subclass=A]*/ /*update: [subclass=A]*/ bar;
  }

  /*element: A.returnEmpty2:[empty]*/
  returnEmpty2() {
    dynamic a = this;
    return a. /*[subclass=A]*/ /*update: [subclass=A]*/ bar
        /*invoke: [empty]*/ -= 42;
  }
}

/*element: B.:[exact=B]*/
class B extends A {
  /*element: B.foo:[exact=JSUInt31]*/
  get foo => 42;
  /*element: B.[]:[exact=JSUInt31]*/
  operator [](/*[empty]*/ index) => 42;

  // TODO(johnniwinther): Investigate why these differ.
  /*ast.element: B.returnString1:Value([exact=JSString], value: "string")*/
  /*kernel.element: B.returnString1:[empty]*/
  /*strong.element: B.returnString1:[empty]*/
  returnString1() =>
      super.foo /*invoke: Value([exact=JSString], value: "string")*/ --;

  /*element: B.returnDynamic1:[empty]*/
  returnDynamic1() =>
      /*invoke: Value([exact=JSString], value: "string")*/
      --super.foo;

  /*element: B.returnDynamic2:[empty]*/
  returnDynamic2() =>
      super.foo /*invoke: Value([exact=JSString], value: "string")*/ -= 42;

  // TODO(johnniwinther): Investigate why these differ.
  /*ast.element: B.returnString2:Value([exact=JSString], value: "string")*/
  /*kernel.element: B.returnString2:[empty]*/
  /*strong.element: B.returnString2:[empty]*/
  returnString2() => super[index]
      /*invoke: Value([exact=JSString], value: "string")*/ --;

  /*element: B.returnDynamic3:[empty]*/
  returnDynamic3() =>
      /*invoke: Value([exact=JSString], value: "string")*/
      --super[index];

  /*element: B.returnDynamic4:[empty]*/
  returnDynamic4() => super[index]
      /*invoke: Value([exact=JSString], value: "string")*/ -= 42;
}

/*element: main:[null]*/
main() {
  new A()
    .. /*invoke: [exact=A]*/ returnNum1()
    .. /*invoke: [exact=A]*/ returnNum2()
    .. /*invoke: [exact=A]*/ returnNum3()
    .. /*invoke: [exact=A]*/ returnNum4()
    .. /*invoke: [exact=A]*/ returnDynamic1()
    .. /*invoke: [exact=A]*/ returnDynamic2()
    .. /*invoke: [exact=A]*/ returnEmpty1()
    .. /*invoke: [exact=A]*/ returnEmpty2()
    .. /*invoke: [exact=A]*/ returnEmpty3();

  new B()
    .. /*invoke: [exact=B]*/ returnString1()
    .. /*invoke: [exact=B]*/ returnString2()
    .. /*invoke: [exact=B]*/ returnDynamic1()
    .. /*invoke: [exact=B]*/ returnDynamic2()
    .. /*invoke: [exact=B]*/ returnDynamic3()
    .. /*invoke: [exact=B]*/ returnDynamic4();
}
