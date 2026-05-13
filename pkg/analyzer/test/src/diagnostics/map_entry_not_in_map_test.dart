// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapEntryNotInMapTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MapEntryNotInMapTest extends PubPackageResolutionTest {
  test_set() async {
    await resolveTestCodeWithDiagnostics('''
var c = <int>{1:2};
//            ^^^
// [diag.mapEntryNotInMap] Map entries can only be used in a map literal.
''');
  }

  test_set_const() async {
    await resolveTestCodeWithDiagnostics('''
var c = const <int>{1:2};
//                  ^^^
// [diag.mapEntryNotInMap] Map entries can only be used in a map literal.
''');
  }
}
