// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'driver_test.dart' show defineDriverTests;

void main() {
  defineDriverTests(
    name: 'prefer_is_empty',
    options: ['--fix', 'prefer_is_empty'],
    expectedSuggestions: ["Replace with 'isEmpty'"],
  );
}
