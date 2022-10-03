// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--no-use-field-guards

import 'dart:typed_data';

class Foo {
  Float32x4 field = Float32x4.splat(0.2565194795417153);
}

main() {
  Foo();
}
