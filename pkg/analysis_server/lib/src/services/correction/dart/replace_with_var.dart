// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/utilities/dot_shorthands.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceWithVar extends ResolvedCorrectionProducer {
  ReplaceWithVar({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.replaceWithVar;

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
    // TODO(brianwilkerson): Optimize this by removing the duplication between
    //  [_canReplaceWithVar] and the rest of this method.
    if (!_canReplaceWithVar()) {
      return;
    }
    var parent = type.parent;
    var grandparent = parent?.parent;
    if (parent is VariableDeclarationList &&
        (grandparent is VariableDeclarationStatement ||
            grandparent is ForPartsWithDeclarations ||
            grandparent is TopLevelVariableDeclaration ||
            grandparent is FieldDeclaration)) {
      var variables = parent.variables;
      // This is the job of RemoveTypeAnnotation fix/assist.
      if (parent.isConst || parent.isFinal) {
        return;
      }
      if (variables.length != 1) {
        return;
      }
      var initializer = variables[0].initializer;
      String? insertionText;
      int? insertionOffset;
      if (initializer != null && isDotShorthand(initializer)) {
        // Inserts the type before the dot shorthand (e.g. `E.a` where type is
        // `E`) because we erase the required context type when we replace the
        // declared type with `var`.
        insertionText = utils.getNodeText(type);
        insertionOffset = initializer.beginToken.offset;
      } else if (type is NamedType) {
        var typeArguments = type.typeArguments;
        if (typeArguments != null) {
          if (initializer is CascadeExpression) {
            initializer = initializer.target;
          }
          if (initializer is TypedLiteral) {
            if (initializer.typeArguments == null) {
              insertionText = utils.getNodeText(typeArguments);
              if (initializer is ListLiteral) {
                insertionOffset = initializer.leftBracket.offset;
              } else if (initializer is SetOrMapLiteral) {
                insertionOffset = initializer.leftBracket.offset;
              } else {
                throw StateError('Unhandled subclass of TypedLiteral');
              }
            }
          } else if (initializer is InstanceCreationExpression) {
            if (initializer.constructorName.type.typeArguments == null) {
              insertionText = utils.getNodeText(typeArguments);
              insertionOffset = initializer.constructorName.type.end;
            }
          }
        }
      }
      if (initializer is SetOrMapLiteral &&
          initializer.typeArguments == null &&
          insertionText == null) {
        // This is to prevent the fix from converting a valid map or set literal
        // into an ambiguous literal. We could apply this in more places
        // by examining the elements of the collection.
        return;
      }
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(type), 'var');

        if (insertionText != null && insertionOffset != null) {
          builder.addSimpleInsertion(insertionOffset, insertionText);
        }
      });
    } else if (parent is DeclaredIdentifier &&
        grandparent is ForEachPartsWithDeclaration) {
      // This is the job of RemoveTypeAnnotation fix/assist.
      if (parent.isConst || parent.isFinal) {
        return;
      }

      String? insertionText;
      int? insertionOffset;
      var iterable = grandparent.iterable;
      if (hasDependentDotShorthand(iterable) && iterable is TypedLiteral) {
        // If there's a dependent shorthand in the literal, we need to
        // insert explicit type arguments to ensure we have an appropriate
        // context type to resolve the dot shorthand.
        insertionText = '<${utils.getNodeText(type)}>';
        insertionOffset = iterable.beginToken.offset;
      } else if (type is NamedType) {
        var typeArguments = type.typeArguments;
        if (typeArguments != null) {
          if (iterable is TypedLiteral && iterable.typeArguments == null) {
            insertionText = utils.getNodeText(typeArguments);
            insertionOffset = iterable.offset;
          }
        }
      }
      await builder.addDartFileEdit(file, (builder) {
        if (parent.isConst || parent.isFinal) {
          builder.addDeletion(range.startStart(type, parent.name));
        } else {
          builder.addSimpleReplacement(range.node(type), 'var');
        }
        if (insertionText != null && insertionOffset != null) {
          builder.addSimpleInsertion(insertionOffset, insertionText);
        }
      });
    }
  }

  /// Return `true` if the type in the [node] can be replaced with `var`.
  bool _canConvertVariableDeclarationList(VariableDeclarationList node) {
    var staticType = node.type?.type;
    if (staticType == null || staticType is DynamicType) {
      return false;
    }
    for (var child in node.variables) {
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
        var iterableType = parent.iterable.typeOrThrow;
        var instantiatedType = iterableType.asInstanceOf(
          typeProvider.iterableElement,
        );
        if (instantiatedType?.typeArguments.first == staticType) {
          return true;
        }
        return false;
      } else if (parent is TopLevelVariableDeclaration) {
        return _canConvertVariableDeclarationList(parent.variables);
      } else if (parent is FieldDeclaration) {
        return _canConvertVariableDeclarationList(parent.fields);
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
