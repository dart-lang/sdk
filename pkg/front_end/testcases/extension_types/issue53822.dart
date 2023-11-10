// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type ET<T>(T _) {
  void test() {}
}

main() {
  ET(null).test();
  ET<int?>(42).test();
}