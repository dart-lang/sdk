// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertAddAllToSpread extends ResolvedCorrectionProducer {
  /// The arguments used to compose the message.
  List<String> _args = [];

  /// A flag indicating whether the change that was built is one that inlines
  /// the elements of another list into the target list.
  final bool _isInlineInvocation;

  final MethodInvocation? _invocation;

  factory ConvertAddAllToSpread({required CorrectionProducerContext context}) {
    if (context is StubCorrectionProducerContext) {
      return ConvertAddAllToSpread._(
        context: context,
        invocation: null,
        isInlineInvocation: false,
      );
    }

    var name = context.node;
    MethodInvocation? invocation;
    var isInlineInvocation = false;
    if (name case SimpleIdentifier(parent: MethodInvocation parent)) {
      invocation = parent;

      if (name != invocation.methodName ||
          name.name != 'addAll' ||
          !invocation.isCascaded ||
          invocation.argumentList.arguments.length != 1) {
        return ConvertAddAllToSpread._(
          context: context,
          invocation: null,
          isInlineInvocation: false,
        );
      }

      var argument = invocation.argumentList.arguments[0];
      if (argument is ListLiteral) {
        isInlineInvocation = true;
      }
    }

    return ConvertAddAllToSpread._(
      context: context,
      invocation: invocation,
      isInlineInvocation: isInlineInvocation,
    );
  }

  ConvertAddAllToSpread._({
    required super.context,
    required MethodInvocation? invocation,
    required bool isInlineInvocation,
  }) : _invocation = invocation,
       _isInlineInvocation = isInlineInvocation;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  List<String> get assistArguments => _args;

  @override
  AssistKind get assistKind => _isInlineInvocation
      ? DartAssistKind.inlineInvocation
      : DartAssistKind.convertToSpread;

  @override
  List<String> get fixArguments => _args;

  @override
  FixKind get fixKind => _isInlineInvocation
      ? DartFixKind.inlineInvocation
      : DartFixKind.convertToSpread;

  @override
  FixKind get multiFixKind => _isInlineInvocation
      ? DartFixKind.inlineInvocationMulti
      : DartFixKind.convertToSpreadMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var invocation = _invocation;
    if (invocation == null) {
      return;
    }

    var cascade = invocation.thisOrAncestorOfType<CascadeExpression>();
    if (cascade == null) {
      return;
    }

    var sections = cascade.cascadeSections;
    var targetList = cascade.target;
    if (targetList is! ListLiteral || sections[0] != invocation) {
      // TODO(brianwilkerson): Consider extending this to handle set literals.
      return;
    }

    var argument = invocation.argumentList.arguments[0];
    assert(argument is ListLiteral == _isInlineInvocation);
    String elementText;
    if (argument is ListLiteral) {
      // ..addAll([ ... ])
      var elements = argument.elements;
      if (elements.isEmpty) {
        // TODO(brianwilkerson): Consider adding a cleanup for the empty list
        //  case. We can essentially remove the whole invocation because it does
        //  nothing.
        return;
      }
      var startOffset = elements.first.offset;
      var endOffset = elements.last.end;
      elementText = utils.getText(startOffset, endOffset - startOffset);
      _args = ['addAll'];
    } else {
      elementText = _computeElementText(argument);
    }

    await builder.addDartFileEdit(file, (builder) {
      if (targetList.elements.isNotEmpty) {
        // ['a']..addAll(['b', 'c']);
        builder.addSimpleInsertion(
          targetList.elements.last.end,
          ', $elementText',
        );
      } else {
        // []..addAll(['b', 'c']);
        builder.addSimpleInsertion(targetList.leftBracket.end, elementText);
      }
      builder.addDeletion(range.node(invocation));
    });
  }

  String _computeElementText(Expression argument) {
    if (argument is BinaryExpression &&
        argument.operator.type == TokenType.QUESTION_QUESTION) {
      var right = argument.rightOperand;
      if (right.isEmptyListLiteral) {
        // ..addAll(things ?? const [])
        // ..addAll(things ?? [])
        return '...?${utils.getNodeText(argument.leftOperand)}';
      }
    } else if (argument is ConditionalExpression) {
      var elseExpression = argument.elseExpression;
      if (elseExpression.isEmptyListLiteral) {
        // ..addAll(condition ? things : const [])
        // ..addAll(condition ? things : [])
        var conditionText = utils.getNodeText(argument.condition);
        var thenText = utils.getNodeText(argument.thenExpression);
        return 'if ($conditionText) ...$thenText';
      }
    }
    return '...${utils.getNodeText(argument)}';
  }
}

extension on Expression {
  bool get isEmptyListLiteral {
    var self = this;
    return self is ListLiteral && self.elements.isEmpty;
  }
}
