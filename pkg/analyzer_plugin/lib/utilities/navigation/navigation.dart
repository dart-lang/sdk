// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show ElementKind, Location;
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';
import 'package:analyzer_plugin/utilities/generator.dart';

/// The information about a requested set of navigation information when
/// computing navigation information in a `.dart` file.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DartNavigationRequest implements NavigationRequest {
  /// The analysis result for the file in which the navigation regions are being
  /// requested.
  ResolvedUnitResult get result;
}

/// An object that [NavigationContributor]s use to record navigation regions.
///
/// Clients may not extend, implement or mix-in this class.
abstract class NavigationCollector {
  /// Whether the collector is collecting target code locations. Computers can
  /// skip computing these if this is false.
  bool get collectCodeLocations;

  /// Record a new navigation region corresponding to the given [range] that
  /// should navigate to the given [targetNameLocation].
  void addRange(
      SourceRange range, ElementKind targetKind, Location targetLocation,
      {Location targetCodeLocation});

  /// Record a new navigation region with the given [offset] and [length] that
  /// should navigate to the given [targetNameLocation].
  void addRegion(int offset, int length, ElementKind targetKind,
      Location targetNameLocation,
      {Location targetCodeLocation});
}

/// An object used to produce navigation regions.
///
/// Clients may implement this class when implementing plugins.
abstract class NavigationContributor {
  /// Contribute navigation regions for the portion of the file specified by the
  /// given [request] into the given [collector].
  void computeNavigation(
      NavigationRequest request, NavigationCollector collector);
}

/// A generator that will generate an 'analysis.navigation' notification.
///
/// Clients may not extend, implement or mix-in this class.
class NavigationGenerator {
  /// The contributors to be used to generate the navigation data.
  final List<NavigationContributor> contributors;

  /// Initialize a newly created navigation generator to use the given
  /// [contributors].
  NavigationGenerator(this.contributors);

  /// Create an 'analysis.navigation' notification for the portion of the file
  /// specified by the given [request]. If any of the contributors throws an
  /// exception, also create a non-fatal 'plugin.error' notification.
  GeneratorResult generateNavigationNotification(NavigationRequest request) {
    var notifications = <Notification>[];
    var collector = NavigationCollectorImpl();
    for (var contributor in contributors) {
      try {
        contributor.computeNavigation(request, collector);
      } catch (exception, stackTrace) {
        notifications.add(PluginErrorParams(
                false, exception.toString(), stackTrace.toString())
            .toNotification());
      }
    }
    collector.createRegions();
    notifications.add(AnalysisNavigationParams(
            request.path, collector.regions, collector.targets, collector.files)
        .toNotification());
    return GeneratorResult(null, notifications);
  }

  /// Create an 'analysis.getNavigation' response for the portion of the file
  /// specified by the given [request]. If any of the contributors throws an
  /// exception, also create a non-fatal 'plugin.error' notification.
  GeneratorResult<AnalysisGetNavigationResult> generateNavigationResponse(
      NavigationRequest request) {
    var notifications = <Notification>[];
    var collector = NavigationCollectorImpl();
    for (var contributor in contributors) {
      try {
        contributor.computeNavigation(request, collector);
      } catch (exception, stackTrace) {
        notifications.add(PluginErrorParams(
                false, exception.toString(), stackTrace.toString())
            .toNotification());
      }
    }
    collector.createRegions();
    var result = AnalysisGetNavigationResult(
        collector.files, collector.targets, collector.regions);
    return GeneratorResult(result, notifications);
  }
}

/// The information about a requested set of navigation information.
///
/// Clients may not extend, implement or mix-in this class.
abstract class NavigationRequest {
  /// Return the length of the region within the source for which navigation
  /// regions are being requested.
  int get length;

  /// Return the offset of the region within the source for which navigation
  /// regions are being requested.
  int get offset;

  /// Return the path of the file in which navigation regions are being
  /// requested.
  String get path;

  /// Return the resource provider associated with this request.
  ResourceProvider get resourceProvider;
}
