// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart'
    show DartFix, EditDartfixParams;
import 'package:analysis_server/src/edit/edit_dartfix.dart';
import 'package:analysis_server/src/edit/fix/basic_fix_lint_assist_task.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/dartfix_registrar.dart';
import 'package:analysis_server/src/edit/fix/fix_error_task.dart';
import 'package:analysis_server/src/edit/fix/fix_lint_task.dart';
import 'package:analysis_server/src/edit/fix/non_nullable_fix.dart';
import 'package:analysis_server/src/edit/fix/prefer_mixin_fix.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

final allFixes = <DartFixInfo>[
  //
  // Required fixes due to errors or upcoming language changes
  //
  DartFixInfo(
    'fix-named-constructor-type-arguments',
    '''
Move named constructor type arguments from the name to the type.

For example, this
  new List.filled<String>(20, 'value');

will be converted to
  new List<String>.filled(20, 'value');''',
    FixErrorTask.fixNamedConstructorTypeArgs,
    isRequired: true,
  ),
  DartFixInfo(
    'use-mixin',
    '''
Convert classes used as a mixin to the new mixin syntax.

For example, this
  class C with M { }
  class M { }

will be converted to
  class C with M { }
  mixin M { }

There are several situations where a class cannot be automatically converted
to a mixin such as when the class contains a constructor. In that situation
a message is displayed and the class is not converted to a mixin.''',
    PreferMixinFix.task,
    isRequired: true,
  ),
  //
  // Pedantic lint fixes.
  //
  // TODO(brianwilkerson) The commented out fixes below involve potentially
  //  non-local changes, so they can't currently be applied together. I have an
  //  idea for how to update FixProcessor to support these fixes.
//  LintFixInfo.alwaysDeclareReturnTypes,
//  LintFixInfo.alwaysRequireNonNullNamedParameters,
  LintFixInfo.annotateOverrides,
  LintFixInfo.avoidEmptyElse,
  LintFixInfo.avoidInitToNull,
  LintFixInfo.avoidRelativeLibImports,
  LintFixInfo.avoidReturnTypesOnSetters,
  LintFixInfo.curlyBracesInFlowControlStructures,
  LintFixInfo.emptyCatches,
  LintFixInfo.emptyConstructorBodies,
  LintFixInfo.noDuplicateCaseValues,
  LintFixInfo.nullClosures,
  LintFixInfo.omitLocalVariableTypes,
  LintFixInfo.preferAdjacentStringConcatenation,
  LintFixInfo.preferConditionalAssignment,
  LintFixInfo.preferEqualForDefaultValues,
  LintFixInfo.preferFinalFields,
  LintFixInfo.preferForElementsToMapFromIterable,
  LintFixInfo.preferGenericFunctionTypeAliases,
  LintFixInfo.preferIfNullOperators,
  LintFixInfo.preferIsEmpty,
  LintFixInfo.preferIsNotEmpty,
  LintFixInfo.preferSingleQuotes,
  LintFixInfo.preferSpreadCollections,
  LintFixInfo.slashForDocComments,
  LintFixInfo.typeInitFormals,
  LintFixInfo.unawaitedFutures,
  LintFixInfo.unnecessaryConst,
  LintFixInfo.unnecessaryNew,
  LintFixInfo.unnecessaryThis,
  LintFixInfo.useRethrowWhenPossible,
  //
  // Other fixes
  //
  DartFixInfo(
    'double-to-int',
    '''
Find double literals ending in .0 and remove the .0
wherever double context can be inferred.

For example, this
  const double myDouble = 8.0;

will be converted to
  const double myDouble = 8;''',
    BasicFixLintAssistTask.preferIntLiterals,
    isDefault: false,
  ),
  DartFixInfo(
    'use-spread-collections',
    '''
Convert to using collection spread operators.

For example, this
  var l1 = ['b'];
  var l2 = ['a']..addAll(l1);

will be converted to
  var l1 = ['b'];
  var l2 = ['a', ...l1];''',
    BasicFixLintAssistTask.preferSpreadCollections,
    isDefault: false,
  ),
  DartFixInfo(
    'collection-if-elements',
    '''
Convert to using if elements when building collections.

For example, this
  f(bool b) => ['a', b ? 'c' : 'd', 'e'];

will be converted to
  f(bool b) => ['a', if (b) 'c' else 'd', 'e'];''',
    BasicFixLintAssistTask.preferIfElementsToConditionalExpressions,
    isDefault: false,
  ),
  DartFixInfo(
    'map-for-elements',
    '''
Convert to for elements when building maps from iterables.

For example, this
  Map<int, int>.fromIterable([1, 2, 3], key: (i) => i, value: (i) => i * 2)

will be converted to
  <int, int>{ for(int i in [1, 2, 3]) i : i * 2, }''',
    BasicFixLintAssistTask.preferForElementsToMapFromIterable,
    isDefault: false,
  ),
  //
  // Experimental fixes
  //
  DartFixInfo(
    'non-nullable',
    // TODO(danrubel) update description and make default/required
    // when NNBD fix is ready
    '''
EXPERIMENTAL: Update sources to be non-nullable by default.
This requires the experimental non-nullable flag to be enabled
when running the updated application.''',
    NonNullableFix.task,
    isDefault: false,
  ),
];

/// [DartFixInfo] represents a fix that can be applied by [EditDartFix].
class DartFixInfo {
  /// The key provided on the command line via the `--fix` option to refer to
  /// this fix.
  final String key;

  /// A description of the fix, printed by the `--help` option.
  final String description;

  /// A flag indicating whether this fix is in the default set of fixes.
  final bool isDefault;

  /// A flag indicating whether this fix is related to the lints in the pedantic
  /// lint set.
  final bool isPedantic;

  /// A flag indicating whether this fix is in the set of required fixes.
  final bool isRequired;

  final void Function(DartFixRegistrar registrar, DartFixListener listener,
      EditDartfixParams params) _setup;

  const DartFixInfo(
    this.key,
    this.description,
    this._setup, {
    this.isDefault = true,
    this.isRequired = false,
    this.isPedantic = false,
  });

  /// Return a newly created fix generated from this fix info.
  DartFix asDartFix() =>
      DartFix(key, description: description, isRequired: isRequired);

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
  // prefer_collection_literals
  // prefer_contains
  // prefer_iterable_whereType
  // recursive_getters
  // unnecessary_null_in_if_null_operators
  // unrelated_type_equality_checks
  // use_function_type_syntax_for_parameters
  // valid_regexps

  static final alwaysDeclareReturnTypes = LintFixInfo(
      'always_declare_return_types',
      DartFixKind.ADD_RETURN_TYPE,
      'Add a return type where possible.',
      isPedantic: true);

  static final alwaysRequireNonNullNamedParameters = LintFixInfo(
      'always_require_non_null_named_parameters',
      DartFixKind.ADD_REQUIRED,
      'Add an @required annotation.',
      isPedantic: true);

  static final annotateOverrides = LintFixInfo('annotate_overrides',
      DartFixKind.ADD_OVERRIDE, 'Add an @override annotation.',
      isPedantic: true);

  static final avoidEmptyElse = LintFixInfo('avoid_empty_else',
      DartFixKind.REMOVE_EMPTY_ELSE, 'Remove the empty else.',
      isPedantic: true);

  static final avoidInitToNull = LintFixInfo('avoid_init_to_null',
      DartFixKind.REMOVE_INITIALIZER, 'Remove the initializer.',
      isPedantic: true);

  static final avoidRelativeLibImports = LintFixInfo(
      'avoid_relative_lib_imports',
      DartFixKind.CONVERT_TO_PACKAGE_IMPORT,
      'Convert the import to a package: import.',
      isPedantic: true);

  static final avoidReturnTypesOnSetters = LintFixInfo(
      'avoid_return_types_on_setters',
      DartFixKind.REMOVE_TYPE_ANNOTATION,
      'Remove the return type.',
      isPedantic: true);

  static final curlyBracesInFlowControlStructures = LintFixInfo(
      'curly_braces_in_flow_control_structures',
      DartFixKind.ADD_CURLY_BRACES,
      'Add curly braces.',
      isPedantic: true);

  static final emptyCatches = LintFixInfo('empty_catches',
      DartFixKind.REMOVE_EMPTY_CATCH, 'Remove the empty catch clause.',
      isPedantic: true);

  static final emptyConstructorBodies = LintFixInfo(
      'empty_constructor_bodies',
      DartFixKind.REMOVE_EMPTY_CONSTRUCTOR_BODY,
      'Remove the empoty catch clause.',
      isPedantic: true);

  static final noDuplicateCaseValues = LintFixInfo('no_duplicate_case_values',
      DartFixKind.REMOVE_DUPLICATE_CASE, 'Remove the duplicate case clause.',
      isPedantic: true);

  static final nullClosures = LintFixInfo(
    'null_closures',
    DartFixKind.REPLACE_NULL_WITH_CLOSURE,
    '''
Convert nulls to closures that return null where expected.

For example, this
  [1, 3, 5].firstWhere((e) => e.isOdd, orElse: null);

will be converted to
  [1, 3, 5].firstWhere((e) => e.isOdd, orElse: () => null);''',
    isPedantic: true,
  );

  static final omitLocalVariableTypes = LintFixInfo('omit_local_variable_types',
      DartFixKind.REPLACE_WITH_VAR, "Replace the type annotation with 'var'",
      isPedantic: true);

  static final preferAdjacentStringConcatenation = LintFixInfo(
      'prefer_adjacent_string_concatenation',
      DartFixKind.REMOVE_OPERATOR,
      "Remove the '+' operator.",
      isPedantic: true);

  static final preferConditionalAssignment = LintFixInfo(
      'prefer_conditional_assignment',
      DartFixKind.REPLACE_WITH_CONDITIONAL_ASSIGNMENT,
      'Replace with a conditional assignment.',
      isPedantic: true);

  static final preferEqualForDefaultValues = LintFixInfo(
    'prefer_equal_for_default_values',
    DartFixKind.REPLACE_COLON_WITH_EQUALS,
    '''
Convert declarations to use = to separate a named parameter from its default value.

For example, this
  f({a: 1}) { }

will be converted to
  f({a = 1}) { }''',
    isPedantic: true,
  );

  static final preferFinalFields = LintFixInfo(
      'prefer_final_fields', DartFixKind.MAKE_FINAL, 'Make the field final.',
      isPedantic: true);

  static final preferForElementsToMapFromIterable = LintFixInfo(
      'prefer_for_elements_to_map_fromIterable',
      DartFixKind.CONVERT_TO_FOR_ELEMENT,
      'Convert to a for element.',
      isPedantic: true);

  static final preferGenericFunctionTypeAliases = LintFixInfo(
      'prefer_generic_function_type_aliases',
      DartFixKind.CONVERT_TO_GENERIC_FUNCTION_SYNTAX,
      "Convert into 'Function' syntax",
      isPedantic: true);

  static final preferIfNullOperators = LintFixInfo('prefer_if_null_operators',
      DartFixKind.CONVERT_TO_IF_NULL, "Convert to use '??'.",
      isPedantic: true);

  static final preferIsEmpty = LintFixInfo(
    'prefer_is_empty',
    DartFixKind.REPLACE_WITH_IS_EMPTY,
    '''
Convert to using 'isEmpty' when checking if a collection or iterable is empty.

For example, this
  if (lunchBox.length == 0) return 'so hungry...';

will be converted to
  if (lunchBox.isEmpty) return 'so hungry...';''',
    isDefault: false,
    isPedantic: true,
  );

  static final preferIsNotEmpty = LintFixInfo(
    'prefer_is_not_empty',
    DartFixKind.REPLACE_WITH_IS_NOT_EMPTY,
    '''
Convert to using 'isNotEmpty' when checking if a collection or iterable is not empty.

For example, this
  if (words.length != 0) return words.join(' ');

will be converted to
  if (words.isNotEmpty) return words.join(' ');''',
    isDefault: false,
    isPedantic: true,
  );

  static final preferSingleQuotes = LintFixInfo(
    'prefer_single_quotes',
    DartFixKind.CONVERT_TO_SINGLE_QUOTED_STRING,
    '''
Convert strings using a dobule quote to use a single quote.''',
    isDefault: false,
    isPedantic: true,
  );

  static final preferSpreadCollections = LintFixInfo(
      'prefer_spread_collections',
      // TODO(brianwilkerson) There are two possible fixes here, but not under
      //  user control.
      DartFixKind.CONVERT_TO_SPREAD,
      'Convert to a spread operator.',
      isPedantic: true);

  static final slashForDocComments = LintFixInfo('slash_for_doc_comments',
      DartFixKind.CONVERT_TO_LINE_COMMENT, 'Convert to a line comment.',
      isPedantic: true);

  static final typeInitFormals = LintFixInfo('type_init_formals',
      DartFixKind.REMOVE_TYPE_ANNOTATION, 'Remove the type annotation.',
      isPedantic: true);

  static final unawaitedFutures = LintFixInfo(
      'unawaited_futures', DartFixKind.ADD_AWAIT, 'Add await.',
      isPedantic: true);

  static final unnecessaryConst = LintFixInfo(
    'unnecessary_const',
    DartFixKind.REMOVE_UNNECESSARY_CONST,
    '''
Remove unnecessary `const` keywords.

For example, this
  static const digits = const ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

will be converted to
  static const digits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];''',
    isDefault: false,
    isPedantic: true,
  );

  static final unnecessaryNew = LintFixInfo(
    'unnecessary_new',
    DartFixKind.REMOVE_UNNECESSARY_NEW,
    '''
Remove unnecessary `new` keywords.

For example, this
  var marker = new Object();

will be converted to
  var marker = Object();''',
    isDefault: false,
    isPedantic: true,
  );

  static final unnecessaryThis = LintFixInfo(
      'unnecessary_this', DartFixKind.REMOVE_THIS_EXPRESSION, 'Remove this.',
      isPedantic: true);

  static final useRethrowWhenPossible = LintFixInfo('use_rethrow_when_possible',
      DartFixKind.USE_RETHROW, 'Replace with rethrow.',
      isPedantic: true);

  /// The name of the lint to be fixed.
  final String lintName;

  /// The kind of fix to be applied.
  final FixKind fixKind;

  /// Initialize a newly created set of fix information.
  LintFixInfo(
    this.lintName,
    this.fixKind,
    String description, {
    bool isDefault = true,
    bool isRequired = false,
    bool isPedantic = false,
  }) : super(lintName.replaceAll('_', '-'), description, null,
            isDefault: isDefault,
            isRequired: isRequired,
            isPedantic: isPedantic);

  @override
  void setup(DartFixRegistrar registrar, DartFixListener listener,
      EditDartfixParams params) {
    registrar.registerLintTask(
        Registry.ruleRegistry[lintName], FixLintTask(listener));
  }
}
