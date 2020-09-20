// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dartdev/src/experiments.dart';
import 'package:test/test.dart';

void main() {
  group('experiments', () {
    test('experimentalFeatures', () {
      expect(experimentalFeatures, isNotEmpty);
      expect(
        experimentalFeatures.map((experiment) => experiment.enableString),
        contains('non-nullable'),
      );
    });
  });
}
