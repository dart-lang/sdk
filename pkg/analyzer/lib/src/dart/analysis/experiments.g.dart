//
// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'tools/experimental_features.yaml' and run
// 'dart pkg/analyzer/tool/experiments/generate.dart' to update.

part of 'experiments.dart';

/// The current version of the Dart language (or, for non-stable releases, the
/// version of the language currently in the process of being developed).
const _currentVersion = '2.12.0';

/// A map containing information about all known experimental flags.
final _knownFeatures = <String, ExperimentalFeature>{
  EnableString.constant_update_2018: ExperimentalFeatures.constant_update_2018,
  EnableString.control_flow_collections:
      ExperimentalFeatures.control_flow_collections,
  EnableString.extension_methods: ExperimentalFeatures.extension_methods,
  EnableString.non_nullable: ExperimentalFeatures.non_nullable,
  EnableString.nonfunction_type_aliases:
      ExperimentalFeatures.nonfunction_type_aliases,
  EnableString.set_literals: ExperimentalFeatures.set_literals,
  EnableString.spread_collections: ExperimentalFeatures.spread_collections,
  EnableString.triple_shift: ExperimentalFeatures.triple_shift,
  EnableString.value_class: ExperimentalFeatures.value_class,
  EnableString.variance: ExperimentalFeatures.variance,
};

/// Constant strings for enabling each of the currently known experimental
/// flags.
class EnableString {
  /// String to enable the experiment "constant-update-2018"
  static const String constant_update_2018 = 'constant-update-2018';

  /// String to enable the experiment "control-flow-collections"
  static const String control_flow_collections = 'control-flow-collections';

  /// String to enable the experiment "extension-methods"
  static const String extension_methods = 'extension-methods';

  /// String to enable the experiment "non-nullable"
  static const String non_nullable = 'non-nullable';

  /// String to enable the experiment "nonfunction-type-aliases"
  static const String nonfunction_type_aliases = 'nonfunction-type-aliases';

  /// String to enable the experiment "set-literals"
  static const String set_literals = 'set-literals';

  /// String to enable the experiment "spread-collections"
  static const String spread_collections = 'spread-collections';

  /// String to enable the experiment "triple-shift"
  static const String triple_shift = 'triple-shift';

  /// String to enable the experiment "value-class"
  static const String value_class = 'value-class';

  /// String to enable the experiment "variance"
  static const String variance = 'variance';
}

class ExperimentalFeatures {
  static final constant_update_2018 = ExperimentalFeature(
    index: 0,
    enableString: EnableString.constant_update_2018,
    isEnabledByDefault: IsEnabledByDefault.constant_update_2018,
    isExpired: IsExpired.constant_update_2018,
    documentation: 'Enhanced constant expressions',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('2.0.0'),
  );

  static final control_flow_collections = ExperimentalFeature(
    index: 1,
    enableString: EnableString.control_flow_collections,
    isEnabledByDefault: IsEnabledByDefault.control_flow_collections,
    isExpired: IsExpired.control_flow_collections,
    documentation: 'Control Flow Collections',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('2.0.0'),
  );

  static final extension_methods = ExperimentalFeature(
    index: 2,
    enableString: EnableString.extension_methods,
    isEnabledByDefault: IsEnabledByDefault.extension_methods,
    isExpired: IsExpired.extension_methods,
    documentation: 'Extension Methods',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('2.6.0'),
  );

  static final non_nullable = ExperimentalFeature(
    index: 3,
    enableString: EnableString.non_nullable,
    isEnabledByDefault: IsEnabledByDefault.non_nullable,
    isExpired: IsExpired.non_nullable,
    documentation: 'Non Nullable by default',
    experimentalReleaseVersion: Version.parse('2.10.0'),
    releaseVersion: Version.parse('2.12.0'),
  );

  static final nonfunction_type_aliases = ExperimentalFeature(
    index: 4,
    enableString: EnableString.nonfunction_type_aliases,
    isEnabledByDefault: IsEnabledByDefault.nonfunction_type_aliases,
    isExpired: IsExpired.nonfunction_type_aliases,
    documentation: 'Type aliases define a <type>, not just a <functionType>',
    experimentalReleaseVersion: null,
    releaseVersion: null,
  );

  static final set_literals = ExperimentalFeature(
    index: 5,
    enableString: EnableString.set_literals,
    isEnabledByDefault: IsEnabledByDefault.set_literals,
    isExpired: IsExpired.set_literals,
    documentation: 'Set Literals',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('2.0.0'),
  );

  static final spread_collections = ExperimentalFeature(
    index: 6,
    enableString: EnableString.spread_collections,
    isEnabledByDefault: IsEnabledByDefault.spread_collections,
    isExpired: IsExpired.spread_collections,
    documentation: 'Spread Collections',
    experimentalReleaseVersion: null,
    releaseVersion: Version.parse('2.0.0'),
  );

  static final triple_shift = ExperimentalFeature(
    index: 7,
    enableString: EnableString.triple_shift,
    isEnabledByDefault: IsEnabledByDefault.triple_shift,
    isExpired: IsExpired.triple_shift,
    documentation: 'Triple-shift operator',
    experimentalReleaseVersion: null,
    releaseVersion: null,
  );

  static final value_class = ExperimentalFeature(
    index: 8,
    enableString: EnableString.value_class,
    isEnabledByDefault: IsEnabledByDefault.value_class,
    isExpired: IsExpired.value_class,
    documentation: 'Value class',
    experimentalReleaseVersion: null,
    releaseVersion: null,
  );

  static final variance = ExperimentalFeature(
    index: 9,
    enableString: EnableString.variance,
    isEnabledByDefault: IsEnabledByDefault.variance,
    isExpired: IsExpired.variance,
    documentation: 'Sound variance',
    experimentalReleaseVersion: null,
    releaseVersion: null,
  );
}

/// Constant bools indicating whether each experimental flag is currently
/// enabled by default.
class IsEnabledByDefault {
  /// Default state of the experiment "constant-update-2018"
  static const bool constant_update_2018 = true;

  /// Default state of the experiment "control-flow-collections"
  static const bool control_flow_collections = true;

  /// Default state of the experiment "extension-methods"
  static const bool extension_methods = true;

  /// Default state of the experiment "non-nullable"
  static const bool non_nullable = true;

  /// Default state of the experiment "nonfunction-type-aliases"
  static const bool nonfunction_type_aliases = false;

  /// Default state of the experiment "set-literals"
  static const bool set_literals = true;

  /// Default state of the experiment "spread-collections"
  static const bool spread_collections = true;

  /// Default state of the experiment "triple-shift"
  static const bool triple_shift = false;

  /// Default state of the experiment "value-class"
  static const bool value_class = false;

  /// Default state of the experiment "variance"
  static const bool variance = false;
}

/// Constant bools indicating whether each experimental flag is currently
/// expired (meaning its enable/disable status can no longer be altered from the
/// value in [IsEnabledByDefault]).
class IsExpired {
  /// Expiration status of the experiment "constant-update-2018"
  static const bool constant_update_2018 = true;

  /// Expiration status of the experiment "control-flow-collections"
  static const bool control_flow_collections = true;

  /// Expiration status of the experiment "extension-methods"
  static const bool extension_methods = false;

  /// Expiration status of the experiment "non-nullable"
  static const bool non_nullable = false;

  /// Expiration status of the experiment "nonfunction-type-aliases"
  static const bool nonfunction_type_aliases = false;

  /// Expiration status of the experiment "set-literals"
  static const bool set_literals = true;

  /// Expiration status of the experiment "spread-collections"
  static const bool spread_collections = true;

  /// Expiration status of the experiment "triple-shift"
  static const bool triple_shift = false;

  /// Expiration status of the experiment "value-class"
  static const bool value_class = false;

  /// Expiration status of the experiment "variance"
  static const bool variance = false;
}

mixin _CurrentState {
  /// Current state for the flag "constant-update-2018"
  bool get constant_update_2018 =>
      isEnabled(ExperimentalFeatures.constant_update_2018);

  /// Current state for the flag "control-flow-collections"
  bool get control_flow_collections =>
      isEnabled(ExperimentalFeatures.control_flow_collections);

  /// Current state for the flag "extension-methods"
  bool get extension_methods =>
      isEnabled(ExperimentalFeatures.extension_methods);

  /// Current state for the flag "non-nullable"
  bool get non_nullable => isEnabled(ExperimentalFeatures.non_nullable);

  /// Current state for the flag "nonfunction-type-aliases"
  bool get nonfunction_type_aliases =>
      isEnabled(ExperimentalFeatures.nonfunction_type_aliases);

  /// Current state for the flag "set-literals"
  bool get set_literals => isEnabled(ExperimentalFeatures.set_literals);

  /// Current state for the flag "spread-collections"
  bool get spread_collections =>
      isEnabled(ExperimentalFeatures.spread_collections);

  /// Current state for the flag "triple-shift"
  bool get triple_shift => isEnabled(ExperimentalFeatures.triple_shift);

  /// Current state for the flag "value-class"
  bool get value_class => isEnabled(ExperimentalFeatures.value_class);

  /// Current state for the flag "variance"
  bool get variance => isEnabled(ExperimentalFeatures.variance);

  bool isEnabled(covariant ExperimentalFeature feature);
}
