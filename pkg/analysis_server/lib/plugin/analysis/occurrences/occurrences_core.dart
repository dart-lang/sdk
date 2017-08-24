// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart' show Occurrences;

/**
 * An object used to record occurrences into.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class OccurrencesCollector {
  /**
   * Record a new element occurrences.
   */
  void addOccurrences(Occurrences occurrences);
}
