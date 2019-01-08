// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(askesc): Generate this file from a flag specification.

enum ExperimentalFlag {
  setLiterals,
  constantUpdate2018,
}

ExperimentalFlag parseExperimentalFlag(String flag) {
  switch (flag) {
    case "set-literals":
      return ExperimentalFlag.setLiterals;
    case "constant-update-2018":
      return ExperimentalFlag.constantUpdate2018;
  }
  return null;
}
