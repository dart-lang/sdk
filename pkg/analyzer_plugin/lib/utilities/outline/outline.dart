// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/outline/outline.dart';
import 'package:analyzer_plugin/utilities/generator.dart';

/**
 * The information about a requested set of outline information when
 * computing outline information in a `.dart` file.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartOutlineRequest implements OutlineRequest {
  /**
   * The analysis result for the file for which the outline is being requested.
   */
  ResolveResult get result;
}

/**
 * An object that [OutlineContributor]s use to record outline information.
 *
 * Invocations of the [startElement] and [endElement] methods must be paired.
 * Any elements started (and ended) between a [startElement] and [endElement]
 * pair are assumed to be children of the outer pair's element and as such will
 * automatically be added as children of the outer pair's outline node.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class OutlineCollector {
  /**
   * Stop recording information about the current element.
   */
  void endElement();

  /**
   * Start recording information about the given [element].
   */
  void startElement(Element element, int offset, int length);
}

/**
 * An object used to produce nodes in an outline.
 *
 * Clients may implement this class when implementing plugins.
 */
abstract class OutlineContributor {
  /**
   * Contribute outline nodes into the given [collector].
   */
  void computeOutline(OutlineRequest request, OutlineCollector collector);
}

/**
 * A generator that will generate an 'analysis.outline' notification.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class OutlineGenerator {
  /**
   * The contributors to be used to generate the outline nodes.
   */
  final List<OutlineContributor> contributors;

  /**
   * Initialize a newly created outline generator to use the given
   * [contributors].
   */
  OutlineGenerator(this.contributors);

  /**
   * Create an 'analysis.outline' notification. If any of the contributors
   * throws an exception, also create a non-fatal 'plugin.error' notification.
   */
  GeneratorResult generateOutlineNotification(OutlineRequest request) {
    List<Notification> notifications = <Notification>[];
    OutlineCollectorImpl collector = new OutlineCollectorImpl();
    for (OutlineContributor contributor in contributors) {
      try {
        contributor.computeOutline(request, collector);
      } catch (exception, stackTrace) {
        notifications.add(new PluginErrorParams(
                false, exception.toString(), stackTrace.toString())
            .toNotification());
      }
    }
    notifications.add(
        new AnalysisOutlineParams(request.path, collector.outlines)
            .toNotification());
    return new GeneratorResult(null, notifications);
  }
}

/**
 * The information about a requested set of outline information.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class OutlineRequest {
  /**
   * Return the path of the file for which an outline is being requested.
   */
  String get path;

  /**
   * Return the resource provider associated with this request.
   */
  ResourceProvider get resourceProvider;
}
