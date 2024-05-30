// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class CreateSetter extends ResolvedCorrectionProducer {
  String _setterName = '';

  CreateSetter({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_setterName];

  @override
  FixKind get fixKind => DartFixKind.CREATE_SETTER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var nameNode = node;
    if (nameNode is! SimpleIdentifier) {
      return;
    }
    if (!nameNode.inSetterContext()) {
      return;
    }
    // prepare target
    Expression? target;
    {
      var nameParent = nameNode.parent;
      if (nameParent is PrefixedIdentifier) {
        target = nameParent.prefix;
      } else if (nameParent is PropertyAccess) {
        target = nameParent.realTarget;
      }
    }
    // prepare target element
    var staticModifier = false;
    Element? targetElement;
    if (target is ExtensionOverride) {
      targetElement = target.element;
    } else if (target is Identifier &&
        target.staticElement is ExtensionElement) {
      targetElement = target.staticElement;
      staticModifier = true;
    } else if (target != null) {
      // prepare target interface type
      var targetType = target.staticType;
      if (targetType is! InterfaceType) {
        return;
      }
      targetElement = targetType.element;
      // maybe static
      if (target is Identifier) {
        var targetIdentifier = target;
        var targetElement = targetIdentifier.staticElement;
        staticModifier = targetElement?.kind == ElementKind.CLASS;
      }
    } else {
      targetElement =
          node.enclosingInterfaceElement ?? node.enclosingExtensionElement;
      if (targetElement == null) {
        return;
      }
      staticModifier = inStaticContext;
    }
    if (targetElement == null) {
      return;
    }
    var targetSource = targetElement.source;
    if (targetSource == null || targetElement.library?.isInSdk == true) {
      return;
    }
    // prepare target declaration
    var targetDeclarationResult =
        await sessionHelper.getElementDeclaration(targetElement);
    if (targetDeclarationResult == null) {
      return;
    }
    var targetNode = targetDeclarationResult.node;
    if (targetNode is CompilationUnitMember) {
      if (targetDeclarationResult.node is! ClassDeclaration &&
          targetDeclarationResult.node is! MixinDeclaration &&
          targetDeclarationResult.node is! ExtensionDeclaration &&
          targetDeclarationResult.node is! ExtensionTypeDeclaration) {
        return;
      }
    } else {
      return;
    }
    // Build setter source.
    var targetFile = targetSource.fullName;
    _setterName = nameNode.name;
    await builder.addDartFileEdit(targetFile, (builder) {
      builder.insertGetter(
        targetNode,
        (builder) {
          var parameterTypeNode = climbPropertyAccess(nameNode);
          var parameterType = inferUndefinedExpressionType(parameterTypeNode);
          builder.writeSetterDeclaration(_setterName,
              isStatic: staticModifier,
              nameGroupName: 'NAME',
              parameterType: parameterType,
              parameterTypeGroupName: 'TYPE');
        },
      );
    });
  }
}
