// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceWithVar extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.REPLACE_WITH_VAR;

  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REPLACE_WITH_VAR;

  @override
  FixKind get multiFixKind => DartFixKind.REPLACE_WITH_VAR_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var type = _findType(node);
    if (type == null) {
      return;
    }
    // TODO(brianwilkerson) Optimize this by removing the duplication between
    //  [_canReplaceWithVar] and the rest of this method.
    if (!_canReplaceWithVar()) {
      return;
    }
    var parent = type.parent;
    var grandparent = parent?.parent;
    if (parent is VariableDeclarationList &&
        (grandparent is VariableDeclarationStatement ||
            grandparent is ForPartsWithDeclarations)) {
      var variables = parent.variables;
      if (variables.length != 1) {
        return;
      }
      var initializer = variables[0].initializer;
      String? typeArgumentsText;
      int? typeArgumentsOffset;
      if (type is NamedType) {
        var typeArguments = type.typeArguments;
        if (typeArguments != null) {
          if (initializer is CascadeExpression) {
            initializer = initializer.target;
          }
          if (initializer is TypedLiteral) {
            if (initializer.typeArguments == null) {
              typeArgumentsText = utils.getNodeText(typeArguments);
              if (initializer is ListLiteral) {
                typeArgumentsOffset = initializer.leftBracket.offset;
              } else if (initializer is SetOrMapLiteral) {
                typeArgumentsOffset = initializer.leftBracket.offset;
              } else {
                throw StateError('Unhandled subclass of TypedLiteral');
              }
            }
          } else if (initializer is InstanceCreationExpression) {
            if (initializer.constructorName.type.typeArguments == null) {
              typeArgumentsText = utils.getNodeText(typeArguments);
              typeArgumentsOffset = initializer.constructorName.type.end;
            }
          }
        }
      }
      if (initializer is SetOrMapLiteral &&
          initializer.typeArguments == null &&
          typeArgumentsText == null) {
        // This is to prevent the fix from converting a valid map or set literal
        // into an ambiguous literal. We could apply this in more places
        // by examining the elements of the collection.
        return;
      }
      await builder.addDartFileEdit(file, (builder) {
        if (parent.isConst || parent.isFinal) {
          builder.addDeletion(range.startStart(type, variables[0]));
        } else {
          builder.addSimpleReplacement(range.node(type), 'var');
        }
        if (typeArgumentsText != null && typeArgumentsOffset != null) {
          builder.addSimpleInsertion(typeArgumentsOffset, typeArgumentsText);
        }
      });
    } else if (parent is DeclaredIdentifier &&
        grandparent is ForEachPartsWithDeclaration) {
      String? typeArgumentsText;
      int? typeArgumentsOffset;
      if (type is NamedType) {
        var typeArguments = type.typeArguments;
        if (typeArguments != null) {
          var iterable = grandparent.iterable;
          if (iterable is TypedLiteral && iterable.typeArguments == null) {
            typeArgumentsText = utils.getNodeText(typeArguments);
            typeArgumentsOffset = iterable.offset;
          }
        }
      }
      await builder.addDartFileEdit(file, (builder) {
        if (parent.isConst || parent.isFinal) {
          builder.addDeletion(range.startStart(type, parent.name));
        } else {
          builder.addSimpleReplacement(range.node(type), 'var');
        }
        if (typeArgumentsText != null && typeArgumentsOffset != null) {
          builder.addSimpleInsertion(typeArgumentsOffset, typeArgumentsText);
        }
      });
    }
  }

  /// Return `true` if the type in the [node] can be replaced with `var`.
  bool _canConvertVariableDeclarationList(VariableDeclarationList node) {
    final staticType = node.type?.type;
    if (staticType == null || staticType is DynamicType) {
      return false;
    }
    for (final child in node.variables) {
      var initializer = child.initializer;
      if (initializer == null || initializer.staticType != staticType) {
        return false;
      }
    }
    return true;
  }

  /// Return `true` if the [node] can be replaced with `var`.
  bool _canReplaceWithVar() {
    var parent = node.parent;
    while (parent != null) {
      if (parent is VariableDeclarationStatement) {
        return _canConvertVariableDeclarationList(parent.variables);
      } else if (parent is ForPartsWithDeclarations) {
        return _canConvertVariableDeclarationList(parent.variables);
      } else if (parent is ForEachPartsWithDeclaration) {
        var loopVariableType = parent.loopVariable.type;
        var staticType = loopVariableType?.type;
        if (staticType == null || staticType is DynamicType) {
          return false;
        }
        final iterableType = parent.iterable.typeOrThrow;
        var instantiatedType =
            iterableType.asInstanceOf(typeProvider.iterableElement);
        if (instantiatedType?.typeArguments.first == staticType) {
          return true;
        }
        return false;
      }
      parent = parent.parent;
    }
    return false;
  }

  /// Using the [node] as a starting point, return the type annotation that is
  /// to be replaced, or `null` if there is no type annotation.
  TypeAnnotation? _findType(AstNode node) {
    if (node is VariableDeclarationList) {
      return node.type;
    }
    return node.thisOrAncestorOfType<TypeAnnotation>();
  }
}
