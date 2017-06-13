// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/task/dart.dart';

/// Collects reachable sources.
class ReachableSourceCollector {
  final Map<String, List<String>> _sourceMap =
      new HashMap<String, List<String>>();

  final Source source;
  final AnalysisContext context;
  ReachableSourceCollector(this.source, this.context) {
    if (source == null) {
      throw new ArgumentError.notNull('source');
    }
    if (context == null) {
      throw new ArgumentError.notNull('context');
    }
  }

  /// Collect reachable sources.
  Map<String, List<String>> collectSources() {
    _addDependencies(source);
    return _sourceMap;
  }

  void _addDependencies(Source source) {
    String sourceUri = source.uri.toString();

    // Careful not to revisit.
    if (_sourceMap[source.uri.toString()] != null) {
      return;
    }

    List<Source> sources = <Source>[];
    sources.addAll(context.computeResult(source, IMPORTED_LIBRARIES));
    sources.addAll(context.computeResult(source, EXPORTED_LIBRARIES));

    _sourceMap[sourceUri] =
        sources.map((source) => source.uri.toString()).toList();

    sources.forEach((s) => _addDependencies(s));
  }
}
