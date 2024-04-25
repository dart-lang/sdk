// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class MakeVariableNullable extends ResolvedCorrectionProducer {
  /// The name of the variable whose type is to be made nullable.
  String _variableName = '';

  @override
  List<String> get fixArguments => [_variableName];

  @override
  FixKind get fixKind => DartFixKind.MAKE_VARIABLE_NULLABLE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    if (node is SimpleFormalParameter) {
      await _forSimpleFormalParameter(builder, node);
    } else if (node is FunctionTypedFormalParameter) {
      await _forFunctionTypedFormalParameter(builder, node);
    } else if (node is FieldFormalParameter) {
      await _forFieldFormalParameter(builder, node);
    } else if (node is SuperFormalParameter) {
      await _forSuperFormalParameter(builder, node);
    } else if (node is Expression) {
      var parent = node.parent;
      if (parent is AssignmentExpression && parent.rightHandSide == node) {
        await _forAssignment(builder, node, parent);
      } else if (parent is VariableDeclaration && parent.initializer == node) {
        await _forVariableDeclaration(builder, node, parent);
      }
    }
  }

  /// Return the list of variable declarations containing the declaration of the
  /// given [variable] that is located in the given [block] or in a surrounding
  /// block. Return `null` if the declaration can't be found.
  VariableDeclarationList? _findDeclaration(
      LocalVariableElement variable, Block? block) {
    var currentBlock = block;
    while (currentBlock != null) {
      for (var statement in currentBlock.statements) {
        if (statement is VariableDeclarationStatement) {
          var variableList = statement.variables;
          for (var declaration in variableList.variables) {
            if (declaration.declaredElement == variable) {
              return variableList;
            }
          }
        }
      }
      currentBlock = currentBlock.parent?.thisOrAncestorOfType<Block>();
    }
    return null;
  }

  Future<void> _forAssignment(ChangeBuilder builder, Expression rightHandSide,
      AssignmentExpression parent) async {
    var leftHandSide = parent.leftHandSide;
    if (leftHandSide is! SimpleIdentifier) {
      return;
    }

    var element = leftHandSide.staticElement;
    if (element is! LocalVariableElement) {
      return;
    }

    var oldType = element.type;
    if (oldType is! InterfaceTypeImpl && oldType is! RecordTypeImpl) {
      return;
    }

    var newType = rightHandSide.typeOrThrow;
    if (rightHandSide is NullLiteral) {
      if (oldType is InterfaceTypeImpl) {
        newType = oldType.withNullability(NullabilitySuffix.question);
      } else if (oldType is RecordTypeImpl) {
        newType = oldType.withNullability(NullabilitySuffix.question);
      } else {
        return;
      }
    } else if (!typeSystem.isAssignableTo(
        oldType, typeSystem.promoteToNonNull(newType),
        strictCasts: analysisOptions.strictCasts)) {
      return;
    }

    var declarationList = _findDeclaration(
      element,
      parent.thisOrAncestorOfType<Block>(),
    );
    if (declarationList == null || declarationList.variables.length > 1) {
      return;
    }

    await _updateVariableType(builder, declarationList, newType);
  }

  /// Makes [parameter] nullable if possible.
  Future<void> _forFieldFormalParameter(
      ChangeBuilder builder, FieldFormalParameter parameter) async {
    if (parameter.parameters != null) {
      // A function-typed field formal parameter.
      if (parameter.question != null) {
        return;
      }
      _variableName = parameter.name.lexeme;
      await builder.addDartFileEdit(file, (builder) {
        // Add '?' after `)`.
        builder.addSimpleInsertion(parameter.end, '?');
      });
    } else {
      var type = parameter.type;
      if (type == null || !_typeCanBeMadeNullable(type)) {
        return;
      }
      _variableName = parameter.name.lexeme;
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(type.end, '?');
      });
    }
  }

  /// Makes [parameter] nullable if possible.
  Future<void> _forFunctionTypedFormalParameter(
      ChangeBuilder builder, FunctionTypedFormalParameter parameter) async {
    if (parameter.question != null) {
      return;
    }
    _variableName = parameter.name.lexeme;
    await builder.addDartFileEdit(file, (builder) {
      // Add '?' after `)`.
      builder.addSimpleInsertion(parameter.end, '?');
    });
  }

  Future<void> _forSimpleFormalParameter(
      ChangeBuilder builder, SimpleFormalParameter parameter) async {
    var type = parameter.type;
    if (type == null || !_typeCanBeMadeNullable(type)) {
      return;
    }

    var identifier = parameter.name;
    if (identifier == null) {
      return;
    }

    _variableName = identifier.lexeme;
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(type.end, '?');
    });
  }

  /// Makes [parameter] nullable if possible.
  Future<void> _forSuperFormalParameter(
      ChangeBuilder builder, SuperFormalParameter parameter) async {
    if (parameter.parameters != null) {
      // A function-typed field formal parameter.
      if (parameter.question != null) {
        return;
      }
      _variableName = parameter.name.lexeme;
      await builder.addDartFileEdit(file, (builder) {
        // Add '?' after `)`.
        builder.addSimpleInsertion(parameter.end, '?');
      });
    } else {
      var type = parameter.type;
      if (type == null || !_typeCanBeMadeNullable(type)) {
        return;
      }
      _variableName = parameter.name.lexeme;
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(type.end, '?');
      });
    }
  }

  Future<void> _forVariableDeclaration(ChangeBuilder builder, Expression node,
      VariableDeclaration parent) async {
    var declarationList = parent.parent;
    if (declarationList is! VariableDeclarationList) {
      return;
    }
    if (declarationList.variables.length > 1) {
      return;
    }

    var oldType = parent.declaredElement!.type;
    if (oldType is! InterfaceTypeImpl && oldType is! RecordTypeImpl) {
      return;
    }

    var newType = node.typeOrThrow;
    if (node is NullLiteral) {
      if (oldType is InterfaceTypeImpl) {
        newType = oldType.withNullability(NullabilitySuffix.question);
      } else if (oldType is RecordTypeImpl) {
        newType = oldType.withNullability(NullabilitySuffix.question);
      } else {
        return;
      }
    } else if (!typeSystem.isAssignableTo(
        oldType, typeSystem.promoteToNonNull(newType),
        strictCasts: analysisOptions.strictCasts)) {
      return;
    }

    await _updateVariableType(builder, declarationList, newType);
  }

  bool _typeCanBeMadeNullable(TypeAnnotation typeAnnotation) {
    return !typeSystem.isNullable(typeAnnotation.typeOrThrow);
  }

  /// Add edits to the [builder] to update the type in the [declarationList] to
  /// match the [newType].
  Future<void> _updateVariableType(ChangeBuilder builder,
      VariableDeclarationList declarationList, DartType newType) async {
    var variable = declarationList.variables[0];
    _variableName = variable.name.lexeme;
    await builder.addDartFileEdit(file, (builder) {
      var keyword = declarationList.keyword;
      if (keyword != null && keyword.type == Keyword.VAR) {
        builder.addReplacement(range.token(keyword), (builder) {
          builder.writeType(newType);
        });
      } else if (keyword == null) {
        var typeAnnotation = declarationList.type;
        if (typeAnnotation == null) {
          builder.addInsertion(variable.offset, (builder) {
            builder.writeType(newType);
            builder.write(' ');
          });
        } else {
          builder.addSimpleInsertion(typeAnnotation.end, '?');
        }
      }
    });
  }
}
