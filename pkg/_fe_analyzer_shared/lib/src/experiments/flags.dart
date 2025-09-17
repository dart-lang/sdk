// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'tools/experimental_features.yaml' and run
// 'dart pkg/front_end/tool/cfe.dart generate-experimental-flags' to update.
const Version defaultLanguageVersion = const Version(3, 10);

/// Enum for experimental flags shared between the CFE and the analyzer.
enum ExperimentalFlag {
  augmentations(
    name: 'augmentations',
    isEnabledByDefault: false,
    isExpired: false,
    experimentEnabledVersion: defaultLanguageVersion,
    experimentReleasedVersion: const Version(3, 6),
  ),

  classModifiers(
    name: 'class-modifiers',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(3, 0),
    experimentReleasedVersion: const Version(3, 0),
  ),

  constFunctions(
    name: 'const-functions',
    isEnabledByDefault: false,
    isExpired: false,
    experimentEnabledVersion: defaultLanguageVersion,
    experimentReleasedVersion: defaultLanguageVersion,
  ),

  constantUpdate2018(
    name: 'constant-update-2018',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(2, 0),
    experimentReleasedVersion: const Version(2, 0),
  ),

  constructorTearoffs(
    name: 'constructor-tearoffs',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(2, 15),
    experimentReleasedVersion: const Version(2, 15),
  ),

  controlFlowCollections(
    name: 'control-flow-collections',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(2, 0),
    experimentReleasedVersion: const Version(2, 0),
  ),

  digitSeparators(
    name: 'digit-separators',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(3, 6),
    experimentReleasedVersion: const Version(3, 6),
  ),

  dotShorthands(
    name: 'dot-shorthands',
    isEnabledByDefault: true,
    isExpired: false,
    experimentEnabledVersion: const Version(3, 10),
    experimentReleasedVersion: const Version(3, 9),
  ),

  enhancedEnums(
    name: 'enhanced-enums',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(2, 17),
    experimentReleasedVersion: const Version(2, 17),
  ),

  enhancedParts(
    name: 'enhanced-parts',
    isEnabledByDefault: false,
    isExpired: false,
    experimentEnabledVersion: defaultLanguageVersion,
    experimentReleasedVersion: const Version(3, 6),
  ),

  extensionMethods(
    name: 'extension-methods',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(2, 6),
    experimentReleasedVersion: const Version(2, 6),
  ),

  genericMetadata(
    name: 'generic-metadata',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(2, 14),
    experimentReleasedVersion: const Version(2, 14),
  ),

  getterSetterError(
    name: 'getter-setter-error',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(3, 9),
    experimentReleasedVersion: const Version(3, 9),
  ),

  inferenceUpdate1(
    name: 'inference-update-1',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(2, 18),
    experimentReleasedVersion: const Version(2, 18),
  ),

  inferenceUpdate2(
    name: 'inference-update-2',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(3, 2),
    experimentReleasedVersion: const Version(3, 2),
  ),

  inferenceUpdate3(
    name: 'inference-update-3',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(3, 4),
    experimentReleasedVersion: const Version(3, 4),
  ),

  inferenceUpdate4(
    name: 'inference-update-4',
    isEnabledByDefault: false,
    isExpired: false,
    experimentEnabledVersion: defaultLanguageVersion,
    experimentReleasedVersion: defaultLanguageVersion,
  ),

  inferenceUsingBounds(
    name: 'inference-using-bounds',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(3, 7),
    experimentReleasedVersion: const Version(3, 7),
  ),

  inlineClass(
    name: 'inline-class',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(3, 3),
    experimentReleasedVersion: const Version(3, 3),
  ),

  macros(
    name: 'macros',
    isEnabledByDefault: false,
    isExpired: false,
    experimentEnabledVersion: defaultLanguageVersion,
    experimentReleasedVersion: const Version(3, 3),
  ),

  namedArgumentsAnywhere(
    name: 'named-arguments-anywhere',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(2, 17),
    experimentReleasedVersion: const Version(2, 17),
  ),

  nativeAssets(
    name: 'native-assets',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(3, 10),
    experimentReleasedVersion: const Version(3, 9),
  ),

  nonNullable(
    name: 'non-nullable',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(2, 12),
    experimentReleasedVersion: const Version(2, 10),
  ),

  nonfunctionTypeAliases(
    name: 'nonfunction-type-aliases',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(2, 13),
    experimentReleasedVersion: const Version(2, 13),
  ),

  nullAwareElements(
    name: 'null-aware-elements',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(3, 8),
    experimentReleasedVersion: const Version(3, 8),
  ),

  patterns(
    name: 'patterns',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(3, 0),
    experimentReleasedVersion: const Version(3, 0),
  ),

  recordUse(
    name: 'record-use',
    isEnabledByDefault: false,
    isExpired: false,
    experimentEnabledVersion: defaultLanguageVersion,
    experimentReleasedVersion: defaultLanguageVersion,
  ),

  records(
    name: 'records',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(3, 0),
    experimentReleasedVersion: const Version(3, 0),
  ),

  sealedClass(
    name: 'sealed-class',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(3, 0),
    experimentReleasedVersion: const Version(3, 0),
  ),

  setLiterals(
    name: 'set-literals',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(2, 0),
    experimentReleasedVersion: const Version(2, 0),
  ),

  soundFlowAnalysis(
    name: 'sound-flow-analysis',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(3, 9),
    experimentReleasedVersion: const Version(3, 9),
  ),

  spreadCollections(
    name: 'spread-collections',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(2, 0),
    experimentReleasedVersion: const Version(2, 0),
  ),

  superParameters(
    name: 'super-parameters',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(2, 17),
    experimentReleasedVersion: const Version(2, 17),
  ),

  testExperiment(
    name: 'test-experiment',
    isEnabledByDefault: false,
    isExpired: false,
    experimentEnabledVersion: defaultLanguageVersion,
    experimentReleasedVersion: defaultLanguageVersion,
  ),

  tripleShift(
    name: 'triple-shift',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(2, 14),
    experimentReleasedVersion: const Version(2, 14),
  ),

  unnamedLibraries(
    name: 'unnamed-libraries',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(2, 19),
    experimentReleasedVersion: const Version(2, 19),
  ),

  unquotedImports(
    name: 'unquoted-imports',
    isEnabledByDefault: false,
    isExpired: false,
    experimentEnabledVersion: defaultLanguageVersion,
    experimentReleasedVersion: defaultLanguageVersion,
  ),

  variance(
    name: 'variance',
    isEnabledByDefault: false,
    isExpired: false,
    experimentEnabledVersion: defaultLanguageVersion,
    experimentReleasedVersion: defaultLanguageVersion,
  ),

  wildcardVariables(
    name: 'wildcard-variables',
    isEnabledByDefault: true,
    isExpired: true,
    experimentEnabledVersion: const Version(3, 7),
    experimentReleasedVersion: const Version(3, 7),
  );

  final String name;
  final bool isEnabledByDefault;
  final bool isExpired;
  final Version experimentEnabledVersion;
  final Version experimentReleasedVersion;

  const ExperimentalFlag({
    required this.name,
    required this.isEnabledByDefault,
    required this.isExpired,
    required this.experimentEnabledVersion,
    required this.experimentReleasedVersion,
  });
}

class Version {
  final int major;
  final int minor;

  const Version(this.major, this.minor);

  String toText() => '$major.$minor';

  @override
  String toString() => toText();
}
