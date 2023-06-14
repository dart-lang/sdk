// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
const int emptyValue = 0;

int create(List<Enum> setFlags) {
  return updateAllFlags(setFlags, true, 0);
}

int updateAllFlags(List<Enum> flagIndices, bool newState, int currentValue) {
  int flags = currentValue;
  for (final hasIndex in flagIndices) {
    flags = updateFlag(hasIndex, newState, flags);
  }
  return flags;
}

int updateFlag(Enum flag, bool newState, int currentValue) {
  return newState ? setFlag(flag, currentValue) : clearFlag(flag, currentValue);
}

int setFlag(Enum flag, int currentValue) => currentValue | (1 << flag.index);

int clearFlag(Enum flag, int currentValue) => currentValue & ~(1 << flag.index);

bool hasFlag(Enum flag, int currentValue) =>
    ((currentValue >> flag.index) & 1) == 1;
