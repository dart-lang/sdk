// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// We want to run each test with and without inlining of the target functions.
// We accomplish this by using VM options in the yes-inlining variant to set the
// "enable_inlining" constant variable to true. This maximizes code sharing
// between the two variants, which are otherwise identical.
const String NeverInline =
    const bool.fromEnvironment("enable_inlining") ? "" : "NeverInline";

// All these tests can be run in test mode or in benchmark mode. In benchmark
// mode, there is introspection is omitted and the tests runs for many more
// iterations.
const bool benchmarkMode = const bool.fromEnvironment("benchmark_mode");

int expectedEntryPoint = -1;
int expectedTearoffEntryPoint = -1;

// We check that this is true at the end of the test to ensure that the
// introspection machinery is operational.
bool validateRan = false;

_validateHelper(int expected, int ep) {
  validateRan = true;
  if (ep < 0 || ep > 2) {
    Expect.fail("ERROR: invalid entry-point ($ep) passed by VM.");
  }
  if (expected < -1 || expected > 2) {
    Expect.fail("ERROR: invalid expected entry-point set ($expected)");
  }
  if (expected == -1) return;
  Expect.equals(expected, ep);
}

void _validateFn(String _, int ep) => _validateHelper(expectedEntryPoint, ep);

// Invocation of tearoffs go through a tearoff wrapper. We want to independently
// test which entrypoint was used for the tearoff wrapper vs. which was used for
// actual target.
_validateTearoffFn(String name, int entryPoint) {
  _validateHelper(
      name.endsWith("#tearoff")
          ? expectedTearoffEntryPoint
          : expectedEntryPoint,
      entryPoint);
}

@pragma("vm:entry-point", "get")
const validate = benchmarkMode ? null : _validateFn;
@pragma("vm:entry-point", "get")
const validateTearoff = benchmarkMode ? null : _validateTearoffFn;
