// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class CreateConstructor extends ResolvedCorrectionProducer {
  /// The name of the constructor being created.
  /// TODO(migration) We set this node when we have the change.
  late String _constructorName;

  @override
  List<Object> get fixArguments => [_constructorName];

  @override
  FixKind get fixKind => DartFixKind.CREATE_CONSTRUCTOR;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    final argumentList = node.parent is ArgumentList ? node.parent : node;
    if (argumentList is ArgumentList) {
      var instanceCreation = argumentList.parent;
      if (instanceCreation is InstanceCreationExpression) {
        await _proposeFromInstanceCreation(builder, instanceCreation);
      }
    } else {
      if (node is SimpleIdentifier) {
        var parent = node.parent;
        if (parent is ConstructorName) {
          await _proposeFromConstructorName(builder, node.token, parent);
          return;
        }
      }
      var parent = node.thisOrAncestorOfType<EnumConstantDeclaration>();
      if (parent != null) {
        await _proposeFromEnumConstantDeclaration(builder, parent.name, parent);
      }
    }
  }

  Future<void> _proposeFromConstructorName(ChangeBuilder builder, Token name,
      ConstructorName constructorName) async {
    InstanceCreationExpression? instanceCreation;
    _constructorName = constructorName.toSource();
    if (constructorName.name?.token == name) {
      var grandParent = constructorName.parent;
      // Type.name
      if (grandParent is InstanceCreationExpression) {
        instanceCreation = grandParent;
        // new Type.name()
        if (grandParent.constructorName != constructorName) {
          return;
        }
      }
    }

    // do we have enough information?
    if (instanceCreation == null) {
      return;
    }

    // prepare target interface type
    var targetType = constructorName.type.type;
    if (targetType is! InterfaceType) {
      return;
    }

    // prepare target ClassDeclaration
    var targetElement = targetType.element;
    var targetResult = await sessionHelper.getElementDeclaration(targetElement);
    if (targetResult == null) {
      return;
    }
    var targetNode = targetResult.node;
    if (targetNode is! ClassDeclaration) {
      return;
    }

    var targetUnit = targetResult.resolvedUnit;
    if (targetUnit == null) {
      return;
    }

    // prepare location
    var targetLocation = CorrectionUtils(targetUnit)
        .prepareNewConstructorLocation(
            unitResult.session, targetNode, targetUnit.file);
    if (targetLocation == null) {
      return;
    }

    await _write(builder, name, targetElement, targetLocation,
        constructorName: name, argumentList: instanceCreation.argumentList);
  }

  Future<void> _proposeFromEnumConstantDeclaration(
      ChangeBuilder builder, Token name, EnumConstantDeclaration parent) async {
    var grandParent = parent.parent;
    if (grandParent is! EnumDeclaration) {
      return;
    }
    var targetElement = grandParent.declaredElement;
    if (targetElement == null) {
      return;
    }

    // prepare target interface type
    var targetResult = await sessionHelper.getElementDeclaration(targetElement);
    if (targetResult == null) {
      return;
    }

    var targetNode = targetResult.node;
    if (targetNode is! EnumDeclaration) {
      return;
    }

    var targetUnit = targetResult.resolvedUnit;
    if (targetUnit == null) {
      return;
    }

    // prepare location
    var targetLocation = CorrectionUtils(targetUnit)
        .prepareEnumNewConstructorLocation(targetNode);

    var arguments = parent.arguments;
    _constructorName =
        '${targetNode.name.lexeme}${arguments?.constructorSelector ?? ''}';

    await _write(
      builder,
      name,
      targetElement,
      targetLocation,
      isConst: true,
      constructorName: arguments?.constructorSelector?.name.token,
      argumentList: arguments?.argumentList,
    );
  }

  Future<void> _proposeFromInstanceCreation(ChangeBuilder builder,
      InstanceCreationExpression instanceCreation) async {
    var constructorName = instanceCreation.constructorName;
    _constructorName = constructorName.toSource();
    // should be synthetic default constructor
    var constructorElement = constructorName.staticElement;
    if (constructorElement == null ||
        !constructorElement.isDefaultConstructor ||
        !constructorElement.isSynthetic) {
      return;
    }

    // prepare target ClassDeclaration
    var targetElement = constructorElement.enclosingElement;
    var targetResult = await sessionHelper.getElementDeclaration(targetElement);
    if (targetResult == null) {
      return;
    }
    var targetNode = targetResult.node;
    if (targetNode is! ClassDeclaration) {
      return;
    }

    var targetUnit = targetResult.resolvedUnit;
    if (targetUnit == null) {
      return;
    }

    // prepare location
    var targetLocation = CorrectionUtils(targetUnit)
        .prepareNewConstructorLocation(
            unitResult.session, targetNode, targetUnit.file);
    if (targetLocation == null) {
      return;
    }

    var targetSource = targetElement.source;
    var targetFile = targetSource.fullName;
    await builder.addDartFileEdit(targetFile, (builder) {
      builder.addInsertion(targetLocation.offset, (builder) {
        builder.write(targetLocation.prefix);
        builder.writeConstructorDeclaration(targetElement.name,
            argumentList: instanceCreation.argumentList);
        builder.write(targetLocation.suffix);
      });
    });
  }

  Future<void> _write(
    ChangeBuilder builder,
    Token name,
    InterfaceElement targetElement,
    InsertionLocation targetLocation, {
    Token? constructorName,
    bool isConst = false,
    ArgumentList? argumentList,
  }) async {
    var targetFile = targetElement.source.fullName;
    await builder.addDartFileEdit(targetFile, (builder) {
      builder.addInsertion(targetLocation.offset, (builder) {
        builder.write(targetLocation.prefix);
        builder.writeConstructorDeclaration(targetElement.name,
            isConst: isConst,
            argumentList: argumentList,
            constructorName: constructorName?.lexeme,
            constructorNameGroupName: 'NAME');
        builder.write(targetLocation.suffix);
      });
      if (targetFile == file) {
        builder.addLinkedPosition(range.token(name), 'NAME');
      }
    });
  }
}
