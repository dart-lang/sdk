// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the compiler can handle imports when package root has not been set.

library dart2js.test.package_root;

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/compiler.dart'
       show DiagnosticHandler, Diagnostic, PackagesDiscoveryProvider;
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

void runCompiler(Uri main,
                 bool checkError(DiagnosticMessage message),
                 {Uri packageRoot,
                  Uri packageConfig,
                  PackagesDiscoveryProvider packagesDiscoveryProvider}) {
  DiagnosticCollector collector = new DiagnosticCollector();
  Compiler compiler = compilerFor(
      MEMORY_SOURCE_FILES,
      diagnosticHandler: collector,
      packageRoot: packageRoot,
      packageConfig: packageConfig,
      packagesDiscoveryProvider: packagesDiscoveryProvider);

  asyncTest(() => compiler.run(main).then((_) {
    Expect.equals(1, collector.errors.length,
        "Unexpected errors: ${collector.errors}");
    Expect.isTrue(checkError(collector.errors.first),
        "Unexpected error: ${collector.errors.first}");
  }));
}

void main() {
  Uri script = currentDirectory.resolveUri(Platform.script);
  Uri packageRoot = script.resolve('./packages/');

  PackagesDiscoveryProvider noPackagesDiscovery = (Uri uri) {
    return new Future.value(Packages.noPackages);
  };

  bool containsErrorReading(DiagnosticMessage message) {
    return message.message.contains("Error reading ");
  }

  bool isLibraryNotFound(DiagnosticMessage message) {
    return message.message.startsWith("Library not found ");
  }

  runCompiler(Uri.parse('memory:main.dart'),
              containsErrorReading,
              packageRoot: packageRoot);
  runCompiler(Uri.parse('memory:main.dart'),
              isLibraryNotFound,
              packageConfig: PACKAGE_CONFIG_URI);
  runCompiler(Uri.parse('memory:main.dart'),
              isLibraryNotFound,
              packagesDiscoveryProvider: noPackagesDiscovery);

  runCompiler(Uri.parse('package:foo/foo.dart'),
              containsErrorReading,
              packageRoot: packageRoot);
  runCompiler(Uri.parse('package:foo/foo.dart'),
              isLibraryNotFound,
              packageConfig: PACKAGE_CONFIG_URI);
  runCompiler(Uri.parse('package:foo/foo.dart'),
              isLibraryNotFound,
              packagesDiscoveryProvider: noPackagesDiscovery);
}
