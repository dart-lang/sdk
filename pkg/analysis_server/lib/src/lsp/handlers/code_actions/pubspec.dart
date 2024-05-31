// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/abstract_code_actions_producer.dart';
import 'package:analysis_server/src/services/correction/fix/pubspec/fix_generator.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:yaml/yaml.dart';

/// Produces [CodeAction]s from Pubspec fixes.
class PubspecCodeActionsProducer extends AbstractCodeActionsProducer {
  PubspecCodeActionsProducer(
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
  String get name => 'ServerPubspecActionsComputer';

  @override
  Future<List<CodeActionWithPriority>> getAssistActions() async => [];

  @override
  Future<List<CodeActionWithPriority>> getFixActions() async {
    var session = await server.getAnalysisSession(path);
    if (session == null) {
      return [];
    }

    var resourceProvider = server.resourceProvider;
    var pubspecFile = resourceProvider.getFile(path);
    var content = safelyRead(pubspecFile);
    if (content == null) {
      return [];
    }
    var lineInfo = LineInfo.fromContent(content);

    YamlNode node;
    try {
      node = loadYamlNode(content);
    } catch (exception) {
      return [];
    }
    var errors = validatePubspec(
      contents: node,
      source: FileSource(pubspecFile),
      provider: resourceProvider,
      analysisOptions: analysisOptions,
    );

    var codeActions = <CodeActionWithPriority>[];
    for (var error in errors) {
      var generator =
          PubspecFixGenerator(resourceProvider, error, content, node);
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
}
