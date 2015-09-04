// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dead_entry_through_mirrors_test;

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
  LibraryMirror lib = currentMirrorSystem().findLibrary(
      #dead_entry_through_mirrors_test);

  // `A` is included by @MirrorsUsed, so its entry is retained too.
  ClassMirror aClass = lib.declarations[#A];
  Expect.equals(map[aClass.reflectedType], "the-text-for-A");

  // `B` is not included altogether.
  Expect.equals(lib.declarations[#B], null);
}
