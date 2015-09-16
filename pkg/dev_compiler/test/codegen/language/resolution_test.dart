// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int get foo => 499;

class CompileError {
  var x;

  // Dart2js tried to resolve factories twice. The second time during building
  // when it was not allowed to do so.
  factory CompileError() {
    return new CompileError.internal(foo);
  }

  CompileError.internal(this.x);
}

void main() {
  Expect.equals(499, new CompileError().x);
}
