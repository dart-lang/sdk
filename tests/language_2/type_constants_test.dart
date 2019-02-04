// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the value of constant type literals are allowed as
// constant map keys and case expressions, and the value of non-constant type
// literals are not.

import "dart:collection" deferred as prefix;

main(args) {
  testSwitch(args);
  testMaps(args);
}

const Type numType = num;

Type argumentType<T>() => T;

void testSwitch<T extends MyType>(args) {
  var types = [MyType, T, argumentType<MyType>(), argumentType<T>()];
  for (int i = 0; i < types.length; i++) {
    switch (types[i]) {
      // Must be type literal or not override `==`.
      case const MyType(): //# 01: compile-time error

      // Must not be type variable.
      case T: //# 02: compile-time error

      // Must not be deferred type.
      case prefix.HashSet: //# 03: compile-time error

      // Constant type literals are valid.
      case String:
        throw "unreachable: String #$i";
      case int:
        throw "unreachable: int #$i";
      case numType:
        throw "unreachable: num #$i";
      case MyType:
        break;
      default:
        throw "unreachable: default #$i";
    }
  }
}

void testMaps<T extends MyType>(args) {
  const map = {
    // Must be type literal or not override `==`.
    MyType(): 0, //# 04: compile-time error

    // Must not be type variable.
    T: 0, //# 05: compile-time error

    // Must not be deferred.
    prefix.HashSet: 0, //# 06: compile-time error

    // Constant type literals are valid.
    MyType: 0,
    int: 1,
    String: 2,
    numType: 3,
  };
  if (map[MyType] != 0) throw "Map Error: ${MyType} as literal";
  if (map[T] != 0) throw "Map Error: ${T} as type argument";
  if (map[argumentType<MyType>()] != 0) {
    throw "Map Error: ${argumentType<MyType>()} as type argument of literal";
  }
  if (map[argumentType<T>()] != 0) {
    throw "Map Error: ${argumentType<T>()} as type argument of type variable";
  }
  if (map[num] != 3) throw "Map Error: ${num} -> ${map[num]}";
}

// An implementation of `Type` which overrides `==`,
// but is not the value of a constant type literal.
class MyType implements Type {
  const MyType();
  int get hashCode => 0;
  bool operator ==(Object other) => identical(this, other);
}
