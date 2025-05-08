// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {
  /*member: C.field:Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
  final T field;

  /*member: C.fixedFunctionField:[subclass=Closure|powerset={N}{O}]*/
  int Function() fixedFunctionField = /*[exact=JSUInt31|powerset={I}{O}]*/
      () => 0;

  /*member: C.functionField:[null|subclass=Closure|powerset={null}{N}{O}]*/
  T Function()? functionField;

  /*member: C.genericFunctionField:[null|subclass=Closure|powerset={null}{N}{O}]*/
  S Function<S>(S)? genericFunctionField;

  /*member: C.:[exact=C|powerset={N}{O}]*/
  C(
    this. /*Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/ field,
  ) {
    /*update: [subclass=C|powerset={N}{O}]*/
    functionField =
        /*Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
        () => /*[subclass=C|powerset={N}{O}]*/ field;
    /*Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
    S local<S>(
      S /*Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
      s,
    ) => s;
    /*update: [subclass=C|powerset={N}{O}]*/
    genericFunctionField = local;
  }

  /*member: C.method:Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
  T method() => /*[subclass=C|powerset={N}{O}]*/ field;

  /*member: C.+:Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
  T operator +(
    T /*Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
    t,
  ) =>
      /*[subclass=C|powerset={N}{O}]*/ field;

  /*member: C.getter:Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
  T get getter => /*[subclass=C|powerset={N}{O}]*/ field;

  /*member: C.fixedFunctionGetter:[subclass=Closure|powerset={N}{O}]*/
  int Function() get fixedFunctionGetter => /*[exact=JSUInt31|powerset={I}{O}]*/
      () => 0;

  /*member: C.functionGetter:[null|subclass=Closure|powerset={null}{N}{O}]*/
  T Function()? get functionGetter => /*[subclass=C|powerset={N}{O}]*/
      functionField;

  /*member: C.genericFunctionGetter:[null|subclass=Closure|powerset={null}{N}{O}]*/
  S Function<S>(S)? get genericFunctionGetter =>
      /*[subclass=C|powerset={N}{O}]*/ genericFunctionField;

  /*member: C.genericMethod:Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
  S genericMethod<S>(
    S /*Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
    s,
  ) => s;
}

class D1 extends C<int> {
  /*member: D1.:[exact=D1|powerset={N}{O}]*/
  D1(int /*[exact=JSUInt31|powerset={I}{O}]*/ field) : super(field);

  /*member: D1.superFieldAccess:[exact=JSUInt31|powerset={I}{O}]*/
  superFieldAccess() => super.field;

  /*member: D1.superFieldInvoke:[subclass=JSInt|powerset={I}{O}]*/
  superFieldInvoke() => super.functionField!();

  /*member: D1.superFixedFieldInvoke:[subclass=JSInt|powerset={I}{O}]*/
  superFixedFieldInvoke() => super.fixedFunctionField();

  /*member: D1.superMethodInvoke:[exact=JSUInt31|powerset={I}{O}]*/
  superMethodInvoke() => super.method();

  /*member: D1.superOperatorInvoke:[exact=JSUInt31|powerset={I}{O}]*/
  superOperatorInvoke() => super + 0;

  /*member: D1.superGetterAccess:[exact=JSUInt31|powerset={I}{O}]*/
  superGetterAccess() => super.getter;

  /*member: D1.superGetterInvoke:[subclass=JSInt|powerset={I}{O}]*/
  superGetterInvoke() => super.functionGetter!();

  /*member: D1.superFixedGetterInvoke:[subclass=JSInt|powerset={I}{O}]*/
  superFixedGetterInvoke() => super.fixedFunctionGetter();

  /*member: D1.superGenericFieldInvoke1:[exact=JSString|powerset={I}{O}]*/
  superGenericFieldInvoke1() => super.genericFunctionField!('');

  /*member: D1.superGenericFieldInvoke2:[subclass=JSInt|powerset={I}{O}]*/
  superGenericFieldInvoke2() => super.genericFunctionField!(0);

  /*member: D1.superGenericMethodInvoke1:[exact=JSString|powerset={I}{O}]*/
  superGenericMethodInvoke1() => super.genericMethod('');

  /*member: D1.superGenericMethodInvoke2:[exact=JSUInt31|powerset={I}{O}]*/
  superGenericMethodInvoke2() => super.genericMethod(0);

  /*member: D1.superGenericGetterInvoke1:[exact=JSString|powerset={I}{O}]*/
  superGenericGetterInvoke1() => super.genericFunctionGetter!('');

  /*member: D1.superGenericGetterInvoke2:[subclass=JSInt|powerset={I}{O}]*/
  superGenericGetterInvoke2() => super.genericFunctionGetter!(0);
}

class D2 extends C<String> {
  /*member: D2.:[exact=D2|powerset={N}{O}]*/
  D2(
    String /*Value([exact=JSString|powerset={I}{O}], value: "", powerset: {I}{O})*/
    field,
  ) : super(field);

  /*member: D2.superFieldAccess:[exact=JSString|powerset={I}{O}]*/
  superFieldAccess() => super.field;

  /*member: D2.superFieldInvoke:[exact=JSString|powerset={I}{O}]*/
  superFieldInvoke() => super.functionField!();

  /*member: D2.superFixedFieldInvoke:[subclass=JSInt|powerset={I}{O}]*/
  superFixedFieldInvoke() => super.fixedFunctionField();

  /*member: D2.superMethodInvoke:[exact=JSString|powerset={I}{O}]*/
  superMethodInvoke() => super.method();

  /*member: D2.superOperatorInvoke:[exact=JSString|powerset={I}{O}]*/
  superOperatorInvoke() => super + '';

  /*member: D2.superGetterAccess:[exact=JSString|powerset={I}{O}]*/
  superGetterAccess() => super.getter;

  /*member: D2.superGetterInvoke:[exact=JSString|powerset={I}{O}]*/
  superGetterInvoke() => super.functionGetter!();

  /*member: D2.superFixedGetterInvoke:[subclass=JSInt|powerset={I}{O}]*/
  superFixedGetterInvoke() => super.fixedFunctionGetter();

  /*member: D2.superGenericFieldInvoke1:[exact=JSString|powerset={I}{O}]*/
  superGenericFieldInvoke1() => super.genericFunctionField!('');

  /*member: D2.superGenericFieldInvoke2:[subclass=JSInt|powerset={I}{O}]*/
  superGenericFieldInvoke2() => super.genericFunctionField!(0);

  /*member: D2.superGenericMethodInvoke1:[exact=JSString|powerset={I}{O}]*/
  superGenericMethodInvoke1() => super.genericMethod('');

  /*member: D2.superGenericMethodInvoke2:[exact=JSUInt31|powerset={I}{O}]*/
  superGenericMethodInvoke2() => super.genericMethod(0);

  /*member: D2.superGenericGetterInvoke1:[exact=JSString|powerset={I}{O}]*/
  superGenericGetterInvoke1() => super.genericFunctionGetter!('');

  /*member: D2.superGenericGetterInvoke2:[subclass=JSInt|powerset={I}{O}]*/
  superGenericGetterInvoke2() => super.genericFunctionGetter!(0);
}

/*member: main:[null|powerset={null}]*/
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
    .. /*invoke: [exact=D1|powerset={N}{O}]*/ superFieldAccess()
    .. /*invoke: [exact=D1|powerset={N}{O}]*/ superFieldInvoke()
    .. /*invoke: [exact=D1|powerset={N}{O}]*/ superFixedFieldInvoke()
    .. /*invoke: [exact=D1|powerset={N}{O}]*/ superMethodInvoke()
    .. /*invoke: [exact=D1|powerset={N}{O}]*/ superOperatorInvoke()
    .. /*invoke: [exact=D1|powerset={N}{O}]*/ superGetterAccess()
    .. /*invoke: [exact=D1|powerset={N}{O}]*/ superGetterInvoke()
    .. /*invoke: [exact=D1|powerset={N}{O}]*/ superFixedGetterInvoke()
    .. /*invoke: [exact=D1|powerset={N}{O}]*/ superGenericFieldInvoke1()
    .. /*invoke: [exact=D1|powerset={N}{O}]*/ superGenericFieldInvoke2()
    .. /*invoke: [exact=D1|powerset={N}{O}]*/ superGenericMethodInvoke1()
    .. /*invoke: [exact=D1|powerset={N}{O}]*/ superGenericMethodInvoke2()
    .. /*invoke: [exact=D1|powerset={N}{O}]*/ superGenericGetterInvoke1()
    .. /*invoke: [exact=D1|powerset={N}{O}]*/ superGenericGetterInvoke2();
  D2('')
    .. /*invoke: [exact=D2|powerset={N}{O}]*/ superFieldAccess()
    .. /*invoke: [exact=D2|powerset={N}{O}]*/ superFieldInvoke()
    .. /*invoke: [exact=D2|powerset={N}{O}]*/ superFixedFieldInvoke()
    .. /*invoke: [exact=D2|powerset={N}{O}]*/ superMethodInvoke()
    .. /*invoke: [exact=D2|powerset={N}{O}]*/ superOperatorInvoke()
    .. /*invoke: [exact=D2|powerset={N}{O}]*/ superGetterAccess()
    .. /*invoke: [exact=D2|powerset={N}{O}]*/ superGetterInvoke()
    .. /*invoke: [exact=D2|powerset={N}{O}]*/ superFixedGetterInvoke()
    .. /*invoke: [exact=D2|powerset={N}{O}]*/ superGenericFieldInvoke1()
    .. /*invoke: [exact=D2|powerset={N}{O}]*/ superGenericFieldInvoke2()
    .. /*invoke: [exact=D2|powerset={N}{O}]*/ superGenericMethodInvoke1()
    .. /*invoke: [exact=D2|powerset={N}{O}]*/ superGenericMethodInvoke2()
    .. /*invoke: [exact=D2|powerset={N}{O}]*/ superGenericGetterInvoke1()
    .. /*invoke: [exact=D2|powerset={N}{O}]*/ superGenericGetterInvoke2();
}

/*member: closureInvoke:[subclass=JSInt|powerset={I}{O}]*/
closureInvoke() {
  int Function() f = /*[exact=JSUInt31|powerset={I}{O}]*/ () => 0;
  return f();
}

/*member: localFunctionInvoke:[exact=JSUInt31|powerset={I}{O}]*/
localFunctionInvoke() {
  /*[exact=JSUInt31|powerset={I}{O}]*/
  int local() => 0;
  return local();
}

/*member: genericLocalFunctionInvoke:[null|powerset={null}]*/
genericLocalFunctionInvoke() {
  /*Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
  S local<S>(
    S /*Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
    s,
  ) => s;

  local(0). /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ toString();
  local(''). /*invoke: [exact=JSString|powerset={I}{O}]*/ toString();
}

/*member: fieldAccess1:[exact=JSUInt31|powerset={I}{O}]*/
fieldAccess1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset={N}{O}]*/ field;
}

/*member: fieldAccess2:[exact=JSString|powerset={I}{O}]*/
fieldAccess2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset={N}{O}]*/ field;
}

/*member: fixedFieldInvoke:[subclass=JSInt|powerset={I}{O}]*/
fixedFieldInvoke() {
  C<int> c = C<int>(0);
  return c.fixedFunctionField /*invoke: [exact=C|powerset={N}{O}]*/ ();
}

/*member: fieldInvoke1:[subclass=JSInt|powerset={I}{O}]*/
fieldInvoke1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset={N}{O}]*/ functionField!();
}

/*member: fieldInvoke2:[exact=JSString|powerset={I}{O}]*/
fieldInvoke2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset={N}{O}]*/ functionField!();
}

/*member: methodInvoke1:[exact=JSUInt31|powerset={I}{O}]*/
methodInvoke1() {
  C<int> c = C<int>(0);
  return c. /*invoke: [exact=C|powerset={N}{O}]*/ method();
}

/*member: methodInvoke2:[exact=JSString|powerset={I}{O}]*/
methodInvoke2() {
  C<String> c = C<String>('');
  return c. /*invoke: [exact=C|powerset={N}{O}]*/ method();
}

/*member: operatorInvoke1:[exact=JSUInt31|powerset={I}{O}]*/
operatorInvoke1() {
  C<int> c = C<int>(0);
  return c /*invoke: [exact=C|powerset={N}{O}]*/ + 0;
}

/*member: operatorInvoke2:[exact=JSString|powerset={I}{O}]*/
operatorInvoke2() {
  C<String> c = C<String>('');
  return c /*invoke: [exact=C|powerset={N}{O}]*/ + '';
}

/*member: fixedGetterInvoke:[subclass=JSInt|powerset={I}{O}]*/
fixedGetterInvoke() {
  C<int> c = C<int>(0);
  return c.fixedFunctionGetter /*invoke: [exact=C|powerset={N}{O}]*/ ();
}

/*member: getterAccess1:[exact=JSUInt31|powerset={I}{O}]*/
getterAccess1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset={N}{O}]*/ getter;
}

/*member: getterAccess2:[exact=JSString|powerset={I}{O}]*/
getterAccess2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset={N}{O}]*/ getter;
}

/*member: getterInvoke1:[subclass=JSInt|powerset={I}{O}]*/
getterInvoke1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset={N}{O}]*/ functionGetter!();
}

/*member: getterInvoke2:[exact=JSString|powerset={I}{O}]*/
getterInvoke2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset={N}{O}]*/ functionGetter!();
}

/*member: genericFieldInvoke1:[exact=JSString|powerset={I}{O}]*/
genericFieldInvoke1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset={N}{O}]*/ genericFunctionField!('');
}

/*member: genericFieldInvoke2:[subclass=JSInt|powerset={I}{O}]*/
genericFieldInvoke2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset={N}{O}]*/ genericFunctionField!(0);
}

/*member: genericMethodInvoke1:[exact=JSString|powerset={I}{O}]*/
genericMethodInvoke1() {
  C<int> c = C<int>(0);
  return c. /*invoke: [exact=C|powerset={N}{O}]*/ genericMethod('');
}

/*member: genericMethodInvoke2:[exact=JSUInt31|powerset={I}{O}]*/
genericMethodInvoke2() {
  C<String> c = C<String>('');
  return c. /*invoke: [exact=C|powerset={N}{O}]*/ genericMethod(0);
}

/*member: genericGetterInvoke1:[exact=JSString|powerset={I}{O}]*/
genericGetterInvoke1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset={N}{O}]*/ genericFunctionGetter!('');
}

/*member: genericGetterInvoke2:[subclass=JSInt|powerset={I}{O}]*/
genericGetterInvoke2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset={N}{O}]*/ genericFunctionGetter!(0);
}
