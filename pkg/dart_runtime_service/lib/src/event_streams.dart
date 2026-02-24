// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart';

import 'clients.dart';
import 'rpc_exceptions.dart';
import 'utils.dart';

/// A base class for events to be sent on [streamId] with a given [kind].
abstract base class StreamEvent {
  StreamEvent({required this.streamId, required this.kind});

  static const kStreamId = 'streamId';
  static const kEvent = 'event';

  final String streamId;
  final String kind;
  final int timestamp = DateTime.now().millisecondsSinceEpoch;

  void send({
    required EventStreamManager eventStreamMethods,
    Client? excludedClient,
  }) {
    eventStreamMethods.streamNotify(
      streamId: streamId,
      data: this,
      excludedClient: excludedClient,
    );
  }

  @mustCallSuper
  Map<String, Object?> toJson();
}

/// Base class for service registration events which are sent on the Service
/// stream.
abstract base class ServiceRegistrationEvent extends StreamEvent {
  ServiceRegistrationEvent({
    required super.kind,
    required this.service,
    required this.namespace,
    required this.alias,
  }) : super(streamId: EventStreams.kService);

  final String namespace;
  final ServiceName service;
  final ServiceAlias alias;

  @override
  Map<String, Object?> toJson() => {
    StreamEvent.kStreamId: streamId,
    StreamEvent.kEvent: Event(
      kind: kind,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      service: service,
      method: '$namespace.$service',
      alias: alias,
    ).toJson(),
  };
}

/// An event sent on the Service stream indicating that a new service is
/// available.
final class ServiceRegisteredEvent extends ServiceRegistrationEvent {
  ServiceRegisteredEvent({
    required super.service,
    required super.namespace,
    required super.alias,
  }) : super(kind: EventKind.kServiceRegistered);
}

/// An event sent on the Service stream indicating that a service is no longer
/// available.
final class ServiceUnregisteredEvent extends ServiceRegistrationEvent {
  ServiceUnregisteredEvent({
    required super.service,
    required super.namespace,
    required super.alias,
  }) : super(kind: EventKind.kServiceUnregistered);
}

abstract interface class EventStreamMethods {
  /// Send `streamNotify` notifications to clients subscribed to `streamId`.
  ///
  /// If `data` is of type `Uint8List`, the notification is assumed to be a
  /// binary event and is forwarded directly over the subscriber's websocket.
  /// Otherwise, the event is sent via the JSON RPC client.
  ///
  /// If `excludedClient` is provided, the notification will be sent to all
  /// clients subscribed to `streamId` except for `excludedClient`.
  void streamNotify({
    required String streamId,
    required Object data,
    Client? excludedClient,
  });

  /// Notifies interested clients that a new [service] is being provided by
  /// [client].
  void sendServiceRegisteredEvent(
    Client client,
    ServiceName service,
    ServiceAlias alias,
  );

  /// Subscribes `client` to a stream.
  void streamListen({required Client client, required String streamId});

  /// Unsubscribes `client` from a stream.
  void streamCancel({required Client client, required String streamId});

  /// Cleanup stream subscriptions for `client` when it has disconnected.
  void onClientDisconnect(Client client);
}

/// Used for keeping track of stream subscription state and sending events to
/// clients subscribed to individual streams.
class EventStreamManager implements EventStreamMethods {
  EventStreamManager({
    required UnmodifiableNamedLookup<Client> Function() clientsGetter,
  }) : _clientsGetter = clientsGetter;

  static const kStreamNotify = 'streamNotify';

  final UnmodifiableNamedLookup<Client> Function() _clientsGetter;
  late final clients = _clientsGetter();

  @visibleForTesting
  final streamListeners = <String, List<Client>>{};

  final _logger = Logger('$EventStreamManager');

  /// Send `streamNotify` notifications to clients subscribed to `streamId`.
  ///
  /// If `data` is of type `Uint8List`, the notification is assumed to be a
  /// binary event and is forwarded directly over the subscriber's websocket.
  /// Otherwise, the event is sent via the JSON RPC client.
  ///
  /// If `excludedClient` is provided, the notification will be sent to all
  /// clients subscribed to `streamId` except for `excludedClient`.
  @override
  void streamNotify({
    required String streamId,
    required Object data,
    Client? excludedClient,
  }) {
    final streamLogger = Logger('${_logger.name} ($streamId)');
    if (streamListeners.containsKey(streamId)) {
      final listeners = streamListeners[streamId]!;
      String eventString;
      if (data is Uint8List) {
        eventString = '<binary data>';
      } else if (data is StreamEvent) {
        eventString = data.toJson().toString();
      } else {
        eventString = '<unknown>';
      }
      streamLogger.info(
        'Sending event to ${listeners.length} clients: $eventString',
      );

      for (final listener in listeners) {
        if (listener == excludedClient) {
          continue;
        }
        switch (data) {
          case Uint8List():
            // TODO(bkonyi): support sending binary events (e.g., for heap
            // snapshots).
            // listener.connection.sink.add(data);
            throw StateError('Cannot send binary data');
          case StreamEvent():
            listener.sendNotification(
              method: kStreamNotify,
              parameters: data.toJson(),
            );
          default:
            throw StateError('Unrecognized data type: ${data.runtimeType}');
        }
      }
    }
  }

  /// Notifies interested clients that a new [service] is being provided by
  /// [client].
  @override
  void sendServiceRegisteredEvent(
    Client client,
    ServiceName service,
    ServiceAlias alias,
  ) {
    final namespace = clients.keyOf(client);
    if (namespace == null) {
      return;
    }
    ServiceRegisteredEvent(
      namespace: namespace,
      service: service,
      alias: alias,
    ).send(eventStreamMethods: this, excludedClient: client);
  }

  /// Notifies interested clients that [client] is no longer providing any
  /// services.
  void _sendServiceUnregisteredEvents(Client client) {
    final namespace = clients.keyOf(client);
    if (namespace == null) {
      return;
    }
    client.logger.info('Sending $ServiceUnregisteredEvent.');
    for (final (:service, :alias) in client.services) {
      ServiceUnregisteredEvent(
        namespace: namespace,
        service: service,
        alias: alias,
      ).send(eventStreamMethods: this, excludedClient: client);
    }
  }

  /// Subscribes `client` to a stream.
  @override
  void streamListen({required Client client, required String streamId}) {
    assert(streamId.isNotEmpty);
    // TODO(bkonyi): invoke backend stream handling logic.
    final listeners = streamListeners.putIfAbsent(streamId, () => []);
    if (listeners.contains(client)) {
      RpcException.streamAlreadySubscribed.throwException();
    }
    listeners.add(client);
    if (streamId == EventStreams.kService) {
      // Send all previously registered service extensions when a client
      // subscribes to the Service stream.
      for (final c in clients) {
        if (c == client) {
          continue;
        }
        final namespace = clients.keyOf(c);
        if (namespace == null) {
          continue;
        }
        for (final (:service, :alias) in c.services.toList()) {
          ServiceRegisteredEvent(
            service: service,
            namespace: namespace,
            alias: alias,
          ).send(eventStreamMethods: this, excludedClient: client);
        }
      }
    }
  }

  /// Unsubscribes `client` from a stream.
  @override
  void streamCancel({required Client client, required String streamId}) {
    assert(streamId.isNotEmpty);
    final listeners = streamListeners[streamId];
    if (listeners == null || !listeners.contains(client)) {
      RpcException.streamNotSubscribed.throwException();
    }

    listeners.remove(client);
    // TODO(bkonyi): invoke backend stream handling logic.
  }

  /// Cleanup stream subscriptions for `client` when it has disconnected.
  @override
  void onClientDisconnect(Client client) {
    for (final streamId in streamListeners.keys.toList()) {
      try {
        streamCancel(client: client, streamId: streamId);
      } on json_rpc.RpcException {
        // Ignore 'stream not subscribed' errors when service is shutting down.
        // ignore: avoid_catching_errors
      } on StateError {
        // Ignore state errors when service is shutting down.
      }
    }

    // Notify other service clients of service extensions that are being
    // unregistered.
    _sendServiceUnregisteredEvents(client);
  }
}
