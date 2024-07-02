// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart' as file_system;
import 'package:analyzer/file_system/physical_file_system.dart' as file_system;
// ignore: implementation_imports
import 'package:analyzer/src/generated/engine.dart' show AnalysisErrorInfo;
// ignore: implementation_imports
import 'package:analyzer/src/lint/analysis.dart';
// ignore: implementation_imports
import 'package:analyzer/src/lint/io.dart';
// ignore: implementation_imports
import 'package:analyzer/src/lint/linter.dart';
// ignore: implementation_imports
import 'package:analyzer/src/lint/pub.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

export 'package:analyzer/src/lint/linter_visitor.dart' show NodeLintRegistry;
export 'package:analyzer/src/lint/state.dart'
    show dart2_12, dart3, dart3_3, State;

/// Dart source linter, only for package:linter's tools and tests.
class TestLinter implements AnalysisErrorListener {
  final errors = <AnalysisError>[];

  final LinterOptions options;
  final file_system.ResourceProvider _resourceProvider;

  /// The total number of sources that were analyzed.
  ///
  /// Only valid after [lintFiles] has been called.
  int numSourcesAnalyzed = 0;

  TestLinter(
    this.options, {
    file_system.ResourceProvider? resourceProvider,
  }) : _resourceProvider =
            resourceProvider ?? file_system.PhysicalResourceProvider.INSTANCE;

  Future<Iterable<AnalysisErrorInfo>> lintFiles(List<File> files) async {
    var errors = <AnalysisErrorInfo>[];
    var lintDriver = LintDriver(options, _resourceProvider);
    errors.addAll(await lintDriver.analyze(files.where(isDartFile)));
    numSourcesAnalyzed = lintDriver.numSourcesAnalyzed;
    files.where(isPubspecFile).forEach((path) {
      numSourcesAnalyzed++;
      var errorsForFile = lintPubspecSource(
        contents: path.readAsStringSync(),
        sourcePath: _resourceProvider.pathContext.normalize(path.absolute.path),
      );
      errors.addAll(errorsForFile);
    });
    return errors;
  }

  @visibleForTesting
  Iterable<AnalysisErrorInfo> lintPubspecSource(
      {required String contents, String? sourcePath}) {
    var results = <AnalysisErrorInfo>[];
    var sourceUrl = sourcePath == null ? null : p.toUri(sourcePath);
    var spec = Pubspec.parse(contents, sourceUrl: sourceUrl);

    for (var rule in options.enabledRules) {
      var visitor = rule.getPubspecVisitor();
      if (visitor != null) {
        // Analyzer sets reporters; if this file is not being analyzed,
        // we need to set one ourselves.  (Needless to say, when pubspec
        // processing gets pushed down, this hack can go away.)
        if (sourceUrl != null) {
          var source = createSource(sourceUrl);
          rule.reporter = ErrorReporter(this, source);
        }
        try {
          spec.accept(visitor);
        } on Exception catch (_) {
          // TODO(srawlins): Report the exception somewhere?
        }
      }
    }

    return results;
  }

  @override
  void onError(AnalysisError error) => errors.add(error);
}
