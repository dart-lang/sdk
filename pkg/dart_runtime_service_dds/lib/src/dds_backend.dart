// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:shelf_proxy/shelf_proxy.dart';
import 'package:vm_service/vm_service.dart' as vm;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'dds_isolate_manager.dart';
import 'dds_rpcs.dart';

/// A [DartRuntimeServiceBackend] implementation that provides the Dart
/// Development Service (DDS) for a remote VM Service.
class DartRuntimeServiceDdsBackend
    extends DartRuntimeServiceBackend<DdsIsolateManager> {
  /// Creates a new [DartRuntimeServiceDdsBackend] connecting to the VM
  /// Service at [remoteVmServiceUri].
  DartRuntimeServiceDdsBackend(
    this.remoteVmServiceUri, {
    required super.frontend,
  });

  /// The [Uri] of the target VM Service.
  final Uri remoteVmServiceUri;

  late final DdsIsolateManager _isolateManager;
  late final WebSocketChannel _webSocketChannel;
  late final vm.VmService _vmServiceClient;
  late final DdsRpcHandlers _rpcHandlers;

  @override
  DdsIsolateManager get isolateManager => _isolateManager;

  vm.VmService get vmServiceClient => _vmServiceClient;

  @override
  late final OptionalHandler httpHandler;

  @override
  Future<void> initialize() async {
    final wsUri = _convertToWebSocketUri(remoteVmServiceUri);
    _webSocketChannel = WebSocketChannel.connect(wsUri);

    _vmServiceClient = vm.VmService(
      _webSocketChannel.stream.cast<String>(),
      (String message) => _webSocketChannel.sink.add(message),
    );

    _isolateManager = DdsIsolateManager(
      backend: this,
      vmServiceClient: _vmServiceClient,
    );
    await _isolateManager.initializeIsolates();

    _rpcHandlers = DdsRpcHandlers(this);

    httpHandler = proxyHandler(remoteVmServiceUri);
  }

  @override
  Future<void> onServiceReady(DartRuntimeService service) async {}

  @override
  Future<void> shutdown() async {
    await _vmServiceClient.dispose();
    await _webSocketChannel.sink.close();
  }

  @override
  Future<void> clearState() async {}

  @override
  Future<void> onServerStarted({
    required Uri httpUri,
    required Uri wsUri,
  }) async {}

  @override
  Future<void> onServerShutdown() async {}

  Uri _convertToWebSocketUri(Uri uri) {
    var scheme = uri.scheme;
    if (uri.isScheme('http')) {
      scheme = 'ws';
    } else if (uri.isScheme('https')) {
      scheme = 'wss';
    }
    var path = uri.path;
    if (!path.endsWith('/ws')) {
      if (path.endsWith('/')) {
        path = '${path}ws';
      } else {
        path = '$path/ws';
      }
    }
    return uri.replace(scheme: scheme, path: path);
  }

  @override
  UnmodifiableListView<ServiceRpcHandler> get rpcs => _rpcHandlers.rpcs;

  @override
  UnmodifiableListView<RpcHandlerWithParameters> get fallbacks =>
      UnmodifiableListView([forwardToRemoteVmService]);

  Future<RpcResponse> forwardToRemoteVmService(json_rpc.Parameters params) {
    return callVmService(
      params.method,
      args: params.value == null ? null : params.asMap.cast<String, Object?>(),
    );
  }

  Future<RpcResponse> callVmService(
    String method, {
    Map<String, Object?>? args,
  }) async {
    try {
      final response = await _vmServiceClient.callMethod(method, args: args);
      return response.toJson();
    } on vm.SentinelException catch (e) {
      return e.sentinel.toJson();
    } on vm.RPCError catch (e) {
      throw json_rpc.RpcException(e.code, e.message, data: e.data);
    }
  }
}
