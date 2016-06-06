// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/source/config.dart';
import 'package:unittest/unittest.dart';
import 'package:yaml/yaml.dart';

main() {
  group('Analysis Config', () {
    test('parseConfigSource', () {
      String source = r'''
analyzer:
  configuration: google/strict
''';
      YamlMap options = loadYamlNode(source);
      AnalysisConfigurationDescriptor descriptor =
          new AnalysisConfigurationDescriptor.fromAnalyzerOptions(
              options['analyzer']);
      expect(descriptor.package, 'google');
      expect(descriptor.pragma, 'strict');
    });
  });
}
