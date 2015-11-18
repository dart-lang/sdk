// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.timing.simple;

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:path/path.dart';

import '../timing_framework.dart';

/**
 * Perform the timing test, printing the minimum, average and maximum times, as
 * well as the standard deviation to the output.
 */
void main(List<String> args) {
  SimpleTest test = new SimpleTest();
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

/**
 * A test of how long it takes to get code completion results after making a
 * minor change inside a method body.
 */
class SimpleTest extends TimingTest {
  /**
   * The path to the file in which code completion is to be performed.
   */
  String mainFilePath;

  /**
   * The original content of the file.
   */
  String originalContent;

  /**
   * The offset of the cursor when requesting code completion.
   */
  int cursorOffset;

  /**
   * A completer that will be completed when code completion results have been
   * received from the server.
   */
  Completer completionReceived;

  /**
   * Initialize a newly created test.
   */
  SimpleTest();

  @override
  Future oneTimeSetUp() {
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
  Future perform() {
    sendAnalysisUpdateContent({
      mainFilePath:
          new ChangeContentOverlay([new SourceEdit(cursorOffset, 0, '.')])
    });
    sendCompletionGetSuggestions(mainFilePath, cursorOffset + 1);
    return completionReceived.future;
  }

  @override
  Future setUp() {
    completionReceived = new Completer();
    onCompletionResults.listen((_) {
      // We only care about the time to the first response.
      if (!completionReceived.isCompleted) {
        completionReceived.complete();
      }
    });
    sendAnalysisSetAnalysisRoots([dirname(mainFilePath)], []);
    sendAnalysisUpdateContent(
        {mainFilePath: new AddContentOverlay(originalContent)});
    return new Future.value();
  }

  @override
  Future tearDown() {
    sendAnalysisSetAnalysisRoots([], []);
    return new Future.value();
  }
}
