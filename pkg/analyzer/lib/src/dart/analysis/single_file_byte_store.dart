// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:io';
import 'dart:math' show Random, min;
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/characters.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/fletcher16.dart';
import 'package:meta/meta.dart';

/// Size in bytes of every physical page in the store.
@visibleForTesting
const int pageSize = 1024;

const _FilePageIndex _allocationBitmapFirstPageIndex = _FilePageIndex(3);

/// The number of entries to evict from a single table chunk (page) when
/// it becomes full.
const int _bucketEvictionCount = 16;

/// The number of data pages represented by one allocation bitmap chunk.
const int _dataPagesPerAllocationChunk = pageSize * 8;

const _FilePageIndex _headerPageIndex = _FilePageIndex(0);

/// Caps the supported file size at 4 GiB. Together with the table limit,
/// this keeps the selector bitmap within one page.
const int _maxFilePageCountLog2 = 22;

/// At the maximum file and table sizes, 512 allocation chunks and 4096 table
/// chunks require 576 selector bytes, fitting within one page.
const int _maxTableSlotCountLog2 = 19;

/// Minimum supported file capacity: 2 MiB.
const int _minFilePageCountLog2 = 11;

/// The table must contain at least one complete 128-entry bucket.
const int _minTableSlotCountLog2 = 7;

const _FilePageIndex _selectorFirstPageIndex = _FilePageIndex(1);

const int _tableEntriesPerPage = pageSize ~/ _tableEntrySize;

/// Byte offset of the page-reference field within a table entry.
/// The field stores the first data-page index plus one; zero means empty.
const int _tableEntryPageReferenceOffset = 4;

/// A 32-bit key hash followed by a 32-bit encoded data-page reference.
const int _tableEntrySize = 8;

/// Storage backed by a caller-owned file handle opened for random-access writes.
/// The caller is responsible for closing the handle. The length is cached and
/// refreshed after acquiring exclusive access. Each process must use one handle
/// for this file, and all processes must cooperate through [withExclusiveAccess].
class FileStorage implements Storage {
  final RandomAccessFile _file;
  int _length;

  FileStorage(this._file) : _length = _file.lengthSync();

  @override
  int get length => _length;

  @override
  void flush() => _file.flushSync();

  @override
  Uint8List read(int offset, int length) {
    RangeError.checkNotNegative(offset, 'offset');
    RangeError.checkNotNegative(length, 'length');
    if (offset + length > this.length) {
      throw RangeError('Read beyond end of storage');
    }
    var bytes = Uint8List(length);
    readInto(offset, bytes);
    return bytes;
  }

  @override
  void readInto(int offset, Uint8List buffer) {
    RangeError.checkNotNegative(offset, 'offset');
    if (offset + buffer.length > length) {
      throw RangeError('Read beyond end of storage');
    }
    _file.setPositionSync(offset);
    var count = 0;
    while (count < buffer.length) {
      var read = _file.readIntoSync(buffer, count);
      if (read == 0) {
        throw RangeError('Read beyond end of storage');
      }
      count += read;
    }
  }

  @override
  void truncate(int length) {
    RangeError.checkNotNegative(length, 'length');
    _file.truncateSync(length);
    _length = length;
  }

  @override
  T withExclusiveAccess<T>(T Function() action) {
    _file.lockSync(FileLock.blockingExclusive);
    try {
      _length = _file.lengthSync();
      return action();
    } finally {
      _file.unlockSync();
    }
  }

  @override
  void write(int offset, Uint8List bytes) {
    RangeError.checkValidRange(offset, offset + bytes.length, length);
    if (bytes.isEmpty) {
      return;
    }
    _file.setPositionSync(offset);
    _file.writeFromSync(bytes);
  }
}

/// A fixed-capacity persistent key/value cache with process-local CLOCK eviction
/// (https://en.wikipedia.org/wiki/Page_replacement_algorithm#Clock).
///
/// The file has the following layout, in 1 KiB pages:
///
/// * Page 0: the header, with the active selector bitmap slot in byte 8 (0 or 1).
/// * Pages 1 and 2: two selector bitmaps, each fitting in one page.
/// * The next [_allocationBitmapChunkCount] pages: allocation bitmap 0.
/// * The next [_allocationBitmapChunkCount] pages: allocation bitmap 1.
/// * Two copies of the hash table, each containing [_tablePageCount] pages.
/// * The remaining pages: data pages, starting at [_dataAreaFirstPageIndex].
///
/// Each allocation bitmap is divided into page-sized chunks. Each chunk
/// contains one allocation bit for each of `8192` data pages. Selector bit `i`
/// chooses slot 0 or 1 of allocation chunk `i`. A set allocation bit means
/// allocated. Bits are numbered least significant first. Data page numbers
/// start at zero in the data area; bitmap bits beyond [_dataPageCount] are
/// unused.
///
/// The following selector bits choose slots of hash table pages. Each table
/// entry holds a 32-bit key hash and a data-page index plus one; zero means empty.
/// Each logical table page is an independent 128-entry bucket. Probing wraps
/// within the bucket, stopping at an empty entry or after examining every slot.
/// Inserting an absent key into a full bucket evicts 16 entries using local CLOCK
/// and rebuilds that bucket.
/// Deleted entries leave no tombstones and survivors never cross bucket boundaries.
///
/// Header encoding is defined by [_Header]. The free-page count is stored in the
/// header alongside the active selector slot, so opening the store or observing an
/// external commit does not require scanning allocation bitmaps to reconstruct it.
///

/// An update writes new record pages, shadow allocation/table pages, and the
/// shadow selectors, flushes them together, and then writes and flushes the
/// complete header with its new slot. New pages become allocated and replaced pages
/// become free in the same publication as the table entries. Recovery follows
/// the slot in a valid header, or resets the store if the header is invalid.
/// All pages are accessed through a private [_BufferPool].
///
/// This protocol relies on storage preserving flushed writes. A torn header
/// write can cause the entire cache to be discarded. Detected corruption resets
/// the cache, discarding all table entries, data page allocations, etc.
///
/// The storage constructor leaves ownership with the caller;
/// [SingleFileByteStore.file] owns its file until [close]. This instance is the
/// only byte store in its process accessing the file. Multiple processes can
/// keep live instances:
/// committed reads, commits, and recovery hold exclusive storage access and
/// reread the header and invalidate metadata when its commit ID changes. Pending
/// values are private to each instance; the last committed batch wins for a key.
///
/// After an I/O error, close and reopen the file before further operations; an
/// error during publication can mean either the old or new state was committed.
class SingleFileByteStore implements ByteStore {
  /// Counter for published transactions and newly initialized stores.
  /// A random high word and time-seeded low word make uniqueness across isolates
  /// and processes probabilistic. IDs are compared only for equality.
  static int _nextCommitId =
      (Random().nextInt(1 << 32) << 32) |
      (DateTime.now().microsecondsSinceEpoch & 0xFFFFFFFF);

  final _BufferPool _bufferPool;

  /// The file owned by this store, which is closed on [close].
  ///
  /// This is only set if the store was created via [SingleFileByteStore.file].
  /// If the store was created via [SingleFileByteStore.new], this is `null` and
  /// the caller is responsible for closing their own file.
  RandomAccessFile? _ownedFile;
  bool _closed = false;

  /// The committed state represented by cached metadata pages.
  int? _cachedCommitId;

  /// Approximate process-local recency, indexed by table slot.
  ///
  /// Reads in other processes do not update these bits. Bits survive external
  /// commits, so a changed slot may retain the previous entry's second chance.
  ///
  /// Note: Since the same set of bits is used for both the per-bucket clocks and
  /// the global reclamation clock, under dual pressure (tight data capacity + high
  /// bucket contention):
  ///
  /// - Entries in high-contention buckets have their clock bits cleared much more
  ///   frequently by local bucket sweeps than entries in quiet buckets.
  ///
  /// - As a result, entries in hot buckets are significantly more vulnerable to
  ///   being reclaimed by the global data clock than entries in cold buckets,
  ///   effectively giving them shorter lifespans than if the two clocks maintained
  ///   separate recency bits.
  late final Uint8List _clockBits = Uint8List(tableSlotCount.divideRoundUp(8));

  /// Per-bucket CLOCK eviction cursors; each stores the next slot to examine.
  late final Uint8List _bucketClockHands = Uint8List(_tablePageCount);

  /// Largest value that fits in otherwise empty storage for every valid key,
  /// accounting for its first page and overflow metadata pages.
  late final int maxValueLength = _ValueHeader.maximumValueLength(
    _dataPageCount,
  );

  /// Latest value queued for each key, owned by this store.
  final Map<String, Uint8List> _pendingValues = {};

  /// Total value bytes in [_pendingValues], used to enforce the byte limit.
  int _pendingValueBytes = 0;

  /// Cumulative statistics for this instance.
  @visibleForTesting
  final _Statistics statistics = ._();

  /// Flush the queue when its values reach this many bytes.
  /// A single larger value is committed immediately.
  final int _maxPendingValueBytes;

  /// Flush the queue when it contains this many distinct keys.
  /// This also bounds queues of empty values.
  final int _maxPendingEntryCount;

  /// Base-two logarithm of the physical page count, including metadata pages.
  /// Values from 11 through 22 represent file sizes from 2 MiB through 4 GiB.
  final int _filePageCountLog2;

  /// Base-two logarithm of the fixed hash table capacity, from 7 through 19.
  final int _tableSlotCountLog2;

  /// Opens valid storage, or resets and initializes it using this configuration.
  ///
  /// The caller owns [storage]. Closing this store flushes pending values but
  /// does not close the caller's storage or its file handle.
  ///
  /// The header's exponents must match [filePageCountLog2] and
  /// [tableSlotCountLog2]. Its page size and chunk count must match
  /// [pageSize] and [_allocationBitmapChunkCount].
  ///
  /// An invalid or incompatible header resets the store using the requested
  /// configuration, discarding all existing entries.
  ///
  /// Initialization flushes after truncating to zero and after writing the new
  /// header. Extension is zero-filled, and the data area can be sparse.
  ///
  /// [bufferPoolCapacityLog2] sets the pool capacity to
  /// `2^bufferPoolCapacityLog2` pages. A transaction's working metadata snapshots
  /// are separate from these cached file pages.
  ///
  /// [maxPendingValueBytes] and [maxPendingEntryCount] bound the write queue.
  /// These runtime limits and the pool capacity are not stored in the header.
  SingleFileByteStore(
    Storage storage, {
    required int filePageCountLog2,
    required int tableSlotCountLog2,
    required int bufferPoolCapacityLog2,
    required int maxPendingValueBytes,
    required int maxPendingEntryCount,
  }) : _filePageCountLog2 = filePageCountLog2,
       _tableSlotCountLog2 = tableSlotCountLog2,
       _maxPendingValueBytes = maxPendingValueBytes,
       _maxPendingEntryCount = maxPendingEntryCount,
       _bufferPool = _BufferPool(
         storage,
         capacityLog2: bufferPoolCapacityLog2,
       ) {
    if (maxPendingValueBytes < 1) {
      throw RangeError.range(
        maxPendingValueBytes,
        1,
        null,
        'maxPendingValueBytes',
      );
    }
    if (maxPendingEntryCount < 1) {
      throw RangeError.range(
        maxPendingEntryCount,
        1,
        null,
        'maxPendingEntryCount',
      );
    }
    RangeError.checkValueInInterval(
      filePageCountLog2,
      _minFilePageCountLog2,
      _maxFilePageCountLog2,
      'filePageCountLog2',
    );
    RangeError.checkValueInInterval(
      tableSlotCountLog2,
      _minTableSlotCountLog2,
      _maxTableSlotCountLog2,
      'tableSlotCountLog2',
    );
    if (_dataPageCount <= 0) {
      throw ArgumentError(
        'The table and allocation metadata must fit in the file',
      );
    }

    // Validate existing storage or initialize it under the exclusive lock.
    _withExclusiveAccess((_) {});
  }

  /// Opens or creates the cache at [path], owning its file until [close].
  ///
  /// Uses the same configuration and recovery rules as [SingleFileByteStore].
  /// The file is closed if initialization fails. The parent directory must exist.
  factory SingleFileByteStore.file(
    String path, {
    required int filePageCountLog2,
    required int tableSlotCountLog2,
    required int bufferPoolCapacityLog2,
    required int maxPendingValueBytes,
    required int maxPendingEntryCount,
  }) {
    var file = File(path).openSync(mode: FileMode.append);
    try {
      return SingleFileByteStore(
        FileStorage(file),
        filePageCountLog2: filePageCountLog2,
        tableSlotCountLog2: tableSlotCountLog2,
        bufferPoolCapacityLog2: bufferPoolCapacityLog2,
        maxPendingValueBytes: maxPendingValueBytes,
        maxPendingEntryCount: maxPendingEntryCount,
      ).._ownedFile = file;
    } catch (_) {
      file.closeSync();
      rethrow;
    }
  }

  /// The path opened by [SingleFileByteStore.file], or null if storage was
  /// supplied by constructing this object using the [SingleFileByteStore.new]
  /// constructor.
  String? get filePath => _ownedFile?.path;

  int get pendingEntryCount => _pendingValues.length;

  int get pendingValueBytes => _pendingValueBytes;

  int get tableSlotCount => 1 << _tableSlotCountLog2;

  /// The number of page-sized chunks in each allocation bitmap.
  /// Uses the total file page count as an upper bound on the data page count.
  int get _allocationBitmapChunkCount =>
      _filePageCount.divideRoundUp(_dataPagesPerAllocationChunk);

  _FilePageIndex get _dataAreaFirstPageIndex =>
      _allocationBitmapFirstPageIndex +
      2 * _allocationBitmapChunkCount +
      2 * _tablePageCount;

  int get _dataPageCount => _filePageCount - _dataAreaFirstPageIndex.value;

  /// Total physical pages in the file, including metadata.
  int get _filePageCount => 1 << _filePageCountLog2;

  /// The size in bytes of the selector bitmap, which contains one bit for each
  /// allocation bitmap chunk and one bit for each hash table page.
  ///
  /// In the maximum configuration (512 allocation chunks and 4096 table pages),
  /// this requires 576 bytes, so each selector bitmap always fits within a single
  /// 1024-byte page.
  int get _selectorSize =>
      (_allocationBitmapChunkCount + _tablePageCount).divideRoundUp(8);

  int get _tablePageCount => tableSlotCount ~/ _tableEntriesPerPage;

  /// Flushes pending values and closes the file owned by this store, if any.
  ///
  /// Caller-owned storage remains open. Even if flushing fails, the owned file
  /// is closed and this store cannot be used again. Further calls to [close] do
  /// nothing; [get], [putGet], and [flush] throw [StateError] after closing.
  void close() {
    if (_closed) return;
    try {
      flush();
    } finally {
      _closed = true;
      _ownedFile?.closeSync();
    }
  }

  /// Commits all pending values together, including flushing storage.
  /// Call before closing the underlying file. An empty queue performs no I/O.
  /// Detected corruption resets the store and discards the pending values.
  ///
  /// Discards an intrinsically oversized batch without evicting anything.
  /// Otherwise, eviction may commit before insertion so freed pages can safely
  /// be reused. Storage failures propagate without clearing the pending values.
  void flush() {
    _checkOpen();
    if (_pendingValues.isEmpty) return;
    _withExclusiveAccess((header) {
      try {
        header = _prepareCapacity(header);

        // Now that we have enough capacity, after evicting old values,
        // put pending values shadow pages and commit.
        var transaction = _WriteTransaction(this, header);
        for (var entry in _pendingValues.entries) {
          transaction.put(entry.key, entry.value);
        }
        transaction.commit();
        statistics._committedEntryCount += _pendingValues.length;
        statistics._committedValueBytes += _pendingValueBytes;
      } on _CapacityException {
        // `_prepareCapacity` rejected the batch as too large.
        statistics._capacityDiscardedBatchCount++;
      } on FormatException {
        _reset();
      }
      _pendingValues.clear();
      _pendingValueBytes = 0;
    });
  }

  /// Returns the pending or committed value, or null if absent or corrupt.
  ///
  /// The caller must not modify the returned bytes, including through other
  /// views of the same buffer; copy them before mutation. The bytes remain
  /// valid across subsequent store operations.
  ///
  /// Detected corruption resets the committed cache, including its page
  /// allocations; pending values remain queued.
  @override
  Uint8List? get(String key) {
    _checkOpen();
    _checkKey(key);

    // Maybe still pending, not in pages yet.
    if (_pendingValues[key] case var pendingValue?) {
      return pendingValue;
    }

    return _withExclusiveAccess((storeHeader) {
      try {
        var selectors = _readSelectors(storeHeader.selectorSlot);

        // Lookup in the commited table.
        var entry = _lookup(selectors, key);
        var header = entry.header;
        if (header == null) {
          return null;
        }

        var value = Uint8List(header.valueLength);

        // Copy the start of the value from the header page.
        var inlineValueLength = min(
          value.length,
          pageSize - header.inlineOffset,
        );
        if (inlineValueLength > 0) {
          var page = _bufferPool.readPage(
            _dataPageIndexToFilePageIndex(header.firstDataPageIndex),
          );
          try {
            value.setRange(
              0,
              inlineValueLength,
              page.bytes,
              header.inlineOffset,
            );
          } finally {
            page.release();
          }
        }

        // Read the remaining of the value from continuation pages.
        _bufferPool.readPagesInto([
          for (var index in header.continuationPages)
            _dataPageIndexToFilePageIndex(index),
        ], Uint8List.sublistView(value, inlineValueLength));

        // Verify the complete value, including inline and continuation bytes.
        if (fletcher16(value) != header.valueChecksum) {
          throw const FormatException('Invalid value checksum');
        }

        // Mark the entry as recently used so CLOCK gives it a second chance.
        _clockBits.setBit(entry.entryIndex, true);

        return value;
      } on FormatException {
        _reset();
        return null;
      }
    });
  }

  /// Queues [bytes] for [key] and returns them, taking ownership and replacing
  /// any pending value. The caller must not mutate the bytes after this call,
  /// including through other views of the same buffer.
  /// Reads see the pending value immediately; persistence requires [flush].
  ///
  /// Values longer than [maxValueLength] bytes are ignored, preserving any
  /// existing value for [key]. Reaching either queue limit flushes the batch.
  /// Before exceeding the byte limit, the preceding batch is flushed first.
  /// A failed flush propagates without clearing pending values. If the preceding
  /// batch cannot be flushed, [bytes] have not yet been queued.
  ///
  /// Returns [bytes] even when the value is too large or its batch cannot fit
  /// in persistent storage.
  ///
  /// [bytes] is returned in order to satisfy the interface construct of [ByteStore]
  /// (which allows for the possibility that this method might return a pre-existing
  /// copy of the data rather than returning [bytes] itself).
  @override
  Uint8List putGet(String key, Uint8List bytes) {
    _checkOpen();
    _checkKey(key);
    if (bytes.length > maxValueLength) {
      statistics._oversizedValueCount++;
      statistics._oversizedValueBytes += bytes.length;
      return bytes;
    }

    // Account for replacing a queued value. Flush before exceeding the byte
    // limit; after flushing, the new value contributes its full length.
    var previousValueLength = _pendingValues[key]?.length ?? 0;
    var valueLengthDelta = bytes.length - previousValueLength;
    if (_pendingValueBytes + valueLengthDelta > _maxPendingValueBytes) {
      flush();
      valueLengthDelta = bytes.length;
    }

    // Queue the latest value and flush when either limit is reached.
    // The entry count limit also bounds batches of empty values.
    _pendingValues[key] = bytes;
    _pendingValueBytes += valueLengthDelta;
    if (_pendingValues.length >= _maxPendingEntryCount ||
        _pendingValueBytes >= _maxPendingValueBytes) {
      flush();
    }
    return bytes;
  }

  @override
  void release(Iterable<String> keys) {}

  _FilePageIndex _allocationBitmapChunkIndexToFilePageIndex(
    int chunkSlot,
    _AllocationBitmapChunkIndex chunkIndex,
  ) =>
      _allocationBitmapFirstPageIndex +
      chunkSlot * _allocationBitmapChunkCount +
      chunkIndex.value;

  void _checkOpen() {
    if (_closed) {
      throw StateError('The byte store is closed');
    }
  }

  _FilePageIndex _committedTableFilePageIndex(
    Uint8List committedSelectors,
    _TablePageIndex tablePageIndex,
  ) {
    var selectorBit = _allocationBitmapChunkCount + tablePageIndex.value;
    var slot = committedSelectors.bitAt(selectorBit) ? 1 : 0;
    return _tablePageIndexToFilePageIndex(slot, tablePageIndex);
  }

  /// Returns the physical file-page index of a data page.
  _FilePageIndex _dataPageIndexToFilePageIndex(_DataPageIndex dataPageIndex) {
    RangeError.checkValidIndex(
      dataPageIndex.value,
      null,
      'dataPageIndex',
      _dataPageCount,
    );
    return _dataAreaFirstPageIndex + dataPageIndex.value;
  }

  /// Probes only within the key's table page, wrapping at its bucket boundary.
  /// Full keys are compared only when their stored hashes match.
  ///
  /// If [key] is found, returns its table entry index and its [_ValueHeader].
  ///
  /// If absent, `header` is `null`, and `entryIndex` is the index of an empty
  /// entry where the key can be inserted, or `-1` if the bucket is full.
  ///
  /// Working pages in [tablePages] override the copies selected by
  /// [committedSelectors], so a transaction can find records inserted earlier
  /// in the same batch.
  ///
  /// Throws [FormatException] if an inspected entry or value header is invalid.
  ({int entryIndex, _ValueHeader? header}) _lookup(
    Uint8List committedSelectors,
    String key, {
    int? keyHash,
    Map<_TablePageIndex, Uint8List> tablePages = const {},
  }) {
    assert(keyHash == null || keyHash == hashKey(key));
    keyHash ??= hashKey(key);

    // The ideal location for this hash in the whole table.
    var homeEntryIndex = keyHash & (tableSlotCount - 1);

    // The location in the table bucket.
    var tablePage = _TablePageIndex(homeEntryIndex ~/ _tableEntriesPerPage);
    var bucketFirstEntryIndex = tablePage.value * _tableEntriesPerPage;
    var bucketSlot = homeEntryIndex % _tableEntriesPerPage;

    // Either use working bytes, or read the page.
    var workingBytes = tablePages[tablePage];
    var page = workingBytes == null
        ? _bufferPool.readPage(
            _committedTableFilePageIndex(committedSelectors, tablePage),
          )
        : null;

    try {
      // Use either working bytes, or the read page bytes.
      var data = ByteData.sublistView(workingBytes ?? page!.bytes);

      // Iterate over the table bucket until the empty slot.
      for (var probe = 0; probe < _tableEntriesPerPage; probe++) {
        var entryIndex = bucketFirstEntryIndex + bucketSlot;
        var offset = bucketSlot * _tableEntrySize;
        var storedHash = data.getUint32(offset, Endian.little);
        var storedPage = data.getUint32(
          offset + _tableEntryPageReferenceOffset,
          Endian.little,
        );

        // Rebuilds leave no tombstones; an empty slot means the key is absent.
        if (storedPage == 0) {
          return (entryIndex: entryIndex, header: null);
        }

        // Sanity check.
        if (storedPage > _dataPageCount) {
          throw const FormatException('Invalid table entry page');
        }

        // Check the hash, then the key.
        if (storedHash == keyHash) {
          var valueFirstPageIndex = _DataPageIndex(storedPage - 1);
          var header = _readValueHeader(valueFirstPageIndex);
          if (header.key == key) {
            // Populate any remaining page indices from the overflow chain so
            // the caller can read the full value or free all of its pages.
            _readOverflowMetadata(header);
            return (entryIndex: entryIndex, header: header);
          }
        }

        // Next slot in the same bucket, with wrap around.
        bucketSlot = (bucketSlot + 1) & (_tableEntriesPerPage - 1);
      }
    } finally {
      page?.release();
    }
    return (entryIndex: -1, header: null);
  }

  /// Reclaims data pages only when the pending batch cannot otherwise be written.
  /// Full hash-table buckets are not checked here; they are evicted on demand
  /// by [_WriteTransaction.put] as each pending entry is inserted.
  ///
  /// Throws [_CapacityException] without modifying storage if the batch cannot
  /// fit even in an empty store.
  ///
  /// When eviction is needed, this method commits the eviction in its own
  /// transaction so that removed entries' pages become durably free on disk
  /// before the caller's insertion transaction reuses them.
  ///
  /// Consequently, the caller must hold exclusive storage access continuously
  /// across both this call and the subsequent insertion so that another process
  /// cannot claim the freed pages in between.
  _Header _prepareCapacity(_Header header) {
    // Count data and overflow metadata pages for the entire batch. Values whose
    // keys already exist also need new pages; insertion cannot overwrite their
    // committed records (since the old data pages must remain intact on disk
    // until the new transaction commits).
    var requiredPages = 0;
    for (var entry in _pendingValues.entries) {
      var continuationPages = _ValueHeader.continuationDataPageCount(
        keyLength: entry.key.length,
        valueLength: entry.value.length,
      );
      requiredPages +=
          1 +
          continuationPages +
          _ValueHeader.overflowMetadataPageCount(
            keyLength: entry.key.length,
            continuationDataPageCount: continuationPages,
          );
    }

    // Reject a batch that cannot fit even in an empty store before evicting
    // any committed entries.
    if (requiredPages > _dataPageCount) {
      throw _CapacityException();
    }

    // If already enough free pages, nothing to do.
    if (header.freePageCount >= requiredPages) return header;

    // Evict entries to free enough data pages.
    var transaction = _WriteTransaction(this, header);
    transaction.evictForPages(requiredPages);
    return transaction.commit();
  }

  /// Reads the file header and returns it if it is valid and matches this
  /// instance's layout configuration ([_filePageCountLog2],
  /// [_tableSlotCountLog2], etc.), or `null` if the store must be reset.
  _Header? _readCompatibleHeader() {
    // Check the file length before attempting to read its header.
    if (!_bufferPool.hasPageCount(_filePageCount)) {
      return null;
    }

    _Header header;
    try {
      var page = _bufferPool.readPage(_headerPageIndex);
      try {
        header = _Header.read(page);
      } finally {
        page.release();
      }
    } on FormatException {
      return null;
    }

    // Check that the header has the same configuration.
    if (header.filePageCountLog2 != _filePageCountLog2 ||
        header.tableSlotCountLog2 != _tableSlotCountLog2 ||
        header.pageSize != pageSize ||
        header.allocationBitmapChunkCount != _allocationBitmapChunkCount) {
      return null;
    }

    // Sanity check.
    if (header.freePageCount > _dataPageCount) {
      return null;
    }

    return header;
  }

  /// Populates [header] with any continuation and metadata page indices from
  /// its overflow chain, and validates that the total page count matches
  /// `header.valueLength`.
  ///
  /// Throws [FormatException] if the record contains out-of-range indices,
  /// cycles, duplicate pages, or metadata/data overlap.
  ///
  /// This is kept separate from [_readValueHeader] so that [_lookup] can first
  /// verify that `header.key` matches before reading the overflow chain.
  /// Callers invoke this before reading a record's value or freeing its pages.
  void _readOverflowMetadata(_ValueHeader header) {
    var seen = <_DataPageIndex>{
      header.firstDataPageIndex,
      ...header.continuationPages,
    };

    // Iterate over the linked list of overflow metadata pages.
    var nextOverflowMetadataPageIndex = header.firstOverflowMetadataPageIndex;
    while (nextOverflowMetadataPageIndex != null) {
      if (nextOverflowMetadataPageIndex.value >= _dataPageCount ||
          !seen.add(nextOverflowMetadataPageIndex)) {
        throw const FormatException(
          'Invalid or repeated overflow metadata page',
        );
      }

      // Read the next overflow page.
      _OverflowMetadata metadata;
      var page = _bufferPool.readPage(
        _dataPageIndexToFilePageIndex(nextOverflowMetadataPageIndex),
      );
      try {
        metadata = _OverflowMetadata.read(page);
      } finally {
        page.release();
      }

      // Sanity check.
      for (var index in metadata.dataPages) {
        if (index.value >= _dataPageCount || !seen.add(index)) {
          throw const FormatException('Invalid or repeated continuation page');
        }
      }

      // Accumulate pages in the header.
      header.overflowMetadataPages.add(nextOverflowMetadataPageIndex);
      header.continuationPages.addAll(metadata.dataPages);

      // Take the next page in the linked list.
      nextOverflowMetadataPageIndex = metadata.nextOverflowMetadataPageIndex;
    }

    // Validate the collected list against the payload it must hold. With
    // overflow, inlineOffset is pageSize and all value bytes are in data pages.
    var inlineValueLength = min(
      header.valueLength,
      pageSize - header.inlineOffset,
    );
    var remainingValueLength = header.valueLength - inlineValueLength;
    if (header.continuationPages.length !=
        remainingValueLength.divideRoundUp(pageSize)) {
      throw const FormatException('Value length does not match its data pages');
    }
  }

  /// Returns an independent copy of the [_selectorSize]-byte selector bitmap
  /// stored in [selectorSlot] (0 or 1), unpinning its buffer frame immediately
  /// so callers can mutate the returned bitmap or reuse the frame.
  Uint8List _readSelectors(int selectorSlot) {
    // Snapshot selectors so their frames can be reused during publication.
    var page = _bufferPool.readPage(_selectorPageIndex(selectorSlot));
    try {
      return page.bytes.sublist(0, _selectorSize);
    } finally {
      page.release();
    }
  }

  /// Reads and decodes the [_ValueHeader] from a record's first data page
  /// ([index]), without loading its overflow metadata chain.
  ///
  /// Throws [FormatException] if the header metadata or its checksum is invalid.
  _ValueHeader _readValueHeader(_DataPageIndex index) {
    var filePageIndex = _dataPageIndexToFilePageIndex(index);
    var page = _bufferPool.readPage(filePageIndex);
    try {
      return _ValueHeader.read(page, index, _dataPageCount);
    } finally {
      page.release();
    }
  }

  _Header _reset() {
    // Discard any existing content.
    _bufferPool.setPageCount(0);
    _bufferPool.flush();

    // Fill the file with zeros to the required size.
    _bufferPool.setPageCount(_filePageCount);
    _clockBits.fillRange(0, _clockBits.length, 0);
    _bucketClockHands.fillRange(0, _bucketClockHands.length, 0);
    var header = _writeHeader(
      selectorSlot: 0,
      freePageCount: _dataPageCount,
      dataReclamationClockHand: 0,
    );
    _bufferPool.flush();
    return header;
  }

  _FilePageIndex _selectorPageIndex(int selectorSlot) =>
      _selectorFirstPageIndex + selectorSlot;

  _FilePageIndex _tablePageIndexToFilePageIndex(
    int slot,
    _TablePageIndex tablePageIndex,
  ) {
    var bitmapPageCount = 2 * _allocationBitmapChunkCount;
    var tableFirstPageIndex = _allocationBitmapFirstPageIndex + bitmapPageCount;
    var tableSlotFirstPageIndex = tableFirstPageIndex + slot * _tablePageCount;
    return tableSlotFirstPageIndex + tablePageIndex.value;
  }

  /// Runs [action] under the exclusive storage lock with the current header.
  /// Before invoking [action], resets storage if its header or file length is
  /// invalid or incompatible, and discards cached pages after external commits.
  T _withExclusiveAccess<T>(T Function(_Header header) action) {
    return _bufferPool.withExclusiveAccess(() {
      // Fetch the current header under the lock before trusting cached pages.
      _bufferPool.discardPage(_headerPageIndex);
      var header = _readCompatibleHeader();

      if (header == null) {
        header = _reset();
      } else if (header.commitId != _cachedCommitId) {
        // If there was a write to the store, we cannot reuse cached pages.
        _bufferPool.discardPages();
      }

      _cachedCommitId = header.commitId;
      return action(header);
    });
  }

  _Header _writeHeader({
    required int selectorSlot,
    required int freePageCount,
    required int dataReclamationClockHand,
  }) {
    var header = _Header(
      filePageCountLog2: _filePageCountLog2,
      tableSlotCountLog2: _tableSlotCountLog2,
      pageSize: pageSize,
      allocationBitmapChunkCount: _allocationBitmapChunkCount,
      selectorSlot: selectorSlot,
      commitId: ++_nextCommitId,
      freePageCount: freePageCount,
      dataReclamationClockHand: dataReclamationClockHand,
    );

    // Write the complete header to publish the selector slot and commit ID.
    // The caller must flush storage to make this publication durable.
    var page = _bufferPool.overwritePage(_headerPageIndex);
    try {
      header.write(page.bytes);
      page.writeAndRelease();
    } finally {
      page.release();
    }

    return header;
  }

  /// Returns the 32-bit FNV-1a key hash stored in hash table entries.
  @visibleForTesting
  static int hashKey(String key) {
    const fnvOffsetBasis = 0x811C9DC5;
    const fnvPrime = 0x01000193;

    var hash = fnvOffsetBasis;
    for (var byte in key.codeUnits) {
      hash = ((hash ^ byte) * fnvPrime) & 0xFFFFFFFF;
    }

    return hash;
  }

  static void _checkKey(String key) {
    if (!_ValueHeader.isValidKey(key)) throw ArgumentError.value(key, 'key');
  }
}

/// Synchronous random-access storage. Use [withExclusiveAccess] to coordinate
/// operations on storage shared between processes.
abstract class Storage {
  int get length;

  /// Flushes preceding writes to the underlying storage.
  void flush();

  /// Reads exactly [length] bytes, returning an independent buffer.
  ///
  /// Throws [RangeError] for negative arguments or if the requested range
  /// extends beyond the end of the storage.
  Uint8List read(int offset, int length);

  /// Fills [buffer] from [offset], with the same range checks as [read].
  void readInto(int offset, Uint8List buffer);

  /// Sets the length, discarding excess bytes or extending with zeros.
  void truncate(int length);

  /// Runs a synchronous [action] while excluding other cooperating processes.
  /// Refreshes [length] after acquiring access and releases access even when
  /// [action] throws. Calls must not be nested or return asynchronous work.
  T withExclusiveAccess<T>(T Function() action);

  /// Writes [bytes] at [offset] within the existing storage length.
  ///
  /// Throws [RangeError] if the range is outside the storage. An empty write
  /// at a valid offset has no effect. Use [truncate] to resize the storage.
  void write(int offset, Uint8List bytes);
}

/// A reusable in-memory buffer slot inside a [_BufferPool] that holds one page.
///
/// Multiple read handles may share a frame, but a writable handle is exclusive.
/// Each borrowed [_BufferPage] pins the frame, preventing the pool from reusing
/// its bytes for another page until all handles have been released.
class _BufferFrame {
  final Uint8List bytes = Uint8List(pageSize);
  late final Uint8List readOnlyBytes = bytes.asUnmodifiableView();
  _FilePageIndex pageIndex = const _FilePageIndex(0);
  int pinCount = 0;
  bool writable = false;
}

/// A handle to a pinned page borrowed from a [_BufferPool].
///
/// [bytes] and any views of them may only be used until [release] or
/// [writeAndRelease]. The pool may reuse the buffer immediately afterward.
///
/// Read handles may share a [_BufferFrame] and expose unmodifiable bytes.
/// A writable handle provides exclusive access to that frame.
class _BufferPage {
  final _BufferPool _pool;
  final _BufferFrame _frame;
  final bool _writable;
  bool _released = false;

  _BufferPage._(this._pool, this._frame, {required bool writable})
    : _writable = writable;

  /// The borrowed page buffer, modifiable only through a writable handle.
  /// This view and any views derived from it are valid only until [release] or
  /// [writeAndRelease]. Throws [StateError] if the handle has already been released.
  Uint8List get bytes {
    _checkActive();
    return _writable ? _frame.bytes : _frame.readOnlyBytes;
  }

  /// Releases a reader, or discards an unwritten replacement without I/O.
  /// Calling this again after [release] or [writeAndRelease] has no effect.
  void release() {
    if (_released) {
      return;
    }
    _released = true;
    if (_writable) {
      _pool._discard(_frame);
    } else {
      _frame.pinCount--;
    }
  }

  /// Writes the entire replacement to storage and releases this handle.
  ///
  /// Does not flush: use [_BufferPool.flush] for the durability barrier. On
  /// success, the written page remains cached for readers. On failure, its
  /// frame is discarded and this handle is released.
  void writeAndRelease() {
    _checkActive();
    if (!_writable) {
      throw StateError('Cannot write a read-only page');
    }

    try {
      _pool._storage.write(_frame.pageIndex.value * pageSize, _frame.bytes);
    } catch (_) {
      release();
      rethrow;
    }

    // Release the handle while keeping the successfully written page cached.
    _frame.writable = false;
    _frame.pinCount = 0;
    _released = true;
  }

  /// Throws [StateError] if the handle has already been released.
  void _checkActive() {
    if (_released) {
      throw StateError('Page handle has been released');
    }
  }
}

/// A cache of up to `2^capacityLog2` physical 1 KiB pages.
///
/// Read and writable frames count toward the same capacity. Frames are allocated
/// lazily and reused. Only unpinned frames can be evicted, in least-recently-used
/// order. Eviction never writes to storage.
///
/// Owned by one byte store, which is the only byte store in its process accessing
/// the file. The owner must release each [_BufferPage] when finished using its
/// bytes so the pool can reuse the frame.
///
/// Page indices are relative to the start of storage, including metadata pages.
/// Cached pages must not be modified through another pool or directly through
/// [Storage].
///
/// [withExclusiveAccess] locks shared storage without changing the cache. The
/// owner must discard stale pages before using them. Discard the pool after a
/// storage flush error, when durability is uncertain.
class _BufferPool {
  /// Caps cached page-buffer memory at 4 MiB.
  static const int _maxCapacityLog2 = 12;

  /// The supported pool capacity starts at four frames. Lookup may pin a table
  /// page while borrowing record metadata pages.
  static const int _minCapacityLog2 = 2;

  final Storage _storage;

  /// Base-two logarithm of the total frame capacity, from 2 through 12.
  /// For example, 10 allows 1024 frames, using up to 1 MiB of page buffers.
  final int capacityLog2;

  /// Frames assigned to pages, ordered from least to most recently used.
  /// Includes pinned frames, which cannot be evicted.
  final LinkedHashMap<_FilePageIndex, _BufferFrame> _frames = LinkedHashMap();

  /// Unassigned frames retained for reuse without allocating new buffers.
  final List<_BufferFrame> _freeFrames = [];

  /// Total frames owned by the pool, including assigned and free frames.
  /// Used to enforce [capacity] when allocating new frames.
  int _allocatedFrameCount = 0;

  _BufferPool(this._storage, {required this.capacityLog2}) {
    RangeError.checkValueInInterval(
      capacityLog2,
      _minCapacityLog2,
      _maxCapacityLog2,
      'capacityLog2',
    );
  }

  /// Cached pages, including all currently borrowed read and writable pages.
  int get cachedPageCount => _frames.length;

  /// The maximum count of cached pages, shared by readers and writers.
  int get capacity => 1 << capacityLog2;

  /// Discards a cached page without I/O, retaining its buffer for reuse.
  /// Does nothing if absent. A cached page must be released before discarding it.
  void discardPage(_FilePageIndex pageIndex) {
    var frame = _frames[pageIndex];
    if (frame == null) return;
    if (frame.pinCount != 0) {
      throw StateError('Cannot discard pinned page $pageIndex');
    }
    _discard(frame);
  }

  /// Discards all cached pages, retaining their buffers for reuse.
  /// Performs no I/O. All pages must be released.
  void discardPages() {
    if (_frames.values.any((frame) => frame.pinCount != 0)) {
      throw StateError('Cannot discard cached pages with pinned pages');
    }
    _freeFrames.addAll(_frames.values);
    _frames.clear();
  }

  /// Flushes explicit preceding writes. Does not write borrowed writable pages.
  /// The caller controls write and flush ordering for publication.
  void flush() => _storage.flush();

  /// Whether storage contains exactly [pageCount] pages, with no trailing bytes.
  bool hasPageCount(int pageCount) => _storage.length == pageCount * pageSize;

  /// Borrows an exclusive, zero-filled buffer to replace an entire page.
  ///
  /// Does not read the old contents. Use [_BufferPage.writeAndRelease] to write
  /// and release the page, or [_BufferPage.release] to discard the replacement.
  /// Throws [StateError] if the page is already pinned or all frames are pinned.
  _BufferPage overwritePage(_FilePageIndex pageIndex) {
    _checkPageIndex(pageIndex);
    var frame = _frames[pageIndex];
    if (frame != null && frame.pinCount != 0) {
      throw StateError('Page $pageIndex is already pinned');
    }
    frame ??= _acquireFrame(pageIndex);
    frame.bytes.fillRange(0, pageSize, 0);
    frame.writable = true;
    frame.pinCount = 1;
    _touch(frame);
    return _BufferPage._(this, frame, writable: true);
  }

  /// Borrows a read-only page, loading it on a cache miss.
  ///
  /// Multiple readers can borrow the same frame. Throws [StateError] if the
  /// page has a writer or a cache miss occurs while all frames are pinned.
  _BufferPage readPage(_FilePageIndex pageIndex) {
    _checkPageIndex(pageIndex);

    // Look for a page in cache, and load that page into cache if not found.
    var frame = _frames[pageIndex];
    if (frame == null) {
      frame = _acquireFrame(pageIndex);
      try {
        _storage.readInto(pageIndex.value * pageSize, frame.bytes);
      } catch (_) {
        // A failed read may leave partial contents; do not keep them cached.
        _discard(frame);
        rethrow;
      }
    } else if (frame.writable) {
      throw StateError('Page $pageIndex has a writer');
    }

    // Pin the frame for this handle and mark it as most recently used.
    frame.pinCount++;
    _touch(frame);
    return _BufferPage._(this, frame, writable: false);
  }

  /// Reads [pageIndices] in their given order directly into [buffer].
  ///
  /// Bypasses cached pages without allocating or evicting frames. Consecutive
  /// page indices share one storage read. The buffer must cover every listed
  /// page, but may omit unused bytes at the end of the last page. An empty list
  /// requires an empty buffer. Listed pages must not have an unwritten writer.
  /// Use within [withExclusiveAccess] when storage is shared between processes.
  void readPagesInto(List<_FilePageIndex> pageIndices, Uint8List buffer) {
    // All but the last listed page need a full page of bytes; the last needs
    // at least one byte so that every listed page participates in the read.
    var minimumLength = pageIndices.isEmpty
        ? 0
        : (pageIndices.length - 1) * pageSize + 1;
    RangeError.checkValueInInterval(
      buffer.length,
      minimumLength,
      pageIndices.length * pageSize,
      'buffer.length',
    );

    // Validate page indices and reject pages with active writable handles.
    for (var pageIndex in pageIndices) {
      _checkPageIndex(pageIndex);
      if (_frames[pageIndex]?.writable ?? false) {
        throw StateError('Page $pageIndex has a writer');
      }
    }

    // Read pages into the buffer, combining consecutive page indices into
    // a single storage read.
    var offset = 0;
    for (var first = 0; first < pageIndices.length;) {
      var end = first + 1;
      while (end < pageIndices.length &&
          pageIndices[end] == pageIndices[end - 1] + 1) {
        end++;
      }
      var bytesToRead = min((end - first) * pageSize, buffer.length - offset);
      _storage.readInto(
        pageIndices[first].value * pageSize,
        Uint8List.sublistView(buffer, offset, offset + bytesToRead),
      );
      offset += bytesToRead;
      first = end;
    }
  }

  /// Resizes storage to [pageCount] physical pages.
  /// Invalidates cached pages. All pages must be released.
  void setPageCount(int pageCount) {
    RangeError.checkNotNegative(pageCount, 'pageCount');
    discardPages();
    _storage.truncate(pageCount * pageSize);
  }

  /// Runs [action] with exclusive storage access.
  ///
  /// Leaves the cache unchanged; [action] must discard stale pages before use.
  /// All pages must be released before entry
  /// and before [action] returns; the callback must be synchronous.
  T withExclusiveAccess<T>(T Function() action) =>
      _storage.withExclusiveAccess(action);

  /// Writes [buffer] directly to [pageIndices] in their given order.
  ///
  /// [pageIndices] must contain the exact number of pages needed for [buffer]
  /// (`buffer.length.divideRoundUp(pageSize)`): the last page may be partially
  /// written (preserving its remaining trailing bytes), and an empty buffer
  /// corresponds to an empty [pageIndices].
  ///
  /// Listed pages must be unpinned. Their cached frames are discarded before
  /// writing, including on failure, so subsequent reads cannot see stale bytes.
  /// Does not flush; use [withExclusiveAccess] for shared storage and [flush]
  /// at the transaction's durability barriers.
  void writePagesFrom(List<_FilePageIndex> pageIndices, Uint8List buffer) {
    // All but the last listed page need a full page of bytes; the last needs
    // at least one byte so that every listed page participates in the write.
    var minimumLength = pageIndices.isEmpty
        ? 0
        : (pageIndices.length - 1) * pageSize + 1;
    RangeError.checkValueInInterval(
      buffer.length,
      minimumLength,
      pageIndices.length * pageSize,
      'buffer.length',
    );

    // Can't write to a page that is currently in use.
    for (var pageIndex in pageIndices) {
      _checkPageIndex(pageIndex);
      if ((_frames[pageIndex]?.pinCount ?? 0) != 0) {
        throw StateError('Page $pageIndex is pinned');
      }
    }

    // We will write these pages directly into the storage.
    // Any previously cached data will become obsolete.
    for (var pageIndex in pageIndices) {
      if (_frames[pageIndex] case var frame?) {
        _discard(frame);
      }
    }

    // Write pages into storage, combining consecutive page indices into
    // a single storage write.
    var offset = 0;
    for (var first = 0; first < pageIndices.length;) {
      var end = first + 1;
      while (end < pageIndices.length &&
          pageIndices[end] == pageIndices[end - 1] + 1) {
        end++;
      }
      var bytesToWrite = min((end - first) * pageSize, buffer.length - offset);
      _storage.write(
        pageIndices[first].value * pageSize,
        Uint8List.sublistView(buffer, offset, offset + bytesToWrite),
      );
      offset += bytesToWrite;
      first = end;
    }
  }

  /// Assigns a frame to [pageIndex], which must not already be cached.
  /// May evict an unpinned page to stay within [capacity].
  /// Throws [StateError] if at capacity and every frame is pinned.
  ///
  /// Registers the frame in [_frames] without initializing its bytes or pinning
  /// it; the caller must do both before exposing it through a handle.
  _BufferFrame _acquireFrame(_FilePageIndex pageIndex) {
    // Validate that pageIndex is not already cached.
    assert(!_frames.containsKey(pageIndex));
    late _BufferFrame frame;
    if (_freeFrames.isNotEmpty) {
      // Use a stored free frame.
      frame = _freeFrames.removeLast();
    } else if (_allocatedFrameCount < capacity) {
      // Allocate a new frame.
      frame = _BufferFrame();
      _allocatedFrameCount++;
    } else {
      // Search for an unused frame to replace with the new page.
      _BufferFrame? victim;
      for (var candidate in _frames.values) {
        if (candidate.pinCount == 0) {
          victim = candidate;
          break;
        }
      }
      if (victim == null) {
        throw StateError('All buffer pool frames are pinned');
      }

      // We are about to use this frame for a new page.
      // So disassociate it from the old page.
      frame = victim;
      _frames.remove(frame.pageIndex);
    }

    // Associate this frame with the new page.
    frame.pageIndex = pageIndex;
    _frames[pageIndex] = frame;
    return frame;
  }

  /// Throws [RangeError] unless [pageIndex] identifies a complete page within
  /// the current storage length.
  void _checkPageIndex(_FilePageIndex pageIndex) {
    RangeError.checkValidIndex(
      pageIndex.value,
      null,
      'pageIndex',
      _storage.length ~/ pageSize,
    );
  }

  /// Removes [frame] from the page cache without writing its contents to storage.
  /// Clears its borrowing state and retains it in [_freeFrames] for reuse.
  void _discard(_BufferFrame frame) {
    _frames.remove(frame.pageIndex);
    frame.pinCount = 0;
    frame.writable = false;
    _freeFrames.add(frame);
  }

  /// Moves [frame] to the most recently used end of [_frames], so eviction
  /// considers less recently used unpinned frames first.
  void _touch(_BufferFrame frame) {
    _frames.remove(frame.pageIndex);
    _frames[frame.pageIndex] = frame;
  }
}

/// Signals that a write batch cannot obtain enough data pages.
/// [SingleFileByteStore.flush] catches this and discards the pending batch
/// without committing its insertions.
class _CapacityException implements Exception {}

/// The decoded file header, independent of the buffer it was read from.
///
/// Header bytes 0..7 contain the magic `DARTBS01`; byte 8 is the active
/// [selectorSlot] (0 or 1), and byte 9 is the format version.
/// Bytes 10 and 11 hold the base-two logarithms of the physical page count and
/// table slot count. Bytes 12..15 hold the page size and 16..19 the chunk count,
/// both little-endian. Bytes 20..27 hold the commit ID as a little-endian signed
/// 64-bit integer.
/// Bytes 28..31 hold the free data-page count as a little-endian unsigned word,
/// describing the allocation bitmap selected by this header.
/// Bytes 32..35 hold the next table slot to examine for data reclamation as a
/// little-endian unsigned word.
/// Bytes 36..37 contain the little-endian Fletcher-16 checksum of bytes 0..35.
/// Publication rewrites the header; a checksum mismatch after interruption
/// causes the store to be reset.
class _Header {
  // Byte offsets within the encoded header.
  static const int _slotOffset = 8;
  static const int _formatVersionOffset = 9;
  static const int _filePageCountLog2Offset = 10;
  static const int _tableSlotCountLog2Offset = 11;
  static const int _pageSizeOffset = 12;
  static const int _allocationBitmapChunkCountOffset = 16;
  static const int _commitIdOffset = 20;
  static const int _freePageCountOffset = 28;
  static const int _dataReclamationClockHandOffset = 32;
  static const int _headerChecksumOffset = 36;

  static const int _formatVersion = 1;
  static const List<int> _headerMagic = [
    0x44, 0x41, 0x52, 0x54, 0x42, 0x53, 0x30, 0x31, // DARTBS01.
  ];

  final int filePageCountLog2;
  final int tableSlotCountLog2;
  final int pageSize;
  final int allocationBitmapChunkCount;

  /// Selects the committed selector bitmap copy: 0 or 1.
  /// Its bits select the committed copies of allocation-bitmap chunks and
  /// table pages. A commit writes and flushes the other selector bitmap copy
  /// before publishing a header that selects it.
  final int selectorSlot;

  // The unique ID of the last write into the store.
  final int commitId;

  /// Unallocated pages in the data area, excluding file metadata pages.
  final int freePageCount;

  /// The next table slot to examine when reclaiming data pages.
  /// Persisted so restarts and cooperating processes continue the same sweep.
  final int dataReclamationClockHand;

  _Header({
    required this.filePageCountLog2,
    required this.tableSlotCountLog2,
    required this.pageSize,
    required this.allocationBitmapChunkCount,
    required this.selectorSlot,
    required this.commitId,
    required this.freePageCount,
    required this.dataReclamationClockHand,
  }) {
    RangeError.checkValueInInterval(
      filePageCountLog2,
      0,
      255,
      'filePageCountLog2',
    );
    RangeError.checkValueInInterval(selectorSlot, 0, 1, 'selectorSlot');
    RangeError.checkValueInInterval(
      tableSlotCountLog2,
      _minTableSlotCountLog2,
      _maxTableSlotCountLog2,
      'tableSlotCountLog2',
    );
    RangeError.checkValueInInterval(
      freePageCount,
      0,
      0xFFFFFFFF,
      'freePageCount',
    );
    RangeError.checkValueInInterval(
      dataReclamationClockHand,
      0,
      (1 << tableSlotCountLog2) - 1,
      'dataReclamationClockHand',
    );
  }

  /// Encodes the header into [bytes].
  void write(Uint8List bytes) {
    bytes.setRange(0, _headerMagic.length, _headerMagic);
    var data = ByteData.sublistView(bytes)
      ..setUint8(_slotOffset, selectorSlot)
      ..setUint8(_formatVersionOffset, _formatVersion)
      ..setUint8(_filePageCountLog2Offset, filePageCountLog2)
      ..setUint8(_tableSlotCountLog2Offset, tableSlotCountLog2)
      ..setUint32(_pageSizeOffset, pageSize, Endian.little)
      ..setUint32(
        _allocationBitmapChunkCountOffset,
        allocationBitmapChunkCount,
        Endian.little,
      )
      ..setInt64(_commitIdOffset, commitId, Endian.little)
      ..setUint32(_freePageCountOffset, freePageCount, Endian.little)
      ..setUint32(
        _dataReclamationClockHandOffset,
        dataReclamationClockHand,
        Endian.little,
      );
    data.setUint16(
      _headerChecksumOffset,
      _headerChecksum(bytes),
      Endian.little,
    );
  }

  /// Throws [FormatException] for an invalid header.
  /// The caller retains ownership of [page].
  /// Configuration compatibility is checked by the byte store after decoding.
  static _Header read(_BufferPage page) {
    var bytes = page.bytes;
    if (bytes[_slotOffset] > 1 ||
        bytes[_formatVersionOffset] != _formatVersion) {
      throw const FormatException('Invalid header slot or format version');
    }
    for (var i = 0; i < _headerMagic.length; i++) {
      if (bytes[i] != _headerMagic[i]) {
        throw const FormatException('Invalid header magic');
      }
    }
    var data = ByteData.sublistView(bytes);
    var tableSlotCountLog2 = bytes[_tableSlotCountLog2Offset];
    if (data.getUint16(_headerChecksumOffset, Endian.little) !=
            _headerChecksum(bytes) ||
        tableSlotCountLog2 < _minTableSlotCountLog2 ||
        tableSlotCountLog2 > _maxTableSlotCountLog2) {
      throw const FormatException('Invalid header checksum or configuration');
    }
    var dataReclamationClockHand = data.getUint32(
      _dataReclamationClockHandOffset,
      Endian.little,
    );
    if (dataReclamationClockHand >= 1 << tableSlotCountLog2) {
      throw const FormatException('Invalid data reclamation clock hand');
    }
    return _Header(
      filePageCountLog2: bytes[_filePageCountLog2Offset],
      tableSlotCountLog2: tableSlotCountLog2,
      pageSize: data.getUint32(_pageSizeOffset, Endian.little),
      allocationBitmapChunkCount: data.getUint32(
        _allocationBitmapChunkCountOffset,
        Endian.little,
      ),
      selectorSlot: bytes[_slotOffset],
      commitId: data.getInt64(_commitIdOffset, Endian.little),
      freePageCount: data.getUint32(_freePageCountOffset, Endian.little),
      dataReclamationClockHand: dataReclamationClockHand,
    );
  }

  static int _headerChecksum(Uint8List bytes) =>
      fletcher16(Uint8List.sublistView(bytes, 0, _headerChecksumOffset));
}

/// A page of continuation data-page indices, all integers little-endian:
///
///     uint32                    nextOverflowMetadataPageIndex (index + 1, or zero)
///     uint16                    dataPageIndexCount
///     uint32[dataPageIndexCount] dataPageIndices
///     uint16                    metadataChecksum
///
/// The checksum covers all preceding fields. Unused bytes are zero. These pages
/// belong to the record and are allocated/freed with its payload pages.
class _OverflowMetadata {
  /// Total bytes for the next-page reference, index count, and trailing checksum.
  /// Excludes the variable-length page-index array.
  static const int _fixedMetadataSize = 8;

  /// Size in bytes of each encoded data-page index.
  static const int _pageIndexSize = 4;

  /// Maximum number of continuation data-page indices in one metadata page.
  static const int pageIndexCapacity =
      (pageSize - _fixedMetadataSize) ~/ _pageIndexSize;

  /// Byte offset of the 16-bit page-index count.
  static const int _dataPageIndexCountOffset = 4;

  /// Byte offset of the page-index array, which is followed by the checksum.
  static const int _dataPageIndicesOffset = 6;

  final _DataPageIndex? nextOverflowMetadataPageIndex;
  final List<_DataPageIndex> dataPages;

  _OverflowMetadata({
    required this.nextOverflowMetadataPageIndex,
    required this.dataPages,
  });

  void write(_BufferPage page) {
    var bytes = page.bytes;
    var data = ByteData.sublistView(bytes);

    // Write index of next overflow metadata page, or 0 if there is none.
    data.setUint32(
      0,
      nextOverflowMetadataPageIndex == null
          ? 0
          : nextOverflowMetadataPageIndex!.value + 1,
      Endian.little,
    );

    // Write count of overflow data pages.
    data.setUint16(_dataPageIndexCountOffset, dataPages.length, Endian.little);

    // Write overflow data page offsets.
    var offset = _dataPageIndicesOffset;
    for (var index in dataPages) {
      data.setUint32(offset, index.value, Endian.little);
      offset += _pageIndexSize;
    }

    // Write the checksum.
    data.setUint16(
      offset,
      fletcher16(Uint8List.sublistView(bytes, 0, offset)),
      Endian.little,
    );
    page.writeAndRelease();
  }

  static _OverflowMetadata read(_BufferPage page) {
    var bytes = page.bytes;
    var data = ByteData.sublistView(bytes);

    // Read data page count on the page, and sanity-check it.
    var dataPageIndexCount = data.getUint16(
      _dataPageIndexCountOffset,
      Endian.little,
    );
    if (dataPageIndexCount == 0 || dataPageIndexCount > pageIndexCapacity) {
      throw const FormatException('Invalid overflow data-page index count');
    }

    // Validate the checksum.
    var checksumOffset =
        _dataPageIndicesOffset + _pageIndexSize * dataPageIndexCount;
    if (data.getUint16(checksumOffset, Endian.little) !=
        fletcher16(Uint8List.sublistView(bytes, 0, checksumOffset))) {
      throw const FormatException('Invalid overflow metadata checksum');
    }

    // Decode the next overflow page link: zero ends the chain; otherwise the
    // stored value is the page index plus one. Data-page indices are stored
    // directly, without this adjustment.
    var nextPage = data.getUint32(0, Endian.little);
    return _OverflowMetadata(
      nextOverflowMetadataPageIndex: nextPage == 0
          ? null
          : _DataPageIndex(nextPage - 1),
      dataPages: [
        for (var i = 0; i < dataPageIndexCount; i++)
          _DataPageIndex(
            data.getUint32(
              _dataPageIndicesOffset + _pageIndexSize * i,
              Endian.little,
            ),
          ),
      ],
    );
  }
}

/// Cumulative statistics for one [SingleFileByteStore] instance.
///
/// These counters live only in memory (they are never written to [Storage]),
/// and they continue accumulating across store resets
/// ([SingleFileByteStore._reset]). They exclude work done by other instances.
class _Statistics {
  int _bucketRebuildCount = 0;
  int _capacityDiscardedBatchCount = 0;
  int _commitCount = 0;
  int _committedEntryCount = 0;
  int _committedValueBytes = 0;
  int _evictedEntryCount = 0;
  int _oversizedValueBytes = 0;
  int _oversizedValueCount = 0;

  _Statistics._();

  /// Bucket rebuilds in committed transactions, including repeats per bucket.
  int get bucketRebuildCount => _bucketRebuildCount;

  /// Batches discarded because the data area could not fit their new records.
  int get capacityDiscardedBatchCount => _capacityDiscardedBatchCount;

  /// Published transactions, including eviction and compaction.
  int get commitCount => _commitCount;

  /// Entries written by successful batches, including replacements and entries
  /// evicted again by later inserts in the same batch.
  int get committedEntryCount => _committedEntryCount;

  /// Value bytes written by successfully committed batches.
  int get committedValueBytes => _committedValueBytes;

  /// Entries durably evicted.
  int get evictedEntryCount => _evictedEntryCount;

  /// Total bytes in values ignored because they exceeded the size limit.
  int get oversizedValueBytes => _oversizedValueBytes;

  /// Values ignored because they exceeded the size limit.
  int get oversizedValueCount => _oversizedValueCount;
}

/// The first page of a value contains its metadata and, without overflow, an
/// inline value prefix.
///
/// Fields in storage order:
///
///     uint16                         keyLength
///     uint8[keyLength]               keyBytes
///     uint32                         valueLength
///     uint16                         valueChecksum
///     uint16                         inlineDataPageIndexCount
///     uint32[inlineDataPageIndexCount] inlineDataPageIndices
///     uint32                         firstOverflowMetadataPage
///     uint16                         metadataChecksum
///     uint8[inlineValueLength]       inlineValueBytes
///
/// All integers are little-endian. Fields are packed without alignment padding;
/// [ByteData] supports unaligned integer accesses. Key bytes are ASCII, and page
/// indices are relative to the data area.
///
/// `firstOverflowMetadataPage` is encoded as index + 1, with zero meaning none.
/// When present, this page contains no value bytes; any remaining bytes are zero.
/// Otherwise, `inlineValueLength` is the smaller of `valueLength` and the space
/// after `metadataChecksum`. Continuation data pages contain only value bytes.
/// Each stored count describes only that page's indices. The reader follows the
/// metadata links and checks the collected data pages against `valueLength`.
///
/// `metadataChecksum` covers every preceding metadata field, including `keyBytes`,
/// `inlineDataPageIndices`, the overflow reference, and `valueChecksum`.
/// `valueChecksum` covers the complete value, including `inlineValueBytes`.
class _ValueHeader {
  static const int maxKeyLength = 100;

  // Encoded field sizes in bytes.
  static const int _keyLengthSize = 2;
  static const int _valueLengthSize = 4;
  static const int _valueChecksumSize = 2;
  static const int _pageIndexCountSize = 2;
  static const int _pageIndexSize = 4;
  static const int _overflowReferenceSize = 4;
  static const int _metadataChecksumSize = 2;

  /// Total metadata bytes excluding the key and inline page-index array.
  static const int _fixedSize =
      _keyLengthSize +
      _valueLengthSize +
      _valueChecksumSize +
      _pageIndexCountSize +
      _overflowReferenceSize +
      _metadataChecksumSize;

  /// Location of this header, retained in memory but not encoded in its bytes.
  final _DataPageIndex firstDataPageIndex;

  final String key;
  final int valueLength;
  final int valueChecksum;
  final List<_DataPageIndex> continuationPages;
  final _DataPageIndex? firstOverflowMetadataPageIndex;

  /// Filled when the overflow chain is read, so replacement can free its pages.
  final List<_DataPageIndex> overflowMetadataPages = [];

  _ValueHeader({
    required this.firstDataPageIndex,
    required this.key,
    required this.valueLength,
    required this.valueChecksum,
    required this.continuationPages,
    required this.firstOverflowMetadataPageIndex,
  });

  int get inlineDataPageIndexCount =>
      min(continuationPages.length, inlinePageIndexCapacity(key.length));

  /// The byte offset within the first page where inline value data begins.
  ///
  /// When overflow metadata pages are present, all value data is stored in
  /// continuation pages. In that case, this returns [pageSize] so that
  /// `pageSize - inlineOffset` evaluates to 0, causing callers to read and
  /// write zero inline bytes from this page.
  int get inlineOffset => firstOverflowMetadataPageIndex != null
      ? pageSize
      : _fixedSize + key.length + _pageIndexSize * inlineDataPageIndexCount;

  /// Writes the metadata and inline prefix, releasing [page] without flushing.
  /// Returns the number of value bytes written, excluding metadata.
  int write(_BufferPage page, Uint8List value) {
    var bytes = page.bytes;
    var data = ByteData.sublistView(bytes);

    data.setUint16(0, key.length, Endian.little);
    bytes.setAll(_keyLengthSize, key.codeUnits);
    var offset = _keyLengthSize + key.length;

    data.setUint32(offset, valueLength, Endian.little);
    offset += _valueLengthSize;

    data.setUint16(offset, valueChecksum, Endian.little);
    offset += _valueChecksumSize;

    // Write the count of continuation data-page indices stored in this header.
    data.setUint16(offset, inlineDataPageIndexCount, Endian.little);
    offset += _pageIndexCountSize;

    // Write those continuation data-page indices.
    for (var index in continuationPages.take(inlineDataPageIndexCount)) {
      data.setUint32(offset, index.value, Endian.little);
      offset += _pageIndexSize;
    }

    // Write the first overflow metadata page index plus one, or zero if absent.
    // Overflow metadata pages store continuation data-page indices that do not
    // fit in this header, plus an encoded link to the next overflow metadata page.
    data.setUint32(
      offset,
      firstOverflowMetadataPageIndex == null
          ? 0
          : firstOverflowMetadataPageIndex!.value + 1,
      Endian.little,
    );
    offset += _overflowReferenceSize;

    data.setUint16(
      offset,
      fletcher16(Uint8List.sublistView(bytes, 0, offset)),
      Endian.little,
    );

    var inlineLength = min(value.length, pageSize - inlineOffset);
    bytes.setRange(inlineOffset, inlineOffset + inlineLength, value);

    page.writeAndRelease();
    return inlineLength;
  }

  static int continuationDataPageCount({
    required int keyLength,
    required int valueLength,
  }) {
    var excess = valueLength + keyLength + _fixedSize - pageSize;
    // A continuation adds 1024 payload bytes but consumes 4 inline bytes
    // for its index. Account for both when choosing the smallest page count.
    var count = excess <= 0
        ? 0
        : excess.divideRoundUp(pageSize - _pageIndexSize);
    // Overflow uses the whole first page for metadata, so all value bytes move
    // to continuation pages. Counts here are not limited to uint16.
    return count <= inlinePageIndexCapacity(keyLength)
        ? count
        : valueLength.divideRoundUp(pageSize);
  }

  /// Maximum continuation-page indices that fit in the header after reserving
  /// space for the key and fixed fields, including the overflow reference and
  /// metadata checksum.
  static int inlinePageIndexCapacity(int keyLength) =>
      (pageSize - _fixedSize - keyLength) ~/ _pageIndexSize;

  static bool isValidKey(String key) =>
      key.isNotEmpty &&
      key.length <= maxKeyLength &&
      key != '.' &&
      !key.contains('..') &&
      key.codeUnits.every(
        (byte) =>
            byte >= $a && byte <= $z ||
            byte >= $0 && byte <= $9 ||
            byte == $PERIOD ||
            byte == $_,
      );

  static int maximumValueLength(int dataPageCount) {
    var remainingPages = dataPageCount - 1;
    var excess = remainingPages - inlinePageIndexCapacity(maxKeyLength);
    // Each additional metadata page consumes a page and describes 254 payload
    // pages. Reserve enough metadata for the worst-case key length.
    var metadataPages = excess <= 0
        ? 0
        : excess.divideRoundUp(_OverflowMetadata.pageIndexCapacity + 1);
    return (remainingPages - metadataPages) * pageSize;
  }

  /// Number of overflow metadata pages needed for continuation-page indices
  /// that do not fit in the value header. These pages let large values span
  /// more data pages than the header alone can reference.
  /// Returns zero if all indices fit in the header.
  static int overflowMetadataPageCount({
    required int keyLength,
    required int continuationDataPageCount,
  }) {
    var excess = continuationDataPageCount - inlinePageIndexCapacity(keyLength);
    return excess <= 0
        ? 0
        : excess.divideRoundUp(_OverflowMetadata.pageIndexCapacity);
  }

  /// Decodes and validates the [_ValueHeader] from [page] (located at
  /// [firstDataPageIndex]), including its inline continuation-page indices.
  ///
  /// Any additional continuation-page indices in the overflow chain are not
  /// loaded yet (see [SingleFileByteStore._readOverflowMetadata]).
  ///
  /// Does not release [page]; the returned header copies all data it needs from
  /// [page] so the caller can release [page] immediately.
  ///
  /// Throws [FormatException] if the metadata checksum, key, field lengths, or
  /// page indices are invalid, out of range for [dataPageCount], or contain
  /// duplicates (including [firstDataPageIndex]).
  static _ValueHeader read(
    _BufferPage page,
    _DataPageIndex firstDataPageIndex,
    int dataPageCount,
  ) {
    var bytes = page.bytes;
    var data = ByteData.sublistView(bytes);

    var keyLength = data.getUint16(0, Endian.little);
    if (keyLength == 0 || keyLength > maxKeyLength) {
      throw const FormatException('Invalid record key length');
    }

    var offset = _keyLengthSize + keyLength;
    var valueLength = data.getUint32(offset, Endian.little);
    offset += _valueLengthSize;

    var valueChecksum = data.getUint16(offset, Endian.little);
    offset += _valueChecksumSize;

    var dataPageIndexCount = data.getUint16(offset, Endian.little);
    offset += _pageIndexCountSize;

    var checksumOffset =
        _fixedSize +
        keyLength +
        dataPageIndexCount * _pageIndexSize -
        _metadataChecksumSize;
    if (checksumOffset + _metadataChecksumSize > pageSize) {
      throw const FormatException('Invalid data-page index count');
    }

    if (data.getUint16(checksumOffset, Endian.little) !=
        fletcher16(Uint8List.sublistView(bytes, 0, checksumOffset))) {
      throw const FormatException('Invalid record metadata checksum');
    }

    var key = String.fromCharCodes(
      bytes,
      _keyLengthSize,
      _keyLengthSize + keyLength,
    );
    if (!isValidKey(key)) {
      throw const FormatException('Invalid record key');
    }

    // Read and validate overflow data page indices.
    var pages = <_DataPageIndex>[];
    var seen = <_DataPageIndex>{firstDataPageIndex};
    for (var i = 0; i < dataPageIndexCount; i++, offset += _pageIndexSize) {
      var index = _DataPageIndex(data.getUint32(offset, Endian.little));
      // Reject repeats, including a reference back to the first metadata page.
      if (index.value >= dataPageCount || !seen.add(index)) {
        throw const FormatException('Invalid or repeated continuation page');
      }
      pages.add(index);
    }

    // Read and validate the overflow metadata page index.
    var storedOverflowPage = data.getUint32(offset, Endian.little);
    if (storedOverflowPage > dataPageCount ||
        storedOverflowPage != 0 &&
            seen.contains(_DataPageIndex(storedOverflowPage - 1))) {
      throw const FormatException('Invalid first overflow metadata page');
    }

    // Return the decoded header with its inline continuation-page indices.
    // Decode the overflow link from index + 1, with zero meaning no overflow;
    // any additional continuation-page indices are loaded from that chain later.
    return _ValueHeader(
      firstDataPageIndex: firstDataPageIndex,
      key: key,
      valueLength: valueLength,
      valueChecksum: valueChecksum,
      continuationPages: pages,
      firstOverflowMetadataPageIndex: storedOverflowPage == 0
          ? null
          : _DataPageIndex(storedOverflowPage - 1),
    );
  }
}

/// A transaction that stages updates (entry insertions, replacements, or
/// evictions) against the current committed state and publishes them atomically
/// on [commit].
///
/// Modified allocation-bitmap chunks, hash-table pages, and selector bits are
/// held in private in-memory copies (`_workingAllocationBitmapChunks`,
/// `_workingTablePages`, and `_selectors`) so the [_BufferPool] can freely
/// evict frames while new record pages are written. Calling [commit] writes
/// the modified metadata to shadow pages and publishes a new [_Header].
class _WriteTransaction {
  int _freePageCount;
  int _dataReclamationClockHand;
  int _rebuiltBucketCount = 0;
  int _evictedEntryCount = 0;
  final SingleFileByteStore _store;
  final int _selectorSlot;

  /// Initialized with a copy of the committed selectors. During [commit], bits
  /// are flipped to select newly written shadow pages before publishing this
  /// bitmap.
  late final Uint8List _selectors;

  /// Working copies of changed allocation bitmap chunks, keyed by chunk index.
  /// Bits reserve new data pages during preparation and free replaced pages
  /// during [commit].
  final Map<_AllocationBitmapChunkIndex, Uint8List>
  _workingAllocationBitmapChunks = {};

  /// Working copies of changed table pages, keyed by logical page index.
  /// Lookups use these bytes to see entries updated earlier in this transaction.
  final Map<_TablePageIndex, Uint8List> _workingTablePages = {};

  /// Working copies of per-bucket slices of [SingleFileByteStore._clockBits]
  /// for changed table pages, keyed by logical table page index.
  ///
  /// Updated when entries are inserted, scanned for eviction, or moved to new
  /// slots by [_rebuildBucket], and copied back into
  /// [SingleFileByteStore._clockBits] during [commit].
  final Map<_TablePageIndex, Uint8List> _workingBucketClockBits = {};

  final List<_DataPageIndex> _pagesToFree = [];

  /// First data page not yet scanned in this transaction. Earlier pages stay
  /// allocated until commit, so subsequent allocations need not revisit them.
  _DataPageIndex _nextAllocationPageIndex = const _DataPageIndex(0);

  _WriteTransaction(this._store, _Header header)
    : _selectorSlot = header.selectorSlot,
      _dataReclamationClockHand = header.dataReclamationClockHand,
      _freePageCount = header.freePageCount {
    _selectors = _store._readSelectors(_selectorSlot);
  }

  _Header commit() {
    // Keep old pages allocated until every new record has been written. Even
    // pages replaced earlier in this batch still belong to the committed root.
    for (var page in _pagesToFree) {
      var chunkIndex = _AllocationBitmapChunkIndex(
        page.value ~/ _dataPagesPerAllocationChunk,
      );
      var chunk = _workingAllocationBitmapChunks.putIfAbsent(
        chunkIndex,
        () => _copyCommittedAllocationBitmapChunk(chunkIndex),
      );
      chunk.setBit(page.value % _dataPagesPerAllocationChunk, false);
    }
    _freePageCount += _pagesToFree.length;

    // Write each changed allocation bitmap chunk to its shadow and flip its
    // selector once, regardless of how many page allocations changed it.
    for (var MapEntry(key: chunkIndex, value: bytes)
        in _workingAllocationBitmapChunks.entries) {
      var slot = _selectors.bitAt(chunkIndex.value) ? 1 : 0;
      _writePage(
        _store._allocationBitmapChunkIndexToFilePageIndex(1 - slot, chunkIndex),
        bytes,
      );
      _selectors.flipBit(chunkIndex.value);
    }

    // Write each changed table page to its shadow and flip its selector once,
    // regardless of how many entries changed. Table selectors follow the
    // allocation bitmap selectors.
    for (var MapEntry(key: index, value: bytes) in _workingTablePages.entries) {
      var selectorBit = _store._allocationBitmapChunkCount + index.value;
      var slot = _selectors.bitAt(selectorBit) ? 1 : 0;
      _writePage(_store._tablePageIndexToFilePageIndex(1 - slot, index), bytes);
      _selectors.flipBit(selectorBit);
    }

    // The old header cannot reach these shadows. Flush data, metadata, and
    // selectors together before publishing the header that selects them.
    var shadowSelectorSlot = 1 - _selectorSlot;
    _writePage(_store._selectorPageIndex(shadowSelectorSlot), _selectors);
    _store._bufferPool.flush();

    // Publish the complete transaction with the header. An invalid
    // header after interruption causes a reset, reclaiming all allocations.
    var header = _store._writeHeader(
      selectorSlot: shadowSelectorSlot,
      freePageCount: _freePageCount,
      dataReclamationClockHand: _dataReclamationClockHand,
    );
    _store._bufferPool.flush();
    _store._cachedCommitId = header.commitId;

    // Drop pages read or staged during writing; subsequent readers populate the
    // cache from the newly committed state and retain it across reads.
    _store._bufferPool.discardPages();
    for (var MapEntry(key: index, value: clockBits)
        in _workingBucketClockBits.entries) {
      _store._clockBits.setAll(
        index.value * _tableEntriesPerPage ~/ 8,
        clockBits,
      );
    }

    _store.statistics._commitCount++;
    _store.statistics._evictedEntryCount += _evictedEntryCount;
    _store.statistics._bucketRebuildCount += _rebuiltBucketCount;

    return header;
  }

  /// Evicts entries from the hash table, to free at least the
  /// [requiredFreePageCount] of data pages.
  ///
  /// The scanning is done across buckets (in contrast to evicting only from a
  /// single bucket when a bucket is full during insertion). Each affected
  /// bucket is rebuilt to reorder entries according to their hash values.
  ///
  /// The transaction must be [commit]ted to finalize the changes.
  void evictForPages(int requiredFreePageCount) {
    var changedBuckets = <_TablePageIndex>{};

    _TablePageIndex? currentPageIndex;
    late ByteData currentPageData;
    // Allow two passes: one to clear reference bits, another to evict.
    // Stop earlier once enough pages are free or scheduled to be freed.
    for (var scanned = 0; scanned < 2 * _store.tableSlotCount; scanned++) {
      // Count both currently free pages and pages this transaction will free.
      // The latter become reusable only after the eviction commits.
      if (_freePageCount + _pagesToFree.length >= requiredFreePageCount) break;

      // Move the clock hand forward, with wrapping around.
      var entryIndex = _dataReclamationClockHand;
      _dataReclamationClockHand =
          (entryIndex + 1) & (_store.tableSlotCount - 1);

      // Maybe read a new table page.
      var pageIndex = _TablePageIndex(entryIndex ~/ _tableEntriesPerPage);
      if (pageIndex != currentPageIndex) {
        currentPageData = ByteData.sublistView(_readTablePage(pageIndex));
        currentPageIndex = pageIndex;
      }

      var entryIndexAtPage = entryIndex % _tableEntriesPerPage;
      var entryOffset = entryIndexAtPage * _tableEntrySize;
      var storedPage = currentPageData.getUint32(
        entryOffset + _tableEntryPageReferenceOffset,
        Endian.little,
      );

      // An empty table slot has no record whose pages we can reclaim.
      if (storedPage == 0) {
        continue;
      }

      // Give the entry a second chance.
      var clockBits = _getBucketClockBits(pageIndex);
      if (clockBits.bitAt(entryIndexAtPage)) {
        clockBits.setBit(entryIndexAtPage, false);
        continue;
      }

      // Creates a copy of [currentPageIndex] page in [_workingTablePages].
      _evictEntry(pageIndex, entryIndexAtPage);

      // Switch data of [currentPageIndex] to [_workingTablePages].
      currentPageData = ByteData.sublistView(_workingTablePages[pageIndex]!);
      changedBuckets.add(pageIndex);
    }

    if (_freePageCount + _pagesToFree.length < requiredFreePageCount) {
      throw _CapacityException();
    }

    // We are done updating buckets, rebuild each once.
    for (var index in changedBuckets) {
      _rebuildBucket(index);
    }
  }

  /// Inserts or replaces [key] in its hash-table bucket, evicting entries
  /// if a new key's bucket is full.
  ///
  /// Writes [value] to newly allocated data pages, including its header and
  /// any overflow metadata needed to locate continuation pages. Updates the
  /// working table entry with the key hash and the first data-page index.
  ///
  /// The changes become visible to other processes only after [commit].
  /// Pages belonging to a replaced entry remain allocated until then.
  void put(String key, Uint8List value) {
    var keyHash = SingleFileByteStore.hashKey(key);
    var entry = _store._lookup(
      _selectors,
      key,
      keyHash: keyHash,
      tablePages: _workingTablePages,
    );

    // A full-bucket miss needs eviction; existing keys can still be replaced.
    if (entry.entryIndex < 0) {
      var homeEntryIndex = keyHash & (_store.tableSlotCount - 1);
      var bucketIndex = _TablePageIndex(homeEntryIndex ~/ _tableEntriesPerPage);
      _evictBucket(bucketIndex);
      entry = _store._lookup(
        _selectors,
        key,
        keyHash: keyHash,
        tablePages: _workingTablePages,
      );
    }

    // Eviction must leave an empty slot for the new key.
    //
    // This is purely a defensive invariant check (it cannot occur in the
    // absence of bugs).
    if (entry.entryIndex < 0) {
      throw StateError('Bucket remains full after eviction');
    }

    var continuationDataPageCount = _ValueHeader.continuationDataPageCount(
      keyLength: key.length,
      valueLength: value.length,
    );
    var overflowMetadataPageCount = _ValueHeader.overflowMetadataPageCount(
      keyLength: key.length,
      continuationDataPageCount: continuationDataPageCount,
    );
    var pages = _allocatePages(
      1 + continuationDataPageCount + overflowMetadataPageCount,
    );
    var valuePages = pages.sublist(0, 1 + continuationDataPageCount);
    var metadataPages = pages.sublist(1 + continuationDataPageCount);

    var header = _ValueHeader(
      firstDataPageIndex: valuePages.first,
      key: key,
      valueLength: value.length,
      valueChecksum: fletcher16(value),
      continuationPages: valuePages.sublist(1),
      firstOverflowMetadataPageIndex: metadataPages.firstOrNull,
    );

    // These pages are reserved only in the working bitmap. Writing their bytes
    // now is harmless to the committed state and lets later hash collisions read
    // their keys through the usual buffer pool.
    var page = _store._bufferPool.overwritePage(
      _store._dataPageIndexToFilePageIndex(valuePages.first),
    );
    late int inlineValueLength;
    try {
      inlineValueLength = header.write(page, value);
    } finally {
      page.release();
    }
    _store._bufferPool.writePagesFrom([
      for (var index in header.continuationPages)
        _store._dataPageIndexToFilePageIndex(index),
    ], Uint8List.sublistView(value, inlineValueLength));

    // Write continuation-page indices that do not fit in the value header
    // into a linked chain of overflow metadata pages.
    for (var i = 0; i < metadataPages.length; i++) {
      var start =
          header.inlineDataPageIndexCount +
          i * _OverflowMetadata.pageIndexCapacity;
      var metadata = _OverflowMetadata(
        nextOverflowMetadataPageIndex: i + 1 < metadataPages.length
            ? metadataPages[i + 1]
            : null,
        dataPages: header.continuationPages.sublist(
          start,
          // The final metadata page may hold fewer indices than its capacity.
          min(
            start + _OverflowMetadata.pageIndexCapacity,
            continuationDataPageCount,
          ),
        ),
      );
      var page = _store._bufferPool.overwritePage(
        _store._dataPageIndexToFilePageIndex(metadataPages[i]),
      );
      try {
        metadata.write(page);
      } finally {
        page.release();
      }
    }

    // Add the entry to the working table page: key hash and the new record's
    // first data-page index, encoded as `index + 1` to reserve zero for
    // empty slots.
    var index = _TablePageIndex(entry.entryIndex ~/ _tableEntriesPerPage);
    var bytes = _getWritableTablePage(index);
    var entryOffset =
        (entry.entryIndex % _tableEntriesPerPage) * _tableEntrySize;
    ByteData.sublistView(bytes)
      ..setUint32(entryOffset, keyHash, Endian.little)
      ..setUint32(
        entryOffset + _tableEntryPageReferenceOffset,
        pages.first.value + 1,
        Endian.little,
      );

    // Mark the entry as recently used so CLOCK gives it a second chance.
    _getBucketClockBits(
      index,
    ).setBit(entry.entryIndex % _tableEntriesPerPage, true);

    // If replaced a value, schedule freeing old pages.
    _pagesToFree.addAll([
      ?entry.header?.firstDataPageIndex,
      ...?entry.header?.continuationPages,
      ...?entry.header?.overflowMetadataPages,
    ]);
  }

  /// Reserves [count] free data pages in the working allocation bitmaps.
  /// Returns their indices in ascending order, not necessarily contiguous.
  /// Does not write page contents or reuse pages scheduled to be freed by this
  /// transaction; those become available only after [commit].
  ///
  /// Throws [_CapacityException] if too few free pages remain. Reservations
  /// may already have been made, so the transaction must then be discarded.
  List<_DataPageIndex> _allocatePages(int count) {
    var result = <_DataPageIndex>[];

    // Iterate from the previous maybe free data page to the last.
    var dataPageIndexRaw = _nextAllocationPageIndex.value;
    while (dataPageIndexRaw < _store._dataPageCount) {
      var chunkIndex = _AllocationBitmapChunkIndex(
        dataPageIndexRaw ~/ _dataPagesPerAllocationChunk,
      );
      var bitmapChunk =
          _workingAllocationBitmapChunks[chunkIndex] ??
          _copyCommittedAllocationBitmapChunk(chunkIndex);

      // The final bitmap chunk may contain unused bits beyond the data area.
      var chunkEnd = min(
        (chunkIndex.value + 1) * _dataPagesPerAllocationChunk,
        _store._dataPageCount,
      );

      // Iterate through the bitmap chunk bits.
      while (dataPageIndexRaw < chunkEnd) {
        var chunkBit = dataPageIndexRaw % _dataPagesPerAllocationChunk;
        // All eight pages represented by this byte are allocated.
        // Skip to the first page represented by the next byte.
        if (bitmapChunk[chunkBit ~/ 8] == 0xFF) {
          dataPageIndexRaw = (dataPageIndexRaw ~/ 8 + 1) * 8;
          continue;
        }
        if (!bitmapChunk.bitAt(chunkBit)) {
          bitmapChunk.setBit(chunkBit, true);
          _workingAllocationBitmapChunks[chunkIndex] = bitmapChunk;
          result.add(_DataPageIndex(dataPageIndexRaw));
          // Stop when we have enough pages.
          if (result.length == count) {
            _nextAllocationPageIndex = _DataPageIndex(dataPageIndexRaw + 1);
            _freePageCount -= count;
            return result;
          }
        }
        dataPageIndexRaw++;
      }
    }
    throw _CapacityException();
  }

  /// Copies [chunkIndex] from the allocation bitmap slot selected by
  /// [_selectors].
  ///
  /// Returns independent bytes that this transaction can modify without
  /// changing the committed bitmap or its cached page.
  Uint8List _copyCommittedAllocationBitmapChunk(
    _AllocationBitmapChunkIndex chunkIndex,
  ) {
    return _readPage(
      _store._allocationBitmapChunkIndexToFilePageIndex(
        _selectors.bitAt(chunkIndex.value) ? 1 : 0,
        chunkIndex,
      ),
    );
  }

  /// Evicts [_bucketEvictionCount] entries from a full page-sized bucket to
  /// make room for insertion.
  void _evictBucket(_TablePageIndex index) {
    var victimsRemaining = _bucketEvictionCount;
    var data = ByteData.sublistView(_getWritableTablePage(index));
    var clockBits = _getBucketClockBits(index);

    // Allow two passes: one to clear reference bits, another to evict.
    // Stop earlier once enough victims have been selected.
    for (
      var scanned = 0;
      scanned < 2 * _tableEntriesPerPage && victimsRemaining > 0;
      scanned++
    ) {
      // Move the clock hand forward, with wrapping around.
      var slot = _store._bucketClockHands[index.value];
      _store._bucketClockHands[index.value] =
          (slot + 1) & (_tableEntriesPerPage - 1);

      var entryOffset = slot * _tableEntrySize;
      var storedPage = data.getUint32(
        entryOffset + _tableEntryPageReferenceOffset,
        Endian.little,
      );

      // Already empty.
      if (storedPage == 0) {
        continue;
      }

      // Give the entry a second chance.
      if (clockBits.bitAt(slot)) {
        clockBits.setBit(slot, false);
        continue;
      }

      _evictEntry(index, slot);
      victimsRemaining--;
    }

    // Two CLOCK passes must find enough victims in a full bucket.
    //
    // This is purely a defensive invariant check (it cannot occur in the
    // absence of bugs).
    if (victimsRemaining != 0) {
      throw StateError('Could not evict enough entries from a full bucket');
    }

    _rebuildBucket(index);
  }

  /// Erases the entry corresponding to [slot] from [index] page.
  ///
  /// Leaves a temporary hole. The caller must rebuild this bucket before any
  /// lookup or publication. Freed pages remain reserved until commit, including
  /// pages belonging to records inserted and evicted in this same transaction.
  void _evictEntry(_TablePageIndex index, int slot) {
    var data = ByteData.sublistView(_getWritableTablePage(index));
    var offset = slot * _tableEntrySize;
    var storedPage = data.getUint32(
      offset + _tableEntryPageReferenceOffset,
      Endian.little,
    );

    // Sanity check.
    if (storedPage == 0 || storedPage > _store._dataPageCount) {
      throw const FormatException('Invalid table entry page');
    }

    // Collect the data pages of the entry.
    var header = _store._readValueHeader(_DataPageIndex(storedPage - 1));
    _store._readOverflowMetadata(header);
    _pagesToFree.addAll([
      header.firstDataPageIndex,
      ...header.continuationPages,
      ...header.overflowMetadataPages,
    ]);

    // Erase the entry: hash and first page.
    data.setUint32(offset, 0, Endian.little);
    data.setUint32(offset + _tableEntryPageReferenceOffset, 0, Endian.little);

    // This entry is definitely not used.
    _getBucketClockBits(index).setBit(slot, false);
    _evictedEntryCount++;
  }

  Uint8List _getBucketClockBits(_TablePageIndex index) {
    return _workingBucketClockBits.putIfAbsent(index, () {
      var start = index.value * _tableEntriesPerPage ~/ 8;
      return Uint8List.fromList(
        _store._clockBits.sublist(start, start + _tableEntriesPerPage ~/ 8),
      );
    });
  }

  /// Returns the working copy to publish when this transaction commits.
  Uint8List _getWritableTablePage(_TablePageIndex index) {
    return _workingTablePages.putIfAbsent(index, () {
      return _readPage(_store._committedTableFilePageIndex(_selectors, index));
    });
  }

  /// Returns a mutable copy of the page at [index] for this transaction to modify.
  Uint8List _readPage(_FilePageIndex index) {
    var page = _store._bufferPool.readPage(index);
    try {
      return Uint8List.fromList(page.bytes);
    } finally {
      page.release();
    }
  }

  Uint8List _readTablePage(_TablePageIndex index) =>
      _workingTablePages[index] ??
      _readPage(_store._committedTableFilePageIndex(_selectors, index));

  /// Rebuilds [index] by re-inserting its surviving entries into a fresh page
  /// buffer, eliminating the empty holes left by [_evictEntry].
  ///
  /// Uses the 32-bit hashes already stored in the table entries without
  /// rereading the records' data pages, and moves each surviving entry's
  /// CLOCK bit ([_workingBucketClockBits]) to its new slot. Because linear
  /// probing wraps within a single 128-entry bucket rather than crossing page
  /// boundaries, other buckets are unaffected.
  void _rebuildBucket(_TablePageIndex index) {
    var sourceData = ByteData.sublistView(_readTablePage(index));
    var sourceClockBits = _getBucketClockBits(index);

    // Empty page to fill.
    var rebuiltBytes = Uint8List(pageSize);
    var rebuiltData = ByteData.sublistView(rebuiltBytes);
    var rebuiltClockBits = Uint8List(sourceClockBits.length);

    for (var sourceSlot = 0; sourceSlot < _tableEntriesPerPage; sourceSlot++) {
      var offset = sourceSlot * _tableEntrySize;
      var storedPage = sourceData.getUint32(
        offset + _tableEntryPageReferenceOffset,
        Endian.little,
      );
      if (storedPage == 0) continue;

      // Find an empty slot for the hash.
      var hash = sourceData.getUint32(offset, Endian.little);
      var rebuiltSlot = hash & (_tableEntriesPerPage - 1);
      while (rebuiltData.getUint32(
            rebuiltSlot * _tableEntrySize + _tableEntryPageReferenceOffset,
            Endian.little,
          ) !=
          0) {
        rebuiltSlot = (rebuiltSlot + 1) & (_tableEntriesPerPage - 1);
      }

      // Put the entry at the found slot.
      rebuiltData.setUint32(rebuiltSlot * _tableEntrySize, hash, Endian.little);
      rebuiltData.setUint32(
        rebuiltSlot * _tableEntrySize + _tableEntryPageReferenceOffset,
        storedPage,
        Endian.little,
      );
      rebuiltClockBits.setBit(rebuiltSlot, sourceClockBits.bitAt(sourceSlot));
    }

    // Replace the working data.
    _workingTablePages[index] = rebuiltBytes;
    _workingBucketClockBits[index] = rebuiltClockBits;
    _rebuiltBucketCount++;
  }

  void _writePage(_FilePageIndex index, Uint8List bytes) {
    var page = _store._bufferPool.overwritePage(index);
    try {
      page.bytes.setAll(0, bytes);
      page.writeAndRelease();
    } finally {
      page.release();
    }
  }
}

/// Logical allocation-bitmap chunk, independent of which physical slot holds it.
extension type const _AllocationBitmapChunkIndex(int value) {}

/// An index relative to the data area. Bounds depend on the owning byte store.
extension type const _DataPageIndex(int value) {}

/// An index relative to the start of storage, including metadata pages.
extension type const _FilePageIndex(int value) {
  _FilePageIndex operator +(int pageOffset) =>
      _FilePageIndex(value + pageOffset);
}

/// Logical table page, independent of which physical slot holds it.
extension type const _TablePageIndex(int value) {}

extension on int {
  /// Divides a nonnegative value by a positive divisor, rounding up.
  int divideRoundUp(int divisor) => (this + divisor - 1) ~/ divisor;
}

/// Bit indices are numbered least significant first within each byte,
/// starting at bit zero of the first byte.
extension on Uint8List {
  bool bitAt(int bitIndex) =>
      (this[bitIndex ~/ 8] & (1 << (bitIndex % 8))) != 0;

  void flipBit(int bitIndex) {
    this[bitIndex ~/ 8] ^= 1 << (bitIndex % 8);
  }

  void setBit(int bitIndex, bool value) {
    var byteIndex = bitIndex ~/ 8;
    var mask = 1 << (bitIndex % 8);
    if (value) {
      this[byteIndex] |= mask;
    } else {
      this[byteIndex] &= ~mask;
    }
  }
}
