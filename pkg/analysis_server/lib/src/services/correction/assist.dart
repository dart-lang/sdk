// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/utilities/assist/assist.dart';

/// An enumeration of possible assist kinds.
abstract final class DartAssistKind {
  static const addDiagnosticPropertyReference = AssistKind(
    'dart.assist.add.diagnosticPropertyReference',
    DartAssistKindPriority.default_,
    'Add a debug reference to this property',
  );
  static const addDigitSeparators = AssistKind(
    'dart.assist.add.digitSeparators',
    DartAssistKindPriority.default_,
    'Add digit separators',
  );
  static const addLate = AssistKind(
    'dart.assist.add.late',
    DartAssistKindPriority.default_,
    "Add 'late' modifier",
  );
  static const addReturnType = AssistKind(
    'dart.assist.add.returnType',
    DartAssistKindPriority.default_,
    'Add return type',
  );
  static const addTypeAnnotation = AssistKind(
    'dart.assist.add.typeAnnotation',
    DartAssistKindPriority.default_,
    'Add type annotation',
  );
  static const assignToLocalVariable = AssistKind(
    'dart.assist.assignToVariable',
    DartAssistKindPriority.default_,
    'Assign value to new local variable',
  );
  static const bindAllToFields = AssistKind(
    'dart.assist.bindAllToFields',
    DartAssistKindPriority.default_,
    'Bind all parameters to fields',
  );
  static const bindToField = AssistKind(
    'dart.assist.bindToField',
    DartAssistKindPriority.default_,
    'Bind parameter to field',
  );
  static const convertClassToEnum = AssistKind(
    'dart.assist.convert.classToEnum',
    DartAssistKindPriority.default_,
    'Convert class to an enum',
  );
  static const convertClassToMixin = AssistKind(
    'dart.assist.convert.classToMixin',
    DartAssistKindPriority.default_,
    'Convert class to a mixin',
  );
  static const convertDocumentationIntoBlock = AssistKind(
    'dart.assist.convert.blockComment',
    DartAssistKindPriority.default_,
    'Convert to block documentation comment',
  );
  static const convertDocumentationIntoLine = AssistKind(
    'dart.assist.convert.lineComment',
    DartAssistKindPriority.default_,
    'Convert to line documentation comment',
  );
  static const convertFieldFormalToNormal = AssistKind(
    'dart.assist.convert.fieldFormalToNormal',
    DartAssistKindPriority.default_,
    'Convert to a normal parameter',
  );
  static const convertIntoAsyncBody = AssistKind(
    'dart.assist.convert.bodyToAsync',
    DartAssistKindPriority.priority,
    'Convert to async function body',
  );
  static const convertIntoBlockBody = AssistKind(
    'dart.assist.convert.bodyToBlock',
    DartAssistKindPriority.default_,
    'Convert to block body',
  );
  static const convertIntoExpressionBody = AssistKind(
    'dart.assist.convert.bodyToExpression',
    DartAssistKindPriority.default_,
    'Convert to expression body',
  );
  static const convertIntoFinalField = AssistKind(
    'dart.assist.convert.getterToFinalField',
    DartAssistKindPriority.default_,
    'Convert to final field',
  );
  static const convertIntoForIndex = AssistKind(
    'dart.assist.convert.forEachToForIndex',
    DartAssistKindPriority.default_,
    'Convert to for-index loop',
  );
  static const convertIntoGenericFunctionSyntax = AssistKind(
    'dart.assist.convert.toGenericFunctionSyntax',
    DartAssistKindPriority.default_,
    "Convert into 'Function' syntax",
  );
  static const convertIntoGetter = AssistKind(
    'dart.assist.convert.finalFieldToGetter',
    DartAssistKindPriority.default_,
    "Convert '{0}' to a getter",
  );
  static const convertIntoIsNot = AssistKind(
    'dart.assist.convert.isNot',
    DartAssistKindPriority.default_,
    'Convert to is!',
  );
  static const convertIntoIsNotEmpty = AssistKind(
    'dart.assist.convert.isNotEmpty',
    DartAssistKindPriority.default_,
    "Convert to 'isNotEmpty'",
  );
  static const convertPartOfToUri = AssistKind(
    'dart.assist.convert.partOfToPartUri',
    DartAssistKindPriority.default_,
    'Convert to use a URI',
  );
  static const convertToDeclaringParameter = AssistKind(
    'dart.assist.convert.toDeclaringParameter',
    DartAssistKindPriority.default_,
    'Convert to a declaring parameter',
  );
  static const convertToDotShorthand = AssistKind(
    'dart.assist.convert.toDotShorthand',
    DartAssistKindPriority.default_,
    'Convert to dot shorthand',
  );
  static const convertToDoubleQuotedString = AssistKind(
    'dart.assist.convert.toDoubleQuotedString',
    DartAssistKindPriority.default_,
    'Convert to double quoted string',
  );
  static const convertToInitializingFormal = AssistKind(
    'dart.assist.convert.toInitializingFormal',
    DartAssistKindPriority.default_,
    'Convert to initializing formal parameter',
  );
  static const convertToForElement = AssistKind(
    'dart.assist.convert.toForElement',
    DartAssistKindPriority.default_,
    "Convert to a 'for' element",
  );
  static const convertToIfCaseStatement = AssistKind(
    'dart.assist.convert.ifCaseStatement',
    DartAssistKindPriority.default_,
    "Convert to 'if-case' statement",
  );
  static const convertToIfCaseStatementChain = AssistKind(
    'dart.assist.convert.ifCaseStatementChain',
    DartAssistKindPriority.default_,
    "Convert to 'if-case' statement chain",
  );
  static const convertToIfElement = AssistKind(
    'dart.assist.convert.toIfElement',
    DartAssistKindPriority.default_,
    "Convert to an 'if' element",
  );
  static const convertToIntLiteral = AssistKind(
    'dart.assist.convert.toIntLiteral',
    DartAssistKindPriority.default_,
    'Convert to an int literal',
  );
  static const convertToMapLiteral = AssistKind(
    'dart.assist.convert.toMapLiteral',
    DartAssistKindPriority.default_,
    'Convert to map literal',
  );
  static const convertToMultilineString = AssistKind(
    'dart.assist.convert.toMultilineString',
    DartAssistKindPriority.default_,
    'Convert to multiline string',
  );
  static const convertToNullAware = AssistKind(
    'dart.assist.convert.toNullAware',
    DartAssistKindPriority.default_,
    "Convert to use '?.'",
  );
  static const convertToPackageImport = AssistKind(
    'dart.assist.convert.relativeToPackageImport',
    DartAssistKindPriority.default_,
    "Convert to 'package:' import",
  );
  static const convertToPrimaryConstructor = AssistKind(
    'dart.assist.convert.toPrimaryConstructor',
    DartAssistKindPriority.default_,
    'Convert to a primary constructor',
  );
  static const convertToRelativeImport = AssistKind(
    'dart.assist.convert.packageToRelativeImport',
    DartAssistKindPriority.default_,
    'Convert to a relative import',
  );
  static const convertToSecondaryConstructor = AssistKind(
    'dart.assist.convert.toSecondaryConstructor',
    DartAssistKindPriority.default_,
    'Convert to a secondary constructor',
  );
  static const convertToSetLiteral = AssistKind(
    'dart.assist.convert.toSetLiteral',
    DartAssistKindPriority.default_,
    'Convert to set literal',
  );
  static const convertToSingleQuotedString = AssistKind(
    'dart.assist.convert.toSingleQuotedString',
    DartAssistKindPriority.default_,
    'Convert to single quoted string',
  );
  static const convertToSpread = AssistKind(
    'dart.assist.convert.toSpread',
    DartAssistKindPriority.default_,
    'Convert to a spread',
  );
  static const convertToSuperParameters = AssistKind(
    'dart.assist.convert.toSuperParameters',
    DartAssistKindPriority.default_,
    'Convert to using super parameters',
  );
  static const convertToSwitchExpression = AssistKind(
    'dart.assist.convert.switchExpression',
    DartAssistKindPriority.default_,
    'Convert to switch expression',
  );
  static const destructureLocalVariableAssignment = AssistKind(
    'dart.assist.destructureLocalVariableAssignment',
    DartAssistKindPriority.default_,
    'Destructure variable assignment',
  );
  static const convertToSwitchStatement = AssistKind(
    'dart.assist.convert.switchStatement',
    DartAssistKindPriority.default_,
    'Convert to switch statement',
  );
  static const encapsulateField = AssistKind(
    'dart.assist.encapsulateField',
    DartAssistKindPriority.default_,
    'Encapsulate field',
  );
  static const exchangeOperands = AssistKind(
    'dart.assist.exchangeOperands',
    DartAssistKindPriority.default_,
    'Exchange operands',
  );
  static const flutterConvertToChildren = AssistKind(
    'dart.assist.flutter.convert.childToChildren',
    DartAssistKindPriority.default_,
    'Convert to children:',
  );
  static const flutterConvertToStatefulWidget = AssistKind(
    'dart.assist.flutter.convert.toStatefulWidget',
    DartAssistKindPriority.default_,
    'Convert to StatefulWidget',
  );
  static const flutterConvertToStatelessWidget = AssistKind(
    'dart.assist.flutter.convert.toStatelessWidget',
    DartAssistKindPriority.default_,
    'Convert to StatelessWidget',
  );
  static const flutterWrapGeneric = AssistKind(
    'dart.assist.flutter.wrap.generic',
    DartAssistKindPriority.flutterWrapGeneral,
    'Wrap with widget...',
  );
  static const flutterWrapBuilder = AssistKind(
    'dart.assist.flutter.wrap.builder',
    DartAssistKindPriority.flutterWrapSpecific,
    'Wrap with Builder',
  );
  static const flutterWrapCenter = AssistKind(
    'dart.assist.flutter.wrap.center',
    DartAssistKindPriority.flutterWrapSpecific,
    'Wrap with Center',
  );
  static const flutterWrapColumn = AssistKind(
    'dart.assist.flutter.wrap.column',
    DartAssistKindPriority.flutterWrapSpecific,
    'Wrap with Column',
  );
  static const flutterWrapContainer = AssistKind(
    'dart.assist.flutter.wrap.container',
    DartAssistKindPriority.flutterWrapSpecific,
    'Wrap with Container',
  );
  static const flutterWrapExpanded = AssistKind(
    'dart.assist.flutter.wrap.expanded',
    DartAssistKindPriority.flutterWrapSpecific,
    'Wrap with Expanded',
  );
  static const flutterWrapFlexible = AssistKind(
    'dart.assist.flutter.wrap.flexible',
    DartAssistKindPriority.flutterWrapSpecific,
    'Wrap with Flexible',
  );
  static const flutterWrapFutureBuilder = AssistKind(
    'dart.assist.flutter.wrap.futureBuilder',
    DartAssistKindPriority.flutterWrapSpecific,
    'Wrap with FutureBuilder',
  );
  static const flutterWrapPadding = AssistKind(
    'dart.assist.flutter.wrap.padding',
    DartAssistKindPriority.flutterWrapSpecific,
    'Wrap with Padding',
  );
  static const flutterWrapRow = AssistKind(
    'dart.assist.flutter.wrap.row',
    DartAssistKindPriority.flutterWrapSpecific,
    'Wrap with Row',
  );
  static const flutterWrapSizedBox = AssistKind(
    'dart.assist.flutter.wrap.sizedBox',
    DartAssistKindPriority.flutterWrapSpecific,
    'Wrap with SizedBox',
  );
  static const flutterWrapStreamBuilder = AssistKind(
    'dart.assist.flutter.wrap.streamBuilder',
    DartAssistKindPriority.flutterWrapSpecific,
    'Wrap with StreamBuilder',
  );
  static const flutterWrapValueListenableBuilder = AssistKind(
    'dart.assist.flutter.wrap.valueListenableBuilder',
    DartAssistKindPriority.flutterWrapSpecific,
    'Wrap with ValueListenableBuilder',
  );
  static const flutterSwapWithChild = AssistKind(
    'dart.assist.flutter.swap.withChild',
    DartAssistKindPriority.flutterSwap,
    'Swap with child',
  );
  static const flutterSwapWithParent = AssistKind(
    'dart.assist.flutter.swap.withParent',
    DartAssistKindPriority.flutterSwap,
    'Swap with parent',
  );
  static const flutterMoveDown = AssistKind(
    'dart.assist.flutter.move.down',
    DartAssistKindPriority.flutterMove,
    'Move widget down',
  );
  static const flutterMoveUp = AssistKind(
    'dart.assist.flutter.move.up',
    DartAssistKindPriority.flutterMove,
    'Move widget up',
  );
  static const flutterRemoveWidget = AssistKind(
    'dart.assist.flutter.removeWidget',
    DartAssistKindPriority.flutterRemove,
    'Remove this widget',
  );
  static const importAddShow = AssistKind(
    'dart.assist.add.showCombinator',
    DartAssistKindPriority.default_,
    "Add explicit 'show' combinator",
  );
  static const inlineInvocation = AssistKind(
    'dart.assist.inline',
    DartAssistKindPriority.default_,
    "Inline invocation of '{0}'",
  );
  static const invertConditionalExpression = AssistKind(
    'dart.assist.invertConditional',
    DartAssistKindPriority.default_,
    'Invert conditional expression',
  );
  static const invertIfStatement = AssistKind(
    'dart.assist.invertIf',
    DartAssistKindPriority.default_,
    "Invert 'if' statement",
  );
  static const joinElseWithIf = AssistKind(
    'dart.assist.inlineElseBlock',
    DartAssistKindPriority.default_,
    "Join the 'else' block with inner 'if' statement",
  );
  static const joinIfWithElse = AssistKind(
    'dart.assist.inlineEnclosingElseBlock',
    DartAssistKindPriority.default_,
    "Join 'if' statement with outer 'else' block",
  );
  static const joinIfWithInner = AssistKind(
    'dart.assist.joinWithInnerIf',
    DartAssistKindPriority.default_,
    "Join 'if' statement with inner 'if' statement",
  );
  static const joinIfWithOuter = AssistKind(
    'dart.assist.joinWithOuterIf',
    DartAssistKindPriority.default_,
    "Join 'if' statement with outer 'if' statement",
  );
  static const joinVariableDeclaration = AssistKind(
    'dart.assist.joinVariableDeclaration',
    DartAssistKindPriority.default_,
    'Join variable declaration',
  );
  static const removeAsync = AssistKind(
    'dart.assist.remove.async',
    DartAssistKindPriority.default_,
    "Remove 'async' modifier",
  );
  static const removeDigitSeparators = AssistKind(
    'dart.assist.remove.digitSeparators',
    DartAssistKindPriority.default_,
    'Remove digit separators',
  );
  static const removeTypeAnnotation = AssistKind(
    // TODO(pq): unify w/ fix
    'dart.assist.remove.typeAnnotation',
    DartAssistKindPriority.priority,
    'Remove type annotation',
  );
  static const removeUnnecessaryName = AssistKind(
    'dart.assist.remove.unnecessaryName',
    DartAssistKindPriority.default_,
    'Remove unnecessary name from pattern',
  );
  static const replaceConditionalWithIfElse = AssistKind(
    'dart.assist.convert.conditionalToIfElse',
    DartAssistKindPriority.default_,
    "Replace conditional with 'if-else'",
  );
  static const replaceIfElseWithConditional = AssistKind(
    'dart.assist.convert.ifElseToConditional',
    DartAssistKindPriority.default_,
    "Replace 'if-else' with conditional ('c ? x : y')",
  );
  static const replaceWithVar = AssistKind(
    'dart.assist.replace.withVar',
    DartAssistKindPriority.default_,
    "Replace type annotation with 'var'",
  );
  static const shadowField = AssistKind(
    'dart.assist.shadowField',
    DartAssistKindPriority.default_,
    'Create a local variable that shadows the field',
  );
  static const sortChildPropertyLast = AssistKind(
    'dart.assist.sort.child.properties.last',
    DartAssistKindPriority.default_,
    'Move child property to end of arguments',
  );
  static const splitAndCondition = AssistKind(
    'dart.assist.splitIfConjunction',
    DartAssistKindPriority.default_,
    'Split && condition',
  );
  static const splitVariableDeclaration = AssistKind(
    'dart.assist.splitVariableDeclaration',
    DartAssistKindPriority.default_,
    'Split variable declaration',
  );
  static const surroundWithBlock = AssistKind(
    'dart.assist.surround.block',
    DartAssistKindPriority.surroundWithBlock,
    'Surround with block',
  );
  static const surroundWithDoWhile = AssistKind(
    'dart.assist.surround.doWhile',
    DartAssistKindPriority.surroundWithDoWhile,
    "Surround with 'do-while'",
  );
  static const surroundWithFor = AssistKind(
    'dart.assist.surround.forEach',
    DartAssistKindPriority.surroundWithFor,
    "Surround with 'for'",
  );
  static const surroundWithForIn = AssistKind(
    'dart.assist.surround.forIn',
    DartAssistKindPriority.surroundWithForIn,
    "Surround with 'for-in'",
  );
  static const surroundWithIf = AssistKind(
    'dart.assist.surround.if',
    DartAssistKindPriority.surroundWithIf,
    "Surround with 'if'",
  );
  static const surroundWithSetState = AssistKind(
    'dart.assist.surround.setState',
    DartAssistKindPriority.surroundWithSetState,
    "Surround with 'setState'",
  );
  static const surroundWithTryCatch = AssistKind(
    'dart.assist.surround.tryCatch',
    DartAssistKindPriority.surroundWithTryCatch,
    "Surround with 'try-catch'",
  );
  static const surroundWithTryFinally = AssistKind(
    'dart.assist.surround.tryFinally',
    DartAssistKindPriority.surroundWithTryFinally,
    "Surround with 'try-finally'",
  );
  static const surroundWithWhile = AssistKind(
    'dart.assist.surround.while',
    DartAssistKindPriority.surroundWithWhile,
    "Surround with 'while'",
  );
  static const useCurlyBraces = AssistKind(
    'dart.assist.surround.curlyBraces',
    DartAssistKindPriority.default_,
    'Use curly braces',
  );
}

/// The priorities associated with various groups of assists.
abstract final class DartAssistKindPriority {
  static const int flutterRemove = 25;
  static const int flutterMove = 26;
  static const int flutterSwap = 27;
  static const int flutterWrapSpecific = 28;
  static const int flutterWrapGeneral = 29;
  static const int default_ = 30;
  static const int priority = 31;
  static const int surroundWithTryFinally = 31;
  static const int surroundWithTryCatch = 32;
  static const int surroundWithDoWhile = 33;
  static const int surroundWithSetState = 33;
  static const int surroundWithFor = 34;
  static const int surroundWithForIn = 35;
  static const int surroundWithWhile = 36;
  static const int surroundWithIf = 37;
  static const int surroundWithBlock = 38;
}
