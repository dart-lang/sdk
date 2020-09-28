// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/search/type_hierarchy.dart';

class ImplementationHandler
    extends MessageHandler<TextDocumentPositionParams, List<Location>> {
  ImplementationHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.textDocument_implementation;

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  @override
  Future<ErrorOr<List<Location>>> handle(
      TextDocumentPositionParams params, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(const []);
    }

    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);
    final offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));
    return offset
        .mapResult((offset) => _getImplementations(path.result, offset, token));
  }

  Future<ErrorOr<List<Location>>> _getImplementations(
      String file, int offset, CancelableToken token) async {
    final element = await server.getElementAtOffset(file, offset);
    final computer = TypeHierarchyComputer(server.searchEngine, element);
    if (token.isCancellationRequested) {
      return cancelled();
    }
    final items = await computer.compute();

    if (items == null || items.isEmpty) {
      return success([]);
    }

    Iterable<TypeHierarchyItem> getDescendants(TypeHierarchyItem item) => item
        .subclasses
        ?.map((i) => items[i])
        ?.followedBy(item.subclasses.expand((i) => getDescendants(items[i])));

    // [TypeHierarchyComputer] returns the whole tree, but we specifically only
    // want implementations (sub-classes). Find the referenced element and then
    // recursively add its children.
    var currentItem = items.firstWhere(
      (item) {
        final location =
            item.memberElement?.location ?? item.classElement?.location;
        return location.offset <= offset &&
            location.offset + location.length >= offset;
      },
      // If we didn't find an item spanning our offset, we must've been at a
      // call site so start everything from the root item.
      orElse: () => items.first,
    );

    final isClass = currentItem.memberElement == null;

    final locations = getDescendants(currentItem).where((item) {
      // Filter based on type, so when searching for members we don't include
      // any intermediate classes that don't have implementations for the
      // method.
      return isClass ? item.classElement != null : item.memberElement != null;
    }).map((item) {
      final elementLocation =
          item.memberElement?.location ?? item.classElement?.location;
      final lineInfo = server.getLineInfo(elementLocation.file);
      return Location(
        uri: Uri.file(elementLocation.file).toString(),
        range:
            toRange(lineInfo, elementLocation.offset, elementLocation.length),
      );
    }).toList();

    return success(locations);
  }
}
