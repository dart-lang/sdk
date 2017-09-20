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
}

/// Call a static method that has a constant return value.

/*element: simpleStaticCall:[exact=JSUInt31]*/
simpleStaticCall() => _returnInt();

/*element: _returnInt:[exact=JSUInt31]*/
_returnInt() => 0;

/// Call a static method that has two positional parameters, the first argument
/// is returned.

/*element: staticCallWithPositionalArguments1:[exact=JSUInt31]*/
staticCallWithPositionalArguments1() => _returnFirst(0, 0.5);

/*element: _returnFirst:[exact=JSUInt31]*/
_returnFirst(/*[exact=JSUInt31]*/ a, /*[exact=JSDouble]*/ b) => a;

/// Call a static method that has two positional parameters, the second argument
/// is returned.

/*element: staticCallWithPositionalArguments2:[exact=JSDouble]*/
staticCallWithPositionalArguments2() => _returnSecond(0, 0.5);

/*element: _returnSecond:[exact=JSDouble]*/
_returnSecond(/*[exact=JSUInt31]*/ a, /*[exact=JSDouble]*/ b) => b;

/// A static method that has an optional parameter with no explicit default
/// value. Only one call site with no arguments.

/*element: staticCallWithOptionalArguments1:[null]*/
staticCallWithOptionalArguments1() => _returnDefaultNull();

/*element: _returnDefaultNull:[null]*/
_returnDefaultNull([/*[null]*/ a]) => a;

/// A static method that has an optional parameter with an explicit default
/// value of `null`. Only one call site with no arguments.

/*element: staticCallWithOptionalArguments2:[null]*/
staticCallWithOptionalArguments2() => _returnDefaultNullExplicit();

/*element: _returnDefaultNullExplicit:[null]*/
_returnDefaultNullExplicit([/*[null]*/ a = null]) => a;

/// A static method that has an optional parameter. Only one call site with an
/// explicit argument.

/*element: staticCallWithOptionalArguments3:[exact=JSUInt31]*/
staticCallWithOptionalArguments3() => _returnDefaultNullCalled(0);

/*element: _returnDefaultNullCalled:[exact=JSUInt31]*/
_returnDefaultNullCalled([/*[exact=JSUInt31]*/ a]) => a;

/// A static method that has an optional parameter. Two call sites, one
/// with an explicit argument and one with no arguments.

/*element: staticCallWithOptionalArguments4a:[null|exact=JSUInt31]*/
staticCallWithOptionalArguments4a() => _returnDefaultNullCalledTwice();

/*element: staticCallWithOptionalArguments4b:[null|exact=JSUInt31]*/
staticCallWithOptionalArguments4b() => _returnDefaultNullCalledTwice(0);

/*element: _returnDefaultNullCalledTwice:[null|exact=JSUInt31]*/
_returnDefaultNullCalledTwice([/*[null|exact=JSUInt31]*/ a]) => a;

/// A static method that has an optional parameter with a default value of `0`.
/// Only one call site with no arguments.

/*element: staticCallWithOptionalArguments5:[exact=JSUInt31]*/
staticCallWithOptionalArguments5() => _returnDefaultZero();

/*element: _returnDefaultZero:[exact=JSUInt31]*/
_returnDefaultZero([/*[exact=JSUInt31]*/ a = 0]) => a;

/// A static method that has an optional parameter with a default value of `0`.
/// Only one call site with an argument of a different type.

/*element: staticCallWithOptionalArguments6:[exact=JSDouble]*/
staticCallWithOptionalArguments6() => _returnDefaultZeroCalled(0.5);

/*element: _returnDefaultZeroCalled:[exact=JSDouble]*/
_returnDefaultZeroCalled([/*[exact=JSDouble]*/ a = 0]) => a;

/// A static method that has a named parameter with a default value of `0`.
/// Only one call site with no arguments.

/*element: staticCallWithNamedArguments1:[exact=JSUInt31]*/
staticCallWithNamedArguments1() => _returnNamedDefaultZero();

/*element: _returnNamedDefaultZero:[exact=JSUInt31]*/
_returnNamedDefaultZero({/*[exact=JSUInt31]*/ a: 0}) => a;

/// A static method that has a named parameter with a default value of `0`.
/// Only one call site with an argument of a different type.

/*element: staticCallWithNamedArguments2:[exact=JSDouble]*/
staticCallWithNamedArguments2() => _returnNamedDefaultZeroCalled(a: 0.5);

/*element: _returnNamedDefaultZeroCalled:[exact=JSDouble]*/
_returnNamedDefaultZeroCalled({/*[exact=JSDouble]*/ a: 0}) => a;

/// A static method that has a named parameter. Two call sites, one with an
/// explicit argument and one with no arguments.

/*element: staticCallWithNamedArguments3a:[null|exact=JSDouble]*/
staticCallWithNamedArguments3a() => _returnNamedNullCalledTwice();

/*element: staticCallWithNamedArguments3b:[null|exact=JSDouble]*/
staticCallWithNamedArguments3b() => _returnNamedNullCalledTwice(a: 0.5);

/*element: _returnNamedNullCalledTwice:[null|exact=JSDouble]*/
_returnNamedNullCalledTwice({/*[null|exact=JSDouble]*/ a}) => a;
