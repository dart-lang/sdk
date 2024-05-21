// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/extensions/string.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RenameToCamelCase extends ResolvedCorrectionProducer {
  /// The camel-case version of the name.
  String _newName = '';

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  List<String> get fixArguments => [_newName];

  @override
  FixKind get fixKind => DartFixKind.RENAME_TO_CAMEL_CASE;

  @override
  FixKind get multiFixKind => DartFixKind.RENAME_TO_CAMEL_CASE_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    Token? nameToken;
    Element? element;
    var node = this.node;
    if (node is SimpleFormalParameter) {
      nameToken = node.name;
      element = node.declaredElement;
    } else if (node is VariableDeclaration) {
      nameToken = node.name;
      element = node.declaredElement;
    } else if (node is RecordTypeAnnotationField) {
      // RecordTypeAnnotationFields do not have Elements.
      nameToken = node.name;
      var newName = nameToken?.lexeme.toLowerCamelCase;
      if (newName == null) {
        return;
      }
      _newName = newName;
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.token(nameToken!), _newName);
      });
      return;
    }

    if (nameToken == null) {
      return;
    }

    // Prepare the new name.
    var newName = nameToken.lexeme.toLowerCamelCase;
    if (newName == null) {
      return;
    }
    _newName = newName;
    if (element == null) {
      return;
    }

    // Find references to the identifier.
    List<SimpleIdentifier>? references;
    if (element is LocalVariableElement) {
      var root = node.thisOrAncestorOfType<Block>();
      if (root != null) {
        references = findLocalElementReferences(root, element);
      }
    } else if (element is ParameterElement) {
      if (!element.isNamed) {
        var root = node
            .thisOrAncestorMatching((node) =>
                node.parent is FunctionDeclaration ||
                node.parent is MethodDeclaration)
            ?.parent;
        if (root != null) {
          references = findLocalElementReferences(root, element);
        }
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
        builder.addSimpleReplacement(sourceRange, _newName);
      }
    });
  }
}
