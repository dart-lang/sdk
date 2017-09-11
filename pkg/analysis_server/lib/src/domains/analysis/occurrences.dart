// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/analysis/occurrences/occurrences_core.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;

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
