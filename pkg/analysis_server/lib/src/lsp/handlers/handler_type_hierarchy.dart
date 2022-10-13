// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/computer/computer_lazy_type_hierarchy.dart'
    as type_hierarchy;
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart';

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
class PrepareTypeHierarchyHandler extends MessageHandler<
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

    final clientCapabilities = server.clientCapabilities;
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

class TypeHierarchySubtypesHandler extends MessageHandler<
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
    final path = pathOfUri(item.uri);
    final unit = await path.mapResult(requireResolvedUnit);
    final computer = type_hierarchy.DartLazyTypeHierarchyComputer(unit.result);

    // Convert the clients item back to one in the servers format so that we
    // can use it to get sub/super types.
    final target = toServerItem(item, unit.result.lineInfo);

    if (target == null) {
      return error(
        ErrorCodes.ContentModified,
        'Content was modified since Type Hierarchy node was produced',
      );
    }

    final calls = await computer.findSubtypes(target, server.searchEngine);
    final results = calls != null ? _convertItems(unit.result, calls) : null;
    return success(results);
  }
}

class TypeHierarchySupertypesHandler extends MessageHandler<
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
    final path = pathOfUri(item.uri);
    final unit = await path.mapResult(requireResolvedUnit);
    final computer = type_hierarchy.DartLazyTypeHierarchyComputer(unit.result);

    // Convert the clients item back to one in the servers format so that we
    // can use it to get sub/super types.
    final target = toServerItem(item, unit.result.lineInfo);

    if (target == null) {
      return error(
        ErrorCodes.ContentModified,
        'Content was modified since Type Hierarchy node was produced',
      );
    }

    final calls = await computer.findSupertypes(target);
    final results = calls != null ? _convertItems(unit.result, calls) : null;
    return success(results);
  }
}

/// Utility methods used by all Type Hierarchy handlers.
mixin _TypeHierarchyUtils {
  /// Converts a server [SourceRange] to an LSP [Range].
  Range sourceRangeToRange(LineInfo lineInfo, SourceRange range) =>
      toRange(lineInfo, range.offset, range.length);

  /// Converts a server [type_hierarchy.TypeHierarchyItem] to an LSP
  /// [TypeHierarchyItem].
  TypeHierarchyItem toLspItem(
    type_hierarchy.TypeHierarchyItem item,
    LineInfo lineInfo,
  ) {
    return TypeHierarchyItem(
      name: item.displayName,
      detail: _detailFor(item),
      kind: SymbolKind.Class,
      uri: Uri.file(item.file),
      range: sourceRangeToRange(lineInfo, item.codeRange),
      selectionRange: sourceRangeToRange(lineInfo, item.nameRange),
    );
  }

  /// Converts an LSP [TypeHierarchyItem] supplied by the client back to a
  /// server [type_hierarchy.TypeHierarchyItem] to use to look up items.
  ///
  /// Returns `null` if the supplied item is no longer valid (for example its
  /// ranges are no longer valid in the current state of the document).
  type_hierarchy.TypeHierarchyItem? toServerItem(
    TypeHierarchyItem item,
    LineInfo lineInfo,
  ) {
    final nameRange = toSourceRange(lineInfo, item.selectionRange);
    final codeRange = toSourceRange(lineInfo, item.range);
    if (nameRange.isError || codeRange.isError) {
      return null;
    }

    return type_hierarchy.TypeHierarchyItem(
      displayName: item.name,
      file: item.uri.toFilePath(),
      nameRange: nameRange.result,
      codeRange: codeRange.result,
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

  /// Gets the "detail" label for [item].
  ///
  /// This includes a user-visible description of the relationship between the
  /// target item and [item].
  String? _detailFor(type_hierarchy.TypeHierarchyItem item) {
    if (item is! type_hierarchy.TypeHierarchyRelatedItem) {
      return null;
    }

    switch (item.relationship) {
      case type_hierarchy.TypeHierarchyItemRelationship.extends_:
        return 'extends';
      case type_hierarchy.TypeHierarchyItemRelationship.implements:
        return 'implements';
      case type_hierarchy.TypeHierarchyItemRelationship.mixesIn:
        return 'mixes in';
      case type_hierarchy.TypeHierarchyItemRelationship.constrainedTo:
        return 'constrained to';
      default:
        return null;
    }
  }
}
