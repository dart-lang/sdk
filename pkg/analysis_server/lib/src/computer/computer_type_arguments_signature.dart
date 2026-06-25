// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/src/computer/computer_documentation.dart';
import 'package:analysis_server/src/lsp/dartdoc.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';

/// A computer for the signature help information about the type parameters for
/// the [TypeArgumentList] surrounding the specified offset of a Dart
/// [CompilationUnit].
class DartTypeArgumentsSignatureComputer {
  final AstNode? _node;
  final Set<lsp.MarkupKind>? preferredFormats;
  final bool clientSupportsNullActiveParameter;
  late TypeArgumentList _argumentList;
  final DartDocumentationComputer _documentationComputer;

  new(
    DartdocDirectiveInfo dartdocInfo,
    CompilationUnit unit,
    int offset, {
    required this.preferredFormats,
    required this.clientSupportsNullActiveParameter,
  }) : _documentationComputer = DartDocumentationComputer(dartdocInfo),
       _node = unit.nodeCovering(offset: offset);

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
    Element? element;
    if (parent is NamedType) {
      element = parent.element;
    } else if (parent is MethodInvocation) {
      element = ElementLocator.locate(parent.methodName);
    }
    if (element is! TypeParameterizedElement ||
        element.typeParameters.isEmpty) {
      return null;
    }

    _argumentList = argumentList;

    var label = element.displayString();
    var documentation = _documentationComputer.compute(element)?.full;

    return _toSignatureHelp(
      label,
      cleanDartdoc(documentation),
      element.typeParameters,
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
    List<TypeParameterElement> typeParameters,
  ) {
    var parameters = typeParameters
        .map((param) => lsp.ParameterInformation(label: param.displayString()))
        .toList();

    var signature = lsp.SignatureInformation(
      label: label,
      documentation: documentation != null
          ? asMarkupContentOrString(preferredFormats, documentation)
          : null,
      parameters: parameters,
    );

    return lsp.SignatureHelp(
      signatures: [signature],
      activeSignature: 0,
      // We don't currently support active type parameter so just return
      // a null value.
      activeParameter:
          // If the client doesn't support `null`, we still must provide an
          // unsigned integer. The LSP spec allows us to send an out-of-bounds
          // value so send the first out-of-bound value (`.length`). The spec
          // says this may be treated as 0, however VS Code will not highlight
          // any parameter in this case (which is preferred and hopefully other
          // clients may copy).
          clientSupportsNullActiveParameter
          ? null
          : (signature.parameters?.length ?? 0),
    );
  }
}
