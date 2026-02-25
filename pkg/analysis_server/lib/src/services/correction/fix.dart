// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// An enumeration of quick fix kinds for the errors found in an analysis
/// options file.
abstract final class AnalysisOptionsFixKind {
  static const removeLint = FixKind(
    'analysisOptions.fix.removeLint',
    DartFixKindPriority.standard,
    "Remove '{0}'",
  );
  static const removeSetting = FixKind(
    'analysisOptions.fix.removeSetting',
    DartFixKindPriority.standard,
    "Remove '{0}'",
  );
  static const replaceWithStrictCasts = FixKind(
    'analysisOptions.fix.replaceWithStrictCasts',
    DartFixKindPriority.standard,
    'Replace with the strict-casts analysis mode',
  );
  static const replaceWithStrictRawTypes = FixKind(
    'analysisOptions.fix.replaceWithStrictRawTypes',
    DartFixKindPriority.standard,
    'Replace with the strict-raw-types analysis mode',
  );
}

/// An enumeration of quick fix kinds found in a Dart file.
abstract final class DartFixKind {
  static const addAsync = FixKind(
    'dart.fix.add.async',
    DartFixKindPriority.standard,
    "Add 'async' modifier",
  );
  static const addAwait = FixKind(
    'dart.fix.add.await',
    DartFixKindPriority.standard + 1,
    "Add 'await' keyword",
  );
  static const addCallSuper = FixKind(
    'dart.fix.add.callSuper',
    DartFixKindPriority.standard,
    "Add 'super.{0}'",
  );
  static const addEmptyArgumentList = FixKind(
    'dart.fix.add.empty.argument.list',
    DartFixKindPriority.standard,
    'Add empty argument list',
  );
  static const addEmptyArgumentListMulti = FixKind(
    'dart.fix.add.empty.argument.list.multi',
    DartFixKindPriority.inFile,
    'Add empty argument lists everywhere in file',
  );
  static const addClassModifierBase = FixKind(
    'dart.fix.add.class.modifier.base',
    DartFixKindPriority.standard,
    "Add 'base' modifier",
  );
  static const addClassModifierBaseMulti = FixKind(
    'dart.fix.add.class.modifier.base.multi',
    DartFixKindPriority.inFile,
    "Add 'base' modifier everywhere in file",
  );
  static const addClassModifierFinal = FixKind(
    'dart.fix.add.class.modifier.final',
    DartFixKindPriority.standard,
    "Add 'final' modifier",
  );
  static const addClassModifierFinalMulti = FixKind(
    'dart.fix.add.class.modifier.final.multi',
    DartFixKindPriority.inFile,
    "Add 'final' modifier everywhere in file",
  );
  static const addClassModifierSealed = FixKind(
    'dart.fix.add.class.modifier.sealed',
    DartFixKindPriority.standard,
    "Add 'sealed' modifier",
  );
  static const addClassModifierSealedMulti = FixKind(
    'dart.fix.add.class.modifier.sealed.multi',
    DartFixKindPriority.inFile,
    "Add 'sealed' modifier everywhere in file",
  );
  static const addConst = FixKind(
    'dart.fix.add.const',
    DartFixKindPriority.standard,
    "Add 'const' modifier",
  );
  static const addConstMulti = FixKind(
    'dart.fix.add.const.multi',
    DartFixKindPriority.inFile,
    "Add 'const' modifiers everywhere in file",
  );
  static const addCurlyBraces = FixKind(
    'dart.fix.add.curlyBraces',
    DartFixKindPriority.standard,
    'Add curly braces',
  );
  static const addCurlyBracesMulti = FixKind(
    'dart.fix.add.curlyBraces.multi',
    DartFixKindPriority.inFile,
    'Add curly braces everywhere in file',
  );
  static const addDiagnosticPropertyReference = FixKind(
    'dart.fix.add.diagnosticPropertyReference',
    DartFixKindPriority.standard,
    'Add a debug reference to this property',
  );
  static const addDiagnosticPropertyReferenceMulti = FixKind(
    'dart.fix.add.diagnosticPropertyReference.multi',
    DartFixKindPriority.inFile,
    'Add missing debug property references everywhere in file',
  );
  static const addEnumConstant = FixKind(
    'dart.fix.add.enumConstant',
    DartFixKindPriority.standard,
    "Add enum constant '{0}'",
  );
  static const addEolAtEndOfFile = FixKind(
    'dart.fix.add.eolAtEndOfFile',
    DartFixKindPriority.standard,
    'Add EOL at end of file',
  );
  static const addExtensionOverride = FixKind(
    'dart.fix.add.extensionOverride',
    DartFixKindPriority.standard,
    "Add an extension override for '{0}'",
  );
  static const addExplicitCall = FixKind(
    'dart.fix.add.explicitCall',
    DartFixKindPriority.standard,
    'Add explicit .call tearoff',
  );
  static const addExplicitCallMulti = FixKind(
    'dart.fix.add.explicitCall.multi',
    DartFixKindPriority.inFile,
    'Add explicit .call to implicit tearoffs in file',
  );
  static const addExplicitCast = FixKind(
    'dart.fix.add.explicitCast',
    DartFixKindPriority.standard - 1,
    'Add cast',
  );
  static const addExplicitCastMulti = FixKind(
    'dart.fix.add.explicitCast.multi',
    DartFixKindPriority.inFile,
    'Add cast everywhere in file',
  );
  static const addInitializingFormalParameters = FixKind(
    'dart.fix.add.initializingFormalParameters',
    DartFixKindPriority.standard + 20,
    'Add final initializing formal parameters',
  );
  static const addInitializingFormalNamedParameters = FixKind(
    'dart.fix.add.initializingFormalNamedParameters',
    DartFixKindPriority.standard + 21,
    'Add final initializing formal required named parameters',
  );
  @Deprecated('Use addKeyToConstructors')
  static const ADD_KEY_TO_CONSTRUCTORS = addKeyToConstructors;
  static const addKeyToConstructors = FixKind(
    'dart.fix.add.keyToConstructors',
    DartFixKindPriority.standard,
    "Add 'key' to constructors",
  );
  @Deprecated('Use addKeyToConstructorsMulti')
  static const ADD_KEY_TO_CONSTRUCTORS_MULTI = addKeyToConstructorsMulti;
  static const addKeyToConstructorsMulti = FixKind(
    'dart.fix.add.keyToConstructors.multi',
    DartFixKindPriority.standard,
    "Add 'key' to constructors everywhere in file",
  );
  static const addLate = FixKind(
    'dart.fix.add.late',
    DartFixKindPriority.standard,
    "Add 'late' modifier",
  );
  static const addLeadingNewlineToString = FixKind(
    'dart.fix.add.leadingNewlineToString',
    DartFixKindPriority.standard,
    'Add leading new line',
  );
  static const addLeadingNewlineToStringMulti = FixKind(
    'dart.fix.add.leadingNewlineToString.multi',
    DartFixKindPriority.standard,
    'Add leading new line everywhere in file',
  );
  static const addMissingEnumCaseClauses = FixKind(
    'dart.fix.add.missingEnumCaseClauses',
    DartFixKindPriority.standard,
    'Add missing case clauses',
  );
  static const addMissingParameterNamed = FixKind(
    'dart.fix.add.missingParameterNamed',
    DartFixKindPriority.standard + 20,
    "Add named parameter '{0}'",
  );
  static const addMissingParameterPositional = FixKind(
    'dart.fix.add.missingParameterPositional',
    DartFixKindPriority.standard + 19,
    'Add optional positional parameter',
  );
  static const addMissingParameterRequired = FixKind(
    'dart.fix.add.missingParameterRequired',
    DartFixKindPriority.standard + 20,
    'Add required positional parameter',
  );
  static const addMissingRequiredArgument = FixKind(
    'dart.fix.add.missingRequiredArgument',
    DartFixKindPriority.standard + 20,
    'Add {0} required argument{1}',
  );
  static const addMissingSwitchCases = FixKind(
    'dart.fix.add.missingSwitchCases',
    DartFixKindPriority.standard,
    'Add missing switch cases',
  );
  static const addNeNull = FixKind(
    'dart.fix.add.neNull',
    DartFixKindPriority.standard,
    'Add != null',
  );
  static const addNeNullMulti = FixKind(
    'dart.fix.add.neNull.multi',
    DartFixKindPriority.inFile,
    'Add != null everywhere in file',
  );
  static const addNullCheck = FixKind(
    'dart.fix.add.nullCheck',
    DartFixKindPriority.standard - 1,
    'Add a null check (!)',
  );
  static const addOverride = FixKind(
    'dart.fix.add.override',
    DartFixKindPriority.standard,
    "Add '@override' annotation",
  );
  static const addOverrideMulti = FixKind(
    'dart.fix.add.override.multi',
    DartFixKindPriority.inFile,
    "Add '@override' annotations everywhere in file",
  );
  static const addRedeclare = FixKind(
    'dart.fix.add.redeclare',
    DartFixKindPriority.standard,
    "Add '@redeclare' annotation",
  );
  static const addRedeclareMulti = FixKind(
    'dart.fix.add.redeclare.multi',
    DartFixKindPriority.inFile,
    "Add '@redeclare' annotations everywhere in file",
  );
  static const addReopen = FixKind(
    'dart.fix.add.reopen',
    DartFixKindPriority.standard,
    "Add '@reopen' annotation",
  );
  static const addReopenMulti = FixKind(
    'dart.fix.add.reopen.multi',
    DartFixKindPriority.inFile,
    "Add '@reopen' annotations everywhere in file",
  );
  static const addRequired = FixKind(
    'dart.fix.add.required',
    DartFixKindPriority.standard,
    "Add 'required' keyword",
  );
  static const addReturnNull = FixKind(
    'dart.fix.add.returnNull',
    DartFixKindPriority.standard,
    "Add 'return null'",
  );
  static const addReturnNullMulti = FixKind(
    'dart.fix.add.returnNull.multi',
    DartFixKindPriority.inFile,
    "Add 'return null' everywhere in file",
  );
  static const addReturnType = FixKind(
    'dart.fix.add.returnType',
    DartFixKindPriority.standard,
    'Add return type',
  );
  static const addReturnTypeMulti = FixKind(
    'dart.fix.add.returnType.multi',
    DartFixKindPriority.inFile,
    'Add return types everywhere in file',
  );
  static const addStatic = FixKind(
    'dart.fix.add.static',
    DartFixKindPriority.standard,
    "Add 'static' modifier",
  );
  static const addSuperConstructorInvocation = FixKind(
    'dart.fix.add.superConstructorInvocation',
    DartFixKindPriority.standard,
    'Add super constructor {0} invocation',
  );
  static const addSuperParameter = FixKind(
    'dart.fix.add.superParameter',
    DartFixKindPriority.standard,
    'Add required parameter{0}',
  );
  static const addSwitchCaseBreak = FixKind(
    'dart.fix.add.switchCaseReturn',
    DartFixKindPriority.standard,
    "Add 'break'",
  );
  static const addSwitchCaseBreakMulti = FixKind(
    'dart.fix.add.switchCaseReturn.multi',
    DartFixKindPriority.inFile,
    "Add 'break' everywhere in file",
  );
  static const addTrailingComma = FixKind(
    'dart.fix.add.trailingComma',
    DartFixKindPriority.standard,
    'Add trailing comma',
  );
  static const addTrailingCommaMulti = FixKind(
    'dart.fix.add.trailingComma.multi',
    DartFixKindPriority.inFile,
    'Add trailing commas everywhere in file',
  );
  static const addTypeAnnotation = FixKind(
    'dart.fix.add.typeAnnotation',
    DartFixKindPriority.standard,
    'Add type annotation',
  );
  static const addTypeAnnotationMulti = FixKind(
    'dart.fix.add.typeAnnotation.multi',
    DartFixKindPriority.inFile,
    'Add type annotations everywhere in file',
  );
  static const changeArgumentName = FixKind(
    'dart.fix.change.argumentName',
    DartFixKindPriority.standard + 10,
    "Change to '{0}'",
  );
  static const changeTo = FixKind(
    'dart.fix.change.to',
    DartFixKindPriority.standard + 1,
    "Change to '{0}'",
  );
  static const changeToNearestPreciseValuee = FixKind(
    'dart.fix.change.toNearestPreciseValue',
    DartFixKindPriority.standard,
    'Change to nearest precise int-as-double value: {0}',
  );
  static const changeToStaticAccess = FixKind(
    'dart.fix.change.toStaticAccess',
    DartFixKindPriority.standard,
    "Change access to static using '{0}'",
  );
  static const changeTypeAnnotation = FixKind(
    'dart.fix.change.typeAnnotation',
    DartFixKindPriority.standard,
    "Change '{0}' to '{1}' type annotation",
  );
  static const convertClassToEnum = FixKind(
    'dart.fix.convert.classToEnum',
    DartFixKindPriority.standard,
    'Convert class to an enum',
  );
  static const convertClassToEnumMulti = FixKind(
    'dart.fix.convert.classToEnum.multi',
    DartFixKindPriority.standard,
    'Convert classes to enums in file',
  );
  static const convertFlutterChild = FixKind(
    'dart.fix.flutter.convert.childToChildren',
    DartFixKindPriority.standard,
    'Convert to children:',
  );
  static const convertFlutterChildren = FixKind(
    'dart.fix.flutter.convert.childrenToChild',
    DartFixKindPriority.standard,
    'Convert to child:',
  );
  static const convertIntoBlockBody = FixKind(
    'dart.fix.convert.bodyToBlock',
    DartFixKindPriority.standard,
    'Convert to block body',
  );
  static const convertIntoBlockBodyMulti = FixKind(
    'dart.fix.convert.bodyToBlock.multi',
    DartFixKindPriority.inFile,
    'Convert to block body everywhere in file',
  );
  static const convertIntoGetter = FixKind(
    'dart.fix.convert.getter',
    DartFixKindPriority.standard,
    "Convert '{0}' to a getter",
  );
  static const convertForEachToForLoop = FixKind(
    'dart.fix.convert.toForLoop',
    DartFixKindPriority.standard,
    "Convert 'forEach' to a 'for' loop",
  );
  static const convertForEachToForLoopMulti = FixKind(
    'dart.fix.convert.toForLoop.multi',
    DartFixKindPriority.inFile,
    "Convert 'forEach' to a 'for' loop everywhere in file",
  );
  static const convertIntoExpressionBody = FixKind(
    'dart.fix.convert.toExpressionBody',
    DartFixKindPriority.standard,
    'Convert to expression body',
  );
  static const convertIntoExpressionBodyMulti = FixKind(
    'dart.fix.convert.toExpressionBody.multi',
    DartFixKindPriority.inFile,
    'Convert to expression bodies everywhere in file',
  );
  static const convertNullCheckToNullAwareElementOrEntry = FixKind(
    'dart.fix.convert.nullCheckToNullAwareElement',
    DartFixKindPriority.standard,
    'Convert null check to null-aware element',
  );
  static const convertNullCheckToNullAwareElementOrEntryMulti = FixKind(
    'dart.fix.convert.nullCheckToNullAwareElement.multi',
    DartFixKindPriority.inFile,
    'Convert null check to null-aware element in file',
  );
  static const convertQuotes = FixKind(
    'dart.fix.convert.quotes',
    DartFixKindPriority.standard,
    'Convert the quotes and remove escapes',
  );
  static const convertQuotesMulti = FixKind(
    'dart.fix.convert.quotes.multi',
    DartFixKindPriority.inFile,
    'Convert the quotes and remove escapes everywhere in file',
  );
  static const convertRelatedToCascade = FixKind(
    'dart.fix.convert.relatedToCascade',
    DartFixKindPriority.standard + 1,
    'Convert this and related to cascade notation',
  );
  static const convertToBoolExpression = FixKind(
    'dart.fix.convert.toBoolExpression',
    DartFixKindPriority.standard,
    'Convert to boolean expression',
  );
  static const convertToBoolExpressionMulti = FixKind(
    'dart.fix.convert.toBoolExpression.multi',
    DartFixKindPriority.standard,
    'Convert to boolean expressions everywhere in file',
  );
  static const convertToCascade = FixKind(
    'dart.fix.convert.toCascade',
    DartFixKindPriority.standard,
    'Convert to cascade notation',
  );
  static const convertToConstantPattern = FixKind(
    'dart.fix.convert.toConstantPattern',
    DartFixKindPriority.standard - 1,
    'Convert to constant pattern',
  );
  static const convertToContains = FixKind(
    'dart.fix.convert.toContains',
    DartFixKindPriority.standard,
    "Convert to using 'contains'",
  );
  static const convertToContainsMulti = FixKind(
    'dart.fix.convert.toContains.multi',
    DartFixKindPriority.inFile,
    "Convert to using 'contains' everywhere in file",
  );
  static const convertToDoubleQuotedString = FixKind(
    'dart.fix.convert.toDoubleQuotedString',
    DartFixKindPriority.standard,
    'Convert to double quoted string',
  );
  static const convertToDoubleQuotedStringMulti = FixKind(
    'dart.fix.convert.toDoubleQuotedString.multi',
    DartFixKindPriority.inFile,
    'Convert to double quoted strings everywhere in file',
  );
  static const convertToFlutterStyleTodo = FixKind(
    'dart.fix.convert.toFlutterStyleTodo',
    DartFixKindPriority.standard,
    'Convert to flutter style todo',
  );
  static const convertToFlutterStyleTodoMulti = FixKind(
    'dart.fix.convert.toFlutterStyleTodo.multi',
    DartFixKindPriority.inFile,
    'Convert to flutter style todos everywhere in file',
  );
  static const convertToForEach = FixKind(
    'dart.fix.convert.toForEach',
    DartFixKindPriority.standard,
    "Convert to 'forEach'",
  );
  static const convertToForElement = FixKind(
    'dart.fix.convert.toForElement',
    DartFixKindPriority.standard,
    "Convert to a 'for' element",
  );
  static const convertToForElementMulti = FixKind(
    'dart.fix.convert.toForElement.multi',
    DartFixKindPriority.inFile,
    "Convert to 'for' elements everywhere in file",
  );
  static const convertToGenericFunctionSyntax = FixKind(
    'dart.fix.convert.toGenericFunctionSyntax',
    DartFixKindPriority.standard,
    "Convert into 'Function' syntax",
  );
  static const convertToGenericFunctionSyntaxMulti = FixKind(
    'dart.fix.convert.toGenericFunctionSyntax.multi',
    DartFixKindPriority.inFile,
    "Convert to 'Function' syntax everywhere in file",
  );
  static const convertToFunctionDeclaration = FixKind(
    'dart.fix.convert.toFunctionDeclaration',
    DartFixKindPriority.standard,
    'Convert to function declaration',
  );
  static const convertToFunctionDeclarationMulti = FixKind(
    'dart.fix.convert.toFunctionDeclaration.multi',
    DartFixKindPriority.inFile,
    'Convert to function declaration everywhere in file',
  );
  static const convertToIfElement = FixKind(
    'dart.fix.convert.toIfElement',
    DartFixKindPriority.standard,
    "Convert to an 'if' element",
  );
  static const convertToIfElementMulti = FixKind(
    'dart.fix.convert.toIfElement.multi',
    DartFixKindPriority.inFile,
    "Convert to 'if' elements everywhere in file",
  );
  static const convertToIfNull = FixKind(
    'dart.fix.convert.toIfNull',
    DartFixKindPriority.standard,
    "Convert to use '??'",
  );
  static const convertToIfNullMulti = FixKind(
    'dart.fix.convert.toIfNull.multi',
    DartFixKindPriority.inFile,
    "Convert to '??'s everywhere in file",
  );
  static const convertToInitializingFormal = FixKind(
    'dart.fix.convert.toInitializingFormal',
    DartFixKindPriority.standard,
    'Convert to an initializing formal parameter',
  );
  static const convertToInitializingFormalMulti = FixKind(
    'dart.fix.convert.toInitializingFormal.multi',
    DartFixKindPriority.standard,
    'Convert to initializing formal parameters everywhere in file',
  );
  static const convertToIntLiteral = FixKind(
    'dart.fix.convert.toIntLiteral',
    DartFixKindPriority.standard,
    'Convert to an int literal',
  );
  static const convertToIntLiteralMulti = FixKind(
    'dart.fix.convert.toIntLiteral.multi',
    DartFixKindPriority.inFile,
    'Convert to int literals everywhere in file',
  );
  static const convertToIsNot = FixKind(
    'dart.fix.convert.isNot',
    DartFixKindPriority.standard,
    'Convert to is!',
  );
  static const convertToIsNotMulti = FixKind(
    'dart.fix.convert.isNot.multi',
    DartFixKindPriority.inFile,
    'Convert to is! everywhere in file',
  );
  static const convertToLineComment = FixKind(
    'dart.fix.convert.toLineComment',
    DartFixKindPriority.standard,
    'Convert to line documentation comment',
  );
  static const convertToLineCommentMulti = FixKind(
    'dart.fix.convert.toLineComment.multi',
    DartFixKindPriority.inFile,
    'Convert to line documentation comments everywhere in file',
  );
  static const convertToMapLiteral = FixKind(
    'dart.fix.convert.toMapLiteral',
    DartFixKindPriority.standard,
    'Convert to map literal',
  );
  static const convertToMapLiteralMulti = FixKind(
    'dart.fix.convert.toMapLiteral.multi',
    DartFixKindPriority.inFile,
    'Convert to map literals everywhere in file',
  );
  static const convertToNamedArguments = FixKind(
    'dart.fix.convert.toNamedArguments',
    DartFixKindPriority.standard,
    'Convert to named arguments',
  );
  static const convertToNullAware = FixKind(
    'dart.fix.convert.toNullAware',
    DartFixKindPriority.standard,
    "Convert to use '?.'",
  );
  static const convertToNullAwareListElement = FixKind(
    'dart.fix.convert.toNullAwareListElement',
    DartFixKindPriority.standard,
    "Convert to use '?'",
  );
  static const convertToNullAwareMapEntryKey = FixKind(
    'dart.fix.convert.toNullAwareMapEntryKey',
    DartFixKindPriority.standard,
    "Convert to use '?'",
  );
  static const convertToNullAwareMapEntryValue = FixKind(
    'dart.fix.convert.toNullAwareMayEntryValue',
    DartFixKindPriority.standard,
    "Convert to use '?'",
  );
  static const convertToNullAwareSetElement = FixKind(
    'dart.fix.convert.toNullAwareSetElement',
    DartFixKindPriority.standard,
    "Convert to use '?'",
  );
  static const convertToNullAwareMulti = FixKind(
    'dart.fix.convert.toNullAware.multi',
    DartFixKindPriority.inFile,
    "Convert to use '?.' everywhere in file",
  );
  static const convertToNullAwareSpread = FixKind(
    'dart.fix.convert.toNullAwareSpread',
    DartFixKindPriority.standard,
    "Convert to use '...?'",
  );
  static const convertToNullAwareSpreadMulti = FixKind(
    'dart.fix.convert.toNullAwareSpread.multi',
    DartFixKindPriority.inFile,
    "Convert to use '...?' everywhere in file",
  );
  static const convertToOnType = FixKind(
    'dart.fix.convert.toOnType',
    DartFixKindPriority.standard,
    "Convert to 'on {0}'",
  );
  static const convertToPackageImport = FixKind(
    'dart.fix.convert.toPackageImport',
    DartFixKindPriority.standard,
    "Convert to 'package:' import",
  );
  static const convertToPackageImportMulti = FixKind(
    'dart.fix.convert.toPackageImport.multi',
    DartFixKindPriority.inFile,
    "Convert to 'package:' imports everywhere in file",
  );
  static const convertToRawString = FixKind(
    'dart.fix.convert.toRawString',
    DartFixKindPriority.standard,
    'Convert to raw string',
  );
  static const convertToRawStringMulti = FixKind(
    'dart.fix.convert.toRawString.multi',
    DartFixKindPriority.inFile,
    'Convert to raw strings everywhere in file',
  );
  static const convertToRelativeImport = FixKind(
    'dart.fix.convert.toRelativeImport',
    DartFixKindPriority.standard,
    'Convert to relative import',
  );
  static const convertToRelativeImportMulti = FixKind(
    'dart.fix.convert.toRelativeImport.multi',
    DartFixKindPriority.inFile,
    'Convert to relative imports everywhere in file',
  );
  static const convertToSetLiteral = FixKind(
    'dart.fix.convert.toSetLiteral',
    DartFixKindPriority.standard,
    'Convert to set literal',
  );
  static const convertToSetLiteralMulti = FixKind(
    'dart.fix.convert.toSetLiteral.multi',
    DartFixKindPriority.inFile,
    'Convert to set literals everywhere in file',
  );
  static const convertToSingleQuotedString = FixKind(
    'dart.fix.convert.toSingleQuotedString',
    DartFixKindPriority.standard,
    'Convert to single quoted string',
  );
  static const convertToSingleQuotedStringMulti = FixKind(
    'dart.fix.convert.toSingleQuotedString.multi',
    DartFixKindPriority.inFile,
    'Convert to single quoted strings everywhere in file',
  );
  static const convertToSpread = FixKind(
    'dart.fix.convert.toSpread',
    DartFixKindPriority.standard,
    'Convert to a spread',
  );
  static const convertToSpreadMulti = FixKind(
    'dart.fix.convert.toSpread.multi',
    DartFixKindPriority.inFile,
    'Convert to spreads everywhere in file',
  );
  static const convertToSuperParameters = FixKind(
    'dart.fix.convert.toSuperParameters',
    DartFixKindPriority.ignore,
    'Convert to using super parameters',
  );
  static const convertToSuperParametersMulti = FixKind(
    'dart.fix.convert.toSuperParameters.multi',
    DartFixKindPriority.ignore,
    'Convert to using super parameters everywhere in file',
  );
  static const convertToWhereType = FixKind(
    'dart.fix.convert.toWhereType',
    DartFixKindPriority.standard,
    "Convert to use 'whereType'",
  );
  static const convertToWhereTypeMulti = FixKind(
    'dart.fix.convert.toWhereType.multi',
    DartFixKindPriority.inFile,
    "Convert to using 'whereType' everywhere in file",
  );
  static const convertToWildcardPattern = FixKind(
    'dart.fix.convert.toWildcardPattern',
    DartFixKindPriority.standard,
    'Convert to wildcard pattern',
  );
  static const convertToWildcardVariable = FixKind(
    'dart.fix.convert.toWildcardVariable',
    DartFixKindPriority.standard,
    'Convert to wildcard variable',
  );
  static const convertToWildcardVariableMulti = FixKind(
    'dart.fix.convert.toWildcardVariable.multi',
    DartFixKindPriority.inFile,
    'Convert to wildcard variables everywhere in file',
  );
  static const createClassUppercase = FixKind(
    'dart.fix.create.class.uppercase',
    DartFixKindPriority.standard + 2,
    "Create class '{0}'",
  );
  static const createClassUppercaseWith = FixKind(
    'dart.fix.create.class.uppercase.with',
    DartFixKindPriority.standard + 1,
    "Create class '{0}'",
  );
  static const createClassLowercase = FixKind(
    'dart.fix.create.class.lowercase',
    DartFixKindPriority.standard - 5,
    "Create class '{0}'",
  );
  static const createClassLowercaseWith = FixKind(
    'dart.fix.create.class.lowercase.with',
    DartFixKindPriority.standard - 6,
    "Create class '{0}'",
  );
  static const createConstructor = FixKind(
    'dart.fix.create.constructor',
    DartFixKindPriority.standard,
    "Create constructor '{0}'",
  );
  static const createConstructorForFinalFields = FixKind(
    'dart.fix.create.constructorForFinalFields',
    DartFixKindPriority.standard,
    'Create constructor for final fields',
  );
  static const createConstructorForFinalFieldsRequiredNamed = FixKind(
    'dart.fix.create.constructorForFinalFields.requiredNamed',
    DartFixKindPriority.standard,
    'Create constructor for final fields, required named',
  );
  static const createConstructorSuper = FixKind(
    'dart.fix.create.constructorSuper',
    DartFixKindPriority.standard,
    'Create constructor to call {0}',
  );
  static const createExtensionGetter = FixKind(
    'dart.fix.create.extension.getter',
    DartFixKindPriority.standard - 3, // Lower than createExtensionMethod
    "Create extension getter '{0}'",
  );
  static const createExtensionMethod = FixKind(
    'dart.fix.create.extension.method',
    DartFixKindPriority.standard - 2,
    "Create extension method '{0}'",
  );
  static const createExtensionOperator = FixKind(
    'dart.fix.create.extension.operator',
    DartFixKindPriority.standard - 2,
    "Create extension operator '{0}'",
  );
  static const createExtensionSetter = FixKind(
    'dart.fix.create.extension.setter',
    DartFixKindPriority.standard - 3, // Matching createExtensionGetter
    "Create extension setter '{0}'",
  );
  static const createField = FixKind(
    'dart.fix.create.field',
    DartFixKindPriority.standard - 1,
    "Create field '{0}'",
  );
  static const createFile = FixKind(
    'dart.fix.create.file',
    DartFixKindPriority.standard,
    "Create file '{0}'",
  );
  static const createFunction = FixKind(
    'dart.fix.create.function',
    DartFixKindPriority.standard - 1,
    "Create function '{0}'",
  );
  static const createFunctionTearoff = FixKind(
    'dart.fix.create.function.tearoff',
    DartFixKindPriority.standard - 1,
    "Create function '{0}'",
  );
  static const createGetter = FixKind(
    'dart.fix.create.getter',
    DartFixKindPriority.standard,
    "Create getter '{0}'",
  );
  static const createLocalVariable = FixKind(
    'dart.fix.create.localVariable',
    DartFixKindPriority.standard,
    "Create local variable '{0}'",
  );
  static const createMethod = FixKind(
    'dart.fix.create.method',
    DartFixKindPriority.standard,
    "Create method '{0}'",
  );
  static const createMethodTearoff = FixKind(
    'dart.fix.create.method.tearoff',
    DartFixKindPriority.standard,
    "Create method '{0}'",
  );

  // TODO(pq): used by LintNames.hash_and_equals; consider removing.
  static const createMethodMulti = FixKind(
    'dart.fix.create.method.multi',
    DartFixKindPriority.inFile,
    'Create methods in file',
  );
  static const createMissingOverrides = FixKind(
    'dart.fix.create.missingOverrides',
    DartFixKindPriority.standard + 1,
    'Create {0} missing override{1}',
  );
  static const createMixinUppercase = FixKind(
    'dart.fix.create.mixin.uppercase',
    DartFixKindPriority.standard,
    "Create mixin '{0}'",
  );
  static const createMixinUppercaseWith = FixKind(
    'dart.fix.create.mixin.uppercase.with',
    DartFixKindPriority.standard + 2,
    "Create mixin '{0}'",
  );
  static const createMixinLowercase = FixKind(
    'dart.fix.create.mixin.lowercase',
    DartFixKindPriority.standard - 6,
    "Create mixin '{0}'",
  );
  static const createMixinLowercaseWith = FixKind(
    'dart.fix.create.mixin.lowercase.with',
    DartFixKindPriority.standard - 5,
    "Create mixin '{0}'",
  );
  static const createNoSuchMethod = FixKind(
    'dart.fix.create.noSuchMethod',
    DartFixKindPriority.standard - 1,
    "Create 'noSuchMethod' method",
  );
  static const createOperator = FixKind(
    'dart.fix.create.operator',
    DartFixKindPriority.standard,
    "Create operator '{0}'",
  );
  static const createParameter = FixKind(
    'dart.fix.create.parameter',
    DartFixKindPriority.standard,
    "Create required positional parameter '{0}'",
  );
  static const createSetter = FixKind(
    'dart.fix.create.setter',
    DartFixKindPriority.standard,
    "Create setter '{0}'",
  );
  static const dataDriven = FixKind(
    'dart.fix.dataDriven',
    DartFixKindPriority.standard,
    '{0}',
  );
  static const extendClassForMixin = FixKind(
    'dart.fix.extendClassForMixin',
    DartFixKindPriority.standard,
    "Extend the class '{0}'",
  );
  static const extractLocalVariable = FixKind(
    'dart.fix.extractLocalVariable',
    DartFixKindPriority.standard,
    'Extract local variable',
  );
  static const importLibraryCombinator = FixKind(
    'dart.fix.import.libraryCombinator',
    DartFixKindPriority.standard + 8,
    "Import '{0}' from {1}",
  );
  static const importLibraryCombinatorMultiple = FixKind(
    'dart.fix.import.libraryCombinatorMultiple',
    DartFixKindPriority.standard + 8,
    "Import '{0}' and {1} other{2} from {3}",
  );
  static const importLibraryHide = FixKind(
    'dart.fix.import.libraryHide',
    DartFixKindPriority.standard,
    "Hide others to use '{0}' from '{1}'{2}",
  );
  static const importLibraryPrefix = FixKind(
    'dart.fix.import.libraryPrefix',
    DartFixKindPriority.standard + 8,
    "Use imported library '{0}' with prefix '{1}'",
  );

  /// {@template dart.fix.import.libraryProject1}
  /// Import defining library.
  /// {@endtemplate}
  static const importLibraryProject1 = FixKind(
    'dart.fix.import.libraryProject1',
    DartFixKindPriority.standard + 5,
    "Import library '{0}'",
  );

  /// {@macro dart.fix.import.libraryProject1}
  static const importLibraryProject1Prefixed = FixKind(
    'dart.fix.import.libraryProject1Prefixed',
    DartFixKindPriority.standard + 5,
    "Import library '{0}' with prefix '{1}'",
  );

  /// {@macro dart.fix.import.libraryProject1}
  static const importLibraryProject1PrefixedShow = FixKind(
    'dart.fix.import.libraryProject1PrefixedShow',
    DartFixKindPriority.standard + 5,
    "Import library '{0}' with prefix '{1}' and 'show'",
  );

  /// {@macro dart.fix.import.libraryProject1}
  static const importLibraryProject1Show = FixKind(
    'dart.fix.import.libraryProject1Show',
    DartFixKindPriority.standard + 5,
    "Import library '{0}' with 'show'",
  );

  /// {@template dart.fix.import.libraryProject2}
  /// Import export library.
  /// {@endtemplate}
  static const importLibraryProject2 = FixKind(
    'dart.fix.import.libraryProject2',
    DartFixKindPriority.standard + 4,
    "Import library '{0}'",
  );

  /// {@macro dart.fix.import.libraryProject2}
  static const importLibraryProject2Prefixed = FixKind(
    'dart.fix.import.libraryProject2Prefixed',
    DartFixKindPriority.standard + 4,
    "Import library '{0}' with prefix '{1}'",
  );

  /// {@macro dart.fix.import.libraryProject2}
  static const importLibraryProject2PrefixedShow = FixKind(
    'dart.fix.import.libraryProject2PrefixedShow',
    DartFixKindPriority.standard + 4,
    "Import library '{0}' with prefix '{1}' and 'show'",
  );

  /// {@macro dart.fix.import.libraryProject2}
  static const importLibraryProject2Show = FixKind(
    'dart.fix.import.libraryProject2Show',
    DartFixKindPriority.standard + 4,
    "Import library '{0}' with 'show'",
  );

  /// {@template dart.fix.import.libraryProject3}
  /// Import non-API.
  /// {@endtemplate}
  static const importLibraryProject3 = FixKind(
    'dart.fix.import.libraryProject3',
    DartFixKindPriority.standard + 3,
    "Import library '{0}'",
  );

  /// {@macro dart.fix.import.libraryProject3}
  static const importLibraryProject3Prefixed = FixKind(
    'dart.fix.import.libraryProject3Prefixed',
    DartFixKindPriority.standard + 3,
    "Import library '{0}' with prefix '{1}'",
  );

  /// {@macro dart.fix.import.libraryProject3}
  static const importLibraryProject3PrefixedShow = FixKind(
    'dart.fix.import.libraryProject3PrefixedShow',
    DartFixKindPriority.standard + 3,
    "Import library '{0}' with prefix '{1}' and 'show'",
  );

  /// {@macro dart.fix.import.libraryProject3}
  static const importLibraryProject3Show = FixKind(
    'dart.fix.import.libraryProject3Show',
    DartFixKindPriority.standard + 3,
    "Import library '{0}' with 'show'",
  );
  static const importLibraryRemoveShow = FixKind(
    'dart.fix.import.libraryRemoveShow',
    DartFixKindPriority.standard - 1,
    "Remove show to use '{0}' from '{1}'{2}",
  );
  static const importLibrarySdk = FixKind(
    'dart.fix.import.librarySdk',
    DartFixKindPriority.standard + 7,
    "Import library '{0}'",
  );
  static const importLibrarySdkPrefixed = FixKind(
    'dart.fix.import.librarySdkPrefixed',
    DartFixKindPriority.standard + 7,
    "Import library '{0}' with prefix '{1}'",
  );
  static const importLibrarySdkShow = FixKind(
    'dart.fix.import.librarySdkShow',
    DartFixKindPriority.standard + 7,
    "Import library '{0}' with 'show'",
  );
  static const importLibrarySdkPrefixedShow = FixKind(
    'dart.fix.import.librarySdkPrefixedShow',
    DartFixKindPriority.standard + 7,
    "Import library '{0}' with prefix '{1}' and 'show'",
  );
  static const inlineInvocation = FixKind(
    'dart.fix.inlineInvocation',
    DartFixKindPriority.ignore,
    "Inline invocation of '{0}'",
  );
  static const inlineInvocationMulti = FixKind(
    'dart.fix.inlineInvocation.multi',
    DartFixKindPriority.inFile - 20,
    'Inline invocations everywhere in file',
  );
  static const inlineTypedef = FixKind(
    'dart.fix.inlineTypedef',
    DartFixKindPriority.ignore,
    "Inline the definition of '{0}'",
  );
  static const inlineTypedefMulti = FixKind(
    'dart.fix.inlineTypedef.multi',
    DartFixKindPriority.inFile - 20,
    'Inline type definitions everywhere in file',
  );
  static const insertBody = FixKind(
    'dart.fix.insertBody',
    DartFixKindPriority.standard,
    'Insert body',
  );
  static const insertOnKeyword = FixKind(
    'dart.fix.insertOnKeyword',
    DartFixKindPriority.standard,
    "Insert 'on' keyword",
  );
  static const insertOnKeywordMulti = FixKind(
    'dart.fix.insertOnKeyword.multi',
    DartFixKindPriority.inFile,
    "Insert 'on' keyword in file",
  );
  static const insertSemicolon = FixKind(
    'dart.fix.insertSemicolon',
    DartFixKindPriority.standard,
    "Insert ';'",
  );
  static const insertSemicolonMulti = FixKind(
    'dart.fix.insertSemicolon.multi',
    DartFixKindPriority.inFile,
    "Insert ';' everywhere in file",
  );
  static const makeClassAbstract = FixKind(
    'dart.fix.makeClassAbstract',
    DartFixKindPriority.standard,
    "Make class '{0}' abstract",
  );
  static const makeFieldNotFinal = FixKind(
    'dart.fix.makeFieldNotFinal',
    DartFixKindPriority.standard,
    "Make field '{0}' not final",
  );
  static const makeFieldPublic = FixKind(
    'dart.fix.makeFieldPublic',
    DartFixKindPriority.standard,
    "Make field '{0}' public",
  );
  static const makeFinal = FixKind(
    'dart.fix.makeFinal',
    DartFixKindPriority.standard,
    'Make final',
  );
  // TODO(pq): consider parameterizing: 'Make {fields} final...'
  static const makeFinalMulti = FixKind(
    'dart.fix.makeFinal.multi',
    DartFixKindPriority.inFile,
    'Make final where possible in file',
  );
  static const makeReturnTypeNullable = FixKind(
    'dart.fix.makeReturnTypeNullable',
    DartFixKindPriority.standard,
    'Make the return type nullable',
  );
  static const makeConditionalOnDebugMode = FixKind(
    'dart.fix.flutter.makeConditionalOnDebugMode',
    DartFixKindPriority.standard,
    "Make conditional on 'kDebugMode'",
  );
  static const makeRequiredNamedParametersFirst = FixKind(
    'dart.fix.makeRequiredNamedParametersFirst',
    DartFixKindPriority.standard,
    'Put required named parameter first',
  );
  static const makeRequiredNamedParametersFirstMulti = FixKind(
    'dart.fix.makeRequiredNamedParametersFirst.multi',
    DartFixKindPriority.inFile,
    'Put required named parameters first everywhere in file',
  );
  static const makeSuperInvocationLast = FixKind(
    'dart.fix.makeSuperInvocationLast',
    DartFixKindPriority.standard,
    'Move the invocation to the end of the initializer list',
  );
  static const makeVariableNotFinal = FixKind(
    'dart.fix.makeVariableNotFinal',
    DartFixKindPriority.standard,
    "Make variable '{0}' not final",
  );
  static const makeVariableNullable = FixKind(
    'dart.fix.makeVariableNullable',
    DartFixKindPriority.standard,
    "Make '{0}' nullable",
  );
  static const matchAnyMap = FixKind(
    'dart.fix.matchAnyMap',
    DartFixKindPriority.standard,
    'Match any map',
  );
  static const matchEmptyMap = FixKind(
    'dart.fix.matchEmptyMap',
    DartFixKindPriority.standard,
    'Match an empty map',
  );

  /// Used when the user has at least one `show` combinator to suggest merging
  /// using `show`.
  static const mergeCombinatorsShowShow = FixKind(
    'dart.fix.mergeCombinatorsShow.show',
    DartFixKindPriority.standard + 1,
    "Merge combinators into a single 'show'",
  );

  /// Used when the user has only `hide` combinators to suggest merging using
  /// `show`.
  static const mergeCombinatorsShowHide = FixKind(
    'dart.fix.mergeCombinatorsShow.hide',
    DartFixKindPriority.standard,
    "Merge combinators into a single 'show'",
  );

  /// Used when the user has only `hide` combinators to suggest merging using
  /// `hide`.
  static const mergeCombinatorsHideHide = FixKind(
    'dart.fix.mergeCombinatorsHide.hide',
    DartFixKindPriority.standard + 1,
    "Merge combinators into a single 'hide'",
  );

  /// Used when the user has at least one `show` combinator to suggest merging
  /// using `hide`.
  static const mergeCombinatorsHideShow = FixKind(
    'dart.fix.mergeCombinatorsHide.show',
    DartFixKindPriority.standard,
    "Merge combinators into a single 'hide'",
  );
  static const moveAnnotationToLibraryDirective = FixKind(
    'dart.fix.moveAnnotationToLibraryDirective',
    DartFixKindPriority.standard,
    'Move this annotation to a library directive',
  );
  static const moveDocCommentToLibraryDirective = FixKind(
    'dart.fix.moveDocCommentToLibraryDirective',
    DartFixKindPriority.standard,
    'Move this doc comment to a library directive',
  );
  static const moveTypeArgumentsToClass = FixKind(
    'dart.fix.moveTypeArgumentsToClass',
    DartFixKindPriority.standard,
    'Move type arguments to after class name',
  );
  static const organizeImports = FixKind(
    'dart.fix.organize.imports',
    DartFixKindPriority.standard,
    'Organize Imports',
  );
  static const qualifyReference = FixKind(
    'dart.fix.qualifyReference',
    DartFixKindPriority.standard,
    "Use '{0}'",
  );
  static const removeAbstract = FixKind(
    'dart.fix.remove.abstract',
    DartFixKindPriority.standard,
    "Remove the 'abstract' keyword",
  );
  static const removeAbstractMulti = FixKind(
    'dart.fix.remove.abstract.multi',
    DartFixKindPriority.inFile,
    "Remove the 'abstract' keyword everywhere in file",
  );
  static const removeAnnotation = FixKind(
    'dart.fix.remove.annotation',
    DartFixKindPriority.standard,
    "Remove the '{0}' annotation",
  );
  static const removeArgument = FixKind(
    'dart.fix.remove.argument',
    DartFixKindPriority.standard,
    'Remove argument',
  );
  // TODO(pq): used by LintNames.avoid_redundant_argument_values;
  //  consider a parameterized message
  static const removeArgumentMulti = FixKind(
    'dart.fix.remove.argument.multi',
    DartFixKindPriority.inFile,
    'Remove arguments in file',
  );
  static const removeAssertion = FixKind(
    'dart.fix.remove.assertion',
    DartFixKindPriority.standard,
    'Remove the assertion',
  );
  static const removeAssignment = FixKind(
    'dart.fix.remove.assignment',
    DartFixKindPriority.standard,
    'Remove assignment',
  );
  static const removeAssignmentMulti = FixKind(
    'dart.fix.remove.assignment.multi',
    DartFixKindPriority.inFile,
    'Remove unnecessary assignments everywhere in file',
  );
  static const removeAsync = FixKind(
    'dart.fix.remove.async',
    DartFixKindPriority.standard,
    "Remove 'async' modifier",
  );
  static const removeAwait = FixKind(
    'dart.fix.remove.await',
    DartFixKindPriority.standard,
    "Remove 'await'",
  );
  static const removeAwaitMulti = FixKind(
    'dart.fix.remove.await.multi',
    DartFixKindPriority.inFile,
    "Remove 'await's in file",
  );
  static const removeBreak = FixKind(
    'dart.fix.remove.break',
    DartFixKindPriority.standard,
    "Remove 'break'",
  );
  static const removeBreakMulti = FixKind(
    'dart.fix.remove.break.multi',
    DartFixKindPriority.inFile,
    "Remove unnecessary 'break's in file",
  );
  static const removeCharacter = FixKind(
    'dart.fix.remove.character',
    DartFixKindPriority.standard,
    "Remove the 'U+{0}' code point",
  );
  static const removeComma = FixKind(
    'dart.fix.remove.comma',
    DartFixKindPriority.standard,
    'Remove the comma',
  );
  static const removeCommaMulti = FixKind(
    'dart.fix.remove.comma.multi',
    DartFixKindPriority.inFile,
    'Remove {0}commas from {1} everywhere in file',
  );
  static const removeComment = FixKind(
    'dart.fix.remove.comment',
    DartFixKindPriority.standard,
    'Remove the comment',
  );
  static const removeComparison = FixKind(
    'dart.fix.remove.comparison',
    DartFixKindPriority.standard,
    'Remove comparison',
  );
  static const removeComparisonMulti = FixKind(
    'dart.fix.remove.comparison.multi',
    DartFixKindPriority.inFile,
    'Remove comparisons in file',
  );
  static const removeConst = FixKind(
    'dart.fix.remove.const',
    DartFixKindPriority.standard,
    "Remove 'const'",
  );
  static const removeConstructor = FixKind(
    'dart.fix.remove.constructor',
    DartFixKindPriority.standard,
    'Remove the constructor',
  );
  static const removeConstructorName = FixKind(
    'dart.fix.remove.constructorName',
    DartFixKindPriority.standard,
    "Remove 'new'",
  );
  static const removeConstructorNameMulti = FixKind(
    'dart.fix.remove.constructorName.multi',
    DartFixKindPriority.inFile,
    'Remove constructor names in file',
  );
  static const removeDeadCode = FixKind(
    'dart.fix.remove.deadCode',
    DartFixKindPriority.standard,
    'Remove dead code',
  );
  static const removeDefaultValue = FixKind(
    'dart.fix.remove.defaultValue',
    DartFixKindPriority.standard,
    'Remove the default value',
  );
  static const removeDeprecatedNewInCommentReference = FixKind(
    'dart.fix.remove.deprecatedNewInCommentReference',
    DartFixKindPriority.standard,
    "Remove deprecated 'new' keyword",
  );
  static const removeDeprecatedNewInCommentReferenceMulti = FixKind(
    'dart.fix.remove.deprecatedNewInCommentReference.multi',
    DartFixKindPriority.inFile,
    "Remove deprecated 'new' keyword in file",
  );
  static const removeDuplicateCase = FixKind(
    'dart.fix.remove.duplicateCase',
    DartFixKindPriority.standard,
    'Remove duplicate case statement',
  );
  // TODO(pq): is this dangerous to bulk apply?  Consider removing.
  static const removeDuplicateCaseMulti = FixKind(
    'dart.fix.remove.duplicateCase.multi',
    DartFixKindPriority.inFile,
    'Remove duplicate case statement',
  );
  static const removeEmptyCatch = FixKind(
    'dart.fix.remove.emptyCatch',
    DartFixKindPriority.standard,
    'Remove empty catch clause',
  );
  static const removeEmptyCatchMulti = FixKind(
    'dart.fix.remove.emptyCatch.multi',
    DartFixKindPriority.inFile,
    'Remove empty catch clauses everywhere in file',
  );
  static const removeEmptyConstructorBody = FixKind(
    'dart.fix.remove.emptyConstructorBody',
    DartFixKindPriority.standard,
    'Remove empty constructor body',
  );
  static const removeEmptyConstructorBodyMulti = FixKind(
    'dart.fix.remove.emptyConstructorBody.multi',
    DartFixKindPriority.inFile,
    'Remove empty constructor bodies in file',
  );
  static const removeEmptyElse = FixKind(
    'dart.fix.remove.emptyElse',
    DartFixKindPriority.standard,
    'Remove empty else clause',
  );
  static const removeEmptyElseMulti = FixKind(
    'dart.fix.remove.emptyElse.multi',
    DartFixKindPriority.inFile,
    'Remove empty else clauses everywhere in file',
  );
  static const removeEmptyStatement = FixKind(
    'dart.fix.remove.emptyStatement',
    DartFixKindPriority.standard,
    'Remove empty statement',
  );
  static const removeEmptyStatementMulti = FixKind(
    'dart.fix.remove.emptyStatement.multi',
    DartFixKindPriority.inFile,
    'Remove empty statements everywhere in file',
  );
  static const removeExtendsClause = FixKind(
    'dart.fix.remove.extends.clause',
    DartFixKindPriority.standard,
    "Remove the invalid 'extends' clause",
  );
  static const removeExtendsClauseMulti = FixKind(
    'dart.fix.remove.extends.clause.multi',
    DartFixKindPriority.inFile,
    "Remove invalid 'extends' clauses everywhere in file",
  );
  static const removeLexeme = FixKind(
    'dart.fix.remove.lexeme',
    DartFixKindPriority.standard,
    'Remove the {0} {1}',
  );
  static const removeLexemeMulti = FixKind(
    'dart.fix.remove.lexeme.multi',
    DartFixKindPriority.inFile,
    'Remove {0}s everywhere in file',
  );
  static const removeIfNullOperator = FixKind(
    'dart.fix.remove.ifNullOperator',
    DartFixKindPriority.standard,
    "Remove the '??' operator",
  );
  static const removeIfNullOperatorMulti = FixKind(
    'dart.fix.remove.ifNullOperator.multi',
    DartFixKindPriority.inFile,
    "Remove unnecessary '??' operators everywhere in file",
  );
  static const removeIgnoredDiagnostic = FixKind(
    'dart.fix.remove.ignored.diagnostic',
    DartFixKindPriority.standard,
    'Remove {0}',
  );
  static const removeIgnoredDiagnosticMulti = FixKind(
    'dart.fix.remove.ignored.diagnostic.multi',
    DartFixKindPriority.inFile,
    'Remove unnecessary ignored diagnostics everywhere in file',
  );
  static const removeInvocation = FixKind(
    'dart.fix.remove.invocation',
    DartFixKindPriority.standard,
    'Remove unnecessary invocation of {0}',
  );
  static const removeInvocationMulti = FixKind(
    'dart.fix.remove.invocation.multi',
    DartFixKindPriority.inFile,
    'Remove unnecessary invocations everywhere in file',
  );
  static const removeInitializer = FixKind(
    'dart.fix.remove.initializer',
    DartFixKindPriority.standard,
    'Remove initializer',
  );
  static const removeInitializerMulti = FixKind(
    'dart.fix.remove.initializer.multi',
    DartFixKindPriority.inFile,
    'Remove unnecessary initializers everywhere in file',
  );
  static const removeInterpolationBraces = FixKind(
    'dart.fix.remove.interpolationBraces',
    DartFixKindPriority.standard,
    'Remove unnecessary interpolation braces',
  );
  static const removeInterpolationBracesMulti = FixKind(
    'dart.fix.remove.interpolationBraces.multi',
    DartFixKindPriority.inFile,
    'Remove unnecessary interpolation braces everywhere in file',
  );
  static const removeLate = FixKind(
    'dart.fix.remove.late',
    DartFixKindPriority.standard,
    "Remove the 'late' keyword",
  );
  static const removeLateMulti = FixKind(
    'dart.fix.remove.late.multi',
    DartFixKindPriority.standard,
    "Remove the 'late' keyword everywhere in file",
  );
  static const removeLeadingUnderscore = FixKind(
    'dart.fix.remove.leadingUnderscore',
    DartFixKindPriority.standard,
    'Remove leading underscore',
  );
  static const removeLeadingUnderscoreMulti = FixKind(
    'dart.fix.remove.leadingUnderscore.multi',
    DartFixKindPriority.inFile,
    'Remove leading underscores in file',
  );
  static const removeLibraryName = FixKind(
    'dart.fix.remove.library.name',
    DartFixKindPriority.standard,
    'Remove the library name',
  );
  static const removeMethoddeclaration = FixKind(
    'dart.fix.remove.methodDeclaration',
    DartFixKindPriority.standard,
    'Remove method declaration',
  );
  // TODO(pq): parameterize to make scope explicit
  static const removeMethodDeclarationMulti = FixKind(
    'dart.fix.remove.methodDeclaration.multi',
    DartFixKindPriority.inFile,
    'Remove unnecessary method declarations in file',
  );
  static const removeNameFromCombinator = FixKind(
    'dart.fix.remove.nameFromCombinator',
    DartFixKindPriority.standard,
    "Remove name from '{0}'",
  );
  static const removeNameFromDeclarationClause = FixKind(
    'dart.fix.remove.nameFromDeclarationClause',
    DartFixKindPriority.standard,
    '{0}',
  );
  static const removeNew = FixKind(
    'dart.fix.remove.new',
    DartFixKindPriority.standard,
    "Remove 'new' keyword",
  );
  static const removeNonNullAssertion = FixKind(
    'dart.fix.remove.nonNullAssertion',
    DartFixKindPriority.standard,
    "Remove the '!'",
  );
  static const removeNonNullAssertionMulti = FixKind(
    'dart.fix.remove.nonNullAssertion.multi',
    DartFixKindPriority.inFile,
    "Remove '!'s in file",
  );
  static const removeOnClause = FixKind(
    'dart.fix.remove.on.clause',
    DartFixKindPriority.standard,
    "Remove the invalid 'on' clause",
  );
  static const removeOnClauseMulti = FixKind(
    'dart.fix.remove.on.clause.multi',
    DartFixKindPriority.inFile,
    "Remove all invalid 'on' clauses in file",
  );
  static const removeOperator = FixKind(
    'dart.fix.remove.operator',
    DartFixKindPriority.standard,
    'Remove the operator',
  );
  static const removeOperatorMulti = FixKind(
    'dart.fix.remove.operator.multi.multi',
    DartFixKindPriority.inFile,
    'Remove operators in file',
  );
  static const removeParenthesesInGetterDeclaration = FixKind(
    'dart.fix.remove.parametersInGetterDeclaration',
    DartFixKindPriority.standard,
    'Remove parameters in getter declaration',
  );
  static const removeParenthesesInGetterInvocation = FixKind(
    'dart.fix.remove.parenthesisInGetterInvocation',
    DartFixKindPriority.standard,
    'Remove parentheses in getter invocation',
  );
  static const removePrint = FixKind(
    'dart.fix.remove.removePrint',
    DartFixKindPriority.standard,
    'Remove print statement',
  );
  static const removePrintMulti = FixKind(
    'dart.fix.remove.removePrint.multi',
    DartFixKindPriority.inFile,
    'Remove print statements in file',
  );
  static const removeQuestionMark = FixKind(
    'dart.fix.remove.questionMark',
    DartFixKindPriority.standard,
    "Remove the '?'",
  );
  static const removeQuestionMarkMulti = FixKind(
    'dart.fix.remove.questionMark.multi',
    DartFixKindPriority.inFile,
    'Remove unnecessary question marks in file',
  );
  static const removeRequired = FixKind(
    'dart.fix.remove.required',
    DartFixKindPriority.standard,
    "Remove 'required'",
  );
  static const removeReturnedValue = FixKind(
    'dart.fix.remove.returnedValue',
    DartFixKindPriority.standard,
    'Remove invalid returned value',
  );
  static const removeReturnedValueMulti = FixKind(
    'dart.fix.remove.returnedValue.multi',
    DartFixKindPriority.inFile,
    'Remove invalid returned values in file',
  );
  static const removeThisExpression = FixKind(
    'dart.fix.remove.thisExpression',
    DartFixKindPriority.standard,
    "Remove 'this' expression",
  );
  static const removeThisExpressionMulti = FixKind(
    'dart.fix.remove.thisExpression.multi',
    DartFixKindPriority.inFile,
    "Remove unnecessary 'this' expressions everywhere in file",
  );
  static const removeTypeAnnotation = FixKind(
    'dart.fix.remove.typeAnnotation',
    DartFixKindPriority.standard,
    'Remove type annotation',
  );
  static const removeTypeAnnotationMulti = FixKind(
    'dart.fix.remove.typeAnnotation.multi',
    DartFixKindPriority.inFile,
    'Remove unnecessary type annotations in file',
  );
  static const removeTypeArguments = FixKind(
    'dart.fix.remove.typeArguments',
    DartFixKindPriority.standard - 1,
    'Remove type arguments',
  );
  static const removeTypeCheck = FixKind(
    'dart.fix.remove.typeCheck',
    DartFixKindPriority.standard,
    'Remove type check',
  );
  static const removeTypeCheckMulti = FixKind(
    'dart.fix.remove.comparison.multi',
    DartFixKindPriority.inFile,
    'Remove type check everywhere in file',
  );
  static const removeUnawaited = FixKind(
    'dart.fix.remove.unawaited',
    DartFixKindPriority.standard,
    "Remove 'unawaited' call",
  );
  static const removeUnawaitedMulti = FixKind(
    'dart.fix.remove.unawaited.multi',
    DartFixKindPriority.standard,
    "Remove 'unawaited' call in file",
  );
  static const removeUnexpectedUnderscores = FixKind(
    'dart.fix.remove.unexpectedUnderscores',
    DartFixKindPriority.standard,
    "Remove unexpected '_' characters",
  );
  static const removeUnexpectedUnderscoresMulti = FixKind(
    'dart.fix.remove.unexpectedUnderscores.multi',
    DartFixKindPriority.standard,
    "Remove unexpected '_' characters in file",
  );
  static const removeUnnecessaryCast = FixKind(
    'dart.fix.remove.unnecessaryCast',
    DartFixKindPriority.standard,
    'Remove unnecessary cast',
  );
  static const removeUnnecessaryCastMulti = FixKind(
    'dart.fix.remove.unnecessaryCast.multi',
    DartFixKindPriority.inFile,
    'Remove all unnecessary casts in file',
  );
  static const removeUnnecessaryName = FixKind(
    'dart.fix.remove.unnecessaryName',
    DartFixKindPriority.standard,
    'Remove unnecessary name from pattern',
  );
  static const removeUnnecessaryNameMulti = FixKind(
    'dart.fix.remove.unnecessaryName.multi',
    DartFixKindPriority.inFile,
    'Remove unnecessary names from patterns in file',
  );
  static const removeUnnecessaryFinal = FixKind(
    'dart.fix.remove.unnecessaryFinal',
    DartFixKindPriority.standard,
    "Remove unnecessary 'final'",
  );
  static const removeUnnecessaryFinalMulti = FixKind(
    'dart.fix.remove.unnecessaryFinal.multi',
    DartFixKindPriority.inFile,
    "Remove all unnecessary 'final's in file",
  );
  static const removeUnnecessaryConst = FixKind(
    'dart.fix.remove.unnecessaryConst',
    DartFixKindPriority.standard,
    "Remove unnecessary 'const' keyword",
  );
  static const removeUnnecessaryConstMulti = FixKind(
    'dart.fix.remove.unnecessaryConst.multi',
    DartFixKindPriority.inFile,
    "Remove unnecessary 'const' keywords everywhere in file",
  );
  static const removeUnnecessaryContainer = FixKind(
    'dart.fix.remove.unnecessaryContainer',
    DartFixKindPriority.standard,
    "Remove unnecessary 'Container'",
  );
  static const removeUnnecessaryContainerMulti = FixKind(
    'dart.fix.remove.unnecessaryContainer.multi',
    DartFixKindPriority.inFile,
    "Remove unnecessary 'Container's in file",
  );
  static const removeUnnecessaryIgnoreComment = FixKind(
    'dart.fix.remove.ignore.comment',
    DartFixKindPriority.standard,
    'Remove unnecessary ignore comment',
  );
  static const removeUnnecessaryIgnoreCommentMulti = FixKind(
    'dart.fix.remove.ignore.comment.multi',
    DartFixKindPriority.inFile,
    'Remove unnecessary ignore comments everywhere in file',
  );
  static const removeUnnecessaryLate = FixKind(
    'dart.fix.remove.unnecessaryLate',
    DartFixKindPriority.standard,
    "Remove unnecessary 'late' keyword",
  );
  static const removeUnnecessaryLateMulti = FixKind(
    'dart.fix.remove.unnecessaryLate.multi',
    DartFixKindPriority.inFile,
    "Remove unnecessary 'late' keywords everywhere in file",
  );
  static const removeUnnecessaryLibraryDirective = FixKind(
    'dart.fix.remove.unnecessaryLibraryDirective',
    DartFixKindPriority.standard,
    'Remove unnecessary library directive',
  );
  static const removeUnnecessaryNew = FixKind(
    'dart.fix.remove.unnecessaryNew',
    DartFixKindPriority.standard,
    "Remove unnecessary 'new' keyword",
  );
  static const removeUnnecessaryNewMulti = FixKind(
    'dart.fix.remove.unnecessaryNew.multi',
    DartFixKindPriority.inFile,
    "Remove unnecessary 'new' keywords everywhere in file",
  );
  static const removeUnnecessaryParentheses = FixKind(
    'dart.fix.remove.unnecessaryParentheses',
    DartFixKindPriority.standard,
    'Remove unnecessary parentheses',
  );
  static const removeUnnecessaryParenthesesMulti = FixKind(
    'dart.fix.remove.unnecessaryParentheses.multi',
    DartFixKindPriority.inFile,
    'Remove all unnecessary parentheses in file',
  );
  static const removeUnnecessaryRawString = FixKind(
    'dart.fix.remove.unnecessaryRawString',
    DartFixKindPriority.standard,
    "Remove unnecessary 'r' in string",
  );
  static const removeUnnecessaryRawStringMulti = FixKind(
    'dart.fix.remove.unnecessaryRawString.multi',
    DartFixKindPriority.inFile,
    "Remove unnecessary 'r' in strings in file",
  );
  static const removeUnnecessaryStringEscape = FixKind(
    'dart.fix.remove.unnecessaryStringEscape',
    DartFixKindPriority.standard,
    "Remove unnecessary '\\' in string",
  );
  static const removeUnnecessaryStringEscapeMulti = FixKind(
    'dart.fix.remove.unnecessaryStringEscape.multi',
    DartFixKindPriority.inFile,
    "Remove unnecessary '\\' in strings in file",
  );
  static const removeUnnecessaryStringInterpolation = FixKind(
    'dart.fix.remove.unnecessaryStringInterpolation',
    DartFixKindPriority.standard,
    'Remove unnecessary string interpolation',
  );
  static const removeUnnecessaryStringInterpolationMulti = FixKind(
    'dart.fix.remove.unnecessaryStringInterpolation.multi',
    DartFixKindPriority.inFile,
    'Remove all unnecessary string interpolations in file',
  );
  static const removeUnnecessaryToList = FixKind(
    'dart.fix.remove.unnecessaryToList',
    DartFixKindPriority.standard,
    "Remove unnecessary 'toList' call",
  );
  static const removeUnnecessaryToListMulti = FixKind(
    'dart.fix.remove.unnecessaryToList.multi',
    DartFixKindPriority.inFile,
    "Remove unnecessary 'toList' calls in file",
  );
  static const removeUnnecessaryWildcardPattern = FixKind(
    'dart.fix.remove.unnecessaryWildcardPattern',
    DartFixKindPriority.standard,
    'Remove unnecessary wildcard pattern',
  );
  static const removeUnnecessaryWildcardPatternMulti = FixKind(
    'dart.fix.remove.unnecessaryWildcardPattern.multi',
    DartFixKindPriority.standard,
    'Remove all unnecessary wildcard pattern in file',
  );
  static const removeUnusedCatchClause = FixKind(
    'dart.fix.remove.unusedCatchClause',
    DartFixKindPriority.standard,
    "Remove unused 'catch' clause",
  );
  static const removeUnusedCatchClauseMulti = FixKind(
    'dart.fix.remove.unusedCatchClause.multi',
    DartFixKindPriority.inFile,
    "Remove unused 'catch' clauses in file",
  );
  static const removeUnusedCatchStack = FixKind(
    'dart.fix.remove.unusedCatchStack',
    DartFixKindPriority.standard,
    'Remove unused stack trace variable',
  );
  static const removeUnusedCatchStackMulti = FixKind(
    'dart.fix.remove.unusedCatchStack.multi',
    DartFixKindPriority.inFile,
    'Remove unused stack trace variables in file',
  );
  static const removeUnusedElement = FixKind(
    'dart.fix.remove.unusedElement',
    DartFixKindPriority.standard,
    'Remove unused element',
  );
  static const removeUnusedField = FixKind(
    'dart.fix.remove.unusedField',
    DartFixKindPriority.standard,
    'Remove unused field',
  );
  static const removeUnusedImport = FixKind(
    'dart.fix.remove.unusedImport',
    DartFixKindPriority.standard,
    'Remove unused import',
  );
  static const removeUnusedImportMulti = FixKind(
    'dart.fix.remove.unusedImport.multi',
    DartFixKindPriority.inFile,
    'Remove all unused imports in file',
  );
  static const removeUnusedLabel = FixKind(
    'dart.fix.remove.unusedLabel',
    DartFixKindPriority.standard,
    'Remove unused label',
  );
  static const removeUnusedLocalVariable = FixKind(
    'dart.fix.remove.unusedLocalVariable',
    DartFixKindPriority.standard,
    'Remove unused local variable',
  );
  static const removeUnusedParameter = FixKind(
    'dart.fix.remove.unusedParameter',
    DartFixKindPriority.standard,
    'Remove the unused parameter',
  );
  static const removeUnusedParameterMulti = FixKind(
    'dart.fix.remove.unusedParameter.multi',
    DartFixKindPriority.inFile,
    'Remove unused parameters everywhere in file',
  );
  static const removeVar = FixKind(
    'dart.fix.remove.var',
    DartFixKindPriority.standard,
    "Remove 'var'",
  );
  static const removeVarKeyword = FixKind(
    'dart.fix.remove.var.keyword',
    DartFixKindPriority.standard,
    "Remove 'var'",
  );
  static const renameMethodParameter = FixKind(
    'dart.fix.rename.methodParameter',
    DartFixKindPriority.standard,
    "Rename '{0}' to '{1}'",
  );
  static const renameToCamelCase = FixKind(
    'dart.fix.rename.toCamelCase',
    DartFixKindPriority.standard,
    "Rename to '{0}'",
  );
  static const renameToCamelCaseMulti = FixKind(
    'dart.fix.rename.toCamelCase.multi',
    DartFixKindPriority.inFile,
    'Rename to camel case everywhere in file',
  );
  static const replaceBooleanWithBool = FixKind(
    'dart.fix.replace.booleanWithBool',
    DartFixKindPriority.standard,
    "Replace 'boolean' with 'bool'",
  );
  static const replaceBooleanWithBoolMulti = FixKind(
    'dart.fix.replace.booleanWithBool.multi',
    DartFixKindPriority.inFile,
    "Replace all 'boolean's with 'bool' in file",
  );
  static const replaceCascadeWithDot = FixKind(
    'dart.fix.replace.cascadeWithDot',
    DartFixKindPriority.standard,
    "Replace '..' with '.'",
  );
  static const replaceCascadeWithDotMulti = FixKind(
    'dart.fix.replace.cascadeWithDot.multi',
    DartFixKindPriority.inFile,
    "Replace unnecessary '..'s with '.'s everywhere in file",
  );
  static const replaceColonWithEquals = FixKind(
    'dart.fix.replace.colonWithEquals',
    DartFixKindPriority.standard,
    "Replace ':' with '='",
  );
  static const replaceColonWithEqualsMulti = FixKind(
    'dart.fix.replace.colonWithEquals.multi',
    DartFixKindPriority.inFile,
    "Replace ':'s with '='s everywhere in file",
  );
  static const replaceColonWithIn = FixKind(
    'dart.fix.replace.colonWithIn',
    DartFixKindPriority.standard,
    "Replace ':' with 'in'",
  );
  static const replaceColonWithInMulti = FixKind(
    'dart.fix.replace.colonWithIn.multi',
    DartFixKindPriority.inFile,
    "Replace ':'s with 'in's everywhere in file",
  );
  static const replaceContainerWithColoredBox = FixKind(
    'dart.fix.replace.containerWithColoredBox',
    DartFixKindPriority.standard,
    "Replace with 'ColoredBox'",
  );
  static const replaceContainerWithColoredBoxMulti = FixKind(
    'dart.fix.replace.containerWithColoredBox.multi',
    DartFixKindPriority.inFile,
    "Replace with 'ColoredBox' everywhere in file",
  );
  static const replaceContainerWithSizedBox = FixKind(
    'dart.fix.replace.containerWithSizedBox',
    DartFixKindPriority.standard,
    "Replace with 'SizedBox'",
  );
  static const replaceContainerWithSizedBoxMulti = FixKind(
    'dart.fix.replace.containerWithSizedBox.multi',
    DartFixKindPriority.inFile,
    "Replace with 'SizedBox' everywhere in file",
  );
  static const replaceFinalWithConst = FixKind(
    'dart.fix.replace.finalWithConst',
    DartFixKindPriority.standard,
    "Replace 'final' with 'const'",
  );
  static const replaceFinalWithConstMulti = FixKind(
    'dart.fix.replace.finalWithConst.multi',
    DartFixKindPriority.inFile,
    "Replace 'final' with 'const' where possible in file",
  );
  static const replaceFinalWithVar = FixKind(
    'dart.fix.replace.finalWithVar',
    DartFixKindPriority.standard,
    "Replace 'final' with 'var'",
  );
  static const replaceFinalWithVarMulti = FixKind(
    'dart.fix.replace.finalWithVar.multi',
    DartFixKindPriority.inFile,
    "Replace 'final' with 'var' where possible in file",
  );
  static const replaceNewWithConst = FixKind(
    'dart.fix.replace.newWithConst',
    DartFixKindPriority.standard,
    "Replace 'new' with 'const'",
  );
  static const replaceNewWithConstMulti = FixKind(
    'dart.fix.replace.newWithConst.multi',
    DartFixKindPriority.inFile,
    "Replace 'new' with 'const' where possible in file",
  );
  static const replaceNullCheckWithCast = FixKind(
    'dart.fix.replace.nullCheckWithCast',
    DartFixKindPriority.standard,
    'Replace null check with a cast',
  );
  static const replaceNullCheckWithCastMulti = FixKind(
    'dart.fix.replace.nullCheckWithCast.multi',
    DartFixKindPriority.inFile,
    'Replace null checks with casts in file',
  );
  static const replaceNullWithClosure = FixKind(
    'dart.fix.replace.nullWithClosure',
    DartFixKindPriority.standard,
    "Replace 'null' with a closure",
  );
  static const replaceNullWithClosureMulti = FixKind(
    'dart.fix.replace.nullWithClosure.multi',
    DartFixKindPriority.inFile,
    "Replace 'null's with closures where possible in file",
  );
  static const replaceNullWithVoid = FixKind(
    'dart.fix.replace.nullWithVoid',
    DartFixKindPriority.standard,
    "Replace 'Null' with 'void'",
  );
  static const replaceNullWithVoidMulti = FixKind(
    'dart.fix.replace.nullWithVoid.multi',
    DartFixKindPriority.inFile,
    "Replace 'Null' with 'void' everywhere in file",
  );
  static const replaceReturnType = FixKind(
    'dart.fix.replace.returnType',
    DartFixKindPriority.standard,
    "Replace the return type with '{0}'",
  );
  static const replaceReturnTypeFuture = FixKind(
    'dart.fix.replace.returnTypeFuture',
    DartFixKindPriority.standard,
    "Return 'Future<{0}>'",
  );
  static const replaceReturnTypeFutureMulti = FixKind(
    'dart.fix.replace.returnTypeFuture.multi',
    DartFixKindPriority.inFile,
    "Return a 'Future' where required in file",
  );
  static const replaceReturnTypeIterable = FixKind(
    'dart.fix.replace.returnTypeIterable',
    DartFixKindPriority.standard,
    "Return 'Iterable<{0}>'",
  );
  static const replaceReturnTypeStream = FixKind(
    'dart.fix.replace.returnTypeStream',
    DartFixKindPriority.standard,
    "Return 'Stream<{0}>'",
  );
  static const replaceVarWithDynamic = FixKind(
    'dart.fix.replace.varWithDynamic',
    DartFixKindPriority.standard,
    "Replace 'var' with 'dynamic'",
  );
  static const replaceWithArrow = FixKind(
    'dart.fix.replace.withArrow',
    DartFixKindPriority.standard,
    "Replace with '=>'",
  );
  static const replaceWithArrowMulti = FixKind(
    'dart.fix.replace.withArrow.multi',
    DartFixKindPriority.standard,
    "Replace with '=>' everywhere in file",
  );
  static const replaceWithBrackets = FixKind(
    'dart.fix.replace.withBrackets',
    DartFixKindPriority.standard,
    'Replace with { }',
  );
  static const replaceWithBracketsMulti = FixKind(
    'dart.fix.replace.withBrackets.multi',
    DartFixKindPriority.inFile,
    'Replace with { } everywhere in file',
  );
  static const replaceWithConditionalAssignment = FixKind(
    'dart.fix.replace.withConditionalAssignment',
    DartFixKindPriority.standard,
    'Replace with ??=',
  );
  static const replaceWithConditionalAssignmentMulti = FixKind(
    'dart.fix.replace.withConditionalAssignment.multi',
    DartFixKindPriority.inFile,
    'Replace with ??= everywhere in file',
  );
  static const replaceWithDecoratedBox = FixKind(
    'dart.fix.replace.withDecoratedBox',
    DartFixKindPriority.standard,
    "Replace with 'DecoratedBox'",
  );
  static const replaceWithDecoratedBoxMulti = FixKind(
    'dart.fix.replace.withDecoratedBox.multi',
    DartFixKindPriority.inFile,
    "Replace with 'DecoratedBox' everywhere in file",
  );
  static const replaceWithEightDigitHex = FixKind(
    'dart.fix.replace.withEightDigitHex',
    DartFixKindPriority.standard,
    "Replace with '{0}'",
  );
  static const replaceWithEightDigitHexMulti = FixKind(
    'dart.fix.replace.withEightDigitHex.multi',
    DartFixKindPriority.inFile,
    'Replace with hex digits everywhere in file',
  );
  static const replaceWithExtensionName = FixKind(
    'dart.fix.replace.withExtensionName',
    DartFixKindPriority.standard,
    "Replace with '{0}'",
  );
  static const replaceWithIdentifier = FixKind(
    'dart.fix.replace.withIdentifier',
    DartFixKindPriority.standard,
    'Replace with identifier',
  );
  // TODO(pq): parameterize message (used by LintNames.avoid_types_on_closure_parameters)
  static const replaceWithIdentifierMulti = FixKind(
    'dart.fix.replace.withIdentifier.multi',
    DartFixKindPriority.inFile,
    'Replace with identifier everywhere in file',
  );
  static const replaceWithInterpolation = FixKind(
    'dart.fix.replace.withInterpolation',
    DartFixKindPriority.standard,
    'Replace with interpolation',
  );
  static const replaceWithInterpolationMulti = FixKind(
    'dart.fix.replace.withInterpolation.multi',
    DartFixKindPriority.inFile,
    'Replace with interpolations everywhere in file',
  );
  static const replaceWithIsEmpty = FixKind(
    'dart.fix.replace.withIsEmpty',
    DartFixKindPriority.standard,
    "Replace with 'isEmpty'",
  );
  static const replaceWithIsEmptyMulti = FixKind(
    'dart.fix.replace.withIsEmpty.multi',
    DartFixKindPriority.inFile,
    "Replace with 'isEmpty' everywhere in file",
  );
  static const replaceWithIsNaN = FixKind(
    'dart.fix.replace.withIsNaN',
    DartFixKindPriority.standard,
    "Replace the condition with '.isNaN'",
  );
  static const replaceWithIsNotEmpty = FixKind(
    'dart.fix.replace.withIsNotEmpty',
    DartFixKindPriority.standard,
    "Replace with 'isNotEmpty'",
  );
  static const replaceWithIsNotEmptyMulti = FixKind(
    'dart.fix.replace.withIsNotEmpty.multi',
    DartFixKindPriority.inFile,
    "Replace with 'isNotEmpty' everywhere in file",
  );
  static const replaceWithNotNullAware = FixKind(
    'dart.fix.replace.withNotNullAware',
    DartFixKindPriority.standard,
    "Replace with '{0}'",
  );
  static const replaceWithNotNullAwareElementOrEntry = FixKind(
    'dart.fix.replace.withNotNullAwareElementOrEntry',
    DartFixKindPriority.standard,
    "Remove the '?'",
  );
  static const replaceWithNotNullAwareElementOrEntryMulti = FixKind(
    'dart.fix.replace.withNotNullAwareElementOrEntry.multi',
    DartFixKindPriority.inFile,
    "Remove the '?' everywhere in file",
  );
  static const replaceWithNotNullAwareMulti = FixKind(
    'dart.fix.replace.withNotNullAware.multi',
    DartFixKindPriority.inFile,
    'Replace with non-null-aware operator everywhere in file',
  );
  static const replaceWithNullAware = FixKind(
    'dart.fix.replace.withNullAware',
    DartFixKindPriority.standard,
    "Replace the '{0}' with a '{1}' in the invocation",
  );
  static const replaceWithPartOfUri = FixKind(
    'dart.fix.replace.withPartOfUri',
    DartFixKindPriority.standard,
    "Replace with 'part of {0}'",
  );
  static const replaceWithTearOff = FixKind(
    'dart.fix.replace.withTearOff',
    DartFixKindPriority.standard,
    'Replace function literal with tear-off',
  );
  static const replaceWithTearOffMulti = FixKind(
    'dart.fix.replace.withTearOff.multi',
    DartFixKindPriority.inFile,
    'Replace function literals with tear-offs everywhere in file',
  );
  static const replaceWithUnicodeEscape = FixKind(
    'dart.fix.replace.withUnicodeEscape',
    DartFixKindPriority.standard,
    'Replace with Unicode escape',
  );
  static const replaceWithIs = FixKind(
    'dart.fix.replace.withIs',
    DartFixKindPriority.standard,
    "Replace '{0}' with 'is{1}'",
  );
  static const replaceWithVar = FixKind(
    'dart.fix.replace.withVar',
    DartFixKindPriority.standard,
    "Replace type annotation with 'var'",
  );
  static const replaceWithVarMulti = FixKind(
    'dart.fix.replace.withVar.multi',
    DartFixKindPriority.inFile,
    "Replace type annotations with 'var' everywhere in file",
  );
  static const replaceWithWildcard = FixKind(
    'dart.fix.replace.withWildcard',
    DartFixKindPriority.standard,
    "Replace with '_'",
  );
  static const replaceWithWildcardMulti = FixKind(
    'dart.fix.replace.withWildcard.multi',
    DartFixKindPriority.standard,
    "Replace with '_' everywhere in file",
  );
  static const sortChildPropertyLast = FixKind(
    'dart.fix.sort.childPropertyLast',
    DartFixKindPriority.standard,
    'Move child property to end of arguments',
  );
  static const sortChildPropertyLastMulti = FixKind(
    'dart.fix.sort.childPropertyLast.multi',
    DartFixKindPriority.inFile,
    'Move child properties to ends of arguments everywhere in file',
  );
  static const sortCombinators = FixKind(
    'dart.fix.sort.combinators',
    DartFixKindPriority.standard,
    'Sort combinators',
  );
  static const sortCombinatorsMulti = FixKind(
    'dart.fix.sort.combinators.multi',
    DartFixKindPriority.inFile,
    'Sort combinators everywhere in file',
  );
  static const sortConstructorFirst = FixKind(
    'dart.fix.sort.sortConstructorFirst',
    DartFixKindPriority.standard,
    'Move before other members',
  );
  static const sortConstructorFirstMulti = FixKind(
    'dart.fix.sort.sortConstructorFirst.multi',
    DartFixKindPriority.standard,
    'Move all constructors before other members',
  );
  static const sortUnnamedConstructorFirst = FixKind(
    'dart.fix.sort.sortUnnamedConstructorFirst',
    DartFixKindPriority.standard,
    'Move before named constructors',
  );
  static const sortUnnamedConstructorFirstMulti = FixKind(
    'dart.fix.sort.sortUnnamedConstructorFirst.multi',
    DartFixKindPriority.standard,
    'Move all unnamed constructors before named constructors',
  );
  static const splitMultipleDeclarations = FixKind(
    'dart.fix.split.multipleDeclarations',
    DartFixKindPriority.standard,
    'Split multiple declarations into multiple lines',
  );
  static const splitMultipleDeclarationsMulti = FixKind(
    'dart.fix.split.multipleDeclarations.multi',
    DartFixKindPriority.standard,
    'Split all multiple declarations into multiple lines',
  );
  static const surroundWithParentheses = FixKind(
    'dart.fix.surround.parentheses',
    DartFixKindPriority.standard,
    'Surround with parentheses',
  );
  static const updateSdkConstraints = FixKind(
    'dart.fix.updateSdkConstraints',
    DartFixKindPriority.standard,
    'Update the SDK constraints',
  );
  static const useDivision = FixKind(
    'dart.fix.use.division',
    DartFixKindPriority.standard,
    'Use / instead of undefined ~/',
  );
  static const useEffectiveIntegerDivision = FixKind(
    'dart.fix.use.effectiveIntegerDivision',
    DartFixKindPriority.standard,
    'Use effective integer division ~/',
  );
  static const useEffectiveIntegerDivisionMulti = FixKind(
    'dart.fix.use.effectiveIntegerDivision.multi',
    DartFixKindPriority.inFile,
    'Use effective integer division ~/ everywhere in file',
  );
  static const useEqEqNull = FixKind(
    'dart.fix.use.eqEqNull',
    DartFixKindPriority.standard,
    "Use == null instead of 'is Null'",
  );
  static const useEqEqNullMulti = FixKind(
    'dart.fix.use.eqEqNull.multi',
    DartFixKindPriority.inFile,
    "Use == null instead of 'is Null' everywhere in file",
  );
  static const useIsNotEmpty = FixKind(
    'dart.fix.use.isNotEmpty',
    DartFixKindPriority.standard,
    "Use x.isNotEmpty instead of '!x.isEmpty'",
  );
  static const useIsNotEmptyMulti = FixKind(
    'dart.fix.use.isNotEmpty.multi',
    DartFixKindPriority.inFile,
    "Use x.isNotEmpty instead of '!x.isEmpty' everywhere in file",
  );
  static const useNamedConstants = FixKind(
    'dart.fix.use.namedConstants',
    DartFixKindPriority.standard,
    'Replace with a predefined named constant',
  );
  static const useNotEqNull = FixKind(
    'dart.fix.use.notEqNull',
    DartFixKindPriority.standard,
    "Use != null instead of 'is! Null'",
  );
  static const useNotEqNullMulti = FixKind(
    'dart.fix.use.notEqNull.multi',
    DartFixKindPriority.inFile,
    "Use != null instead of 'is! Null' everywhere in file",
  );
  static const useRethrow = FixKind(
    'dart.fix.use.rethrow',
    DartFixKindPriority.standard,
    'Replace throw with rethrow',
  );
  static const useRethrowMulti = FixKind(
    'dart.fix.use.rethrow.multi',
    DartFixKindPriority.inFile,
    'Replace throw with rethrow where possible in file',
  );
  static const wrapInText = FixKind(
    'dart.fix.flutter.wrap.text',
    DartFixKindPriority.standard,
    "Wrap in a 'Text' widget",
  );
  static const wrapInUnawaited = FixKind(
    'dart.fix.wrap.unawaited',
    DartFixKindPriority.standard,
    "Wrap in 'unawaited'",
  );
}
