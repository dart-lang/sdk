// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertAddAllToSpread extends CorrectionProducer {
  /// The arguments used to compose the message.
  List<String> _args = [];

  /// A flag indicating whether the change that was built is one that inlines
  /// the elements of another list into the target list.
  bool _isInlineInvocation = false;

  @override
  List<Object> get assistArguments => _args;

  @override
  AssistKind get assistKind => _isInlineInvocation
      ? DartAssistKind.INLINE_INVOCATION
      : DartAssistKind.CONVERT_TO_SPREAD;

  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  List<Object> get fixArguments => _args;

  @override
  FixKind get fixKind => _isInlineInvocation
      ? DartFixKind.INLINE_INVOCATION
      : DartFixKind.CONVERT_TO_SPREAD;

  @override
  FixKind get multiFixKind => _isInlineInvocation
      ? DartFixKind.INLINE_INVOCATION_MULTI
      : DartFixKind.CONVERT_TO_SPREAD_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var name = node;
    if (name is! SimpleIdentifier) {
      return;
    }

    var invocation = name.parent;
    if (invocation is! MethodInvocation) {
      return;
    }

    if (name != invocation.methodName ||
        name.name != 'addAll' ||
        !invocation.isCascaded ||
        invocation.argumentList.arguments.length != 1) {
      return;
    }

    var cascade = invocation.thisOrAncestorOfType<CascadeExpression>();
    if (cascade == null) {
      return;
    }

    var sections = cascade.cascadeSections;
    var targetList = cascade.target;
    if (targetList is! ListLiteral || sections[0] != invocation) {
      // TODO(brianwilkerson) Consider extending this to handle set literals.
      return;
    }

    bool isEmptyListLiteral(Expression expression) =>
        expression is ListLiteral && expression.elements.isEmpty;

    var argument = invocation.argumentList.arguments[0];
    String? elementText;
    if (argument is BinaryExpression &&
        argument.operator.type == TokenType.QUESTION_QUESTION) {
      var right = argument.rightOperand;
      if (isEmptyListLiteral(right)) {
        // ..addAll(things ?? const [])
        // ..addAll(things ?? [])
        elementText = '...?${utils.getNodeText(argument.leftOperand)}';
      }
    } else if (argument is ConditionalExpression) {
      var elseExpression = argument.elseExpression;
      if (isEmptyListLiteral(elseExpression)) {
        // ..addAll(condition ? things : const [])
        // ..addAll(condition ? things : [])
        var conditionText = utils.getNodeText(argument.condition);
        var thenText = utils.getNodeText(argument.thenExpression);
        elementText = 'if ($conditionText) ...$thenText';
      }
    } else if (argument is ListLiteral) {
      // ..addAll([ ... ])
      var elements = argument.elements;
      if (elements.isEmpty) {
        // TODO(brianwilkerson) Consider adding a cleanup for the empty list
        //  case. We can essentially remove the whole invocation because it does
        //  nothing.
        return null;
      }
      var startOffset = elements.first.offset;
      var endOffset = elements.last.end;
      elementText = utils.getText(startOffset, endOffset - startOffset);
      _args = ['addAll'];
      _isInlineInvocation = true;
    }
    elementText ??= '...${utils.getNodeText(argument)}';

    final elementText_final = elementText;
    await builder.addDartFileEdit(file, (builder) {
      if (targetList.elements.isNotEmpty) {
        // ['a']..addAll(['b', 'c']);
        builder.addSimpleInsertion(
          targetList.elements.last.end,
          ', $elementText_final',
        );
      } else {
        // []..addAll(['b', 'c']);
        builder.addSimpleInsertion(
          targetList.leftBracket.end,
          elementText_final,
        );
      }
      builder.addDeletion(range.node(invocation));
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertAddAllToSpread newInstance() => ConvertAddAllToSpread();
}
