// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixedNamespaceTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PrefixedNamespaceTest extends PubPackageResolutionTest {
  Future<({PrefixedNamespace namespace, TestResolvedUnitResult result})>
  get _dartMath async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as prefix;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:math'.
''');
    var namespace = result.findElement.import('dart:math').namespace;
    return (namespace: namespace as PrefixedNamespace, result: result);
  }

  void test_lookup_missing() async {
    var dartMath = await _dartMath;
    expect(dartMath.namespace.get2('prefix.Missing'), isNull);
  }

  Future<void> test_lookup_missing_matchesPrefix() async {
    var dartMath = await _dartMath;
    expect(dartMath.namespace.get2('prefix'), isNull);
  }

  Future<void> test_lookup_valid() async {
    var dartMath = await _dartMath;

    var random = dartMath.result.findElement
        .importFind('dart:math')
        .class_('Random');
    expect(dartMath.namespace.get2('prefix.Random'), same(random));
  }
}
