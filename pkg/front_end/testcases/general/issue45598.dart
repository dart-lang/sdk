// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

foo(Function<X extends Z, Y, Z>({Map<Y, Z> m}) bar, Map<String, String> m) {
  bar(m: m);
}

main() {}
