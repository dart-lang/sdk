// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'generate_resources.dart' as generate_resources;

/// Validate that the
/// pkg/nnbd_migration/lib/src/front_end/resources/resources.g.dart
/// file was regenerated after changing upstream dependencies.
void main() async {
  test('description', () {
    generate_resources.verifyResourcesGDartGenerated(failVerification: fail);
  });
}
