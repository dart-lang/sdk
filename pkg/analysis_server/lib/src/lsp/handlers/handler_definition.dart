// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/protocol/protocol_generated.dart'
    hide AnalysisGetNavigationParams;
import 'package:analysis_server/src/domains/analysis/navigation_dart.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/plugin/result_merger.dart';
import 'package:analysis_server/src/protocol_server.dart' show NavigationTarget;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';

class DefinitionHandler
    extends MessageHandler<TextDocumentPositionParams, List<Location>> {
  DefinitionHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.textDocument_definition;

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  Future<List<AnalysisNavigationParams>> getPluginResults(
    String path,
    int offset,
  ) async {
    // LSP requests must be converted to DAS-protocol requests for compatibility
    // with plugins.
    final requestParams = plugin.AnalysisGetNavigationParams(path, offset, 0);

    final driver = server.getAnalysisDriver(path);
    final pluginFutures = server.pluginManager
        .broadcastRequest(requestParams, contextRoot: driver.contextRoot);

    final responses =
        await waitForResponses(pluginFutures, requestParameters: requestParams);

    return responses
        .map((response) =>
            plugin.AnalysisGetNavigationResult.fromResponse(response))
        .map((result) => AnalysisNavigationParams(
            path, result.regions, result.targets, result.files))
        .toList();
  }

  Future<AnalysisNavigationParams> getServerResult(
      String path, int offset) async {
    final collector = NavigationCollectorImpl();

    final result = await server.getResolvedUnit(path);
    if (result?.state == ResultState.VALID) {
      computeDartNavigation(
          server.resourceProvider, collector, result.unit, offset, 0);
    }

    return AnalysisNavigationParams(
        path, collector.regions, collector.targets, collector.files);
  }

  @override
  Future<ErrorOr<List<Location>>> handle(
      TextDocumentPositionParams params, CancellationToken token) async {
    final pos = params.position;
    final path = pathOfDoc(params.textDocument);

    return path.mapResult((path) async {
      final lineInfo = server.getLineInfo(path);
      // If there is no lineInfo, the request canot be translated from LSP line/col
      // to server offset/length.
      if (lineInfo == null) {
        return success(const []);
      }

      final offset = toOffset(lineInfo, pos);

      return offset.mapResult((offset) async {
        final allResults = [
          await getServerResult(path, offset),
          ...await getPluginResults(path, offset),
        ];

        final merger = ResultMerger();
        final mergedResults = merger.mergeNavigation(allResults);
        final mergedTargets = mergedResults?.targets ?? [];

        Location toLocation(NavigationTarget target) {
          final targetFilePath = mergedResults.files[target.fileIndex];
          final lineInfo = server.getLineInfo(targetFilePath);
          return navigationTargetToLocation(targetFilePath, target, lineInfo);
        }

        return success(convert(mergedTargets, toLocation).toList());
      });
    });
  }
}
