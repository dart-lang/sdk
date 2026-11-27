// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';

import 'package:dartpad/dartpad.dart';
import 'package:dartpad_worker/src/util/message_port.dart';
import 'package:test/test.dart' show addTearDown;
import 'package:web/web.dart' as web;

import '../../integration_harness.dart';

String _appSource(String label) =>
    '''
  import 'package:flutter/material.dart';

  void main() => runApp(const MyApp());

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      print('built: $label');
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('$label'),
          ),
        ),
      );
    }
  }
''';

typedef _RpcResponse = ({String method, Map<String, Object?> result});

/// Relays JSON-RPC messages between [devToolsPort] and the returned `port`,
/// emitting `(method, result)` for each successful response.
///
/// Closes automatically when either side closes its [MessagePort].
({MessagePort port, Stream<_RpcResponse> responses}) _proxyServiceProtocol(
  MessagePort devToolsPort,
) {
  final (port1, port2) = MessagePortExt.createChannel();
  final devTools = devToolsPort.vmServiceChannel();
  final sandbox = port1.vmServiceChannel();
  final idToMethod = <Object?, String>{};
  final responses = StreamController<_RpcResponse>();

  devTools.stream
      .map((msg) {
        if (msg is String) {
          if (jsonDecode(msg) case {
            'method': final String method,
            'id': final Object id,
          }) {
            idToMethod[id] = method;
          }
        }
        return msg;
      })
      .pipe(sandbox.sink)
      .ignore();

  sandbox.stream
      .map((msg) {
        if (msg is String) {
          if (jsonDecode(msg) case {
            'id': final Object id,
            'result': final Map<String, Object?> result,
          }) {
            if (idToMethod.remove(id) case final method?) {
              responses.add((method: method, result: result));
            }
          }
        }
        return msg;
      })
      .pipe(devTools.sink)
      .whenComplete(responses.close)
      .ignore();

  return (port: port2, responses: responses.stream);
}

void main() {
  testFlutterIntegration(
    'createDevToolsIframe boots DevTools and connects to Flutter sandbox',
    (ctx) async {
      // `package:test`'s host page hides suite iframes with `visibility:
      // hidden`, which causes Chromium to render-throttle rAF inside nested
      // cross-origin iframes and stalls DevTools' Flutter Web UI before the
      // Inspector mounts. Temporarily make the suite iframe visible.
      if (web.window.frameElement case final web.HTMLElement outerFrame) {
        final previousVisibility = outerFrame.style.visibility;
        outerFrame.style.visibility = 'visible';
        addTearDown(() => outerFrame.style.visibility = previousVisibility);
      }

      await ctx.ws.writeFileFromText('pubspec.yaml', '''
        name: myapp
        environment:
          sdk: ^3.12.0
        dependencies:
          flutter:
            sdk: flutter
      ''');
      await ctx.ws.pub(command: 'get');
      await ctx.ws.writeFileFromText(
        'lib/main.dart',
        _appSource('hello-devtools-v1'),
      );

      await ctx.sandbox.run('lib/main.dart', mode: 'flutter');
      await ctx.checkConsole(.it()..contains('built: hello-devtools-v1'));

      final sdk = DartPadSdk(
        assetBaseUrl: ctx.server.baseUrl.resolve('flutter/'),
      );
      final devTools = await sdk.createDevToolsIframe(web.document.body!);
      addTearDown(devTools.close);

      final (:port, :responses) = _proxyServiceProtocol(devTools.port);
      final widgetTrees = check(
        responses
            .where((r) => r.method == 'ext.flutter.inspector.getRootWidgetTree')
            .map((r) => jsonEncode(r.result)),
      ).withQueue;

      await ctx.sandbox.connectServiceProtocol(port);
      await widgetTrees.emitsThrough(
        .it()
          ..contains('MyApp')
          ..contains('hello-devtools-v1'),
      );

      // Hot reload while DevTools is attached.
      await ctx.ws.writeFileFromText(
        'lib/main.dart',
        _appSource('hello-devtools-v2'),
      );
      await ctx.sandbox.hotReload();
      await ctx.checkConsole(.it()..contains('built: hello-devtools-v2'));

      // Hot restart: DevTools follows the new isolate and refreshes the
      // Inspector widget tree.
      await ctx.ws.writeFileFromText(
        'lib/main.dart',
        _appSource('hello-devtools-v3'),
      );
      await ctx.sandbox.hotRestart();
      await ctx.checkConsole(.it()..contains('built: hello-devtools-v3'));
      await widgetTrees.emitsThrough(
        .it()
          ..contains('MyApp')
          ..contains('hello-devtools-v3'),
      );

      check(ctx.consoleLog.where((e) => e.level == ConsoleLevel.error)).isEmpty;
    },
  );
}
