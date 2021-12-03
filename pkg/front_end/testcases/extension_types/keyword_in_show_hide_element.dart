// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  void mixin() {}
  void as() {}
}

extension type E1 on A show mixin, as {}
extension type E2 on A hide mixin, as {}

main() {}
