// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of malformed_test;

/// [o] is either `null` or `new List<String>()`.
void testValue(var o) {
  assert(o == null || o is List<String>);

  test(true, () => o is Unresolved, "$o is Unresolved");
  test(false, () => o is List<Unresolved>, "$o is List<Unresolved>");
  test(true, () => o is! Unresolved, "$o is! Unresolved");
  test(false, () => o is! List<Unresolved>, "$o is List<Unresolved>");

  test(true, () => o as Unresolved, "$o as Unresolved");
  test(false, () => o as List<Unresolved>, "$o as List<Unresolved>");

  test(false, () {
    try {} on Unresolved catch (e) {} catch (e) {}
  }, "on Unresolved catch: Nothing thrown.");
  test(true, () {
    try {
      throw o;
    } on Unresolved catch (e) {} catch (e) {}
  }, "on Unresolved catch ($o)");
  test(false, () {
    try {
      throw o;
    } on List<
        String> catch (e) {} on NullThrownError catch (e) {} on Unresolved catch (e) {} catch (e) {}
  }, "on List<String>/NullThrowError catch ($o)");
  test(false, () {
    try {
      throw o;
    } on List<
        Unresolved> catch (e) {} on NullThrownError catch (e) {} on Unresolved catch (e) {} catch (e) {}
  }, "on List<Unresolved>/NullThrowError catch ($o)");

  test(o != null && inCheckedMode(), () {
    Unresolved u = o;
  }, "Unresolved u = $o;");
  test(false, () {
    List<Unresolved> u = o;
  }, "List<Unresolved> u = $o;");
}
