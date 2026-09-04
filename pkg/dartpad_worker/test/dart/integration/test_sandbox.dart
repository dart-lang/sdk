// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import '../../integration_harness.dart';

void main() {
  testDartIntegration('sandbox can run code', (ctx) async {
    await ctx.ws.writeFileFromText('main.dart', '''
      void main() {
        print('Hello World');
      }
    ''');

    await ctx.ws.writeFileFromText('pubspec.yaml', '''
      name: pad
      environment:
        sdk: ^3.11.0
    ''');
    await ctx.ws.pub(command: 'get');
    await ctx.sandbox.runMain('main.dart');

    await ctx.checkConsole((m) => m.contains('Hello World'));
  });

  testDartIntegration('sandbox handles unhandled error', (ctx) async {
    await ctx.ws.writeFileFromText('main.dart', '''
      import 'dart:async';
      void main() {
        Timer(Duration.zero, () {
          throw Exception('uncaught error in sandbox');
        });
      }
    ''');

    final errorFuture = ctx.sandbox.errors.first;
    await ctx.ws.writeFileFromText('pubspec.yaml', '''
      name: pad
      environment:
        sdk: ^3.11.0
    ''');
    await ctx.ws.pub(command: 'get');
    await ctx.sandbox.runMain('main.dart');

    await check(errorFuture).completes((r) => r.contains('Error\n'));
  });

  testDartIntegration('sandbox handles unhandled promise rejection', (
    ctx,
  ) async {
    await ctx.ws.writeFileFromText('main.dart', '''
      import 'dart:js_interop';

      @JS('Promise.reject')
      external void rejectPromise(JSAny? reason);

      @JS('Error')
      extension type JSError._(JSObject _) implements JSObject {
        external factory JSError(JSString message);
      }

      void main() {
        rejectPromise(JSError('unhandled rejection in sandbox'.toJS));
      }
    ''');

    final rejectionFuture = ctx.sandbox.unhandledRejections.first;

    await ctx.ws.writeFileFromText('pubspec.yaml', '''
      name: pad
      environment:
        sdk: ^3.11.0
    ''');
    await ctx.ws.pub(command: 'get');
    await ctx.sandbox.runMain('main.dart');

    await check(
      rejectionFuture,
    ).completes((r) => r.contains('unhandled rejection in sandbox'));
  });

  testDartIntegration('sandbox handles extension event', (ctx) async {
    await ctx.ws.writeFileFromText('main.dart', '''
      import 'dart:developer';

      void main() {
        postEvent('my.custom.event', {'foo': 'bar'});
      }
    ''');

    final eventFuture = ctx.sandbox.extensionEvents.first;

    await ctx.ws.writeFileFromText('pubspec.yaml', '''
      name: pad
      environment:
        sdk: ^3.11.0
    ''');
    await ctx.ws.pub(command: 'get');
    await ctx.sandbox.runMain('main.dart');

    await check(eventFuture).completes((r) {
      r.kind.equals('my.custom.event');
      r.data.deepEquals({'foo': 'bar', '__destinationStream': 'Extension'});
    });
  });

  testDartIntegration('sandbox handles invokeExtension', (ctx) async {
    await ctx.ws.writeFileFromText('main.dart', '''
      import 'dart:developer';
      import 'dart:convert';

      void main() {
        registerExtension('ext.dartpad.test', (method, parameters) async {
          return ServiceExtensionResponse.result(jsonEncode({'hello': 'world'}));
        });
        print('extension registered');
      }
    ''');

    await ctx.ws.writeFileFromText('pubspec.yaml', '''
      name: pad
      environment:
        sdk: ^3.11.0
    ''');
    await ctx.ws.pub(command: 'get');
    await ctx.sandbox.runMain('main.dart');

    // Wait for registration!
    await ctx.checkConsole((m) => m.contains('extension registered'));

    final response = await ctx.sandbox.invokeExtension('ext.dartpad.test', {});

    check(response).equals('{"hello":"world"}');
  });
}
