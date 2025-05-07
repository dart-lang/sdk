// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {
  /*member: C.field:Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  final T field;

  /*member: C.fixedFunctionField:[subclass=Closure|powerset={N}]*/
  int Function() fixedFunctionField = /*[exact=JSUInt31|powerset={I}]*/ () => 0;

  /*member: C.functionField:[null|subclass=Closure|powerset={null}{N}]*/
  T Function()? functionField;

  /*member: C.genericFunctionField:[null|subclass=Closure|powerset={null}{N}]*/
  S Function<S>(S)? genericFunctionField;

  /*member: C.:[exact=C|powerset={N}]*/
  C(
    this. /*Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/ field,
  ) {
    /*update: [subclass=C|powerset={N}]*/
    functionField =
        /*Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
        () => /*[subclass=C|powerset={N}]*/ field;
    /*Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
    S local<S>(
      S /*Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
      s,
    ) => s;
    /*update: [subclass=C|powerset={N}]*/
    genericFunctionField = local;
  }

  /*member: C.method:Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  T method() => /*[subclass=C|powerset={N}]*/ field;

  /*member: C.+:Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  T operator +(
    T /*Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
    t,
  ) =>
      /*[subclass=C|powerset={N}]*/ field;

  /*member: C.getter:Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  T get getter => /*[subclass=C|powerset={N}]*/ field;

  /*member: C.fixedFunctionGetter:[subclass=Closure|powerset={N}]*/
  int Function() get fixedFunctionGetter => /*[exact=JSUInt31|powerset={I}]*/
      () => 0;

  /*member: C.functionGetter:[null|subclass=Closure|powerset={null}{N}]*/
  T Function()? get functionGetter => /*[subclass=C|powerset={N}]*/
      functionField;

  /*member: C.genericFunctionGetter:[null|subclass=Closure|powerset={null}{N}]*/
  S Function<S>(S)? get genericFunctionGetter =>
      /*[subclass=C|powerset={N}]*/ genericFunctionField;

  /*member: C.genericMethod:Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  S genericMethod<S>(
    S /*Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
    s,
  ) => s;
}

class D1 extends C<int> {
  /*member: D1.:[exact=D1|powerset={N}]*/
  D1(int /*[exact=JSUInt31|powerset={I}]*/ field) : super(field);

  /*member: D1.superFieldAccess:[exact=JSUInt31|powerset={I}]*/
  superFieldAccess() => super.field;

  /*member: D1.superFieldInvoke:[subclass=JSInt|powerset={I}]*/
  superFieldInvoke() => super.functionField!();

  /*member: D1.superFixedFieldInvoke:[subclass=JSInt|powerset={I}]*/
  superFixedFieldInvoke() => super.fixedFunctionField();

  /*member: D1.superMethodInvoke:[exact=JSUInt31|powerset={I}]*/
  superMethodInvoke() => super.method();

  /*member: D1.superOperatorInvoke:[exact=JSUInt31|powerset={I}]*/
  superOperatorInvoke() => super + 0;

  /*member: D1.superGetterAccess:[exact=JSUInt31|powerset={I}]*/
  superGetterAccess() => super.getter;

  /*member: D1.superGetterInvoke:[subclass=JSInt|powerset={I}]*/
  superGetterInvoke() => super.functionGetter!();

  /*member: D1.superFixedGetterInvoke:[subclass=JSInt|powerset={I}]*/
  superFixedGetterInvoke() => super.fixedFunctionGetter();

  /*member: D1.superGenericFieldInvoke1:[exact=JSString|powerset={I}]*/
  superGenericFieldInvoke1() => super.genericFunctionField!('');

  /*member: D1.superGenericFieldInvoke2:[subclass=JSInt|powerset={I}]*/
  superGenericFieldInvoke2() => super.genericFunctionField!(0);

  /*member: D1.superGenericMethodInvoke1:[exact=JSString|powerset={I}]*/
  superGenericMethodInvoke1() => super.genericMethod('');

  /*member: D1.superGenericMethodInvoke2:[exact=JSUInt31|powerset={I}]*/
  superGenericMethodInvoke2() => super.genericMethod(0);

  /*member: D1.superGenericGetterInvoke1:[exact=JSString|powerset={I}]*/
  superGenericGetterInvoke1() => super.genericFunctionGetter!('');

  /*member: D1.superGenericGetterInvoke2:[subclass=JSInt|powerset={I}]*/
  superGenericGetterInvoke2() => super.genericFunctionGetter!(0);
}

class D2 extends C<String> {
  /*member: D2.:[exact=D2|powerset={N}]*/
  D2(
    String /*Value([exact=JSString|powerset={I}], value: "", powerset: {I})*/
    field,
  ) : super(field);

  /*member: D2.superFieldAccess:[exact=JSString|powerset={I}]*/
  superFieldAccess() => super.field;

  /*member: D2.superFieldInvoke:[exact=JSString|powerset={I}]*/
  superFieldInvoke() => super.functionField!();

  /*member: D2.superFixedFieldInvoke:[subclass=JSInt|powerset={I}]*/
  superFixedFieldInvoke() => super.fixedFunctionField();

  /*member: D2.superMethodInvoke:[exact=JSString|powerset={I}]*/
  superMethodInvoke() => super.method();

  /*member: D2.superOperatorInvoke:[exact=JSString|powerset={I}]*/
  superOperatorInvoke() => super + '';

  /*member: D2.superGetterAccess:[exact=JSString|powerset={I}]*/
  superGetterAccess() => super.getter;

  /*member: D2.superGetterInvoke:[exact=JSString|powerset={I}]*/
  superGetterInvoke() => super.functionGetter!();

  /*member: D2.superFixedGetterInvoke:[subclass=JSInt|powerset={I}]*/
  superFixedGetterInvoke() => super.fixedFunctionGetter();

  /*member: D2.superGenericFieldInvoke1:[exact=JSString|powerset={I}]*/
  superGenericFieldInvoke1() => super.genericFunctionField!('');

  /*member: D2.superGenericFieldInvoke2:[subclass=JSInt|powerset={I}]*/
  superGenericFieldInvoke2() => super.genericFunctionField!(0);

  /*member: D2.superGenericMethodInvoke1:[exact=JSString|powerset={I}]*/
  superGenericMethodInvoke1() => super.genericMethod('');

  /*member: D2.superGenericMethodInvoke2:[exact=JSUInt31|powerset={I}]*/
  superGenericMethodInvoke2() => super.genericMethod(0);

  /*member: D2.superGenericGetterInvoke1:[exact=JSString|powerset={I}]*/
  superGenericGetterInvoke1() => super.genericFunctionGetter!('');

  /*member: D2.superGenericGetterInvoke2:[subclass=JSInt|powerset={I}]*/
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
    .. /*invoke: [exact=D1|powerset={N}]*/ superFieldAccess()
    .. /*invoke: [exact=D1|powerset={N}]*/ superFieldInvoke()
    .. /*invoke: [exact=D1|powerset={N}]*/ superFixedFieldInvoke()
    .. /*invoke: [exact=D1|powerset={N}]*/ superMethodInvoke()
    .. /*invoke: [exact=D1|powerset={N}]*/ superOperatorInvoke()
    .. /*invoke: [exact=D1|powerset={N}]*/ superGetterAccess()
    .. /*invoke: [exact=D1|powerset={N}]*/ superGetterInvoke()
    .. /*invoke: [exact=D1|powerset={N}]*/ superFixedGetterInvoke()
    .. /*invoke: [exact=D1|powerset={N}]*/ superGenericFieldInvoke1()
    .. /*invoke: [exact=D1|powerset={N}]*/ superGenericFieldInvoke2()
    .. /*invoke: [exact=D1|powerset={N}]*/ superGenericMethodInvoke1()
    .. /*invoke: [exact=D1|powerset={N}]*/ superGenericMethodInvoke2()
    .. /*invoke: [exact=D1|powerset={N}]*/ superGenericGetterInvoke1()
    .. /*invoke: [exact=D1|powerset={N}]*/ superGenericGetterInvoke2();
  D2('')
    .. /*invoke: [exact=D2|powerset={N}]*/ superFieldAccess()
    .. /*invoke: [exact=D2|powerset={N}]*/ superFieldInvoke()
    .. /*invoke: [exact=D2|powerset={N}]*/ superFixedFieldInvoke()
    .. /*invoke: [exact=D2|powerset={N}]*/ superMethodInvoke()
    .. /*invoke: [exact=D2|powerset={N}]*/ superOperatorInvoke()
    .. /*invoke: [exact=D2|powerset={N}]*/ superGetterAccess()
    .. /*invoke: [exact=D2|powerset={N}]*/ superGetterInvoke()
    .. /*invoke: [exact=D2|powerset={N}]*/ superFixedGetterInvoke()
    .. /*invoke: [exact=D2|powerset={N}]*/ superGenericFieldInvoke1()
    .. /*invoke: [exact=D2|powerset={N}]*/ superGenericFieldInvoke2()
    .. /*invoke: [exact=D2|powerset={N}]*/ superGenericMethodInvoke1()
    .. /*invoke: [exact=D2|powerset={N}]*/ superGenericMethodInvoke2()
    .. /*invoke: [exact=D2|powerset={N}]*/ superGenericGetterInvoke1()
    .. /*invoke: [exact=D2|powerset={N}]*/ superGenericGetterInvoke2();
}

/*member: closureInvoke:[subclass=JSInt|powerset={I}]*/
closureInvoke() {
  int Function() f = /*[exact=JSUInt31|powerset={I}]*/ () => 0;
  return f();
}

/*member: localFunctionInvoke:[exact=JSUInt31|powerset={I}]*/
localFunctionInvoke() {
  /*[exact=JSUInt31|powerset={I}]*/
  int local() => 0;
  return local();
}

/*member: genericLocalFunctionInvoke:[null|powerset={null}]*/
genericLocalFunctionInvoke() {
  /*Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  S local<S>(
    S /*Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
    s,
  ) => s;

  local(0). /*invoke: [exact=JSUInt31|powerset={I}]*/ toString();
  local(''). /*invoke: [exact=JSString|powerset={I}]*/ toString();
}

/*member: fieldAccess1:[exact=JSUInt31|powerset={I}]*/
fieldAccess1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset={N}]*/ field;
}

/*member: fieldAccess2:[exact=JSString|powerset={I}]*/
fieldAccess2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset={N}]*/ field;
}

/*member: fixedFieldInvoke:[subclass=JSInt|powerset={I}]*/
fixedFieldInvoke() {
  C<int> c = C<int>(0);
  return c.fixedFunctionField /*invoke: [exact=C|powerset={N}]*/ ();
}

/*member: fieldInvoke1:[subclass=JSInt|powerset={I}]*/
fieldInvoke1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset={N}]*/ functionField!();
}

/*member: fieldInvoke2:[exact=JSString|powerset={I}]*/
fieldInvoke2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset={N}]*/ functionField!();
}

/*member: methodInvoke1:[exact=JSUInt31|powerset={I}]*/
methodInvoke1() {
  C<int> c = C<int>(0);
  return c. /*invoke: [exact=C|powerset={N}]*/ method();
}

/*member: methodInvoke2:[exact=JSString|powerset={I}]*/
methodInvoke2() {
  C<String> c = C<String>('');
  return c. /*invoke: [exact=C|powerset={N}]*/ method();
}

/*member: operatorInvoke1:[exact=JSUInt31|powerset={I}]*/
operatorInvoke1() {
  C<int> c = C<int>(0);
  return c /*invoke: [exact=C|powerset={N}]*/ + 0;
}

/*member: operatorInvoke2:[exact=JSString|powerset={I}]*/
operatorInvoke2() {
  C<String> c = C<String>('');
  return c /*invoke: [exact=C|powerset={N}]*/ + '';
}

/*member: fixedGetterInvoke:[subclass=JSInt|powerset={I}]*/
fixedGetterInvoke() {
  C<int> c = C<int>(0);
  return c.fixedFunctionGetter /*invoke: [exact=C|powerset={N}]*/ ();
}

/*member: getterAccess1:[exact=JSUInt31|powerset={I}]*/
getterAccess1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset={N}]*/ getter;
}

/*member: getterAccess2:[exact=JSString|powerset={I}]*/
getterAccess2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset={N}]*/ getter;
}

/*member: getterInvoke1:[subclass=JSInt|powerset={I}]*/
getterInvoke1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset={N}]*/ functionGetter!();
}

/*member: getterInvoke2:[exact=JSString|powerset={I}]*/
getterInvoke2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset={N}]*/ functionGetter!();
}

/*member: genericFieldInvoke1:[exact=JSString|powerset={I}]*/
genericFieldInvoke1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset={N}]*/ genericFunctionField!('');
}

/*member: genericFieldInvoke2:[subclass=JSInt|powerset={I}]*/
genericFieldInvoke2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset={N}]*/ genericFunctionField!(0);
}

/*member: genericMethodInvoke1:[exact=JSString|powerset={I}]*/
genericMethodInvoke1() {
  C<int> c = C<int>(0);
  return c. /*invoke: [exact=C|powerset={N}]*/ genericMethod('');
}

/*member: genericMethodInvoke2:[exact=JSUInt31|powerset={I}]*/
genericMethodInvoke2() {
  C<String> c = C<String>('');
  return c. /*invoke: [exact=C|powerset={N}]*/ genericMethod(0);
}

/*member: genericGetterInvoke1:[exact=JSString|powerset={I}]*/
genericGetterInvoke1() {
  C<int> c = C<int>(0);
  return c. /*[exact=C|powerset={N}]*/ genericFunctionGetter!('');
}

/*member: genericGetterInvoke2:[subclass=JSInt|powerset={I}]*/
genericGetterInvoke2() {
  C<String> c = C<String>('');
  return c. /*[exact=C|powerset={N}]*/ genericFunctionGetter!(0);
}
