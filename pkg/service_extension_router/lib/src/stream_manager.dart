// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'client.dart';

// TODO(danchevalier): Add documentation before major release
class StreamManager {
  StreamManager({this.onStreamCancel});
  Future<void> Function(Client client, String stream)? onStreamCancel;

  final _streamListeners =
      <String, List<Client>>{}; // TODO should this be set of StreamClient?
  List<Client>? getListenersFor({required String stream}) =>
      _streamListeners[stream];

  /// Returns true if [client] is subscribed to [stream]
  bool isSubscribed(Client client, String stream) {
    return _streamListeners[stream]?.contains(client) ?? false;
  }

  /// Returns true if [stream] has any [ServiceExtensionClients] subscribed.
  bool hasSubscriptions(String stream) {
    return _streamListeners[stream]?.isNotEmpty ?? false;
  }

  /// Triggers [Client.streamNotify] for all clients subscribed
  /// to [stream].
  void postEvent(
    String stream,
    Map<String, Object?> data, {
    Client? excludedClient,
  }) {
    final listeners = _streamListeners[stream] ?? const <Client>[];
    for (final listener in listeners) {
      if (listener == excludedClient) continue;
      listener.streamNotify(stream, data);
    }
  }

  /// Subscribes `client` to a stream.
  ///
  /// If `client` is the first client to listen to `stream`, DDS will send a
  /// `streamListen` request for `stream` to the VM service.
  void streamListen(
    Client client,
    String stream,
  ) async {
    _streamListeners.putIfAbsent(stream, () => <Client>[]);
    if (_streamListeners[stream]!.contains(client)) {
      throw StreamAlreadyListeningException(stream, client);
    }
    _streamListeners[stream]!.add(client);
  }

  /// Unsubscribes [client] from [stream].
  Future<void> streamCancel(
    Client client,
    String stream,
  ) async {
    if (!_streamListeners.containsKey(stream)) return;

    _streamListeners[stream]!.remove(client);
    if (onStreamCancel != null) {
      await onStreamCancel!(client, stream);
    }
  }

  Future<void> onClientDisconnect(Client client) async {
    await Future.wait([
      for (final stream in _streamListeners.keys)
        if (_streamListeners[stream]!.contains(client))
          streamCancel(client, stream),
    ]);
  }
}

class StreamAlreadyListeningException implements Exception {
  const StreamAlreadyListeningException(this.stream, this.client);
  final String stream;
  final Client client;

  @override
  String toString() =>
      "Client, with hashCode ${client.hashCode}, is already subscribed to stream $stream";
}
