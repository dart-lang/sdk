// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/stream_channel.dart';
import 'package:vm_service/vm_service.dart';

/// Invokes [onHotReload] and formats the result (or any thrown error) as a VM
/// Service [ReloadReport] JSON response.
///
/// Note that `package:vm_service`'s `ReloadReport.toJson()` drops the `notices`
/// field, so failure notices are merged into the returned map.
Future<RpcResponse> reloadSourcesRpc(
  Future<void> Function() onHotReload,
) async {
  try {
    await onHotReload();
    return ReloadReport(success: true).toJson();
  } on Object catch (e) {
    return <String, Object?>{
      ...ReloadReport(success: false).toJson(),
      'notices': [
        {'type': 'ReasonForCancelling', 'message': e.toString()},
      ],
    };
  }
}

/// Attaches an internal VM Service client (analogous to `flutter_tools` or
/// DWDS's `DwdsVmClient`) to [service] via
/// [DartRuntimeService.addArtificialClient] and registers runner-level
/// services (`reloadSources`, `hotRestart`, and `flutterVersion`).
///
/// When external clients such as DevTools subscribe to the `Service` stream,
/// [DartRuntimeService] advertises these services as `ServiceRegistered` events
/// under this client's namespace (e.g. `s0.reloadSources`, `s0.hotRestart`,
/// `s0.flutterVersion`) and routes invocations back to this peer.
///
/// When [service] shuts down, its `ClientManager` closes the artificial client
/// connection, which automatically closes the local [json_rpc.Peer].
void attachDartPadRunnerClient({
  required DartRuntimeService service,
  required Future<void> Function() onHotReload,
  required Future<void> Function() onHotRestart,
  required Map<String, Object?>? flutterVersion,
}) {
  final controller = StreamChannelController<String>();
  final client = service.addArtificialClient(
    connection: controller.foreign,
    name: 'DartPad',
  );
  final peer = json_rpc.Peer(controller.local)
    ..registerMethod(
      'reloadSources',
      (json_rpc.Parameters _) => reloadSourcesRpc(onHotReload),
    )
    ..registerMethod('hotRestart', (json_rpc.Parameters _) async {
      await onHotRestart();
      return Success().toJson();
    });

  client
    ..registerService(service: 'reloadSources', alias: 'DartPad Hot Reload')
    ..registerService(service: 'hotRestart', alias: 'DartPad Hot Restart');

  if (flutterVersion != null) {
    peer.registerMethod(
      'flutterVersion',
      (json_rpc.Parameters _) => flutterVersion,
    );
    client.registerService(
      service: 'flutterVersion',
      alias: 'DartPad Flutter Version',
    );
  }

  unawaited(peer.listen());
}
