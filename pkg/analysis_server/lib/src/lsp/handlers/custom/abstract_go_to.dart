// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:meta/meta.dart';

/// A common base for commands that accept a position in a document and return
/// a location to navigate to a particular kind of related element, such as
/// Super, Augmentation Target or Augmentation.
abstract class AbstractGoToHandler
    extends
        SharedMessageHandler<
          TextDocumentPositionParams,
          Either2<Location, List<Location>>?
        > {
  AbstractGoToHandler(super.server);

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  Location? elementToLocation(Element? element) {
    var targetElement = element?.nonSynthetic;
    if (targetElement == null) {
      return null;
    }
    var sourcePath = targetElement.declaration?.source?.fullName;
    if (sourcePath == null) {
      return null;
    }

    // TODO(FMorschel): Remove this when migrating to the new element model.
    var locationLineInfo = server.getLineInfo(sourcePath);
    if (locationLineInfo == null) {
      return null;
    }

    return Location(
      uri: uriConverter.toClientUri(sourcePath),
      range: toRange(
        locationLineInfo,
        targetElement.nameOffset,
        targetElement.nameLength,
      ),
    );
  }

  @protected
  Either2<Location?, List<Location>> findRelatedLocations(
    Element element,
    ResolvedLibraryResult libraryResult,
    ResolvedUnitResult unit,
    String? prefix,
  );

  @override
  Future<ErrorOr<Either2<Location, List<Location>>?>> handle(
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

      String? prefix;
      if (node is NamedType) {
        prefix = node.importPrefix?.name.lexeme;
      } else if (node?.thisOrAncestorOfType<PrefixedIdentifier>()
          case PrefixedIdentifier identifier) {
        prefix = identifier.prefix.name;
      } else if (node is SimpleIdentifier) {
        if (node.parent case MethodInvocation(
          :var target,
        ) when target is SimpleIdentifier?) {
          prefix = target?.toString();
        }
      }

      var enclosingElement = element.enclosingElement3;
      if (enclosingElement is ExtensionElement) {
        element = enclosingElement;
      }
      var relatedElements = findRelatedLocations(
        element,
        library,
        unit,
        prefix,
      );

      return success(
        relatedElements.map(
          (location) {
            if (location == null) {
              return null;
            }
            return Either2.t1(location);
          },
          (locations) {
            if (locations.isEmpty) {
              return null;
            }
            return Either2.t2(locations);
          },
        ),
      );
    });
  }
}
