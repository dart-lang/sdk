// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/abstract_code_actions_producer.dart';
import 'package:analysis_server/src/services/correction/fix/pubspec/fix_generator.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:yaml/yaml.dart';

/// Produces [CodeAction]s from Pubspec fixes.
class PubspecCodeActionsProducer extends AbstractCodeActionsProducer {
  PubspecCodeActionsProducer(
    super.server,
    super.path,
    super.lineInfo, {
    required super.offset,
    required super.length,
    required super.shouldIncludeKind,
    required super.capabilities,
  });

  @override
  String get name => 'ServerPubspecActionsComputer';

  @override
  Future<List<CodeActionWithPriority>> getAssistActions() async => [];

  @override
  Future<List<CodeActionWithPriority>> getFixActions() async {
    final session = await server.getAnalysisSession(path);
    if (session == null) {
      return [];
    }

    final resourceProvider = server.resourceProvider;
    final pubspecFile = resourceProvider.getFile(path);
    final content = safelyRead(pubspecFile);
    if (content == null) {
      return [];
    }
    final lineInfo = LineInfo.fromContent(content);

    YamlDocument document;
    try {
      document = loadYamlDocument(content);
    } catch (exception) {
      return [];
    }
    var yamlContent = document.contents;
    if (yamlContent is! YamlMap) {
      yamlContent = YamlMap();
    }

    final errors = validatePubspec(
      contents: yamlContent.nodes,
      source: pubspecFile.createSource(),
      provider: resourceProvider,
    );

    final codeActions = <CodeActionWithPriority>[];
    for (final error in errors) {
      final generator =
          PubspecFixGenerator(resourceProvider, error, content, document);
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
}
