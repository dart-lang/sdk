// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../dtd.dart';

typedef DTDServiceCallback = Future<Map<String, Object?>> Function(
  Parameters params,
);

// TODO(danchevalier): add a serviceMethodIsAvailable experience. it will listen
// to a stream that announces servicemethods getting registered and
// unregistered. The state can then be presented as a listenable so that clients
// can gate their behaviour on a serviceMethod going up/down.

/// A connection to a Dart Tooling Daemon instance.
///
/// The base interactions for Dart Tooling Daemon are found here.
class DartToolingDaemon {
  /// Connects to a Dart Tooling Daemon instance over the provided
  /// [streamChannel].
  ///
  /// To over a WebSocket, the [DartToolingDaemon.connect] helper can be used.
  DartToolingDaemon.fromStreamChannel(StreamChannel<String> streamChannel)
      : _clientPeer = Peer(streamChannel) {
    _clientPeer.registerMethod(CoreDtdServiceConstants.streamNotify,
        (Parameters params) {
      try {
        final streamId = params[DtdParameters.streamId].asString;
        final eventKind = params[DtdParameters.eventKind].asString;
        final eventData =
            params[DtdParameters.eventData].asMap as Map<String, Object?>;
        final timestamp = params[DtdParameters.timestamp].asInt;

        _subscribedStreamControllers[streamId]?.add(
          DTDEvent(
            streamId,
            eventKind,
            eventData,
            timestamp,
          ),
        );
      } catch (e) {
        print('Error while handling streamNotify event: $e');
      }
    });

    _done = _clientPeer.listen();
  }

  /// Connects to a Dart Tooling Daemon instance.
  ///
  /// ```dart
  /// final uri = Uri.parse('ws://127.0.0.1:59247/em6ZgeqMpvV8tOKg');
  /// final client = DartToolingDaemon.connect(uri);
  /// ```
  static Future<DartToolingDaemon> connect(Uri uri) async {
    final channel = WebSocketChannel.connect(uri);
    await channel.ready;
    return DartToolingDaemon.fromStreamChannel(channel.cast<String>());
  }

  late final Peer _clientPeer;
  late final Future<void> _done;
  final _subscribedStreamControllers = <String, StreamController<DTDEvent>>{};

  /// Terminates the connection with the Dart Tooling Daemon.
  Future<void> close() => _clientPeer.close();

  /// A [Future] that completes when the connection with the Dart Tooling Daemon
  /// is terminated.
  Future<void> get done => _done;

  /// Whether or not the connection is closed.
  bool get isClosed => _clientPeer.isClosed;

  /// Registers this client as the handler for the [service].[method] service
  /// method.
  ///
  /// An optional map of [capabilities] can be supplied that will be provided
  /// to clients listening for `ServiceRegistered` events. The use of this field
  /// is service method specific.
  ///
  /// If the [service] has already been registered by another client, then an
  /// [RpcException] with [RpcErrorCodes.kServiceAlreadyRegistered] is thrown.
  /// Only one client at a time may register to a [service]. Once a client
  /// disconnects then another client may register services under than name.
  ///
  /// If the [method] has already been registered on the [service], then an
  /// [RpcException] with [RpcErrorCodes.kServiceMethodAlreadyRegistered] is
  /// thrown.
  Future<void> registerService(
    String service,
    String method,
    DTDServiceCallback callback, {
    Map<String, Object?>? capabilities,
  }) async {
    final combinedName = '$service.$method';
    await _clientPeer.sendRequest(CoreDtdServiceConstants.registerService, {
      DtdParameters.service: service,
      DtdParameters.method: method,
      if (capabilities != null) DtdParameters.capabilities: capabilities,
    });

    _clientPeer.registerMethod(
      combinedName,
      callback,
    );
  }

  /// Returns a structured response with all the currently registered services
  /// available on this DTD instance.
  Future<RegisteredServicesResponse> getRegisteredServices() async {
    final json = await _clientPeer.sendRequest(
      CoreDtdServiceConstants.getRegisteredServices,
    ) as Map<String, Object?>;

    final dtdResponse = _dtdResponseFromJson(json);
    return RegisteredServicesResponse.fromDTDResponse(dtdResponse);
  }

  /// Subscribes this client to events posted on [streamId].
  ///
  /// Once called, the Dart Tooling Daemon will then send any events on the
  /// [streamId] to this instance of [DartToolingDaemon]. See [onEvent] for
  /// details on how to get access to that [Stream] of [DTDEvent]s.
  ///
  /// If this client is already subscribed to [streamId], an [RpcException] with
  /// [RpcErrorCodes.kStreamAlreadySubscribed] will be thrown.
  Future<void> streamListen(String streamId) {
    return _clientPeer.sendRequest(
      CoreDtdServiceConstants.streamListen,
      {
        DtdParameters.streamId: streamId,
      },
    );
  }

  /// Cancel the subscription to [streamId].
  ///
  /// Once called, this connection will no longer receive events posted on
  /// [streamId].
  ///
  /// If this client was not subscribed to [streamId], an [RpcException] with
  /// [RpcErrorCodes.kStreamNotSubscribed] will be thrown.
  Future<void> streamCancel(String streamId) {
    return _clientPeer.sendRequest(
      CoreDtdServiceConstants.streamCancel,
      {
        DtdParameters.streamId: streamId,
      },
    );
  }

  /// Returns a broadcast [Stream] for events received on [streamId].
  ///
  /// This method should be called and a listener added before calling
  /// [streamListen] to ensure events aren't dropped.
  Stream<DTDEvent> onEvent(String streamId) {
    return _subscribedStreamControllers
        .putIfAbsent(
          streamId,
          StreamController<DTDEvent>.broadcast,
        )
        .stream;
  }

  /// Posts a [DTDEvent] with [eventData] to [streamId].
  ///
  /// The Dart Tooling Daemon will forward the [DTDEvent] to all clients that
  /// have subscribed to [streamId] by calling [streamListen].
  ///
  /// If no clients are listening to [streamId], the event will be dropped.
  Future<void> postEvent(
    String streamId,
    String eventKind,
    Map<String, Object?> eventData,
  ) async {
    await _clientPeer.sendRequest(
      CoreDtdServiceConstants.postEvent,
      {
        DtdParameters.streamId: streamId,
        DtdParameters.eventKind: eventKind,
        DtdParameters.eventData: eventData,
      },
    );
  }

  /// Invokes the service method registered with the name
  /// `[serviceName].[methodName]`, or with `[methodName]` when [serviceName] is
  /// null.
  ///
  /// [serviceName] may be null if the service method is a first party service
  /// method registered by DTD or by an internal service.
  ///
  /// If provided, [params] will be sent as the set of parameters used when
  /// invoking the service.
  ///
  /// If `[serviceName].[methodName]`, or `[methodName]` when [serviceName] is
  /// null, is not a registered service method, an [RpcException] will be thrown
  /// with [RpcErrorCodes.kMethodNotFound].
  ///
  /// If the parameters included in [params] are invalid, an [RpcException] will
  /// be thrown with [RpcErrorCodes.kInvalidParams].
  Future<DTDResponse> call(
    String? serviceName,
    String methodName, {
    Map<String, Object?>? params,
  }) async {
    final combinedName = [serviceName, methodName].nonNulls.join('.');
    final json = await _clientPeer.sendRequest(
      combinedName,
      params,
    ) as Map<String, Object?>;
    return _dtdResponseFromJson(json);
  }

  DTDResponse _dtdResponseFromJson(Map<String, Object?> json) {
    final type = json[DtdParameters.type] as String?;
    if (type == null) {
      throw DartToolingDaemonConnectionException.callResponseMissingType(json);
    }

    // TODO(danchevalier): Find out how to get access to the id.
    return DTDResponse('-1', type, json);
  }
}

/// Represents the response of an RPC call to the Dart Tooling Daemon.
class DTDResponse {
  DTDResponse(this._id, this._type, this._result);

  DTDResponse.fromDTDResponse(DTDResponse other)
      : this(
          other.id,
          other.type,
          other.result,
        );
  final String _id;
  final String _type;
  final Map<String, Object?> _result;

  String get id => _id;

  String get type => _type;

  Map<String, Object?> get result => _result;
}

/// A Dart Tooling Daemon stream event.
class DTDEvent {
  DTDEvent(this.stream, this.kind, this.data, this.timestamp);
  String stream;
  int timestamp;
  String kind;
  Map<String, Object?> data;

  @override
  String toString() {
    return jsonEncode({
      DtdParameters.stream: stream,
      DtdParameters.timestamp: timestamp,
      DtdParameters.kind: kind,
      DtdParameters.data: data,
    });
  }
}

class DartToolingDaemonConnectionException implements Exception {
  static const int callParamsMissingTypeError = 1;

  /// The response to a call method is missing the top level type parameter.
  factory DartToolingDaemonConnectionException.callResponseMissingType(
    Map<String, Object?> json,
  ) {
    return DartToolingDaemonConnectionException._(
      callParamsMissingTypeError,
      'call received an invalid response, '
      "it is missing the 'type' param. Got: $json",
    );
  }
  DartToolingDaemonConnectionException._(this.errorCode, this.message);

  @override
  String toString() => 'DartToolingDaemonConnectionException: $message';

  final int errorCode;
  final String message;
}
