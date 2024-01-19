# main

- removed lint: `always_require_non_null_named_parameters`
- removed lint: `avoid_returning_null`
- removed lint: `avoid_returning_null_for_future`
- removed lint: `iterable_contains_unrelated_type`
- removed lint: `list_remove_unrelated_type`

# 3.2.0

- new lint: `annotate_redeclares` (experimental)
- stable: `use_build_context_synchronously`

# 3.1.0

- new lint: `no_self_assignments`
- new lint: `no_wildcard_variable_uses`

# 3.0.0

- new lint: `implicit_reopen`
- new lint: `unnecessary_breaks`
- new lint: `type_literal_in_constant_pattern`
- new lint: `invalid_case_patterns`
- new lint: `matching_super_parameters`
- new lint: `no_literal_bool_comparisons`

- removed lint: `enable_null_safety`
- removed lint: `invariant_booleans`
- removed lint: `prefer_bool_in_asserts`
- removed lint: `prefer_equal_for_default_values`
- removed lint: `super_goes_last`

---

# 1.35.0

- add new lints: 
  - `implicit_reopen`
  - `unnecessary_breaks`
  - `type_literal_in_constant_pattern`
- updates to existing lints to support patterns and class modifiers
- remove support for:
  - `enable_null_safety`
  - `invariant_booleans`
  - `prefer_bool_in_asserts`
  - `prefer_equal_for_default_values`
  - `super_goes_last`
- fix `unnecessary_parenthesis` false-positives with null-aware expressions
- fix `void_checks` to allow assignments of `Future<dynamic>?` to parameters
  typed `FutureOr<void>?`
- fix `use_build_context_synchronously` in if conditions
- fix a false positive for `avoid_private_typedef_functions` with generalized
  type aliases
- update `unnecessary_parenthesis` to detect some doubled parens
- update `void_checks` to allow returning `Never` as void
- update `no_adjacent_strings_in_list` to support set literals and for- and
  if-elements
- update `avoid_types_as_parameter_names` to handle type variables
- update `avoid_positional_boolean_parameters` to handle typedefs
- update `avoid_redundant_argument_values` to check parameters of redirecting
  constructors
- improve performance for `prefer_const_literals_to_create_immutables`
- update `use_build_context_synchronously` to check context properties
- improve `unnecessary_parenthesis` support for property accesses and method
  invocations

# 1.34.0

- update `only_throw_errors` to not report on values of type `Never`
- update `prefer_mixin` to handle class mixins
- update `unnecessary_null_checks` to ignore `Future.value` and 
  `Completer.complete`
- fix `unnecessary_parenthesis` false positives on constant patterns
- new lint: `invalid_case_patterns`
- update `unnecessary_const` to handle case patterns
- improve handling of null-aware cascades in `unnecessary_parenthesis`
- update `unreachable_from_main` to report unreachable public static fields,
  getters, setters, and methods, that are declared on public classes, mixins,
  enums, and extensions

# 1.33.0

- fix `unnecessary_parenthesis` false-positive with null-aware expressions
- fix `void_checks` to allow assignments of `Future<dynamic>?` to parameters 
  typed `FutureOr<void>?`
- removed support for:
  - `enable_null_safety`
  - `invariant_booleans`
  - `prefer_bool_in_asserts`
  - `prefer_equal_for_default_values`
  - `super_goes_last`
- update `unnecessary_parenthesis` to detect some doubled parens
- update `void_checks` to allow returning `Never` as void
- new lint: `unnecessary_breaks`
- fix `use_build_context_synchronously` in if conditions
- update `no_adjacent_strings_in_list` to support set literals and for- and 
  if-elements

# 1.32.0

- update `avoid_types_as_parameter_names` to handle type variables
- update `avoid_positional_boolean_parameters` to handle typedefs
- improve `unnecessary_parenthesis` support for property accesses and method invocations
- update `avoid_redundant_argument_values` to check parameters of redirecting constructors
- performance improvements for `prefer_const_literals_to_create_immutables`
- update `use_build_context_synchronously` to check context properties
- fix false positive for `avoid_private_typedef_functions` with generalized type aliases

# 1.31.0

- update `prefer_equal_for_default_values` to not report for SDKs `>=2.19`,
  where this lint is now an analyzer diagnostic.
- update `unrelated_type_equality_checks` to support updated `package:fixnum`
  structure.

# 1.30.0

- new lint: `enable_null_safety`
- new lint: `library_annotations`
- miscellaneous documentation improvements

# 1.29.0

- new lint: `dangling_library_doc_comments`
- fix `no_leading_underscores_for_local_identifiers` to not report super formals as local variables
- fix `unnecessary_overrides` false negatives
- fix `cancel_subscriptions` for nullable fields 
- new lint: `collection_methods_unrelated_type`
- update `library_names` to support unnamed libraries
- fix `unnecessary_parenthesis` support for as-expressions
- fix `use_build_context_synchronously` to check for context property accesses
- fix false positive in `comment_references`
- improved unrelated type checks to handle enums and cascades
- fix `unnecessary_brace_in_string_interps` for `this` expressions 
- update `use_build_context_synchronously` for `BuildContext.mounted`
- improve `flutter_style_todos` to handle more cases
- fix `use_build_context_synchronously` to check for `BuildContext`s in named expressions
- fix `exhaustive_cases` to check parenthesized expressions
- performance improvements for:
  - `avoid_null_checks_in_equality_operators`
  - `join_return_with_statement`
  - `recursive_getters`
  - `unnecessary_lambdas`
  - `diagnostic_describe_all_properties`
  - `prefer_foreach`
  - `avoid_escaping_inner_quotes`
  - `cascade_invocations`
  - `tighten_type_of_initializing_formals`
  - `prefer_interpolation_to_compose_strings`
  - `prefer_constructors_over_static_methods`
  - `avoid_returning_null`
  - `parameter_assignments`
  - `prefer_constructors_over_static_methods`
  - `prefer_interpolation_to_compose_strings`
  - `avoid_returning_null`
  - `avoid_returning_this`
  - `flutter_style_todos`
  - `avoid_positional_boolean_parameters`
  - `prefer_const_constructors`
- new lint: `implicit_call_tearoffs`
- new lint: `unnecessary_library_directive`

# 1.28.0

- update `avoid_redundant_argument_values` to work with enum declarations
- performance improvements for `prefer_contains`
- new lint: `unreachable_from_main`
- (internal): analyzer API updates and `DartTypeUtilities` refactoring

# 1.27.0

- fix `avoid_redundant_argument_values` when referencing required 
  parameters in legacy libraries
- performance improvements for `use_late_for_private_fields_and_variables`
- new lint: `use_string_in_part_of_directives`
- fixed `use_super_parameters` false positive with repeated super
  parameter references
- updated `use_late_for_private_fields_and_variables` to handle enums
- fixed `prefer_contains` false positive when start index is non-zero
- improved `noop_primitive_operations` to catch `.toString()`
  in string interpolations
- updated `public_member_api_docs` to report diagnostics on extension
  names (instead of bodies)
- miscellaneous documentation improvements
- (internal): `DartTypeUtilities` refactoring

# 1.26.0

- new lint: `combinators_ordering`
- fixed `use_colored_box` and `use_decorated_box` to not over-report
  on containers without a child
- fixed false positive for `unnecessary_parenthesis` on a map-or-set
  literal at the start of an expression statement
- fixed false positive for `prefer_final_locals` reporting on fields
- fixed `unnecessary_overrides` to allow overrides on `@Protected`
  members
- fixed `avoid_multiple_declarations_per_line` false positive in
  `for` statements
- fixed `prefer_final_locals` false positive on declaration lists
  with at least one non-final variable
- fixed `use_build_context_synchronously` to handle `await`s in
  `if` conditions

# 1.25.0

- new lint: `discarded_futures`
- improved message and highlight range for
  `no_duplicate_case_values`
- performance improvements for `lines_longer_than_80_chars`,
  `prefer_const_constructors_in_immutables`, and
  `prefer_initializing_formals`

# 1.24.0

- fix `prefer_final_parameters` to support super parameters
- new lint: `unnecessary_to_list_in_spreads`
- fix `unawaited_futures` to handle string interpolated
  futures
- update `use_colored_box` to not flag nullable colors
- new lint: `unnecessary_null_aware_operator_on_extension_on_nullable`

# 1.23.0

- fixed `no_leading_underscores_for_local_identifiers`
  to lint local function declarations 
- fixed `avoid_init_to_null` to correctly handle super
  initializing defaults that are non-null
- updated `no_leading_underscores_for_local_identifiers`
  to allow identifiers with just underscores
- fixed `flutter_style_todos` to support usernames that
  start with a digit
- updated `require_trailing_commas` to handle functions
  in asserts and multi-line strings
- updated `unsafe_html` to allow assignments to 
  `img.src`
- fixed `unnecessary_null_checks` to properly handle map
  literal entries

# 1.22.0

- fixed false positives for `unnecessary_getters_setters`
  and `prefer_final_fields`with enhanced enums
- updated to analyzer 3.4.0 APIs
- fixed null-safe variance in `invariant_booleans`

# 1.21.2

- several `use_super_parameters` false positive fixes
- updated `depend_on_referenced_packages` to treat
  `flutter_gen` as a virtual package, not needing an
  explicit dependency

# 1.21.1

- bumped language lower-bound constraint to `2.15.0`

# 1.21.0

- fixed `use_key_in_widget_constructors` false positive
  with `key` super parameter initializers
- fixed `use_super_parameters` false positive with field
  formal params
- updated `unnecessary_null_checks` and 
  `null_check_on_nullable_type_parameter` to handle
  list/set/map literals, and `yield` and `await`
  expressions

# 1.20.0

- renamed `use_super_initializers` to `use_super_parameters`
- fixed `unnecessary_null_aware_assignments` property-access
  false positive

# 1.19.2

- new lint: `use_super_initializers`
- new lint: `use_enums`
- new lint: `use_colored_box`
- performance improvements for `sort_constructors`
- doc improvements for `always_use_package_imports`,
  `avoid_print`, and `avoid_relative_lib_imports` 
- update `avoid_void_async` to skip `main` functions
- update `prefer_final_parameters` to not super on super params
- lint updates for enhanced-enums and super-initializer language
  features
- updated `unnecessary_late` to report on the variable name
- marked `null_check_on_nullable_type_parameter` stable

# 1.18.0

- extend `camel_case_types` to cover enums
- fix `no_leading_underscores_for_local_identifiers` to not 
  mis-flag field formal parameters with default values
- fix `prefer_function_declarations_over_variables` to not
  mis-flag non-final fields
- performance improvements for `prefer_contains`
- update `exhaustive_cases` to skip deprecated values that
  redirect to other values

# 1.17.1

- update to `analyzer` version 3.0

# 1.17.0

- new lint: `unnecessary_late`
- fix to `no_leading_underscores_for_local_identifiers` to allow
  underscores in catch clauses

# 1.16.0

- doc improvements for `prefer_initializing_formals`
- updates to `secure_pubspec_urls` to check `issue_tracker` and
  `repository` entries
- new lint: `conditional_uri_does_not_exist`
- performance improvements for 
  `missing_whitespace_between_adjacent_strings`

# 1.15.0

- new lint: `use_decorated_box`
- new lint: `no_leading_underscores_for_library_prefixes`
- new lint: `no_leading_underscores_for_local_identifiers`
- new lint: `secure_pubspec_urls`
- new lint: `sized_box_shrink_expand`
- new lint: `avoid_final_parameters`
- improved docs for `omit_local_variable_types`

# 1.14.0

- fix `omit_local_variable_types` to not flag a local type that is 
  required for inference

# 1.13.0

- allow `while (true) { ...}` in `literal_only_boolean_expressions`
- fixed `file_names` to report at the start of the file (not the entire 
  compilation unit)
- fixed `prefer_collection_literals` named typed param false positive
- control flow improvements for `use_build_context_synchronously`

# 1.12.0

- fixed `unnecessary_lambdas` false positive for const constructor invocations
- updated `avoid_print` to allow `kDebugMode`-wrapped print calls
- fixed handling of initializing formals in `prefer_final_parameters`
- fixed `unnecessary_parenthesis` false positive with function expressions

# 1.11.0

- added support for constructor tear-offs to `avoid_redundant_argument_values`, 
  `unnecessary_lambdas`, and `unnecessary_parenthesis`
- new lint: `unnecessary_constructor_name` to flag unnecessary uses of `.new`

# 1.10.0

- improved regular expression parsing performance for common checks 
  (`camel_case_types`, `file_names`, etc.)
- (internal) migrated to analyzer 2.1.0 APIs
- fixed false positive in `use_build_context_synchronously` in awaits inside 
  anonymous functions
- fixed `overridden_fields` false positive w/ static fields
- fixed false positive in `avoid_null_checks_in_equality_operators` w/ 
  non-nullable params
- fixed false positive for deferred imports in `prefer_const_constructors`

# 1.9.0

- marked `avoid_dynamic_calls` stable
- (internal) removed unused `MockPubVisitor` and `MockRule` classes
- fixed `prefer_void_to_null` false positive w/ overridden properties
- (internal) removed references to `NodeLintRule` in lint rule declarations
- fixed `prefer_void_to_null` false positive on overriding returns
- fixed `prefer_generic_function_type_aliases` false positive w/ incomplete statements
- fixed false positive for `prefer_initializing_formals` with factory constructors
- fixed `void_checks` false positives with incomplete source
- updated `unnecessary_getters_setters` to only flag the getter
- improved messages for `avoid_renaming_method_parameters`
- fixed false positive in `prefer_void_to_null`
- fixed false positive in `omit_local_variable_types`
- fixed false positive in `use_rethrow_when_possible`
- performance improvements for `annotate_overrides`, `prefer_contains`, and `prefer_void_to_null`

# 1.8.0

- performance improvements for `prefer_is_not_empty`
- fixed false positive in `no_logic_in_create_state`
- improve `package_names` to allow dart identifiers as package names
- fixed false-positive in `package_names` (causing keywords to wrongly get flagged)
- fixed `avoid_classes_with_only_static_member` to check for inherited members and also
  flag classes with only methods
- fixed `curly_braces_in_flow_control_structures` to properly flag terminating `else-if`
  blocks
- improved `always_specify_types` to support type aliases
- fixed false positive in `unnecessary_string_interpolations` w/ nullable interpolated 
  strings
- fixed false positive in `avoid_function_literals_in_foreach_calls` for nullable
  iterables
- fixed false positive in `avoid_returning_null` w/ NNBD
- fixed false positive in `use_late_for_private_fields_and_variables` in the presence
  of const constructors
- new lint: `eol_at_end_of_file`
- updated `analyzer` constraint to `>=2.0.0 <3.0.0`

# 1.7.1

- Update `analyzer` constraint to `>=1.7.0 <3.0.0`.
- Update `meta` constraint to `>=1.3.0 <3.0.0`.

# 1.7.0

- fixed case-sensitive false positive in `use_full_hex_values_for_flutter_colors`
- improved try-block and switch statement flow analysis for 
  `use_build_context_synchronously`
- updated `use_setters_to_change_properties` to only highlight a method name,
  not the entire body and doc comment
- updated `unnecessary_getters_setters` to allow otherwise "unnecessary" getters
  and setters with annotations
- updated `missing_whitespace_between_adjacent_strings` to allow String
  interpolations at the beginning and end of String literals
- updated `unnecessary_getters_setters` to allow for setters with non-basic
  assignments (for example, `??=` or `+=`)

# 1.6.1

- reverted relaxation of `sort_child_properties_last` to allow for a 
  trailing Widget in instance creations

# 1.6.0

- relaxed `non_constant_identifier_names` to allow for a trailing
  underscore
- fixed false negative in `prefer_final_parameters` where first parameter
  is final
- improved `directives_ordering` sorting of directives with dot paths and 
  dot-separated package names
- relaxed `sort_child_properties_last` to allow for a trailing Widget in
  instance creations

# 1.5.0

- (internal) migrated to `SecurityLintCode` instead of deprecated 
  `SecurityLintCodeWithUniqueName`
- (internal) fixed `avoid_types_as_parameter_names` to skip field formal
  parameters
- fixed false positives in `prefer_interpolation_to_compose_strings` where
  the left operand is not a String
- fixed false positives in `only_throw_errors` for misidentified type
  variables
- new lint: `depend_on_referenced_packages`
- update `avoid_returning_null_for_future` to skip checks for null-safe
  libraries
- new lint: `use_test_throws_matchers`
- relax `sort_child_properties_last` to accept closures after child
- performance improvements for `prefer_contains` and `prefer_is_empty`
- new lint: `noop_primitive_operations`
- mark `avoid_web_libraries_in_flutter` as stable
- new lint: `prefer_final_parameters`
- update `prefer_initializing_formals` to allow assignments where identifier
  names don't match

# 1.4.0

- `directives_ordering` now checks ordering of `package:` imports in code
  outside pub packages
- simple reachability analysis added to `use_build_context_synchronously` to
  short-circuit await-discovery in terminating blocks
- `use_build_context_synchronously` updated to recognize nullable types when
  accessed from legacy libraries

# 1.3.0

- `non_constant_identifier_names` updated to check local variables, for-loop
  initializers and catch clauses
- error range of `lines_longer_than_80_chars` updated to start at 80 to make
  splitting easier
- new lint: `require_trailing_commas`
- new lint: `prefer_null_aware_method_calls`

# 1.2.1

- fix: adjusted SDK lower bound to 2.12.0-0 (from 2.13.0-0)

# 1.2.0

- improvements to `iterable_contains_unrelated_type` to better support `List`
  content checks
- fixes to `camel_case_types` and `prefer_mixin` to support non-function
  type aliases

# 1.1.0

- fixed `prefer_mixin` to properly make exceptions for `dart.collection` legacy
  mixins
- improved formatting of source examples in docs
- new lint: `use_build_context_synchronously` (experimental)
- new lint: `avoid_multiple_declarations_per_line`

# 1.0.0

- full library migration to null-safety
- new lint: `use_if_null_to_convert_nulls_to_bools`
- new lint: `deprecated_consistency`
- new lint: `use_named_constants`
- deprecation of `avoid_as`

# 0.1.129

- fixed a bug where `avoid_dynamic_calls` produced false-positives for `.call()`

# 0.1.128

- new lint: `avoid_dynamic_calls`
- (internal): updated `avoid_type_to_string` to use `addArgumentList` registry API
- documentation improvements

# 0.1.127

- fixed crash in `prefer_collection_literals` when there is no static parameter
  element

# 0.1.126

- fixed false negatives for `prefer_collection_literals` when a LinkedHashSet or
  LinkedHashMap instantiation is passed as the argument to a function in any
  position other than the first
- fixed false negatives for `prefer_collection_literals` when a LinkedHashSet or
  LinkedHashMap instantiation is used in a place with a static type other than
  Set or Map

# 0.1.125

- (internal): update to new `PhysicalResourceProvider` API

# 0.1.124

- fixed false positives in `prefer_constructors_over_static_methods`
- updated `package_names` to allow leading underscores

# 0.1.123

- fixed NPEs in `unnecessary_null_checks`

# 0.1.122

- fixed NPE in `unnecessary_null_checks`
- fixed NPE in `missing_whitespace_between_adjacent_strings`
- updated `void_checks` for NNBD
- fixed range error in `unnecessary_string_escapes`
- fixed false positives in `unnecessary_null_types`
- fixed `prefer_constructors_over_static_methods` to respect type parameters
- updated `always_require_non_null_named_parameters` to be NNBD-aware
- updated `unnecessary_nullable_for_final_variable_declarations` to allow dynamic
- update `overridden_fields` to not report on abstract parent fields
- fixes to `unrelated_type_equality_checks` for NNBD
- improvement to `type_init_formals`to allow types not equal to the field type

# 0.1.121

- performance improvements to `always_use_package_imports`, `avoid_renaming_method_parameters`, `prefer_relative_imports` and `public_member_api_docs`
- (internal): update to analyzer `0.40.4` APIs

# 0.1.120

- new lint: `cast_nullable_to_non_nullable`
- new lint: `null_check_on_nullable_type_parameter`
- new lint: `tighten_type_of_initializing_formals`
- update `public_member_apis` to check generic type aliases
- (internal): update to new analyzer APIs

# 0.1.119

- fix `close_sinks` to handle `this`-prefixed property accesses
- new lint: `unnecessary_null_checks`
- fix `unawaited_futures` to handle `Future` subtypes
- new lint: `avoid_type_to_string`

# 0.1.118

- new lint: `unnecessary_nullable_for_final_variable_declarations`
- fixed NPE in `prefer_asserts_in_initializer_lists`
- fixed range error in `unnecessary_string_escapes`
- `unsafe_html` updated to support unique error codes
- updates to `diagnostic_describe_all_properties` to check for `Diagnosticable`s (not `DiagnosticableMixin`s)
- new lint: `use_late`
- fixed `unnecessary_lambdas` to respect deferred imports
- updated `public_member_api_docs` to check mixins
- updated `unnecessary_statements` to skip `as` expressions
- fixed `prefer_relative_imports` to work with path dependencies

# 0.1.117

- fixed `directives_ordering` to remove third party package special-casing
- fixed `unnecessary_lambdas` to check for tearoff assignability
- fixed `exhaustive_cases` to not flag missing cases that are defaulted
- fixed `prefer_is_empty` to special-case assert initializers and const contexts
- test utilities moved to: `lib/src/test_utilities`
- new lint: `do_not_use_environment`

# 0.1.116

- new lint: `no_default_cases` (experimental)
- new lint: `exhaustive_cases`
- updated `type_annotate_public_apis` to allow inferred types in final field assignments
- updated `prefer_mixin` to allow "legacy" SDK abstract class mixins
- new lint: `use_is_even_rather_than_modulo`
- update `unsafe_html` to use a `SecurityLintCode` (making it un-ignorable)
- improved `sized_box_for_whitespace` to address false-positives

# 0.1.115

- updated `avoid_types_as_parameter_names` to check catch-clauses
- fixed `unsafe_html` to check attributes and methods on extensions
- extended `unsafe_html` to include `Window.open`, `Element.html` and `DocumentFragment.html` in unsafe API checks
- improved docs for `sort_child_properties_last`
- (internal) `package:analyzer` API updates
- new lint: `sized_box_for_whitespace`

# 0.1.114

- fixed `avoid_shadowing_type_parameters` to support extensions and mixins
- updated `non_constant_identifier_names` to allow named constructors made up of only underscores (`_`)
- updated `avoid_unused_constructor_parameters` to ignore unused params named in all underscores (`_`)

# 0.1.113

- updated documentation links
- `one_member_abstracts` updated to not lint classes with mixins or implementing interfaces
- `unnecessary_getters_setters` fixed to ignore cases where a getter/setter is deprecated
- new lint: `leading_newlines_in_multiline_strings`
- improved highlight ranges for `avoid_private_typedef_functions` and `avoid_returning_null_for_future`

# 0.1.112

- marked `prefer_typing_uninitialized_variables` and `omit_local_variable_types` as compatible

# 0.1.111+1

- new lint: `use_raw_strings`
- new lint: `unnecessary_raw_strings`
- new lint: `avoid_escaping_inner_quotes`
- new lint: `unnecessary_string_escapes`
- incompatible rule documentation improvements

# 0.1.110

- fixed flutter web plugin detection in `avoid_web_libraries_in_flutter`
- new lint: `unnecessary_string_interpolations`
- new lint: `missing_whitespace_between_adjacent_strings`
- `avoid_unused_constructor_parameters` updated to ignore deprecated parameters
- new lint: `no_runtimeType_toString`
- miscellaneous doc fixes

# 0.1.109

- improved`prefer_single_quotes` lint message
- `unnecessary_finals` fixed to not flag fields
- `unnecessary_lambdas` fixed to work with type arguments
- (internal) migrated to use analyzer `LinterContext.resolveNameInScope()` API

# 0.1.108

- fixes to `avoid_redundant_argument_values`
- new lint: `use_key_in_widget_constructors`
- `always_put_required_parameters` updated for NNBD
- updated to `package:analyzer` 0.39.3 APIs

# 0.1.107

- miscellaneous doc cleanup (typos, etc)
- new lint: `avoid_redundant_argument_values`
- updated `slash_for_doc_comments` to check mixin declarations
- (internal) updates to use new `LinterContext.evaluateConstant` API
- improved docs for `always_require_non_null_named_parameters`

# 0.1.106

- improved docs for `comment_references`
- fixed `null_closures` to properly handle `Iterable.singleWhere`
- (internal) migrated to latest analyzer APIs
- new lint: `no_logic_in_create_state`

# 0.1.105+1

- fixed regressions in `always_require_non_null_named_parameters`
- (internal) pedantic lint clean-up

# 0.1.105

- hardened check for lib dir location (fixing crashes in `avoid_renaming_method_parameters`,
  `prefer_relative_imports` and `public_member_api_docs`)
- improved performance for `always_require_non_null_named_parameters`

# 0.1.104

- updated `unnecessary_overrides` to allow overrides when annotations (besides `@override` are specified)
- updated `file_names` to allow names w/ leading `_`'s (and improved performance)
- new lint: `unnecessary_final`

# 0.1.103

- updated `prefer_relative_imports` to use a faster and more robust way to check for self-package references
- updated our approach to checking for `lib` dir contents (speeding up `avoid_renaming_method_parameters` and
  making `prefer_relative_imports` and `public_member_api_docs` amenable to internal package formats -- w/o pubspecs)

# 0.1.102

- `avoid_web_libraries_in_flutter` updated to disallow access from all but Flutter web plugin packages
- updated `avoid_returning_null_for_void` to check only `null` literals (and not expressions having `Null` types)
- fixed `prefer_final_fields` to respect non-mutating prefix operators
- new lint: `prefer_is_not_operator`
- new lint: `avoid_unnecessary_containers`
- added basic nnbd-awareness to `avoid_init_to_null`

# 0.1.101

- fixed `diagnostic_describe_all_properties` to flag properties in `Diagnosticable`s with no debug methods defined
- fixed `noSuchMethod` exception in `camel_case_extensions` when analyzing unnamed extensions
- fixed `avoid_print` to catch tear-off usage
- new lint: `avoid_web_libraries_in_flutter` (experimental)
- (internal) prepare `unnecessary_lambdas` for coming `MethodInvocation` vs. `FunctionExpressionInvocation` changes

# 0.1.100

- (internal) stop accessing `staticType` in favor of getting type of `FormalParameter`s from the declared element
- (internal) remove stale analyzer work-around for collecting `TypeParameterElement`s in `prefer_const_constructors`

# 0.1.99

- fixed unsafe cast in `overridden_fields`
- (internal) migrated to the mock SDK in `package:analyzer` for testing
- fixed empty argument list access in `use_full_hex_values_for_flutter_color_fix`
- new lint: `prefer_relative_imports`
- improved messages for `await_only_futures`

# 0.1.98

- fixed null raw expression accesses in `use_to_and_as_if_applicable`
- (internal) migrated to using analyzer `InheritanceManager3`

# 0.1.97+1

- enabled `camel_case_extensions` experimental lint

# 0.1.97

- internal: migrated away from using analyzer `resolutionMap`
- various fixes and improvements to anticipate support for extension-methods
- new lint: `camel_case_extensions`
- rule template generation improvements
- new lint: `avoid_equals_and_hash_code_on_mutable_classes`
- extended `avoid_slow_async_io` to flag async `Directory` methods

# 0.1.96

- fixed false positives in `unnecessary_parens`
- various changes to migrate to preferred analyzer APIs
- rule test fixes

# 0.1.95

- improvements to `unsafe_html` error reporting
- fixed false positive in `prefer_asserts_in_initializer_lists`
- fixed `prefer_const_constructors` to not flag `@literal` annotated constructors

# 0.1.94

- (internal): analyzer API call updates
- (internal): implicit cast cleanup

# 0.1.93

- new lint: `avoid_print`

# 0.1.92

- improved `prefer_collection_literals` to better handle `LinkedHashSet`s and `LinkedHashMap`s
- updates to the Effective Dart rule set
- updated `prefer_final_fields` to be more inclusive
- miscellaneous documentation fixes

# 0.1.91

- fixed missed cases in `prefer_const_constructors`
- fixed `prefer_initializing_formals` to no longer suggest API breaking changes
- updated `omit_local_variable_types` to allow explicit `dynamic`s
- (internal) migration from deprecated analyzer APIs

# 0.1.90

- fixed null-reference in `unrelated_type_equality_checks`
- new lint: `unsafe_html`

# 0.1.89

- broadened `prefer_null_aware_operators` to work beyond local variables
- new lint: `prefer_if_null_operators`
- fixed `prefer_contains` false positives
- fixed `unnecessary_parenthesis` false positives

# 0.1.88

- fixed `prefer_asserts_in_initializer_lists` false positives
- fixed `curly_braces_in_flow_control_structures` to handle more cases
- new lint: `prefer_double_quotes`
- new lint: `sort_child_properties_last`
- fixed `type_annotate_public_apis` false positive for `static const` initializers

# 0.1.87

- change: `prefer_const_constructors_in_immutables` is currently overly permissive, pending analyzer changes (#1537)
- fixed `unnecessary_await_in_return` false positive
- fixed `unrelated_type_equality_checks` false negative with functions
- fixed `prefer_spread_collections` to not lint in const contexts
- fixed false positive in `prefer_iterable_whereType` for `is!`
- fixed false positive in `prefer_collection_literals` for constructors with params

# 0.1.86

- updated `prefer_spread_collections` to ignore calls to `addAll` that could be inlined
- new lint: `prefer_inlined_adds`

# 0.1.85

- (**BREAKING**) renamed `spread_collections` to `prefer_spread_collections`
- new lint: `prefer_for_elements_to_map_fromIterable`
- new lint: `prefer_if_elements_to_conditional_expressions`
- new lint: `diagnostic_describe_all_properties`

# 0.1.84

- new lint: `spread_collections`
- (internal) update to analyzer 0.36.0 APIs
- new lint: `prefer_asserts_with_message`

# 0.1.83

- updated `file_names` to skip prefixed-extension Dart files (e.g., `.css.dart`, `.g.dart`)
- updated SDK constraint to `2.2.0`
- miscellaneous rule documentation fixes
- (internal) updated sources to use Set literals
- fixed NPE in `avoid_shadowing_type_parameters`
- added linter version numbering for use in analyzer summaries
- fixed type utilities to handle inheritance cycles
- (internal) changes to adopt new `package:analyzer` APIs
- fixed `unnecessary_parenthesis` false positives

# 0.1.82

- fixed `prefer_collection_literals` Set literal false positives
- fixed `prefer_const_declarations` Set literal false positives
- new lint: `provide_deprecation_message`

# 0.1.81

- updated `prefer_collection_literals` to support Set literals

# 0.1.80

- deprecated `super_goes_last`
- (internal) migrations to analyzer's preferred `InheritanceManager2` API

# 0.1.79

- `unnecessary_parenthesis` updated to play nicer with cascades
- new lint: `use_full_hex_values_for_flutter_colors`
- new lint: `prefer_null_aware_operators`
- miscellaneous documentation fixes
- removed deprecated lints from the "all options" sample
- stopped registering "default lints"
- `hash_and_equals` fixed to respect `hashCode` fields

# 0.1.78

- restored `prefer_final_locals` to ignore loop variables, and
- introduced a new `prefer_final_in_for_each` lint to handle the `for each` case

# 0.1.77

- updated `prefer_final_locals` to check to for loop variables
- fixed `type_annotate_public_apis` false positives on local functions
- fixed `avoid_shadowing_type_parameters` to report shadowed type parameters in generic typedefs
- fixed `use_setters_to_change_properties` to not wrongly lint overriding methods
- fixed `cascade_invocations` to not lint awaited targets
- fixed `prefer_conditional_assignment` false positives
- fixed `join_return_with_assignment` false positives
- fixed `cascade_invocations` false positives
- miscellaneous documentation improvements
- updated `invariant_booleans` status to experimental

# 0.1.76

- `unnecessary_parenthesis` updated to allow wrapping a `!` argument
- miscellaneous documentation grammar and spelling fixes
- improved error messages for `always_declare_return_types`
- fix `prefer_final_fields ` to work with classes that have generic type arguments
- (internal): deprecated code cleanup
- fixed false positives in `unrelated_type_equality_checks`

# 0.1.75

- analyzer package dependency bumped to `^0.34.0`

# 0.1.74

- experimental lints `avoid_positional_boolean_parameters`, `literal_only_boolean_expressions`, `prefer_foreach`, `prefer_void_to_null` promoted to stable
- `unnecessary_parenthesis` improved to handle function expressions

# 0.1.73

- deprecated `prefer_bool_in_asserts` (redundant w/ Dart 2 checks)
- improved doc generation to highlight deprecated and experimental lints
- bumped analyzer lower-bound to `0.33.4`
- bumped SDK lower-bound to `2.1.0`
- new lint: `unnecessary_await_in_return`

# 0.1.72

- new lint: `use_function_type_syntax_for_parameters`
- internal changes to migrate towards analyzer's new `LinterContext` API
- fix false positive in `use_setters_to_change_properties`
- implementation improvements (and speed-ups) to `prefer_foreach` and `public_member_api_docs`
- new lint: `avoid_returning_null_for_future`
- new lint: `avoid_shadowing_type_parameters`

# 0.1.71

- new lint: `prefer_int_literals`
- update `await_only_futures` to allow awaiting on `null`
- update `use_setters_to_change_properties` to work with `=>` short-hand

# 0.1.70

- fix NPE in `prefer_iterable_whereType`

# 0.1.69

- improved message display for `await_only_futures`
- performance improvements for `null_closures`
- new lint: `avoid_returning_null_for_void`

# 0.1.68

- updated analyzer compatibility to `^0.33.0`

# 0.1.67

- miscellaneous mixin support fixes
- update to `sort_constructors_first` to apply to all members
- update `unnecessary_this` to work on field initializers

# 0.1.66

- broadened SDK version constraint

# 0.1.65

- fix cast exceptions related to mixin support

# 0.1.64

- fixes to better support mixins

# 0.1.63

- updated `unawaited_futures` to ignore assignments within cascades
- new lint: `sort_pub_dependencies`

# 0.1.62

- new lint: `prefer_mixin`
- new lint: `avoid_implementing_value_types`

# 0.1.61

- new lint: `flutter_style_todos`
- improved handling of constant expressions with generic type params
- NPE fix for `invariant_booleans`
- Google lints example moved to `package:pedantic`
- improved docs for `unawaited_futures`

# 0.1.60

- new lint: `avoid_void_async`
- `unawaited_futures` updated to check cascades

# 0.1.59

- relaxed `void_checks` (allowing `T Function()` to be assigned to `void Function()`)
- test and build improvements
- introduced Effective Dart rule set
- Google ruleset updates
- (internal cleanup): move cli main into `lib/`
- fixed false positives in `lines_longer_than_80_chars`
- new lint: `prefer_void_to_null`

# 0.1.58

- roll-back to explicit uses of `new` and `const` to be compatible w/ VMs running `--no-preview-dart-2`

# 0.1.57

- fix to `lines_longer_than_80_chars` to handle CRLF endings
- doc improvements
- set max SDK version to <3.0.0
- fix to `non_constant_identifier_names` to better handle invalid code
- new lint: `curly_braces_in_flow_control_structures`

# 0.1.56

- fix to `avoid_positional_boolean_parameters` to ignore overridden methods
- fix to `prefer_is_empty` to not evaluate constants beyond int literals
- new lint: `null_closures`
- new lint: `lines_longer_than_80_chars`

# 0.1.55

- fixed an issue in `const` error handling
- updated `linter` binary to use `previewDart2`

# 0.1.54

- new `unnecessary_const` lint
- new `unnecessary_new` lint
- fixed errors in `use_to_and_as_if_applicable`
- new `file_names` lint

# 0.1.53

- updated `unnecessary_statements` to ignore getters (as they may be side-effecting).

# 0.1.52

- fixed `void_checks` to handle arguments not resolved to a parameter
- fixed exceptions produced by `prefer_const_literals_to_create_immutables`

# 0.1.51

- `unrelated_type_equality_checks` now allows comparison between `Int64` or `Int32` and `int`
- `unnecessary_parenthesis` improved to handle cascades _in_ cascades

# 0.1.50

- migration of rules to use analyzer package `NodeLintRule` and `UnitLintRule` yielding significant performance gains all around
- specific performance improvements for `prefer_final_fields` (~6x)
- addressed no such method calls in `void_checks`
- improved lint reporting for various lints

# 0.1.49

- new `void_checks` lint

# 0.1.48

- new `avoid_field_initializers_in_const_classes` lint
- miscellaneous documentation fixes
- improved handling of cascades in `unnecessary_statements`
- new `avoid_js_rounded_ints` lint

# 0.1.47

- new `avoid_double_and_int_checks` lint
- fix to handle uninitialized vars in `prefer_const_declarations`
- fix for generic function type handling in `avoid_types_as_parameter_names`
- new `prefer_iterable_whereType` lint
- new `prefer_generic_function_type_aliases` lint
- Dart 2 compatibility fixes

# 0.1.46

- performance fixes for library prefix testing (`library_prefixes`)
- new `avoid_bool_literals_in_conditional_expressions` lint
- new `prefer_equal_for_default_values` lint
- new `avoid_private_typedef_functions` lint
- new `avoid_single_cascade_in_expression_statements` lint

# 0.1.45

- fix for `invariant_booleans` when analyzing for loops with no condition
- new `avoid_types_as_parameter_names` lint
- new `avoid_renaming_method_parameters` lint

# 0.1.44

- new `avoid_relative_lib_imports` lint
- new `unnecessary_parenthesis` lint
- fix to `prefer_const_literals_to_create_immutables` to handle undefined classes gracefully
- updates to `prefer_const_declarations` to support optional `new` and `const`
- `prefer_const_declarations` updated to check locals
- fixes to `invariant_booleans`
- bumped SDK lower bound to `2.0.0-dev`
- build and workflow improvements: rule template fixes; formatting and header validation
- miscellaneous documentation fixes

# 0.1.43

- new `prefer_const_declarations.dart` lint
- new `prefer_const_literals_to_create_immutables` lint
- miscellaneous documentation improvements

# 0.1.42

- added support for external constructors in `avoid_unused_constructor_parameters`
- added code reference resolution docs for `comment_references`

# 0.1.41

- broadened `args` package dependency to support versions `1.*`

# 0.1.40

- `avoid_unused_constructor_parameters` updated to better handle redirecting factory constructors
- `avoid_returning_this` improvements
- `prefer_bool_in_asserts` improvements
- miscellaneous documentation fixes

# 0.1.39

- `prefer_interpolation_to_compose_strings` updated to allow concatenation of two non-literal strings
- `prefer_interpolation_to_compose_strings` updated to allow `+=`
- lots of rule documentation fixes and enhancements
- fix for `prefer_const_constructors_in_immutables` false positive with redirecting factory constructors

# 0.1.38

- `public_member_api_docs` fix for package URIs

# 0.1.37

- `avoid_positional_boolean_parameters` updated to allow booleans in operator declarations
- `comment_references` fixed to handle incomplete references
- `non_constant_identifier_names` updated to allow underscores around numbers

# 0.1.36

- new `avoid_unused_constructor_parameters` lint
- new `prefer_bool_in_asserts` lint
- new `prefer_typing_uninitialized_variables` lint
- new `unnecessary_statements` lint
- `public_member_api_docs` updated to only lint source in `lib/`
- 'avoid_empty_else' fixed to ignore synthetic `EmptyStatement`s
- updated library prefix checking to allow leading `$`s
- miscellaneous documentation fixes
- Dart SDK constraints restored (removed unneeded `2.0.0-dev.infinity` constraint)

# 0.1.35

- linter engine updated to use new analysis driver

# 0.1.34

## Features

- `non_constant_identifier_names` extended to include named constructors
- SDK constraint broadened to `2.0.0-dev.infinity`
- improved `prefer_final_fields` performance

## Fixes

- fixes to `unnecessary_overrides` (`noSuchMethod` handling, return type narrowing, special casing of documented `super` calls)
- fix to `non_constant_identifier_names` to handle identifiers with no name
- fixes to `prefer_const_constructors` to support list literals
- fixes to `recursive_getters`
- fixes to `cascade_invocations`

# 0.1.33

## Features

- new `prefer_const_constructors_in_immutables` lint
- new `always_put_required_named_parameters_first` lint
- new `prefer_asserts_in_initializer_lists` lint
- support for running in `--benchmark` mode
- new `prefer_single_quote_strings` lint

## Fixes

- docs for `avoid_setters_without_getters`
- fix to `directives_ordering` to work with part directives located after exports
- fixes to `cascade_invocations` false positives
- fixes to `literal_only_boolean_expressions` false positives
- fix to ensure `cascade_invocations` only lints method invocations if target is a simple identifier
- fixes to `use_string_buffers` false positives
- fixes to `prefer_const_constructors`

# 0.1.32

- Lint stats (`-s`) output now sorted.

# 0.1.31

- New `prefer_foreach` lint.
- New `use_string_buffers` rule.
- New `unnecessary_overrides` rule.
- New `join_return_with_assignment_when_possible` rule.
- New `use_to_and_as_if_applicable` rule.
- New `avoid_setters_without_getters` rule.
- New `always_put_control_body_on_new_line` rule.
- New `avoid_positional_boolean_parameters` rule.
- New `always_require_non_null_named_parameters` rule.
- New `prefer_conditional_assignment` rule.
- New `avoid_types_on_closure_parameters` rule.
- New `always_put_control_body_on_new_line` rule.
- New `use_setters_to_change_properties` rule.
- New `avoid_returning_this` rule.
- New `avoid_annotating_with_dynamic_when_not_required` rule.
- New `prefer_constructors_over_static_methods` rule.
- New `avoid_returning_null` rule.
- New `avoid_classes_with_only_static_members` rule.
- New `avoid_null_checks_in_equality_operators` rule.
- New `avoid_catches_without_on_clauses` rule.
- New `avoid_catching_errors` rule.
- New `use_rethrow_when_possible` rule.
- Many lint fixes (notably `prefer_final_fields`, `unnecessary_lambdas`, `await_only_futures`, `cascade_invocations`, `avoid_types_on_closure_parameters`, and `overridden_fields`).
- Significant performance improvements for `prefer_interpolation_to_compose_strings`.
- New `unnecessary_this` rule.
- New `prefer_initializing_formals` rule.

# 0.1.30

- New `avoid_function_literals_in_foreach_calls` lint.
- New `avoid_slow_async_io` lint.
- New `cascade_invocations` lint.
- New `directives_ordering` lint.
- New `no_adjacent_strings_in_list` lint.
- New `no_duplicate_case_values` lint.
- New `omit_local_variable_types` lint.
- New `prefer_adjacent_string_concatenation` lint.
- New `prefer_collection_literals` lint.
- New `prefer_const_constructors` lint.
- New `prefer_contains` lint.
- New `prefer_expression_function_bodies` lint.
- New `prefer_function_declarations_over_variables` lint.
- New `prefer_initializing_formals` lint.
- New `prefer_interpolation_to_compose_strings` lint.
- New `prefer_is_empty` lint.
- New `recursive_getters` lint.
- New `unnecessary_brace_in_string_interps` lint.
- New `unnecessary_lambdas` lint.
- New `unnecessary_null_aware_assignments` lint.
- New `unnecessary_null_in_if_null_operators` lint.
- Miscellaneous bug fixes and codegen improvements.

# 0.1.29

- New `cascade_invocations` lint.
- Expand `await_only_futures` to accept classes that extend or implement `Future`.
- Improve camel case regular expression tests to accept `$`s.
- Fixes to `parameter_assignments` (improved getter handling and an NPE).

# 0.1.27

- Fixed cast exception in `dart_type_utilities` (dart-lang/sdk#27405).
- New `parameter_assignments` lint.
- New `prefer_final_fields` lint.
- New `prefer_final_locals` lint.
- Markdown link fixes in docs (#306).
- Miscellaneous solo test running fixes and introduction of `solo_debug` (#304).

# 0.1.26

- Updated tests to use package `test` (#302).

# 0.1.25

- Fixed false positive on `[]=` in `always_declare_return_types` (#300).
- New `invariant_booleans` lint.
- New `literal_only_boolean_expressions` lint.
- Fixed `camel_case_types` to allow `$` in identifiers (#290).

# 0.1.24

- Internal updates to keep up with changes in the analyzer package.
- Updated `close_sinks` to respect calls to `destroy` (#282).
- Fixed `only_throw_errors` to report on the expression not node.

# 0.1.23

- Removed `whitespace_around_ops` pending re-name and re-design (#249).

# 0.1.22

- Grinder support (`rule:rule_name` and `docs:location`) for rule stub and doc generation (respectively).
- Fix to allow leading underscores in `non_constant_identifier_names`.
- New `valid_regexps` lint (#277).
- New `whitespace_around_ops` lint (#249).
- Fix to `overridden_fields` to flag overridden static fields (#274).
- New `list_remove_unrelated_type` to detect passing a non-`T` value to `List.remove()`` (#271).
- New `empty_catches` lint to catch empty catch blocks (#43).
- Fixed `close_sinks` false positive (#268).
- `linter` support for `--strong` to allow for running linter in strong mode.

# 0.1.21

- New `only_throw_errors` lint.
- New lint to check for `empty_statements` (#259).
- Fixed NSME when file contents cannot be read (#260).
- Fixed unsafe cast in `iterable_contains_unrelated_type` (#267).

# 0.1.20

- New `cancel_subscriptions` lint.

# 0.1.19

- New `close_sinks` lint.
- Fixes to `iterable_contains_unrelated_type `.

# 0.1.18

- Fix NSME in `iterable_contains_unrelated_type` (#245).
- Fixed typo in `comment_references` error description.
- Fix `overriden_field` false positive (#246).
- Rename linter binary `lints` option to `rules` (#248).
- Help doc tweaks.

# 0.1.17

- Fix to `public_member_api_docs` to check for documented getters when checking setters (#237).
- New `iterable_contains_unrelated_type` lint to detect when `Iterable.contains` is invoked with an object of an unrelated type.
- New `comment_references` lint to ensure identifiers referenced in docs are in scope (#240).

# 0.1.16

- Fix for false positive in `overriden_field`s.
- New `unrelated_type_equality_checks` lint.
- Fix to accept `$` identifiers in string interpolation lint (#214).
- Update to new `plugin` API (`0.2.0`).
- Strong mode cleanup.

# 0.1.15

- Fix to allow simple getter/setters when a decl is ``@protected` (#215).
- Fix to not require type params in `is` checks (#227).
- Fix to not flag field formal identifiers in parameters (#224).
- Fix to respect filters when calculating error codes (#198).
- Fix to allow `const` and `final` vars to be initialized to null (#210).
- Fix to respect commented blocks in `empty_constructor_bodies` (#209).
- Fix to check types on list/map literals (#199).
- Fix to skip `main` when checking for API docs (#207).
- Fix to allow leading `$` in type names (#220).
- Fix to ignore private typedefs when checking for types (#216).
- New `test_types_in_equals` lint.
- New `await_only_futures` lint.
- New `throw_in_finally` lint.
- New `control_flow_in_finally` lint.

# 0.1.14

- Fix to respect `@optionalTypeArgs` (#196).
- Lint to warn if a field overrides or hides other field.
- Fix to allow single char UPPER_CASE non-constants (#201).
- Fix to accept casts to dynamic (#195).

# 0.1.13

- Fix to skip overriding members in API doc checks (`public_member_api_docs`).
- Fix to suppress lints on synthetic nodes/tokens (#193).
- Message fixes (`annotate_overrides`, `public_member_api_docs`).
- Fix to exclude setters from return type checks (#192).

# 0.1.12

- Fix to address `LibraryNames` regexp that in pathological cases went exponential.

# 0.1.11

- Doc generation improvements (now with options samples).
- Lint to sort unnamed constructors first (#187).
- Lint to ensure public members have API docs (#188).
- Lint to ensure constructors are sorted first (#186).
- Lint for `hashCode` and `==` (#168).
- Lint to detect un-annotated overrides (#167).
- Fix to ignore underscores in public APIs (#153).
- Lint to check for return types on setters (#122).
- Lint to flag missing type params (#156).
- Lint to avoid inits to `null` (#160).

# 0.1.10

- Updated to use `analyzer` `0.27.0`.
- Updated options processing to handle untyped maps (dart-lang/sdk#25126).

# 0.1.9

- Fix `type_annotate_public_apis` to properly handle getters/setters (#151; dart-lang/sdk#25092).

# 0.1.8

- Fix to protect against errors in linting invalid source (dart-lang/sdk#24910).
- Added `avoid_empty_else` lint rule (dart-lang/sdk#224936).

# 0.1.7

- Fix to `package_api_docs` (dart-lang/sdk#24947; #154).

# 0.1.6

- Fix to `package_prefixed_library_names` (dart-lang/sdk#24947; #154).

# 0.1.5

- Added `prefer_is_not_empty` lint rule (#143).
- Added `type_annotate_public_apis` lint rule (#24).
- Added `avoid_as` lint rule (#145).
- Fixed `non_constant_identifier_names` rule to special case underscore identifiers in callbacks.
- Fix to escape `_`s in callback type validation (addresses false positives in `always_specify_types`) (#147).

# 0.1.4

- Added `always_declare_return_types` lint rule (#146).
- Improved `always_specify_types` to detect missing types in declared identifiers and narrowed source range to the token.
- Added `implementation_imports` lint rule (#33).
- Test performance improvements.

# 0.1.3+5

- Added `always_specify_types` lint rule (#144).

# 0.1.3+4

- Fixed linter registry memory leaks.

# 0.1.3

- Fixed various options file parsing issues.

# 0.1.2

- Fixed false positives in `unnecessary_brace_in_string_interp` lint. Fix #112.

# 0.1.1

- Internal code and dependency constraint cleanup.

# 0.1.0

- Initial stable release.

# 0.0.2+1

- Added machine output option. Fix #69.
- Fixed resolution of files in `lib/` to use a `package:` URI. Fix #49.
- Tightened up `analyzer` package constraints.
- Fixed false positives in `one_member_abstracts` lint. Fix #64.

# 0.0.2

- Initial push to pub.
