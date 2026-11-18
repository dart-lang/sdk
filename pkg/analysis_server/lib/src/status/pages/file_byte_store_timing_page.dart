// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analysis_server/src/utilities/timing_byte_store.dart';

String _bytesCell(int bytes) => _cell(bytes == 0 ? '' : printBytes(bytes));

String _cell(String text, {int rowSpan = 1}) {
  var rowSpanAttribute = rowSpan == 1 ? '' : ' rowspan="$rowSpan"';
  return '<td class="right nowrap"$rowSpanAttribute>$text</td>';
}

/// Formats [time] as `HH:mm:ss.SSS`.
String _formatTime(DateTime time) {
  String digits(int value, int width) => '$value'.padLeft(width, '0');
  return '${digits(time.hour, 2)}:${digits(time.minute, 2)}:'
      '${digits(time.second, 2)}.${digits(time.millisecond, 3)}';
}

String _numberCell(int value) => _cell(value == 0 ? '' : '$value');

String _timeCell(Duration duration) {
  var microseconds = duration.inMicroseconds;
  return _cell(
    microseconds == 0 ? '' : (microseconds / 1000).toStringAsFixed(3),
  );
}

class FileByteStoreTimingPage extends DiagnosticPageWithNav
    with PerformanceChartMixin {
  new(DiagnosticsSite site)
    : super(
        site,
        'file-byte-store-timing',
        'Byte store timing',
        description: 'On-disk byte store timing statistics.',
        indentInNav: true,
      );

  @override
  Future<void> generateContent(Map<String, String> params) async {
    h3('Byte Store Timings');

    var timingByteStore = server.timingByteStore;
    var total = timingByteStore?.total;
    if (timingByteStore == null || total == null || total.isEmpty) {
      p(
        'There are currently no timings. '
        'Try refreshing after the server has performed initial analysis.',
      );
      _writeSingleFileStatistics();
      return;
    }

    p(
      'Operations on the on-disk byte store, for values not in the memory '
      'cache. Put time includes any writing that the store does '
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

    _writeSingleFileStatistics();
  }

  /// Writes the statistics of the single-file store, if it is used.
  void _writeSingleFileStatistics() {
    var stats = server.byteStoreStats;
    var path = stats?.singleFileStorePath;
    if (stats == null || path == null) {
      return;
    }

    h4('Single-file store');
    buf.writeln(formatOption('Path', escape(path)));
    var dataBytes = stats.singleFileDataBytes ?? 0;
    var usedDataBytes = dataBytes - (stats.singleFileFreeDataBytes ?? 0);
    buf.writeln(
      formatOption(
        'Used data space',
        '${printBytes(usedDataBytes)} of ${printBytes(dataBytes)} '
            '(${printPercentage(usedDataBytes / dataBytes)})',
      ),
    );
    buf.writeln(
      formatOption(
        'Resets that discarded the cache',
        stats.singleFileResetCount ?? 0,
      ),
    );
    buf.writeln(
      formatOption('Pending entries', stats.singleFilePendingEntryCount ?? 0),
    );
    buf.writeln(formatOption('Commits', stats.singleFileCommitCount ?? 0));
    buf.writeln(
      formatOption(
        'Committed entries',
        '${stats.singleFileCommittedEntryCount ?? 0} '
            '(${printBytes(stats.singleFileCommittedValueBytes ?? 0)})',
      ),
    );
    buf.writeln(
      formatOption(
        'Entries evicted for space',
        stats.singleFileEvictedForSpaceEntryCount ?? 0,
      ),
    );
    buf.writeln(
      formatOption(
        'Entries evicted from full table buckets',
        stats.singleFileEvictedFromFullBucketEntryCount ?? 0,
      ),
    );
    buf.writeln(
      formatOption(
        'Batches discarded for lack of space',
        stats.singleFileCapacityDiscardedBatchCount ?? 0,
      ),
    );
    buf.writeln(
      formatOption(
        'Oversized values ignored',
        '${stats.singleFileOversizedValueCount ?? 0} '
            '(${printBytes(stats.singleFileOversizedValueBytes ?? 0)})',
      ),
    );
    buf.writeln(
      formatOption('Bucket rebuilds', stats.singleFileBucketRebuildCount ?? 0),
    );
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
            _cell(milliseconds == 0 ? '' : '$milliseconds', rowSpan: rowSpan),
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
