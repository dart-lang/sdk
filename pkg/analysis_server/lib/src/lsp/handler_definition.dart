// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/domains/analysis/navigation_dart.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart' show NavigationTarget;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';

class DefinitionHandler
    extends MessageHandler<TextDocumentPositionParams, List<Location>> {
  final LspAnalysisServer server;
  String get handlesMessage => 'textDocument/definition';
  DefinitionHandler(this.server) : super(TextDocumentPositionParams.fromJson);

  Future<List<Location>> handle(TextDocumentPositionParams params) async {
    final path = pathOf(params.textDocument);
    ResolvedUnitResult result = await server.getResolvedUnit(path);
    // TODO(dantup): Handle bad paths/offsets.
    CompilationUnit unit = result?.unit;

    if (unit == null) {
      return null;
    }

    final pos = params.position;
    final offset = result.lineInfo.getOffsetOfLine(pos.line) + pos.character;

    NavigationCollectorImpl collector = new NavigationCollectorImpl();
    computeDartNavigation(server.resourceProvider, collector, unit, offset, 0);

    Future<Location> toLocation(NavigationTarget target) async {
      final targetFilePath = collector.files[target.fileIndex];
      final lineInfo = server.getLineInfo(targetFilePath);

      if (lineInfo == null) {
        return null;
      }

      return new Location(
        Uri.file(targetFilePath).toString(),
        toRange(lineInfo, target.offset, target.length),
      );
    }

    final locations = await Future.wait(collector.targets.map(toLocation));
    return locations.where((l) => l != null).toList();
  }
}
