// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import 'package:dartpad_worker/src/util/message_port.dart';
import 'package:path/path.dart' as p;
import 'package:vm_service/vm_service.dart';
import 'package:web/web.dart' as web;

import '../../integration_harness.dart';

void main() {
  testDartIntegration('sandbox startServiceProtocol and VM Service RPCs', (
    ctx,
  ) async {
    await ctx.ws.writeFileFromText('main.dart', '''
      import 'dart:convert';
      import 'dart:developer' as developer;

      void main() {
        developer.registerExtension('ext.dartpad.echo', (method, params) async {
          return developer.ServiceExtensionResponse.result(
            jsonEncode({'type': '_ExtensionType', 'echo': params['msg']}),
          );
        });
        developer.registerExtension('ext.dartpad.fail', (method, params) async {
          return developer.ServiceExtensionResponse.error(
            developer.ServiceExtensionResponse.extensionErrorMin,
            'custom extension failure',
          );
        });
        print('stdout from main');
        developer.log(
          'structured log message',
          name: 'my.logger',
          level: 800,
          sequenceNumber: 42,
          error: 'some error',
          stackTrace: StackTrace.current,
        );
        developer.postEvent('my.custom.event', {'count': 7});
      }
    ''');

    await ctx.ws.writeFileFromText('pubspec.yaml', '''
      name: pad
      environment:
        sdk: ^3.11.0
    ''');
    await ctx.ws.pub(command: 'get');

    // Connect VM service before run() to verify live event streams.
    final service = await ctx.sandbox.startServiceProtocol();
    try {
      final version = await service.getVersion();
      check(version.major).equals(4);

      check(service.onServiceEvent).withQueue.emitsThrough(
        .it()
          ..kind.equals(EventKind.kServiceRegistered)
          ..service.equals('hotRestart'),
      );

      await service.streamListen(EventStreams.kIsolate);
      await service.streamListen(EventStreams.kStdout);
      await service.streamListen(EventStreams.kLogging);
      await service.streamListen(EventStreams.kExtension);
      await service.streamListen(EventStreams.kService);

      check(service.onStdoutEvent).withQueue.emitsThrough(
        .it()..decodedBytes.contains('stdout from main'),
      );
      check(service.onLoggingEvent).withQueue.emitsThrough(
        .it()
          ..logRecord.isNotNull().which(
            .it()
              ..message.isNotNull().valueAsString.equals(
                'structured log message',
              )
              ..loggerName.isNotNull().valueAsString.equals('my.logger')
              ..level.equals(800)
              ..sequenceNumber.equals(42)
              ..error.isNotNull().valueAsString.equals('some error')
              ..stackTrace.isNotNull().valueAsString.isNotNull().contains(
                'main.dart',
              ),
          ),
      );
      check(service.onExtensionEvent).withQueue.emitsThrough(
        .it()
          ..extensionKind.equals('my.custom.event')
          ..extensionData.isNotNull().data.isNotNull().deepEquals({'count': 7}),
      );
      check(service.onIsolateEvent).withQueue.emitsThrough(
        .it()
          ..kind.equals(EventKind.kServiceExtensionAdded)
          ..extensionRPC.equals('ext.dartpad.echo'),
      );
      check(service.onIsolateEvent).withQueue.emitsThrough(
        .it()
          ..kind.equals(EventKind.kServiceExtensionAdded)
          ..extensionRPC.equals('ext.dartpad.fail'),
      );

      await ctx.sandbox.run('main.dart', mode: 'console');

      final vm = await service.getVM();
      check(vm.name).equals('WebSocketDebugProxy');
      check(vm.isolates).isNotNull().isNotEmpty;

      final isolateId = vm.isolates!.first.id!;
      final isolate = await service.getIsolate(isolateId);
      check(isolate.runnable).equals(true);
      check(isolate.pauseEvent?.kind).equals(EventKind.kResume);
      check(isolate.extensionRPCs).isNotNull().contains('ext.dartpad.echo');

      final scripts = await service.getScripts(isolateId);
      check(scripts.scripts).isNotNull().isEmpty;

      await check(
        service.getObject(isolateId, isolate.rootLib!.id!),
      ).throws<SentinelException>();

      await check(
        service.getObject(isolateId, 'objects/non-existent'),
      ).throws<SentinelException>();

      final mainFileUri = p.posix
          .toUri(p.posix.join(ctx.ws.workspaceFolder, 'main.dart'))
          .toString();
      final fooFileUri = p.posix
          .toUri(p.posix.join(ctx.ws.workspaceFolder, 'lib/foo.dart'))
          .toString();

      final resolvedUris = await service.lookupResolvedPackageUris(isolateId, [
        'workspace:///main.dart',
        'package:pad/foo.dart',
        'dart:core',
      ]);
      check(
        resolvedUris.uris,
      ).isNotNull().deepEquals([mainFileUri, fooFileUri, null]);

      final packageUris = await service.lookupPackageUris(isolateId, [
        mainFileUri,
        fooFileUri,
        'file:///other/bar.dart',
      ]);
      check(packageUris.uris).isNotNull().deepEquals([
        'workspace:///main.dart',
        'package:pad/foo.dart',
        null,
      ]);

      final flags = await service.getFlagList();
      check(flags.flags).isNotNull();

      final extRes = await service.callServiceExtension(
        'ext.dartpad.echo',
        isolateId: isolateId,
        args: {'msg': 'hello service protocol'},
      );
      check(extRes.json?['echo']).equals('hello service protocol');

      await check(
        service.callServiceExtension('ext.dartpad.fail', isolateId: isolateId),
      ).throws<RPCError>();

      await check(
        service.callServiceExtension(
          'ext.dartpad.unregistered',
          isolateId: isolateId,
        ),
      ).throws<RPCError>();

      // Connect a late subscriber after run() to verify DDS-style history
      // replay for Stdout, Logging, and Extension streams.
      final lateService = await ctx.sandbox.startServiceProtocol();
      try {
        check(lateService.onStdoutEvent).withQueue.emitsThrough(
          .it()..decodedBytes.contains('stdout from main'),
        );
        check(lateService.onLoggingEvent).withQueue.emitsThrough(
          .it()
            ..logRecord.isNotNull().message.isNotNull().valueAsString.equals(
              'structured log message',
            ),
        );
        check(lateService.onExtensionEvent).withQueue.emitsThrough(
          .it()..extensionKind.equals('my.custom.event'),
        );

        await lateService.streamListen(EventStreams.kStdout);
        await lateService.streamListen(EventStreams.kLogging);
        await lateService.streamListen(EventStreams.kExtension);
      } finally {
        await lateService.dispose();
      }
    } finally {
      await service.dispose();
    }
  });

  testDartIntegration(
    'sandbox connectServiceProtocol over web.MessageChannel and hotRestart',
    (ctx) async {
      await ctx.ws.writeFileFromText('main.dart', '''
        void main() {
          print('generation 1');
        }
      ''');

      await ctx.ws.writeFileFromText('pubspec.yaml', '''
        name: pad
        environment:
          sdk: ^3.11.0
      ''');
      await ctx.ws.pub(command: 'get');
      await ctx.sandbox.run('main.dart', mode: 'console');
      await ctx.checkConsole(.it()..contains('generation 1'));

      // Connect a second client via an explicit web.MessageChannel
      final channel = web.MessageChannel();
      await ctx.sandbox.connectServiceProtocol(
        MessagePortExt.fromMessagePort(channel.port2),
      );
      final clientPort = MessagePortExt.fromMessagePort(channel.port1);
      final clientChannel = clientPort.vmServiceChannel();
      final service = VmService(
        clientChannel.stream,
        (String message) => clientChannel.sink.add(message),
      );

      try {
        await service.streamListen(EventStreams.kIsolate);
        final vm1 = await service.getVM();
        final isolateId1 = vm1.isolates!.first.id!;
        check(isolateId1).equals('isolates/1');

        await ctx.ws.writeFileFromText('main.dart', '''
          void main() {
            print('generation 2');
          }
        ''');

        check(service.onIsolateEvent).withQueue.emitsThrough(
          .it()
            ..kind.equals(EventKind.kIsolateExit)
            ..isolate.isNotNull().id.equals('isolates/1'),
        );
        check(service.onIsolateEvent).withQueue.emitsThrough(
          .it()
            ..kind.equals(EventKind.kIsolateStart)
            ..isolate.isNotNull().id.equals('isolates/2'),
        );

        await ctx.sandbox.hotRestart();
        await ctx.checkConsole(.it()..contains('generation 2'));

        final vm2 = await service.getVM();
        check(vm2.isolates!.first.id).equals('isolates/2');
      } finally {
        await service.dispose();
        await clientChannel.sink.close();
      }
    },
  );
}
