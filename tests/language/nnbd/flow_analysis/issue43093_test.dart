// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for a bug in which `!` applied to a null-shorting
// expression would corrupt the state of flow analysis, causing a crash when
// trying to finish analyzing an enclosing `if` statement.

// SharedOptions=--enable-experiment=non-nullable
import 'package:expect/expect.dart';

class C {
  final int? x;
  C(this.x);
}

int? f(bool b, C? c) {
  if (b) {
    return c?.x!;
  } else {
    return null;
  }
}

main() {
  // Note: it is currently being discussed whether `!` should participate in
  // null shorting (see https://github.com/dart-lang/language/issues/1163), so
  // let's not have an expectation about whether `f(true, null)` should throw an
  // exception.
  //  f(true, null);

  Expect.throws(() => f(true, C(null)));
  Expect.equals(f(true, C(1)), 1);
}
