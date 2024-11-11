// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/utilities/extensions/ast.dart';

class AugmentationHandler
    extends SharedMessageHandler<TextDocumentPositionParams, Location?> {
  AugmentationHandler(super.server);

  @override
  Method get handlesMessage => CustomMethods.augmentation;

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<Location?>> handle(
    TextDocumentPositionParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    var pos = params.position;
    var path = pathOfDoc(params.textDocument);
    var unit = await path.mapResult(requireResolvedUnit);
    var offset = unit.mapResultSync((unit) => toOffset(unit.lineInfo, pos));

    return (unit, offset).mapResultsSync((unit, offset) {
      // Find the nearest node that could have fragments.
      var node =
          unit.unit
              .nodeCovering(offset: offset)
              ?.thisOrAncestorOfType<ast.Declaration>();

      var location = fragmentToLocation(
        uriConverter,
        // Augmentation = next fragment.
        node?.declaredFragment?.nextFragment,
      );
      return success(location);
    });
  }
}
