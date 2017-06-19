// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the compiler can handle imports when package root has not been set.

library dart2js.test.package_root;

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/compiler.dart' show PackagesDiscoveryProvider;
import 'package:compiler/src/diagnostics/messages.dart' show MessageKind;
import 'package:package_config/packages.dart';

import 'memory_compiler.dart';
import 'memory_source_file_helper.dart';

const MEMORY_SOURCE_FILES = const {
  'main.dart': '''

import 'package:foo/foo.dart';

main() {}
''',
  'package.config': '''
''',
};

final Uri PACKAGE_CONFIG_URI = Uri.parse('memory:package.config');

Future runTest(Uri main, MessageKind expectedMessageKind,
    {Uri packageRoot,
    Uri packageConfig,
    PackagesDiscoveryProvider packagesDiscoveryProvider}) async {
  DiagnosticCollector collector = new DiagnosticCollector();
  await runCompiler(
      entryPoint: main,
      memorySourceFiles: MEMORY_SOURCE_FILES,
      diagnosticHandler: collector,
      packageRoot: packageRoot,
      packageConfig: packageConfig,
      packagesDiscoveryProvider: packagesDiscoveryProvider);
  Expect.equals(
      1, collector.errors.length, "Unexpected errors: ${collector.errors}");
  Expect.equals(expectedMessageKind, collector.errors.first.message.kind,
      "Unexpected error: ${collector.errors.first}");
}

void main() {
  asyncTest(() async {
    Uri script = currentDirectory.resolveUri(Platform.script);
    Uri packageRoot = script.resolve('./packages/');

    PackagesDiscoveryProvider noPackagesDiscovery = (Uri uri) {
      return new Future.value(Packages.noPackages);
    };

    await runTest(Uri.parse('memory:main.dart'), MessageKind.READ_URI_ERROR,
        packageRoot: packageRoot);
    await runTest(Uri.parse('memory:main.dart'), MessageKind.LIBRARY_NOT_FOUND,
        packageConfig: PACKAGE_CONFIG_URI);
    await runTest(Uri.parse('memory:main.dart'), MessageKind.LIBRARY_NOT_FOUND,
        packagesDiscoveryProvider: noPackagesDiscovery);

    await runTest(
        Uri.parse('package:foo/foo.dart'), MessageKind.READ_SELF_ERROR,
        packageRoot: packageRoot);
    await runTest(
        Uri.parse('package:foo/foo.dart'), MessageKind.LIBRARY_NOT_FOUND,
        packageConfig: PACKAGE_CONFIG_URI);
    await runTest(
        Uri.parse('package:foo/foo.dart'), MessageKind.LIBRARY_NOT_FOUND,
        packagesDiscoveryProvider: noPackagesDiscovery);
  });
}
