// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {
  /*member: C.field:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
  final T field;

  /*member: C.fixedFunctionField:[subclass=Closure|powerset=0]*/
  int Function() fixedFunctionField = /*[exact=JSUInt31|powerset=0]*/ () => 0;

  /*member: C.functionField:[null|subclass=Closure|powerset=1]*/
  T Function()? functionField;

  /*member: C.genericFunctionField:[null|subclass=Closure|powerset=1]*/
  S Function<S>(S)? genericFunctionField;

  /*member: C.:[exact=C|powerset=0]*/
  C(
    this. /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ field,
  ) {
    /*update: [subclass=C|powerset=0]*/
    functionField =
        /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
        () => /*[subclass=C|powerset=0]*/ field;
    /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
    S local<S>(
      S /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
      s,
    ) => s;
    /*update: [subclass=C|powerset=0]*/
    genericFunctionField = local;
  }

  /*member: C.method:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
  T method() => /*[subclass=C|powerset=0]*/ field;

  /*member: C.+:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
  T operator +(
    T /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
    t,
  ) =>
      /*[subclass=C|powerset=0]*/ field;

  /*member: C.getter:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
  T get getter => /*[subclass=C|powerset=0]*/ field;

  /*member: C.fixedFunctionGetter:[subclass=Closure|powerset=0]*/
  int Function() get fixedFunctionGetter => /*[exact=JSUInt31|powerset=0]*/
      () => 0;

  /*member: C.functionGetter:[null|subclass=Closure|powerset=1]*/
  T Function()? get functionGetter => /*[subclass=C|powerset=0]*/ functionField;

  /*member: C.genericFunctionGetter:[null|subclass=Closure|powerset=1]*/
  S Function<S>(S)? get genericFunctionGetter =>
      /*[subclass=C|powerset=0]*/ genericFunctionField;

  /*member: C.genericMethod:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
  S genericMethod<S>(
    S /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
    s,
  ) => s;
}

class D1 extends C<int> {
  /*member: D1.:[exact=D1|powerset=0]*/
  D1(int /*[exact=JSUInt31|powerset=0]*/ field) : super(field);

  /*member: D1.superFieldAccess:[exact=JSUInt31|powerset=0]*/
  superFieldAccess() => super.field;

  /*member: D1.superFieldInvoke:[subclass=JSInt|powerset=0]*/
  superFieldInvoke() => super.functionField!();

  /*member: D1.superFixedFieldInvoke:[subclass=JSInt|powerset=0]*/
  superFixedFieldInvoke() => super.fixedFunctionField();

  /*member: D1.superMethodInvoke:[exact=JSUInt31|powerset=0]*/
  superMethodInvoke() => super.method();

  /*member: D1.superOperatorInvoke:[exact=JSUInt31|powerset=0]*/
  superOperatorInvoke() => super + 0;

  /*member: D1.superGetterAccess:[exact=JSUInt31|powerset=0]*/
  superGetterAccess() => super.getter;

  /*member: D1.superGetterInvoke:[subclass=JSInt|powerset=0]*/
  superGetterInvoke() => super.functionGetter!();

  /*member: D1.superFixedGetterInvoke:[subclass=JSInt|powerset=0]*/
  superFixedGetterInvoke() => super.fixedFunctionGetter();

  /*member: D1.superGenericFieldInvoke1:[exact=JSString|powerset=0]*/
  superGenericFieldInvoke1() => super.genericFunctionField!('');

  /*member: D1.superGenericFieldInvoke2:[subclass=JSInt|powerset=0]*/
  superGenericFieldInvoke2() => super.genericFunctionField!(0);

  /*member: D1.superGenericMethodInvoke1:[exact=JSString|powerset=0]*/
  superGenericMethodInvoke1() => super.genericMethod('');

  /*member: D1.superGenericMethodInvoke2:[exact=JSUInt31|powerset=0]*/
  superGenericMethodInvoke2() => super.genericMethod(0);

  /*member: D1.superGenericGetterInvoke1:[exact=JSString|powerset=0]*/
  superGenericGetterInvoke1() => super.genericFunctionGetter!('');

  /*member: D1.superGenericGetterInvoke2:[subclass=JSInt|powerset=0]*/
  superGenericGetterInvoke2() => super.genericFunctionGetter!(0);
}

class D2 extends C<String> {
  /*member: D2.:[exact=D2|powerset=0]*/
  D2(
    String /*Value([exact=JSString|powerset=0], value: "", powerset: 0)*/ field,
  ) : super(field);

  /*member: D2.superFieldAccess:[exact=JSString|powerset=0]*/
  superFieldAccess() => super.field;

  /*member: D2.superFieldInvoke:[exact=JSString|powerset=0]*/
  superFieldInvoke() => super.functionField!();

  /*member: D2.superFixedFieldInvoke:[subclass=JSInt|powerset=0]*/
  superFixedFieldInvoke() => super.fixedFunctionField();

  /*member: D2.superMethodInvoke:[exact=JSString|powerset=0]*/
  superMethodInvoke() => super.method();

  /*member: D2.superOperatorInvoke:[exact=JSString|powerset=0]*/
  superOperatorInvoke() => super + '';

  /*member: D2.superGetterAccess:[exact=JSString|powerset=0]*/
  superGetterAccess() => super.getter;

  /*member: D2.superGetterInvoke:[exact=JSString|powerset=0]*/
  superGetterInvoke() => super.functionGetter!();

  /*member: D2.superFixedGetterInvoke:[subclass=JSInt|powerset=0]*/
  superFixedGetterInvoke() => super.fixedFunctionGetter();

  /*member: D2.superGenericFieldInvoke1:[exact=JSString|powerset=0]*/
  superGenericFieldInvoke1() => super.genericFunctionField!('');

  /*member: D2.superGenericFieldInvoke2:[subclass=JSInt|powerset=0]*/
  superGenericFieldInvoke2() => super.genericFunctionField!(0);

  /*member: D2.superGenericMethodInvoke1:[exact=JSString|powerset=0]*/
  superGenericMethodInvoke1() => super.genericMethod('');

  /*member: D2.superGenericMethodInvoke2:[exact=JSUInt31|powerset=0]*/
  superGenericMethodInvoke2() => super.genericMethod(0);

  /*member: D2.superGenericGetterInvoke1:[exact=JSString|powerset=0]*/
  superGenericGetterInvoke1() => super.genericFunctionGetter!('');

  /*member: D2.superGenericGetterInvoke2:[subclass=JSInt|powerset=0]*/
  superGenericGetterInvoke2() => super.genericFunctionGetter!(0);
}

/*member: main:[null|powerset=1]*/
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
  D1(0)
    .. /*invoke: [exact=D1|powerset=0]*/ superFieldAccess()
    .. /*invoke: [exact=D1|powerset=0]*/ superFieldInvoke()
    .. /*invoke: [exact=D1|powerset=0]*/ superFixedFieldInvoke()
    .. /*invoke: [exact=D1|powerset=0]*/ superMethodInvoke()
    .. /*invoke: [exact=D1|powerset=0]*/ superOperatorInvoke()
    .. /*invoke: [exact=D1|powerset=0]*/ superGetterAccess()
    .. /*invoke: [exact=D1|powerset=0]*/ superGetterInvoke()
    .. /*invoke: [exact=D1|powerset=0]*/ superFixedGetterInvoke()
    .. /*invoke: [exact=D1|powerset=0]*/ superGenericFieldInvoke1()
    .. /*invoke: [exact=D1|powerset=0]*/ superGenericFieldInvoke2()
    .. /*invoke: [exact=D1|powerset=0]*/ superGenericMethodInvoke1()
    .. /*invoke: [exact=D1|powerset=0]*/ superGenericMethodInvoke2()
    .. /*invoke: [exact=D1|powerset=0]*/ superGenericGetterInvoke1()
    .. /*invoke: [exact=D1|powerset=0]*/ superGenericGetterInvoke2();
  D2('')
    .. /*invoke: [exact=D2|powerset=0]*/ superFieldAccess()
    .. /*invoke: [exact=D2|powerset=0]*/ superFieldInvoke()
    .. /*invoke: [exact=D2|powerset=0]*/ superFixedFieldInvoke()
    .. /*invoke: [exact=D2|powerset=0]*/ superMethodInvoke()
    .. /*invoke: [exact=D2|powerset=0]*/ superOperatorInvoke()
    .. /*invoke: [exact=D2|powerset=0]*/ superGetterAccess()
    .. /*invoke: [exact=D2|powerset=0]*/ superGetterInvoke()
    .. /*invoke: [exact=D2|powerset=0]*/ superFixedGetterInvoke()
    .. /*invoke: [exact=D2|powerset=0]*/ superGenericFieldInvoke1()
    .. /*invoke: [exact=D2|powerset=0]*/ superGenericFieldInvoke2()
    .. /*invoke: [exact=D2|powerset=0]*/ superGenericMethodInvoke1()
    .. /*invoke: [exact=D2|powerset=0]*/ superGenericMethodInvoke2()
    .. /*invoke: [exact=D2|powerset=0]*/ superGenericGetterInvoke1()
    .. /*invoke: [exact=D2|powerset=0]*/ superGenericGetterInvoke2();
}

/*member: closureInvoke:[subclass=JSInt|powerset=0]*/
closureInvoke() {
  int Function() f = /*[exact=JSUInt31|powerset=0]*/ () => 0;
  return f();
}

/*member: localFunctionInvoke:[exact=JSUInt31|powerset=0]*/
localFunctionInvoke() {
  /*[exact=JSUInt31|powerset=0]*/
  int local() => 0;
  return local();
}

/*member: genericLocalFunctionInvoke:[null|powerset=1]*/
genericLocalFunctionInvoke() {
  /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
  S local<S>(
    S /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
    s,
  ) => s;

  local(0). /*invoke: [exact=JSUInt31|powerset=0]*/ toString();
  local(''). /*invoke: [exact=JSString|powerset=0]*/ toString();
}

/*member: fieldAccess1:[exact=JSUInt31|powerset=0]*/
fieldAccess1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset=0]*/ field;
}

/*member: fieldAccess2:[exact=JSString|powerset=0]*/
fieldAccess2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset=0]*/ field;
}

/*member: fixedFieldInvoke:[subclass=JSInt|powerset=0]*/
fixedFieldInvoke() {
  C<int> c = C<int>(0);
  return c.fixedFunctionField /*invoke: [exact=C|powerset=0]*/ ();
}

/*member: fieldInvoke1:[subclass=JSInt|powerset=0]*/
fieldInvoke1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset=0]*/ functionField!();
}

/*member: fieldInvoke2:[exact=JSString|powerset=0]*/
fieldInvoke2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset=0]*/ functionField!();
}

/*member: methodInvoke1:[exact=JSUInt31|powerset=0]*/
methodInvoke1() {
  C<int> c = C<int>(0);
  return c. /*invoke: [exact=C|powerset=0]*/ method();
}

/*member: methodInvoke2:[exact=JSString|powerset=0]*/
methodInvoke2() {
  C<String> c = C<String>('');
  return c. /*invoke: [exact=C|powerset=0]*/ method();
}

/*member: operatorInvoke1:[exact=JSUInt31|powerset=0]*/
operatorInvoke1() {
  C<int> c = C<int>(0);
  return c /*invoke: [exact=C|powerset=0]*/ + 0;
}

/*member: operatorInvoke2:[exact=JSString|powerset=0]*/
operatorInvoke2() {
  C<String> c = C<String>('');
  return c /*invoke: [exact=C|powerset=0]*/ + '';
}

/*member: fixedGetterInvoke:[subclass=JSInt|powerset=0]*/
fixedGetterInvoke() {
  C<int> c = C<int>(0);
  return c.fixedFunctionGetter /*invoke: [exact=C|powerset=0]*/ ();
}

/*member: getterAccess1:[exact=JSUInt31|powerset=0]*/
getterAccess1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset=0]*/ getter;
}

/*member: getterAccess2:[exact=JSString|powerset=0]*/
getterAccess2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset=0]*/ getter;
}

/*member: getterInvoke1:[subclass=JSInt|powerset=0]*/
getterInvoke1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset=0]*/ functionGetter!();
}

/*member: getterInvoke2:[exact=JSString|powerset=0]*/
getterInvoke2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset=0]*/ functionGetter!();
}

/*member: genericFieldInvoke1:[exact=JSString|powerset=0]*/
genericFieldInvoke1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset=0]*/ genericFunctionField!('');
}

/*member: genericFieldInvoke2:[subclass=JSInt|powerset=0]*/
genericFieldInvoke2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset=0]*/ genericFunctionField!(0);
}

/*member: genericMethodInvoke1:[exact=JSString|powerset=0]*/
genericMethodInvoke1() {
  C<int> c = C<int>(0);
  return c. /*invoke: [exact=C|powerset=0]*/ genericMethod('');
}

/*member: genericMethodInvoke2:[exact=JSUInt31|powerset=0]*/
genericMethodInvoke2() {
  C<String> c = C<String>('');
  return c. /*invoke: [exact=C|powerset=0]*/ genericMethod(0);
}

/*member: genericGetterInvoke1:[exact=JSString|powerset=0]*/
genericGetterInvoke1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset=0]*/ genericFunctionGetter!('');
}

/*member: genericGetterInvoke2:[subclass=JSInt|powerset=0]*/
genericGetterInvoke2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset=0]*/ genericFunctionGetter!(0);
}
