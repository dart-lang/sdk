// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

class Class {
  const Class([a]);
  const Class.named({a});
}

@Class(
  "a"
  "b",
)
/*member: constructorInvocation1:
resolved=ConstructorInvocation(
  Class.new(AdjacentStringLiterals(
      StringLiteral('a')
      StringLiteral('b'))))
evaluate=ConstructorInvocation(
  Class.new(StringLiteral('ab')))*/
void constructorInvocation1() {}

@Class.named(
  a:
      "a"
      "b",
)
/*member: constructorInvocation2:
resolved=ConstructorInvocation(
  Class.named(a: AdjacentStringLiterals(
      StringLiteral('a')
      StringLiteral('b'))))
evaluate=ConstructorInvocation(
  Class.named(a: StringLiteral('ab')))*/
void constructorInvocation2() {}
