// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.analysis.navigation.navigation_core;

import 'package:analysis_server/src/protocol.dart'
    show ElementKind, Location, NavigationRegion, NavigationTarget;
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/source.dart' show Source;

/**
 * An object used to produce navigation regions.
 *
 * Clients are expected to subtype this class when implementing plugins.
 */
abstract class NavigationContributor {
  /**
   * Contribute navigation regions for a part of the given [source] into the
   * given [holder]. The part is specified by the [offset] and [length].
   * The [context] can be used to get analysis results.
   */
  void computeNavigation(NavigationHolder holder, AnalysisContext context,
      Source source, int offset, int length);
}

/**
 * An object that [NavigationContributor]s use to record navigation regions
 * into.
 *
 * Clients are not expected to subtype this class.
 */
abstract class NavigationHolder {
  /**
   * Record a new navigation region with the given [offset] and [length] that
   * should navigation to the given [targetLocation].
   */
  void addRegion(
      int offset, int length, ElementKind targetKind, Location targetLocation);
}
