// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.domain_diagnostic;

import 'dart:async';
import 'dart:collection';
import 'dart:core';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' as nd;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/task/model.dart';

int _workItemCount(AnalysisContextImpl context) {
  AnalysisDriver driver = context.driver;
  List<WorkItem> items = driver.currentWorkOrder?.workItems;
  return items?.length ?? 0;
}

/// Instances of the class [DiagnosticDomainHandler] implement a
/// [RequestHandler] that handles requests in the `diagnostic` domain.
class DiagnosticDomainHandler implements RequestHandler {
  /// The analysis server that is using this handler to process requests.
  final AnalysisServer server;

  /// Initialize a newly created handler to handle requests for the given
  /// [server].
  DiagnosticDomainHandler(this.server);

  /// Answer the `diagnostic.getDiagnostics` request.
  Response computeDiagnostics(Request request) {
    List<ContextData> contexts = <ContextData>[];
    if (server.options.enableNewAnalysisDriver) {
      contexts = server.driverMap.values.map(extractDataFromDriver).toList();
    } else {
      for (AnalysisContext context in server.analysisContexts) {
        contexts.add(extractDataFromContext(context));
      }
    }
    return new DiagnosticGetDiagnosticsResult(contexts).toResponse(request.id);
  }

  /// Extract context data from the given [context].
  ContextData extractDataFromContext(AnalysisContext context) {
    int explicitFiles = 0;
    int implicitFiles = 0;
    int workItems = 0;
    Set<String> exceptions = new HashSet<String>();
    if (context is AnalysisContextImpl) {
      workItems = _workItemCount(context);
      var cache = context.analysisCache;
      if (cache is AnalysisCache) {
        Set<AnalysisTarget> countedTargets = new HashSet<AnalysisTarget>();
        MapIterator<AnalysisTarget, CacheEntry> iterator = cache.iterator();
        while (iterator.moveNext()) {
          AnalysisTarget target = iterator.key;
          if (countedTargets.add(target)) {
            CacheEntry cacheEntry = iterator.value;
            if (cacheEntry == null) {
              throw new StateError(
                  "mutated cache key detected: $target (${target.runtimeType})");
            }
            if (target is Source) {
              if (cacheEntry.explicitlyAdded) {
                explicitFiles++;
              } else {
                implicitFiles++;
              }
            }
            // Caught exceptions.
            if (cacheEntry.exception != null) {
              exceptions.add(cacheEntry.exception.toString());
            }
          }
        }
      }
    }
    return new ContextData(context.name, explicitFiles, implicitFiles,
        workItems, exceptions.toList());
  }

  /// Extract context data from the given [driver].
  ContextData extractDataFromDriver(nd.AnalysisDriver driver) {
    int explicitFileCount = driver.addedFiles.length;
    int knownFileCount = driver.knownFiles.length;
    return new ContextData(driver.name, explicitFileCount,
        knownFileCount - explicitFileCount, driver.numberOfFilesToAnalyze, []);
  }

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == DIAGNOSTIC_GET_DIAGNOSTICS) {
        return computeDiagnostics(request);
      } else if (requestName == DIAGNOSTIC_GET_SERVER_PORT) {
        handleGetServerPort(request);
        return Response.DELAYED_RESPONSE;
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  /// Answer the `diagnostic.getServerPort` request.
  Future handleGetServerPort(Request request) async {
    try {
      // Open a port (or return the existing one).
      int port = await server.diagnosticServer.getServerPort();
      server.sendResponse(
          new DiagnosticGetServerPortResult(port).toResponse(request.id));
    } catch (error) {
      server
          .sendResponse(new Response.debugPortCouldNotBeOpened(request, error));
    }
  }
}
