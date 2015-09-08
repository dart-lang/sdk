// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library live_entry_through_mirrors_test;

import 'package:lookup_map/lookup_map.dart';
import 'package:expect/expect.dart';
import 'dart:mirrors';

class A{}
class B{}
const map = const LookupMap(const [
    A, "the-text-for-A",
    B, "the-text-for-B",
]);

main() {
  // `A` is referenced explicitly, so its entry should be retained regardless.
  ClassMirror aClass = reflectClass(A);
  Expect.equals(map[aClass.reflectedType], "the-text-for-A");

  // `B` is used via mirrors. Because no @MirrorsUsed was found that's enough to
  // retain the entry.
  LibraryMirror lib = currentMirrorSystem().findLibrary(
      #live_entry_through_mirrors_test);
  ClassMirror bClass = lib.declarations[#B];
  Expect.equals(map[bClass.reflectedType], "the-text-for-B");
}
