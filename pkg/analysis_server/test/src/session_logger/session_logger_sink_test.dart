// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analysis_server/src/session_logger/log_normalizer.dart';
import 'package:analysis_server/src/session_logger/session_logger_sink.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_testing/utilities/extensions/resource_provider.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SessionLoggerFileSinkTest);
    defineReflectiveTests(SessionLoggerInMemorySinkTest);
  });
}

/// Test the [SessionLoggerFileSink], an implementation of [SessionLoggerSink]
/// that writes to the physical disk via `dart:io`. It doesn't use the
/// analyzer file abstraction, as it uses `openWrite()` and `IOSink` which are
/// not implemented in the abstraction.
@reflectiveTest
class SessionLoggerFileSinkTest {
  late LogNormalizer normalizer;
  late io.Directory tempDirectory;
  late String logPath;
  late io.File logFile;
  PhysicalResourceProvider provider = PhysicalResourceProvider.INSTANCE;
  late path.Context pathContext = provider.pathContext;

  late String Function(String) convertPath = ResourceProviderExtension(provider)
      .convertPath;

  void setUp() {
    normalizer = LogNormalizer();
    tempDirectory = io.Directory.systemTemp.createTempSync(
      'dartServer_sessionLog_fileSinkTest',
    );
    logPath = path.join(tempDirectory.path, 'foo.txt');
    logFile = io.File(logPath);
  }

  void tearDown() {
    tempDirectory.deleteSync(recursive: true);
  }

  Future<void> test_multipleWrites() async {
    var fileSink = SessionLoggerFileSink(logPath, normalizer: normalizer);

    // Write multiple entries
    fileSink.writeLogEntry({'id': 1});
    fileSink.writeLogEntry({'id': 2});
    fileSink.writeLogEntry({'id': 3});

    await fileSink.close();

    // Ensure they are all recorded.
    var content = io.File(logPath).readAsStringSync();
    expect(content, '{"id":1}\n{"id":2}\n{"id":3}\n');
  }

  Future<void> test_normalized() async {
    var pathToNormalize = convertPath('/path/to/normalize');

    var fileSink = SessionLoggerFileSink(logPath, normalizer: normalizer);
    normalizer.addReplacementsForPath(pathToNormalize, 'normalized');
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

    await fileSink.close();

    var content = io.File(logPath).readAsStringSync();
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
    normalizer = LogNormalizer();
    sink = SessionLoggerInMemorySink(
      maxBufferLength: 10,
      normalizer: normalizer,
    );
  }

  void test_capturedEntries_normalized() {
    var convertPath = ResourceProviderExtension(provider).convertPath;
    var pathToNormalize = convertPath('/path/to/normalize');

    normalizer.addReplacementsForPath(pathToNormalize, 'normalized');
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
