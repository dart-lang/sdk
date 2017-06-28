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

/**
 * A description of a class of fixes. Instances are intended to hold the
 * information that is common across a number of fixes and to be shared by those
 * fixes. For example, if an unnecessary cast is found then one of the suggested
 * fixes will be to remove the cast. If there are multiple unnecessary casts in
 * a single file, then there will be multiple fixes, one per occurrence, but
 * they will all share the same kind.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class FixKind {
  /**
   * The name of this kind of fix, used for debugging.
   */
  final String name;

  /**
   * The priority of this kind of fix for the kind of error being addressed.
   */
  final int priority;

  /**
   * A human-readable description of the changes that will be applied by this
   * kind of fix. The message can contain parameters, where each parameter is
   * represented by a zero-based index inside curly braces. For example, the
   * message `"Create a component named '{0}' in '{1}'"` contains two parameters.
   */
  final String message;

  /**
   * Initialize a newly created kind of fix to have the given [name],
   * [priority] and [message].
   */
  const FixKind(this.name, this.priority, this.message);

  @override
  String toString() => name;
}
