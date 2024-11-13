// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart' as file_system;
import 'package:analyzer/file_system/physical_file_system.dart' as file_system;
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/source.dart';
// ignore: implementation_imports
import 'package:analyzer/src/lint/io.dart';
// ignore: implementation_imports
import 'package:analyzer/src/lint/pub.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'analysis_error_info.dart';
import 'lint_driver.dart';
import 'linter_options.dart';

Source createSource(Uri uri) {
  var filePath = uri.toFilePath();
  var file = file_system.PhysicalResourceProvider.INSTANCE.getFile(filePath);
  return FileSource(file, uri);
}

/// Dart source linter, only for package:linter's tools and tests.
class TestLinter implements AnalysisErrorListener {
  final errors = <AnalysisError>[];

  final LinterOptions options;
  final file_system.ResourceProvider _resourceProvider;

  TestLinter(
    this.options, {
    file_system.ResourceProvider? resourceProvider,
  }) : _resourceProvider =
            resourceProvider ?? file_system.PhysicalResourceProvider.INSTANCE;

  Future<List<AnalysisErrorInfo>> lintFiles(List<File> files) async {
    var errors = <AnalysisErrorInfo>[];
    var lintDriver = LintDriver(options, _resourceProvider);
    errors.addAll(await lintDriver.analyze(files.where(isDartFile)));
    for (var file in files.where(isPubspecFile)) {
      lintPubspecSource(
        contents: file.readAsStringSync(),
        sourcePath: _resourceProvider.pathContext.normalize(file.absolute.path),
      );
    }
    return errors;
  }

  @visibleForTesting
  void lintPubspecSource({required String contents, String? sourcePath}) {
    var sourceUrl = sourcePath == null ? null : path.toUri(sourcePath);
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
  }

  @override
  void onError(AnalysisError error) => errors.add(error);
}
