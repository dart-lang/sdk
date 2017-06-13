// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer_plugin/protocol/protocol_common.dart' show Occurrences;

/**
 * An object that [OccurrencesContributor]s use to record occurrences into.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class OccurrencesCollector {
  /**
   * Record a new element occurrences.
   */
  void addOccurrences(Occurrences occurrences);
}

/**
 * An object used to produce occurrences.
 *
 * Clients may implement this class when implementing plugins.
 */
abstract class OccurrencesContributor {
  /**
   * Contribute occurrences into the given [collector].
   * The [context] can be used to get analysis results.
   */
  void computeOccurrences(
      OccurrencesCollector collector, AnalysisContext context, Source source);
}
