#!/usr/bin/env dart
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:polymer/testing/content_shell_test.dart';
import 'package:unittest/compact_vm_config.dart';

void main() {
  useCompactVMConfiguration();
  // Base directory, input, expected, output:
  renderTests('..', '.', 'expected', 'out');
}
