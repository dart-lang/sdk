// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/utilities/extensions/results.dart';

class ImportsHandler
    extends SharedMessageHandler<TextDocumentPositionParams, List<Location>?> {
  ImportsHandler(super.server);

  @override
  Method get handlesMessage => CustomMethods.imports;

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<List<Location>?>> handle(
    TextDocumentPositionParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    var pos = params.position;
    var path = pathOfDoc(params.textDocument);
    var library = await path.mapResult(requireResolvedLibrary);
    var unit = (path, library).mapResultsSync<ResolvedUnitResult>((
      path,
      library,
    ) {
      var unit = library.unitWithPath(path);
      return unit != null
          ? success(unit)
          : error(
            ErrorCodes.InternalError,
            'The library containing a path did not contain the path.',
          );
    });
    var offset = unit.mapResultSync(
      (unit) => toOffset(unit.unit.lineInfo, pos),
    );

    return (library, unit, offset).mapResults((library, unit, offset) async {
      var node = unit.unit.nodeCovering(offset: offset);
      if (node == null) {
        return success(null);
      }

      var element = ElementLocator.locate(node);
      if (element == null) {
        return success(null);
      }

      String? prefixName;
      if (node is NamedType) {
        prefixName = node.importPrefix?.name.lexeme;
      } else if (node.thisOrAncestorOfType<PrefixedIdentifier>()
          case PrefixedIdentifier(:var prefix)
          when prefix != node && prefix.element is PrefixElement) {
        prefixName = prefix.name;
      } else if (node is SimpleIdentifier) {
        if (node.parent case MethodInvocation(
          target: SimpleIdentifier target?,
        ) when target.element is PrefixElement) {
          prefixName = target.name;
        }
      }

      var enclosingElement = element.enclosingElement;
      if (enclosingElement is ExtensionElement) {
        element = enclosingElement;
      }

      var locations = _getImportLocations(library, unit, element, prefixName);

      return success(nullIfEmpty(locations));
    });
  }

  /// Returns [Location]s for imports that import the given [element] into
  /// [unitResult].
  List<Location> _getImportLocations(
    ResolvedLibraryResult libraryResult,
    ResolvedUnitResult? unitResult,
    Element element,
    String? prefix,
  ) {
    var elementName = element.name;
    if (elementName == null) {
      return [];
    }

    // Search in each unit up the chain for related imports.
    while (unitResult is ResolvedUnitResult) {
      var results = _getImportsInUnit(
        unitResult.unit,
        element,
        prefix: prefix,
        elementName: elementName,
      );

      // Stop searching in the unit where we find any matching imports.
      if (results.isNotEmpty) {
        return results;
      }

      // Otherwise, we continue up the chain.
      unitResult = libraryResult.parentUnitOf(unitResult);
    }

    return [];
  }

  /// Gets the locations of all imports that provide [element] with [prefix] in
  /// [unit].
  List<Location> _getImportsInUnit(
    CompilationUnit unit,
    Element element, {
    required String? prefix,
    required String elementName,
  }) {
    var results = <Location>[];
    for (var directive in unit.directives.whereType<ImportDirective>()) {
      var import = directive.libraryImport;
      if (import == null) continue;
      var importPrefix = directive.prefix?.name;
      if (importPrefix != prefix) continue;

      var importedElement =
          prefix == null
              ? import.namespace.get2(elementName)
              : import.namespace.getPrefixed2(prefix, elementName);

      var isMatch =
          element is MultiplyDefinedElement
              ? element.conflictingElements.contains(importedElement)
              : element == importedElement;

      if (isMatch) {
        var uri = uriConverter.toClientUri(
          unit.declaredFragment!.source.fullName,
        );
        var lineInfo = unit.lineInfo;
        var range = toRange(lineInfo, directive.offset, directive.length);
        results.add(Location(uri: uri, range: range));
      }
    }
    return results;
  }
}
