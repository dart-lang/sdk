// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:native_assets_cli/native_assets_cli.dart';
import 'package:test/test.dart';

import '../helpers.dart';
import 'helpers.dart';

const Timeout longTimeout = Timeout(Duration(minutes: 5));

void main(List<String> args) async {
  test('dry_run', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('native_add/');

      await runPubGet(
        workingDirectory: packageUri,
        logger: logger,
      );

      final dryRunAssets = (await dryRun(packageUri, logger, dartExecutable))
          .where((element) => element.target == Target.current)
          .toList();
      final buildAssets = await build(packageUri, logger, dartExecutable);

      expect(dryRunAssets.length, buildAssets.length);
      for (int i = 0; i < dryRunAssets.length; i++) {
        final dryRunAsset = dryRunAssets[0];
        final buildAsset = buildAssets[0];
        expect(dryRunAsset.linkMode, buildAsset.linkMode);
        expect(dryRunAsset.name, buildAsset.name);
        expect(dryRunAsset.target, buildAsset.target);
        // The target folders are different, so the paths are different.
      }
    });
  });
}
