// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dds;

class _StreamManager {
  _StreamManager(this.dds);

  /// Send `streamNotify` notifications to clients subscribed to `streamId`.
  ///
  /// If `data` is of type `Uint8List`, the notification is assumed to be a
  /// binary event and is forwarded directly over the subscriber's websocket.
  /// Otherwise, the event is sent via the JSON RPC client.
  void streamNotify(String streamId, data) {
    if (streamListeners.containsKey(streamId)) {
      final listeners = streamListeners[streamId];
      final isBinaryData = data is Uint8List;
      for (final listener in listeners) {
        if (isBinaryData) {
          listener.ws.sink.add(data);
        } else {
          listener.sendNotification('streamNotify', data);
        }
      }
    }
  }

  /// Start listening for `streamNotify` events from the VM service and forward
  /// them to the clients which have subscribed to the stream.
  void listen() => dds._vmServiceClient.registerMethod(
        'streamNotify',
        (parameters) {
          final streamId = parameters['streamId'].asString;
          streamNotify(streamId, parameters.value);
        },
      );

  /// Subscribes `client` to a stream.
  ///
  /// If `client` is the first client to listen to `stream`, DDS will send a
  /// `streamListen` request for `stream` to the VM service.
  Future<void> streamListen(
    _DartDevelopmentServiceClient client,
    String stream,
  ) async {
    assert(stream != null && stream.isNotEmpty);
    if (!streamListeners.containsKey(stream)) {
      // This will return an RPC exception if the stream doesn't exist. This
      // will throw and the exception will be forwarded to the client.
      final result = await dds._vmServiceClient.sendRequest('streamListen', {
        'streamId': stream,
      });
      assert(result['type'] == 'Success');
      streamListeners[stream] = <_DartDevelopmentServiceClient>[];
    }
    if (streamListeners[stream].contains(client)) {
      throw kStreamAlreadySubscribedException;
    }
    streamListeners[stream].add(client);
  }

  /// Unsubscribes `client` from a stream.
  ///
  /// If `client` is the last client to unsubscribe from `stream`, DDS will
  /// send a `streamCancel` request for `stream` to the VM service.
  Future<void> streamCancel(
    _DartDevelopmentServiceClient client,
    String stream,
  ) async {
    assert(stream != null && stream.isNotEmpty);
    final listeners = streamListeners[stream];
    if (listeners == null || !listeners.contains(client)) {
      throw kStreamNotSubscribedException;
    }
    listeners.remove(client);
    if (listeners.isEmpty) {
      streamListeners.remove(stream);
      final result = await dds._vmServiceClient.sendRequest('streamCancel', {
        'streamId': stream,
      });
      assert(result['type'] == 'Success');
    } else {
      streamListeners[stream] = listeners;
    }
  }

  /// Cleanup stream subscriptions for `client` when it has disconnected.
  void clientDisconnect(_DartDevelopmentServiceClient client) {
    for (final streamId in streamListeners.keys.toList()) {
      streamCancel(client, streamId);
    }
  }

  // These error codes must be kept in sync with those in vm/json_stream.h and
  // vmservice.dart.
  static const kStreamAlreadySubscribed = 103;
  static const kStreamNotSubscribed = 104;

  // Keep these messages in sync with the VM service.
  static final kStreamAlreadySubscribedException = json_rpc.RpcException(
    kStreamAlreadySubscribed,
    'Stream already subscribed',
  );

  static final kStreamNotSubscribedException = json_rpc.RpcException(
    kStreamNotSubscribed,
    'Stream not subscribed',
  );

  final _DartDevelopmentService dds;
  final streamListeners = <String, List<_DartDevelopmentServiceClient>>{};
}
