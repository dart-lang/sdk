// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'analyzer.dart';
import 'rules/always_declare_return_types.dart';
import 'rules/always_put_control_body_on_new_line.dart';
import 'rules/always_put_required_named_parameters_first.dart';
import 'rules/always_require_non_null_named_parameters.dart';
import 'rules/always_specify_types.dart';
import 'rules/always_use_package_imports.dart';
import 'rules/annotate_overrides.dart';
import 'rules/avoid_annotating_with_dynamic.dart';
import 'rules/avoid_as.dart';
import 'rules/avoid_bool_literals_in_conditional_expressions.dart';
import 'rules/avoid_catches_without_on_clauses.dart';
import 'rules/avoid_catching_errors.dart';
import 'rules/avoid_classes_with_only_static_members.dart';
import 'rules/avoid_double_and_int_checks.dart';
import 'rules/avoid_dynamic_calls.dart';
import 'rules/avoid_empty_else.dart';
import 'rules/avoid_equals_and_hash_code_on_mutable_classes.dart';
import 'rules/avoid_escaping_inner_quotes.dart';
import 'rules/avoid_field_initializers_in_const_classes.dart';
import 'rules/avoid_final_parameters.dart';
import 'rules/avoid_function_literals_in_foreach_calls.dart';
import 'rules/avoid_implementing_value_types.dart';
import 'rules/avoid_init_to_null.dart';
import 'rules/avoid_js_rounded_ints.dart';
import 'rules/avoid_multiple_declarations_per_line.dart';
import 'rules/avoid_null_checks_in_equality_operators.dart';
import 'rules/avoid_positional_boolean_parameters.dart';
import 'rules/avoid_print.dart';
import 'rules/avoid_private_typedef_functions.dart';
import 'rules/avoid_redundant_argument_values.dart';
import 'rules/avoid_relative_lib_imports.dart';
import 'rules/avoid_renaming_method_parameters.dart';
import 'rules/avoid_return_types_on_setters.dart';
import 'rules/avoid_returning_null.dart';
import 'rules/avoid_returning_null_for_future.dart';
import 'rules/avoid_returning_null_for_void.dart';
import 'rules/avoid_returning_this.dart';
import 'rules/avoid_setters_without_getters.dart';
import 'rules/avoid_shadowing_type_parameters.dart';
import 'rules/avoid_single_cascade_in_expression_statements.dart';
import 'rules/avoid_slow_async_io.dart';
import 'rules/avoid_type_to_string.dart';
import 'rules/avoid_types_as_parameter_names.dart';
import 'rules/avoid_types_on_closure_parameters.dart';
import 'rules/avoid_unnecessary_containers.dart';
import 'rules/avoid_unused_constructor_parameters.dart';
import 'rules/avoid_void_async.dart';
import 'rules/avoid_web_libraries_in_flutter.dart';
import 'rules/await_only_futures.dart';
import 'rules/camel_case_extensions.dart';
import 'rules/camel_case_types.dart';
import 'rules/cancel_subscriptions.dart';
import 'rules/cascade_invocations.dart';
import 'rules/cast_nullable_to_non_nullable.dart';
import 'rules/close_sinks.dart';
import 'rules/collection_methods_unrelated_type.dart';
import 'rules/combinators_ordering.dart';
import 'rules/comment_references.dart';
import 'rules/conditional_uri_does_not_exist.dart';
import 'rules/constant_identifier_names.dart';
import 'rules/control_flow_in_finally.dart';
import 'rules/curly_braces_in_flow_control_structures.dart';
import 'rules/dangling_library_doc_comments.dart';
import 'rules/deprecated_consistency.dart';
import 'rules/deprecated_member_use_from_same_package.dart';
import 'rules/diagnostic_describe_all_properties.dart';
import 'rules/directives_ordering.dart';
import 'rules/discarded_futures.dart';
import 'rules/do_not_use_environment.dart';
import 'rules/empty_catches.dart';
import 'rules/empty_constructor_bodies.dart';
import 'rules/empty_statements.dart';
import 'rules/enable_null_safety.dart';
import 'rules/eol_at_end_of_file.dart';
import 'rules/exhaustive_cases.dart';
import 'rules/file_names.dart';
import 'rules/flutter_style_todos.dart';
import 'rules/hash_and_equals.dart';
import 'rules/implementation_imports.dart';
import 'rules/implicit_call_tearoffs.dart';
import 'rules/implicit_reopen.dart';
import 'rules/invalid_case_patterns.dart';
import 'rules/invariant_booleans.dart';
import 'rules/iterable_contains_unrelated_type.dart';
import 'rules/join_return_with_assignment.dart';
import 'rules/leading_newlines_in_multiline_strings.dart';
import 'rules/library_annotations.dart';
import 'rules/library_names.dart';
import 'rules/library_prefixes.dart';
import 'rules/library_private_types_in_public_api.dart';
import 'rules/lines_longer_than_80_chars.dart';
import 'rules/list_remove_unrelated_type.dart';
import 'rules/literal_only_boolean_expressions.dart';
import 'rules/matching_super_parameters.dart';
import 'rules/missing_whitespace_between_adjacent_strings.dart';
import 'rules/no_adjacent_strings_in_list.dart';
import 'rules/no_default_cases.dart';
import 'rules/no_duplicate_case_values.dart';
import 'rules/no_leading_underscores_for_library_prefixes.dart';
import 'rules/no_leading_underscores_for_local_identifiers.dart';
import 'rules/no_literal_bool_comparisons.dart';
import 'rules/no_logic_in_create_state.dart';
import 'rules/no_runtimeType_toString.dart';
import 'rules/no_self_assignments.dart';
import 'rules/no_wildcard_variable_uses.dart';
import 'rules/non_constant_identifier_names.dart';
import 'rules/noop_primitive_operations.dart';
import 'rules/null_check_on_nullable_type_parameter.dart';
import 'rules/null_closures.dart';
import 'rules/omit_local_variable_types.dart';
import 'rules/one_member_abstracts.dart';
import 'rules/only_throw_errors.dart';
import 'rules/overridden_fields.dart';
import 'rules/package_api_docs.dart';
import 'rules/package_prefixed_library_names.dart';
import 'rules/parameter_assignments.dart';
import 'rules/prefer_adjacent_string_concatenation.dart';
import 'rules/prefer_asserts_in_initializer_lists.dart';
import 'rules/prefer_asserts_with_message.dart';
import 'rules/prefer_bool_in_asserts.dart';
import 'rules/prefer_collection_literals.dart';
import 'rules/prefer_conditional_assignment.dart';
import 'rules/prefer_const_constructors.dart';
import 'rules/prefer_const_constructors_in_immutables.dart';
import 'rules/prefer_const_declarations.dart';
import 'rules/prefer_const_literals_to_create_immutables.dart';
import 'rules/prefer_constructors_over_static_methods.dart';
import 'rules/prefer_contains.dart';
import 'rules/prefer_double_quotes.dart';
import 'rules/prefer_equal_for_default_values.dart';
import 'rules/prefer_expression_function_bodies.dart';
import 'rules/prefer_final_fields.dart';
import 'rules/prefer_final_in_for_each.dart';
import 'rules/prefer_final_locals.dart';
import 'rules/prefer_final_parameters.dart';
import 'rules/prefer_for_elements_to_map_fromIterable.dart';
import 'rules/prefer_foreach.dart';
import 'rules/prefer_function_declarations_over_variables.dart';
import 'rules/prefer_generic_function_type_aliases.dart';
import 'rules/prefer_if_elements_to_conditional_expressions.dart';
import 'rules/prefer_if_null_operators.dart';
import 'rules/prefer_initializing_formals.dart';
import 'rules/prefer_inlined_adds.dart';
import 'rules/prefer_int_literals.dart';
import 'rules/prefer_interpolation_to_compose_strings.dart';
import 'rules/prefer_is_empty.dart';
import 'rules/prefer_is_not_empty.dart';
import 'rules/prefer_is_not_operator.dart';
import 'rules/prefer_iterable_whereType.dart';
import 'rules/prefer_mixin.dart';
import 'rules/prefer_null_aware_method_calls.dart';
import 'rules/prefer_null_aware_operators.dart';
import 'rules/prefer_relative_imports.dart';
import 'rules/prefer_single_quotes.dart';
import 'rules/prefer_spread_collections.dart';
import 'rules/prefer_typing_uninitialized_variables.dart';
import 'rules/prefer_void_to_null.dart';
import 'rules/provide_deprecation_message.dart';
import 'rules/pub/depend_on_referenced_packages.dart';
import 'rules/pub/package_names.dart';
import 'rules/pub/secure_pubspec_urls.dart';
import 'rules/pub/sort_pub_dependencies.dart';
import 'rules/public_member_api_docs.dart';
import 'rules/recursive_getters.dart';
import 'rules/require_trailing_commas.dart';
import 'rules/sized_box_for_whitespace.dart';
import 'rules/sized_box_shrink_expand.dart';
import 'rules/slash_for_doc_comments.dart';
import 'rules/sort_child_properties_last.dart';
import 'rules/sort_constructors_first.dart';
import 'rules/sort_unnamed_constructors_first.dart';
import 'rules/super_goes_last.dart';
import 'rules/test_types_in_equals.dart';
import 'rules/throw_in_finally.dart';
import 'rules/tighten_type_of_initializing_formals.dart';
import 'rules/type_annotate_public_apis.dart';
import 'rules/type_init_formals.dart';
import 'rules/type_literal_in_constant_pattern.dart';
import 'rules/unawaited_futures.dart';
import 'rules/unnecessary_await_in_return.dart';
import 'rules/unnecessary_brace_in_string_interps.dart';
import 'rules/unnecessary_breaks.dart';
import 'rules/unnecessary_const.dart';
import 'rules/unnecessary_constructor_name.dart';
import 'rules/unnecessary_final.dart';
import 'rules/unnecessary_getters_setters.dart';
import 'rules/unnecessary_lambdas.dart';
import 'rules/unnecessary_late.dart';
import 'rules/unnecessary_library_directive.dart';
import 'rules/unnecessary_new.dart';
import 'rules/unnecessary_null_aware_assignments.dart';
import 'rules/unnecessary_null_aware_operator_on_extension_on_nullable.dart';
import 'rules/unnecessary_null_checks.dart';
import 'rules/unnecessary_null_in_if_null_operators.dart';
import 'rules/unnecessary_nullable_for_final_variable_declarations.dart';
import 'rules/unnecessary_overrides.dart';
import 'rules/unnecessary_parenthesis.dart';
import 'rules/unnecessary_raw_strings.dart';
import 'rules/unnecessary_statements.dart';
import 'rules/unnecessary_string_escapes.dart';
import 'rules/unnecessary_string_interpolations.dart';
import 'rules/unnecessary_this.dart';
import 'rules/unnecessary_to_list_in_spreads.dart';
import 'rules/unreachable_from_main.dart';
import 'rules/unrelated_type_equality_checks.dart';
import 'rules/unsafe_html.dart';
import 'rules/use_build_context_synchronously.dart';
import 'rules/use_colored_box.dart';
import 'rules/use_decorated_box.dart';
import 'rules/use_enums.dart';
import 'rules/use_full_hex_values_for_flutter_colors.dart';
import 'rules/use_function_type_syntax_for_parameters.dart';
import 'rules/use_if_null_to_convert_nulls_to_bools.dart';
import 'rules/use_is_even_rather_than_modulo.dart';
import 'rules/use_key_in_widget_constructors.dart';
import 'rules/use_late_for_private_fields_and_variables.dart';
import 'rules/use_named_constants.dart';
import 'rules/use_raw_strings.dart';
import 'rules/use_rethrow_when_possible.dart';
import 'rules/use_setters_to_change_properties.dart';
import 'rules/use_string_buffers.dart';
import 'rules/use_string_in_part_of_directives.dart';
import 'rules/use_super_parameters.dart';
import 'rules/use_test_throws_matchers.dart';
import 'rules/use_to_and_as_if_applicable.dart';
import 'rules/valid_regexps.dart';
import 'rules/void_checks.dart';

void registerLintRules({bool inTestMode = false}) {
  Analyzer.facade.cacheLinterVersion();
  Analyzer.facade
    ..register(AlwaysDeclareReturnTypes())
    ..register(AlwaysPutControlBodyOnNewLine())
    ..register(AlwaysPutRequiredNamedParametersFirst())
    ..register(AlwaysRequireNonNullNamedParameters())
    ..register(AlwaysSpecifyTypes())
    ..register(AlwaysUsePackageImports())
    ..register(AnnotateOverrides())
    ..register(AvoidAnnotatingWithDynamic())
    ..register(AvoidAs())
    ..register(AvoidBoolLiteralsInConditionalExpressions())
    ..register(AvoidCatchesWithoutOnClauses())
    ..register(AvoidCatchingErrors())
    ..register(AvoidClassesWithOnlyStaticMembers())
    ..register(AvoidDoubleAndIntChecks())
    ..register(AvoidDynamicCalls())
    ..register(AvoidEmptyElse())
    ..register(AvoidEqualsAndHashCodeOnMutableClasses())
    ..register(AvoidEscapingInnerQuotes())
    ..register(AvoidFieldInitializersInConstClasses())
    ..register(AvoidFinalParameters())
    ..register(AvoidFunctionLiteralsInForeachCalls())
    ..register(AvoidImplementingValueTypes())
    ..register(AvoidInitToNull())
    ..register(AvoidJsRoundedInts())
    ..register(AvoidMultipleDeclarationsPerLine())
    ..register(AvoidNullChecksInEqualityOperators())
    ..register(AvoidPositionalBooleanParameters())
    ..register(AvoidPrint())
    ..register(AvoidPrivateTypedefFunctions())
    ..register(AvoidRedundantArgumentValues())
    ..register(AvoidRelativeLibImports())
    ..register(AvoidRenamingMethodParameters())
    ..register(AvoidReturnTypesOnSetters())
    ..register(AvoidReturningNull())
    ..register(AvoidReturningNullForFuture())
    ..register(AvoidReturningNullForVoid())
    ..register(AvoidReturningThis())
    ..register(AvoidSettersWithoutGetters())
    ..register(AvoidShadowingTypeParameters())
    ..register(AvoidSingleCascadeInExpressionStatements())
    ..register(AvoidSlowAsyncIo())
    ..register(AvoidTypeToString())
    ..register(AvoidTypesAsParameterNames())
    ..register(AvoidTypesOnClosureParameters())
    ..register(AvoidUnnecessaryContainers())
    ..register(AvoidUnusedConstructorParameters())
    ..register(AvoidVoidAsync())
    ..register(AvoidWebLibrariesInFlutter())
    ..register(AwaitOnlyFutures())
    ..register(CamelCaseExtensions())
    ..register(CamelCaseTypes())
    ..register(CancelSubscriptions())
    ..register(CascadeInvocations())
    ..register(CastNullableToNonNullable())
    ..register(CloseSinks())
    ..register(CollectionMethodsUnrelatedType())
    ..register(CombinatorsOrdering())
    ..register(CommentReferences())
    ..register(ConditionalUriDoesNotExist())
    ..register(ConstantIdentifierNames())
    ..register(ControlFlowInFinally())
    ..register(CurlyBracesInFlowControlStructures())
    ..register(DanglingLibraryDocComments())
    ..register(DependOnReferencedPackages())
    ..register(DeprecatedConsistency())
    ..register(DeprecatedMemberUseFromSamePackage())
    ..register(DiagnosticDescribeAllProperties())
    ..register(DirectivesOrdering())
    ..register(DiscardedFutures())
    ..register(DoNotUseEnvironment())
    ..register(EmptyCatches())
    ..register(EmptyConstructorBodies())
    ..register(EmptyStatements())
    ..register(EnableNullSafety())
    ..register(EolAtEndOfFile())
    ..register(ExhaustiveCases())
    ..register(FileNames())
    ..register(FlutterStyleTodos())
    ..register(HashAndEquals())
    ..register(ImplementationImports())
    ..register(ImplicitCallTearoffs())
    ..register(ImplicitReopen())
    ..register(InvalidCasePatterns())
    ..register(InvariantBooleans())
    ..register(IterableContainsUnrelatedType())
    ..register(JoinReturnWithAssignment())
    ..register(LeadingNewlinesInMultilineStrings())
    ..register(LibraryAnnotations())
    ..register(LibraryNames())
    ..register(LibraryPrefixes())
    ..register(LibraryPrivateTypesInPublicApi())
    ..register(LinesLongerThan80Chars())
    ..register(ListRemoveUnrelatedType())
    ..register(LiteralOnlyBooleanExpressions())
    ..register(MatchingSuperParameters())
    ..register(MissingWhitespaceBetweenAdjacentStrings())
    ..register(NoAdjacentStringsInList())
    ..register(NoDefaultCases())
    ..register(NoDuplicateCaseValues())
    ..register(NoLeadingUnderscoresForLibraryPrefixes())
    ..register(NoLeadingUnderscoresForLocalIdentifiers())
    ..register(NoLiteralBoolComparisons())
    ..register(NoLogicInCreateState())
    ..register(NoRuntimeTypeToString())
    ..register(NoSelfAssignments())
    ..register(NoWildcardVariableUses())
    ..register(NonConstantIdentifierNames())
    ..register(NoopPrimitiveOperations())
    ..register(NullCheckOnNullableTypeParameter())
    ..register(NullClosures())
    ..register(OmitLocalVariableTypes())
    ..register(OneMemberAbstracts())
    ..register(OnlyThrowErrors())
    ..register(OverriddenFields())
    ..register(PackageApiDocs())
    ..register(PackageNames())
    ..register(PackagePrefixedLibraryNames())
    ..register(ParameterAssignments())
    ..register(PreferAdjacentStringConcatenation())
    ..register(PreferAssertsInInitializerLists())
    ..register(PreferAssertsWithMessage())
    ..register(PreferBoolInAsserts())
    ..register(PreferCollectionLiterals())
    ..register(PreferConditionalAssignment())
    ..register(PreferConstConstructors())
    ..register(PreferConstConstructorsInImmutables())
    ..register(PreferConstDeclarations())
    ..register(PreferConstLiteralsToCreateImmutables())
    ..register(PreferConstructorsOverStaticMethods())
    ..register(PreferContains())
    ..register(PreferDoubleQuotes())
    ..register(PreferEqualForDefaultValues())
    ..register(PreferExpressionFunctionBodies())
    ..register(PreferFinalFields())
    ..register(PreferFinalInForEach())
    ..register(PreferFinalLocals())
    ..register(PreferFinalParameters())
    ..register(PreferForElementsToMapFromIterable())
    ..register(PreferForeach())
    ..register(PreferFunctionDeclarationsOverVariables())
    ..register(PreferGenericFunctionTypeAliases())
    ..register(PreferIfElementsToConditionalExpressions())
    ..register(PreferIfNullOperators())
    ..register(PreferInitializingFormals())
    ..register(PreferInlinedAdds())
    ..register(PreferIntLiterals())
    ..register(PreferInterpolationToComposeStrings())
    ..register(PreferIsEmpty())
    ..register(PreferIsNotEmpty())
    ..register(PreferIsNotOperator())
    ..register(PreferIterableWhereType())
    ..register(PreferMixin())
    ..register(PreferNullAwareMethodCalls())
    ..register(PreferNullAwareOperators())
    ..register(PreferRelativeImports())
    ..register(PreferSingleQuotes())
    ..register(PreferSpreadCollections())
    ..register(PreferTypingUninitializedVariables())
    ..register(PreferVoidToNull())
    ..register(ProvideDeprecationMessage())
    ..register(PublicMemberApiDocs())
    ..register(RecursiveGetters())
    ..register(RequireTrailingCommas())
    ..register(SecurePubspecUrls())
    ..register(SizedBoxForWhitespace())
    ..register(SizedBoxShrinkExpand())
    ..register(SlashForDocComments())
    ..register(SortChildPropertiesLast())
    ..register(SortConstructorsFirst())
    ..register(SortPubDependencies())
    ..register(SortUnnamedConstructorsFirst())
    ..register(SuperGoesLast())
    ..register(TestTypesInEquals())
    ..register(ThrowInFinally())
    ..register(TightenTypeOfInitializingFormals())
    ..register(TypeAnnotatePublicApis())
    ..register(TypeInitFormals())
    ..register(TypeLiteralInConstantPattern())
    ..register(UnawaitedFutures())
    ..register(UnnecessaryAwaitInReturn())
    ..register(UnnecessaryBraceInStringInterps())
    ..register(UnnecessaryBreaks())
    ..register(UnnecessaryConst())
    ..register(UnnecessaryConstructorName())
    ..register(UnnecessaryFinal())
    ..register(UnnecessaryGettersSetters())
    ..register(UnnecessaryLambdas())
    ..register(UnnecessaryLate())
    ..register(UnnecessaryLibraryDirective())
    ..register(UnnecessaryNew())
    ..register(UnnecessaryNullAwareAssignments())
    ..register(UnnecessaryNullAwareOperatorOnExtensionOnNullable())
    ..register(UnnecessaryNullChecks())
    ..register(UnnecessaryNullInIfNullOperators())
    ..register(UnnecessaryNullableForFinalVariableDeclarations())
    ..register(UnnecessaryOverrides())
    ..register(UnnecessaryParenthesis())
    ..register(UnnecessaryRawStrings())
    ..register(UnnecessaryStatements())
    ..register(UnnecessaryStringEscapes())
    ..register(UnnecessaryStringInterpolations())
    ..register(UnnecessaryThis())
    ..register(UnnecessaryToListInSpreads())
    ..register(UnreachableFromMain())
    ..register(UnrelatedTypeEqualityChecks())
    ..register(UnsafeHtml())
    ..register(UseBuildContextSynchronously(inTestMode: inTestMode))
    ..register(UseColoredBox())
    ..register(UseDecoratedBox())
    ..register(UseEnums())
    ..register(UseFullHexValuesForFlutterColors())
    ..register(UseFunctionTypeSyntaxForParameters())
    ..register(UseIfNullToConvertNullsToBools())
    ..register(UseIsEvenRatherThanModulo())
    ..register(UseKeyInWidgetConstructors())
    ..register(UseLateForPrivateFieldsAndVariables())
    ..register(UseNamedConstants())
    ..register(UseRawStrings())
    ..register(UseRethrowWhenPossible())
    ..register(UseSettersToChangeProperties())
    ..register(UseStringBuffers())
    ..register(UseStringInPartOfDirectives())
    ..register(UseSuperParameters())
    ..register(UseTestThrowsMatchers())
    ..register(UseToAndAsIfApplicable())
    ..register(ValidRegexps())
    ..register(VoidChecks());
}
