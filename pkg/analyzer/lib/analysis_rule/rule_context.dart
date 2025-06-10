// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/workspace/workspace.dart';

/// Provides access to information needed by analysis rules that is not
/// available from AST nodes or the element model.
abstract class RuleContext {
  /// The list of all compilation units that make up the library under analysis,
  /// including the defining compilation unit, all parts, and all augmentations.
  List<RuleContextUnit> get allUnits;

  /// The compilation unit being analyzed.
  ///
  /// `null` when a unit is not currently being analyzed (for example when node
  /// processors are being registered).
  RuleContextUnit? get currentUnit;

  /// The defining compilation unit of the library under analysis.
  RuleContextUnit get definingUnit;

  /// Whether the [definingUnit]'s location is in a package's top-level 'lib'
  /// directory, including locations deeply nested, and locations in the
  /// package-implementation directory, 'lib/src'.
  bool get isInLibDir;

  /// Whether the [definingUnit] is in a [package]'s "test" directory.
  bool get isInTestDirectory;

  /// The library element representing the library that contains the compilation
  /// unit being analyzed.
  LibraryElement? get libraryElement;

  /// The package in which the library being analyzed lives, or `null` if it
  /// does not live in a package.
  WorkspacePackage? get package;

  TypeProvider get typeProvider;

  TypeSystem get typeSystem;

  /// Whether the given [feature] is enabled in this rule context.
  bool isFeatureEnabled(Feature feature);
}

/// Provides access to information needed by analysis rules that is not
/// available from AST nodes or the element model.
class RuleContextUnit {
  final File file;
  final String content;
  final DiagnosticReporter diagnosticReporter;
  final CompilationUnit unit;

  RuleContextUnit({
    required this.file,
    required this.content,
    required this.diagnosticReporter,
    required this.unit,
  });
}
