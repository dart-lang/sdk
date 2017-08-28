// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_plugin/utilities/occurrences/occurrences.dart';

/**
 * A concrete implementation of [DartOccurrencesRequest].
 */
class DartOccurrencesRequestImpl implements DartOccurrencesRequest {
  @override
  final ResourceProvider resourceProvider;

  @override
  final ResolveResult result;

  /**
   * Initialize a newly create request with the given data.
   */
  DartOccurrencesRequestImpl(this.resourceProvider, this.result);

  @override
  String get path => result.path;
}

/**
 * A concrete implementation of [OccurrencesCollector].
 */
class OccurrencesCollectorImpl implements OccurrencesCollector {
  /**
   * The locations of the occurrences that have been collected.
   */
  Map<Element, List<int>> occurrenceLocations = <Element, List<int>>{};

  /**
   * Initialize a newly created collector.
   */
  OccurrencesCollectorImpl();

  /**
   * Return the list of occurrences that have been collected.
   */
  List<Occurrences> get occurrences {
    List<Occurrences> occurrences = <Occurrences>[];
    occurrenceLocations.forEach((Element element, List<int> offsets) {
      offsets.sort();
      occurrences.add(new Occurrences(element, offsets, element.name.length));
    });
    return occurrences;
  }

  @override
  void addOccurrence(Element element, int offset) {
    occurrenceLocations.putIfAbsent(element, () => <int>[]).add(offset);
  }
}
