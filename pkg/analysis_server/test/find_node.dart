// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer_testing/src/single_unit.dart';

mixin FindNodeMixin on SingleUnitTest {
  /// A helper for finding [AstNode]s within [testUnit].
  ///
  /// Populated when parsing [testFile] via [parseTestCode], or when resolving
  /// [testFile] via [getResolvedUnit], [resolveTestFile], or [resolveTestCode].
  late FindNode findNode;

  @override
  Future<ResolvedUnitResult> getResolvedUnit(
    File file, {
    List<DiagnosticCode>? ignore,
  }) async {
    var unitResult = await super.getResolvedUnit(file, ignore: ignore);
    if (file.path == convertPath(testFilePath)) {
      findNode = FindNode(unitResult.content, testUnit);
    }
    return unitResult;
  }

  @override
  Future<void> parseTestCode(String code) async {
    await super.parseTestCode(code);
    findNode = FindNode(testCode, testUnit);
  }
}
