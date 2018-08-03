// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that malformed types are handled as dynamic, and that types with the
// wrong number of type arguments are handled as raw types.

import 'package:expect/expect.dart';
import 'package:expect/expect.dart' as prefix; // Define 'prefix'.

checkIsUnresolved(var v) {
  Expect.throws(() => v is Unresolved, (e) => e is TypeError);
  Expect.throws(() => v is Unresolved<int>, (e) => e is TypeError);
  Expect.throws(() => v is prefix.Unresolved, (e) => e is TypeError);
  Expect.throws(() => v is prefix.Unresolved<int>, (e) => e is TypeError);
}

checkIsListUnresolved(bool expect, var v) {
  Expect.equals(expect, v is List<Unresolved>);
  Expect.equals(expect, v is List<Unresolved<int>>);
  Expect.equals(expect, v is List<prefix.Unresolved>);
  Expect.equals(expect, v is List<prefix.Unresolved<int>>);
  Expect.equals(expect, v is List<int, String>);
}

checkIsListDynamic(bool expect, var v) {
  checkIsListUnresolved(true, v);
  Expect.equals(expect, v is List<int> && v is List<String>);
}

checkAsUnresolved(var v) {
  Expect.throws(() => v as Unresolved, (e) => e is TypeError);
  Expect.throws(() => v as Unresolved<int>, (e) => e is TypeError);
  Expect.throws(() => v as prefix.Unresolved, (e) => e is TypeError);
  Expect.throws(() => v as prefix.Unresolved<int>, (e) => e is TypeError);
}

checkAsListUnresolved(bool expect, var v) {
  if (expect) {
    Expect.equals(v, v as List<Unresolved>);
    Expect.equals(v, v as List<Unresolved<int>>);
    Expect.equals(v, v as List<prefix.Unresolved>);
    Expect.equals(v, v as List<prefix.Unresolved<int>>);
    Expect.equals(v, v as List<int, String>);
  } else {
    Expect.throws(() => v as List<Unresolved>, (e) => e is CastError);
    Expect.throws(() => v as List<Unresolved<int>>, (e) => e is CastError);
    Expect.throws(() => v as List<prefix.Unresolved>, (e) => e is CastError);
    Expect.throws(
        () => v as List<prefix.Unresolved<int>>, (e) => e is CastError);
    Expect.throws(() => v as List<int, String>, (e) => e is CastError);
  }
}

checkIsMapDynamic(bool first, bool second, var v) {
  Expect.equals(first, v is Map<String, Object> && v is Map<int, Object>);
  Expect.equals(second, v is Map<Object, int> && v is Map<Object, String>);
}

void main() {
  checkIsUnresolved('');
  checkIsUnresolved(0);
  checkIsListUnresolved(false, '');
  checkIsListUnresolved(true, new List());
  checkIsListUnresolved(true, new List<int>());
  checkIsListUnresolved(true, new List<String>());
  checkIsListUnresolved(true, new List<int, String>());

  checkAsUnresolved('');
  checkAsUnresolved(0);
  checkAsListUnresolved(false, '');
  checkAsListUnresolved(true, new List());
  checkAsListUnresolved(true, new List<int>());
  checkAsListUnresolved(true, new List<String>());
  checkAsListUnresolved(true, new List<int, String>());

  checkIsListDynamic(true, []);
  checkIsListDynamic(true, <>[]); //# 01: syntax error
  checkIsListDynamic(false, <int>[]);
  checkIsListDynamic(true, <Unresolved>[]);
  checkIsListDynamic(true, <Unresolved<int>>[]);
  checkIsListDynamic(true, <prefix.Unresolved>[]);
  checkIsListDynamic(true, <prefix.Unresolved<int>>[]);
  checkIsListDynamic(true, <int, String>[]);

  checkIsListDynamic(true, new List());
  checkIsListDynamic(true, new List<>()); //# 02: syntax error
  checkIsListDynamic(true, new List<Unresolved>());
  checkIsListDynamic(true, new List<Unresolved<int>>());
  checkIsListDynamic(true, new List<prefix.Unresolved>());
  checkIsListDynamic(true, new List<prefix.Unresolved<int>>());
  checkIsListDynamic(true, new List<int, String>());

  checkIsMapDynamic(true, true, <dynamic, dynamic>{});
  checkIsMapDynamic(true, true, {});
  checkIsMapDynamic(true, true, <>{}); //# 03: syntax error
  checkIsMapDynamic(true, true, <int>{});
  checkIsMapDynamic(false, false, <String, int>{});
  checkIsMapDynamic(true, true, <String, int, String>{});
  checkIsMapDynamic(true, false, <Unresolved, int>{});
  checkIsMapDynamic(false, true, <String, Unresolved<int>>{});
  checkIsMapDynamic(true, false, <prefix.Unresolved, int>{});
  checkIsMapDynamic(false, true, <String, prefix.Unresolved<int>>{});

  checkIsMapDynamic(true, true, new Map());
  checkIsMapDynamic(true, true, new Map<>); //# 04: syntax error
  checkIsMapDynamic(true, true, new Map<int>());
  checkIsMapDynamic(false, false, new Map<String, int>());
  checkIsMapDynamic(true, true, new Map<String, int, String>());
  checkIsMapDynamic(true, false, new Map<Unresolved, int>());
  checkIsMapDynamic(false, true, new Map<String, Unresolved<int>>());
  checkIsMapDynamic(true, false, new Map<prefix.Unresolved, int>());
  checkIsMapDynamic(false, true, new Map<String, prefix.Unresolved<int>>());

  Expect.throws(() => new Unresolved(), (e) => true);
  Expect.throws(() => new Unresolved<int>(), (e) => true);
  Expect.throws(() => new prefix.Unresolved(), (e) => true);
  Expect.throws(() => new prefix.Unresolved<int>(), (e) => true);

  // The expression 'undeclared_prefix.Unresolved()' is parsed as the invocation
  // of the named constructor 'Unresolved' on the type 'undeclared_prefix'.
  Expect.throws(() => new undeclared_prefix.Unresolved(), (e) => true);
  // The expression 'undeclared_prefix.Unresolved<int>' is a malformed type.
  Expect.throws(() => new undeclared_prefix.Unresolved<int>(), (e) => true);

  try {
    try {
      throw 'foo';
    } on Unresolved catch (e) {
      Expect.fail("This code shouldn't be executed");
    }
    Expect.fail("This code shouldn't be executed");
  } on TypeError catch (e) {}
  try {
    try {
      throw 'foo';
    } on Unresolved<int> catch (e) {
      Expect.fail("This code shouldn't be executed");
    }
    Expect.fail("This code shouldn't be executed");
  } on TypeError catch (e) {}
  try {
    try {
      throw 'foo';
    } on prefix.Unresolved catch (e) {
      Expect.fail("This code shouldn't be executed");
    }
    Expect.fail("This code shouldn't be executed");
  } on TypeError catch (e) {}
  try {
    try {
      throw 'foo';
    } on prefix.Unresolved<int> catch (e) {
      Expect.fail("This code shouldn't be executed");
    }
    Expect.fail("This code shouldn't be executed");
  } on TypeError catch (e) {}
  try {
    throw 'foo';
  }
    on undeclared_prefix.Unresolved<int> // //# 06: runtime error
  catch (e) {}
}
