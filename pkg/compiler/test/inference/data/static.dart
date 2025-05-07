// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  simpleStaticCall();
  staticCallWithPositionalArguments1();
  staticCallWithPositionalArguments2();
  staticCallWithOptionalArguments1();
  staticCallWithOptionalArguments2();
  staticCallWithOptionalArguments3();
  staticCallWithOptionalArguments4a();
  staticCallWithOptionalArguments4b();
  staticCallWithOptionalArguments5();
  staticCallWithOptionalArguments6();
  staticCallWithNamedArguments1();
  staticCallWithNamedArguments2();
  staticCallWithNamedArguments3a();
  staticCallWithNamedArguments3b();

  invokeStaticFieldUninitialized();
  invokeStaticFieldTearOff();
  invokeStaticTypedFieldTearOff();
  invokeStaticFieldTearOffParameters();

  invokeStaticGetterTearOff();
  invokeStaticTypedGetterTearOff();

  invokeStaticGenericMethod1();
  invokeStaticGenericMethod2();
  invokeStaticGenericGetter1();
  invokeStaticGenericGetter2();
  invokeStaticGenericField1();
  invokeStaticGenericField2();
}

////////////////////////////////////////////////////////////////////////////////
/// Call a static method that has a constant return value.
////////////////////////////////////////////////////////////////////////////////

/*member: simpleStaticCall:[exact=JSUInt31|powerset={I}]*/
simpleStaticCall() => _returnInt();

/*member: _returnInt:[exact=JSUInt31|powerset={I}]*/
_returnInt() => 0;

////////////////////////////////////////////////////////////////////////////////
/// Call a static method that has two positional parameters, the first argument
/// is returned.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithPositionalArguments1:[exact=JSUInt31|powerset={I}]*/
staticCallWithPositionalArguments1() => _returnFirst(0, 0.5);

/*member: _returnFirst:[exact=JSUInt31|powerset={I}]*/
_returnFirst(
  /*[exact=JSUInt31|powerset={I}]*/ a,
  /*[exact=JSNumNotInt|powerset={I}]*/ b,
) => a;

////////////////////////////////////////////////////////////////////////////////
/// Call a static method that has two positional parameters, the second argument
/// is returned.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithPositionalArguments2:[exact=JSNumNotInt|powerset={I}]*/
staticCallWithPositionalArguments2() => _returnSecond(0, 0.5);

/*member: _returnSecond:[exact=JSNumNotInt|powerset={I}]*/
_returnSecond(
  /*[exact=JSUInt31|powerset={I}]*/ a,
  /*[exact=JSNumNotInt|powerset={I}]*/ b,
) => b;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter with no explicit default
/// value. Only one call site with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithOptionalArguments1:[null|powerset={null}]*/
staticCallWithOptionalArguments1() => _returnDefaultNull();

/*member: _returnDefaultNull:[null|powerset={null}]*/
_returnDefaultNull([/*[null|powerset={null}]*/ a]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter with an explicit default
/// value of `null`. Only one call site with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithOptionalArguments2:[null|powerset={null}]*/
staticCallWithOptionalArguments2() => _returnDefaultNullExplicit();

/*member: _returnDefaultNullExplicit:[null|powerset={null}]*/
_returnDefaultNullExplicit([/*[null|powerset={null}]*/ a = null]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter. Only one call site with an
/// explicit argument.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithOptionalArguments3:[exact=JSUInt31|powerset={I}]*/
staticCallWithOptionalArguments3() => _returnDefaultNullCalled(0);

/*member: _returnDefaultNullCalled:[exact=JSUInt31|powerset={I}]*/
_returnDefaultNullCalled([/*[exact=JSUInt31|powerset={I}]*/ a]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter. Two call sites, one
/// with an explicit argument and one with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithOptionalArguments4a:[null|exact=JSUInt31|powerset={null}{I}]*/
staticCallWithOptionalArguments4a() => _returnDefaultNullCalledTwice();

/*member: staticCallWithOptionalArguments4b:[null|exact=JSUInt31|powerset={null}{I}]*/
staticCallWithOptionalArguments4b() => _returnDefaultNullCalledTwice(0);

/*member: _returnDefaultNullCalledTwice:[null|exact=JSUInt31|powerset={null}{I}]*/
_returnDefaultNullCalledTwice([
  /*[null|exact=JSUInt31|powerset={null}{I}]*/ a,
]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter with a default value of `0`.
/// Only one call site with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithOptionalArguments5:[exact=JSUInt31|powerset={I}]*/
staticCallWithOptionalArguments5() => _returnDefaultZero();

/*member: _returnDefaultZero:[exact=JSUInt31|powerset={I}]*/
_returnDefaultZero([/*[exact=JSUInt31|powerset={I}]*/ a = 0]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter with a default value of `0`.
/// Only one call site with an argument of a different type.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithOptionalArguments6:[exact=JSNumNotInt|powerset={I}]*/
staticCallWithOptionalArguments6() => _returnDefaultZeroCalled(0.5);

/*member: _returnDefaultZeroCalled:[exact=JSNumNotInt|powerset={I}]*/
_returnDefaultZeroCalled([/*[exact=JSNumNotInt|powerset={I}]*/ a = 0]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has a named parameter with a default value of `0`.
/// Only one call site with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithNamedArguments1:[exact=JSUInt31|powerset={I}]*/
staticCallWithNamedArguments1() => _returnNamedDefaultZero();

/*member: _returnNamedDefaultZero:[exact=JSUInt31|powerset={I}]*/
_returnNamedDefaultZero({/*[exact=JSUInt31|powerset={I}]*/ a = 0}) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has a named parameter with a default value of `0`.
/// Only one call site with an argument of a different type.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithNamedArguments2:[exact=JSNumNotInt|powerset={I}]*/
staticCallWithNamedArguments2() => _returnNamedDefaultZeroCalled(a: 0.5);

/*member: _returnNamedDefaultZeroCalled:[exact=JSNumNotInt|powerset={I}]*/
_returnNamedDefaultZeroCalled({/*[exact=JSNumNotInt|powerset={I}]*/ a = 0}) =>
    a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has a named parameter. Two call sites, one with an
/// explicit argument and one with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithNamedArguments3a:[null|exact=JSNumNotInt|powerset={null}{I}]*/
staticCallWithNamedArguments3a() => _returnNamedNullCalledTwice();

/*member: staticCallWithNamedArguments3b:[null|exact=JSNumNotInt|powerset={null}{I}]*/
staticCallWithNamedArguments3b() => _returnNamedNullCalledTwice(a: 0.5);

/*member: _returnNamedNullCalledTwice:[null|exact=JSNumNotInt|powerset={null}{I}]*/
_returnNamedNullCalledTwice({
  /*[null|exact=JSNumNotInt|powerset={null}{I}]*/ a,
}) => a;

////////////////////////////////////////////////////////////////////////////////
/// Call an uninitialized top level field.
////////////////////////////////////////////////////////////////////////////////

/*member: _field1:[null|powerset={null}]*/
dynamic _field1;

/*member: invokeStaticFieldUninitialized:[empty|powerset=empty]*/
invokeStaticFieldUninitialized() => _field1();

////////////////////////////////////////////////////////////////////////////////
/// Call a top level field initialized to a tear-off of a top level method.
////////////////////////////////////////////////////////////////////////////////

/*member: _method1:[exact=JSUInt31|powerset={I}]*/
_method1() => 42;

/*member: _field2:[subclass=Closure|powerset={N}]*/
dynamic _field2 = _method1;

/*member: invokeStaticFieldTearOff:[null|subclass=Object|powerset={null}{IN}]*/
invokeStaticFieldTearOff() => _field2();

////////////////////////////////////////////////////////////////////////////////
/// Call a top level field initialized to a tear-off of a top level method.
////////////////////////////////////////////////////////////////////////////////

/*member: _method5:Value([exact=JSString|powerset={I}], value: "", powerset: {I})*/
String _method5() => '';

/*member: _field5:[subclass=Closure|powerset={N}]*/
String Function() _field5 = _method5;

/*member: invokeStaticTypedFieldTearOff:[exact=JSString|powerset={I}]*/
invokeStaticTypedFieldTearOff() => _field5();

////////////////////////////////////////////////////////////////////////////////
/// Call a top level field initialized to a tear-off of a top level method
/// taking one argument.
////////////////////////////////////////////////////////////////////////////////

/*member: _method2:[exact=JSUInt31|powerset={I}]*/
_method2(/*[exact=JSUInt31|powerset={I}]*/ o) => 42;

/*member: _field3:[subclass=Closure|powerset={N}]*/
dynamic _field3 = _method2;

/*member: invokeStaticFieldTearOffParameters:[null|subclass=Object|powerset={null}{IN}]*/
invokeStaticFieldTearOffParameters() => _field3(42);

////////////////////////////////////////////////////////////////////////////////
/// Call a top level getter returning a tear-off of a top level method.
////////////////////////////////////////////////////////////////////////////////

/*member: _method3:[exact=JSUInt31|powerset={I}]*/
_method3() => 42;

/*member: _getter1:[subclass=Closure|powerset={N}]*/
get _getter1 => _method3;

/*member: invokeStaticGetterTearOff:[null|subclass=Object|powerset={null}{IN}]*/
invokeStaticGetterTearOff() => _getter1();

////////////////////////////////////////////////////////////////////////////////
/// Call a typed top level getter returning a tear-off of a top level method.
////////////////////////////////////////////////////////////////////////////////

/*member: _method6:[exact=JSUInt31|powerset={I}]*/
int _method6() => 0;

/*member: _field7:[subclass=Closure|powerset={N}]*/
int Function() _field7 = _method6;

/*member: _getter3:[subclass=Closure|powerset={N}]*/
int Function() get _getter3 => _field7;

/*member: invokeStaticTypedGetterTearOff:[subclass=JSInt|powerset={I}]*/
invokeStaticTypedGetterTearOff() => _getter3();

////////////////////////////////////////////////////////////////////////////////
/// Calls to a generic static method whose return type depend upon the type
/// arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: _method4:Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
T _method4<T>(
  T /*Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  t,
) => t;

/*member: invokeStaticGenericMethod1:[exact=JSUInt31|powerset={I}]*/
invokeStaticGenericMethod1() => _method4(0);

/*member: invokeStaticGenericMethod2:[exact=JSString|powerset={I}]*/
invokeStaticGenericMethod2() => _method4('');

////////////////////////////////////////////////////////////////////////////////
/// Calls to a generic static method whose return type depend upon the type
/// arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: _getter2:[subclass=Closure|powerset={N}]*/
T Function<T>(T) get _getter2 => _method4;

/*member: invokeStaticGenericGetter1:[subclass=JSInt|powerset={I}]*/
invokeStaticGenericGetter1() => _getter2(0);

/*member: invokeStaticGenericGetter2:[exact=JSString|powerset={I}]*/
invokeStaticGenericGetter2() => _getter2('');

////////////////////////////////////////////////////////////////////////////////
/// Calls to a generic static method whose return type depend upon the type
/// arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: _field4:[subclass=Closure|powerset={N}]*/
T Function<T>(T) _field4 = _method4;

/*member: invokeStaticGenericField1:[subclass=JSInt|powerset={I}]*/
invokeStaticGenericField1() => _field4(0);

/*member: invokeStaticGenericField2:[exact=JSString|powerset={I}]*/
invokeStaticGenericField2() => _field4('');
