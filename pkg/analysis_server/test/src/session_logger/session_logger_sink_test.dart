// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/session_logger/log_normalizer.dart';
import 'package:analysis_server/src/session_logger/session_logger_sink.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

// ignore_for_file: unreachable_from_main

void main() {
  defineReflectiveSuite(() {
    // TODO(srawlins): Fix windows bot.
    //defineReflectiveTests(SessionLoggerFileSinkTest);
    //defineReflectiveTests(SessionLoggerInMemorySinkTest);
  });
}

@reflectiveTest
class SessionLoggerFileSinkTest {
  late LogNormalizer normalizer;

  void setUp() {
    normalizer = LogNormalizer();
  }

  Future<void> test_normalized() async {
    var provider = MemoryResourceProvider();
    var logFile = provider.getFile('/foo.txt');
    var fileSink = SessionLoggerFileSink(logFile, normalizer: normalizer);
    normalizer.addPathReplacement('/path/to/normalize', '{{normalized}}');
    fileSink.writeLogEntry({
      'kind': 'message',
      'message': {
        'method': 'textDocument/didOpen',
        'params': {
          'textDocument': {'uri': 'file:///path/to/normalize'},
        },
      },
    });

    var content = logFile.readAsStringSync();
    expect(
      content,
      '{"kind":"message",'
      '"message":{"method":"textDocument/didOpen",'
      '"params":{"textDocument":{"uri":"{{normalized}}"}}}}\n',
    );
  }
}

@reflectiveTest
class SessionLoggerInMemorySinkTest {
  late LogNormalizer normalizer;
  late SessionLoggerInMemorySink sink;

  void setUp() {
    normalizer = LogNormalizer();
    sink = SessionLoggerInMemorySink(
      maxBufferLength: 10,
      normalizer: normalizer,
    );
  }

  void test_capturedEntries_normalized() {
    normalizer.addPathReplacement('/path/to/normalize', '{{normalized}}');
    sink.startCapture();
    sink.writeLogEntry({
      'kind': 'message',
      'message': {
        'method': 'textDocument/didOpen',
        'params': {
          'textDocument': {'uri': 'file:///path/to/normalize'},
        },
      },
    });

    var entries = sink.capturedEntries;
    expect(entries, hasLength(1));
    expect(entries[0].message.textDocument, '{{normalized}}');
  }
}
