// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {
  /*element: C.field:Union([exact=JSString], [exact=JSUInt31])*/
  final T field;

  /*element: C.fixedFunctionField:[subclass=Closure]*/
  int Function() fixedFunctionField = /*[exact=JSUInt31]*/ () => 0;

  /*element: C.functionField:[null|subclass=Closure]*/
  T Function() functionField;

  /*element: C.genericFunctionField:[null|subclass=Closure]*/
  S Function<S>(S) genericFunctionField;

  /*element: C.:[exact=C]*/
  C(this. /*Union([exact=JSString], [exact=JSUInt31])*/ field) {
    /*update: [subclass=C]*/ functionField =
        /*Union([exact=JSString], [exact=JSUInt31])*/
        () => /*[subclass=C]*/ field;
    /*Union([exact=JSString], [exact=JSUInt31])*/
    S local<S>(S /*Union([exact=JSString], [exact=JSUInt31])*/ s) => s;
    /*update: [subclass=C]*/ genericFunctionField = local;
  }

  /*element: C.method:Union([exact=JSString], [exact=JSUInt31])*/
  T method() => /*[subclass=C]*/ field;

  /*element: C.+:Union([exact=JSString], [exact=JSUInt31])*/
  T operator +(T /*Union([exact=JSString], [exact=JSUInt31])*/ t) =>
      /*[subclass=C]*/ field;

  /*element: C.getter:Union([exact=JSString], [exact=JSUInt31])*/
  T get getter => /*[subclass=C]*/ field;

  /*element: C.fixedFunctionGetter:[subclass=Closure]*/
  int Function() get fixedFunctionGetter => /*[exact=JSUInt31]*/ () => 0;

  /*element: C.functionGetter:[null|subclass=Closure]*/
  T Function() get functionGetter => /*[subclass=C]*/ functionField;

  /*element: C.genericFunctionGetter:[null|subclass=Closure]*/
  S Function<S>(S) get genericFunctionGetter =>
      /*[subclass=C]*/ genericFunctionField;

  /*element: C.genericMethod:Union([exact=JSString], [exact=JSUInt31])*/
  S genericMethod<S>(S /*Union([exact=JSString], [exact=JSUInt31])*/ s) => s;
}

class D1 extends C<int> {
  /*element: D1.:[exact=D1]*/
  D1(int /*[exact=JSUInt31]*/ field) : super(field);

  /*element: D1.superFieldAccess:[exact=JSUInt31]*/
  superFieldAccess() => super.field;

  /*element: D1.superFieldInvoke:[null|subclass=JSInt]*/
  superFieldInvoke() => super.functionField();

  /*element: D1.superFixedFieldInvoke:[null|subclass=JSInt]*/
  superFixedFieldInvoke() => super.fixedFunctionField();

  /*element: D1.superMethodInvoke:[exact=JSUInt31]*/
  superMethodInvoke() => super.method();

  /*element: D1.superOperatorInvoke:[exact=JSUInt31]*/
  superOperatorInvoke() => super + 0;

  /*element: D1.superGetterAccess:[exact=JSUInt31]*/
  superGetterAccess() => super.getter;

  /*element: D1.superGetterInvoke:[null|subclass=JSInt]*/
  superGetterInvoke() => super.functionGetter();

  /*element: D1.superFixedGetterInvoke:[null|subclass=JSInt]*/
  superFixedGetterInvoke() => super.fixedFunctionGetter();

  /*element: D1.superGenericFieldInvoke1:[null|exact=JSString]*/
  superGenericFieldInvoke1() => super.genericFunctionField('');

  /*element: D1.superGenericFieldInvoke2:[null|subclass=JSInt]*/
  superGenericFieldInvoke2() => super.genericFunctionField(0);

  /*element: D1.superGenericMethodInvoke1:[exact=JSString]*/
  superGenericMethodInvoke1() => super.genericMethod('');

  /*element: D1.superGenericMethodInvoke2:[exact=JSUInt31]*/
  superGenericMethodInvoke2() => super.genericMethod(0);

  /*element: D1.superGenericGetterInvoke1:[null|exact=JSString]*/
  superGenericGetterInvoke1() => super.genericFunctionGetter('');

  /*element: D1.superGenericGetterInvoke2:[null|subclass=JSInt]*/
  superGenericGetterInvoke2() => super.genericFunctionGetter(0);
}

class D2 extends C<String> {
  /*element: D2.:[exact=D2]*/
  D2(String /*Value([exact=JSString], value: "")*/ field) : super(field);

  /*element: D2.superFieldAccess:[exact=JSString]*/
  superFieldAccess() => super.field;

  /*element: D2.superFieldInvoke:[null|exact=JSString]*/
  superFieldInvoke() => super.functionField();

  /*element: D2.superFixedFieldInvoke:[null|subclass=JSInt]*/
  superFixedFieldInvoke() => super.fixedFunctionField();

  /*element: D2.superMethodInvoke:[exact=JSString]*/
  superMethodInvoke() => super.method();

  /*element: D2.superOperatorInvoke:[exact=JSString]*/
  superOperatorInvoke() => super + '';

  /*element: D2.superGetterAccess:[exact=JSString]*/
  superGetterAccess() => super.getter;

  /*element: D2.superGetterInvoke:[null|exact=JSString]*/
  superGetterInvoke() => super.functionGetter();

  /*element: D2.superFixedGetterInvoke:[null|subclass=JSInt]*/
  superFixedGetterInvoke() => super.fixedFunctionGetter();

  /*element: D2.superGenericFieldInvoke1:[null|exact=JSString]*/
  superGenericFieldInvoke1() => super.genericFunctionField('');

  /*element: D2.superGenericFieldInvoke2:[null|subclass=JSInt]*/
  superGenericFieldInvoke2() => super.genericFunctionField(0);

  /*element: D2.superGenericMethodInvoke1:[exact=JSString]*/
  superGenericMethodInvoke1() => super.genericMethod('');

  /*element: D2.superGenericMethodInvoke2:[exact=JSUInt31]*/
  superGenericMethodInvoke2() => super.genericMethod(0);

  /*element: D2.superGenericGetterInvoke1:[null|exact=JSString]*/
  superGenericGetterInvoke1() => super.genericFunctionGetter('');

  /*element: D2.superGenericGetterInvoke2:[null|subclass=JSInt]*/
  superGenericGetterInvoke2() => super.genericFunctionGetter(0);
}

/*element: main:[null]*/
main() {
  closureInvoke();
  localFunctionInvoke();
  genericLocalFunctionInvoke();
  fieldAccess1();
  fieldAccess2();
  fixedFieldInvoke();
  fieldInvoke1();
  fieldInvoke2();
  methodInvoke1();
  methodInvoke2();
  operatorInvoke1();
  operatorInvoke2();
  fixedGetterInvoke();
  getterAccess1();
  getterAccess2();
  getterInvoke1();
  getterInvoke2();
  genericFieldInvoke1();
  genericFieldInvoke2();
  genericMethodInvoke1();
  genericMethodInvoke2();
  genericGetterInvoke1();
  genericGetterInvoke2();
  new D1(0)
    .. /*invoke: [exact=D1]*/ superFieldAccess()
    .. /*invoke: [exact=D1]*/ superFieldInvoke()
    .. /*invoke: [exact=D1]*/ superFixedFieldInvoke()
    .. /*invoke: [exact=D1]*/ superMethodInvoke()
    .. /*invoke: [exact=D1]*/ superOperatorInvoke()
    .. /*invoke: [exact=D1]*/ superGetterAccess()
    .. /*invoke: [exact=D1]*/ superGetterInvoke()
    .. /*invoke: [exact=D1]*/ superFixedGetterInvoke()
    .. /*invoke: [exact=D1]*/ superGenericFieldInvoke1()
    .. /*invoke: [exact=D1]*/ superGenericFieldInvoke2()
    .. /*invoke: [exact=D1]*/ superGenericMethodInvoke1()
    .. /*invoke: [exact=D1]*/ superGenericMethodInvoke2()
    .. /*invoke: [exact=D1]*/ superGenericGetterInvoke1()
    .. /*invoke: [exact=D1]*/ superGenericGetterInvoke2();
  new D2('')
    .. /*invoke: [exact=D2]*/ superFieldAccess()
    .. /*invoke: [exact=D2]*/ superFieldInvoke()
    .. /*invoke: [exact=D2]*/ superFixedFieldInvoke()
    .. /*invoke: [exact=D2]*/ superMethodInvoke()
    .. /*invoke: [exact=D2]*/ superOperatorInvoke()
    .. /*invoke: [exact=D2]*/ superGetterAccess()
    .. /*invoke: [exact=D2]*/ superGetterInvoke()
    .. /*invoke: [exact=D2]*/ superFixedGetterInvoke()
    .. /*invoke: [exact=D2]*/ superGenericFieldInvoke1()
    .. /*invoke: [exact=D2]*/ superGenericFieldInvoke2()
    .. /*invoke: [exact=D2]*/ superGenericMethodInvoke1()
    .. /*invoke: [exact=D2]*/ superGenericMethodInvoke2()
    .. /*invoke: [exact=D2]*/ superGenericGetterInvoke1()
    .. /*invoke: [exact=D2]*/ superGenericGetterInvoke2();
}

/*element: closureInvoke:[null|subclass=JSInt]*/
closureInvoke() {
  int Function() f = /*[exact=JSUInt31]*/ () => 0;
  return f();
}

/*element: localFunctionInvoke:[exact=JSUInt31]*/
localFunctionInvoke() {
  /*[exact=JSUInt31]*/
  int local() => 0;
  return local();
}

/*element: genericLocalFunctionInvoke:[null]*/
genericLocalFunctionInvoke() {
  /*Union([exact=JSString], [exact=JSUInt31])*/
  S local<S>(S /*Union([exact=JSString], [exact=JSUInt31])*/ s) => s;

  local(0). /*invoke: [exact=JSUInt31]*/ toString();
  local(''). /*invoke: [exact=JSString]*/ toString();
}

/*element: fieldAccess1:[exact=JSUInt31]*/
fieldAccess1() {
  C<int> c = new C<int>(0);
  return c. /*[exact=C]*/ field;
}

/*element: fieldAccess2:[exact=JSString]*/
fieldAccess2() {
  C<String> c = new C<String>('');
  return c. /*[exact=C]*/ field;
}

/*element: fixedFieldInvoke:[null|subclass=JSInt]*/
fixedFieldInvoke() {
  C<int> c = new C<int>(0);
  return c. /*invoke: [exact=C]*/ fixedFunctionField();
}

/*element: fieldInvoke1:[null|subclass=JSInt]*/
fieldInvoke1() {
  C<int> c = new C<int>(0);
  return c. /*invoke: [exact=C]*/ functionField();
}

/*element: fieldInvoke2:[null|exact=JSString]*/
fieldInvoke2() {
  C<String> c = new C<String>('');
  return c. /*invoke: [exact=C]*/ functionField();
}

/*element: methodInvoke1:[exact=JSUInt31]*/
methodInvoke1() {
  C<int> c = new C<int>(0);
  return c. /*invoke: [exact=C]*/ method();
}

/*element: methodInvoke2:[exact=JSString]*/
methodInvoke2() {
  C<String> c = new C<String>('');
  return c. /*invoke: [exact=C]*/ method();
}

/*element: operatorInvoke1:[exact=JSUInt31]*/
operatorInvoke1() {
  C<int> c = new C<int>(0);
  return c /*invoke: [exact=C]*/ + 0;
}

/*element: operatorInvoke2:[exact=JSString]*/
operatorInvoke2() {
  C<String> c = new C<String>('');
  return c /*invoke: [exact=C]*/ + '';
}

/*element: fixedGetterInvoke:[null|subclass=JSInt]*/
fixedGetterInvoke() {
  C<int> c = new C<int>(0);
  return c. /*invoke: [exact=C]*/ fixedFunctionGetter();
}

/*element: getterAccess1:[exact=JSUInt31]*/
getterAccess1() {
  C<int> c = new C<int>(0);
  return c. /*[exact=C]*/ getter;
}

/*element: getterAccess2:[exact=JSString]*/
getterAccess2() {
  C<String> c = new C<String>('');
  return c. /*[exact=C]*/ getter;
}

/*element: getterInvoke1:[null|subclass=JSInt]*/
getterInvoke1() {
  C<int> c = new C<int>(0);
  return c. /*invoke: [exact=C]*/ functionGetter();
}

/*element: getterInvoke2:[null|exact=JSString]*/
getterInvoke2() {
  C<String> c = new C<String>('');
  return c. /*invoke: [exact=C]*/ functionGetter();
}

/*element: genericFieldInvoke1:[null|exact=JSString]*/
genericFieldInvoke1() {
  C<int> c = new C<int>(0);
  return c. /*invoke: [exact=C]*/ genericFunctionField('');
}

/*element: genericFieldInvoke2:[null|subclass=JSInt]*/
genericFieldInvoke2() {
  C<String> c = new C<String>('');
  return c. /*invoke: [exact=C]*/ genericFunctionField(0);
}

/*element: genericMethodInvoke1:[exact=JSString]*/
genericMethodInvoke1() {
  C<int> c = new C<int>(0);
  return c. /*invoke: [exact=C]*/ genericMethod('');
}

/*element: genericMethodInvoke2:[exact=JSUInt31]*/
genericMethodInvoke2() {
  C<String> c = new C<String>('');
  return c. /*invoke: [exact=C]*/ genericMethod(0);
}

/*element: genericGetterInvoke1:[null|exact=JSString]*/
genericGetterInvoke1() {
  C<int> c = new C<int>(0);
  return c. /*invoke: [exact=C]*/ genericFunctionGetter('');
}

/*element: genericGetterInvoke2:[null|subclass=JSInt]*/
genericGetterInvoke2() {
  C<String> c = new C<String>('');
  return c. /*invoke: [exact=C]*/ genericFunctionGetter(0);
}
