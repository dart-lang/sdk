// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that if a record literal contains named fields, then all of the record
/// literal's fields are type inferred in the order in which they are written,
/// regardless of the sort order of the field names, and regardless of the
/// relative ordering of named and unnamed fields.
///
/// See https://github.com/dart-lang/sdk/issues/55914

import 'package:expect/static_type_helper.dart';

({Object a, Object b, Object c}) testSortedNamedFields(Object o1, Object o2) {
  // Check that `a` is type inferred before `b` by promoting `o1` in `a` and
  // checking its type in `b`. Check that `b` is type inferred before `c` by
  // promoting `o2` in `b` and checking its type in `c`.
  return (
    a: o1 as int,
    b: [o1..expectStaticType<Exactly<int>>(), o2 as int],
    c: o2..expectStaticType<Exactly<int>>()
  );
}

({Object a, Object b, Object c}) testReversedNamedFields(Object o1, Object o2) {
  // Check that `c` is type inferred before `b` by promoting `o1` in `c` and
  // checking its type in `b`. Check that `b` is type inferred before `a` by
  // promoting `o2` in `b` and checking its type in `a`.
  return (
    c: o1 as int,
    b: [o1..expectStaticType<Exactly<int>>(), o2 as int],
    a: o2..expectStaticType<Exactly<int>>()
  );
}

(Object, {Object a, Object b}) testSortedNamedFieldsAfterPositional(
    Object o1, Object o2) {
  // Check that `$1` is type inferred before `a` by promoting `o1` in `$1` and
  // checking its type in `a`. Check that `a` is type inferred before `b` by
  // promoting `o2` in `a` and checking its type in `b`.
  return (
    o1 as int,
    a: [o1..expectStaticType<Exactly<int>>(), o2 as int],
    b: o2..expectStaticType<Exactly<int>>()
  );
}

(Object, {Object a, Object b}) testReversedNamedFieldsAfterPositional(
    Object o1, Object o2) {
  // Check that `$1` is type inferred before `b` by promoting `o1` in `$1` and
  // checking its type in `b`. Check that `b` is type inferred before `a` by
  // promoting `o2` in `b` and checking its type in `a`.
  return (
    o1 as int,
    b: [o1..expectStaticType<Exactly<int>>(), o2 as int],
    a: o2..expectStaticType<Exactly<int>>()
  );
}

(Object, {Object a, Object b}) testSortedNamedFieldsBeforePositional(
    Object o1, Object o2) {
  // Check that `a` is type inferred before `b` by promoting `o1` in `a` and
  // checking its type in `b`. Check that `b` is type inferred before `$1` by
  // promoting `o2` in `b` and checking its type in `$1`.
  return (
    a: o1 as int,
    b: [o1..expectStaticType<Exactly<int>>(), o2 as int],
    o2..expectStaticType<Exactly<int>>()
  );
}

(Object, {Object a, Object b}) testReversedNamedFieldsBeforePositional(
    Object o1, Object o2) {
  // Check that `b` is type inferred before `a` by promoting `o1` in `b` and
  // checking its type in `a`. Check that `a` is type inferred before `$1` by
  // promoting `o2` in `a` and checking its type in `$1`.
  return (
    b: o1 as int,
    a: [o1..expectStaticType<Exactly<int>>(), o2 as int],
    o2..expectStaticType<Exactly<int>>()
  );
}

(Object, Object, {Object a}) testSingleNamedFieldAfterPositionals(
    Object o1, Object o2) {
  // Check that `$1` is type inferred before `$2` by promoting `o1` in `$1` and
  // checking its type in `$2`. Check that `$2` is type inferred before `a` by
  // promoting `o2` in `$2` and checking its type in `a`.
  return (
    o1 as int,
    [o1..expectStaticType<Exactly<int>>(), o2 as int],
    a: o2..expectStaticType<Exactly<int>>()
  );
}

(Object, Object, {Object a}) testSingleNamedFieldBetweenPositionals(
    Object o1, Object o2) {
  // Check that `$1` is type inferred before `a` by promoting `o1` in `$1` and
  // checking its type in `a`. Check that `a` is type inferred before `$2` by
  // promoting `o2` in `a` and checking its type in `$2`.
  return (
    o1 as int,
    a: [o1..expectStaticType<Exactly<int>>(), o2 as int],
    o2..expectStaticType<Exactly<int>>()
  );
}

(Object, Object, {Object a}) testSingleNamedFieldBeforePositionals(
    Object o1, Object o2) {
  // Check that `a` is type inferred before `$1` by promoting `o1` in `a` and
  // checking its type in `$1`. Check that `$1` is type inferred before `$2` by
  // promoting `o2` in `$1` and checking its type in `$2`.
  return (
    a: o1 as int,
    [o1..expectStaticType<Exactly<int>>(), o2 as int],
    o2..expectStaticType<Exactly<int>>()
  );
}

main() {
  testSortedNamedFields(0, 1);
  testReversedNamedFields(0, 1);
  testSortedNamedFieldsAfterPositional(0, 1);
  testReversedNamedFieldsAfterPositional(0, 1);
  testSortedNamedFieldsBeforePositional(0, 1);
  testReversedNamedFieldsBeforePositional(0, 1);
  testSingleNamedFieldAfterPositionals(0, 1);
  testSingleNamedFieldBetweenPositionals(0, 1);
  testSingleNamedFieldBeforePositionals(0, 1);
}
