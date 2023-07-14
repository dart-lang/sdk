// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/abstract_code_actions_producer.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart' as plugin;

/// Produces [CodeAction]s from Plugin fixes and assists.
class PluginCodeActionsProducer extends AbstractCodeActionsProducer {
  final AnalysisDriver? driver;

  PluginCodeActionsProducer(
    super.server,
    super.path,
    super.lineInfo, {
    required super.offset,
    required super.length,
    required super.shouldIncludeKind,
    required super.capabilities,
  }) : driver = server.getAnalysisDriver(path);

  @override
  String get name => 'PluginActionsComputer';

  @override
  Future<List<CodeActionWithPriority>> getAssistActions() async {
    // These assists are only provided as literal CodeActions.
    if (!supportsLiterals) {
      return [];
    }

    final requestParams = plugin.EditGetAssistsParams(path, offset, length);
    final responses = await _sendPluginRequest(requestParams);

    return responses
        .map((response) => plugin.EditGetAssistsResult.fromResponse(response))
        .expand((response) => response.assists)
        .map(_convertAssist)
        .toList();
  }

  @override
  Future<List<CodeActionWithPriority>> getFixActions() async {
    // These fixes are only provided as literal CodeActions.
    if (!supportsLiterals) {
      return [];
    }

    final requestParams = plugin.EditGetFixesParams(path, offset);
    final responses = await _sendPluginRequest(requestParams);

    return responses
        .map((response) => plugin.EditGetFixesResult.fromResponse(response))
        .expand((response) => response.fixes)
        .map(_convertFixes)
        .expand((fix) => fix)
        .toList();
  }

  @override
  Future<List<Either2<CodeAction, Command>>> getRefactorActions() async => [];

  @override
  Future<List<Either2<CodeAction, Command>>> getSourceActions() async => [];

  CodeActionWithPriority _convertAssist(plugin.PrioritizedSourceChange assist) {
    return (
      action: createAssistAction(assist.change, path, lineInfo),
      priority: assist.priority,
    );
  }

  Iterable<CodeActionWithPriority> _convertFixes(
      plugin.AnalysisErrorFixes fixes) {
    final diagnostic = pluginToDiagnostic(
      server.pathContext,
      (_) => lineInfo,
      fixes.error,
      supportedTags: supportedDiagnosticTags,
      clientSupportsCodeDescription: supportsCodeDescription,
    );
    return fixes.fixes.map(
      (fix) => (
        action: createFixAction(fix.change, diagnostic, path, lineInfo),
        priority: fix.priority,
      ),
    );
  }

  Future<List<plugin.Response>> _sendPluginRequest(
      plugin.RequestParams requestParams) async {
    final driver = this.driver;
    if (driver == null) {
      return [];
    }

    var pluginFutures = server.broadcastRequestToPlugins(requestParams, driver);

    return waitForResponses(
      pluginFutures,
      requestParameters: requestParams,
    );
  }
}
