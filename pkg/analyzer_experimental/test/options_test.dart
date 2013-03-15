// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library options_test;

import 'package:unittest/unittest.dart';
import 'package:analyzer_experimental/options.dart';

main() {

  group('AnalyzerOptions.parse()', () {

    test('defaults', () {
      CommandLineOptions options = new CommandLineOptions.parse(['foo.dart']);
      expect(options, isNotNull);
      expect(options.shouldBatch, isFalse);
      expect(options.machineFormat, isFalse);
      expect(options.ignoreUnrecognizedFlags, isFalse);
      expect(options.showMetrics, isFalse);
      expect(options.warningsAreFatal, isFalse);
      expect(options.dartSdkPath, isNull);
      expect(options.sourceFiles, equals(['foo.dart']));

    });

    test('notice unrecognized flags', () {
      CommandLineOptions options = new CommandLineOptions.parse(['--bar', '--baz',
        'foo.dart']);
      expect(options, isNull);
    });

    test('ignore unrecognized flags', () {
      CommandLineOptions options = new CommandLineOptions.parse([
        '--ignore_unrecognized_flags', '--bar', '--baz', 'foo.dart']);
      expect(options, isNotNull);
      expect(options.sourceFiles, equals(['foo.dart']));
    });

  });

}

