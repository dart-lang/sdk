// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--lazy-async-stacks --no-causal-async-stacks

import "package:expect/expect.dart";

main() {
  Expect.isFalse(
      const bool.fromEnvironment('dart.developer.causal_async_stacks'));
}
