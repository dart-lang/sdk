// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Bug: 4254106 Constant constructors must have (implicit) const parameters.

class ConstCounter {
  const ConstCounter(int i)
      : nextValue_ = (
            // Incorrect assignment of a non-const function to a final field.
            () => //# 01: compile-time error
                i + 1);

  final nextValue_;
}

main() {
  const ConstCounter(3);
}
