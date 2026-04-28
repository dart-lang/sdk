// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/src/config/tool_configuration.dart';
import 'package:dwds/src/debugging/location.dart';
import 'package:dwds/src/debugging/metadata/provider.dart';
import 'package:dwds/src/utilities/dart_uri.dart';

const maxValue = 2147483647;

class SkipLists {
  // Map of script ID to scriptList.
  final _idToList = <String, List<Map<String, dynamic>>>{};
  // Map of url to script ID.
  final _urlToId = <String, String>{};
  final String _root;

  SkipLists(this._root);

  /// Initialize any caches.
  ///
  /// If [modifiedModuleReport] is not null, only invalidates the caches for the
  /// modified modules instead.
  Future<void> initialize(
    String entrypoint, {
    ModifiedModuleReport? modifiedModuleReport,
  }) async {
    if (modifiedModuleReport != null) {
      for (final url in _urlToId.keys) {
        final dartUri = DartUri(url, _root);
        final serverPath = dartUri.serverPath;
        final module = await globalToolConfiguration.loadStrategy
            .moduleForServerPath(entrypoint, serverPath);
        if (modifiedModuleReport.modifiedModules.contains(module)) {
          _idToList.remove(_urlToId[url]!);
          _urlToId.remove(url);
        }
      }
      return;
    }
    _idToList.clear();
    _urlToId.clear();
  }

  /// Returns a skipList as defined by the Chrome DevTools Protocol.
  ///
  /// A `skipList` is an array of `LocationRange`s see:
  /// https://chromedevtools.github.io/devtools-protocol/tot/Debugger/#method-stepInto
  ///
  /// Can return a cached value.
  List<Map<String, dynamic>> compute(
    String scriptId,
    String url,
    Set<Location> locations,
  ) {
    if (_idToList.containsKey(scriptId)) return _idToList[scriptId]!;

    final sortedLocations = locations.toList()
      ..sort((a, b) => a.jsLocation.compareTo(b.jsLocation));

    final ranges = <Map<String, dynamic>>[];
    var startLine = 0;
    var startColumn = 0;
    for (final location in sortedLocations) {
      var endLine = location.jsLocation.line;
      var endColumn = location.jsLocation.column;
      // Stop before the known location.
      endColumn -= 1;
      if (endColumn < 0) {
        endLine -= 1;
        endColumn = maxValue;
      }
      if (endLine > startLine || endColumn > startColumn) {
        if (endLine >= startLine) {
          ranges.add(
            _rangeFor(scriptId, startLine, startColumn, endLine, endColumn),
          );
        }
        startLine = location.jsLocation.line;
        startColumn = location.jsLocation.column + 1;
      }
    }
    ranges.add(_rangeFor(scriptId, startLine, startColumn, maxValue, maxValue));

    if (url.isNotEmpty) {
      _idToList[scriptId] = ranges;
      _urlToId[url] = scriptId;
    }
    return ranges;
  }

  Map<String, dynamic> _rangeFor(
    String scriptId,
    int startLine,
    int startColumn,
    int endLine,
    int endColumn,
  ) => {
    'scriptId': scriptId,
    'start': {'lineNumber': startLine, 'columnNumber': startColumn},
    'end': {'lineNumber': endLine, 'columnNumber': endColumn},
  };
}
