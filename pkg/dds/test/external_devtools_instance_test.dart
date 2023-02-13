// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dds/dds.dart';
import 'package:dds/devtools_server.dart';
import 'package:dds/src/dds_impl.dart';

import 'package:test/test.dart';
import 'common/test_helper.dart';

void main() {
  Process? process;
  DartDevelopmentService? ddService;
  HttpServer? devToolsServer;

  setUp(() async {
    // We don't care what's actually running in the target process for this
    // test, so we're just using an existing one that invokes `debugger()` so
    // we know it won't exit before we can connect.
    process = await spawnDartProcess(
      'get_stream_history_script.dart',
      serveObservatory: false,
      pauseOnStart: false,
    );

    devToolsServer = (await DevToolsServer().serveDevTools(
      customDevToolsPath: devtoolsAppUri(prefix: '../../../').toFilePath(),
    ))!;
  });

  tearDown(() async {
    devToolsServer?.close(force: true);
    await ddService?.shutdown();
    process?.kill();
    ddService = null;
    process = null;
    devToolsServer = null;
  });

  defineTest({required bool authCodesEnabled}) {
    test(
        'Ensure external DevTools assets are available with '
        '${authCodesEnabled ? '' : 'no'} auth codes', () async {
      ddService = await DartDevelopmentService.startDartDevelopmentService(
        remoteVmServiceUri,
      );
      final dds = ddService!;
      expect(dds.isRunning, true);
      expect(dds.devToolsUri, isNull);

      final client = HttpClient();
      final ddsDevToolsUri =
          (dds as DartDevelopmentServiceImpl).toDevTools(dds.uri!)!;

      // Check that DevTools assets are not accessible before registering the
      // DevTools server URI with DDS.
      final badRequest = await client.getUrl(ddsDevToolsUri);
      final badResponse = await badRequest.close();
      expect(badResponse.statusCode, HttpStatus.notFound);
      badResponse.drain();

      // Register the external DevTools server URI with DDS.
      dds.setExternalDevToolsUri(
        Uri.parse(
          'http://${devToolsServer!.address.host}:${devToolsServer!.port}',
        ),
      );

      // Check that DevTools assets are accessible via the DDS DevTools URI.
      final devtoolsRequest = await client.getUrl(ddsDevToolsUri);
      final devtoolsResponse = await devtoolsRequest.close();

      // DevTools should be served from the DevTools server port, not the DDS port.
      expect(devtoolsResponse.connectionInfo!.remotePort, devToolsServer!.port);
      expect(devtoolsResponse.statusCode, 200);
      final devtoolsContent =
          await devtoolsResponse.transform(utf8.decoder).join();
      expect(devtoolsContent, startsWith('<!DOCTYPE html>'));
      client.close();
    });
  }

  defineTest(authCodesEnabled: true);
  defineTest(authCodesEnabled: false);
}
