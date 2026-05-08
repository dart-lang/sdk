// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:test/test.dart';
import 'package:webdriver/async_io.dart';

import 'utils/matchers.dart';
import 'utils/utilities.dart';

// NOTE: this test requires that Chrome is available via PATH or CHROME_PATH
// environment variables.

void main() {
  late SseHandler handler;
  late HttpServer server;
  late WebDriver webdriver;
  late Process chromeDriver;

  setUpAll(() async {
    var chromedriverPath = Platform.environment['CHROMEDRIVER_PATH'];
    if (chromedriverPath == null) {
      chromedriverPath = '../../../third_party/webdriver/chrome/chromedriver';
      if (Platform.isWindows) {
        chromedriverPath = '$chromedriverPath.exe';
      }
    }
    final chromedriverUri = resolveTestRelativePath(chromedriverPath);
    try {
      chromeDriver = await Process.start(chromedriverUri.toFilePath(), [
        '--port=4444',
        '--url-base=wd/hub',
      ]);
      final started = Completer<void>();
      late final StreamSubscription<String> sub;
      sub = chromeDriver.stdout.transform(utf8.decoder).listen((e) {
        if (e.contains('ChromeDriver was started successfully')) {
          started.complete();
          sub.cancel();
        }
      });
      await started.future;
    } catch (e) {
      throw StateError(
        'Could not start ChromeDriver. Is it installed?\nError: $e',
      );
    }
  });

  tearDownAll(() async {
    chromeDriver.kill();
    await chromeDriver.exitCode;
  });

  group('SSE client test:', () {
    setUp(() async {
      FutureOr<shelf.Response> faviconHandler(shelf.Request request) {
        if (request.url.path.endsWith('favicon.ico')) {
          return shelf.Response.ok('');
        }
        return shelf.Response.notFound('');
      }

      handler = SseHandler(Uri.parse('/test'));
      final cascade = shelf.Cascade()
          .add(handler.handler)
          .add(faviconHandler)
          .add(
            createStaticHandler(
              resolveTestRelativePath('web').toFilePath(),
              listDirectories: true,
              defaultDocument: 'index.html',
            ),
          );

      server = await io.serve(cascade.handler, 'localhost', 0);

      final capabilities = Capabilities.chrome
        ..addAll({
          Capabilities.chromeOptions: {
            'args': ['--headless'],
            'binary': ?Platform.environment['CHROME_PATH'],
          },
        });
      webdriver = await createDriver(desired: capabilities);
    });

    tearDown(() async {
      await webdriver.quit();
      await server.close();
    });

    Future<void> validateConnection(DartRuntimeService service) async {
      await webdriver.get('http://localhost:${server.port}');
      final testeeConnection = await handler.connections.next;

      // Replace the sse scheme with http as sse isn't supported for CORS.
      testeeConnection.sink.add(
        service.sseUri.replace(scheme: 'http').toString(),
      );
      final response = await testeeConnection.stream.first;
      expect(response, 'Success');
    }

    const config = DartRuntimeServiceOptions(
      enableLogging: true,
      sseHandlerPath: r'$devHandler',
    );

    test('SSE connection with no authentication codes', () async {
      final service = await createDartRuntimeServiceForTest(
        config: config.copyWith(disableAuthCodes: true),
      );
      expectAuthenticationCodesDisabled(service);
      await validateConnection(service);
    });

    test('SSE connection with authentication codes', () async {
      final service = await createDartRuntimeServiceForTest(
        config: config.copyWith(disableAuthCodes: false),
      );
      expectAuthenticationCodesEnabled(service);
      await validateConnection(service);
    });
  }, timeout: Timeout.none);
}
