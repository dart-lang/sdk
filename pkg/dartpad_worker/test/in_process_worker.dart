// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:dartpad/src/message_port/message_port.dart';
import 'package:dartpad/src/worker_client.dart';
import 'package:dartpad_worker/src/worker.dart';
import 'package:http/http.dart' as http;
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import 'asset_server/asset_server_client.dart';

/// Create a worker in the same process.
Future<WorkerClient> createInprocessWorker(
  AssetServerClient server,
  String sdkPath,
) async {
  final sdkTarUri = server.baseUrl.resolve('$sdkPath/sdk.tar');
  final r = await http.get(sdkTarUri);
  if (r.statusCode != 200) {
    fail('Unable to fetch "$sdkTarUri" (${r.statusCode})');
  }

  final sdkTar = r.bodyBytes;
  final worker = await Worker.create(
    Stream.value(sdkTar),
    pubHostedUrl: server.baseUrl.toString(),
  );
  final channelController = StreamChannelController<Object?>();

  worker.session(
    channelController.foreign.transform(_asyncStreamChannelTransform),
  );
  return WorkerClient(
    channelController.local.transform(_asyncStreamChannelTransform),
  );
}

final _asyncStreamChannelTransform = StreamChannelTransformer(
  StreamTransformer.fromBind((Stream<Object?> messages) async* {
    await for (final m in messages) {
      await Future<void>.delayed(Duration.zero);
      yield _jsonify(m);
    }
  }),
  StreamSinkTransformer.fromStreamTransformer(
    StreamTransformer.fromBind((Stream<Object?> messages) async* {
      await for (final m in messages) {
        await Future<void>.delayed(Duration.zero);
        yield _jsonify(m);
      }
    }),
  ),
);

Object? _jsonify(Object? obj) {
  if (obj is MessagePort ||
      obj == null ||
      obj is String ||
      obj is num ||
      obj is bool) {
    return obj;
  }
  if (obj is Map) {
    return <String, Object?>{
      for (final e in obj.entries) e.key as String: _jsonify(e.value),
    };
  }
  if (obj is List) {
    return <Object?>[for (final e in obj) _jsonify(e)];
  }
  try {
    return _jsonify((obj as dynamic).toJson());
    // ignore: avoid_catching_errors
  } on NoSuchMethodError {
    // Ignore if toJson doesn't exist
  }
  throw AssertionError('Cannot jsonify $obj (${obj.runtimeType})');
}
