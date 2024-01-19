// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';

typedef DTDServiceCallback = Future<Map<String, Object?>> Function(
  Parameters params,
);

// TODO(danchevalier): add a serviceMethodIsAvailable experience. it will listen
// to a stream that announces servicemethods getting registered and
// unregistered. The state can then be presented as a listenable so that clients
// can gate their behaviour on a serviceMethod going up/down.

// TODO(danchevalier) dart docs
class DTDConnection {
  late final Peer _clientPeer;
  late final Future _done;
  final _subscribedStreamControllers = <String, StreamController<DTDEvent>>{};

  DTDConnection(this._connectionChannel)
      : _clientPeer = Peer(_connectionChannel.cast<String>()) {
    _clientPeer.registerMethod('streamNotify', (Parameters params) {
      final streamId = params['streamId'].value as String;
      final event = params['event'];
      final eventKind = event['eventKind'].value as String;
      final eventData = event['eventData'].value as Map<String, Object?>;
      final timestamp = event['timestamp'].value as int;

      _subscribedStreamControllers[streamId]?.add(
        DTDEvent(streamId, eventKind, eventData, timestamp),
      );
    });

    _done = _clientPeer.listen();
  }

  /// Terminates the connection with the Dart Tooling Daemon.
  Future<void> close() => _clientPeer.close();

  /// A `Future` that completes when the connection with the Dart Tooling Daemon
  /// is terminated.
  Future<void> get done => _done;

  /// Returns the current list of services available.
  Future<List<String>> getRegisteredServices() async {
    return await _clientPeer.sendRequest(
      'getRegisteredServices',
    ) as List<String>;
  }

  /// Returns the current list of streams with active subscribers.
  Future<List<String>> getRegisteredStreams() async {
    return await _clientPeer.sendRequest(
      'getRegisteredStreams',
    ) as List<String>;
  }

  Future<void> registerService(
    String service,
    String method,
    DTDServiceCallback callback,
  ) async {
    final combinedName = '$service.$method';
    await _clientPeer.sendRequest('registerService', {
      'service': service,
      'method': method,
    });

    _clientPeer.registerMethod(
      combinedName,
      callback,
    );
  }

  /// Subscribes this client to events posted on [streamId].
  ///
  /// If this client is already subscribed to [streamId], an exception will be
  /// thrown.
  Future<void> streamListen(String streamId) {
    // TODO(@danchevalier)
    return _clientPeer.sendRequest(
      'streamListen',
      {
        'streamId': streamId,
      },
    );
  }

  /// Cancel the subscription to [streamId].
  ///
  /// Once called, this connection will no longer receive events posted on
  /// [streamId].
  ///
  /// If this client was not subscribed to [streamId], an exception will be
  /// thrown.
  Future<void> streamCancel(Stream streamId) {
    // TODO(@danchevalier)
    return _clientPeer.sendRequest(
      'streamCancel',
      {
        'streamId': streamId,
      },
    );
  }

  /// Creates a `Stream` for events received on [streamId].
  ///
  /// This method should be called before calling [streamListen] to ensure
  /// events aren't dropped. [streamListen(streamId)] must be called before any
  /// events will appear on the returned stream.
  Stream<DTDEvent> onEvent(String streamId) {
    return _subscribedStreamControllers
        .putIfAbsent(
          streamId,
          StreamController<DTDEvent>.new,
        )
        .stream;
  }

  /// Posts an [DTDEvent] with [eventData] to [streamId].
  ///
  /// If no clients are subscribed to [streamId], the event will be dropped.
  void postEvent(
    String streamId,
    String eventKind,
    Map<String, Object?> eventData,
  ) {
    _clientPeer.sendRequest(
      'postEvent',
      {
        'streamId': streamId,
        'eventKind': eventKind,
        'eventData': eventData,
      },
    );
  }

  /// Invokes a service with the name `serviceName.methodName`.
  ///
  /// If provided, [params] will be sent as the set of parameters used when
  /// invoking the service.
  ///
  /// If `serviceName.methodName` is not a valid service, an exception will be
  /// thrown.
  ///
  /// If the parameters included in [params] are invalid, an exception will be
  /// thrown.
  Future<DTDResponse> call(
    String serviceName,
    String methodName, {
    Map<String, Object>? params,
  }) async {
    final json = await _clientPeer.sendRequest(
      '$serviceName.$methodName',
      params ?? <String, dynamic>{},
    ) as Map<String, Object?>;

    final type = json['type'] as String?;
    if (type == null) {
      throw DTDConnectionException.callResponseMissingType(json);
    }

    //TODO(danchevalier): Find out how to get access to the id.
    return DTDResponse('-1', type, json);
  }

  // ignore: unused_field
  final StreamChannel _connectionChannel;
}

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

// TODO(@danchevalier): is this how event should be done?
class DTDEvent {
  DTDEvent(this.stream, this.kind, this.data, this.timestamp);
  String stream;
  int timestamp;
  String kind;
  Map<String, Object?> data;

  @override
  String toString() {
    return jsonEncode({
      'stream': stream,
      'timestamp': timestamp,
      'kind': kind,
      'data': data,
    });
  }
}

class DTDConnectionException implements Exception {
  static const int callParamsMissingTypeError = 1;

  /// The response to a call method is missing the top level type parameter.
  factory DTDConnectionException.callResponseMissingType(
    Map<String, Object?> json,
  ) {
    return DTDConnectionException._(
      callParamsMissingTypeError,
      'call received an invalid response, '
      "it is missing the 'type' param. Got: $json",
    );
  }
  DTDConnectionException._(this.errorCode, this.message);

  @override
  String toString() => 'DTDConnectionException: $message';

  final int errorCode;
  final String message;
}
