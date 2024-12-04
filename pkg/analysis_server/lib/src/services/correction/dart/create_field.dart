// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/create_getter.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class CreateField extends CreateFieldOrGetter {
  /// The name of the field to be created.
  String _fieldName = '';

  CreateField({required super.context});

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  @override
  List<String> get fixArguments => [_fieldName];

  @override
  FixKind get fixKind => DartFixKind.CREATE_FIELD;

  @override
  Future<void> addForObjectPattern({
    required ChangeBuilder builder,
    required InterfaceElement2? targetElement,
    required String fieldName,
    required DartType? fieldType,
  }) async {
    _fieldName = fieldName;

    await _addDeclaration(
      builder: builder,
      staticModifier: false,
      targetElement: targetElement,
      fieldType: fieldType,
    );
  }

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (await compute0(builder)) {
      return;
    }

    var parameter = node.thisOrAncestorOfType<FieldFormalParameter>();
    if (parameter != null) {
      await _proposeFromFieldFormalParameter(builder, parameter);
    } else {
      await _proposeFromIdentifier(builder);
    }
  }

  Future<void> _addDeclaration({
    required ChangeBuilder builder,
    required bool staticModifier,
    required InterfaceElement2? targetElement,
    required DartType? fieldType,
  }) async {
    if (targetElement == null) {
      return;
    }
    if (targetElement.library2.isInSdk) {
      return;
    }
    // Prepare target `ClassDeclaration`.
    var targetFragment = targetElement.firstFragment;
    var targetDeclarationResult = await sessionHelper.getElementDeclaration2(
      targetFragment,
    );
    if (targetDeclarationResult == null) {
      return;
    }
    var targetNode = targetDeclarationResult.node;
    if (targetNode is! CompilationUnitMember) {
      return;
    }
    if (!(targetNode is ClassDeclaration ||
        targetNode is EnumDeclaration ||
        targetNode is MixinDeclaration)) {
      return;
    }
    // Build field source.
    var targetSource = targetFragment.libraryFragment.source;
    var targetFile = targetSource.fullName;
    await builder.addDartFileEdit(targetFile, (builder) {
      builder.insertField(targetNode, (builder) {
        builder.writeFieldDeclaration(
          _fieldName,
          isFinal: targetNode is EnumDeclaration,
          isStatic: staticModifier,
          nameGroupName: 'NAME',
          type: fieldType,
          typeGroupName: 'TYPE',
        );
      });
    });
  }

  Future<void> _proposeFromFieldFormalParameter(
    ChangeBuilder builder,
    FieldFormalParameter parameter,
  ) async {
    var constructor = parameter.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructor == null) {
      return;
    }
    var container = constructor.thisOrAncestorOfType<CompilationUnitMember>();
    if (container == null) {
      return;
    }
    if (container is! ClassDeclaration && container is! EnumDeclaration) {
      return;
    }

    _fieldName = parameter.name.lexeme;

    // Add proposal.
    await builder.addDartFileEdit(file, (builder) {
      builder.insertField(container, (builder) {
        builder.writeFieldDeclaration(
          _fieldName,
          isFinal: constructor.constKeyword != null,
          nameGroupName: 'NAME',
          type: parameter.declaredFragment?.element.type,
          typeGroupName: 'TYPE',
        );
      });
    });
  }

  Future<void> _proposeFromIdentifier(ChangeBuilder builder) async {
    var nameNode = node;
    if (nameNode is! SimpleIdentifier) {
      return;
    }
    _fieldName = nameNode.name;
    // Prepare target `Expression`.
    var target = switch (nameNode.parent) {
      PrefixedIdentifier(:var prefix) => prefix,
      PropertyAccess(:var realTarget) => realTarget,
      _ => null,
    };
    // Prepare target `ClassElement`.
    var staticModifier = false;
    InterfaceElement2? targetClassElement;
    if (target != null) {
      targetClassElement = getTargetInterfaceElement2(target);
      // Maybe static.
      if (target is Identifier) {
        var targetIdentifier = target;
        var targetElement = targetIdentifier.element;
        if (targetElement == null) {
          return;
        }
        staticModifier = targetElement.kind == ElementKind.CLASS;
      }
    } else {
      targetClassElement = node.enclosingInterfaceElement2;
      staticModifier = inStaticContext;
    }

    var fieldTypeNode = climbPropertyAccess(nameNode);
    var fieldTypeParent = fieldTypeNode.parent;
    if (targetClassElement is EnumElement2 &&
        fieldTypeParent is AssignmentExpression &&
        fieldTypeNode == fieldTypeParent.leftHandSide) {
      // Any field on an enum must be final; creating a final field does not
      // make sense when seen in an assignment expression.
      return;
    }
    var fieldType = inferUndefinedExpressionType(fieldTypeNode);

    await _addDeclaration(
      builder: builder,
      staticModifier: staticModifier,
      targetElement: targetClassElement,
      fieldType: fieldType,
    );
  }
}
