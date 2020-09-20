// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'tools/experimental_features.yaml' and run
// 'dart pkg/front_end/tool/fasta.dart generate-experimental-flags' to update.

part of 'experimental_flags.dart';

enum ExperimentalFlag {
  alternativeInvalidationStrategy,
  constantUpdate2018,
  controlFlowCollections,
  extensionMethods,
  nonNullable,
  nonfunctionTypeAliases,
  setLiterals,
  spreadCollections,
  tripleShift,
  valueClass,
  variance,
}

const Version enableAlternativeInvalidationStrategyVersion =
    const Version(2, 10);
const Version enableConstantUpdate2018Version = const Version(2, 4);
const Version enableControlFlowCollectionsVersion = const Version(2, 0);
const Version enableExtensionMethodsVersion = const Version(2, 6);
const Version enableNonNullableVersion = const Version(2, 10);
const Version enableNonfunctionTypeAliasesVersion = const Version(2, 10);
const Version enableSetLiteralsVersion = const Version(2, 0);
const Version enableSpreadCollectionsVersion = const Version(2, 0);
const Version enableTripleShiftVersion = const Version(2, 10);
const Version enableValueClassVersion = const Version(2, 10);
const Version enableVarianceVersion = const Version(2, 10);

ExperimentalFlag parseExperimentalFlag(String flag) {
  switch (flag) {
    case "alternative-invalidation-strategy":
      return ExperimentalFlag.alternativeInvalidationStrategy;
    case "constant-update-2018":
      return ExperimentalFlag.constantUpdate2018;
    case "control-flow-collections":
      return ExperimentalFlag.controlFlowCollections;
    case "extension-methods":
      return ExperimentalFlag.extensionMethods;
    case "non-nullable":
      return ExperimentalFlag.nonNullable;
    case "nonfunction-type-aliases":
      return ExperimentalFlag.nonfunctionTypeAliases;
    case "set-literals":
      return ExperimentalFlag.setLiterals;
    case "spread-collections":
      return ExperimentalFlag.spreadCollections;
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
  ExperimentalFlag.constantUpdate2018: true,
  ExperimentalFlag.controlFlowCollections: true,
  ExperimentalFlag.extensionMethods: true,
  ExperimentalFlag.nonNullable: false,
  ExperimentalFlag.nonfunctionTypeAliases: false,
  ExperimentalFlag.setLiterals: true,
  ExperimentalFlag.spreadCollections: true,
  ExperimentalFlag.tripleShift: false,
  ExperimentalFlag.valueClass: false,
  ExperimentalFlag.variance: false,
};

const Map<ExperimentalFlag, bool> expiredExperimentalFlags = {
  ExperimentalFlag.alternativeInvalidationStrategy: false,
  ExperimentalFlag.constantUpdate2018: true,
  ExperimentalFlag.controlFlowCollections: true,
  ExperimentalFlag.extensionMethods: false,
  ExperimentalFlag.nonNullable: false,
  ExperimentalFlag.nonfunctionTypeAliases: false,
  ExperimentalFlag.setLiterals: true,
  ExperimentalFlag.spreadCollections: true,
  ExperimentalFlag.tripleShift: false,
  ExperimentalFlag.valueClass: false,
  ExperimentalFlag.variance: false,
};

const Map<ExperimentalFlag, Version> experimentEnabledVersion = {
  ExperimentalFlag.alternativeInvalidationStrategy: const Version(2, 10),
  ExperimentalFlag.constantUpdate2018: const Version(2, 4),
  ExperimentalFlag.controlFlowCollections: const Version(2, 0),
  ExperimentalFlag.extensionMethods: const Version(2, 6),
  ExperimentalFlag.nonNullable: const Version(2, 10),
  ExperimentalFlag.nonfunctionTypeAliases: const Version(2, 10),
  ExperimentalFlag.setLiterals: const Version(2, 0),
  ExperimentalFlag.spreadCollections: const Version(2, 0),
  ExperimentalFlag.tripleShift: const Version(2, 10),
  ExperimentalFlag.valueClass: const Version(2, 10),
  ExperimentalFlag.variance: const Version(2, 10),
};

const Map<ExperimentalFlag, Version> experimentReleasedVersion = {
  ExperimentalFlag.alternativeInvalidationStrategy: const Version(2, 10),
  ExperimentalFlag.constantUpdate2018: const Version(2, 4),
  ExperimentalFlag.controlFlowCollections: const Version(2, 0),
  ExperimentalFlag.extensionMethods: const Version(2, 6),
  ExperimentalFlag.nonNullable: const Version(2, 10),
  ExperimentalFlag.nonfunctionTypeAliases: const Version(2, 10),
  ExperimentalFlag.setLiterals: const Version(2, 0),
  ExperimentalFlag.spreadCollections: const Version(2, 0),
  ExperimentalFlag.tripleShift: const Version(2, 10),
  ExperimentalFlag.valueClass: const Version(2, 10),
  ExperimentalFlag.variance: const Version(2, 10),
};

const AllowedExperimentalFlags defaultAllowedExperimentalFlags =
    const AllowedExperimentalFlags(sdkDefaultExperiments: {
  ExperimentalFlag.nonNullable,
}, sdkLibraryExperiments: {}, packageExperiments: {
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
  "flutter_test": {
    ExperimentalFlag.nonNullable,
  },
  "flutter_goldens": {
    ExperimentalFlag.nonNullable,
  },
  "flutter_goldens_client": {
    ExperimentalFlag.nonNullable,
  },
  "js": {
    ExperimentalFlag.nonNullable,
  },
  "matcher": {
    ExperimentalFlag.nonNullable,
  },
  "meta": {
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
  "pool": {
    ExperimentalFlag.nonNullable,
  },
  "process": {
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
  "vector_math": {
    ExperimentalFlag.nonNullable,
  },
});
