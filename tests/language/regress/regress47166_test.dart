// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/47166

import 'package:expect/expect.dart';

@pragma('dart2js:noInline')
void maybeThrow(bool doThrow) {
  if (doThrow) throw Exception('omg!');
}

int triggerTheProblem(bool doThrow) {
  int x = 1;
  try {
    x = 100;
    maybeThrow(doThrow);
    x = 1; // unreached.
    log1 = x;
  } catch (e) {
    log2 = x;
  }
  log3 = x;

  // This closure creates a context object ('box') subject to load elimination.
  // In the reported bug, log2 and log3 were assigned constant '1' from an
  // incorrect store-forwarding optimization of the boxed 'x'. The '1' came from
  // the merge of '1' from the initialization of 'x' and the unreachable
  // assignment of 'x'.
  g = () => x;

  log4 = x;
  return x;
}

dynamic g;
int log1 = 0, log2 = 0, log3 = 0, log4 = 0, log5 = 0, log6 = 0;

void main() {
  log5 = triggerTheProblem(true);
  log6 = g(); // Use 'g'.
  Expect.equals(
      'log1=0 log2=100 log3=100 log4=100 log5=100 log6=100',
      'log1=$log1 log2=$log2 log3=$log3 log4=$log4 log5=$log5 log6=$log6',
      'throwing');

  // Run the test with 'doThrow' being false to avoid any confounding
  // optimizations due to constant propagation.
  log1 = log2 = log3 = log4 = log5 = log6 = 0;
  log5 = triggerTheProblem(false);
  log6 = g(); // Use 'g'.
  Expect.equals(
      'log1=1 log2=0 log3=1 log4=1 log5=1 log6=1',
      'log1=$log1 log2=$log2 log3=$log3 log4=$log4 log5=$log5 log6=$log6',
      'not throwing');
}
