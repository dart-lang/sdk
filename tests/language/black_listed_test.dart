// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test checking that static/instance field shadowing do not conflict.

import 'package:expect/expect.dart' show Expect;

// Test that certain interfaces/classes are blacklisted from being
// implemented or extended.

class MyBool
    extends bool             //# 01a: compile-time error
    implements bool          //# 01b: compile-time error
    extends Object with bool //# 01c: compile-time error
{
  factory MyBool() => throw "bad";
}

abstract class MyBoolInterface
    extends bool             //# 02a: compile-time error
    implements bool          //# 02b: compile-time error
    extends Object with bool //# 02c: compile-time error
{
  factory MyBoolInterface() => throw "bad";
}

class MyNum
    extends num             //# 03a: compile-time error
    implements num          //# 03b: compile-time error
    extends Object with num //# 03c: compile-time error
{
  factory MyNum() => throw "bad";
}

abstract class MyNumInterface
    extends num             //# 04a: compile-time error
    implements num          //# 04b: compile-time error
    extends Object with num //# 04c: compile-time error
{
  factory MyNumInterface() => throw "bad";
}

class MyInt
    extends int             //# 05a: compile-time error
    implements int          //# 05b: compile-time error
    extends Object with int //# 05c: compile-time error
{
  factory MyInt() => throw "bad";
}

abstract class MyIntInterface
    extends int             //# 06a: compile-time error
    implements int          //# 06b: compile-time error
    extends Object with int //# 06c: compile-time error
{
  factory MyIntInterface() => throw "bad";
}

class MyDouble
    extends double             //# 07a: compile-time error
    implements double          //# 07b: compile-time error
    extends Object with double //# 07c: compile-time error
{
  factory MyDouble() => throw "bad";
}

abstract class MyDoubleInterface
    extends double             //# 08a: compile-time error
    implements double          //# 08b: compile-time error
    extends Object with double //# 08c: compile-time error
{
  factory MyDoubleInterface() => throw "bad";
}

class MyString
    extends String             //# 09a: compile-time error
    implements String          //# 09b: compile-time error
    extends Object with String //# 09c: compile-time error
{
  factory MyString() => throw "bad";
}

abstract class MyStringInterface
    extends String             //# 10a: compile-time error
    implements String          //# 10b: compile-time error
    extends Object with String //# 10c: compile-time error
{
  factory MyStringInterface() => throw "bad";
}

class MyFunction implements Function {
  factory MyFunction() => throw "bad";
}

class MyOtherFunction extends Function {
  factory MyOtherFunction() => throw "bad";
}

abstract class MyFunctionInterface implements Function {
  factory MyFunctionInterface() => throw "bad";
}

class MyDynamic
    extends dynamic             //# 13a: compile-time error
    implements dynamic          //# 13b: compile-time error
    extends Object with dynamic //# 13c: compile-time error
{
  factory MyDynamic() => throw "bad";
}

abstract class MyDynamicInterface
    extends dynamic             //# 14a: compile-time error
    implements dynamic          //# 14b: compile-time error
    extends Object with dynamic //# 14c: compile-time error
{
  factory MyDynamicInterface() => throw "bad";
}

bool isBadString(e) => identical("bad", e);

main() {
  Expect.throws(() => new MyBool(), isBadString);
  Expect.throws(() => new MyBoolInterface(), isBadString);
  Expect.throws(() => new MyNum(), isBadString);
  Expect.throws(() => new MyNumInterface(), isBadString);
  Expect.throws(() => new MyInt(), isBadString);
  Expect.throws(() => new MyIntInterface(), isBadString);
  Expect.throws(() => new MyDouble(), isBadString);
  Expect.throws(() => new MyDoubleInterface(), isBadString);
  Expect.throws(() => new MyString(), isBadString);
  Expect.throws(() => new MyStringInterface(), isBadString);
  Expect.throws(() => new MyFunction(), isBadString);
  Expect.throws(() => new MyOtherFunction(), isBadString);
  Expect.throws(() => new MyFunctionInterface(), isBadString);
  Expect.throws(() => new MyDynamic(), isBadString);
  Expect.throws(() => new MyDynamicInterface(), isBadString);
}
