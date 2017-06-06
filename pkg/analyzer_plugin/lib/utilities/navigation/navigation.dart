// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show ElementKind, Location;
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';
import 'package:analyzer_plugin/utilities/generator.dart';

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
   * Contribute navigation regions for the portion of the file specified by the
   * given [request] into the given [collector].
   */
  void computeNavigation(
      NavigationRequest request, NavigationCollector collector);
}

/**
 * A generator that will generate an 'analysis.navigation' notification.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class NavigationGenerator {
  /**
   * The contributors to be used to generate the navigation data.
   */
  final List<NavigationContributor> contributors;

  /**
   * Initialize a newly created navigation generator to use the given
   * [contributors].
   */
  NavigationGenerator(this.contributors);

  /**
   * Create an 'analysis.navigation' notification for the portion of the file
   * specified by the given [request]. If any of the contributors throws an
   * exception, also create a non-fatal 'plugin.error' notification.
   */
  GeneratorResult generateNavigationNotification(NavigationRequest request) {
    List<Notification> notifications = <Notification>[];
    NavigationCollectorImpl collector = new NavigationCollectorImpl();
    for (NavigationContributor contributor in contributors) {
      try {
        contributor.computeNavigation(request, collector);
      } catch (exception, stackTrace) {
        notifications.add(new PluginErrorParams(
                false, exception.toString(), stackTrace.toString())
            .toNotification());
      }
    }
    collector.createRegions();
    notifications.add(new AnalysisNavigationParams(request.result.path,
            collector.regions, collector.targets, collector.files)
        .toNotification());
    return new GeneratorResult(null, notifications);
  }

  /**
   * Create an 'analysis.getNavigation' response for the portion of the file
   * specified by the given [request]. If any of the contributors throws an
   * exception, also create a non-fatal 'plugin.error' notification.
   */
  GeneratorResult generateNavigationResponse(NavigationRequest request) {
    List<Notification> notifications = <Notification>[];
    NavigationCollectorImpl collector = new NavigationCollectorImpl();
    for (NavigationContributor contributor in contributors) {
      try {
        contributor.computeNavigation(request, collector);
      } catch (exception, stackTrace) {
        notifications.add(new PluginErrorParams(
                false, exception.toString(), stackTrace.toString())
            .toNotification());
      }
    }
    collector.createRegions();
    AnalysisGetNavigationResult result = new AnalysisGetNavigationResult(
        collector.files, collector.targets, collector.regions);
    return new GeneratorResult(result, notifications);
  }
}

/**
 * The information about a requested set of navigation information.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class NavigationRequest {
  /**
   * Return the length of the region within the source for which navigation
   * regions are being requested.
   */
  int get length;

  /**
   * Return the offset of the region within the source for which navigation
   * regions are being requested.
   */
  int get offset;

  /**
   * Return the resource provider associated with this request.
   */
  ResourceProvider get resourceProvider;

  /**
   * The analysis result for the file in which the navigation regions are being
   * requested.
   */
  ResolveResult get result;
}
