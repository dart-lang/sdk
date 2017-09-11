// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/highlights/highlights.dart';
import 'package:analyzer_plugin/utilities/generator.dart';

/**
 * The information about a requested set of highlight regions when computing
 * highlight regions in a `.dart` file.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartHighlightsRequest implements HighlightsRequest {
  /**
   * The analysis result for the file for which the highlight regions are being
   * requested.
   */
  ResolveResult get result;
}

/**
 * An object that [HighlightsContributor]s use to record highlight regions.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class HighlightsCollector {
  /**
   * Add a highlight region corresponding to the given source [range] whose type
   * is the given [type].
   */
  void addRange(SourceRange range, HighlightRegionType type);

  /**
   * Add a highlight region starting at the given [offset] and having the given
   * [length] whose type is the given [type].
   */
  void addRegion(int offset, int length, HighlightRegionType type);
}

/**
 * An object used to produce highlight regions.
 *
 * Clients may implement this class when implementing plugins.
 */
abstract class HighlightsContributor {
  /**
   * Contribute highlight regions into the given [collector].
   */
  void computeHighlights(
      HighlightsRequest request, HighlightsCollector collector);
}

/**
 * A generator that will generate an 'analysis.highlights' notification.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class HighlightsGenerator {
  /**
   * The contributors to be used to generate the highlight regions.
   */
  final List<HighlightsContributor> contributors;

  /**
   * Initialize a newly created highlights generator to use the given
   * [contributors].
   */
  HighlightsGenerator(this.contributors);

  /**
   * Create an 'analysis.highlights' notification. If any of the contributors
   * throws an exception, also create a non-fatal 'plugin.error' notification.
   */
  GeneratorResult generateHighlightsNotification(HighlightsRequest request) {
    List<Notification> notifications = <Notification>[];
    HighlightsCollectorImpl collector = new HighlightsCollectorImpl();
    for (HighlightsContributor contributor in contributors) {
      try {
        contributor.computeHighlights(request, collector);
      } catch (exception, stackTrace) {
        notifications.add(new PluginErrorParams(
                false, exception.toString(), stackTrace.toString())
            .toNotification());
      }
    }
    notifications.add(
        new AnalysisHighlightsParams(request.path, collector.regions)
            .toNotification());
    return new GeneratorResult(null, notifications);
  }
}

/**
 * The information about a requested set of highlight regions.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class HighlightsRequest {
  /**
   * Return the path of the file for which highlight regions are being
   * requested.
   */
  String get path;

  /**
   * Return the resource provider associated with this request.
   */
  ResourceProvider get resourceProvider;
}
