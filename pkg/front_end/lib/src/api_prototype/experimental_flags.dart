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
  spreadCollections,
  tripleShift,

  // A placeholder representing an "expired" flag which has been removed
  // from the codebase but still needs to be gracefully ignored
  // when specified on the command line.
  expiredFlag,
}

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
    case "spread-collections":
      return ExperimentalFlag.spreadCollections;
    case "triple-shift":
      return ExperimentalFlag.tripleShift;

    // Expired flags
    case "set-literals":
      return ExperimentalFlag.expiredFlag;
  }
  return null;
}

const Map<ExperimentalFlag, bool> defaultExperimentalFlags = {
  ExperimentalFlag.constantUpdate2018: true,
  ExperimentalFlag.controlFlowCollections: true,
  ExperimentalFlag.extensionMethods: false,
  ExperimentalFlag.nonNullable: false,
  ExperimentalFlag.spreadCollections: true,
  ExperimentalFlag.tripleShift: false,
};
