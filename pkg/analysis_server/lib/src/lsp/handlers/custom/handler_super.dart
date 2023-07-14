// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/search/type_hierarchy.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:collection/collection.dart';

class SuperHandler
    extends LspMessageHandler<TextDocumentPositionParams, Location?> {
  SuperHandler(super.server);
  @override
  Method get handlesMessage => CustomMethods.super_;

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  @override
  Future<ErrorOr<Location?>> handle(TextDocumentPositionParams params,
      MessageInfo message, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);
    final offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));

    return offset.mapResult((offset) async {
      var node = NodeLocator(offset).searchWithin(unit.result.unit);
      if (node == null) {
        return success(null);
      }

      // Walk up the nodes until we find one that has an element so we can support
      // finding supers even if the cursor location was inside a method or on its
      // return type.
      var element = server.getElementOfNode(node);
      while (element == null && node?.parent != null) {
        node = node?.parent;
        element = server.getElementOfNode(node);
      }
      if (element == null) {
        return success(null);
      }

      final computer = TypeHierarchyComputer(server.searchEngine, element);
      final items = computer.computeSuper();

      // We expect to get at least two items back - the first will be the input
      // element so we start looking from the second.
      if (items == null || items.length < 2) {
        return success(null);
      }

      // The class will have a memberElement if we were searching for an element
      // otherwise we're looking for a class.
      final isMember = items.first.memberElement != null;
      final superItem = items.skip(1).firstWhereOrNull(
          (elm) => isMember ? elm.memberElement != null : true);

      final location = superItem?.memberElement?.location ??
          superItem?.classElement.location;

      if (location == null) {
        return success(null);
      }

      final locationLineInfo = server.getLineInfo(location.file);
      if (locationLineInfo == null) {
        return success(null);
      }

      return success(toLocation(pathContext, location, locationLineInfo));
    });
  }
}
