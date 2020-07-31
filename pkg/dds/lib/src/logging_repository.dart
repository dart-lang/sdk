// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dds;

/// [_LoggingRepository] is used to store historical log messages from the
/// target VM service. Clients which connect to DDS and subscribe to the
/// `Logging` stream will be sent all messages contained within this repository
/// upon initial subscription.
class _LoggingRepository extends _RingBuffer<Map<String, dynamic>> {
  _LoggingRepository([int logHistoryLength = 10000]) : super(logHistoryLength) {
    // TODO(bkonyi): enforce log history limit when DartDevelopmentService
    // allows for this to be set via Dart code.
  }

  void sendHistoricalLogs(_DartDevelopmentServiceClient client) {
    // Only send historical log messages when the client first subscribes to
    // the logging stream.
    if (_sentHistoricLogsClientSet.contains(client)) {
      return;
    }
    _sentHistoricLogsClientSet.add(client);
    for (final log in this()) {
      client.sendNotification('streamNotify', log);
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
  final Set<_DartDevelopmentServiceClient> _sentHistoricLogsClientSet = {};
  static const int _kMaxLogBufferSize = 100000;
}

// TODO(bkonyi): move to standalone file if we decide to use this elsewhere.
class _RingBuffer<T> {
  _RingBuffer(int initialSize) {
    _bufferSize = initialSize;
    _buffer = List<T>.filled(
      _bufferSize,
      null,
    );
  }

  Iterable<T> call() sync* {
    for (int i = _size - 1; i >= 0; --i) {
      yield _buffer[(_count - i - 1) % _bufferSize];
    }
  }

  void add(T e) {
    if (_buffer.isEmpty) {
      return;
    }
    _buffer[_count++ % _bufferSize] = e;
  }

  void resize(int size) {
    assert(size >= 0);
    if (size == _bufferSize) {
      return;
    }
    final resized = List<T>.filled(
      size,
      null,
    );
    int count = 0;
    if (size > 0) {
      for (final e in this()) {
        resized[count++ % size] = e;
      }
    }
    _count = count;
    _bufferSize = size;
    _buffer = resized;
  }

  int get bufferSize => _bufferSize;
  int get _size => min(_count, _bufferSize);

  int _bufferSize;
  int _count = 0;
  List<T> _buffer;
}
