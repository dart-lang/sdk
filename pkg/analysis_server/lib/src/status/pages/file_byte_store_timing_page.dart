// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analysis_server/src/utilities/timing_byte_store.dart';

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

    var periods = timingByteStore.periods.where((period) => !period.isEmpty);

    h4('Since startup');
    _writeTable('Period', [
      for (var period in periods)
        if (period.isMilestone)
          (
            label:
                '${escape(period.reason)} &rarr; '
                '${escape(period.endReason ?? 'now')}',
            duration: period.duration,
            timings: period,
          ),
      if (timingByteStore.recentTotal case var recentTotal
          when !recentTotal.isEmpty)
        (label: 'All recent periods', duration: null, timings: recentTotal),
      (label: '<b>Total</b>', duration: null, timings: total),
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
          (
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

  /// Writes a table with a row for each of [rows], with [labelHeader] over
  /// the column of their labels.
  ///
  /// The table scrolls within a limited height, with the header kept visible.
  void _writeTable(
    String labelHeader,
    List<({String label, Duration? duration, ByteStoreTimings timings})> rows,
  ) {
    buf.writeln('<table class="sticky-header">');
    buf.writeln('<thead>');
    buf.writeln(
      '<tr><th rowspan="2">$labelHeader</th>'
      '<th rowspan="2">Duration (ms)</th>'
      '<th colspan="5">Lookups</th><th colspan="4">Puts</th></tr>',
    );
    buf.writeln(
      '<tr><th>count</th><th>not found</th><th>bytes</th>'
      '<th>ms</th><th>max ms</th>'
      '<th>count</th><th>bytes</th><th>ms</th><th>max ms</th></tr>',
    );
    buf.writeln('</thead>');
    buf.writeln('<tbody>');
    for (var (:label, :duration, :timings) in rows) {
      var lookups = timings.lookups;
      var puts = timings.puts;
      buf.writeln(
        '<tr><td>$label</td>'
        '${_numberCell(duration?.inMilliseconds ?? 0)}'
        '${_numberCell(lookups.count)}'
        '${_numberCell(timings.notFoundCount)}'
        '${_bytesCell(lookups.bytes)}'
        '${_timeCell(lookups.elapsed)}'
        '${_timeCell(lookups.max)}'
        '${_numberCell(puts.count)}'
        '${_bytesCell(puts.bytes)}'
        '${_timeCell(puts.elapsed)}'
        '${_timeCell(puts.max)}'
        '</tr>',
      );
    }
    buf.writeln('</tbody>');
    buf.writeln('</table>');
  }

  static String _bytesCell(int bytes) =>
      _cell(bytes == 0 ? '' : printBytes(bytes));

  static String _cell(String text) => '<td class="right nowrap">$text</td>';

  /// Formats [time] as `HH:mm:ss.SSS`.
  static String _formatTime(DateTime time) {
    String digits(int value, int width) => '$value'.padLeft(width, '0');
    return '${digits(time.hour, 2)}:${digits(time.minute, 2)}:'
        '${digits(time.second, 2)}.${digits(time.millisecond, 3)}';
  }

  static String _numberCell(int value) => _cell(value == 0 ? '' : '$value');

  static String _timeCell(Duration duration) {
    var microseconds = duration.inMicroseconds;
    return _cell(
      microseconds == 0 ? '' : (microseconds / 1000).toStringAsFixed(3),
    );
  }
}
