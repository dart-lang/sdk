// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' show JS;
import 'dart:_runtime' as dart;

import 'package:expect/expect.dart';

/// Unwrap the user code type representation to expose the runtime
/// representation of [t].
///
/// Legacy types (produced by the legacy helper below) are returned unchanged
/// because they are created unwrapped since wrapping will strip the legacy from
/// them by design.
/// Generic functions are also unchanged, as they have a separate runtime type object representation.
Object unwrap(Type t) {
  if (JS<bool>('!', '# instanceof #', t, dart.LegacyType) ||
      JS<bool>('!', '# instanceof #', t, dart.GenericFunctionType)) {
    return t;
  }
  return dart.unwrapType(t);
}

/// Returns tWrapped? as a wrapped type.
Type nullable(Type tWrapped) {
  var t = unwrap(tWrapped);
  var tNullable = dart.nullable(t);
  return dart.wrapType(tNullable);
}

/// Returns tWrapped* as an *unwrapped* type when it produces a legacy type, and
/// a *wrapped* type when the legacy has been normalized away.
///
/// For example DDC does not create a legacy dynamic type, only dynamic.
///
/// This is the only helper to return an unwrapped version of a type because
/// wrapping a legacy type will strip off the legacy by design.
Type legacy(Type tWrapped) {
  var t = unwrap(tWrapped);
  var tLegacy = dart.legacy(t);
  // During normalization some types never get created as legacy versions.
  // Ex: dynamic.
  return tLegacy is dart.LegacyType ? tLegacy : dart.wrapType(tLegacy);
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
