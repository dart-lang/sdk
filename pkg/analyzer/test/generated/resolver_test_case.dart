// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'strong_mode_test.dart';
library;

// import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';

import '../src/dart/resolution/context_collection_resolution.dart';

/// Shared infrastructure for [StrongModeStaticTypeAnalyzer2Test].
class StaticTypeAnalyzer2TestShared extends PubPackageResolutionTest {
  /// Looks up the initializer for the declaration containing [name] and
  /// validates its static [type].
  ///
  /// If [type] is a string, validates that the identifier's static type
  /// stringifies to that text. Otherwise, [type] is used directly a [Matcher]
  /// to match the type.
  void expectInitializerType(
    TestResolvedUnitResult result,
    String name,
    String type,
  ) {
    var declaration = result.findNode.variableDeclaration(name);
    var initializer = declaration.initializer2!;
    assertType(initializer.staticType, type);
  }

  /// Looks up the local variable with [name] and validates its [type].
  void expectLocalVariableType(
    TestResolvedUnitResult result,
    String name,
    String type,
  ) {
    assertType(result.findElement.localVar(name).type, type);
  }
}
