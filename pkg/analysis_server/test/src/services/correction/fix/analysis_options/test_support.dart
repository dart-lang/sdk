// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/protocol_server.dart' show SourceEdit;
import 'package:analysis_server/src/services/correction/fix/analysis_options/fix_generator.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:yaml/src/yaml_node.dart';
import 'package:yaml/yaml.dart';

/// A base class providing utility methods for tests of fixes associated with
/// errors in Dart files.
class AnalysisOptionsFixTest with ResourceProviderMixin {
  Future<void> assertHasFix(
      String initialContent, String expectedContent) async {
    var fixes = await _getFixes(initialContent);
    expect(fixes, hasLength(1));
    var fileEdits = fixes[0].change.edits;
    expect(fileEdits, hasLength(1));

    var actualContent =
        SourceEdit.applySequence(initialContent, fileEdits[0].edits);
    expect(actualContent, expectedContent);
  }

  Future<void> assertHasNoFix(String initialContent) async {
    var fixes = await _getFixes(initialContent);
    expect(fixes, hasLength(0));
  }

  Future<List<Fix>> _getFixes(String content) {
    var optionsFile = getFile('/analysis_options.yaml');
    var sourceFactory = SourceFactory([]);
    var errors = analyzeAnalysisOptions(
        optionsFile.createSource(), content, sourceFactory);
    expect(errors, hasLength(1));
    var error = errors[0];
    var options = _parseYaml(content);
    var generator = AnalysisOptionsFixGenerator(error, content, options);
    return generator.computeFixes();
  }

  YamlMap _parseYaml(String content) {
    if (content == null) {
      return YamlMap();
    }
    try {
      var doc = loadYamlNode(content);
      if (doc is YamlMap) {
        return doc;
      }
      return YamlMap();
    } catch (exception) {
      return null;
    }
  }
}
