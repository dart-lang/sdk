// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
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
  FixKind get fixKind =>
      DartFixKind.CONVERT_NULL_CHECK_TO_NULL_AWARE_ELEMENT_OR_ENTRY;

  @override
  FixKind get multiFixKind =>
      DartFixKind.CONVERT_NULL_CHECK_TO_NULL_AWARE_ELEMENT_OR_ENTRY_MULTI;

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
        if (thenElement is! MapLiteralEntry) {
          // In case of a list or set element, we simply replace the entire
          // element with the then-element prefixed by '?'.
          //
          //     `[if (x != null) x]` ==> `[?x]`
          //     `{if (x != null) x]` ==> `{?x}`
          await builder.addDartFileEdit(file, (builder) {
            builder.addSimpleReplacement(
              range.startOffsetEndOffset(
                node.ifKeyword.offset,
                thenElement.offset,
              ),
              '?',
            );
          });
        } else {
          // In case of a map entry we need to check if it's the key that's
          // promoted to non-nullable or the value.
          var binaryCondition = condition as BinaryExpression;
          var keyCanonicalElement = thenElement.key.canonicalElement;
          if (keyCanonicalElement != null &&
              (binaryCondition.leftOperand.canonicalElement ==
                      keyCanonicalElement ||
                  binaryCondition.rightOperand.canonicalElement ==
                      keyCanonicalElement)) {
            // In case the key is promoted, we simply replace everything before
            // the key with '?'.
            //
            //     `{if (x != null) x: "value"}` ==> `{?x: "value"}`
            await builder.addDartFileEdit(file, (builder) {
              builder.addSimpleReplacement(
                range.startOffsetEndOffset(node.offset, thenElement.key.offset),
                '?',
              );
            });
          } else {
            // In case the value is promoted, we remove everything before the
            // key and insert '?' before the value.
            //
            //     `{if (x != null) "key": x}` ==> `{"key": ?x}`
            await builder.addDartFileEdit(file, (builder) {
              builder.addDeletion(
                range.startOffsetEndOffset(node.offset, thenElement.key.offset),
              );
              builder.addSimpleInsertion(thenElement.value.offset, '?');
            });
          }
        }
      } else {
        // An element or entry of the form `if (x case var y?) ...`.
        if (thenElement is! MapLiteralEntry) {
          // In case of a list or set element, we replace the entire element
          // with the expression to the left of 'case', prefixed by '?'.
          //
          //     `[if (x case var y?) y]` ==> `[?x]`
          //     `{if (x case var y?) y]` ==> `{?x}`
          await builder.addDartFileEdit(file, (builder) {
            builder.addSimpleReplacement(
              range.startOffsetEndOffset(node.offset, node.end),
              '?${condition.toSource()}',
            );
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
            //     `{if (x case var y?) y: "value"}` ==> `{?x: "value"}`
            await builder.addDartFileEdit(file, (builder) {
              builder.addSimpleReplacement(
                range.startOffsetEndOffset(node.offset, thenElement.key.end),
                '?${condition.toSource()}',
              );
            });
          } else {
            // In case the value is promoted, delete everything before the key
            // and replace the value with the expression to the left of 'case',
            // prefixed by '?'.
            //
            //     `{if (x case var y?) "key": y}` ==> `{"key": ?x}`
            await builder.addDartFileEdit(file, (builder) {
              builder.addDeletion(
                range.startOffsetEndOffset(node.offset, thenElement.key.offset),
              );
              builder.addSimpleReplacement(
                range.startOffsetEndOffset(
                  thenElement.value.offset,
                  thenElement.value.end,
                ),
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
