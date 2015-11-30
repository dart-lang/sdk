// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library src.domain_diagnostic;

import 'dart:async';
import 'dart:collection';
import 'dart:core' hide Resource;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/utilities/average.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/generated/engine.dart'
    hide AnalysisCache, AnalysisContextImpl;
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

  /// The sampler tracking rolling work queue length averages.
  Sampler sampler;

  /// Initialize a newly created handler to handle requests for the given
  /// [server].
  DiagnosticDomainHandler(this.server);

  /// Answer the `diagnostic.diagnostics` request.
  Response computeDiagnostics(Request request) {
    // Initialize sampler if needed.
    if (sampler == null) {
      sampler = new Sampler(server);
    }

    List<ContextData> infos = <ContextData>[];
    server.folderMap.forEach((Folder folder, AnalysisContext context) {
      infos.add(extractData(folder, context));
    });

    return new DiagnosticGetDiagnosticsResult(infos).toResponse(request.id);
  }

  /// Extract context data from the given [context].
  ContextData extractData(Folder folder, AnalysisContext context) {
    int explicitFiles = 0;
    int implicitFiles = 0;
    int workItems = 0;
    String workItemAverage = '-1';
    Set<String> exceptions = new HashSet<String>();
    if (context is AnalysisContextImpl) {
      workItems = _workItemCount(context);
      workItemAverage = sampler.getAverage(folder)?.toString() ?? '-1';
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
    return new ContextData(context.name, explicitFiles, implicitFiles,
        workItems, workItemAverage, exceptions.toList());
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

/// Keeps track of a moving average of work item queue lengths mapped to
/// contexts.
///
/// Sampling terminates after [maxSampleCount], if no one expresses interest
/// by calling [resetTimerCountdown].
class Sampler {
  /// Timer interval.
  static const Duration duration = const Duration(seconds: 1);

  /// Maximum number of samples taken between calls to [reset].
  static const int maxSampleCount = 30;

  /// Current sample count.
  int sampleCount = 0;

  /// The shared timer.
  Timer timer;

  /// Map of contexts (tracked as folders to avoid leaks) to averages.
  /// TOOD(pq): consider adding GC to remove mappings for deleted folders
  Map<Folder, Average> averages = new HashMap<Folder, Average>();

  final AnalysisServer server;
  Sampler(this.server) {
    start();
    _sample();
  }

  /// Get the average for the context associated with the given [folder].
  int getAverage(Folder folder) {
    resetTimerCountdown();
    return averages[folder].value;
  }

  /// Check if we're currently sampling.
  bool isSampling() => timer?.isActive ?? false;

  /// Reset counter.
  void resetTimerCountdown() {
    sampleCount = 0;
  }

  /// Start sampling.
  void start() {
    // No need to (re)start if already sampling.
    if (isSampling()) {
      return;
    }
    timer = new Timer.periodic(duration, (Timer timer) {
      _sample();
      if (sampleCount++ >= maxSampleCount) {
        timer.cancel();
      }
    });
  }

  /// Stop sampling.
  void stop() {
    timer.cancel();
  }

  /// Take a sample.
  void _sample() {
    try {
      server.folderMap.forEach((Folder folder, AnalysisContext context) {
        if (context is AnalysisContextImpl) {
          Average average = averages[folder];
          if (average == null) {
            average = new Average();
            averages[folder] = average;
          }
          average.addSample(_workItemCount(context));
        }
      });
    } on Exception {
      stop();
    }
  }
}
