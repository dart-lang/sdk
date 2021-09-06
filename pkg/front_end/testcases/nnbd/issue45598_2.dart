// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo(Map<String, String> m) {
  void bar<X extends Z, Y, Z>({required Map<Y, Z> m}) {}
  bar(m: m);
}

main() {}
