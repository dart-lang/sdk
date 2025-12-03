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
  TimingPage(DiagnosticsSite site)
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
    buf.writeln('<tr><th>Time</th><th>Request</th></tr>');
    for (var item in items) {
      buf.writeln(
        '<tr>'
        '<td class="pre right"><a href="timing?id=${item.id}">'
        '${formatLatencyTiming(item.performance.elapsed.inMilliseconds, item.requestLatency)}'
        '</a></td>'
        '<td>${escape(item.operation)}</td>'
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
      buf.writeln('Request latency: $requestLatency ms.');
      buf.writeln('<p>');
    }
    var startTime = item.startTime;
    if (startTime != null) {
      buf.writeln('Request start time: ${startTime.toIso8601String()}.');
      buf.writeln('<p>');
    }
    var buffer = StringBuffer();
    item.performance.write(buffer: buffer);
    pre(() {
      buf.write('<code>');
      buf.write(escape('$buffer'));
      buf.writeln('</code>');
    });
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
