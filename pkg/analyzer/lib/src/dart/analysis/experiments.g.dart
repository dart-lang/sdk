//
// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'tools/experimental_features.yaml' and run
// 'dart pkg/analyzer/tool/experiments/generate.dart' to update.

part of 'experiments.dart';

// We allow some snake_case and SCREAMING_SNAKE_CASE identifiers in generated
// code, as they match names declared in the source configuration files.
// ignore_for_file: constant_identifier_names

/// The current version of the Dart language (or, for non-stable releases, the
/// version of the language currently in the process of being developed).
const _currentVersion = '3.7.0';

/// A map containing information about all known experimental flags.
final _knownFeatures = <String, ExperimentalFeature>{
  EnableString.augmentations: ExperimentalFeatures.augmentations,
  EnableString.class_modifiers: ExperimentalFeatures.class_modifiers,
  EnableString.const_functions: ExperimentalFeatures.const_functions,
  EnableString.constant_update_2018: ExperimentalFeatures.constant_update_2018,
  EnableString.constructor_tearoffs: ExperimentalFeatures.constructor_tearoffs,
  EnableString.control_flow_collections:
      ExperimentalFeatures.control_flow_collections,
  EnableString.digit_separators: ExperimentalFeatures.digit_separators,
  EnableString.enhanced_enums: ExperimentalFeatures.enhanced_enums,
  EnableString.enhanced_parts: ExperimentalFeatures.enhanced_parts,
  EnableString.extension_methods: ExperimentalFeatures.extension_methods,
  EnableString.generic_metadata: ExperimentalFeatures.generic_metadata,
  EnableString.inference_update_1: ExperimentalFeatures.inference_update_1,
  EnableString.inference_update_2: ExperimentalFeatures.inference_update_2,
  EnableString.inference_update_3: ExperimentalFeatures.inference_update_3,
  EnableString.inference_update_4: ExperimentalFeatures.inference_update_4,
  EnableString.inference_using_bounds:
      ExperimentalFeatures.inference_using_bounds,
  EnableString.inline_class: ExperimentalFeatures.inline_class,
  EnableString.macros: ExperimentalFeatures.macros,
  EnableString.named_arguments_anywhere:
      ExperimentalFeatures.named_arguments_anywhere,
  EnableString.native_assets: ExperimentalFeatures.native_assets,
  EnableString.non_nullable: ExperimentalFeatures.non_nullable,
  EnableString.nonfunction_type_aliases:
      ExperimentalFeatures.nonfunction_type_aliases,
  EnableString.null_aware_elements: ExperimentalFeatures.null_aware_elements,
  EnableString.patterns: ExperimentalFeatures.patterns,
  EnableString.record_use: ExperimentalFeatures.record_use,
  EnableString.records: ExperimentalFeatures.records,
  EnableString.sealed_class: ExperimentalFeatures.sealed_class,
  EnableString.set_literals: ExperimentalFeatures.set_literals,
  EnableString.spread_collections: ExperimentalFeatures.spread_collections,
  EnableString.super_parameters: ExperimentalFeatures.super_parameters,
  EnableString.test_experiment: ExperimentalFeatures.test_experiment,
  EnableString.triple_shift: ExperimentalFeatures.triple_shift,
  EnableString.unnamed_libraries: ExperimentalFeatures.unnamed_libraries,
  EnableString.unquoted_imports: ExperimentalFeatures.unquoted_imports,
  EnableString.variance: ExperimentalFeatures.variance,
  EnableString.wildcard_variables: ExperimentalFeatures.wildcard_variables,
};

/// Constant strings for enabling each of the currently known experimental
/// flags.
class EnableString {
  /// String to enable the experiment "augmentations"
  static const String augmentations = 'augmentations';

  /// String to enable the experiment "class-modifiers"
  static const String class_modifiers = 'class-modifiers';

  /// String to enable the experiment "const-functions"
  static const String const_functions = 'const-functions';

  /// String to enable the experiment "constant-update-2018"
  static const String constant_update_2018 = 'constant-update-2018';

  /// String to enable the experiment "constructor-tearoffs"
  static const String constructor_tearoffs = 'constructor-tearoffs';

  /// String to enable the experiment "control-flow-collections"
  static const String control_flow_collections = 'control-flow-collections';

  /// String to enable the experiment "digit-separators"
  static const String digit_separators = 'digit-separators';

  /// String to enable the experiment "enhanced-enums"
  static const String enhanced_enums = 'enhanced-enums';

  /// String to enable the experiment "enhanced-parts"
  static const String enhanced_parts = 'enhanced-parts';

  /// String to enable the experiment "extension-methods"
  static const String extension_methods = 'extension-methods';

  /// String to enable the experiment "generic-metadata"
  static const String generic_metadata = 'generic-metadata';

  /// String to enable the experiment "inference-update-1"
  static const String inference_update_1 = 'inference-update-1';

  /// String to enable the experiment "inference-update-2"
  static const String inference_update_2 = 'inference-update-2';

  /// String to enable the experiment "inference-update-3"
  static const String inference_update_3 = 'inference-update-3';

  /// String to enable the experiment "inference-update-4"
  static const String inference_update_4 = 'inference-update-4';

  /// String to enable the experiment "inference-using-bounds"
  static const String inference_using_bounds = 'inference-using-bounds';

  /// String to enable the experiment "inline-class"
  static const String inline_class = 'inline-class';

  /// String to enable the experiment "macros"
  static const String macros = 'macros';

  /// String to enable the experiment "named-arguments-anywhere"
  static const String named_arguments_anywhere = 'named-arguments-anywhere';

  /// String to enable the experiment "native-assets"
  static const String native_assets = 'native-assets';

  /// String to enable the experiment "non-nullable"
  static const String non_nullable = 'non-nullable';

  /// String to enable the experiment "nonfunction-type-aliases"
  static const String nonfunction_type_aliases = 'nonfunction-type-aliases';

  /// String to enable the experiment "null-aware-elements"
  static const String null_aware_elements = 'null-aware-elements';

  /// String to enable the experiment "patterns"
  static const String patterns = 'patterns';

  /// String to enable the experiment "record-use"
  static const String record_use = 'record-use';

  /// String to enable the experiment "records"
  static const String records = 'records';

  /// String to enable the experiment "sealed-class"
  static const String sealed_class = 'sealed-class';

  /// String to enable the experiment "set-literals"
  static const String set_literals = 'set-literals';

  /// String to enable the experiment "spread-collections"
  static const String spread_collections = 'spread-collections';

  /// String to enable the experiment "super-parameters"
  static const String super_parameters = 'super-parameters';

  /// String to enable the experiment "test-experiment"
  static const String test_experiment = 'test-experiment';

  /// String to enable the experiment "triple-shift"
  static const String triple_shift = 'triple-shift';

  /// String to enable the experiment "unnamed-libraries"
  static const String unnamed_libraries = 'unnamed-libraries';

  /// String to enable the experiment "unquoted-imports"
  static const String unquoted_imports = 'unquoted-imports';

  /// String to enable the experiment "variance"
  static const String variance = 'variance';

  /// String to enable the experiment "wildcard-variables"
  static const String wildcard_variables = 'wildcard-variables';
}

class ExperimentalFeatures {
  static final augmentations = ExperimentalFeature(
    index: 0,
    enableString: EnableString.augmentations,
    isEnabledByDefault: IsEnabledByDefault.augmentations,
    isExpired: IsExpired.augmentations,
    documentation: 'Augmentations - enhancing declarations from outside',
    experimentalReleaseVersion: null,
    releaseVersion: null,
  );

  static final class_modifiers = ExperimentalFeature(
    index: 1,
    enableString: EnableString.class_modifiers,
    isEnabledByDefault: IsEnabledByDefault.class_modifiers,
    isExpired: IsExpired.class_modifiers,
    documentation: 'Class modifiers',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('3.0.0'),
  );

  static final const_functions = ExperimentalFeature(
    index: 2,
    enableString: EnableString.const_functions,
    isEnabledByDefault: IsEnabledByDefault.const_functions,
    isExpired: IsExpired.const_functions,
    documentation:
        'Allow more of the Dart language to be executed in const expressions.',
    experimentalReleaseVersion: null,
    releaseVersion: null,
  );

  static final constant_update_2018 = ExperimentalFeature(
    index: 3,
    enableString: EnableString.constant_update_2018,
    isEnabledByDefault: IsEnabledByDefault.constant_update_2018,
    isExpired: IsExpired.constant_update_2018,
    documentation: 'Enhanced constant expressions',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('2.0.0'),
  );

  static final constructor_tearoffs = ExperimentalFeature(
    index: 4,
    enableString: EnableString.constructor_tearoffs,
    isEnabledByDefault: IsEnabledByDefault.constructor_tearoffs,
    isExpired: IsExpired.constructor_tearoffs,
    documentation:
        'Allow constructor tear-offs and explicit generic instantiations.',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('2.15.0'),
  );

  static final control_flow_collections = ExperimentalFeature(
    index: 5,
    enableString: EnableString.control_flow_collections,
    isEnabledByDefault: IsEnabledByDefault.control_flow_collections,
    isExpired: IsExpired.control_flow_collections,
    documentation: 'Control Flow Collections',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('2.0.0'),
  );

  static final digit_separators = ExperimentalFeature(
    index: 6,
    enableString: EnableString.digit_separators,
    isEnabledByDefault: IsEnabledByDefault.digit_separators,
    isExpired: IsExpired.digit_separators,
    documentation: 'Number literals with digit separators.',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('3.6.0'),
  );

  static final enhanced_enums = ExperimentalFeature(
    index: 7,
    enableString: EnableString.enhanced_enums,
    isEnabledByDefault: IsEnabledByDefault.enhanced_enums,
    isExpired: IsExpired.enhanced_enums,
    documentation: 'Enhanced Enums',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('2.17.0'),
  );

  static final enhanced_parts = ExperimentalFeature(
    index: 8,
    enableString: EnableString.enhanced_parts,
    isEnabledByDefault: IsEnabledByDefault.enhanced_parts,
    isExpired: IsExpired.enhanced_parts,
    documentation: 'Generalize parts to be nested and have exports/imports.',
    experimentalReleaseVersion: null,
    releaseVersion: null,
  );

  static final extension_methods = ExperimentalFeature(
    index: 9,
    enableString: EnableString.extension_methods,
    isEnabledByDefault: IsEnabledByDefault.extension_methods,
    isExpired: IsExpired.extension_methods,
    documentation: 'Extension Methods',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('2.6.0'),
  );

  static final generic_metadata = ExperimentalFeature(
    index: 10,
    enableString: EnableString.generic_metadata,
    isEnabledByDefault: IsEnabledByDefault.generic_metadata,
    isExpired: IsExpired.generic_metadata,
    documentation:
        'Allow annotations to accept type arguments; also allow generic function types as type arguments.',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('2.14.0'),
  );

  static final inference_update_1 = ExperimentalFeature(
    index: 11,
    enableString: EnableString.inference_update_1,
    isEnabledByDefault: IsEnabledByDefault.inference_update_1,
    isExpired: IsExpired.inference_update_1,
    documentation:
        'Horizontal type inference for function expressions passed to generic invocations.',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('2.18.0'),
  );

  static final inference_update_2 = ExperimentalFeature(
    index: 12,
    enableString: EnableString.inference_update_2,
    isEnabledByDefault: IsEnabledByDefault.inference_update_2,
    isExpired: IsExpired.inference_update_2,
    documentation: 'Type promotion for fields',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('3.2.0'),
  );

  static final inference_update_3 = ExperimentalFeature(
    index: 13,
    enableString: EnableString.inference_update_3,
    isEnabledByDefault: IsEnabledByDefault.inference_update_3,
    isExpired: IsExpired.inference_update_3,
    documentation:
        'Better handling of conditional expressions, and switch expressions.',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('3.4.0'),
  );

  static final inference_update_4 = ExperimentalFeature(
    index: 14,
    enableString: EnableString.inference_update_4,
    isEnabledByDefault: IsEnabledByDefault.inference_update_4,
    isExpired: IsExpired.inference_update_4,
    documentation: 'A bundle of updates to type inference.',
    experimentalReleaseVersion: null,
    releaseVersion: null,
  );

  static final inference_using_bounds = ExperimentalFeature(
    index: 15,
    enableString: EnableString.inference_using_bounds,
    isEnabledByDefault: IsEnabledByDefault.inference_using_bounds,
    isExpired: IsExpired.inference_using_bounds,
    documentation:
        'Use type parameter bounds more extensively in type inference.',
    experimentalReleaseVersion: null,
    releaseVersion: null,
  );

  static final inline_class = ExperimentalFeature(
    index: 16,
    enableString: EnableString.inline_class,
    isEnabledByDefault: IsEnabledByDefault.inline_class,
    isExpired: IsExpired.inline_class,
    documentation: 'Extension Types',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('3.3.0'),
  );

  static final macros = ExperimentalFeature(
    index: 17,
    enableString: EnableString.macros,
    isEnabledByDefault: IsEnabledByDefault.macros,
    isExpired: IsExpired.macros,
    documentation: 'Static meta-programming',
    experimentalReleaseVersion: Version.parse('3.3.0'),
    releaseVersion: null,
  );

  static final named_arguments_anywhere = ExperimentalFeature(
    index: 18,
    enableString: EnableString.named_arguments_anywhere,
    isEnabledByDefault: IsEnabledByDefault.named_arguments_anywhere,
    isExpired: IsExpired.named_arguments_anywhere,
    documentation: 'Named Arguments Anywhere',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('2.17.0'),
  );

  static final native_assets = ExperimentalFeature(
    index: 19,
    enableString: EnableString.native_assets,
    isEnabledByDefault: IsEnabledByDefault.native_assets,
    isExpired: IsExpired.native_assets,
    documentation: 'Compile and bundle native assets.',
    experimentalReleaseVersion: null,
    releaseVersion: null,
  );

  static final non_nullable = ExperimentalFeature(
    index: 20,
    enableString: EnableString.non_nullable,
    isEnabledByDefault: IsEnabledByDefault.non_nullable,
    isExpired: IsExpired.non_nullable,
    documentation: 'Non Nullable by default',
    experimentalReleaseVersion: Version.parse('2.10.0'),
    releaseVersion: Version.parse('2.12.0'),
  );

  static final nonfunction_type_aliases = ExperimentalFeature(
    index: 21,
    enableString: EnableString.nonfunction_type_aliases,
    isEnabledByDefault: IsEnabledByDefault.nonfunction_type_aliases,
    isExpired: IsExpired.nonfunction_type_aliases,
    documentation: 'Type aliases define a <type>, not just a <functionType>',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('2.13.0'),
  );

  static final null_aware_elements = ExperimentalFeature(
    index: 22,
    enableString: EnableString.null_aware_elements,
    isEnabledByDefault: IsEnabledByDefault.null_aware_elements,
    isExpired: IsExpired.null_aware_elements,
    documentation: 'Null-aware elements and map entries in collections.',
    experimentalReleaseVersion: null,
    releaseVersion: null,
  );

  static final patterns = ExperimentalFeature(
    index: 23,
    enableString: EnableString.patterns,
    isEnabledByDefault: IsEnabledByDefault.patterns,
    isExpired: IsExpired.patterns,
    documentation: 'Patterns',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('3.0.0'),
  );

  static final record_use = ExperimentalFeature(
    index: 24,
    enableString: EnableString.record_use,
    isEnabledByDefault: IsEnabledByDefault.record_use,
    isExpired: IsExpired.record_use,
    documentation: 'Output arguments used by static functions.',
    experimentalReleaseVersion: null,
    releaseVersion: null,
  );

  static final records = ExperimentalFeature(
    index: 25,
    enableString: EnableString.records,
    isEnabledByDefault: IsEnabledByDefault.records,
    isExpired: IsExpired.records,
    documentation: 'Records',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('3.0.0'),
  );

  static final sealed_class = ExperimentalFeature(
    index: 26,
    enableString: EnableString.sealed_class,
    isEnabledByDefault: IsEnabledByDefault.sealed_class,
    isExpired: IsExpired.sealed_class,
    documentation: 'Sealed class',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('3.0.0'),
  );

  static final set_literals = ExperimentalFeature(
    index: 27,
    enableString: EnableString.set_literals,
    isEnabledByDefault: IsEnabledByDefault.set_literals,
    isExpired: IsExpired.set_literals,
    documentation: 'Set Literals',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('2.0.0'),
  );

  static final spread_collections = ExperimentalFeature(
    index: 28,
    enableString: EnableString.spread_collections,
    isEnabledByDefault: IsEnabledByDefault.spread_collections,
    isExpired: IsExpired.spread_collections,
    documentation: 'Spread Collections',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('2.0.0'),
  );

  static final super_parameters = ExperimentalFeature(
    index: 29,
    enableString: EnableString.super_parameters,
    isEnabledByDefault: IsEnabledByDefault.super_parameters,
    isExpired: IsExpired.super_parameters,
    documentation: 'Super-Initializer Parameters',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('2.17.0'),
  );

  static final test_experiment = ExperimentalFeature(
    index: 30,
    enableString: EnableString.test_experiment,
    isEnabledByDefault: IsEnabledByDefault.test_experiment,
    isExpired: IsExpired.test_experiment,
    documentation:
        'Has no effect. Can be used for testing the --enable-experiment command line functionality.',
    experimentalReleaseVersion: null,
    releaseVersion: null,
  );

  static final triple_shift = ExperimentalFeature(
    index: 31,
    enableString: EnableString.triple_shift,
    isEnabledByDefault: IsEnabledByDefault.triple_shift,
    isExpired: IsExpired.triple_shift,
    documentation: 'Triple-shift operator',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('2.14.0'),
  );

  static final unnamed_libraries = ExperimentalFeature(
    index: 32,
    enableString: EnableString.unnamed_libraries,
    isEnabledByDefault: IsEnabledByDefault.unnamed_libraries,
    isExpired: IsExpired.unnamed_libraries,
    documentation: 'Unnamed libraries',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('2.19.0'),
  );

  static final unquoted_imports = ExperimentalFeature(
    index: 33,
    enableString: EnableString.unquoted_imports,
    isEnabledByDefault: IsEnabledByDefault.unquoted_imports,
    isExpired: IsExpired.unquoted_imports,
    documentation: 'Shorter import syntax.',
    experimentalReleaseVersion: null,
    releaseVersion: null,
  );

  static final variance = ExperimentalFeature(
    index: 34,
    enableString: EnableString.variance,
    isEnabledByDefault: IsEnabledByDefault.variance,
    isExpired: IsExpired.variance,
    documentation: 'Sound variance',
    experimentalReleaseVersion: null,
    releaseVersion: null,
  );

  static final wildcard_variables = ExperimentalFeature(
    index: 35,
    enableString: EnableString.wildcard_variables,
    isEnabledByDefault: IsEnabledByDefault.wildcard_variables,
    isExpired: IsExpired.wildcard_variables,
    documentation:
        'Local declarations and parameters named `_` are non-binding.',
    experimentalReleaseVersion: null,
    releaseVersion: null,
  );
}

/// Constant bools indicating whether each experimental flag is currently
/// enabled by default.
class IsEnabledByDefault {
  /// Default state of the experiment "augmentations"
  static const bool augmentations = false;

  /// Default state of the experiment "class-modifiers"
  static const bool class_modifiers = true;

  /// Default state of the experiment "const-functions"
  static const bool const_functions = false;

  /// Default state of the experiment "constant-update-2018"
  static const bool constant_update_2018 = true;

  /// Default state of the experiment "constructor-tearoffs"
  static const bool constructor_tearoffs = true;

  /// Default state of the experiment "control-flow-collections"
  static const bool control_flow_collections = true;

  /// Default state of the experiment "digit-separators"
  static const bool digit_separators = true;

  /// Default state of the experiment "enhanced-enums"
  static const bool enhanced_enums = true;

  /// Default state of the experiment "enhanced-parts"
  static const bool enhanced_parts = false;

  /// Default state of the experiment "extension-methods"
  static const bool extension_methods = true;

  /// Default state of the experiment "generic-metadata"
  static const bool generic_metadata = true;

  /// Default state of the experiment "inference-update-1"
  static const bool inference_update_1 = true;

  /// Default state of the experiment "inference-update-2"
  static const bool inference_update_2 = true;

  /// Default state of the experiment "inference-update-3"
  static const bool inference_update_3 = true;

  /// Default state of the experiment "inference-update-4"
  static const bool inference_update_4 = false;

  /// Default state of the experiment "inference-using-bounds"
  static const bool inference_using_bounds = false;

  /// Default state of the experiment "inline-class"
  static const bool inline_class = true;

  /// Default state of the experiment "macros"
  static const bool macros = false;

  /// Default state of the experiment "named-arguments-anywhere"
  static const bool named_arguments_anywhere = true;

  /// Default state of the experiment "native-assets"
  static const bool native_assets = false;

  /// Default state of the experiment "non-nullable"
  static const bool non_nullable = true;

  /// Default state of the experiment "nonfunction-type-aliases"
  static const bool nonfunction_type_aliases = true;

  /// Default state of the experiment "null-aware-elements"
  static const bool null_aware_elements = false;

  /// Default state of the experiment "patterns"
  static const bool patterns = true;

  /// Default state of the experiment "record-use"
  static const bool record_use = false;

  /// Default state of the experiment "records"
  static const bool records = true;

  /// Default state of the experiment "sealed-class"
  static const bool sealed_class = true;

  /// Default state of the experiment "set-literals"
  static const bool set_literals = true;

  /// Default state of the experiment "spread-collections"
  static const bool spread_collections = true;

  /// Default state of the experiment "super-parameters"
  static const bool super_parameters = true;

  /// Default state of the experiment "test-experiment"
  static const bool test_experiment = false;

  /// Default state of the experiment "triple-shift"
  static const bool triple_shift = true;

  /// Default state of the experiment "unnamed-libraries"
  static const bool unnamed_libraries = true;

  /// Default state of the experiment "unquoted-imports"
  static const bool unquoted_imports = false;

  /// Default state of the experiment "variance"
  static const bool variance = false;

  /// Default state of the experiment "wildcard-variables"
  static const bool wildcard_variables = false;
}

/// Constant bools indicating whether each experimental flag is currently
/// expired (meaning its enable/disable status can no longer be altered from the
/// value in [IsEnabledByDefault]).
class IsExpired {
  /// Expiration status of the experiment "augmentations"
  static const bool augmentations = false;

  /// Expiration status of the experiment "class-modifiers"
  static const bool class_modifiers = true;

  /// Expiration status of the experiment "const-functions"
  static const bool const_functions = false;

  /// Expiration status of the experiment "constant-update-2018"
  static const bool constant_update_2018 = true;

  /// Expiration status of the experiment "constructor-tearoffs"
  static const bool constructor_tearoffs = true;

  /// Expiration status of the experiment "control-flow-collections"
  static const bool control_flow_collections = true;

  /// Expiration status of the experiment "digit-separators"
  static const bool digit_separators = false;

  /// Expiration status of the experiment "enhanced-enums"
  static const bool enhanced_enums = true;

  /// Expiration status of the experiment "enhanced-parts"
  static const bool enhanced_parts = false;

  /// Expiration status of the experiment "extension-methods"
  static const bool extension_methods = true;

  /// Expiration status of the experiment "generic-metadata"
  static const bool generic_metadata = true;

  /// Expiration status of the experiment "inference-update-1"
  static const bool inference_update_1 = true;

  /// Expiration status of the experiment "inference-update-2"
  static const bool inference_update_2 = true;

  /// Expiration status of the experiment "inference-update-3"
  static const bool inference_update_3 = true;

  /// Expiration status of the experiment "inference-update-4"
  static const bool inference_update_4 = false;

  /// Expiration status of the experiment "inference-using-bounds"
  static const bool inference_using_bounds = false;

  /// Expiration status of the experiment "inline-class"
  static const bool inline_class = true;

  /// Expiration status of the experiment "macros"
  static const bool macros = false;

  /// Expiration status of the experiment "named-arguments-anywhere"
  static const bool named_arguments_anywhere = true;

  /// Expiration status of the experiment "native-assets"
  static const bool native_assets = false;

  /// Expiration status of the experiment "non-nullable"
  static const bool non_nullable = true;

  /// Expiration status of the experiment "nonfunction-type-aliases"
  static const bool nonfunction_type_aliases = true;

  /// Expiration status of the experiment "null-aware-elements"
  static const bool null_aware_elements = false;

  /// Expiration status of the experiment "patterns"
  static const bool patterns = true;

  /// Expiration status of the experiment "record-use"
  static const bool record_use = false;

  /// Expiration status of the experiment "records"
  static const bool records = true;

  /// Expiration status of the experiment "sealed-class"
  static const bool sealed_class = true;

  /// Expiration status of the experiment "set-literals"
  static const bool set_literals = true;

  /// Expiration status of the experiment "spread-collections"
  static const bool spread_collections = true;

  /// Expiration status of the experiment "super-parameters"
  static const bool super_parameters = true;

  /// Expiration status of the experiment "test-experiment"
  static const bool test_experiment = false;

  /// Expiration status of the experiment "triple-shift"
  static const bool triple_shift = true;

  /// Expiration status of the experiment "unnamed-libraries"
  static const bool unnamed_libraries = true;

  /// Expiration status of the experiment "unquoted-imports"
  static const bool unquoted_imports = false;

  /// Expiration status of the experiment "variance"
  static const bool variance = false;

  /// Expiration status of the experiment "wildcard-variables"
  static const bool wildcard_variables = false;
}

mixin _CurrentState {
  /// Current state for the flag "augmentations"
  bool get augmentations => isEnabled(ExperimentalFeatures.augmentations);

  /// Current state for the flag "class-modifiers"
  bool get class_modifiers => isEnabled(ExperimentalFeatures.class_modifiers);

  /// Current state for the flag "const-functions"
  bool get const_functions => isEnabled(ExperimentalFeatures.const_functions);

  /// Current state for the flag "constant-update-2018"
  bool get constant_update_2018 =>
      isEnabled(ExperimentalFeatures.constant_update_2018);

  /// Current state for the flag "constructor-tearoffs"
  bool get constructor_tearoffs =>
      isEnabled(ExperimentalFeatures.constructor_tearoffs);

  /// Current state for the flag "control-flow-collections"
  bool get control_flow_collections =>
      isEnabled(ExperimentalFeatures.control_flow_collections);

  /// Current state for the flag "digit-separators"
  bool get digit_separators => isEnabled(ExperimentalFeatures.digit_separators);

  /// Current state for the flag "enhanced-enums"
  bool get enhanced_enums => isEnabled(ExperimentalFeatures.enhanced_enums);

  /// Current state for the flag "enhanced-parts"
  bool get enhanced_parts => isEnabled(ExperimentalFeatures.enhanced_parts);

  /// Current state for the flag "extension-methods"
  bool get extension_methods =>
      isEnabled(ExperimentalFeatures.extension_methods);

  /// Current state for the flag "generic-metadata"
  bool get generic_metadata => isEnabled(ExperimentalFeatures.generic_metadata);

  /// Current state for the flag "inference-update-1"
  bool get inference_update_1 =>
      isEnabled(ExperimentalFeatures.inference_update_1);

  /// Current state for the flag "inference-update-2"
  bool get inference_update_2 =>
      isEnabled(ExperimentalFeatures.inference_update_2);

  /// Current state for the flag "inference-update-3"
  bool get inference_update_3 =>
      isEnabled(ExperimentalFeatures.inference_update_3);

  /// Current state for the flag "inference-update-4"
  bool get inference_update_4 =>
      isEnabled(ExperimentalFeatures.inference_update_4);

  /// Current state for the flag "inference-using-bounds"
  bool get inference_using_bounds =>
      isEnabled(ExperimentalFeatures.inference_using_bounds);

  /// Current state for the flag "inline-class"
  bool get inline_class => isEnabled(ExperimentalFeatures.inline_class);

  /// Current state for the flag "macros"
  bool get macros => isEnabled(ExperimentalFeatures.macros);

  /// Current state for the flag "named-arguments-anywhere"
  bool get named_arguments_anywhere =>
      isEnabled(ExperimentalFeatures.named_arguments_anywhere);

  /// Current state for the flag "native-assets"
  bool get native_assets => isEnabled(ExperimentalFeatures.native_assets);

  /// Current state for the flag "non-nullable"
  bool get non_nullable => isEnabled(ExperimentalFeatures.non_nullable);

  /// Current state for the flag "nonfunction-type-aliases"
  bool get nonfunction_type_aliases =>
      isEnabled(ExperimentalFeatures.nonfunction_type_aliases);

  /// Current state for the flag "null-aware-elements"
  bool get null_aware_elements =>
      isEnabled(ExperimentalFeatures.null_aware_elements);

  /// Current state for the flag "patterns"
  bool get patterns => isEnabled(ExperimentalFeatures.patterns);

  /// Current state for the flag "record-use"
  bool get record_use => isEnabled(ExperimentalFeatures.record_use);

  /// Current state for the flag "records"
  bool get records => isEnabled(ExperimentalFeatures.records);

  /// Current state for the flag "sealed-class"
  bool get sealed_class => isEnabled(ExperimentalFeatures.sealed_class);

  /// Current state for the flag "set-literals"
  bool get set_literals => isEnabled(ExperimentalFeatures.set_literals);

  /// Current state for the flag "spread-collections"
  bool get spread_collections =>
      isEnabled(ExperimentalFeatures.spread_collections);

  /// Current state for the flag "super-parameters"
  bool get super_parameters => isEnabled(ExperimentalFeatures.super_parameters);

  /// Current state for the flag "test-experiment"
  bool get test_experiment => isEnabled(ExperimentalFeatures.test_experiment);

  /// Current state for the flag "triple-shift"
  bool get triple_shift => isEnabled(ExperimentalFeatures.triple_shift);

  /// Current state for the flag "unnamed-libraries"
  bool get unnamed_libraries =>
      isEnabled(ExperimentalFeatures.unnamed_libraries);

  /// Current state for the flag "unquoted-imports"
  bool get unquoted_imports => isEnabled(ExperimentalFeatures.unquoted_imports);

  /// Current state for the flag "variance"
  bool get variance => isEnabled(ExperimentalFeatures.variance);

  /// Current state for the flag "wildcard-variables"
  bool get wildcard_variables =>
      isEnabled(ExperimentalFeatures.wildcard_variables);

  bool isEnabled(covariant ExperimentalFeature feature);
}
