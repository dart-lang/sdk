// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:native_assets_builder/native_assets_builder.dart';
import 'package:native_assets_builder/src/build_runner/build_planner.dart';
import 'package:test/test.dart';

import '../helpers.dart';
import 'helpers.dart';

void main() async {
  test('build dependency graph from pub', () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final nativeAddUri = tempUri.resolve('native_add/');

      // First, run `pub get`, we need pub to resolve our dependencies.
      await runPubGet(workingDirectory: nativeAddUri, logger: logger);

      final result = await runProcess(
        executable: Uri.file(Platform.resolvedExecutable),
        arguments: [
          'pub',
          'deps',
          '--json',
        ],
        workingDirectory: nativeAddUri,
        logger: logger,
      );
      expect(result.exitCode, 0);

      final graph = PackageGraph.fromPubDepsJsonString(result.stdout);

      final packageLayout =
          await PackageLayout.fromRootPackageRoot(nativeAddUri);
      final packagesWithNativeAssets =
          await packageLayout.packagesWithNativeAssets;

      final planner = NativeAssetsBuildPlanner(
        packageGraph: graph,
        packagesWithNativeAssets: packagesWithNativeAssets,
        dartExecutable: Uri.file(Platform.resolvedExecutable),
      );
      final buildPlan = planner.plan();
      expect(buildPlan.length, 1);
      expect(buildPlan.single.name, 'native_add');
    });
  });
  test('build dependency graph fromPackageRoot', () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final nativeAddUri = tempUri.resolve('native_add/');

      // First, run `pub get`, we need pub to resolve our dependencies.
      await runPubGet(workingDirectory: nativeAddUri, logger: logger);

      final packageLayout =
          await PackageLayout.fromRootPackageRoot(nativeAddUri);
      final packagesWithNativeAssets =
          await packageLayout.packagesWithNativeAssets;
      final buildPlan = (await NativeAssetsBuildPlanner.fromRootPackageRoot(
        rootPackageRoot: nativeAddUri,
        packagesWithNativeAssets: packagesWithNativeAssets,
        dartExecutable: Uri.file(Platform.resolvedExecutable),
      ))
          .plan();
      expect(buildPlan.length, 1);
      expect(buildPlan.single.name, 'native_add');
    });
  });
}
