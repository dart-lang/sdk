// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analysis_server_plugin/src/correction/performance.dart';
import 'package:collection/collection.dart';

class TimingPage extends DiagnosticPageWithNav with PerformanceChartMixin {
  new(DiagnosticsSite site)
    : super(site, 'timing', 'Timing', description: 'Timing statistics.');

  @override
  ContentType contentType(Map<String, String> params) {
    if (params['asJson'] != null) {
      return ContentType.json;
    }
    return super.contentType(params);
  }

  @override
  Future<void> generateContent(Map<String, String> params) async {
    var kind = params['kind'];

    List<RequestPerformance> items;
    List<RequestPerformance>? itemsSlow;
    if (kind == 'completion') {
      items = server.recentPerformance.completion.items.toList();
    } else if (kind == 'getAssists') {
      items = server.recentPerformance.getAssists.items.toList();
    } else if (kind == 'getFixes') {
      items = server.recentPerformance.getFixes.items.toList();
    } else if (kind == 'getRefactorings') {
      items = server.recentPerformance.getRefactorings.items.toList();
    } else {
      items = server.recentPerformance.requests.items.toList();
      itemsSlow = server.recentPerformance.slowRequests.items.toList();
    }

    var id = int.tryParse(params['id'] ?? '');
    if (id == null) {
      _generateList(items, itemsSlow);
    } else {
      _generateDetails(id, items, itemsSlow);
    }
  }

  @override
  Future<void> generatePage(Map<String, String> params) async {
    if (params['asJson'] != null) {
      var data = [];
      // No added header etc.
      for (var item in server.recentPerformance.requests.items.toList()) {
        data.add({
          'id': item.id,
          'operation': item.operation,
          'elapsedMs': item.performance.elapsed.inMilliseconds,
          'latency': item.requestLatency,
          if (item.additionalTimings case var additionalTimings?)
            for (var additionalTiming
                in additionalTimings.timingsInMilliseconds.entries)
              additionalTiming.key: additionalTiming.value,
          'performance': item.performance.toJson(),
        });
      }
      buf.write(json.encode(data));
      return;
    }
    return await super.generatePage(params);
  }

  void _emitTable(List<RequestPerformance> items) {
    buf.writeln('<table>');
    buf.writeln(
      '<tr><th>Total Time</th><th>Request</th><th>Excluding Additional</th><th>Additional</th><th>Latency</th></tr>',
    );
    for (var item in items) {
      buf.writeln(
        '<tr>'
        '<td class="pre right"><a href="timing?id=${item.id}">'
        '${printMilliseconds(item.performance.elapsed.inMilliseconds)}'
        '</a></td>'
        '<td>${escape(item.operation)}</td>'
        '<td class="pre right">${escape(formatExcludingAdditional(item))}</td>'
        '<td class="pre right">${escape(formatAdditional(item))}</td>'
        '<td class="pre right">${escape(printMilliseconds(item.requestLatency))}</td>'
        '</tr>',
      );
    }
    buf.writeln('</table>');
  }

  void _generateDetails(
    int id,
    List<RequestPerformance> items,
    List<RequestPerformance>? itemsSlow,
  ) {
    var item = items.firstWhereOrNull((info) => info.id == id);
    if (item == null && itemsSlow != null) {
      item = itemsSlow.firstWhereOrNull((info) => info.id == id);
    }

    if (item == null) {
      blankslate(
        'Unable to find data for $id. '
        'Perhaps newer requests have pushed it out of the buffer?',
      );
      return;
    }

    h3("Request '${item.operation}'");
    var requestLatency = item.requestLatency;
    if (requestLatency != null) {
      buf.writeln(
        '<p>Request latency: ${printMilliseconds(requestLatency)}.</p>',
      );
    }
    var startTime = item.startTime;
    if (startTime != null) {
      buf.writeln('<p>Request start time: ${startTime.toIso8601String()}.</p>');
    }
    var totalTime = item.performance.elapsed.inMilliseconds;
    buf.writeln('<p>Total time: ${printMilliseconds(totalTime)}.</p>');
    var additionalTimings =
        item.additionalTimings?.timingsInMilliseconds ?? const {};
    if (additionalTimings.isNotEmpty) {
      buf.writeln('<p>Time includes:</p>');
      buf.writeln('<ul>');
      for (var MapEntry(key: kind, value: timeInMs)
          in additionalTimings.entries) {
        buf.writeln('$kind: ${printMilliseconds(timeInMs)}');
      }
      buf.writeln('</ul>');
    }

    var buffer = StringBuffer();
    item.performance.write(buffer: buffer);
    pre(() {
      buf.write('<code>');
      buf.write(escape('$buffer'));
      buf.writeln('</code>');
    });

    if (item is ProducerRequestPerformance) {
      var itemTimings = item.producerTimings;
      if (itemTimings.isNotEmpty) {
        h3('Producer Timings');
        buf.writeln('<table>');
        buf.writeln('<tr><th>Time (ms)</th><th>Producer</th></tr>');
        for (var timing in itemTimings) {
          buf.writeln(
            '<tr>'
            '<td class="right">${timing.elapsedTime}</td>'
            '<td>${escape(timing.className)}</td>'
            '</tr>',
          );
        }
        buf.writeln('</table>');
      }

      var snippet = item.snippet;
      if (snippet.isNotEmpty) {
        h3('Snippet');
        pre(() {
          buf.writeln(escape(snippet));
        });
      }
    }
  }

  void _generateList(
    List<RequestPerformance> items,
    List<RequestPerformance>? itemsSlow,
  ) {
    if (items.isEmpty) {
      assert(itemsSlow == null || itemsSlow.isEmpty);
      blankslate('No requests recorded.');
      return;
    }

    drawChart(items);

    // emit the data as a table
    if (itemsSlow != null) {
      h3('Recent requests');
    }
    _emitTable(items);

    if (itemsSlow != null) {
      h3('Slow requests');
      _emitTable(itemsSlow);
    }
  }
}
