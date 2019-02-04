// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/severity.dart' show Severity;

/// Test that Severity has the expected indexes. Note that this is important
/// and shouldn't be changed lightly because we use it in serialization!
main() {
  expect(Severity.context.index, 0);
  expect(Severity.error.index, 1);
  expect(Severity.internalProblem.index, 4);
  expect(Severity.warning.index, 5);

  expect(Severity.values[0], Severity.context);
  expect(Severity.values[1], Severity.error);
  expect(Severity.values[4], Severity.internalProblem);
  expect(Severity.values[5], Severity.warning);
}

void expect(Object actual, Object expect) {
  if (expect != actual) throw "Expected $expect got $actual";
}
