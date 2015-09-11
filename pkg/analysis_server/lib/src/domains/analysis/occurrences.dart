// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domains.analysis.occurrences;

import 'package:analysis_server/analysis/occurrences_core.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine;
import 'package:analyzer/src/generated/java_engine.dart' show CaughtException;
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
  final List<protocol.Occurrences> allOccurrences = <protocol.Occurrences>[];

  @override
  void addOccurrences(protocol.Occurrences occurrences) {
    allOccurrences.add(occurrences);
  }
}
