// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test a sequence of modifications to hello-world which used to cause problems
// on Try Dart.

import 'dart:io' show
    Platform;

import 'dart:async' show
    Future;

import 'package:try/src/caching_compiler.dart' show
    reuseCompiler;

import 'package:compiler/compiler.dart' as compiler;

import 'package:async_helper/async_helper.dart' show
    asyncTest;

import 'package:expect/expect.dart' show
    Expect;

import '../memory_source_file_helper.dart' show
    MemorySourceFileProvider;

import 'incremental_helper.dart';

var tests = {
'/test1.dart':
'''
var greeting = "Hello, World!";

void main() {
  print(greeting);
}
''',
'/test2.dart':
'''
va greeting = "Hello, World!";

void main() {
  print(greeting);
}
''',
'/test3.dart':
'''
 greeting = "Hello, World!";

void main() {
  print(greeting);
}
''',
'/test4.dart':
'''
in greeting = "Hello, World!";

void main() {
  print(greeting);
}
''',
'/test5.dart':
'''
int greeting = "Hello, World!";

void main() {
  print(greeting);
}
''',
};

var testResults = {
  '/test1.dart': true,
  '/test2.dart': true,
  '/test3.dart': false,
  '/test4.dart': false,
  '/test5.dart': true,
};

var cachedCompiler;

main() {
  Uri libraryRoot = Uri.base.resolve('sdk/');
  Uri packageRoot = Uri.base.resolveUri(
      new Uri.file('${Platform.packageRoot}/'));
  MemorySourceFileProvider provider =
      new MemorySourceFileProvider(tests);
  asyncTest(
      () => runTests(libraryRoot, packageRoot, provider, INCREMENTAL_OPTIONS));
}

Future runTests(
    Uri libraryRoot,
    Uri packageRoot,
    MemorySourceFileProvider provider,
    options) {
  return Future.forEach(tests.keys, (String testName) {
    cachedCompiler = reuseCompiler(
        diagnosticHandler: handler,
        inputProvider: provider,
        options: options,
        cachedCompiler: cachedCompiler,
        libraryRoot: libraryRoot,
        packageRoot: packageRoot);
    Uri testUri = Uri.parse('memory:$testName');
    return cachedCompiler.run(testUri).then((bool success) {
      Expect.equals(
          testResults[testName], success,
          'Compilation unexpectedly ${success ? "succeed" : "failed"}.');
    });
  });
}

void handler(Uri uri,
             int begin,
             int end,
             String message,
             compiler.Diagnostic kind) {
  if (kind != compiler.Diagnostic.VERBOSE_INFO) {
    print('$uri:$begin:$end:$message:$kind');
  }
}
