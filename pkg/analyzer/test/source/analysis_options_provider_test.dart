// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.source.analysis_options_provider;

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:unittest/unittest.dart';
import 'package:yaml/yaml.dart';

import '../utils.dart';

main() {
  initializeTestEnvironment();
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
      expect(options.length, equals(1));
      expect(options['analyzer'], isNotNull);
      YamlMap analyzer = options['analyzer'];
      expect(analyzer.length, equals(1));
      expect(analyzer['ignore'], isNotNull);
      YamlList ignore = analyzer['ignore'];
      expect(ignore.length, equals(2));
      expect(ignore[0], equals('ignoreme.dart'));
      expect(ignore[1], equals('sdk_ext/**'));
    });
    test('test_doesnotexist', () {
      var optionsProvider = new AnalysisOptionsProvider();
      Map<String, YamlNode> options =
          optionsProvider.getOptions(resourceProvider.getFolder('/empty'));
      expect(options.length, equals(0));
    });
  });
  group('AnalysisOptionsProvider', () {
    setUp(() {
      buildResourceProvider(true);
    });
    tearDown(() {
      clearResourceProvider();
    });
    test('test_empty', () {
      var optionsProvider = new AnalysisOptionsProvider();
      Map<String, YamlNode> options =
          optionsProvider.getOptions(resourceProvider.getFolder('/'));
    });
  });
  group('AnalysisOptionsProvider', () {
    setUp(() {
      buildResourceProvider(false, true);
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
      } catch (e, st) {
        exceptionCaught = true;
      }
      expect(exceptionCaught, isTrue);
    });
  });
}

MemoryResourceProvider resourceProvider;

buildResourceProvider([bool emptyAnalysisOptions = false,
                       bool badAnalysisOptions = false]) {
  resourceProvider = new MemoryResourceProvider();
  resourceProvider.newFolder('/empty');
  resourceProvider.newFolder('/tmp');
  if (badAnalysisOptions) {
    resourceProvider.newFile('/.analysis_options', r''':''');
  } else if (emptyAnalysisOptions) {
    resourceProvider.newFile('/.analysis_options', r'''''');
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
