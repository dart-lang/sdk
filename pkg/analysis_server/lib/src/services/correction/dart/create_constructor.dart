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
import 'package:analyzer_plugin/utilities/range_factory.dart';

class CreateConstructor extends CorrectionProducer {
  /// The name of the constructor being created.
  ConstructorName _constructorName;

  @override
  List<Object> get fixArguments => [_constructorName];

  @override
  FixKind get fixKind => DartFixKind.CREATE_CONSTRUCTOR;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node is ArgumentList && node.parent is InstanceCreationExpression) {
      await _proposeFromInstanceCreation(builder);
    } else {
      await _proposeFromConstructorName(builder);
    }
  }

  Future<void> _proposeFromConstructorName(ChangeBuilder builder) async {
    SimpleIdentifier name;
    InstanceCreationExpression instanceCreation;
    if (node is SimpleIdentifier) {
      // name
      name = node as SimpleIdentifier;
      if (name.parent is ConstructorName) {
        _constructorName = name.parent as ConstructorName;
        if (_constructorName.name == name) {
          // Type.name
          if (_constructorName.parent is InstanceCreationExpression) {
            instanceCreation =
                _constructorName.parent as InstanceCreationExpression;
            // new Type.name()
            if (instanceCreation.constructorName != _constructorName) {
              return;
            }
          }
        }
      }
    }
    // do we have enough information?
    if (instanceCreation == null) {
      return;
    }
    // prepare target interface type
    var targetType = _constructorName.type.type;
    if (targetType is! InterfaceType) {
      return;
    }

    // prepare target ClassDeclaration
    ClassElement targetElement = targetType.element;
    var targetResult = await sessionHelper.getElementDeclaration(targetElement);
    var targetNode = targetResult.node;
    if (targetNode is! ClassDeclaration) {
      return;
    }

    // prepare location
    var targetLocation = CorrectionUtils(targetResult.resolvedUnit)
        .prepareNewConstructorLocation(targetNode);

    var targetFile = targetElement.source.fullName;
    await builder.addDartFileEdit(targetFile, (builder) {
      builder.addInsertion(targetLocation.offset, (builder) {
        builder.write(targetLocation.prefix);
        builder.writeConstructorDeclaration(targetElement.name,
            argumentList: instanceCreation.argumentList,
            constructorName: name,
            constructorNameGroupName: 'NAME');
        builder.write(targetLocation.suffix);
      });
      if (targetFile == file) {
        builder.addLinkedPosition(range.node(name), 'NAME');
      }
    });
  }

  Future<void> _proposeFromInstanceCreation(ChangeBuilder builder) async {
    InstanceCreationExpression instanceCreation = node.parent;
    _constructorName = instanceCreation.constructorName;
    // should be synthetic default constructor
    var constructorElement = _constructorName.staticElement;
    if (constructorElement == null ||
        !constructorElement.isDefaultConstructor ||
        !constructorElement.isSynthetic) {
      return;
    }
    // prepare target
    if (constructorElement.enclosingElement is! ClassElement) {
      return;
    }

    // prepare target ClassDeclaration
    var targetElement = constructorElement.enclosingElement;
    var targetResult = await sessionHelper.getElementDeclaration(targetElement);
    var targetNode = targetResult.node;
    if (targetNode is! ClassDeclaration) {
      return;
    }

    // prepare location
    var targetLocation = CorrectionUtils(targetResult.resolvedUnit)
        .prepareNewConstructorLocation(targetNode);

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

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static CreateConstructor newInstance() => CreateConstructor();
}
