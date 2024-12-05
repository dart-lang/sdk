// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void checkStatic(
  String expected, {
  String arguments = 'a',
  String constructor = 'c',
  String hasOwnProperty = 'h',
  String isPrototypeOf = 'i',
  String propertyIsEnumerable = 'p',
  String toLocaleString = 'L',
  String toString = 'S',
  String valueOf = 'v',
}) {
  Expect.equals(
      expected,
      '$arguments,'
      '$constructor,'
      '$hasOwnProperty,'
      '$isPrototypeOf,'
      '$propertyIsEnumerable,'
      '$toLocaleString,'
      '$toString,'
      '$valueOf');
}

class CheckMethod {
  void method(
    String expected, {
    String arguments = 'a',
    String constructor = 'c',
    String hasOwnProperty = 'h',
    String isPrototypeOf = 'i',
    String propertyIsEnumerable = 'p',
    String toLocaleString = 'L',
    String toString = 'S',
    String valueOf = 'v',
  }) {
    Expect.equals(
        expected,
        '$arguments,'
        '$constructor,'
        '$hasOwnProperty,'
        '$isPrototypeOf,'
        '$propertyIsEnumerable,'
        '$toLocaleString,'
        '$toString,'
        '$valueOf');
  }

  static void check(CheckMethod object) {
    object.method('a,c,h,i,p,L,S,v');
    object.method('X,c,h,i,p,L,S,v', arguments: 'X');
    object.method('a,X,h,i,p,L,S,v', constructor: 'X');
    object.method('a,c,X,i,p,L,S,v', hasOwnProperty: 'X');
    object.method('a,c,h,X,p,L,S,v', isPrototypeOf: 'X');
    object.method('a,c,h,i,X,L,S,v', propertyIsEnumerable: 'X');
    object.method('a,c,h,i,p,X,S,v', toLocaleString: 'X');
    object.method('a,c,h,i,p,L,X,v', toString: 'X');
    object.method('a,c,h,i,p,L,S,X', valueOf: 'X');

    object.method('a,c,h,i,p,L,Y,X', valueOf: 'X', toString: 'Y');
  }
}

class CheckMethod2 extends CheckMethod {
  void method(
    String expected, {
    String? arguments,
    String? constructor,
    String? hasOwnProperty,
    String? isPrototypeOf,
    String? propertyIsEnumerable,
    String? toLocaleString,
    String? toString,
    String? valueOf,
  }) {
    arguments ??= 'a';
    constructor ??= 'c';
    hasOwnProperty ??= 'h';
    isPrototypeOf ??= 'i';
    propertyIsEnumerable ??= 'p';
    toLocaleString ??= 'L';
    toString ??= 'S';
    valueOf ??= 'v';
    Expect.equals(
        expected,
        '$arguments,'
        '$constructor,'
        '$hasOwnProperty,'
        '$isPrototypeOf,'
        '$propertyIsEnumerable,'
        '$toLocaleString,'
        '$toString,'
        '$valueOf');
  }
}

main() {
  checkStatic('a,c,h,i,p,L,S,v');
  checkStatic('X,c,h,i,p,L,S,v', arguments: 'X');
  checkStatic('a,X,h,i,p,L,S,v', constructor: 'X');
  checkStatic('a,c,X,i,p,L,S,v', hasOwnProperty: 'X');
  checkStatic('a,c,h,X,p,L,S,v', isPrototypeOf: 'X');
  checkStatic('a,c,h,i,X,L,S,v', propertyIsEnumerable: 'X');
  checkStatic('a,c,h,i,p,X,S,v', toLocaleString: 'X');
  checkStatic('a,c,h,i,p,L,X,v', toString: 'X');
  checkStatic('a,c,h,i,p,L,S,X', valueOf: 'X');

  checkStatic('a,c,h,i,p,L,Y,X', valueOf: 'X', toString: 'Y');

  CheckMethod.check(CheckMethod());
  CheckMethod.check(CheckMethod2());
  // TODO(https://dartbug.com/56314): Remove following line when fixed.
  // Explanation at:
  // https://dart-review.googlesource.com/c/sdk/+/377360/2/tests/language/argument/strangely_named_arguments_test.dart#117
  CheckMethod2().method('a,c,h,i,p,L,S,v');
}
