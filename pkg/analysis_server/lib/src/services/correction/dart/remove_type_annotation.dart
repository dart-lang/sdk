// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveTypeAnnotation extends ParsedCorrectionProducer {
  final _Kind _kind;

  RemoveTypeAnnotation.fixVarAndType() : _kind = _Kind.fixVarAndType;

  RemoveTypeAnnotation.other() : _kind = _Kind.other;

  @override
  AssistKind get assistKind => DartAssistKind.REMOVE_TYPE_ANNOTATION;

  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_TYPE_ANNOTATION;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_TYPE_ANNOTATION_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (_kind == _Kind.fixVarAndType) {
      return _varAndType(builder);
    }

    for (var node in this.node.withParents) {
      if (node is DeclaredIdentifier) {
        return _removeFromDeclaredIdentifier(builder, node);
      }
      if (node is SimpleFormalParameter) {
        return _removeTypeAnnotation(builder, node.type);
      }
      if (node is SuperFormalParameter) {
        return _removeTypeAnnotation(builder, node.type,
            parameters: node.parameters);
      }
      if (node is TypeAnnotation && diagnostic != null) {
        return _removeTypeAnnotation(builder, node);
      }
      if (node is VariableDeclarationList) {
        return _removeFromDeclarationList(builder, node);
      }
    }
  }

  Future<void> _removeFromDeclarationList(
      ChangeBuilder builder, VariableDeclarationList declarationList) async {
    // we need a type
    var type = declarationList.type;
    if (type == null) {
      return;
    }
    // ignore if an incomplete variable declaration
    if (declarationList.variables.length == 1 &&
        declarationList.variables[0].name.isSynthetic) {
      return;
    }
    // must be not after the name of the variable
    var firstVariable = declarationList.variables[0];
    if (selectionOffset > firstVariable.name.end) {
      return;
    }

    var initializer = firstVariable.initializer;
    // The variable must have an initializer, otherwise there is no other
    // source for its type.
    if (initializer == null) {
      return;
    }

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
    var keyword = declarationList.keyword;
    await builder.addDartFileEdit(file, (builder) {
      var typeRange = range.startStart(type, firstVariable);
      if (keyword != null && keyword.lexeme != 'var') {
        builder.addSimpleReplacement(typeRange, '');
      } else {
        builder.addSimpleReplacement(typeRange, 'var ');
      }
      if (typeArgumentsText != null && typeArgumentsOffset != null) {
        builder.addSimpleInsertion(typeArgumentsOffset, typeArgumentsText);
      }
    });
  }

  Future<void> _removeFromDeclaredIdentifier(
      ChangeBuilder builder, DeclaredIdentifier declaration) async {
    var typeNode = declaration.type;
    if (typeNode == null) {
      return;
    }
    var keyword = declaration.keyword;
    var variableName = declaration.name;
    await builder.addDartFileEdit(file, (builder) {
      var typeRange = range.startStart(typeNode, variableName);
      if (keyword != null && keyword.lexeme != 'var') {
        builder.addSimpleReplacement(typeRange, '');
      } else {
        builder.addSimpleReplacement(typeRange, 'var ');
      }
    });
  }

  Future<void> _removeTypeAnnotation(
      ChangeBuilder builder, TypeAnnotation? type,
      {FormalParameterList? parameters}) async {
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
    final node = this.node;

    Future<void> removeTypeAfterVar({
      required Token? varKeyword,
      required TypeAnnotation? type,
    }) async {
      if (varKeyword != null && type != null) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(
            range.endEnd(varKeyword, type),
          );
        });
      }
    }

    if (node is DeclaredVariablePattern) {
      await removeTypeAfterVar(
        varKeyword: node.varKeyword,
        type: node.type,
      );
    }

    if (node is VariableDeclarationList) {
      await removeTypeAfterVar(
        varKeyword: node.varKeyword,
        type: node.type,
      );
    }
  }
}

enum _Kind {
  fixVarAndType,
  other,
}
