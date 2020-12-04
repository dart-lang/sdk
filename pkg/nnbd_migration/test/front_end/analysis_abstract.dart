// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../abstract_context.dart';

/// An abstract base for all 'analysis' domain tests.
class AbstractAnalysisTest extends AbstractContextTest {
  String projectPath;
  String testFolder;
  String testFile;
  String testCode;

  AbstractAnalysisTest();

  void addAnalysisOptionsFile(String content) {
    newFile(
        resourceProvider.pathContext.join(projectPath, 'analysis_options.yaml'),
        content: content);
  }

  String addTestFile(String content) {
    newFile(testFile, content: content);
    testCode = content;
    return testFile;
  }

  /// Create an analysis options file based on the given arguments.
  void createAnalysisOptionsFile({List<String> experiments}) {
    var buffer = StringBuffer();
    if (experiments != null) {
      buffer.writeln('analyzer:');
      buffer.writeln('  enable-experiment:');
      for (var experiment in experiments) {
        buffer.writeln('    - $experiment');
      }
    }
    addAnalysisOptionsFile(buffer.toString());
  }

  /// Creates a project [projectPath].
  void createProject({Map<String, String> packageRoots}) {
    newFolder(projectPath);
  }

  /// Returns the offset of [search] in the file at the given [path].
  /// Fails if not found.
  int findFileOffset(String path, String search) {
    var file = getFile(path);
    var code = file.createSource().contents.data;
    var offset = code.indexOf(search);
    expect(offset, isNot(-1), reason: '"$search" in\n$code');
    return offset;
  }

  /// Returns the offset of [search] in [testCode].
  /// Fails if not found.
  int findOffset(String search) {
    var offset = testCode.indexOf(search);
    expect(offset, isNot(-1));
    return offset;
  }

  String modifyTestFile(String content) {
    modifyFile(testFile, content);
    testCode = content;
    return testFile;
  }

  void setUp() {
    super.setUp();
    projectPath = convertPath(testsPath);
    testFolder = convertPath('$testsPath/bin');
    testFile = convertPath('$testsPath/bin/test.dart');
  }
}
