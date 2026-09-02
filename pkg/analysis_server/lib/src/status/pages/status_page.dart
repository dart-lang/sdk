// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/protocol/protocol_constants.dart'
    show PROTOCOL_VERSION;
import 'package:analysis_server/src/scheduler/message_scheduler.dart';
import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analyzer/src/util/platform_info.dart';

class StatusPage extends DiagnosticPageWithNav {
  new(DiagnosticsSite site)
    : super(
        site,
        'status',
        'Status',
        description: 'General status and diagnostics for the analysis server.',
      );

  @override
  Future<void> generateContent(Map<String, String> params) async {
    buf.writeln('<div class="columns">');

    buf.writeln('<div class="column one-half">');
    h3('Status');
    buf.writeln(formatOption('Server type', server.runtimeType));
    // buf.writeln(writeOption('Instrumentation enabled',
    //     AnalysisEngine.instance.instrumentationService.isActive));
    buf.writeln(
      formatOption(
        '(Scheduler) allow overlapping message handlers:',
        MessageScheduler.allowOverlappingHandlers,
      ),
    );
    buf.writeln(formatOption('Server process ID', pid));
    buf.writeln('</div>');

    buf.writeln('<div class="column one-half">');
    h3('Versions');
    buf.writeln(formatOption('Analysis server version', PROTOCOL_VERSION));
    buf.writeln(formatOption('Dart SDK', platform.version));
    buf.writeln('</div>');

    buf.writeln('</div>');

    // SDK configuration overrides.
    var sdkConfig = server.options.configurationOverrides;
    if (sdkConfig?.hasAnyOverrides == true) {
      buf.writeln('<div class="columns">');

      buf.writeln('<div class="column one-half">');
      h3('Configuration Overrides');
      buf.writeln(
        '<pre><code>${sdkConfig?.displayString ?? '<unknown overrides>'}</code></pre><br>',
      );
      buf.writeln('</div>');

      buf.writeln('</div>');
    }

    var byteStoreStats = server.byteStoreStats;
    if (byteStoreStats != null) {
      buf.writeln('<div class="columns">');

      buf.writeln('<div class="column one-half">');
      h3('Byte Store');
      buf.writeln(
        formatOption(
          'Memory cache limit',
          printBytes(byteStoreStats.maxSizeBytes),
        ),
      );
      buf.writeln(
        formatOption(
          'Memory cache resident',
          '${printBytes(byteStoreStats.currentSizeBytes)} (${byteStoreStats.entryCount} entries)',
        ),
      );
      buf.writeln(
        formatOption(
          'Memory cache hits / misses',
          '${byteStoreStats.cacheHitCount} / ${byteStoreStats.cacheMissCount}',
        ),
      );
      buf.writeln(
        formatOption(
          'Backing store hits / misses',
          '${byteStoreStats.storeHitCount} / ${byteStoreStats.storeMissCount}',
        ),
      );
      buf.writeln(formatOption('Memory cache puts', byteStoreStats.putCount));
      buf.writeln(
        formatOption(
          'Memory cache evictions',
          '${byteStoreStats.evictionCount} (${byteStoreStats.evictedEntryCount} entries, ${printBytes(byteStoreStats.evictedBytes)})',
        ),
      );
      buf.writeln('</div>');

      buf.writeln('<div class="column one-half">');
      h3('File Byte Store');
      if (byteStoreStats.usesFileByteStore) {
        buf.writeln(
          formatOption(
            'File cache path',
            byteStoreStats.fileStorePath ?? '<unknown>',
          ),
        );
        buf.writeln(
          formatOption(
            'File cache limit',
            printBytes(byteStoreStats.fileCacheSizeBytes ?? 0),
          ),
        );
        if (byteStoreStats.fileStoreSizeBytes case var fileStoreSizeBytes?) {
          buf.writeln(
            formatOption('Last observed size', printBytes(fileStoreSizeBytes)),
          );
        }
        buf.writeln(
          formatOption(
            'Reads / misses',
            '${byteStoreStats.readCount ?? 0} / ${byteStoreStats.readMissCount ?? 0}',
          ),
        );
        buf.writeln(
          formatOption(
            'Writes',
            '${byteStoreStats.writeCount ?? 0} (${printBytes(byteStoreStats.writeBytes ?? 0)})',
          ),
        );
        buf.writeln(
          formatOption('Pending writes', byteStoreStats.pendingWriteCount ?? 0),
        );
        buf.writeln(
          formatOption('Cleanup runs', byteStoreStats.cleanUpCount ?? 0),
        );
        buf.writeln(
          formatOption(
            'Cleanup deletions',
            '${byteStoreStats.deletedFileCount ?? 0} files, ${printBytes(byteStoreStats.deletedBytes ?? 0)}',
          ),
        );
        if (byteStoreStats.lastCleanUpTimeMilliseconds
            case var lastCleanUpTimeMilliseconds?) {
          buf.writeln(
            formatOption(
              'Last cleanup time',
              printMilliseconds(lastCleanUpTimeMilliseconds),
            ),
          );
        }
        if (byteStoreStats.lastScannedFileCount
            case var lastScannedFileCount?) {
          buf.writeln(
            formatOption('Files seen in last cleanup', lastScannedFileCount),
          );
        }
        buf.writeln(
          formatOption(
            'Failed reads / writes',
            '${byteStoreStats.failedReadCount ?? 0} / ${byteStoreStats.failedWriteCount ?? 0}',
          ),
        );
      } else {
        buf.writeln('File byte store is disabled or unavailable.<br>');
      }
      buf.writeln('</div>');

      buf.writeln('</div>');
    }

    var lines = site.lastPrintedLines;
    if (lines.isNotEmpty) {
      h3('Debug output');
      p(lines.join('\n'), style: 'white-space: pre');
    }
  }
}
