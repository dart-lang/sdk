//
// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'tools/experimental_features.yaml' and run
// 'dart pkg/analyzer/tool/experiments/generate.dart' to update.

part of 'experiments.dart';

/// A map containing information about all known experimental flags.
const _knownFeatures = <String, ExperimentalFeature>{
  EnableString.constant_update_2018: ExperimentalFeatures.constant_update_2018,
  EnableString.control_flow_collections:
      ExperimentalFeatures.control_flow_collections,
  EnableString.extension_methods: ExperimentalFeatures.extension_methods,
  EnableString.non_nullable: ExperimentalFeatures.non_nullable,
  EnableString.set_literals: ExperimentalFeatures.set_literals,
  EnableString.spread_collections: ExperimentalFeatures.spread_collections,
  EnableString.triple_shift: ExperimentalFeatures.triple_shift,
  EnableString.variance: ExperimentalFeatures.variance,

  // ignore: deprecated_member_use_from_same_package
  EnableString.bogus_disabled: ExperimentalFeatures.bogus_disabled,
  // ignore: deprecated_member_use_from_same_package
  EnableString.bogus_enabled: ExperimentalFeatures.bogus_enabled,
};

List<bool> _buildExperimentalFlagsArray() => <bool>[
      true, // constant-update-2018
      true, // control-flow-collections
      true, // extension-methods
      IsEnabledByDefault.non_nullable,
      true, // set-literals
      true, // spread-collections
      IsEnabledByDefault.triple_shift,
      IsEnabledByDefault.variance,
      false, // bogus-disabled
      true, // bogus-enabled
    ];

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

  /// String to enable the experiment "set-literals"
  static const String set_literals = 'set-literals';

  /// String to enable the experiment "spread-collections"
  static const String spread_collections = 'spread-collections';

  /// String to enable the experiment "triple-shift"
  static const String triple_shift = 'triple-shift';

  /// String to enable the experiment "variance"
  static const String variance = 'variance';

  /// String to enable the experiment "bogus-disabled"
  @deprecated
  static const String bogus_disabled = 'bogus-disabled';

  /// String to enable the experiment "bogus-enabled"
  @deprecated
  static const String bogus_enabled = 'bogus-enabled';
}

class ExperimentalFeatures {
  static const constant_update_2018 = const ExperimentalFeature(
      0,
      EnableString.constant_update_2018,
      IsEnabledByDefault.constant_update_2018,
      IsExpired.constant_update_2018,
      'Enhanced constant expressions',
      firstSupportedVersion: '2.4.1');

  static const control_flow_collections = const ExperimentalFeature(
      1,
      EnableString.control_flow_collections,
      IsEnabledByDefault.control_flow_collections,
      IsExpired.control_flow_collections,
      'Control Flow Collections',
      firstSupportedVersion: '2.2.2');

  static const extension_methods = const ExperimentalFeature(
      2,
      EnableString.extension_methods,
      IsEnabledByDefault.extension_methods,
      IsExpired.extension_methods,
      'Extension Methods',
      firstSupportedVersion: '2.6.0');

  static const non_nullable = const ExperimentalFeature(
      3,
      EnableString.non_nullable,
      IsEnabledByDefault.non_nullable,
      IsExpired.non_nullable,
      'Non Nullable by default');

  static const set_literals = const ExperimentalFeature(
      4,
      EnableString.set_literals,
      IsEnabledByDefault.set_literals,
      IsExpired.set_literals,
      'Set Literals',
      firstSupportedVersion: '2.2.0');

  static const spread_collections = const ExperimentalFeature(
      5,
      EnableString.spread_collections,
      IsEnabledByDefault.spread_collections,
      IsExpired.spread_collections,
      'Spread Collections',
      firstSupportedVersion: '2.2.2');

  static const triple_shift = const ExperimentalFeature(
      6,
      EnableString.triple_shift,
      IsEnabledByDefault.triple_shift,
      IsExpired.triple_shift,
      'Triple-shift operator');

  static const variance = const ExperimentalFeature(7, EnableString.variance,
      IsEnabledByDefault.variance, IsExpired.variance, 'Sound variance.');

  @deprecated
  static const bogus_disabled = const ExperimentalFeature(
      8,
      // ignore: deprecated_member_use_from_same_package
      EnableString.bogus_disabled,
      IsEnabledByDefault.bogus_disabled,
      IsExpired.bogus_disabled,
      null);

  @deprecated
  static const bogus_enabled = const ExperimentalFeature(
      9,
      // ignore: deprecated_member_use_from_same_package
      EnableString.bogus_enabled,
      IsEnabledByDefault.bogus_enabled,
      IsExpired.bogus_enabled,
      null,
      firstSupportedVersion: '1.0.0');
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
  static const bool non_nullable = false;

  /// Default state of the experiment "set-literals"
  static const bool set_literals = true;

  /// Default state of the experiment "spread-collections"
  static const bool spread_collections = true;

  /// Default state of the experiment "triple-shift"
  static const bool triple_shift = false;

  /// Default state of the experiment "variance"
  static const bool variance = false;

  /// Default state of the experiment "bogus-disabled"
  @deprecated
  static const bool bogus_disabled = false;

  /// Default state of the experiment "bogus-enabled"
  @deprecated
  static const bool bogus_enabled = true;
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

  /// Expiration status of the experiment "set-literals"
  static const bool set_literals = true;

  /// Expiration status of the experiment "spread-collections"
  static const bool spread_collections = true;

  /// Expiration status of the experiment "triple-shift"
  static const bool triple_shift = false;

  /// Expiration status of the experiment "variance"
  static const bool variance = false;

  /// Expiration status of the experiment "bogus-disabled"
  static const bool bogus_disabled = true;

  /// Expiration status of the experiment "bogus-enabled"
  static const bool bogus_enabled = true;
}

mixin _CurrentState {
  /// Current state for the flag "bogus-disabled"
  @deprecated
  bool get bogus_disabled => isEnabled(ExperimentalFeatures.bogus_disabled);

  /// Current state for the flag "bogus-enabled"
  @deprecated
  bool get bogus_enabled => isEnabled(ExperimentalFeatures.bogus_enabled);

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

  /// Current state for the flag "set-literals"
  bool get set_literals => isEnabled(ExperimentalFeatures.set_literals);

  /// Current state for the flag "spread-collections"
  bool get spread_collections =>
      isEnabled(ExperimentalFeatures.spread_collections);

  /// Current state for the flag "triple-shift"
  bool get triple_shift => isEnabled(ExperimentalFeatures.triple_shift);

  /// Current state for the flag "variance"
  bool get variance => isEnabled(ExperimentalFeatures.variance);

  bool isEnabled(covariant ExperimentalFeature feature);
}
