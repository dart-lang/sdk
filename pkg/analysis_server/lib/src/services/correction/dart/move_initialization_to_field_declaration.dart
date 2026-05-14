// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class MoveInitializationToFieldDeclaration extends ResolvedCorrectionProducer {
  MoveInitializationToFieldDeclaration({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.moveInitializationToFieldDeclaration;

  @override
  FixKind get multiFixKind =>
      DartFixKind.moveInitializationToFieldDeclarationMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! SimpleIdentifier) {
      return;
    }
    var initializer = node.parent;
    if (initializer is! ConstructorFieldInitializer) {
      return;
    }
    var field = node.element;
    if (field is! FieldElement) {
      return;
    }
    var constructorDeclaration = initializer.parent;
    if (constructorDeclaration is! ClassMember) {
      return;
    }
    var initializers = switch (constructorDeclaration) {
      ConstructorDeclaration() => constructorDeclaration.initializers,
      PrimaryConstructorBody() => constructorDeclaration.initializers,
      _ => null,
    };
    if (initializers == null) {
      return;
    }
    var fieldDeclaration = findFieldDeclaration(field, constructorDeclaration);
    if (fieldDeclaration == null ||
        fieldDeclaration.equals != null ||
        fieldDeclaration.initializer != null) {
      return;
    }
    var expression = utils.getRangeText(initializer.expression.sourceRange);

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.nodeInList(initializers, initializer));
      builder.addSimpleInsertion(fieldDeclaration.end, ' = $expression');
    });
  }

  /// Returns the declaration of the [field].
  ///
  /// Uses the [initializer] to find the container containing the field's
  /// declaration.
  ///
  /// Returns `null` if the declaration can't be found.
  VariableDeclaration? findFieldDeclaration(
    FieldElement field,
    ClassMember constructorDeclaration,
  ) {
    // TODO(brianwilkerson): When support for augmentations is added, this will
    //  need to look at all of the fragments of the container in order to find
    //  the declaration.
    var container = constructorDeclaration.parent;
    var members = switch (container) {
      ClassBody() => container.members,
      EnumBody() => container.members,
      _ => null,
    };
    if (members == null) return null;
    for (var member in members) {
      if (member is FieldDeclaration) {
        for (var fieldDeclarartion in member.fields.variables) {
          if (fieldDeclarartion.declaredFieldElement == field) {
            return fieldDeclarartion;
          }
        }
      }
    }
    return null;
  }
}
