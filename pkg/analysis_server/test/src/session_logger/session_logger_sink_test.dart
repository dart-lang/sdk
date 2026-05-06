// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/session_logger/log_normalizer.dart';
import 'package:analysis_server/src/session_logger/session_logger_sink.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer_testing/utilities/extensions/resource_provider.dart';
import 'package:path/path.dart' as path show Context;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SessionLoggerFileSinkTest);
    defineReflectiveTests(SessionLoggerInMemorySinkTest);
  });
}

@reflectiveTest
class SessionLoggerFileSinkTest {
  late LogNormalizer normalizer;
  late MemoryResourceProvider provider;
  late path.Context pathContext;

  void setUp() {
    provider = MemoryResourceProvider();
    pathContext = provider.pathContext;
    normalizer = LogNormalizer(pathContext);
  }

  Future<void> test_normalized() async {
    var convertPath = ResourceProviderExtension(provider).convertPath;
    var logPath = convertPath('/foo.txt');
    var pathToNormalize = convertPath('/path/to/normalize');

    var logFile = provider.getFile(logPath);
    var fileSink = SessionLoggerFileSink(logFile, normalizer: normalizer);
    normalizer.addPathReplacement(pathToNormalize, '{{normalized}}');
    fileSink.writeLogEntry({
      'kind': 'message',
      'message': {
        'method': 'textDocument/didOpen',
        'params': {
          'textDocument': {
            'uri': pathContext.toUri(pathToNormalize).toString(),
          },
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
  late MemoryResourceProvider provider;
  late path.Context pathContext;
  late SessionLoggerInMemorySink sink;

  void setUp() {
    provider = MemoryResourceProvider();
    pathContext = provider.pathContext;
    normalizer = LogNormalizer(pathContext);
    sink = SessionLoggerInMemorySink(
      maxBufferLength: 10,
      normalizer: normalizer,
    );
  }

  void test_capturedEntries_normalized() {
    var convertPath = ResourceProviderExtension(provider).convertPath;
    var pathToNormalize = convertPath('/path/to/normalize');

    normalizer.addPathReplacement(pathToNormalize, '{{normalized}}');
    sink.startCapture();
    sink.writeLogEntry({
      'kind': 'message',
      'message': {
        'method': 'textDocument/didOpen',
        'params': {
          'textDocument': {
            'uri': pathContext.toUri(pathToNormalize).toString(),
          },
        },
      },
    });

    var entries = sink.capturedEntries;
    expect(entries, hasLength(1));
    expect(entries[0].message.textDocument, '{{normalized}}');
  }
}
