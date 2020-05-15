// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart'
    show DartFix, EditDartfixParams;
import 'package:analysis_server/src/edit/edit_dartfix.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/dartfix_registrar.dart';
import 'package:analysis_server/src/edit/fix/fix_error_task.dart';
import 'package:analysis_server/src/edit/fix/fix_lint_task.dart';
import 'package:analysis_server/src/edit/fix/prefer_mixin_fix.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

final allFixes = <DartFixInfo>[
  //
  // Error and warning fixes.
  //
  DartFixInfo(
    'wrong_number_of_type_arguments_constructor',
    'Move named constructor type arguments from the name to the type.',
    FixErrorTask.fixNamedConstructorTypeArgs,
  ),
  //
  // Assist fixes.
  //
  DartFixInfo(
    'convert_class_to_mixin',
    'Convert classes used as a mixin to the new mixin syntax.',
    PreferMixinFix.task,
  ),
  //
  // Lint fixes.
  //
  // TODO(brianwilkerson) The commented out fixes below involve potentially
  //  non-local changes, so they can't currently be applied together. I have an
  //  idea for how to update FixProcessor to support these fixes.
//  LintFixInfo.alwaysDeclareReturnTypes,
//  LintFixInfo.alwaysRequireNonNullNamedParameters
//  LintFixInfo.alwaysSpecifyTypes,
  LintFixInfo.annotateOverrides,
  LintFixInfo.avoidAnnotatingWithDynamic,
  LintFixInfo.avoidEmptyElse,
  LintFixInfo.avoidInitToNull,
  LintFixInfo.avoidRedundantArgumentValues,
  LintFixInfo.avoidRelativeLibImports,
  LintFixInfo.avoidReturnTypesOnSetters,
  LintFixInfo.avoidTypesOnClosureParameters,
  LintFixInfo.awaitOnlyFutures,
  LintFixInfo.curlyBracesInFlowControlStructures,
  LintFixInfo.diagnosticDescribeAllProperties,
  LintFixInfo.emptyCatches,
  LintFixInfo.emptyConstructorBodies,
  LintFixInfo.emptyStatements,
  LintFixInfo.hashAndEquals,
  LintFixInfo.noDuplicateCaseValues,
  LintFixInfo.nonConstantIdentifierNames,
  LintFixInfo.nullClosures,
  LintFixInfo.omitLocalVariableTypes,
  LintFixInfo.preferAdjacentStringConcatenation,
  LintFixInfo.preferCollectionLiterals,
  LintFixInfo.preferConditionalAssignment,
  LintFixInfo.preferConstConstructors,
  LintFixInfo.preferConstConstructorsInImmutables,
  LintFixInfo.preferConstDeclarations,
  LintFixInfo.preferContains,
  LintFixInfo.preferEqualForDefaultValues,
  LintFixInfo.preferFinalFields,
  LintFixInfo.preferFinalLocals,
  LintFixInfo.preferForElementsToMapFromIterable,
  LintFixInfo.preferGenericFunctionTypeAliases,
  LintFixInfo.preferIfElementsToConditionalExpressions,
  LintFixInfo.preferIfNullOperators,
  LintFixInfo.preferInlinedAdds,
  LintFixInfo.preferIntLiterals,
  LintFixInfo.preferIsEmpty,
  LintFixInfo.preferIsNotEmpty,
  LintFixInfo.preferIterableWhereType,
  LintFixInfo.preferNullAwareOperators,
  LintFixInfo.preferRelativeImports,
  LintFixInfo.preferSingleQuotes,
  LintFixInfo.preferSpreadCollections,
  LintFixInfo.slashForDocComments,
  LintFixInfo.sortChildPropertiesLast,
//  LintFixInfo.typeAnnotatePublicApis,
  LintFixInfo.typeInitFormals,
  LintFixInfo.unawaitedFutures,
  LintFixInfo.unnecessaryBraceInStringInterps,
  LintFixInfo.unnecessaryConst,
  LintFixInfo.unnecessaryLambdas,
  LintFixInfo.unnecessaryNew,
  LintFixInfo.unnecessaryOverrides,
  LintFixInfo.unnecessaryThis,
  LintFixInfo.useFunctionTypeSyntaxForParameters,
  LintFixInfo.useRethrowWhenPossible,
];

/// [DartFixInfo] represents a fix that can be applied by [EditDartFix].
class DartFixInfo {
  /// The key provided on the command line via the `--fix` option to refer to
  /// this fix.
  final String key;

  /// A description of the fix, printed by the `--help` option.
  final String description;

  /// A flag indicating whether this fix is related to the lints in the pedantic
  /// lint set.
  final bool isPedantic;

  final void Function(DartFixRegistrar registrar, DartFixListener listener,
      EditDartfixParams params) _setup;

  const DartFixInfo(
    this.key,
    this.description,
    this._setup, {
    this.isPedantic = false,
  });

  /// Return a newly created fix generated from this fix info.
  DartFix asDartFix() => DartFix(key, description: description);

  /// Register this fix with the [registrar] and report progress to the
  /// [listener].
  void setup(DartFixRegistrar registrar, DartFixListener listener,
      EditDartfixParams params) {
    _setup(registrar, listener, params);
  }
}

/// Information about a fix that applies to a lint.
class LintFixInfo extends DartFixInfo {
  // TODO(brianwilkerson) Add fixes in FixProcessor for the following pedantic
  //  lints:
  // avoid_null_checks_in_equality_operators
  // avoid_shadowing_type_parameters
  // avoid_types_as_parameter_names
  // camel_case_extensions
  // library_names
  // prefer_contains
  // recursive_getters
  // unrelated_type_equality_checks
  // valid_regexps

  static final alwaysDeclareReturnTypes = LintFixInfo(
    'always_declare_return_types',
    DartFixKind.ADD_RETURN_TYPE,
    'Add a return type where possible.',
    isPedantic: true,
  );

  static final alwaysRequireNonNullNamedParameters = LintFixInfo(
    'always_require_non_null_named_parameters',
    DartFixKind.ADD_REQUIRED,
    'Add an @required annotation.',
    isPedantic: true,
  );

  static final alwaysSpecifyTypes = LintFixInfo(
    'always_specify_types',
    DartFixKind.ADD_TYPE_ANNOTATION,
    'Add a type annotation.',
  );

  static final annotateOverrides = LintFixInfo(
    'annotate_overrides',
    DartFixKind.ADD_OVERRIDE,
    'Add an @override annotation.',
    isPedantic: true,
  );

  static final avoidAnnotatingWithDynamic = LintFixInfo(
    'avoid_annotating_with_dynamic',
    DartFixKind.REMOVE_TYPE_ANNOTATION,
    'Remove the type annotation.',
  );

  static final avoidEmptyElse = LintFixInfo(
    'avoid_empty_else',
    DartFixKind.REMOVE_EMPTY_ELSE,
    'Remove the empty else.',
    isPedantic: true,
  );

  static final avoidInitToNull = LintFixInfo(
    'avoid_init_to_null',
    DartFixKind.REMOVE_INITIALIZER,
    'Remove the initializer.',
    isPedantic: true,
  );

  static final avoidRedundantArgumentValues = LintFixInfo(
    'avoid_redundant_argument_values',
    DartFixKind.REMOVE_ARGUMENT,
    'Remove the redundant argument.',
  );

  static final avoidRelativeLibImports = LintFixInfo(
    'avoid_relative_lib_imports',
    DartFixKind.CONVERT_TO_PACKAGE_IMPORT,
    'Convert the import to a package: import.',
    isPedantic: true,
  );

  static final avoidReturnTypesOnSetters = LintFixInfo(
    'avoid_return_types_on_setters',
    DartFixKind.REMOVE_TYPE_ANNOTATION,
    'Remove the return type.',
    isPedantic: true,
  );

  static final avoidTypesOnClosureParameters = LintFixInfo(
    'avoid_types_on_closure_parameters',
    // Also sometimes fixed by DartFixKind.REPLACE_WITH_IDENTIFIER
    DartFixKind.REMOVE_TYPE_ANNOTATION,
    'Remove the type annotation.',
  );

  static final awaitOnlyFutures = LintFixInfo(
    'await_only_futures',
    DartFixKind.REMOVE_AWAIT,
    "Remove the 'await'.",
  );

  static final curlyBracesInFlowControlStructures = LintFixInfo(
    'curly_braces_in_flow_control_structures',
    DartFixKind.ADD_CURLY_BRACES,
    'Add curly braces.',
    isPedantic: true,
  );

  static final diagnosticDescribeAllProperties = LintFixInfo(
    'diagnostic_describe_all_properties',
    DartFixKind.ADD_DIAGNOSTIC_PROPERTY_REFERENCE,
    'Add a debug reference to this property.',
  );

  static final emptyCatches = LintFixInfo(
    'empty_catches',
    DartFixKind.REMOVE_EMPTY_CATCH,
    'Remove the empty catch clause.',
    isPedantic: true,
  );

  static final emptyConstructorBodies = LintFixInfo(
    'empty_constructor_bodies',
    DartFixKind.REMOVE_EMPTY_CONSTRUCTOR_BODY,
    'Remove the empoty catch clause.',
    isPedantic: true,
  );

  static final emptyStatements = LintFixInfo(
    'empty_statements',
    // Also sometimes fixed by DartFixKind.REPLACE_WITH_BRACKETS
    DartFixKind.REMOVE_EMPTY_STATEMENT,
    'Remove the empty statement.',
  );

  static final hashAndEquals = LintFixInfo(
    'hash_and_equals',
    DartFixKind.CREATE_METHOD,
    'Create the missing method.',
  );

  static final noDuplicateCaseValues = LintFixInfo(
    'no_duplicate_case_values',
    DartFixKind.REMOVE_DUPLICATE_CASE,
    'Remove the duplicate case clause.',
    isPedantic: true,
  );

  static final nonConstantIdentifierNames = LintFixInfo(
    'non_constant_identifier_names',
    DartFixKind.RENAME_TO_CAMEL_CASE,
    'Change the name to be camelCase.',
  );

  static final nullClosures = LintFixInfo(
    'null_closures',
    DartFixKind.REPLACE_NULL_WITH_CLOSURE,
    'Convert nulls to closures that return null where expected.',
    isPedantic: true,
  );

  static final omitLocalVariableTypes = LintFixInfo(
    'omit_local_variable_types',
    DartFixKind.REPLACE_WITH_VAR,
    "Replace the type annotation with 'var'",
    isPedantic: true,
  );

  static final preferAdjacentStringConcatenation = LintFixInfo(
    'prefer_adjacent_string_concatenation',
    DartFixKind.REMOVE_OPERATOR,
    "Remove the '+' operator.",
    isPedantic: true,
  );

  static final preferCollectionLiterals = LintFixInfo(
    'prefer_collection_literals',
    DartFixKind.CONVERT_TO_LIST_LITERAL,
    'Replace with a collection literal.',
    isPedantic: true,
  );

  static final preferConditionalAssignment = LintFixInfo(
    'prefer_conditional_assignment',
    DartFixKind.REPLACE_WITH_CONDITIONAL_ASSIGNMENT,
    'Replace with a conditional assignment.',
    isPedantic: true,
  );

  static final preferConstConstructors = LintFixInfo(
    'prefer_const_constructors',
    DartFixKind.ADD_CONST,
    'Make the instantiation const.',
  );

  static final preferConstConstructorsInImmutables = LintFixInfo(
    'prefer_const_constructors_in_immutables',
    DartFixKind.ADD_CONST,
    'Make the constructor const.',
  );

  static final preferConstDeclarations = LintFixInfo(
    'prefer_const_declarations',
    DartFixKind.REPLACE_FINAL_WITH_CONST,
    'Make the declaration const.',
  );

  static final preferContains = LintFixInfo(
    'prefer_contains',
    DartFixKind.CONVERT_TO_CONTAINS,
    "Convert to using 'contains'.",
    isPedantic: true,
  );

  static final preferEqualForDefaultValues = LintFixInfo(
    'prefer_equal_for_default_values',
    DartFixKind.REPLACE_COLON_WITH_EQUALS,
    'Convert declarations to use = to separate a named parameter from its default value.',
    isPedantic: true,
  );

  static final preferFinalFields = LintFixInfo(
    'prefer_final_fields',
    DartFixKind.MAKE_FINAL,
    'Make the field final.',
    isPedantic: true,
  );

  static final preferFinalLocals = LintFixInfo(
    'prefer_final_locals',
    DartFixKind.MAKE_FINAL,
    "Make the variable 'final'.",
  );

  static final preferForElementsToMapFromIterable = LintFixInfo(
    'prefer_for_elements_to_map_fromIterable',
    DartFixKind.CONVERT_TO_FOR_ELEMENT,
    'Convert to a for element.',
    isPedantic: true,
  );

  static final preferGenericFunctionTypeAliases = LintFixInfo(
    'prefer_generic_function_type_aliases',
    DartFixKind.CONVERT_TO_GENERIC_FUNCTION_SYNTAX,
    "Convert into 'Function' syntax",
    isPedantic: true,
  );

  static final preferIfElementsToConditionalExpressions = LintFixInfo(
      'prefer_if_elements_to_conditional_expressions',
      DartFixKind.CONVERT_TO_IF_ELEMENT,
      "Convert to an 'if' element.");

  static final preferIfNullOperators = LintFixInfo(
    'prefer_if_null_operators',
    DartFixKind.CONVERT_TO_IF_NULL,
    "Convert to use '??'.",
    isPedantic: true,
  );

  static final preferInlinedAdds = LintFixInfo(
    'prefer_inlined_adds',
    DartFixKind.INLINE_INVOCATION,
    'Inline the invocation.',
  );

  static final preferIntLiterals = LintFixInfo(
    'prefer_int_literals',
    DartFixKind.CONVERT_TO_INT_LITERAL,
    'Convert to an int literal',
  );

  static final preferIsEmpty = LintFixInfo(
    'prefer_is_empty',
    DartFixKind.REPLACE_WITH_IS_EMPTY,
    "Convert to using 'isEmpty' when checking if a collection or iterable is empty.",
    isPedantic: true,
  );

  static final preferIsNotEmpty = LintFixInfo(
    'prefer_is_not_empty',
    DartFixKind.REPLACE_WITH_IS_NOT_EMPTY,
    "Convert to using 'isNotEmpty' when checking if a collection or iterable is not empty.",
    isPedantic: true,
  );

  static final preferIterableWhereType = LintFixInfo(
    'prefer_iterable_whereType',
    DartFixKind.CONVERT_TO_WHERE_TYPE,
    'Add a return type where possible.',
    isPedantic: true,
  );

  static final preferNullAwareOperators = LintFixInfo(
    'prefer_null_aware_operators',
    DartFixKind.CONVERT_TO_NULL_AWARE,
    "Convert to use '?.'.",
  );

  static final preferRelativeImports = LintFixInfo(
    'prefer_relative_imports',
    DartFixKind.CONVERT_TO_RELATIVE_IMPORT,
    'Convert to a relative import.',
  );

  static final preferSingleQuotes = LintFixInfo(
    'prefer_single_quotes',
    DartFixKind.CONVERT_TO_SINGLE_QUOTED_STRING,
    'Convert strings using a double quote to use a single quote.',
    isPedantic: true,
  );

  static final preferSpreadCollections = LintFixInfo(
    'prefer_spread_collections',
    // TODO(brianwilkerson) There are two possible fixes here, but not under
    //  user control.
    DartFixKind.CONVERT_TO_SPREAD,
    'Convert to a spread operator.',

    isPedantic: true,
  );

  static final slashForDocComments = LintFixInfo(
    'slash_for_doc_comments',
    DartFixKind.CONVERT_TO_LINE_COMMENT,
    'Convert to a line comment.',
    isPedantic: true,
  );

  static final sortChildPropertiesLast = LintFixInfo(
    'sort_child_properties_last',
    DartFixKind.SORT_CHILD_PROPERTY_LAST,
    "Move the 'child' argument to the end of the argument list.",
  );

  static final typeAnnotatePublicApis = LintFixInfo(
    'type_annotate_public_apis',
    DartFixKind.ADD_TYPE_ANNOTATION,
    'Add a type annotation.',
  );

  static final typeInitFormals = LintFixInfo(
    'type_init_formals',
    DartFixKind.REMOVE_TYPE_ANNOTATION,
    'Remove the type annotation.',
    isPedantic: true,
  );

  static final unawaitedFutures = LintFixInfo(
    'unawaited_futures',
    DartFixKind.ADD_AWAIT,
    'Add await.',
    isPedantic: true,
  );

  static final unnecessaryBraceInStringInterps = LintFixInfo(
    'unnecessary_brace_in_string_interps',
    DartFixKind.REMOVE_INTERPOLATION_BRACES,
    'Remove the unnecessary interpolation braces.',
  );

  static final unnecessaryConst = LintFixInfo(
    'unnecessary_const',
    DartFixKind.REMOVE_UNNECESSARY_CONST,
    "Remove unnecessary 'const'' keywords.",
    isPedantic: true,
  );

  static final unnecessaryLambdas = LintFixInfo(
    'unnecessary_lambdas',
    DartFixKind.REPLACE_WITH_TEAR_OFF,
    'Replace the function literal with a tear-off.',
  );

  static final unnecessaryNew = LintFixInfo(
    'unnecessary_new',
    DartFixKind.REMOVE_UNNECESSARY_NEW,
    "Remove unnecessary 'new' keywords.",
    isPedantic: true,
  );

  static final unnecessaryNullInIfNullOperators = LintFixInfo(
    'unnecessary_null_in_if_null_operators',
    DartFixKind.REMOVE_IF_NULL_OPERATOR,
    "Remove the '??' operator.",
    isPedantic: true,
  );

  static final unnecessaryOverrides = LintFixInfo(
    'unnecessary_overrides',
    DartFixKind.REMOVE_METHOD_DECLARATION,
    'Remove the unnecessary override.',
  );

  static final unnecessaryThis = LintFixInfo(
    'unnecessary_this',
    DartFixKind.REMOVE_THIS_EXPRESSION,
    'Remove this.',
    isPedantic: true,
  );

  static final useFunctionTypeSyntaxForParameters = LintFixInfo(
    'use_function_type_syntax_for_parameters',
    DartFixKind.CONVERT_TO_GENERIC_FUNCTION_SYNTAX,
    "Convert into 'Function' syntax",
    isPedantic: true,
  );

  static final useRethrowWhenPossible = LintFixInfo(
    'use_rethrow_when_possible',
    DartFixKind.USE_RETHROW,
    'Replace with rethrow.',
    isPedantic: true,
  );

  /// The name of the lint to be fixed.
  final String lintName;

  /// The kind of fix to be applied.
  final FixKind fixKind;

  /// Initialize a newly created set of fix information.
  LintFixInfo(
    this.lintName,
    this.fixKind,
    String description, {
    bool isPedantic = false,
  }) : super(lintName, description, null, isPedantic: isPedantic);

  @override
  void setup(DartFixRegistrar registrar, DartFixListener listener,
      EditDartfixParams params) {
    registrar.registerLintTask(
        Registry.ruleRegistry[lintName], FixLintTask(listener));
  }
}
