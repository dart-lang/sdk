// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/abstract_code_actions_producer.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart' as plugin;
import 'package:collection/collection.dart';

/// Produces [CodeActionLiteral]s from Plugin fixes and assists.
class PluginCodeActionsProducer extends AbstractCodeActionsProducer {
  final AnalysisDriver? driver;

  PluginCodeActionsProducer(
    super.server,
    super.file,
    super.lineInfo, {
    required super.offset,
    required super.length,
    required super.shouldIncludeKind,
    required super.editorCapabilities,
    required super.callerCapabilities,
    required super.allowCodeActionLiterals,
    required super.allowCommands,
    required super.analysisOptions,
    required super.allowSnippets,
  }) : driver = server.getAnalysisDriver(file.path);

  @override
  String get name => 'PluginActionsComputer';

  @override
  Future<List<CodeActionWithPriority>> getAssistActions({
    OperationPerformance? performance,
  }) async {
    // These assists are only provided as literal CodeActions.
    if (!allowCodeActionLiterals) {
      // TODO(dantup): Support this (via createCodeActionLiteralOrApplyCommand)
      //  this will require plugins to create stable IDs/kinds so we can look
      //  them back up in `applyCodeAction`.
      return [];
    }

    var requestParams = plugin.EditGetAssistsParams(path, offset, length);
    var responses = await _sendPluginRequest(requestParams);

    return responses
        .map((response) => plugin.EditGetAssistsResult.fromResponse(response))
        .expand((response) => response.assists)
        .map(_convertAssist)
        .nonNulls
        .toList();
  }

  @override
  Future<List<CodeActionWithPriority>> getFixActions(
    OperationPerformance? performance,
  ) async {
    // These fixes are only provided as literal CodeActions.
    if (!allowCodeActionLiterals) {
      // TODO(dantup): Support this (via createCodeActionLiteralOrApplyCommand)
      //  this will require plugins to create stable IDs/kinds so we can look
      //  them back up in `applyCodeAction`.
      return [];
    }

    var requestParams = plugin.EditGetFixesParams(path, offset);
    var responses = await _sendPluginRequest(requestParams);

    return responses
        .map((response) => plugin.EditGetFixesResult.fromResponse(response))
        .expand((response) => response.fixes)
        .map(_convertFixes)
        .flattenedToList;
  }

  @override
  Future<List<CodeAction>> getRefactorActions(
    OperationPerformance? performance,
  ) async => [];

  @override
  Future<List<CodeAction>> getSourceActions() async => [];

  CodeActionWithPriority? _convertAssist(
    plugin.PrioritizedSourceChange assist,
  ) {
    var kind = toCodeActionKind(assist.change.id, CodeActionKind.Refactor);
    // TODO(dantup): Find a way to filter these earlier, so we don't
    //  compute fixes we will filter out.
    if (!shouldIncludeKind(kind)) {
      return null;
    }

    return (
      action: CodeAction.t1(
        createCodeActionLiteral(
          assist.change,
          kind,
          'assist from plugin',
          path,
          lineInfo,
        ),
      ),
      priority: assist.priority,
    );
  }

  Iterable<CodeActionWithPriority> _convertFixes(
    plugin.AnalysisErrorFixes fixes,
  ) {
    var diagnostic = pluginToDiagnostic(
      server.uriConverter,
      (_) => lineInfo,
      fixes.error,
      supportedTags: callerSupportedDiagnosticTags,
      clientSupportsCodeDescription: callerSupportsCodeDescription,
    );
    return fixes.fixes.map((fix) {
      var kind = toCodeActionKind(fix.change.id, CodeActionKind.QuickFix);
      // TODO(dantup): Find a way to filter these earlier, so we don't
      //  compute fixes we will filter out.
      if (!shouldIncludeKind(kind)) {
        return null;
      }
      return (
        action: CodeAction.t1(
          createCodeActionLiteral(
            fix.change,
            kind,
            'fix from plugin',
            path,
            lineInfo,
            diagnostic: diagnostic,
          ),
        ),
        priority: fix.priority,
      );
    }).nonNulls;
  }

  Future<List<plugin.Response>> _sendPluginRequest(
    plugin.RequestParams requestParams,
  ) async {
    var driver = this.driver;
    if (driver == null) {
      return [];
    }

    var pluginFutures = server.broadcastRequestToPlugins(requestParams, driver);

    return waitForResponses(pluginFutures, requestParameters: requestParams);
  }
}
