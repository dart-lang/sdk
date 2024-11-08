// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// An enumeration of quick fix kinds for the errors found in an analysis
/// options file.
abstract final class AnalysisOptionsFixKind {
  static const REMOVE_LINT = FixKind(
    'analysisOptions.fix.removeLint',
    50,
    "Remove '{0}'",
  );
  static const REMOVE_SETTING = FixKind(
    'analysisOptions.fix.removeSetting',
    50,
    "Remove '{0}'",
  );
  static const REPLACE_WITH_STRICT_CASTS = FixKind(
    'analysisOptions.fix.replaceWithStrictCasts',
    50,
    'Replace with the strict-casts analysis mode',
  );
  static const REPLACE_WITH_STRICT_RAW_TYPES = FixKind(
    'analysisOptions.fix.replaceWithStrictRawTypes',
    50,
    'Replace with the strict-raw-types analysis mode',
  );
}

/// An enumeration of quick fix kinds found in a Dart file.
abstract final class DartFixKind {
  static const ADD_ASYNC = FixKind(
    'dart.fix.add.async',
    DartFixKindPriority.standard,
    "Add 'async' modifier",
  );
  static const ADD_AWAIT = FixKind(
    'dart.fix.add.await',
    DartFixKindPriority.standard,
    "Add 'await' keyword",
  );
  static const ADD_AWAIT_MULTI = FixKind(
    'dart.fix.add.await.multi',
    DartFixKindPriority.inFile,
    "Add 'await's everywhere in file",
  );
  static const ADD_CALL_SUPER = FixKind(
    'dart.fix.add.callSuper',
    DartFixKindPriority.standard,
    "Add 'super.{0}'",
  );
  static const ADD_EMPTY_ARGUMENT_LIST = FixKind(
    'dart.fix.add.empty.argument.list',
    DartFixKindPriority.standard,
    'Add empty argument list',
  );
  static const ADD_EMPTY_ARGUMENT_LIST_MULTI = FixKind(
    'dart.fix.add.empty.argument.list.multi',
    DartFixKindPriority.inFile,
    'Add empty argument lists everywhere in file',
  );
  static const ADD_CLASS_MODIFIER_BASE = FixKind(
    'dart.fix.add.class.modifier.base',
    DartFixKindPriority.standard,
    "Add 'base' modifier",
  );
  static const ADD_CLASS_MODIFIER_BASE_MULTI = FixKind(
    'dart.fix.add.class.modifier.base.multi',
    DartFixKindPriority.inFile,
    "Add 'base' modifier everywhere in file",
  );
  static const ADD_CLASS_MODIFIER_FINAL = FixKind(
    'dart.fix.add.class.modifier.final',
    DartFixKindPriority.standard,
    "Add 'final' modifier",
  );
  static const ADD_CLASS_MODIFIER_FINAL_MULTI = FixKind(
    'dart.fix.add.class.modifier.final.multi',
    DartFixKindPriority.inFile,
    "Add 'final' modifier everywhere in file",
  );
  static const ADD_CLASS_MODIFIER_SEALED = FixKind(
    'dart.fix.add.class.modifier.sealed',
    DartFixKindPriority.standard,
    "Add 'sealed' modifier",
  );
  static const ADD_CLASS_MODIFIER_SEALED_MULTI = FixKind(
    'dart.fix.add.class.modifier.sealed.multi',
    DartFixKindPriority.inFile,
    "Add 'sealed' modifier everywhere in file",
  );
  static const ADD_CONST = FixKind(
    'dart.fix.add.const',
    DartFixKindPriority.standard,
    "Add 'const' modifier",
  );
  static const ADD_CONST_MULTI = FixKind(
    'dart.fix.add.const.multi',
    DartFixKindPriority.inFile,
    "Add 'const' modifiers everywhere in file",
  );
  static const ADD_CURLY_BRACES = FixKind(
    'dart.fix.add.curlyBraces',
    DartFixKindPriority.standard,
    'Add curly braces',
  );
  static const ADD_CURLY_BRACES_MULTI = FixKind(
    'dart.fix.add.curlyBraces.multi',
    DartFixKindPriority.inFile,
    'Add curly braces everywhere in file',
  );
  static const ADD_DIAGNOSTIC_PROPERTY_REFERENCE = FixKind(
    'dart.fix.add.diagnosticPropertyReference',
    DartFixKindPriority.standard,
    'Add a debug reference to this property',
  );
  static const ADD_DIAGNOSTIC_PROPERTY_REFERENCE_MULTI = FixKind(
    'dart.fix.add.diagnosticPropertyReference.multi',
    DartFixKindPriority.inFile,
    'Add missing debug property references everywhere in file',
  );
  static const ADD_ENUM_CONSTANT = FixKind(
    'dart.fix.add.enumConstant',
    DartFixKindPriority.standard,
    "Add enum constant '{0}'",
  );
  static const ADD_EOL_AT_END_OF_FILE = FixKind(
    'dart.fix.add.eolAtEndOfFile',
    DartFixKindPriority.standard,
    'Add EOL at end of file',
  );
  static const ADD_EXTENSION_OVERRIDE = FixKind(
    'dart.fix.add.extensionOverride',
    DartFixKindPriority.standard,
    "Add an extension override for '{0}'",
  );
  static const ADD_EXPLICIT_CALL = FixKind(
    'dart.fix.add.explicitCall',
    DartFixKindPriority.standard,
    'Add explicit .call tearoff',
  );
  static const ADD_EXPLICIT_CALL_MULTI = FixKind(
    'dart.fix.add.explicitCall.multi',
    DartFixKindPriority.inFile,
    'Add explicit .call to implicit tearoffs in file',
  );
  static const ADD_EXPLICIT_CAST = FixKind(
    'dart.fix.add.explicitCast',
    DartFixKindPriority.standard,
    'Add cast',
  );
  static const ADD_EXPLICIT_CAST_MULTI = FixKind(
    'dart.fix.add.explicitCast.multi',
    DartFixKindPriority.inFile,
    'Add cast everywhere in file',
  );
  static const ADD_FIELD_FORMAL_PARAMETERS = FixKind(
    'dart.fix.add.fieldFormalParameters',
    70,
    'Add final field formal parameters',
  );
  static const ADD_KEY_TO_CONSTRUCTORS = FixKind(
    'dart.fix.add.keyToConstructors',
    DartFixKindPriority.standard,
    "Add 'key' to constructors",
  );
  static const ADD_KEY_TO_CONSTRUCTORS_MULTI = FixKind(
    'dart.fix.add.keyToConstructors.multi',
    DartFixKindPriority.standard,
    "Add 'key' to constructors everywhere in file",
  );
  static const ADD_LATE = FixKind(
    'dart.fix.add.late',
    DartFixKindPriority.standard,
    "Add 'late' modifier",
  );
  static const ADD_LEADING_NEWLINE_TO_STRING = FixKind(
    'dart.fix.add.leadingNewlineToString',
    DartFixKindPriority.standard,
    'Add leading new line',
  );
  static const ADD_LEADING_NEWLINE_TO_STRING_MULTI = FixKind(
    'dart.fix.add.leadingNewlineToString.multi',
    DartFixKindPriority.standard,
    'Add leading new line everywhere in file',
  );
  static const ADD_MISSING_ENUM_CASE_CLAUSES = FixKind(
    'dart.fix.add.missingEnumCaseClauses',
    DartFixKindPriority.standard,
    'Add missing case clauses',
  );
  static const ADD_MISSING_PARAMETER_NAMED = FixKind(
    'dart.fix.add.missingParameterNamed',
    70,
    "Add named parameter '{0}'",
  );
  static const ADD_MISSING_PARAMETER_POSITIONAL = FixKind(
    'dart.fix.add.missingParameterPositional',
    69,
    'Add optional positional parameter',
  );
  static const ADD_MISSING_PARAMETER_REQUIRED = FixKind(
    'dart.fix.add.missingParameterRequired',
    70,
    'Add required positional parameter',
  );
  static const ADD_MISSING_REQUIRED_ARGUMENT = FixKind(
    'dart.fix.add.missingRequiredArgument',
    70,
    "Add required argument '{0}'",
  );
  static const ADD_MISSING_SWITCH_CASES = FixKind(
    'dart.fix.add.missingSwitchCases',
    DartFixKindPriority.standard,
    'Add missing switch cases',
  );
  static const ADD_NE_NULL = FixKind(
    'dart.fix.add.neNull',
    DartFixKindPriority.standard,
    'Add != null',
  );
  static const ADD_NE_NULL_MULTI = FixKind(
    'dart.fix.add.neNull.multi',
    DartFixKindPriority.inFile,
    'Add != null everywhere in file',
  );
  static const ADD_NULL_CHECK = FixKind(
    'dart.fix.add.nullCheck',
    DartFixKindPriority.standard - 1,
    'Add a null check (!)',
  );
  static const ADD_OVERRIDE = FixKind(
    'dart.fix.add.override',
    DartFixKindPriority.standard,
    "Add '@override' annotation",
  );
  static const ADD_OVERRIDE_MULTI = FixKind(
    'dart.fix.add.override.multi',
    DartFixKindPriority.inFile,
    "Add '@override' annotations everywhere in file",
  );
  static const ADD_REDECLARE = FixKind(
    'dart.fix.add.redeclare',
    DartFixKindPriority.standard,
    "Add '@redeclare' annotation",
  );
  static const ADD_REDECLARE_MULTI = FixKind(
    'dart.fix.add.redeclare.multi',
    DartFixKindPriority.inFile,
    "Add '@redeclare' annotations everywhere in file",
  );
  static const ADD_REOPEN = FixKind(
    'dart.fix.add.reopen',
    DartFixKindPriority.standard,
    "Add '@reopen' annotation",
  );
  static const ADD_REOPEN_MULTI = FixKind(
    'dart.fix.add.reopen.multi',
    DartFixKindPriority.inFile,
    "Add '@reopen' annotations everywhere in file",
  );
  static const ADD_REQUIRED = FixKind(
    'dart.fix.add.required',
    DartFixKindPriority.standard,
    "Add 'required' keyword",
  );
  static const ADD_RETURN_NULL = FixKind(
    'dart.fix.add.returnNull',
    DartFixKindPriority.standard,
    "Add 'return null'",
  );
  static const ADD_RETURN_NULL_MULTI = FixKind(
    'dart.fix.add.returnNull.multi',
    DartFixKindPriority.inFile,
    "Add 'return null' everywhere in file",
  );
  static const ADD_RETURN_TYPE = FixKind(
    'dart.fix.add.returnType',
    DartFixKindPriority.standard,
    'Add return type',
  );
  static const ADD_RETURN_TYPE_MULTI = FixKind(
    'dart.fix.add.returnType.multi',
    DartFixKindPriority.inFile,
    'Add return types everywhere in file',
  );
  static const ADD_STATIC = FixKind(
    'dart.fix.add.static',
    DartFixKindPriority.standard,
    "Add 'static' modifier",
  );
  static const ADD_SUPER_CONSTRUCTOR_INVOCATION = FixKind(
    'dart.fix.add.superConstructorInvocation',
    DartFixKindPriority.standard,
    'Add super constructor {0} invocation',
  );
  static const ADD_SUPER_PARAMETER = FixKind(
    'dart.fix.add.superParameter',
    DartFixKindPriority.standard,
    'Add required parameter{0}',
  );
  static const ADD_SWITCH_CASE_BREAK = FixKind(
    'dart.fix.add.switchCaseReturn',
    DartFixKindPriority.standard,
    "Add 'break'",
  );
  static const ADD_SWITCH_CASE_BREAK_MULTI = FixKind(
    'dart.fix.add.switchCaseReturn.multi',
    DartFixKindPriority.inFile,
    "Add 'break' everywhere in file",
  );
  static const ADD_TRAILING_COMMA = FixKind(
    'dart.fix.add.trailingComma',
    DartFixKindPriority.standard,
    'Add trailing comma',
  );
  static const ADD_TRAILING_COMMA_MULTI = FixKind(
    'dart.fix.add.trailingComma.multi',
    DartFixKindPriority.inFile,
    'Add trailing commas everywhere in file',
  );
  static const ADD_TYPE_ANNOTATION = FixKind(
    'dart.fix.add.typeAnnotation',
    DartFixKindPriority.standard,
    'Add type annotation',
  );
  static const ADD_TYPE_ANNOTATION_MULTI = FixKind(
    'dart.fix.add.typeAnnotation.multi',
    DartFixKindPriority.inFile,
    'Add type annotations everywhere in file',
  );
  static const CHANGE_ARGUMENT_NAME = FixKind(
    'dart.fix.change.argumentName',
    60,
    "Change to '{0}'",
  );
  static const CHANGE_TO = FixKind(
    'dart.fix.change.to',
    DartFixKindPriority.standard + 1,
    "Change to '{0}'",
  );
  static const CHANGE_TO_NEAREST_PRECISE_VALUE = FixKind(
    'dart.fix.change.toNearestPreciseValue',
    DartFixKindPriority.standard,
    'Change to nearest precise int-as-double value: {0}',
  );
  static const CHANGE_TO_STATIC_ACCESS = FixKind(
    'dart.fix.change.toStaticAccess',
    DartFixKindPriority.standard,
    "Change access to static using '{0}'",
  );
  static const CHANGE_TYPE_ANNOTATION = FixKind(
    'dart.fix.change.typeAnnotation',
    DartFixKindPriority.standard,
    "Change '{0}' to '{1}' type annotation",
  );
  static const CONVERT_CLASS_TO_ENUM = FixKind(
    'dart.fix.convert.classToEnum',
    DartFixKindPriority.standard,
    'Convert class to an enum',
  );
  static const CONVERT_CLASS_TO_ENUM_MULTI = FixKind(
    'dart.fix.convert.classToEnum.multi',
    DartFixKindPriority.standard,
    'Convert classes to enums in file',
  );
  static const CONVERT_FLUTTER_CHILD = FixKind(
    'dart.fix.flutter.convert.childToChildren',
    DartFixKindPriority.standard,
    'Convert to children:',
  );
  static const CONVERT_FLUTTER_CHILDREN = FixKind(
    'dart.fix.flutter.convert.childrenToChild',
    DartFixKindPriority.standard,
    'Convert to child:',
  );
  static const CONVERT_INTO_BLOCK_BODY = FixKind(
    'dart.fix.convert.bodyToBlock',
    DartFixKindPriority.standard,
    'Convert to block body',
  );
  static const CONVERT_INTO_BLOCK_BODY_MULTI = FixKind(
    'dart.fix.convert.bodyToBlock.multi',
    DartFixKindPriority.inFile,
    'Convert to block body everywhere in file',
  );
  static const CONVERT_FOR_EACH_TO_FOR_LOOP = FixKind(
    'dart.fix.convert.toForLoop',
    DartFixKindPriority.standard,
    "Convert 'forEach' to a 'for' loop",
  );
  static const CONVERT_FOR_EACH_TO_FOR_LOOP_MULTI = FixKind(
    'dart.fix.convert.toForLoop.multi',
    DartFixKindPriority.inFile,
    "Convert 'forEach' to a 'for' loop everywhere in file",
  );
  static const CONVERT_INTO_EXPRESSION_BODY = FixKind(
    'dart.fix.convert.toExpressionBody',
    DartFixKindPriority.standard,
    'Convert to expression body',
  );
  static const CONVERT_INTO_EXPRESSION_BODY_MULTI = FixKind(
    'dart.fix.convert.toExpressionBody.multi',
    DartFixKindPriority.inFile,
    'Convert to expression bodies everywhere in file',
  );
  static const CONVERT_QUOTES = FixKind(
    'dart.fix.convert.quotes',
    DartFixKindPriority.standard,
    'Convert the quotes and remove escapes',
  );
  static const CONVERT_QUOTES_MULTI = FixKind(
    'dart.fix.convert.quotes.multi',
    DartFixKindPriority.inFile,
    'Convert the quotes and remove escapes everywhere in file',
  );
  static const CONVERT_RELATED_TO_CASCADE = FixKind(
    'dart.fix.convert.relatedToCascade',
    DartFixKindPriority.standard + 1,
    'Convert this and related to cascade notation',
  );
  static const CONVERT_TO_BOOL_EXPRESSION = FixKind(
    'dart.fix.convert.toBoolExpression',
    DartFixKindPriority.standard,
    'Convert to boolean expression',
  );
  static const CONVERT_TO_BOOL_EXPRESSION_MULTI = FixKind(
    'dart.fix.convert.toBoolExpression.multi',
    DartFixKindPriority.standard,
    'Convert to boolean expressions everywhere in file',
  );
  static const CONVERT_TO_CASCADE = FixKind(
    'dart.fix.convert.toCascade',
    DartFixKindPriority.standard,
    'Convert to cascade notation',
  );
  static const CONVERT_TO_CONSTANT_PATTERN = FixKind(
    'dart.fix.convert.toConstantPattern',
    49,
    'Convert to constant pattern',
  );
  static const CONVERT_TO_CONTAINS = FixKind(
    'dart.fix.convert.toContains',
    DartFixKindPriority.standard,
    "Convert to using 'contains'",
  );
  static const CONVERT_TO_CONTAINS_MULTI = FixKind(
    'dart.fix.convert.toContains.multi',
    DartFixKindPriority.inFile,
    "Convert to using 'contains' everywhere in file",
  );
  static const CONVERT_TO_DOUBLE_QUOTED_STRING = FixKind(
    'dart.fix.convert.toDoubleQuotedString',
    DartFixKindPriority.standard,
    'Convert to double quoted string',
  );
  static const CONVERT_TO_DOUBLE_QUOTED_STRING_MULTI = FixKind(
    'dart.fix.convert.toDoubleQuotedString.multi',
    DartFixKindPriority.inFile,
    'Convert to double quoted strings everywhere in file',
  );
  static const CONVERT_TO_FLUTTER_STYLE_TODO = FixKind(
    'dart.fix.convert.toFlutterStyleTodo',
    DartFixKindPriority.standard,
    'Convert to flutter style todo',
  );
  static const CONVERT_TO_FLUTTER_STYLE_TODO_MULTI = FixKind(
    'dart.fix.convert.toFlutterStyleTodo.multi',
    DartFixKindPriority.inFile,
    'Convert to flutter style todos everywhere in file',
  );
  static const CONVERT_TO_FOR_ELEMENT = FixKind(
    'dart.fix.convert.toForElement',
    DartFixKindPriority.standard,
    "Convert to a 'for' element",
  );
  static const CONVERT_TO_FOR_ELEMENT_MULTI = FixKind(
    'dart.fix.convert.toForElement.multi',
    DartFixKindPriority.inFile,
    "Convert to 'for' elements everywhere in file",
  );
  static const CONVERT_TO_GENERIC_FUNCTION_SYNTAX = FixKind(
    'dart.fix.convert.toGenericFunctionSyntax',
    DartFixKindPriority.standard,
    "Convert into 'Function' syntax",
  );
  static const CONVERT_TO_GENERIC_FUNCTION_SYNTAX_MULTI = FixKind(
    'dart.fix.convert.toGenericFunctionSyntax.multi',
    DartFixKindPriority.inFile,
    "Convert to 'Function' syntax everywhere in file",
  );
  static const CONVERT_TO_FUNCTION_DECLARATION = FixKind(
    'dart.fix.convert.toFunctionDeclaration',
    DartFixKindPriority.standard,
    'Convert to function declaration',
  );
  static const CONVERT_TO_FUNCTION_DECLARATION_MULTI = FixKind(
    'dart.fix.convert.toFunctionDeclaration.multi',
    DartFixKindPriority.inFile,
    'Convert to function declaration everywhere in file',
  );
  static const CONVERT_TO_IF_ELEMENT = FixKind(
    'dart.fix.convert.toIfElement',
    DartFixKindPriority.standard,
    "Convert to an 'if' element",
  );
  static const CONVERT_TO_IF_ELEMENT_MULTI = FixKind(
    'dart.fix.convert.toIfElement.multi',
    DartFixKindPriority.inFile,
    "Convert to 'if' elements everywhere in file",
  );
  static const CONVERT_TO_IF_NULL = FixKind(
    'dart.fix.convert.toIfNull',
    DartFixKindPriority.standard,
    "Convert to use '??'",
  );
  static const CONVERT_TO_IF_NULL_MULTI = FixKind(
    'dart.fix.convert.toIfNull.multi',
    DartFixKindPriority.inFile,
    "Convert to '??'s everywhere in file",
  );
  static const CONVERT_TO_INITIALIZING_FORMAL = FixKind(
    'dart.fix.convert.toInitializingFormal',
    DartFixKindPriority.standard,
    'Convert to an initializing formal parameter',
  );
  static const CONVERT_TO_INT_LITERAL = FixKind(
    'dart.fix.convert.toIntLiteral',
    DartFixKindPriority.standard,
    'Convert to an int literal',
  );
  static const CONVERT_TO_INT_LITERAL_MULTI = FixKind(
    'dart.fix.convert.toIntLiteral.multi',
    DartFixKindPriority.inFile,
    'Convert to int literals everywhere in file',
  );
  static const CONVERT_TO_IS_NOT = FixKind(
    'dart.fix.convert.isNot',
    DartFixKindPriority.standard,
    'Convert to is!',
  );
  static const CONVERT_TO_IS_NOT_MULTI = FixKind(
    'dart.fix.convert.isNot.multi',
    DartFixKindPriority.inFile,
    'Convert to is! everywhere in file',
  );
  static const CONVERT_TO_LINE_COMMENT = FixKind(
    'dart.fix.convert.toLineComment',
    DartFixKindPriority.standard,
    'Convert to line documentation comment',
  );
  static const CONVERT_TO_LINE_COMMENT_MULTI = FixKind(
    'dart.fix.convert.toLineComment.multi',
    DartFixKindPriority.inFile,
    'Convert to line documentation comments everywhere in file',
  );
  static const CONVERT_TO_MAP_LITERAL = FixKind(
    'dart.fix.convert.toMapLiteral',
    DartFixKindPriority.standard,
    'Convert to map literal',
  );
  static const CONVERT_TO_MAP_LITERAL_MULTI = FixKind(
    'dart.fix.convert.toMapLiteral.multi',
    DartFixKindPriority.inFile,
    'Convert to map literals everywhere in file',
  );
  static const CONVERT_TO_NAMED_ARGUMENTS = FixKind(
    'dart.fix.convert.toNamedArguments',
    DartFixKindPriority.standard,
    'Convert to named arguments',
  );
  static const CONVERT_TO_NULL_AWARE = FixKind(
    'dart.fix.convert.toNullAware',
    DartFixKindPriority.standard,
    "Convert to use '?.'",
  );
  static const CONVERT_TO_NULL_AWARE_MULTI = FixKind(
    'dart.fix.convert.toNullAware.multi',
    DartFixKindPriority.inFile,
    "Convert to use '?.' everywhere in file",
  );
  static const CONVERT_TO_NULL_AWARE_SPREAD = FixKind(
    'dart.fix.convert.toNullAwareSpread',
    DartFixKindPriority.standard,
    "Convert to use '...?'",
  );
  static const CONVERT_TO_NULL_AWARE_SPREAD_MULTI = FixKind(
    'dart.fix.convert.toNullAwareSpread.multi',
    DartFixKindPriority.inFile,
    "Convert to use '...?' everywhere in file",
  );
  static const CONVERT_TO_ON_TYPE = FixKind(
    'dart.fix.convert.toOnType',
    DartFixKindPriority.standard,
    "Convert to 'on {0}'",
  );
  static const CONVERT_TO_PACKAGE_IMPORT = FixKind(
    'dart.fix.convert.toPackageImport',
    DartFixKindPriority.standard,
    "Convert to 'package:' import",
  );
  static const CONVERT_TO_PACKAGE_IMPORT_MULTI = FixKind(
    'dart.fix.convert.toPackageImport.multi',
    DartFixKindPriority.inFile,
    "Convert to 'package:' imports everywhere in file",
  );
  static const CONVERT_TO_RAW_STRING = FixKind(
    'dart.fix.convert.toRawString',
    DartFixKindPriority.standard,
    'Convert to raw string',
  );
  static const CONVERT_TO_RAW_STRING_MULTI = FixKind(
    'dart.fix.convert.toRawString.multi',
    DartFixKindPriority.inFile,
    'Convert to raw strings everywhere in file',
  );
  static const CONVERT_TO_RELATIVE_IMPORT = FixKind(
    'dart.fix.convert.toRelativeImport',
    DartFixKindPriority.standard,
    'Convert to relative import',
  );
  static const CONVERT_TO_RELATIVE_IMPORT_MULTI = FixKind(
    'dart.fix.convert.toRelativeImport.multi',
    DartFixKindPriority.inFile,
    'Convert to relative imports everywhere in file',
  );
  static const CONVERT_TO_SET_LITERAL = FixKind(
    'dart.fix.convert.toSetLiteral',
    DartFixKindPriority.standard,
    'Convert to set literal',
  );
  static const CONVERT_TO_SET_LITERAL_MULTI = FixKind(
    'dart.fix.convert.toSetLiteral.multi',
    DartFixKindPriority.inFile,
    'Convert to set literals everywhere in file',
  );
  static const CONVERT_TO_SINGLE_QUOTED_STRING = FixKind(
    'dart.fix.convert.toSingleQuotedString',
    DartFixKindPriority.standard,
    'Convert to single quoted string',
  );
  static const CONVERT_TO_SINGLE_QUOTED_STRING_MULTI = FixKind(
    'dart.fix.convert.toSingleQuotedString.multi',
    DartFixKindPriority.inFile,
    'Convert to single quoted strings everywhere in file',
  );
  static const CONVERT_TO_SPREAD = FixKind(
    'dart.fix.convert.toSpread',
    DartFixKindPriority.standard,
    'Convert to a spread',
  );
  static const CONVERT_TO_SPREAD_MULTI = FixKind(
    'dart.fix.convert.toSpread.multi',
    DartFixKindPriority.inFile,
    'Convert to spreads everywhere in file',
  );
  static const CONVERT_TO_SUPER_PARAMETERS = FixKind(
    'dart.fix.convert.toSuperParameters',
    30,
    'Convert to using super parameters',
  );
  static const CONVERT_TO_SUPER_PARAMETERS_MULTI = FixKind(
    'dart.fix.convert.toSuperParameters.multi',
    30,
    'Convert to using super parameters everywhere in file',
  );
  static const CONVERT_TO_WHERE_TYPE = FixKind(
    'dart.fix.convert.toWhereType',
    DartFixKindPriority.standard,
    "Convert to use 'whereType'",
  );
  static const CONVERT_TO_WHERE_TYPE_MULTI = FixKind(
    'dart.fix.convert.toWhereType.multi',
    DartFixKindPriority.inFile,
    "Convert to using 'whereType' everywhere in file",
  );
  static const CONVERT_TO_WILDCARD_PATTERN = FixKind(
    'dart.fix.convert.toWildcardPattern',
    DartFixKindPriority.standard,
    'Convert to wildcard pattern',
  );
  static const CONVERT_TO_WILDCARD_VARIABLE = FixKind(
    'dart.fix.convert.toWildcardVariable',
    DartFixKindPriority.standard,
    'Convert to wildcard variable',
  );
  static const CREATE_CLASS = FixKind(
    'dart.fix.create.class',
    DartFixKindPriority.standard,
    "Create class '{0}'",
  );
  static const CREATE_CONSTRUCTOR = FixKind(
    'dart.fix.create.constructor',
    DartFixKindPriority.standard,
    "Create constructor '{0}'",
  );
  static const CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS = FixKind(
    'dart.fix.create.constructorForFinalFields',
    DartFixKindPriority.standard,
    'Create constructor for final fields',
  );
  static const CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS_REQUIRED_NAMED = FixKind(
    'dart.fix.create.constructorForFinalFields.requiredNamed',
    DartFixKindPriority.standard,
    'Create constructor for final fields, required named',
  );
  static const CREATE_CONSTRUCTOR_SUPER = FixKind(
    'dart.fix.create.constructorSuper',
    DartFixKindPriority.standard,
    'Create constructor to call {0}',
  );
  static const CREATE_EXTENSION_GETTER = FixKind(
    'dart.fix.create.extension.getter',
    DartFixKindPriority.standard - 20,
    "Create extension getter '{0}'",
  );
  static const CREATE_EXTENSION_METHOD = FixKind(
    'dart.fix.create.extension.method',
    DartFixKindPriority.standard - 20,
    "Create extension method '{0}'",
  );
  static const CREATE_EXTENSION_SETTER = FixKind(
    'dart.fix.create.extension.setter',
    DartFixKindPriority.standard - 20,
    "Create extension setter '{0}'",
  );
  static const CREATE_FIELD = FixKind(
    'dart.fix.create.field',
    49,
    "Create field '{0}'",
  );
  static const CREATE_FILE = FixKind(
    'dart.fix.create.file',
    DartFixKindPriority.standard,
    "Create file '{0}'",
  );
  static const CREATE_FUNCTION = FixKind(
    'dart.fix.create.function',
    49,
    "Create function '{0}'",
  );
  static const CREATE_GETTER = FixKind(
    'dart.fix.create.getter',
    DartFixKindPriority.standard,
    "Create getter '{0}'",
  );
  static const CREATE_LOCAL_VARIABLE = FixKind(
    'dart.fix.create.localVariable',
    DartFixKindPriority.standard,
    "Create local variable '{0}'",
  );
  static const CREATE_METHOD = FixKind(
    'dart.fix.create.method',
    DartFixKindPriority.standard,
    "Create method '{0}'",
  );

  // TODO(pq): used by LintNames.hash_and_equals; consider removing.
  static const CREATE_METHOD_MULTI = FixKind(
    'dart.fix.create.method.multi',
    DartFixKindPriority.inFile,
    'Create methods in file',
  );
  static const CREATE_MISSING_OVERRIDES = FixKind(
    'dart.fix.create.missingOverrides',
    DartFixKindPriority.standard + 1,
    'Create {0} missing override{1}',
  );
  static const CREATE_MIXIN = FixKind(
    'dart.fix.create.mixin',
    DartFixKindPriority.standard,
    "Create mixin '{0}'",
  );
  static const CREATE_NO_SUCH_METHOD = FixKind(
    'dart.fix.create.noSuchMethod',
    49,
    "Create 'noSuchMethod' method",
  );
  static const CREATE_PARAMETER = FixKind(
    'dart.fix.create.parameter',
    DartFixKindPriority.standard,
    "Create required positional parameter '{0}'",
  );
  static const CREATE_SETTER = FixKind(
    'dart.fix.create.setter',
    DartFixKindPriority.standard,
    "Create setter '{0}'",
  );
  static const DATA_DRIVEN = FixKind(
    'dart.fix.dataDriven',
    DartFixKindPriority.standard,
    '{0}',
  );
  static const EXTEND_CLASS_FOR_MIXIN = FixKind(
    'dart.fix.extendClassForMixin',
    DartFixKindPriority.standard,
    "Extend the class '{0}'",
  );
  static const EXTRACT_LOCAL_VARIABLE = FixKind(
    'dart.fix.extractLocalVariable',
    DartFixKindPriority.standard,
    'Extract local variable',
  );
  static const IGNORE_ERROR_LINE = FixKind(
    'dart.fix.ignore.line',
    DartFixKindPriority.ignore,
    "Ignore '{0}' for this line",
  );
  static const IGNORE_ERROR_FILE = FixKind(
    'dart.fix.ignore.file',
    DartFixKindPriority.ignore - 1,
    "Ignore '{0}' for the whole file",
  );
  static const IGNORE_ERROR_ANALYSIS_FILE = FixKind(
    'dart.fix.ignore.analysis',
    DartFixKindPriority.ignore - 2,
    "Ignore '{0}' in `analysis_options.yaml`",
  );
  static const IMPORT_ASYNC = FixKind(
    'dart.fix.import.async',
    49,
    "Import 'dart:async'",
  );
  static const IMPORT_LIBRARY_COMBINATOR = FixKind(
    'dart.fix.import.libraryCombinator',
    DartFixKindPriority.standard + 5,
    "Update library '{0}' import",
  );
  static const IMPORT_LIBRARY_PREFIX = FixKind(
    'dart.fix.import.libraryPrefix',
    DartFixKindPriority.standard + 5,
    "Use imported library '{0}' with prefix '{1}'",
  );
  static const IMPORT_LIBRARY_PROJECT1 = FixKind(
    'dart.fix.import.libraryProject1',
    DartFixKindPriority.standard + 3,
    "Import library '{0}'",
  );
  static const IMPORT_LIBRARY_PROJECT1_PREFIXED = FixKind(
    'dart.fix.import.libraryProject1Prefixed',
    DartFixKindPriority.standard + 3,
    "Import library '{0}' with prefix '{1}'",
  );
  static const IMPORT_LIBRARY_PROJECT2 = FixKind(
    'dart.fix.import.libraryProject2',
    DartFixKindPriority.standard + 2,
    "Import library '{0}'",
  );
  static const IMPORT_LIBRARY_PROJECT2_PREFIXED = FixKind(
    'dart.fix.import.libraryProject2Prefixed',
    DartFixKindPriority.standard + 2,
    "Import library '{0}' with prefix '{1}'",
  );
  static const IMPORT_LIBRARY_PROJECT3 = FixKind(
    'dart.fix.import.libraryProject3',
    DartFixKindPriority.standard + 1,
    "Import library '{0}'",
  );
  static const IMPORT_LIBRARY_PROJECT3_PREFIXED = FixKind(
    'dart.fix.import.libraryProject3Prefixed',
    DartFixKindPriority.standard + 1,
    "Import library '{0}' with prefix '{1}'",
  );
  static const IMPORT_LIBRARY_SDK = FixKind(
    'dart.fix.import.librarySdk',
    DartFixKindPriority.standard + 4,
    "Import library '{0}'",
  );
  static const IMPORT_LIBRARY_SDK_PREFIXED = FixKind(
    'dart.fix.import.librarySdk',
    DartFixKindPriority.standard + 4,
    "Import library '{0}' with prefix '{1}'",
  );
  static const INLINE_INVOCATION = FixKind(
    'dart.fix.inlineInvocation',
    DartFixKindPriority.standard - 20,
    "Inline invocation of '{0}'",
  );
  static const INLINE_INVOCATION_MULTI = FixKind(
    'dart.fix.inlineInvocation.multi',
    DartFixKindPriority.inFile - 20,
    'Inline invocations everywhere in file',
  );
  static const INLINE_TYPEDEF = FixKind(
    'dart.fix.inlineTypedef',
    DartFixKindPriority.standard - 20,
    "Inline the definition of '{0}'",
  );
  static const INLINE_TYPEDEF_MULTI = FixKind(
    'dart.fix.inlineTypedef.multi',
    DartFixKindPriority.inFile - 20,
    'Inline type definitions everywhere in file',
  );
  static const INSERT_BODY = FixKind(
    'dart.fix.insertBody',
    DartFixKindPriority.standard,
    'Insert body',
  );
  static const INSERT_ON_KEYWORD = FixKind(
    'dart.fix.insertOnKeyword',
    DartFixKindPriority.standard,
    "Insert 'on' keyword",
  );
  static const INSERT_ON_KEYWORD_MULTI = FixKind(
    'dart.fix.insertOnKeyword.multi',
    DartFixKindPriority.inFile,
    "Insert 'on' keyword in file",
  );
  static const INSERT_SEMICOLON = FixKind(
    'dart.fix.insertSemicolon',
    DartFixKindPriority.standard,
    "Insert ';'",
  );
  static const INSERT_SEMICOLON_MULTI = FixKind(
    'dart.fix.insertSemicolon.multi',
    DartFixKindPriority.inFile,
    "Insert ';' everywhere in file",
  );
  static const MAKE_CLASS_ABSTRACT = FixKind(
    'dart.fix.makeClassAbstract',
    DartFixKindPriority.standard,
    "Make class '{0}' abstract",
  );
  static const MAKE_FIELD_NOT_FINAL = FixKind(
    'dart.fix.makeFieldNotFinal',
    DartFixKindPriority.standard,
    "Make field '{0}' not final",
  );
  static const MAKE_FIELD_PUBLIC = FixKind(
    'dart.fix.makeFieldPublic',
    DartFixKindPriority.standard,
    "Make field '{0}' public",
  );
  static const MAKE_FINAL = FixKind(
    'dart.fix.makeFinal',
    DartFixKindPriority.standard,
    'Make final',
  );

  // TODO(pq): consider parameterizing: 'Make {fields} final...'
  static const MAKE_FINAL_MULTI = FixKind(
    'dart.fix.makeFinal.multi',
    DartFixKindPriority.inFile,
    'Make final where possible in file',
  );
  static const MAKE_RETURN_TYPE_NULLABLE = FixKind(
    'dart.fix.makeReturnTypeNullable',
    DartFixKindPriority.standard,
    'Make the return type nullable',
  );
  static const MAKE_CONDITIONAL_ON_DEBUG_MODE = FixKind(
    'dart.fix.flutter.makeConditionalOnDebugMode',
    DartFixKindPriority.standard,
    "Make conditional on 'kDebugMode'",
  );
  static const MAKE_REQUIRED_NAMED_PARAMETERS_FIRST = FixKind(
    'dart.fix.makeRequiredNamedParametersFirst',
    DartFixKindPriority.standard,
    'Put required named parameter first',
  );
  static const MAKE_REQUIRED_NAMED_PARAMETERS_FIRST_MULTI = FixKind(
    'dart.fix.makeRequiredNamedParametersFirst.multi',
    DartFixKindPriority.inFile,
    'Put required named parameters first everywhere in file',
  );
  static const MAKE_SUPER_INVOCATION_LAST = FixKind(
    'dart.fix.makeSuperInvocationLast',
    DartFixKindPriority.standard,
    'Move the invocation to the end of the initializer list',
  );
  static const MAKE_VARIABLE_NOT_FINAL = FixKind(
    'dart.fix.makeVariableNotFinal',
    DartFixKindPriority.standard,
    "Make variable '{0}' not final",
  );
  static const MAKE_VARIABLE_NULLABLE = FixKind(
    'dart.fix.makeVariableNullable',
    DartFixKindPriority.standard,
    "Make '{0}' nullable",
  );
  static const MATCH_ANY_MAP = FixKind(
    'dart.fix.matchAnyMap',
    DartFixKindPriority.standard,
    'Match any map',
  );
  static const MATCH_EMPTY_MAP = FixKind(
    'dart.fix.matchEmptyMap',
    DartFixKindPriority.standard,
    'Match an empty map',
  );
  static const MOVE_ANNOTATION_TO_LIBRARY_DIRECTIVE = FixKind(
    'dart.fix.moveAnnotationToLibraryDirective',
    DartFixKindPriority.standard,
    'Move this annotation to a library directive',
  );
  static const MOVE_DOC_COMMENT_TO_LIBRARY_DIRECTIVE = FixKind(
    'dart.fix.moveDocCommentToLibraryDirective',
    DartFixKindPriority.standard,
    'Move this doc comment to a library directive',
  );
  static const MOVE_TYPE_ARGUMENTS_TO_CLASS = FixKind(
    'dart.fix.moveTypeArgumentsToClass',
    DartFixKindPriority.standard,
    'Move type arguments to after class name',
  );
  static const ORGANIZE_IMPORTS = FixKind(
    'dart.fix.organize.imports',
    DartFixKindPriority.standard,
    'Organize Imports',
  );
  static const QUALIFY_REFERENCE = FixKind(
    'dart.fix.qualifyReference',
    DartFixKindPriority.standard,
    "Use '{0}'",
  );
  static const REMOVE_ABSTRACT = FixKind(
    'dart.fix.remove.abstract',
    DartFixKindPriority.standard,
    "Remove the 'abstract' keyword",
  );
  static const REMOVE_ABSTRACT_MULTI = FixKind(
    'dart.fix.remove.abstract.multi',
    DartFixKindPriority.inFile,
    "Remove the 'abstract' keyword everywhere in file",
  );
  static const REMOVE_ANNOTATION = FixKind(
    'dart.fix.remove.annotation',
    DartFixKindPriority.standard,
    "Remove the '{0}' annotation",
  );
  static const REMOVE_ARGUMENT = FixKind(
    'dart.fix.remove.argument',
    DartFixKindPriority.standard,
    'Remove argument',
  );

  // TODO(pq): used by LintNames.avoid_redundant_argument_values;
  //  consider a parameterized message
  static const REMOVE_ARGUMENT_MULTI = FixKind(
    'dart.fix.remove.argument.multi',
    DartFixKindPriority.inFile,
    'Remove arguments in file',
  );
  static const REMOVE_ASSERTION = FixKind(
    'dart.fix.remove.assertion',
    DartFixKindPriority.standard,
    'Remove the assertion',
  );
  static const REMOVE_ASSIGNMENT = FixKind(
    'dart.fix.remove.assignment',
    DartFixKindPriority.standard,
    'Remove assignment',
  );
  static const REMOVE_ASSIGNMENT_MULTI = FixKind(
    'dart.fix.remove.assignment.multi',
    DartFixKindPriority.inFile,
    'Remove unnecessary assignments everywhere in file',
  );
  static const REMOVE_AWAIT = FixKind(
    'dart.fix.remove.await',
    DartFixKindPriority.standard,
    'Remove await',
  );
  static const REMOVE_AWAIT_MULTI = FixKind(
    'dart.fix.remove.await.multi',
    DartFixKindPriority.inFile,
    'Remove awaits in file',
  );
  static const REMOVE_BREAK = FixKind(
    'dart.fix.remove.break',
    DartFixKindPriority.standard,
    'Remove break',
  );
  static const REMOVE_BREAK_MULTI = FixKind(
    'dart.fix.remove.break.multi',
    DartFixKindPriority.inFile,
    'Remove unnecessary breaks in file',
  );
  static const REMOVE_CHARACTER = FixKind(
    'dart.fix.remove.character',
    DartFixKindPriority.standard,
    "Remove the 'U+{0}' code point",
  );
  static const REMOVE_COMMA = FixKind(
    'dart.fix.remove.comma',
    DartFixKindPriority.standard,
    'Remove the comma',
  );
  static const REMOVE_COMMA_MULTI = FixKind(
    'dart.fix.remove.comma.multi',
    DartFixKindPriority.inFile,
    'Remove {0}commas from {1} everywhere in file',
  );
  static const REMOVE_COMPARISON = FixKind(
    'dart.fix.remove.comparison',
    DartFixKindPriority.standard,
    'Remove comparison',
  );
  static const REMOVE_COMPARISON_MULTI = FixKind(
    'dart.fix.remove.comparison.multi',
    DartFixKindPriority.inFile,
    'Remove comparisons in file',
  );
  static const REMOVE_CONST = FixKind(
    'dart.fix.remove.const',
    DartFixKindPriority.standard,
    'Remove const',
  );
  static const REMOVE_CONSTRUCTOR = FixKind(
    'dart.fix.remove.constructor',
    DartFixKindPriority.standard,
    'Remove the constructor',
  );
  static const REMOVE_CONSTRUCTOR_NAME = FixKind(
    'dart.fix.remove.constructorName',
    DartFixKindPriority.standard,
    "Remove 'new'",
  );
  static const REMOVE_CONSTRUCTOR_NAME_MULTI = FixKind(
    'dart.fix.remove.constructorName.multi',
    DartFixKindPriority.inFile,
    'Remove constructor names in file',
  );
  static const REMOVE_DEAD_CODE = FixKind(
    'dart.fix.remove.deadCode',
    DartFixKindPriority.standard,
    'Remove dead code',
  );
  static const REMOVE_DEFAULT_VALUE = FixKind(
    'dart.fix.remove.defaultValue',
    DartFixKindPriority.standard,
    'Remove the default value',
  );
  static const REMOVE_DEPRECATED_NEW_IN_COMMENT_REFERENCE = FixKind(
    'dart.fix.remove.deprecatedNewInCommentReference',
    DartFixKindPriority.standard,
    'Remove deprecated new keyword',
  );
  static const REMOVE_DEPRECATED_NEW_IN_COMMENT_REFERENCE_MULTI = FixKind(
    'dart.fix.remove.deprecatedNewInCommentReference.multi',
    DartFixKindPriority.inFile,
    'Remove deprecated new keyword in file',
  );
  static const REMOVE_DUPLICATE_CASE = FixKind(
    'dart.fix.remove.duplicateCase',
    DartFixKindPriority.standard,
    'Remove duplicate case statement',
  );

  // TODO(pq): is this dangerous to bulk apply?  Consider removing.
  static const REMOVE_DUPLICATE_CASE_MULTI = FixKind(
    'dart.fix.remove.duplicateCase.multi',
    DartFixKindPriority.inFile,
    'Remove duplicate case statement',
  );
  static const REMOVE_EMPTY_CATCH = FixKind(
    'dart.fix.remove.emptyCatch',
    DartFixKindPriority.standard,
    'Remove empty catch clause',
  );
  static const REMOVE_EMPTY_CATCH_MULTI = FixKind(
    'dart.fix.remove.emptyCatch.multi',
    DartFixKindPriority.inFile,
    'Remove empty catch clauses everywhere in file',
  );
  static const REMOVE_EMPTY_CONSTRUCTOR_BODY = FixKind(
    'dart.fix.remove.emptyConstructorBody',
    DartFixKindPriority.standard,
    'Remove empty constructor body',
  );
  static const REMOVE_EMPTY_CONSTRUCTOR_BODY_MULTI = FixKind(
    'dart.fix.remove.emptyConstructorBody.multi',
    DartFixKindPriority.inFile,
    'Remove empty constructor bodies in file',
  );
  static const REMOVE_EMPTY_ELSE = FixKind(
    'dart.fix.remove.emptyElse',
    DartFixKindPriority.standard,
    'Remove empty else clause',
  );
  static const REMOVE_EMPTY_ELSE_MULTI = FixKind(
    'dart.fix.remove.emptyElse.multi',
    DartFixKindPriority.inFile,
    'Remove empty else clauses everywhere in file',
  );
  static const REMOVE_EMPTY_STATEMENT = FixKind(
    'dart.fix.remove.emptyStatement',
    DartFixKindPriority.standard,
    'Remove empty statement',
  );
  static const REMOVE_EMPTY_STATEMENT_MULTI = FixKind(
    'dart.fix.remove.emptyStatement.multi',
    DartFixKindPriority.inFile,
    'Remove empty statements everywhere in file',
  );
  static const REMOVE_EXTENDS_CLAUSE = FixKind(
    'dart.fix.remove.extends.clause',
    DartFixKindPriority.standard,
    "Remove the invalid 'extends' clause",
  );
  static const REMOVE_EXTENDS_CLAUSE_MULTI = FixKind(
    'dart.fix.remove.extends.clause.multi',
    DartFixKindPriority.inFile,
    "Remove invalid 'extends' clauses everywhere in file",
  );
  static const REMOVE_LEXEME = FixKind(
    'dart.fix.remove.lexeme',
    DartFixKindPriority.standard,
    'Remove the {0} {1}',
  );
  static const REMOVE_LEXEME_MULTI = FixKind(
    'dart.fix.remove.lexeme.multi',
    DartFixKindPriority.inFile,
    'Remove {0}s everywhere in file',
  );
  static const REMOVE_IF_NULL_OPERATOR = FixKind(
    'dart.fix.remove.ifNullOperator',
    DartFixKindPriority.standard,
    "Remove the '??' operator",
  );
  static const REMOVE_IF_NULL_OPERATOR_MULTI = FixKind(
    'dart.fix.remove.ifNullOperator.multi',
    DartFixKindPriority.inFile,
    "Remove unnecessary '??' operators everywhere in file",
  );
  static const REMOVE_INVOCATION = FixKind(
    'dart.fix.remove.invocation',
    DartFixKindPriority.standard,
    'Remove unnecessary invocation of {0}',
  );
  static const REMOVE_INVOCATION_MULTI = FixKind(
    'dart.fix.remove.invocation.multi',
    DartFixKindPriority.inFile,
    'Remove unnecessary invocations of {0} in file',
  );
  static const REMOVE_INITIALIZER = FixKind(
    'dart.fix.remove.initializer',
    DartFixKindPriority.standard,
    'Remove initializer',
  );
  static const REMOVE_INITIALIZER_MULTI = FixKind(
    'dart.fix.remove.initializer.multi',
    DartFixKindPriority.inFile,
    'Remove unnecessary initializers everywhere in file',
  );
  static const REMOVE_INTERPOLATION_BRACES = FixKind(
    'dart.fix.remove.interpolationBraces',
    DartFixKindPriority.standard,
    'Remove unnecessary interpolation braces',
  );
  static const REMOVE_INTERPOLATION_BRACES_MULTI = FixKind(
    'dart.fix.remove.interpolationBraces.multi',
    DartFixKindPriority.inFile,
    'Remove unnecessary interpolation braces everywhere in file',
  );
  static const REMOVE_LATE = FixKind(
    'dart.fix.remove.late',
    DartFixKindPriority.standard,
    "Remove the 'late' keyword",
  );
  static const REMOVE_LATE_MULTI = FixKind(
    'dart.fix.remove.late.multi',
    DartFixKindPriority.standard,
    "Remove the 'late' keyword everywhere in file",
  );
  static const REMOVE_LEADING_UNDERSCORE = FixKind(
    'dart.fix.remove.leadingUnderscore',
    DartFixKindPriority.standard,
    'Remove leading underscore',
  );
  static const REMOVE_LEADING_UNDERSCORE_MULTI = FixKind(
    'dart.fix.remove.leadingUnderscore.multi',
    DartFixKindPriority.inFile,
    'Remove leading underscores in file',
  );
  static const REMOVE_LIBRARY_NAME = FixKind(
    'dart.fix.remove.library.name',
    DartFixKindPriority.standard,
    'Remove the library name',
  );
  static const REMOVE_METHOD_DECLARATION = FixKind(
    'dart.fix.remove.methodDeclaration',
    DartFixKindPriority.standard,
    'Remove method declaration',
  );

  // TODO(pq): parameterize to make scope explicit
  static const REMOVE_METHOD_DECLARATION_MULTI = FixKind(
    'dart.fix.remove.methodDeclaration.multi',
    DartFixKindPriority.inFile,
    'Remove unnecessary method declarations in file',
  );
  static const REMOVE_NAME_FROM_COMBINATOR = FixKind(
    'dart.fix.remove.nameFromCombinator',
    DartFixKindPriority.standard,
    "Remove name from '{0}'",
  );
  static const REMOVE_NAME_FROM_DECLARATION_CLAUSE = FixKind(
    'dart.fix.remove.nameFromDeclarationClause',
    DartFixKindPriority.standard,
    '{0}',
  );
  static const REMOVE_NEW = FixKind(
    'dart.fix.remove.new',
    DartFixKindPriority.standard,
    "Remove 'new' keyword",
  );
  static const REMOVE_NON_NULL_ASSERTION = FixKind(
    'dart.fix.remove.nonNullAssertion',
    DartFixKindPriority.standard,
    "Remove the '!'",
  );
  static const REMOVE_NON_NULL_ASSERTION_MULTI = FixKind(
    'dart.fix.remove.nonNullAssertion.multi',
    DartFixKindPriority.inFile,
    "Remove '!'s in file",
  );
  static const REMOVE_ON_CLAUSE = FixKind(
    'dart.fix.remove.on.clause',
    DartFixKindPriority.standard,
    "Remove the invalid 'on' clause",
  );
  static const REMOVE_ON_CLAUSE_MULTI = FixKind(
    'dart.fix.remove.on.clause.multi',
    DartFixKindPriority.inFile,
    "Remove all invalid 'on' clauses in file",
  );
  static const REMOVE_OPERATOR = FixKind(
    'dart.fix.remove.operator',
    DartFixKindPriority.standard,
    'Remove the operator',
  );
  static const REMOVE_OPERATOR_MULTI = FixKind(
    'dart.fix.remove.operator.multi.multi',
    DartFixKindPriority.inFile,
    'Remove operators in file',
  );
  static const REMOVE_PARAMETERS_IN_GETTER_DECLARATION = FixKind(
    'dart.fix.remove.parametersInGetterDeclaration',
    DartFixKindPriority.standard,
    'Remove parameters in getter declaration',
  );
  static const REMOVE_PARENTHESIS_IN_GETTER_INVOCATION = FixKind(
    'dart.fix.remove.parenthesisInGetterInvocation',
    DartFixKindPriority.standard,
    'Remove parentheses in getter invocation',
  );
  static const REMOVE_PRINT = FixKind(
    'dart.fix.remove.removePrint',
    DartFixKindPriority.standard,
    'Remove print statement',
  );
  static const REMOVE_PRINT_MULTI = FixKind(
    'dart.fix.remove.removePrint.multi',
    DartFixKindPriority.inFile,
    'Remove print statements in file',
  );
  static const REMOVE_QUESTION_MARK = FixKind(
    'dart.fix.remove.questionMark',
    DartFixKindPriority.standard,
    "Remove the '?'",
  );
  static const REMOVE_QUESTION_MARK_MULTI = FixKind(
    'dart.fix.remove.questionMark.multi',
    DartFixKindPriority.inFile,
    'Remove unnecessary question marks in file',
  );
  static const REMOVE_REQUIRED = FixKind(
    'dart.fix.remove.required',
    DartFixKindPriority.standard,
    "Remove 'required'",
  );
  static const REMOVE_RETURNED_VALUE = FixKind(
    'dart.fix.remove.returnedValue',
    DartFixKindPriority.standard,
    'Remove invalid returned value',
  );
  static const REMOVE_RETURNED_VALUE_MULTI = FixKind(
    'dart.fix.remove.returnedValue.multi',
    DartFixKindPriority.inFile,
    'Remove invalid returned values in file',
  );
  static const REMOVE_THIS_EXPRESSION = FixKind(
    'dart.fix.remove.thisExpression',
    DartFixKindPriority.standard,
    "Remove 'this' expression",
  );
  static const REMOVE_THIS_EXPRESSION_MULTI = FixKind(
    'dart.fix.remove.thisExpression.multi',
    DartFixKindPriority.inFile,
    "Remove unnecessary 'this' expressions everywhere in file",
  );
  static const REMOVE_TYPE_ANNOTATION = FixKind(
    'dart.fix.remove.typeAnnotation',
    DartFixKindPriority.standard,
    'Remove type annotation',
  );
  static const REMOVE_TYPE_ANNOTATION_MULTI = FixKind(
    'dart.fix.remove.typeAnnotation.multi',
    DartFixKindPriority.inFile,
    'Remove unnecessary type annotations in file',
  );
  static const REMOVE_TYPE_ARGUMENTS = FixKind(
    'dart.fix.remove.typeArguments',
    49,
    'Remove type arguments',
  );
  static const REMOVE_TYPE_CHECK = FixKind(
    'dart.fix.remove.typeCheck',
    DartFixKindPriority.standard,
    'Remove type check',
  );
  static const REMOVE_TYPE_CHECK_MULTI = FixKind(
    'dart.fix.remove.comparison.multi',
    DartFixKindPriority.inFile,
    'Remove type check everywhere in file',
  );
  static const REMOVE_UNEXPECTED_UNDERSCORES = FixKind(
    'dart.fix.remove.unexpectedUnderscores',
    DartFixKindPriority.standard,
    "Remove unexpected '_' characters",
  );
  static const REMOVE_UNEXPECTED_UNDERSCORES_MULTI = FixKind(
    'dart.fix.remove.unexpectedUnderscores.multi',
    DartFixKindPriority.standard,
    "Remove unexpected '_' characters in file",
  );
  static const REMOVE_UNNECESSARY_CAST = FixKind(
    'dart.fix.remove.unnecessaryCast',
    DartFixKindPriority.standard,
    'Remove unnecessary cast',
  );
  static const REMOVE_UNNECESSARY_CAST_MULTI = FixKind(
    'dart.fix.remove.unnecessaryCast.multi',
    DartFixKindPriority.inFile,
    'Remove all unnecessary casts in file',
  );
  static const REMOVE_UNNECESSARY_FINAL = FixKind(
    'dart.fix.remove.unnecessaryFinal',
    DartFixKindPriority.standard,
    "Remove unnecessary 'final'",
  );
  static const REMOVE_UNNECESSARY_FINAL_MULTI = FixKind(
    'dart.fix.remove.unnecessaryFinal.multi',
    DartFixKindPriority.inFile,
    "Remove all unnecessary 'final's in file",
  );
  static const REMOVE_UNNECESSARY_CONST = FixKind(
    'dart.fix.remove.unnecessaryConst',
    DartFixKindPriority.standard,
    'Remove unnecessary const keyword',
  );
  static const REMOVE_UNNECESSARY_CONST_MULTI = FixKind(
    'dart.fix.remove.unnecessaryConst.multi',
    DartFixKindPriority.inFile,
    "Remove unnecessary 'const' keywords everywhere in file",
  );
  static const REMOVE_UNNECESSARY_CONTAINER = FixKind(
    'dart.fix.remove.unnecessaryContainer',
    DartFixKindPriority.standard,
    "Remove unnecessary 'Container'",
  );
  static const REMOVE_UNNECESSARY_CONTAINER_MULTI = FixKind(
    'dart.fix.remove.unnecessaryContainer.multi',
    DartFixKindPriority.inFile,
    "Remove unnecessary 'Container's in file",
  );
  static const REMOVE_UNNECESSARY_LATE = FixKind(
    'dart.fix.remove.unnecessaryLate',
    DartFixKindPriority.standard,
    "Remove unnecessary 'late' keyword",
  );
  static const REMOVE_UNNECESSARY_LATE_MULTI = FixKind(
    'dart.fix.remove.unnecessaryLate.multi',
    DartFixKindPriority.inFile,
    "Remove unnecessary 'late' keywords everywhere in file",
  );
  static const REMOVE_UNNECESSARY_LIBRARY_DIRECTIVE = FixKind(
    'dart.fix.remove.unnecessaryLibraryDirective',
    DartFixKindPriority.standard,
    'Remove unnecessary library directive',
  );
  static const REMOVE_UNNECESSARY_NEW = FixKind(
    'dart.fix.remove.unnecessaryNew',
    DartFixKindPriority.standard,
    "Remove unnecessary 'new' keyword",
  );
  static const REMOVE_UNNECESSARY_NEW_MULTI = FixKind(
    'dart.fix.remove.unnecessaryNew.multi',
    DartFixKindPriority.inFile,
    "Remove unnecessary 'new' keywords everywhere in file",
  );
  static const REMOVE_UNNECESSARY_PARENTHESES = FixKind(
    'dart.fix.remove.unnecessaryParentheses',
    DartFixKindPriority.standard,
    'Remove unnecessary parentheses',
  );
  static const REMOVE_UNNECESSARY_PARENTHESES_MULTI = FixKind(
    'dart.fix.remove.unnecessaryParentheses.multi',
    DartFixKindPriority.inFile,
    'Remove all unnecessary parentheses in file',
  );
  static const REMOVE_UNNECESSARY_RAW_STRING = FixKind(
    'dart.fix.remove.unnecessaryRawString',
    DartFixKindPriority.standard,
    "Remove unnecessary 'r' in string",
  );
  static const REMOVE_UNNECESSARY_RAW_STRING_MULTI = FixKind(
    'dart.fix.remove.unnecessaryRawString.multi',
    DartFixKindPriority.inFile,
    "Remove unnecessary 'r' in strings in file",
  );
  static const REMOVE_UNNECESSARY_STRING_ESCAPE = FixKind(
    'dart.fix.remove.unnecessaryStringEscape',
    DartFixKindPriority.standard,
    "Remove unnecessary '\\' in string",
  );
  static const REMOVE_UNNECESSARY_STRING_ESCAPE_MULTI = FixKind(
    'dart.fix.remove.unnecessaryStringEscape.multi',
    DartFixKindPriority.inFile,
    "Remove unnecessary '\\' in strings in file",
  );
  static const REMOVE_UNNECESSARY_STRING_INTERPOLATION = FixKind(
    'dart.fix.remove.unnecessaryStringInterpolation',
    DartFixKindPriority.standard,
    'Remove unnecessary string interpolation',
  );
  static const REMOVE_UNNECESSARY_STRING_INTERPOLATION_MULTI = FixKind(
    'dart.fix.remove.unnecessaryStringInterpolation.multi',
    DartFixKindPriority.inFile,
    'Remove all unnecessary string interpolations in file',
  );
  static const REMOVE_UNNECESSARY_TO_LIST = FixKind(
    'dart.fix.remove.unnecessaryToList',
    DartFixKindPriority.standard,
    "Remove unnecessary 'toList' call",
  );
  static const REMOVE_UNNECESSARY_TO_LIST_MULTI = FixKind(
    'dart.fix.remove.unnecessaryToList.multi',
    DartFixKindPriority.inFile,
    "Remove unnecessary 'toList' calls in file",
  );
  static const REMOVE_UNNECESSARY_WILDCARD_PATTERN = FixKind(
    'dart.fix.remove.unnecessaryWildcardPattern',
    DartFixKindPriority.standard,
    'Remove unnecessary wildcard pattern',
  );
  static const REMOVE_UNNECESSARY_WILDCARD_PATTERN_MULTI = FixKind(
    'dart.fix.remove.unnecessaryWildcardPattern.multi',
    DartFixKindPriority.standard,
    'Remove all unnecessary wildcard pattern in file',
  );
  static const REMOVE_UNUSED_CATCH_CLAUSE = FixKind(
    'dart.fix.remove.unusedCatchClause',
    DartFixKindPriority.standard,
    "Remove unused 'catch' clause",
  );
  static const REMOVE_UNUSED_CATCH_CLAUSE_MULTI = FixKind(
    'dart.fix.remove.unusedCatchClause.multi',
    DartFixKindPriority.inFile,
    "Remove unused 'catch' clauses in file",
  );
  static const REMOVE_UNUSED_CATCH_STACK = FixKind(
    'dart.fix.remove.unusedCatchStack',
    DartFixKindPriority.standard,
    'Remove unused stack trace variable',
  );
  static const REMOVE_UNUSED_CATCH_STACK_MULTI = FixKind(
    'dart.fix.remove.unusedCatchStack.multi',
    DartFixKindPriority.inFile,
    'Remove unused stack trace variables in file',
  );
  static const REMOVE_UNUSED_ELEMENT = FixKind(
    'dart.fix.remove.unusedElement',
    DartFixKindPriority.standard,
    'Remove unused element',
  );
  static const REMOVE_UNUSED_FIELD = FixKind(
    'dart.fix.remove.unusedField',
    DartFixKindPriority.standard,
    'Remove unused field',
  );
  static const REMOVE_UNUSED_IMPORT = FixKind(
    'dart.fix.remove.unusedImport',
    DartFixKindPriority.standard,
    'Remove unused import',
  );
  static const REMOVE_UNUSED_IMPORT_MULTI = FixKind(
    'dart.fix.remove.unusedImport.multi',
    DartFixKindPriority.inFile,
    'Remove all unused imports in file',
  );
  static const REMOVE_UNUSED_LABEL = FixKind(
    'dart.fix.remove.unusedLabel',
    DartFixKindPriority.standard,
    'Remove unused label',
  );
  static const REMOVE_UNUSED_LOCAL_VARIABLE = FixKind(
    'dart.fix.remove.unusedLocalVariable',
    DartFixKindPriority.standard,
    'Remove unused local variable',
  );
  static const REMOVE_UNUSED_PARAMETER = FixKind(
    'dart.fix.remove.unusedParameter',
    DartFixKindPriority.standard,
    'Remove the unused parameter',
  );
  static const REMOVE_UNUSED_PARAMETER_MULTI = FixKind(
    'dart.fix.remove.unusedParameter.multi',
    DartFixKindPriority.inFile,
    'Remove unused parameters everywhere in file',
  );
  static const REMOVE_VAR = FixKind(
    'dart.fix.remove.var',
    DartFixKindPriority.standard,
    "Remove 'var'",
  );
  static const REMOVE_VAR_KEYWORD = FixKind(
    'dart.fix.remove.var.keyword',
    DartFixKindPriority.standard,
    "Remove 'var'",
  );
  static const RENAME_METHOD_PARAMETER = FixKind(
    'dart.fix.rename.methodParameter',
    DartFixKindPriority.standard,
    "Rename '{0}' to '{1}'",
  );
  static const RENAME_TO_CAMEL_CASE = FixKind(
    'dart.fix.rename.toCamelCase',
    DartFixKindPriority.standard,
    "Rename to '{0}'",
  );
  static const RENAME_TO_CAMEL_CASE_MULTI = FixKind(
    'dart.fix.rename.toCamelCase.multi',
    DartFixKindPriority.inFile,
    'Rename to camel case everywhere in file',
  );
  static const REPLACE_BOOLEAN_WITH_BOOL = FixKind(
    'dart.fix.replace.booleanWithBool',
    DartFixKindPriority.standard,
    "Replace 'boolean' with 'bool'",
  );
  static const REPLACE_BOOLEAN_WITH_BOOL_MULTI = FixKind(
    'dart.fix.replace.booleanWithBool.multi',
    DartFixKindPriority.inFile,
    "Replace all 'boolean's with 'bool' in file",
  );
  static const REPLACE_CASCADE_WITH_DOT = FixKind(
    'dart.fix.replace.cascadeWithDot',
    DartFixKindPriority.standard,
    "Replace '..' with '.'",
  );
  static const REPLACE_CASCADE_WITH_DOT_MULTI = FixKind(
    'dart.fix.replace.cascadeWithDot.multi',
    DartFixKindPriority.inFile,
    "Replace unnecessary '..'s with '.'s everywhere in file",
  );
  static const REPLACE_COLON_WITH_EQUALS = FixKind(
    'dart.fix.replace.colonWithEquals',
    DartFixKindPriority.standard,
    "Replace ':' with '='",
  );
  static const REPLACE_COLON_WITH_EQUALS_MULTI = FixKind(
    'dart.fix.replace.colonWithEquals.multi',
    DartFixKindPriority.inFile,
    "Replace ':'s with '='s everywhere in file",
  );
  static const REPLACE_COLON_WITH_IN = FixKind(
    'dart.fix.replace.colonWithIn',
    DartFixKindPriority.standard,
    "Replace ':' with 'in'",
  );
  static const REPLACE_COLON_WITH_IN_MULTI = FixKind(
    'dart.fix.replace.colonWithIn.multi',
    DartFixKindPriority.inFile,
    "Replace ':'s with 'in's everywhere in file",
  );
  static const REPLACE_CONTAINER_WITH_COLORED_BOX = FixKind(
    'dart.fix.replace.containerWithColoredBox',
    DartFixKindPriority.standard,
    "Replace with 'ColoredBox'",
  );
  static const REPLACE_CONTAINER_WITH_COLORED_BOX_MULTI = FixKind(
    'dart.fix.replace.containerWithColoredBox.multi',
    DartFixKindPriority.inFile,
    "Replace with 'ColoredBox' everywhere in file",
  );
  static const REPLACE_CONTAINER_WITH_SIZED_BOX = FixKind(
    'dart.fix.replace.containerWithSizedBox',
    DartFixKindPriority.standard,
    "Replace with 'SizedBox'",
  );
  static const REPLACE_CONTAINER_WITH_SIZED_BOX_MULTI = FixKind(
    'dart.fix.replace.containerWithSizedBox.multi',
    DartFixKindPriority.inFile,
    "Replace with 'SizedBox' everywhere in file",
  );
  static const REPLACE_FINAL_WITH_CONST = FixKind(
    'dart.fix.replace.finalWithConst',
    DartFixKindPriority.standard,
    "Replace 'final' with 'const'",
  );
  static const REPLACE_FINAL_WITH_CONST_MULTI = FixKind(
    'dart.fix.replace.finalWithConst.multi',
    DartFixKindPriority.inFile,
    "Replace 'final' with 'const' where possible in file",
  );
  static const REPLACE_FINAL_WITH_VAR = FixKind(
    'dart.fix.replace.finalWithVar',
    DartFixKindPriority.standard,
    "Replace 'final' with 'var'",
  );
  static const REPLACE_FINAL_WITH_VAR_MULTI = FixKind(
    'dart.fix.replace.finalWithVar.multi',
    DartFixKindPriority.inFile,
    "Replace 'final' with 'var' where possible in file",
  );
  static const REPLACE_NEW_WITH_CONST = FixKind(
    'dart.fix.replace.newWithConst',
    DartFixKindPriority.standard,
    "Replace 'new' with 'const'",
  );
  static const REPLACE_NEW_WITH_CONST_MULTI = FixKind(
    'dart.fix.replace.newWithConst.multi',
    DartFixKindPriority.inFile,
    "Replace 'new' with 'const' where possible in file",
  );
  static const REPLACE_NULL_CHECK_WITH_CAST = FixKind(
    'dart.fix.replace.nullCheckWithCast',
    DartFixKindPriority.standard,
    'Replace null check with a cast',
  );
  static const REPLACE_NULL_CHECK_WITH_CAST_MULTI = FixKind(
    'dart.fix.replace.nullCheckWithCast.multi',
    DartFixKindPriority.inFile,
    'Replace null checks with casts in file',
  );
  static const REPLACE_NULL_WITH_CLOSURE = FixKind(
    'dart.fix.replace.nullWithClosure',
    DartFixKindPriority.standard,
    "Replace 'null' with a closure",
  );
  static const REPLACE_NULL_WITH_CLOSURE_MULTI = FixKind(
    'dart.fix.replace.nullWithClosure.multi',
    DartFixKindPriority.inFile,
    "Replace 'null's with closures where possible in file",
  );
  static const REPLACE_NULL_WITH_VOID = FixKind(
    'dart.fix.replace.nullWithVoid',
    DartFixKindPriority.standard,
    "Replace 'Null' with 'void'",
  );
  static const REPLACE_NULL_WITH_VOID_MULTI = FixKind(
    'dart.fix.replace.nullWithVoid.multi',
    DartFixKindPriority.inFile,
    "Replace 'Null' with 'void' everywhere in file",
  );
  static const REPLACE_RETURN_TYPE = FixKind(
    'dart.fix.replace.returnType',
    DartFixKindPriority.standard,
    "Replace the return type with '{0}'",
  );
  static const REPLACE_RETURN_TYPE_FUTURE = FixKind(
    'dart.fix.replace.returnTypeFuture',
    DartFixKindPriority.standard,
    "Return 'Future<{0}>'",
  );
  static const REPLACE_RETURN_TYPE_FUTURE_MULTI = FixKind(
    'dart.fix.replace.returnTypeFuture.multi',
    DartFixKindPriority.inFile,
    "Return a 'Future' where required in file",
  );
  static const REPLACE_RETURN_TYPE_ITERABLE = FixKind(
    'dart.fix.replace.returnTypeIterable',
    DartFixKindPriority.standard,
    "Return 'Iterable<{0}>'",
  );
  static const REPLACE_RETURN_TYPE_STREAM = FixKind(
    'dart.fix.replace.returnTypeStream',
    DartFixKindPriority.standard,
    "Return 'Stream<{0}>'",
  );
  static const REPLACE_VAR_WITH_DYNAMIC = FixKind(
    'dart.fix.replace.varWithDynamic',
    DartFixKindPriority.standard,
    "Replace 'var' with 'dynamic'",
  );
  static const REPLACE_WITH_ARROW = FixKind(
    'dart.fix.replace.withArrow',
    DartFixKindPriority.standard,
    "Replace with '=>'",
  );
  static const REPLACE_WITH_ARROW_MULTI = FixKind(
    'dart.fix.replace.withArrow.multi',
    DartFixKindPriority.standard,
    "Replace with '=>' everywhere in file",
  );
  static const REPLACE_WITH_BRACKETS = FixKind(
    'dart.fix.replace.withBrackets',
    DartFixKindPriority.standard,
    'Replace with { }',
  );
  static const REPLACE_WITH_BRACKETS_MULTI = FixKind(
    'dart.fix.replace.withBrackets.multi',
    DartFixKindPriority.inFile,
    'Replace with { } everywhere in file',
  );
  static const REPLACE_WITH_CONDITIONAL_ASSIGNMENT = FixKind(
    'dart.fix.replace.withConditionalAssignment',
    DartFixKindPriority.standard,
    'Replace with ??=',
  );
  static const REPLACE_WITH_CONDITIONAL_ASSIGNMENT_MULTI = FixKind(
    'dart.fix.replace.withConditionalAssignment.multi',
    DartFixKindPriority.inFile,
    'Replace with ??= everywhere in file',
  );
  static const REPLACE_WITH_DECORATED_BOX = FixKind(
    'dart.fix.replace.withDecoratedBox',
    DartFixKindPriority.standard,
    "Replace with 'DecoratedBox'",
  );
  static const REPLACE_WITH_DECORATED_BOX_MULTI = FixKind(
    'dart.fix.replace.withDecoratedBox.multi',
    DartFixKindPriority.inFile,
    "Replace with 'DecoratedBox' everywhere in file",
  );
  static const REPLACE_WITH_EIGHT_DIGIT_HEX = FixKind(
    'dart.fix.replace.withEightDigitHex',
    DartFixKindPriority.standard,
    "Replace with '{0}'",
  );
  static const REPLACE_WITH_EIGHT_DIGIT_HEX_MULTI = FixKind(
    'dart.fix.replace.withEightDigitHex.multi',
    DartFixKindPriority.inFile,
    'Replace with hex digits everywhere in file',
  );
  static const REPLACE_WITH_EXTENSION_NAME = FixKind(
    'dart.fix.replace.withExtensionName',
    DartFixKindPriority.standard,
    "Replace with '{0}'",
  );
  static const REPLACE_WITH_IDENTIFIER = FixKind(
    'dart.fix.replace.withIdentifier',
    DartFixKindPriority.standard,
    'Replace with identifier',
  );

  // TODO(pq): parameterize message (used by LintNames.avoid_types_on_closure_parameters)
  static const REPLACE_WITH_IDENTIFIER_MULTI = FixKind(
    'dart.fix.replace.withIdentifier.multi',
    DartFixKindPriority.inFile,
    'Replace with identifier everywhere in file',
  );
  static const REPLACE_WITH_INTERPOLATION = FixKind(
    'dart.fix.replace.withInterpolation',
    DartFixKindPriority.standard,
    'Replace with interpolation',
  );
  static const REPLACE_WITH_INTERPOLATION_MULTI = FixKind(
    'dart.fix.replace.withInterpolation.multi',
    DartFixKindPriority.inFile,
    'Replace with interpolations everywhere in file',
  );
  static const REPLACE_WITH_IS_EMPTY = FixKind(
    'dart.fix.replace.withIsEmpty',
    DartFixKindPriority.standard,
    "Replace with 'isEmpty'",
  );
  static const REPLACE_WITH_IS_EMPTY_MULTI = FixKind(
    'dart.fix.replace.withIsEmpty.multi',
    DartFixKindPriority.inFile,
    "Replace with 'isEmpty' everywhere in file",
  );
  static const REPLACE_WITH_IS_NAN = FixKind(
    'dart.fix.replace.withIsNaN',
    DartFixKindPriority.standard,
    "Replace the condition with '.isNaN'",
  );
  static const REPLACE_WITH_IS_NOT_EMPTY = FixKind(
    'dart.fix.replace.withIsNotEmpty',
    DartFixKindPriority.standard,
    "Replace with 'isNotEmpty'",
  );
  static const REPLACE_WITH_IS_NOT_EMPTY_MULTI = FixKind(
    'dart.fix.replace.withIsNotEmpty.multi',
    DartFixKindPriority.inFile,
    "Replace with 'isNotEmpty' everywhere in file",
  );
  static const REPLACE_WITH_NOT_NULL_AWARE = FixKind(
    'dart.fix.replace.withNotNullAware',
    DartFixKindPriority.standard,
    "Replace with '{0}'",
  );
  static const REPLACE_WITH_NOT_NULL_AWARE_MULTI = FixKind(
    'dart.fix.replace.withNotNullAware.multi',
    DartFixKindPriority.inFile,
    'Replace with non-null-aware operator everywhere in file',
  );
  static const REPLACE_WITH_NULL_AWARE = FixKind(
    'dart.fix.replace.withNullAware',
    DartFixKindPriority.standard,
    "Replace the '{0}' with a '{1}' in the invocation",
  );
  static const REPLACE_WITH_PART_OF_URI = FixKind(
    'dart.fix.replace.withPartOfUri',
    DartFixKindPriority.standard,
    "Replace with 'part of {0}'",
  );
  static const REPLACE_WITH_TEAR_OFF = FixKind(
    'dart.fix.replace.withTearOff',
    DartFixKindPriority.standard,
    'Replace function literal with tear-off',
  );
  static const REPLACE_WITH_TEAR_OFF_MULTI = FixKind(
    'dart.fix.replace.withTearOff.multi',
    DartFixKindPriority.inFile,
    'Replace function literals with tear-offs everywhere in file',
  );
  static const REPLACE_WITH_UNICODE_ESCAPE = FixKind(
    'dart.fix.replace.withUnicodeEscape',
    DartFixKindPriority.standard,
    'Replace with Unicode escape',
  );
  static const REPLACE_WITH_VAR = FixKind(
    'dart.fix.replace.withVar',
    DartFixKindPriority.standard,
    "Replace type annotation with 'var'",
  );
  static const REPLACE_WITH_VAR_MULTI = FixKind(
    'dart.fix.replace.withVar.multi',
    DartFixKindPriority.inFile,
    "Replace type annotations with 'var' everywhere in file",
  );
  static const REPLACE_WITH_WILDCARD = FixKind(
    'dart.fix.replace.withWildcard',
    DartFixKindPriority.standard,
    "Replace with '_'",
  );
  static const REPLACE_WITH_WILDCARD_MULTI = FixKind(
    'dart.fix.replace.withWildcard.multi',
    DartFixKindPriority.standard,
    "Replace with '_' everywhere in file",
  );
  static const SORT_CHILD_PROPERTY_LAST = FixKind(
    'dart.fix.sort.childPropertyLast',
    DartFixKindPriority.standard,
    'Move child property to end of arguments',
  );
  static const SORT_CHILD_PROPERTY_LAST_MULTI = FixKind(
    'dart.fix.sort.childPropertyLast.multi',
    DartFixKindPriority.inFile,
    'Move child properties to ends of arguments everywhere in file',
  );
  static const SORT_COMBINATORS = FixKind(
    'dart.fix.sort.combinators',
    DartFixKindPriority.standard,
    'Sort combinators',
  );
  static const SORT_COMBINATORS_MULTI = FixKind(
    'dart.fix.sort.combinators.multi',
    DartFixKindPriority.inFile,
    'Sort combinators everywhere in file',
  );
  static const SORT_CONSTRUCTOR_FIRST = FixKind(
    'dart.fix.sort.sortConstructorFirst',
    DartFixKindPriority.standard,
    'Move before other members',
  );
  static const SORT_CONSTRUCTOR_FIRST_MULTI = FixKind(
    'dart.fix.sort.sortConstructorFirst.multi',
    DartFixKindPriority.standard,
    'Move all constructors before other members',
  );
  static const SORT_UNNAMED_CONSTRUCTOR_FIRST = FixKind(
    'dart.fix.sort.sortUnnamedConstructorFirst',
    DartFixKindPriority.standard,
    'Move before named constructors',
  );
  static const SORT_UNNAMED_CONSTRUCTOR_FIRST_MULTI = FixKind(
    'dart.fix.sort.sortUnnamedConstructorFirst.multi',
    DartFixKindPriority.standard,
    'Move all unnamed constructors before named constructors',
  );
  static const SPLIT_MULTIPLE_DECLARATIONS = FixKind(
    'dart.fix.split.multipleDeclarations',
    DartFixKindPriority.standard,
    'Split multiple declarations into multiple lines',
  );
  static const SPLIT_MULTIPLE_DECLARATIONS_MULTI = FixKind(
    'dart.fix.split.multipleDeclarations.multi',
    DartFixKindPriority.standard,
    'Split all multiple declarations into multiple lines',
  );
  static const SURROUND_WITH_PARENTHESES = FixKind(
    'dart.fix.surround.parentheses',
    DartFixKindPriority.standard,
    'Surround with parentheses',
  );
  static const UPDATE_SDK_CONSTRAINTS = FixKind(
    'dart.fix.updateSdkConstraints',
    DartFixKindPriority.standard,
    'Update the SDK constraints',
  );
  static const USE_DIVISION = FixKind(
    'dart.fix.use.division',
    DartFixKindPriority.standard,
    'Use / instead of undefined ~/',
  );
  static const USE_EFFECTIVE_INTEGER_DIVISION = FixKind(
    'dart.fix.use.effectiveIntegerDivision',
    DartFixKindPriority.standard,
    'Use effective integer division ~/',
  );
  static const USE_EFFECTIVE_INTEGER_DIVISION_MULTI = FixKind(
    'dart.fix.use.effectiveIntegerDivision.multi',
    DartFixKindPriority.inFile,
    'Use effective integer division ~/ everywhere in file',
  );
  static const USE_EQ_EQ_NULL = FixKind(
    'dart.fix.use.eqEqNull',
    DartFixKindPriority.standard,
    "Use == null instead of 'is Null'",
  );
  static const USE_EQ_EQ_NULL_MULTI = FixKind(
    'dart.fix.use.eqEqNull.multi',
    DartFixKindPriority.inFile,
    "Use == null instead of 'is Null' everywhere in file",
  );
  static const USE_IS_NOT_EMPTY = FixKind(
    'dart.fix.use.isNotEmpty',
    DartFixKindPriority.standard,
    "Use x.isNotEmpty instead of '!x.isEmpty'",
  );
  static const USE_IS_NOT_EMPTY_MULTI = FixKind(
    'dart.fix.use.isNotEmpty.multi',
    DartFixKindPriority.inFile,
    "Use x.isNotEmpty instead of '!x.isEmpty' everywhere in file",
  );
  static const USE_NAMED_CONSTANTS = FixKind(
    'dart.fix.use.namedConstants',
    DartFixKindPriority.standard,
    'Replace with a predefined named constant',
  );
  static const USE_NOT_EQ_NULL = FixKind(
    'dart.fix.use.notEqNull',
    DartFixKindPriority.standard,
    "Use != null instead of 'is! Null'",
  );
  static const USE_NOT_EQ_NULL_MULTI = FixKind(
    'dart.fix.use.notEqNull.multi',
    DartFixKindPriority.inFile,
    "Use != null instead of 'is! Null' everywhere in file",
  );
  static const USE_RETHROW = FixKind(
    'dart.fix.use.rethrow',
    DartFixKindPriority.standard,
    'Replace throw with rethrow',
  );
  static const USE_RETHROW_MULTI = FixKind(
    'dart.fix.use.rethrow.multi',
    DartFixKindPriority.inFile,
    'Replace throw with rethrow where possible in file',
  );
  static const WRAP_IN_TEXT = FixKind(
    'dart.fix.flutter.wrap.text',
    DartFixKindPriority.standard,
    "Wrap in a 'Text' widget",
  );
  static const WRAP_IN_UNAWAITED = FixKind(
    'dart.fix.wrap.unawaited',
    DartFixKindPriority.standard,
    "Wrap in 'unawaited'",
  );
}
