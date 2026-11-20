// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analysis_server/src/utilities/timing_byte_store.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/file_byte_store.dart'
    show EvictingFileByteStore;
import 'package:analyzer/src/dart/analysis/single_file_byte_store.dart';
import 'package:analyzer/src/file_system/timing_resource_provider.dart';

/// A snapshot of the sizes and counters of the byte stores used by the
/// server, for display on the diagnostics pages.
///
/// Fields specific to a persistent byte store are `null` when that store is
/// not used by the server.
class const AnalysisServerByteStoreStats({
  required final int cacheHitCount,
  required final int cacheMissCount,
  required final int currentSizeBytes,
  required final int entryCount,
  required final int evictedBytes,
  required final int evictedEntryCount,
  required final int evictionCount,
  required final int maxSizeBytes,
  required final int putCount,
  required final int storeHitCount,
  required final int storeMissCount,
  final int? cleanUpCount,
  final int? deletedBytes,
  final int? deletedFileCount,
  final int? failedReadCount,
  final int? failedWriteCount,
  final int? fileCacheSizeBytes,
  final String? fileStorePath,
  final int? fileStoreSizeBytes,
  final int? lastCleanUpTimeMilliseconds,
  final int? lastScannedFileCount,
  final int? pendingWriteCount,
  final int? readCount,
  final int? readMissCount,
  final int? singleFileBucketRebuildCount,
  final int? singleFileCapacityDiscardedBatchCount,
  final int? singleFileCommitCount,
  final int? singleFileCommittedEntryCount,
  final int? singleFileCommittedValueBytes,
  final int? singleFileDataBytes,
  final int? singleFileEvictedForSpaceEntryCount,
  final int? singleFileEvictedFromFullBucketEntryCount,
  final int? singleFileFreeDataBytes,
  final int? singleFileOversizedValueBytes,
  final int? singleFileOversizedValueCount,
  final int? singleFilePendingEntryCount,
  final int? singleFileResetCount,
  final String? singleFileStorePath,
  final int? singleFileTableSlotCount,
  final int? writeBytes,
  final int? writeCount,
}) {
  bool get usesFileByteStore => fileStorePath != null;
}

/// Manages the [ByteStore] hierarchy used by `AnalysisServer`, including
/// memory caching, optional disk persistence, timing collection, statistics,
/// and flushing/closing.
class ServerByteStore {
  /// The [ByteStore] exposed to analysis drivers and operations.
  late final ByteStore byteStore;

  /// A [TimingByteStore] that records operations on the on-disk byte store.
  TimingByteStore? _timingByteStore;

  /// The file byte store created by this manager, if any.
  EvictingFileByteStore? _fileByteStore;

  /// The memory caching byte store created by this manager or provided
  /// externally, if any.
  MemoryCachingByteStore? _memoryCachingByteStore;

  /// The single-file byte store owned by this manager, if any.
  SingleFileByteStore? _singleFileByteStore;

  new(
    ResourceProvider resourceProvider, {
    ByteStore? providedByteStore,
    bool disableFileByteStore = false,
    bool useSingleFileByteStore = false,
  }) {
    byteStore = _createByteStore(
      resourceProvider,
      providedByteStore: providedByteStore,
      disableFileByteStore: disableFileByteStore,
      useSingleFileByteStore: useSingleFileByteStore,
    );
  }

  /// Statistics for the byte stores managed by this instance, or `null` if a
  /// non-caching byte store was provided externally.
  AnalysisServerByteStoreStats? get stats {
    var memoryByteStore = _memoryCachingByteStore;
    if (memoryByteStore == null) {
      return null;
    }

    var fileByteStore = _fileByteStore;
    var singleFileByteStore = _singleFileByteStore;
    var singleFileStatistics = singleFileByteStore?.statistics;
    return AnalysisServerByteStoreStats(
      cacheHitCount: memoryByteStore.cacheHitCount,
      cacheMissCount: memoryByteStore.cacheMissCount,
      currentSizeBytes: memoryByteStore.currentSizeBytes,
      entryCount: memoryByteStore.entryCount,
      evictedBytes: memoryByteStore.evictedBytes,
      evictedEntryCount: memoryByteStore.evictedEntryCount,
      evictionCount: memoryByteStore.evictionCount,
      maxSizeBytes: memoryByteStore.maxSizeBytes,
      putCount: memoryByteStore.putCount,
      storeHitCount: memoryByteStore.storeHitCount,
      storeMissCount: memoryByteStore.storeMissCount,
      cleanUpCount: fileByteStore?.cleanUpCount,
      deletedBytes: fileByteStore?.deletedBytes,
      deletedFileCount: fileByteStore?.deletedFileCount,
      failedReadCount: fileByteStore?.failedReadCount,
      failedWriteCount: fileByteStore?.failedWriteCount,
      fileCacheSizeBytes: fileByteStore?.maxSizeBytes,
      fileStorePath: fileByteStore?.cachePath,
      fileStoreSizeBytes: fileByteStore?.lastKnownSizeBytes,
      lastCleanUpTimeMilliseconds: fileByteStore?.lastCleanUpTimeMilliseconds,
      lastScannedFileCount: fileByteStore?.lastScannedFileCount,
      pendingWriteCount: fileByteStore?.pendingWriteCount,
      readCount: fileByteStore?.readCount,
      readMissCount: fileByteStore?.readMissCount,
      writeBytes: fileByteStore?.writeBytes,
      writeCount: fileByteStore?.writeCount,
      singleFileStorePath: singleFileByteStore?.filePath,
      singleFilePendingEntryCount: singleFileByteStore?.pendingEntryCount,
      singleFileDataBytes: singleFileByteStore == null
          ? null
          : singleFileByteStore.dataPageCount * pageSize,
      singleFileFreeDataBytes: singleFileByteStore == null
          ? null
          : singleFileByteStore.freeDataPageCount * pageSize,
      singleFileBucketRebuildCount: singleFileStatistics?.bucketRebuildCount,
      singleFileCapacityDiscardedBatchCount:
          singleFileStatistics?.capacityDiscardedBatchCount,
      singleFileCommitCount: singleFileStatistics?.commitCount,
      singleFileCommittedEntryCount: singleFileStatistics?.committedEntryCount,
      singleFileCommittedValueBytes: singleFileStatistics?.committedValueBytes,
      singleFileEvictedForSpaceEntryCount:
          singleFileStatistics?.evictedForSpaceEntryCount,
      singleFileEvictedFromFullBucketEntryCount:
          singleFileStatistics?.evictedFromFullBucketEntryCount,
      singleFileOversizedValueBytes: singleFileStatistics?.oversizedValueBytes,
      singleFileOversizedValueCount: singleFileStatistics?.oversizedValueCount,
      singleFileResetCount: singleFileStatistics?.resetCount,
      singleFileTableSlotCount: singleFileByteStore?.tableSlotCount,
    );
  }

  /// The timings of the on-disk byte store, or `null` if there is none.
  TimingByteStore? get timingByteStore => _timingByteStore;

  /// Flushes any pending single-file byte store entries.
  void flush() {
    _singleFileByteStore?.flush();
  }

  /// Flushes and closes any persistent byte stores owned by this instance.
  Future<void> shutdown() async {
    await _fileByteStore?.flush();
    _singleFileByteStore?.close();
  }

  /// Returns the number of committed entries in each hash table bucket of the
  /// single file byte store, or `null` if the server does not use it.
  ///
  /// Unlike [stats], this reads the whole table from the disk.
  Uint8List? singleFileTableBucketEntryCounts() =>
      _singleFileByteStore?.tableBucketEntryCounts();

  /// Ends the current timings period and starts a new one tagged with [reason],
  /// if timing is being tracked.
  void startPeriod(String reason, {bool isMilestone = false}) {
    _timingByteStore?.startPeriod(reason, isMilestone: isMilestone);
  }

  /// If the state location can be accessed and disk caching is enabled, returns
  /// a memory-cached file byte store; otherwise returns a memory-only byte
  /// store (or [providedByteStore] if supplied).
  ByteStore _createByteStore(
    ResourceProvider resourceProvider, {
    ByteStore? providedByteStore,
    required bool disableFileByteStore,
    required bool useSingleFileByteStore,
  }) {
    const M = 1024 * 1024 /*1 MiB*/;
    const G = 1024 * 1024 * 1024 /*1 GiB*/;

    const fileCacheSize = 4 * G;
    const memoryCacheSize = 256 * M;

    if (providedByteStore != null) {
      if (providedByteStore is MemoryCachingByteStore) {
        _memoryCachingByteStore = providedByteStore;
      }
      return providedByteStore;
    }

    if (disableFileByteStore) {
      return _memoryCachingByteStore = MemoryCachingByteStore(
        NullByteStore(),
        memoryCacheSize,
      );
    }

    if (resourceProvider is OverlayResourceProvider) {
      resourceProvider = resourceProvider.baseProvider;
    }
    var baseProvider = resourceProvider is TimingResourceProvider
        ? resourceProvider.baseProvider
        : resourceProvider;
    if (baseProvider is PhysicalResourceProvider) {
      ByteStore? fileByteStore;
      if (useSingleFileByteStore) {
        var folder = resourceProvider.getStateLocation('.analysis-cache');
        if (folder != null) {
          fileByteStore = _singleFileByteStore =
              SingleFileByteStore.inDirectory(
                folder.path,
                filePageCountLog2: 22, // 4 GiB, including metadata.
                tableSlotCountLog2: 19, // 524,288 entries.
                bufferPoolCapacityLog2: 12, // 4 MiB of cached pages.
                maxPendingValueBytes: M,
                maxPendingEntryCount: 64,
              );
        }
      } else {
        var folder = resourceProvider.getStateLocation('.analysis-driver');
        if (folder != null) {
          fileByteStore = _fileByteStore = EvictingFileByteStore(
            folder.path,
            fileCacheSize,
          );
        }
      }
      if (fileByteStore != null) {
        var timingByteStore = _timingByteStore = TimingByteStore(fileByteStore);
        _singleFileByteStore?.onFlush = timingByteStore.recordFlush;
        return _memoryCachingByteStore = MemoryCachingByteStore(
          timingByteStore,
          memoryCacheSize,
        );
      }
    }

    return _memoryCachingByteStore = MemoryCachingByteStore(
      NullByteStore(),
      memoryCacheSize,
    );
  }
}
