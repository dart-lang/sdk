// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_abstract.dart';
import 'package:analysis_server/src/handler/legacy/analysis_get_errors.dart';
import 'package:analysis_server/src/handler/legacy/analysis_get_hover.dart';
import 'package:analysis_server/src/handler/legacy/analysis_get_imported_elements.dart';
import 'package:analysis_server/src/handler/legacy/analysis_get_navigation.dart';
import 'package:analysis_server/src/handler/legacy/analysis_get_signature.dart';
import 'package:analysis_server/src/handler/legacy/analysis_reanalyze.dart';
import 'package:analysis_server/src/handler/legacy/analysis_set_analysis_roots.dart';
import 'package:analysis_server/src/handler/legacy/analysis_set_general_subscriptions.dart';
import 'package:analysis_server/src/handler/legacy/analysis_set_priority_files.dart';
import 'package:analysis_server/src/handler/legacy/analysis_set_subscriptions.dart';
import 'package:analysis_server/src/handler/legacy/unsupported_request.dart';
import 'package:analysis_server/src/plugin/request_converter.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/utilities/cancellation.dart';

/// Instances of the class [AnalysisDomainHandler] implement a [RequestHandler]
/// that handles requests in the `analysis` domain.
class AnalysisDomainHandler extends AbstractRequestHandler {
  /// Initialize a newly created handler to handle requests for the given
  /// [server].
  AnalysisDomainHandler(AnalysisServer server) : super(server);

  @override
  Response? handleRequest(
      Request request, CancellationToken cancellationToken) {
    try {
      var requestName = request.method;
      if (requestName == ANALYSIS_REQUEST_GET_ERRORS) {
        AnalysisGetErrorsHandler(server, request, cancellationToken).handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == ANALYSIS_REQUEST_GET_HOVER) {
        AnalysisGetHoverHandler(server, request, cancellationToken).handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == ANALYSIS_REQUEST_GET_IMPORTED_ELEMENTS) {
        AnalysisGetImportedElementsHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == ANALYSIS_REQUEST_GET_LIBRARY_DEPENDENCIES) {
        UnsupportedRequestHandler(server, request, cancellationToken).handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == ANALYSIS_REQUEST_GET_NAVIGATION) {
        AnalysisGetNavigationHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == ANALYSIS_REQUEST_GET_REACHABLE_SOURCES) {
        UnsupportedRequestHandler(server, request, cancellationToken).handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == ANALYSIS_REQUEST_GET_SIGNATURE) {
        AnalysisGetSignatureHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == ANALYSIS_REQUEST_REANALYZE) {
        AnalysisReanalyzeHandler(server, request, cancellationToken).handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS) {
        AnalysisSetAnalysisRootsHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == ANALYSIS_REQUEST_SET_GENERAL_SUBSCRIPTIONS) {
        AnalysisSetGeneralSubscriptionsHandler(
                server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == ANALYSIS_REQUEST_SET_PRIORITY_FILES) {
        AnalysisSetPriorityFilesHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == ANALYSIS_REQUEST_SET_SUBSCRIPTIONS) {
        AnalysisSetSubscriptionsHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == ANALYSIS_REQUEST_UPDATE_CONTENT) {
        // TODO(brianwilkerson) Converting this to a handler currently causes a
        //  test to timeout.
        return updateContent(request);
      } else if (requestName == ANALYSIS_REQUEST_UPDATE_OPTIONS) {
        // TODO(brianwilkerson) Converting this to a handler currently causes a
        //  test to timeout.
        return updateOptions(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  /// Implement the 'analysis.updateContent' request.
  Response updateContent(Request request) {
    var params = AnalysisUpdateContentParams.fromRequest(request);

    for (var file in params.files.keys) {
      if (!server.isAbsoluteAndNormalized(file)) {
        return Response.invalidFilePathFormat(request, file);
      }
    }

    server.updateContent(request.id, params.files);
    //
    // Forward the request to the plugins.
    //
    var converter = RequestConverter();
    server.pluginManager.setAnalysisUpdateContentParams(
        converter.convertAnalysisUpdateContentParams(params));
    //
    // Send the response.
    //
    return AnalysisUpdateContentResult().toResponse(request.id);
  }

  /// Implement the 'analysis.updateOptions' request.
  Response updateOptions(Request request) {
    // options
    var params = AnalysisUpdateOptionsParams.fromRequest(request);
    var newOptions = params.options;
    var updaters = <OptionUpdater>[];
    var generateHints = newOptions.generateHints;
    if (generateHints != null) {
      updaters.add((engine.AnalysisOptionsImpl options) {
        options.hint = generateHints;
      });
    }
    var generateLints = newOptions.generateLints;
    if (generateLints != null) {
      updaters.add((engine.AnalysisOptionsImpl options) {
        options.lint = generateLints;
      });
    }
    server.updateOptions(updaters);
    return AnalysisUpdateOptionsResult().toResponse(request.id);
  }
}
