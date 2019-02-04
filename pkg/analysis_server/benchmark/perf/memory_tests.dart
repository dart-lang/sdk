// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:test/test.dart';

import '../../test/integration/support/integration_tests.dart';

/**
 * Base class for analysis server memory usage tests.
 */
class AnalysisServerMemoryUsageTest
    extends AbstractAnalysisServerIntegrationTest {
  static const int vmServicePort = 12345;

  Future<int> getMemoryUsage() async {
    Uri uri = Uri.parse('ws://127.0.0.1:$vmServicePort/ws');
    final ServiceProtocol service = await ServiceProtocol.connect(uri);
    final Map vm = await service.call('getVM');

    int total = 0;

    List isolateRefs = vm['isolates'];
    for (Map isolateRef in isolateRefs) {
      Map isolate =
          await service.call('getIsolate', {'isolateId': isolateRef['id']});

      Map _heaps = isolate['_heaps'];
      total += _heaps['new']['used'] + _heaps['new']['external'];
      total += _heaps['old']['used'] + _heaps['old']['external'];
    }

    service.dispose();

    return total;
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
  Future setUp() {
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
    return startServer(servicesPort: vmServicePort).then((_) {
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
}
