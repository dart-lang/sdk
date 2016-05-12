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
