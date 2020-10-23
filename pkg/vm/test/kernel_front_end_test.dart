// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/api_unstable/vm.dart'
    show computePlatformBinariesLocation;
import 'package:test/test.dart';
import 'package:vm/kernel_front_end.dart';

final String sdkDir = Platform.script.resolve('../../..').toFilePath();

String platformPath() => computePlatformBinariesLocation()
    .resolve('vm_platform_strong.dill')
    .toFilePath();

const String mainScript = 'pkg/vm/bin/gen_kernel.dart';
const String mainScriptPackageUri = 'package:vm/kernel_front_end.dart';
const String packagesFile = '.packages';
const String packageConfigFile = '.dart_tool/package_config.json';

void testCompile(List<String> args) async {
  final compilerExitCode =
      await runCompiler(createCompilerArgParser().parse(args), '');
  expect(compilerExitCode, successExitCode);
}

main() {
  Directory tempDir;
  setUp(() {
    var systemTempDir = Directory.systemTemp;
    tempDir = systemTempDir.createTempSync('kernel_front_end_test');
  });

  tearDown(() {
    tempDir.delete(recursive: true);
  });

  String outputDill() => new File('${tempDir.path}/foo.dill').path;
  String outputManifest() => new File('${tempDir.path}/foo.manifest').path;

  test('compile-simple', () async {
    await testCompile([
      '--platform',
      platformPath(),
      '--packages',
      '$sdkDir/$packagesFile',
      '--output',
      outputDill(),
      '$sdkDir/$mainScript',
    ]);
  }, timeout: Timeout.none);

  test('compile-multi-root', () async {
    await testCompile([
      '--platform',
      platformPath(),
      '--filesystem-scheme',
      'test-filesystem-scheme',
      '--filesystem-root',
      sdkDir,
      '--packages',
      'test-filesystem-scheme:///$packagesFile',
      '--output',
      outputDill(),
      'test-filesystem-scheme:///$mainScript',
    ]);
  }, timeout: Timeout.none);

  test('compile-multi-root-with-package-uri-main', () async {
    await testCompile([
      '--platform',
      platformPath(),
      '--filesystem-scheme',
      'test-filesystem-scheme',
      '--filesystem-root',
      sdkDir,
      '--packages',
      'test-filesystem-scheme:///$packagesFile',
      '--output',
      outputDill(),
      '$mainScriptPackageUri',
    ]);
  }, timeout: Timeout.none);

  test('compile-package-split', () async {
    await testCompile([
      '--platform',
      platformPath(),
      '--packages',
      '$sdkDir/$packagesFile',
      '--output',
      outputDill(),
      '--split-output-by-packages',
      '--manifest',
      outputManifest(),
      '--component-name',
      'foo_component',
      '$sdkDir/$mainScript',
    ]);
  }, timeout: Timeout.none);

  test('compile-package-config', () async {
    await testCompile([
      '--platform',
      platformPath(),
      '--packages',
      '$sdkDir/$packageConfigFile',
      '--output',
      outputDill(),
      '$sdkDir/$mainScript',
    ]);
  }, timeout: Timeout.none);

  test('compile-multi-root-package-config', () async {
    await testCompile([
      '--platform',
      platformPath(),
      '--filesystem-scheme',
      'test-filesystem-scheme',
      '--filesystem-root',
      sdkDir,
      '--packages',
      'test-filesystem-scheme:///$packageConfigFile',
      '--output',
      outputDill(),
      'test-filesystem-scheme:///$mainScript',
    ]);
  }, timeout: Timeout.none);
}
