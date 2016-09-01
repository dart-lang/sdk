// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.domain_diagnostic;

import 'dart:collection';
import 'dart:core' hide Resource;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart';
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
  /// The name of the request used to get diagnostic information.
  static const String DIAGNOSTICS = 'diagnostic.getDiagnostics';

  /// The analysis server that is using this handler to process requests.
  final AnalysisServer server;

  /// Initialize a newly created handler to handle requests for the given
  /// [server].
  DiagnosticDomainHandler(this.server);

  /// Answer the `diagnostic.diagnostics` request.
  Response computeDiagnostics(Request request) {
    List<ContextData> infos = <ContextData>[];
    for (AnalysisContext context in server.analysisContexts) {
      infos.add(extractData(context));
    }
    return new DiagnosticGetDiagnosticsResult(infos).toResponse(request.id);
  }

  /// Extract context data from the given [context].
  ContextData extractData(AnalysisContext context) {
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

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == DIAGNOSTICS) {
        return computeDiagnostics(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }
}
