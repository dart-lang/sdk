// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(askesc): Generate this file from a flag specification.

enum ExperimentalFlag {
  constantUpdate2018,
  controlFlowCollections,
  setLiterals,
  spreadCollections,
}

ExperimentalFlag parseExperimentalFlag(String flag) {
  switch (flag) {
    case "constant-update-2018":
      return ExperimentalFlag.constantUpdate2018;
    case "control-flow-collections":
      return ExperimentalFlag.controlFlowCollections;
    case "set-literals":
      return ExperimentalFlag.setLiterals;
    case "spread-collections":
      return ExperimentalFlag.spreadCollections;
  }
  return null;
}

const Map<ExperimentalFlag, bool> defaultExperimentalFlags = {
  ExperimentalFlag.constantUpdate2018: false,
  ExperimentalFlag.controlFlowCollections: true,
  ExperimentalFlag.setLiterals: true,
  ExperimentalFlag.spreadCollections: true,
};
