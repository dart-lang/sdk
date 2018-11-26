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
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';

class DefinitionHandler
    extends MessageHandler<TextDocumentPositionParams, List<Location>> {
  DefinitionHandler(LspAnalysisServer server) : super(server);
  String get handlesMessage => 'textDocument/definition';

  @override
  TextDocumentPositionParams convertParams(Map<String, dynamic> json) =>
      TextDocumentPositionParams.fromJson(json);

  Future<List<Location>> handle(TextDocumentPositionParams params) async {
    final path = pathOf(params.textDocument);
    final result = await requireUnit(path);
    final offset = toOffset(result.lineInfo, params.position);

    NavigationCollectorImpl collector = new NavigationCollectorImpl();
    computeDartNavigation(
        server.resourceProvider, collector, result.unit, offset, 0);

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
