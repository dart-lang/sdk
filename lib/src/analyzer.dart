// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/linter.dart'; // ignore: implementation_imports
import 'package:analyzer/src/lint/registry.dart'; // ignore: implementation_imports
import 'package:analyzer/src/lint/util.dart' // ignore: implementation_imports
    as util;

export 'package:analyzer/src/dart/ast/token.dart';
export 'package:analyzer/src/dart/constant/evaluation.dart'
    show ConstantEvaluationEngine, ConstantVisitor;
export 'package:analyzer/src/dart/constant/value.dart' show DartObjectImpl;
export 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisErrorInfo;
export 'package:analyzer/src/generated/resolver.dart'
    show InheritanceManager, TypeProvider, TypeSystem;
export 'package:analyzer/src/generated/source.dart' show LineInfo, Source;
export 'package:analyzer/src/lint/linter.dart'
    show DartLinter, LintRule, Group, Maturity, LinterOptions, LintFilter;
export 'package:analyzer/src/lint/project.dart'
    show DartProject, ProjectVisitor;
export 'package:analyzer/src/lint/pub.dart' show PubspecVisitor, PSEntry;
export 'package:analyzer/src/lint/util.dart' show Spelunker;
export 'package:analyzer/src/services/lint.dart' show lintRegistry;

/// Facade for managing access to `analyzer` package APIs.
class Analyzer {
  /// Shared instance.
  static Analyzer facade = new Analyzer();

  /// Returns currently registered lint rules.
  Iterable<LintRule> get registeredRules => Registry.ruleRegistry;

  /// Create a library name prefix based on [libraryPath], [projectRoot] and
  /// current [packageName].
  String createLibraryNamePrefix(
          {String libraryPath, String projectRoot, String packageName}) =>
      util.createLibraryNamePrefix(
          libraryPath: libraryPath,
          projectRoot: projectRoot,
          packageName: packageName);

  /// Check if this [string] is formatted in `CamelCase`.
  bool isCamelCase(String string) => CamelCaseString.isCamelCase(string);

  /// Returns `true` if this [name] is a legal Dart identifier.
  bool isIdentifier(String name) => util.isIdentifier(name);

  /// Check if this [string] consists only of `_`s.
  bool isJustUnderscores(String string) => util.isJustUnderscores(string);

  /// Returns `true` if this [id] is `lowerCamelCase`.
  bool isLowerCamelCase(String id) => util.isLowerCamelCase(id);

  /// Returns `true` if this [id] is `lower_camel_case_with_underscores`.
  bool isLowerCaseUnderScore(String id) => util.isLowerCaseUnderScore(id);

  /// Returns `true` if this [id] is `lower_camel_case_with_underscores_or.dots`.
  bool isLowerCaseUnderScoreWithDots(String id) =>
      util.isLowerCaseUnderScoreWithDots(id);

  /// Returns `true` if this [fileName] is a Pubspec file.
  bool isPubspecFileName(String fileName) => util.isPubspecFileName(fileName);

  /// Returns `true` if the given code unit [c] is upper case.
  bool isUpperCase(int c) => util.isUpperCase(c);

  /// Register this [lint] with the analyzer's rule registry.
  void register(LintRule lint) {
    Registry.ruleRegistry.register(lint);
  }

  /// Register this [lint] with the analyzer's rule registry and mark it as a
  /// a default.
  void registerDefault(LintRule lint) {
    Registry.ruleRegistry.registerDefault(lint);
  }
}
