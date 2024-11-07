// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:meta/meta.dart';

/// A common base for commands that accept a position in a document and return
/// a location to navigate to a particular kind of related element, such as
/// Super, Augmentation Target or Augmentation.
abstract class AbstractGoToHandler
    extends SharedMessageHandler<TextDocumentPositionParams, Location?> {
  AbstractGoToHandler(super.server);

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  @protected
  Element? findRelatedElement(Element element);

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
      var node = NodeLocator(offset).searchWithin(unit.unit);
      if (node == null) {
        return success(null);
      }

      // Walk up the nodes until we find one that has an element so we can
      // find target even if the cursor location was inside a method or on a
      // return type.
      var element = server.getElementOfNode(node);
      while (element == null && node?.parent != null) {
        node = node?.parent;
        element = server.getElementOfNode(node);
      }
      if (element == null) {
        return success(null);
      }

      var targetElement = findRelatedElement(element)?.nonSynthetic;
      var sourcePath = targetElement?.declaration?.source?.fullName;

      if (targetElement == null || sourcePath == null) {
        return success(null);
      }

      var locationLineInfo = server.getLineInfo(sourcePath);
      if (locationLineInfo == null) {
        return success(null);
      }

      return success(
        Location(
          uri: uriConverter.toClientUri(sourcePath),
          range: toRange(
            locationLineInfo,
            targetElement.nameOffset,
            targetElement.nameLength,
          ),
        ),
      );
    });
  }
}
