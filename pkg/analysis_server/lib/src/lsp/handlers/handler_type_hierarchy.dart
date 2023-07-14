// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/computer/computer_lazy_type_hierarchy.dart'
    as type_hierarchy;
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/element/element.dart';

/// A handler for the initial "prepare" request for starting navigation with
/// Type Hierarchy.
///
/// This handler returns the initial target based on the offset where the
/// feature is invoked. Invocations at item sites will resolve to the respective
/// declarations.
///
/// The target returned by this handler will be sent back to the server for
/// supertype/supertype items as the user navigates the type hierarchy in the
/// client.
class PrepareTypeHierarchyHandler extends LspMessageHandler<
    TypeHierarchyPrepareParams,
    TextDocumentPrepareTypeHierarchyResult> with _TypeHierarchyUtils {
  PrepareTypeHierarchyHandler(super.server);
  @override
  Method get handlesMessage => Method.textDocument_prepareTypeHierarchy;

  @override
  LspJsonHandler<TypeHierarchyPrepareParams> get jsonHandler =>
      TypeHierarchyPrepareParams.jsonHandler;

  @override
  Future<ErrorOr<TextDocumentPrepareTypeHierarchyResult>> handle(
      TypeHierarchyPrepareParams params,
      MessageInfo message,
      CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(const []);
    }

    final clientCapabilities = server.lspClientCapabilities;
    if (clientCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return serverNotInitializedError;
    }

    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);
    final offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));
    return offset.mapResult((offset) {
      final computer =
          type_hierarchy.DartLazyTypeHierarchyComputer(unit.result);
      final target = computer.findTarget(offset);
      if (target == null) {
        return success(null);
      }

      final item = toLspItem(target, unit.result.lineInfo);
      return success([item]);
    });
  }
}

class TypeHierarchySubtypesHandler extends LspMessageHandler<
    TypeHierarchySubtypesParams,
    TypeHierarchySubtypesResult> with _TypeHierarchyUtils {
  TypeHierarchySubtypesHandler(super.server);
  @override
  Method get handlesMessage => Method.typeHierarchy_subtypes;

  @override
  LspJsonHandler<TypeHierarchySubtypesParams> get jsonHandler =>
      TypeHierarchySubtypesParams.jsonHandler;

  @override
  Future<ErrorOr<TypeHierarchySubtypesResult>> handle(
      TypeHierarchySubtypesParams params,
      MessageInfo message,
      CancellationToken token) async {
    final item = params.item;
    final data = item.data;
    final path = pathOfUri(item.uri);
    final unit = await path.mapResult(requireResolvedUnit);
    final computer = type_hierarchy.DartLazyTypeHierarchyComputer(unit.result);

    if (data == null) {
      return error(
        ErrorCodes.InvalidParams,
        'TypeHierarchyItem is missing the data field',
      );
    }

    final location = ElementLocationImpl.con2(data.ref);
    final calls = await computer.findSubtypes(location, server.searchEngine);
    final results = calls != null ? _convertItems(unit.result, calls) : null;
    return success(results);
  }
}

class TypeHierarchySupertypesHandler extends LspMessageHandler<
    TypeHierarchySupertypesParams,
    TypeHierarchySupertypesResult> with _TypeHierarchyUtils {
  TypeHierarchySupertypesHandler(super.server);
  @override
  Method get handlesMessage => Method.typeHierarchy_supertypes;

  @override
  LspJsonHandler<TypeHierarchySupertypesParams> get jsonHandler =>
      TypeHierarchySupertypesParams.jsonHandler;

  @override
  Future<ErrorOr<TypeHierarchySupertypesResult>> handle(
      TypeHierarchySupertypesParams params,
      MessageInfo message,
      CancellationToken token) async {
    final item = params.item;
    final data = item.data;
    final path = pathOfUri(item.uri);
    final unit = await path.mapResult(requireResolvedUnit);
    final computer = type_hierarchy.DartLazyTypeHierarchyComputer(unit.result);

    if (data == null) {
      return error(
        ErrorCodes.InvalidParams,
        'TypeHierarchyItem is missing the data field',
      );
    }

    final location = ElementLocationImpl.con2(data.ref);
    final anchor = _toServerAnchor(data);
    final calls = await computer.findSupertypes(location, anchor: anchor);
    final results = calls != null ? _convertItems(unit.result, calls) : null;
    return success(results);
  }

  /// Reads the anchor from [data] (if available) and converts it to a server
  /// [type_hierarchy.TypeHierarchyAnchor].
  type_hierarchy.TypeHierarchyAnchor? _toServerAnchor(
    TypeHierarchyItemInfo data,
  ) {
    final anchor = data.anchor;
    return anchor != null
        ? type_hierarchy.TypeHierarchyAnchor(
            location: ElementLocationImpl.con2(anchor.ref),
            path: anchor.path,
          )
        : null;
  }
}

/// Utility methods used by all Type Hierarchy handlers.
mixin _TypeHierarchyUtils on HandlerHelperMixin<AnalysisServer> {
  /// Converts a server [SourceRange] to an LSP [Range].
  Range sourceRangeToRange(LineInfo lineInfo, SourceRange range) =>
      toRange(lineInfo, range.offset, range.length);

  /// Converts a server [type_hierarchy.TypeHierarchyItem] to an LSP
  /// [TypeHierarchyItem].
  TypeHierarchyItem toLspItem(
    type_hierarchy.TypeHierarchyItem item,
    LineInfo lineInfo,
  ) {
    final anchor =
        item is type_hierarchy.TypeHierarchyRelatedItem ? item.anchor : null;
    return TypeHierarchyItem(
      name: item.displayName,
      kind: SymbolKind.Class,
      uri: pathContext.toUri(item.file),
      range: sourceRangeToRange(lineInfo, item.codeRange),
      selectionRange: sourceRangeToRange(lineInfo, item.nameRange),
      data: TypeHierarchyItemInfo(
        ref: item.location.encoding,
        anchor: anchor != null
            ? TypeHierarchyAnchor(
                ref: anchor.location.encoding,
                path: anchor.path,
              )
            : null,
      ),
    );
  }

  /// Converts a server [type_hierarchy.TypeHierarchyItem] to an LSP
  /// [TypeHierarchyItem].
  ///
  /// Reads [LineInfo]s from [session], using [lineInfoCache] as a cache.
  TypeHierarchyItem? _convertItem(
    AnalysisSession session,
    Map<String, LineInfo?> lineInfoCache,
    type_hierarchy.TypeHierarchyItem item,
  ) {
    final filePath = item.file;
    final lineInfo = lineInfoCache.putIfAbsent(filePath, () {
      final file = session.getFile(filePath);
      return file is FileResult ? file.lineInfo : null;
    });
    if (lineInfo == null) {
      return null;
    }

    return toLspItem(item, lineInfo);
  }

  /// Converts multiple server [type_hierarchy.TypeHierarchyItem] to an LSP
  /// [TypeHierarchyItem].
  ///
  /// Reads [LineInfo]s from [unit.session], caching them for items in the same
  /// file.
  List<TypeHierarchyItem> _convertItems(
    ResolvedUnitResult unit,
    List<type_hierarchy.TypeHierarchyRelatedItem> items,
  ) {
    final session = unit.session;
    final lineInfoCache = <String, LineInfo?>{
      unit.path: unit.lineInfo,
    };
    final results = convert(
      items,
      (type_hierarchy.TypeHierarchyRelatedItem item) => _convertItem(
        session,
        lineInfoCache,
        item,
      ),
    );
    return results.toList();
  }
}
