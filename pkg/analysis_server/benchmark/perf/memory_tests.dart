// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';

import '../../test/integration/support/integration_tests.dart';

void printMemoryResults(String id, String description, List<int> sizes) {
  int minMemory = sizes.fold(sizes.first, min);
  int maxMemory = sizes.fold(sizes.first, max);
  String now = new DateTime.now().toUtc().toIso8601String();
  print('$now ========== $id');
  print('memory: $sizes');
  print('min_memory: $minMemory');
  print('max_memory: $maxMemory');
  print(description.trim());
  print('--------------------');
  print('');
  print('');
}

/**
 * Base class for analysis server memory usage tests.
 */
class AnalysisServerMemoryUsageTest
    extends AbstractAnalysisServerIntegrationTest {
  static const int vmServicePort = 12345;

  int getMemoryUsage() {
    String vmService =
        'http://localhost:$vmServicePort/_getAllocationProfile\?isolateId=isolates/root\&gc=full';
    ProcessResult result;
    if (Platform.isWindows) {
      result = _run(
          'powershell', <String>['-Command', '(curl "$vmService").Content']);
    } else {
      result = _run('curl', <String>[vmService]);
    }
    Map jsonData = json.decode(result.stdout);
    Map heaps = jsonData['result']['heaps'];
    int newSpace = heaps['new']['used'];
    int oldSpace = heaps['old']['used'];
    return newSpace + oldSpace;
  }

  /**
   * Send the server an 'analysis.setAnalysisRoots' command directing it to
   * analyze [sourceDirectory].
   */
  Future setAnalysisRoot() =>
      sendAnalysisSetAnalysisRoots([sourceDirectory.path], []);

  /**
   * The server is automatically started before every test.
  */
  @override
  Future setUp({bool useCFE: false}) {
    onAnalysisErrors.listen((AnalysisErrorsParams params) {
      currentAnalysisErrors[params.file] = params.errors;
    });
    onServerError.listen((ServerErrorParams params) {
      // A server error should never happen during an integration test.
      fail('${params.message}\n${params.stackTrace}');
    });
    Completer serverConnected = new Completer();
    onServerConnected.listen((_) {
      outOfTestExpect(serverConnected.isCompleted, isFalse);
      serverConnected.complete();
    });
    return startServer(
      servicesPort: vmServicePort,
      cfe: useCFE,
    ).then((_) {
      server.listenToOutput(dispatchNotification);
      server.exitCode.then((_) {
        skipShutdown = true;
      });
      return serverConnected.future;
    });
  }

  /**
   * After every test, the server is stopped.
   */
  Future shutdown() async => await shutdownIfNeeded();

  /**
   * Enable [ServerService.STATUS] notifications so that [analysisFinished]
   * can be used.
   */
  Future subscribeToStatusNotifications() async {
    await sendServerSetSubscriptions([ServerService.STATUS]);
  }

  /**
   * Synchronously run the given [executable] with the given [arguments]. Return
   * the result of running the process.
   */
  ProcessResult _run(String executable, List<String> arguments) {
    return Process.runSync(executable, arguments,
        stderrEncoding: utf8, stdoutEncoding: utf8);
  }

  /**
   *  1. Start Analysis Server.
   *  2. Set the analysis [roots].
   *  3. Wait for analysis to complete.
   *  4. Record the heap size after analysis is finished.
   *  5. Shutdown.
   *  6. Go to (1).
   */
  static Future<List<int>> start_waitInitialAnalysis_shutdown(
      {List<String> roots, int numOfRepeats}) async {
    outOfTestExpect(roots, isNotNull, reason: 'roots');
    outOfTestExpect(numOfRepeats, isNotNull, reason: 'numOfRepeats');
    // Repeat.
    List<int> sizes = <int>[];
    for (int i = 0; i < numOfRepeats; i++) {
      AnalysisServerMemoryUsageTest test = new AnalysisServerMemoryUsageTest();
      // Initialize Analysis Server.
      await test.setUp();
      await test.subscribeToStatusNotifications();
      // Set roots and analyze.
      await test.sendAnalysisSetAnalysisRoots(roots, []);
      await test.analysisFinished;
      sizes.add(test.getMemoryUsage());
      // Stop the server.
      await test.shutdown();
    }
    return sizes;
  }
}
