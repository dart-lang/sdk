// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Directory, File, Platform;
import 'dart:isolate';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';

import 'asset_server.dart';
import 'package.dart';

void hybridMain(StreamChannel<Object?> channel, Object? initialMessage) async {
  final peer = Peer(
    channel.cast(),
    onUnhandledError: (e, st) => print('AssetServer.hybridMain: $e\n$st'),
  );
  if (initialMessage is! Map<String, Object?>) {
    initialMessage = const <String, Object?>{};
  }

  // Avoid blocking printOnFailure, if we're not listening on peer
  var isListeningOnPeer = false;
  Future<void> printOnFailure(String message) async {
    if (isListeningOnPeer) {
      await peer.sendRequest('printOnFailure', {'message': message});
    } else {
      peer.sendNotification('printOnFailure', {'message': message});
    }
  }

  final buildRoot = Uri.file(
    Platform.environment['resolvedExecutable'] ?? Platform.resolvedExecutable,
  ).resolve('../../');
  final projectRoot = Isolate.resolvePackageUriSync(
    Uri.parse('package:dartpad_worker/'),
  )!.resolve('../');
  final packageArchiveFolder = projectRoot.resolve(
    '.dart_tool/dartpad_worker/packages/',
  );
  final flutterAssetPath = projectRoot.resolve(
    '.dart_tool/dartpad_worker/asset/flutter/',
  );

  final hasFlutter =
      Directory.fromUri(packageArchiveFolder).existsSync() &&
      Directory.fromUri(flutterAssetPath).existsSync();

  final server = await AssetServer.listen(
    printOnFailure: printOnFailure,
    dartAssetPath: buildRoot.resolve('dartpad/'),
    flutterAssetPath: hasFlutter ? flutterAssetPath : null,
  );

  peer.registerMethod('addPackage', (Parameters params) async {
    final f = params['files'].asMap;
    final files = f.map((k, v) {
      if (k is! String || v is! String) {
        throw RpcException.invalidParams('files must be a Map<String, String>');
      }
      return MapEntry(k, v);
    });

    try {
      server.addPackage(await Package.fromFileMap(files));
    } on FormatException catch (e) {
      throw RpcException.invalidParams(
        'invalid package in files: ${e.message}',
      );
    }
  });

  server.addPackage(
    await Package.fromFileMap({
      'pubspec.yaml': '''{
        "name": "foo",
        "version": "1.0.0",
        "environment": {"sdk": "^3.10.0"}
      }
      ''',
      'README.md': '# foo for dart',
      'lib/foo.dart': '''
        void sayHello() => print('Hello world');
      ''',
    }),
  );

  if (hasFlutter) {
    await Future.wait(
      Directory.fromUri(packageArchiveFolder).listSync().whereType<File>().map(
        (f) async =>
            server.addPackage(await Package.fromArchive(await f.readAsBytes())),
      ),
    );
  }

  peer.sendNotification('ready', {
    'baseUrl': server.baseUrl.toString(),
    'hasFlutter': hasFlutter,
  });

  try {
    isListeningOnPeer = true;
    await peer.listen();
  } finally {
    isListeningOnPeer = false;
    await server.close();
  }
}
