// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/lint/util.dart' as util;

export 'package:analyzer/dart/element/type_system.dart';
export 'package:analyzer/src/dart/ast/token.dart';
export 'package:analyzer/src/dart/element/inheritance_manager3.dart'
    show InheritanceManager3, Name;
export 'package:analyzer/src/dart/error/lint_codes.dart';
export 'package:analyzer/src/dart/resolver/exit_detector.dart';
export 'package:analyzer/src/generated/engine.dart' show AnalysisErrorInfo;
export 'package:analyzer/src/generated/source.dart' show LineInfo, Source;
export 'package:analyzer/src/lint/lint_rule_timers.dart';
export 'package:analyzer/src/lint/linter.dart'
    show
        dart2_12,
        dart3,
        dart3_3,
        LintRule,
        LinterContext,
        LinterOptions,
        NodeLintRegistry,
        State;
export 'package:analyzer/src/lint/pub.dart' show PSEntry, PubspecVisitor;
export 'package:analyzer/src/lint/util.dart' show FileSpelunker;
export 'package:analyzer/src/utilities/extensions/ast.dart';
export 'package:analyzer/src/workspace/pub.dart' show PubPackage;

export 'lint_codes.dart';
export 'lint_names.dart';

const loggedAnalyzerErrorExitCode = 63;

/// Facade for managing access to `analyzer` package APIs.
class Analyzer {
  /// Shared instance.
  static Analyzer facade = Analyzer();

  /// Returns currently registered lint rules.
  Iterable<LintRule> get registeredRules => Registry.ruleRegistry;

  /// Create a library name prefix based on [libraryPath], [projectRoot] and
  /// current [packageName].
  String createLibraryNamePrefix(
          {required String libraryPath,
          String? projectRoot,
          String? packageName}) =>
      util.createLibraryNamePrefix(
          libraryPath: libraryPath,
          projectRoot: projectRoot,
          packageName: packageName);

  /// Register this [lint] with the analyzer's rule registry.
  void register(LintRule lint) {
    Registry.ruleRegistry.register(lint);
  }
}
