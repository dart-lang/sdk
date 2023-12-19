// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Can't run in strong mode since it contains a legacy library.
// Requirements=nnbd-weak

import "package:expect/expect.dart";

import "legacy_library.dart";

class A {}

class B {}

Type type<T>() => T;

Type listType<T>() => <T>[].runtimeType;

main() {
  Expect.isFalse(type<int?>() == legacyType<int>());
  Expect.isTrue(type<int>() == legacyType<int>());
  Expect.isFalse(legacyType<int>() == type<int?>());
  Expect.isTrue(legacyType<int>() == type<int>());
  Expect.isTrue(legacyType<int>() == legacyType<int>());

  Expect.isTrue(listType<int>() == legacyListType<int>());
}
