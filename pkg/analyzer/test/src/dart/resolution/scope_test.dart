// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixedNamespaceTest);
  });
}

@reflectiveTest
class PrefixedNamespaceTest extends PubPackageResolutionTest {
  Future<PrefixedNamespace> get _dartMath async {
    await assertErrorsInCode(
      r'''
import 'dart:math' as prefix;
''',
      [error(WarningCode.unusedImport, 7, 11)],
    );
    var namespace = findElement2.import('dart:math').namespace;
    return namespace as PrefixedNamespace;
  }

  void test_lookup_missing() async {
    var namespace = await _dartMath;
    expect(namespace.get2('prefix.Missing'), isNull);
  }

  Future<void> test_lookup_missing_matchesPrefix() async {
    var namespace = await _dartMath;
    expect(namespace.get2('prefix'), isNull);
  }

  Future<void> test_lookup_valid() async {
    var namespace = await _dartMath;

    var random = findElement2.importFind('dart:math').class_('Random');
    expect(namespace.get2('prefix.Random'), same(random));
  }
}
