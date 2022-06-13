// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/plugin/result_converter.dart';
import 'package:analysis_server/src/request_handler_mixin.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/src/exception/exception.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;

/// The handler for the `edit.getAssists` request.
class EditGetAssistsHandler extends LegacyHandler
    with RequestHandlerMixin<AnalysisServer> {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  EditGetAssistsHandler(super.server, super.request, super.cancellationToken);

  @override
  Future<void> handle() async {
    var params = EditGetAssistsParams.fromRequest(request);
    var file = params.file;
    var offset = params.offset;
    var length = params.length;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }
    //
    // Allow plugins to start computing assists.
    //
    Map<PluginInfo, Future<plugin.Response>> pluginFutures;
    var requestParams = plugin.EditGetAssistsParams(file, offset, length);
    var driver = server.getAnalysisDriver(file);
    if (driver == null) {
      pluginFutures = <PluginInfo, Future<plugin.Response>>{};
    } else {
      pluginFutures = server.pluginManager.broadcastRequest(
        requestParams,
        contextRoot: driver.analysisContext!.contextRoot,
      );
    }

    //
    // Compute fixes associated with server-generated errors.
    //
    var changes = await _computeServerAssists(request, file, offset, length);

    //
    // Add the fixes produced by plugins to the server-generated fixes.
    //
    var responses =
        await waitForResponses(pluginFutures, requestParameters: requestParams);
    server.requestStatistics?.addItemTimeNow(request, 'pluginResponses');
    var converter = ResultConverter();
    var pluginChanges = <plugin.PrioritizedSourceChange>[];
    for (var response in responses) {
      var result = plugin.EditGetAssistsResult.fromResponse(response);
      pluginChanges.addAll(result.assists);
    }
    pluginChanges
        .sort((first, second) => first.priority.compareTo(second.priority));
    changes.addAll(pluginChanges.map(converter.convertPrioritizedSourceChange));

    //
    // Send the response.
    //
    sendResult(EditGetAssistsResult(changes));
  }

  Future<List<SourceChange>> _computeServerAssists(
      Request request, String file, int offset, int length) async {
    var changes = <SourceChange>[];

    var result = await server.getResolvedUnit(file);
    server.requestStatistics?.addItemTimeNow(request, 'resolvedUnit');

    if (result != null) {
      var context = DartAssistContextImpl(
        server.instrumentationService,
        DartChangeWorkspace(
          await server.currentSessions,
        ),
        result,
        offset,
        length,
      );

      try {
        var processor = AssistProcessor(context);
        var assists = await processor.compute();
        assists.sort(Assist.SORT_BY_RELEVANCE);
        for (var assist in assists) {
          changes.add(assist.change);
        }
      } on InconsistentAnalysisException {
        // ignore
      } catch (exception, stackTrace) {
        var parametersFile = '''
offset: $offset
length: $length
      ''';
        throw CaughtExceptionWithFiles(exception, stackTrace, {
          file: result.content,
          'parameters': parametersFile,
        });
      }

      server.requestStatistics?.addItemTimeNow(request, 'computedAssists');
    }

    return changes;
  }
}
