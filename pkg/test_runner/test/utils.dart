// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:test_runner/src/configuration.dart';
import 'package:test_runner/src/options.dart';
import 'package:test_runner/src/path.dart';
import 'package:test_runner/src/static_error.dart';
import 'package:test_runner/src/test_file.dart';
import 'package:test_runner/src/test_suite.dart';

final Path _suiteDirectory = Path("language_2");

TestFile parseTestFile(String source, {String path = "some_test.dart"}) {
  path = _suiteDirectory.absolute.append(path).toNativePath();
  return TestFile.parse(_suiteDirectory.absolute, path, source);
}

// TODO(rnystrom): Would be nice if there was a simpler way to create a
// configuration for use in unit tests.
TestConfiguration makeConfiguration(List<String> arguments) =>
    OptionsParser().parse([...arguments, "language_2"]).first;

/// Creates a [StandardTestSuite] hardcoded to contain [testFiles].
StandardTestSuite makeTestSuite(
        TestConfiguration configuration, List<TestFile> testFiles) =>
    _MockTestSuite(configuration, testFiles);

StaticError makeError(
    {int line,
    int column,
    int length,
    String analyzerError,
    String cfeError,
    String webError}) {
  var errors = {
    if (analyzerError != null) ErrorSource.analyzer: analyzerError,
    if (cfeError != null) ErrorSource.cfe: cfeError,
    if (webError != null) ErrorSource.web: webError,
  };
  return StaticError(errors, line: line, column: column, length: length);
}

class _MockTestSuite extends StandardTestSuite {
  final List<TestFile> _testFiles;

  _MockTestSuite(TestConfiguration configuration, this._testFiles)
      : super(configuration, "language_2", _suiteDirectory, []);

  @override
  Iterable<TestFile> findTests() => _testFiles;
}
