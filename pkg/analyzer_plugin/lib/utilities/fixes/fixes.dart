// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/generator.dart';

/**
 * The information about a requested set of fixes when computing fixes in a
 * `.dart` file.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartFixesRequest implements FixesRequest {
  /**
   * The analysis result for the file in which the fixes are being requested.
   */
  ResolveResult get result;
}

/**
 * An object that [FixContributor]s use to record fixes.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FixCollector {
  /**
   * Record a new [change] (fix) associated with the given [error].
   */
  void addFix(AnalysisError error, PrioritizedSourceChange change);
}

/**
 * An object used to produce fixes.
 *
 * Clients may implement this class when implementing plugins.
 */
abstract class FixContributor {
  /**
   * Contribute fixes for the location in the file specified by the given
   * [request] into the given [collector].
   */
  void computeFixes(covariant FixesRequest request, FixCollector collector);
}

/**
 * The information about a requested set of fixes.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FixesRequest {
  /**
   * The analysis error to be fixed, or `null` if the error has not been
   * determined.
   */
  List<AnalysisError> get errorsToFix;

  /**
   * Return the offset within the source for which fixes are being requested.
   */
  int get offset;

  /**
   * Return the resource provider associated with this request.
   */
  ResourceProvider get resourceProvider;
}

/**
 * A generator that will generate an 'edit.getFixes' response.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class FixGenerator {
  /**
   * The contributors to be used to generate the fixes.
   */
  final List<FixContributor> contributors;

  /**
   * Initialize a newly created fix generator to use the given [contributors].
   */
  FixGenerator(this.contributors);

  /**
   * Create an 'edit.getFixes' response for the location in the file specified
   * by the given [request]. If any of the contributors throws an exception,
   * also create a non-fatal 'plugin.error' notification.
   */
  GeneratorResult generateFixesResponse(FixesRequest request) {
    List<Notification> notifications = <Notification>[];
    FixCollectorImpl collector = new FixCollectorImpl();
    for (FixContributor contributor in contributors) {
      try {
        contributor.computeFixes(request, collector);
      } catch (exception, stackTrace) {
        notifications.add(new PluginErrorParams(
                false, exception.toString(), stackTrace.toString())
            .toNotification());
      }
    }
    EditGetFixesResult result = new EditGetFixesResult(collector.fixes);
    return new GeneratorResult(result, notifications);
  }
}
