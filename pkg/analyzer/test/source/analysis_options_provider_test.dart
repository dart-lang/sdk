// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.source.analysis_options_provider_test;

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:unittest/unittest.dart';
import 'package:yaml/yaml.dart';

import '../utils.dart';

main() {
  initializeTestEnvironment();

  group('AnalysisOptionsProvider', () {
    void expectMergesTo(String defaults, String overrides, String expected) {
      var optionsProvider = new AnalysisOptionsProvider();
      var defaultOptions = optionsProvider.getOptionsFromString(defaults);
      var overrideOptions = optionsProvider.getOptionsFromString(overrides);
      var merged = optionsProvider.merge(defaultOptions, overrideOptions);
      expect(merged, optionsProvider.getOptionsFromString(expected));
    }

    group('merging', () {
      test('integration', () {
        expectMergesTo(
            '''
analyzer:
  plugins:
    - p1
    - p2
  errors:
    unused_local_variable : error
linter:
  rules:
    - camel_case_types
    - one_member_abstracts
''',
            '''
analyzer:
  plugins:
    - p3
  errors:
    unused_local_variable : ignore # overrides error
linter:
  rules:
    one_member_abstracts: false # promotes and disables
    always_specify_return_types: true
''',
            '''
analyzer:
  plugins:
    - p1
    - p2
    - p3
  errors:
    unused_local_variable : ignore
linter:
  rules:
    camel_case_types: true
    one_member_abstracts: false
    always_specify_return_types: true
''');
      });
    });
  });

  group('AnalysisOptionsProvider', () {
    setUp(() {
      buildResourceProvider();
    });
    tearDown(() {
      clearResourceProvider();
    });
    test('test_simple', () {
      var optionsProvider = new AnalysisOptionsProvider();
      Map<String, YamlNode> options =
          optionsProvider.getOptions(resourceProvider.getFolder('/'));
      expect(options, hasLength(1));
      expect(options['analyzer'], isNotNull);
      YamlMap analyzer = options['analyzer'];
      expect(analyzer, hasLength(1));
      expect(analyzer['ignore'], isNotNull);
      YamlList ignore = analyzer['ignore'];
      expect(ignore, hasLength(2));
      expect(ignore[0], 'ignoreme.dart');
      expect(ignore[1], 'sdk_ext/**');
    });
    test('test_doesnotexist', () {
      var optionsProvider = new AnalysisOptionsProvider();
      Map<String, YamlNode> options =
          optionsProvider.getOptions(resourceProvider.getFolder('/empty'));
      expect(options, isEmpty);
    });
  });
  group('AnalysisOptionsProvider', () {
    setUp(() {
      buildResourceProvider(emptyAnalysisOptions: true);
    });
    tearDown(() {
      clearResourceProvider();
    });
    test('test_empty', () {
      var optionsProvider = new AnalysisOptionsProvider();
      Map<String, YamlNode> options =
          optionsProvider.getOptions(resourceProvider.getFolder('/'));
      expect(options, isNotNull);
    });
  });
  group('AnalysisOptionsProvider', () {
    setUp(() {
      buildResourceProvider(badAnalysisOptions: true);
    });
    tearDown(() {
      clearResourceProvider();
    });
    test('test_invalid', () {
      var optionsProvider = new AnalysisOptionsProvider();
      bool exceptionCaught = false;
      try {
        Map<String, YamlNode> options =
            optionsProvider.getOptions(resourceProvider.getFolder('/'));
        expect(options, isNotNull);
      } catch (e) {
        exceptionCaught = true;
      }
      expect(exceptionCaught, isTrue);
    });
  });
  group('AnalysisOptionsProvider', () {
    test('test_bad_yaml (1)', () {
      var src = '''
    analyzer: # <= bang
strong-mode: true
''';

      var optionsProvider = new AnalysisOptionsProvider();
      expect(() => optionsProvider.getOptionsFromString(src),
          throwsA(new isInstanceOf<OptionsFormatException>()));
    });

    test('test_bad_yaml (2)', () {
      var src = '''
analyzer:
  strong-mode:true # missing space (sdk/issues/24885)
''';

      var optionsProvider = new AnalysisOptionsProvider();
      // Should not throw an exception.
      var options = optionsProvider.getOptionsFromString(src);
      // Should return a non-null options list.
      expect(options, isNotNull);
    });
  });
}

MemoryResourceProvider resourceProvider;

buildResourceProvider(
    {bool emptyAnalysisOptions: false, bool badAnalysisOptions: false}) {
  resourceProvider = new MemoryResourceProvider();
  resourceProvider.newFolder('/empty');
  resourceProvider.newFolder('/tmp');
  if (badAnalysisOptions) {
    resourceProvider.newFile('/.analysis_options', r''':''');
  } else if (emptyAnalysisOptions) {
    resourceProvider.newFile('/.analysis_options', r'''#empty''');
  } else {
    resourceProvider.newFile(
        '/.analysis_options',
        r'''
analyzer:
  ignore:
    - ignoreme.dart
    - 'sdk_ext/**'
''');
  }
}

clearResourceProvider() {
  resourceProvider = null;
}

emptyResourceProvider() {
  resourceProvider = new MemoryResourceProvider();
}
