// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart' as file_system;
import 'package:analyzer/file_system/physical_file_system.dart' as file_system;
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/source.dart';
// ignore: implementation_imports
import 'package:analyzer/src/lint/pub.dart';
// ignore: implementation_imports
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'analysis_error_info.dart';
import 'lint_driver.dart';
import 'linter_options.dart';

Source _createSource(Uri uri) {
  var filePath = uri.toFilePath();
  var file = file_system.PhysicalResourceProvider.INSTANCE.getFile(filePath);
  return FileSource(file, uri);
}

/// Dart source linter, only for package:linter's tools and tests.
class TestLinter implements DiagnosticListener {
  final errors = <Diagnostic>[];

  final LinterOptions options;
  final file_system.ResourceProvider _resourceProvider;

  TestLinter(this.options, {file_system.ResourceProvider? resourceProvider})
    : _resourceProvider =
          resourceProvider ?? file_system.PhysicalResourceProvider.INSTANCE;

  Future<List<DiagnosticInfo>> lintFiles(List<File> files) async {
    var lintDriver = LintDriver(options, _resourceProvider);
    var errors = await lintDriver.analyze(
      files.where((f) => f.path.endsWith('.dart')),
    );
    for (var file in files.where(_isPubspecFile)) {
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
      var visitor = rule.pubspecVisitor;
      if (visitor != null) {
        // Analyzer sets reporters; if this file is not being analyzed,
        // we need to set one ourselves.  (Needless to say, when pubspec
        // processing gets pushed down, this hack can go away.)
        if (sourceUrl != null) {
          var source = _createSource(sourceUrl);
          rule.reporter = DiagnosticReporter(this, source);
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
  void onDiagnostic(Diagnostic error) => errors.add(error);

  /// Returns whether this [entry] is a pubspec file.
  bool _isPubspecFile(FileSystemEntity entry) =>
      path.basename(entry.path) == file_paths.pubspecYaml;
}
