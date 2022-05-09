// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/api_unstable/vm.dart'
    show computePlatformBinariesLocation;
import 'package:kernel/ast.dart' show Component;
import 'package:kernel/kernel.dart' show loadComponentFromBinary;
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

Future<void> testCompile(List<String> args) async {
  final compilerExitCode =
      await runCompiler(createCompilerArgParser().parse(args), '');
  expect(compilerExitCode, successExitCode);
}

bool containsLibrary(Component component, String name) {
  for (final lib in component.libraries) {
    if (lib.importUri.pathSegments.last == name) {
      return true;
    }
  }
  return false;
}

main() {
  late Directory tempDir;
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

  test('multiple-sources', () async {
    final src1 = File('${tempDir.path}/src1.dart');
    final src2 = File('${tempDir.path}/src2.dart');
    src1.writeAsStringSync("main() {}");
    src2.writeAsStringSync("entryPoint() {}");
    await testCompile([
      '--platform',
      platformPath(),
      '--no-link-platform',
      // Need to specify --packages as front-end refuses to infer
      // its location when compiling multiple sources.
      '--packages',
      '$sdkDir/$packageConfigFile',
      '--source',
      src2.path,
      '--output',
      outputDill(),
      src1.path,
    ]);
    final component = loadComponentFromBinary(outputDill());
    expect(containsLibrary(component, 'src1.dart'), equals(true));
    expect(containsLibrary(component, 'src2.dart'), equals(true));
  }, timeout: Timeout.none);
}
