// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'tools/experimental_features.yaml' and run
// 'pkg/front_end/tool/fasta generate-experimental-flags' to update.

enum ExperimentalFlag {
  constantUpdate2018,
  controlFlowCollections,
  extensionMethods,
  nonNullable,
  nonfunctionTypeAliases,
  setLiterals,
  spreadCollections,
  tripleShift,
  variance,
}

const int enableConstantUpdate2018MajorVersion = 2;
const int enableConstantUpdate2018MinorVersion = 4;
const int enableControlFlowCollectionsMajorVersion = 2;
const int enableControlFlowCollectionsMinorVersion = 2;
const int enableExtensionMethodsMajorVersion = 2;
const int enableExtensionMethodsMinorVersion = 6;
const int enableNonNullableMajorVersion = 2;
const int enableNonNullableMinorVersion = 8;
const int enableNonfunctionTypeAliasesMajorVersion = 2;
const int enableNonfunctionTypeAliasesMinorVersion = 8;
const int enableSetLiteralsMajorVersion = 2;
const int enableSetLiteralsMinorVersion = 2;
const int enableSpreadCollectionsMajorVersion = 2;
const int enableSpreadCollectionsMinorVersion = 2;
const int enableTripleShiftMajorVersion = 2;
const int enableTripleShiftMinorVersion = 8;
const int enableVarianceMajorVersion = 2;
const int enableVarianceMinorVersion = 8;

ExperimentalFlag parseExperimentalFlag(String flag) {
  switch (flag) {
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
    case "variance":
      return ExperimentalFlag.variance;
  }
  return null;
}

const Map<ExperimentalFlag, bool> defaultExperimentalFlags = {
  ExperimentalFlag.constantUpdate2018: true,
  ExperimentalFlag.controlFlowCollections: true,
  ExperimentalFlag.extensionMethods: true,
  ExperimentalFlag.nonNullable: false,
  ExperimentalFlag.nonfunctionTypeAliases: false,
  ExperimentalFlag.setLiterals: true,
  ExperimentalFlag.spreadCollections: true,
  ExperimentalFlag.tripleShift: false,
  ExperimentalFlag.variance: false,
};

const Map<ExperimentalFlag, bool> expiredExperimentalFlags = {
  ExperimentalFlag.constantUpdate2018: true,
  ExperimentalFlag.controlFlowCollections: true,
  ExperimentalFlag.extensionMethods: false,
  ExperimentalFlag.nonNullable: false,
  ExperimentalFlag.nonfunctionTypeAliases: false,
  ExperimentalFlag.setLiterals: true,
  ExperimentalFlag.spreadCollections: true,
  ExperimentalFlag.tripleShift: false,
  ExperimentalFlag.variance: false,
};
