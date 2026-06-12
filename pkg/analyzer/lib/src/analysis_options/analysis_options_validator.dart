// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/analysis_options/options_file_validator.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:pub_semver/pub_semver.dart';

/// Validates analysis options files and produces user-visible diagnostics.
final class AnalysisOptionsValidator {
  final SourceFactory sourceFactory;
  final ResourceProvider resourceProvider;
  final String contextRoot;
  final VersionConstraint? sdkVersionConstraint;
  final AnalysisOptionsCache _analysisOptionsCache;

  AnalysisOptionsValidator({
    required this.sourceFactory,
    required this.resourceProvider,
    required this.contextRoot,
    this.sdkVersionConstraint,
    AnalysisOptionsCache? analysisOptionsCache,
  }) : _analysisOptionsCache = analysisOptionsCache ?? {};

  List<Diagnostic> validateContent({
    required File file,
    required String content,
  }) {
    return AnalysisOptionsAnalyzer(
      initialSource: sourceFactory.forUri2(file.toUri()) ?? FileSource(file),
      sourceFactory: sourceFactory,
      contextRoot: contextRoot,
      sdkVersionConstraint: sdkVersionConstraint,
      resourceProvider: resourceProvider,
      analysisOptionsCache: _analysisOptionsCache,
    ).walkIncludes(content: content);
  }

  List<Diagnostic> validateFile(File file) {
    return validateContent(file: file, content: file.readAsStringSync());
  }
}
