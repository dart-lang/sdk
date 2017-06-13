// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/generator.dart';

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
  void computeFixes(FixesRequest request, FixCollector collector);
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
  AnalysisError get error;

  /**
   * Return the offset within the source for which fixes are being requested.
   */
  int get offset;

  /**
   * Return the resource provider associated with this request.
   */
  ResourceProvider get resourceProvider;

  /**
   * The analysis result for the file in which the fixes are being requested.
   */
  ResolveResult get result;
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
    Iterable<AnalysisError> errors = _getErrors(request);
    FixesRequestImpl requestImpl = request;
    for (FixContributor contributor in contributors) {
      try {
        for (AnalysisError error in errors) {
          requestImpl.error = error;
          contributor.computeFixes(request, collector);
        }
      } catch (exception, stackTrace) {
        notifications.add(new PluginErrorParams(
                false, exception.toString(), stackTrace.toString())
            .toNotification());
      } finally {
        requestImpl.error = null;
      }
    }
    EditGetFixesResult result = new EditGetFixesResult(collector.fixes);
    return new GeneratorResult(result, notifications);
  }

  Iterable<AnalysisError> _getErrors(FixesRequest request) {
    int offset = request.offset;
    LineInfo lineInfo = request.result.lineInfo;
    int offsetLine = lineInfo.getLocation(offset).lineNumber;
    return request.result.errors.where((AnalysisError error) {
      int errorLine = lineInfo.getLocation(error.offset).lineNumber;
      return errorLine == offsetLine;
    });
  }
}
