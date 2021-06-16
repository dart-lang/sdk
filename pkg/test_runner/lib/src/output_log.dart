// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _nonUtf8Error = '[test.dart: This test output contains non-UTF8 data]';
const _truncatedError =
    '[test.dart: This test output was too long and was truncated here.';

/// Records the output from a test.
class OutputLog implements StreamConsumer<List<int>> {
  // TODO(45618): Reduce this if language_2/unsorted/disassemble_test is fixed
  // to produce less output and any other large-output tests are fixed.
  static const _maxLength = 10 * 1024 * 1024;

  final List<int> _data = [];
  StreamSubscription _subscription;

  bool get hasNonUtf8 => _hasNonUtf8 ??= _checkUtf8();
  bool _hasNonUtf8;

  bool get wasTruncated => _wasTruncated;
  bool _wasTruncated = false;

  List<int> get bytes => _data;

  void add(List<int> data) {
    if (_hasNonUtf8 != null) {
      throw StateError("Cannot add to OutputLog after accessing bytes.");
    }

    // Discard additional output after we've reached the limit.
    if (_wasTruncated) return;

    if (_data.length + data.length > _maxLength) {
      _data.addAll(data.take(_maxLength - _data.length));
      _data.addAll(utf8.encode(_truncatedError));
      _wasTruncated = true;
    } else {
      _data.addAll(data);
    }
  }

  void clear() {
    _data.clear();
  }

  bool _checkUtf8() {
    try {
      utf8.decode(_data, allowMalformed: false);
      return false;
    } on FormatException {
      var malformed = utf8.decode(_data, allowMalformed: true);
      _data.clear();
      _data.addAll(utf8.encode(malformed));
      _data.addAll(utf8.encode(_nonUtf8Error));
      return true;
    }
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    _subscription = stream.listen(add);
    return _subscription.asFuture();
  }

  @override
  Future close() => _subscription?.cancel();

  Future cancel() => _subscription?.cancel();
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
