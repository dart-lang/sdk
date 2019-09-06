// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// An OutputLog records the output from a test, but truncates it if
/// it is longer than [_maxHead] characters, and just keeps the head and
/// the last [_tailLength] characters of the output.
class OutputLog implements StreamConsumer<List<int>> {
  static const _maxHead = 500 * 1024;
  static const _tailLength = 10 * 1024;

  List<int> _head = [];
  List<int> _tail;
  List<int> complete;
  bool _dataDropped = false;
  StreamSubscription _subscription;

  bool _hasNonUtf8 = false;
  bool get hasNonUtf8 => _hasNonUtf8;

  void add(List<int> data) {
    if (complete != null) {
      throw StateError("Cannot add to OutputLog after calling toList");
    }
    if (_tail == null) {
      _head.addAll(data);
      if (_head.length > _maxHead) {
        _tail = _head.sublist(_maxHead);
        _head.length = _maxHead;
      }
    } else {
      _tail.addAll(data);
    }
    if (_tail != null && _tail.length > 2 * _tailLength) {
      _tail = _truncatedTail();
      _dataDropped = true;
    }
  }

  List<int> _truncatedTail() => _tail.length > _tailLength
      ? _tail.sublist(_tail.length - _tailLength)
      : _tail;

  void _checkUtf8(List<int> data) {
    try {
      utf8.decode(data, allowMalformed: false);
    } on FormatException {
      _hasNonUtf8 = true;
      var malformed = utf8.decode(data, allowMalformed: true);
      data
        ..clear()
        ..addAll(utf8.encode(malformed))
        ..addAll("""
*****************************************************************************
test.dart: The output of this test contained non-UTF8 formatted data.
*****************************************************************************
"""
            .codeUnits);
    }
  }

  List<int> toList() {
    if (complete == null) {
      complete = _head;
      if (_dataDropped) {
        complete.addAll("""
*****************************************************************************
test.dart: Data was removed due to excessive length. If you need the limit to
be increased, please contact dart-engprod or file an issue.
*****************************************************************************
"""
            .codeUnits);
        complete.addAll(_truncatedTail());
      } else if (_tail != null) {
        complete.addAll(_tail);
      }
      _head = null;
      _tail = null;
      _checkUtf8(complete);
    }
    return complete;
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    _subscription = stream.listen(add);
    return _subscription.asFuture();
  }

  @override
  Future close() {
    toList();
    return _subscription?.cancel();
  }

  Future cancel() {
    return _subscription?.cancel();
  }
}

/// An [OutputLog] that tees the output to a file as well.
class FileOutputLog extends OutputLog {
  final File _outputFile;
  IOSink _sink;

  FileOutputLog(this._outputFile);

  @override
  void add(List<int> data) {
    super.add(data);
    _sink ??= _outputFile.openWrite();
    _sink.add(data);
  }

  @override
  Future close() {
    return Future.wait([
      super.close(),
      if (_sink != null) _sink.flush().whenComplete(_sink.close)
    ]);
  }

  @override
  Future cancel() {
    return Future.wait([
      super.cancel(),
      if (_sink != null) _sink.flush().whenComplete(_sink.close)
    ]);
  }
}
