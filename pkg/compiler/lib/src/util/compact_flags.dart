// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
const int emptyCompactFlags = 0;

typedef CompactFlags = int;

extension CompactFlagsMethods on CompactFlags {
  CompactFlags updateAllFlags(List<Enum> flagIndices, bool newState) {
    int flags = this;
    for (final index in flagIndices) {
      flags = flags.updateFlag(index, newState);
    }
    return flags;
  }

  CompactFlags updateFlag(Enum flag, bool newState) {
    return newState ? setFlag(flag) : clearFlag(flag);
  }

  CompactFlags setFlag(Enum flag) => this | (1 << flag.index);

  CompactFlags clearFlag(Enum flag) => this & ~(1 << flag.index);

  bool hasFlag(Enum flag) => ((this >> flag.index) & 1) == 1;
}

CompactFlags create(List<Enum> setFlags) {
  return emptyCompactFlags.updateAllFlags(setFlags, true);
}
