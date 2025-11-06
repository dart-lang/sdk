// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/utilities/dot_shorthands.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveTypeAnnotation extends ParsedCorrectionProducer {
  final _Kind _kind;

  RemoveTypeAnnotation.fixVarAndType({required super.context})
    : _kind = _Kind.fixVarAndType;

  RemoveTypeAnnotation.other({required super.context}) : _kind = _Kind.other;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.removeTypeAnnotation;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_TYPE_ANNOTATION;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_TYPE_ANNOTATION_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (_kind == _Kind.fixVarAndType) {
      return _varAndType(builder);
    }

    for (var node in this.node.withAncestors) {
      if (node is DeclaredIdentifier) {
        return _removeFromDeclaredIdentifier(builder, node);
      }
      if (node is SimpleFormalParameter) {
        return _removeTypeAnnotation(builder, node.type);
      }
      if (node is SuperFormalParameter) {
        return _removeTypeAnnotation(
          builder,
          node.type,
          parameters: node.parameters,
        );
      }
      if (node case TypeAnnotation(:var parent) when diagnostic != null) {
        if (parent is VariableDeclarationList) {
          return _removeFromDeclarationList(builder, parent);
        } else if (parent is DeclaredIdentifier) {
          return _removeFromDeclaredIdentifier(builder, parent);
        }
        return _removeTypeAnnotation(builder, node);
      }
      if (node is VariableDeclarationList) {
        return _removeFromDeclarationList(builder, node);
      }
    }
  }

  Future<void> _removeFromDeclarationList(
    ChangeBuilder builder,
    VariableDeclarationList declarationList,
  ) async {
    // we need a type
    var type = declarationList.type;
    if (type == null) {
      return;
    }
    // ignore if an incomplete variable declaration
    if (declarationList.variables.length == 1 &&
        declarationList.variables.first.name.isSynthetic) {
      return;
    }
    // must be not after the name of the variable
    var firstVariable = declarationList.variables.first;
    if (selectionOffset > firstVariable.name.end) {
      return;
    }

    var initializer = firstVariable.initializer;
    // The variable must have an initializer, otherwise there is no other
    // source for its type.
    if (initializer == null) {
      return;
    }

    String? insertionText;
    int? insertionOffset;
    if (isDotShorthand(initializer)) {
      // Inserts the type before the dot shorthand (e.g. `E.a` where type is
      // `E`) because we erase the required context type when we replace the
      // declared type with `var`.
      // TODO(kallentu): https://github.com/dart-lang/sdk/issues/61164
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
    var keyword = declarationList.keyword;
    await builder.addDartFileEdit(file, (builder) {
      var typeRange = range.startStart(type, firstVariable);
      if (keyword != null && keyword.lexeme != Keyword.VAR.lexeme) {
        builder.addSimpleReplacement(typeRange, '');
      } else {
        builder.addSimpleReplacement(typeRange, '${Keyword.VAR.lexeme} ');
      }
      if (insertionText != null && insertionOffset != null) {
        builder.addSimpleInsertion(insertionOffset, insertionText);
      }
    });
  }

  Future<void> _removeFromDeclaredIdentifier(
    ChangeBuilder builder,
    DeclaredIdentifier declaration,
  ) async {
    var typeNode = declaration.type;
    if (typeNode == null) {
      return;
    }

    String? insertionText;
    int? insertionOffset;
    var parent = declaration.parent;
    if (parent is ForEachPartsWithDeclaration) {
      var iterable = parent.iterable;
      if (hasDependentDotShorthand(iterable) && iterable is TypedLiteral) {
        // If there's a dependent shorthand in the literal, we need to
        // insert explicit type arguments to ensure we have an appropriate
        // context type to resolve the dot shorthand.
        insertionText = '<${utils.getNodeText(typeNode)}>';
        insertionOffset = iterable.beginToken.offset;
      }
    }

    var keyword = declaration.keyword;
    var variableName = declaration.name;
    await builder.addDartFileEdit(file, (builder) {
      var typeRange = range.startStart(typeNode, variableName);
      if (keyword != null && keyword.lexeme != Keyword.VAR.lexeme) {
        builder.addSimpleReplacement(typeRange, '');
      } else {
        builder.addSimpleReplacement(typeRange, '${Keyword.VAR.lexeme} ');
      }

      if (insertionText != null && insertionOffset != null) {
        builder.addSimpleInsertion(insertionOffset, insertionText);
      }
    });
  }

  Future<void> _removeTypeAnnotation(
    ChangeBuilder builder,
    TypeAnnotation? type, {
    FormalParameterList? parameters,
  }) async {
    if (type == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.startStart(type, type.endToken.next!));
      if (parameters != null) {
        builder.addDeletion(range.deletionRange(parameters));
      }
    });
  }

  Future<void> _varAndType(ChangeBuilder builder) async {
    var node = this.node;

    Future<void> removeTypeAfterVar({
      required Token? varKeyword,
      required TypeAnnotation? type,
    }) async {
      if (varKeyword != null && type != null) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(range.endEnd(varKeyword, type));
        });
      }
    }

    if (node is DeclaredVariablePattern) {
      await removeTypeAfterVar(varKeyword: node.varKeyword, type: node.type);
    }

    if (node is VariableDeclarationList) {
      await removeTypeAfterVar(varKeyword: node.varKeyword, type: node.type);
    }
  }
}

enum _Kind { fixVarAndType, other }
