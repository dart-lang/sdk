// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
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

/*element: simpleStaticCall:[exact=JSUInt31]*/
simpleStaticCall() => _returnInt();

/*element: _returnInt:[exact=JSUInt31]*/
_returnInt() => 0;

////////////////////////////////////////////////////////////////////////////////
/// Call a static method that has two positional parameters, the first argument
/// is returned.
////////////////////////////////////////////////////////////////////////////////

/*element: staticCallWithPositionalArguments1:[exact=JSUInt31]*/
staticCallWithPositionalArguments1() => _returnFirst(0, 0.5);

/*element: _returnFirst:[exact=JSUInt31]*/
_returnFirst(/*[exact=JSUInt31]*/ a, /*[exact=JSDouble]*/ b) => a;

////////////////////////////////////////////////////////////////////////////////
/// Call a static method that has two positional parameters, the second argument
/// is returned.
////////////////////////////////////////////////////////////////////////////////

/*element: staticCallWithPositionalArguments2:[exact=JSDouble]*/
staticCallWithPositionalArguments2() => _returnSecond(0, 0.5);

/*element: _returnSecond:[exact=JSDouble]*/
_returnSecond(/*[exact=JSUInt31]*/ a, /*[exact=JSDouble]*/ b) => b;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter with no explicit default
/// value. Only one call site with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*element: staticCallWithOptionalArguments1:[null]*/
staticCallWithOptionalArguments1() => _returnDefaultNull();

/*element: _returnDefaultNull:[null]*/
_returnDefaultNull([/*[null]*/ a]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter with an explicit default
/// value of `null`. Only one call site with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*element: staticCallWithOptionalArguments2:[null]*/
staticCallWithOptionalArguments2() => _returnDefaultNullExplicit();

/*element: _returnDefaultNullExplicit:[null]*/
_returnDefaultNullExplicit([/*[null]*/ a = null]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter. Only one call site with an
/// explicit argument.
////////////////////////////////////////////////////////////////////////////////

/*element: staticCallWithOptionalArguments3:[exact=JSUInt31]*/
staticCallWithOptionalArguments3() => _returnDefaultNullCalled(0);

/*element: _returnDefaultNullCalled:[exact=JSUInt31]*/
_returnDefaultNullCalled([/*[exact=JSUInt31]*/ a]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter. Two call sites, one
/// with an explicit argument and one with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*element: staticCallWithOptionalArguments4a:[null|exact=JSUInt31]*/
staticCallWithOptionalArguments4a() => _returnDefaultNullCalledTwice();

/*element: staticCallWithOptionalArguments4b:[null|exact=JSUInt31]*/
staticCallWithOptionalArguments4b() => _returnDefaultNullCalledTwice(0);

/*element: _returnDefaultNullCalledTwice:[null|exact=JSUInt31]*/
_returnDefaultNullCalledTwice([/*[null|exact=JSUInt31]*/ a]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter with a default value of `0`.
/// Only one call site with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*element: staticCallWithOptionalArguments5:[exact=JSUInt31]*/
staticCallWithOptionalArguments5() => _returnDefaultZero();

/*element: _returnDefaultZero:[exact=JSUInt31]*/
_returnDefaultZero([/*[exact=JSUInt31]*/ a = 0]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has an optional parameter with a default value of `0`.
/// Only one call site with an argument of a different type.
////////////////////////////////////////////////////////////////////////////////

/*element: staticCallWithOptionalArguments6:[exact=JSDouble]*/
staticCallWithOptionalArguments6() => _returnDefaultZeroCalled(0.5);

/*element: _returnDefaultZeroCalled:[exact=JSDouble]*/
_returnDefaultZeroCalled([/*[exact=JSDouble]*/ a = 0]) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has a named parameter with a default value of `0`.
/// Only one call site with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*element: staticCallWithNamedArguments1:[exact=JSUInt31]*/
staticCallWithNamedArguments1() => _returnNamedDefaultZero();

/*element: _returnNamedDefaultZero:[exact=JSUInt31]*/
_returnNamedDefaultZero({/*[exact=JSUInt31]*/ a: 0}) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has a named parameter with a default value of `0`.
/// Only one call site with an argument of a different type.
////////////////////////////////////////////////////////////////////////////////

/*element: staticCallWithNamedArguments2:[exact=JSDouble]*/
staticCallWithNamedArguments2() => _returnNamedDefaultZeroCalled(a: 0.5);

/*element: _returnNamedDefaultZeroCalled:[exact=JSDouble]*/
_returnNamedDefaultZeroCalled({/*[exact=JSDouble]*/ a: 0}) => a;

////////////////////////////////////////////////////////////////////////////////
/// A static method that has a named parameter. Two call sites, one with an
/// explicit argument and one with no arguments.
////////////////////////////////////////////////////////////////////////////////

/*element: staticCallWithNamedArguments3a:[null|exact=JSDouble]*/
staticCallWithNamedArguments3a() => _returnNamedNullCalledTwice();

/*element: staticCallWithNamedArguments3b:[null|exact=JSDouble]*/
staticCallWithNamedArguments3b() => _returnNamedNullCalledTwice(a: 0.5);

/*element: _returnNamedNullCalledTwice:[null|exact=JSDouble]*/
_returnNamedNullCalledTwice({/*[null|exact=JSDouble]*/ a}) => a;

////////////////////////////////////////////////////////////////////////////////
/// Call an uninitialized top level field.
////////////////////////////////////////////////////////////////////////////////

/*element: _field1:[null]*/
dynamic _field1;

/*element: invokeStaticFieldUninitialized:[null|subclass=Object]*/
invokeStaticFieldUninitialized() => _field1();

////////////////////////////////////////////////////////////////////////////////
/// Call a top level field initialized to a tear-off of a top level method.
////////////////////////////////////////////////////////////////////////////////

/*element: _method1:[exact=JSUInt31]*/
_method1() => 42;

/*element: _field2:[null|subclass=Closure]*/
dynamic _field2 = _method1;

/*element: invokeStaticFieldTearOff:[null|subclass=Object]*/
invokeStaticFieldTearOff() => _field2();

////////////////////////////////////////////////////////////////////////////////
/// Call a top level field initialized to a tear-off of a top level method.
////////////////////////////////////////////////////////////////////////////////

/*element: _method5:Value([exact=JSString], value: "")*/
String _method5() => '';

/*element: _field5:[null|subclass=Closure]*/
String Function() _field5 = _method5;

/*element: invokeStaticTypedFieldTearOff:[null|exact=JSString]*/
invokeStaticTypedFieldTearOff() => _field5();

////////////////////////////////////////////////////////////////////////////////
/// Call a top level field initialized to a tear-off of a top level method
/// taking one argument.
////////////////////////////////////////////////////////////////////////////////

/*element: _method2:[exact=JSUInt31]*/
_method2(/*[exact=JSUInt31]*/ o) => 42;

/*element: _field3:[null|subclass=Closure]*/
dynamic _field3 = _method2;

/*element: invokeStaticFieldTearOffParameters:[null|subclass=Object]*/
invokeStaticFieldTearOffParameters() => _field3(42);

////////////////////////////////////////////////////////////////////////////////
/// Call a top level getter returning a tear-off of a top level method.
////////////////////////////////////////////////////////////////////////////////

/*element: _method3:[exact=JSUInt31]*/
_method3() => 42;

/*element: _getter1:[subclass=Closure]*/
get _getter1 => _method3;

/*element: invokeStaticGetterTearOff:[null|subclass=Object]*/
invokeStaticGetterTearOff() => _getter1();

////////////////////////////////////////////////////////////////////////////////
/// Call a typed top level getter returning a tear-off of a top level method.
////////////////////////////////////////////////////////////////////////////////

/*element: _method6:[exact=JSUInt31]*/
int _method6() => 0;

/*element: _field7:[null|subclass=Closure]*/
int Function() _field7 = _method6;

/*element: _getter3:[null|subclass=Closure]*/
int Function() get _getter3 => _field7;

/*element: invokeStaticTypedGetterTearOff:[null|subclass=JSInt]*/
invokeStaticTypedGetterTearOff() => _getter3();

////////////////////////////////////////////////////////////////////////////////
/// Calls to a generic static method whose return type depend upon the type
/// arguments.
////////////////////////////////////////////////////////////////////////////////

/*element: _method4:Union([exact=JSString], [exact=JSUInt31])*/
T _method4<T>(T /*Union([exact=JSString], [exact=JSUInt31])*/ t) => t;

/*element: invokeStaticGenericMethod1:[exact=JSUInt31]*/
invokeStaticGenericMethod1() => _method4(0);

/*element: invokeStaticGenericMethod2:[exact=JSString]*/
invokeStaticGenericMethod2() => _method4('');

////////////////////////////////////////////////////////////////////////////////
/// Calls to a generic static method whose return type depend upon the type
/// arguments.
////////////////////////////////////////////////////////////////////////////////

/*element: _getter2:[subclass=Closure]*/
T Function<T>(T) get _getter2 => _method4;

/*element: invokeStaticGenericGetter1:[null|subclass=JSInt]*/
invokeStaticGenericGetter1() => _getter2(0);

/*element: invokeStaticGenericGetter2:[null|exact=JSString]*/
invokeStaticGenericGetter2() => _getter2('');

////////////////////////////////////////////////////////////////////////////////
/// Calls to a generic static method whose return type depend upon the type
/// arguments.
////////////////////////////////////////////////////////////////////////////////

/*element: _field4:[null|subclass=Closure]*/
T Function<T>(T) _field4 = _method4;

/*element: invokeStaticGenericField1:[null|subclass=JSInt]*/
invokeStaticGenericField1() => _field4(0);

/*element: invokeStaticGenericField2:[null|exact=JSString]*/
invokeStaticGenericField2() => _field4('');
