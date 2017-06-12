// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:core';

import 'package:analysis_server/plugin/analysis/analysis_domain.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/context_manager.dart';
import 'package:analysis_server/src/domain_abstract.dart';
import 'package:analysis_server/src/domains/analysis/navigation.dart';
import 'package:analysis_server/src/domains/analysis/navigation_dart.dart';
import 'package:analysis_server/src/operation/operation_analysis.dart'
    show NavigationOperation, OccurrencesOperation;
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/plugin/request_converter.dart';
import 'package:analysis_server/src/plugin/result_merger.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/dependencies/library_dependencies.dart';
import 'package:analysis_server/src/services/dependencies/reachable_source_collector.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' as engine;
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/task/model.dart' show ResultDescriptor;
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;

/**
 * Instances of the class [AnalysisDomainHandler] implement a [RequestHandler]
 * that handles requests in the `analysis` domain.
 */
class AnalysisDomainHandler extends AbstractRequestHandler {
  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  AnalysisDomainHandler(AnalysisServer server) : super(server) {
    _callAnalysisDomainReceivers();
  }

  /**
   * Implement the `analysis.getErrors` request.
   */
  Future<Null> getErrors(Request request) async {
    String file = new AnalysisGetErrorsParams.fromRequest(request).file;

    void send(engine.AnalysisOptions analysisOptions, LineInfo lineInfo,
        List<engine.AnalysisError> errors) {
      if (lineInfo == null) {
        server.sendResponse(new Response.getErrorsInvalidFile(request));
      } else {
        List<AnalysisError> protocolErrors =
            doAnalysisError_listFromEngine(analysisOptions, lineInfo, errors);
        server.sendResponse(
            new AnalysisGetErrorsResult(protocolErrors).toResponse(request.id));
      }
    }

    if (server.options.enableNewAnalysisDriver) {
      var result = await server.getAnalysisResult(file);

      if (server.onResultErrorSupplementor != null) {
        if (result != null) {
          await server.onResultErrorSupplementor(file, result.errors);
        } else {
          server.onNoAnalysisResult(file, send);
          return;
        }
      }

      send(result?.driver?.analysisOptions, result?.lineInfo, result?.errors);
      return;
    }

    Future<AnalysisDoneReason> completionFuture =
        server.onFileAnalysisComplete(file);
    if (completionFuture == null) {
      server.sendResponse(new Response.getErrorsInvalidFile(request));
    }
    completionFuture.then((AnalysisDoneReason reason) async {
      switch (reason) {
        case AnalysisDoneReason.COMPLETE:
          engine.AnalysisErrorInfo errorInfo = server.getErrors(file);
          if (errorInfo == null) {
            server.sendResponse(new Response.getErrorsInvalidFile(request));
          } else {
            engine.AnalysisContext context = server.getAnalysisContext(file);
            send(context.analysisOptions, errorInfo.lineInfo, errorInfo.errors);
          }
          break;
        case AnalysisDoneReason.CONTEXT_REMOVED:
          // The active contexts have changed, so try again.
          await getErrors(request);
          break;
      }
    });
  }

  /**
   * Implement the `analysis.getHover` request.
   */
  Future<Null> getHover(Request request) async {
    var params = new AnalysisGetHoverParams.fromRequest(request);

    // Prepare the resolved units.
    CompilationUnit unit;
    if (server.options.enableNewAnalysisDriver) {
      AnalysisResult result = await server.getAnalysisResult(params.file);
      unit = result?.unit;
    } else {
      unit = await server.getResolvedCompilationUnit(params.file);
    }

    // Prepare the hovers.
    List<HoverInformation> hovers = <HoverInformation>[];
    if (unit != null) {
      HoverInformation hoverInformation =
          new DartUnitHoverComputer(unit, params.offset).compute();
      if (hoverInformation != null) {
        hovers.add(hoverInformation);
      }
    }

    // Send the response.
    server.sendResponse(
        new AnalysisGetHoverResult(hovers).toResponse(request.id));
  }

  /// Implement the `analysis.getLibraryDependencies` request.
  Response getLibraryDependencies(Request request) {
    server.onAnalysisComplete.then((_) {
      LibraryDependencyCollector collector =
          new LibraryDependencyCollector(server.analysisContexts);
      Set<String> libraries = collector.collectLibraryDependencies();
      Map<String, Map<String, List<String>>> packageMap =
          collector.calculatePackageMap(server.folderMap);
      server.sendResponse(new AnalysisGetLibraryDependenciesResult(
              libraries.toList(growable: false), packageMap)
          .toResponse(request.id));
    }).catchError((error, st) {
      server.sendResponse(new Response.serverError(request, error, st));
    });
    // delay response
    return Response.DELAYED_RESPONSE;
  }

  /**
   * Implement the `analysis.getNavigation` request.
   */
  Future<Null> getNavigation(Request request) async {
    var params = new AnalysisGetNavigationParams.fromRequest(request);
    String file = params.file;
    int offset = params.offset;
    int length = params.length;

    if (server.options.enableNewAnalysisDriver) {
      AnalysisDriver driver = server.getAnalysisDriver(file);
      if (driver == null) {
        server.sendResponse(new Response.getNavigationInvalidFile(request));
      } else {
        //
        // Allow plugins to start computing navigation data.
        //
        plugin.AnalysisGetNavigationParams requestParams =
            new plugin.AnalysisGetNavigationParams(file, offset, length);
        Map<PluginInfo, Future<plugin.Response>> pluginFutures = server
            .pluginManager
            .broadcastRequest(requestParams, contextRoot: driver.contextRoot);
        //
        // Compute navigation data generated by server.
        //
        List<AnalysisNavigationParams> allResults =
            <AnalysisNavigationParams>[];
        AnalysisResult result = await server.getAnalysisResult(file);
        CompilationUnit unit = result?.unit;
        if (unit != null && result.exists) {
          NavigationCollectorImpl collector = new NavigationCollectorImpl();
          computeDartNavigation(collector, unit, offset, length);
          collector.createRegions();
          allResults.add(new AnalysisNavigationParams(
              file, collector.regions, collector.targets, collector.files));
        }
        //
        // Add the navigation data produced by plugins to the server-generated
        // navigation data.
        //
        if (pluginFutures != null) {
          List<plugin.Response> responses = await waitForResponses(
              pluginFutures,
              requestParameters: requestParams);
          for (plugin.Response response in responses) {
            plugin.AnalysisGetNavigationResult result =
                new plugin.AnalysisGetNavigationResult.fromResponse(response);
            allResults.add(new AnalysisNavigationParams(
                file, result.regions, result.targets, result.files));
          }
        }
        //
        // Return the result.
        //
        ResultMerger merger = new ResultMerger();
        AnalysisNavigationParams mergedResults =
            merger.mergeNavigation(allResults);
        if (mergedResults == null) {
          server.sendResponse(new AnalysisGetNavigationResult(
                  <String>[], <NavigationTarget>[], <NavigationRegion>[])
              .toResponse(request.id));
        } else {
          server.sendResponse(new AnalysisGetNavigationResult(
                  mergedResults.files,
                  mergedResults.targets,
                  mergedResults.regions)
              .toResponse(request.id));
        }
      }
      return;
    }

    Future<AnalysisDoneReason> analysisFuture =
        server.onFileAnalysisComplete(file);
    if (analysisFuture == null) {
      server.sendResponse(new Response.getNavigationInvalidFile(request));
      return;
    }
    analysisFuture.then((AnalysisDoneReason reason) async {
      switch (reason) {
        case AnalysisDoneReason.COMPLETE:
          CompilationUnit unit = await server.getResolvedCompilationUnit(file);
          if (unit == null) {
            server.sendResponse(new Response.getNavigationInvalidFile(request));
          } else {
            CompilationUnitElement unitElement = unit.element;
            NavigationCollectorImpl collector = computeNavigation(
                server,
                unitElement.context,
                unitElement.source,
                params.offset,
                params.length);
            server.sendResponse(new AnalysisGetNavigationResult(
                    collector.files, collector.targets, collector.regions)
                .toResponse(request.id));
          }
          break;
        case AnalysisDoneReason.CONTEXT_REMOVED:
          // The active contexts have changed, so try again.
          await getNavigation(request);
          break;
      }
    });
  }

  /**
   * Implement the `analysis.getReachableSources` request.
   */
  Response getReachableSources(Request request) {
    AnalysisGetReachableSourcesParams params =
        new AnalysisGetReachableSourcesParams.fromRequest(request);
    ContextSourcePair pair = server.getContextSourcePair(params.file);
    if (pair.context == null || pair.source == null) {
      return new Response.getReachableSourcesInvalidFile(request);
    }
    Map<String, List<String>> sources =
        new ReachableSourceCollector(pair.source, pair.context)
            .collectSources();
    return new AnalysisGetReachableSourcesResult(sources)
        .toResponse(request.id);
  }

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == ANALYSIS_GET_ERRORS) {
        getErrors(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == ANALYSIS_GET_HOVER) {
        getHover(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == ANALYSIS_GET_LIBRARY_DEPENDENCIES) {
        return getLibraryDependencies(request);
      } else if (requestName == ANALYSIS_GET_NAVIGATION) {
        getNavigation(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == ANALYSIS_GET_REACHABLE_SOURCES) {
        return getReachableSources(request);
      } else if (requestName == ANALYSIS_REANALYZE) {
        return reanalyze(request);
      } else if (requestName == ANALYSIS_SET_ANALYSIS_ROOTS) {
        return setAnalysisRoots(request);
      } else if (requestName == ANALYSIS_SET_GENERAL_SUBSCRIPTIONS) {
        return setGeneralSubscriptions(request);
      } else if (requestName == ANALYSIS_SET_PRIORITY_FILES) {
        return setPriorityFiles(request);
      } else if (requestName == ANALYSIS_SET_SUBSCRIPTIONS) {
        return setSubscriptions(request);
      } else if (requestName == ANALYSIS_UPDATE_CONTENT) {
        return updateContent(request);
      } else if (requestName == ANALYSIS_UPDATE_OPTIONS) {
        return updateOptions(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  /**
   * Implement the 'analysis.reanalyze' request.
   */
  Response reanalyze(Request request) {
    AnalysisReanalyzeParams params =
        new AnalysisReanalyzeParams.fromRequest(request);
    List<String> roots = params.roots;
    if (roots == null || roots.isNotEmpty) {
      List<String> includedPaths = server.contextManager.includedPaths;
      List<Resource> rootResources = null;
      if (roots != null) {
        rootResources = <Resource>[];
        for (String rootPath in roots) {
          if (!includedPaths.contains(rootPath)) {
            return new Response.invalidAnalysisRoot(request, rootPath);
          }
          rootResources.add(server.resourceProvider.getResource(rootPath));
        }
      }
      server.reanalyze(rootResources);
    }
    //
    // Forward the request to the plugins.
    //
    RequestConverter converter = new RequestConverter();
    server.pluginManager
        .broadcastRequest(converter.convertAnalysisReanalyzeParams(params));
    //
    // Send the response.
    //
    return new AnalysisReanalyzeResult().toResponse(request.id);
  }

  /**
   * Implement the 'analysis.setAnalysisRoots' request.
   */
  Response setAnalysisRoots(Request request) {
    var params = new AnalysisSetAnalysisRootsParams.fromRequest(request);
    List<String> includedPathList = params.included;
    List<String> excludedPathList = params.excluded;
    // validate
    for (String path in includedPathList) {
      if (!server.isValidFilePath(path)) {
        return new Response.invalidFilePathFormat(request, path);
      }
    }
    for (String path in excludedPathList) {
      if (!server.isValidFilePath(path)) {
        return new Response.invalidFilePathFormat(request, path);
      }
    }
    // continue in server
    server.setAnalysisRoots(request.id, includedPathList, excludedPathList,
        params.packageRoots ?? <String, String>{});
    return new AnalysisSetAnalysisRootsResult().toResponse(request.id);
  }

  /**
   * Implement the 'analysis.setGeneralSubscriptions' request.
   */
  Response setGeneralSubscriptions(Request request) {
    AnalysisSetGeneralSubscriptionsParams params =
        new AnalysisSetGeneralSubscriptionsParams.fromRequest(request);
    server.setGeneralAnalysisSubscriptions(params.subscriptions);
    return new AnalysisSetGeneralSubscriptionsResult().toResponse(request.id);
  }

  /**
   * Implement the 'analysis.setPriorityFiles' request.
   */
  Response setPriorityFiles(Request request) {
    var params = new AnalysisSetPriorityFilesParams.fromRequest(request);
    server.setPriorityFiles(request.id, params.files);
    //
    // Forward the request to the plugins.
    //
    RequestConverter converter = new RequestConverter();
    server.pluginManager.setAnalysisSetPriorityFilesParams(
        converter.convertAnalysisSetPriorityFilesParams(params));
    //
    // Send the response.
    //
    return new AnalysisSetPriorityFilesResult().toResponse(request.id);
  }

  /**
   * Implement the 'analysis.setSubscriptions' request.
   */
  Response setSubscriptions(Request request) {
    var params = new AnalysisSetSubscriptionsParams.fromRequest(request);
    // parse subscriptions
    Map<AnalysisService, Set<String>> subMap = mapMap(params.subscriptions,
        valueCallback: (List<String> subscriptions) => subscriptions.toSet());
    server.setAnalysisSubscriptions(subMap);
    //
    // Forward the request to the plugins.
    //
    RequestConverter converter = new RequestConverter();
    server.pluginManager.setAnalysisSetSubscriptionsParams(
        converter.convertAnalysisSetSubscriptionsParams(params));
    //
    // Send the response.
    //
    return new AnalysisSetSubscriptionsResult().toResponse(request.id);
  }

  /**
   * Implement the 'analysis.updateContent' request.
   */
  Response updateContent(Request request) {
    var params = new AnalysisUpdateContentParams.fromRequest(request);
    server.updateContent(request.id, params.files);
    //
    // Forward the request to the plugins.
    //
    RequestConverter converter = new RequestConverter();
    server.pluginManager.setAnalysisUpdateContentParams(
        converter.convertAnalysisUpdateContentParams(params));
    //
    // Send the response.
    //
    return new AnalysisUpdateContentResult().toResponse(request.id);
  }

  /**
   * Implement the 'analysis.updateOptions' request.
   */
  Response updateOptions(Request request) {
    // options
    var params = new AnalysisUpdateOptionsParams.fromRequest(request);
    AnalysisOptions newOptions = params.options;
    List<OptionUpdater> updaters = new List<OptionUpdater>();
    if (newOptions.generateDart2jsHints != null) {
      updaters.add((engine.AnalysisOptionsImpl options) {
        options.dart2jsHint = newOptions.generateDart2jsHints;
      });
    }
    if (newOptions.generateHints != null) {
      updaters.add((engine.AnalysisOptionsImpl options) {
        options.hint = newOptions.generateHints;
      });
    }
    if (newOptions.generateLints != null) {
      updaters.add((engine.AnalysisOptionsImpl options) {
        options.lint = newOptions.generateLints;
      });
    }
    if (newOptions.enableSuperMixins != null) {
      updaters.add((engine.AnalysisOptionsImpl options) {
        options.enableSuperMixins = newOptions.enableSuperMixins;
      });
    }
    server.updateOptions(updaters);
    return new AnalysisUpdateOptionsResult().toResponse(request.id);
  }

  /**
   * Call all the registered [SetAnalysisDomain] functions.
   */
  void _callAnalysisDomainReceivers() {
    AnalysisDomain analysisDomain = new AnalysisDomainImpl(server);
    for (SetAnalysisDomain function
        in server.serverPlugin.setAnalysisDomainFunctions) {
      try {
        function(analysisDomain);
      } catch (exception, stackTrace) {
        engine.AnalysisEngine.instance.logger.logError(
            'Exception from analysis domain receiver: ${function.runtimeType}',
            new CaughtException(exception, stackTrace));
      }
    }
  }
}

/**
 * An implementation of [AnalysisDomain] for [AnalysisServer].
 */
class AnalysisDomainImpl implements AnalysisDomain {
  final AnalysisServer server;

  final Map<ResultDescriptor, StreamController<engine.ResultChangedEvent>>
      controllers =
      <ResultDescriptor, StreamController<engine.ResultChangedEvent>>{};

  AnalysisDomainImpl(this.server) {
    server.onContextsChanged.listen((ContextsChangedEvent event) {
      event.added.forEach(_subscribeForContext);
    });
  }

  @override
  Stream<engine.ResultChangedEvent> onResultChanged(
      ResultDescriptor descriptor) {
    Stream<engine.ResultChangedEvent> stream =
        controllers.putIfAbsent(descriptor, () {
      return new StreamController<engine.ResultChangedEvent>.broadcast();
    }).stream;
    server.analysisContexts.forEach(_subscribeForContext);
    return stream;
  }

  @override
  void scheduleNotification(
      engine.AnalysisContext context, Source source, AnalysisService service) {
    String file = source.fullName;
    if (server.hasAnalysisSubscription(service, file)) {
      if (service == AnalysisService.NAVIGATION) {
        server.scheduleOperation(new NavigationOperation(context, source));
      }
      if (service == AnalysisService.OCCURRENCES) {
        server.scheduleOperation(new OccurrencesOperation(context, source));
      }
    }
  }

  void _subscribeForContext(engine.AnalysisContext context) {
    for (ResultDescriptor descriptor in controllers.keys) {
      context.onResultChanged(descriptor).listen((result) {
        StreamController<engine.ResultChangedEvent> controller =
            controllers[result.descriptor];
        if (controller != null) {
          controller.add(result);
        }
      });
    }
  }
}
