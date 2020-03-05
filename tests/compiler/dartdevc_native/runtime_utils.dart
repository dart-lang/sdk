// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' show JS;
import 'dart:_runtime' as dart;

import 'dart:async';
import 'package:expect/expect.dart';

// Function type used to extract the FutureOr now that a raw FutureOr gets
// normalized away.
typedef _futureOrReturn = FutureOr<int> Function();

// The runtime representation of the void type.
final voidType = dart.wrapType(dart.void_);

/// Unwrap the user code type representation to expose the runtime
/// representation of [t].
///
/// Generic functions are unchanged, as they have a separate runtime type object representation.
Object unwrap(Type t) {
  if (t is dart.GenericFunctionType) {
    return t;
  }
  return dart.unwrapType(t);
}

Type futureOrOf(Type tWrapped) {
  var t = unwrap(tWrapped);
  var f = unwrap(_futureOrReturn);
  // Extract a raw FutureOr from an existing use.
  var futureOrGeneric = dart.getGenericClass(JS('', '#.returnType', f));
  return dart.wrapType(JS('', '#(#)', futureOrGeneric, t));
}

// Returns sWrapped<tWrapped> as a wrapped type.
Type generic1(Type sWrapped, Type tWrapped) {
  var s = unwrap(sWrapped);
  var t = unwrap(tWrapped);
  var sGeneric = dart.getGenericClass(s);
  return dart.wrapType(JS('', '#(#)', sGeneric, t));
}

// Returns sWrapped<tWrapped, rWrapped> as a wrapped type.
Type generic2(Type sWrapped, Type tWrapped, Type rWrapped) {
  var s = unwrap(sWrapped);
  var t = unwrap(tWrapped);
  var r = unwrap(rWrapped);
  var sGeneric = dart.getGenericClass(s);
  return dart.wrapType(JS('', '#(#, #)', sGeneric, t, r));
}

// Returns a function type of argWrapped -> returnWrapped as a wrapped type.
Type function1(Type returnWrapped, Type argWrapped) {
  var returnType = unwrap(returnWrapped);
  var argType = unwrap(argWrapped);
  var fun = dart.fnType(returnType, [argType]);
  return dart.wrapType(fun);
}

// Returns a function type with a bounded type argument that takes no argument
// and returns void as a wrapped type.
Type genericFunction(Type boundWrapped) =>
    dart.gFnType((T) => [dart.VoidType, []], (T) => [unwrap(boundWrapped)]);

// Returns a function type with a bounded generic return type of
// <T extends boundWrapped> argWrapped -> T as a wrapped type.
Type functionGenericReturn(Type boundWrapped, Type argWrapped) => dart.gFnType(
    (T) => [
          T,
          [unwrap(argWrapped)]
        ],
    (T) => [unwrap(boundWrapped)]);

// Returns a function with a bounded generic argument type of
// <T extends boundWrapped> T -> returnWrapped as a wrapped type.
Type functionGenericArg(Type boundWrapped, Type returnWrapped) => dart.gFnType(
    (T) => [
          unwrap(returnWrapped),
          [T]
        ],
    (T) => [unwrap(boundWrapped)]);

void checkSubtype(Type sWrapped, Type tWrapped) {
  var s = unwrap(sWrapped);
  var t = unwrap(tWrapped);
  Expect.isTrue(dart.isSubtypeOf(s, t), '$s should be subtype of $t.');
}

void checkProperSubtype(Type sWrapped, Type tWrapped) {
  var s = unwrap(sWrapped);
  var t = unwrap(tWrapped);
  Expect.isTrue(dart.isSubtypeOf(s, t), '$s should be subtype of $t.');
  checkSubtypeFailure(tWrapped, sWrapped);
}

void checkSubtypeFailure(Type sWrapped, Type tWrapped) {
  var s = unwrap(sWrapped);
  var t = unwrap(tWrapped);
  Expect.isFalse(dart.isSubtypeOf(s, t), '$s should not be subtype of $t.');
}
