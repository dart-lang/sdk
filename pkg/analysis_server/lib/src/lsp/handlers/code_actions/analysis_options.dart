// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/abstract_code_actions_producer.dart';
import 'package:analysis_server/src/services/correction/fix/analysis_options/fix_generator.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:yaml/yaml.dart';

/// Produces [CodeAction]s from analysis options fixes.
class AnalysisOptionsCodeActionsProducer extends AbstractCodeActionsProducer {
  AnalysisOptionsCodeActionsProducer(
    super.server,
    super.file,
    super.lineInfo, {
    required super.offset,
    required super.length,
    required super.shouldIncludeKind,
    required super.capabilities,
  });

  @override
  String get name => 'ServerAnalysisOptionsActionsComputer';

  @override
  Future<List<CodeActionWithPriority>> getAssistActions() async => [];

  @override
  Future<List<CodeActionWithPriority>> getFixActions() async {
    final session = await server.getAnalysisSession(path);
    if (session == null) {
      return [];
    }

    final driver = server.getAnalysisDriver(path);
    if (driver == null) {
      return [];
    }

    final resourceProvider = server.resourceProvider;
    final sourceFactory = driver.sourceFactory;
    final optionsFile = resourceProvider.getFile(path);
    final content = safelyRead(optionsFile);
    if (content == null) {
      return [];
    }
    final lineInfo = LineInfo.fromContent(content);

    final options = _getOptions(sourceFactory, content);
    if (options == null) {
      return [];
    }

    final errors = analyzeAnalysisOptions(
      optionsFile.createSource(),
      content,
      sourceFactory,
      session.analysisContext.contextRoot.root.path,
      session.analysisContext.analysisOptions.sdkVersionConstraint,
    );

    final codeActions = <CodeActionWithPriority>[];
    for (final error in errors) {
      final generator = AnalysisOptionsFixGenerator(
          resourceProvider, error, content, options);
      final fixes = await generator.computeFixes();
      if (fixes.isEmpty) {
        continue;
      }

      final result = createResult(session, lineInfo, errors);
      final diagnostic = createDiagnostic(lineInfo, result, error);
      codeActions.addAll(
        fixes.map((fix) {
          final action =
              createFixAction(fix.change, diagnostic, path, lineInfo);
          return (action: action, priority: fix.kind.priority);
        }),
      );
    }

    return codeActions;
  }

  @override
  Future<List<Either2<CodeAction, Command>>> getRefactorActions() async => [];

  @override
  Future<List<Either2<CodeAction, Command>>> getSourceActions() async => [];

  YamlMap? _getOptions(SourceFactory sourceFactory, String content) {
    var optionsProvider = AnalysisOptionsProvider(sourceFactory);
    try {
      return optionsProvider.getOptionsFromString(content);
    } on OptionsFormatException {
      return null;
    }
  }
}
