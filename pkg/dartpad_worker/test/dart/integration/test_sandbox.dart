// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import 'package:vm_service/vm_service.dart';

import '../../integration_harness.dart';

void main() {
  testDartIntegration('sandbox can run code', (ctx) async {
    await ctx.ws.writeFileFromText('main.dart', '''
      import 'dart:developer' as developer;

      class _Item {
        @override
        String toString() => 'custom-item';
      }

      void main() {
        print('Hello World');
        developer.inspect([_Item()]);
      }
    ''');

    await ctx.ws.writeFileFromText('pubspec.yaml', '''
      name: pad
      environment:
        sdk: ^3.11.0
    ''');
    await ctx.ws.pub(command: 'get');
    await ctx.sandbox.run('main.dart', mode: 'console');

    await ctx.checkConsole(.it()..contains('Hello World'));
    await ctx.checkConsole(.it()..equals('[custom-item]'), level: .debug);

    // Closing the iframe triggers pagehide in sandbox.js, which posts null on
    // the sandbox MessagePort and closes the sandbox in the worker.
    await ctx.iframe.close();
    await check(ctx.sandbox.hotReload()).throws<SandboxNotFoundException>();
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

    await ctx.ws.writeFileFromText('pubspec.yaml', '''
      name: pad
      environment:
        sdk: ^3.11.0
    ''');
    await ctx.ws.pub(command: 'get');
    await ctx.sandbox.run('main.dart', mode: 'console');

    // The message of the Dart exception, not just the bare `Error` that V8
    // captured before DDC filled it in. See `renderError` in `sandbox.js`.
    await ctx.checkConsole(
      .it()..contains('Exception: uncaught error in sandbox'),
      level: .error,
    );
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

    await ctx.ws.writeFileFromText('pubspec.yaml', '''
      name: pad
      environment:
        sdk: ^3.11.0
    ''');
    await ctx.ws.pub(command: 'get');
    await ctx.sandbox.run('main.dart', mode: 'console');

    await ctx.checkConsole(
      .it()..contains('unhandled rejection in sandbox'),
      level: .error,
    );
  });

  testDartIntegration('sandbox handles extension event', (ctx) async {
    await ctx.ws.writeFileFromText('main.dart', '''
      import 'dart:developer';

      void main() {
        postEvent('my.custom.event', {'foo': 'bar'});
      }
    ''');

    final service = await ctx.sandbox.startServiceProtocol();
    await service.streamListen(EventStreams.kExtension);
    check(service.onExtensionEvent).withQueue.emitsThrough(
      .it()
        ..extensionKind.equals('my.custom.event')
        ..extensionData.isNotNull().data.isNotNull().deepEquals({'foo': 'bar'}),
    );

    await ctx.ws.writeFileFromText('pubspec.yaml', '''
      name: pad
      environment:
        sdk: ^3.11.0
    ''');
    await ctx.ws.pub(command: 'get');
    await ctx.sandbox.run('main.dart', mode: 'console');
    await service.dispose();
  });

  testDartIntegration('sandbox handles callServiceExtension', (ctx) async {
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
    await ctx.sandbox.run('main.dart', mode: 'console');

    // Wait for registration!
    await ctx.checkConsole(.it()..contains('extension registered'));

    final service = await ctx.sandbox.startServiceProtocol();
    final vm = await service.getVM();
    final isolateId = vm.isolates!.first.id!;
    final response = await service.callServiceExtension(
      'ext.dartpad.test',
      isolateId: isolateId,
    );

    check(response.json?['hello']).equals('world');
    await service.dispose();
  });

  testDartIntegration(r'sandbox $dartpadWorkspace', (ctx) async {
    await ctx.ws.writeFileFromText('assets/hello.txt', 'hello');
    await ctx.ws.writeFileFromText('main.dart', r'''
      import 'dart:js_interop';

      @JS(r'$dartpadWorkspace')
      external _DartPadWorkspace get _workspace;

      extension type _DartPadWorkspace._(JSObject _) implements JSObject {
        external String? get packageRoot;
        external JSPromise<JSString> readFileAsText(String path);
        external JSPromise<JSUint8Array> readFileAsBytes(String path);
        external JSPromise<_Stat> stat(String path);
        external JSPromise<JSArray<_Entry>> listDirectory(String path);
        external JSPromise<_Package?> resolvePackage(String package);
      }

      extension type _Stat._(JSObject _) implements JSObject {
        external String get type;
        external int? get size;
      }

      extension type _Entry._(JSObject _) implements JSObject {
        external String get path;
        external String get type;
      }

      extension type _Package._(JSObject _) implements JSObject {
        external String get name;
        external String get rootPath;
        external String get packagePath;
        external String get languageVersion;
      }

      Future<void> main() async {
        print('packageRoot=${_workspace.packageRoot}');
        final text = (await _workspace.readFileAsText('assets/hello.txt').toDart).toDart;
        print('text=$text');
        final bytes = (await _workspace.readFileAsBytes('assets/hello.txt').toDart).toDart;
        print('bytes=$bytes');
        final s = await _workspace.stat('assets/hello.txt').toDart;
        print('stat=${s.type}:${s.size}');
        final entries = (await _workspace.listDirectory('assets').toDart).toDart;
        print('entries=${entries.map((e) => '${e.path}:${e.type}').join(',')}');
        final pkg = await _workspace.resolvePackage('pad').toDart;
        print('pkg=${pkg?.name}:${pkg?.rootPath}:${pkg?.packagePath}:${pkg?.languageVersion}');
        final missing = await _workspace.resolvePackage('unknown').toDart;
        print('missing=$missing');
      }
    ''');

    await ctx.ws.writeFileFromText('pubspec.yaml', '''
      name: pad
      environment:
        sdk: ^3.11.0
    ''');
    await ctx.ws.pub(command: 'get');
    await ctx.sandbox.run('main.dart', mode: 'console');

    await ctx.checkConsole(
      .it()..equals('packageRoot=${ctx.ws.workspaceFolder}'),
    );
    await ctx.checkConsole(.it()..equals('text=hello'));
    await ctx.checkConsole(.it()..equals('bytes=[104, 101, 108, 108, 111]'));
    await ctx.checkConsole(.it()..equals('stat=file:5'));
    await ctx.checkConsole(.it()..equals('entries=hello.txt:file'));
    await ctx.checkConsole(
      .it()..equals(
        'pkg=pad:${ctx.ws.workspaceFolder}:'
        '${ctx.ws.workspaceFolder}/lib:3.11',
      ),
    );
    await ctx.checkConsole(.it()..equals('missing=null'));
  });
}
