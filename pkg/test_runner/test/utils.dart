// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'package:test_runner/src/configuration.dart';
import 'package:test_runner/src/options.dart';
import 'package:test_runner/src/path.dart';
import 'package:test_runner/src/static_error.dart';
import 'package:test_runner/src/test_file.dart';
import 'package:test_runner/src/test_suite.dart';

final tempDir = Directory.systemTemp.createTempSync('test_runner_test');

/// Writes then parses a test file.
TestFile createTestFile(
    {required String source,
    String path = "some_test.dart",
    String suite = "language"}) {
  var suitePath = Path(tempDir.path).append(suite);
  path = suitePath.append(path).toNativePath();
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(source);
  return TestFile.read(suitePath.absolute, path);
}

// TODO(rnystrom): Would be nice if there was a simpler way to create a
// configuration for use in unit tests.
TestConfiguration makeConfiguration(List<String> arguments, String suite) {
  return OptionsParser().parse([...arguments, suite]).first;
}

/// Creates a [StandardTestSuite] hardcoded to contain [testFiles].
StandardTestSuite makeTestSuite(TestConfiguration configuration,
        List<TestFile> testFiles, String suite) =>
    _MockTestSuite(configuration, testFiles, suite);

/// Creates a [StaticError].
///
/// Only one of [analyzerError], [cfeError], [webError], or [contextError] may
/// be passed.
StaticError makeError(
    {String path = 'test.dart',
    int line = 1,
    int column = 2,
    int length = 0,
    String? analyzerError,
    String? cfeError,
    String? webError,
    String? contextError,
    List<StaticError>? context}) {
  ErrorSource source;
  String? message;
  if (analyzerError != null) {
    assert(cfeError == null);
    assert(webError == null);
    assert(contextError == null);
    source = ErrorSource.analyzer;
    message = analyzerError;
  } else if (cfeError != null) {
    assert(webError == null);
    assert(contextError == null);
    source = ErrorSource.cfe;
    message = cfeError;
  } else if (webError != null) {
    assert(contextError == null);
    source = ErrorSource.web;
    message = webError;
  } else {
    assert(contextError != null);
    source = ErrorSource.context;
    message = contextError;
  }

  var error = StaticError(source, message!,
      path: path, line: line, column: column, length: length);
  if (context != null) error.contextMessages.addAll(context);
  return error;
}

class _MockTestSuite extends StandardTestSuite {
  final List<TestFile> _testFiles;

  _MockTestSuite(TestConfiguration configuration, this._testFiles, String suite)
      : super(configuration, suite, Path(suite), []);

  @override
  Iterable<TestFile> findTests() => _testFiles;
}
