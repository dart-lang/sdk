// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'tools/experimental_features.yaml' and run
// 'dart pkg/front_end/tool/fasta.dart generate-experimental-flags' to update.

part of 'experimental_flags.dart';

enum ExperimentalFlag {
  alternativeInvalidationStrategy,
  constFunctions,
  constantUpdate2018,
  constructorTearoffs,
  controlFlowCollections,
  enhancedEnums,
  extensionMethods,
  extensionTypes,
  genericMetadata,
  macros,
  namedArgumentsAnywhere,
  nonNullable,
  nonfunctionTypeAliases,
  setLiterals,
  spreadCollections,
  superParameters,
  testExperiment,
  tripleShift,
  valueClass,
  variance,
}

const Version enableAlternativeInvalidationStrategyVersion =
    const Version(2, 17);
const Version enableConstFunctionsVersion = const Version(2, 17);
const Version enableConstantUpdate2018Version = const Version(2, 0);
const Version enableConstructorTearoffsVersion = const Version(2, 15);
const Version enableControlFlowCollectionsVersion = const Version(2, 0);
const Version enableEnhancedEnumsVersion = const Version(2, 17);
const Version enableExtensionMethodsVersion = const Version(2, 6);
const Version enableExtensionTypesVersion = const Version(2, 17);
const Version enableGenericMetadataVersion = const Version(2, 14);
const Version enableMacrosVersion = const Version(2, 17);
const Version enableNamedArgumentsAnywhereVersion = const Version(2, 17);
const Version enableNonNullableVersion = const Version(2, 12);
const Version enableNonfunctionTypeAliasesVersion = const Version(2, 13);
const Version enableSetLiteralsVersion = const Version(2, 0);
const Version enableSpreadCollectionsVersion = const Version(2, 0);
const Version enableSuperParametersVersion = const Version(2, 17);
const Version enableTestExperimentVersion = const Version(2, 17);
const Version enableTripleShiftVersion = const Version(2, 14);
const Version enableValueClassVersion = const Version(2, 17);
const Version enableVarianceVersion = const Version(2, 17);

ExperimentalFlag? parseExperimentalFlag(String flag) {
  switch (flag) {
    case "alternative-invalidation-strategy":
      return ExperimentalFlag.alternativeInvalidationStrategy;
    case "const-functions":
      return ExperimentalFlag.constFunctions;
    case "constant-update-2018":
      return ExperimentalFlag.constantUpdate2018;
    case "constructor-tearoffs":
      return ExperimentalFlag.constructorTearoffs;
    case "control-flow-collections":
      return ExperimentalFlag.controlFlowCollections;
    case "enhanced-enums":
      return ExperimentalFlag.enhancedEnums;
    case "extension-methods":
      return ExperimentalFlag.extensionMethods;
    case "extension-types":
      return ExperimentalFlag.extensionTypes;
    case "generic-metadata":
      return ExperimentalFlag.genericMetadata;
    case "macros":
      return ExperimentalFlag.macros;
    case "named-arguments-anywhere":
      return ExperimentalFlag.namedArgumentsAnywhere;
    case "non-nullable":
      return ExperimentalFlag.nonNullable;
    case "nonfunction-type-aliases":
      return ExperimentalFlag.nonfunctionTypeAliases;
    case "set-literals":
      return ExperimentalFlag.setLiterals;
    case "spread-collections":
      return ExperimentalFlag.spreadCollections;
    case "super-parameters":
      return ExperimentalFlag.superParameters;
    case "test-experiment":
      return ExperimentalFlag.testExperiment;
    case "triple-shift":
      return ExperimentalFlag.tripleShift;
    case "value-class":
      return ExperimentalFlag.valueClass;
    case "variance":
      return ExperimentalFlag.variance;
  }
  return null;
}

const Map<ExperimentalFlag, bool> defaultExperimentalFlags = {
  ExperimentalFlag.alternativeInvalidationStrategy: false,
  ExperimentalFlag.constFunctions: false,
  ExperimentalFlag.constantUpdate2018: true,
  ExperimentalFlag.constructorTearoffs: true,
  ExperimentalFlag.controlFlowCollections: true,
  ExperimentalFlag.enhancedEnums: false,
  ExperimentalFlag.extensionMethods: true,
  ExperimentalFlag.extensionTypes: false,
  ExperimentalFlag.genericMetadata: true,
  ExperimentalFlag.macros: false,
  ExperimentalFlag.namedArgumentsAnywhere: false,
  ExperimentalFlag.nonNullable: true,
  ExperimentalFlag.nonfunctionTypeAliases: true,
  ExperimentalFlag.setLiterals: true,
  ExperimentalFlag.spreadCollections: true,
  ExperimentalFlag.superParameters: false,
  ExperimentalFlag.testExperiment: false,
  ExperimentalFlag.tripleShift: true,
  ExperimentalFlag.valueClass: false,
  ExperimentalFlag.variance: false,
};

const Map<ExperimentalFlag, bool> expiredExperimentalFlags = {
  ExperimentalFlag.alternativeInvalidationStrategy: false,
  ExperimentalFlag.constFunctions: false,
  ExperimentalFlag.constantUpdate2018: true,
  ExperimentalFlag.constructorTearoffs: true,
  ExperimentalFlag.controlFlowCollections: true,
  ExperimentalFlag.enhancedEnums: false,
  ExperimentalFlag.extensionMethods: true,
  ExperimentalFlag.extensionTypes: false,
  ExperimentalFlag.genericMetadata: true,
  ExperimentalFlag.macros: false,
  ExperimentalFlag.namedArgumentsAnywhere: false,
  ExperimentalFlag.nonNullable: true,
  ExperimentalFlag.nonfunctionTypeAliases: true,
  ExperimentalFlag.setLiterals: true,
  ExperimentalFlag.spreadCollections: true,
  ExperimentalFlag.superParameters: false,
  ExperimentalFlag.testExperiment: false,
  ExperimentalFlag.tripleShift: true,
  ExperimentalFlag.valueClass: false,
  ExperimentalFlag.variance: false,
};

const Map<ExperimentalFlag, Version> experimentEnabledVersion = {
  ExperimentalFlag.alternativeInvalidationStrategy: const Version(2, 17),
  ExperimentalFlag.constFunctions: const Version(2, 17),
  ExperimentalFlag.constantUpdate2018: const Version(2, 0),
  ExperimentalFlag.constructorTearoffs: const Version(2, 15),
  ExperimentalFlag.controlFlowCollections: const Version(2, 0),
  ExperimentalFlag.enhancedEnums: const Version(2, 17),
  ExperimentalFlag.extensionMethods: const Version(2, 6),
  ExperimentalFlag.extensionTypes: const Version(2, 17),
  ExperimentalFlag.genericMetadata: const Version(2, 14),
  ExperimentalFlag.macros: const Version(2, 17),
  ExperimentalFlag.namedArgumentsAnywhere: const Version(2, 17),
  ExperimentalFlag.nonNullable: const Version(2, 12),
  ExperimentalFlag.nonfunctionTypeAliases: const Version(2, 13),
  ExperimentalFlag.setLiterals: const Version(2, 0),
  ExperimentalFlag.spreadCollections: const Version(2, 0),
  ExperimentalFlag.superParameters: const Version(2, 17),
  ExperimentalFlag.testExperiment: const Version(2, 17),
  ExperimentalFlag.tripleShift: const Version(2, 14),
  ExperimentalFlag.valueClass: const Version(2, 17),
  ExperimentalFlag.variance: const Version(2, 17),
};

const Map<ExperimentalFlag, Version> experimentReleasedVersion = {
  ExperimentalFlag.alternativeInvalidationStrategy: const Version(2, 17),
  ExperimentalFlag.constFunctions: const Version(2, 17),
  ExperimentalFlag.constantUpdate2018: const Version(2, 0),
  ExperimentalFlag.constructorTearoffs: const Version(2, 15),
  ExperimentalFlag.controlFlowCollections: const Version(2, 0),
  ExperimentalFlag.enhancedEnums: const Version(2, 17),
  ExperimentalFlag.extensionMethods: const Version(2, 6),
  ExperimentalFlag.extensionTypes: const Version(2, 17),
  ExperimentalFlag.genericMetadata: const Version(2, 14),
  ExperimentalFlag.macros: const Version(2, 17),
  ExperimentalFlag.namedArgumentsAnywhere: const Version(2, 17),
  ExperimentalFlag.nonNullable: const Version(2, 10),
  ExperimentalFlag.nonfunctionTypeAliases: const Version(2, 13),
  ExperimentalFlag.setLiterals: const Version(2, 0),
  ExperimentalFlag.spreadCollections: const Version(2, 0),
  ExperimentalFlag.superParameters: const Version(2, 17),
  ExperimentalFlag.testExperiment: const Version(2, 17),
  ExperimentalFlag.tripleShift: const Version(2, 14),
  ExperimentalFlag.valueClass: const Version(2, 17),
  ExperimentalFlag.variance: const Version(2, 17),
};

const AllowedExperimentalFlags defaultAllowedExperimentalFlags =
    const AllowedExperimentalFlags(
        sdkDefaultExperiments: {},
        sdkLibraryExperiments: {},
        packageExperiments: {
      "async": {
        ExperimentalFlag.nonNullable,
      },
      "boolean_selector": {
        ExperimentalFlag.nonNullable,
      },
      "characters": {
        ExperimentalFlag.nonNullable,
      },
      "charcode": {
        ExperimentalFlag.nonNullable,
      },
      "clock": {
        ExperimentalFlag.nonNullable,
      },
      "collection": {
        ExperimentalFlag.nonNullable,
      },
      "connectivity": {
        ExperimentalFlag.nonNullable,
      },
      "connectivity_platform_interface": {
        ExperimentalFlag.nonNullable,
      },
      "convert": {
        ExperimentalFlag.nonNullable,
      },
      "crypto": {
        ExperimentalFlag.nonNullable,
      },
      "csslib": {
        ExperimentalFlag.nonNullable,
      },
      "dart_internal": {
        ExperimentalFlag.nonNullable,
      },
      "device_info": {
        ExperimentalFlag.nonNullable,
      },
      "device_info_platform_interface": {
        ExperimentalFlag.nonNullable,
      },
      "fake_async": {
        ExperimentalFlag.nonNullable,
      },
      "file": {
        ExperimentalFlag.nonNullable,
      },
      "fixnum": {
        ExperimentalFlag.nonNullable,
      },
      "flutter": {
        ExperimentalFlag.nonNullable,
      },
      "flutter_driver": {
        ExperimentalFlag.nonNullable,
      },
      "flutter_test": {
        ExperimentalFlag.nonNullable,
      },
      "flutter_goldens": {
        ExperimentalFlag.nonNullable,
      },
      "flutter_goldens_client": {
        ExperimentalFlag.nonNullable,
      },
      "http": {
        ExperimentalFlag.nonNullable,
      },
      "http_parser": {
        ExperimentalFlag.nonNullable,
      },
      "intl": {
        ExperimentalFlag.nonNullable,
      },
      "js": {
        ExperimentalFlag.nonNullable,
      },
      "logging": {
        ExperimentalFlag.nonNullable,
      },
      "matcher": {
        ExperimentalFlag.nonNullable,
      },
      "meta": {
        ExperimentalFlag.nonNullable,
      },
      "native_stack_traces": {
        ExperimentalFlag.nonNullable,
      },
      "observatory": {
        ExperimentalFlag.nonNullable,
      },
      "observatory_test_package": {
        ExperimentalFlag.nonNullable,
      },
      "path": {
        ExperimentalFlag.nonNullable,
      },
      "pedantic": {
        ExperimentalFlag.nonNullable,
      },
      "platform": {
        ExperimentalFlag.nonNullable,
      },
      "plugin_platform_interface": {
        ExperimentalFlag.nonNullable,
      },
      "pool": {
        ExperimentalFlag.nonNullable,
      },
      "process": {
        ExperimentalFlag.nonNullable,
      },
      "pub_semver": {
        ExperimentalFlag.nonNullable,
      },
      "sky_engine": {
        ExperimentalFlag.nonNullable,
      },
      "source_maps": {
        ExperimentalFlag.nonNullable,
      },
      "source_map_stack_trace": {
        ExperimentalFlag.nonNullable,
      },
      "source_span": {
        ExperimentalFlag.nonNullable,
      },
      "stack_trace": {
        ExperimentalFlag.nonNullable,
      },
      "stream_channel": {
        ExperimentalFlag.nonNullable,
      },
      "string_scanner": {
        ExperimentalFlag.nonNullable,
      },
      "term_glyph": {
        ExperimentalFlag.nonNullable,
      },
      "test": {
        ExperimentalFlag.nonNullable,
      },
      "test_api": {
        ExperimentalFlag.nonNullable,
      },
      "test_core": {
        ExperimentalFlag.nonNullable,
      },
      "typed_data": {
        ExperimentalFlag.nonNullable,
      },
      "url_launcher": {
        ExperimentalFlag.nonNullable,
      },
      "url_launcher_linux": {
        ExperimentalFlag.nonNullable,
      },
      "url_launcher_macos": {
        ExperimentalFlag.nonNullable,
      },
      "url_launcher_platform_interface": {
        ExperimentalFlag.nonNullable,
      },
      "url_launcher_windows": {
        ExperimentalFlag.nonNullable,
      },
      "vector_math": {
        ExperimentalFlag.nonNullable,
      },
      "video_player": {
        ExperimentalFlag.nonNullable,
      },
      "video_player_platform_interface": {
        ExperimentalFlag.nonNullable,
      },
      "video_player_web": {
        ExperimentalFlag.nonNullable,
      },
    });
