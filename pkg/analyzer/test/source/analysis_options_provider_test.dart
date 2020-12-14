// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

import '../resource_utils.dart';
import '../src/util/yaml_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisOptionsProviderTest);
  });
  group('AnalysisOptionsProvider', () {
    void expectMergesTo(String defaults, String overrides, String expected) {
      var optionsProvider = AnalysisOptionsProvider();
      var defaultOptions = optionsProvider.getOptionsFromString(defaults);
      var overrideOptions = optionsProvider.getOptionsFromString(overrides);
      var merged = optionsProvider.merge(defaultOptions, overrideOptions);
      expectEquals(merged, optionsProvider.getOptionsFromString(expected));
    }

    group('merging', () {
      test('integration', () {
        expectMergesTo('''
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
''', '''
analyzer:
  plugins:
    - p3
  errors:
    unused_local_variable : ignore # overrides error
linter:
  rules:
    one_member_abstracts: false # promotes and disables
    always_specify_return_types: true
''', '''
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
    test('test_bad_yaml (1)', () {
      var src = '''
    analyzer: # <= bang
strong-mode: true
''';

      var optionsProvider = AnalysisOptionsProvider();
      expect(() => optionsProvider.getOptionsFromString(src),
          throwsA(TypeMatcher<OptionsFormatException>()));
    });

    test('test_bad_yaml (2)', () {
      var src = '''
analyzer:
  strong-mode:true # missing space (sdk/issues/24885)
''';

      var optionsProvider = AnalysisOptionsProvider();
      // Should not throw an exception.
      var options = optionsProvider.getOptionsFromString(src);
      // Should return a non-null options list.
      expect(options, isNotNull);
    });
  });
}

@reflectiveTest
class AnalysisOptionsProviderTest {
  /*late*/ TestPathTranslator pathTranslator;
  /*late*/ ResourceProvider resourceProvider;

  /*late*/ AnalysisOptionsProvider provider;

  String get optionsFileName => AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE;

  void setUp() {
    var rawProvider = MemoryResourceProvider();
    resourceProvider = TestResourceProvider(rawProvider);
    pathTranslator = TestPathTranslator(rawProvider);
    provider = AnalysisOptionsProvider(SourceFactory([
      ResourceUriResolver(rawProvider),
    ]));
  }

  void test_getOptions_crawlUp_hasInFolder() {
    pathTranslator.newFolder('/foo/bar');
    pathTranslator.newFile('/foo/$optionsFileName', r'''
analyzer:
  ignore:
    - foo
''');
    pathTranslator.newFile('/foo/bar/$optionsFileName', r'''
analyzer:
  ignore:
    - bar
''');
    YamlMap options = _getOptions('/foo/bar', crawlUp: true);
    expect(options, hasLength(1));
    {
      var analyzer = getValue(options, 'analyzer') as YamlMap;
      expect(analyzer, isNotNull);
      expect(getValue(analyzer, 'ignore'), unorderedEquals(['bar']));
    }
  }

  void test_getOptions_crawlUp_hasInParent() {
    pathTranslator.newFolder('/foo/bar/baz');
    pathTranslator.newFile('/foo/$optionsFileName', r'''
analyzer:
  ignore:
    - foo
''');
    pathTranslator.newFile('/foo/bar/$optionsFileName', r'''
analyzer:
  ignore:
    - bar
''');
    YamlMap options = _getOptions('/foo/bar/baz', crawlUp: true);
    expect(options, hasLength(1));
    {
      var analyzer = getValue(options, 'analyzer') as YamlMap;
      expect(analyzer, isNotNull);
      expect(getValue(analyzer, 'ignore'), unorderedEquals(['bar']));
    }
  }

  void test_getOptions_doesNotExist() {
    pathTranslator.newFolder('/notFile');
    YamlMap options = _getOptions('/notFile');
    expect(options, isEmpty);
  }

  void test_getOptions_empty() {
    pathTranslator.newFile('/$optionsFileName', r'''#empty''');
    YamlMap options = _getOptions('/');
    expect(options, isNotNull);
    expect(options, isEmpty);
  }

  void test_getOptions_include() {
    pathTranslator.newFile('/foo.include', r'''
analyzer:
  ignore:
    - ignoreme.dart
    - 'sdk_ext/**'
''');
    pathTranslator.newFile('/$optionsFileName', r'''
include: foo.include
''');
    YamlMap options = _getOptions('/');
    expect(options, hasLength(2));
    {
      var analyzer = getValue(options, 'analyzer') as YamlMap;
      expect(analyzer, hasLength(1));
      {
        var ignore = getValue(analyzer, 'ignore') as YamlList;
        expect(ignore, hasLength(2));
        expect(ignore[0], 'ignoreme.dart');
        expect(ignore[1], 'sdk_ext/**');
      }
    }
  }

  void test_getOptions_include_missing() {
    pathTranslator.newFile('/$optionsFileName', r'''
include: /foo.include
''');
    YamlMap options = _getOptions('/');
    expect(options, hasLength(1));
  }

  void test_getOptions_invalid() {
    pathTranslator.newFile('/$optionsFileName', r''':''');
    YamlMap options = _getOptions('/');
    expect(options, hasLength(1));
  }

  void test_getOptions_simple() {
    pathTranslator.newFile('/$optionsFileName', r'''
analyzer:
  ignore:
    - ignoreme.dart
    - 'sdk_ext/**'
''');
    YamlMap options = _getOptions('/');
    expect(options, hasLength(1));
    {
      var analyzer = getValue(options, 'analyzer') as YamlMap;
      expect(analyzer, hasLength(1));
      {
        var ignore = getValue(analyzer, 'ignore') as YamlList;
        expect(ignore, hasLength(2));
        expect(ignore[0], 'ignoreme.dart');
        expect(ignore[1], 'sdk_ext/**');
      }
    }
  }

  YamlMap _getOptions(String posixPath, {bool crawlUp = false}) {
    Resource resource = pathTranslator.getResource(posixPath);
    return provider.getOptions(resource, crawlUp: crawlUp);
  }
}
