// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:analyzer/src/dart/analysis/single_file_byte_store.dart';
import 'package:analyzer/src/dart/analysis/xxh64.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileStorageTest);
    defineReflectiveTests(SingleFileByteStoreFileTest);
    defineReflectiveTests(SingleFileByteStoreInDirectoryTest);
    defineReflectiveTests(SingleFileByteStoreTest);
  });
}

@reflectiveTest
class FileStorageTest {
  void test_read_partialReadsAndSeeks() {
    var file = _TestFile()..bytes.addAll([0, 1, 2, 3, 4, 5, 6, 7]);
    var storage = FileStorage(file);

    expect(storage.read(2, 5), [2, 3, 4, 5, 6]);
    expect(storage.read(0, 3), [0, 1, 2]);
  }

  void test_read_unexpectedEndOfFile() {
    var file = _TestFile()..bytes.addAll([0, 1, 2]);
    var storage = FileStorage(file);
    file.endOfFile = true;

    expect(() => storage.read(0, 3), throwsRangeError);
  }

  void test_withExclusiveAccess_releasesLockAfterFailure() {
    var file = _TestFile();
    var storage = FileStorage(file);

    expect(
      () => storage.withExclusiveAccess<void>(() {
        expect(file.locked, isTrue);
        throw const FileSystemException('Simulated operation failure');
      }),
      throwsA(isA<FileSystemException>()),
    );
    expect(file.locked, isFalse);
    expect(file.unlockCount, 1);
    expect(storage.withExclusiveAccess(() => 42), 42);
    expect(file.unlockCount, 2);
  }

  void test_write_seeksAndPreservesOtherBytes() {
    var file = _TestFile()..bytes.addAll([0, 1, 2, 3, 4, 5]);
    var storage = FileStorage(file);

    storage.write(3, Uint8List.fromList([8, 9]));
    storage.write(1, Uint8List.fromList([7]));

    expect(file.bytes, [0, 7, 2, 8, 9, 5]);
  }
}

@reflectiveTest
class SingleFileByteStoreFileTest {
  late Directory directory;
  late _TestFile file;
  late _TestFileSource fileSource;

  void setUp() {
    directory = Directory.systemTemp.createTempSync('byte_store_');
    file = _TestFile();
    fileSource = _TestFileSource(file);
  }

  void tearDown() {
    directory.deleteSync(recursive: true);
  }

  void test_close_closesFileWhenFlushFails() {
    var store = _open();
    store.putGet('key', Uint8List.fromList([1, 2, 3]));
    file.failFlush = true;

    expect(store.close, throwsA(isA<FileSystemException>()));
    expect(file.closeCount, 1);
    expect(() => store.get('key'), throwsStateError);
    expect(store.flush, throwsStateError);
    expect(() => store.putGet('other', Uint8List(1)), throwsStateError);
    store.close();
    expect(file.closeCount, 1);
  }

  void test_close_flushesAndClosesFileOnce() {
    var store = _open();
    expect(store.filePath, 'cache');
    store.putGet('key', Uint8List.fromList([1, 2, 3]));
    expect(store.pendingEntryCount, 1);

    store.close();
    expect(store.pendingEntryCount, 0);
    expect(store.statistics.committedEntryCount, 1);
    expect(file.closeCount, 1);
    store.close();
    expect(file.closeCount, 1);
    expect(() => store.get('key'), throwsStateError);
    expect(store.flush, throwsStateError);
    expect(() => store.putGet('other', Uint8List(1)), throwsStateError);
  }

  void test_close_leavesBorrowedFileOpen() {
    var store = SingleFileByteStore(
      FileStorage(file),
      filePageCountLog2: 11,
      tableSlotCountLog2: 7,
      bufferPoolCapacityLog2: 2,
      maxPendingValueBytes: 1024,
      maxPendingEntryCount: 64,
    );
    store.putGet('key', Uint8List.fromList([1, 2, 3]));

    store.close();
    expect(store.filePath, isNull);
    expect(store.pendingEntryCount, 0);
    expect(store.statistics.committedEntryCount, 1);
    expect(file.closeCount, 0);
  }

  void test_inDirectory_closesFileWhenInitializationFails() {
    file.failLock = true;
    expect(_open, throwsA(isA<FileSystemException>()));
    expect(file.closeCount, 1);
  }

  void test_inDirectory_closesFileWhenLengthReadFails() {
    file.failLength = true;
    expect(_open, throwsA(isA<FileSystemException>()));
    expect(file.closeCount, 1);
  }

  SingleFileByteStore _open() {
    return IOOverrides.runZoned(
      () => SingleFileByteStore.inDirectory(
        directory.path,
        filePageCountLog2: 11,
        tableSlotCountLog2: 7,
        bufferPoolCapacityLog2: 2,
        maxPendingValueBytes: 1024,
        maxPendingEntryCount: 64,
      ),
      createFile: (path) {
        expect(
          path,
          '${directory.path}${Platform.pathSeparator}'
          'v1-page1024-file11-table7.bin',
        );
        return fileSource;
      },
    );
  }
}

@reflectiveTest
class SingleFileByteStoreInDirectoryTest {
  late Directory directory;
  final List<SingleFileByteStore> _stores = [];

  void setUp() {
    directory = Directory.systemTemp.createTempSync('byte_store_');
  }

  void tearDown() {
    for (var store in _stores) {
      store.close();
    }
    directory.deleteSync(recursive: true);
  }

  void test_deletesStaleCacheFiles() {
    _createFile('v1-page1024-file12-table7.bin', age: const Duration(days: 31));
    _createFile('v0-page512-file12-table7.bin', age: const Duration(days: 31));
    _createFile('v1-page1024-file13-table7.bin', age: const Duration(days: 29));
    _createFile('notes.txt', age: const Duration(days: 31));
    _createFile('other.bin', age: const Duration(days: 31));
    _createFile('v1-notes.txt', age: const Duration(days: 31));

    _open(filePageCountLog2: 11);
    expect(directory.listSync().map((e) => e.uri.pathSegments.last).sorted(), [
      'notes.txt',
      'other.bin',
      'v1-notes.txt',
      'v1-page1024-file11-table7.bin',
      'v1-page1024-file13-table7.bin',
    ]);
  }

  void test_differentConfigurations_useSeparateFiles() {
    var store11 = _open(filePageCountLog2: 11);
    store11.putGet('key', Uint8List.fromList([1, 2, 3]));
    store11.close();

    var store12 = _open(filePageCountLog2: 12);
    expect(store12.filePath, isNot(store11.filePath));
    expect(store12.get('key'), isNull);
    store12.putGet('key', Uint8List.fromList([4, 5, 6]));
    store12.close();

    store11 = _open(filePageCountLog2: 11);
    expect(store11.get('key'), [1, 2, 3]);
  }

  void test_fileName() {
    var store = _open(filePageCountLog2: 11);
    expect(
      store.filePath,
      '${directory.path}${Platform.pathSeparator}'
      'v1-page1024-file11-table7.bin',
    );
  }

  void test_markAsUsedFails_keepsOwnFile() {
    // Create a valid store file.
    var store = _open(filePageCountLog2: 11);
    store.putGet('key', Uint8List.fromList([1, 2, 3]));
    store.close();

    // Make it stale.
    var file = File(store.filePath!);
    file.setLastModifiedSync(DateTime.now().subtract(const Duration(days: 31)));

    // Reopen it, but fail to mark it as used.
    store = IOOverrides.runZoned(
      () => _open(filePageCountLog2: 11),
      createFile: (path) {
        expect(path, file.path);
        return _SetLastModifiedFailingFile(file);
      },
    );

    // Still stale, but not deleted as such.
    expect(file.existsSync(), isTrue);
    var age = DateTime.now().difference(file.lastModifiedSync());
    expect(age, greaterThan(const Duration(days: 30)));
    expect(store.get('key'), [1, 2, 3]);
  }

  void test_marksOwnFileAsUsed() {
    // Create a valid store file.
    var store = _open(filePageCountLog2: 11);
    store.putGet('key', Uint8List.fromList([1, 2, 3]));
    store.close();

    // Make it stale.
    var file = File(store.filePath!);
    file.setLastModifiedSync(DateTime.now().subtract(const Duration(days: 31)));

    // Reopening without a commit marks it as used.
    store = _open(filePageCountLog2: 11);
    var age = DateTime.now().difference(file.lastModifiedSync());
    expect(age, lessThan(const Duration(days: 1)));

    // The file was not reset, which would also update its modification time.
    expect(store.get('key'), [1, 2, 3]);
  }

  void test_reopensValuesCommittedByClose() {
    var store = _open(filePageCountLog2: 11);
    store.putGet('key', Uint8List.fromList([1, 2, 3]));
    store.close();

    store = _open(filePageCountLog2: 11);
    expect(store.get('key'), [1, 2, 3]);
  }

  File _createFile(String name, {required Duration age}) {
    var file = File('${directory.path}${Platform.pathSeparator}$name')
      ..writeAsBytesSync([0]);
    file.setLastModifiedSync(DateTime.now().subtract(age));
    return file;
  }

  SingleFileByteStore _open({required int filePageCountLog2}) {
    var store = SingleFileByteStore.inDirectory(
      directory.path,
      filePageCountLog2: filePageCountLog2,
      tableSlotCountLog2: 7,
      bufferPoolCapacityLog2: 2,
      maxPendingValueBytes: 1024,
      maxPendingEntryCount: 64,
    );
    _stores.add(store);
    return store;
  }
}

/// Reopening preserves the storage bytes but creates a fresh store with its own
/// queue and page cache.
@reflectiveTest
class SingleFileByteStoreTest {
  final _MemoryStorage storage = _MemoryStorage();
  late SingleFileByteStore store;

  void setUp() {
    _open();
  }

  void test_constructor_emptyStorage_notCountedAsReset() {
    // `setUp` opened the store on empty storage.
    expect(store.statistics.resetCount, 0);
    expect(store.freeDataPageCount, store.dataPageCount);
  }

  void test_constructor_recoversInvalidFile() {
    storage.truncate(3);
    storage.write(0, Uint8List.fromList([1, 2, 3]));

    // No exception, just reset.
    _open();
    expect(store.statistics.resetCount, 1);

    // It is valid, but empty.
    expect(store.get('missing'), isNull);

    // We can put new data.
    store.putGet('key', _value(10));
    store.flush();

    _open();
    expect(store.get('key'), _value(10));
  }

  void test_constructor_rejectsTableSmallerThanOnePage() {
    store.putGet('key', _value(10));
    store.flush();

    expect(() => _open(tableSlotCountLog2: 6), throwsRangeError);

    _open();
    expect(store.get('key'), _value(10));
  }

  void test_constructor_resetsWhenDataReclamationClockHandIsInvalid() {
    store.putGet('key', _value(10));
    store.flush();

    // Keep the checksum valid to exercise the cursor's range check.
    var header = storage.read(0, pageSize);
    ByteData.sublistView(header)
      ..setUint32(32, store.tableSlotCount, Endian.little)
      ..setUint32(
        headerChecksumOffset,
        xxh64(header.sublist(0, headerChecksumOffset)) & 0xFFFFFFFF,
        Endian.little,
      );
    storage.write(0, header);

    _open();
    expect(store.get('key'), isNull);
    store.putGet('new_key', _value(20));
    store.flush();
    _open();
    expect(store.get('new_key'), _value(20));
  }

  void test_constructor_resetsWhenFilePageCountChanges() {
    // Grow and then shrink the storage, checking that each reset uses the new
    // size and that subsequent reopening preserves newly committed entries.
    for (var filePageCountLog2 in [12, 11]) {
      store.putGet('old_key', _value(10));
      store.flush();

      _open(filePageCountLog2: filePageCountLog2);
      expect(storage.length, (1 << filePageCountLog2) * pageSize);
      expect(store.get('old_key'), isNull);
      expect(store.get('new_key'), isNull);
      store.putGet('new_key', _value(20));
      store.flush();

      _open(filePageCountLog2: filePageCountLog2);
      expect(store.get('old_key'), isNull);
      expect(store.get('new_key'), _value(20));
    }
  }

  void test_constructor_resetsWhenHeaderChecksumIsCorrupt() {
    store.putGet('key', _value(10));
    store.flush();

    // Corrupt the upper half of the 32-bit header checksum.
    var header = storage.read(0, pageSize);
    header[headerChecksumOffset + 2] ^= 0x80;
    storage.write(0, header);

    _open();
    expect(store.statistics.resetCount, 1);
    expect(store.get('key'), isNull);
    store.putGet('new_key', _value(20));
    store.flush();
    _open();
    expect(store.get('new_key'), _value(20));
  }

  void test_constructor_resetsWhenTableSlotCountChanges() {
    store.putGet('key', _value(10));
    store.flush();

    // No exception, just reset.
    _open(tableSlotCountLog2: 8);
    expect(store.statistics.resetCount, 1);
    expect(store.tableSlotCount, 256);
    expect(store.get('key'), isNull);
    store.putGet('new_key', _value(20));
    store.flush();

    // The same configuration: preserved new data.
    _open(tableSlotCountLog2: 8);
    expect(store.get('key'), isNull);
    expect(store.get('new_key'), _value(20));
  }

  void test_flush_callsOnFlush() {
    var flushedBytes = <int>[];
    store.onFlush = (valueBytes, elapsed) {
      expect(elapsed, greaterThanOrEqualTo(Duration.zero));
      flushedBytes.add(valueBytes);
    };

    store.putGet('a', _value(10));
    store.putGet('b', _value(20));
    store.flush();
    expect(flushedBytes, [30]);

    // Nothing pending, so no flush.
    store.flush();
    expect(flushedBytes, [30]);
  }

  void test_flush_continuesDataReclamationAfterReopening() {
    var firstKey = _keyForSlot(10);
    var secondKey = _keyForSlot(90);
    var thirdKey = _keyForSlot(0);
    var fourthKey = _keyForSlot(50);
    // Two values fit, but every subsequent insertion requires one eviction.
    var value = _value(storage.length * 3 ~/ 8);
    store.putGet(firstKey, value);
    store.putGet(secondKey, value);
    store.close();

    _open();
    store.putGet(thirdKey, value);
    store.close();

    _open();
    expect(store.get(firstKey), isNull);
    store.putGet(fourthKey, value);
    store.flush();

    // The sweep resumes after slot 10, preserving the new entry at slot 0.
    expect(store.get(secondKey), isNull);
    expect(store.get(thirdKey), value);
    expect(store.get(fourthKey), value);
  }

  void test_flush_continuesDataReclamationFromAnotherStore() {
    var firstKey = _keyForSlot(10);
    var secondKey = _keyForSlot(90);
    var thirdKey = _keyForSlot(0);
    var fourthKey = _keyForSlot(50);
    var smallKey = _keyForSlot(120);
    var value = _value(storage.length * 3 ~/ 8);
    store.putGet(firstKey, value);
    store.putGet(secondKey, value);
    store.close();

    _open();
    var storeA = store;
    _open();
    var storeB = store;

    storeA.putGet(thirdKey, value);
    storeA.flush();
    expect(storeA.get(firstKey), isNull);

    // B was opened before A reclaimed pages. Its insertion-only commit must
    // preserve A's cursor instead of publishing a stale process-local cursor.
    storeB.putGet(smallKey, _value(10));
    storeB.flush();
    expect(storeB.statistics.evictedForSpaceEntryCount, 0);
    expect(storeB.statistics.evictedFromFullBucketEntryCount, 0);
    storeB.putGet(fourthKey, value);
    storeB.flush();

    // Continuing after slot 10 evicts slot 90 rather than restarting at 0.
    expect(storeA.get(secondKey), isNull);
    expect(storeA.get(thirdKey), value);
    expect(storeA.get(fourthKey), value);
    expect(storeA.get(smallKey), _value(10));
  }

  void test_flush_discardsOversizedBatchWithoutEvicting() {
    _open(maxPendingValueBytes: 4 * 1024 * 1024);
    store.putGet('existing', _value(10));
    store.flush();

    // Each value fits, but the combined batch payload exceeds the 2 MiB
    // storage even before accounting for record and overflow metadata pages.
    var value = _value(768 * 1024);
    expect(value.length, lessThanOrEqualTo(store.maxValueLength));
    for (var i = 0; i < 3; i++) {
      store.putGet('key_$i', value);
    }
    expect(store.pendingEntryCount, 3);
    expect(store.pendingValueBytes, 3 * value.length);
    expect(store.statistics.oversizedValueCount, 0);
    var writeCount = storage.writeCount;
    var commitCount = store.statistics.commitCount;

    store.flush();
    expect(store.statistics.capacityDiscardedBatchCount, 1);
    expect(store.statistics.evictedForSpaceEntryCount, 0);
    expect(store.statistics.evictedFromFullBucketEntryCount, 0);
    expect(store.statistics.commitCount, commitCount);
    expect(storage.writeCount, writeCount);
    expect(store.pendingEntryCount, 0);
    expect(store.pendingValueBytes, 0);
    expect(store.get('existing'), _value(10));

    _open();
    expect(store.get('existing'), _value(10));
    for (var i = 0; i < 3; i++) {
      expect(store.get('key_$i'), isNull);
    }
  }

  void test_flush_evictsUnreadEntries_whenNotEnoughFreeDataPages() {
    // Use two buckets with ample table capacity, so only data-page pressure
    // causes eviction. The sweep encounters the read entry first.
    _open(tableSlotCountLog2: 8);

    // The first entry in the 0-th bucket.
    var readKey = _keyForSlot(0);

    // The first entry in the 1-th bucket.
    var unreadKey = _keyForSlot(128);

    // An entry in the 0-th bucket.
    var newKey = _keyForSlot(64);

    // 768 KiB * 2 < 2 MiB, both fit
    var value = _value(768 * 1024);
    store.putGet(readKey, value);
    store.putGet(unreadKey, value);
    store.flush();

    // Insertion sets CLOCK bits too.
    // Reopen to clear them.
    // Then mark only the first entry as recently read.
    _open(tableSlotCountLog2: 8);
    expect(store.get(readKey), value);

    // 768 KiB * 3 > 2 MiB, needs data-page pressure eviction
    store.putGet(newKey, value);
    store.flush();

    // The eviction happened, CLOCK encountered `readKey` first, but it was
    // read, so `unreadKey` was evicted instead.
    expect(store.statistics.evictedForSpaceEntryCount, 1);
    expect(store.statistics.evictedFromFullBucketEntryCount, 0);
    expect(store.get(readKey), value);
    expect(store.get(unreadKey), isNull);
    expect(store.get(newKey), value);

    _open(tableSlotCountLog2: 8);
    expect(store.get(readKey), value);
    expect(store.get(unreadKey), isNull);
    expect(store.get(newKey), value);
  }

  void test_flush_evictsUnreadEntries_whenTableBucketIsFull() {
    // Fill the single bucket with one key per home slot. Small values leave
    // plenty of free data pages, so only bucket pressure causes eviction.
    var keys = [
      for (var slot = 0; slot < store.tableSlotCount; slot++) _keyForSlot(slot),
    ];
    for (var i = 0; i < keys.length; i++) {
      store.putGet(keys[i], _value(10, startByte: i));
    }
    store.flush();

    // Clear insertion CLOCK bits, then protect entries at the start of the
    // sweep. Ignoring second chances would evict these entries first.
    _open();
    for (var i = 0; i < 8; i++) {
      expect(store.get(keys[i]), _value(10, startByte: i));
    }

    // By default tests run with 1 hash table bucket.
    store.putGet('new_key', _value(20));
    store.flush();
    expect(store.statistics.evictedForSpaceEntryCount, 0);
    expect(store.statistics.evictedFromFullBucketEntryCount, 16);

    void checkEntries() {
      // The sweep skips the 8 read entries, evicts the next 16,
      // and stops without evicting any later entries.
      for (var i = 0; i < keys.length; i++) {
        if (i >= 8 && i < 24) {
          expect(store.get(keys[i]), isNull, reason: keys[i]);
        } else {
          expect(store.get(keys[i]), _value(10, startByte: i), reason: keys[i]);
        }
      }
      expect(store.get('new_key'), _value(20));
    }

    checkEntries();

    _open();
    checkEntries();
  }

  void test_flush_evictsWhenFreeDataPagesAreInsufficient() {
    var storageLength = storage.length;

    // Each value uses 3/8 of storage: two fit, but three require eviction.
    var valueLength = storageLength * 3 ~/ 8;
    for (var i = 0; i < 4; i++) {
      store.putGet('key_$i', _value(valueLength, startByte: i));
      store.flush();
      expect(store.get('key_$i'), _value(valueLength, startByte: i));
      expect(storage.length, storageLength);
    }

    // We know that we tried to put too much data.
    // So we expect eviction, but don't need to know how much exactly.
    expect(store.statistics.evictedForSpaceEntryCount, greaterThan(0));
    expect(store.statistics.evictedFromFullBucketEntryCount, 0);

    _open();

    // The last value is definitely here.
    expect(store.get('key_3'), _value(valueLength, startByte: 3));

    // But we also evicted at least some values.
    var missingCount = 0;
    for (var i = 0; i < 3; i++) {
      var value = store.get('key_$i');
      if (value == null) {
        missingCount++;
      } else {
        expect(value, _value(valueLength, startByte: i));
      }
    }
    expect(missingCount, greaterThan(0));
  }

  void test_flush_evictsWhenTableBucketIsFull() {
    // This test uses single 128-entry bucket.
    var entryCount = store.tableSlotCount * 3;
    var storageLength = storage.length;
    for (var i = 0; i < entryCount; i++) {
      store.putGet('key_$i', _value(10, startByte: i));
      store.flush();
      expect(store.get('key_$i'), _value(10, startByte: i));
    }

    // We tried to put 3x more entries than the capacity.
    // So, some were evicted.
    expect(store.statistics.evictedForSpaceEntryCount, 0);
    expect(store.statistics.evictedFromFullBucketEntryCount, greaterThan(0));

    // The storage size is fixed, does not grow with number of entries.
    expect(storage.length, storageLength);

    _open();

    // At least the last entry is alive.
    expect(
      store.get('key_${entryCount - 1}'),
      _value(10, startByte: entryCount - 1),
    );

    var retainedCount = 0;
    for (var i = 0; i < entryCount; i++) {
      if (store.get('key_$i') case var value?) {
        expect(value, _value(10, startByte: i));
        retainedCount++;
      }
    }

    // We put 3x table capacity, so end up with the full bucket.
    expect(retainedCount, store.tableSlotCount);
  }

  void test_flush_persistsPendingValues() {
    store.putGet('a', _value(10));
    store.putGet('b', _value(2000, startByte: 1));
    expect(store.get('a'), _value(10));
    expect(store.get('b'), _value(2000, startByte: 1));
    expect(store.pendingEntryCount, 2);

    store.flush();
    expect(store.pendingEntryCount, 0);
    expect(store.pendingValueBytes, 0);

    _open();
    expect(store.get('a'), _value(10));
    expect(store.get('b'), _value(2000, startByte: 1));
  }

  void test_flush_reusesSpaceWhenReplacingCommittedValue() {
    store.putGet('other', _value(10));
    store.flush();

    // The cumulative writes exceed the file size. Replacements must reclaim
    // their old pages without evicting the unrelated entry.
    for (var i = 0; i < 8; i++) {
      store.putGet('key', _value(400 * 1024, startByte: i));
      store.flush();
      expect(store.get('key'), _value(400 * 1024, startByte: i));
      expect(store.get('other'), _value(10));
    }
    expect(store.statistics.evictedForSpaceEntryCount, 0);
    expect(store.statistics.evictedFromFullBucketEntryCount, 0);

    _open();
    expect(store.get('key'), _value(400 * 1024, startByte: 7));
    expect(store.get('other'), _value(10));
  }

  void test_flush_writeFailurePreservesCommittedValues() {
    store.putGet('key', _value(10));
    store.flush();
    var snapshot = storage.read(0, storage.length);

    // Count every write in a replacement, including the final header write.
    var writeCountBefore = storage.writeCount;
    store.putGet('key', _value(20, startByte: 1));
    store.flush();
    var batchWriteCount = storage.writeCount - writeCountBefore;
    expect(batchWriteCount, greaterThan(0));

    for (var writeIndex = 0; writeIndex < batchWriteCount; writeIndex++) {
      storage.write(0, snapshot);
      _open();
      store.putGet('key', _value(20, startByte: 1));
      storage.writesBeforeFailure = writeIndex;

      expect(
        store.flush,
        throwsA(isA<FileSystemException>()),
        reason: 'writeIndex=$writeIndex',
      );
      expect(store.pendingEntryCount, 1);

      // Each failure occurs before publication. Recover with a fresh store
      // rather than retrying operations on the failed instance.
      _open();
      expect(store.get('key'), _value(10), reason: 'writeIndex=$writeIndex');
    }
  }

  void test_freeDataPageCount() {
    store.putGet('key', _value(10));
    store.flush();
    expect(store.freeDataPageCount, store.dataPageCount - 1);

    // Another instance reads it from the header.
    _open();
    expect(store.freeDataPageCount, store.dataPageCount - 1);
  }

  void test_get_hashCollision() {
    // These distinct keys all have the same 32-bit FNV-1a hash.
    const hash = 0x091b8ddd;
    const key1 = '0288d733647696b9';
    const key2 = '9482d072788c8ad1';
    const key3 = 'c3d3f552a1980882';

    expect(SingleFileByteStore.hashKey(key1), hash);
    expect(SingleFileByteStore.hashKey(key2), hash);
    expect(SingleFileByteStore.hashKey(key3), hash);

    store.putGet(key1, _value(20));
    store.putGet(key2, _value(20, startByte: 1));
    store.flush();

    _open();
    expect(store.get(key1), _value(20));
    expect(store.get(key2), _value(20, startByte: 1));
    expect(store.get(key3), isNull);
  }

  void test_get_observesCommitsFromAnotherStore() {
    // Bigger cache size to validate that we discard cached pages because
    // of external changes, not just because of capacity.
    _open(bufferPoolCapacityLog2: 5);
    var storeA = store;

    _open(bufferPoolCapacityLog2: 5);
    var storeB = store;

    // No such key initially.
    expect(storeA.get('key'), isNull);
    expect(storeB.get('key'), isNull);

    // Put through A.
    storeA.putGet('key', _value(10));
    storeA.flush();

    // Can get through B.
    expect(storeB.get('key'), _value(10));

    // Update through A.
    storeA.putGet('key', _value(20, startByte: 1));
    storeA.flush();

    // Can see the updated value through B.
    expect(storeB.get('key'), _value(20, startByte: 1));

    // Put a different key through B.
    storeB.putGet('other_key', _value(30, startByte: 2));
    storeB.flush();

    // Can see both keys through A.
    expect(storeA.get('other_key'), _value(30, startByte: 2));
    expect(storeA.get('key'), _value(20, startByte: 1));
  }

  void test_get_randomBitCorruption() {
    // Fill over 90% of storage with inline, continuation, and overflow values.
    var valueLengths = [
      0,
      1,
      17,
      pageSize - 32,
      pageSize,
      2 * pageSize + 17,
      32 * pageSize + 3,
      for (var i = 0; i < 6; i++) 320 * pageSize + i,
    ];
    var valueBytes = valueLengths.fold(0, (sum, length) => sum + length);
    expect(valueBytes, greaterThan(storage.length * 9 ~/ 10));
    for (var i = 0; i < valueLengths.length; i++) {
      store.putGet('key_$i', _value(valueLengths[i], startByte: i));
    }
    store.flush();
    expect(store.pendingEntryCount, 0);
    expect(store.statistics.evictedForSpaceEntryCount, 0);
    expect(store.statistics.evictedFromFullBucketEntryCount, 0);
    expect(store.statistics.capacityDiscardedBatchCount, 0);

    // Expected values, generated once: generating them in each corruption
    // iteration below takes longer than everything else in this test.
    var values = [
      for (var i = 0; i < valueLengths.length; i++)
        _value(valueLengths[i], startByte: i),
    ];

    // Verify every value after reopening before taking the clean snapshot.
    _open();
    for (var i = 0; i < values.length; i++) {
      _expectBytes(
        store.get('key_$i'),
        values[i],
        reason: 'key_$i in clean storage',
      );
    }

    var snapshot = storage.read(0, storage.length);

    const seed = 0x5eed;
    var random = math.Random(seed);

    for (var iteration = 0; iteration < 100; iteration++) {
      var offset = random.nextInt(snapshot.length);
      var bit = random.nextInt(8);
      storage.write(0, snapshot);
      storage.write(
        offset,
        Uint8List.fromList([snapshot[offset] ^ (1 << bit)]),
      );

      expect(
        () {
          _open();
          for (var i = 0; i < values.length; i++) {
            var key = 'key_$i';
            var value = store.get(key);
            if (value != null) {
              _expectBytes(value, values[i], reason: key);
            }
          }
        },
        returnsNormally,
        reason:
            'seed=$seed iteration=$iteration '
            'offset=$offset bit=$bit',
      );
    }
  }

  void test_get_resetsWhenValueIsCorrupt() {
    var value = Uint8List(100)..fillRange(0, 100, 0xAB);
    store.putGet('key', value);
    store.flush();

    // Find the end of the value bytes in storage, and corrupt the last one.
    var bytes = storage.read(0, storage.length);
    var offset = 0;
    for (var runLength = 0; runLength < value.length; offset++) {
      runLength = bytes[offset] == 0xAB ? runLength + 1 : 0;
    }
    storage.write(offset - 1, Uint8List.fromList([0]));

    _open();
    expect(store.statistics.resetCount, 0);
    expect(store.get('key'), isNull);
    expect(store.statistics.resetCount, 1);
  }

  void test_get_returnedBytesRemainValidAfterOtherOperations() {
    store.putGet('key', _value(2000));
    store.flush();
    var original = store.get('key')!;

    store.putGet('key', _value(3000, startByte: 1));
    store.flush();
    for (var i = 0; i < 16; i++) {
      store.putGet('other_$i', _value(2000, startByte: i));
    }
    store.flush();
    for (var i = 0; i < 16; i++) {
      expect(store.get('other_$i'), _value(2000, startByte: i));
    }

    expect(original, _value(2000));
    expect(store.get('key'), _value(3000, startByte: 1));
  }

  void test_get_returnsNullForMissingKey() {
    expect(store.get('missing'), isNull);
    store.putGet('present', _value(10));
    store.flush();
    expect(store.get('missing'), isNull);
  }

  void test_putGet_doesNotPersistWithoutFlush() {
    store.putGet('key', _value(10));
    expect(store.get('key'), _value(10));

    _open();
    expect(store.get('key'), isNull);
  }

  void test_putGet_emptyValue() {
    store.putGet('key', Uint8List(0));
    expect(store.get('key'), isEmpty);
    store.flush();

    _open();
    expect(store.get('key'), isEmpty);
    expect(store.get('missing'), isNull);
  }

  void test_putGet_flushesBeforeExceedingByteLimit() {
    _open(maxPendingValueBytes: 5);
    store.putGet('a', _value(3));
    store.putGet('b', _value(3, startByte: 1));

    // We have `b` in pending, so its value is available.
    expect(store.get('b'), _value(3, startByte: 1));
    expect(store.pendingEntryCount, 1);

    // Note, no flush before this reopen.
    // So, `a` was written to storage on the byte limit.
    // But `b` stayed in the pending, and was not persisted.
    _open();
    expect(store.get('a'), _value(3));
    expect(store.get('b'), isNull);
  }

  void test_putGet_flushesWhenByteLimitIsReached() {
    _open(maxPendingValueBytes: 5);
    store.putGet('a', _value(2));
    store.putGet('b', _value(3));

    // `2 + 3 = 5`, so both pending values flushed.
    expect(store.pendingEntryCount, 0);

    // Note, no flush before this reopen.
    // Both `a` and `b` were persisted when `2 + 3` reached exactly byte limit.
    _open();
    expect(store.get('a'), _value(2));
    expect(store.get('b'), _value(3));
  }

  void test_putGet_flushesWhenEntryLimitIsReached() {
    _open(maxPendingEntryCount: 2);
    var flushedBytes = <int>[];
    store.onFlush = (valueBytes, _) => flushedBytes.add(valueBytes);
    store.putGet('a', _value(10));
    expect(
      store.putGet('b', _value(20, startByte: 1)),
      _value(20, startByte: 1),
    );
    expect(store.pendingEntryCount, 0);
    expect(flushedBytes, [30]);

    _open();
    expect(store.get('a'), _value(10));
    expect(store.get('b'), _value(20, startByte: 1));
  }

  void test_putGet_largeValue() {
    // This value needs 768 continuation data pages. For the three-byte key,
    // the record header holds 250 page references, leaving 518 references for
    // a chain of three overflow metadata pages (253 references per page).
    var value = _value(768 * 1024);
    store.putGet('key', value);
    store.flush();
    expect(store.get('key'), value);

    _open();
    expect(store.get('key'), value);
  }

  void test_putGet_preservesPreviousValueWhenNewValueIsOversized() {
    store.putGet('key', _value(10));
    store.flush();

    // The oversized value is returned without replacing the stored value.
    var oversizedValue = Uint8List(store.maxValueLength + 1);
    expect(store.putGet('key', oversizedValue), same(oversizedValue));
    store.flush();

    expect(store.get('key'), _value(10));

    _open();
    expect(store.get('key'), _value(10));
  }

  void test_putGet_replacesPendingValue() {
    store.putGet('key', _value(20));
    store.putGet('key', _value(10, startByte: 1));
    expect(store.get('key'), _value(10, startByte: 1));
    expect(store.pendingEntryCount, 1);
    expect(store.pendingValueBytes, 10);
    store.flush();

    _open();
    expect(store.get('key'), _value(10, startByte: 1));
  }

  void test_putGet_returnsValueAndQueuesItForPersistence() {
    var value = _value(10);
    expect(store.putGet('key', value), same(value));
    expect(store.get('key'), _value(10));
    store.flush();

    _open();
    expect(store.get('key'), _value(10));
  }

  void test_putGet_unalignedValue() {
    var bytes = _value(2048);
    var value = Uint8List.sublistView(bytes, 1, 2046);
    store.putGet('key', value);
    store.flush();

    _open();
    expect(store.get('key'), value);
  }

  void test_tableBucketEntryCounts() {
    // 4 buckets of 128 slots.
    _open(tableSlotCountLog2: 9);
    for (var slot in [0, 1, 2, 2 * 128 + 5]) {
      store.putGet(_keyForSlot(slot), _value(10));
    }
    store.flush();
    expect(store.tableBucketEntryCounts(), [3, 0, 1, 0]);

    // Pending values are not counted.
    store.putGet(_keyForSlot(128), _value(10));
    expect(store.tableBucketEntryCounts(), [3, 0, 1, 0]);

    // Another instance reads the same committed table.
    store.flush();
    _open(tableSlotCountLog2: 9);
    expect(store.tableBucketEntryCounts(), [3, 1, 1, 0]);
  }

  void test_tableBucketEntryCounts_fullBucket() {
    // By default tests run with 1 hash table bucket.
    for (var slot = 0; slot < store.tableSlotCount; slot++) {
      store.putGet(_keyForSlot(slot), _value(10));
    }
    store.flush();
    expect(store.tableBucketEntryCounts(), [128]);

    // A new key evicts 16 entries from the full bucket.
    store.putGet('new_key', _value(10));
    store.flush();
    expect(store.tableBucketEntryCounts(), [113]);
  }

  String _keyForSlot(int slot) {
    for (var i = 0; ; i++) {
      var key = 'key_$i';
      if (SingleFileByteStore.hashKey(key) & (store.tableSlotCount - 1) ==
          slot) {
        return key;
      }
    }
  }

  /// Opens a fresh store over the storage without flushing the old store.
  void _open({
    int bufferPoolCapacityLog2 = 2,
    int filePageCountLog2 = 11,
    int tableSlotCountLog2 = 7,
    int maxPendingValueBytes = 1024 * 1024,
    int maxPendingEntryCount = 64,
  }) {
    store = SingleFileByteStore(
      storage,
      filePageCountLog2: filePageCountLog2,
      tableSlotCountLog2: tableSlotCountLog2,
      bufferPoolCapacityLog2: bufferPoolCapacityLog2,
      maxPendingValueBytes: maxPendingValueBytes,
      maxPendingEntryCount: maxPendingEntryCount,
    );
  }

  Uint8List _value(int length, {int startByte = 0}) {
    return Uint8List.fromList(
      List.generate(length, (index) => (index + startByte) & 0xff),
    );
  }

  /// Like `expect(actual, expected)`, but fast for large equal values.
  ///
  /// The `equals` matcher formats a location string for every element it
  /// compares, which dominates tests that compare megabytes many times.
  static void _expectBytes(
    Uint8List? actual,
    Uint8List expected, {
    String? reason,
  }) {
    if (!const ListEquality<int>().equals(actual, expected)) {
      expect(actual, expected, reason: reason);
    }
  }
}

/// [Storage] backed by an in-memory byte buffer.
/// Can fail a selected write before modifying the bytes.
class _MemoryStorage implements Storage {
  Uint8List _bytes = Uint8List(0);
  int writeCount = 0;

  /// Successful writes remaining before a single simulated write failure.
  int? writesBeforeFailure;

  @override
  int get length => _bytes.length;

  @override
  void flush() {}

  @override
  Uint8List read(int offset, int length) {
    RangeError.checkNotNegative(length, 'length');
    RangeError.checkValidRange(offset, offset + length, this.length);
    return _bytes.sublist(offset, offset + length);
  }

  @override
  void readInto(int offset, Uint8List buffer) {
    RangeError.checkValidRange(offset, offset + buffer.length, length);
    buffer.setRange(0, buffer.length, _bytes, offset);
  }

  @override
  void truncate(int length) {
    var bytes = Uint8List(length);
    bytes.setRange(0, math.min(length, this.length), _bytes);
    _bytes = bytes;
  }

  @override
  T withExclusiveAccess<T>(T Function() action) => action();

  @override
  void write(int offset, Uint8List bytes) {
    writeCount++;
    if (writesBeforeFailure case var remaining?) {
      if (remaining == 0) {
        writesBeforeFailure = null;
        throw const FileSystemException('Simulated write failure');
      }
      writesBeforeFailure = remaining - 1;
    }
    RangeError.checkValidRange(offset, offset + bytes.length, length);
    _bytes.setRange(offset, offset + bytes.length, bytes);
  }
}

/// A real [File] whose [setLastModifiedSync] simulates a file-system
/// exception.
class _SetLastModifiedFailingFile implements File {
  final File _file;

  new(this._file);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  RandomAccessFile openSync({FileMode mode = FileMode.read}) {
    return _file.openSync(mode: mode);
  }

  @override
  void setLastModifiedSync(DateTime time) {
    throw const FileSystemException('Simulated set last modified failure');
  }
}

/// A mock [RandomAccessFile] backed by an in-memory byte list.
///
/// [setPositionSync] moves the cursor. [readIntoSync] copies at most two bytes
/// per call and advances the cursor, or returns zero when [endOfFile] is set.
/// [writeFromSync] copies bytes at the cursor, extending the file if necessary,
/// advances the cursor, and counts write calls.
///
/// [lengthSync] returns the byte count and counts length queries.
/// [truncateSync] shrinks the file or extends it with zeros, preserving the
/// cursor. [flushSync] only counts flush calls.
/// [closeSync] counts close calls, and [path] reports `cache`.
///
/// [lockSync] checks for a whole-file blocking exclusive lock and marks the
/// file locked. [unlockSync] checks that it is locked, clears that state, and
/// counts unlocks. These methods check usage without providing actual locking.
///
/// [failFlush], [failLength], [failTruncate], and [failLock] simulate file-system
/// exceptions in the corresponding methods. Unimplemented methods throw through
/// [noSuchMethod].
class _TestFile implements RandomAccessFile {
  final List<int> bytes = [];

  bool endOfFile = false;
  bool locked = false;
  bool failFlush = false;
  bool failLength = false;
  bool failLock = false;
  bool failTruncate = false;

  int closeCount = 0;
  int flushCount = 0;
  int lengthReadCount = 0;
  int unlockCount = 0;
  int writeCount = 0;
  int _position = 0;

  @override
  String get path => 'cache';

  @override
  void closeSync() {
    closeCount++;
  }

  @override
  void flushSync() {
    flushCount++;
    if (failFlush) {
      throw const FileSystemException('Simulated flush failure');
    }
  }

  @override
  int lengthSync() {
    lengthReadCount++;
    if (failLength) {
      throw const FileSystemException('Simulated length failure');
    }
    return bytes.length;
  }

  @override
  void lockSync([
    FileLock mode = FileLock.exclusive,
    int start = 0,
    int end = -1,
  ]) {
    expect(mode, FileLock.blockingExclusive);
    expect(start, 0);
    expect(end, -1);
    if (failLock) {
      throw const FileSystemException('Simulated lock failure');
    }
    expect(locked, isFalse);
    locked = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  int readIntoSync(List<int> buffer, [int start = 0, int? end]) {
    if (endOfFile) {
      return 0;
    }
    end ??= buffer.length;
    var count = math.min(2, math.min(end - start, bytes.length - _position));
    buffer.setRange(start, start + count, bytes, _position);
    _position += count;
    return count;
  }

  @override
  void setPositionSync(int position) {
    _position = position;
  }

  @override
  void truncateSync(int length) {
    if (failTruncate) {
      throw const FileSystemException('Simulated truncate failure');
    }
    if (length < bytes.length) {
      bytes.length = length;
    } else {
      bytes.addAll(List.filled(length - bytes.length, 0));
    }
  }

  @override
  void unlockSync([int start = 0, int end = -1]) {
    expect(start, 0);
    expect(end, -1);
    expect(locked, isTrue);
    locked = false;
    unlockCount++;
  }

  @override
  void writeFromSync(List<int> buffer, [int start = 0, int? end]) {
    writeCount++;
    end ??= buffer.length;
    var count = end - start;
    if (_position + count > bytes.length) {
      truncateSync(_position + count);
    }
    bytes.setRange(_position, _position + count, buffer, start);
    _position += count;
  }
}

/// Supplies a controlled handle when [SingleFileByteStore.inDirectory] opens
/// its file.
///
/// [setLastModifiedSync] does nothing.
class _TestFileSource implements File {
  final _TestFile handle;

  new(this.handle);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  RandomAccessFile openSync({FileMode mode = FileMode.read}) {
    expect(mode, FileMode.append);
    return handle;
  }

  @override
  void setLastModifiedSync(DateTime time) {}
}
