// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart' as analyzer;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';

typedef StaticOptions =
    Either3<bool, TypeDefinitionOptions, TypeDefinitionRegistrationOptions>;

class TypeDefinitionHandler
    extends
        SharedMessageHandler<
          TypeDefinitionParams,
          TextDocumentTypeDefinitionResult
        >
    with LspPluginRequestHandlerMixin {
  static const _emptyResult = TextDocumentTypeDefinitionResult.t2([]);

  TypeDefinitionHandler(super.server);

  @override
  Method get handlesMessage => Method.textDocument_typeDefinition;

  @override
  LspJsonHandler<TypeDefinitionParams> get jsonHandler =>
      TypeDefinitionParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  // The private type in the return type is dictated by the signature of the
  // super-method and the class's super-class.
  Future<ErrorOr<TextDocumentTypeDefinitionResult>> handle(
    TypeDefinitionParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    if (!isDartDocument(params.textDocument)) {
      return success(_emptyResult);
    }

    var clientCapabilities = message.clientCapabilities;
    if (clientCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return serverNotInitializedError;
    }

    /// Whether the client supports `LocationLink` results instead of the
    /// original `Location`. `LocationLink`s can include an additional `Range`
    /// to distinguish between codeRange and nameRange (selectionRange), and
    /// also an `originSelectionRange` that tells the client which range the
    /// result is valid for.
    var supportsLocationLink = clientCapabilities.typeDefinitionLocationLink;
    var pos = params.position;
    var path = pathOfDoc(params.textDocument);

    return path.mapResult((path) async {
      var result = await server.getResolvedUnit(path);
      if (result == null) {
        return success(_emptyResult);
      }

      var offset = toOffset(result.lineInfo, pos);
      return offset.mapResult((offset) async {
        var node = result.unit.nodeCovering(offset: offset);
        if (node == null) {
          return success(_emptyResult);
        }

        SyntacticEntity? originEntity;
        DartType? type;
        if (node is NamedType) {
          originEntity = node.name;
          var element = node.element;
          if (element case analyzer.InterfaceElement element) {
            type = element.thisType;
          }
        } else if (node is VariableDeclaration) {
          originEntity = node.name;
          type = node.declaredFragment?.element.type;
        } else if (node is DeclaredIdentifier) {
          originEntity = node.name;
          type = node.declaredFragment?.element.type;
        } else if (node is Expression) {
          originEntity = node;
          type = _getType(node);
        } else if (node is FormalParameter) {
          originEntity = node.name;
          type = node.declaredFragment?.element.type;
        }
        if (originEntity == null) {
          return success(_emptyResult);
        }

        analyzer.Element? element;
        if (type is InterfaceType) {
          element = type.element;
        } else if (type is TypeParameterType) {
          element = type.element;
        }
        if (element is! analyzer.Element) {
          return success(_emptyResult);
        }

        // TODO(dantup): Consider returning all fragments for the type instead
        //  of only the first.
        var targetFragment = element.nonSynthetic.firstFragment;
        var targetUnit = targetFragment.libraryFragment;
        if (targetUnit == null) {
          return success(_emptyResult);
        }

        var nameOffset = targetFragment.nameOffset;
        var nameLength = targetFragment.name?.length;
        if (nameOffset == null || nameLength == null) {
          return success(_emptyResult);
        }

        var nameRange = toRange(targetUnit.lineInfo, nameOffset, nameLength);
        if (supportsLocationLink) {
          return success(
            TextDocumentTypeDefinitionResult.t2([
              _toLocationLink(
                originEntity,
                result.lineInfo,
                targetFragment,
                nameRange,
                targetUnit,
              ),
            ]),
          );
        } else {
          return success(
            TextDocumentTypeDefinitionResult.t1(
              Definition.t2(_toLocation(targetFragment, nameRange, targetUnit)),
            ),
          );
        }
      });
    });
  }

  /// Creates an LSP [Location] for navigating to [targetFragment].
  Location _toLocation(
    analyzer.Fragment targetFragment,
    Range targetNameRange,
    analyzer.LibraryFragment targetUnit,
  ) {
    return Location(
      uri: uriConverter.toClientUri(targetUnit.source.fullName),
      range: targetNameRange,
    );
  }

  /// Creates an LSP [LocationLink] for navigating to [targetFragment].
  ///
  /// Uses [originLineInfo] and [originEntity] to compute `originSelectionRange`
  /// and [targetFragment] and [targetUnit] for code ranges.
  LocationLink _toLocationLink(
    SyntacticEntity originEntity,
    LineInfo originLineInfo,
    analyzer.Fragment targetFragment,
    Range targetNameRange,
    analyzer.LibraryFragment targetUnit,
  ) {
    var (codeOffset, codeLength) = switch (targetFragment) {
      FragmentImpl e => (e.codeOffset, e.codeLength),
      _ => (null, null),
    };

    var codeRange =
        codeOffset != null && codeLength != null
            ? toRange(targetUnit.lineInfo, codeOffset, codeLength)
            : targetNameRange;

    return LocationLink(
      originSelectionRange: toRange(
        originLineInfo,
        originEntity.offset,
        originEntity.length,
      ),
      targetUri: uriConverter.toClientUri(targetUnit.source.fullName),
      targetRange: codeRange,
      targetSelectionRange: targetNameRange,
    );
  }

  /// Returns the [DartType] most appropriate for navigating to from [node] when
  /// invoking Go to Type Definition.
  static DartType? _getType(Expression node) {
    if (node is SimpleIdentifier) {
      var element = node.element;
      if (element case analyzer.InterfaceElement element) {
        return element.thisType;
      } else if (element case analyzer.VariableElement element) {
        if (node.inDeclarationContext()) {
          return element.type;
        }
        var parent = node.parent?.parent;
        if (parent is NamedExpression && parent.name.label == node) {
          return element.type;
        }
      } else if (node.inSetterContext()) {
        var writeElement = node.writeOrReadElement;
        if (writeElement
            case analyzer.GetterElement(:var variable) ||
                analyzer.SetterElement(:var variable)) {
          return variable?.type;
        }
      }
    }

    return node.staticType;
  }
}

class TypeDefinitionRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<StaticOptions> {
  TypeDefinitionRegistrations(super.info);

  @override
  ToJsonable? get options => TextDocumentRegistrationOptions(
    documentSelector: dartFiles, // This is currently Dart-specific
  );

  @override
  Method get registrationMethod => Method.textDocument_typeDefinition;

  @override
  StaticOptions get staticOptions => Either3.t1(true);

  @override
  bool get supportsDynamic => clientDynamic.typeDefinition;
}
