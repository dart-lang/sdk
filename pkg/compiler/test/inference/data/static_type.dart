// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {
  /*member: C.field:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
  final T field;

  /*member: C.fixedFunctionField:[subclass=Closure|powerset={N}{O}{N}]*/
  int Function() fixedFunctionField = /*[exact=JSUInt31|powerset={I}{O}{N}]*/
      () => 0;

  /*member: C.functionField:[null|subclass=Closure|powerset={null}{N}{O}{N}]*/
  T Function()? functionField;

  /*member: C.genericFunctionField:[null|subclass=Closure|powerset={null}{N}{O}{N}]*/
  S Function<S>(S)? genericFunctionField;

  /*member: C.:[exact=C|powerset={N}{O}{N}]*/
  C(
    this. /*Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/ field,
  ) {
    /*update: [subclass=C|powerset={N}{O}{N}]*/
    functionField =
        /*Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
        () => /*[subclass=C|powerset={N}{O}{N}]*/ field;
    /*Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
    S local<S>(
      S /*Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
      s,
    ) => s;
    /*update: [subclass=C|powerset={N}{O}{N}]*/
    genericFunctionField = local;
  }

  /*member: C.method:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
  T method() => /*[subclass=C|powerset={N}{O}{N}]*/ field;

  /*member: C.+:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
  T operator +(
    T /*Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
    t,
  ) =>
      /*[subclass=C|powerset={N}{O}{N}]*/ field;

  /*member: C.getter:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
  T get getter => /*[subclass=C|powerset={N}{O}{N}]*/ field;

  /*member: C.fixedFunctionGetter:[subclass=Closure|powerset={N}{O}{N}]*/
  int Function()
  get fixedFunctionGetter => /*[exact=JSUInt31|powerset={I}{O}{N}]*/
      () => 0;

  /*member: C.functionGetter:[null|subclass=Closure|powerset={null}{N}{O}{N}]*/
  T Function()? get functionGetter => /*[subclass=C|powerset={N}{O}{N}]*/
      functionField;

  /*member: C.genericFunctionGetter:[null|subclass=Closure|powerset={null}{N}{O}{N}]*/
  S Function<S>(S)? get genericFunctionGetter =>
      /*[subclass=C|powerset={N}{O}{N}]*/ genericFunctionField;

  /*member: C.genericMethod:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
  S genericMethod<S>(
    S /*Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
    s,
  ) => s;
}

class D1 extends C<int> {
  /*member: D1.:[exact=D1|powerset={N}{O}{N}]*/
  D1(int /*[exact=JSUInt31|powerset={I}{O}{N}]*/ field) : super(field);

  /*member: D1.superFieldAccess:[exact=JSUInt31|powerset={I}{O}{N}]*/
  superFieldAccess() => super.field;

  /*member: D1.superFieldInvoke:[subclass=JSInt|powerset={I}{O}{N}]*/
  superFieldInvoke() => super.functionField!();

  /*member: D1.superFixedFieldInvoke:[subclass=JSInt|powerset={I}{O}{N}]*/
  superFixedFieldInvoke() => super.fixedFunctionField();

  /*member: D1.superMethodInvoke:[exact=JSUInt31|powerset={I}{O}{N}]*/
  superMethodInvoke() => super.method();

  /*member: D1.superOperatorInvoke:[exact=JSUInt31|powerset={I}{O}{N}]*/
  superOperatorInvoke() => super + 0;

  /*member: D1.superGetterAccess:[exact=JSUInt31|powerset={I}{O}{N}]*/
  superGetterAccess() => super.getter;

  /*member: D1.superGetterInvoke:[subclass=JSInt|powerset={I}{O}{N}]*/
  superGetterInvoke() => super.functionGetter!();

  /*member: D1.superFixedGetterInvoke:[subclass=JSInt|powerset={I}{O}{N}]*/
  superFixedGetterInvoke() => super.fixedFunctionGetter();

  /*member: D1.superGenericFieldInvoke1:[exact=JSString|powerset={I}{O}{I}]*/
  superGenericFieldInvoke1() => super.genericFunctionField!('');

  /*member: D1.superGenericFieldInvoke2:[subclass=JSInt|powerset={I}{O}{N}]*/
  superGenericFieldInvoke2() => super.genericFunctionField!(0);

  /*member: D1.superGenericMethodInvoke1:[exact=JSString|powerset={I}{O}{I}]*/
  superGenericMethodInvoke1() => super.genericMethod('');

  /*member: D1.superGenericMethodInvoke2:[exact=JSUInt31|powerset={I}{O}{N}]*/
  superGenericMethodInvoke2() => super.genericMethod(0);

  /*member: D1.superGenericGetterInvoke1:[exact=JSString|powerset={I}{O}{I}]*/
  superGenericGetterInvoke1() => super.genericFunctionGetter!('');

  /*member: D1.superGenericGetterInvoke2:[subclass=JSInt|powerset={I}{O}{N}]*/
  superGenericGetterInvoke2() => super.genericFunctionGetter!(0);
}

class D2 extends C<String> {
  /*member: D2.:[exact=D2|powerset={N}{O}{N}]*/
  D2(
    String /*Value([exact=JSString|powerset={I}{O}{I}], value: "", powerset: {I}{O}{I})*/
    field,
  ) : super(field);

  /*member: D2.superFieldAccess:[exact=JSString|powerset={I}{O}{I}]*/
  superFieldAccess() => super.field;

  /*member: D2.superFieldInvoke:[exact=JSString|powerset={I}{O}{I}]*/
  superFieldInvoke() => super.functionField!();

  /*member: D2.superFixedFieldInvoke:[subclass=JSInt|powerset={I}{O}{N}]*/
  superFixedFieldInvoke() => super.fixedFunctionField();

  /*member: D2.superMethodInvoke:[exact=JSString|powerset={I}{O}{I}]*/
  superMethodInvoke() => super.method();

  /*member: D2.superOperatorInvoke:[exact=JSString|powerset={I}{O}{I}]*/
  superOperatorInvoke() => super + '';

  /*member: D2.superGetterAccess:[exact=JSString|powerset={I}{O}{I}]*/
  superGetterAccess() => super.getter;

  /*member: D2.superGetterInvoke:[exact=JSString|powerset={I}{O}{I}]*/
  superGetterInvoke() => super.functionGetter!();

  /*member: D2.superFixedGetterInvoke:[subclass=JSInt|powerset={I}{O}{N}]*/
  superFixedGetterInvoke() => super.fixedFunctionGetter();

  /*member: D2.superGenericFieldInvoke1:[exact=JSString|powerset={I}{O}{I}]*/
  superGenericFieldInvoke1() => super.genericFunctionField!('');

  /*member: D2.superGenericFieldInvoke2:[subclass=JSInt|powerset={I}{O}{N}]*/
  superGenericFieldInvoke2() => super.genericFunctionField!(0);

  /*member: D2.superGenericMethodInvoke1:[exact=JSString|powerset={I}{O}{I}]*/
  superGenericMethodInvoke1() => super.genericMethod('');

  /*member: D2.superGenericMethodInvoke2:[exact=JSUInt31|powerset={I}{O}{N}]*/
  superGenericMethodInvoke2() => super.genericMethod(0);

  /*member: D2.superGenericGetterInvoke1:[exact=JSString|powerset={I}{O}{I}]*/
  superGenericGetterInvoke1() => super.genericFunctionGetter!('');

  /*member: D2.superGenericGetterInvoke2:[subclass=JSInt|powerset={I}{O}{N}]*/
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
    .. /*invoke: [exact=D1|powerset={N}{O}{N}]*/ superFieldAccess()
    .. /*invoke: [exact=D1|powerset={N}{O}{N}]*/ superFieldInvoke()
    .. /*invoke: [exact=D1|powerset={N}{O}{N}]*/ superFixedFieldInvoke()
    .. /*invoke: [exact=D1|powerset={N}{O}{N}]*/ superMethodInvoke()
    .. /*invoke: [exact=D1|powerset={N}{O}{N}]*/ superOperatorInvoke()
    .. /*invoke: [exact=D1|powerset={N}{O}{N}]*/ superGetterAccess()
    .. /*invoke: [exact=D1|powerset={N}{O}{N}]*/ superGetterInvoke()
    .. /*invoke: [exact=D1|powerset={N}{O}{N}]*/ superFixedGetterInvoke()
    .. /*invoke: [exact=D1|powerset={N}{O}{N}]*/ superGenericFieldInvoke1()
    .. /*invoke: [exact=D1|powerset={N}{O}{N}]*/ superGenericFieldInvoke2()
    .. /*invoke: [exact=D1|powerset={N}{O}{N}]*/ superGenericMethodInvoke1()
    .. /*invoke: [exact=D1|powerset={N}{O}{N}]*/ superGenericMethodInvoke2()
    .. /*invoke: [exact=D1|powerset={N}{O}{N}]*/ superGenericGetterInvoke1()
    .. /*invoke: [exact=D1|powerset={N}{O}{N}]*/ superGenericGetterInvoke2();
  D2('')
    .. /*invoke: [exact=D2|powerset={N}{O}{N}]*/ superFieldAccess()
    .. /*invoke: [exact=D2|powerset={N}{O}{N}]*/ superFieldInvoke()
    .. /*invoke: [exact=D2|powerset={N}{O}{N}]*/ superFixedFieldInvoke()
    .. /*invoke: [exact=D2|powerset={N}{O}{N}]*/ superMethodInvoke()
    .. /*invoke: [exact=D2|powerset={N}{O}{N}]*/ superOperatorInvoke()
    .. /*invoke: [exact=D2|powerset={N}{O}{N}]*/ superGetterAccess()
    .. /*invoke: [exact=D2|powerset={N}{O}{N}]*/ superGetterInvoke()
    .. /*invoke: [exact=D2|powerset={N}{O}{N}]*/ superFixedGetterInvoke()
    .. /*invoke: [exact=D2|powerset={N}{O}{N}]*/ superGenericFieldInvoke1()
    .. /*invoke: [exact=D2|powerset={N}{O}{N}]*/ superGenericFieldInvoke2()
    .. /*invoke: [exact=D2|powerset={N}{O}{N}]*/ superGenericMethodInvoke1()
    .. /*invoke: [exact=D2|powerset={N}{O}{N}]*/ superGenericMethodInvoke2()
    .. /*invoke: [exact=D2|powerset={N}{O}{N}]*/ superGenericGetterInvoke1()
    .. /*invoke: [exact=D2|powerset={N}{O}{N}]*/ superGenericGetterInvoke2();
}

/*member: closureInvoke:[subclass=JSInt|powerset={I}{O}{N}]*/
closureInvoke() {
  int Function() f = /*[exact=JSUInt31|powerset={I}{O}{N}]*/ () => 0;
  return f();
}

/*member: localFunctionInvoke:[exact=JSUInt31|powerset={I}{O}{N}]*/
localFunctionInvoke() {
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/
  int local() => 0;
  return local();
}

/*member: genericLocalFunctionInvoke:[null|powerset={null}]*/
genericLocalFunctionInvoke() {
  /*Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
  S local<S>(
    S /*Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
    s,
  ) => s;

  local(0). /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ toString();
  local(''). /*invoke: [exact=JSString|powerset={I}{O}{I}]*/ toString();
}

/*member: fieldAccess1:[exact=JSUInt31|powerset={I}{O}{N}]*/
fieldAccess1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset={N}{O}{N}]*/ field;
}

/*member: fieldAccess2:[exact=JSString|powerset={I}{O}{I}]*/
fieldAccess2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset={N}{O}{N}]*/ field;
}

/*member: fixedFieldInvoke:[subclass=JSInt|powerset={I}{O}{N}]*/
fixedFieldInvoke() {
  C<int> c = C<int>(0);
  return c.fixedFunctionField /*invoke: [exact=C|powerset={N}{O}{N}]*/ ();
}

/*member: fieldInvoke1:[subclass=JSInt|powerset={I}{O}{N}]*/
fieldInvoke1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset={N}{O}{N}]*/ functionField!();
}

/*member: fieldInvoke2:[exact=JSString|powerset={I}{O}{I}]*/
fieldInvoke2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset={N}{O}{N}]*/ functionField!();
}

/*member: methodInvoke1:[exact=JSUInt31|powerset={I}{O}{N}]*/
methodInvoke1() {
  C<int> c = C<int>(0);
  return c. /*invoke: [exact=C|powerset={N}{O}{N}]*/ method();
}

/*member: methodInvoke2:[exact=JSString|powerset={I}{O}{I}]*/
methodInvoke2() {
  C<String> c = C<String>('');
  return c. /*invoke: [exact=C|powerset={N}{O}{N}]*/ method();
}

/*member: operatorInvoke1:[exact=JSUInt31|powerset={I}{O}{N}]*/
operatorInvoke1() {
  C<int> c = C<int>(0);
  return c /*invoke: [exact=C|powerset={N}{O}{N}]*/ + 0;
}

/*member: operatorInvoke2:[exact=JSString|powerset={I}{O}{I}]*/
operatorInvoke2() {
  C<String> c = C<String>('');
  return c /*invoke: [exact=C|powerset={N}{O}{N}]*/ + '';
}

/*member: fixedGetterInvoke:[subclass=JSInt|powerset={I}{O}{N}]*/
fixedGetterInvoke() {
  C<int> c = C<int>(0);
  return c.fixedFunctionGetter /*invoke: [exact=C|powerset={N}{O}{N}]*/ ();
}

/*member: getterAccess1:[exact=JSUInt31|powerset={I}{O}{N}]*/
getterAccess1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset={N}{O}{N}]*/ getter;
}

/*member: getterAccess2:[exact=JSString|powerset={I}{O}{I}]*/
getterAccess2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset={N}{O}{N}]*/ getter;
}

/*member: getterInvoke1:[subclass=JSInt|powerset={I}{O}{N}]*/
getterInvoke1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset={N}{O}{N}]*/ functionGetter!();
}

/*member: getterInvoke2:[exact=JSString|powerset={I}{O}{I}]*/
getterInvoke2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset={N}{O}{N}]*/ functionGetter!();
}

/*member: genericFieldInvoke1:[exact=JSString|powerset={I}{O}{I}]*/
genericFieldInvoke1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset={N}{O}{N}]*/ genericFunctionField!('');
}

/*member: genericFieldInvoke2:[subclass=JSInt|powerset={I}{O}{N}]*/
genericFieldInvoke2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset={N}{O}{N}]*/ genericFunctionField!(0);
}

/*member: genericMethodInvoke1:[exact=JSString|powerset={I}{O}{I}]*/
genericMethodInvoke1() {
  C<int> c = C<int>(0);
  return c. /*invoke: [exact=C|powerset={N}{O}{N}]*/ genericMethod('');
}

/*member: genericMethodInvoke2:[exact=JSUInt31|powerset={I}{O}{N}]*/
genericMethodInvoke2() {
  C<String> c = C<String>('');
  return c. /*invoke: [exact=C|powerset={N}{O}{N}]*/ genericMethod(0);
}

/*member: genericGetterInvoke1:[exact=JSString|powerset={I}{O}{I}]*/
genericGetterInvoke1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset={N}{O}{N}]*/ genericFunctionGetter!('');
}

/*member: genericGetterInvoke2:[subclass=JSInt|powerset={I}{O}{N}]*/
genericGetterInvoke2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset={N}{O}{N}]*/ genericFunctionGetter!(0);
}
