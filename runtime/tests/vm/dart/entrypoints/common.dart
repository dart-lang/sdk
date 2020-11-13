// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// We want to run each test with and without inlining of the target functions.
// We accomplish this by using VM options in the yes-inlining variant to set the
// "enable_inlining" constant variable to true. This maximizes code sharing
// between the two variants, which are otherwise identical.
const pragma? NeverInline = const bool.fromEnvironment("enable_inlining")
    ? null
    : pragma('vm:never-inline');

// In AOT we need to force some functions to be inlined since we only build the
// unchecked entry-point when inlining.
const pragma? AlwaysInline = const bool.fromEnvironment("enable_inlining")
    ? pragma('vm:prefer-inline')
    : null;

// All these tests can be run in test mode or in benchmark mode. In benchmark
// mode, there is introspection is omitted and the tests runs for many more
// iterations.
const bool benchmarkMode = const bool.fromEnvironment("benchmark_mode");

class TargetCalls {
  int checked = 0;
  int unchecked = 0;

  // Leave a little room for some cases which always use the checked entry, like
  // lazy compile stub.
  static const int wiggle = 10;

  void expectChecked(int iterations) {
    print("$checked, $unchecked");
    Expect.isTrue(checked >= iterations - wiggle && unchecked == 0);
  }

  void expectUnchecked(int iterations) {
    print("$checked, $unchecked");
    Expect.isTrue(checked <= wiggle && unchecked >= iterations - wiggle);
  }
}

TargetCalls entryPoint = TargetCalls();
TargetCalls tearoffEntryPoint = TargetCalls();

_validateHelper(int ep, TargetCalls? calls) {
  calls ??= entryPoint;

  if (ep < 0 || ep > 2) {
    Expect.fail("ERROR: invalid entry-point ($ep) passed by VM.");
  }
  if (ep == 0) {
    calls.checked++;
  } else {
    calls.unchecked++;
  }
}

void _validateFn(String _, int ep) => _validateHelper(ep, null);

// Invocation of tearoffs go through a tearoff wrapper. We want to independently
// test which entrypoint was used for the tearoff wrapper vs. which was used for
// actual target.
_validateTearoffFn(String name, int ep) {
  _validateHelper(
      ep, name.endsWith("#tearoff") ? tearoffEntryPoint : entryPoint);
}

@pragma("vm:entry-point", "get")
const validate = benchmarkMode ? null : _validateFn;

@pragma("vm:entry-point", "get")
const validateTearoff = benchmarkMode ? null : _validateTearoffFn;
