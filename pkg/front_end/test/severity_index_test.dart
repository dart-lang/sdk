// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/severity.dart'
    show CfeSeverity;

/// Test that Severity has the expected indexes. Note that this is important
/// and shouldn't be changed lightly because we use it in serialization!
void main() {
  expect(CfeSeverity.context.index, 0);
  expect(CfeSeverity.error.index, 1);
  expect(CfeSeverity.internalProblem.index, 3);
  expect(CfeSeverity.warning.index, 4);

  expect(CfeSeverity.values[0], CfeSeverity.context);
  expect(CfeSeverity.values[1], CfeSeverity.error);
  expect(CfeSeverity.values[3], CfeSeverity.internalProblem);
  expect(CfeSeverity.values[4], CfeSeverity.warning);
}

void expect(Object actual, Object expect) {
  if (expect != actual) throw "Expected $expect got $actual";
}
