// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Subset of dead_entry_through_mirrors_test that is not affected by
// tree-shaking. This subset can be run in the VM.
library live_entry_through_mirrors_used_test;

import 'package:lookup_map/lookup_map.dart';
import 'package:expect/expect.dart';

@MirrorsUsed(targets: const [A])
import 'dart:mirrors';

class A{}
class B{}
const map = const LookupMap(const [
    A, "the-text-for-A",
    B, "the-text-for-B",
]);

main() {
  // `A` is included by @MirrorsUsed, so its entry is retained too.
  LibraryMirror lib = currentMirrorSystem().findLibrary(
      #live_entry_through_mirrors_used_test);
  ClassMirror aClass = lib.declarations[#A];
  Expect.equals(map[aClass.reflectedType], "the-text-for-A");
}
