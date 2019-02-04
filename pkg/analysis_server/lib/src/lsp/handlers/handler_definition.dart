// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/domains/analysis/navigation_dart.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart' show NavigationTarget;
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';

class DefinitionHandler
    extends MessageHandler<TextDocumentPositionParams, List<Location>> {
  DefinitionHandler(LspAnalysisServer server) : super(server);
  Method get handlesMessage => Method.textDocument_definition;

  @override
  TextDocumentPositionParams convertParams(Map<String, dynamic> json) =>
      TextDocumentPositionParams.fromJson(json);

  Future<ErrorOr<List<Location>>> handle(
      TextDocumentPositionParams params) async {
    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);
    final offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));

    return offset.mapResult((offset) {
      NavigationCollectorImpl collector = new NavigationCollectorImpl();
      computeDartNavigation(
          server.resourceProvider, collector, unit.result.unit, offset, 0);

      Location toLocation(NavigationTarget target) {
        final targetFilePath = collector.files[target.fileIndex];
        final lineInfo = server.getLineInfo(targetFilePath);
        return navigationTargetToLocation(targetFilePath, target, lineInfo);
      }

      return success(convert(collector.targets, toLocation).toList());
    });
  }
}
