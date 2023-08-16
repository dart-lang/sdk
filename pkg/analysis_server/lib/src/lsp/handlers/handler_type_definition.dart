// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element.dart' as analyzer;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart' as analyzer;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/utilities/analyzer_converter.dart';

class TypeDefinitionHandler extends LspMessageHandler<TypeDefinitionParams,
    TextDocumentTypeDefinitionResult> with LspPluginRequestHandlerMixin {
  static const _emptyResult = TextDocumentTypeDefinitionResult.t2([]);

  TypeDefinitionHandler(super.server);

  @override
  Method get handlesMessage => Method.textDocument_typeDefinition;

  @override
  LspJsonHandler<TypeDefinitionParams> get jsonHandler =>
      TypeDefinitionParams.jsonHandler;

  @override
  // The private type in the return type is dictated by the signature of the
  // super-method and the class's super-class.
  Future<ErrorOr<TextDocumentTypeDefinitionResult>> handle(
      TypeDefinitionParams params,
      MessageInfo message,
      CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(_emptyResult);
    }

    final clientCapabilities = server.lspClientCapabilities;
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

        final SyntacticEntity originEntity;
        DartType? type;
        if (node is NamedType) {
          originEntity = node.name2;
          final element = node.element;
          if (element is InterfaceElement) {
            type = element.thisType;
          }
        } else if (node is VariableDeclaration) {
          originEntity = node.name;
          type = node.declaredElement?.type;
        } else if (node is Expression) {
          originEntity = node;
          type = _getType(node);
        } else {
          return success(_emptyResult);
        }

        analyzer.Element? element;
        if (type is InterfaceType) {
          element = type.element;
        } else if (type is TypeParameterType) {
          element = type.element;
        }
        if (element is! analyzer.ElementImpl) {
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
          return success(TextDocumentTypeDefinitionResult.t2([
            _toLocationLink(result.lineInfo, targetLineInfo, originEntity,
                element, location)
          ]));
        } else {
          return success(TextDocumentTypeDefinitionResult.t1(
            Definition.t2(_toLocation(location, targetLineInfo)),
          ));
        }
      });
    });
  }

  /// Creates an LSP [Location] for the server [location].
  Location _toLocation(plugin.Location location, LineInfo lineInfo) {
    return Location(
      uri: pathContext.toUri(location.file),
      range: toRange(lineInfo, location.offset, location.length),
    );
  }

  /// Creates an LSP [LocationLink] for the server [targetLocation].
  ///
  /// Uses [originLineInfo] and [originEntity] to compute `originSelectionRange`
  /// and [targetLineInfo] and [targetElement] for code ranges.
  LocationLink _toLocationLink(
    LineInfo originLineInfo,
    LineInfo targetLineInfo,
    SyntacticEntity originEntity,
    analyzer.ElementImpl targetElement,
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
          toRange(originLineInfo, originEntity.offset, originEntity.length),
      targetUri: pathContext.toUri(targetLocation.file),
      targetRange: codeRange,
      targetSelectionRange: nameRange,
    );
  }

  /// Returns the [DartType] most appropriate for navigating to from [node] when
  /// invoking Go to Type Definition.
  static DartType? _getType(Expression node) {
    if (node is SimpleIdentifier) {
      final element = node.staticElement;
      if (element is InterfaceElement) {
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
