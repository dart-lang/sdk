// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library server.performance.scenarios;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:test/test.dart';

import '../../test/integration/integration_tests.dart';
import 'performance_tests.dart';

void printBenchmarkResults(String id, String description, List<int> times) {
  int minTime = times.fold(1 << 20, min);
  String now = new DateTime.now().toUtc().toIso8601String();
  print('$now ========== $id');
  print('times: $times');
  print('min_time: $minTime');
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
    outOfTestExpect(roots, isNotNull, reason: 'roots');
    outOfTestExpect(file, isNotNull, reason: 'file');
    outOfTestExpect(fileChange, isNotNull, reason: 'fileChange');
    outOfTestExpect(numOfRepeats, isNotNull, reason: 'numOfRepeats');
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
    outOfTestExpect(roots, isNotNull, reason: 'roots');
    outOfTestExpect(file, isNotNull, reason: 'file');
    outOfTestExpect(fileChange, isNotNull, reason: 'fileChange');
    outOfTestExpect(completeAfterStr, isNotNull, reason: 'completeAfterStr');
    outOfTestExpect(numOfRepeats, isNotNull, reason: 'numOfRepeats');
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
    outOfTestExpect(roots, isNotNull, reason: 'roots');
    outOfTestExpect(file, isNotNull, reason: 'file');
    outOfTestExpect(fileChange, isNotNull, reason: 'fileChange');
    outOfTestExpect(refactoringAtStr, isNotNull, reason: 'refactoringAtStr');
    outOfTestExpect(refactoringKind, isNotNull, reason: 'refactoringKind');
    outOfTestExpect(refactoringOptions, isNotNull,
        reason: 'refactoringOptions');
    outOfTestExpect(numOfRepeats, isNotNull, reason: 'numOfRepeats');
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
    String updatedContent;
    if (desc.afterStr != null) {
      int offset = _indexOfEnd(file, originalContent, desc.afterStr);
      offset -= desc.afterStrBack;
      updatedContent = originalContent.substring(0, offset) +
          desc.insertStr +
          originalContent.substring(offset);
    } else if (desc.replaceWhat != null) {
      int offset = _indexOf(file, originalContent, desc.replaceWhat);
      updatedContent = originalContent.substring(0, offset) +
          desc.replaceWith +
          originalContent.substring(offset + desc.replaceWhat.length);
    }
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
    outOfTestExpect(roots, isNotNull, reason: 'roots');
    outOfTestExpect(numOfRepeats, isNotNull, reason: 'numOfRepeats');
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
    outOfTestExpect(file.existsSync(), isTrue,
        reason: 'File $path does not exist.');
    return file.readAsStringSync();
  }

  /**
   * Return the index of [what] in [where] in the [file], fail if not found.
   */
  static int _indexOf(String file, String where, String what) {
    int index = where.indexOf(what);
    outOfTestExpect(index, isNot(-1), reason: 'Cannot find |$what| in $file.');
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
  final String replaceWhat;
  final String replaceWith;

  FileChange(
      {this.afterStr,
      this.afterStrBack: 0,
      this.insertStr,
      this.replaceWhat,
      this.replaceWith}) {
    if (afterStr != null) {
      outOfTestExpect(insertStr, isNotNull, reason: 'insertStr');
    } else if (replaceWhat != null) {
      outOfTestExpect(replaceWith, isNotNull, reason: 'replaceWith');
    }
  }
}
