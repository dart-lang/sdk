// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show ElementKind, Location;

/**
 * An object used to record navigation regions.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class NavigationCollector {
  /**
   * Record a new navigation region with the given [offset] and [length] that
   * should navigate to the given [targetLocation].
   */
  void addRegion(
      int offset, int length, ElementKind targetKind, Location targetLocation);
}
