// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart' show ElementImpl;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/utilities/analyzer_converter.dart';

typedef _LocationsOrLinks = Either2<List<Location>, List<LocationLink>>;

class TypeDefinitionHandler
    extends MessageHandler<TypeDefinitionParams, _LocationsOrLinks>
    with LspPluginRequestHandlerMixin {
  static const _emptyResult = _LocationsOrLinks.t1([]);

  TypeDefinitionHandler(LspAnalysisServer server) : super(server);

  @override
  Method get handlesMessage => Method.textDocument_typeDefinition;

  @override
  LspJsonHandler<TypeDefinitionParams> get jsonHandler =>
      TypeDefinitionParams.jsonHandler;

  @override
  Future<ErrorOr<_LocationsOrLinks>> handle(
      TypeDefinitionParams params, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(_emptyResult);
    }

    final clientCapabilities = server.clientCapabilities;
    if (clientCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return serverNotInitializedError;
    }

    /// Whether the client supports `LocationLink` results instead of the
    /// original `Location`. `LocationLink`s can include an additional `Range`
    /// to distinguish between codeRange and nameRange (selectionRange), and
    /// also an `originSelectionRange` that tells the client which range the
    /// result is valid for.
    final supportsLocationLink = clientCapabilities.typeDefinitionLocationLink;
    final pos = params.position;
    final path = pathOfDoc(params.textDocument);

    return path.mapResult((path) async {
      final result = await server.getResolvedUnit(path);
      if (result == null) {
        return success(_emptyResult);
      }

      final offset = toOffset(result.lineInfo, pos);
      return offset.mapResult((offset) async {
        final node = NodeLocator(offset).searchWithin(result.unit);
        if (node == null) {
          return success(_emptyResult);
        }

        final type = node is Expression ? _getType(node) : null;
        final element = type?.element;
        if (element is! ElementImpl) {
          return success(_emptyResult);
        }

        // Obtain a `LineInfo` for the targets file to map offsets.
        final targetUnitElement =
            element.thisOrAncestorOfType<CompilationUnitElement>();
        final targetLineInfo = targetUnitElement?.lineInfo;
        if (targetLineInfo == null) {
          return success(_emptyResult);
        }

        final converter = AnalyzerConverter();
        final location = converter.locationFromElement(element);
        if (location == null) {
          return success(_emptyResult);
        }

        if (supportsLocationLink) {
          return success(_LocationsOrLinks.t2([
            _toLocationLink(
                result.lineInfo, targetLineInfo, node, element, location)
          ]));
        } else {
          return success(
              _LocationsOrLinks.t1([_toLocation(location, targetLineInfo)]));
        }
      });
    });
  }

  /// Creates an LSP [Location] for the server [location].
  Location _toLocation(plugin.Location location, LineInfo lineInfo) {
    return Location(
      uri: Uri.file(location.file).toString(),
      range: toRange(lineInfo, location.offset, location.length),
    );
  }

  /// Creates an LSP [LocationLink] for the server [targetLocation].
  ///
  /// Uses [originLineInfo] and [originNode] to compute `originSelectionRange`
  /// and [targetLineInfo] and [targetElement] for code ranges.
  LocationLink _toLocationLink(
    LineInfo originLineInfo,
    LineInfo targetLineInfo,
    AstNode originNode,
    ElementImpl targetElement,
    plugin.Location targetLocation,
  ) {
    final nameRange =
        toRange(targetLineInfo, targetLocation.offset, targetLocation.length);

    final codeOffset = targetElement.codeOffset;
    final codeLength = targetElement.codeLength;
    final codeRange = codeOffset != null && codeLength != null
        ? toRange(targetLineInfo, codeOffset, codeLength)
        : nameRange;

    return LocationLink(
      originSelectionRange:
          toRange(originLineInfo, originNode.offset, originNode.length),
      targetUri: Uri.file(targetLocation.file).toString(),
      targetRange: codeRange,
      targetSelectionRange: nameRange,
    );
  }

  /// Returns the [DartType] most appropriate for navigating to from [node] when
  /// invoking Go to Type Definition.
  static DartType? _getType(Expression node) {
    if (node is SimpleIdentifier) {
      final element = node.staticElement;
      if (element is ClassElement) {
        return element.thisType;
      } else if (element is VariableElement) {
        if (node.inDeclarationContext()) {
          return element.type;
        }
        final parent = node.parent?.parent;
        if (parent is NamedExpression && parent.name.label == node) {
          return element.type;
        }
      } else if (node.inSetterContext()) {
        final writeElement = node.writeElement;
        if (writeElement is PropertyAccessorElement) {
          return writeElement.variable.type;
        }
      }
    }

    return node.staticType;
  }
}
