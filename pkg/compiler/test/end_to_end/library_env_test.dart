// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// Check that 'dart:' libraries have their corresponding dart.library.X
/// environment variable set.

import 'dart:async';

import '../helpers/memory_compiler.dart';
import '../helpers/memory_source_file_helper.dart';

import "package:async_helper/async_helper.dart";

import 'package:expect/expect.dart' show Expect;

import 'package:compiler/src/null_compiler_output.dart' show NullCompilerOutput;

import 'package:compiler/src/options.dart' show CompilerOptions;

import 'package:compiler/src/commandline_options.dart';

import 'package:compiler/src/io/source_file.dart' show Binary;

import 'package:compiler/compiler_new.dart'
    show CompilerInput, CompilerDiagnostics, Input, InputKind;

const String librariesJson = r'''
{
 "dart2js": {
   "libraries": {
    "mock.client": {"uri": "mock1.dart"},
    "mock.shared": {"uri": "mock3.dart"},
    "collection": {"uri": "collection/collection.dart"},
    "html": {"uri": "html/dart2js/html_dart2js.dart"}
   }
 },
 "dart2js_server": {
   "libraries": {
    "mock.server": {"uri": "mock2.dart"},
    "mock.shared": {"uri": "mock3.dart"},
    "collection": {"uri": "collection/collection.dart"},
    "io": {"uri": "io/io.dart"}
   }
 }
}
''';

class DummyCompilerInput implements CompilerInput {
  const DummyCompilerInput();

  @override
  Future<Input> readFromUri(Uri uri,
      {InputKind inputKind: InputKind.UTF8}) async {
    if (uri.path.endsWith("libraries.json")) {
      return new Binary(uri, librariesJson.codeUnits);
    } else {
      throw "should not be needed $uri";
    }
  }
}

class DummyCompilerDiagnostics implements CompilerDiagnostics {
  const DummyCompilerDiagnostics();

  @override
  report(code, uri, begin, end, text, kind) {
    throw "should not be needed";
  }
}

class CustomCompiler extends CompilerImpl {
  CustomCompiler(List<String> options, Map<String, String> environment)
      : super(
            const DummyCompilerInput(),
            const NullCompilerOutput(),
            const DummyCompilerDiagnostics(),
            CompilerOptions.parse(
                ['--platform-binaries=$sdkPlatformBinariesPath']
                  ..addAll(options),
                librariesSpecificationUri: sdkLibrariesSpecificationUri)
              ..environment = environment);
}

runTest() async {
  {
    final compiler = new CustomCompiler([], {});

    await compiler.setupSdk();
    final lookup = compiler.environment.valueOf;

    // Core libraries are always present.
    Expect.equals("true", lookup("dart.library.collection"));
    // Non-existing entries in the environment return 'null'.
    Expect.isNull(lookup("not in env"));
    // Check for client libraries (default if there are no flags to the compiler).
    Expect.equals("true", lookup("dart.library.mock.client"));
    Expect.equals("true", lookup("dart.library.html"));
    // Check for shared libraries..
    Expect.equals("true", lookup("dart.library.mock.shared"));
    // Check server libraries are not present.
    Expect.equals(null, lookup("dart.library.mock.server"));
    Expect.equals(null, lookup("dart.library.io"));
  }
  {
    final compiler = new CustomCompiler([Flags.serverMode], {});

    await compiler.setupSdk();
    final lookup = compiler.environment.valueOf;

    // Core libraries are always present.
    Expect.equals("true", lookup("dart.library.collection"));
    // Non-existing entries in the environment return 'null'.
    Expect.isNull(lookup("not in env"));
    // Check client libraries are not present.
    Expect.equals(null, lookup("dart.library.mock.client"));
    Expect.equals(null, lookup("dart.library.html"));
    // Check for shared libraries..
    Expect.equals("true", lookup("dart.library.mock.shared"));
    // Check for server libraries.
    Expect.equals("true", lookup("dart.library.mock.server"));
    Expect.equals("true", lookup("dart.library.io"));
  }
  {
    // Check that user-defined env-variables win.
    final compiler = new CustomCompiler([], {
      'dart.library.collection': "false",
      'dart.library.mock.client': "foo"
    });

    await compiler.setupSdk();
    final lookup = compiler.environment.valueOf;

    Expect.equals("false", lookup("dart.library.collection"));
    Expect.equals("foo", lookup("dart.library.mock.client"));
  }
}

main() {
  asyncStart();
  runTest().then((_) {
    asyncEnd();
  });
}
