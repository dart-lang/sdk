// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  load();
  load(cond: true);
  Expect.equals('side-effect', state);
}

String state = 'start';

// `cond` can be both true and false.
// `use` is always be false.
dynamic load({bool cond = false, bool use = false}) {
  int? data;
  if (cond) {
    data = callWithSideEffects();
  }
  return [if (use && cond) data];
}

@pragma('dart2js:noInline')
int callWithSideEffects() {
  state = 'side-effect';
  return 2;
}
