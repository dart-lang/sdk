// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/src/computer/computer_documentation.dart';
import 'package:analysis_server/src/lsp/dartdoc.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';

/// A computer for the signature help information about the type parameters for
/// the [TypeArgumentList] surrounding the specified offset of a Dart
/// [CompilationUnit].
class DartTypeArgumentsSignatureComputer {
  final AstNode? _node;
  final Set<lsp.MarkupKind>? preferredFormats;
  late TypeArgumentList _argumentList;
  final DocumentationPreference documentationPreference;
  final DartDocumentationComputer _documentationComputer;

  DartTypeArgumentsSignatureComputer(
    DartdocDirectiveInfo dartdocInfo,
    CompilationUnit unit,
    int offset,
    this.preferredFormats, {
    this.documentationPreference = DocumentationPreference.full,
  })  : _documentationComputer = DartDocumentationComputer(dartdocInfo),
        _node = NodeLocator(offset).searchWithin(unit);

  /// The [TypeArgumentList] node located by [compute].
  TypeArgumentList get argumentList => _argumentList;

  bool get offsetIsValid => _node != null;

  /// Returns the computed signature information, maybe `null`.
  lsp.SignatureHelp? compute() {
    var argumentList = _findTypeArgumentList();
    if (argumentList == null) {
      return null;
    }
    var parent = argumentList.parent;
    Element2? element;
    if (parent is NamedType) {
      element = parent.element2;
    } else if (parent is MethodInvocation) {
      element = ElementLocator.locate2(parent.methodName);
    }
    if (element is! TypeParameterizedElement2 ||
        element.typeParameters2.isEmpty) {
      return null;
    }

    _argumentList = argumentList;

    var label = element.displayString2();
    var documentation = _documentationComputer.computePreferred2(
        element, documentationPreference);

    return _toSignatureHelp(
      label,
      cleanDartdoc(documentation),
      element.typeParameters2,
    );
  }

  /// Return the closest type argument list surrounding the [_node].
  TypeArgumentList? _findTypeArgumentList() {
    var node = _node;
    while (node != null && node is! TypeArgumentList) {
      // Certain nodes don't make sense to search above for an argument list
      // (for example when inside a function expression).
      if (node is FunctionExpression) {
        return null;
      }
      node = node.parent;
    }
    return node as TypeArgumentList?;
  }

  /// Builds an [lsp.SignatureHelp] for the given type parameters.
  lsp.SignatureHelp? _toSignatureHelp(
    String label,
    String? documentation,
    List<TypeParameterElement2> typeParameters,
  ) {
    var parameters = typeParameters
        .map((param) => lsp.ParameterInformation(
              label: param.displayString2(),
            ))
        .toList();

    var signatures = [
      lsp.SignatureInformation(
        label: label,
        documentation: documentation != null
            ? asMarkupContentOrString(preferredFormats, documentation)
            : null,
        parameters: parameters,
      ),
    ];

    return lsp.SignatureHelp(
      signatures: signatures,
      activeSignature: 0,
      // As with [toSignatureHelp], we don't currently use this, but need to set
      // it to something that doesn't match a parameter to avoid one being
      // selected.
      activeParameter: -1,
    );
  }
}
