// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:path/path.dart';

import '../timing_framework.dart';

/// Perform the timing test, printing the minimum, average and maximum times, as
/// well as the standard deviation to the output.
void main(List<String> args) {
  var test = SimpleTest();
  test.run().then((TimingResult result) {
    print('minTime = ${result.minTime}');
    print('averageTime = ${result.averageTime}');
    print('maxTime = ${result.maxTime}');
    print('standardDeviation = ${result.standardDeviation}');
    print('');
    print('Press return to exit');
    return stdin.first;
  });
}

/// A test of how long it takes to get code completion results after making a
/// minor change inside a method body.
class SimpleTest extends TimingTest {
  /// The path to the file in which code completion is to be performed.
  late String mainFilePath;

  /// The original content of the file.
  late String originalContent;

  /// The offset of the cursor when requesting code completion.
  late int cursorOffset;

  /// Initialize a newly created test.
  SimpleTest();

  @override
  Future<void> oneTimeSetUp() {
    return super.oneTimeSetUp().then((_) {
      mainFilePath = sourcePath('test.dart');
      originalContent = r'''
class C {
  m() {
    return 0;
  }
}

f(C c) {
  return c;
}
''';
      cursorOffset = originalContent.indexOf('c;') + 1;
      writeFile(mainFilePath, originalContent);
    });
  }

  @override
  Future<void> perform() {
    sendAnalysisUpdateContent({
      mainFilePath: ChangeContentOverlay([SourceEdit(cursorOffset, 0, '.')]),
    });
    return sendCompletionGetSuggestions2(mainFilePath, cursorOffset + 1, 1000);
  }

  @override
  Future<void> setUp() {
    sendAnalysisSetAnalysisRoots([dirname(mainFilePath)], []);
    sendAnalysisUpdateContent({
      mainFilePath: AddContentOverlay(originalContent),
    });
    return Future.value();
  }

  @override
  Future<void> tearDown() {
    sendAnalysisSetAnalysisRoots([], []);
    return Future.value();
  }
}
