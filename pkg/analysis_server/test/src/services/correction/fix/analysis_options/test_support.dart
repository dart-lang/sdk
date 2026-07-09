// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/analysis_options/fix_generator.dart';
import 'package:analysis_server_plugin/edit/fix/fix.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/src/analysis_options/analysis_options_parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:test/test.dart';

/// A base class providing utility methods for tests of fixes associated with
/// errors in analysis options files.
class AnalysisOptionsFixTest with ResourceProviderMixin {
  Future<void> assertHasFix(
    String initialContent,
    String expectedContent, {
    bool Function(Diagnostic)? errorFilter,
  }) async {
    var fixes = await _getFixes(initialContent, diagnosticFilter: errorFilter);
    expect(fixes, hasLength(1));
    var fileEdits = fixes[0].change.edits;
    expect(fileEdits, hasLength(1));

    var actualContent = SourceEdit.applySequence(
      initialContent,
      fileEdits[0].edits,
    );
    expect(actualContent, expectedContent);
  }

  Future<void> assertHasNoFix(String initialContent) async {
    var fixes = await _getFixes(initialContent);
    expect(fixes, hasLength(0));
  }

  Future<List<Fix>> _getFixes(
    String content, {
    bool Function(Diagnostic)? diagnosticFilter,
  }) {
    var optionsFile = newFile('/analysis_options.yaml', content);
    var sourceFactory = SourceFactory([]);
    var parseResult = AnalysisOptionsParseSession().parse(
      sourceFactory: sourceFactory,
      contextRoot: getFolder('/'),
      file: optionsFile,
      sdkVersionConstraint: dart2_12,
    );
    var errors = parseResult.diagnostics;
    if (diagnosticFilter != null) {
      if (errors.length == 1) {
        fail('Unnecessary error filter');
      }
      errors = errors.where(diagnosticFilter).toList();
    }
    expect(errors, hasLength(1));
    var error = errors[0];
    var fileContent = parseResult.content;
    var yamlMap = fileContent?.yamlMap;
    if (fileContent == null || yamlMap == null) {
      fail('Expected readable analysis_options.yaml with a YAML map.');
    }
    var generator = AnalysisOptionsFixGenerator(
      resourceProvider,
      error,
      fileContent.text,
      yamlMap,
    );
    return generator.computeFixes();
  }
}
