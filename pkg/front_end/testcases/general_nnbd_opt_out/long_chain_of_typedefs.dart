// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// Test for potentially slow compilation of long typedef dependency chains.

typedef Foo01<X, Y, Z> = void Function(Null);
typedef Foo02<X, Y, Z> = void Function(Foo01<X, Y, Z>);
typedef Foo03<X, Y, Z> = void Function(Foo02<X, Y, Z>);
typedef Foo04<X, Y, Z> = void Function(Foo03<X, Y, Z>);
typedef Foo05<X, Y, Z> = void Function(Foo04<X, Y, Z>);
typedef Foo06<X, Y, Z> = void Function(Foo05<X, Y, Z>);
typedef Foo07<X, Y, Z> = void Function(Foo06<X, Y, Z>);
typedef Foo08<X, Y, Z> = void Function(Foo07<X, Y, Z>);
typedef Foo09<X, Y, Z> = void Function(Foo08<X, Y, Z>);
typedef Foo10<X, Y, Z> = void Function(Foo09<X, Y, Z>);
typedef Foo11<X, Y, Z> = void Function(Foo10<X, Y, Z>);
typedef Foo12<X, Y, Z> = void Function(Foo11<X, Y, Z>);
typedef Foo13<X, Y, Z> = void Function(Foo12<X, Y, Z>);
typedef Foo14<X, Y, Z> = void Function(Foo13<X, Y, Z>);
typedef Foo15<X, Y, Z> = void Function(Foo14<X, Y, Z>);
typedef Foo16<X, Y, Z> = void Function(Foo15<X, Y, Z>);
typedef Foo17<X, Y, Z> = void Function(Foo16<X, Y, Z>);
typedef Foo18<X, Y, Z> = void Function(Foo17<X, Y, Z>);
typedef Foo19<X, Y, Z> = void Function(Foo18<X, Y, Z>);
typedef Foo20<X, Y, Z> = void Function(Foo19<X, Y, Z>);

main() {}
