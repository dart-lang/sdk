// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// For ClientName response type.
import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:vm_service/vm_service.dart';

import 'clients.dart';
import 'dart_runtime_service.dart';
import 'event_streams.dart';
import 'rpc_exceptions.dart';
import 'utils.dart';

typedef RpcResponse = Map<String, Object?>;
typedef RpcHandlerWithNoParameters = FutureOr<RpcResponse> Function();
typedef RpcHandlerWithParameters =
    FutureOr<RpcResponse> Function(json_rpc.Parameters);

/// Manages requests made to platform-agnostic RPCs provided by
/// [DartRuntimeService] by a single [Client].
final class DartRuntimeServiceRpcs {
  DartRuntimeServiceRpcs({
    required this.clients,
    required this.eventStreamMethods,
    required this.client,
  });

  /// The current set of clients connected to the service.
  final UnmodifiableNamedLookup<Client> clients;

  /// Wrapper for methods used to interact with event stream state.
  final EventStreamMethods eventStreamMethods;

  /// The client sending and receiving RPCs.
  final Client client;

  // Parameters for [registerService].
  static const _kService = 'service';
  static const _kAlias = 'alias';

  // Parameters for streamListen
  static const _kStreamId = 'streamId';

  late final _commonRpcs = <(String, Function)>[
    ('getClientName', getClientName),
    ('registerService', registerService),
    ('setClientName', setClientName),
    ('streamCancel', streamCancel),
    ('streamListen', streamListen),
  ];

  /// Registers the set of platform-agnostic RPCs for use by [client].
  void registerRpcsWithPeer(json_rpc.Peer clientPeer) {
    for (final (method, callback) in _commonRpcs) {
      if (callback is! RpcHandlerWithNoParameters &&
          callback is! RpcHandlerWithParameters) {
        throw StateError("Callback for '$method' is not valid. ($callback).");
      }

      clientPeer.registerMethod(method, (json_rpc.Parameters parameters) async {
        try {
          late RpcResponse response;
          if (callback is RpcHandlerWithNoParameters) {
            client.logger.info('Invoked $method');
            response = await callback();
            client.logger.info('Response: $response');
          } else if (callback is RpcHandlerWithParameters) {
            client.logger.info('Invoked $method (${parameters.value})');
            response = await callback(parameters);
            client.logger.info('Response: $response');
          }
          return response;
        } catch (e) {
          client.logger.info('Exception thrown when invoking $method: $e');
          rethrow;
        }
      });
    }

    clientPeer.registerFallback(serviceExtensionForwarderFallback);
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

  /// When invoked within a fallback, the next fallback will start executing.
  Never _nextFallback() => RpcException.methodNotFound.throwException();

  /// Fallback responsible for handling client registered service extension
  /// invocations.
  ///
  /// If `parameters.method` is not of the form `<namespace>.<method>` or
  /// there's no matching service extension, [_nextFallback] is invoked to
  /// execute the next fallback (or return a method not found error if this is
  /// the last fallback).
  Future<RpcResponse> serviceExtensionForwarderFallback(
    json_rpc.Parameters parameters,
  ) async {
    final method = parameters.method;
    (String, String)? getNamespaceAndService() {
      if (method.split('.') case [final namespace, final service]) {
        return (namespace, service);
      }
      return null;
    }

    final serviceInfo = getNamespaceAndService();
    if (serviceInfo == null) {
      _nextFallback();
    }
    final (namespace, service) = serviceInfo;

    // Lookup the client associated with the service extension's namespace.
    // If the client exists and that client has registered the specified
    // method, forward the request to that client.
    final serviceClient = clients[namespace];
    if (serviceClient != null && serviceClient.hasService(service)) {
      client.logger.info(
        'Invoking $method provided by ${serviceClient.name} with '
        '${parameters.value}.',
      );
      try {
        final response = await Future.any([
          // Forward the request to the service client or...
          serviceClient.sendRequest(
            method: service,
            parameters: parameters.asMap.cast<String, Object?>(),
          ),
          // if the service client closes, return an error response.
          serviceClient.done.then<RpcResponse>(
            (_) => RpcException.serviceDisappeared.throwException(),
          ),
        ]);
        client.logger.info('$method responded with: $response');
        return response;
      } on json_rpc.RpcException catch (e) {
        if (e.code == RpcException.serviceDisappeared.code) {
          client.logger.info(
            '$method provided by ${serviceClient.name} has disappeared.',
          );
        }
        rethrow;
      }
    }
    client.logger.info('Failed to find client that handles $method.');
    _nextFallback();
  }

  /// Registers a service extension that is handled by this client.
  ///
  /// Client-based service extensions (not to be confused with service
  /// extensions registered via `dart:developer`'s `registerServiceExtension`)
  /// are invoked by calling methods of the form `<namespace>.<service>`, where
  /// `namespace` is a unique identifier associated with the [Client] providing
  /// the service.
  ///
  /// If a client attempts to register a service name that's already associated
  /// with the namespace, an error response is returned.
  RpcResponse registerService(json_rpc.Parameters parameters) {
    final service = parameters[_kService].asString;
    final alias = parameters[_kAlias].asString;
    if (!client.registerService(service: service, alias: alias)) {
      RpcException.serviceAlreadyRegistered.throwException();
    }
    return Success().toJson();
  }

  /// Subscribes this client to events on the specified stream.
  ///
  /// If the stream ID corresponds with a stream that's already subscribed to
  /// by this client, an error response is returned.
  ///
  /// If the stream ID does not correspond with a known stream, an error
  /// response may be returned.
  RpcResponse streamListen(json_rpc.Parameters parameters) {
    final stream = parameters[_kStreamId].asString;
    eventStreamMethods.streamListen(client: client, streamId: stream);
    return Success().toJson();
  }

  /// Cancels this client's subscription to the specified stream.
  ///
  /// If the stream ID corresponds with a stream that's not subscribed to by
  /// this client, an error response is returned.
  ///
  /// If the stream ID does not correspond with a known stream, an error
  /// response may be returned.
  RpcResponse streamCancel(json_rpc.Parameters parameters) {
    final streamId = parameters[_kStreamId].asString;
    eventStreamMethods.streamCancel(client: client, streamId: streamId);
    return Success().toJson();
  }
}
