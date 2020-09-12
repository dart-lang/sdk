// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
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

/*member: simpleStaticCall:[exact=JSUInt31]*/
simpleStaticCall() => _returnInt();

/*member: _returnInt:[exact=JSUInt31]*/
_returnInt() => 0;

////////////////////////////////////////////////////////////////////////////////
/// Call a static method that has two positional parameters, the first argument
/// is returned.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithPositionalArguments1:[exact=JSUInt31]*/
staticCallWithPositionalArguments1() => _returnFirst(0, 0.5);

/*member: _returnFirst:[exact=JSUInt31]*/
_returnFirst(/*[exact=JSUInt31]*/ a, /*[exact=JSDouble]*/ b) => a;

////////////////////////////////////////////////////////////////////////////////
/// Call a static method that has two positional parameters, the second argument
/// is returned.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithPositionalArguments2:[exact=JSDouble]*/
staticCallWithPositionalArguments2() => _returnSecond(0, 0.5);

/*member: _returnSecond:[exact=JSDouble]*/
_returnSecond(/*[exact=JSUInt31]*/ a, /*[exact=JSDouble]*/ b) => b;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter with no explicit default
/// value. Only one call site with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithOptionalArguments1:[null]*/
staticCallWithOptionalArguments1() => _returnDefaultNull();

/*member: _returnDefaultNull:[null]*/
_returnDefaultNull([/*[null]*/ a]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter with an explicit default
/// value of `null`. Only one call site with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithOptionalArguments2:[null]*/
staticCallWithOptionalArguments2() => _returnDefaultNullExplicit();

/*member: _returnDefaultNullExplicit:[null]*/
_returnDefaultNullExplicit([/*[null]*/ a = null]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter. Only one call site with an
/// explicit argument.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithOptionalArguments3:[exact=JSUInt31]*/
staticCallWithOptionalArguments3() => _returnDefaultNullCalled(0);

/*member: _returnDefaultNullCalled:[exact=JSUInt31]*/
_returnDefaultNullCalled([/*[exact=JSUInt31]*/ a]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter. Two call sites, one
/// with an explicit argument and one with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithOptionalArguments4a:[null|exact=JSUInt31]*/
staticCallWithOptionalArguments4a() => _returnDefaultNullCalledTwice();

/*member: staticCallWithOptionalArguments4b:[null|exact=JSUInt31]*/
staticCallWithOptionalArguments4b() => _returnDefaultNullCalledTwice(0);

/*member: _returnDefaultNullCalledTwice:[null|exact=JSUInt31]*/
_returnDefaultNullCalledTwice([/*[null|exact=JSUInt31]*/ a]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter with a default value of `0`.
/// Only one call site with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithOptionalArguments5:[exact=JSUInt31]*/
staticCallWithOptionalArguments5() => _returnDefaultZero();

/*member: _returnDefaultZero:[exact=JSUInt31]*/
_returnDefaultZero([/*[exact=JSUInt31]*/ a = 0]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter with a default value of `0`.
/// Only one call site with an argument of a different type.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithOptionalArguments6:[exact=JSDouble]*/
staticCallWithOptionalArguments6() => _returnDefaultZeroCalled(0.5);

/*member: _returnDefaultZeroCalled:[exact=JSDouble]*/
_returnDefaultZeroCalled([/*[exact=JSDouble]*/ a = 0]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has a named parameter with a default value of `0`.
/// Only one call site with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithNamedArguments1:[exact=JSUInt31]*/
staticCallWithNamedArguments1() => _returnNamedDefaultZero();

/*member: _returnNamedDefaultZero:[exact=JSUInt31]*/
_returnNamedDefaultZero({/*[exact=JSUInt31]*/ a: 0}) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has a named parameter with a default value of `0`.
/// Only one call site with an argument of a different type.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithNamedArguments2:[exact=JSDouble]*/
staticCallWithNamedArguments2() => _returnNamedDefaultZeroCalled(a: 0.5);

/*member: _returnNamedDefaultZeroCalled:[exact=JSDouble]*/
_returnNamedDefaultZeroCalled({/*[exact=JSDouble]*/ a: 0}) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has a named parameter. Two call sites, one with an
/// explicit argument and one with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: staticCallWithNamedArguments3a:[null|exact=JSDouble]*/
staticCallWithNamedArguments3a() => _returnNamedNullCalledTwice();

/*member: staticCallWithNamedArguments3b:[null|exact=JSDouble]*/
staticCallWithNamedArguments3b() => _returnNamedNullCalledTwice(a: 0.5);

/*member: _returnNamedNullCalledTwice:[null|exact=JSDouble]*/
_returnNamedNullCalledTwice({/*[null|exact=JSDouble]*/ a}) => a;

////////////////////////////////////////////////////////////////////////////////
/// Call an uninitialized top level field.
////////////////////////////////////////////////////////////////////////////////

/*member: _field1:[null]*/
dynamic _field1;

/*member: invokeStaticFieldUninitialized:[empty]*/
invokeStaticFieldUninitialized() => _field1();

////////////////////////////////////////////////////////////////////////////////
/// Call a top level field initialized to a tear-off of a top level method.
////////////////////////////////////////////////////////////////////////////////

/*member: _method1:[exact=JSUInt31]*/
_method1() => 42;

/*member: _field2:[subclass=Closure]*/
dynamic _field2 = _method1;

/*member: invokeStaticFieldTearOff:[null|subclass=Object]*/
invokeStaticFieldTearOff() => _field2();

////////////////////////////////////////////////////////////////////////////////
/// Call a top level field initialized to a tear-off of a top level method.
////////////////////////////////////////////////////////////////////////////////

/*member: _method5:Value([exact=JSString], value: "")*/
String _method5() => '';

/*member: _field5:[subclass=Closure]*/
String Function() _field5 = _method5;

/*member: invokeStaticTypedFieldTearOff:[null|exact=JSString]*/
invokeStaticTypedFieldTearOff() => _field5();

////////////////////////////////////////////////////////////////////////////////
/// Call a top level field initialized to a tear-off of a top level method
/// taking one argument.
////////////////////////////////////////////////////////////////////////////////

/*member: _method2:[exact=JSUInt31]*/
_method2(/*[exact=JSUInt31]*/ o) => 42;

/*member: _field3:[subclass=Closure]*/
dynamic _field3 = _method2;

/*member: invokeStaticFieldTearOffParameters:[null|subclass=Object]*/
invokeStaticFieldTearOffParameters() => _field3(42);

////////////////////////////////////////////////////////////////////////////////
/// Call a top level getter returning a tear-off of a top level method.
////////////////////////////////////////////////////////////////////////////////

/*member: _method3:[exact=JSUInt31]*/
_method3() => 42;

/*member: _getter1:[subclass=Closure]*/
get _getter1 => _method3;

/*member: invokeStaticGetterTearOff:[null|subclass=Object]*/
invokeStaticGetterTearOff() => _getter1();

////////////////////////////////////////////////////////////////////////////////
/// Call a typed top level getter returning a tear-off of a top level method.
////////////////////////////////////////////////////////////////////////////////

/*member: _method6:[exact=JSUInt31]*/
int _method6() => 0;

/*member: _field7:[subclass=Closure]*/
int Function() _field7 = _method6;

/*member: _getter3:[subclass=Closure]*/
int Function() get _getter3 => _field7;

/*member: invokeStaticTypedGetterTearOff:[null|subclass=JSInt]*/
invokeStaticTypedGetterTearOff() => _getter3();

////////////////////////////////////////////////////////////////////////////////
/// Calls to a generic static method whose return type depend upon the type
/// arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: _method4:Union([exact=JSString], [exact=JSUInt31])*/
T _method4<T>(T /*Union([exact=JSString], [exact=JSUInt31])*/ t) => t;

/*member: invokeStaticGenericMethod1:[exact=JSUInt31]*/
invokeStaticGenericMethod1() => _method4(0);

/*member: invokeStaticGenericMethod2:[exact=JSString]*/
invokeStaticGenericMethod2() => _method4('');

////////////////////////////////////////////////////////////////////////////////
/// Calls to a generic static method whose return type depend upon the type
/// arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: _getter2:[subclass=Closure]*/
T Function<T>(T) get _getter2 => _method4;

/*member: invokeStaticGenericGetter1:[null|subclass=JSInt]*/
invokeStaticGenericGetter1() => _getter2(0);

/*member: invokeStaticGenericGetter2:[null|exact=JSString]*/
invokeStaticGenericGetter2() => _getter2('');

////////////////////////////////////////////////////////////////////////////////
/// Calls to a generic static method whose return type depend upon the type
/// arguments.
////////////////////////////////////////////////////////////////////////////////

/*member: _field4:[subclass=Closure]*/
T Function<T>(T) _field4 = _method4;

/*member: invokeStaticGenericField1:[null|subclass=JSInt]*/
invokeStaticGenericField1() => _field4(0);

/*member: invokeStaticGenericField2:[null|exact=JSString]*/
invokeStaticGenericField2() => _field4('');
