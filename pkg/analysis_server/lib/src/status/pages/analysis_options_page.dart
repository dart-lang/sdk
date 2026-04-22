// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analyzer/src/generated/engine.dart';

/// The page that displays information about analysis options.
class AnalysisOptionsPage extends DiagnosticPageWithNav {
  AnalysisOptionsPage(DiagnosticsSite site)
    : super(
        site,
        'options',
        'Analysis options',
        description: 'Analysis options file contents.',
      );

  @override
  Future<void> generateContent(Map<String, String> params) async {
    if (driverMap.isEmpty) {
      blankslate('No contexts.');
      return;
    }

    var (folder: folder, driver: driver) = currentContext(params);
    var contextPath = folder.path;

    writeContextNavigationTabs(folder);
    buf.writeln(formatOption('Context location', escape(contextPath)));

    var optionsList = getOptionsList(folder, driver);

    p(
      'This analysis context is configured with ${optionsList.length} analysis '
      'options files:',
    );

    for (var options in optionsList) {
      h3(options.file!.path);
      _writeMap(options.toDebugInfo());
    }
  }

  void _writeList(Iterable<Object> info) {
    var filtered = info.where((item) {
      if (item is Map && item.isEmpty) return false;
      if (item is Iterable && item.isEmpty) return false;
      return true;
    });
    if (filtered.isEmpty) return;
    ul(filtered, _writeValue);
  }

  void _writeMap(Map<String, Object> info) {
    if (info.isEmpty) return;
    buf.writeln('<table>');
    for (var MapEntry(:key, :value) in info.entries) {
      if (value is Map && value.isEmpty) continue;
      if (value is Iterable && value.isEmpty) continue;

      buf.writeln('<tr>');
      buf.write('<td>${escape(key)}</td>');
      buf.write('<td>');
      _writeValue(value);
      buf.writeln('</td>');
      buf.writeln('</tr>');
    }
    buf.writeln('</table>');
  }

  void _writeValue(Object item) {
    switch (item) {
      case Map<String, Object>():
        _writeMap(item);
      case Iterable<Object>():
        _writeList(item);
      case DebugLink(:var url, :var text):
        buf.write(url == null ? escape(text) : '<a href="$url">$text</a>');
      case DebugCodeBlock(:var text):
        pre(() => buf.write(escape(text)));
      default:
        buf.write(escape(item.toString()));
    }
  }
}
