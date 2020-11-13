// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class MakeVariableNullable extends CorrectionProducer {
  /// The name of the variable whose type is to be made nullable.
  String _variableName;

  @override
  List<Object> get fixArguments => [_variableName];

  @override
  FixKind get fixKind => DartFixKind.MAKE_VARIABLE_NULLABLE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = coveredNode;
    var parent = node?.parent;
    if (unit.featureSet.isEnabled(Feature.non_nullable)) {
      if (node is SimpleIdentifier && parent is SimpleFormalParameter) {
        await _forSimpleFormalParameter(builder, node, parent);
      } else if (node is SimpleIdentifier &&
          parent is FunctionTypedFormalParameter) {
        await _forFunctionTypedFormalParameter(builder, node, parent);
      } else if (node is SimpleIdentifier && parent is FieldFormalParameter) {
        await _forFieldFormalParameter(builder, node, parent);
      } else if (parent is AssignmentExpression &&
          parent.rightHandSide == node) {
        await _forVariableDeclaration(builder, node, parent);
      }
    }
  }

  /// Return the list of variable declarations containing the declaration of the
  /// given [variable] that is located in the given [block] or in a surrounding
  /// block. Return `null` if the declaration can't be found.
  VariableDeclarationList _findDeclaration(
      LocalVariableElement variable, Block block) {
    if (variable == null) {
      return null;
    }
    var currentBlock = block;
    while (currentBlock != null) {
      for (var statement in block.statements) {
        if (statement is VariableDeclarationStatement) {
          var variableList = statement.variables;
          if (variableList != null) {
            var variables = variableList.variables;
            for (var declaration in variables) {
              if (declaration.declaredElement == variable) {
                return variableList;
              }
            }
          }
        }
      }
      currentBlock = currentBlock.parent.thisOrAncestorOfType<Block>();
    }
    return null;
  }

  /// Makes [parameter] nullable if possible.
  Future<void> _forFieldFormalParameter(ChangeBuilder builder,
      SimpleIdentifier name, FieldFormalParameter parameter) async {
    if (parameter.parameters != null) {
      // A function-typed field formal parameter.
      if (parameter.question != null) {
        return;
      }
      _variableName = parameter.identifier.name;
      await builder.addDartFileEdit(file, (builder) {
        // Add '?' after `)`.
        builder.addSimpleInsertion(parameter.endToken.end, '?');
      });
    } else {
      if (!_typeCanBeMadeNullable(parameter.type)) {
        return;
      }
      _variableName = parameter.identifier.name;
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(parameter.type.end, '?');
      });
    }
  }

  /// Makes [parameter] nullable if possible.
  Future<void> _forFunctionTypedFormalParameter(ChangeBuilder builder,
      SimpleIdentifier name, FunctionTypedFormalParameter parameter) async {
    if (parameter.question != null) {
      return;
    }
    _variableName = parameter.identifier.name;
    await builder.addDartFileEdit(file, (builder) {
      // Add '?' after `)`.
      builder.addSimpleInsertion(parameter.endToken.end, '?');
    });
  }

  Future<void> _forSimpleFormalParameter(ChangeBuilder builder,
      SimpleIdentifier name, SimpleFormalParameter parameter) async {
    if (!_typeCanBeMadeNullable(parameter.type)) {
      return;
    }
    _variableName = parameter.identifier.name;
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(parameter.type.end, '?');
    });
  }

  Future<void> _forVariableDeclaration(
      ChangeBuilder builder, AstNode node, AssignmentExpression parent) async {
    var leftHandSide = parent.leftHandSide;
    if (leftHandSide is SimpleIdentifier) {
      var element = leftHandSide.staticElement;
      if (element is LocalVariableElement) {
        var oldType = element.type;
        var newType = (node as Expression).staticType;
        if (node is NullLiteral) {
          newType = (oldType as InterfaceTypeImpl)
              .withNullability(NullabilitySuffix.question);
        } else if (!typeSystem.isAssignableTo(
            oldType, typeSystem.promoteToNonNull(newType))) {
          return;
        }
        var declarationList =
            _findDeclaration(element, parent.thisOrAncestorOfType<Block>());
        if (declarationList == null || declarationList.variables.length > 1) {
          return;
        }
        var variable = declarationList.variables[0];
        _variableName = variable.name.name;
        await builder.addDartFileEdit(file, (builder) {
          var keyword = declarationList.keyword;
          if (keyword != null && keyword.type == Keyword.VAR) {
            builder.addReplacement(range.token(keyword), (builder) {
              builder.writeType(newType);
            });
          } else if (keyword == null) {
            if (declarationList.type == null) {
              builder.addInsertion(variable.offset, (builder) {
                builder.writeType(newType);
                builder.write(' ');
              });
            } else {
              builder.addSimpleInsertion(declarationList.type.end, '?');
            }
          }
        });
      }
    }
  }

  bool _typeCanBeMadeNullable(TypeAnnotation typeAnnotation) {
    // Ensure that there is a type annotation.
    if (typeAnnotation == null) {
      return false;
    }
    if (typeSystem.isNullable(typeAnnotation.type)) {
      return false;
    }
    return true;
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static MakeVariableNullable newInstance() => MakeVariableNullable();
}
