// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' show JS;
import 'dart:_runtime' as dart;

import 'package:expect/expect.dart';

// Returns sWrapped<tWrapped> as a wrapped type.
Type generic1(Type sWrapped, Type tWrapped) {
  var s = dart.unwrapType(sWrapped);
  var t = dart.unwrapType(tWrapped);
  var sGeneric = dart.getGenericClass(s);
  return dart.wrapType(JS('', '#(#)', sGeneric, t));
}

// Returns sWrapped<tWrapped, rWrapped> as a wrapped type.
Type generic2(Type sWrapped, Type tWrapped, Type rWrapped) {
  var s = dart.unwrapType(sWrapped);
  var t = dart.unwrapType(tWrapped);
  var r = dart.unwrapType(rWrapped);
  var sGeneric = dart.getGenericClass(s);
  return dart.wrapType(JS('', '#(#, #)', sGeneric, t, r));
}

// Returns a function type of argWrapped -> returnWrapped as a wrapped type.
Type function1(Type returnWrapped, Type argWrapped) {
  var returnType = dart.unwrapType(returnWrapped);
  var argType = dart.unwrapType(argWrapped);
  var fun = dart.fnType(returnType, [argType]);
  return dart.wrapType(fun);
}

// Returns a function type with a bounded type argument that takes no argument
// and returns void as a wrapped type.
Type genericFunction(Type boundWrapped) => dart.wrapType(dart.gFnType(
    (T) => [dart.VoidType, []], (T) => [dart.unwrapType(boundWrapped)]));

// Returns a function type with a bounded generic return type of
// <T extends boundWrapped> argWrapped -> T as a wrapped type.
Type functionGenericReturn(Type boundWrapped, Type argWrapped) =>
    dart.wrapType(dart.gFnType(
        (T) => [
              T,
              [dart.unwrapType(argWrapped)]
            ],
        (T) => [dart.unwrapType(boundWrapped)]));

// Returns a function with a bounded generic argument type of
// <T extends boundWrapped> T -> returnWrapped as a wrapped type.
Type functionGenericArg(Type boundWrapped, Type returnWrapped) =>
    dart.wrapType(dart.gFnType(
        (T) => [
              dart.unwrapType(returnWrapped),
              [T]
            ],
        (T) => [dart.unwrapType(boundWrapped)]));

void checkSubtype(Type sWrapped, Type tWrapped) {
  var s = dart.unwrapType(sWrapped);
  var t = dart.unwrapType(tWrapped);
  Expect.isTrue(dart.isSubtypeOf(s, t), '$s should be subtype of $t.');
}

void checkProperSubtype(Type sWrapped, Type tWrapped) {
  var s = dart.unwrapType(sWrapped);
  var t = dart.unwrapType(tWrapped);
  Expect.isTrue(dart.isSubtypeOf(s, t), '$s should be subtype of $t.');
  checkSubtypeFailure(tWrapped, sWrapped);
}

void checkSubtypeFailure(Type sWrapped, Type tWrapped) {
  var s = dart.unwrapType(sWrapped);
  var t = dart.unwrapType(tWrapped);
  Expect.isFalse(dart.isSubtypeOf(s, t), '$s should not be subtype of $t.');
}
