// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  final l = foo(growable: false);
  Expect.throws(() => l.add(1));

  final l2 = foo(growable: true);
  l2.clear();
}

List foo({final bool growable = true}) =>
    List<dynamic>.empty(growable: growable);
