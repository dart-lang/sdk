# 0.1.34

## Features

* `non_constant_identifier_names` extended to include named constructors
* SDK constraint broadened to `2.0.0-dev.infinity`
* improved `prefer_final_fields` performance

## Fixes

* fixes to `unnecessary_overrides` (`noSuchMethod` handling, return type narrowing, special casing of documented `super` calls)
* fix to `non_constant_identifier_names` to handle identifiers with no name
* fixes to `prefer_const_constructors` to support list literals
* fixes to `recursive_getters`
* fixes to `cascade_invocations`

# 0.1.33

## Features

* new `prefer_const_constructors_in_immutables` lint
* new `always_put_required_named_parameters_first` lint
* new `prefer_asserts_in_initializer_lists` lint
* support for running in `--benchmark` mode
* new `prefer_single_quote_strings` lint

## Fixes

* docs for `avoid_setters_without_getters`
* fix to `directives_ordering` to work with part directives located after exports
* fixes to `cascade_invocations` false positives
* fixes to `literal_only_boolean_expressions` false positives
* fix to ensure `cascade_invocations` only lints method invocations if target is a simple identifier 
* fixes to `use_string_buffers` false positives
* fixes to `prefer_const_constructors`

# 0.1.32

* Lint stats (`-s`) output now sorted.

# 0.1.31

* New `prefer_foreach` lint.
* New `use_string_buffers` rule.
* New `unnecessary_overrides` rule.
* New `join_return_with_assignment_when_possible` rule.
* New `use_to_and_as_if_applicable` rule.
* New `avoid_setters_without_getters` rule.
* New `always_put_control_body_on_new_line` rule.
* New `avoid_positional_boolean_parameters` rule.
* New `always_require_non_null_named_parameters` rule.
* New `prefer_conditional_assignment` rule.
* New `avoid_types_on_closure_parameters` rule.
* New `always_put_control_body_on_new_line` rule.
* New `use_setters_to_change_properties` rule.
* New `avoid_returning_this` rule.
* New `avoid_annotating_with_dynamic_when_not_required` rule.
* New `prefer_constructors_over_static_methods` rule.
* New `avoid_returning_null` rule.
* New `avoid_classes_with_only_static_members` rule.
* New `avoid_null_checks_in_equality_operators` rule.
* New `avoid_catches_without_on_clauses` rule.
* New `avoid_catching_errors` rule.
* New `use_rethrow_when_possible` rule.
* Many lint fixes (notably `prefer_final_fields`, `unnecessary_lambdas`, `await_only_futures`, `cascade_invocations`, `avoid_types_on_closure_parameters`, and `overridden_fields`).
* Significant performance improvements for `prefer_interpolation_to_compose_strings`.
* New `unnecessary_this` rule.
* New `prefer_initializing_formals` rule.

# 0.1.30

* New `avoid_function_literals_in_foreach_calls` lint.
* New `avoid_slow_async_io` lint.
* New `cascade_invocations` lint.
* New `directives_ordering` lint.
* New `no_adjacent_strings_in_list` lint.
* New `no_duplicate_case_values` lint.
* New `omit_local_variable_types` lint.
* New `prefer_adjacent_string_concatenation` lint.
* New `prefer_collection_literals` lint.
* New `prefer_const_constructors` lint.
* New `prefer_contains` lint.
* New `prefer_expression_function_bodies` lint.
* New `prefer_function_declarations_over_variables` lint.
* New `prefer_initializing_formals` lint.
* New `prefer_interpolation_to_compose_strings` lint.
* New `prefer_is_empty` lint.
* New `recursive_getters` lint.
* New `unnecessary_brace_in_string_interps` lint.
* New `unnecessary_lambdas` lint.
* New `unnecessary_null_aware_assignments` lint.
* New `unnecessary_null_in_if_null_operators` lint.
* Miscellaneous bug fixes and codegen improvements.

# 0.1.29

* New `cascade_invocations` lint.
* Expand `await_only_futures` to accept classes that extend or implement `Future`.
* Improve camel case regular expression tests to accept `$`s.
* Fixes to `parameter_assignments` (improved getter handling and an NPE).

# 0.1.27

* Fixed cast exception in `dart_type_utilities` (dart-lang/sdk#27405).
* New `parameter_assignments` lint.
* New `prefer_final_fields` lint.
* New `prefer_final_locals` lint.
* Markdown link fixes in docs (#306).
* Miscellaneous solo test running fixes and introduction of `solo_debug` (#304).

# 0.1.26

* Updated tests to use package `test` (#302).

# 0.1.25

* Fixed false positive on `[]=` in `always_declare_return_types` (#300).
* New `invariant_booleans` lint.
* New `literal_only_boolean_expressions` lint.
* Fixed `camel_case_types` to allow `$` in identifiers (#290).

# 0.1.24

* Internal updates to keep up with changes in the analyzer package.
* Updated `close_sinks` to respect calls to `destroy` (#282).
* Fixed `only_throw_errors` to report on the expression not node.

# 0.1.23

* Removed `whitespace_around_ops` pending re-name and re-design (#249).

# 0.1.22

* Grinder support (`rule:rule_name` and `docs:location`) for rule stub and doc generation (respectively).
* Fix to allow leading underscores in `non_constant_identifier_names`.
* New `valid_regexps` lint (#277).
* New `whitespace_around_ops` lint (#249).
* Fix to `overridden_fields` to flag overridden static fields (#274).
* New `list_remove_unrelated_type` to detect passing a non-`T` value to `List.remove()`` (#271).
* New `empty_catches` lint to catch empty catch blocks (#43).
* Fixed `close_sinks` false positive (#268).
* `linter` support for `--strong` to allow for running linter in strong mode.

# 0.1.21

* New `only_throw_errors` lint.
* New lint to check for `empty_statements` (#259).
* Fixed NSME when file contents cannot be read (#260).
* Fixed unsafe cast in `iterable_contains_unrelated_type` (#267).

# 0.1.20

* New `cancel_subscriptions` lint.

# 0.1.19

* New `close_sinks` lint.
* Fixes to `iterable_contains_unrelated_type `.

# 0.1.18

* Fix NSME in `iterable_contains_unrelated_type` (#245).
* Fixed typo in `comment_references` error description.
* Fix `overriden_field` false positive (#246).
* Rename linter binary `lints` option to `rules` (#248).
* Help doc tweaks.

# 0.1.17

* Fix to `public_member_api_docs` to check for documented getters when checking setters (#237).
* New `iterable_contains_unrelated_type` lint to detect when `Iterable.contains` is invoked with an object of an unrelated type.
* New `comment_references` lint to ensure identifiers referenced in docs are in scope (#240).

# 0.1.16

* Fix for false positive in `overriden_field`s.
* New `unrelated_type_equality_checks` lint.
* Fix to accept `$` identifiers in string interpolation lint (#214).
* Update to new `plugin` API (`0.2.0`).
* Strong mode cleanup.

# 0.1.15

* Fix to allow simple getter/setters when a decl is ``@protected` (#215).
* Fix to not require type params in `is` checks (#227).
* Fix to not flag field formal identifiers in parameters (#224).
* Fix to respect filters when calculating error codes (#198).
* Fix to allow `const` and `final` vars to be initialized to null (#210).
* Fix to respect commented blocks in `empty_constructor_bodies` (#209).
* Fix to check types on list/map literals (#199).
* Fix to skip `main` when checking for API docs (#207).
* Fix to allow leading `$` in type names (#220).
* Fix to ignore private typedefs when checking for types (#216).
* New `test_types_in_equals` lint.
* New `await_only_futures` lint.
* New `throw_in_finally` lint.
* New `control_flow_in_finally` lint.

# 0.1.14

* Fix to respect `@optionalTypeArgs` (#196).
* Lint to warn if a field overrides or hides other field.
* Fix to allow single char UPPER_CASE non-constants (#201).
* Fix to accept casts to dynamic (#195).

# 0.1.13

* Fix to skip overriding members in API doc checks (`public_member_api_docs`).
* Fix to suppress lints on synthetic nodes/tokens (#193).
* Message fixes (`annotate_overrides`, `public_member_api_docs`).
* Fix to exclude setters from return type checks (#192).

# 0.1.12

* Fix to address `LibraryNames` regexp that in pathological cases went exponential.

# 0.1.11

* Doc generation improvements (now with options samples).
* Lint to sort unnamed constructors first (#187).
* Lint to ensure public members have API docs (#188).
* Lint to ensure constructors are sorted first (#186).
* Lint for `hashCode` and `==` (#168).
* Lint to detect un-annotated overrides (#167).
* Fix to ignore underscores in public APIs (#153).
* Lint to check for return types on setters (#122).
* Lint to flag missing type params (#156).
* Lint to avoid inits to `null` (#160).

# 0.1.10

* Updated to use `analyzer` `0.27.0`.
* Updated options processing to handle untyped maps (dart-lang/sdk#25126).

# 0.1.9

* Fix `type_annotate_public_apis` to properly handle getters/setters (#151; dart-lang/sdk#25092).

# 0.1.8

* Fix to protect against errors in linting invalid source (dart-lang/sdk#24910).
* Added `avoid_empty_else` lint rule (dart-lang/sdk#224936).

# 0.1.7

* Fix to `package_api_docs` (dart-lang/sdk#24947; #154).

# 0.1.6

* Fix to `package_prefixed_library_names` (dart-lang/sdk#24947; #154).

# 0.1.5

* Added `prefer_is_not_empty` lint rule (#143).
* Added `type_annotate_public_apis` lint rule (#24).
* Added `avoid_as` lint rule (#145).
* Fixed `non_constant_identifier_names` rule to special case underscore identifiers in callbacks.
* Fix to escape `_`s in callback type validation (addresses false positives in `always_specify_types`) (#147).

# 0.1.4

* Added `always_declare_return_types` lint rule (#146).
* Improved `always_specify_types` to detect missing types in declared identifiers and narrowed source range to the token.
* Added `implementation_imports` lint rule (#33).
* Test performance improvements.

# 0.1.3+5

* Added `always_specify_types` lint rule (#144).

# 0.1.3+4

* Fixed linter registry memory leaks.

# 0.1.3

* Fixed various options file parsing issues.

# 0.1.2

* Fixed false positives in `unnecessary_brace_in_string_interp` lint. Fix #112.

# 0.1.1

* Internal code and dependency constraint cleanup.

# 0.1.0

* Initial stable release.

# 0.0.2+1

* Added machine output option. Fix #69.
* Fixed resolution of files in `lib/` to use a `package:` URI. Fix #49.
* Tightened up `analyzer` package constraints.
* Fixed false positives in `one_member_abstracts` lint. Fix #64.

# 0.0.2

* Initial push to pub.
