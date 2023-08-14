// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/create_getter.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class CreateField extends CreateFieldOrGetter {
  /// The name of the field to be created.
  String _fieldName = '';

  @override
  List<Object> get fixArguments => [_fieldName];

  @override
  FixKind get fixKind => DartFixKind.CREATE_FIELD;

  @override
  Future<void> addForObjectPattern({
    required ChangeBuilder builder,
    required InterfaceElement? targetElement,
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
    required InterfaceElement? targetElement,
    required DartType? fieldType,
  }) async {
    if (targetElement == null) {
      return;
    }
    if (targetElement.library.isInSdk) {
      return;
    }
    utils.targetClassElement = targetElement;
    // prepare target ClassDeclaration
    var targetDeclarationResult =
        await sessionHelper.getElementDeclaration(targetElement);
    if (targetDeclarationResult == null) {
      return;
    }
    var targetNode = targetDeclarationResult.node;
    if (targetNode is! CompilationUnitMember) {
      return;
    }
    if (!(targetNode is ClassDeclaration || targetNode is MixinDeclaration)) {
      return;
    }
    // prepare location
    var targetUnit = targetDeclarationResult.resolvedUnit;
    if (targetUnit == null) {
      return;
    }
    var targetLocation =
        CorrectionUtils(targetUnit).prepareNewFieldLocation(targetNode);
    if (targetLocation == null) {
      return;
    }
    // build field source
    var targetSource = targetElement.source;
    var targetFile = targetSource.fullName;
    await builder.addDartFileEdit(targetFile, (builder) {
      builder.addInsertion(targetLocation.offset, (builder) {
        builder.write(targetLocation.prefix);
        builder.writeFieldDeclaration(_fieldName,
            isStatic: staticModifier,
            nameGroupName: 'NAME',
            type: fieldType,
            typeGroupName: 'TYPE');
        builder.write(targetLocation.suffix);
      });
    });
  }

  Future<void> _proposeFromFieldFormalParameter(
      ChangeBuilder builder, FieldFormalParameter parameter) async {
    var targetClassNode = parameter.thisOrAncestorOfType<ClassDeclaration>();
    if (targetClassNode == null) {
      return;
    }

    _fieldName = parameter.name.lexeme;

    var targetLocation = utils.prepareNewFieldLocation(targetClassNode);
    if (targetLocation == null) {
      return;
    }

    //
    // Add proposal.
    //
    await builder.addDartFileEdit(file, (builder) {
      var fieldType = parameter.type?.type;
      builder.addInsertion(targetLocation.offset, (builder) {
        builder.write(targetLocation.prefix);
        builder.writeFieldDeclaration(_fieldName,
            nameGroupName: 'NAME', type: fieldType, typeGroupName: 'TYPE');
        builder.write(targetLocation.suffix);
      });
    });
  }

  Future<void> _proposeFromIdentifier(ChangeBuilder builder) async {
    var nameNode = node;
    if (nameNode is! SimpleIdentifier) {
      return;
    }
    _fieldName = nameNode.name;
    // prepare target Expression
    Expression? target;
    {
      var nameParent = nameNode.parent;
      if (nameParent is PrefixedIdentifier) {
        target = nameParent.prefix;
      } else if (nameParent is PropertyAccess) {
        target = nameParent.realTarget;
      }
    }
    // prepare target ClassElement
    var staticModifier = false;
    InterfaceElement? targetClassElement;
    if (target != null) {
      targetClassElement = getTargetInterfaceElement(target);
      // maybe static
      if (target is Identifier) {
        var targetIdentifier = target;
        var targetElement = targetIdentifier.staticElement;
        if (targetElement == null) {
          return;
        }
        staticModifier = targetElement.kind == ElementKind.CLASS;
      }
    } else {
      targetClassElement = node.enclosingInterfaceElement;
      staticModifier = inStaticContext;
    }

    var fieldTypeNode = climbPropertyAccess(nameNode);
    var fieldType = inferUndefinedExpressionType(fieldTypeNode);

    await _addDeclaration(
      builder: builder,
      staticModifier: staticModifier,
      targetElement: targetClassElement,
      fieldType: fieldType,
    );
  }
}
