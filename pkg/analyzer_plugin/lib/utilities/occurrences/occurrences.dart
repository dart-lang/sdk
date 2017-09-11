// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/occurrences/occurrences.dart';
import 'package:analyzer_plugin/utilities/generator.dart';

/**
 * The information about a requested set of occurrences information when
 * computing occurrences information in a `.dart` file.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartOccurrencesRequest implements OccurrencesRequest {
  /**
   * The analysis result for the file for which the occurrences information is
   * being requested.
   */
  ResolveResult get result;
}

/**
 * An object that [OccurrencesContributor]s use to record occurrences.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class OccurrencesCollector {
  /**
   * Add an occurrence of the given [element] at the given [offset].
   */
  void addOccurrence(Element element, int offset);
}

/**
 * An object used to produce occurrences information.
 *
 * Clients may implement this class when implementing plugins.
 */
abstract class OccurrencesContributor {
  /**
   * Contribute occurrences information into the given [collector].
   */
  void computeOccurrences(
      OccurrencesRequest request, OccurrencesCollector collector);
}

/**
 * A generator that will generate an 'analysis.occurrences' notification.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class OccurrencesGenerator {
  /**
   * The contributors to be used to generate the occurrences information.
   */
  final List<OccurrencesContributor> contributors;

  /**
   * Initialize a newly created occurrences generator to use the given
   * [contributors].
   */
  OccurrencesGenerator(this.contributors);

  /**
   * Create an 'analysis.occurrences' notification. If any of the contributors
   * throws an exception, also create a non-fatal 'plugin.error' notification.
   */
  GeneratorResult generateOccurrencesNotification(OccurrencesRequest request) {
    List<Notification> notifications = <Notification>[];
    OccurrencesCollectorImpl collector = new OccurrencesCollectorImpl();
    for (OccurrencesContributor contributor in contributors) {
      try {
        contributor.computeOccurrences(request, collector);
      } catch (exception, stackTrace) {
        notifications.add(new PluginErrorParams(
                false, exception.toString(), stackTrace.toString())
            .toNotification());
      }
    }
    notifications.add(
        new AnalysisOccurrencesParams(request.path, collector.occurrences)
            .toNotification());
    return new GeneratorResult(null, notifications);
  }
}

/**
 * The information about a requested set of occurrences information.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class OccurrencesRequest {
  /**
   * Return the path of the file for which occurrences information is being
   * requested.
   */
  String get path;

  /**
   * Return the resource provider associated with this request.
   */
  ResourceProvider get resourceProvider;
}
