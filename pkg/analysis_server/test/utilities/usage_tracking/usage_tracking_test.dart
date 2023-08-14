// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analysis_server/src/utilities/usage_tracking/usage_tracking.dart';
import 'package:test/test.dart';

void main() {
  group('parseAutoSnapshottingConfig', () {
    test('parses correct config', () {
      final config = parseAutoSnapshottingConfig(_argsWithSnapshotting)!;
      expect(config.thresholdMb, 200);
      expect(config.increaseMb, 100);
      expect(config.directory, '/Users/polinach/Downloads/analyzer_snapshots');
      expect(config.directorySizeLimitMb, 10000);
      expect(config.minDelayBetweenSnapshots, Duration(seconds: 20));
    });

    test('returns null for no config', () {
      final config = parseAutoSnapshottingConfig(_argsNoSnapshotting);
      expect(config, null);
    });

    test('throws for wrong config', () {
      final wrongAutosnapshottingArg = 'autosnapshotting--wrong-configuration';
      expect(
        () => parseAutoSnapshottingConfig(
            [wrongAutosnapshottingArg, 'some other arg']),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

const _argsNoSnapshotting = [
  '--sdk=C:/b/s/w/ir/x/w/sdk/sdk/',
  '--train-using=C:/b/s/w/ir/x/w/sdk/pkg/compiler/lib'
];
const _argsWithSnapshotting = [
  _autosnapshottingArg,
  '--sdk=C:/b/s/w/ir/x/w/sdk/sdk/',
  '--train-using=C:/b/s/w/ir/x/w/sdk/pkg/compiler/lib'
];

// This constant is referenced in README.md for auto-snapshotting.
const _autosnapshottingArg =
    'autosnapshotting-thresholdMb-200,increaseMb-100,dir-/Users/polinach/Downloads/analyzer_snapshots,dirLimitMb-10000,delaySec-20';
