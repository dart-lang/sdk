// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A null safe library cannot implement `toString()` and return `null`, but a
// legacy library, which may be called from null safe code, can. Test that that
// doesn't fail.

// Requirements=nnbd-weak
import "package:expect/expect.dart";

import "interpolation_and_buffer_legacy_lib.dart";

void main() {
  var n = ToStringNull();

  // Throws immediately when evaluating the first interpolated expression.
  Expect.throws<Error>(() => "$n${throw "unreachable"}");

  // Throws immediately when adding object that doesn't return a String.
  Expect.throws<Error>(
      () => StringBuffer()..write(n)..write(throw "unreachable"));

  // Same behavior for constructor argument as if adding it to buffer later.
  Expect.throws<Error>(() => StringBuffer(n)..write(throw "unreachable"));
}
