// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';
import 'dart:core' as core;

core.String field = '';

void main() {
  core.String value = field;
  method(value);
}

@annotation
void method(@annotation core.String value) {
  core.print(value);
  void local(@annotation int i) {}
  local(0);
}

const annotation = const Object();
