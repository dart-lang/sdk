// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show ElementKind, Location;
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/navigation.dart';

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
   * [offset] and [length]. The [driver] can be used to access analysis results.
   */
  void computeNavigation(NavigationCollector collector,
      AnalysisDriverGeneric driver, String filePath, int offset, int length);
}

/**
 * A generator that will generate an 'analysis.navigation' notification.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class NavigationGenerator {
  /**
   * The driver to be passed in to the contributors.
   */
  final AnalysisDriverGeneric driver;

  /**
   * The contributors to be used to generate the navigation data.
   */
  final List<NavigationContributor> contributors;

  /**
   * Initialize a newly created navigation generator.
   */
  NavigationGenerator(this.driver, this.contributors);

  /**
   * Create an 'analysis.navigation' notification for the file with the given
   * [filePath]. If any of the contributors throws an exception, also create a
   * non-fatal 'plugin.error' notification.
   */
  List<Notification> generateNavigationNotification(String filePath) {
    // TODO(brianwilkerson) Consider not passing a driver in (to either the
    // NavigationGenerator constructor or computeNavigation) and replace the
    // filePath with an AnalysisResult that then gets passed in to
    // computeNavigation. That would allow contributors to use previously
    // computed results rather than re-compute them.
    List<Notification> notifications = <Notification>[];
    NavigationCollectorImpl collector = new NavigationCollectorImpl();
    for (NavigationContributor contributor in contributors) {
      try {
        contributor.computeNavigation(collector, driver, filePath, null, null);
      } catch (exception, stackTrace) {
        notifications.add(new PluginErrorParams(
                false, exception.toString(), stackTrace.toString())
            .toNotification());
      }
    }
    collector.createRegions();
    notifications.add(new AnalysisNavigationParams(
            filePath, collector.regions, collector.targets, collector.files)
        .toNotification());
    return notifications;
  }
}
