// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domain.analysis;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/protocol.dart';

/**
 * Instances of the class [AnalysisDomainHandler] implement a [RequestHandler]
 * that handles requests in the `analysis` domain.
 */
class AnalysisDomainHandler implements RequestHandler {
  /**
   * The name of the `analysis.getFixes` request.
   */
  static const String GET_FIXES_METHOD = 'analysis.getFixes';

  /**
   * The name of the `analysis.getMinorRefactorings` request.
   */
  static const String GET_MINOR_REFACTORINGS_METHOD = 'analysis.getMinorRefactorings';

  /**
   * The name of the `analysis.setAnalysisRoots` request.
   */
  static const String SET_ANALYSIS_ROOTS_METHOD = 'analysis.setAnalysisRoots';

  /**
   * The name of the `analysis.setPriorityFiles` request.
   */
  static const String SET_PRIORITY_FILES_METHOD = 'analysis.setPriorityFiles';

  /**
   * The name of the `analysis.setSubscriptions` request.
   */
  static const String SET_SUBSCRIPTIONS_METHOD = 'analysis.setSubscriptions';

  /**
   * The name of the `analysis.updateContent` request.
   */
  static const String UPDATE_CONTENT_METHOD = 'analysis.updateContent';

  /**
   * The name of the `analysis.updateOptions` request.
   */
  static const String UPDATE_OPTIONS_METHOD = 'analysis.updateOptions';

  /**
   * The name of the `analysis.updateSdks` request.
   */
  static const String UPDATE_SDKS_METHOD = 'analysis.updateSdks';

  /**
   * The name of the `analysis.errors` notification.
   */
  static const String ERRORS_NOTIFICATION = 'analysis.errors';

  /**
   * The name of the `analysis.highlights` notification.
   */
  static const String HIGHLIGHTS_NOTIFICATION = 'analysis.highlights';

  /**
   * The name of the `analysis.navigation` notification.
   */
  static const String NAVIGATION_NOTIFICATION = 'analysis.navigation';

  /**
   * The name of the `analysis.outline` notification.
   */
  static const String OUTLINE_NOTIFICATION = 'analysis.outline';

  /**
   * The name of the `aadded` parameter.
   */
  static const String ADDED_PARAM = 'added';

  /**
   * The name of the `default` parameter.
   */
  static const String DEFAULT_PARAM = 'default';

  /**
   * The name of the `errors` parameter.
   */
  static const String ERRORS_PARAM = 'errors';

  /**
   * The name of the `excluded` parameter.
   */
  static const String EXCLUDED_PARAM = 'excluded';

  /**
   * The name of the `file` parameter.
   */
  static const String FILE_PARAM = 'file';

  /**
   * The name of the `files` parameter.
   */
  static const String FILES_PARAM = 'files';

  /**
   * The name of the `fixes` parameter.
   */
  static const String FIXES_PARAM = 'fixes';

  /**
   * The name of the `included` parameter.
   */
  static const String INCLUDED_PARAM = 'included';

  /**
   * The name of the `length` parameter.
   */
  static const String LENGTH_PARAM = 'length';

  /**
   * The name of the `offset` parameter.
   */
  static const String OFFSET_PARAM = 'offset';

  /**
   * The name of the `options` parameter.
   */
  static const String OPTIONS_PARAM = 'options';

  /**
   * The name of the `outline` parameter.
   */
  static const String OUTLINE_PARAM = 'outline';

  /**
   * The name of the `refactorings` parameter.
   */
  static const String REFACTORINGS_PARAM = 'refactorings';

  /**
   * The name of the `regions` parameter.
   */
  static const String REGIONS_PARAM = 'regions';

  /**
   * The name of the `removed` parameter.
   */
  static const String REMOVED_PARAM = 'removed';

  /**
   * The name of the `subscriptions` parameter.
   */
  static const String SUBSCRIPTIONS_PARAM = 'subscriptions';

  /**
   * The analysis server that is using this handler to process requests.
   */
  final AnalysisServer server;

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  AnalysisDomainHandler(this.server);

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == GET_FIXES_METHOD) {
        return getFixes(request);
      } else if (requestName == GET_MINOR_REFACTORINGS_METHOD) {
          return getMinorRefactorings(request);
      } else if (requestName == SET_ANALYSIS_ROOTS_METHOD) {
        return setAnalysisRoots(request);
      } else if (requestName == SET_PRIORITY_FILES_METHOD) {
        return setPriorityFiles(request);
      } else if (requestName == SET_SUBSCRIPTIONS_METHOD) {
        return setSubscriptions(request);
      } else if (requestName == UPDATE_CONTENT_METHOD) {
        return updateContent(request);
      } else if (requestName == UPDATE_OPTIONS_METHOD) {
        return updateOptions(request);
      } else if (requestName == UPDATE_SDKS_METHOD) {
        return updateSdks(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  Response getFixes(Request request) {
    // TODO(scheglov) implement
    return null;
  }

  Response getMinorRefactorings(Request request) {
    // TODO(scheglov) implement
    return null;
  }

  Response setAnalysisRoots(Request request) {
    // TODO(scheglov) implement
    return null;
  }

  Response setPriorityFiles(Request request) {
    // TODO(scheglov) implement
    return null;
  }

  Response setSubscriptions(Request request) {
    // TODO(scheglov) implement
    return null;
  }

  Response updateContent(Request request) {
    // TODO(scheglov) implement
    return null;
  }

  Response updateOptions(Request request) {
    // TODO(scheglov) implement
    return null;
  }

  Response updateSdks(Request request) {
    // TODO(scheglov) implement
    return null;
  }
}
