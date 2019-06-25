// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' show JS, JS_GET_NAME;
import 'dart:_js_embedded_names' show JsGetName;
import 'dart:_rti' as rti;
import "package:expect/expect.dart";

final String objectName = JS_GET_NAME(JsGetName.OBJECT_CLASS_TYPE_NAME);
final String futureName = JS_GET_NAME(JsGetName.FUTURE_CLASS_TYPE_NAME);
final String nullName = JS_GET_NAME(JsGetName.NULL_CLASS_TYPE_NAME);

const typeRulesJson = r'''
{
  "int": {"num": []},
  "List": {"Iterable": ["1"]},
  "CodeUnits": {
    "List": ["int"],
    "Iterable": ["int"]
  }
}
''';
final typeRules = JS('=Object', 'JSON.parse(#)', typeRulesJson);
final universe = rti.testingCreateUniverse();

main() {
  rti.testingAddRules(universe, typeRules);
  runTests();
  runTests(); // Ensure caching didn't change anything.
}

void runTests() {
  strictSubtype('List<CodeUnits>', 'Iterable<List<int>>');
  strictSubtype('CodeUnits', 'Iterable<num>');
  strictSubtype('Iterable<int>', 'Iterable<num>');
  strictSubtype('List<int>', objectName);
  strictSubtype('$futureName<int>', '$futureName<num>');
  strictSubtype('int', 'int/');
  strictSubtype('$futureName<int>', 'int/');
  strictSubtype('int/', 'num/');
  strictSubtype('int', 'num/');
  strictSubtype('$futureName<int>', 'num/');
  strictSubtype(nullName, 'int');
  strictSubtype(nullName, 'Iterable<CodeUnits>');
  strictSubtype(nullName, objectName);
  unrelated('int', 'CodeUnits');
  equivalent(nullName, nullName);
  equivalent('double', 'double');
  equivalent(objectName, objectName);
  equivalent('@', '@');
  equivalent('~', '~');
  equivalent('1&', '1&');
  equivalent('List<int>', 'List<int>');
  equivalent(objectName, '@');
  equivalent(objectName, '~');
  equivalent(objectName, '1&');
  equivalent('@', '~');
  equivalent('@', '1&');
  equivalent('~', '1&');
  equivalent('List<$objectName>', 'List<@>');
  equivalent('List<$objectName>', 'List<~>');
  equivalent('List<$objectName>', 'List<1&>');
  equivalent('List<@>', 'List<~>');
  equivalent('List<@>', 'List<1&>');
  equivalent('List<~>', 'List<1&>');
  equivalent('@/', '~/');
}

String reason(String s, String t) => "$s <: $t";

void strictSubtype(String s, String t) {
  var sRti = rti.testingUniverseEval(universe, s);
  var tRti = rti.testingUniverseEval(universe, t);
  Expect.isTrue(rti.testingIsSubtype(universe, sRti, tRti), reason(s, t));
  Expect.isFalse(rti.testingIsSubtype(universe, tRti, sRti), reason(t, s));
}

void unrelated(String s, String t) {
  var sRti = rti.testingUniverseEval(universe, s);
  var tRti = rti.testingUniverseEval(universe, t);
  Expect.isFalse(rti.testingIsSubtype(universe, sRti, tRti), reason(s, t));
  Expect.isFalse(rti.testingIsSubtype(universe, tRti, sRti), reason(t, s));
}

void equivalent(String s, String t) {
  var sRti = rti.testingUniverseEval(universe, s);
  var tRti = rti.testingUniverseEval(universe, t);
  Expect.isTrue(rti.testingIsSubtype(universe, sRti, tRti), reason(s, t));
  Expect.isTrue(rti.testingIsSubtype(universe, tRti, sRti), reason(t, s));
}
