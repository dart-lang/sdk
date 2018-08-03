// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/utilities/assist/assist.dart';

/**
 * An enumeration of possible assist kinds.
 */
class DartAssistKind {
  static const ADD_TYPE_ANNOTATION = const AssistKind(
      'dart.assist.addTypeAnnotation', 30, "Add type annotation");
  static const ASSIGN_TO_LOCAL_VARIABLE = const AssistKind(
      'dart.assist.assignToVariable', 30, "Assign value to new local variable");
  static const CONVERT_DOCUMENTATION_INTO_BLOCK = const AssistKind(
      'dart.assist.convert.blockComment',
      30,
      "Convert to block documentation comment");
  static const CONVERT_DOCUMENTATION_INTO_LINE = const AssistKind(
      'dart.assist.convert.lineComment',
      30,
      "Convert to line documentation comment");
  static const CONVERT_INTO_ASYNC_BODY = const AssistKind(
      'dart.assist.convert.bodyToAsync', 30, "Convert to async function body");
  static const CONVERT_INTO_BLOCK_BODY = const AssistKind(
      'dart.assist.convert.bodyToBlock', 30, "Convert to block body");
  static const CONVERT_INTO_EXPRESSION_BODY = const AssistKind(
      'dart.assist.convert.bodyToExpression', 30, "Convert to expression body");
  static const CONVERT_INTO_FOR_INDEX = const AssistKind(
      'dart.assist.convert.forEachToForIndex', 30, "Convert to for-index loop");
  static const CONVERT_INTO_FINAL_FIELD = const AssistKind(
      'dart.assist.convert.getterToFinalField', 30, "Convert to final field");
  static const CONVERT_INTO_GENERIC_FUNCTION_SYNTAX = const AssistKind(
      'dart.assist.convert.toGenericFunctionSyntax',
      30,
      "Convert into 'Function' syntax");
  static const CONVERT_INTO_GETTER = const AssistKind(
      'dart.assist.convert.finalFieldToGetter', 30, "Convert to getter");
  static const CONVERT_INTO_IS_NOT =
      const AssistKind('dart.assist.convert.isNot', 30, "Convert to is!");
  static const CONVERT_INTO_IS_NOT_EMPTY = const AssistKind(
      'dart.assist.convert.isNotEmpty', 30, "Convert to 'isNotEmpty'");
  static const CONVERT_PART_OF_TO_URI = const AssistKind(
      'dart.assist.convert.partOfToPartUri', 30, "Convert to use a URI");
  static const CONVERT_TO_DOUBLE_QUOTED_STRING = const AssistKind(
      'dart.assist.convert.toDoubleQuotedString',
      30,
      "Convert to double quoted string");
  static const CONVERT_TO_FIELD_PARAMETER = const AssistKind(
      'dart.assist.convert.toConstructorFieldParameter',
      30,
      "Convert to field formal parameter");
  static const CONVERT_TO_NORMAL_PARAMETER = const AssistKind(
      'dart.assist.convert.toConstructorNormalParameter',
      30,
      "Convert to normal parameter");
  static const CONVERT_TO_SINGLE_QUOTED_STRING = const AssistKind(
      'dart.assist.convert.toSingleQuotedString',
      30,
      "Convert to single quoted string");
  static const ENCAPSULATE_FIELD =
      const AssistKind('dart.assist.encapsulateField', 30, "Encapsulate field");
  static const EXCHANGE_OPERANDS =
      const AssistKind('dart.assist.exchangeOperands', 30, "Exchange operands");
  static const FLUTTER_CONVERT_TO_CHILDREN = const AssistKind(
      'dart.assist.flutter.convert.childToChildren',
      30,
      "Convert to children:");
  static const FLUTTER_CONVERT_TO_STATEFUL_WIDGET = const AssistKind(
      'dart.assist.flutter.convert.toStatefulWidget',
      30,
      "Convert to StatefulWidget");
  static const FLUTTER_MOVE_DOWN =
      const AssistKind('dart.assist.flutter.move.down', 30, "Move widget down");
  static const FLUTTER_MOVE_UP =
      const AssistKind('dart.assist.flutter.move.up', 30, "Move widget up");
  static const FLUTTER_REMOVE_WIDGET =
      const AssistKind('dart.assist.flutter.removeWidget', 30, "Remove widget");
  static const FLUTTER_SWAP_WITH_CHILD = const AssistKind(
      'dart.assist.flutter.swap.withChild', 30, "Swap with child");
  static const FLUTTER_SWAP_WITH_PARENT = const AssistKind(
      'dart.assist.flutter.swap.withParent', 30, "Swap with parent");
  static const FLUTTER_WRAP_CENTER =
      const AssistKind('dart.assist.flutter.wrap.center', 30, "Center widget");
  static const FLUTTER_WRAP_COLUMN = const AssistKind(
      'dart.assist.flutter.wrap.column', 30, "Wrap with Column");
  static const FLUTTER_WRAP_GENERIC = const AssistKind(
      'dart.assist.flutter.wrap.generic', 30, "Wrap with new widget");
  static const FLUTTER_WRAP_PADDING =
      const AssistKind('dart.assist.flutter.wrap.padding', 30, "Add padding");
  static const FLUTTER_WRAP_ROW =
      const AssistKind('dart.assist.flutter.wrap.row', 30, "Wrap with Row");
  static const IMPORT_ADD_SHOW = const AssistKind(
      'dart.assist.addShowCombinator', 30, "Add explicit 'show' combinator");
  static const INTRODUCE_LOCAL_CAST_TYPE = const AssistKind(
      'dart.assist.introduceLocalCast',
      30,
      "Introduce new local with tested type");
  static const INVERT_IF_STATEMENT =
      const AssistKind('dart.assist.invertIf', 30, "Invert 'if' statement");
  static const JOIN_IF_WITH_INNER = const AssistKind(
      'dart.assist.joinWithInnerIf',
      30,
      "Join 'if' statement with inner 'if' statement");
  static const JOIN_IF_WITH_OUTER = const AssistKind(
      'dart.assist.joinWithOuterIf',
      30,
      "Join 'if' statement with outer 'if' statement");
  static const JOIN_VARIABLE_DECLARATION = const AssistKind(
      'dart.assist.joinVariableDeclaration', 30, "Join variable declaration");
  static const REMOVE_TYPE_ANNOTATION = const AssistKind(
      'dart.assist.removeTypeAnnotation', 29, "Remove type annotation");
  static const REPLACE_CONDITIONAL_WITH_IF_ELSE = const AssistKind(
      'dart.assist.convert.conditionalToIfElse',
      30,
      "Replace conditional with 'if-else'");
  static const REPLACE_IF_ELSE_WITH_CONDITIONAL = const AssistKind(
      'dart.assist.convert.ifElseToConditional',
      30,
      "Replace 'if-else' with conditional ('c ? x : y')");
  static const SPLIT_AND_CONDITION = const AssistKind(
      'dart.assist.splitIfConjunction', 30, "Split && condition");
  static const SPLIT_VARIABLE_DECLARATION = const AssistKind(
      'dart.assist.splitVariableDeclaration', 30, "Split variable declaration");
  static const SURROUND_WITH_BLOCK =
      const AssistKind('dart.assist.surround.block', 22, "Surround with block");
  static const SURROUND_WITH_DO_WHILE = const AssistKind(
      'dart.assist.surround.doWhile', 27, "Surround with 'do-while'");
  static const SURROUND_WITH_FOR = const AssistKind(
      'dart.assist.surround.forEach', 26, "Surround with 'for'");
  static const SURROUND_WITH_FOR_IN = const AssistKind(
      'dart.assist.surround.forIn', 25, "Surround with 'for-in'");
  static const SURROUND_WITH_IF =
      const AssistKind('dart.assist.surround.if', 23, "Surround with 'if'");
  static const SURROUND_WITH_TRY_CATCH = const AssistKind(
      'dart.assist.surround.tryCatch', 28, "Surround with 'try-catch'");
  static const SURROUND_WITH_TRY_FINALLY = const AssistKind(
      'dart.assist.surround.tryFinally', 29, "Surround with 'try-finally'");
  static const SURROUND_WITH_WHILE = const AssistKind(
      'dart.assist.surround.while', 24, "Surround with 'while'");
}
