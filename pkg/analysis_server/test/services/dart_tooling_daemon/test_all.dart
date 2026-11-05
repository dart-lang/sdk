// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'dtd_services_test.dart' as dtd_services;

void main() {
  defineReflectiveSuite(() {
    dtd_services.main();
  }, name: 'dart_tooling_daemon');
}
