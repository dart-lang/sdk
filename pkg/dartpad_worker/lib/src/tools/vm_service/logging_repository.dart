// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:vm_service/vm_service.dart';

import '../sandbox_client.dart';

final _dartCoreLib = LibraryRef(
  id: 'libraries/dart:core',
  name: 'dart:core',
  uri: 'dart:core',
);

final _stringClassRef = ClassRef(
  id: 'classes/String',
  name: 'String',
  library: _dartCoreLib,
);

final _nullInstance = InstanceRef(
  id: 'objects/null',
  kind: InstanceKind.kNull,
  classRef: ClassRef(id: 'classes/Null', name: 'Null', library: _dartCoreLib),
  valueAsString: 'null',
);

InstanceRef _stringOrNullInstance(String? value) {
  if (value == null) return _nullInstance;
  return InstanceRef(
    id: 'objects/string',
    kind: InstanceKind.kString,
    classRef: _stringClassRef,
    valueAsString: value,
    valueAsStringIsTruncated: false,
    length: value.length,
  );
}

extension SandboxLogRecordExt on SandboxLogRecord {
  /// Converts a [SandboxLogRecord] emitted by `sandbox.js` into a VM Service
  /// [LogRecord].
  LogRecord toLogRecord() => LogRecord(
    message: _stringOrNullInstance(message),
    time: time,
    level: level,
    sequenceNumber: sequenceNumber,
    loggerName: _stringOrNullInstance(name),
    zone: _nullInstance,
    error: _stringOrNullInstance(error),
    stackTrace: _stringOrNullInstance(stackTrace),
  );
}

/// DDS-style ring buffer of historical stream events (`Stdout`, `Stderr`,
/// `Logging`, and `Extension`) replayed once per client per stream on first
/// `streamListen`.
final class LoggingRepository {
  static const _maxEntriesPerStream = 1000;

  final _buffers = <String, ListQueue<StreamEvent>>{
    EventStreams.kStdout: ListQueue<StreamEvent>(),
    EventStreams.kStderr: ListQueue<StreamEvent>(),
    EventStreams.kLogging: ListQueue<StreamEvent>(),
    EventStreams.kExtension: ListQueue<StreamEvent>(),
  };

  final _sentStreamsByClient = Expando<Set<String>>('sentHistoricalStreams');

  void add(StreamEvent event) {
    final buffer = _buffers[event.streamId];
    if (buffer == null) return;
    while (buffer.length >= _maxEntriesPerStream) {
      buffer.removeFirst();
    }
    buffer.addLast(event);
  }

  void sendHistoricalEvents(Client client, String streamId) {
    final buffer = _buffers[streamId];
    if (buffer == null) return;
    final sentStreams = _sentStreamsByClient[client] ??= <String>{};
    if (!sentStreams.add(streamId)) return;
    for (final event in buffer) {
      event.sendToClient(client);
    }
  }
}
