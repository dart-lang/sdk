// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library template_binding.test.analyzer_test;

import 'dart:html';
import 'package:template_binding/template_binding.dart';

// @static-clean

// This test ensures template_binding compiles without errors.
void main() {
  // To make analyzer happy about unused imports.
  nodeBind(document);
}
