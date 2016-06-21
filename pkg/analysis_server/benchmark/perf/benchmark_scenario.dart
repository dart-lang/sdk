// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library server.performance.scenarios;

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:unittest/unittest.dart';

import 'performance_tests.dart';

void printBenchmarkResults(String id, String description, List<int> times) {
  String now = new DateTime.now().toUtc().toIso8601String();
  print('$now ========== $id');
  print('times: $times');
  print(description.trim());
  print('--------------------');
  print('');
  print('');
}

class BenchmarkScenario extends AbstractTimingTest {
  /**
   * Init.
   *  - Start Analysis Server.
   *  - Set the analysis [roots].
   *  - Wait for analysis to complete.
   *  - Make [file] the priority file.
   *
   * Measurement.
   *  - Change the [file] according to the [fileChange].
   *  - Record the time to finish analysis.
   *
   * Repeat.
   *  - Undo changes to the [file].
   *  - Repeat measurement [numOfRepeats] times.
   */
  Future<List<int>> waitAnalyze_change_analyze(
      {List<String> roots,
      String file,
      FileChange fileChange,
      int numOfRepeats}) async {
    expect(roots, isNotNull, reason: 'roots');
    expect(file, isNotNull, reason: 'file');
    expect(fileChange, isNotNull, reason: 'fileChange');
    expect(numOfRepeats, isNotNull, reason: 'numOfRepeats');
    // Initialize Analysis Server.
    await super.setUp();
    await subscribeToStatusNotifications();
    // Set roots and analyze.
    await sendAnalysisSetAnalysisRoots(roots, []);
    await analysisFinished;
    // Make the file priority.
    await sendAnalysisSetPriorityFiles([file]);
    // Repeat.
    List<int> times = <int>[];
    for (int i = 0; i < numOfRepeats; i++) {
      // Update and wait for analysis.
      Stopwatch stopwatch = new Stopwatch()..start();
      await _applyFileChange(file, fileChange);
      await analysisFinished;
      times.add(stopwatch.elapsed.inMilliseconds);
      // Remove the overlay and analyze.
      await sendAnalysisUpdateContent({file: new RemoveContentOverlay()});
      await analysisFinished;
    }
    // Done.
    await shutdown();
    return times;
  }

  /**
   * Init.
   * 1. Start Analysis Server.
   * 2. Set the analysis [roots].
   * 3. Wait for analysis to complete.
   * 4. Make [file] the priority file.
   *
   * Measurement.
   * 5. Change the [file] according to the [fileChange].
   * 6. Request [completeAfterStr] in the updated file content.
   * 7. Record the time to get completion results.
   * 8. Undo changes to the [file] and analyze.
   * 9. Go to (5).
   */
  Future<List<int>> waitAnalyze_change_getCompletion(
      {List<String> roots,
      String file,
      FileChange fileChange,
      String completeAfterStr,
      int numOfRepeats}) async {
    expect(roots, isNotNull, reason: 'roots');
    expect(file, isNotNull, reason: 'file');
    expect(fileChange, isNotNull, reason: 'fileChange');
    expect(completeAfterStr, isNotNull, reason: 'completeAfterStr');
    expect(numOfRepeats, isNotNull, reason: 'numOfRepeats');
    // Initialize Analysis Server.
    await super.setUp();
    await subscribeToStatusNotifications();
    // Set roots and analyze.
    await sendAnalysisSetAnalysisRoots(roots, []);
    await analysisFinished;
    // Make the file priority.
    await sendAnalysisSetPriorityFiles([file]);
    // Repeat.
    List<int> times = <int>[];
    for (int i = 0; i < numOfRepeats; i++) {
      String updatedContent = await _applyFileChange(file, fileChange);
      // Measure completion time.
      int completionOffset =
          _indexOfEnd(file, updatedContent, completeAfterStr);
      Duration completionDuration =
          await _measureCompletionTime(file, completionOffset);
      times.add(completionDuration.inMilliseconds);
      // Remove the overlay and analyze.
      await sendAnalysisUpdateContent({file: new RemoveContentOverlay()});
      await analysisFinished;
    }
    // Done.
    await shutdown();
    return times;
  }

  /**
   * Init.
   * 1. Start Analysis Server.
   * 2. Set the analysis [roots].
   * 3. Wait for analysis to complete.
   * 4. Make [file] the priority file.
   *
   * Measurement.
   * 5. Change the [file] according to the [fileChange].
   * 6. Request [refactoringAtStr] in the updated file content.
   * 7. Record the time to get refactoring.
   * 8. Undo changes to the [file] and analyze.
   * 9. Go to (5).
   */
  Future<List<int>> waitAnalyze_change_getRefactoring(
      {List<String> roots,
      String file,
      FileChange fileChange,
      String refactoringAtStr,
      RefactoringKind refactoringKind,
      RefactoringOptions refactoringOptions,
      int numOfRepeats}) async {
    expect(roots, isNotNull, reason: 'roots');
    expect(file, isNotNull, reason: 'file');
    expect(fileChange, isNotNull, reason: 'fileChange');
    expect(refactoringAtStr, isNotNull, reason: 'refactoringAtStr');
    expect(refactoringKind, isNotNull, reason: 'refactoringKind');
    expect(refactoringOptions, isNotNull, reason: 'refactoringOptions');
    expect(numOfRepeats, isNotNull, reason: 'numOfRepeats');
    // Initialize Analysis Server.
    await super.setUp();
    await subscribeToStatusNotifications();
    // Set roots and analyze.
    await sendAnalysisSetAnalysisRoots(roots, []);
    await analysisFinished;
    // Make the file priority.
    await sendAnalysisSetPriorityFiles([file]);
    // Repeat.
    List<int> times = <int>[];
    for (int i = 0; i < numOfRepeats; i++) {
      String updatedContent = await _applyFileChange(file, fileChange);
      // Measure time to get refactoring.
      int refactoringOffset = _indexOf(file, updatedContent, refactoringAtStr);
      Duration refactoringDuration = await _measureRefactoringTime(
          file, refactoringOffset, refactoringKind, refactoringOptions);
      times.add(refactoringDuration.inMilliseconds);
      // Remove the overlay and analyze.
      await sendAnalysisUpdateContent({file: new RemoveContentOverlay()});
      await analysisFinished;
    }
    // Done.
    await shutdown();
    return times;
  }

  /**
   * Compute updated content of the [file] as described by [desc], add overlay
   * for the [file], and return the updated content.
   */
  Future<String> _applyFileChange(String file, FileChange desc) async {
    String originalContent = _getFileContent(file);
    int offset = _indexOfEnd(file, originalContent, desc.afterStr);
    offset -= desc.afterStrBack;
    String updatedContent = originalContent.substring(0, offset) +
        desc.insertStr +
        originalContent.substring(offset);
    await sendAnalysisUpdateContent(
        {file: new AddContentOverlay(updatedContent)});
    return updatedContent;
  }

  Future<Duration> _measureCompletionTime(String file, int offset) async {
    Stopwatch stopwatch = new Stopwatch();
    stopwatch.start();
    Completer<Duration> completer = new Completer<Duration>();
    var completionSubscription = onCompletionResults.listen((_) {
      completer.complete(stopwatch.elapsed);
    });
    try {
      await sendCompletionGetSuggestions(file, offset);
      return await completer.future;
    } finally {
      completionSubscription.cancel();
    }
  }

  Future<Duration> _measureRefactoringTime(
      String file,
      int offset,
      RefactoringKind refactoringKind,
      RefactoringOptions refactoringOptions) async {
    Stopwatch stopwatch = new Stopwatch();
    stopwatch.start();
    await sendEditGetRefactoring(refactoringKind, file, offset, 0, false,
        options: refactoringOptions);
    return stopwatch.elapsed;
  }

  /**
   *  1. Start Analysis Server.
   *  2. Set the analysis [roots].
   *  3. Wait for analysis to complete.
   *  4. Record the time to finish analysis.
   *  5. Shutdown.
   *  6. Go to (1).
   */
  static Future<List<int>> start_waitInitialAnalysis_shutdown(
      {List<String> roots, int numOfRepeats}) async {
    expect(roots, isNotNull, reason: 'roots');
    expect(numOfRepeats, isNotNull, reason: 'numOfRepeats');
    // Repeat.
    List<int> times = <int>[];
    for (int i = 0; i < numOfRepeats; i++) {
      BenchmarkScenario instance = new BenchmarkScenario();
      // Initialize Analysis Server.
      await instance.setUp();
      await instance.subscribeToStatusNotifications();
      // Set roots and analyze.
      Stopwatch stopwatch = new Stopwatch()..start();
      await instance.sendAnalysisSetAnalysisRoots(roots, []);
      await instance.analysisFinished;
      times.add(stopwatch.elapsed.inMilliseconds);
      // Stop the server.
      await instance.shutdown();
    }
    return times;
  }

  static String _getFileContent(String path) {
    File file = new File(path);
    expect(file.existsSync(), isTrue, reason: 'File $path does not exist.');
    return file.readAsStringSync();
  }

  /**
   * Return the index of [what] in [where] in the [file], fail if not found.
   */
  static int _indexOf(String file, String where, String what) {
    int index = where.indexOf(what);
    expect(index, isNot(-1), reason: 'Cannot find |$what| in $file.');
    return index;
  }

  /**
   * Return the end index if [what] in [where] in the [file], fail if not found.
   */
  static int _indexOfEnd(String file, String where, String what) {
    return _indexOf(file, where, what) + what.length;
  }
}

class FileChange {
  final String afterStr;
  final int afterStrBack;
  final String insertStr;

  FileChange({this.afterStr, this.afterStrBack: 0, this.insertStr}) {
    expect(afterStr, isNotNull, reason: 'afterStr');
    expect(insertStr, isNotNull, reason: 'insertStr');
  }
}
