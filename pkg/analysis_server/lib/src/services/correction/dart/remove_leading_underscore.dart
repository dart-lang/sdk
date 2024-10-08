// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveLeadingUnderscore extends ResolvedCorrectionProducer {
  RemoveLeadingUnderscore({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_LEADING_UNDERSCORE;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_LEADING_UNDERSCORE_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    Token? nameToken;
    Element2? element;
    if (node is SimpleIdentifier) {
      nameToken = node.token;
      element = node.element;
    } else if (node is FormalParameter) {
      nameToken = node.name;
      element = node.declaredFragment?.element;
    } else if (node is VariableDeclaration) {
      nameToken = node.name;
      element = node.declaredElement2 ?? node.declaredFragment?.element;
    } else if (node is DeclaredVariablePattern) {
      nameToken = node.name;
      element = node.declaredElement2;
    } else if (node is FunctionDeclaration) {
      nameToken = node.name;
      element = node.declaredElement2 ?? node.declaredFragment?.element;
    } else {
      return;
    }

    if (nameToken == null || element == null) {
      return;
    }

    var oldName = nameToken.lexeme;
    if (oldName.length < 2) {
      return;
    }

    var newName = oldName.substring(1);

    // Find references to the identifier.
    List<AstNode>? references;
    if (element is LocalVariableElement2 || element is LocalFunctionElement) {
      var block = node.thisOrAncestorOfType<Block>();
      if (block != null) {
        references = findLocalElementReferences3(block, element);

        var declaration = block.thisOrAncestorOfType<MethodDeclaration>() ??
            block.thisOrAncestorOfType<FunctionDeclaration>();

        if (declaration != null) {
          if (isDeclaredIn(declaration, newName)) {
            var suffix = -1;
            do {
              suffix++;
            } while (isDeclaredIn(declaration, '$newName$suffix'));
            newName = '$newName$suffix';
          }
        }
      }
    } else if (element is FormalParameterElement) {
      if (!element.isNamed) {
        var root = node
            .thisOrAncestorMatching((node) =>
                node.parent is FunctionDeclaration ||
                node.parent is MethodDeclaration ||
                node.parent is ConstructorDeclaration)
            ?.parent;
        if (root != null) {
          references = findLocalElementReferences3(root, element);
        }
      }
    } else if (element is PrefixElement2) {
      var root = node.thisOrAncestorOfType<CompilationUnit>();
      if (root != null) {
        references = findPrefixElementReferences2(root, element);
      }
    }
    if (references == null) {
      return;
    }

    // Compute the change.
    var sourceRanges = {
      range.token(nameToken),
      ...references.map(range.node),
    };
    await builder.addDartFileEdit(file, (builder) {
      for (var sourceRange in sourceRanges) {
        builder.addSimpleReplacement(sourceRange, newName);
      }
    });
  }
}
