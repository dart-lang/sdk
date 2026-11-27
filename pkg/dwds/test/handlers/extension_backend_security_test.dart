// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dwds/dart_web_debug_service.dart';
import 'package:dwds/data/build_result.dart';
import 'package:dwds/src/config/tool_configuration.dart';
import 'package:dwds_test_common/fixtures/fakes.dart';
import 'package:test/test.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

const _extensionOrigin = 'chrome-extension://abcdefghijklmnop';

void main() {
  group('ExtensionBackend WebSocket Origin validation', () {
    late Dwds dwds;
    late String extensionUri;

    setUp(() async {
      final assetReader = FakeAssetReader();
      dwds = await Dwds.start(
        assetReader: assetReader,
        buildResults: const Stream<BuildResult>.empty(),
        chromeConnection: () =>
            Future<ChromeConnection>.error(UnimplementedError()),
        toolConfiguration: ToolConfiguration(
          loadStrategy: FakeStrategy(assetReader),
          debugSettings: DebugSettings(
            enableDebugging: false,
            enableDebugExtension: true,
            useSseForDebugBackend: false,
            urlEncoder: (url) async {
              extensionUri = url;
              return url;
            },
            ddsConfiguration: const DartDevelopmentServiceConfiguration(
              enable: false,
            ),
          ),
          appMetadata: const AppMetadata(),
        ),
      );
    });

    tearDown(() async {
      await dwds.stop();
    });

    test('rejects non-extension Origin headers', () async {
      for (final origin in const <String>['http://evil.test', 'null']) {
        await expectLater(
          WebSocket.connect(
            extensionUri,
            headers: <String, Object>{'Origin': origin},
          ),
          throwsA(isA<WebSocketException>()),
          reason: 'Origin "$origin" should be rejected',
        );
      }
    });

    test('allows chrome-extension:// Origin and absent Origin', () async {
      final extensionWs = await WebSocket.connect(
        extensionUri,
        headers: const <String, Object>{'Origin': _extensionOrigin},
      );
      await extensionWs.close();

      final nativeWs = await WebSocket.connect(extensionUri);
      await nativeWs.close();
    });
  });
}
