// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

void foo(Stream<int> Function() values) {}

void main() {
  foo(/*@ returnType=Stream<int*>* */ () async* {
    yield 0;
    yield 1;
  });
}
