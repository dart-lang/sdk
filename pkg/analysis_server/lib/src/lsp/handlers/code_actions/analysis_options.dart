// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/abstract_code_actions_producer.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/services/correction/fix/analysis_options/fix_generator.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/analysis_options/options_file_validator.dart';
import 'package:analyzer/src/generated/source.dart' show SourceFactory;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:yaml/yaml.dart';

/// Produces [CodeActionLiteral]s from analysis options fixes.
class AnalysisOptionsCodeActionsProducer extends AbstractCodeActionsProducer {
  AnalysisOptionsCodeActionsProducer(
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
  });

  @override
  String get name => 'ServerAnalysisOptionsActionsComputer';

  @override
  Future<List<CodeActionWithPriority>> getAssistActions({
    OperationPerformance? performance,
  }) async => [];

  @override
  Future<List<CodeActionWithPriority>> getFixActions(
    OperationPerformance? performance,
  ) async {
    // These fixes are only provided as literal CodeActions.
    if (!allowCodeActionLiterals) {
      // TODO(dantup): Support this (via createCodeActionLiteralOrApplyCommand)
      return [];
    }

    var session = await server.getAnalysisSession(path);
    if (session == null) {
      return [];
    }

    var driver = server.getAnalysisDriver(path);
    if (driver == null) {
      return [];
    }

    var resourceProvider = server.resourceProvider;
    var sourceFactory = driver.sourceFactory;
    var optionsFile = resourceProvider.getFile(path);
    var content = safelyRead(optionsFile);
    if (content == null) {
      return [];
    }
    var lineInfo = LineInfo.fromContent(content);

    var options = _getOptions(sourceFactory, content);
    if (options == null) {
      return [];
    }

    var contextRoot = session.analysisContext.contextRoot;
    var package = contextRoot.workspace.findPackageFor(optionsFile.path);
    var sdkVersionConstraint = (package is PubPackage)
        ? package.sdkVersionConstraint
        : null;

    var errors = AnalysisOptionsAnalyzer(
      initialSource: FileSource(optionsFile),
      sourceFactory: sourceFactory,
      contextRoot: contextRoot.root.path,
      sdkVersionConstraint: sdkVersionConstraint,
      resourceProvider: resourceProvider,
    ).walkIncludes(content: content);

    var codeActions = <CodeActionWithPriority>[];
    for (var error in errors) {
      var generator = AnalysisOptionsFixGenerator(
        resourceProvider,
        error,
        content,
        options,
      );
      var fixes = await generator.computeFixes();
      if (fixes.isEmpty) {
        continue;
      }

      var result = createResult(session, lineInfo, errors);
      var diagnostic = createDiagnostic(lineInfo, result, error);
      codeActions.addAll(
        fixes.map((fix) {
          var kind = toCodeActionKind(fix.change.id, CodeActionKind.QuickFix);
          // TODO(dantup): Find a way to filter these earlier, so we don't
          //  compute fixes we will filter out.
          if (!shouldIncludeKind(kind)) {
            return null;
          }
          var action = CodeAction.t1(
            createCodeActionLiteral(
              fix.change,
              kind,
              fix.change.id,
              path,
              lineInfo,
              diagnostic: diagnostic,
            ),
          );
          return (action: action, priority: fix.kind.priority);
        }).nonNulls,
      );
    }

    return codeActions;
  }

  @override
  Future<List<CodeAction>> getRefactorActions(
    OperationPerformance? performance,
  ) async => [];

  @override
  Future<List<CodeAction>> getSourceActions() async => [];

  YamlMap? _getOptions(SourceFactory sourceFactory, String content) {
    var optionsProvider = AnalysisOptionsProvider(sourceFactory);
    try {
      return optionsProvider.getOptionsFromString(content);
    } on OptionsFormatException {
      return null;
    }
  }
}
