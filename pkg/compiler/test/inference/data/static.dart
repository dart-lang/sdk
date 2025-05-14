// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
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

/*member: simpleStaticCall:[exact=JSUInt31|powerset=0]*/
simpleStaticCall() => _returnInt();

/*member: _returnInt:[exact=JSUInt31|powerset=0]*/
_returnInt() => 0;

////////////////////////////////////////////////////////////////////////////////
/// Call a static method that has two positional parameters, the first argument
/// is returned.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithPositionalArguments1:[exact=JSUInt31|powerset=0]*/
staticCallWithPositionalArguments1() => _returnFirst(0, 0.5);

/*member: _returnFirst:[exact=JSUInt31|powerset=0]*/
_returnFirst(
  /*[exact=JSUInt31|powerset=0]*/ a,
  /*[exact=JSNumNotInt|powerset=0]*/ b,
) => a;

////////////////////////////////////////////////////////////////////////////////
/// Call a static method that has two positional parameters, the second argument
/// is returned.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithPositionalArguments2:[exact=JSNumNotInt|powerset=0]*/
staticCallWithPositionalArguments2() => _returnSecond(0, 0.5);

/*member: _returnSecond:[exact=JSNumNotInt|powerset=0]*/
_returnSecond(
  /*[exact=JSUInt31|powerset=0]*/ a,
  /*[exact=JSNumNotInt|powerset=0]*/ b,
) => b;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter with no explicit default
/// value. Only one call site with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithOptionalArguments1:[null|powerset=1]*/
staticCallWithOptionalArguments1() => _returnDefaultNull();

/*member: _returnDefaultNull:[null|powerset=1]*/
_returnDefaultNull([/*[null|powerset=1]*/ a]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter with an explicit default
/// value of `null`. Only one call site with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithOptionalArguments2:[null|powerset=1]*/
staticCallWithOptionalArguments2() => _returnDefaultNullExplicit();

/*member: _returnDefaultNullExplicit:[null|powerset=1]*/
_returnDefaultNullExplicit([/*[null|powerset=1]*/ a = null]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter. Only one call site with an
/// explicit argument.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithOptionalArguments3:[exact=JSUInt31|powerset=0]*/
staticCallWithOptionalArguments3() => _returnDefaultNullCalled(0);

/*member: _returnDefaultNullCalled:[exact=JSUInt31|powerset=0]*/
_returnDefaultNullCalled([/*[exact=JSUInt31|powerset=0]*/ a]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter. Two call sites, one
/// with an explicit argument and one with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithOptionalArguments4a:[null|exact=JSUInt31|powerset=1]*/
staticCallWithOptionalArguments4a() => _returnDefaultNullCalledTwice();

/*member: staticCallWithOptionalArguments4b:[null|exact=JSUInt31|powerset=1]*/
staticCallWithOptionalArguments4b() => _returnDefaultNullCalledTwice(0);

/*member: _returnDefaultNullCalledTwice:[null|exact=JSUInt31|powerset=1]*/
_returnDefaultNullCalledTwice([/*[null|exact=JSUInt31|powerset=1]*/ a]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter with a default value of `0`.
/// Only one call site with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithOptionalArguments5:[exact=JSUInt31|powerset=0]*/
staticCallWithOptionalArguments5() => _returnDefaultZero();

/*member: _returnDefaultZero:[exact=JSUInt31|powerset=0]*/
_returnDefaultZero([/*[exact=JSUInt31|powerset=0]*/ a = 0]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter with a default value of `0`.
/// Only one call site with an argument of a different type.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithOptionalArguments6:[exact=JSNumNotInt|powerset=0]*/
staticCallWithOptionalArguments6() => _returnDefaultZeroCalled(0.5);

/*member: _returnDefaultZeroCalled:[exact=JSNumNotInt|powerset=0]*/
_returnDefaultZeroCalled([/*[exact=JSNumNotInt|powerset=0]*/ a = 0]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has a named parameter with a default value of `0`.
/// Only one call site with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithNamedArguments1:[exact=JSUInt31|powerset=0]*/
staticCallWithNamedArguments1() => _returnNamedDefaultZero();

/*member: _returnNamedDefaultZero:[exact=JSUInt31|powerset=0]*/
_returnNamedDefaultZero({/*[exact=JSUInt31|powerset=0]*/ a = 0}) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has a named parameter with a default value of `0`.
/// Only one call site with an argument of a different type.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithNamedArguments2:[exact=JSNumNotInt|powerset=0]*/
staticCallWithNamedArguments2() => _returnNamedDefaultZeroCalled(a: 0.5);

/*member: _returnNamedDefaultZeroCalled:[exact=JSNumNotInt|powerset=0]*/
_returnNamedDefaultZeroCalled({/*[exact=JSNumNotInt|powerset=0]*/ a = 0}) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has a named parameter. Two call sites, one with an
/// explicit argument and one with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithNamedArguments3a:[null|exact=JSNumNotInt|powerset=1]*/
staticCallWithNamedArguments3a() => _returnNamedNullCalledTwice();

/*member: staticCallWithNamedArguments3b:[null|exact=JSNumNotInt|powerset=1]*/
staticCallWithNamedArguments3b() => _returnNamedNullCalledTwice(a: 0.5);

/*member: _returnNamedNullCalledTwice:[null|exact=JSNumNotInt|powerset=1]*/
_returnNamedNullCalledTwice({/*[null|exact=JSNumNotInt|powerset=1]*/ a}) => a;

////////////////////////////////////////////////////////////////////////////////
/// Call an uninitialized top level field.
////////////////////////////////////////////////////////////////////////////////

/*member: _field1:[null|powerset=1]*/
dynamic _field1;

/*member: invokeStaticFieldUninitialized:[empty|powerset=0]*/
invokeStaticFieldUninitialized() => _field1();

////////////////////////////////////////////////////////////////////////////////
/// Call a top level field initialized to a tear-off of a top level method.
////////////////////////////////////////////////////////////////////////////////

/*member: _method1:[exact=JSUInt31|powerset=0]*/
_method1() => 42;

/*member: _field2:[subclass=Closure|powerset=0]*/
dynamic _field2 = _method1;

/*member: invokeStaticFieldTearOff:[null|subclass=Object|powerset=1]*/
invokeStaticFieldTearOff() => _field2();

////////////////////////////////////////////////////////////////////////////////
/// Call a top level field initialized to a tear-off of a top level method.
////////////////////////////////////////////////////////////////////////////////

/*member: _method5:Value([exact=JSString|powerset=0], value: "", powerset: 0)*/
String _method5() => '';

/*member: _field5:[subclass=Closure|powerset=0]*/
String Function() _field5 = _method5;

/*member: invokeStaticTypedFieldTearOff:[exact=JSString|powerset=0]*/
invokeStaticTypedFieldTearOff() => _field5();

////////////////////////////////////////////////////////////////////////////////
/// Call a top level field initialized to a tear-off of a top level method
/// taking one argument.
////////////////////////////////////////////////////////////////////////////////

/*member: _method2:[exact=JSUInt31|powerset=0]*/
_method2(/*[exact=JSUInt31|powerset=0]*/ o) => 42;

/*member: _field3:[subclass=Closure|powerset=0]*/
dynamic _field3 = _method2;

/*member: invokeStaticFieldTearOffParameters:[null|subclass=Object|powerset=1]*/
invokeStaticFieldTearOffParameters() => _field3(42);

////////////////////////////////////////////////////////////////////////////////
/// Call a top level getter returning a tear-off of a top level method.
////////////////////////////////////////////////////////////////////////////////

/*member: _method3:[exact=JSUInt31|powerset=0]*/
_method3() => 42;

/*member: _getter1:[subclass=Closure|powerset=0]*/
get _getter1 => _method3;

/*member: invokeStaticGetterTearOff:[null|subclass=Object|powerset=1]*/
invokeStaticGetterTearOff() => _getter1();

////////////////////////////////////////////////////////////////////////////////
/// Call a typed top level getter returning a tear-off of a top level method.
////////////////////////////////////////////////////////////////////////////////

/*member: _method6:[exact=JSUInt31|powerset=0]*/
int _method6() => 0;

/*member: _field7:[subclass=Closure|powerset=0]*/
int Function() _field7 = _method6;

/*member: _getter3:[subclass=Closure|powerset=0]*/
int Function() get _getter3 => _field7;

/*member: invokeStaticTypedGetterTearOff:[subclass=JSInt|powerset=0]*/
invokeStaticTypedGetterTearOff() => _getter3();

////////////////////////////////////////////////////////////////////////////////
/// Calls to a generic static method whose return type depend upon the type
/// arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: _method4:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
T _method4<T>(
  T /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
  t,
) => t;

/*member: invokeStaticGenericMethod1:[exact=JSUInt31|powerset=0]*/
invokeStaticGenericMethod1() => _method4(0);

/*member: invokeStaticGenericMethod2:[exact=JSString|powerset=0]*/
invokeStaticGenericMethod2() => _method4('');

////////////////////////////////////////////////////////////////////////////////
/// Calls to a generic static method whose return type depend upon the type
/// arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: _getter2:[subclass=Closure|powerset=0]*/
T Function<T>(T) get _getter2 => _method4;

/*member: invokeStaticGenericGetter1:[subclass=JSInt|powerset=0]*/
invokeStaticGenericGetter1() => _getter2(0);

/*member: invokeStaticGenericGetter2:[exact=JSString|powerset=0]*/
invokeStaticGenericGetter2() => _getter2('');

////////////////////////////////////////////////////////////////////////////////
/// Calls to a generic static method whose return type depend upon the type
/// arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: _field4:[subclass=Closure|powerset=0]*/
T Function<T>(T) _field4 = _method4;

/*member: invokeStaticGenericField1:[subclass=JSInt|powerset=0]*/
invokeStaticGenericField1() => _field4(0);

/*member: invokeStaticGenericField2:[exact=JSString|powerset=0]*/
invokeStaticGenericField2() => _field4('');
