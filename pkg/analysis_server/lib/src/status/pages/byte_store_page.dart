// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analysis_server/src/utilities/timing_byte_store.dart';
import 'package:collection/collection.dart';

String _bytesCell(int bytes) => _cell(bytes == 0 ? '' : printBytes(bytes));

String _cell(String text, {int rowSpan = 1}) {
  var rowSpanAttribute = rowSpan == 1 ? '' : ' rowspan="$rowSpan"';
  return '<td class="right nowrap"$rowSpanAttribute>$text</td>';
}

/// Formats [value] with thousands separators, such as `27,275`.
String _formatCount(int value) {
  var digits = '${value.abs()}';
  var buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Formats [part] of [whole] as a percentage in HTML, such as `85.3%`.
///
/// A fraction that is not exactly zero or one is shown as `< 0.1%` or
/// `> 99.9%` rather than rounded to `0.0%` or `100.0%`, so that a few misses
/// among many hits are not hidden.
String _formatFraction(int part, int whole) {
  var text = printPercentage(part / whole);
  if (part != 0 && text == printPercentage(0)) {
    return '&lt; 0.1%';
  }
  if (part != whole && text == printPercentage(1)) {
    return '&gt; 99.9%';
  }
  return text;
}

/// Formats [time] as `HH:mm:ss.SSS`.
String _formatTime(DateTime time) {
  String digits(int value, int width) => '$value'.padLeft(width, '0');
  return '${digits(time.hour, 2)}:${digits(time.minute, 2)}:'
      '${digits(time.second, 2)}.${digits(time.millisecond, 3)}';
}

String _numberCell(int value) => _cell(value == 0 ? '' : _formatCount(value));

String _timeCell(Duration duration) {
  var microseconds = duration.inMicroseconds;
  return _cell(
    microseconds == 0 ? '' : (microseconds / 1000).toStringAsFixed(3),
  );
}

class ByteStorePage extends DiagnosticPageWithNav {
  new(DiagnosticsSite site)
    : super(
        site,
        'byte-store',
        'Byte store',
        description:
            'The memory cache and the disk store of analysis results, '
            'with timings of disk operations.',
      );

  @override
  Future<void> generateContent(Map<String, String> params) async {
    // The scan reads the current header of the single file store, so scan
    // first, for the data used in the statistics to match the entries.
    var scanTimer = Stopwatch()..start();
    var bucketEntryCounts = server.singleFileTableBucketEntryCounts();
    var scanTime = scanTimer.elapsed;
    var stats = server.byteStoreStats;
    if (stats == null) {
      p('The server did not create a byte store.');
      return;
    }

    var path = stats.singleFileStorePath ?? stats.fileStorePath;
    if (path != null) {
      buf.writeln(formatOption('Disk store path', escape(path)));
    }

    // Both tables are narrow, so side by side they leave the operations
    // tables closer to the top.
    buf.writeln('<div class="columns">');
    buf.writeln('<div class="column one-half">');
    _writeMemoryCache(stats, hasDiskStore: path != null);
    // Below the memory cache, the shorter table, to keep the page short.
    if (bucketEntryCounts != null) {
      _writeTableBuckets(stats, bucketEntryCounts, scanTime: scanTime);
    }
    buf.writeln('</div>');
    buf.writeln('<div class="column one-half">');
    if (bucketEntryCounts != null) {
      _writeSingleFileStore(stats, bucketEntryCounts);
    } else if (stats.usesFileByteStore) {
      _writeFileStore(stats);
    } else {
      h3('Disk Store');
      p('The disk store is disabled or unavailable.');
    }
    buf.writeln('</div>');
    buf.writeln('</div>');

    if (path != null) {
      _writeOperations();
    }
  }

  /// Writes [groups] of facts as one table under [title], each group under
  /// its label, so that values still align across groups.
  void _writeFactGroups(String title, Map<String, Map<String, String>> groups) {
    h3(title);
    buf.writeln('<table>');
    for (var MapEntry(key: label, value: facts) in groups.entries) {
      buf.writeln('<tbody>');
      buf.writeln('<tr><th colspan="2" scope="rowgroup">$label</th></tr>');
      _writeFactRows(facts);
      buf.writeln('</tbody>');
    }
    buf.writeln('</table>');
  }

  void _writeFactRows(Map<String, String> facts) {
    for (var MapEntry(key: name, :value) in facts.entries) {
      buf.writeln('<tr><td>$name</td>${_cell(value)}</tr>');
    }
  }

  /// Writes [facts] as a table of names and values under [title].
  ///
  /// Each value is a single number, so that values align.
  void _writeFacts(String title, Map<String, String> facts) {
    h3(title);
    buf.writeln('<table>');
    _writeFactRows(facts);
    buf.writeln('</table>');
  }

  void _writeFileStore(AnalysisServerByteStoreStats stats) {
    _writeFacts('File Store', {
      'Limit': printBytes(stats.fileCacheSizeBytes ?? 0),
      if (stats.fileStoreSizeBytes case var fileStoreSizeBytes?)
        'Last observed size': printBytes(fileStoreSizeBytes),
      'Pending writes': _formatCount(stats.pendingWriteCount ?? 0),
      'Reads': _formatCount(stats.readCount ?? 0),
      'Read misses': _formatCount(stats.readMissCount ?? 0),
      'Writes': _formatCount(stats.writeCount ?? 0),
      'Written bytes': printBytes(stats.writeBytes ?? 0),
      'Cleanup runs': _formatCount(stats.cleanUpCount ?? 0),
      'Files deleted by cleanup': _formatCount(stats.deletedFileCount ?? 0),
      'Bytes deleted by cleanup': printBytes(stats.deletedBytes ?? 0),
      if (stats.lastCleanUpTimeMilliseconds
          case var lastCleanUpTimeMilliseconds?)
        'Last cleanup time': printMilliseconds(lastCleanUpTimeMilliseconds),
      if (stats.lastScannedFileCount case var lastScannedFileCount?)
        'Files seen in last cleanup': _formatCount(lastScannedFileCount),
      'Failed reads': _formatCount(stats.failedReadCount ?? 0),
      'Failed writes': _formatCount(stats.failedWriteCount ?? 0),
    });
  }

  /// Writes the memory cache facts, splitting its misses by whether the disk
  /// store had the value, if [hasDiskStore].
  void _writeMemoryCache(
    AnalysisServerByteStoreStats stats, {
    required bool hasDiskStore,
  }) {
    var lookupCount = stats.cacheHitCount + stats.cacheMissCount;
    var diskLookupCount = stats.storeHitCount + stats.storeMissCount;
    _writeFacts('Memory Cache', {
      'Limit': printBytes(stats.maxSizeBytes),
      'Resident entries': _formatCount(stats.entryCount),
      'Resident bytes': printBytes(stats.currentSizeBytes),
      'Memory hits': _formatCount(stats.cacheHitCount),
      'Memory misses': _formatCount(stats.cacheMissCount),
      if (lookupCount > 0)
        'Memory hit rate': _formatFraction(stats.cacheHitCount, lookupCount),
      // Only memory misses look up the disk, so disk hits and misses add up
      // to memory misses.
      if (hasDiskStore) ...{
        'Disk hits': _formatCount(stats.storeHitCount),
        'Disk misses': _formatCount(stats.storeMissCount),
        if (diskLookupCount > 0)
          'Disk hit rate': _formatFraction(
            stats.storeHitCount,
            diskLookupCount,
          ),
      },
      'Puts': _formatCount(stats.putCount),
      'Evictions': _formatCount(stats.evictionCount),
      'Evicted entries': _formatCount(stats.evictedEntryCount),
      'Evicted bytes': printBytes(stats.evictedBytes),
    });
  }

  /// Writes the operations on the disk store, grouped into periods.
  void _writeOperations() {
    h3('Disk Operations');

    var timingByteStore = server.timingByteStore;
    var total = timingByteStore?.total;
    if (timingByteStore == null || total == null || total.isEmpty) {
      p(
        'There are currently no operations. '
        'Try refreshing after the server has performed initial analysis.',
      );
      return;
    }

    p(
      'Operations on the disk byte store, for values not in the memory '
      'cache. Get time includes reads that the operating system serves from '
      'its file cache, so it is often far below the latency of the disk. '
      'Put time includes any writing that the store does '
      'synchronously. Periods without operations are not shown, and empty '
      'cells are zero.',
    );
    // Only stores that keep values pending report flushes.
    if (total.flushes.count > 0) {
      p(
        'Flushes write pending values to disk, both when puts reach a limit, '
        'and when analysis becomes idle. Their time is not included into put '
        'time, so the times of operations add up.',
      );
    }

    var periods = timingByteStore.periods.where((period) => !period.isEmpty);

    h4('Since startup');
    _writeTable('Period', [
      for (var period in periods)
        if (period.isMilestone)
          _Row(
            label:
                '${escape(period.reason)} &rarr; '
                '${escape(period.endReason ?? 'now')}',
            duration: period.duration,
            timings: period,
          ),
      if (timingByteStore.recentTotal case var recentTotal
          when !recentTotal.isEmpty)
        _Row(label: 'All recent periods', duration: null, timings: recentTotal),
      _Row(label: '<b>Total</b>', duration: null, timings: total),
    ]);

    h4('Recent periods, newest first');
    if (timingByteStore.droppedPeriodCount case var count when count > 0) {
      p(
        '$count earlier periods are included only in the '
        '"All recent periods" and "Total" rows above.',
      );
    }
    var recent = periods.where((period) => !period.isMilestone).toList();
    if (recent.isEmpty) {
      p('There are no recent periods yet.');
    } else {
      _writeTable('Started', [
        for (var period in recent.reversed)
          _Row(
            // Almost all periods are analysis, so only others are marked.
            label: switch (period.reason) {
              'analysis' => _formatTime(period.startTime),
              var reason =>
                '${_formatTime(period.startTime)} ${escape(reason)}',
            },
            duration: period.duration,
            timings: period,
          ),
      ]);
    }
  }

  void _writeSingleFileStore(
    AnalysisServerByteStoreStats stats,
    List<int> bucketEntryCounts,
  ) {
    var dataBytes = stats.singleFileDataBytes ?? 0;
    var usedDataBytes = dataBytes - (stats.singleFileFreeDataBytes ?? 0);
    var entrySlotCount = stats.singleFileTableSlotCount ?? 0;
    var bucketSize = entrySlotCount ~/ bucketEntryCounts.length;
    var entryCount = bucketEntryCounts.sum;
    // The file outlives this process, and is shared with other processes, so
    // it holds much more than this process wrote to it.
    _writeFactGroups('Single File Store', {
      'File': {
        'Data limit': printBytes(dataBytes),
        'Data used': printBytes(usedDataBytes),
        'Data usage': _formatFraction(usedDataBytes, dataBytes),
        // Below about 11 KiB, the server's table fills before its data space.
        if (entryCount > 0)
          'Average entry size': printBytes(usedDataBytes ~/ entryCount),
        'Entry limit': _formatCount(entrySlotCount),
        'Entries used': _formatCount(entryCount),
        'Entry usage': _formatFraction(entryCount, entrySlotCount),
        // Its overflow evicts entries even when the table is far from full.
        'Fullest bucket usage': _formatFraction(
          bucketEntryCounts.max,
          bucketSize,
        ),
      },
      'This process': {
        'Pending entries': _formatCount(stats.singleFilePendingEntryCount ?? 0),
        'Commits': _formatCount(stats.singleFileCommitCount ?? 0),
        'Committed entries': _formatCount(
          stats.singleFileCommittedEntryCount ?? 0,
        ),
        'Committed bytes': printBytes(stats.singleFileCommittedValueBytes ?? 0),
        'Entries evicted for space': _formatCount(
          stats.singleFileEvictedForSpaceEntryCount ?? 0,
        ),
        'Entries evicted from full table buckets': _formatCount(
          stats.singleFileEvictedFromFullBucketEntryCount ?? 0,
        ),
        // Rebuilds fill the holes that evictions leave in buckets.
        'Bucket rebuilds': _formatCount(
          stats.singleFileBucketRebuildCount ?? 0,
        ),
        // Losses, from a single value up to the whole cache.
        'Oversized values ignored': _formatCount(
          stats.singleFileOversizedValueCount ?? 0,
        ),
        'Oversized bytes ignored': printBytes(
          stats.singleFileOversizedValueBytes ?? 0,
        ),
        'Batches discarded for lack of space': _formatCount(
          stats.singleFileCapacityDiscardedBatchCount ?? 0,
        ),
        'Resets that discarded the cache': _formatCount(
          stats.singleFileResetCount ?? 0,
        ),
      },
    });
  }

  /// Writes a table with a group of lines for each of [rows], one line for
  /// each operation, and [labelHeader] over the column of their labels.
  ///
  /// Each group is a separate `tbody`, shaded and separated as a whole.
  /// The table scrolls within a limited height, with the header kept visible.
  void _writeTable(String labelHeader, List<_Row> rows) {
    buf.writeln('<table class="sticky-header row-groups">');
    buf.writeln(
      '<thead><tr><th>$labelHeader</th><th>Duration (ms)</th>'
      '<th>Operation</th><th>count</th><th>not found</th><th>bytes</th>'
      '<th>ms</th><th>max ms</th></tr></thead>',
    );
    for (var row in rows) {
      var operations = row.operations;
      buf.writeln('<tbody>');
      for (var (index, operation) in operations.indexed) {
        buf.write('<tr>');
        if (index == 0) {
          var rowSpan = operations.length;
          var rowSpanAttribute = rowSpan == 1 ? '' : ' rowspan="$rowSpan"';
          buf.write('<td$rowSpanAttribute>${row.label}</td>');
          var milliseconds = row.duration?.inMilliseconds ?? 0;
          buf.write(
            _cell(
              milliseconds == 0 ? '' : _formatCount(milliseconds),
              rowSpan: rowSpan,
            ),
          );
        }
        buf.writeln(
          '<td class="${operation.cssClass}">${operation.name}</td>'
          '${_numberCell(operation.timings.count)}'
          '${_numberCell(operation.notFoundCount)}'
          '${_bytesCell(operation.timings.bytes)}'
          '${_timeCell(operation.timings.elapsed)}'
          '${_timeCell(operation.timings.max)}</tr>',
        );
      }
      buf.writeln('</tbody>');
    }
    buf.writeln('</table>');
  }

  /// Writes how many hash table buckets hold each range of entry counts, next
  /// to how many uniform hashing would give, to show whether buckets fill
  /// uniformly.
  ///
  /// [scanTime] includes waiting for other processes that hold the lock.
  void _writeTableBuckets(
    AnalysisServerByteStoreStats stats,
    List<int> bucketEntryCounts, {
    required Duration scanTime,
  }) {
    var bucketSize =
        (stats.singleFileTableSlotCount ?? 0) ~/ bucketEntryCounts.length;
    // Ranges of 8 entry counts. Because 8 divides the bucket size, full
    // buckets are a range of their own.
    const rangeSize = 8;
    var rangeCount = bucketSize ~/ rangeSize + 1;
    var actual = List.filled(rangeCount, 0);
    for (var entryCount in bucketEntryCounts) {
      actual[entryCount ~/ rangeSize]++;
    }

    // With uniform hashing, entry counts follow the Poisson distribution.
    // Without evictions, buckets would hold more entries than they can, so
    // full buckets get the rest of the probability.
    var bucketCount = bucketEntryCounts.length;
    var mean = bucketEntryCounts.sum / bucketCount;
    var expected = List.filled(rangeCount, 0.0);
    var probability = exp(-mean);
    var cumulativeProbability = 0.0;
    for (var entryCount = 0; entryCount < bucketSize; entryCount++) {
      expected[entryCount ~/ rangeSize] += probability * bucketCount;
      cumulativeProbability += probability;
      probability *= mean / (entryCount + 1);
    }
    expected[rangeCount - 1] +=
        max(0.0, 1 - cumulativeProbability) * bucketCount;

    // Show ranges between the first and the last that has buckets, or would
    // have with uniform hashing, so that gaps stay visible.
    bool isShown(int range) => actual[range] > 0 || expected[range] >= 0.5;
    var first = 0;
    while (!isShown(first)) {
      first++;
    }
    var last = rangeCount - 1;
    while (!isShown(last)) {
      last--;
    }

    h3('Table Buckets');
    p('Expected for uniform hashing, without evictions.');
    buf.writeln('<table>');
    buf.writeln(
      '<thead><tr><th>Entries per bucket</th><th>Buckets</th>'
      '<th>Expected</th></tr></thead>',
    );
    for (var range = first; range <= last; range++) {
      var low = range * rangeSize;
      var high = min(low + rangeSize - 1, bucketSize);
      var label = low == high ? '$low' : '$low&ndash;$high';
      var expectedCount = expected[range].round();
      var expectedText = expectedCount == 0 && expected[range] > 0
          ? '&lt; 1'
          : _formatCount(expectedCount);
      buf.writeln(
        '<tr><td>$label</td>${_cell(_formatCount(actual[range]))}'
        '${_cell(expectedText)}</tr>',
      );
    }
    buf.writeln('</table>');
    var scanMilliseconds = (scanTime.inMicroseconds / 1000).toStringAsFixed(1);
    p('Scanned in $scanMilliseconds ms.');
  }
}

/// One kind of operation of a period, shown as a line.
class _Operation {
  final String name;

  final ByteStoreOperationTimings timings;

  /// The number of `get` calls that did not find a value, zero for other
  /// operations.
  final int notFoundCount;

  new(this.name, this.timings, {this.notFoundCount = 0});

  /// The CSS class that colors the [name].
  String get cssClass => 'operation-$name';
}

/// A period, or a total, shown as a group of lines, one for each operation.
class _Row {
  /// The label, as HTML.
  final String label;

  /// The wall-clock duration, or `null` for a total.
  final Duration? duration;

  final ByteStoreTimings timings;

  new({required this.label, required this.duration, required this.timings});

  /// The operations that happened, each shown as a line.
  List<_Operation> get operations {
    return [
      if (timings.gets.count > 0)
        _Operation('get', timings.gets, notFoundCount: timings.notFoundCount),
      if (timings.puts.count > 0) _Operation('put', timings.puts),
      if (timings.flushes.count > 0) _Operation('flush', timings.flushes),
    ];
  }
}
