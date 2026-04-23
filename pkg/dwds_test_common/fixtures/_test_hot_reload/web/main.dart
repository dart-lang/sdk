// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';
import 'dart:js_interop';

import 'package:_test_hot_reload/library1.dart';

@JS('console.log')
external void log(String _);

void evaluate() {
  log('$reloadValue');
}

void main() {
  evaluate();
}
