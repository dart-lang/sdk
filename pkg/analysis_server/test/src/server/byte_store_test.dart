// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/session_logger/entry_kind.dart';
import 'package:analysis_server/src/session_logger/session_logger.dart';
import 'package:analysis_server/src/session_logger/session_logger_sink.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages/byte_store_page.dart';
import 'package:analysis_server/src/utilities/mocks.dart';
import 'package:analyzer/src/file_system/timing_resource_provider.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../status/test_socket_server.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ByteStoreTest);
  });
}

/// Tests for the byte stores that the server opens in its cache folder on the
/// physical file system.
@reflectiveTest
class ByteStoreTest {
  late Directory cacheFolder;

  /// The session log of the most recently started server.
  late SessionLoggerInMemorySink sessionLogSink;

  void setUp() {
    cacheFolder = Directory.systemTemp.createTempSync('byte_store_');
  }

  void tearDown() {
    cacheFolder.deleteSync(recursive: true);
  }

  Future<void> test_default_singleFile() async {
    var (:server, :channel) = _startServer();
    try {
      var stats = server.byteStoreStats!;
      expect(
        stats.singleFileStorePath,
        startsWith(path.join(cacheFolder.path, '.analysis-cache')),
      );
      expect(stats.fileStorePath, isNull);
    } finally {
      await _shutDown(channel);
    }
  }

  Future<void> test_evictingFile_open() async {
    var (:server, :channel) = _startServer(useSingleFileByteStore: false);
    try {
      var stats = server.byteStoreStats!;
      expect(stats.usesFileByteStore, isTrue);
      expect(
        stats.fileStorePath,
        path.join(cacheFolder.path, '.analysis-driver'),
      );
      expect(stats.singleFileStorePath, isNull);

      // The disk store is used through the timing resource provider.
      expect(
        server
            .timingResourceProvider
            .timings[ResourceProviderOperation.resourceGetStateLocation]
            ?.count,
        greaterThanOrEqualTo(1),
      );

      var bytes = Uint8List.fromList([1, 2, 3]);
      server.byteStore.putGet('key', bytes);
      expect(server.byteStore.get('key'), bytes);
    } finally {
      await _shutDown(channel);
    }
  }

  Future<void> test_singleFile_open() async {
    var (:server, :channel) = _startServer(useSingleFileByteStore: true);
    try {
      var stats = server.byteStoreStats!;
      expect(
        stats.singleFileStorePath,
        startsWith(path.join(cacheFolder.path, '.analysis-cache')),
      );
      expect(stats.singleFileStoreOpenFailure, isNull);
      expect(stats.singleFileStoreStorageFailure, isNull);

      var html = await _generateByteStorePage(server);
      expect(html, contains('Single File Store'));
      expect(html, isNot(contains('storage failure')));
    } finally {
      await _shutDown(channel);
    }
  }

  Future<void> test_singleFile_open_failure_usesMemoryCache() async {
    // Find the path of the cache file, and put a directory there.
    var first = _startServer(useSingleFileByteStore: true);
    var storePath = first.server.byteStoreStats!.singleFileStorePath!;
    await _shutDown(first.channel);
    File(storePath).deleteSync();
    Directory(storePath).createSync();

    var (:server, :channel) = _startServer(useSingleFileByteStore: true);
    try {
      var stats = server.byteStoreStats!;
      expect(stats.singleFileStorePath, isNull);
      expect(stats.singleFileStoreOpenFailure, contains('FileSystemException'));
      expect(stats.singleFileStoreStorageFailure, isNull);
      _assertOpenFailureLogged();

      // The memory cache still works.
      var bytes = Uint8List.fromList([1, 2, 3]);
      server.byteStore.putGet('key', bytes);
      expect(server.byteStore.get('key'), bytes);

      var html = await _generateByteStorePage(server);
      expect(html, contains('The single-file store could not be opened'));
    } finally {
      await _shutDown(channel);
    }
  }

  Future<void> test_singleFile_open_folderFailure_usesMemoryCache() async {
    // A file where the cache folder should be.
    File(path.join(cacheFolder.path, '.analysis-cache')).createSync();

    var (:server, :channel) = _startServer();
    try {
      var stats = server.byteStoreStats!;
      expect(stats.singleFileStorePath, isNull);
      expect(stats.singleFileStoreOpenFailure, contains('FileSystemException'));
      _assertOpenFailureLogged();

      // The memory cache still works.
      var bytes = Uint8List.fromList([1, 2, 3]);
      server.byteStore.putGet('key', bytes);
      expect(server.byteStore.get('key'), bytes);

      var html = await _generateByteStorePage(server);
      expect(html, contains('The single-file store could not be opened'));
    } finally {
      await _shutDown(channel);
    }
  }

  Future<void> test_singleFile_storageFailure_shownOnPage() async {
    var failLock = false;
    var outerZone = Zone.current;
    var (:server, :channel) = IOOverrides.runZoned(
      _startServer,
      createFile: (filePath) {
        var file = outerZone.run(() => File(filePath));
        return filePath.endsWith('.bin')
            ? _LockFailingFile(file, () => failLock)
            : file;
      },
    );
    try {
      failLock = true;
      expect(server.byteStore.get('missing'), isNull);
      var stats = server.byteStoreStats!;
      expect(stats.singleFileStorePath, isNotNull);
      expect(stats.singleFileStoreStorageFailure, contains('lock failure'));

      // The file is not read anymore, but the statistics of this process are.
      var html = await _generateByteStorePage(server);
      expect(html, contains('Single File Store'));
      expect(html, contains('This process'));
      expect(html, isNot(contains('Entries used')));
      expect(html, contains('Stopped using the file after a storage failure'));
    } finally {
      await _shutDown(channel);
    }
  }

  /// Asserts that the failure to open the store was logged once, with a stack
  /// trace.
  void _assertOpenFailureLogged() {
    var messages = sessionLogSink.capturedEntries
        .where((entry) => entry.kind == EntryKind.info)
        .map((entry) => entry.textMessage)
        .where((message) => message.contains('single-file byte store'))
        .toList();
    expect(messages, [
      allOf(
        startsWith('Could not open the single-file byte store: '),
        contains('FileSystemException'),
        contains('server_byte_store.dart'),
      ),
    ]);
  }

  Future<String> _generateByteStorePage(AnalysisServer server) {
    var site = DiagnosticsSite(TestSocketServer(server), []);
    return ByteStorePage(site).generate({});
  }

  Future<void> _shutDown(MockServerChannel channel) async {
    await channel.simulateRequestFromClient(
      ServerShutdownParams().toRequest('0', clientUriConverter: null),
    );
  }

  /// Starts a server that uses [cacheFolder], and [useSingleFileByteStore]
  /// if not `null`, otherwise the default.
  ({AnalysisServer server, MockServerChannel channel}) _startServer({
    bool? useSingleFileByteStore,
  }) {
    var sessionLogger = SessionLogger();
    sessionLogSink = sessionLogger.sink as SessionLoggerInMemorySink;
    sessionLogSink.startCapture();
    var options = AnalysisServerOptions()..cacheFolder = cacheFolder.path;
    if (useSingleFileByteStore != null) {
      options.useSingleFileByteStore = useSingleFileByteStore;
    }
    var socketServer = SocketServer(
      options,
      DartSdkManager(''),
      CrashReportingAttachmentsBuilder.empty,
      sessionLogger,
      null,
      null,
      AnalyticsManager(NoOpAnalytics()),
      null,
      null,
    );
    var channel = MockServerChannel();
    socketServer.createAnalysisServer(channel);
    return (server: socketServer.analysisServer!, channel: channel);
  }
}

/// A real [File] whose opened file throws from [RandomAccessFile.lockSync]
/// while [_failLock] returns `true`.
class _LockFailingFile implements File {
  final File _file;
  final bool Function() _failLock;

  new(this._file, this._failLock);

  @override
  String get path => _file.path;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  RandomAccessFile openSync({FileMode mode = FileMode.read}) {
    return _LockFailingRandomAccessFile(_file.openSync(mode: mode), _failLock);
  }

  @override
  void setLastModifiedSync(DateTime time) {
    _file.setLastModifiedSync(time);
  }
}

/// A real [RandomAccessFile] whose [lockSync] throws while [_failLock]
/// returns `true`.
class _LockFailingRandomAccessFile implements RandomAccessFile {
  final RandomAccessFile _file;
  final bool Function() _failLock;

  new(this._file, this._failLock);

  @override
  String get path => _file.path;

  @override
  void closeSync() {
    _file.closeSync();
  }

  @override
  void flushSync() {
    _file.flushSync();
  }

  @override
  int lengthSync() => _file.lengthSync();

  @override
  void lockSync([
    FileLock mode = FileLock.exclusive,
    int start = 0,
    int end = -1,
  ]) {
    if (_failLock()) {
      throw const FileSystemException('Simulated lock failure');
    }
    _file.lockSync(mode, start, end);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  int readIntoSync(List<int> buffer, [int start = 0, int? end]) {
    return _file.readIntoSync(buffer, start, end);
  }

  @override
  void setPositionSync(int position) {
    _file.setPositionSync(position);
  }

  @override
  void truncateSync(int length) {
    _file.truncateSync(length);
  }

  @override
  void unlockSync([int start = 0, int end = -1]) {
    _file.unlockSync(start, end);
  }

  @override
  void writeFromSync(List<int> buffer, [int start = 0, int? end]) {
    _file.writeFromSync(buffer, start, end);
  }
}
