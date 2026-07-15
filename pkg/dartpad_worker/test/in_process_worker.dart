// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  worker.session(channelController.foreign.cast());
  return WorkerClient(channelController.local.cast());
}
