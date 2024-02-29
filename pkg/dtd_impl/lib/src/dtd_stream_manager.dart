// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_service_protocol_shared/dart_service_protocol_shared.dart';

import '../dart_tooling_daemon.dart';

/// Manages state related to stream subscriptions made by [DTDClient]s.
class DTDStreamManager extends StreamManager {
  DTDStreamManager(this.dtd);

  final DartToolingDaemon dtd;

  /// Send an event to the [stream].
  ///
  /// [stream] must be a registered custom stream (i.e., not a stream specified
  /// as part of the VM service protocol).
  ///
  /// If [stream] is not a registered custom stream, an [RPCError] with code
  /// [kCustomStreamDoesNotExist] will be thrown.
  ///
  /// If [stream] is a core stream, an [RPCError] with code
  /// [kCoreStreamNotAllowed] will be thrown.
  void postEventHelper(
    String stream,
    String eventKind,
    Map<String, Object?> eventData,
  ) {
    super.postEvent(
      stream,
      <String, dynamic>{
        'streamId': stream,
        'eventKind': eventKind,
        'eventData': eventData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Send `streamNotify` notifications to clients subscribed to `streamId`.
  void streamNotify(
    String streamId,
    Map<String, Object?> data,
  ) {
    super.postEvent(streamId, data);
  }
}
