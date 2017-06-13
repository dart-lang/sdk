// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/generator.dart';

/**
 * An object that [AssistContributor]s use to record assists.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class AssistCollector {
  /**
   * Record a new [assist].
   */
  void addAssist(PrioritizedSourceChange assist);
}

/**
 * An object used to produce assists.
 *
 * Clients may implement this class when implementing plugins.
 */
abstract class AssistContributor {
  /**
   * Contribute assists for the location in the file specified by the given
   * [request] into the given [collector].
   */
  void computeAssists(AssistRequest request, AssistCollector collector);
}

/**
 * A generator that will generate an 'edit.getAssists' response.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AssistGenerator {
  /**
   * The contributors to be used to generate the assists.
   */
  final List<AssistContributor> contributors;

  /**
   * Initialize a newly created assists generator to use the given
   * [contributors].
   */
  AssistGenerator(this.contributors);

  /**
   * Create an 'edit.getAssists' response for the location in the file specified
   * by the given [request]. If any of the contributors throws an exception,
   * also create a non-fatal 'plugin.error' notification.
   */
  GeneratorResult generateAssistsResponse(AssistRequest request) {
    List<Notification> notifications = <Notification>[];
    AssistCollectorImpl collector = new AssistCollectorImpl();
    for (AssistContributor contributor in contributors) {
      try {
        contributor.computeAssists(request, collector);
      } catch (exception, stackTrace) {
        notifications.add(new PluginErrorParams(
                false, exception.toString(), stackTrace.toString())
            .toNotification());
      }
    }
    EditGetAssistsResult result = new EditGetAssistsResult(collector.assists);
    return new GeneratorResult(result, notifications);
  }
}

/**
 * The information about a requested set of assists.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class AssistRequest {
  /**
   * Return the length of the selection within the source for which assists are
   * being requested.
   */
  int get length;

  /**
   * Return the offset of the selection within the source for which assists are
   * being requested.
   */
  int get offset;

  /**
   * Return the resource provider associated with this request.
   */
  ResourceProvider get resourceProvider;

  /**
   * The analysis result for the file in which the assists are being requested.
   */
  ResolveResult get result;
}
