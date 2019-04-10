// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/protocol_server.dart' show SourceEdit;
import 'package:analysis_server/src/services/correction/fix/analysis_options/fix_generator.dart';
import 'package:analyzer/error/error.dart' as engine;
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show SourceFileEdit;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/src/yaml_node.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveSettingTest);
  });
}

class NonDartFixTest with ResourceProviderMixin {
  Future<void> assertHasFix(
      String initialContent, String location, String expectedContent) async {
    File optionsFile = resourceProvider.getFile('/analysis_options.yaml');
    SourceFactory sourceFactory = new SourceFactory([]);
    List<engine.AnalysisError> errors = analyzeAnalysisOptions(
        optionsFile.createSource(), initialContent, sourceFactory);
    expect(errors, hasLength(1));
    engine.AnalysisError error = errors[0];
    YamlMap options = _getOptions(sourceFactory, initialContent);
    AnalysisOptionsFixGenerator generator =
        new AnalysisOptionsFixGenerator(error, initialContent, options);
    List<Fix> fixes = await generator.computeFixes();
    expect(fixes, hasLength(1));
    List<SourceFileEdit> fileEdits = fixes[0].change.edits;
    expect(fileEdits, hasLength(1));

    String actualContent =
        SourceEdit.applySequence(initialContent, fileEdits[0].edits);
    expect(actualContent, expectedContent);
  }

  YamlMap _getOptions(SourceFactory sourceFactory, String content) {
    AnalysisOptionsProvider optionsProvider =
        new AnalysisOptionsProvider(sourceFactory);
    try {
      return optionsProvider.getOptionsFromString(content);
    } on OptionsFormatException {
      return null;
    }
  }
}

@reflectiveTest
class RemoveSettingTest extends NonDartFixTest {
  test_enableSuperMixins() async {
    await assertHasFix(
        '''
analyzer:
  enable-experiment:
    - non-nullable
  language:
    enableSuperMixins: true
''',
        'enable',
        '''
analyzer:
  enable-experiment:
    - non-nullable
''');
  }

  test_invalidExperiment_first() async {
    await assertHasFix(
        '''
analyzer:
  enable-experiment:
    - not-an-experiment
    - non-nullable
''',
        'not-',
        '''
analyzer:
  enable-experiment:
    - non-nullable
''');
  }

  test_invalidExperiment_last() async {
    await assertHasFix(
        '''
analyzer:
  enable-experiment:
    - non-nullable
    - not-an-experiment
''',
        'not-',
        '''
analyzer:
  enable-experiment:
    - non-nullable
''');
  }

  test_invalidExperiment_only() async {
    await assertHasFix(
        '''
analyzer:
  enable-experiment:
    - not-an-experiment
''',
        'not-',
        '''
''');
  }
}
