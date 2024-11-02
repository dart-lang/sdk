// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceReturnType extends ResolvedCorrectionProducer {
  String _newType = '';

  ReplaceReturnType({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_newType];

  @override
  FixKind get fixKind => DartFixKind.REPLACE_RETURN_TYPE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is Expression) {
      var typeSystem = libraryElement2.typeSystem;

      var newType = node.staticType;

      void updateNewType(SyntacticEntity entity) {
        if (entity is FunctionExpression) {
          return;
        } else if (entity is ReturnStatement) {
          var type = entity.expression?.staticType;
          if (type != null) {
            if (newType == null) {
              newType = type;
            } else {
              newType = typeSystem.leastUpperBound(newType!, type);
            }
          }
        } else if (entity is AstNode) {
          entity.childEntities.forEach(updateNewType);
        }
      }

      var functionBody = node.thisOrAncestorOfType<FunctionBody>();
      var parent = functionBody?.parent;
      var grandParent = parent?.parent;

      TypeAnnotation? returnType;
      if (grandParent is FunctionDeclaration) {
        updateNewType(grandParent.functionExpression.body);
        returnType = grandParent.returnType;
      } else if (parent is MethodDeclaration) {
        updateNewType(parent.body);
        if (_isCompatibleWithReturnType(parent, newType)) {
          returnType = parent.returnType;
        }
      }

      if (returnType != null && newType != null) {
        if (functionBody!.isAsynchronous) {
          newType = typeProvider.futureType(newType!);
        }

        _newType = newType!.getDisplayString();

        await builder.addDartFileEdit(file, (builder) {
          if (builder.canWriteType(newType)) {
            builder.addReplacement(range.node(returnType!), (builder) {
              builder.writeType(newType);
            });
          }
        });
      }
    }
  }

  bool _isCompatibleWithReturnType(
      MethodDeclaration method, DartType? newType) {
    if (newType == null) {
      return false;
    }

    var clazz = method.thisOrAncestorOfType<ClassDeclaration>();
    if (clazz == null) {
      return false;
    }

    var methodName = method.declaredFragment!.name2;
    if (methodName == null) {
      return false;
    }

    var classElement = clazz.declaredFragment!.element;
    var overriddenList = InheritanceManager3().getOverridden4(
      classElement,
      Name.forLibrary(classElement.library2, methodName),
    );

    if (overriddenList != null) {
      var notSubtype = overriddenList.any((element) =>
          !libraryElement2.typeSystem.isSubtypeOf(newType, element.returnType));
      if (notSubtype) {
        return false;
      }
    }
    return true;
  }
}
