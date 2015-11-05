// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library src.domain_experimental;

import 'dart:collection';
import 'dart:core' hide Resource;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/generated/engine.dart'
    hide AnalysisCache, AnalysisContextImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/task/driver.dart';
import 'package:analyzer/task/model.dart';

/// Extract context data from the given [context].
ContextData extractData(AnalysisContext context) {
  int explicitFiles = 0;
  int implicitFiles = 0;
  int workItems = 0;
  Set<String> exceptions = new HashSet<String>();
  if (context is AnalysisContextImpl) {
    // Work Item count.
    AnalysisDriver driver = context.driver;
    List<WorkItem> items = driver.currentWorkOrder?.workItems;
    workItems ??= items?.length;
    var cache = context.analysisCache;
    if (cache is AnalysisCache) {
      Set<AnalysisTarget> countedTargets = new HashSet<AnalysisTarget>();
      MapIterator<AnalysisTarget, CacheEntry> iterator = cache.iterator();
      while (iterator.moveNext()) {
        AnalysisTarget target = iterator.key;
        if (countedTargets.add(target)) {
          CacheEntry cacheEntry = iterator.value;
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
  return new ContextData(context.name, explicitFiles, implicitFiles, workItems,
      exceptions.toList());
}

/// Instances of the class [ExperimentalDomainHandler] implement a
/// [RequestHandler] that handles requests in the `experimental` domain.
class ExperimentalDomainHandler implements RequestHandler {
  /// The name of the request used to get diagnostic information.
  static const String EXPERIMENTAL_DIAGNOSTICS = 'experimental.getDiagnostics';

  /// The analysis server that is using this handler to process requests.
  final AnalysisServer server;

  /// Initialize a newly created handler to handle requests for the given
  /// [server].
  ExperimentalDomainHandler(this.server);

  /// Answer the `experimental.diagnostics` request.
  Response computeDiagnostics(Request request) {
    List<ContextData> infos = <ContextData>[];
    server.folderMap.forEach((Folder folder, AnalysisContext context) {
      infos.add(extractData(context));
    });

    return new ExperimentalGetDiagnosticsResult(infos).toResponse(request.id);
  }

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == EXPERIMENTAL_DIAGNOSTICS) {
        return computeDiagnostics(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }
}
