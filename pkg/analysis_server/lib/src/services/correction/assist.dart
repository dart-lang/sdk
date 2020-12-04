// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/assist/assist_dart.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';

/// The implementation of [DartAssistContext].
class DartAssistContextImpl implements DartAssistContext {
  @override
  final InstrumentationService instrumentationService;

  @override
  final ChangeWorkspace workspace;

  @override
  final ResolvedUnitResult resolveResult;

  @override
  final int selectionOffset;

  @override
  final int selectionLength;

  DartAssistContextImpl(this.instrumentationService, this.workspace,
      this.resolveResult, this.selectionOffset, this.selectionLength);
}

/// An enumeration of possible assist kinds.
class DartAssistKind {
  static const ADD_DIAGNOSTIC_PROPERTY_REFERENCE = AssistKind(
      'dart.assist.add.diagnosticPropertyReference',
      30,
      'Add a debug reference to this property');
  static const ADD_NOT_NULL_ASSERT = AssistKind(
      'dart.assist.add.notNullAssert', 30, 'Add a not-null assertion');
  static const ADD_RETURN_TYPE =
      AssistKind('dart.assist.add.returnType', 30, 'Add return type');
  static const ADD_TYPE_ANNOTATION =
      AssistKind('dart.assist.add.typeAnnotation', 30, 'Add type annotation');
  static const ASSIGN_TO_LOCAL_VARIABLE = AssistKind(
      'dart.assist.assignToVariable', 30, 'Assign value to new local variable');
  static const CONVERT_CLASS_TO_MIXIN = AssistKind(
      'dart.assist.convert.classToMixin', 30, 'Convert class to a mixin');
  static const CONVERT_DOCUMENTATION_INTO_BLOCK = AssistKind(
      'dart.assist.convert.blockComment',
      30,
      'Convert to block documentation comment');
  static const CONVERT_DOCUMENTATION_INTO_LINE = AssistKind(
      'dart.assist.convert.lineComment',
      30,
      'Convert to line documentation comment');
  static const CONVERT_INTO_ASYNC_BODY = AssistKind(
      'dart.assist.convert.bodyToAsync', 29, 'Convert to async function body');
  static const CONVERT_INTO_BLOCK_BODY = AssistKind(
      'dart.assist.convert.bodyToBlock', 30, 'Convert to block body');
  static const CONVERT_INTO_EXPRESSION_BODY = AssistKind(
      'dart.assist.convert.bodyToExpression', 30, 'Convert to expression body');
  static const CONVERT_INTO_FINAL_FIELD = AssistKind(
      'dart.assist.convert.getterToFinalField', 30, 'Convert to final field');
  static const CONVERT_INTO_FOR_INDEX = AssistKind(
      'dart.assist.convert.forEachToForIndex', 30, 'Convert to for-index loop');
  static const CONVERT_INTO_GENERIC_FUNCTION_SYNTAX = AssistKind(
      'dart.assist.convert.toGenericFunctionSyntax',
      30,
      "Convert into 'Function' syntax");
  static const CONVERT_INTO_GETTER = AssistKind(
      'dart.assist.convert.finalFieldToGetter', 30, 'Convert to getter');
  static const CONVERT_INTO_IS_NOT =
      AssistKind('dart.assist.convert.isNot', 30, 'Convert to is!');
  static const CONVERT_INTO_IS_NOT_EMPTY = AssistKind(
      'dart.assist.convert.isNotEmpty', 30, "Convert to 'isNotEmpty'",
      // todo (pq): unify w/ fix
      associatedErrorCodes: <String>['prefer_is_not_empty']);
  static const CONVERT_PART_OF_TO_URI = AssistKind(
      'dart.assist.convert.partOfToPartUri', 30, 'Convert to use a URI');
  static const CONVERT_TO_DOUBLE_QUOTED_STRING = AssistKind(
      'dart.assist.convert.toDoubleQuotedString',
      30,
      'Convert to double quoted string');
  static const CONVERT_TO_FIELD_PARAMETER = AssistKind(
      'dart.assist.convert.toConstructorFieldParameter',
      30,
      'Convert to field formal parameter');
  static const CONVERT_TO_FOR_ELEMENT = AssistKind(
      'dart.assist.convert.toForElement', 30, "Convert to a 'for' element");
  static const CONVERT_TO_IF_ELEMENT = AssistKind(
      'dart.assist.convert.toIfElement', 30, "Convert to an 'if' element");
  static const CONVERT_TO_INT_LITERAL = AssistKind(
      'dart.assist.convert.toIntLiteral', 30, 'Convert to an int literal');
  static const CONVERT_TO_LIST_LITERAL = AssistKind(
      'dart.assist.convert.toListLiteral', 30, 'Convert to list literal',
      associatedErrorCodes: <String>['prefer_collection_literals']);
  static const CONVERT_TO_MAP_LITERAL = AssistKind(
      'dart.assist.convert.toMapLiteral', 30, 'Convert to map literal',
      associatedErrorCodes: <String>['prefer_collection_literals']);
  static const CONVERT_TO_MULTILINE_STRING = AssistKind(
      'dart.assist.convert.toMultilineString',
      30,
      'Convert to multiline string');
  static const CONVERT_TO_NORMAL_PARAMETER = AssistKind(
      'dart.assist.convert.toConstructorNormalParameter',
      30,
      'Convert to normal parameter');
  static const CONVERT_TO_NULL_AWARE =
      AssistKind('dart.assist.convert.toNullAware', 30, "Convert to use '?.'");
  static const CONVERT_TO_PACKAGE_IMPORT = AssistKind(
      'dart.assist.convert.relativeToPackageImport',
      30,
      "Convert to 'package:' import");
  static const CONVERT_TO_RELATIVE_IMPORT = AssistKind(
      'dart.assist.convert.packageToRelativeImport',
      30,
      'Convert to a relative import');
  static const CONVERT_TO_SET_LITERAL = AssistKind(
      'dart.assist.convert.toSetLiteral', 30, 'Convert to set literal',
      associatedErrorCodes: <String>['prefer_collection_literals']);
  static const CONVERT_TO_SINGLE_QUOTED_STRING = AssistKind(
      'dart.assist.convert.toSingleQuotedString',
      30,
      'Convert to single quoted string');
  static const CONVERT_TO_SPREAD =
      AssistKind('dart.assist.convert.toSpread', 30, 'Convert to a spread');
  static const ENCAPSULATE_FIELD =
      AssistKind('dart.assist.encapsulateField', 30, 'Encapsulate field');
  static const EXCHANGE_OPERANDS =
      AssistKind('dart.assist.exchangeOperands', 30, 'Exchange operands');

  // Flutter assists
  static const FLUTTER_CONVERT_TO_CHILDREN = AssistKind(
      'dart.assist.flutter.convert.childToChildren',
      30,
      'Convert to children:');
  static const FLUTTER_CONVERT_TO_STATEFUL_WIDGET = AssistKind(
      'dart.assist.flutter.convert.toStatefulWidget',
      30,
      'Convert to StatefulWidget');

  // Flutter wrap specific assists
  static const FLUTTER_WRAP_GENERIC =
      AssistKind('dart.assist.flutter.wrap.generic', 31, 'Wrap with widget...');

  static const FLUTTER_WRAP_CENTER =
      AssistKind('dart.assist.flutter.wrap.center', 32, 'Wrap with Center');
  static const FLUTTER_WRAP_COLUMN =
      AssistKind('dart.assist.flutter.wrap.column', 32, 'Wrap with Column');
  static const FLUTTER_WRAP_CONTAINER = AssistKind(
      'dart.assist.flutter.wrap.container', 32, 'Wrap with Container');
  static const FLUTTER_WRAP_PADDING =
      AssistKind('dart.assist.flutter.wrap.padding', 32, 'Wrap with Padding');
  static const FLUTTER_WRAP_ROW =
      AssistKind('dart.assist.flutter.wrap.row', 32, 'Wrap with Row');
  static const FLUTTER_WRAP_SIZED_BOX =
      AssistKind('dart.assist.flutter.wrap.sizedBox', 32, 'Wrap with SizedBox');
  static const FLUTTER_WRAP_STREAM_BUILDER = AssistKind(
      'dart.assist.flutter.wrap.streamBuilder', 32, 'Wrap with StreamBuilder');

  // Flutter re-order assists
  static const FLUTTER_SWAP_WITH_CHILD =
      AssistKind('dart.assist.flutter.swap.withChild', 33, 'Swap with child');
  static const FLUTTER_SWAP_WITH_PARENT =
      AssistKind('dart.assist.flutter.swap.withParent', 33, 'Swap with parent');
  static const FLUTTER_MOVE_DOWN =
      AssistKind('dart.assist.flutter.move.down', 34, 'Move widget down');
  static const FLUTTER_MOVE_UP =
      AssistKind('dart.assist.flutter.move.up', 34, 'Move widget up');

  // Flutter remove assist
  static const FLUTTER_REMOVE_WIDGET =
      AssistKind('dart.assist.flutter.removeWidget', 35, 'Remove this widget');

  static const IMPORT_ADD_SHOW = AssistKind(
      'dart.assist.add.showCombinator', 30, "Add explicit 'show' combinator");
  static const INLINE_INVOCATION =
      AssistKind('dart.assist.inline', 30, "Inline invocation of '{0}'");
  static const INTRODUCE_LOCAL_CAST_TYPE = AssistKind(
      'dart.assist.introduceLocalCast',
      30,
      'Introduce new local with tested type');
  static const INVERT_IF_STATEMENT =
      AssistKind('dart.assist.invertIf', 30, "Invert 'if' statement");
  static const JOIN_IF_WITH_INNER = AssistKind('dart.assist.joinWithInnerIf',
      30, "Join 'if' statement with inner 'if' statement");
  static const JOIN_IF_WITH_OUTER = AssistKind('dart.assist.joinWithOuterIf',
      30, "Join 'if' statement with outer 'if' statement");
  static const JOIN_VARIABLE_DECLARATION = AssistKind(
      'dart.assist.joinVariableDeclaration', 30, 'Join variable declaration');
  static const REMOVE_TYPE_ANNOTATION = AssistKind(
      // todo (pq): unify w/ fix
      'dart.assist.remove.typeAnnotation',
      29,
      'Remove type annotation');
  static const REPLACE_CONDITIONAL_WITH_IF_ELSE = AssistKind(
      'dart.assist.convert.conditionalToIfElse',
      30,
      "Replace conditional with 'if-else'");
  static const REPLACE_IF_ELSE_WITH_CONDITIONAL = AssistKind(
      'dart.assist.convert.ifElseToConditional',
      30,
      "Replace 'if-else' with conditional ('c ? x : y')");
  static const REPLACE_WITH_VAR = AssistKind(
      'dart.assist.replace.withVar', 30, "Replace type annotation with 'var'");
  static const SHADOW_FIELD = AssistKind('dart.assist.shadowField', 30,
      'Create a local variable that shadows the field');
  static const SORT_CHILD_PROPERTY_LAST = AssistKind(
      'dart.assist.sort.child.properties.last',
      30,
      'Move child property to end of arguments');
  static const SPLIT_AND_CONDITION =
      AssistKind('dart.assist.splitIfConjunction', 30, 'Split && condition');
  static const SPLIT_VARIABLE_DECLARATION = AssistKind(
      'dart.assist.splitVariableDeclaration', 30, 'Split variable declaration');
  static const SURROUND_WITH_BLOCK =
      AssistKind('dart.assist.surround.block', 22, 'Surround with block');
  static const SURROUND_WITH_DO_WHILE = AssistKind(
      'dart.assist.surround.doWhile', 27, "Surround with 'do-while'");
  static const SURROUND_WITH_FOR =
      AssistKind('dart.assist.surround.forEach', 26, "Surround with 'for'");
  static const SURROUND_WITH_FOR_IN =
      AssistKind('dart.assist.surround.forIn', 25, "Surround with 'for-in'");
  static const SURROUND_WITH_IF =
      AssistKind('dart.assist.surround.if', 23, "Surround with 'if'");
  static const SURROUND_WITH_SET_STATE = AssistKind(
      'dart.assist.surround.setState', 27, "Surround with 'setState'");
  static const SURROUND_WITH_TRY_CATCH = AssistKind(
      'dart.assist.surround.tryCatch', 28, "Surround with 'try-catch'");
  static const SURROUND_WITH_TRY_FINALLY = AssistKind(
      'dart.assist.surround.tryFinally', 29, "Surround with 'try-finally'");
  static const SURROUND_WITH_WHILE =
      AssistKind('dart.assist.surround.while', 24, "Surround with 'while'");
  static const USE_CURLY_BRACES =
      AssistKind('dart.assist.surround.curlyBraces', 30, 'Use curly braces');
}
