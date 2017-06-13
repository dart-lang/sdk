// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/analysis/occurrences/occurrences_core.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine;
import 'package:analyzer/src/generated/source.dart' show Source;

/**
 * Compute all known occurrences for the given [source].
 */
OccurrencesCollectorImpl computeOccurrences(
    AnalysisServer server, AnalysisContext context, Source source) {
  OccurrencesCollectorImpl collector = new OccurrencesCollectorImpl();
  List<OccurrencesContributor> contributors =
      server.serverPlugin.occurrencesContributors;
  for (OccurrencesContributor contributor in contributors) {
    try {
      contributor.computeOccurrences(collector, context, source);
    } catch (exception, stackTrace) {
      AnalysisEngine.instance.logger.logError(
          'Exception from occurrences contributor: ${contributor.runtimeType}',
          new CaughtException(exception, stackTrace));
    }
  }
  return collector;
}

/**
 * A concrete implementation of [OccurrencesCollector].
 */
class OccurrencesCollectorImpl implements OccurrencesCollector {
  Map<protocol.Element, protocol.Occurrences> elementOccurrences =
      <protocol.Element, protocol.Occurrences>{};

  List<protocol.Occurrences> get allOccurrences {
    return elementOccurrences.values.toList();
  }

  @override
  void addOccurrences(protocol.Occurrences current) {
    protocol.Element element = current.element;
    protocol.Occurrences existing = elementOccurrences[element];
    if (existing != null) {
      List<int> offsets = _merge(existing.offsets, current.offsets);
      current = new protocol.Occurrences(element, offsets, existing.length);
    }
    elementOccurrences[element] = current;
  }

  static List<int> _merge(List<int> a, List<int> b) {
    return <int>[]..addAll(a)..addAll(b);
  }
}
