// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyze_library_test_config;

import 'dart:io';
import '../../../tools/testing/dart/test_suite.dart';

class AnalyzeLibraryTestSuite extends DartcCompilationTestSuite {
  final libraries = [ 'async', 'core', 'crypto', 'io', 'isolate', 'json',
                      'math', 'mirrors', 'typeddata', 'uri',
                      'utf' ];

  AnalyzeLibraryTestSuite(Map configuration)
      : super(configuration,
              'analyze_library',
              'sdk',
              [ 'lib' ],
              ['tests/lib/analyzer/analyze_library.status'],
              allStaticClean: true);

  bool isTestFile(String filename) {
    var sep = Platform.pathSeparator;
    return libraries.any((String lib) {
      return filename.endsWith('lib$sep$lib$sep$lib.dart');
    });
  }

  bool get listRecursively => true;
}
