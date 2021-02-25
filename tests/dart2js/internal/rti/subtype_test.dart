// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' show JS, JS_GET_NAME, TYPE_REF;
import 'dart:_js_embedded_names' show JsGetName;
import 'dart:_rti' as rti;
import 'package:expect/expect.dart';

import 'subtype_utils.dart';

final String objectName = JS_GET_NAME(JsGetName.OBJECT_CLASS_TYPE_NAME);
final String futureName = JS_GET_NAME(JsGetName.FUTURE_CLASS_TYPE_NAME);
final String nullName = JS_GET_NAME(JsGetName.NULL_CLASS_TYPE_NAME);

final String nullableObject = "$objectName?";

const typeRulesJson = r'''
{
  "int": {"num": []},
  "double": {"num": []},
  "List": {"Iterable": ["1"]},
  "CodeUnits": {
    "List": ["int"],
    "Iterable": ["int"]
  }
}
''';
final typeRules = JS('=Object', 'JSON.parse(#)', typeRulesJson);

main() {
  rti.testingAddRules(universe, typeRules);
  rti.testingUniverseEvalOverride(
      universe, nullableObject, TYPE_REF<Object?>());
  rti.testingUniverseEvalOverride(universe, objectName, TYPE_REF<Object>());
  rti.testingUniverseEvalOverride(universe, nullName, TYPE_REF<Null>());
  runTests();
  runTests(); // Ensure caching didn't change anything.
}

void runTests() {
  testInterfaces();
  testTopTypes();
  testNull();
  testBottom();
  testFutureOr();
  testFunctions();
  testGenericFunctions();
}

void testInterfaces() {
  strictSubtype('List<CodeUnits>', 'Iterable<List<int>>');
  strictSubtype('CodeUnits', 'Iterable<num>');
  strictSubtype('Iterable<int>', 'Iterable<num>');
  unrelated('int', 'CodeUnits');
  equivalent('double', 'double');
  equivalent('List<int>', 'List<int>');
}

void testTopTypes() {
  strictSubtype('List<int>', nullableObject);
  equivalent(nullableObject, nullableObject);
  equivalent('@', '@');
  equivalent('~', '~');
  equivalent('1&', '1&');
  equivalent(nullableObject, '@');
  equivalent(nullableObject, '~');
  equivalent(nullableObject, '1&');
  equivalent('@', '~');
  equivalent('@', '1&');
  equivalent('~', '1&');
  equivalent('List<$nullableObject>', 'List<@>');
  equivalent('List<$nullableObject>', 'List<~>');
  equivalent('List<$nullableObject>', 'List<1&>');
  equivalent('List<@>', 'List<~>');
  equivalent('List<@>', 'List<1&>');
  equivalent('List<~>', 'List<1&>');
}

void testNull() {
  if (hasSoundNullSafety) {
    unrelated(nullName, 'int');
    unrelated(nullName, 'Iterable<CodeUnits>');
    unrelated(nullName, objectName);
  } else {
    strictSubtype(nullName, 'int');
    strictSubtype(nullName, 'Iterable<CodeUnits>');
    strictSubtype(nullName, objectName);
  }
  strictSubtype(nullName, nullableObject);
  equivalent(nullName, nullName);
}

void testBottom() {
  String never = '0&';
  if (hasSoundNullSafety) {
    strictSubtype(never, nullName);
  } else {
    equivalent(never, nullName);
  }
}

void testFutureOr() {
  strictSubtype('$futureName<int>', '$futureName<num>');
  strictSubtype('int', 'int/');
  strictSubtype('$futureName<int>', 'int/');
  strictSubtype('int/', 'num/');
  strictSubtype('int', 'num/');
  strictSubtype('$futureName<int>', 'num/');
  equivalent('@/', '~/');
}

void testFunctions() {
  equivalent('~()', '~()');
  equivalent('@()', '~()');
  unrelated('int()', 'int(int)');
  strictSubtype('int()', 'num()');
  strictSubtype('~(num)', '~(int)');
  strictSubtype('int(Iterable<num>)', 'num(CodeUnits)');

  equivalent('~(int,@,num)', '~(int,@,num)');
  equivalent('@(int,~,num)', '~(int,@,num)');
  unrelated('int(int,double)', 'void(String)');
  unrelated('int(int,double)', 'int(int)');
  unrelated('int(int,double)', 'int(double)');
  unrelated('int(int,double)', 'int(int,int)');
  unrelated('int(int,double)', 'int(String,double)');
  strictSubtype('int(int,double)', '~(int,double)');
  strictSubtype('int(int,double)', 'num(int,double)');
  strictSubtype('int(num,double)', 'int(int,double)');
  strictSubtype('int(int,num)', 'int(int,double)');
  strictSubtype('int(num,num)', 'int(int,double)');
  strictSubtype('double(num,Iterable<num>,int/)', 'num(int,CodeUnits,int)');

  equivalent('~([@])', '~([@])');
  equivalent('~(int,[double])', '~(int,[double])');
  equivalent('~(int,[double,CodeUnits])', '~(int,[double,CodeUnits])');
  unrelated('~([int])', '~([double])');
  unrelated('~(int,[int])', '~(int,[double])');
  unrelated('~(int,[CodeUnits,int])', '~(int,[CodeUnits,double])');
  strictSubtype('~([num])', '~([int])');
  strictSubtype('~([num,num])', '~([int,double])');
  strictSubtype('~([int,double])', '~(int,[double])');
  strictSubtype('~([int,double,CodeUnits])', '~([int,double])');
  strictSubtype('~([int,double,CodeUnits])', '~(int,[double])');

  equivalent('~({foo:@})', '~({foo:@})');
  unrelated('~({foo:@})', '~({bar:@})');
  unrelated('~({foo:@,quux:@})', '~({bar:@,baz:@})');
  unrelated('~(@,{foo:@})', '~(@,@)');
  unrelated('~(@,{foo:@})', '~({bar:@,foo:@})');
  equivalent('~({bar:int,foo:double})', '~({bar:int,foo:double})');
  strictSubtype('~({bar:int,foo:double})', '~({bar:int})');
  strictSubtype('~({bar:int,foo:double})', '~({foo:double})');
  strictSubtype('~({bar:num,baz:num,foo:num})', '~({baz:int,foo:double})');
}

void testGenericFunctions() {
  equivalent('~()<int>', '~()<int>');
  unrelated('~()<int>', '~()<double>');
  unrelated('~()<int>', '~()<int,int>');
  unrelated('~()<int>', '~()<num>');
  unrelated('~()<int,double>', '~()<double,int>');
  strictSubtype('List<0^>()<int>', 'Iterable<0^>()<int>');
  strictSubtype('~(Iterable<0^>)<int>', '~(List<0^>)<int>');

  equivalent('~()<@>', '~()<~>');
  equivalent('~()<List<@/>>', '~()<List<~/>>');
  unrelated('~()<List<int/>>', '~()<List<num/>>');
}
