// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dartdev/src/experiments.dart';
import 'package:dartdev/src/sdk.dart';
import 'package:test/test.dart';

void main() {
  group('experiments', () {
    test('experimentalFeatures', () {
      expect(experimentalFeatures, isNotEmpty);
      expect(
        experimentalFeatures.map((experiment) => experiment.enableString),
        contains('test-experiment'),
      );
    });

    test('unknown experiment', () {
      final errors = validateExperiments(['foo']);
      expect(errors, equals(['Unknown experiment: foo']));
    });

    test('native assets experiment', () {
      final errors = validateExperiments(['native-assets']);
      final channel = Runtime.runtime.channel!;
      switch (channel) {
        case 'stable':
        case 'beta':
          expect(
            errors,
            equals([
              'Unavailable experiment: native-assets (this experiment is only '
                  'available on the main, dev channels, this current channel is $channel)',
            ]),
          );

        default:
          expect(errors, isEmpty);
      }
    });
  });
}
