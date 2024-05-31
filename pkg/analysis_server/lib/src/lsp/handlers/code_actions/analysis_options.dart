// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/abstract_code_actions_producer.dart';
import 'package:analysis_server/src/services/correction/fix/analysis_options/fix_generator.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/generated/source.dart' show SourceFactory;
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/workspace/pub.dart';
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
    required super.analysisOptions,
  });

  @override
  String get name => 'ServerAnalysisOptionsActionsComputer';

  @override
  Future<List<CodeActionWithPriority>> getAssistActions() async => [];

  @override
  Future<List<CodeActionWithPriority>> getFixActions() async {
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
    var sdkVersionConstraint =
        (package is PubPackage) ? package.sdkVersionConstraint : null;

    var errors = analyzeAnalysisOptions(
      FileSource(optionsFile),
      content,
      sourceFactory,
      contextRoot.root.path,
      sdkVersionConstraint,
    );

    var codeActions = <CodeActionWithPriority>[];
    for (var error in errors) {
      var generator = AnalysisOptionsFixGenerator(
          resourceProvider, error, content, options);
      var fixes = await generator.computeFixes();
      if (fixes.isEmpty) {
        continue;
      }

      var result = createResult(session, lineInfo, errors);
      var diagnostic = createDiagnostic(lineInfo, result, error);
      codeActions.addAll(
        fixes.map((fix) {
          var action = createFixAction(fix.change, diagnostic, path, lineInfo);
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
