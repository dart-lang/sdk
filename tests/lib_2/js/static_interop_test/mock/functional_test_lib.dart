// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test basic functionality of `createStaticInteropMock`. Basic methods, fields
// (final and not), getters, and setters are tested along with potential
// renames.

import 'package:expect/minitest.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS()
@staticInterop
class Methods {}

extension on Methods {
  external int add(int a, int b);
  // Sanity-check that non-externals are unaffected.
  int nonExternal() => 0;
  @JS('_rename')
  external int rename();
  external int optionalAdd(int a, int b, [int c = 0, int? d]);
}

class MethodsDart {
  int add(int a, int b) => a + b;
  int nonExternal() => 1;
  int rename() => 1;
  int optionalAdd(int a, int b, [int? c, int? d]) =>
      a + b + (c ?? 0) + (d ?? 0);
}

@JS()
@staticInterop
class Fields {}

extension on Fields {
  external int field;
  external final int finalField;
  @JS('_renamedField')
  external int renamedField;
  @JS('_renamedFinalField')
  external final int renamedFinalField;
}

class FieldsDart {
  int field = 1;
  int finalField = 1;
  int renamedField = 1;
  final int renamedFinalField = 1;
}

@JS()
@staticInterop
class GetSet {}

extension on GetSet {
  external int get getSet;
  external set getSet(int val);
  @JS('_renamedGetSet')
  external int get renamedGetSet;
  @JS('_renamedGetSet')
  external set renamedGetSet(int val);
  @JS('_sameNameDifferentRenameGet')
  external int get sameNameDifferentRename;
  @JS('_sameNameDifferentRenameSet')
  external set sameNameDifferentRename(int val);
  @JS('_differentNameSameRename')
  external int get differentNameSameRenameGet;
  @JS('_differentNameSameRename')
  external set differentNameSameRenameSet(int val);
}

class GetSetDart {
  int getSet = 1;
  int renamedGetSet = 1;
  int sameNameDifferentRename = 1;
  int differentNameSameRenameGet = 1;
  int differentNameSameRenameSet = 1;
}

void test([Object? proto]) {
  var jsMethods =
      createStaticInteropMock<Methods, MethodsDart>(MethodsDart(), proto);
  expect(jsMethods.add(1, 1), 2);
  expect(jsMethods.nonExternal(), 0);
  expect(jsMethods.rename(), 1);
  expect(jsMethods.optionalAdd(1, 1), 2);
  expect(jsMethods.optionalAdd(1, 1, 1), 3);
  expect(jsMethods.optionalAdd(1, 1, 1, 1), 4);
  var dartFields = FieldsDart();
  var jsFields = createStaticInteropMock<Fields, FieldsDart>(dartFields, proto);
  expect(jsFields.field, 1);
  expect(jsFields.finalField, 1);
  expect(jsFields.renamedField, 1);
  expect(jsFields.renamedFinalField, 1);
  // Modify the JS mock and check for updates in the Dart mock.
  jsFields.field = 2;
  jsFields.renamedField = 2;
  expect(dartFields.field, 2);
  expect(dartFields.renamedField, 2);
  // Modify the Dart mock and check for updates in the JS mock.
  dartFields.field = 3;
  dartFields.finalField = 3;
  dartFields.renamedField = 3;
  expect(jsFields.field, 3);
  expect(jsFields.finalField, 3);
  expect(jsFields.renamedField, 3);
  var dartGetSet = GetSetDart();
  var jsGetSet = createStaticInteropMock<GetSet, GetSetDart>(dartGetSet, proto);
  expect(jsGetSet.getSet, 1);
  expect(jsGetSet.renamedGetSet, 1);
  expect(jsGetSet.sameNameDifferentRename, 1);
  expect(jsGetSet.differentNameSameRenameGet, 1);
  // Modify the JS mock and check for updates in the Dart mock.
  jsGetSet.getSet = 2;
  jsGetSet.renamedGetSet = 2;
  jsGetSet.sameNameDifferentRename = 2;
  jsGetSet.differentNameSameRenameSet = 2;
  expect(dartGetSet.getSet, 2);
  expect(dartGetSet.renamedGetSet, 2);
  expect(dartGetSet.sameNameDifferentRename, 2);
  expect(dartGetSet.differentNameSameRenameGet, 1);
  expect(dartGetSet.differentNameSameRenameSet, 2);
  // Modify the Dart mock and check for updates in the JS mock.
  dartGetSet.getSet = 3;
  dartGetSet.renamedGetSet = 3;
  dartGetSet.sameNameDifferentRename = 3;
  // Use different values to disambiguate.
  dartGetSet.differentNameSameRenameGet = 3;
  dartGetSet.differentNameSameRenameSet = 4;
  expect(jsGetSet.getSet, 3);
  expect(jsGetSet.renamedGetSet, 3);
  expect(jsGetSet.sameNameDifferentRename, 3);
  expect(jsGetSet.differentNameSameRenameGet, 3);
}
