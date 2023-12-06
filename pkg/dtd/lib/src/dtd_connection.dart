// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:stream_channel/stream_channel.dart';

class DTDConnection {
  DTDConnection(this._connectionChannel) {
    // TODO(@danchevalier);
  }

  /// Terminates the connection with the Dart Tooling Daemon.
  Future<void> close() async {
    // TODO(@danchevalier)
    return;
  }

  // TODO(@danchevalier)
  /// A `Future` that completes when the connection with the Dart Tooling Daemon
  /// is terminated.
  Future<void> get done async => Future.value();

  /// Returns the current list of services available.
  Future<List<String>> getRegisteredServices() async {
    // TODO(@danchevalier)
    return Future.value([]);
  }

  /// Returns the current list of streams with active subscribers.
  Future<List<String>> getRegisteredStreams() async {
    // TODO(@danchevalier)
    return Future.value([]);
  }

  /// Subscribes this client to events posted on [streamId].
  ///
  /// If this client is already subscribed to [streamId], an exception will be
  /// thrown.
  Future<void> streamListen(String streamId) async {
    // TODO(@danchevalier)
    return;
  }

  /// Cancel the subscription to [streamId].
  ///
  /// Once called, this connection will no longer receive events posted on
  /// [streamId].
  ///
  /// If this client was not subscribed to [streamId], an exception will be
  /// thrown.
  Future<void> streamCancel(Stream streamId) async {
    // TODO(@danchevalier)
    return;
  }

  /// Creates a `Stream` for events received on [streamId].
  ///
  /// This method should be called before calling [streamListen] to ensure
  /// events aren't dropped. [streamListen(streamId)] must be called before any
  /// events will appear on the returned stream.
  Stream<DTDEvent> onEvent(String streamId) {
    // TODO(@danchevalier)
    return const Stream.empty();
  }

  /// Posts an [DTDEvent] with [eventData] to [streamId].
  ///
  /// If no clients are subscribed to [streamId], the event will be dropped.
  void postEvent(String streamId, Map<String, Object?> eventData) {
    // TODO(@danchevalier)
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
  Future<T> call<T extends DTDResponse>(
    String serviceName,
    String methodName, {
    Map<String, Object>? params,
  }) async {
    // TODO(@danchevalier)
    // ignore: null_argument_to_non_null_type
    return Future.value();
  }

  // ignore: unused_field
  final StreamChannel _connectionChannel;
}

abstract class DTDResponse {
  String get id;

  String get type;

  Map<String, Object?> get json;
}

// TODO(@danchevalier): is this how event should be done?
abstract class DTDEvent {}
