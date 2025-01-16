// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: implementation_imports
import 'package:analyzer/src/error/ignore_validator.dart';

import '../analyzer.dart';

const _desc = r"Don't ignore a diagnostic code that is not produced.";

class UnnecessaryIgnore extends LintRule {
  UnnecessaryIgnore() : super(name: 'unnecessary_ignore', description: _desc) {
    // Register the unnecessary_ignore lint codes with the analyzer's validator.
    // We do this here to avoid having to introduce a dependency from the analyzer
    // on the linter.
    IgnoreValidator.unnecessaryIgnoreFileLintCode =
        LinterLintCode.unnecessary_ignore_file;
    IgnoreValidator.unnecessaryIgnoreLocationLintCode =
        LinterLintCode.unnecessary_ignore;
    IgnoreValidator.unnecessaryIgnoreNameFileLintCode =
        LinterLintCode.unnecessary_ignore_name_file;
    IgnoreValidator.unnecessaryIgnoreNameLocationLintCode =
        LinterLintCode.unnecessary_ignore_name;
  }

  @override
  List<LintCode> get lintCodes => const [
    LinterLintCode.unnecessary_ignore,
    LinterLintCode.unnecessary_ignore_file,
    LinterLintCode.unnecessary_ignore_name,
    LinterLintCode.unnecessary_ignore_name_file,
  ];

  /// Note that there is intentionally no registration logic as there is no visiting or
  /// analysis done in the lint implementation. Instead the heavy-lifting is done in an
  /// `IgnoreValidator` instantiated by the `library_analyzer` during analysis.
  /// This is necessary because the lint can only be computed *after* all other diagnostics
  /// have been reported and lints don't hook into the analysis life-cycle with that kind
  /// of awareness.
  ///
  /// The implementation here serves to:
  ///
  /// 1. define the lint code (in the same place as other lints) and (as a result)
  /// 2. register that code with the `IgnoreValidator` so that it can use it in reporting
}
