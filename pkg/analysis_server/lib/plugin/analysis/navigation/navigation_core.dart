// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.plugin.analysis.navigation.navigation_core;

import 'package:analysis_server/plugin/protocol/protocol.dart'
    show ElementKind, Location;
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/source.dart' show Source;

/**
 * An object that [NavigationContributor]s use to record navigation regions.
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

/**
 * An object used to produce navigation regions.
 *
 * Clients may implement this class when implementing plugins.
 */
abstract class NavigationContributor {
  /**
   * Contribute navigation regions for a subset of the content of the given
   * [source] into the given [collector]. The subset is specified by the
   * [offset] and [length]. The [context] can be used to access analysis results.
   */
  void computeNavigation(NavigationCollector collector, AnalysisContext context,
      Source source, int offset, int length);
}
