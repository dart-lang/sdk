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
import 'package:analysis_server/src/plugin/request_converter.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/utilities/progress.dart';
import 'package:analyzer/src/generated/engine.dart' as engine;

/// Instances of the class [AnalysisDomainHandler] implement a [RequestHandler]
/// that handles requests in the `analysis` domain.
class AnalysisDomainHandler extends AbstractRequestHandler {
  /// Initialize a newly created handler to handle requests for the given
  /// [server].
  AnalysisDomainHandler(AnalysisServer server) : super(server);

  /// Implement the `analysis.getLibraryDependencies` request.
  Response getLibraryDependencies(Request request) {
    return Response.unsupportedFeature(request.id,
        'Please contact the Dart analyzer team if you need this request.');
//    server.onAnalysisComplete.then((_) {
//      LibraryDependencyCollector collector =
//          new LibraryDependencyCollector(server.analysisContexts);
//      Set<String> libraries = collector.collectLibraryDependencies();
//      Map<String, Map<String, List<String>>> packageMap =
//          collector.calculatePackageMap(server.folderMap);
//      server.sendResponse(new AnalysisGetLibraryDependenciesResult(
//              libraries.toList(growable: false), packageMap)
//          .toResponse(request.id));
//    }).catchError((error, st) {
//      server.sendResponse(new Response.serverError(request, error, st));
//    });
//    // delay response
//    return Response.DELAYED_RESPONSE;
  }

  /// Implement the `analysis.getReachableSources` request.
  Response getReachableSources(Request request) {
    return Response.unsupportedFeature(request.id,
        'Please contact the Dart analyzer team if you need this request.');
//    AnalysisGetReachableSourcesParams params =
//        new AnalysisGetReachableSourcesParams.fromRequest(request);
//    ContextSourcePair pair = server.getContextSourcePair(params.file);
//    if (pair.context == null || pair.source == null) {
//      return new Response.getReachableSourcesInvalidFile(request);
//    }
//    Map<String, List<String>> sources =
//        new ReachableSourceCollector(pair.source, pair.context)
//            .collectSources();
//    return new AnalysisGetReachableSourcesResult(sources)
//        .toResponse(request.id);
  }

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
        return getLibraryDependencies(request);
      } else if (requestName == ANALYSIS_REQUEST_GET_NAVIGATION) {
        AnalysisGetNavigationHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == ANALYSIS_REQUEST_GET_REACHABLE_SOURCES) {
        return getReachableSources(request);
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
        return setGeneralSubscriptions(request);
      } else if (requestName == ANALYSIS_REQUEST_SET_PRIORITY_FILES) {
        return setPriorityFiles(request);
      } else if (requestName == ANALYSIS_REQUEST_SET_SUBSCRIPTIONS) {
        return setSubscriptions(request);
      } else if (requestName == ANALYSIS_REQUEST_UPDATE_CONTENT) {
        return updateContent(request);
      } else if (requestName == ANALYSIS_REQUEST_UPDATE_OPTIONS) {
        return updateOptions(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  /// Implement the 'analysis.setGeneralSubscriptions' request.
  Response setGeneralSubscriptions(Request request) {
    var params = AnalysisSetGeneralSubscriptionsParams.fromRequest(request);
    server.setGeneralAnalysisSubscriptions(params.subscriptions);
    return AnalysisSetGeneralSubscriptionsResult().toResponse(request.id);
  }

  /// Implement the 'analysis.setPriorityFiles' request.
  Response setPriorityFiles(Request request) {
    var params = AnalysisSetPriorityFilesParams.fromRequest(request);

    for (var file in params.files) {
      if (!server.isAbsoluteAndNormalized(file)) {
        return Response.invalidFilePathFormat(request, file);
      }
    }

    server.setPriorityFiles(request.id, params.files);
    //
    // Forward the request to the plugins.
    //
    var converter = RequestConverter();
    server.pluginManager.setAnalysisSetPriorityFilesParams(
        converter.convertAnalysisSetPriorityFilesParams(params));
    //
    // Send the response.
    //
    return AnalysisSetPriorityFilesResult().toResponse(request.id);
  }

  /// Implement the 'analysis.setSubscriptions' request.
  Response setSubscriptions(Request request) {
    var params = AnalysisSetSubscriptionsParams.fromRequest(request);

    for (var fileList in params.subscriptions.values) {
      for (var file in fileList) {
        if (!server.isAbsoluteAndNormalized(file)) {
          return Response.invalidFilePathFormat(request, file);
        }
      }
    }

    // parse subscriptions
    var subMap =
        mapMap<AnalysisService, List<String>, AnalysisService, Set<String>>(
            params.subscriptions,
            valueCallback: (List<String> subscriptions) =>
                subscriptions.toSet());
    server.setAnalysisSubscriptions(subMap);
    //
    // Forward the request to the plugins.
    //
    var converter = RequestConverter();
    server.pluginManager.setAnalysisSetSubscriptionsParams(
        converter.convertAnalysisSetSubscriptionsParams(params));
    //
    // Send the response.
    //
    return AnalysisSetSubscriptionsResult().toResponse(request.id);
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
