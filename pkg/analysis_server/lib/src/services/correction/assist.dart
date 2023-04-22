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
    DartAssistKindPriority.DEFAULT,
    'Add a debug reference to this property',
  );
  static const ADD_NOT_NULL_ASSERT = AssistKind(
    'dart.assist.add.notNullAssert',
    DartAssistKindPriority.DEFAULT,
    'Add a not-null assertion',
  );
  static const ADD_RETURN_TYPE = AssistKind(
    'dart.assist.add.returnType',
    DartAssistKindPriority.DEFAULT,
    'Add return type',
  );
  static const ADD_TYPE_ANNOTATION = AssistKind(
    'dart.assist.add.typeAnnotation',
    DartAssistKindPriority.DEFAULT,
    'Add type annotation',
  );
  static const ASSIGN_TO_LOCAL_VARIABLE = AssistKind(
    'dart.assist.assignToVariable',
    DartAssistKindPriority.DEFAULT,
    'Assign value to new local variable',
  );
  static const CONVERT_CLASS_TO_ENUM = AssistKind(
    'dart.assist.convert.classToEnum',
    DartAssistKindPriority.DEFAULT,
    'Convert class to an enum',
  );
  static const CONVERT_CLASS_TO_MIXIN = AssistKind(
    'dart.assist.convert.classToMixin',
    DartAssistKindPriority.DEFAULT,
    'Convert class to a mixin',
  );
  static const CONVERT_DOCUMENTATION_INTO_BLOCK = AssistKind(
    'dart.assist.convert.blockComment',
    DartAssistKindPriority.DEFAULT,
    'Convert to block documentation comment',
  );
  static const CONVERT_DOCUMENTATION_INTO_LINE = AssistKind(
    'dart.assist.convert.lineComment',
    DartAssistKindPriority.DEFAULT,
    'Convert to line documentation comment',
  );
  static const CONVERT_INTO_ASYNC_BODY = AssistKind(
    'dart.assist.convert.bodyToAsync',
    DartAssistKindPriority.PRIORITY,
    'Convert to async function body',
  );
  static const CONVERT_INTO_BLOCK_BODY = AssistKind(
    'dart.assist.convert.bodyToBlock',
    DartAssistKindPriority.DEFAULT,
    'Convert to block body',
  );
  static const CONVERT_INTO_EXPRESSION_BODY = AssistKind(
    'dart.assist.convert.bodyToExpression',
    DartAssistKindPriority.DEFAULT,
    'Convert to expression body',
  );
  static const CONVERT_INTO_FINAL_FIELD = AssistKind(
    'dart.assist.convert.getterToFinalField',
    DartAssistKindPriority.DEFAULT,
    'Convert to final field',
  );
  static const CONVERT_INTO_FOR_INDEX = AssistKind(
    'dart.assist.convert.forEachToForIndex',
    DartAssistKindPriority.DEFAULT,
    'Convert to for-index loop',
  );
  static const CONVERT_INTO_GENERIC_FUNCTION_SYNTAX = AssistKind(
    'dart.assist.convert.toGenericFunctionSyntax',
    DartAssistKindPriority.DEFAULT,
    "Convert into 'Function' syntax",
  );
  static const CONVERT_INTO_GETTER = AssistKind(
    'dart.assist.convert.finalFieldToGetter',
    DartAssistKindPriority.DEFAULT,
    'Convert to getter',
  );
  static const CONVERT_INTO_IS_NOT = AssistKind(
    'dart.assist.convert.isNot',
    DartAssistKindPriority.DEFAULT,
    'Convert to is!',
  );
  static const CONVERT_INTO_IS_NOT_EMPTY = AssistKind(
    'dart.assist.convert.isNotEmpty',
    DartAssistKindPriority.DEFAULT,
    "Convert to 'isNotEmpty'",
  );
  static const CONVERT_PART_OF_TO_URI = AssistKind(
    'dart.assist.convert.partOfToPartUri',
    DartAssistKindPriority.DEFAULT,
    'Convert to use a URI',
  );
  static const CONVERT_TO_DOUBLE_QUOTED_STRING = AssistKind(
    'dart.assist.convert.toDoubleQuotedString',
    DartAssistKindPriority.DEFAULT,
    'Convert to double quoted string',
  );
  static const CONVERT_TO_FIELD_PARAMETER = AssistKind(
    'dart.assist.convert.toConstructorFieldParameter',
    DartAssistKindPriority.DEFAULT,
    'Convert to field formal parameter',
  );
  static const CONVERT_TO_FOR_ELEMENT = AssistKind(
    'dart.assist.convert.toForElement',
    DartAssistKindPriority.DEFAULT,
    "Convert to a 'for' element",
  );
  static const CONVERT_TO_IF_CASE_STATEMENT = AssistKind(
    'dart.assist.convert.ifCaseStatement',
    DartAssistKindPriority.DEFAULT,
    "Convert to 'if-case' statement",
  );
  static const CONVERT_TO_IF_CASE_STATEMENT_CHAIN = AssistKind(
    'dart.assist.convert.ifCaseStatementChain',
    DartAssistKindPriority.DEFAULT,
    "Convert to 'if-case' statement chain",
  );
  static const CONVERT_TO_IF_ELEMENT = AssistKind(
    'dart.assist.convert.toIfElement',
    DartAssistKindPriority.DEFAULT,
    "Convert to an 'if' element",
  );
  static const CONVERT_TO_INT_LITERAL = AssistKind(
    'dart.assist.convert.toIntLiteral',
    DartAssistKindPriority.DEFAULT,
    'Convert to an int literal',
  );
  static const CONVERT_TO_MAP_LITERAL = AssistKind(
    'dart.assist.convert.toMapLiteral',
    DartAssistKindPriority.DEFAULT,
    'Convert to map literal',
  );
  static const CONVERT_TO_MULTILINE_STRING = AssistKind(
    'dart.assist.convert.toMultilineString',
    DartAssistKindPriority.DEFAULT,
    'Convert to multiline string',
  );
  static const CONVERT_TO_NORMAL_PARAMETER = AssistKind(
    'dart.assist.convert.toConstructorNormalParameter',
    DartAssistKindPriority.DEFAULT,
    'Convert to normal parameter',
  );
  static const CONVERT_TO_NULL_AWARE = AssistKind(
    'dart.assist.convert.toNullAware',
    DartAssistKindPriority.DEFAULT,
    "Convert to use '?.'",
  );
  static const CONVERT_TO_PACKAGE_IMPORT = AssistKind(
    'dart.assist.convert.relativeToPackageImport',
    DartAssistKindPriority.DEFAULT,
    "Convert to 'package:' import",
  );
  static const CONVERT_TO_RELATIVE_IMPORT = AssistKind(
    'dart.assist.convert.packageToRelativeImport',
    DartAssistKindPriority.DEFAULT,
    'Convert to a relative import',
  );
  static const CONVERT_TO_SET_LITERAL = AssistKind(
    'dart.assist.convert.toSetLiteral',
    DartAssistKindPriority.DEFAULT,
    'Convert to set literal',
  );
  static const CONVERT_TO_SINGLE_QUOTED_STRING = AssistKind(
    'dart.assist.convert.toSingleQuotedString',
    DartAssistKindPriority.DEFAULT,
    'Convert to single quoted string',
  );
  static const CONVERT_TO_SPREAD = AssistKind(
    'dart.assist.convert.toSpread',
    DartAssistKindPriority.DEFAULT,
    'Convert to a spread',
  );
  static const CONVERT_TO_SUPER_PARAMETERS = AssistKind(
    'dart.assist.convert.toSuperParameters',
    DartAssistKindPriority.DEFAULT,
    'Convert to using super parameters',
  );
  static const CONVERT_TO_SWITCH_EXPRESSION = AssistKind(
    'dart.assist.convert.switchExpression',
    DartAssistKindPriority.DEFAULT,
    'Convert to switch expression',
  );
  static const DESTRUCTURE_LOCAL_VARIABLE_ASSIGNMENT = AssistKind(
    'dart.assist.destructureLocalVariableAssignment',
    DartAssistKindPriority.DEFAULT,
    'Destructure variable assignment',
  );
  static const CONVERT_TO_SWITCH_STATEMENT = AssistKind(
    'dart.assist.convert.switchStatement',
    DartAssistKindPriority.DEFAULT,
    'Convert to switch statement',
  );
  static const ENCAPSULATE_FIELD = AssistKind(
    'dart.assist.encapsulateField',
    DartAssistKindPriority.DEFAULT,
    'Encapsulate field',
  );
  static const EXCHANGE_OPERANDS = AssistKind(
    'dart.assist.exchangeOperands',
    DartAssistKindPriority.DEFAULT,
    'Exchange operands',
  );
  static const FLUTTER_CONVERT_TO_CHILDREN = AssistKind(
    'dart.assist.flutter.convert.childToChildren',
    DartAssistKindPriority.DEFAULT,
    'Convert to children:',
  );
  static const FLUTTER_CONVERT_TO_STATEFUL_WIDGET = AssistKind(
    'dart.assist.flutter.convert.toStatefulWidget',
    DartAssistKindPriority.DEFAULT,
    'Convert to StatefulWidget',
  );
  static const FLUTTER_CONVERT_TO_STATELESS_WIDGET = AssistKind(
    'dart.assist.flutter.convert.toStatelessWidget',
    DartAssistKindPriority.DEFAULT,
    'Convert to StatelessWidget',
  );
  static const FLUTTER_WRAP_GENERIC = AssistKind(
    'dart.assist.flutter.wrap.generic',
    DartAssistKindPriority.FLUTTER_WRAP_GENERAL,
    'Wrap with widget...',
  );
  static const FLUTTER_WRAP_BUILDER = AssistKind(
    'dart.assist.flutter.wrap.builder',
    DartAssistKindPriority.FLUTTER_WRAP_SPECIFIC,
    'Wrap with Builder',
  );
  static const FLUTTER_WRAP_CENTER = AssistKind(
    'dart.assist.flutter.wrap.center',
    DartAssistKindPriority.FLUTTER_WRAP_SPECIFIC,
    'Wrap with Center',
  );
  static const FLUTTER_WRAP_COLUMN = AssistKind(
    'dart.assist.flutter.wrap.column',
    DartAssistKindPriority.FLUTTER_WRAP_SPECIFIC,
    'Wrap with Column',
  );
  static const FLUTTER_WRAP_CONTAINER = AssistKind(
    'dart.assist.flutter.wrap.container',
    DartAssistKindPriority.FLUTTER_WRAP_SPECIFIC,
    'Wrap with Container',
  );
  static const FLUTTER_WRAP_PADDING = AssistKind(
    'dart.assist.flutter.wrap.padding',
    DartAssistKindPriority.FLUTTER_WRAP_SPECIFIC,
    'Wrap with Padding',
  );
  static const FLUTTER_WRAP_ROW = AssistKind(
    'dart.assist.flutter.wrap.row',
    DartAssistKindPriority.FLUTTER_WRAP_SPECIFIC,
    'Wrap with Row',
  );
  static const FLUTTER_WRAP_SIZED_BOX = AssistKind(
    'dart.assist.flutter.wrap.sizedBox',
    DartAssistKindPriority.FLUTTER_WRAP_SPECIFIC,
    'Wrap with SizedBox',
  );
  static const FLUTTER_WRAP_STREAM_BUILDER = AssistKind(
    'dart.assist.flutter.wrap.streamBuilder',
    DartAssistKindPriority.FLUTTER_WRAP_SPECIFIC,
    'Wrap with StreamBuilder',
  );
  static const FLUTTER_SWAP_WITH_CHILD = AssistKind(
    'dart.assist.flutter.swap.withChild',
    DartAssistKindPriority.FLUTTER_SWAP,
    'Swap with child',
  );
  static const FLUTTER_SWAP_WITH_PARENT = AssistKind(
    'dart.assist.flutter.swap.withParent',
    DartAssistKindPriority.FLUTTER_SWAP,
    'Swap with parent',
  );
  static const FLUTTER_MOVE_DOWN = AssistKind(
    'dart.assist.flutter.move.down',
    DartAssistKindPriority.FLUTTER_MOVE,
    'Move widget down',
  );
  static const FLUTTER_MOVE_UP = AssistKind(
    'dart.assist.flutter.move.up',
    DartAssistKindPriority.FLUTTER_MOVE,
    'Move widget up',
  );
  static const FLUTTER_REMOVE_WIDGET = AssistKind(
    'dart.assist.flutter.removeWidget',
    DartAssistKindPriority.FLUTTER_REMOVE,
    'Remove this widget',
  );
  static const IMPORT_ADD_SHOW = AssistKind(
    'dart.assist.add.showCombinator',
    DartAssistKindPriority.DEFAULT,
    "Add explicit 'show' combinator",
  );
  static const INLINE_INVOCATION = AssistKind(
    'dart.assist.inline',
    DartAssistKindPriority.DEFAULT,
    "Inline invocation of '{0}'",
  );
  static const INVERT_IF_STATEMENT = AssistKind(
    'dart.assist.invertIf',
    DartAssistKindPriority.DEFAULT,
    "Invert 'if' statement",
  );
  static const JOIN_IF_WITH_INNER = AssistKind(
    'dart.assist.joinWithInnerIf',
    DartAssistKindPriority.DEFAULT,
    "Join 'if' statement with inner 'if' statement",
  );
  static const JOIN_IF_WITH_OUTER = AssistKind(
    'dart.assist.joinWithOuterIf',
    DartAssistKindPriority.DEFAULT,
    "Join 'if' statement with outer 'if' statement",
  );
  static const JOIN_VARIABLE_DECLARATION = AssistKind(
    'dart.assist.joinVariableDeclaration',
    DartAssistKindPriority.DEFAULT,
    'Join variable declaration',
  );
  static const REMOVE_TYPE_ANNOTATION = AssistKind(
    // todo (pq): unify w/ fix
    'dart.assist.remove.typeAnnotation',
    DartAssistKindPriority.PRIORITY,
    'Remove type annotation',
  );
  static const REPLACE_CONDITIONAL_WITH_IF_ELSE = AssistKind(
    'dart.assist.convert.conditionalToIfElse',
    DartAssistKindPriority.DEFAULT,
    "Replace conditional with 'if-else'",
  );
  static const REPLACE_IF_ELSE_WITH_CONDITIONAL = AssistKind(
    'dart.assist.convert.ifElseToConditional',
    DartAssistKindPriority.DEFAULT,
    "Replace 'if-else' with conditional ('c ? x : y')",
  );
  static const REPLACE_WITH_VAR = AssistKind(
    'dart.assist.replace.withVar',
    DartAssistKindPriority.DEFAULT,
    "Replace type annotation with 'var'",
  );
  static const SHADOW_FIELD = AssistKind(
    'dart.assist.shadowField',
    DartAssistKindPriority.DEFAULT,
    'Create a local variable that shadows the field',
  );
  static const SORT_CHILD_PROPERTY_LAST = AssistKind(
    'dart.assist.sort.child.properties.last',
    DartAssistKindPriority.DEFAULT,
    'Move child property to end of arguments',
  );
  static const SPLIT_AND_CONDITION = AssistKind(
    'dart.assist.splitIfConjunction',
    DartAssistKindPriority.DEFAULT,
    'Split && condition',
  );
  static const SPLIT_VARIABLE_DECLARATION = AssistKind(
    'dart.assist.splitVariableDeclaration',
    DartAssistKindPriority.DEFAULT,
    'Split variable declaration',
  );
  static const SURROUND_WITH_BLOCK = AssistKind(
    'dart.assist.surround.block',
    DartAssistKindPriority.SURROUND_WITH_BLOCK,
    'Surround with block',
  );
  static const SURROUND_WITH_DO_WHILE = AssistKind(
    'dart.assist.surround.doWhile',
    DartAssistKindPriority.SURROUND_WITH_DO_WHILE,
    "Surround with 'do-while'",
  );
  static const SURROUND_WITH_FOR = AssistKind(
    'dart.assist.surround.forEach',
    DartAssistKindPriority.SURROUND_WITH_FOR,
    "Surround with 'for'",
  );
  static const SURROUND_WITH_FOR_IN = AssistKind(
    'dart.assist.surround.forIn',
    DartAssistKindPriority.SURROUND_WITH_FOR_IN,
    "Surround with 'for-in'",
  );
  static const SURROUND_WITH_IF = AssistKind(
    'dart.assist.surround.if',
    DartAssistKindPriority.SURROUND_WITH_IF,
    "Surround with 'if'",
  );
  static const SURROUND_WITH_SET_STATE = AssistKind(
    'dart.assist.surround.setState',
    DartAssistKindPriority.SURROUND_WITH_SET_STATE,
    "Surround with 'setState'",
  );
  static const SURROUND_WITH_TRY_CATCH = AssistKind(
    'dart.assist.surround.tryCatch',
    DartAssistKindPriority.SURROUND_WITH_TRY_CATCH,
    "Surround with 'try-catch'",
  );
  static const SURROUND_WITH_TRY_FINALLY = AssistKind(
    'dart.assist.surround.tryFinally',
    DartAssistKindPriority.SURROUND_WITH_TRY_FINALLY,
    "Surround with 'try-finally'",
  );
  static const SURROUND_WITH_WHILE = AssistKind(
    'dart.assist.surround.while',
    DartAssistKindPriority.SURROUND_WITH_WHILE,
    "Surround with 'while'",
  );
  static const UNWRAP_IF_BODY = AssistKind(
    'dart.assist.unwrap.if',
    DartAssistKindPriority.DEFAULT,
    "Unwrap 'if' body",
  );
  static const USE_CURLY_BRACES = AssistKind(
    'dart.assist.surround.curlyBraces',
    DartAssistKindPriority.DEFAULT,
    'Use curly braces',
  );
}

/// The priorities associated with various groups of assists.
class DartAssistKindPriority {
  static const int FLUTTER_REMOVE = 25;
  static const int FLUTTER_MOVE = 26;
  static const int FLUTTER_SWAP = 27;
  static const int FLUTTER_WRAP_SPECIFIC = 28;
  static const int FLUTTER_WRAP_GENERAL = 29;
  static const int DEFAULT = 30;
  static const int PRIORITY = 31;
  static const int SURROUND_WITH_TRY_FINALLY = 31;
  static const int SURROUND_WITH_TRY_CATCH = 32;
  static const int SURROUND_WITH_DO_WHILE = 33;
  static const int SURROUND_WITH_SET_STATE = 33;
  static const int SURROUND_WITH_FOR = 34;
  static const int SURROUND_WITH_FOR_IN = 35;
  static const int SURROUND_WITH_WHILE = 36;
  static const int SURROUND_WITH_IF = 37;
  static const int SURROUND_WITH_BLOCK = 38;
}
