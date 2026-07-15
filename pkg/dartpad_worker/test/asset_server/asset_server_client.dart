// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:test/test.dart' show printOnFailure, spawnHybridUri;

final class AssetServerClient {
  final Peer _peer;

  /// BaseUrl for the server
  final Uri baseUrl;

  /// Whether the server has Flutter assets and packages available
  final bool hasFlutter;

  final Completer<void> _closed;

  bool get isClosed => _closed.isCompleted;

  AssetServerClient._(
    this._peer,
    this._closed, {
    required this.baseUrl,
    required this.hasFlutter,
  });

  /// Spawn a `AssetServerClient` using [spawnHybridUri] from `package:test`.
  static Future<AssetServerClient> spawnHybrid({bool stayAlive = false}) async {
    final channel = spawnHybridUri(
      '/test/asset_server/asset_server_main.dart',
      message: <String, Object?>{},
      stayAlive: stayAlive,
    );
    final peer = Peer(
      channel.cast(),
      onUnhandledError: (e, st) => print('AssetServerClient: $e\n$st'),
    );

    peer.registerMethod('printOnFailure', (Parameters param) async {
      printOnFailure(param['message'].asString);
    });

    final ready = Completer<({Uri baseUrl, bool hasFlutter})>();
    peer.registerMethod('ready', (Parameters param) async {
      final baseUrl = Uri.parse(param['baseUrl'].asString);
      final hasFlutter = param['hasFlutter'].asBool;
      ready.complete((baseUrl: baseUrl, hasFlutter: hasFlutter));
    });

    final closed = Completer<void>();
    unawaited(() async {
      try {
        await peer.listen();
      } finally {
        closed.complete();
      }
    }());

    final (:baseUrl, :hasFlutter) = await ready.future;

    return AssetServerClient._(
      peer,
      closed,
      baseUrl: baseUrl,
      hasFlutter: hasFlutter,
    );
  }

  Future<void> addPackage(Map<String, String> files) async {
    await _peer.sendRequest('addPackage', {'files': files});
  }

  Future<void> close() async {
    await _peer.close();
  }
}
