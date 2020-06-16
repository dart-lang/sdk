// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class CreateSetter extends CorrectionProducer {
  String _setterName;

  @override
  List<Object> get fixArguments => [_setterName];

  @override
  FixKind get fixKind => DartFixKind.CREATE_SETTER;

  @override
  Future<void> compute(DartChangeBuilder builder) async {
    if (node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier nameNode = node;
    if (!nameNode.inSetterContext()) {
      return;
    }
    // prepare target
    Expression target;
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
    Element targetElement;
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
    if (targetElement.librarySource.isInSystemLibrary) {
      return;
    }
    // prepare target declaration
    var targetDeclarationResult =
        await sessionHelper.getElementDeclaration(targetElement);
    if (targetDeclarationResult == null) {
      return;
    }
    if (targetDeclarationResult.node is! ClassOrMixinDeclaration &&
        targetDeclarationResult.node is! ExtensionDeclaration) {
      return;
    }
    CompilationUnitMember targetNode = targetDeclarationResult.node;
    // prepare location
    var targetLocation = CorrectionUtils(targetDeclarationResult.resolvedUnit)
        .prepareNewGetterLocation(targetNode); // Rename to "AccessorLocation"
    // build method source
    var targetSource = targetElement.source;
    var targetFile = targetSource.fullName;
    _setterName = nameNode.name;
    await builder.addFileEdit(targetFile, (DartFileEditBuilder builder) {
      builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
        var parameterTypeNode = climbPropertyAccess(nameNode);
        var parameterType = inferUndefinedExpressionType(parameterTypeNode);
        builder.write(targetLocation.prefix);
        builder.writeSetterDeclaration(_setterName,
            isStatic: staticModifier,
            nameGroupName: 'NAME',
            parameterType: parameterType,
            parameterTypeGroupName: 'TYPE');
        builder.write(targetLocation.suffix);
      });
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static CreateSetter newInstance() => CreateSetter();
}
