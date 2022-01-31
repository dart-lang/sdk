// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class CreateGetter extends CorrectionProducer {
  String _getterName = '';

  @override
  List<Object> get fixArguments => [_getterName];

  @override
  FixKind get fixKind => DartFixKind.CREATE_GETTER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var nameNode = node;
    if (nameNode is! SimpleIdentifier) {
      return;
    }
    _getterName = nameNode.name;
    if (!nameNode.inGetterContext()) {
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
      targetElement = target.staticElement;
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
          getEnclosingClassElement(node) ?? getEnclosingExtensionElement(node);
      if (targetElement == null) {
        return;
      }
      staticModifier = inStaticContext;
    }
    if (targetElement == null) {
      return;
    }
    var targetSource = targetElement.source;
    if (targetSource == null || targetSource.uri.isScheme('dart')) {
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
      if (targetDeclarationResult.node is! ClassOrMixinDeclaration &&
          targetDeclarationResult.node is! ExtensionDeclaration) {
        return;
      }
    } else {
      return;
    }
    // prepare location
    var resolvedUnit = targetDeclarationResult.resolvedUnit;
    if (resolvedUnit == null) {
      return;
    }
    var targetLocation =
        CorrectionUtils(resolvedUnit).prepareNewGetterLocation(targetNode);
    if (targetLocation == null) {
      return;
    }
    // build method source
    var targetFile = targetSource.fullName;
    await builder.addDartFileEdit(targetFile, (builder) {
      builder.addInsertion(targetLocation.offset, (builder) {
        var fieldTypeNode = climbPropertyAccess(nameNode);
        var fieldType = inferUndefinedExpressionType(fieldTypeNode);
        builder.write(targetLocation.prefix);
        builder.writeGetterDeclaration(_getterName,
            isStatic: staticModifier,
            nameGroupName: 'NAME',
            returnType: fieldType ?? typeProvider.dynamicType,
            returnTypeGroupName: 'TYPE');
        builder.write(targetLocation.suffix);
      });
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static CreateGetter newInstance() => CreateGetter();
}
