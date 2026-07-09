// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'uri_test.dart' as uri;

main() {
  defineReflectiveSuite(() {
    uri.main();
  }, name: 'extensions');
}
