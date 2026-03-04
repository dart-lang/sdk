// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertNullCheckToNullAwareElementOrEntry
    extends ResolvedCorrectionProducer {
  ConvertNullCheckToNullAwareElementOrEntry({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.convertNullCheckToNullAwareElementOrEntry;

  @override
  FixKind get multiFixKind =>
      DartFixKind.convertNullCheckToNullAwareElementOrEntryMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = coveringNode;
    if (node case IfElement(
      expression: var condition,
      :var thenElement,
      elseKeyword: null,
    )) {
      if (node.caseClause == null) {
        // An element or entry of the form `if (x != null) ...`.
        if (thenElement
            case SpreadElement(expression: SimpleIdentifier element) ||
                SimpleIdentifier element) {
          // In case of a list or set element with a promotable target, we
          // simply replace the entire element with the then-element prefixed by
          // '?'.
          //
          //     `if (x != null) x` is rewritten as `?x`
          await builder.addDartFileEdit(file, (builder) {
            builder.addSimpleReplacement(
              range.startStart(node, element),
              thenElement is SpreadElement ? '...?' : '?',
            );
          });
        } else if (thenElement
            case SpreadElement(expression: PostfixExpression element) ||
                PostfixExpression element) {
          // In case of a list or set element with a getter target, we replace
          // the entire element with the then-element target identifier prefixed
          // by '?'. Note that in the case of a getter target, the null-check
          // operator '!' is always present in [thenElement].
          //
          //     `if (x != null) x!` is rewritten as `?x`
          await builder.addDartFileEdit(file, (builder) {
            builder.addSimpleReplacement(
              range.startStart(node, element),
              thenElement is SpreadElement ? '...?' : '?',
            );
            builder.addDeletion(range.endEnd(element.operand, element));
          });
        } else if (thenElement is MapLiteralEntry) {
          // In case of a map entry we need to check if it's the key that's
          // promoted to non-nullable or the value.
          var thenElementKey = thenElement.key;
          var keyCanonicalElement = switch (thenElementKey) {
            SimpleIdentifier() => thenElementKey.canonicalElement,
            PostfixExpression(:var operand, operator: Token(lexeme: '!')) =>
              operand.canonicalElement,
            _ => null,
          };

          var binaryCondition = condition as BinaryExpression;
          if (keyCanonicalElement != null &&
              (binaryCondition.leftOperand.canonicalElement ==
                      keyCanonicalElement ||
                  binaryCondition.rightOperand.canonicalElement ==
                      keyCanonicalElement)) {
            if (thenElementKey is SimpleIdentifier) {
              // In case the key is null-aware and is promotable, we simply
              // replace everything before the key with '?'.
              //
              //     `if (x != null) x: "v"` is rewritten as `?x: "v"`
              await builder.addDartFileEdit(file, (builder) {
                builder.addSimpleReplacement(
                  range.startStart(node, thenElement.key),
                  '?',
                );
              });
            } else if (thenElementKey is PostfixExpression) {
              // In case the key is null-aware and is a getter, we replace
              // everything before the key with '?' and remove '!' afterwards.
              // Note that in the case of a getter, the null-check operator '!'
              // is always present in [thenElementKey].
              //
              //     `if (x != null) x!: "v"` is rewritten as `?x: "v"`
              await builder.addDartFileEdit(file, (builder) {
                builder.addSimpleReplacement(
                  range.startStart(node, thenElementKey),
                  '?',
                );
                builder.addDeletion(
                  range.endStart(thenElementKey.operand, thenElement.separator),
                );
              });
            }
          } else {
            var thenElementValue = thenElement.value;
            if (thenElementValue is SimpleIdentifier) {
              // In case the value is null-aware and is promotable, we remove
              // everything before the key and insert '?' before the value.
              //
              //     `if (x != null) "k": x` is rewritten as `"k": ?x`
              await builder.addDartFileEdit(file, (builder) {
                builder.addDeletion(range.startStart(node, thenElement.key));
                builder.addSimpleInsertion(thenElement.value.offset, '?');
              });
            } else if (thenElementValue is PostfixExpression) {
              // In case the value is null-aware and is a getter, we remove
              // everything before the key, insert '?' before the value, and
              // delete '!' after it. Note that in the case of a getter, the
              // null-check operator '!' is always present in
              // [thenElementValue].
              //
              //     `if (x != null) "k": x!` is rewritten as `"k": ?x`
              await builder.addDartFileEdit(file, (builder) {
                builder.addDeletion(range.startStart(node, thenElementKey));
                builder.addSimpleInsertion(thenElementValue.offset, '?');
                builder.addDeletion(
                  range.endEnd(thenElementValue.operand, thenElementValue),
                );
              });
            }
          }
        }
      } else {
        // An element or entry of the form `if (x case var y?) ...`.
        if (thenElement is! MapLiteralEntry) {
          // In case of a list or set element, we replace the entire element
          // with the expression to the left of 'case', prefixed by '?'.
          //
          //     `if (x case var y?) y` is rewritten as `?x`
          await builder.addDartFileEdit(file, (builder) {
            builder.addSimpleReplacement(
              range.startStart(node, condition),
              thenElement is SpreadElement ? '...?' : '?',
            );
            builder.addDeletion(range.endEnd(condition, node));
          });
        } else {
          // In case of a map entry we need to check if it's the key that's
          // promoted to non-nullable or the value.
          var caseVariable =
              ((node.caseClause?.guardedPattern.pattern as NullCheckPattern)
                          .pattern
                      as DeclaredVariablePattern)
                  .declaredFragment
                  ?.element;
          if (caseVariable == thenElement.key.canonicalElement) {
            // In case the key is promoted, replace everything before ':' with
            // the expression before 'case', prefixed by '?'.
            //
            //     `if (x case var y?) y: "v"` is rewritten as `?x: "v"`
            await builder.addDartFileEdit(file, (builder) {
              builder.addSimpleReplacement(
                range.startStart(node, condition),
                '?',
              );
              builder.addDeletion(range.endEnd(condition, thenElement.key));
            });
          } else {
            // In case the value is promoted, delete everything before the key
            // and replace the value with the expression to the left of 'case',
            // prefixed by '?'.
            //
            //     `if (x case var y?) "k": y` is rewritten as `"k": ?x`
            await builder.addDartFileEdit(file, (builder) {
              builder.addDeletion(range.startStart(node, thenElement.key));
              builder.addSimpleReplacement(
                range.startEnd(thenElement.value, thenElement.value),
                '?${condition.toSource()}',
              );
            });
          }
        }
      }
    }
  }
}

extension AstNodeNullableExtension on AstNode? {
  Element? get canonicalElement {
    var self = this;
    if (self is Expression) {
      var node = self.unParenthesized;
      if (node is Identifier) {
        return node.element;
      } else if (node is PropertyAccess) {
        return node.propertyName.element;
      }
    }
    return null;
  }
}
