// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';

import 'package:dartpad/dartpad.dart';
import 'package:dartpad_worker/src/util/message_port.dart';
import 'package:web/web.dart' as web;

import '../../integration_harness.dart';

void main() {
  testDartIntegration(
    'createDevToolsIframe boots DevTools and connects to sandbox',
    (ctx) async {
      await ctx.ws.writeFileFromText('main.dart', '''
        void main() {
          print('devtools test app running');
        }
      ''');

      await ctx.ws.writeFileFromText('pubspec.yaml', '''
        name: pad
        environment:
          sdk: ^3.11.0
      ''');
      await ctx.ws.pub(command: 'get');
      await ctx.sandbox.run('main.dart', mode: 'console');
      await ctx.checkConsole(.it()..contains('devtools test app running'));

      final sdk = DartPadSdk(assetBaseUrl: ctx.server.baseUrl.resolve('dart/'));
      final devTools = await sdk.createDevToolsIframe(web.document.body!);
      final relay = web.MessageChannel();
      final devToolsChannel = devTools.port.vmServiceChannel();
      final workerFrontChannel = MessagePortExt.fromMessagePort(
        relay.port1,
      ).vmServiceChannel();

      final devToolsMethods = StreamController<String>();
      final sub1 = devToolsChannel.stream.listen((msg) {
        if (msg is String) {
          if (jsonDecode(msg) case {'method': final String method}) {
            devToolsMethods.add(method);
          }
        }
        workerFrontChannel.sink.add(msg);
      });
      final sub2 = workerFrontChannel.stream.listen((msg) {
        devToolsChannel.sink.add(msg);
      });

      try {
        await ctx.sandbox.connectServiceProtocol(
          MessagePortExt.fromMessagePort(relay.port2),
        );

        await check(devToolsMethods.stream).withQueue.inOrder([
          .it()..emitsThrough(.it()..equals('getVM')),
          .it()..emitsThrough(.it()..equals('streamListen')),
          .it()..emitsThrough(.it()..equals('getIsolate')),
        ]);
      } finally {
        await sub1.cancel();
        await sub2.cancel();
        devToolsMethods.close().ignore();
        await devToolsChannel.sink.close();
        await workerFrontChannel.sink.close();
        await devTools.close();
      }
    },
  );
}
