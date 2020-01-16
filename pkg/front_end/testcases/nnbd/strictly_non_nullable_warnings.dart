// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks for compile-time warnings about expressions of strictly
// non-nullable types being used in positions typically occupied by those of
// nullable types, that is, in various null-aware expressions.

warning(String s, List<String> l) {
  s?.length;
  s?..length;
  s ?? "foo";
  s ??= "foo";
  [...?l];
  s!;
}

main() {}
