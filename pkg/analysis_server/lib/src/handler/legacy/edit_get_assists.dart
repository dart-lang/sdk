// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/plugin/result_converter.dart';
import 'package:analysis_server/src/request_handler_mixin.dart';
import 'package:analysis_server_plugin/edit/assist/assist.dart';
import 'package:analysis_server_plugin/edit/assist/dart_assist_context.dart';
import 'package:analysis_server_plugin/src/correction/assist_performance.dart';
import 'package:analysis_server_plugin/src/correction/assist_processor.dart';
import 'package:analysis_server_plugin/src/correction/dart_change_workspace.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/src/exception/exception.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;

/// The handler for the `edit.getAssists` request.
class EditGetAssistsHandler extends LegacyHandler
    with RequestHandlerMixin<LegacyAnalysisServer> {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  EditGetAssistsHandler(
    super.server,
    super.request,
    super.cancellationToken,
    super.performance,
  );

  @override
  Future<void> handle() async {
    var params = EditGetAssistsParams.fromRequest(
      request,
      clientUriConverter: server.uriConverter,
    );
    var file = params.file;
    var offset = params.offset;
    var length = params.length;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }
    //
    // Allow plugins to start computing assists.
    //
    var requestParams = plugin.EditGetAssistsParams(file, offset, length);
    var driver = performance.run(
      'getAnalysisDriver',
      (_) => server.getAnalysisDriver(file),
    );
    var pluginFutures = server.broadcastRequestToPlugins(requestParams, driver);

    //
    // Compute fixes associated with server-generated errors.
    //
    var changes = await performance.runAsync(
      '_computeServerAssists',
      (_) => _computeServerAssists(request, file, offset, length),
    );

    //
    // Add the fixes produced by plugins to the server-generated fixes.
    //
    var responses = await performance.runAsync(
      'waitForResponses',
      (_) => waitForResponses(pluginFutures, requestParameters: requestParams),
    );
    server.requestStatistics?.addItemTimeNow(request, 'pluginResponses');
    var converter = ResultConverter();
    var pluginChanges = <plugin.PrioritizedSourceChange>[];
    for (var response in responses) {
      var result = plugin.EditGetAssistsResult.fromResponse(response);
      pluginChanges.addAll(result.assists);
    }
    pluginChanges.sort(
      (first, second) => first.priority.compareTo(second.priority),
    );
    changes.addAll(pluginChanges.map(converter.convertPrioritizedSourceChange));

    //
    // Send the response.
    //
    sendResult(EditGetAssistsResult(changes));
  }

  Future<List<SourceChange>> _computeServerAssists(
    Request request,
    String file,
    int offset,
    int length,
  ) async {
    var changes = <SourceChange>[];

    var libraryResult = await server.getResolvedLibrary(file);
    server.requestStatistics?.addItemTimeNow(request, 'resolvedUnit');

    if (libraryResult != null) {
      var unitResult = libraryResult.unitWithPath(file)!;
      var context = DartAssistContext(
        server.instrumentationService,
        DartChangeWorkspace(await server.currentSessions),
        libraryResult,
        unitResult,
        offset,
        length,
      );

      try {
        var performanceTracker = AssistPerformance();
        var assists = await computeAssists(
          context,
          performance: performanceTracker,
        );
        assists.sort(Assist.compareAssists);
        for (var assist in assists) {
          changes.add(assist.change);
        }

        server.recentPerformance.getAssists.add(
          GetAssistsPerformance(
            performance: performance,
            path: file,
            content: unitResult.content,
            offset: offset,
            requestLatency: performanceTracker.computeTime!.inMilliseconds,
            producerTimings: performanceTracker.producerTimings,
          ),
        );
      } on InconsistentAnalysisException {
        // ignore
      } catch (exception, stackTrace) {
        var parametersFile =
            '''
offset: $offset
length: $length
      ''';
        throw CaughtExceptionWithFiles(exception, stackTrace, {
          file: unitResult.content,
          'parameters': parametersFile,
        });
      }

      server.requestStatistics?.addItemTimeNow(request, 'computedAssists');
    }

    return changes;
  }
}
