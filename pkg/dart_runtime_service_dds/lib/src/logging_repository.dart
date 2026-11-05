// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import 'ring_buffer.dart';

/// [LoggingRepository] is used to store historical log messages from the
/// target VM service. Clients which connect to DDS and subscribe to the
/// `Logging` stream will be sent all messages contained within this repository
/// upon initial subscription.
class LoggingRepository extends RingBuffer<Map<String, Object?>> {
  LoggingRepository([super.logHistoryLength = _kDefaultLogHistoryLength]);

  static const _kDefaultLogHistoryLength = 10_000;
  static const _kMaxLogBufferSize = 100_000;

  void sendHistoricalLogs(Client client) {
    // Only send historical log messages when the client first subscribes to
    // the logging stream.
    if (_sentHistoricLogsClientSet.contains(client)) {
      return;
    }
    _sentHistoricLogsClientSet.add(client);
    for (final log in this()) {
      client.sendNotification(
        method: EventStreamManager.kStreamNotify,
        parameters: log,
      );
    }
  }

  @override
  void resize(int size) {
    if (size > _kMaxLogBufferSize) {
      throw json_rpc.RpcException.invalidParams(
        "'size' must be less than $_kMaxLogBufferSize",
      );
    }
    super.resize(size);
  }

  // The set of clients which have subscribed to the Logging stream at some
  // point in time.
  final _sentHistoricLogsClientSet = <Client>{};
}
