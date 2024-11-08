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
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';

typedef _ImportRecord = ({CompilationUnit unit, ImportDirective directive});

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
      var node = NodeLocator(offset).searchWithin(unit.unit);
      if (node == null) {
        return success(null);
      }

      var element = ElementLocator.locate2(node);
      if (element == null) {
        return success(null);
      }

      String? prefix;
      if (node is NamedType) {
        prefix = node.importPrefix?.name.lexeme;
      } else if (node.thisOrAncestorOfType<PrefixedIdentifier>()
          case PrefixedIdentifier identifier) {
        prefix = identifier.prefix.name;
      } else if (node is SimpleIdentifier) {
        if (node.parent case MethodInvocation(
          target: SimpleIdentifier target?,
        )) {
          prefix = target.toString();
        }
      }

      var enclosingElement = element.enclosingElement2;
      if (enclosingElement is ExtensionElement2) {
        element = enclosingElement;
      }

      var locations = _getImportLocations(element, library, unit, prefix);

      return success(nullIfEmpty(locations));
    });
  }

  /// Returns [Location]s for imports that import the given [element] into
  /// [unit].
  List<Location> _getImportLocations(
    Element2 element,
    ResolvedLibraryResult libraryResult,
    ResolvedUnitResult unit,
    String? prefix,
  ) {
    var elementName = element.name3;
    if (elementName == null) {
      return [];
    }

    var imports = _getImports(libraryResult);
    var results = <Location>[];

    for (var (:unit, :directive) in imports) {
      var import = directive.libraryImport;
      if (import == null) continue;

      var importedElement =
          prefix == null
              ? import.namespace.get2(elementName)
              : import.namespace.getPrefixed2(prefix, elementName);

      var isMatch =
          element is MultiplyDefinedElement2
              ? element.conflictingElements2.contains(importedElement)
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

  List<_ImportRecord> _getImports(ResolvedLibraryResult libraryResult) {
    var imports = <_ImportRecord>[];

    // TODO(dantup): With enhanced parts, we may need to look at more than
    //  just the first fragment.
    var unit = libraryResult.units.first.unit;
    for (var directive in unit.directives.whereType<ImportDirective>()) {
      imports.add((unit: unit, directive: directive));
    }

    return imports;
  }
}
