// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

class ShadowField extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.SHADOW_FIELD;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node is! SimpleIdentifier) {
      return;
    }
    var element = (node as SimpleIdentifier).writeOrReadElement;
    if (element is! PropertyAccessorElement) {
      return;
    }
    var accessor = element as PropertyAccessorElement;
    if (!accessor.isGetter || accessor.enclosingElement is! ClassElement) {
      // TODO(brianwilkerson) Should we also require that the getter be synthetic?
      return;
    }
    var statement = _getStatement();
    if (statement == null) {
      return;
    }
    if (statement.parent is! Block) {
      // TODO(brianwilkerson) Support adding a block between the statement and
      //  its parent (where the parent will be something like a while or if
      //  statement). Also support the case where the parent is a case clause.
      return;
    }
    var enclosingBlock = statement.parent as Block;
    var finder = _ReferenceFinder(accessor.correspondingSetter);
    enclosingBlock.accept(finder);
    if (finder.hasSetterReference) {
      return;
    }
    var fieldName = accessor.name;
    var offset = statement.offset;
    var prefix = utils.getLinePrefix(offset);
    //
    // Build the change.
    //
    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(offset, (builder) {
        // TODO(brianwilkerson) Conditionally write a type annotation instead of
        //  'var' when we're able to discover user preferences.
        builder.write('var ');
        builder.write(fieldName);
        builder.write(' = this.');
        builder.write(fieldName);
        builder.writeln(';');
        builder.write(prefix);
      });
      // TODO(brianwilkerson) Consider removing unnecessary casts and null
      //  checks that are no longer needed because promotion works. This would
      //  be dependent on whether enhanced promotion is supported in the library
      //  being edited.
    });
  }

  /// Return the statement immediately enclosing the [node] that would promote
  /// the type of the field if it were replaced by a local variable.
  Statement _getStatement() {
    var parent = node.parent;

    Statement enclosingIf(Expression expression) {
      var parent = expression.parent;
      while (parent is BinaryExpression) {
        var opType = (parent as BinaryExpression).operator.type;
        if (opType != TokenType.AMPERSAND_AMPERSAND) {
          break;
        }
        parent = parent.parent;
      }
      if (parent is IfStatement) {
        return parent;
      }
      return null;
    }

    if (parent is IsExpression && parent.expression == node) {
      return enclosingIf(parent);
    } else if (parent is BinaryExpression &&
        resolvedResult.libraryElement.isNonNullableByDefault) {
      var opType = parent.operator.type;
      if (opType == TokenType.EQ_EQ || opType == TokenType.BANG_EQ) {
        return enclosingIf(parent);
      }
    }
    return null;
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ShadowField newInstance() => ShadowField();
}

/// A utility that will find any references to a setter within an AST structure.
class _ReferenceFinder extends RecursiveAstVisitor<void> {
  /// The setter being searched for.
  final PropertyAccessorElement setter;

  /// A flag indicating whether a reference to the [setter] has been found.
  bool hasSetterReference = false;

  /// Initialize a newly created reference finder to find references to the
  /// given [setter].
  _ReferenceFinder(this.setter);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.writeOrReadElement == setter) {
      hasSetterReference = true;
    }
  }
}
