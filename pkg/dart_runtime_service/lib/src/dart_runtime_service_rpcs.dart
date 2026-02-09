// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// For ClientName response type.
import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:logging/logging.dart';
import 'package:vm_service/vm_service.dart';

import 'clients.dart';
import 'dart_runtime_service.dart';

typedef RpcResponse = Map<String, Object?>;
typedef RpcHandlerWithNoParameters = FutureOr<RpcResponse> Function();
typedef RpcHandlerWithParameters =
    FutureOr<RpcResponse> Function(json_rpc.Parameters);

/// Manages requests made to platform-agnostic RPCs provided by
/// [DartRuntimeService] by a single [Client].
final class DartRuntimeServiceRpcs {
  DartRuntimeServiceRpcs({required this.client});

  /// The client sending and receiving RPCs.
  final Client client;

  final _logger = Logger('$DartRuntimeServiceRpcs');
  late final _commonRpcs = <(String, Function)>[
    ('getClientName', getClientName),
    ('setClientName', setClientName),
  ];

  /// Registers the set of platform-agnostic RPCs for use by [client].
  void registerRpcsWithPeer(json_rpc.Peer clientPeer) {
    for (final (method, callback) in _commonRpcs) {
      if (callback is! RpcHandlerWithNoParameters &&
          callback is! RpcHandlerWithParameters) {
        throw StateError("Callback for '$method' is not valid. ($callback).");
      }

      clientPeer.registerMethod(method, (json_rpc.Parameters parameters) async {
        late RpcResponse response;
        if (callback is RpcHandlerWithNoParameters) {
          _logger.info('(${client.name}) invoked $method');
          response = await callback();
          _logger.info('(${client.name}) response: $response');
        } else if (callback is RpcHandlerWithParameters) {
          _logger.info(
            '(${client.name}) invoked $method (${parameters.value})',
          );
          response = await callback(parameters);
          _logger.info('(${client.name}) response: $response');
        }
        return response;
      });
    }
  }

  /// Attempts to [parse] [parameters] into an instance of [T].
  ///
  /// If [parameters] can't be parsed, a [json_rpc.RpcException] is thrown
  /// and returned to the requesting client as an error response.
  T _tryParse<T extends Response>(
    T? Function(Map<String, Object?>) parse,
    json_rpc.Parameters parameters,
  ) {
    final result = parse(parameters.asMap.cast<String, Object?>());
    if (result == null) {
      throw json_rpc.RpcException.invalidParams(
        'Unable to create $T from ${parameters.value}',
      );
    }
    return result;
  }

  /// Returns the current name of [client].
  RpcResponse getClientName() => ClientName(name: client.name).toJson();

  /// Sets the name of the [client].
  RpcResponse setClientName(json_rpc.Parameters parameters) {
    final clientName = _tryParse(ClientName.parse, parameters);
    client.setName(clientName.name.isEmpty ? null : clientName.name);
    return Success().toJson();
  }
}
